extends SceneTree
## Testes do layout fixo do anfiteatro e das funções da arena e das reservas (spec 007).
## Rodar depois do comando de validação 1:
##   "$G" --headless --path . --script tools/tests/test_arena_layout.gd
## Imprime PASS/FAIL por verificação e sai com 0 (tudo passou) ou 1.

const SEEDS_FROM: int = 1
const SEEDS_TO: int = 20
const RANDOM_POINTS: int = 1000

var _failures: int = 0
var _passes: int = 0


func _initialize() -> void:
	var config := MapGenConfig.new()
	var gen := MapGenerator.new(config)
	var maps: Array[MapData] = []
	for s in range(SEEDS_FROM, SEEDS_TO + 1):
		maps.append(gen.generate(s))
	_test_fixed_across_seeds(maps)
	_test_sizes(maps[0], config)
	_test_benches(maps[0], config)
	_test_layout_symmetry(maps)
	_test_inside_arena(maps[0])
	_test_clamp(maps[0], "arena", maps[0].arena_rect, maps[0].is_inside_arena, maps[0].clamp_to_arena)
	for team in 2:
		var bench: MapBench = maps[0].get_bench(team)
		_test_clamp(maps[0], "reserva do time %d" % team, bench.rect,
				func(p: Vector2) -> bool: return maps[0].is_inside_bench(p, team),
				func(p: Vector2) -> Vector2: return maps[0].clamp_to_bench(p, team))
	_test_side_of(maps[0])
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


## Tudo que é fixo, num texto (escadas de fora da arena, reservas, anéis e built_mask).
func _fixed_signature(map: MapData) -> String:
	var parts: PackedStringArray = []
	parts.append(str(map.size, map.arena_rect, map.arena_center, map.arena_floor_level))
	for bench: MapBench in map.benches:
		parts.append(str(bench.team, bench.rect, bench.terrace_rect, bench.level))
	for stair: MapStair in map.stairs:
		if map.is_arena_cell(stair.cells[0]):
			continue
		parts.append(str(stair.cells, stair.up_direction, stair.base_level, stair.levels))
	parts.append(map.built_mask.hex_encode())
	for cz in map.size.y:
		for cx in map.size.x:
			var cell := Vector2i(cx, cz)
			if map.is_built_cell(cell) and not map.is_arena_cell(cell):
				parts.append(str(map.get_level(cell)))
	return "|".join(parts)


func _test_fixed_across_seeds(maps: Array[MapData]) -> void:
	var first: String = _fixed_signature(maps[0])
	var ok := true
	var detail := ""
	for map: MapData in maps:
		if _fixed_signature(map) != first:
			ok = false
			detail += "seed %d difere; " % map.map_seed
	_check(ok, "layout fixo: arena, reservas, escadas fixas, anéis e built_mask iguais nas seeds %d-%d" % [SEEDS_FROM, SEEDS_TO], detail)


func _test_sizes(map: MapData, config: MapGenConfig) -> void:
	var centered: bool = map.arena_center.is_equal_approx(Vector2(map.size) * 0.5)
	_check(map.arena_rect.size == Vector2(config.arena_size) and map.arena_rect.size == Vector2(20, 18),
			"arena_rect.size = (20, 18)", str(map.arena_rect))
	_check(centered, "arena centrada no mapa", "centro %s, mapa %s" % [map.arena_center, map.size])
	_check(map.size == Vector2i(44, 44), "mapa 44 x 44", str(map.size))
	var built_box := Rect2i()
	var first := true
	for cz in map.size.y:
		for cx in map.size.x:
			if map.is_built_cell(Vector2i(cx, cz)):
				var cell_rect := Rect2i(cx, cz, 1, 1)
				built_box = cell_rect if first else built_box.merge(cell_rect)
				first = false
	_check(built_box == Rect2i(8, 8, 28, 28), "anfiteatro (built_mask) = [8, 36)²", str(built_box))


