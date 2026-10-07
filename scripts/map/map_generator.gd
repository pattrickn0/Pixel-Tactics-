class_name MapGenerator
extends RefCounted
## Gera um MapData a partir da seed.
## Função pura: depende só de map_seed e da config (sem arquivos, assets, tempo, OS,
## cena nem RNG global). Primeiro monta o layout fixo do anfiteatro (sem RNG); depois os
## passos procedurais rodam sempre na mesma ordem, cada um com o próprio RNG tirado do RNG
## mestre, para mexer num passo não embaralhar os outros.

const NEIGHBORS_4: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
## Tamanho do balde da grade espacial usada no espaçamento da vegetação.
const GRID_BUCKET: float = 2.0

var config: MapGenConfig


## Estado intermediário de uma geração (descartado no fim).
class GenContext extends RefCounted:
	var data: MapData
	var cfg: MapGenConfig
	var w: int = 0
	var h: int = 0
	var arena: Rect2i = Rect2i()
	## Arena + terraços das reservas + anel 1 dos lados curtos.
	var inner: Rect2i = Rect2i()
	## Anfiteatro inteiro (inner + anel 2): tudo que é construído.
	var outer: Rect2i = Rect2i()
	var floor_level: int = 0
	var bench_level: int = 0
	var ring2_level: int = 0
	## Faixa (em z) das escadas de entrada: primeira linha.
	var entrance_z: int = 0
	## Distância (Chebyshev, em células) até o anfiteatro; 0 dentro dele.
	var forest_dist: PackedInt32Array = PackedInt32Array()
	var stair: PackedByteArray = PackedByteArray()
	## Chegadas das escadas (embaixo e em cima): sem decoração.
	var landing: PackedByteArray = PackedByteArray()
	## 0 = não é trilha, 1 = trilha de terra, 2 = trilha de pedra.
	var trail: PackedByteArray = PackedByteArray()
	var occupied: PackedByteArray = PackedByteArray()
	var arena_dirt: PackedByteArray = PackedByteArray()


func _init(p_config: MapGenConfig = null) -> void:
	config = p_config if p_config != null else MapGenConfig.new()


func generate(map_seed: int) -> MapData:
	var master := RandomNumberGenerator.new()
	master.seed = map_seed
	var ctx := _new_context(map_seed)
	_build_fixed_layout(ctx)
	_build_arena_relief(ctx, _sub_rng(master))
	_build_arena_dirt(ctx, _sub_rng(master))
	_build_forest_relief(ctx, _sub_rng(master))
	_build_trails(ctx, _sub_rng(master))
	_build_ground(ctx, _sub_rng(master))
	_place_monoliths(ctx, _sub_rng(master))
	_place_rocks(ctx, _sub_rng(master))
	_place_vegetation(ctx, _sub_rng(master))
	ctx.data.invalidate_caches()
	return ctx.data


# --- Contexto e utilidades -------------------------------------------------

