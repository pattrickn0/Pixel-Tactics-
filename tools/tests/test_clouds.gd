extends SceneTree
## Nuvens volumétricas (spec 013): sem billboard, sol só no uniform global (publicado a partir do nó Sun), tabela
## CloudTables nas faixas da Tabela N3 (lóbulos, topo <= +6, proxies que contêm os lóbulos), anel das vistas giradas,
## regra da órbita e visibilidade da arena com os proxies, layout sem sorteio e build reproduzível (md5).
## Rodar depois do comando de validação 1 e de tools/kit/build_clouds.gd:
##   "$G" --headless --path . --script tools/tests/test_clouds.gd
## Imprime PASS/FAIL por verificação e sai com 0 (tudo passou) ou 1.

const MAP_PATH: String = "res://scenes/map.tscn"
const SHADER_PATH: String = "res://assets/materials/cloud_volume.gdshader"
const BUILD_PATH: String = "res://tools/kit/build_clouds.gd"
const MAX_TOP: float = 6.0
## Faixas da Tabela N3: massa (ou prefixo) -> [raio mínimo dos grandes, grandes mín, máx, raio máximo das bolotas,
## bolotas mín, máx]. Lóbulos entre os dois raios são intermediários (sem limite).
const LOBE_RANGES: Dictionary = {
	"M1": [4.0, 5, 7, 3.0, 8, 12],
	"M2": [5.0, 3, 4, 3.0, 0, 99],
	"M3_R": [3.5, 3, 5, 3.0, 0, 99],
	"M4": [5.0, 2, 2, 3.5, 4, 6],
	"M5": [5.0, 4, 6, 4.0, 0, 8],
	"M6": [8.0, 3, 4, 4.5, 8, 10],
	"M7_R": [3.5, 3, 5, 3.0, 0, 99],
}
## Massas obrigatórias da vista padrão (Tabela N3) e o mar.
const REQUIRED: PackedStringArray = ["M1", "M2", "M2b", "M3_R1", "M3_R2", "M3_R3", "M3_R4", "M4", "M5", "M6", "M7_R1", "M7_R2",
		"M7_R3", "M8", "Sea"]
const BANNED: PackedStringArray = ["cloud_puffs.png", "cloud_puff.gdshader", "mist_puff"]

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
	var map := (load(MAP_PATH) as PackedScene).instantiate() as Node3D
	root.add_child(map)
	await process_frame
	var clouds: Array[MeshInstance3D] = _cloud_nodes(map)
	_test_no_billboard(map, clouds)
	_test_table()
	_test_orbit_and_visibility(clouds)
	_test_ring(clouds)
	map.queue_free()
	await process_frame
	await _test_sun_global()
	_test_shader_code()
	_test_forbidden_code()
	_test_reproducible()
	print("")
	if _failures == 0:
		print("RESULTADO: PASS (%d verificações)" % _passes)
	else:
		print("RESULTADO: FAIL (%d de %d verificações falharam)" % [_failures, _passes + _failures])
	quit(0 if _failures == 0 else 1)


static func _descendants(node: Node) -> Array[Node]:
	var out: Array[Node] = []
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		out.append(n)
		for c: Node in n.get_children():
			stack.append(c)
	return out


func _cloud_nodes(map: Node3D) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	var group: Node = map.get_node_or_null("Sky/Clouds")
	_check(group != null, "o mapa tem o grupo Sky/Clouds")
	if group == null:
		return out
	for node: Node in _descendants(group):
		if node is MeshInstance3D:
			out.append(node as MeshInstance3D)
	return out


# ---------------------------------------------------------------- sem billboard