func _test_benches(map: MapData, config: MapGenConfig) -> void:
	var south: MapBench = map.get_bench(0)
	var north: MapBench = map.get_bench(1)
	var expected_level: int = map.arena_floor_level + config.bench_level_offset
	_check(map.benches.size() == 2 and south != null and north != null, "duas reservas (time 0 e time 1)")
	_check(south.rect == Rect2(14, 31.5, 16, 2) and north.rect == Rect2(14, 10.5, 16, 2),
			"áreas úteis: time 0 = (14, 31.5, 16, 2), time 1 = (14, 10.5, 16, 2)", "%s / %s" % [south.rect, north.rect])
	_check(south.rect.position.y >= map.arena_rect.end.y and north.rect.end.y <= map.arena_rect.position.y,
			"reserva do time 0 ao sul da arena e a do time 1 ao norte")
	_check(not south.rect.intersects(map.arena_rect) and not north.rect.intersects(map.arena_rect),
			"reservas fora da arena")
	_check(south.level == expected_level and north.level == expected_level and expected_level > map.arena_floor_level,
			"reservas no mesmo nível bench_level (%d), acima do chão da arena (%d)" % [expected_level, map.arena_floor_level])
	var stair_ok := true
	var flat_ok := true
	var detail := ""
	for bench: MapBench in map.benches:
		for stair: MapStair in map.stairs:
			for cell: Vector2i in stair.cells:
				if bench.rect.intersects(Rect2(Vector2(cell), Vector2.ONE)):
					stair_ok = false
					detail += "escada %s na reserva %d; " % [cell, bench.team]
		var lo := Vector2i(bench.rect.position.floor())
		var r := Rect2i(lo, Vector2i(bench.rect.end.ceil()) - lo)
		for cz in range(r.position.y, r.end.y):
			for cx in range(r.position.x, r.end.x):
				if map.get_level(Vector2i(cx, cz)) != bench.level:
					flat_ok = false
					detail += "célula %s da reserva %d no nível %d; " % [Vector2i(cx, cz), bench.team, map.get_level(Vector2i(cx, cz))]
	_check(stair_ok, "reservas não se sobrepõem às escadas", detail)
	_check(flat_ok, "área útil das reservas plana, no nível da reserva", detail)
	var bench_stairs: int = 0
	var entrance_stairs: int = 0
	for stair: MapStair in map.stairs:
		if stair.base_level == map.arena_floor_level and not map.is_arena_cell(stair.cells[0]):
			if stair.up_direction.x == 0:
				bench_stairs += 1
			else:
				entrance_stairs += 1
	_check(bench_stairs == 4 and entrance_stairs == 2, "escadas fixas: 2 por reserva e 1 por lado curto saindo da arena",
			"reserva %d, entrada %d" % [bench_stairs, entrance_stairs])


func _rot_cell(map: MapData, cell: Vector2i) -> Vector2i:
	return map.cell_at(2.0 * map.arena_center - (Vector2(cell) + Vector2(0.5, 0.5)))


func _test_layout_symmetry(maps: Array[MapData]) -> void:
	var ok := true
	var detail := ""
	for map: MapData in maps:
		for cz in range(8, 36):
			for cx in range(8, 36):
				var c := Vector2i(cx, cz)
				var m: Vector2i = _rot_cell(map, c)
				if map.get_level(c) != map.get_level(m) or map.is_built_cell(c) != map.is_built_cell(m):
					ok = false
					detail += "seed %d célula %s x %s; " % [map.map_seed, c, m]
					break
	_check(ok, "layout simétrico por rotação de 180°: altura e built_mask de c = de mirror(c) em [8, 36)² (seeds %d-%d)" % [SEEDS_FROM, SEEDS_TO], detail)