func _new_context(map_seed: int) -> GenContext:
	var cfg := config
	var ctx := GenContext.new()
	ctx.cfg = cfg
	var aw: int = maxi(cfg.arena_size.x, 8)
	var ad: int = maxi(cfg.arena_size.y, 8)
	var r1: int = maxi(cfg.ring1_width, 1)
	var r2: int = maxi(cfg.ring2_width, 1)
	var bd: int = maxi(cfg.bench_depth, 1)
	# O mapa precisa caber o anfiteatro e pelo menos 2 células de floresta em volta.
	ctx.w = maxi(cfg.map_size.x, aw + 2 * (r1 + r2) + 4)
	ctx.h = maxi(cfg.map_size.y, ad + 2 * (bd + r2) + 4)
	ctx.arena = Rect2i(floori((ctx.w - aw) / 2.0), floori((ctx.h - ad) / 2.0), aw, ad)
	ctx.inner = Rect2i(ctx.arena.position - Vector2i(r1, bd), ctx.arena.size + Vector2i(2 * r1, 2 * bd))
	ctx.outer = ctx.inner.grow(r2)
	ctx.floor_level = 1
	ctx.bench_level = 2
	ctx.ring2_level = 3
	var n: int = ctx.w * ctx.h
	var data := MapData.new()
	data.map_seed = map_seed
	data.size = Vector2i(ctx.w, ctx.h)
	data.arena_floor_level = ctx.floor_level
	data.relief_symmetry = cfg.relief_symmetry
	data.heights = _filled_ints(n, ctx.ring2_level)
	data.ground = _filled_bytes(n, MapData.Ground.FOREST_GRASS)
	data.arena_mask = _filled_bytes(n, 0)
	data.built_mask = _filled_bytes(n, 0)
	ctx.data = data
	ctx.forest_dist = _filled_ints(n, 0)
	ctx.stair = _filled_bytes(n, 0)
	ctx.landing = _filled_bytes(n, 0)
	ctx.trail = _filled_bytes(n, 0)
	ctx.occupied = _filled_bytes(n, 0)
	ctx.arena_dirt = _filled_bytes(n, 0)
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


func _jitter_in_cell(rng: RandomNumberGenerator, cell: Vector2i, margin: float) -> Vector2:
	return Vector2(cell.x + rng.randf_range(margin, 1.0 - margin), cell.y + rng.randf_range(margin, 1.0 - margin))


## Célula correspondente pela rotação de 180° em torno do centro da arena.
func _rotate_cell(ctx: GenContext, cell: Vector2i) -> Vector2i:
	return ctx.arena.position * 2 + ctx.arena.size - Vector2i.ONE - cell


## Retângulo correspondente pela rotação de 180° em torno do centro da arena.
func _rotate_rect(ctx: GenContext, rect: Rect2) -> Rect2:
	var c2: Vector2 = Vector2(ctx.arena.position * 2 + ctx.arena.size)
	return Rect2(c2 - rect.end, rect.size)


# --- 1. Layout fixo (sem RNG) ------------------------------------------------------

func _build_fixed_layout(ctx: GenContext) -> void:
	var data := ctx.data
	data.arena_rect = Rect2(14, 15, 16, 14)
	data.arena_center = Vector2(22.0, 22.0)

	# Anfiteatro octogonal canônico proporcional 1:1 à imagem de referência:
	for cz in ctx.h:
		for cx in ctx.w:
			var cell := Vector2i(cx, cz)
			var i: int = _idx(ctx, cell)
			var dx: float = absf(cx + 0.5 - 22.0)
			var dz: float = absf(cz + 0.5 - 22.0)

			# 1. Arena central octogonal:
			var in_arena: bool = dx < 7.8 and dz < 7.2 and (dx + dz) < 10.6
			# 2. Tier 1 (Terrace com largura uniforme de ~2 células em todos os 8 lados):
			var in_tier1: bool = dx < 10.4 and dz < 9.6 and (dx + dz) < 14.0
			# 3. Tier 2 (Apenas ao norte e lados, cz <= 23):
			var in_tier2: bool = (cz <= 23) and (dx < 13.0 and dz < 12.0 and (dx + dz) < 17.5)

			if in_arena:
				data.built_mask[i] = 1
				data.arena_mask[i] = 1
				data.heights[i] = ctx.floor_level
			elif in_tier1:
				data.built_mask[i] = 1
				data.arena_mask[i] = 0
				data.heights[i] = ctx.bench_level
			elif in_tier2:
				data.built_mask[i] = 1
				data.arena_mask[i] = 0
				data.heights[i] = ctx.ring2_level
			else:
				data.built_mask[i] = 0
				data.arena_mask[i] = 0
				if cz >= 24:
					# Primeiro plano (Sul): o chão cai para o nível 0, revelando o muro frontal de pedra!
					data.heights[i] = 0
				else:
					var back_elevation: int = 1 if (cz < 7 and (dx + dz) > 16.0) else 0
					data.heights[i] = ctx.ring2_level + back_elevation

			var dist_out: int = 0
			if not in_tier1 and not in_tier2:
				dist_out = maxi(floori(dx - 12.5), floori(dz - 11.0))
				dist_out = maxi(dist_out, 1)
			ctx.forest_dist[i] = dist_out

	# Reservas (sul e norte)
	var south := MapBench.new()
	south.team = 0
	south.level = ctx.bench_level
	south.terrace_rect = Rect2(15, 27, 14, 2)
	south.rect = Rect2(15.5, 27.2, 13.0, 1.6)
	var north := MapBench.new()
	north.team = 1
	north.level = ctx.bench_level
	north.terrace_rect = Rect2(15, 14, 14, 2)
	north.rect = Rect2(15.5, 14.2, 13.0, 1.6)
	data.benches.append(south)
	data.benches.append(north)

	# 1. Escadas Sudoeste na diagonal (entrada do anfiteatro pelo calçamento)
	var sw_stair := _make_stair(ctx, Vector2i(14, 30), Vector2i(1, 0), Vector2i(0, -1), 3, 2, 0)
	_register_stair(ctx, sw_stair)

	# 2. Escada Nordeste (arena -> terraço/trilha da floresta)
	var ne_stair := _make_stair(ctx, Vector2i(27, 17), Vector2i(1, 0), Vector2i(0, -1), 2, 1, ctx.floor_level)
	_register_stair(ctx, ne_stair)

	# 3. Escada Noroeste (arena -> terraço noroeste)
	var nw_stair := _make_stair(ctx, Vector2i(16, 17), Vector2i(1, 0), Vector2i(0, -1), 2, 1, ctx.floor_level)
	_register_stair(ctx, nw_stair)