func _test_no_billboard(map: Node3D, clouds: Array[MeshInstance3D]) -> void:
	var wrong: Array[String] = []
	for mi: MeshInstance3D in clouds:
		var sm := mi.material_override as ShaderMaterial
		if sm == null or sm.shader == null or sm.shader.resource_path != SHADER_PATH:
			wrong.append(str(mi.name))
	_check(not clouds.is_empty() and wrong.is_empty(), "todo nó com malha em Sky/Clouds usa o cloud_volume.gdshader (%d nós)" % clouds.size(),
			str(wrong))
	var names: Dictionary = {}
	for mi: MeshInstance3D in clouds:
		names[str(mi.name)] = true
	var missing: Array[String] = []
	for n: String in REQUIRED:
		if not names.has(n):
			missing.append(n)
	_check(missing.is_empty(), "as massas da Tabela N3 e o mar estão em Sky/Clouds", str(missing))
	var bad: Array[String] = []
	for node: Node in _descendants(map):
		var file: String = str(node.scene_file_path.get_file())
		if file.begins_with("cloud_") or file == "mist_a.tscn" or str(node.name).begins_with("cloud_") or str(node.name).begins_with("mist_a"):
			bad.append(str(node.name))
		var gi := node as GeometryInstance3D
		if gi == null:
			continue
		var mats: Array[Material] = [gi.material_override]
		var mi := node as MeshInstance3D
		if mi != null and mi.mesh != null:
			for s in mi.mesh.get_surface_count():
				mats.append(mi.mesh.surface_get_material(s))
		for mat: Material in mats:
			var sm := mat as ShaderMaterial
			if sm != null and sm.shader != null and sm.shader.resource_path.ends_with("cloud_puff.gdshader"):
				bad.append("%s (cloud_puff)" % node.name)
			var std := mat as BaseMaterial3D
			if std != null and std.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED:
				bad.append("%s (billboard)" % node.name)
	_check(bad.is_empty(), "o mapa não tem cloud_a..e, mist_a, cloud_sea, cloud_puff nem billboard", str(bad))
	var hits: Array[String] = []
	for dir_path: String in ["res://scenes", "res://scripts", "res://tools/kit"]:
		_grep(dir_path, BANNED, hits)
	_check(hits.is_empty(), "scenes/, scripts/ e tools/kit/ sem cloud_puffs.png, cloud_puff.gdshader e mist_puff", str(hits))


func _grep(dir_path: String, words: PackedStringArray, hits: Array[String]) -> void:
	for file_name: String in DirAccess.get_files_at(dir_path):
		if not (file_name.ends_with(".gd") or file_name.ends_with(".tscn") or file_name.ends_with(".tres")):
			continue
		var text: String = FileAccess.get_file_as_string(dir_path + "/" + file_name)
		for w: String in words:
			if text.contains(w):
				hits.append("%s/%s: %s" % [dir_path, file_name, w])
	for sub: String in DirAccess.get_directories_at(dir_path):
		_grep(dir_path + "/" + sub, words, hits)


# ---------------------------------------------------------------- tabela

static func _lobe_top(pos: Vector3, l: Array) -> float:
	var ay: float = float(l[5]) if l.size() >= 7 else 1.0
	return pos.y + float(l[1]) + float(l[3]) * ay


func _test_table() -> void:
	var problems: Array[String] = []
	var highest: float = -INF
	for mass: Dictionary in CloudTables.MASSES:
		var mass_name: String = str(mass["name"])
		var pos: Vector3 = mass["pos"]
		var box: AABB = mass["proxy"]
		var lobes: Array = mass.get("lobes", [])
		if lobes.size() > 32:
			problems.append("%s: %d lóbulos (máx. 32)" % [mass_name, lobes.size()])
		for l: Array in lobes:
			highest = maxf(highest, _lobe_top(pos, l))
			var ax := Vector3(float(l[4]), float(l[5]), float(l[6])) if l.size() >= 7 else Vector3.ONE
			var c := Vector3(float(l[0]), float(l[1]), float(l[2]))
			var half: Vector3 = ax * float(l[3])
			if not (box.has_point(c - half + Vector3.ONE * 0.01) and box.has_point(c + half - Vector3.ONE * 0.01)):
				problems.append("%s: lóbulo fora do proxy (%s)" % [mass_name, c])
		if mass.has("layer"):
			var layer: Array = mass["layer"]
			highest = maxf(highest, pos.y + float(layer[0]) + float(layer[1]))
		var key: String = ""
		for k: String in LOBE_RANGES.keys():
			if mass_name == k or (k.ends_with("_R") and mass_name.begins_with(k)):
				key = k
		if key == "":
			continue
		var rng: Array = LOBE_RANGES[key]
		var big: int = 0
		var small: int = 0
		for l: Array in lobes:
			var r: float = float(l[3])
			if r >= float(rng[0]):
				big += 1
			elif r <= float(rng[3]):
				small += 1
		if big < int(rng[1]) or big > int(rng[2]) or small < int(rng[4]) or small > int(rng[5]):
			problems.append("%s: %d grandes (%d a %d) e %d bolotas (%d a %d)" % [mass_name, big, rng[1], rng[2], small, rng[4], rng[5]])
	_check(problems.is_empty(), "tabela: lóbulos de cada massa nas faixas da Tabela N3, dentro do proxy e no máximo 32", str(problems))
	_check(highest <= MAX_TOP, "nenhuma nuvem passa de y +6 (topo mais alto %.2f)" % highest)


