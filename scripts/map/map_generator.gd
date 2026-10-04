class_name MapGenerator
extends RefCounted
## Gera um MapData a partir da seed.
## Função pura: depende só de map_seed e da config (sem arquivos, assets, tempo, OS,
## cena nem RNG global). Os passos rodam sempre na mesma ordem, cada um com o próprio RNG
## tirado do RNG mestre, para mexer num passo não embaralhar os outros.

const NEIGHBORS_4: Array = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
const NEIGHBORS_8: Array = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0),
	Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
]
## Tamanho do balde da grade espacial usada no espaçamento da vegetação.
const GRID_BUCKET: float = 2.0

var config: MapGenConfig


## Estado intermediário de uma geração (descartado no fim).
class GenContext extends RefCounted:
	var data: MapData
	var cfg: MapGenConfig
	var w: int = 0
	var h: int = 0
	var arena_count: int = 0
	var arena_bounds: Rect2i = Rect2i()
	## Distância (Chebyshev, em células) até a arena; 0 dentro dela.
	var arena_dist: PackedInt32Array = PackedInt32Array()
	## Distância (Chebyshev) até fora da arena; 0 fora dela.
	var inner_dist: PackedInt32Array = PackedInt32Array()
	## Por coluna: cz da célula de arena mais ao sul (-1 se a coluna não tem arena).
	var south_most: PackedInt32Array = PackedInt32Array()
	var south_strip: PackedByteArray = PackedByteArray()
	var raised: PackedByteArray = PackedByteArray()
	var stair: PackedByteArray = PackedByteArray()
	var trail: PackedByteArray = PackedByteArray()
	var occupied: PackedByteArray = PackedByteArray()


func _init(p_config: MapGenConfig = null) -> void:
	config = p_config if p_config != null else MapGenConfig.new()


func generate(map_seed: int) -> MapData:
	var master := RandomNumberGenerator.new()
	master.seed = map_seed
	var ctx := _new_context(map_seed)
	_build_arena(ctx, _sub_rng(master))
	_build_relief(ctx, _sub_rng(master))
	_build_raised_regions(ctx, _sub_rng(master))
	_build_trails(ctx, _sub_rng(master))
	_build_ground(ctx, _sub_rng(master))
	_build_walls(ctx, _sub_rng(master))
	_place_monoliths(ctx, _sub_rng(master))
	_place_rocks(ctx, _sub_rng(master))
	_place_vegetation(ctx, _sub_rng(master))
	ctx.data.invalidate_caches()
	return ctx.data


# --- Contexto e utilidades -------------------------------------------------

func _new_context(map_seed: int) -> GenContext:
	var ctx := GenContext.new()
	ctx.cfg = config
	ctx.w = maxi(config.map_size.x, 24)
	ctx.h = maxi(config.map_size.y, 24)
	var n: int = ctx.w * ctx.h
	var data := MapData.new()
	data.map_seed = map_seed
	data.size = Vector2i(ctx.w, ctx.h)
	data.arena_base_level = config.arena_base_level
	data.wall_thickness = config.wall_thickness
	data.heights = _filled_ints(n, config.arena_base_level)
	data.ground = _filled_bytes(n, MapData.Ground.FOREST_GRASS)
	data.arena_mask = _filled_bytes(n, 0)
	ctx.data = data
	ctx.south_strip = _filled_bytes(n, 0)
	ctx.raised = _filled_bytes(n, 0)
	ctx.stair = _filled_bytes(n, 0)
	ctx.trail = _filled_bytes(n, 0)
	ctx.occupied = _filled_bytes(n, 0)
	return ctx


func _sub_rng(master: RandomNumberGenerator) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = master.randi()
	return rng


func _make_noise(rng: RandomNumberGenerator, frequency: float, octaves: int) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = int(rng.randi() & 0x7FFFFFFF)
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = frequency
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM if octaves > 1 else FastNoiseLite.FRACTAL_NONE
	noise.fractal_octaves = maxi(octaves, 1)
	return noise


func _filled_bytes(n: int, value: int) -> PackedByteArray:
	var arr := PackedByteArray()
	arr.resize(n)
	arr.fill(value)
	return arr


func _filled_ints(n: int, value: int) -> PackedInt32Array:
	var arr := PackedInt32Array()
	arr.resize(n)
	arr.fill(value)
	return arr