## Escada de width × levels células: origin é a célula de baixo num canto, width_dir
## anda na largura e up na subida. A célula k (a partir de baixo) fica no nível base + k.
func _make_stair(ctx: GenContext, origin: Vector2i, width_dir: Vector2i, up: Vector2i, width: int, levels: int, base: int) -> MapStair:
	var stair := MapStair.new()
	stair.up_direction = up
	stair.base_level = base
	stair.levels = levels
	for k in levels:
		for a in width:
			var cell: Vector2i = origin + width_dir * a + up * k
			stair.cells.append(cell)
			ctx.data.heights[_idx(ctx, cell)] = base + k
	return stair


func _register_stair(ctx: GenContext, stair: MapStair) -> void:
	ctx.data.stairs.append(stair)
	for cell: Vector2i in stair.cells:
		ctx.stair[_idx(ctx, cell)] = 1
	for list: Array[Vector2i] in [stair.arrival_cells(), stair.landing_cells()]:
		for cell: Vector2i in list:
			if _in_map(ctx, cell):
				ctx.landing[_idx(ctx, cell)] = 1


# --- 2. Relevo da arena ------------------------------------------------------------

func _build_arena_relief(ctx: GenContext, _rng: RandomNumberGenerator) -> void:
	# Arena 100% plana: nenhuma altura/degrau no meio da arena.
	for cz in ctx.h:
		for cx in ctx.w:
			var i: int = _idx(ctx, Vector2i(cx, cz))
			if ctx.data.arena_mask[i] == 1:
				ctx.data.heights[i] = ctx.floor_level
	ctx.data.relief_mode = MapData.ReliefMode.CENTRAL
	ctx.data.relief_peak = 0


