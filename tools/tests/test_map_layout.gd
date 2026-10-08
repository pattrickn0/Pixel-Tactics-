extends SceneTree
## Testes do mapa feito à mão (spec 011, Fase 1): dados lidos de scenes/map.tscn.
## Rodar depois do comando de validação 1:
##   "$G" --headless --path . --script tools/tests/test_map_layout.gd
## Imprime PASS/FAIL por verificação e sai com 0 (tudo passou) ou 1.

const MAP_PATH: String = "res://scenes/map.tscn"
const SAMPLES: int = 1000
const TOLERANCE: float = 0.0001

var _failures: int = 0
var _passes: int = 0
var _map: MapData = null
var _layout: MapLayout = null


func _initialize() -> void:
	@warning_ignore("missing_await")
	_run()


func _run() -> void:
	_layout = (load(MAP_PATH) as PackedScene).instantiate() as MapLayout
	root.add_child(_layout)
	await process_frame
	await process_frame
	_map = _layout.build_map_data()
	_test_rects()
	_test_heights()
	_test_stairs()
	_test_fairness()
	await _test_determinism()
	await _test_snap()
	_test_obstacles()
	_test_arena_api()
	_test_forbidden_code()
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


func _rect_eq(a: Rect2, b: Rect2) -> bool:
	return a.position.distance_to(b.position) < TOLERANCE and a.size.distance_to(b.size) < TOLERANCE


func _test_rects() -> void:
	_check(_rect_eq(_map.arena_rect, Rect2(-10, -9, 20, 18)) and _map.arena_center == Vector2.ZERO,
			"arena_rect = Rect2(-10, -9, 20, 18) e arena_center = (0, 0)", str(_map.arena_rect))
	var south: MapBench = _map.get_bench(0)
	var north: MapBench = _map.get_bench(1)
	_check(south != null and _rect_eq(south.rect, Rect2(-9.5, 9.5, 19, 2.5)) and is_equal_approx(south.height, 0.5),
			"reserva do time 0: rect Rect2(-9.5, 9.5, 19, 2.5) e height 0,5", str(south.rect) if south else "sem reserva")
	_check(north != null and _rect_eq(north.rect, Rect2(-9.5, -12, 19, 2.5)) and is_equal_approx(north.height, 0.5),
			"reserva do time 1: rect Rect2(-9.5, -12, 19, 2.5) e height 0,5", str(north.rect) if north else "sem reserva")
	_check(south != null and north != null and _rect_eq(south.terrace_rect, Rect2(-10, 9, 20, 4))
			and _rect_eq(north.terrace_rect, Rect2(-10, -13, 20, 4)),
			"terrace_rect das reservas: Rect2(-10, 9, 20, 4) e Rect2(-10, -13, 20, 4)")
	_check(_map.benches.size() == 2, "exatamente 2 reservas")


