extends SceneTree
## Monta a primeira versão de scenes/map.tscn a partir das coordenadas da spec 011 (seção 2).
## Sem sorteio: a mata é uma malha escalonada com desvios por aritmética inteira fixa.
## ATENÇÃO: sobrescreve scenes/map.tscn e apaga a montagem manual. Depois do primeiro passe o mapa
## é editado à mão no editor; por isso o script recusa rodar sem a flag explícita --force:
##   "$G" --headless --path . --script tools/kit/gen_initial_map.gd -- --force
## (rodar depois de tools/kit/build_kit.gd)

const OUT_PATH: String = "res://scenes/map.tscn"
const KIT_DIR: String = "res://scenes/kit/"
## Retângulo onde não nasce árvore: anel + 2 de folga.
const FOREST_HOLE: Rect2 = Rect2(-17.0, -16.0, 34.0, 32.0)

var _root: MapLayout = null
var _groups: Dictionary = {}
var _counter: int = 0
var _forest_keep_out: Array[Rect2] = []


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
	_build_decals()
	_build_audience()
	_build_terrace_props()
	_build_forest()
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
		bench.position = Vector3(0.0, 0.0, 11.0 if team == 0 else -11.0)
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
	for x in range(-12, 13, 4):
		_place("Terrace", "terrace_fill_4x3", float(x), 0.0, -11.5, 0.0)
		_place("Terrace", "terrace_fill_4x3", float(x), 0.0, 11.5, 0.0)
	for z in [-8.0, -4.0, 0.0]:
		_place_pair("Terrace", "terrace_fill_4x3", -12.5, 0.0, z, 90.0)
	_place_pair("Terrace", "terrace_fill_1x3", -12.5, 0.0, 2.5, 90.0)
	_place_pair("Terrace", "terrace_fill_1x3", -11.5, 0.0, 4.5, 0.0)
	_place_pair("Terrace", "terrace_fill_1x3", -12.5, 0.0, 6.5, 90.0)
	_place_pair("Terrace", "terrace_fill_3x3", -12.5, 0.0, 8.5, 0.0)


func _build_walls() -> void:
	for x in range(-13, 14, 2):
		_place("Walls", "wall_high_2", float(x), 0.0, -13.5, 0.0)
		_place("Walls", "wall_high_2", float(-x), 0.0, 13.5, 180.0)
	for z in [-12, -10, -8, -6, -4, -2, 0, 2, 7, 9, 11]:
		_place_pair("Walls", "wall_high_2", -14.5, 0.0, float(z), 90.0)
	for z in [3.5, 4.5, 5.5, 12.5]:
		_place_pair("Walls", "wall_high_1", -14.5, 0.0, z, 90.0)
	_place("Walls", "wall_high_corner", -14.5, 0.0, -13.5, 0.0)
	_place("Walls", "wall_high_corner", 14.5, 0.0, -13.5, 270.0)
	_place("Walls", "wall_high_corner", 14.5, 0.0, 13.5, 180.0)
	_place("Walls", "wall_high_corner", -14.5, 0.0, 13.5, 90.0)


func _build_stairs() -> void:
	_place_pair("Stairs", "stair_outer_3", -16.5, 0.0, 4.5, 270.0)
	_place_pair("Stairs", "stair_inner_3", -13.0, 0.0, 4.5, 90.0)
	_place_pair("Stairs", "stair_low_3", -10.5, 0.0, 4.5, 90.0)
	_forest_keep_out.append(Rect2(-20.5, 1.5, 6.0, 6.0))
	_forest_keep_out.append(Rect2(14.5, -7.5, 6.0, 6.0))


## Mancha de terra, manchas de grama e trilhas de lajes (provisórios, em retângulos e elipses).
func _build_decals() -> void:
	_place("Decals", "decal_arena_dirt", 0.0, 0.01, -0.5)
	_place("Decals", "decal_grass_light_0", -6.0, 0.012, 5.5)
	_place("Decals", "decal_grass_light_1", 6.5, 0.012, -5.0)
	_place("Decals", "decal_grass_light_2", 5.0, 0.012, 6.0)
	_place("Decals", "decal_grass_dark_0", -7.0, 0.014, -5.0)
	_place("Decals", "decal_grass_dark_1", 2.0, 0.014, -7.0)
	_place("Decals", "decal_forest_soil_0", -19.0, 0.012, -6.0)
	_place("Decals", "decal_forest_soil_1", 19.0, 0.012, 8.0)
	# Trilha sudoeste (a nordeste é a reflexão).
	var trail: Array = [
		["decal_trail_0", -19.5, 4.5], ["decal_trail_1", -20.5, 8.0], ["decal_trail_bend", -21.5, 11.5],
		["decal_trail_2", -22.0, 15.5], ["decal_trail_1", -22.5, 20.0],
	]
	for piece: Array in trail:
		_place_pair("Trail", str(piece[0]), float(piece[1]), 0.012, float(piece[2]), 0.0)
		_forest_keep_out.append(Rect2(float(piece[1]) - 3.0, float(piece[2]) - 3.5, 6.0, 7.0))
		_forest_keep_out.append(Rect2(-float(piece[1]) - 3.0, -float(piece[2]) - 3.5, 6.0, 7.0))


