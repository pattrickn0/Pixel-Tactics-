extends SceneTree
## Ilha flutuante (spec 012, Fase 1): contorno da Tabela A, mata da Tabela C, regra da órbita da Tabela D,
## braseiros, ausência de rio, código sem sorteio e place_decor.gd protegido por --force.
## Lê scenes/map.tscn (a fonte de verdade) e as tabelas de tools/kit/.
## Rodar depois do comando de validação 1:
##   "$G" --headless --path . --script tools/tests/test_island.gd
## Imprime PASS/FAIL por verificação e sai com 0 (tudo passou) ou 1.

const MAP_PATH: String = "res://scenes/map.tscn"
## Âncoras da Tabela A (sentido horário a partir da ponta sul).
const ANCHORS: Array[Vector2] = [
	Vector2(0.0, 18.5), Vector2(2.4, 17.6), Vector2(4.8, 17.2), Vector2(7.2, 16.9), Vector2(9.7, 16.3), Vector2(12.2, 15.6),
	Vector2(14.6, 14.1), Vector2(16.4, 11.8), Vector2(18.5, 8.8), Vector2(20.5, 5.5), Vector2(22.5, 2.3), Vector2(24.8, -1.2),
	Vector2(26.9, -4.9), Vector2(28.3, -9.5), Vector2(29.3, -14.3), Vector2(30.5, -18.5), Vector2(31.0, -22.7), Vector2(27.5, -24.6),
	Vector2(23.0, -24.1), Vector2(19.0, -23.6), Vector2(15.0, -22.6), Vector2(10.0, -21.4), Vector2(4.8, -20.7), Vector2(0.3, -20.4),
	Vector2(-4.3, -20.7), Vector2(-9.0, -21.6), Vector2(-13.8, -22.9), Vector2(-18.0, -22.6), Vector2(-22.0, -20.8), Vector2(-25.0, -18.0),
	Vector2(-26.8, -14.5), Vector2(-25.5, -9.5), Vector2(-23.6, -4.0), Vector2(-22.3, -1.2), Vector2(-20.9, 1.7), Vector2(-19.8, 4.8),
	Vector2(-18.7, 7.8), Vector2(-17.0, 10.3), Vector2(-15.5, 12.1), Vector2(-14.6, 13.7), Vector2(-12.4, 14.7), Vector2(-9.5, 15.7),
	Vector2(-6.8, 16.5), Vector2(-4.4, 17.0), Vector2(-2.2, 17.7),
]
const WALL_RECT: Rect2 = Rect2(-14.0, -13.0, 28.0, 26.0)
## Zonas da Tabela C (f1): [nome, retângulo (x0, z0, largura, fundo), mínimo, máximo].
const ZONES: Array = [
	["noroeste", Rect2(-27.0, -23.0, 17.0, 18.0), 24, 32],
	["oeste perto do portão", Rect2(-23.0, -5.0, 7.0, 8.0), 4, 6],
	["nordeste", Rect2(10.0, -23.0, 9.0, 8.0), 6, 9],
	["leste", Rect2(20.0, -25.0, 11.0, 21.0), 18, 26],
	["frente leste", Rect2(16.0, -4.0, 6.0, 15.0), 6, 8],
]
const EAST_ZONE: Rect2 = Rect2(20.0, -25.0, 11.0, 21.0)
## Faixa sul (f1): entre o muro sul e a borda; a passagem sul e o patamar ficam livres.
const SOUTH_STRIP: Rect2 = Rect2(-16.0, 13.0, 32.0, 6.0)
const SOUTH_KEEP_CLEAR: Array[Rect2] = [Rect2(-1.5, 12.0, 3.0, 2.5), Rect2(-2.5, 14.5, 5.0, 3.5)]
## Faixa norte central sem tronco e o norte central (1 ou 2 folhosas na ponta oeste).
const NORTH_STRIP: Rect2 = Rect2(-8.0, -21.0, 18.0, 6.5)
## Lajes (patamar sul, patamar norte, plataforma oeste) e caminho nordeste: tronco a >= 0,75.
const SLAB_RECTS: Array[Rect2] = [Rect2(-2.5, 14.5, 5.0, 3.5), Rect2(-2.0, -16.0, 4.0, 1.5), Rect2(-20.0, 4.0, 4.0, 5.5)]