# ---------------------------------------------------------------- órbita e visibilidade

static func _world_box(mi: MeshInstance3D) -> AABB:
	return mi.global_transform * mi.mesh.get_aabb()


func _test_orbit_and_visibility(clouds: Array[MeshInstance3D]) -> void:
	var bad: Array[String] = []
	var top: float = -INF
	for mi: MeshInstance3D in clouds:
		if mi.mesh == null:
			bad.append("%s sem malha" % mi.name)
			continue
		for v: Vector3 in mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			var w: Vector3 = mi.global_transform * v
			var r: float = Vector2(w.x, w.z).length()
			top = maxf(top, w.y)
			if r < 55.0 and w.y >= 0.51 * r - 4.0 and bad.size() < 6:
				bad.append("%s em %s (r %.1f)" % [mi.name, w, r])
	_check(bad.is_empty(), "regra da órbita nos vértices dos proxies (r >= 55 ou y < 0,51 r - 4)", str(bad))
	# Nenhum proxy entre a câmera e a arena (8 giros, distância padrão e máxima).
	var cam := MapCamera.new()
	var blocked: Array[String] = []
	for dist: float in [cam.start_distance, cam.max_distance]:
		for k in 8:
			var yaw: float = 45.0 * float(k)
			var eye: Vector3 = cam.transform_for(yaw, dist).origin
			for x in range(-10, 11, 2):
				for z in range(-9, 10, 2):
					var p := Vector3(float(x), 0.6, float(z))
					for mi: MeshInstance3D in clouds:
						if mi.mesh != null and _world_box(mi).intersects_segment(p, eye) != null:
							if blocked.size() < 6:
								blocked.append("yaw %.0f dist %.0f: %s" % [yaw, dist, mi.name])
	cam.free()
	_check(blocked.is_empty(), "nenhum volume de nuvem entre a câmera e a arena (8 giros, distância padrão e máxima)", str(blocked))


## Anel das vistas giradas: em cada lado (N, L, S, O) uma fileira (centro a raio de 30 a 60, topo de -12 a -2) e uma massa
## de fundo (raio de 70 a 130, topo <= +6); o maior vão entre as fileiras em volta da ilha fica <= 90°.
func _test_ring(clouds: Array[MeshInstance3D]) -> void:
	var rows: Array[float] = []
	var far_sides: Dictionary = {}
	var row_sides: Dictionary = {}
	for mi: MeshInstance3D in clouds:
		if mi.mesh == null or str(mi.name) == "Sea":
			continue
		var box: AABB = _world_box(mi)
		var c: Vector3 = box.get_center()
		var r: float = Vector2(c.x, c.z).length()
		var ang: float = fposmod(rad_to_deg(atan2(c.x, -c.z)), 360.0)
		var side: int = int(fposmod(ang + 45.0, 360.0) / 90.0)
		var top: float = _mass_top(str(mi.name))
		if r >= 30.0 and r <= 60.0 and top >= -12.0 and top <= -2.0:
			rows.append(ang)
			row_sides[side] = true
		elif r >= 70.0 and r <= 130.0 and top <= MAX_TOP:
			far_sides[side] = true
	rows.sort()
	var widest: float = 360.0
	if rows.size() > 1:
		widest = 0.0
		for i in rows.size():
			var next: float = rows[(i + 1) % rows.size()] + (360.0 if i == rows.size() - 1 else 0.0)
			widest = maxf(widest, next - rows[i])
	_check(row_sides.size() == 4 and far_sides.size() == 4 and widest <= 90.0,
			"anel: fileiras e massas de fundo nos 4 lados (fileiras em %d lados, fundo em %d), maior vão entre fileiras %.0f°" % [
			row_sides.size(), far_sides.size(), widest])


static func _mass_top(mass_name: String) -> float:
	for mass: Dictionary in CloudTables.MASSES:
		if str(mass["name"]) == mass_name:
			var top: float = -INF
			for l: Array in mass.get("lobes", []):
				top = maxf(top, _lobe_top(mass["pos"], l))
			return top
	return INF


# ---------------------------------------------------------------- sol só no global

