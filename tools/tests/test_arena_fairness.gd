extends SceneTree
## Testes do relevo justo dentro da arena (spec 007, seção C), seeds 1 a 100.
## Rodar depois do comando de validação 1:
##   "$G" --headless --path . --script tools/tests/test_arena_fairness.gd
## Imprime PASS/FAIL por verificação e sai com 0 (tudo passou) ou 1.

const SEEDS_FROM: int = 1
const SEEDS_TO: int = 100
const MIRROR_SEEDS_TO: int = 50
const POINTS_PER_SEED: int = 500
## Distância mínima de uma borda de degrau (múltiplos de 0,5) para o ponto do teste de simetria.
const EDGE_EPS: float = 0.01
const NEIGHBORS_4: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]

var _failures: int = 0
var _passes: int = 0


func _initialize() -> void:
	var config := MapGenConfig.new()
	var gen := MapGenerator.new(config)
	var maps: Array[MapData] = []
	for s in range(SEEDS_FROM, SEEDS_TO + 1):
		maps.append(gen.generate(s))
	_test_symmetry(maps, "rotação")
	_test_area_per_level(maps, "rotação")
	_test_terraces(maps, config)
	_test_shape(maps)
	_test_margins_area(maps, config)
	_test_floor_connection(maps)
	_test_internal_stairs(maps)
	_test_modes(maps)
	_test_variety(maps, config)

	var mirror_cfg := MapGenConfig.new()
	mirror_cfg.relief_symmetry = MapData.ReliefSymmetry.MIRROR
	var mirror_gen := MapGenerator.new(mirror_cfg)
	var mirror_maps: Array[MapData] = []
	for s in range(SEEDS_FROM, MIRROR_SEEDS_TO + 1):
		mirror_maps.append(mirror_gen.generate(s))
	_test_symmetry(mirror_maps, "espelho")
	_test_area_per_level(mirror_maps, "espelho")
	print("")
	if _failures == 0:
		print("RESULTADO: PASS (%d verificações)" % _passes)
	else:
		print("RESULTADO: FAIL (%d de %d verificações falharam)" % [_failures, _passes + _failures])
	quit(0 if _failures == 0 else 1)


func _check(ok: bool, what: String, detail: String = "") -> void:
	if ok:
		_passes += 1
		print("PASS: ", what)
	else:
		_failures += 1
		print("FAIL: ", what, (" -> " + detail.left(600)) if detail != "" else "")


func _arena(map: MapData) -> Rect2i:
	return Rect2i(map.arena_rect)


## Nível acima do chão de cada célula da arena (j * w + i).
func _levels(map: MapData) -> PackedInt32Array:
	var r := _arena(map)
	var out := PackedInt32Array()
	out.resize(r.size.x * r.size.y)
	for j in r.size.y:
		for i in r.size.x:
			out[j * r.size.x + i] = map.get_level(r.position + Vector2i(i, j)) - map.arena_floor_level
	return out


## Célula correspondente na outra metade, pelo mirror_point do próprio mapa.
func _mirror_cell(map: MapData, cell: Vector2i) -> Vector2i:
	return map.cell_at(map.mirror_point(Vector2(cell) + Vector2(0.5, 0.5)))


func _test_symmetry(maps: Array[MapData], tag: String) -> void:
	var ok := true
	var detail := ""
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var tested: int = 0
	for map: MapData in maps:
		var r := map.arena_rect
		var done: int = 0
		while done < POINTS_PER_SEED:
			var p := Vector2(rng.randf_range(r.position.x, r.end.x), rng.randf_range(r.position.y, r.end.y))
			var fx: float = fposmod(p.x * 2.0, 1.0)
			var fz: float = fposmod(p.y * 2.0, 1.0)
			if fx < EDGE_EPS * 2.0 or fx > 1.0 - EDGE_EPS * 2.0 or fz < EDGE_EPS * 2.0 or fz > 1.0 - EDGE_EPS * 2.0:
				continue
			done += 1
			tested += 1
			var a: float = map.get_height_at(p)
			var b: float = map.get_height_at(map.mirror_point(p))
			if not is_equal_approx(a, b):
				ok = false
				detail += "seed %d ponto %s: %.3f x %.3f; " % [map.map_seed, p, a, b]
				break
	_check(ok, "simetria (%s): get_height_at(p) == get_height_at(mirror_point(p)) em %d pontos" % [tag, tested], detail)