var _failures: int = 0
var _passes: int = 0


func _initialize() -> void:
	@warning_ignore("missing_await")
	_run()


func _check(ok: bool, what: String, detail: String = "") -> void:
	if ok:
		_passes += 1
		print("PASS: ", what)
	else:
		_failures += 1
		print("FAIL: ", what, (" -> " + detail.left(800)) if detail != "" else "")


func _run() -> void:
	_test_outline()
	var map := (load(MAP_PATH) as PackedScene).instantiate() as Node3D
	root.add_child(map)
	await process_frame
	_test_forest(map)
	_test_orbit_rule(map)
	_test_braziers(map)
	_test_fireflies(map)
	_test_no_river(map)
	map.queue_free()
	await process_frame
	_test_forbidden_code()
	_test_place_decor_force()
	print("")
	if _failures == 0:
		print("RESULTADO: PASS (%d verificações)" % _passes)
	else:
		print("RESULTADO: FAIL (%d de %d verificações falharam)" % [_failures, _passes + _failures])
	quit(0 if _failures == 0 else 1)


# ---------------------------------------------------------------- contorno

static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	return p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))


static func _edge_dist(p: Vector2, poly: PackedVector2Array) -> float:
	var best: float = INF
	for i in poly.size():
		best = minf(best, _seg_dist(p, poly[i], poly[(i + 1) % poly.size()]))
	return best


func _test_outline() -> void:
	var poly: PackedVector2Array = IslandTables.ISLAND_OUTLINE
	_check(poly.size() >= 56 and poly.size() <= 90, "ISLAND_OUTLINE com 56 a 90 vértices (%d)" % poly.size())
	var longest: float = 0.0
	for i in poly.size():
		longest = maxf(longest, poly[i].distance_to(poly[(i + 1) % poly.size()]))
	_check(longest <= 3.0, "arestas do contorno <= 3 (maior %.2f)" % longest)
	var crossings: int = 0
	for i in poly.size():
		for j in range(i + 2, poly.size()):
			if i == 0 and j == poly.size() - 1:
				continue
			if Geometry2D.segment_intersects_segment(poly[i], poly[(i + 1) % poly.size()], poly[j], poly[(j + 1) % poly.size()]) != null:
				crossings += 1
	_check(crossings == 0, "contorno é um polígono simples (sem arestas cruzadas)", "%d cruzamentos" % crossings)
	var far: Array[String] = []
	for a: Vector2 in ANCHORS:
		var d: float = _edge_dist(a, poly)
		if d > 0.75:
			far.append("%s a %.2f" % [a, d])
	_check(far.is_empty(), "o contorno passa a <= 0,75 de cada uma das %d âncoras da Tabela A" % ANCHORS.size(), str(far))
	var inside_ok := true
	var margin: float = INF
	var corners: Array[Vector2] = [WALL_RECT.position, Vector2(WALL_RECT.end.x, WALL_RECT.position.y), WALL_RECT.end,
			Vector2(WALL_RECT.position.x, WALL_RECT.end.y)]
	for k in 4:
		var a: Vector2 = corners[k]
		var b: Vector2 = corners[(k + 1) % 4]
		for s in 101:
			var p: Vector2 = a.lerp(b, float(s) / 100.0)
			if not Geometry2D.is_point_in_polygon(p, poly):
				inside_ok = false
			margin = minf(margin, _edge_dist(p, poly))
	_check(inside_ok and margin >= 0.75, "o muro externo fica dentro da ilha, a >= 0,75 da borda (%.2f)" % margin)


# ---------------------------------------------------------------- mata

## Árvores da mata: [nó, centro (x, z), raio da copa].
func _trees(map: Node3D) -> Array:
	var out: Array = []
	var forest: Node = map.get_node_or_null("Forest")
	if forest == null:
		return out
	for child: Node in forest.get_children():
		var piece := child as KitPiece
		if piece == null:
			continue
		var kind: String = str(piece.scene_file_path.get_file().get_basename())
		if not (kind.begins_with("tree_") or kind.begins_with("conifer_")):
			continue
		var p := Vector2(piece.global_position.x, piece.global_position.z)
		out.append([piece, p, piece.size.x * 0.5 * piece.scale.x])
	return out