func _build_arena_dirt(ctx: GenContext, _rng: RandomNumberGenerator) -> void:
	for cz in ctx.h:
		for cx in ctx.w:
			var i: int = _idx(ctx, Vector2i(cx, cz))
			if ctx.data.arena_mask[i] != 1:
				continue
			var dx: float = cx + 0.5 - 22.0
			var dz: float = cz + 0.5 - 22.0
			var dist: float = sqrt(dx * dx + dz * dz)
			var angle: float = atan2(dz, dx)
			var rad: float = 4.8 + sin(angle * 3.0 + 0.4) * 0.7 + cos(angle * 5.0) * 0.4 + sin(dx * 2.5) * 0.3
			if dist < rad:
				var is_island: bool = (dist > 1.3 and dist < 2.3 and posmod(cx * 7 + cz * 13, 8) == 0)
				if not is_island:
					ctx.arena_dirt[i] = 1


# --- 4. Relevo da floresta ------------------------------------------------------------

func _build_forest_relief(ctx: GenContext, rng: RandomNumberGenerator) -> void:
	var cfg := ctx.cfg
	var noise := _make_noise(rng, cfg.forest_noise_frequency, 3)
	var top: int = maxi(cfg.forest_relief_max, 0)
	for cz in ctx.h:
		for cx in ctx.w:
			var i: int = cz * ctx.w + cx
			var dist: int = ctx.forest_dist[i]
			if dist == 0 or cz >= 24:
				continue
			var far: float = clampf(float(dist - 1) / maxf(cfg.forest_distance_falloff, 1.0), 0.0, 1.0)
			var v: float = noise.get_noise_2d(cx, cz) * cfg.forest_noise_amplitude + far * cfg.forest_distance_bias
			ctx.data.heights[i] = ctx.ring2_level + clampi(floori(v + 0.5), 0, top)
	_clean_forest(ctx)


## Floresta em terraços: degrau de no máximo 1 nível entre vizinhas e cada nível passando na
## abertura 3×3. Só baixa células (nunca abaixo do anel 2); anfiteatro e trilhas ficam.
func _clean_forest(ctx: GenContext) -> void:
	var heights := ctx.data.heights
	var top: int = ctx.ring2_level + maxi(ctx.cfg.forest_relief_max, 0)
	for _round in 8:
		var changed := false
		# Degrau máximo de 1 nível (repete até estabilizar).
		var moving := true
		while moving:
			moving = false
			for cz in ctx.h:
				for cx in ctx.w:
					var i: int = cz * ctx.w + cx
					if ctx.forest_dist[i] == 0 or ctx.trail[i] != 0 or cz >= 24:
						continue
					var lowest: int = heights[i]
					for d: Vector2i in NEIGHBORS_4:
						var nb := Vector2i(cx, cz) + d
						if _in_map(ctx, nb):
							lowest = mini(lowest, heights[_idx(ctx, nb)] + 1)
					var lowered: int = maxi(lowest, ctx.ring2_level)
					if lowered < heights[i]:
						heights[i] = lowered
						moving = true
						changed = true
		# Abertura 3×3 de cada nível, de baixo para cima.
		for k in range(ctx.ring2_level + 1, top + 1):
			var region: Dictionary = {}
			for cz in ctx.h:
				for cx in ctx.w:
					var i: int = cz * ctx.w + cx
					if ctx.forest_dist[i] > 0 and ctx.trail[i] == 0 and heights[i] >= k:
						region[Vector2i(cx, cz)] = true
			var kept: Dictionary = {}
			for cell: Vector2i in open_3x3(region):
				kept[cell] = true
			for cell: Vector2i in region:
				if not kept.has(cell):
					heights[_idx(ctx, cell)] = k - 1
					changed = true
		if not changed:
			break
	ctx.data.heights = heights


## Abertura 3×3: uma célula fica só se algum quadrado 3×3 que a contém está inteiro no
## conjunto. Tira pontas e tiras com menos de 3 células de largura. Função pura; a ordem
## do resultado segue a ordem de inserção do conjunto (determinística).
static func open_3x3(cells: Dictionary) -> Array[Vector2i]:
	var kept: Dictionary = {}
	for corner: Vector2i in cells:
		var full := true
		for dz in 3:
			for dx in 3:
				if not cells.has(corner + Vector2i(dx, dz)):
					full = false
					break
			if not full:
				break
		if not full:
			continue
		for dz in 3:
			for dx in 3:
				kept[corner + Vector2i(dx, dz)] = true
	var result: Array[Vector2i] = []
	for cell: Vector2i in cells:
		if kept.has(cell):
			result.append(cell)
	return result