func _test_sun_global() -> void:
	for key: String in ["sun_direction", "sun_color", "sun_energy", "cloud_time", "island_shadow_mask", "island_shadow_rect"]:
		_check(ProjectSettings.has_setting("shader_globals/" + key), "uniform global %s declarado em project.godot" % key)
	var holder := Node3D.new()
	root.add_child(holder)
	var sun := DirectionalLight3D.new()
	holder.add_child(sun)
	var globals := SkyGlobals.new()
	globals.sun = sun
	holder.add_child(globals)
	await process_frame
	var worst: float = 0.0
	for rot: Vector3 in [Vector3(-34.0, -112.5, 0.0), Vector3(-60.0, 30.0, 0.0), Vector3(-15.0, 170.0, 0.0)]:
		sun.rotation_degrees = rot
		globals.publish()
		var expected: Vector3 = sun.global_transform.basis.z.normalized()
		worst = maxf(worst, globals.published_direction.distance_to(expected))
		var stored: Variant = RenderingServer.global_shader_parameter_get(&"sun_direction")
		if stored is Vector3:
			worst = maxf(worst, (stored as Vector3).distance_to(expected))
	sun.light_energy = 0.7
	globals.publish()
	_check(worst < 0.001 and is_equal_approx(globals.published_energy, 0.7),
			"girar o Sun muda o uniform global sun_direction (erro %.4f) e a energia segue o nó" % worst)
	globals.freeze()
	_check(globals.frozen and globals.cloud_time == 0.0, "na captura o tempo das nuvens fica em 0")
	holder.queue_free()
	await process_frame


func _test_shader_code() -> void:
	var code: String = FileAccess.get_file_as_string(SHADER_PATH)
	_check(code.contains("global uniform vec3 sun_direction;"), "o shader lê a direção do sol do uniform global")
	var assigns: bool = code.contains("sun_direction =") or code.contains("LIGHT0_DIRECTION") or code.contains("LIGHT_DIRECTION")
	# Nenhum vetor do sol da cena escrito no shader (componentes da direção padrão).
	var literal: bool = code.contains("0.766") or code.contains("0.559") or code.contains("0.317") or code.contains("112.5")
	_check(not assigns and not literal, "o shader não tem direção de sol escrita nem atribui o global")


func _test_forbidden_code() -> void:
	var hits: Array[String] = []
	for dir_path: String in ["res://scripts/map", "res://scripts/match", "res://tools/kit"]:
		_grep(dir_path, ["RandomNumberGenerator", "FastNoiseLite", "randi(", "randf(", "randomize"], hits)
	_check(hits.is_empty(), "scripts/map, scripts/match e tools/kit sem sorteio", str(hits))


# ---------------------------------------------------------------- build reproduzível

func _test_reproducible() -> void:
	var build: Script = load(BUILD_PATH)
	var shader := load(SHADER_PATH) as Shader
	var tmp: String = OS.get_user_data_dir().path_join("test_clouds")
	DirAccess.make_dir_recursive_absolute(tmp)
	var diff: Array[String] = []
	for mass: Dictionary in CloudTables.MASSES:
		var mass_name: String = str(mass["name"])
		var sums: Array[String] = []
		for run in 2:
			var mesh_path: String = tmp.path_join("%s_%d.res" % [mass_name, run])
			var mat_path: String = tmp.path_join("%s_%d.tres" % [mass_name, run])
			ResourceSaver.save(build.call("proxy_mesh", mass["proxy"]), mesh_path)
			ResourceSaver.save(build.call("make_material", shader, mass), mat_path)
			sums.append(FileAccess.get_md5(mesh_path) + FileAccess.get_md5(mat_path))
		if sums[0] != sums[1]:
			diff.append(mass_name + " (duas gerações diferentes)")
		var disk_mat: String = ProjectSettings.globalize_path("res://assets/materials/clouds/cloud_%s.tres" % mass_name)
		var disk_mesh: String = ProjectSettings.globalize_path("res://assets/models/clouds/%s.res" % mass_name)
		if FileAccess.get_md5(disk_mat) != FileAccess.get_md5(tmp.path_join("%s_0.tres" % mass_name)) \
				or FileAccess.get_md5(disk_mesh) != FileAccess.get_md5(tmp.path_join("%s_0.res" % mass_name)):
			diff.append(mass_name + " (diferente do arquivo no repositório: rode tools/kit/build_clouds.gd)")
	var mask_a: Image = build.call("island_mask")
	var mask_b: Image = build.call("island_mask")
	if mask_a.get_data() != mask_b.get_data():
		diff.append("máscara da sombra da ilha")
	_check(diff.is_empty(), "materiais, proxies e máscara das nuvens: duas gerações dão arquivos idênticos (md5) e iguais aos do disco",
			str(diff))