## Plateia atrás do muro norte: banco, caixote, pilha de madeira e dois troncos com musgo.
func _build_audience() -> void:
	_place("Audience", "bench_wood", -5.5, 0.0, -17.5, 0.0)
	_place("Audience", "crate", -2.5, 0.0, -17.8, 0.0)
	_place("Audience", "crate_stack", -1.2, 0.0, -17.4, 0.0)
	_place("Audience", "wood_pile", 2.0, 0.0, -17.5, 0.0)
	_place("Audience", "log_a", -3.5, 0.0, -19.2, 0.0)
	_place("Audience", "log_c", 1.5, 0.0, -19.4, 0.0)
	_forest_keep_out.append(Rect2(-9.0, -21.0, 16.0, 7.0))


func _build_terrace_props() -> void:
	_place_pair("TerraceProps", "log_a", -12.5, 0.5, -3.5, 90.0)
	_place_pair("TerraceProps", "rock_a", -12.8, 0.5, -7.0, 0.0)
	_place_pair("TerraceProps", "rock_d", -13.0, 0.5, 1.0, 90.0)
	_place_pair("TerraceProps", "rock_b", -12.4, 0.5, 9.0, 180.0)
	_place_pair("TerraceProps", "flowers_a", -12.0, 0.5, -1.2, 0.0)
	_place_pair("TerraceProps", "tall_grass_a", -13.2, 0.5, 8.0, 0.0)


## Mata densa fora do anel: malha escalonada com desvios fixos; ao sul só árvores baixas.
func _build_forest() -> void:
	var tall: PackedStringArray = ["conifer_a", "tree_broad_a", "conifer_b", "tree_broad_b", "conifer_c",
			"tree_broad_c", "conifer_d", "tree_small_a", "conifer_e", "tree_broad_d", "conifer_f", "tree_broad_e"]
	var low: PackedStringArray = ["tree_small_a", "bush_c", "tree_small_b", "bush_b", "tree_small_c", "bush_d"]
	var step: float = 2.6
	var rows: int = 0
	var z: float = -23.5
	while z <= 23.5:
		var x_shift: float = 1.3 if rows % 2 == 1 else 0.0
		var x: float = -23.5 + x_shift
		var cols: int = 0
		while x <= 23.5:
			var dx: float = float((cols * 7 + rows * 13) % 5 - 2) * 0.24
			var dz: float = float((cols * 11 + rows * 5) % 5 - 2) * 0.24
			var pos := Vector2(snappedf(x + dx, 1.0 / 32.0), snappedf(z + dz, 1.0 / 32.0))
			# Ao sul (câmera padrão) a mata só começa a 6,5 unidades do muro e só com árvores baixas:
			# a face externa do muro sul e a reserva ficam à vista.
			if _forest_free(pos) and (pos.y < 14.0 or pos.y >= 20.5):
				var pick: int = (cols * 5 + rows * 3) % tall.size()
				var piece: String = tall[pick] if pos.y < 14.0 else low[(cols + rows) % low.size()]
				_place("Forest", piece, pos.x, 0.0, pos.y, float(((cols + rows) % 4) * 90))
			x += step
			cols += 1
		z += step * 0.85
		rows += 1
	# Aglomerados de fundo, além da borda montada à mão (sem tapar a câmera ao sul).
	var backdrop: Array = [
		["forest_backdrop_a", -29.0, -29.0], ["forest_backdrop_b", -8.0, -31.0], ["forest_backdrop_c", 12.0, -30.0],
		["forest_backdrop_a", 29.0, -27.0], ["forest_backdrop_b", -31.0, -5.0], ["forest_backdrop_c", 31.0, 4.0],
		["forest_backdrop_a", -30.0, 14.0], ["forest_backdrop_b", 30.0, 16.0],
	]
	for item: Array in backdrop:
		_place("Backdrop", str(item[0]), float(item[1]), 0.0, float(item[2]), 0.0)


func _forest_free(pos: Vector2) -> bool:
	if FOREST_HOLE.has_point(pos):
		return false
	for rect: Rect2 in _forest_keep_out:
		if rect.has_point(pos):
			return false
	return true