func _test_inside_arena(map: MapData) -> void:
	var r: Rect2 = map.arena_rect
	var e: float = 0.0001
	var inside: Array[Vector2] = [
		r.get_center(), r.position, Vector2(r.position.x, r.end.y - e), Vector2(r.end.x - e, r.position.y),
		r.end - Vector2(e, e), Vector2(r.position.x, r.get_center().y), Vector2(r.get_center().x, r.position.y),
	]
	var outside: Array[Vector2] = [
		Vector2(r.end.x, r.get_center().y), Vector2(r.get_center().x, r.end.y), r.end, Vector2(r.position.x - e, r.position.y),
		Vector2(r.position.x, r.position.y - e), Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y),
		Vector2(-5.0, -5.0), Vector2(100.0, 20.0), Vector2(20.0, 100.0),
	]
	var ok := true
	var detail := ""
	for p: Vector2 in inside:
		if not map.is_inside_arena(p):
			ok = false
			detail += "%s deveria estar dentro; " % p
	for p: Vector2 in outside:
		if map.is_inside_arena(p):
			ok = false
			detail += "%s deveria estar fora; " % p
	_check(ok, "is_inside_arena: verdadeiro só no retângulo (dentro, 4 bordas, cantos e fora)", detail)


func _test_clamp(map: MapData, tag: String, rect: Rect2, inside_fn: Callable, clamp_fn: Callable) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	var same_ok := true
	var inside_ok := true
	var nearest_ok := true
	var detail := ""
	for _i in RANDOM_POINTS:
		var p := Vector2(rng.randf_range(rect.position.x, rect.end.x), rng.randf_range(rect.position.y, rect.end.y))
		if inside_fn.call(p) and clamp_fn.call(p) != p:
			same_ok = false
			detail = "ponto de dentro %s mudou" % p
	var tested: int = 0
	while tested < RANDOM_POINTS:
		var p := Vector2(rng.randf_range(-10.0, map.size.x + 10.0), rng.randf_range(-10.0, map.size.y + 10.0))
		if inside_fn.call(p):
			continue
		tested += 1
		var q: Vector2 = clamp_fn.call(p)
		if not inside_fn.call(q):
			inside_ok = false
			detail = "%s -> %s fora" % [p, q]
		var best: float = p.distance_to(p.clamp(rect.position, rect.end))
		if absf(p.distance_to(q) - best) > MapData.CLAMP_INSET * 2.0:
			nearest_ok = false
			detail = "%s: clamp a %.4f, mínimo %.4f" % [p, p.distance_to(q), best]
	_check(same_ok, "clamp (%s): ponto de dentro volta igual (%d pontos)" % [tag, RANDOM_POINTS], detail)
	_check(inside_ok, "clamp (%s): resultado de %d pontos de fora fica dentro" % [tag, RANDOM_POINTS], detail)
	_check(nearest_ok, "clamp (%s): é o ponto mais próximo do retângulo (tolerância de CLAMP_INSET)" % tag, detail)


func _test_side_of(map: MapData) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var r: Rect2 = map.arena_rect
	var ok := true
	var dist_ok := true
	var mirror_ok := true
	var detail := ""
	for _i in 1000:
		var p := Vector2(rng.randf_range(-5.0, map.size.x + 5.0), rng.randf_range(-5.0, map.size.y + 5.0))
		var expected: int = -1
		if map.is_inside_arena(p):
			expected = 0 if p.y >= map.arena_center.y else 1
		if map.arena_side_of(p) != expected:
			ok = false
			detail += "%s deu %d (esperado %d); " % [p, map.arena_side_of(p), expected]
		var d_expected: float = p.distance_to(p.clamp(r.position, r.end))
		if not is_equal_approx(map.distance_to_arena(p), d_expected):
			dist_ok = false
		var m: Vector2 = map.mirror_point(p)
		if not map.mirror_point(m).is_equal_approx(p) or not (p + m).is_equal_approx(2.0 * map.arena_center):
			mirror_ok = false
		if expected >= 0 and map.arena_side_of(m) != 1 - expected and not is_equal_approx(p.y, map.arena_center.y):
			mirror_ok = false
			detail += "mirror de %s ficou na mesma metade; " % p
	_check(ok, "arena_side_of: 0 na metade sul, 1 na norte e -1 fora (1000 pontos)", detail)
	_check(dist_ok, "distance_to_arena: distância ao retângulo (0 dentro)")
	_check(mirror_ok, "mirror_point: rotação de 180° em torno do centro, leva cada metade para a outra", detail)
