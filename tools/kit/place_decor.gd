extends SceneTree
## Aplica a tabela de montagem (tools/kit/map_decor_table.gd) em scenes/map.tscn: troca só os grupos
## decorativos (decalques, trilhas, plateia, props do terraço, pequenos, mata e fundo) e mantém o
## anel, as escadas, o chão e os marcadores como estão. Sem sorteio: cada peça vem de uma linha da tabela.
## Rodar da raiz do projeto, depois do build_kit.gd:
##   "$G" --headless --path . --script tools/kit/place_decor.gd

const MAP_PATH: String = "res://scenes/map.tscn"
const KIT_DIR: String = "res://scenes/kit/"


func _initialize() -> void:
	var map_scene := load(MAP_PATH) as PackedScene
	var map_root := map_scene.instantiate() as Node3D
	if map_root == null:
		push_error("Não abriu " + MAP_PATH)
		quit(1)
		return
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
		var parent: Node = groups[str(item[0])]
		parent.add_child(node)
		node.owner = map_root
	var packed_map := PackedScene.new()
	if packed_map.pack(map_root) != OK:
		push_error("Falha ao empacotar o mapa")
		quit(1)
		return
	var err: Error = ResourceSaver.save(packed_map, MAP_PATH)
	print("Montagem aplicada: %d peças em %d grupos (erro %d)" % [counter, MapDecorTable.GROUPS.size(), err])
	map_root.free()
	quit(0 if err == OK else 1)