func _test_forest(map: Node3D) -> void:
	var trees: Array = _trees(map)
	_check(trees.size() >= 60 and trees.size() <= 82, "de 60 a 82 árvores na ilha principal (%d)" % trees.size())
	for zone: Array in ZONES:
		var rect: Rect2 = zone[1]
		var count: int = 0
		for t: Array in trees:
			if rect.has_point(t[1]):
				count += 1
		_check(count >= int(zone[2]) and count <= int(zone[3]), "zona %s: de %d a %d árvores (%d)" % [zone[0], zone[2], zone[3], count])
	var east_total: int = 0
	var east_conifers: int = 0
	for t: Array in trees:
		if EAST_ZONE.has_point(t[1]):
			east_total += 1
			if str((t[0] as KitPiece).scene_file_path.get_file()).begins_with("conifer_"):
				east_conifers += 1
	_check(east_total > 0 and east_conifers * 3 >= east_total * 2, "leste: pelo menos 2/3 coníferas (%d de %d)" % [east_conifers, east_total])
	var north_west_tip: int = 0
	var in_strip: Array[String] = []
	for t: Array in trees:
		var p: Vector2 = t[1]
		if NORTH_STRIP.has_point(p):
			in_strip.append(str((t[0] as Node).name))
		if Rect2(-9.0, -21.0, 1.0, 6.5).has_point(p):
			north_west_tip += 1
	_check(in_strip.is_empty(), "faixa norte central (x -8 a 10, z -21 a -14,5) sem tronco de árvore", str(in_strip))
	_check(north_west_tip >= 1 and north_west_tip <= 2, "norte central: 1 ou 2 folhosas na ponta oeste (%d)" % north_west_tip)
	var overlaps: Array[String] = []
	for i in trees.size():
		for j in range(i + 1, trees.size()):
			var a: Array = trees[i]
			var b: Array = trees[j]
			var d: float = (a[1] as Vector2).distance_to(b[1])
			var need: float = maxf(1.2, 0.45 * (float(a[2]) + float(b[2])))
			if d < need:
				overlaps.append("%s x %s (%.2f < %.2f)" % [(a[0] as Node).name, (b[0] as Node).name, d, need])
	_check(overlaps.is_empty(), "troncos a >= max(1,2; 0,45 x (ra + rb)) (copas encavalam até cerca da metade)", str(overlaps))
	var too_close: Array[String] = []
	var poly: PackedVector2Array = IslandTables.ISLAND_OUTLINE
	var path: PackedVector2Array = IslandTables.PATH_NE
	for t: Array in trees:
		var p: Vector2 = t[1]
		var node_name: String = str((t[0] as Node).name)
		var wall_d: float = p.distance_to(p.clamp(WALL_RECT.position, WALL_RECT.end))
		if wall_d < 1.5:
			too_close.append("%s: muro %.2f" % [node_name, wall_d])
		if _edge_dist(p, poly) < 1.0 or not Geometry2D.is_point_in_polygon(p, poly):
			too_close.append("%s: borda %.2f" % [node_name, _edge_dist(p, poly)])
		for rect: Rect2 in SLAB_RECTS:
			if p.distance_to(p.clamp(rect.position, rect.end)) < 0.75:
				too_close.append("%s: lajes" % node_name)
		var path_d: float = INF
		for i in range(path.size() - 1):
			path_d = minf(path_d, _seg_dist(p, path[i], path[i + 1]))
		if path_d - IslandTables.PATH_NE_WIDTH * 0.5 < 0.75:
			too_close.append("%s: caminho %.2f" % [node_name, path_d - IslandTables.PATH_NE_WIDTH * 0.5])
	_check(too_close.is_empty(), "troncos a >= 1,5 do muro, >= 0,75 das lajes e >= 1,0 da borda da ilha", str(too_close))
	_test_south_strip(map)


