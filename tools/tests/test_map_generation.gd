extends SceneTree
## Testes puros do gerador de mapa (spec 001). Rodar depois do comando de validação 1:
##   "$G" --headless --path . --script tools/tests/test_map_generation.gd
## Imprime PASS/FAIL por verificação e sai com 0 (tudo passou) ou 1.

const DETERMINISM_SEEDS: Array[int] = [0, 1, 7, 42, 1337, 999999999, 2147483647, -12345]
const RULE_SEEDS_FROM: int = 1
const RULE_SEEDS_TO: int = 20
const NEIGHBORS_4: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]

var _failures: int = 0
var _passes: int = 0


func _initialize() -> void:
	var config := MapGenConfig.new()
	_test_determinism(config)
	_test_global_rng(config)
	var maps: Array[MapData] = []
	var gen := MapGenerator.new(config)
	for s in range(RULE_SEEDS_FROM, RULE_SEEDS_TO + 1):
		maps.append(gen.generate(s))
	_test_arena_shape(maps)
	_test_clamp(maps[0])
	_test_clamp(gen.generate(42))
	_test_relief(maps)
	_test_stairs(maps)
	_test_south_strip(maps)
	_test_objects(maps)
	_test_trails(maps, config)
	_test_walls(maps)
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
		print("FAIL: ", what, (" -> " + detail) if detail != "" else "")


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
		# Mesma instância: A, depois B, depois A de novo.
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


func _test_global_rng(config: MapGenConfig) -> void:
	seed(1)
	var expected: int = randi()
	seed(1)
	MapGenerator.new(config).generate(42)
	var got: int = randi()
	_check(expected == got, "generate() não consome o RNG global", "esperado %d, veio %d" % [expected, got])


# --- Arena --------------------------------------------------------------------

func _test_arena_shape(maps: Array[MapData]) -> void:
	var box_ok := true
	var connected_ok := true
	var holes_ok := true
	var detail := ""
	for map: MapData in maps:
		var fx: float = map.arena_rect.size.x / map.size.x
		var fz: float = map.arena_rect.size.y / map.size.y
		var real_box := _arena_bounds(map)
		if fx < 0.58 or fx > 0.72 or fz < 0.58 or fz > 0.72 or Rect2(real_box) != map.arena_rect:
			box_ok = false
			detail += "seed %d caixa %.2f x %.2f; " % [map.map_seed, fx, fz]
		if _count_components(map, 1) != 1:
			connected_ok = false
			detail += "seed %d arena desconectada; " % map.map_seed
		if _has_holes(map):
			holes_ok = false
			detail += "seed %d arena com buraco; " % map.map_seed
	_check(box_ok, "arena: caixa entre 58%% e 72%% do mapa na largura e na altura (seeds %d-%d)" % [RULE_SEEDS_FROM, RULE_SEEDS_TO], detail)
	_check(connected_ok, "arena: uma única região conectada (vizinhança 4)", detail)
	_check(holes_ok, "arena: sem buracos", detail)


func _arena_bounds(map: MapData) -> Rect2i:
	var lo := Vector2i(map.size.x, map.size.y)
	var hi := Vector2i(-1, -1)
	for cz in map.size.y:
		for cx in map.size.x:
			if map.is_arena_cell(Vector2i(cx, cz)):
				lo = Vector2i(mini(lo.x, cx), mini(lo.y, cz))
				hi = Vector2i(maxi(hi.x, cx), maxi(hi.y, cz))
	return Rect2i(lo, hi - lo + Vector2i.ONE)


func _count_components(map: MapData, value: int) -> int:
	var seen: Dictionary = {}
	var count: int = 0
	for cz in map.size.y:
		for cx in map.size.x:
			var cell := Vector2i(cx, cz)
			if map.arena_mask[map.index_of(cell)] != value or seen.has(cell):
				continue
			count += 1
			var queue: Array[Vector2i] = [cell]
			seen[cell] = true
			var head: int = 0
			while head < queue.size():
				var c: Vector2i = queue[head]
				head += 1
				for d: Vector2i in NEIGHBORS_4:
					var nb: Vector2i = c + d
					if map.is_cell_in_map(nb) and not seen.has(nb) and map.arena_mask[map.index_of(nb)] == value:
						seen[nb] = true
						queue.append(nb)
	return count