func _test_area_per_level(maps: Array[MapData], tag: String) -> void:
	var ok := true
	var detail := ""
	for map: MapData in maps:
		var counts: Dictionary = {}
		for cz in map.size.y:
			for cx in map.size.x:
				var cell := Vector2i(cx, cz)
				var side: int = map.arena_side_of(Vector2(cell) + Vector2(0.5, 0.5))
				if side < 0:
					continue
				var key := Vector2i(map.get_level(cell), side)
				counts[key] = int(counts.get(key, 0)) + 1
		for key: Vector2i in counts:
			if int(counts.get(Vector2i(key.x, 1 - key.y), 0)) != int(counts[key]):
				ok = false
				detail += "seed %d nível %d: %d x %d; " % [map.map_seed, key.x, counts.get(Vector2i(key.x, 0), 0), counts.get(Vector2i(key.x, 1), 0)]
				break
	_check(ok, "área por nível (%s): metade sul = metade norte (seeds %d-%d)" % [tag, SEEDS_FROM, SEEDS_FROM + maps.size() - 1], detail)


func _test_terraces(maps: Array[MapData], config: MapGenConfig) -> void:
	var diff_ok := true
	var peak_ok := true
	var detail := ""
	for map: MapData in maps:
		var r := _arena(map)
		var lv := _levels(map)
		var hi: int = 0
		for j in r.size.y:
			for i in r.size.x:
				var v: int = lv[j * r.size.x + i]
				hi = maxi(hi, v)
				if i + 1 < r.size.x and absi(v - lv[j * r.size.x + i + 1]) > 1:
					diff_ok = false
					detail += "seed %d em (%d,%d); " % [map.map_seed, i, j]
				if j + 1 < r.size.y and absi(v - lv[(j + 1) * r.size.x + i]) > 1:
					diff_ok = false
					detail += "seed %d em (%d,%d); " % [map.map_seed, i, j]
		if hi < 1 or hi > config.relief_peak_max or hi != map.relief_peak:
			peak_ok = false
			detail += "seed %d pico %d (relief_peak %d); " % [map.map_seed, hi, map.relief_peak]
	_check(diff_ok, "terraços: vizinhas (vizinhança 4) da arena diferem no máximo 1 nível", detail)
	_check(peak_ok, "terraços: nível mais alto entre 1 e relief_peak_max acima do chão", detail)


## Trechos retos do contorno (fora da arena conta como fora da região): todos com 2+ células.
func _short_run(mask: Dictionary) -> String:
	for dir: Vector2i in NEIGHBORS_4:
		var along := Vector2i(absi(dir.y), absi(dir.x))
		for c: Vector2i in mask:
			var is_edge: bool = not mask.has(c + dir)
			var prev_edge: bool = mask.has(c - along) and not mask.has(c - along + dir)
			if not is_edge or prev_edge:
				continue
			var length: int = 0
			while mask.has(c + along * length) and not mask.has(c + along * length + dir):
				length += 1
			if length < 2:
				return "trecho de %d em %s virado para %s" % [length, c, dir]
	return ""


func _test_shape(maps: Array[MapData]) -> void:
	var open_ok := true
	var runs_ok := true
	var detail := ""
	for map: MapData in maps:
		var r := _arena(map)
		var lv := _levels(map)
		for k in range(1, map.relief_peak + 1):
			var mask: Dictionary = {}
			for j in r.size.y:
				for i in r.size.x:
					if lv[j * r.size.x + i] >= k:
						mask[Vector2i(i, j)] = true
			if MapGenerator.open_3x3(mask).size() != mask.size():
				open_ok = false
				detail += "seed %d nível %d não passa na abertura 3x3; " % [map.map_seed, k]
			var bad: String = _short_run(mask)
			if bad != "":
				runs_ok = false
				detail += "seed %d nível %d: %s; " % [map.map_seed, k, bad]
	_check(open_ok, "forma: cada região de nível >= 1 passa na abertura 3x3", detail)
	_check(runs_ok, "forma: todo trecho reto do contorno tem pelo menos 2 células", detail)


