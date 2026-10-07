extends SceneTree
## Testes puros do gerador de mapa (spec 007: determinismo, RNG global, config, trilhas,
## monólitos e zonas da decoração). Layout fixo em test_arena_layout.gd, relevo justo em
## test_arena_fairness.gd e visibilidade em test_arena_visibility.gd.
## Rodar depois do comando de validação 1:
##   "$G" --headless --path . --script tools/tests/test_map_generation.gd
## Imprime PASS/FAIL por verificação e sai com 0 (tudo passou) ou 1.

const DETERMINISM_SEEDS: Array[int] = [0, 1, 7, 42, 1337, 999999999, 2147483647, -12345]
const RULE_SEEDS_FROM: int = 1
const RULE_SEEDS_TO: int = 20
const WIDE_SEEDS_TO: int = 100
const NEIGHBORS_4: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
## Campos e funções que a spec 007 tirou (o teste confere que sumiram).
const DEAD_FIELD_PREFIXES: Array[String] = [
	"arena_fraction_", "arena_shape_", "arena_center_jitter", "ring_width", "raised_", "wall_", "ruin_",
	"south_low_depth", "monolith_north_fraction", "monolith_gap_clearance", "monolith_max_arena_distance",
	"arena_base_level", "trail_count_", "trail_arena_depth_", "height_noise_", "max_level",
]
const DEAD_FUNCTIONS: Array[String] = [
	"_build_arena", "_clean_arena_mask", "_build_raised_regions", "_raised_candidate", "_add_blob",
	"_build_walls", "_break_fits", "_fill_trail_mouths", "_near_south_strip", "_visible_step_distance",
	"_ruin_allowed", "_completes_ruin_block",
]
const LOW_KINDS: Array[int] = [MapObject.ObjectKind.BUSH, MapObject.ObjectKind.GRASS_TUFT, MapObject.ObjectKind.FLOWER]

var _failures: int = 0
var _passes: int = 0


func _initialize() -> void:
	var config := MapGenConfig.new()
	_test_determinism(config)
	_test_global_rng(config)
	_test_config_fields(config)
	_test_open_3x3()
	var gen := MapGenerator.new(config)
	var maps: Array[MapData] = []
	for s in range(RULE_SEEDS_FROM, WIDE_SEEDS_TO + 1):
		maps.append(gen.generate(s))
	var rule_maps: Array[MapData] = maps.slice(0, RULE_SEEDS_TO - RULE_SEEDS_FROM + 1)
	_test_trails(maps)
	_test_monoliths(rule_maps, config)
	_test_zones(maps)
	_test_arena_dirt(maps)
	_test_objects_basic(rule_maps)
	_report_timing(config)
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


# --- Determinismo -------------------------------------------------------------

func _test_determinism(config: MapGenConfig) -> void:
	var fingerprints: Array[String] = []
	var same_two_instances := true
	var same_after_other := true
	var detail := ""
	for s: int in DETERMINISM_SEEDS:
		var a: String = MapGenerator.new(config).generate(s).fingerprint()
		var b: String = MapGenerator.new(config).generate(s).fingerprint()
		if a != b:
			same_two_instances = false
			detail += "seed %d difere entre instâncias; " % s
		var gen := MapGenerator.new(config)
		var first: String = gen.generate(s).fingerprint()
		gen.generate(s + 12345)
		var again: String = gen.generate(s).fingerprint()
		if first != again:
			same_after_other = false
			detail += "seed %d muda depois de gerar outra; " % s
		fingerprints.append(a)
	_check(same_two_instances, "determinismo: duas instâncias geram o mesmo fingerprint (8 seeds)", detail)
	_check(same_after_other, "determinismo: A, B, A na mesma instância dá o mesmo fingerprint de A", detail)
	var unique: Dictionary = {}
	for p: String in fingerprints:
		unique[p] = true
	_check(unique.size() == fingerprints.size(), "seeds diferentes geram fingerprints diferentes (8 seeds)",
			"%d únicos de %d" % [unique.size(), fingerprints.size()])
	# Para comparar entre duas execuções do Godot (o relatório confere as duas saídas).
	print("INFO: fingerprint da seed 42 = ", fingerprints[DETERMINISM_SEEDS.find(42)])


func _test_global_rng(config: MapGenConfig) -> void:
	seed(1)
	var expected: int = randi()
	seed(1)
	MapGenerator.new(config).generate(42)
	var got: int = randi()
	_check(expected == got, "generate() não consome o RNG global", "esperado %d, veio %d" % [expected, got])


