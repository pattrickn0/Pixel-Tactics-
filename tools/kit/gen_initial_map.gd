extends SceneTree
## Monta a ESTRUTURA de scenes/map.tscn (chão, marcadores, degrau baixo, terraço, muro alto e escadas) a partir
## das coordenadas da spec 011 (seção 2, com a decisão de 2026-10-08: muro com crista em 1,0 e terraço de 3).
## Os grupos decorativos (decalques, trilhas, plateia, props, mata, fundo) NÃO são feitos aqui: vêm da tabela
## tools/kit/map_decor_table.gd, aplicada por tools/kit/place_decor.gd.
## ATENÇÃO: sobrescreve scenes/map.tscn e apaga a montagem manual. Depois do primeiro passe o mapa
## é editado à mão no editor; por isso o script recusa rodar sem a flag explícita --force:
##   "$G" --headless --path . --script tools/kit/gen_initial_map.gd -- --force
## (rodar depois de tools/kit/build_kit.gd e antes de tools/kit/place_decor.gd)

const OUT_PATH: String = "res://scenes/map.tscn"
const KIT_DIR: String = "res://scenes/kit/"

var _root: MapLayout = null
var _groups: Dictionary = {}
var _counter: int = 0


func _initialize() -> void:
	if FileAccess.file_exists(OUT_PATH) and not OS.get_cmdline_user_args().has("--force"):
		push_error("%s já existe e este script apagaria a montagem manual. Rode com `-- --force` se for isso mesmo." % OUT_PATH)
		quit(1)
		return
	_root = MapLayout.new()
	_root.name = "Map"
	_build_ground()
	_build_markers()
	_build_step_low()
	_build_terrace()
	_build_walls()
	_build_stairs()
	var packed := PackedScene.new()
	if packed.pack(_root) != OK:
		push_error("Falha ao empacotar o mapa")
		quit(1)
		return
	var err: Error = ResourceSaver.save(packed, OUT_PATH)
	print("Mapa gravado em %s (erro %d, %d nós)" % [OUT_PATH, err, _count_nodes(_root)])
	_root.free()
	quit(0 if err == OK else 1)


func _count_nodes(node: Node) -> int:
	var total: int = 1
	for child: Node in node.get_children():
		total += _count_nodes(child)
	return total


## Pasta (Node3D) com o nome dado, criada na primeira vez.
func _group(group_name: String) -> Node3D:
	if not _groups.has(group_name):
		var node := Node3D.new()
		node.name = group_name
		_root.add_child(node)
		node.owner = _root
		_groups[group_name] = node
	return _groups[group_name]


## Instancia uma peça do kit em (x, y, z) com yaw em graus.
func _place(group_name: String, piece: String, x: float, y: float, z: float, yaw: float = 0.0) -> Node3D:
	var scene := load(KIT_DIR + piece + ".tscn") as PackedScene
	var node := scene.instantiate() as Node3D
	_counter += 1
	node.name = "%s_%d" % [piece, _counter]
	node.position = Vector3(x, y, z)
	node.rotation_degrees = Vector3(0.0, yaw, 0.0)
	var parent := _group(group_name)
	parent.add_child(node)
	node.owner = _root
	return node


## A mesma peça girada 180° em torno do centro da arena (justiça entre os lados).
func _place_pair(group_name: String, piece: String, x: float, y: float, z: float, yaw: float) -> void:
	_place(group_name, piece, x, y, z, yaw)
	_place(group_name, piece, -x, y, -z, yaw + 180.0)


func _build_ground() -> void:
	_place("Ground", "ground_far", 0.0, -0.02, 0.0)
	_place("Ground", "ground_outer", 0.0, -0.01, 0.0)
	_place("Ground", "ground_inner", 0.0, 0.0, 0.0)


func _build_markers() -> void:
	var arena := ArenaMarker.new()
	arena.name = "Arena"
	var markers := _group("Markers")
	markers.add_child(arena)
	arena.owner = _root
	for team in 2:
		var bench := BenchMarker.new()
		bench.name = "Bench%d" % team
		bench.team = team
		bench.size = Vector2(20.0, 3.0)
		bench.usable_margin = Vector4(0.5, 0.5, 0.5, 0.25)
		bench.position = Vector3(0.0, 0.0, 10.5 if team == 0 else -10.5)
		bench.rotation_degrees = Vector3(0.0, 0.0 if team == 0 else 180.0, 0.0)
		markers.add_child(bench)
		bench.owner = _root