# --- 5. Trilhas ----------------------------------------------------------------

func _build_trails(ctx: GenContext, _rng: RandomNumberGenerator) -> void:
	var trail_sw := MapTrail.new()
	trail_sw.side = MapTrail.Border.WEST
	trail_sw.stone = true
	trail_sw.start_cell = Vector2i(15, 31)
	trail_sw.border_cell = Vector2i(4, 42)
	ctx.data.trails.append(trail_sw)

	# Calçamento sudoeste: entra pelo canto inferior-esquerdo conectando à escada frontal
	for step in 35:
		var t: float = float(step) / 34.0
		var pt: Vector2 = Vector2(4.0, 42.0).lerp(Vector2(15.5, 31.0), t)
		for ox in [-1, 0, 1]:
			for oz in [-1, 0, 1]:
				var cell := Vector2i(floori(pt.x) + ox, floori(pt.y) + oz)
				if _in_map(ctx, cell):
					var idx: int = _idx(ctx, cell)
					if ctx.data.arena_mask[idx] == 0 and ctx.stair[idx] == 0:
						ctx.trail[idx] = 2
						ctx.data.ground[idx] = MapData.Ground.STONE_PATH
						ctx.data.heights[idx] = 0

	var trail_ne := MapTrail.new()
	trail_ne.side = MapTrail.Border.EAST
	trail_ne.stone = true
	trail_ne.start_cell = Vector2i(27, 16)
	trail_ne.border_cell = Vector2i(36, 1)
	ctx.data.trails.append(trail_ne)

	# Calçamento nordeste: sai da escada nordeste para a floresta
	for step in 35:
		var t: float = float(step) / 34.0
		var pt: Vector2 = Vector2(27.5, 16.0).lerp(Vector2(36.0, 1.0), t)
		for ox in [-1, 0, 1]:
			for oz in [-1, 0, 1]:
				var cell := Vector2i(floori(pt.x) + ox, floori(pt.y) + oz)
				if _in_map(ctx, cell):
					var idx: int = _idx(ctx, cell)
					if ctx.data.arena_mask[idx] == 0 and ctx.stair[idx] == 0:
						ctx.trail[idx] = 2
						ctx.data.ground[idx] = MapData.Ground.STONE_PATH


## Passeio aleatório suave (curvas) da célula start até a borda do mapa, puxado para
## target, sempre no corredor de floresta do lado (o pincel nunca entra no anfiteatro).
## Devolve as células de origem do pincel, conectadas na vizinhança 4.
func _walk_trail(ctx: GenContext, rng: RandomNumberGenerator, start: Vector2i, target: Vector2, west: bool) -> Array[Vector2i]:
	var cfg := ctx.cfg
	var tw: int = maxi(cfg.trail_width, 1)
	var lo := Vector2i(0 if west else ctx.outer.end.x, 0)
	var hi := Vector2i(ctx.outer.position.x - tw if west else ctx.w - tw, ctx.h - tw)
	var pos: Vector2 = Vector2(start) + Vector2(0.5, 0.5)
	var heading: float = (target - pos).angle()
	var turn: float = 0.0
	var path: Array[Vector2i] = [start]
	var last: Vector2i = start
	var steps: int = 0
	while not _at_border(ctx, last, tw) and steps < 4000:
		steps += 1
		if steps < 600:
			turn = clampf(turn + rng.randf_range(-cfg.trail_wiggle, cfg.trail_wiggle), -cfg.trail_max_turn, cfg.trail_max_turn)
			heading = lerp_angle(heading + turn, (target - pos).angle(), cfg.trail_pull)
		else:
			heading = (target - pos).angle()
		pos += Vector2.from_angle(heading) * 0.5
		pos = pos.clamp(Vector2(lo) + Vector2(0.01, 0.01), Vector2(hi) + Vector2(0.99, 0.99))
		var cell := Vector2i(floori(pos.x), floori(pos.y))
		if cell == last:
			continue
		if cell.x != last.x and cell.y != last.y:
			# Andou na diagonal: insere o canto para a trilha ficar conectada (vizinhança 4).
			path.append(Vector2i(cell.x, last.y))
		path.append(cell)
		last = cell
	return path