## Buraco = célula de fora da arena que não alcança a borda do mapa por fora da arena.
func _has_holes(map: MapData) -> bool:
	var seen: Dictionary = {}
	var queue: Array[Vector2i] = []
	for cz in map.size.y:
		for cx in map.size.x:
			var border: bool = cx == 0 or cz == 0 or cx == map.size.x - 1 or cz == map.size.y - 1
			var cell := Vector2i(cx, cz)
			if border and not map.is_arena_cell(cell):
				seen[cell] = true
				queue.append(cell)
	var head: int = 0
	while head < queue.size():
		var c: Vector2i = queue[head]
		head += 1
		for d: Vector2i in NEIGHBORS_4:
			var nb: Vector2i = c + d
			if map.is_cell_in_map(nb) and not seen.has(nb) and not map.is_arena_cell(nb):
				seen[nb] = true
				queue.append(nb)
	for cz in map.size.y:
		for cx in map.size.x:
			var cell := Vector2i(cx, cz)
			if not map.is_arena_cell(cell) and not seen.has(cell):
				return true
	return false


func _test_clamp(map: MapData) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	var arena_cells: Array[Vector2i] = []
	for cz in map.size.y:
		for cx in map.size.x:
			if map.is_arena_cell(Vector2i(cx, cz)):
				arena_cells.append(Vector2i(cx, cz))
	var inside_ok := true
	var same_ok := true
	var nearest_ok := true
	var detail := ""
	for i in 1000:
		# Inclui pontos fora do mapa.
		var p := Vector2(rng.randf_range(-10.0, map.size.x + 10.0), rng.randf_range(-10.0, map.size.y + 10.0))
		var q: Vector2 = map.clamp_to_arena(p)
		if not map.is_inside_arena(q):
			inside_ok = false
			detail = "ponto %s -> %s fora da arena" % [p, q]
		if map.is_inside_arena(p):
			if q != p:
				same_ok = false
				detail = "ponto de dentro %s mudou para %s" % [p, q]
			continue
		var best: float = INF
		for cell: Vector2i in arena_cells:
			var nearest: Vector2 = p.clamp(Vector2(cell), Vector2(cell) + Vector2.ONE)
			best = minf(best, p.distance_to(nearest))
		if absf(p.distance_to(q) - best) > 0.01:
			nearest_ok = false
			detail = "ponto %s: clamp a %.4f, mínimo %.4f (i=%d)" % [p, p.distance_to(q), best, i]
	var tag: String = "(seed %d, 1000 pontos)" % map.map_seed
	_check(inside_ok, "clamp_to_arena: resultado sempre passa em is_inside_arena " + tag, detail)
	_check(same_ok, "clamp_to_arena: ponto de dentro volta igual " + tag, detail)
	_check(nearest_ok, "clamp_to_arena: ponto de fora vai para o ponto mais próximo da arena (tolerância 0,01) " + tag, detail)


# --- Relevo e escadas ---------------------------------------------------------------

