extends SceneTree
## Construtor do kit do mapa (spec 011, fase 2). Rodar da raiz do projeto, depois do comando de
## validação 1 (que registra os class_name):
##   "$G" --headless --path . --script tools/kit/build_kit.gd
## Grava: assets/materials/*.tres (um por linha de KitMaterialDefs), assets/models/kit/*.res (uma
## malha por peça, montada das tabelas de KitTables) e scenes/kit/*.tscn (KitPiece + malha +
## marcadores). Sem sorteio: rodar de novo regrava arquivos idênticos. Não mexe em scenes/map.tscn.

const MESH_DIR: String = "res://assets/models/kit/"
## MultiMesh dos tufos, das flores e dos vaga-lumes (spec 012, item 9 e Fase 3), em .tres de texto.
const SCATTER_DIR: String = "res://assets/models/scatter/"
const SCENE_DIR: String = "res://scenes/kit/"
## Peças que não projetam sombra (chão e decalques); as do cenário pintado usam "no_shadow" na tabela.
const NO_SHADOW_BUILDS: PackedStringArray = ["ground", "decal"]
## Luz dos braseiros (spec 012): cor quente, sem sombra.
const LIGHT_COLOR: Color = Color("#ffb066")


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MESH_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCENE_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(KitMaterialDefs.OUT_DIR))
	var defs: Dictionary = KitMaterialDefs.all()
	var materials: Dictionary = _write_materials(defs)
	materials.merge(_write_scenery_materials(KitMaterialDefs.scenery()))
	var tangent_keys: Dictionary = {}
	for key: String in defs.keys():
		var entry: Dictionary = defs[key]
		tangent_keys[key] = int(entry.get("mode", 0)) == 0 and bool(entry.get("normal", false))
	var count: int = 0
	var tris: int = 0
	for entry: Dictionary in KitTables.catalog():
		var mesher: KitMesher = KitPieces.build(entry)
		for key: String in mesher.batches.keys():
			if not materials.has(key):
				push_error("Material sem definição: %s (peça %s)" % [key, entry["name"]])
				quit(1)
				return
			tris += (mesher.batches[key] as MeshBatch).vertices.size() / 3
		var mesh: ArrayMesh = mesher.to_mesh(materials, tangent_keys)
		var mesh_path: String = MESH_DIR + str(entry["name"]) + ".res"
		if ResourceSaver.save(mesh, mesh_path) != OK:
			push_error("Falha ao gravar " + mesh_path)
			quit(1)
			return
		var saved: ArrayMesh = ResourceLoader.load(mesh_path, "", ResourceLoader.CACHE_MODE_REPLACE) as ArrayMesh
		if _write_scene(entry, saved):
			count += 1
	var scatter: int = _write_scatter(materials)
	print("Kit: %d malhas e cenas gravadas, %d triângulos no total, %d materiais, %d tufos/flores" % [count, tris, materials.size(), scatter])
	quit(0)


## Grava um .tres por material e devolve os recursos recarregados do disco (referência externa nas malhas).
func _write_materials(defs: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	var keys: Array = defs.keys()
	keys.sort()
	for key: String in keys:
		var path: String = KitMaterialDefs.OUT_DIR + key + ".tres"
		var mat: ShaderMaterial = KitMaterialDefs.make(defs[key])
		if ResourceSaver.save(mat, path) != OK:
			push_error("Falha ao gravar " + path)
			continue
		out[key] = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
	return out


## Grava os MultiMesh de tufos e flores das tabelas de ScatterTables; devolve o total de instâncias.
func _write_scatter(materials: Dictionary) -> int:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCATTER_DIR))
	var total: int = 0
	total += _save_scatter("tufts_arena", ScatterTables.ARENA_TUFTS, ScatterTables.ARENA_TUFT_SIZE, materials["tuft_grass_arena"], false)
	total += _save_scatter("tufts_outer", ScatterTables.OUTER_TUFTS, ScatterTables.OUTER_TUFT_SIZE, materials["tuft_grass"], false)
	total += _save_scatter("flowers", ScatterTables.FLOWERS, ScatterTables.FLOWER_SIZE, materials["tuft_flower"], true)
	total += _save_fireflies(materials["firefly"])
	return total


## Vaga-lumes (spec 012, Fase 3): um quad (cantos ±1 no plano XY, o shader faz o billboard) por ponto da tabela.
func _save_fireflies(material: Material) -> int:
	var m := KitMesher.new()
	m.quad("firefly", Vector3(-1.0, 1.0, 0.0), Vector3(1.0, 1.0, 0.0), Vector3(1.0, -1.0, 0.0), Vector3(-1.0, -1.0, 0.0), Vector3(0.0, 0.0, 1.0),
			Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 1.0), Vector2(0.0, 1.0))
	var items: Array[Transform3D] = []
	for p: Vector3 in IslandTables.FIREFLIES:
		items.append(Transform3D(Basis.IDENTITY, p))
	var no_colors: Array[Color] = []
	_write_multimesh("fireflies", m.to_mesh({"firefly": material}, {}), items, no_colors)
	return items.size()


