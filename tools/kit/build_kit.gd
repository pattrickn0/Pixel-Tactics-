extends SceneTree
## Construtor do kit do mapa (spec 011, fase 2). Rodar da raiz do projeto, depois do comando de
## validação 1 (que registra os class_name):
##   "$G" --headless --path . --script tools/kit/build_kit.gd
## Grava: assets/materials/*.tres (um por linha de KitMaterialDefs), assets/models/kit/*.res (uma
## malha por peça, montada das tabelas de KitTables) e scenes/kit/*.tscn (KitPiece + malha +
## marcadores). Sem sorteio: rodar de novo regrava arquivos idênticos. Não mexe em scenes/map.tscn.

const MESH_DIR: String = "res://assets/models/kit/"
const SCENE_DIR: String = "res://scenes/kit/"
## Peças que não projetam sombra (chão e decalques).
const NO_SHADOW_BUILDS: PackedStringArray = ["ground", "decal"]


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MESH_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCENE_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(KitMaterialDefs.OUT_DIR))
	var defs: Dictionary = KitMaterialDefs.all()
	var materials: Dictionary = _write_materials(defs)
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
	print("Kit: %d malhas e cenas gravadas, %d triângulos no total, %d materiais" % [count, tris, materials.size()])
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


func _write_scene(entry: Dictionary, mesh: ArrayMesh) -> bool:
	var root := KitPiece.new()
	root.name = str(entry["name"])
	root.size = entry["size"]
	root.structural = bool(entry.get("structural", false))
	root.obstacle = bool(entry.get("obstacle", false))
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = "Mesh"
	mesh_node.mesh = mesh
	if NO_SHADOW_BUILDS.has(str(entry["build"])):
		mesh_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mesh_node)
	mesh_node.owner = root
	if entry.has("stair"):
		var spec: Array = entry["stair"]
		var stair := StairArea.new()
		stair.name = "Stair"
		stair.size = Vector2(float(spec[1]), float(spec[2]))
		stair.step_count = int(spec[3])
		stair.position = Vector3(0.0, float(spec[0]), 0.0)
		root.add_child(stair)
		stair.owner = root
	var index: int = 0
	for area_spec: Array in entry.get("areas", []):
		var area := HeightArea.new()
		area.name = "Height" if index == 0 else "Height%d" % (index + 1)
		area.size = Vector2(float(area_spec[3]), float(area_spec[4]))
		area.top = float(area_spec[5])
		area.position = Vector3(float(area_spec[0]), float(area_spec[1]), float(area_spec[2]))
		root.add_child(area)
		area.owner = root
		index += 1
	var packed := PackedScene.new()
	if packed.pack(root) != OK:
		push_error("Falha ao empacotar " + str(entry["name"]))
		root.free()
		return false
	var path: String = SCENE_DIR + str(entry["name"]) + ".tscn"
	var err: Error = ResourceSaver.save(packed, path)
	root.free()
	if err != OK:
		push_error("Falha ao gravar %s (erro %d)" % [path, err])
		return false
	return true
