extends SceneTree
## Aplica a tabela de montagem (tools/kit/map_decor_table.gd) em scenes/map.tscn: troca só os grupos
## decorativos (MapDecorTable.GROUPS: ilha, estruturas, decalques, mata, props, tufos, céu e névoa) e mantém
## o anel, as escadas, o chão e os marcadores como estão. Sem sorteio: cada peça vem de uma linha da tabela.
## ATENÇÃO (spec 012): scenes/map.tscn é a fonte de verdade. Este script APAGA o que foi ajustado à mão nesses
## grupos, por isso só roda com a flag explícita --force (e avisa quantos nós vai trocar):
##   "$G" --headless --path . --script tools/kit/place_decor.gd -- --force
## (rodar depois de tools/kit/build_kit.gd e tools/kit/build_clouds.gd e, se o anel mudou, de
## tools/kit/gen_initial_map.gd -- --force)
## Nuvens (spec 013): um nó por massa da tabela CloudTables em Sky/Clouds (proxy + material de build_clouds.gd).

const MAP_PATH: String = "res://scenes/map.tscn"
const KIT_DIR: String = "res://scenes/kit/"
const SCATTER_DIR: String = "res://assets/models/scatter/"
const CLOUD_MODEL_DIR: String = "res://assets/models/clouds/"
const CLOUD_MATERIAL_DIR: String = "res://assets/materials/clouds/"
## Tufos, flores e vaga-lumes (MultiMesh): [nome do nó, arquivo, grupo].
const SCATTER_NODES: Array = [["TuftsArena", "tufts_arena", "Small"], ["TuftsOuter", "tufts_outer", "Small"], ["Flowers", "flowers", "Small"],
		["Fireflies", "fireflies", "Fx"]]


func _initialize() -> void:
	var map_scene := load(MAP_PATH) as PackedScene
	var map_root := map_scene.instantiate() as Node3D
	if map_root == null:
		push_error("Não abriu " + MAP_PATH)
		quit(1)
		return
	var replaced: int = 0
	for group_name: String in MapDecorTable.GROUPS:
		var old: Node = map_root.get_node_or_null(group_name)
		if old != null:
			replaced += old.get_child_count()
	if not OS.get_cmdline_user_args().has("--force"):
		push_error("place_decor.gd trocaria %d nós dos grupos %s em %s (a montagem manual se perde). Rode com `-- --force` se for isso mesmo." % [
				replaced, ", ".join(MapDecorTable.GROUPS), MAP_PATH])
		map_root.free()
		quit(1)
		return
	print("Trocando %d nós dos grupos decorativos" % replaced)
	for group_name: String in MapDecorTable.GROUPS:
		var old: Node = map_root.get_node_or_null(group_name)
		if old != null:
			map_root.remove_child(old)
			old.free()
	var groups: Dictionary = {}
	for group_name: String in MapDecorTable.GROUPS:
		var group := Node3D.new()
		group.name = group_name
		map_root.add_child(group)
		group.owner = map_root
		groups[group_name] = group
	var counter: int = 0
	var cache: Dictionary = {}
	for item: Array in MapDecorTable.ITEMS:
		var piece: String = str(item[1])
		if not cache.has(piece):
			cache[piece] = load(KIT_DIR + piece + ".tscn") as PackedScene
		var packed: PackedScene = cache[piece]
		if packed == null:
			push_error("Peça do kit inexistente: " + piece)
			continue
		var node := packed.instantiate() as Node3D
		counter += 1
		node.name = "%s_%d" % [piece, counter]
		node.position = Vector3(float(item[2]), float(item[3]), float(item[4]))
		node.rotation_degrees = Vector3(0.0, float(item[5]), 0.0)
		if item.size() > 6:
			var s: float = float(item[6])
			node.scale = Vector3(s, s, s)
		var parent: Node = groups[str(item[0])]
		parent.add_child(node)
		node.owner = map_root
	for spec: Array in SCATTER_NODES:
		var mmi := MultiMeshInstance3D.new()
		mmi.name = str(spec[0])
		mmi.multimesh = load(SCATTER_DIR + str(spec[1]) + ".tres") as MultiMesh
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		(groups[str(spec[2])] as Node3D).add_child(mmi)
		mmi.owner = map_root
		counter += 1
	counter += _place_clouds(groups["Sky"] as Node3D, map_root)
	var packed_map := PackedScene.new()
	if packed_map.pack(map_root) != OK:
		push_error("Falha ao empacotar o mapa")
		quit(1)
		return
	var err: Error = ResourceSaver.save(packed_map, MAP_PATH)
	print("Montagem aplicada: %d peças em %d grupos (erro %d)" % [counter, MapDecorTable.GROUPS.size(), err])
	map_root.free()
	quit(0 if err == OK else 1)


## Nuvens volumétricas: Sky/Clouds com um MeshInstance3D por massa (o shader trabalha no espaço local do nó,
## então arrastar o nó no editor move o volume).
func _place_clouds(sky: Node3D, map_root: Node3D) -> int:
	var clouds := Node3D.new()
	clouds.name = "Clouds"
	sky.add_child(clouds)
	clouds.owner = map_root
	var placed: int = 0
	for mass: Dictionary in CloudTables.MASSES:
		var mass_name: String = str(mass["name"])
		var mi := MeshInstance3D.new()
		mi.name = mass_name
		mi.mesh = load(CLOUD_MODEL_DIR + mass_name + ".res") as Mesh
		mi.material_override = load(CLOUD_MATERIAL_DIR + "cloud_" + mass_name + ".tres") as Material
		if mi.mesh == null or mi.material_override == null:
			push_error("Massa de nuvem sem proxy ou material (rode tools/kit/build_clouds.gd): " + mass_name)
		mi.position = mass["pos"]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		clouds.add_child(mi)
		mi.owner = map_root
		placed += 1
	return placed