func _test_heights() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var arena_ok := true
	var bench_ok := true
	var detail := ""
	for _i in SAMPLES:
		var p := _random_in(rng, _map.arena_rect)
		if not is_zero_approx(_map.get_height_at(p)):
			arena_ok = false
			detail += "arena %s = %.3f; " % [p, _map.get_height_at(p)]
		for bench: MapBench in _map.benches:
			var q := _random_in(rng, bench.rect)
			if not is_equal_approx(_map.get_height_at(q), 0.5):
				bench_ok = false
				detail += "reserva %d %s = %.3f; " % [bench.team, q, _map.get_height_at(q)]
	_check(arena_ok, "get_height_at = 0,0 em %d pontos da arena" % SAMPLES, detail)
	_check(bench_ok, "get_height_at = 0,5 em %d pontos de cada reserva" % SAMPLES, detail)
	var crest: Array[Vector2] = [Vector2(0, 13.5), Vector2(-14.5, 0), Vector2(0, -13.5), Vector2(14.5, 0)]
	var crest_ok := true
	for p: Vector2 in crest:
		if not is_equal_approx(_map.get_height_at(p), 1.5):
			crest_ok = false
			detail = "%s = %.3f" % [p, _map.get_height_at(p)]
	_check(crest_ok, "crista do muro em 1,5 (0, 13.5), (-14.5, 0), (0, -13.5), (14.5, 0)", detail)
	# Exterior a pelo menos 0,5 do muro e das escadas: 0,0.
	var outside_ok := true
	var outside_detail := ""
	var stair_zone: Array[Rect2] = []
	for stair: MapStair in _map.stairs:
		stair_zone.append(stair.rect.grow(0.75))
	for _i in SAMPLES:
		var p := Vector2(rng.randf_range(-24.0, 24.0), rng.randf_range(-24.0, 24.0))
		if Rect2(-15.5, -14.5, 31, 29).has_point(p):
			continue
		var near_stair := false
		for zone: Rect2 in stair_zone:
			if zone.has_point(p):
				near_stair = true
		if near_stair:
			continue
		if not is_zero_approx(_map.get_height_at(p)):
			outside_ok = false
			outside_detail += "%s = %.3f; " % [p, _map.get_height_at(p)]
	_check(outside_ok, "exterior a >= 0,5 do muro e das escadas = 0,0", outside_detail)
	_check(is_equal_approx(_map.get_max_height(), 1.5), "altura máxima do mapa = 1,5", str(_map.get_max_height()))
	var step_ok := true
	var step_detail := ""
	for _i in SAMPLES * 4:
		var p := Vector2(rng.randf_range(-24.0, 24.0), rng.randf_range(-24.0, 24.0))
		var h: float = _map.get_height_at(p)
		if h > 1.5 + TOLERANCE or h < 0.0:
			step_ok = false
			step_detail += "%s = %.3f; " % [p, h]
	_check(step_ok, "toda altura fica entre 0,0 e 1,5", step_detail)


## Anda pelo eixo dos lances: só saltos de 0,25.
func _test_stairs() -> void:
	_check(_map.stairs.size() == 6, "6 trechos de escada (3 por lance, 2 lances)", str(_map.stairs.size()))
	var terrace_rects: Array[Rect2] = []
	for bench: MapBench in _map.benches:
		terrace_rects.append(bench.terrace_rect)
	var outside_terrace := true
	for stair: MapStair in _map.stairs:
		for terrace: Rect2 in terrace_rects:
			if terrace.intersects(stair.rect):
				outside_terrace = false
	_check(outside_terrace, "nenhuma célula de escada dentro de bench.terrace_rect")
	# Lance oeste: ao longo de z = 4.5, de x = -19 até x = -9.75.
	var heights: Array[float] = _walk(Vector2(-19.0, 4.5), Vector2(1, 0), 9.25)
	_check(_steps_ok(heights, 0.25), "lance oeste: alturas mudam só em saltos de 0,25", str(_unique(heights)))
	_check(_expected_profile(heights), "lance oeste: 0 -> 1,5 por fora, 1,5 -> 0,5 por dentro, 0,5 -> 0 até a arena",
			str(_unique(heights)))
	var east: Array[float] = _walk(Vector2(19.0, -4.5), Vector2(-1, 0), 9.25)
	_check(_steps_ok(east, 0.25) and _expected_profile(east), "lance leste: mesmo perfil (rotação de 180°)", str(_unique(east)))
	var west_flights: int = 0
	var east_flights: int = 0
	for stair: MapStair in _map.stairs:
		if stair.rect.get_center().x < 0.0:
			west_flights += 1
		else:
			east_flights += 1
	_check(west_flights == 3 and east_flights == 3, "3 trechos no lance oeste e 3 no leste")


func _walk(from: Vector2, dir: Vector2, length: float) -> Array[float]:
	var out: Array[float] = []
	var t: float = 0.0
	while t <= length:
		out.append(_map.get_height_at(from + dir * t))
		t += 0.05
	return out


func _steps_ok(values: Array[float], rise: float) -> bool:
	for i in range(1, values.size()):
		var jump: float = absf(values[i] - values[i - 1])
		if jump > rise + TOLERANCE:
			return false
	return true