# --- Config e código morto ------------------------------------------------------------

func _test_config_fields(config: MapGenConfig) -> void:
	var dead: Array[String] = []
	for prop: Dictionary in config.get_property_list():
		if not (int(prop["usage"]) & PROPERTY_USAGE_EDITOR):
			continue
		var prop_name: String = prop["name"]
		for prefix: String in DEAD_FIELD_PREFIXES:
			if prop_name.begins_with(prefix):
				dead.append(prop_name)
	_check(dead.is_empty(), "config: nenhum campo de \"O que sai\" da spec 007", str(dead))
	var gen := MapGenerator.new(config)
	var dead_funcs: Array[String] = []
	for f: String in DEAD_FUNCTIONS:
		if gen.has_method(f):
			dead_funcs.append(f)
	_check(dead_funcs.is_empty(), "gerador: nenhuma função de \"O que sai\" da spec 007", str(dead_funcs))
	var gone: bool = not MapData.Ground.has("RUIN_TILE") and MapData.Ground.has("STONE_PATH") \
			and not ResourceLoader.exists("res://scripts/map/wall_segment.gd") \
			and not ResourceLoader.exists("res://scripts/map/wall_mesh_builder.gd") \
			and not "wall_segments" in MapData.new()
	_check(gone, "muro baixo e lajotas removidos (WallSegment, WallMeshBuilder, RUIN_TILE)")
	var needed: Array[String] = [
		"arena_size", "arena_floor_level", "bench_level_offset", "bench_depth", "ring1_width", "ring2_width",
		"ring2_level_offset", "stair_width", "relief_symmetry", "relief_central_chance", "relief_midline_gap",
		"relief_peak_min", "relief_peak_max", "relief_long_margin", "relief_short_margin", "relief_area_min",
		"relief_area_max", "forest_relief_max", "trail_stone_chance", "trail_branch_max", "monolith_min_spacing",
	]
	var missing: Array[String] = []
	for n: String in needed:
		if not n in config:
			missing.append(n)
	_check(missing.is_empty(), "config: parâmetros da spec 007 em @export", str(missing))
	_check(config.map_size == Vector2i(44, 44) and config.arena_size == Vector2i(20, 18) and config.bench_level_offset == 2
			and is_equal_approx(config.monolith_min_spacing, 6.0),
			"config: mapa 44x44, arena 20x18, reserva 2 níveis acima do chão, monólitos a 6")


## Abertura 3×3: bloco 3×3 com uma ponta de 1 célula e uma tira de 2 de largura.
func _test_open_3x3() -> void:
	var shape: Dictionary = {}
	for z in 3:
		for x in 3:
			shape[Vector2i(x, z)] = true
	shape[Vector2i(3, 1)] = true # ponta
	for x in range(4, 8):
		shape[Vector2i(x, 0)] = true # tira de 2 de largura
		shape[Vector2i(x, 1)] = true
	var opened: Array[Vector2i] = MapGenerator.open_3x3(shape)
	var ok: bool = opened.size() == 9
	for cell: Vector2i in opened:
		if cell.x > 2 or cell.y > 2:
			ok = false
	_check(ok, "abertura 3x3: tira pontas e tiras finas, mantém o bloco 3x3", str(opened))


# --- Trilhas -----------------------------------------------------------------------

## Escadas de entrada: as que saem do nível da reserva (anel 2), fora da arena.
func _entrance_tops(map: MapData) -> Array:
	var tops: Array = []
	var bench_level: int = map.get_bench(0).level
	for stair: MapStair in map.stairs:
		if stair.base_level == bench_level and stair.up_direction.y == 0:
			tops.append(stair.landing_cells())
	return tops