## Degrau baixo em volta da arena (1 de largura), frente virada para a arena.
func _build_step_low() -> void:
	for x in range(-9, 10, 2):
		_place("StepLow", "step_low_2", float(x), 0.0, -9.5, 0.0)
		_place("StepLow", "step_low_2", float(-x), 0.0, 9.5, 180.0)
	# Lado oeste (a escada baixa ocupa z 3 a 6); o leste é a reflexão.
	for z in [-8, -6, -4, -2, 0, 2, 7]:
		_place_pair("StepLow", "step_low_2", -10.5, 0.0, float(z), 90.0)
	_place_pair("StepLow", "step_low_1", -10.5, 0.0, 8.5, 90.0)
	_place("StepLow", "step_low_corner", -10.5, 0.0, -9.5, 0.0)
	_place("StepLow", "step_low_corner", 10.5, 0.0, -9.5, 270.0)
	_place("StepLow", "step_low_corner", 10.5, 0.0, 9.5, 180.0)
	_place("StepLow", "step_low_corner", -10.5, 0.0, 9.5, 90.0)


func _build_terrace() -> void:
	# Faixas norte/sul entre o degrau baixo e o muro (x -11 a 11, z 10 a 12): 4 + 4 + 4 + 4 + 3 + 3.
	for x in [-9.0, -5.0, -1.0, 3.0]:
		_place_pair("Terrace", "terrace_fill_4x2", x, 0.0, 11.0, 0.0)
	for x in [6.5, 9.5]:
		_place_pair("Terrace", "terrace_fill_3x2", x, 0.0, 11.0, 0.0)
	# Faixa oeste (x -13 a -11): z -12 a 3 (4 + 4 + 4 + 3), patamar da escada (x -12 a -11, z 3 a 6) e z 6 a 12 (3 + 3).
	for z in [-10.0, -6.0, -2.0]:
		_place_pair("Terrace", "terrace_fill_4x2", -12.0, 0.0, z, 90.0)
	for z in [1.5, 7.5, 10.5]:
		_place_pair("Terrace", "terrace_fill_3x2", -12.0, 0.0, z, 90.0)
	_place_pair("Terrace", "terrace_fill_1x3", -11.5, 0.0, 4.5, 0.0)


func _build_walls() -> void:
	for x in range(-12, 13, 2):
		_place("Walls", "wall_high_2", float(x), 0.0, -12.5, 0.0)
		_place("Walls", "wall_high_2", float(-x), 0.0, 12.5, 180.0)
	for z in [-11, -9, -7, -5, -3, -1, 1, 7, 9, 11]:
		_place_pair("Walls", "wall_high_2", -13.5, 0.0, float(z), 90.0)
	for z in [2.5, 3.5, 4.5, 5.5]:
		_place_pair("Walls", "wall_high_1", -13.5, 0.0, z, 90.0)
	_place("Walls", "wall_high_corner", -13.5, 0.0, -12.5, 0.0)
	_place("Walls", "wall_high_corner", 13.5, 0.0, -12.5, 270.0)
	_place("Walls", "wall_high_corner", 13.5, 0.0, 12.5, 180.0)
	_place("Walls", "wall_high_corner", -13.5, 0.0, 12.5, 90.0)


## Escada oeste, de fora para dentro: externa x -16 a -14 (0 a 1,0), crista x -14 a -13 (as wall_high_1),
## interna x -13 a -12 (1,0 a 0,5), patamar x -12 a -11, baixa x -11 a -10 (0,5 a 0). A leste é a rotação de 180°.
func _build_stairs() -> void:
	_place_pair("Stairs", "stair_outer_3", -15.0, 0.0, 4.5, 270.0)
	_place_pair("Stairs", "stair_inner_3", -12.5, 0.0, 4.5, 90.0)
	_place_pair("Stairs", "stair_low_3", -10.5, 0.0, 4.5, 90.0)