## Faixa sul (f1): 18 a 26 arbustos e 4 a 6 raízes de superfície fora da escada e do patamar; 6 a 10 cipós
## na face externa do muro sul.
func _test_south_strip(map: Node3D) -> void:
	var bushes: int = 0
	var roots: int = 0
	var vines: int = 0
	var blocked: Array[String] = []
	for node: Node in _descendants(map):
		var piece := node as KitPiece
		if piece == null:
			continue
		var kind: String = str(piece.scene_file_path.get_file().get_basename())
		var p := Vector2(piece.global_position.x, piece.global_position.z)
		if kind.begins_with("bush_") and piece.get_parent().name == "Forest" and SOUTH_STRIP.has_point(p):
			bushes += 1
			var r: float = piece.size.x * 0.5 * piece.scale.x
			for rect: Rect2 in SOUTH_KEEP_CLEAR:
				if p.distance_to(p.clamp(rect.position, rect.end)) < r:
					blocked.append(str(piece.name))
		elif kind.begins_with("root_surface_"):
			roots += 1
			var chains: Array = IslandTables.SURFACE_ROOTS["abc".find(kind.right(1))]
			for chain: Array in chains:
				for v: Vector4 in chain:
					var w: Vector3 = piece.global_transform * Vector3(v.x, v.y, v.z)
					for rect: Rect2 in SOUTH_KEEP_CLEAR:
						if rect.grow(v.w).has_point(Vector2(w.x, w.z)):
							blocked.append(str(piece.name))
		elif kind.begins_with("vine_hang_") and absf(piece.global_position.z - 13.0) < 0.2 and absf(piece.global_position.y - 1.0) < 0.1:
			vines += 1
	_check(bushes >= 18 and bushes <= 26, "faixa sul: de 18 a 26 arbustos (%d)" % bushes)
	_check(roots >= 4 and roots <= 6, "faixa sul: de 4 a 6 raízes de superfície (%d)" % roots)
	_check(vines >= 6 and vines <= 10, "faixa sul: de 6 a 10 cipós na face externa do muro (%d)" % vines)
	_check(blocked.is_empty(), "faixa sul: nenhum arbusto ou raiz sobre a escada ou o patamar", str(blocked))


# ---------------------------------------------------------------- fora da ilha

## Regra da órbita: todo vértice de Sky com raio horizontal r <= 60 tem r >= 55 ou fica abaixo de y = 0,51 r - 4.
func _test_orbit_rule(map: Node3D) -> void:
	var sky: Node = map.get_node_or_null("Sky")
	_check(sky != null and sky.get_child_count() > 0, "o mapa tem o grupo Sky")
	if sky == null:
		return
	var bad: Array[String] = []
	var checked: int = 0
	for node: Node in _descendants(sky):
		var mi := node as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var xf: Transform3D = mi.global_transform
		for s in mi.mesh.get_surface_count():
			var verts: PackedVector3Array = mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
			for v: Vector3 in verts:
				var w: Vector3 = xf * v
				var r: float = Vector2(w.x, w.z).length()
				checked += 1
				if r <= 60.0 and r < 55.0 and w.y >= 0.51 * r - 4.0:
					if bad.size() < 6:
						bad.append("%s em %s (r %.1f)" % [mi.get_parent().name, w, r])
	_check(bad.is_empty(), "regra da órbita em %d vértices de Sky (r >= 55 ou y < 0,51 r - 4)" % checked, str(bad))
	_test_horizon_ring(sky)
	var cam := MapCamera.new()
	var orbit: float = cam.max_distance * cos(deg_to_rad(27.0)) - 4.3
	_check(orbit <= 50.0, "max_distance x cos 27° - 4,3 <= 50 (%.2f)" % orbit)
	cam.free()