func _test_relief(maps: Array[MapData]) -> void:
	var levels_ok := true
	var base_share_ok := true
	var blocks_ok := true
	var ring_ok := true
	var detail := ""
	for map: MapData in maps:
		var base: int = map.arena_base_level
		var total: int = 0
		var at_base: int = 0
		for cz in map.size.y:
			for cx in map.size.x:
				var cell := Vector2i(cx, cz)
				var level: int = map.get_level(cell)
				if map.is_arena_cell(cell):
					total += 1
					if level == base:
						at_base += 1
					elif level == base + 1:
						if not _in_full_raised_block(map, cell):
							blocks_ok = false
							detail += "seed %d célula %s elevada fora de bloco 3x3; " % [map.map_seed, cell]
					else:
						levels_ok = false
						detail += "seed %d célula %s no nível %d; " % [map.map_seed, cell, level]
				elif _touches_arena_8(map, cell) and level != base:
					ring_ok = false
					detail += "seed %d anel %s no nível %d; " % [map.map_seed, cell, level]
		if float(at_base) / float(total) < 0.7:
			base_share_ok = false
			detail += "seed %d só %.0f%% no nível base; " % [map.map_seed, 100.0 * at_base / total]
	_check(levels_ok, "relevo da arena: toda célula no nível base ou base+1", detail)
	_check(base_share_ok, "relevo da arena: pelo menos 70% no nível base", detail)
	_check(blocks_ok, "relevo da arena: toda célula elevada pertence a um bloco 3x3 inteiro elevado", detail)
	_check(ring_ok, "anel (vizinhas da arena, vizinhança 8) no nível base", detail)


func _in_full_raised_block(map: MapData, cell: Vector2i) -> bool:
	var raised: int = map.arena_base_level + 1
	for oz in range(-2, 1):
		for ox in range(-2, 1):
			var full := true
			for dz in 3:
				for dx in 3:
					var c := cell + Vector2i(ox + dx, oz + dz)
					if not map.is_arena_cell(c) or map.get_level(c) != raised:
						full = false
			if full:
				return true
	return false


func _touches_arena_8(map: MapData, cell: Vector2i) -> bool:
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			if (dx != 0 or dz != 0) and map.is_arena_cell(cell + Vector2i(dx, dz)):
				return true
	return false


func _test_stairs(maps: Array[MapData]) -> void:
	var with_stairs: int = 0
	var cells_ok := true
	var detail := ""
	for map: MapData in maps:
		if not map.stairs.is_empty():
			with_stairs += 1
		for stair: MapStair in map.stairs:
			for cell: Vector2i in stair.cells:
				var north: Vector2i = cell + Vector2i(0, -1)
				var ok: bool = map.is_arena_cell(cell) and map.get_level(cell) == map.arena_base_level \
						and map.is_cell_in_map(north) and map.get_level(north) == map.arena_base_level + 1
				if not ok:
					cells_ok = false
					detail += "seed %d escada %s; " % [map.map_seed, cell]
	_check(with_stairs >= 6, "escadas em pelo menos 6 das seeds %d-%d" % [RULE_SEEDS_FROM, RULE_SEEDS_TO], "%d com escada" % with_stairs)
	_check(cells_ok, "escada: célula da arena, no nível base, com a célula ao norte em base+1", detail)


func _test_south_strip(maps: Array[MapData]) -> void:
	var ok := true
	var detail := ""
	for map: MapData in maps:
		for cx in map.size.x:
			var south_most: int = -1
			for cz in map.size.y:
				if map.is_arena_cell(Vector2i(cx, cz)):
					south_most = cz
			if south_most < 0:
				continue
			for cz in range(south_most + 1, map.size.y):
				if map.get_level(Vector2i(cx, cz)) > map.arena_base_level:
					ok = false
					detail += "seed %d (%d,%d); " % [map.map_seed, cx, cz]
	_check(ok, "faixa sul: nada acima do nível base ao sul da arena", detail)


# --- Objetos ------------------------------------------------------------------