func _test_margins_area(maps: Array[MapData], config: MapGenConfig) -> void:
	var margin_ok := true
	var area_ok := true
	var lo: float = 1.0
	var hi: float = 0.0
	var detail := ""
	for map: MapData in maps:
		var r := _arena(map)
		var lv := _levels(map)
		var elevated: int = 0
		for j in r.size.y:
			for i in r.size.x:
				if lv[j * r.size.x + i] < 1:
					continue
				elevated += 1
				var long_d: int = mini(j, r.size.y - 1 - j)
				var short_d: int = mini(i, r.size.x - 1 - i)
				if long_d < config.relief_long_margin or short_d < config.relief_short_margin:
					margin_ok = false
					detail += "seed %d célula elevada (%d,%d); " % [map.map_seed, i, j]
		var share: float = float(elevated) / float(lv.size())
		lo = minf(lo, share)
		hi = maxf(hi, share)
		if share < config.relief_area_min - 0.0001 or share > config.relief_area_max + 0.0001:
			area_ok = false
			detail += "seed %d área elevada %.0f%%; " % [map.map_seed, share * 100.0]
	_check(margin_ok, "margens: nada elevado a menos de %d das bordas compridas e %d das curtas" % [config.relief_long_margin, config.relief_short_margin], detail)
	_check(area_ok, "área elevada entre %.0f%% e %.0f%% da arena" % [config.relief_area_min * 100.0, config.relief_area_max * 100.0],
			"de %.0f%% a %.0f%%; %s" % [lo * 100.0, hi * 100.0, detail])
	print("INFO: área elevada de %.0f%% a %.0f%% da arena" % [lo * 100.0, hi * 100.0])


func _components(lv: PackedInt32Array, w: int, d: int, accept: Callable) -> Array:
	var seen: Dictionary = {}
	var comps: Array = []
	for j in d:
		for i in w:
			var c := Vector2i(i, j)
			if seen.has(c) or not accept.call(lv[j * w + i]):
				continue
			var comp: Array[Vector2i] = [c]
			seen[c] = true
			var head: int = 0
			while head < comp.size():
				var cur: Vector2i = comp[head]
				head += 1
				for dir: Vector2i in NEIGHBORS_4:
					var nb: Vector2i = cur + dir
					if nb.x >= 0 and nb.y >= 0 and nb.x < w and nb.y < d and not seen.has(nb) and accept.call(lv[nb.y * w + nb.x]):
						seen[nb] = true
						comp.append(nb)
			comps.append(comp)
	return comps


func _test_floor_connection(maps: Array[MapData]) -> void:
	var conn_ok := true
	var arrival_ok := true
	var detail := ""
	for map: MapData in maps:
		var r := _arena(map)
		var lv := _levels(map)
		var floors: Array = _components(lv, r.size.x, r.size.y, func(v: int) -> bool: return v == 0)
		var north := false
		var south := false
		if floors.size() == 1:
			for c: Vector2i in floors[0]:
				north = north or c.y == 0
				south = south or c.y == r.size.y - 1
		if floors.size() != 1 or not north or not south:
			conn_ok = false
			detail += "seed %d: %d regiões de chão (norte %s, sul %s); " % [map.map_seed, floors.size(), north, south]
		# Chegadas das escadas de fora (reserva e entrada) dentro da arena: no chão e livres.
		for stair: MapStair in map.stairs:
			if map.is_arena_cell(stair.cells[0]):
				continue
			for c: Vector2i in stair.arrival_cells():
				if not map.is_arena_cell(c):
					continue
				if map.get_level(c) != map.arena_floor_level or map.is_stair_cell(c):
					arrival_ok = false
					detail += "seed %d chegada %s fora do chão; " % [map.map_seed, c]
	_check(conn_ok, "conexão: o chão é uma região só e toca as duas bordas compridas", detail)
	_check(arrival_ok, "conexão: toda chegada de escada de reserva e de entrada fica no chão", detail)


func _test_internal_stairs(maps: Array[MapData]) -> void:
	var each_ok := true
	var reach_ok := true
	var detail := ""
	for map: MapData in maps:
		var r := _arena(map)
		var lv := _levels(map)
		var internal: Array[MapStair] = []
		for stair: MapStair in map.stairs:
			if map.is_arena_cell(stair.cells[0]):
				internal.append(stair)
		for k in range(1, map.relief_peak + 1):
			for comp: Array in _components(lv, r.size.x, r.size.y, func(v: int) -> bool: return v == k):
				var has_stair := false
				for stair: MapStair in internal:
					var fits := true
					for c: Vector2i in stair.cells:
						var top: Vector2i = c + stair.up_direction - r.position
						if map.get_level(c) - map.arena_floor_level != k - 1 or not comp.has(top):
							fits = false
					if fits:
						has_stair = true
				if not has_stair:
					each_ok = false
					detail += "seed %d região de nível %d sem escada; " % [map.map_seed, k]
		# Busca: anda no mesmo nível; só muda de nível pela escada.
		var links: Dictionary = {}
		for stair: MapStair in internal:
			for c: Vector2i in stair.cells:
				var top: Vector2i = c + stair.up_direction
				links[Vector4i(c.x, c.y, top.x, top.y)] = true
				links[Vector4i(top.x, top.y, c.x, c.y)] = true
		var seen: Dictionary = {}
		var queue: Array[Vector2i] = []
		for j in r.size.y:
			for i in r.size.x:
				if lv[j * r.size.x + i] == 0:
					var c: Vector2i = r.position + Vector2i(i, j)
					seen[c] = true
					queue.append(c)
		var head: int = 0
		while head < queue.size():
			var c: Vector2i = queue[head]
			head += 1
			for dir: Vector2i in NEIGHBORS_4:
				var nb: Vector2i = c + dir
				if not map.is_arena_cell(nb) or seen.has(nb):
					continue
				if map.get_level(nb) == map.get_level(c) or links.has(Vector4i(c.x, c.y, nb.x, nb.y)):
					seen[nb] = true
					queue.append(nb)
		if seen.size() != lv.size():
			reach_ok = false
			detail += "seed %d: %d de %d células alcançáveis; " % [map.map_seed, seen.size(), lv.size()]
	_check(each_ok, "escadas internas: toda região de nível k >= 1 tem escada vinda de k - 1", detail)
	_check(reach_ok, "escadas internas: a busca só por escadas alcança toda célula elevada a partir do chão", detail)