## Anel de nuvens do horizonte (Tabela D, f1): de 10 a 16 aglomerados largos (>= 30 de largura) com o centro a
## raio horizontal de 35 a 60 e o topo em y de -6 a -2, cobrindo o giro inteiro (nenhum vão maior que 60°).
func _test_horizon_ring(sky: Node) -> void:
	var angles: Array[float] = []
	for child: Node in sky.get_children():
		var piece := child as KitPiece
		if piece == null or not str(piece.scene_file_path.get_file()).begins_with("cloud_"):
			continue
		var r: float = Vector2(piece.global_position.x, piece.global_position.z).length()
		if r < 35.0 or r > 60.0:
			continue
		var box := AABB()
		var first := true
		for node: Node in _descendants(piece):
			var mi := node as MeshInstance3D
			if mi == null or mi.mesh == null:
				continue
			var b: AABB = mi.global_transform * mi.mesh.get_aabb()
			box = b if first else box.merge(b)
			first = false
		# Fase 3: os puffs são billboards (o quad passa do desenho); o topo é o do desenho (SceneryPieces.cloud_visible_top).
		var variant: int = "abcde".find(str(piece.scene_file_path.get_file().get_basename()).right(1))
		var top: float = piece.global_position.y + SceneryPieces.cloud_visible_top(variant) * piece.scale.y
		if first or top < -6.0 or top > -2.0 or maxf(box.size.x, box.size.z) < 30.0:
			continue
		angles.append(fposmod(rad_to_deg(atan2(piece.global_position.x, piece.global_position.z)), 360.0))
	angles.sort()
	var widest: float = 0.0
	for i in angles.size():
		var next: float = angles[(i + 1) % angles.size()] + (360.0 if i == angles.size() - 1 else 0.0)
		widest = maxf(widest, next - angles[i])
	_check(angles.size() >= 10 and angles.size() <= 16 and widest <= 60.0,
			"anel de nuvens do horizonte: de 10 a 16 aglomerados largos (%d), raio 35 a 60, topo de -6 a -2, maior vão %.0f°" % [angles.size(), widest])


## Fase 3: de 28 a 48 vaga-lumes em tabela (MultiMesh no grupo Fx), sem sombra.
func _test_fireflies(map: Node3D) -> void:
	var fx: Node = map.get_node_or_null("Fx")
	var mmi := fx.get_node_or_null("Fireflies") as MultiMeshInstance3D if fx != null else null
	var count: int = mmi.multimesh.instance_count if mmi != null and mmi.multimesh != null else 0
	_check(count >= 28 and count <= 48 and count == IslandTables.FIREFLIES.size()
			and mmi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
			"vaga-lumes: de 28 a 48 na tabela, no grupo Fx e sem sombra (%d)" % count)


func _test_braziers(map: Node3D) -> void:
	var braziers: int = 0
	var lights: Array[OmniLight3D] = []
	for node: Node in _descendants(map):
		if node is KitPiece and str(node.scene_file_path).ends_with("/brazier_a.tscn"):
			braziers += 1
		if node is OmniLight3D:
			lights.append(node as OmniLight3D)
	var lights_ok := true
	for light: OmniLight3D in lights:
		if light.shadow_enabled or light.omni_range > 4.0:
			lights_ok = false
	_check(braziers == 10 and lights.size() == 10, "10 braseiros e 10 OmniLight3D (%d e %d)" % [braziers, lights.size()])
	_check(lights_ok, "todas as OmniLight3D sem sombra e com alcance <= 4")


func _test_no_river(map: Node3D) -> void:
	var found: Array[String] = []
	for group: Node in map.get_children():
		if group.name == "Sky":
			continue
		for node: Node in _descendants(group):
			var kind: String = str(node.scene_file_path.get_file().get_basename())
			if kind.begins_with("river_") or kind == "bridge_wood" or kind == "waterfall" or kind.begins_with("lake"):
				found.append(str(node.get_path()))
	_check(found.is_empty(), "sem rio, lagoa, ponte sobre rio nem cascata fora de Sky", str(found))


# ---------------------------------------------------------------- código e ferramentas

func _test_forbidden_code() -> void:
	var hits: Array[String] = []
	for dir_path: String in ["res://scripts/map", "res://scripts/match", "res://tools/kit"]:
		_scan(dir_path, hits)
	_check(hits.is_empty(), "scripts/map, scripts/match e tools/kit sem RandomNumberGenerator, FastNoiseLite, randi, randf, randomize", str(hits))


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


## place_decor.gd sem --force sai com código diferente de 0 e não muda o map.tscn.
func _test_place_decor_force() -> void:
	var before: String = FileAccess.get_md5(MAP_PATH)
	var output: Array = []
	var code: int = OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
			"--script", "res://tools/kit/place_decor.gd"], output, true)
	var after: String = FileAccess.get_md5(MAP_PATH)
	_check(code != 0 and before == after, "place_decor.gd sem --force sai com código %d (!= 0) e não altera o map.tscn" % code)


static func _descendants(root_node: Node) -> Array[Node]:
	var out: Array[Node] = []
	var stack: Array[Node] = [root_node]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		out.append(node)
		for child: Node in node.get_children():
			stack.append(child)
	return out