func _test_objects(maps: Array[MapData]) -> void:
	var arena_kinds_ok := true
	var stair_ok := true
	var south_ok := true
	var monolith_ok := true
	var variant_ok := true
	var bounds_ok := true
	var detail := ""
	for map: MapData in maps:
		var south_most: PackedInt32Array = PackedInt32Array()
		south_most.resize(map.size.x)
		south_most.fill(-1)
		for cz in map.size.y:
			for cx in map.size.x:
				if map.is_arena_cell(Vector2i(cx, cz)):
					south_most[cx] = cz
		var monoliths: Array[Vector2] = []
		for obj: MapObject in map.objects:
			var p: Vector2 = obj.position
			var cell := Vector2i(floori(p.x), floori(p.y))
			if p.x < 0.0 or p.y < 0.0 or p.x >= map.size.x or p.y >= map.size.y:
				bounds_ok = false
				detail += "seed %d objeto fora do mapa %s; " % [map.map_seed, p]
				continue
			if map.is_inside_arena(p) and obj.kind != MapObject.ObjectKind.GRASS_TUFT and obj.kind != MapObject.ObjectKind.FLOWER:
				arena_kinds_ok = false
				detail += "seed %d tipo %d na arena; " % [map.map_seed, obj.kind]
			if map.is_stair_cell(cell):
				stair_ok = false
				detail += "seed %d objeto na escada; " % map.map_seed
			var in_south: bool = south_most[cell.x] >= 0 and cell.y > south_most[cell.x]
			if in_south and (obj.kind == MapObject.ObjectKind.TREE_BIG or obj.kind == MapObject.ObjectKind.MONOLITH):
				south_ok = false
				detail += "seed %d tipo %d na faixa sul; " % [map.map_seed, obj.kind]
			if obj.variant < 0 or obj.variant >= MapObject.variant_count(obj.kind):
				variant_ok = false
				detail += "seed %d variante %d do tipo %d; " % [map.map_seed, obj.variant, obj.kind]
			if obj.kind == MapObject.ObjectKind.MONOLITH:
				var dist: float = _distance_to_arena_brute(map, p)
				if map.is_inside_arena(p) or dist > 2.0:
					monolith_ok = false
					detail += "seed %d monólito a %.2f da arena; " % [map.map_seed, dist]
				for other: Vector2 in monoliths:
					if p.distance_to(other) < 6.0:
						monolith_ok = false
						detail += "seed %d monólitos a %.2f; " % [map.map_seed, p.distance_to(other)]
				monoliths.append(p)
	_check(arena_kinds_ok, "objetos: dentro da arena só GRASS_TUFT e FLOWER", detail)
	_check(stair_ok, "objetos: nenhum em célula de escada", detail)
	_check(south_ok, "objetos: nenhum TREE_BIG nem MONOLITH na faixa sul", detail)
	_check(monolith_ok, "monólitos: fora da arena, a no máximo 2 dela e a pelo menos 6 um do outro", detail)
	_check(variant_ok, "objetos: variantes dentro das contagens da arte", detail)
	_check(bounds_ok, "objetos: todas as posições dentro do mapa", detail)


func _distance_to_arena_brute(map: MapData, p: Vector2) -> float:
	var best: float = INF
	for cz in map.size.y:
		for cx in map.size.x:
			if map.is_arena_cell(Vector2i(cx, cz)):
				var nearest: Vector2 = p.clamp(Vector2(cx, cz), Vector2(cx + 1, cz + 1))
				best = minf(best, p.distance_to(nearest))
	return best


# --- Trilhas e muro ----------------------------------------------------------------

func _test_trails(maps: Array[MapData], config: MapGenConfig) -> void:
	var count_ok := true
	var south_ok := true
	var gap_ok := true
	var detail := ""
	for map: MapData in maps:
		var segments := _segments_by_edge(map)
		var valid: int = 0
		var from_south := false
		for trail: MapTrail in map.trails:
			var start: Vector2i = trail.start_cell
			var on_border: bool = start.x == 0 or start.y == 0 or start.x == map.size.x - 1 or start.y == map.size.y - 1
			if not on_border or map.get_ground(start) != MapData.Ground.DIRT:
				continue
			# Caminho de terra (vizinhança 4) da borda até uma célula vizinha da arena.
			var arrivals: Array[Vector2i] = _dirt_arrivals(map, start)
			if arrivals.is_empty():
				continue
			valid += 1
			if start.y == map.size.y - 1:
				from_south = true
			for cell: Vector2i in arrivals:
				for d: Vector2i in NEIGHBORS_4:
					var inner: Vector2i = cell + d
					if not map.is_arena_cell(inner):
						continue
					var key := Vector4i(inner.x, inner.y, -d.x, -d.y)
					if segments.has(key) and not (segments[key] as WallSegment).is_gap():
						gap_ok = false
						detail += "seed %d muro sem falha em %s; " % [map.map_seed, cell]
		if valid < config.trail_count_min:
			count_ok = false
			detail += "seed %d só %d trilhas válidas; " % [map.map_seed, valid]
		if not from_south:
			south_ok = false
			detail += "seed %d sem trilha do sul; " % map.map_seed
	_check(count_ok, "trilhas: pelo menos trail_count_min caminhos de terra da borda até a arena", detail)
	_check(south_ok, "trilhas: pelo menos uma começa na borda sul", detail)
	_check(gap_ok, "trilhas: falha no muro onde cada trilha chega na arena", detail)