func _save_scatter(file_name: String, groups: Array, size: Vector2, material: Material, with_colors: bool) -> int:
	var items: Array[Transform3D] = []
	var colors: Array[Color] = []
	for g: Array in groups:
		var center := Vector3(float(g[0]), float(g[1]), float(g[2]))
		var turn: float = deg_to_rad(float(g[3]))
		var pattern: Array = ScatterTables.PATTERNS[int(g[4])]
		var k: int = 0
		for off: Vector3 in pattern:
			var d := Vector2(off.x, off.y).rotated(turn)
			var b := Basis(Vector3.UP, turn + deg_to_rad(37.0 * float(k))).scaled(Vector3(off.z, off.z, off.z))
			var spot: Vector3 = center + Vector3(d.x, 0.0, d.y)
			# Fase 3: os tufos agora aparecem (o buffer antes saía vazio); os que caíam fora da ilha (tabelas da
			# ilha antiga) ficam de fora.
			if not _on_island(Vector2(spot.x, spot.z)):
				k += 1
				continue
			items.append(Transform3D(b, spot))
			if with_colors:
				colors.append(ScatterTables.FLOWER_COLORS[(int(g[5]) + k) % ScatterTables.FLOWER_COLORS.size()])
			k += 1
	if not with_colors:
		colors.clear()
	_write_multimesh(file_name, _tuft_mesh(size, material), items, colors)
	return items.size()


## Ponto dentro do contorno da ilha e a pelo menos ISLAND_MARGIN da borda.
const ISLAND_MARGIN: float = 0.4


static func _on_island(p: Vector2) -> bool:
	var poly: PackedVector2Array = IslandTables.ISLAND_OUTLINE
	if not Geometry2D.is_point_in_polygon(p, poly):
		return false
	for i in poly.size():
		var q: Vector2 = Geometry2D.get_closest_point_to_segment(p, poly[i], poly[(i + 1) % poly.size()])
		if p.distance_to(q) < ISLAND_MARGIN:
			return false
	return true


## Grava o MultiMesh como .tres de texto com o buffer escrito aqui. No modo headless o servidor de renderização
## é o "dummy" e não guarda o buffer de MultiMesh.set_instance_transform (o .res saía com todas as instâncias
## na origem). A malha vai num .res próprio. Buffer por instância: base em linhas + origem (12) e cor (4).
func _write_multimesh(file_name: String, mesh: ArrayMesh, items: Array[Transform3D], colors: Array[Color]) -> void:
	var mesh_path: String = SCATTER_DIR + file_name + "_mesh.res"
	if ResourceSaver.save(mesh, mesh_path) != OK:
		push_error("Falha ao gravar " + mesh_path)
		return
	var values := PackedStringArray()
	for i in items.size():
		var t: Transform3D = items[i]
		var b: Basis = t.basis
		for v: float in [b.x.x, b.y.x, b.z.x, t.origin.x, b.x.y, b.y.y, b.z.y, t.origin.y, b.x.z, b.y.z, b.z.z, t.origin.z]:
			values.append(_num(v))
		if not colors.is_empty():
			for v: float in [colors[i].r, colors[i].g, colors[i].b, colors[i].a]:
				values.append(_num(v))
	var text: String = "[gd_resource type=\"MultiMesh\" load_steps=2 format=3]\n\n"
	text += "[ext_resource type=\"ArrayMesh\" path=\"%s\" id=\"1_mesh\"]\n\n" % mesh_path
	text += "[resource]\ntransform_format = 1\n"
	if not colors.is_empty():
		text += "use_colors = true\n"
	text += "instance_count = %d\nmesh = ExtResource(\"1_mesh\")\nbuffer = PackedFloat32Array(%s)\n" % [items.size(), ", ".join(values)]
	var path: String = SCATTER_DIR + file_name + ".tres"
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("Falha ao gravar " + path)
		return
	f.store_string(text)
	f.close()


static func _num(v: float) -> String:
	var r: float = snappedf(v, 0.00001)
	return "0" if is_zero_approx(r) else str(r)


## Tufo: 3 cartões cruzados de 60°, normal para cima (assenta no chão); UV.y = número do cartão.
func _tuft_mesh(size: Vector2, material: Material) -> ArrayMesh:
	var m := KitMesher.new()
	for k in 3:
		var ang: float = deg_to_rad(60.0 * float(k))
		var d := Vector3(cos(ang), 0.0, sin(ang)) * size.x * 0.5
		var up := Vector3(0.0, size.y, 0.0)
		var id: float = float(k)
		m.tri("tuft", -d + up, d + up, d, Vector3.UP, Vector3.UP, Vector3.UP, Vector2(0.0, id), Vector2(1.0, id), Vector2(1.0, id + 0.999))
		m.tri("tuft", -d + up, d, -d, Vector3.UP, Vector3.UP, Vector3.UP, Vector2(0.0, id), Vector2(1.0, id + 0.999), Vector2(0.0, id + 0.999))
	return m.to_mesh({"tuft": material}, {})