func _test_trails(maps: Array[MapData]) -> void:
	var count_ok := true
	var start_ok := true
	var border_ok := true
	var single_ok := true
	var dirt_seen := false
	var stone_seen := false
	var detail := ""
	for map: MapData in maps:
		if map.trails.size() != 2:
			count_ok = false
			detail += "seed %d com %d trilhas; " % [map.map_seed, map.trails.size()]
			continue
		var tops: Array = _entrance_tops(map)
		for trail: MapTrail in map.trails:
			var cells: Dictionary = {}
			for c: Vector2i in trail.cells:
				cells[c] = true
			var expected: MapData.Ground = MapData.Ground.STONE_PATH if trail.stone else MapData.Ground.DIRT
			for c: Vector2i in trail.cells:
				if map.get_ground(c) != expected:
					single_ok = false
					detail += "seed %d trilha com chão misturado em %s; " % [map.map_seed, c]
					break
			if trail.stone:
				stone_seen = true
			else:
				dirt_seen = true
			# Começa no topo de uma escada de entrada: as células do patamar são trilha.
			var starts := false
			for top: Array in tops:
				var all_in := true
				for c: Vector2i in top:
					if not cells.has(c):
						all_in = false
				if all_in and top.has(trail.start_cell):
					starts = true
			if not starts:
				start_ok = false
				detail += "seed %d trilha não começa no topo da escada (%s); " % [map.map_seed, trail.start_cell]
			# Caminho de células da trilha do início até a borda do mapa.
			var seen: Dictionary = {trail.start_cell: true}
			var queue: Array[Vector2i] = [trail.start_cell]
			var reached := false
			var head: int = 0
			while head < queue.size():
				var c: Vector2i = queue[head]
				head += 1
				if c.x == 0 or c.y == 0 or c.x == map.size.x - 1 or c.y == map.size.y - 1:
					reached = true
				for d: Vector2i in NEIGHBORS_4:
					var nb: Vector2i = c + d
					if cells.has(nb) and not seen.has(nb):
						seen[nb] = true
						queue.append(nb)
			if not reached:
				border_ok = false
				detail += "seed %d trilha não chega na borda; " % map.map_seed
	_check(count_ok, "trilhas: 2 por mapa (seeds 1-100)", detail)
	_check(start_ok, "trilhas: cada uma começa no topo de uma escada de entrada", detail)
	_check(border_ok, "trilhas: caminho contínuo até a borda do mapa", detail)
	_check(single_ok, "trilhas: cada uma é toda DIRT ou toda STONE_PATH", detail)
	_check(dirt_seen and stone_seen, "trilhas: de terra e de pedra aparecem nas seeds 1-100",
			"terra %s, pedra %s" % [str(dirt_seen), str(stone_seen)])


# --- Monólitos -------------------------------------------------------------------

func _stair_rects(map: MapData) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for stair: MapStair in map.stairs:
		for c: Vector2i in stair.cells:
			rects.append(Rect2(Vector2(c), Vector2.ONE))
	return rects


func _test_monoliths(maps: Array[MapData], config: MapGenConfig) -> void:
	var count_ok := true
	var place_ok := true
	var spacing_ok := true
	var sides: Dictionary = {}
	var detail := ""
	for map: MapData in maps:
		var monos: Array[Vector2] = []
		for obj: MapObject in map.objects:
			if obj.kind == MapObject.ObjectKind.MONOLITH:
				monos.append(obj.position)
		if monos.size() < config.monolith_count_min or monos.size() > config.monolith_count_max:
			count_ok = false
			detail += "seed %d com %d monólitos; " % [map.map_seed, monos.size()]
		var stairs: Array[Rect2] = _stair_rects(map)
		for p: Vector2 in monos:
			if map.is_inside_arena(p) or map.is_inside_bench(p, 0) or map.is_inside_bench(p, 1) \
					or map.get_bench(0).terrace_rect.has_point(p) or map.get_bench(1).terrace_rect.has_point(p):
				place_ok = false
				detail += "seed %d monólito na arena ou reserva %s; " % [map.map_seed, p]
			for r: Rect2 in stairs:
				if p.distance_to(p.clamp(r.position, r.end)) < config.monolith_clearance - 0.0001:
					place_ok = false
					detail += "seed %d monólito a menos de %.1f de escada %s; " % [map.map_seed, config.monolith_clearance, p]
			for other: Vector2 in monos:
				if other != p and p.distance_to(other) < config.monolith_min_spacing:
					spacing_ok = false
			var rel: Vector2 = p - map.arena_center
			var side: String = ("E" if rel.x > 0.0 else "W") if absf(rel.x) > absf(rel.y) else ("S" if rel.y > 0.0 else "N")
			sides[side] = true
	_check(count_ok, "monólitos: de %d a %d por mapa (seeds 1-20)" % [config.monolith_count_min, config.monolith_count_max], detail)
	_check(place_ok, "monólitos: fora da arena, das reservas e das escadas (folga %.1f)" % config.monolith_clearance, detail)
	_check(spacing_ok, "monólitos: a pelo menos %.0f um do outro" % config.monolith_min_spacing, detail)
	_check(sides.size() >= 3, "monólitos: em pelo menos 3 dos 4 lados somando as seeds 1-20", str(sides.keys()))