## Sobe de 0 a 1,5, desce a 0,5 e termina em 0 (sem sair da faixa 0..1,5).
func _expected_profile(values: Array[float]) -> bool:
	if not is_zero_approx(values[0]) or not is_zero_approx(values[values.size() - 1]):
		return false
	var peak: float = 0.0
	var peak_index: int = 0
	for i in values.size():
		if values[i] > peak:
			peak = values[i]
			peak_index = i
	if not is_equal_approx(peak, 1.5):
		return false
	# Depois do pico passa pelo terraço (0,5) antes de chegar na arena.
	var seen_terrace := false
	for i in range(peak_index, values.size()):
		if is_equal_approx(values[i], 0.5):
			seen_terrace = true
	return seen_terrace


func _unique(values: Array[float]) -> Array[float]:
	var out: Array[float] = []
	for v: float in values:
		if out.is_empty() or not is_equal_approx(out[out.size() - 1], v):
			out.append(v)
	return out


func _test_fairness() -> void:
	var ok := true
	var detail := ""
	var checked: int = 0
	var x: float = -19.0 + 0.125
	while x < 19.0:
		var z: float = -15.0 + 0.125
		while z < 15.0:
			var p := Vector2(x, z)
			var a: float = _map.get_height_at(p)
			var b: float = _map.get_height_at(-p)
			checked += 1
			if absf(a - b) > TOLERANCE:
				ok = false
				if detail.length() < 400:
					detail += "%s: %.3f x %.3f; " % [p, a, b]
			z += 0.25
		x += 0.25
	_check(ok, "get_height_at(p) == get_height_at(-p) em %d pontos (grade 0,25 deslocada 0,125)" % checked, detail)
	var south: MapBench = _map.get_bench(0)
	var north: MapBench = _map.get_bench(1)
	var rotated := Rect2(-south.rect.end, south.rect.size)
	_check(_rect_eq(rotated, north.rect), "a reserva do time 1 é a rotação de 180° da do time 0")
	_check(_map.mirror_point(Vector2(3, 4)) == Vector2(-3, -4), "mirror_point gira 180° em torno do centro")


func _test_determinism() -> void:
	var first: String = _map.fingerprint()
	var other := (load(MAP_PATH) as PackedScene).instantiate() as MapLayout
	root.add_child(other)
	await process_frame
	var second: String = other.build_map_data().fingerprint()
	other.queue_free()
	_check(first == second and first.length() == 64, "carregar map.tscn duas vezes dá fingerprint idêntico", first + " x " + second)
	_check(_layout.build_map_data().fingerprint() == first, "build_map_data repetido dá o mesmo fingerprint")


func _test_snap() -> void:
	_check(_layout.last_errors.is_empty(), "map.tscn: peças estruturais na grade de 0,5 e rotação em múltiplos de 90°",
			str(_layout.last_errors))
	var bad := MapLayout.new()
	bad.strict_snap = false
	root.add_child(bad)
	var arena := ArenaMarker.new()
	bad.add_child(arena)
	var piece := (load("res://scenes/kit/wall_high_2.tscn") as PackedScene).instantiate() as Node3D
	piece.name = "PecaForaDaGrade"
	piece.position = Vector3(0.3, 0.0, 0.0)
	bad.add_child(piece)
	var rotated := (load("res://scenes/kit/wall_high_2.tscn") as PackedScene).instantiate() as Node3D
	rotated.name = "PecaGirada"
	rotated.rotation_degrees = Vector3(0.0, 30.0, 0.0)
	bad.add_child(rotated)
	await process_frame
	bad.build_map_data()
	var named_off_grid: bool = false
	var named_rotated: bool = false
	for message: String in bad.last_errors:
		named_off_grid = named_off_grid or message.contains("PecaForaDaGrade")
		named_rotated = named_rotated or message.contains("PecaGirada")
	_check(named_off_grid and named_rotated, "peça fora da grade e peça girada 30° geram erro com o nome do nó",
			str(bad.last_errors))
	bad.queue_free()


func _test_obstacles() -> void:
	var obstacles: Array[Node] = get_nodes_in_group("map_obstacle")
	var bad: Array[String] = []
	var blocked: Array[Rect2] = [_map.arena_rect]
	for bench: MapBench in _map.benches:
		blocked.append(bench.rect)
	for node: Node in obstacles:
		var piece := node as KitPiece
		if piece == null:
			continue
		var foot: Rect2 = piece.get_footprint()
		for rect: Rect2 in blocked:
			if foot.intersects(rect):
				bad.append(str(piece.name))
	_check(not obstacles.is_empty(), "há obstáculos (árvores e props) no grupo map_obstacle (%d)" % obstacles.size())
	_check(bad.is_empty(), "nenhum map_obstacle com pegada cruzando a arena ou uma reserva", str(bad))