func _in_map(ctx: GenContext, cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < ctx.w and cell.y < ctx.h


func _idx(ctx: GenContext, cell: Vector2i) -> int:
	return cell.y * ctx.w + cell.x


func _is_arena(ctx: GenContext, cell: Vector2i) -> bool:
	return _in_map(ctx, cell) and ctx.data.arena_mask[_idx(ctx, cell)] == 1


func _jitter_in_cell(rng: RandomNumberGenerator, cell: Vector2i, margin: float) -> Vector2:
	return Vector2(cell.x + rng.randf_range(margin, 1.0 - margin), cell.y + rng.randf_range(margin, 1.0 - margin))


# --- 2. Arena ----------------------------------------------------------------

func _build_arena(ctx: GenContext, rng: RandomNumberGenerator) -> void:
	var cfg := ctx.cfg
	var jitter: int = maxi(cfg.arena_center_jitter, 0)
	var center := Vector2(
		ctx.w * 0.5 + rng.randi_range(-jitter, jitter),
		ctx.h * 0.5 + rng.randi_range(-jitter, jitter))
	var target := Vector2(
		rng.randf_range(cfg.arena_fraction_min, cfg.arena_fraction_max) * ctx.w,
		rng.randf_range(cfg.arena_fraction_min, cfg.arena_fraction_max) * ctx.h)
	var exponent: float = rng.randf_range(cfg.arena_shape_exponent_min, cfg.arena_shape_exponent_max)
	var noise := _make_noise(rng, 1.0, 2)
	var radii: Vector2 = target * 0.5
	var mask := PackedByteArray()
	# A deformação muda a caixa; corrige os raios até a caixa bater com o alvo.
	for _attempt in 8:
		mask = _shape_mask(ctx, center, radii, exponent, noise)
		_clean_arena_mask(ctx, mask, center)
		var box := _mask_bounds(ctx, mask)
		var err: Vector2 = Vector2(box.size) - target
		if absf(err.x) <= 1.0 and absf(err.y) <= 1.0:
			break
		radii.x *= target.x / maxf(float(box.size.x), 1.0)
		radii.y *= target.y / maxf(float(box.size.y), 1.0)
	ctx.data.arena_mask = mask

	var bounds := _mask_bounds(ctx, mask)
	ctx.arena_bounds = bounds
	ctx.data.arena_rect = Rect2(bounds)
	ctx.data.arena_center = ctx.data.arena_rect.get_center()
	ctx.arena_count = mask.count(1)
	ctx.arena_dist = _chebyshev_distance(ctx, mask, 1)
	ctx.inner_dist = _chebyshev_distance(ctx, mask, 0)

	# Faixa sul: tudo que fica abaixo da célula de arena mais ao sul de cada coluna.
	ctx.south_most = _filled_ints(ctx.w, -1)
	for cz in ctx.h:
		for cx in ctx.w:
			if mask[cz * ctx.w + cx] == 1:
				ctx.south_most[cx] = cz
	for cx in ctx.w:
		if ctx.south_most[cx] < 0:
			continue
		for cz in range(ctx.south_most[cx] + 1, ctx.h):
			ctx.south_strip[cz * ctx.w + cx] = 1


func _shape_mask(ctx: GenContext, center: Vector2, radii: Vector2, exponent: float, noise: FastNoiseLite) -> PackedByteArray:
	var mask := _filled_bytes(ctx.w * ctx.h, 0)
	var amp: float = ctx.cfg.arena_shape_noise
	var circle_r: float = ctx.cfg.arena_shape_noise_scale
	for cz in ctx.h:
		for cx in ctx.w:
			var p := Vector2(cx + 0.5, cz + 0.5) - center
			var q := Vector2(absf(p.x) / radii.x, absf(p.y) / radii.y)
			var d: float = pow(pow(q.x, exponent) + pow(q.y, exponent), 1.0 / exponent)
			var dir: Vector2 = p.normalized() if p.length_squared() > 0.0001 else Vector2.RIGHT
			# Noise amostrado num círculo: a deformação fecha sem emenda.
			var bump: float = clampf(noise.get_noise_2d(dir.x * circle_r, dir.y * circle_r) * 1.8, -1.0, 1.0)
			if d <= 1.0 + bump * amp:
				mask[cz * ctx.w + cx] = 1
	return mask


## Limpa a forma: borda do mapa livre, sem protuberâncias/entalhes de 1 célula,
## sem pinça diagonal, uma única região (vizinhança 4) e sem buracos.
func _clean_arena_mask(ctx: GenContext, mask: PackedByteArray, center: Vector2) -> void:
	var margin: int = ctx.cfg.ring_width + 3
	var w: int = ctx.w
	var h: int = ctx.h
	for _pass in 8:
		var changed := false
		for cz in h:
			for cx in w:
				var near_border: bool = cx < margin or cz < margin or cx >= w - margin or cz >= h - margin
				if near_border and mask[cz * w + cx] == 1:
					mask[cz * w + cx] = 0
					changed = true
		var src := mask.duplicate()
		for cz in range(margin, h - margin):
			for cx in range(margin, w - margin):
				var i: int = cz * w + cx
				var n4: int = src[i - 1] + src[i + 1] + src[i - w] + src[i + w]
				if src[i] == 1 and n4 <= 1:
					mask[i] = 0
					changed = true
				elif src[i] == 0 and n4 >= 3:
					mask[i] = 1
					changed = true
		for cz in range(margin, h - margin - 1):
			for cx in range(margin, w - margin - 1):
				var a: int = cz * w + cx
				var b: int = a + 1
				var c: int = a + w
				var d: int = a + w + 1
				if mask[a] == 1 and mask[d] == 1 and mask[b] == 0 and mask[c] == 0:
					mask[b] = 1
					changed = true
				elif mask[b] == 1 and mask[c] == 1 and mask[a] == 0 and mask[d] == 0:
					mask[a] = 1
					changed = true
		if _keep_main_component(ctx, mask, center):
			changed = true
		if _fill_holes(ctx, mask):
			changed = true
		if not changed:
			break


func _keep_main_component(ctx: GenContext, mask: PackedByteArray, center: Vector2) -> bool:
	var start := Vector2i(floori(center.x), floori(center.y))
	if not _in_map(ctx, start) or mask[_idx(ctx, start)] == 0:
		# Centro fora da forma: usa a célula de arena mais próxima do centro.
		var best_d: float = INF
		for cz in ctx.h:
			for cx in ctx.w:
				if mask[cz * ctx.w + cx] == 1:
					var dd: float = center.distance_squared_to(Vector2(cx + 0.5, cz + 0.5))
					if dd < best_d:
						best_d = dd
						start = Vector2i(cx, cz)
		if best_d == INF:
			return false
	var seen := _filled_bytes(ctx.w * ctx.h, 0)
	var queue: Array[Vector2i] = [start]
	seen[_idx(ctx, start)] = 1
	var head: int = 0
	while head < queue.size():
		var cell: Vector2i = queue[head]
		head += 1
		for d: Vector2i in NEIGHBORS_4:
			var nb: Vector2i = cell + d
			if _in_map(ctx, nb) and mask[_idx(ctx, nb)] == 1 and seen[_idx(ctx, nb)] == 0:
				seen[_idx(ctx, nb)] = 1
				queue.append(nb)
	var changed := false
	for i in mask.size():
		if mask[i] == 1 and seen[i] == 0:
			mask[i] = 0
			changed = true
	return changed


func _fill_holes(ctx: GenContext, mask: PackedByteArray) -> bool:
	var seen := _filled_bytes(ctx.w * ctx.h, 0)
	var queue: Array[Vector2i] = []
	for cz in ctx.h:
		for cx in ctx.w:
			var on_border: bool = cx == 0 or cz == 0 or cx == ctx.w - 1 or cz == ctx.h - 1
			if on_border and mask[cz * ctx.w + cx] == 0:
				seen[cz * ctx.w + cx] = 1
				queue.append(Vector2i(cx, cz))
	var head: int = 0
	while head < queue.size():
		var cell: Vector2i = queue[head]
		head += 1
		for d: Vector2i in NEIGHBORS_4:
			var nb: Vector2i = cell + d
			if _in_map(ctx, nb) and mask[_idx(ctx, nb)] == 0 and seen[_idx(ctx, nb)] == 0:
				seen[_idx(ctx, nb)] = 1
				queue.append(nb)
	var changed := false
	for i in mask.size():
		if mask[i] == 0 and seen[i] == 0:
			mask[i] = 1
			changed = true
	return changed


func _mask_bounds(ctx: GenContext, mask: PackedByteArray) -> Rect2i:
	var lo := Vector2i(ctx.w, ctx.h)
	var hi := Vector2i(-1, -1)
	for cz in ctx.h:
		for cx in ctx.w:
			if mask[cz * ctx.w + cx] == 1:
				lo = Vector2i(mini(lo.x, cx), mini(lo.y, cz))
				hi = Vector2i(maxi(hi.x, cx), maxi(hi.y, cz))
	if hi.x < 0:
		return Rect2i()
	return Rect2i(lo, hi - lo + Vector2i.ONE)


## BFS multi-fonte (vizinhança 8): distância de cada célula até a célula mais próxima
## com mask == source_value.
func _chebyshev_distance(ctx: GenContext, mask: PackedByteArray, source_value: int) -> PackedInt32Array:
	var dist := _filled_ints(ctx.w * ctx.h, -1)
	var queue: Array[Vector2i] = []
	for cz in ctx.h:
		for cx in ctx.w:
			if mask[cz * ctx.w + cx] == source_value:
				dist[cz * ctx.w + cx] = 0
				queue.append(Vector2i(cx, cz))
	var head: int = 0
	while head < queue.size():
		var cell: Vector2i = queue[head]
		head += 1
		var next_d: int = dist[_idx(ctx, cell)] + 1
		for d: Vector2i in NEIGHBORS_8:
			var nb: Vector2i = cell + d
			if _in_map(ctx, nb) and dist[_idx(ctx, nb)] < 0:
				dist[_idx(ctx, nb)] = next_d
				queue.append(nb)
	return dist


# --- 3. Relevo ---------------------------------------------------------------

func _build_relief(ctx: GenContext, rng: RandomNumberGenerator) -> void:
	var cfg := ctx.cfg
	var noise := _make_noise(rng, cfg.height_noise_frequency, 3)
	var base: int = cfg.arena_base_level
	var heights := ctx.data.heights
	for cz in ctx.h:
		for cx in ctx.w:
			var i: int = cz * ctx.w + cx
			var ad: int = ctx.arena_dist[i]
			if ad <= cfg.ring_width:
				heights[i] = base
				continue
			# Fora do anel: noise + subida suave com a distância da arena.
			var far: float = clampf(float(ad - cfg.ring_width) / maxf(cfg.height_distance_falloff, 1.0), 0.0, 1.0)
			var v: float = noise.get_noise_2d(cx, cz) * cfg.height_noise_amplitude + far * cfg.height_distance_bias
			var level: int = clampi(base + floori(v + 0.5), 0, cfg.max_level)
			if ctx.south_strip[i] == 1:
				level = mini(level, base)
			heights[i] = level
	ctx.data.heights = heights
	_remove_spikes(ctx, _locked_cells(ctx, false))


## Células que a limpeza de relevo não pode mexer: arena, anel e (opcional) trilhas.
func _locked_cells(ctx: GenContext, include_trails: bool) -> PackedByteArray:
	var locked := _filled_bytes(ctx.w * ctx.h, 0)
	for i in locked.size():
		if ctx.arena_dist[i] <= ctx.cfg.ring_width or (include_trails and ctx.trail[i] == 1):
			locked[i] = 1
	return locked


## Tira "espinhos" e valas de 1 célula de largura (fora das células travadas)
## e mantém a faixa sul no máximo no nível base.
func _remove_spikes(ctx: GenContext, locked: PackedByteArray) -> void:
	var heights := ctx.data.heights
	var w: int = ctx.w
	for _pass in 4:
		var changed := false
		var src := heights.duplicate()
		for cz in ctx.h:
			for cx in w:
				var i: int = cz * w + cx
				if locked[i] == 1:
					continue
				var hc: int = src[i]
				var l: int = src[i - 1] if cx > 0 else hc
				var r: int = src[i + 1] if cx < w - 1 else hc
				var u: int = src[i - w] if cz > 0 else hc
				var d: int = src[i + w] if cz < ctx.h - 1 else hc
				var nh: int = hc
				if l < nh and r < nh:
					nh = maxi(l, r)
				elif l > nh and r > nh:
					nh = mini(l, r)
				if u < nh and d < nh:
					nh = maxi(u, d)
				elif u > nh and d > nh:
					nh = mini(u, d)
				if nh != hc:
					heights[i] = nh
					changed = true
		if not changed:
			break
	var base: int = ctx.cfg.arena_base_level
	for i in heights.size():
		if ctx.south_strip[i] == 1 and heights[i] > base:
			heights[i] = base
	ctx.data.heights = heights


# --- 4. Degraus e escada na arena ------------------------------------------

func _build_raised_regions(ctx: GenContext, rng: RandomNumberGenerator) -> void:
	var cfg := ctx.cfg
	var base: int = cfg.arena_base_level
	var count: int = rng.randi_range(cfg.raised_regions_min, maxi(cfg.raised_regions_min, cfg.raised_regions_max))
	var max_cells: int = floori(cfg.raised_region_max_fraction * ctx.arena_count)
	var total_cap: int = floori(cfg.raised_total_max_fraction * ctx.arena_count)
	var total: int = 0
	var margin: int = maxi(cfg.raised_region_edge_margin, 0)
	var min_size := Vector2i(maxi(cfg.raised_region_min_size.x, 3), maxi(cfg.raised_region_min_size.y, 3))
	var max_size := Vector2i(maxi(cfg.raised_region_max_size.x, min_size.x), maxi(cfg.raised_region_max_size.y, min_size.y))
	var b := ctx.arena_bounds
	var regions: Array = []
	for _r in count:
		for _attempt in 80:
			var radius: float = rng.randf_range(2.5, 5.0)
			var cx: int = rng.randi_range(b.position.x + 4, maxi(b.position.x + 4, b.end.x - 4))
			var cz: int = rng.randi_range(b.position.y + 4, maxi(b.position.y + 4, b.end.y - 4))
			var cells: Array[Vector2i] = _blob_cells(rng, Vector2i(cx, cz), radius)
			# Anexar uma segunda bolha para formar formatos mais variados (amendoim, L, etc)
			if rng.randf() < 0.7:
				var offset_x: int = rng.randi_range(-3, 3)
				var offset_z: int = rng.randi_range(-3, 3)
				var r2: float = radius * rng.randf_range(0.6, 1.1)
				var extra_cells: Array[Vector2i] = _blob_cells(rng, Vector2i(cx + offset_x, cz + offset_z), r2)
				for c in extra_cells:
					if not cells.has(c):
						cells.append(c)
			if cells.size() > max_cells or total + cells.size() > total_cap:
				continue
			if not _region_fits(ctx, cells, margin):
				continue
			for cell: Vector2i in cells:
				ctx.raised[_idx(ctx, cell)] = 1
				ctx.data.heights[_idx(ctx, cell)] = base + 1
			total += cells.size()
			regions.append(cells)
			break

	if regions.is_empty() or rng.randf() >= cfg.stair_chance:
		return
	var region: Array = regions[rng.randi_range(0, regions.size() - 1)]
	_add_stair(ctx, rng, region)


func _blob_cells(rng: RandomNumberGenerator, center: Vector2i, radius: float) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var r2: float = radius * radius
	# Estica um pouco para não ser um círculo perfeito
	var stretch_x: float = rng.randf_range(0.8, 1.25)
	var stretch_z: float = rng.randf_range(0.8, 1.25)
	var max_r: int = ceili(radius * 1.5)
	for cz in range(center.y - max_r, center.y + max_r + 1):
		for cx in range(center.x - max_r, center.x + max_r + 1):
			var dx: float = (cx - center.x) / stretch_x
			var dz: float = (cz - center.y) / stretch_z
			if dx * dx + dz * dz <= r2:
				cells.append(Vector2i(cx, cz))
	return cells


func _region_fits(ctx: GenContext, cells: Array[Vector2i], margin: int) -> bool:
	var gap: int = 3
	for cell: Vector2i in cells:
		if not _is_arena(ctx, cell):
			return false
		if ctx.inner_dist[_idx(ctx, cell)] < margin + 1:
			return false
		# Distância de outras regiões elevadas (corredores largos entre elas).
		for dz in range(-gap, gap + 1):
			for dx in range(-gap, gap + 1):
				var nb := cell + Vector2i(dx, dz)
				if _in_map(ctx, nb) and ctx.raised[_idx(ctx, nb)] == 1:
					return false
	return true


func _add_stair(ctx: GenContext, rng: RandomNumberGenerator, region: Array) -> void:
	var cfg := ctx.cfg
	var sw: int = maxi(cfg.stair_width, 1)
	# Trechos contínuos da borda sul da região (célula elevada com vizinho sul no nível base).
	var edge: Dictionary = {}
	for cell: Vector2i in region:
		var south: Vector2i = cell + Vector2i(0, 1)
		if _is_arena(ctx, south) and ctx.raised[_idx(ctx, south)] == 0:
			edge[cell] = true
	var runs: Array = []
	for cell: Vector2i in region:
		if not edge.has(cell) or edge.has(cell + Vector2i(-1, 0)):
			continue
		var length: int = 0
		while edge.has(cell + Vector2i(length, 0)):
			length += 1
		if length >= sw + 2:
			runs.append(Vector3i(cell.x, cell.y, length))
	if runs.is_empty():
		return
	var run: Vector3i = runs[rng.randi_range(0, runs.size() - 1)]
	var lo: int = run.x + 1
	var hi: int = run.x + run.z - 1 - sw
	var mid: int = run.x + floori((run.z - sw) * 0.5)
	var start_x: int = clampi(mid + rng.randi_range(-1, 1), lo, maxi(lo, hi))
	var stair := MapStair.new()
	stair.base_level = cfg.arena_base_level
	stair.up_direction = Vector2i(0, -1)
	for k in sw:
		var cell := Vector2i(start_x + k, run.y + 1)
		stair.cells.append(cell)
		ctx.stair[_idx(ctx, cell)] = 1
	ctx.data.stairs.append(stair)


# --- 5. Trilhas ----------------------------------------------------------------

func _build_trails(ctx: GenContext, rng: RandomNumberGenerator) -> void:
	var cfg := ctx.cfg
	var count: int = clampi(rng.randi_range(cfg.trail_count_min, maxi(cfg.trail_count_min, cfg.trail_count_max)), 1, 4)
	var others: Array[int] = [MapTrail.Border.WEST, MapTrail.Border.EAST, MapTrail.Border.NORTH]
	# Embaralha com o RNG local (Array.shuffle usaria o RNG global).
	for i in range(others.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: int = others[i]
		others[i] = others[j]
		others[j] = tmp
	var sides: Array[int] = [MapTrail.Border.SOUTH]
	for i in count - 1:
		sides.append(others[i])
	for side: int in sides:
		_carve_trail(ctx, rng, side)
	# A trilha corta o relevo; limpa de novo os espinhos que sobraram em volta.
	_remove_spikes(ctx, _locked_cells(ctx, true))


func _carve_trail(ctx: GenContext, rng: RandomNumberGenerator, side: int) -> void:
	var cfg := ctx.cfg
	var tw: int = maxi(cfg.trail_width, 1)
	var b := ctx.arena_bounds
	var max_cell := Vector2i(ctx.w - tw, ctx.h - tw)
	var start := Vector2i.ZERO
	var border_cell := Vector2i.ZERO
	var x_pick: int = rng.randi_range(b.position.x + 4, maxi(b.position.x + 4, b.end.x - 4 - tw))
	var z_pick: int = rng.randi_range(b.position.y + 4, maxi(b.position.y + 4, b.end.y - 4 - tw))
	match side:
		MapTrail.Border.SOUTH:
			start = Vector2i(x_pick, max_cell.y)
			border_cell = Vector2i(x_pick, ctx.h - 1)
		MapTrail.Border.NORTH:
			start = Vector2i(x_pick, 0)
			border_cell = start
		MapTrail.Border.WEST:
			start = Vector2i(0, z_pick)
			border_cell = start
		_:
			start = Vector2i(max_cell.x, z_pick)
			border_cell = Vector2i(ctx.w - 1, z_pick)

	var tj: float = cfg.trail_target_jitter
	var target: Vector2 = ctx.data.arena_center + Vector2(rng.randf_range(-tj, tj), rng.randf_range(-tj, tj))
	var pos: Vector2 = Vector2(start) + Vector2(0.5, 0.5)
	var heading: float = (target - pos).angle()
	var turn: float = 0.0
	var path: Array[Vector2i] = []
	var last: Vector2i = start
	var arrived: bool = _trail_step(ctx, path, start, tw)
	var steps: int = 0
	while not arrived and steps < 4000:
		steps += 1
		if steps < 600:
			# Passeio aleatório suave (curvas), puxado para o centro da arena.
			turn = clampf(turn + rng.randf_range(-cfg.trail_wiggle, cfg.trail_wiggle), -cfg.trail_max_turn, cfg.trail_max_turn)
			heading = lerp_angle(heading + turn, (target - pos).angle(), cfg.trail_pull)
		else:
			heading = (target - pos).angle()
		pos += Vector2.from_angle(heading) * 0.5
		pos = pos.clamp(Vector2(0.01, 0.01), Vector2(max_cell) + Vector2(0.99, 0.99))
		var cell := Vector2i(floori(pos.x), floori(pos.y))
		if cell == last:
			continue
		if cell.x != last.x and cell.y != last.y:
			# Andou na diagonal: insere o canto para a trilha ficar conectada (vizinhança 4).
			var corner := Vector2i(cell.x, last.y)
			last = corner
			if _trail_step(ctx, path, corner, tw):
				arrived = true
				break
		last = cell
		arrived = _trail_step(ctx, path, cell, tw)

	var trail := MapTrail.new()
	trail.side = side as MapTrail.Border
	trail.start_cell = border_cell
	var base: int = cfg.arena_base_level
	for cell: Vector2i in path:
		for brush: Vector2i in _brush(cell, tw):
			var i: int = _idx(ctx, brush)
			if ctx.data.arena_mask[i] == 1 or trail.cells.has(brush):
				continue
			ctx.trail[i] = 1
			ctx.data.heights[i] = base
			trail.cells.append(brush)

	# Entrada na arena: a terra avança algumas células e se dissolve com borda irregular.
	var last_brush := _brush(last, tw)
	var in_dir := _arena_direction(ctx, last_brush)
	if in_dir != Vector2i.ZERO:
		var perp := Vector2i(-in_dir.y, in_dir.x)
		var depth: int = rng.randi_range(cfg.trail_arena_depth_min, maxi(cfg.trail_arena_depth_min, cfg.trail_arena_depth_max))
		for k in range(1, depth + 1):
			var keep: float = 1.0 - float(k - 1) / float(depth) * 0.8
			for brush: Vector2i in last_brush:
				var c: Vector2i = brush + in_dir * k
				if rng.randf() < keep:
					_paint_arena_dirt(ctx, trail, c)
				if k > 1 and rng.randf() < keep * 0.35:
					_paint_arena_dirt(ctx, trail, c + perp)
				if k > 1 and rng.randf() < keep * 0.35:
					_paint_arena_dirt(ctx, trail, c - perp)
	ctx.data.trails.append(trail)


func _brush(cell: Vector2i, tw: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for j in tw:
		for i in tw:
			cells.append(cell + Vector2i(i, j))
	return cells


## Adiciona a célula ao caminho; verdadeiro se o pincel já encosta na arena.
func _trail_step(ctx: GenContext, path: Array[Vector2i], cell: Vector2i, tw: int) -> bool:
	path.append(cell)
	for brush: Vector2i in _brush(cell, tw):
		if _is_arena(ctx, brush):
			return true
		for d: Vector2i in NEIGHBORS_4:
			if _is_arena(ctx, brush + d):
				return true
	return false


## Direção (vizinhança 4) mais comum das células do pincel para a arena.
func _arena_direction(ctx: GenContext, cells: Array[Vector2i]) -> Vector2i:
	var best := Vector2i.ZERO
	var best_count: int = 0
	for d: Vector2i in NEIGHBORS_4:
		var n: int = 0
		for cell: Vector2i in cells:
			if _is_arena(ctx, cell + d):
				n += 1
		if n > best_count:
			best_count = n
			best = d
	return best


func _paint_arena_dirt(ctx: GenContext, trail: MapTrail, cell: Vector2i) -> void:
	if not _is_arena(ctx, cell):
		return
	var i: int = _idx(ctx, cell)
	if ctx.trail[i] == 1 or ctx.raised[i] == 1 or ctx.stair[i] == 1:
		return
	if ctx.data.heights[i] != ctx.cfg.arena_base_level:
		return
	ctx.trail[i] = 1
	trail.arena_cells.append(cell)


# --- 6. Chão -------------------------------------------------------------------

func _build_ground(ctx: GenContext, rng: RandomNumberGenerator) -> void:
	var cfg := ctx.cfg
	var noise := _make_noise(rng, cfg.ground_blend_noise_frequency, 2)
	var ground := ctx.data.ground
	var ring: int = cfg.ring_width
	for cz in ctx.h:
		for cx in ctx.w:
			var i: int = cz * ctx.w + cx
			var ad: int = ctx.arena_dist[i]
			var g: int = MapData.Ground.FOREST_GRASS
			if ad == 0:
				g = MapData.Ground.ARENA_GRASS
			elif ad <= ring + 1:
				# Transição irregular entre a grama clara da arena e a da mata.
				var t: float = 1.0 - float(ad - 1) / float(ring + 1)
				if t + noise.get_noise_2d(cx, cz) * cfg.ground_blend_noise_strength > 0.5:
					g = MapData.Ground.ARENA_GRASS
			if ctx.trail[i] == 1:
				g = MapData.Ground.DIRT
			ground[i] = g
	ctx.data.ground = ground

	# Manchas de lajota: soltas e espaçadas, nunca um bloco maciço.
	var patches: int = rng.randi_range(cfg.ruin_patch_count_min, maxi(cfg.ruin_patch_count_min, cfg.ruin_patch_count_max))
	var b := ctx.arena_bounds
	for _p in patches:
		for _attempt in 40:
			var center := Vector2i(rng.randi_range(b.position.x, b.end.x - 1), rng.randi_range(b.position.y, b.end.y - 1))
			if not _ruin_allowed(ctx, center) or ctx.inner_dist[_idx(ctx, center)] < 3:
				continue
			var radius: float = rng.randf_range(cfg.ruin_patch_radius_min, maxf(cfg.ruin_patch_radius_min, cfg.ruin_patch_radius_max))
			for dz in range(-3, 4):
				for dx in range(-3, 4):
					var dist: float = Vector2(dx, dz).length()
					if dist > radius:
						continue
					var cell: Vector2i = center + Vector2i(dx, dz)
					if not _ruin_allowed(ctx, cell):
						continue
					var chance: float = lerpf(cfg.ruin_center_chance, cfg.ruin_edge_chance, dist / radius)
					if rng.randf() < chance and not _completes_ruin_block(ctx, cell):
						ground[_idx(ctx, cell)] = MapData.Ground.RUIN_TILE
			break
	ctx.data.ground = ground


func _ruin_allowed(ctx: GenContext, cell: Vector2i) -> bool:
	if not _is_arena(ctx, cell):
		return false
	var i: int = _idx(ctx, cell)
	return ctx.stair[i] == 0 and ctx.data.ground[i] == MapData.Ground.ARENA_GRASS


## Verdadeiro se pôr lajota aqui fecharia um bloco 2×2 só de lajota.
func _completes_ruin_block(ctx: GenContext, cell: Vector2i) -> bool:
	for corner: Vector2i in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]:
		var all_ruin := true
		for o: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			var c: Vector2i = cell + corner + o
			if c == cell:
				continue
			if not _in_map(ctx, c) or ctx.data.ground[_idx(ctx, c)] != MapData.Ground.RUIN_TILE:
				all_ruin = false
				break
		if all_ruin:
			return true
	return false


# --- 7. Muro -------------------------------------------------------------------

func _build_walls(ctx: GenContext, rng: RandomNumberGenerator) -> void:
	var cfg := ctx.cfg
	var segs: Array[WallSegment] = []
	var index_by_key: Dictionary = {}
	for cz in ctx.h:
		for cx in ctx.w:
			var cell := Vector2i(cx, cz)
			if not _is_arena(ctx, cell):
				continue
			for dir_i in 4:
				var d: Vector2i = NEIGHBORS_4[dir_i]
				if _is_arena(ctx, cell + d):
					continue
				var seg := WallSegment.new()
				seg.cell = cell
				seg.outward = d
				seg.height = cfg.wall_height
				match dir_i:
					0:
						seg.start = Vector2(cx, cz)
						seg.end = Vector2(cx + 1, cz)
					1:
						seg.start = Vector2(cx + 1, cz)
						seg.end = Vector2(cx + 1, cz + 1)
					2:
						seg.start = Vector2(cx, cz + 1)
						seg.end = Vector2(cx + 1, cz + 1)
					_:
						seg.start = Vector2(cx, cz)
						seg.end = Vector2(cx, cz + 1)
				index_by_key[Vector3i(cx, cz, dir_i)] = segs.size()
				segs.append(seg)

	# Falha obrigatória onde a trilha encosta na arena.
	var gaps: int = 0
	for seg: WallSegment in segs:
		var outside: Vector2i = seg.cell + seg.outward
		if _in_map(ctx, outside) and ctx.trail[_idx(ctx, outside)] == 1:
			seg.height = 0.0
			gaps += 1

	# Trechos quebrados: corridas de 1 a 3 segmentos colineares, mais baixos ou com falha.
	var total: int = segs.size()
	var broken_target: int = roundi(cfg.wall_broken_ratio * total)
	var max_gaps: int = floori(cfg.wall_max_gap_ratio * total)
	var broken: int = 0
	var low_height: float = snappedf(cfg.wall_height * cfg.wall_low_height_ratio, WorldScale.PIXEL_SIZE)
	var attempts: int = 0
	while broken < broken_target and attempts < 400 and total > 0:
		attempts += 1
		var first: int = rng.randi_range(0, total - 1)
		if segs[first].height < cfg.wall_height:
			continue
		var run_len: int = rng.randi_range(1, 3)
		var make_gap: bool = rng.randf() < cfg.wall_gap_share and gaps + run_len <= max_gaps
		var dir_i: int = NEIGHBORS_4.find(segs[first].outward)
		var along := Vector2i(-segs[first].outward.y, segs[first].outward.x)
		var cell: Vector2i = segs[first].cell
		for _k in run_len:
			var key := Vector3i(cell.x, cell.y, dir_i)
			if not index_by_key.has(key):
				break
			var seg: WallSegment = segs[int(index_by_key[key])]
			if seg.height < cfg.wall_height:
				break
			seg.height = 0.0 if make_gap else low_height
			broken += 1
			if make_gap:
				gaps += 1
			cell += along
	ctx.data.wall_segments = segs


# --- 8. Monólitos --------------------------------------------------------------

func _place_monoliths(ctx: GenContext, rng: RandomNumberGenerator) -> void:
	var cfg := ctx.cfg
	var data := ctx.data
	var count: int = rng.randi_range(cfg.monolith_count_min, maxi(cfg.monolith_count_min, cfg.monolith_count_max))
	# Só no norte e nos lados de cima da arena: nada alto entre a câmera e a arena.
	var south_limit: float = data.arena_rect.position.y + data.arena_rect.size.y * cfg.monolith_north_fraction
	var candidates: Array[WallSegment] = []
	var gap_points: Array[Vector2] = []
	for seg: WallSegment in data.wall_segments:
		if seg.is_gap():
			gap_points.append(seg.midpoint())
		elif seg.outward != Vector2i(0, 1) and seg.midpoint().y <= south_limit:
			candidates.append(seg)
	if candidates.is_empty():
		return
	var placed: Array[Vector2] = []
	var attempts: int = 0
	var max_dist: float = minf(cfg.monolith_max_arena_distance, float(cfg.ring_width)) - 0.05
	while placed.size() < count and attempts < 400:
		attempts += 1
		var seg: WallSegment = candidates[rng.randi_range(0, candidates.size() - 1)]
		var along: Vector2 = (seg.end - seg.start).normalized()
		var pos: Vector2 = seg.midpoint() + Vector2(seg.outward) * rng.randf_range(cfg.wall_thickness + 0.45, max_dist - 0.05) \
				+ along * rng.randf_range(-0.3, 0.3)
		var cell := Vector2i(floori(pos.x), floori(pos.y))
		if not _in_map(ctx, cell) or _is_arena(ctx, cell):
			continue
		var i: int = _idx(ctx, cell)
		if ctx.trail[i] == 1 or ctx.south_strip[i] == 1 or ctx.occupied[i] == 1:
			continue
		if data.distance_to_arena(pos) > max_dist:
			continue
		var ok := true
		for g: Vector2 in gap_points:
			if pos.distance_to(g) < cfg.monolith_gap_clearance:
				ok = false
				break
		for other: Vector2 in placed:
			if pos.distance_to(other) < cfg.monolith_min_spacing:
				ok = false
				break
		if not ok:
			continue
		placed.append(pos)
		ctx.occupied[i] = 1
		data.objects.append(MapObject.new(MapObject.ObjectKind.MONOLITH, pos, rng.randi_range(0, MapObject.variant_count(MapObject.ObjectKind.MONOLITH) - 1)))


# --- 9. Pedras 3D --------------------------------------------------------------

func _place_rocks(ctx: GenContext, rng: RandomNumberGenerator) -> void:
	var cfg := ctx.cfg
	var variants: int = MapObject.variant_count(MapObject.ObjectKind.ROCK)
	for cz in ctx.h:
		for cx in ctx.w:
			var i: int = cz * ctx.w + cx
			if ctx.arena_dist[i] <= cfg.ring_width or ctx.trail[i] == 1 or ctx.occupied[i] == 1:
				continue
			if rng.randf() >= cfg.rock_density:
				continue
			var pos := Vector2(cx + 0.5 + rng.randf_range(-0.06, 0.06), cz + 0.5 + rng.randf_range(-0.06, 0.06))
			ctx.occupied[i] = 1
			ctx.data.objects.append(MapObject.new(MapObject.ObjectKind.ROCK, pos, rng.randi_range(0, variants - 1)))


# --- 10. Vegetação -------------------------------------------------------------

func _place_vegetation(ctx: GenContext, rng: RandomNumberGenerator) -> void:
	var cfg := ctx.cfg
	var data := ctx.data
	var grove := _make_noise(rng, cfg.forest_density_noise_frequency, 2)
	var tall_grid: Dictionary = {}
	var bush_grid: Dictionary = {}
	for obj: MapObject in data.objects:
		_grid_add(tall_grid, obj.position)
		_grid_add(bush_grid, obj.position)
	var center_z: float = data.arena_center.y
	var center_x: float = data.arena_center.x
	for cz in ctx.h:
		for cx in ctx.w:
			var i: int = cz * ctx.w + cx
			var cell := Vector2i(cx, cz)
			if data.arena_mask[i] == 1:
				# Dentro da arena só capim e flores baixos, em densidade baixa.
				if ctx.stair[i] == 1 or ctx.trail[i] == 1:
					continue
				if rng.randf() < cfg.arena_detail_density:
					var p := _jitter_in_cell(rng, cell, 0.15)
					if rng.randf() < cfg.arena_grass_tuft_share:
						data.objects.append(MapObject.new(MapObject.ObjectKind.GRASS_TUFT, p, rng.randi_range(0, 1)))
					else:
						data.objects.append(MapObject.new(MapObject.ObjectKind.FLOWER, p, rng.randi_range(0, 2)))
				continue
			if ctx.trail[i] == 1 or ctx.occupied[i] == 1:
				continue
			var in_ring: bool = ctx.arena_dist[i] <= cfg.ring_width
			var south_depth: int = cz - ctx.south_most[cx] if ctx.south_strip[i] == 1 else -1
			# Na frente de uma face de degrau virada para a câmera: sem nada alto (o degrau aparece).
			var step_front: int = _visible_step_distance(ctx, cx, cz, center_x)
			var low_only: bool = in_ring or step_front > 0 or (south_depth >= 0 and south_depth <= cfg.south_low_depth)
			var no_big: bool = low_only or _near_south_strip(ctx, cx, cz)
			var density: float = clampf(1.0 + grove.get_noise_2d(cx, cz) * cfg.forest_density_variation, 0.55, 1.5)

			if not no_big and rng.randf() < cfg.tree_big_density * density:
				var p := _jitter_in_cell(rng, cell, 0.2)
				if _grid_clear(tall_grid, p, cfg.tree_spacing):
					_grid_add(tall_grid, p)
					data.objects.append(MapObject.new(MapObject.ObjectKind.TREE_BIG, p, rng.randi_range(0, 2)))
			if not low_only and rng.randf() < cfg.tree_small_density * density:
				var p := _jitter_in_cell(rng, cell, 0.2)
				if _grid_clear(tall_grid, p, cfg.tree_spacing * 0.85):
					_grid_add(tall_grid, p)
					data.objects.append(MapObject.new(MapObject.ObjectKind.TREE_SMALL, p, rng.randi_range(0, 1)))
			# No anel, arbusto só na metade de cima (não tampa o muro do lado da câmera);
			# colado numa face de degrau, nenhum.
			var bush_ok: bool = step_front != 1 and (not in_ring or cz < center_z)
			if bush_ok and rng.randf() < cfg.bush_density * (0.5 + 0.5 * density):
				var p := _jitter_in_cell(rng, cell, 0.2)
				if _grid_clear(bush_grid, p, cfg.bush_spacing) and _grid_clear(tall_grid, p, 0.5):
					_grid_add(bush_grid, p)
					data.objects.append(MapObject.new(MapObject.ObjectKind.BUSH, p, rng.randi_range(0, 2)))
			if rng.randf() < cfg.grass_tuft_density:
				var p := _jitter_in_cell(rng, cell, 0.12)
				var light: bool = data.ground[i] == MapData.Ground.ARENA_GRASS
				var variant: int = rng.randi_range(0, 1) if light else 2
				data.objects.append(MapObject.new(MapObject.ObjectKind.GRASS_TUFT, p, variant))
			if rng.randf() < cfg.flower_density:
				var p := _jitter_in_cell(rng, cell, 0.12)
				data.objects.append(MapObject.new(MapObject.ObjectKind.FLOWER, p, rng.randi_range(0, 2)))


## 1 ou 2 se a célula está colada (ou a 2 células) na frente de uma face de degrau que a
## câmera vê (virada para o sul ou para o centro da tela); 0 se não.
func _visible_step_distance(ctx: GenContext, cx: int, cz: int, center_x: float) -> int:
	var heights := ctx.data.heights
	var hc: int = heights[cz * ctx.w + cx]
	for k in range(1, 3):
		if cz - k >= 0 and heights[(cz - k) * ctx.w + cx] > hc:
			return k
		var sx: int = cx - k if cx + 0.5 < center_x else cx + k
		if sx >= 0 and sx < ctx.w and heights[cz * ctx.w + sx] > hc:
			return k
	return 0


## Perto (2 colunas) da faixa sul: sem árvore grande, para não tampar a borda de baixo.
func _near_south_strip(ctx: GenContext, cx: int, cz: int) -> bool:
	for dx in range(-2, 3):
		var x: int = cx + dx
		if x >= 0 and x < ctx.w and ctx.south_strip[cz * ctx.w + x] == 1:
			return true
	return false


func _grid_key(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / GRID_BUCKET), floori(pos.y / GRID_BUCKET))


func _grid_add(grid: Dictionary, pos: Vector2) -> void:
	var key := _grid_key(pos)
	if not grid.has(key):
		grid[key] = []
	var bucket: Array = grid[key]
	bucket.append(pos)


func _grid_clear(grid: Dictionary, pos: Vector2, min_dist: float) -> bool:
	var key := _grid_key(pos)
	var min_sq: float = min_dist * min_dist
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var k: Vector2i = key + Vector2i(dx, dz)
			if not grid.has(k):
				continue
			for other: Vector2 in grid[k]:
				if pos.distance_squared_to(other) < min_sq:
					return false
	return true