## Célula do pincel que fica na borda do mapa.
func _border_cell_of(ctx: GenContext, cell: Vector2i, tw: int) -> Vector2i:
	for dz in tw:
		for dx in tw:
			var c: Vector2i = cell + Vector2i(dx, dz)
			if c.x == 0 or c.y == 0 or c.x == ctx.w - 1 or c.y == ctx.h - 1:
				return c
	return cell


func _at_border(ctx: GenContext, cell: Vector2i, tw: int) -> bool:
	return cell.x <= 0 or cell.y <= 0 or cell.x >= ctx.w - tw or cell.y >= ctx.h - tw


func _paint_trail(ctx: GenContext, trail: MapTrail, path: Array[Vector2i]) -> void:
	var tw: int = maxi(ctx.cfg.trail_width, 1)
	for cell: Vector2i in path:
		for dz in tw:
			for dx in tw:
				var c: Vector2i = cell + Vector2i(dx, dz)
				var i: int = _idx(ctx, c)
				if ctx.trail[i] != 0:
					continue
				ctx.trail[i] = 2 if trail.stone else 1
				ctx.data.heights[i] = ctx.ring2_level
				trail.cells.append(c)


# --- 6. Chão -------------------------------------------------------------------

func _build_ground(ctx: GenContext, _rng: RandomNumberGenerator) -> void:
	var ground := ctx.data.ground
	for cz in ctx.h:
		for cx in ctx.w:
			var i: int = cz * ctx.w + cx
			var g: int = MapData.Ground.FOREST_GRASS
			if ctx.data.arena_mask[i] == 1:
				g = MapData.Ground.DIRT if ctx.arena_dirt[i] == 1 else MapData.Ground.ARENA_GRASS
			elif ctx.data.built_mask[i] == 1:
				g = MapData.Ground.ARENA_GRASS
			if ctx.trail[i] == 2:
				g = MapData.Ground.STONE_PATH
			ground[i] = g
	ctx.data.ground = ground


# --- 7. Monólitos --------------------------------------------------------------

func _place_monoliths(ctx: GenContext, _rng: RandomNumberGenerator) -> void:
	# Monólitos nas bordas da floresta profunda (fora da visão do anfiteatro)
	var pos1 := Vector2(2.5, 2.5)
	var pos2 := Vector2(41.5, 2.5)
	ctx.data.objects.append(MapObject.new(MapObject.ObjectKind.MONOLITH, pos1, 0))
	ctx.data.objects.append(MapObject.new(MapObject.ObjectKind.MONOLITH, pos2, 1))


# --- 8. Pedras 3D --------------------------------------------------------------

func _place_rocks(ctx: GenContext, rng: RandomNumberGenerator) -> void:
	var cfg := ctx.cfg
	var variants: int = MapObject.variant_count(MapObject.ObjectKind.ROCK)
	for cz in ctx.h:
		for cx in ctx.w:
			var i: int = cz * ctx.w + cx
			if ctx.forest_dist[i] == 0 or ctx.trail[i] != 0 or ctx.occupied[i] == 1 or ctx.landing[i] == 1:
				continue
			if rng.randf() >= cfg.rock_density:
				continue
			var pos := Vector2(cx + 0.5 + rng.randf_range(-0.06, 0.06), cz + 0.5 + rng.randf_range(-0.06, 0.06))
			ctx.occupied[i] = 1
			ctx.data.objects.append(MapObject.new(MapObject.ObjectKind.ROCK, pos, rng.randi_range(0, variants - 1)))