func _test_arena_api() -> void:
	_check(_map.is_inside_arena(Vector2(0, 0)) and not _map.is_inside_arena(Vector2(0, 9.0)) and _map.is_inside_arena(Vector2(-10, -9)),
			"is_inside_arena: retângulo semiaberto [x0, x1) x [z0, z1)")
	var out: Vector2 = _map.clamp_to_arena(Vector2(50, -50))
	_check(_map.is_inside_arena(out), "clamp_to_arena sempre cai dentro da arena", str(out))
	_check(is_zero_approx(_map.distance_to_arena(Vector2(0, 0))) and is_equal_approx(_map.distance_to_arena(Vector2(13, 0)), 3.0),
			"distance_to_arena")
	_check(_map.arena_side_of(Vector2(0, 1)) == 0 and _map.arena_side_of(Vector2(0, -1)) == 1 and _map.arena_side_of(Vector2(30, 0)) == -1,
			"arena_side_of: sul 0, norte 1, fora -1")
	_check(_map.is_inside_bench(Vector2(0, 10), 0) and _map.is_inside_bench(Vector2(0, -10), 1) and not _map.is_inside_bench(Vector2(0, 0), 0),
			"is_inside_bench")
	_check(_map.is_inside_bench(_map.clamp_to_bench(Vector2(40, 40), 0), 0), "clamp_to_bench cai dentro da reserva")


func _test_forbidden_code() -> void:
	var hits: Array[String] = []
	for dir_path: String in ["res://scripts/map", "res://tools/kit"]:
		_scan(dir_path, hits)
	_check(hits.is_empty(), "scripts/map e tools/kit sem RandomNumberGenerator, FastNoiseLite, randi, randf, randomize", str(hits))
	var old: Array[String] = []
	for dir_path: String in ["res://scripts", "res://scenes"]:
		_scan_old_names(dir_path, old)
	_check(old.is_empty(), "sem MapGenerator, MapGenConfig, SeedInput, GenerateButton, UseSeedButton, map_requested", str(old))
	_check(not FileAccess.file_exists("res://scripts/map/map_generator.gd") and not FileAccess.file_exists("res://scripts/map/map_gen_config.gd"),
			"map_generator.gd e map_gen_config.gd não existem")


func _scan(dir_path: String, hits: Array[String]) -> void:
	var banned: PackedStringArray = ["RandomNumberGenerator", "FastNoiseLite", "randi(", "randf(", "randomize"]
	for file_name: String in DirAccess.get_files_at(dir_path):
		if not file_name.ends_with(".gd"):
			continue
		var text: String = FileAccess.get_file_as_string(dir_path + "/" + file_name)
		for word: String in banned:
			if text.contains(word):
				hits.append("%s/%s: %s" % [dir_path, file_name, word])
	for sub: String in DirAccess.get_directories_at(dir_path):
		_scan(dir_path + "/" + sub, hits)


func _scan_old_names(dir_path: String, hits: Array[String]) -> void:
	var banned: PackedStringArray = ["MapGenerator", "MapGenConfig", "SeedInput", "GenerateButton", "UseSeedButton", "map_requested"]
	for file_name: String in DirAccess.get_files_at(dir_path):
		if not (file_name.ends_with(".gd") or file_name.ends_with(".tscn")):
			continue
		var text: String = FileAccess.get_file_as_string(dir_path + "/" + file_name)
		for word: String in banned:
			if text.contains(word):
				hits.append("%s/%s: %s" % [dir_path, file_name, word])
	for sub: String in DirAccess.get_directories_at(dir_path):
		_scan_old_names(dir_path + "/" + sub, hits)


func _random_in(rng: RandomNumberGenerator, rect: Rect2) -> Vector2:
	return Vector2(rng.randf_range(rect.position.x, rect.end.x - 0.001), rng.randf_range(rect.position.y, rect.end.y - 0.001))