# --- Zonas -------------------------------------------------------------------------

func _test_zones(maps: Array[MapData]) -> void:
	var bench_ok := true
	var stair_ok := true
	var arena_ok := true
	var ring_ok := true
	var forest_ok := true
	var detail := ""
	for map: MapData in maps:
		var ring2_level: int = map.get_bench(0).level + 2
		for obj: MapObject in map.objects:
			var p: Vector2 = obj.position
			var cell: Vector2i = map.cell_at(p)
			if map.is_inside_bench(p, 0) or map.is_inside_bench(p, 1):
				bench_ok = false
				detail += "seed %d objeto %d na área útil da reserva; " % [map.map_seed, obj.kind]
			if map.is_stair_cell(cell):
				stair_ok = false
				detail += "seed %d objeto na escada %s; " % [map.map_seed, cell]
			if map.is_inside_arena(p):
				if obj.kind != MapObject.ObjectKind.GRASS_TUFT and obj.kind != MapObject.ObjectKind.FLOWER:
					arena_ok = false
					detail += "seed %d tipo %d na arena; " % [map.map_seed, obj.kind]
			elif map.is_built_cell(cell):
				# Nos anéis só vegetação baixa; monólito só no anel 2.
				var low: bool = LOW_KINDS.has(obj.kind)
				var mono_ok: bool = obj.kind == MapObject.ObjectKind.MONOLITH and map.get_level(cell) == ring2_level
				if not low and not mono_ok:
					ring_ok = false
					detail += "seed %d tipo %d no anel %s; " % [map.map_seed, obj.kind, cell]
		for cz in map.size.y:
			for cx in map.size.x:
				var cell := Vector2i(cx, cz)
				if not map.is_built_cell(cell) and map.get_level(cell) < ring2_level:
					forest_ok = false
					detail += "seed %d floresta abaixo do anel 2 em %s; " % [map.map_seed, cell]
	_check(bench_ok, "zonas: nenhum objeto na área útil das reservas (seeds 1-100)", detail)
	_check(stair_ok, "zonas: nenhum objeto nas escadas", detail)
	_check(arena_ok, "zonas: na arena só capim e flor", detail)
	_check(ring_ok, "zonas: nos anéis só vegetação baixa (e monólito no anel 2)", detail)
	_check(forest_ok, "zonas: relevo da floresta sempre >= ring2_level", detail)


func _test_arena_dirt(maps: Array[MapData]) -> void:
	var ok := true
	var lo: float = 1.0
	var hi: float = 0.0
	for map: MapData in maps:
		var dirt: int = 0
		var total: int = 0
		for cz in map.size.y:
			for cx in map.size.x:
				if map.is_arena_cell(Vector2i(cx, cz)):
					total += 1
					if map.get_ground(Vector2i(cx, cz)) == MapData.Ground.DIRT:
						dirt += 1
		var share: float = float(dirt) / float(total)
		lo = minf(lo, share)
		hi = maxf(hi, share)
		if share < 0.15 or share > 0.35:
			ok = false
	_check(ok, "terra na arena: de 15% a 35% das células (seeds 1-100)", "de %.0f%% a %.0f%%" % [lo * 100.0, hi * 100.0])


func _test_objects_basic(maps: Array[MapData]) -> void:
	var variant_ok := true
	var bounds_ok := true
	for map: MapData in maps:
		for obj: MapObject in map.objects:
			var p: Vector2 = obj.position
			if p.x < 0.0 or p.y < 0.0 or p.x >= map.size.x or p.y >= map.size.y:
				bounds_ok = false
			if obj.variant < 0 or obj.variant >= MapObject.variant_count(obj.kind):
				variant_ok = false
	_check(variant_ok, "objetos: variantes dentro das contagens da arte")
	_check(bounds_ok, "objetos: todas as posições dentro do mapa")


func _report_timing(config: MapGenConfig) -> void:
	var gen := MapGenerator.new(config)
	var runs: int = 10
	var start: int = Time.get_ticks_usec()
	for i in runs:
		gen.generate(5000 + i)
	var avg_ms: float = (Time.get_ticks_usec() - start) / 1000.0 / runs
	print("INFO: tempo médio de generate() com a config padrão: %.1f ms (meta < 500 ms)" % avg_ms)
	_check(avg_ms < 500.0, "desempenho: generate() abaixo de 500 ms em média", "%.1f ms" % avg_ms)