# --- 9. Vegetação -------------------------------------------------------------

## Zonas: arena só capim e flor; área útil das reservas, nada; resto dos anéis, só
## vegetação baixa; floresta, tudo (nada alto colado no anel 2).
func _place_vegetation(ctx: GenContext, rng: RandomNumberGenerator) -> void:
	var cfg := ctx.cfg
	var data := ctx.data
	var grove := _make_noise(rng, cfg.forest_density_noise_frequency, 2)
	var tall_grid: Dictionary = {}
	var bush_grid: Dictionary = {}
	for obj: MapObject in data.objects:
		_grid_add(tall_grid, obj.position)
		_grid_add(bush_grid, obj.position)

	# 1. Cogumelos coloridos canônicos fiéis à imagem de referência (azuis e rosas)
	var mushroom_spots: Array = [
		# Canto inferior-direito na base do muro frontal (destaque na referência)
		{"pos": Vector2(26.8, 30.6), "v": 1}, # azul
		{"pos": Vector2(27.5, 31.2), "v": 0}, # rosa
		{"pos": Vector2(28.2, 30.4), "v": 1}, # azul
		{"pos": Vector2(29.0, 31.0), "v": 0}, # rosa
		{"pos": Vector2(29.8, 29.8), "v": 3}, # laranja
		{"pos": Vector2(30.5, 29.2), "v": 1}, # azul
		# Perto da entrada sudoeste (ao lado do calçamento)
		{"pos": Vector2(11.8, 32.5), "v": 1}, # azul
		{"pos": Vector2(12.5, 33.2), "v": 0}, # rosa
		{"pos": Vector2(11.2, 33.8), "v": 1}, # azul
		# Perto dos troncos nos terraços
		{"pos": Vector2(28.5, 25.8), "v": 1},
		{"pos": Vector2(13.8, 24.8), "v": 0},
	]
	for m_def: Dictionary in mushroom_spots:
		data.objects.append(MapObject.new(MapObject.ObjectKind.MUSHROOM, m_def["pos"], m_def["v"]))

	# 2. Árvores de primeiro plano apenas nos cantos (emolduram a câmera sem tapar o muro frontal)
	var fg_trees: Array = [
		Vector2(2.5, 37.0), Vector2(4.5, 38.5), Vector2(6.5, 36.5), Vector2(7.5, 39.5),
		Vector2(34.5, 36.5), Vector2(36.5, 34.5), Vector2(37.5, 37.0), Vector2(39.5, 35.5), Vector2(41.5, 33.5),
	]
	for p: Vector2 in fg_trees:
		data.objects.append(MapObject.new(MapObject.ObjectKind.TREE_BIG, p, rng.randi_range(0, 2)))
		_grid_add(tall_grid, p)

	# 3. Arbustos baixos na base do muro frontal
	var fg_bushes: Array = [
		Vector2(18.5, 32.2), Vector2(21.0, 32.5), Vector2(23.5, 32.3), Vector2(25.5, 31.8),
	]
	for p: Vector2 in fg_bushes:
		data.objects.append(MapObject.new(MapObject.ObjectKind.BUSH, p, rng.randi_range(0, 2)))
		_grid_add(bush_grid, p)

	var outer_row: Rect2i = ctx.outer.grow(-1)
	for cz in ctx.h:
		for cx in ctx.w:
			var i: int = cz * ctx.w + cx
			var cell := Vector2i(cx, cz)
			if ctx.stair[i] == 1 or ctx.landing[i] == 1 or ctx.trail[i] != 0 or ctx.occupied[i] == 1:
				continue
			if ctx.data.arena_mask[i] == 1:
				# Arena: pequenos botões de flores e relva discreta
				if rng.randf() < 0.035:
					var p := _jitter_in_cell(rng, cell, 0.18)
					if rng.randf() < 0.55:
						data.objects.append(MapObject.new(MapObject.ObjectKind.GRASS_TUFT, p, rng.randi_range(0, 1)))
					else:
						data.objects.append(MapObject.new(MapObject.ObjectKind.FLOWER, p, rng.randi_range(0, 2)))
				continue
			if ctx.data.built_mask[i] == 1:
				_place_ring_detail(ctx, rng, cell, bush_grid, not outer_row.has_point(cell))
				continue
			var in_front_corridor: bool = (cz >= 26 and cx >= 10 and cx <= 34)
			var no_tall: bool = in_front_corridor
			var density: float = clampf(1.0 + grove.get_noise_2d(cx, cz) * cfg.forest_density_variation, 0.7, 1.6)
			if not no_tall and rng.randf() < cfg.tree_big_density * density:
				var p := _jitter_in_cell(rng, cell, 0.2)
				if _grid_clear(tall_grid, p, cfg.tree_spacing):
					_grid_add(tall_grid, p)
					data.objects.append(MapObject.new(MapObject.ObjectKind.TREE_BIG, p, rng.randi_range(0, 2)))
			if not no_tall and rng.randf() < cfg.tree_small_density * density:
				var p := _jitter_in_cell(rng, cell, 0.2)
				if _grid_clear(tall_grid, p, cfg.tree_spacing * 0.85):
					_grid_add(tall_grid, p)
					data.objects.append(MapObject.new(MapObject.ObjectKind.TREE_SMALL, p, rng.randi_range(0, 1)))
			if rng.randf() < cfg.bush_density * (0.5 + 0.5 * density):
				var p := _jitter_in_cell(rng, cell, 0.2)
				if _grid_clear(bush_grid, p, cfg.bush_spacing) and _grid_clear(tall_grid, p, 0.5):
					_grid_add(bush_grid, p)
					data.objects.append(MapObject.new(MapObject.ObjectKind.BUSH, p, rng.randi_range(0, 2)))
			if rng.randf() < cfg.grass_tuft_density:
				data.objects.append(MapObject.new(MapObject.ObjectKind.GRASS_TUFT, _jitter_in_cell(rng, cell, 0.12), 2))
			if rng.randf() < cfg.flower_density:
				data.objects.append(MapObject.new(MapObject.ObjectKind.FLOWER, _jitter_in_cell(rng, cell, 0.12), rng.randi_range(0, 2)))