func _dirt_arrivals(map: MapData, start: Vector2i) -> Array[Vector2i]:
	var arrivals: Array[Vector2i] = []
	var seen: Dictionary = {start: true}
	var queue: Array[Vector2i] = [start]
	var head: int = 0
	while head < queue.size():
		var c: Vector2i = queue[head]
		head += 1
		var touches := false
		for d: Vector2i in NEIGHBORS_4:
			var nb: Vector2i = c + d
			if map.is_arena_cell(nb):
				touches = true
			elif map.is_cell_in_map(nb) and not seen.has(nb) and map.get_ground(nb) == MapData.Ground.DIRT:
				seen[nb] = true
				queue.append(nb)
		if touches:
			arrivals.append(c)
	return arrivals


func _segments_by_edge(map: MapData) -> Dictionary:
	var result: Dictionary = {}
	for seg: WallSegment in map.wall_segments:
		result[Vector4i(seg.cell.x, seg.cell.y, seg.outward.x, seg.outward.y)] = seg
	return result


func _test_walls(maps: Array[MapData]) -> void:
	var coverage_ok := true
	var placement_ok := true
	var detail := ""
	for map: MapData in maps:
		var segments := _segments_by_edge(map)
		var perimeter: int = 0
		var walled: int = 0
		for cz in map.size.y:
			for cx in map.size.x:
				var cell := Vector2i(cx, cz)
				if not map.is_arena_cell(cell):
					continue
				for d: Vector2i in NEIGHBORS_4:
					if map.is_arena_cell(cell + d):
						continue
					perimeter += 1
					var key := Vector4i(cx, cz, d.x, d.y)
					if segments.has(key) and (segments[key] as WallSegment).height > 0.0:
						walled += 1
		var share: float = float(walled) / float(maxi(perimeter, 1))
		if share < 0.75:
			coverage_ok = false
			detail += "seed %d muro em %.0f%%; " % [map.map_seed, share * 100.0]
		for seg: WallSegment in map.wall_segments:
			var outward := Vector2(seg.outward)
			var body_mid: Vector2 = seg.midpoint() + outward * map.wall_thickness * 0.5
			var on_border: bool = map.is_arena_cell(seg.cell) and not map.is_arena_cell(seg.cell + seg.outward)
			if map.is_inside_arena(body_mid) or not on_border:
				placement_ok = false
				detail += "seed %d segmento em %s sobre a arena; " % [map.map_seed, seg.midpoint()]
	_check(coverage_ok, "muro: pelo menos 75% do perímetro da arena com altura > 0", detail)
	_check(placement_ok, "muro: nenhum segmento sobre célula da arena", detail)


func _report_timing(config: MapGenConfig) -> void:
	var gen := MapGenerator.new(config)
	var runs: int = 10
	var start: int = Time.get_ticks_usec()
	for i in runs:
		gen.generate(5000 + i)
	var avg_ms: float = (Time.get_ticks_usec() - start) / 1000.0 / runs
	print("INFO: tempo médio de generate() com a config padrão: %.1f ms (meta < 500 ms)" % avg_ms)
	_check(avg_ms < 500.0, "desempenho: generate() abaixo de 500 ms em média", "%.1f ms" % avg_ms)