## Materiais provisórios do cenário pintado (spec 012): um .tres por linha de KitMaterialDefs.scenery().
func _write_scenery_materials(defs: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	var keys: Array = defs.keys()
	keys.sort()
	for key: String in keys:
		var path: String = KitMaterialDefs.OUT_DIR + key + ".tres"
		if ResourceSaver.save(KitMaterialDefs.make_scenery(defs[key]), path) != OK:
			push_error("Falha ao gravar " + path)
			continue
		out[key] = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
	return out


## Reaproveita a cena que já existe (mantém os unique_id dos nós e o diff do repositório limpo):
## só troca a malha e as propriedades. Cria uma nova quando não há cena ou a estrutura mudou.
func _write_scene(entry: Dictionary, mesh: ArrayMesh) -> bool:
	var path: String = SCENE_DIR + str(entry["name"]) + ".tscn"
	var root: KitPiece = _load_existing(path, entry)
	if root == null:
		root = _fresh_root(entry)
	root.name = str(entry["name"])
	root.size = entry["size"]
	root.structural = bool(entry.get("structural", false))
	root.obstacle = bool(entry.get("obstacle", false))
	var mesh_node := root.get_node("Mesh") as MeshInstance3D
	mesh_node.mesh = mesh
	mesh_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if _no_shadow(entry) \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	# Billboards (nuvens e névoa) giram no shader: a margem evita o descarte na borda do quadro.
	mesh_node.extra_cull_margin = float(entry.get("cull_margin", 0.0))
	if entry.has("light"):
		var light_spec: Array = entry["light"]
		var light: OmniLight3D = root.get_node("Light")
		light.position = Vector3(0.0, float(light_spec[0]), 0.0)
		light.omni_range = float(light_spec[1])
		light.light_energy = float(light_spec[2])
		light.light_color = LIGHT_COLOR
		light.shadow_enabled = false
	if entry.has("stair"):
		var spec: Array = entry["stair"]
		var stair: StairArea = root.get_node("Stair")
		stair.size = Vector2(float(spec[1]), float(spec[2]))
		stair.step_count = int(spec[3])
		# 5º campo opcional: deslocamento em Z local do trecho andável.
		stair.position = Vector3(0.0, float(spec[0]), float(spec[4]) if spec.size() > 4 else 0.0)
	var index: int = 0
	for area_spec: Array in entry.get("areas", []):
		var area: HeightArea = root.get_node("Height" if index == 0 else "Height%d" % (index + 1))
		area.size = Vector2(float(area_spec[3]), float(area_spec[4]))
		area.top = float(area_spec[5])
		area.position = Vector3(float(area_spec[0]), float(area_spec[1]), float(area_spec[2]))
		index += 1
	var packed := PackedScene.new()
	if packed.pack(root) != OK:
		push_error("Falha ao empacotar " + str(entry["name"]))
		root.free()
		return false
	var err: Error = ResourceSaver.save(packed, path)
	root.free()
	if err != OK:
		push_error("Falha ao gravar %s (erro %d)" % [path, err])
		return false
	return true


## Nomes dos filhos que a cena da tabela deve ter.
func _expected_children(entry: Dictionary) -> PackedStringArray:
	var names: PackedStringArray = ["Mesh"]
	if entry.has("light"):
		names.append("Light")
	if entry.has("stair"):
		names.append("Stair")
	var index: int = 0
	for _area_spec: Array in entry.get("areas", []):
		names.append("Height" if index == 0 else "Height%d" % (index + 1))
		index += 1
	return names


func _no_shadow(entry: Dictionary) -> bool:
	return NO_SHADOW_BUILDS.has(str(entry["build"])) or bool(entry.get("no_shadow", false))


func _load_existing(path: String, entry: Dictionary) -> KitPiece:
	if not ResourceLoader.exists(path):
		return null
	var packed := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE) as PackedScene
	var root := packed.instantiate() as KitPiece if packed != null else null
	if root == null:
		return null
	var expected: PackedStringArray = _expected_children(entry)
	var found: PackedStringArray = PackedStringArray()
	for child: Node in root.get_children():
		found.append(str(child.name))
	found.sort()
	expected.sort()
	if found != expected:
		root.free()
		return null
	return root


func _fresh_root(entry: Dictionary) -> KitPiece:
	var root := KitPiece.new()
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = "Mesh"
	root.add_child(mesh_node)
	mesh_node.owner = root
	if entry.has("light"):
		var light := OmniLight3D.new()
		light.name = "Light"
		root.add_child(light)
		light.owner = root
	if entry.has("stair"):
		var stair := StairArea.new()
		stair.name = "Stair"
		root.add_child(stair)
		stair.owner = root
	var index: int = 0
	for _area_spec: Array in entry.get("areas", []):
		var area := HeightArea.new()
		area.name = "Height" if index == 0 else "Height%d" % (index + 1)
		root.add_child(area)
		area.owner = root
		index += 1
	return root