## Anéis e terraço das reservas: capim e flor fora da área útil; arbusto só na fileira de
## fora do anel 2 (não tampa a reserva nem a arena atrás dele).
func _place_ring_detail(ctx: GenContext, rng: RandomNumberGenerator, cell: Vector2i, bush_grid: Dictionary, outer_row: bool) -> void:
	var cfg := ctx.cfg
	var data := ctx.data
	if rng.randf() < cfg.ring_detail_density:
		var p := _jitter_in_cell(rng, cell, 0.12)
		if not data.is_inside_bench(p, 0) and not data.is_inside_bench(p, 1):
			if rng.randf() < 0.75:
				var light: bool = data.ground[_idx(ctx, cell)] == MapData.Ground.ARENA_GRASS
				data.objects.append(MapObject.new(MapObject.ObjectKind.GRASS_TUFT, p, rng.randi_range(0, 1) if light else 2))
			else:
				data.objects.append(MapObject.new(MapObject.ObjectKind.FLOWER, p, rng.randi_range(0, 2)))
	if outer_row and rng.randf() < cfg.bush_density * 0.5:
		var p := _jitter_in_cell(rng, cell, 0.2)
		if _grid_clear(bush_grid, p, cfg.bush_spacing):
			_grid_add(bush_grid, p)
			data.objects.append(MapObject.new(MapObject.ObjectKind.BUSH, p, rng.randi_range(0, 2)))


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