func _test_modes(maps: Array[MapData]) -> void:
	var central: int = 0
	var per_side: int = 0
	var shape_ok := true
	var detail := ""
	for map: MapData in maps:
		var r := _arena(map)
		var lv := _levels(map)
		var hills: Array = _components(lv, r.size.x, r.size.y, func(v: int) -> bool: return v >= 1)
		var mid: int = floori(r.size.y / 2.0)
		if map.relief_mode == MapData.ReliefMode.CENTRAL:
			central += 1
			var crosses := false
			if hills.size() == 1:
				var n := false
				var s := false
				for c: Vector2i in hills[0]:
					n = n or c.y < mid
					s = s or c.y >= mid
				crosses = n and s
			if not crosses:
				shape_ok = false
				detail += "seed %d CENTRAL com %d morros; " % [map.map_seed, hills.size()]
		else:
			per_side += 1
			var one_each := hills.size() == 2
			var halves: Dictionary = {}
			for hill: Array in hills:
				var north_n: int = 0
				for c: Vector2i in hill:
					if c.y < mid:
						north_n += 1
				if north_n != 0 and north_n != hill.size():
					one_each = false
				halves[north_n > 0] = true
			if not one_each or halves.size() != 2:
				shape_ok = false
				detail += "seed %d PER_SIDE com %d morros; " % [map.map_seed, hills.size()]
	print("INFO: modos nas seeds %d-%d: CENTRAL %d, PER_SIDE %d" % [SEEDS_FROM, SEEDS_TO, central, per_side])
	_check(central >= 30 and per_side >= 30, "modos: CENTRAL e PER_SIDE em pelo menos 30 seeds cada",
			"CENTRAL %d, PER_SIDE %d" % [central, per_side])
	_check(shape_ok, "modos: CENTRAL = um morro que cruza o meio; PER_SIDE = um morro em cada metade", detail)


func _test_variety(maps: Array[MapData], config: MapGenConfig) -> void:
	var peaks: Dictionary = {}
	var grids: Dictionary = {}
	for map: MapData in maps:
		peaks[map.relief_peak] = int(peaks.get(map.relief_peak, 0)) + 1
		grids[_levels(map).to_byte_array().hex_encode()] = true
	# Pico menor que o sorteado (forma não comportou) e forma reserva, refazendo o RNG do passo.
	var reduced: int = 0
	var fallbacks: int = 0
	for map: MapData in maps:
		var master := RandomNumberGenerator.new()
		master.seed = map.map_seed
		var rng := RandomNumberGenerator.new()
		rng.seed = master.randi()
		var r := _arena(map)
		var res: ArenaReliefGenerator.Result = ArenaReliefGenerator.new(r.size.x, r.size.y, config).generate(rng)
		if res.peak < res.peak_target:
			reduced += 1
		if res.fallback:
			fallbacks += 1
	print("INFO: picos nas seeds %d-%d: %s; pico menor que o sorteado em %d seeds; forma reserva em %d"
			% [SEEDS_FROM, SEEDS_TO, str(peaks), reduced, fallbacks])
	_check(int(peaks.get(3, 0)) >= 25, "variedade: pelo menos 25 seeds com pico de 3 níveis", str(peaks))
	_check(grids.size() >= 60, "variedade: pelo menos 60 grades de altura da arena diferentes", "%d diferentes" % grids.size())
