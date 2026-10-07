extends SceneTree
## Testes da malha do terreno (specs 003 e 007), com MapData montado à mão nos casos de quina,
## nas escadas e nos muros do anfiteatro.
## Rodar depois do comando de validação 1:
##   "$G" --headless --path . --script tools/tests/test_terrain_mesh.gd
## Imprime PASS/FAIL por verificação e sai com 0 (tudo passou) ou 1.

const MAP_SIZE: int = 7
## O raio disparado contra o vão tem que bater na malha a no máximo esta distância da aresta.
const MAX_HIT_DEPTH: float = 0.4
## De onde (distância da face) o raio parte, do lado de fora.
const RAY_START: float = 1.5
## Pontos do vão (até BEVEL_R do canto) e alturas (fração do nível de baixo) testados.
const GAP_OFFSETS: Array[float] = [0.03, 0.12, 0.2, 0.28, 0.36]
const GAP_LEVEL_FRACTIONS: Array[float] = [0.1, 0.5, 0.9]
## Quinas: (sinal em X, sinal em Z).
const CORNERS: Array[Vector2i] = [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1)]

var _failures: int = 0
var _passes: int = 0


func _initialize() -> void:
	var art := ArtLibrary.new()
	art.force_placeholders = true
	_test_bevel_gaps(art, false)
	_test_bevel_gaps(art, true)
	_test_side_uv(art)
	_test_stone_path_texture(art)
	_test_stairs_4_dirs(art)
	_test_built_walls(art)
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


func _make_map(base_level: int) -> MapData:
	var data := MapData.new()
	data.size = Vector2i(MAP_SIZE, MAP_SIZE)
	var n: int = MAP_SIZE * MAP_SIZE
	data.heights.resize(n)
	data.heights.fill(base_level)
	data.ground.resize(n)
	data.ground.fill(MapData.Ground.FOREST_GRASS)
	data.arena_mask.resize(n)
	data.arena_mask.fill(0)
	data.built_mask.resize(n)
	data.built_mask.fill(0)
	data.arena_floor_level = base_level
	data.invalidate_caches()
	return data


func _triangles(mesh: ArrayMesh) -> PackedVector3Array:
	var tris := PackedVector3Array()
	for s in mesh.get_surface_count():
		var arrays: Array = mesh.surface_get_arrays(s)
		tris.append_array(arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array)
	return tris


## Distância até o triângulo mais próximo que o raio acerta (INF se não acerta nenhum).
func _nearest_hit(tris: PackedVector3Array, from: Vector3, dir: Vector3) -> float:
	var best: float = INF
	for i in range(0, tris.size(), 3):
		var hit: Variant = Geometry3D.ray_intersects_triangle(from, dir, tris[i], tris[i + 1], tris[i + 2])
		if hit != null:
			best = minf(best, from.distance_to(hit as Vector3))
	return best


## Quina convexa H = 2 com um vizinho em 1 e o outro em 0 (ou fora do mapa, com o chão
## do mapa em 0). As 4 quinas, com o lado mais baixo na horizontal e na vertical.
## Raios horizontais de fora contra a faixa da parede até BEVEL_R do canto, entre os
## níveis 0 e 1, têm que bater na malha logo na aresta (não pode haver vão).
func _test_bevel_gaps(art: ArtLibrary, at_border: bool) -> void:
	var lh: float = WorldScale.LEVEL_HEIGHT
	var ok := true
	var detail := ""
	var cases: int = 0
	for corner: Vector2i in CORNERS:
		for lower_is_x: bool in [true, false]:
			var data := _make_map(1 if at_border else 0)
			var c := Vector2i(3, 3)
			# Vizinho mais baixo do lado da face testada (X ou Z da quina); o da outra direção
			# da quina fica no nível 1.
			var high_dir := Vector2i(0, corner.y) if lower_is_x else Vector2i(corner.x, 0)
			if at_border:
				# Célula colada na borda: o vizinho mais baixo fica fora do mapa (nível 0).
				if lower_is_x:
					c.x = 0 if corner.x < 0 else MAP_SIZE - 1
				else:
					c.y = 0 if corner.y < 0 else MAP_SIZE - 1
			data.heights[data.index_of(c)] = 2
			data.heights[data.index_of(c + high_dir)] = 1
			data.invalidate_caches()
			var tris := _triangles(TerrainMeshBuilder.build(data, art))
			cases += 1
			# Face do lado mais baixo e aresta da quina.
			var face: float = 0.0
			var edge: float = 0.0
			if lower_is_x:
				face = c.x + (0.0 if corner.x < 0 else 1.0)
				edge = c.y + (0.0 if corner.y < 0 else 1.0)
			else:
				face = c.y + (0.0 if corner.y < 0 else 1.0)
				edge = c.x + (0.0 if corner.x < 0 else 1.0)
			var out_sign: float = float(corner.x if lower_is_x else corner.y)
			var in_sign: float = float(corner.y if lower_is_x else corner.x)
			for t: float in GAP_OFFSETS:
				for frac: float in GAP_LEVEL_FRACTIONS:
					var y: float = frac * lh
					var along: float = edge - in_sign * t
					var from := Vector3.ZERO
					var dir := Vector3.ZERO
					if lower_is_x:
						from = Vector3(face + out_sign * RAY_START, y, along)
						dir = Vector3(-out_sign, 0.0, 0.0)
					else:
						from = Vector3(along, y, face + out_sign * RAY_START)
						dir = Vector3(0.0, 0.0, -out_sign)
					var depth: float = _nearest_hit(tris, from, dir) - RAY_START
					if depth > MAX_HIT_DEPTH or depth < -0.001:
						ok = false
						detail += "quina %s, baixo em %s, ponto %.2f altura %.2f: bateu a %.2f da aresta; " \
								% [corner, "X" if lower_is_x else "Z", t, y, depth]
	var where: String = "na borda do mapa" if at_border else "dentro do mapa"
	_check(ok, "quina convexa com vizinhos em níveis diferentes, %s: sem vão na parede (%d casos)" % [where, cases], detail)


## UV das laterais: cada nível mostra as 16 linhas de cima da textura (v de 0 a LEVEL_HEIGHT,
## v = topo do nível - y).
func _test_side_uv(art: ArtLibrary) -> void:
	var lh: float = WorldScale.LEVEL_HEIGHT
	var data := _make_map(0)
	data.heights[data.index_of(Vector2i(3, 3))] = 3
	data.heights[data.index_of(Vector2i(4, 3))] = 2
	data.heights[data.index_of(Vector2i(3, 4))] = 1
	data.invalidate_caches()
	var mesh := TerrainMeshBuilder.build(data, art)
	var ok := true
	var faces: int = 0
	var detail := ""
	for s in mesh.get_surface_count():
		var arrays: Array = mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		for i in range(0, verts.size(), 3):
			if absf(normals[i].y) > 0.5:
				continue
			faces += 1
			var top: float = maxf(verts[i].y, maxf(verts[i + 1].y, verts[i + 2].y))
			var v_top: float = ceilf(top / lh - 0.001) * lh
			for k in 3:
				var expected: float = v_top - verts[i + k].y
				if absf(uvs[i + k].y - expected) > 0.001 or uvs[i + k].y < -0.001 or uvs[i + k].y > lh + 0.001:
					ok = false
					detail = "vértice %s com v %.3f (esperado %.3f)" % [verts[i + k], uvs[i + k].y, expected]
	_check(ok and faces > 0, "laterais: 16 linhas por nível, a partir do topo (v = topo do nível - y) em %d triângulos" % faces, detail)


## Trilhas de pedra: cada célula STONE_PATH tem o topo na superfície da textura ruin_tile.
func _test_stone_path_texture(art: ArtLibrary) -> void:
	var lh: float = WorldScale.LEVEL_HEIGHT
	var config := MapGenConfig.new()
	config.trail_stone_chance = 1.0
	var gen := MapGenerator.new(config)
	var stone_mat: Material = art.terrain_material("ruin_tile")
	var tex_ok: bool = (stone_mat as StandardMaterial3D).albedo_texture == art.get_terrain_texture("ruin_tile")
	var ok := true
	var stone_cells: int = 0
	var detail := ""
	for map_seed in range(1, 4):
		var data: MapData = gen.generate(map_seed)
		var mesh := TerrainMeshBuilder.build(data, art)
		var covered: Dictionary = {}
		for s in mesh.get_surface_count():
			if mesh.surface_get_material(s) != stone_mat:
				continue
			var verts: PackedVector3Array = mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
			for i in range(0, verts.size(), 3):
				var mid: Vector3 = (verts[i] + verts[i + 1] + verts[i + 2]) / 3.0
				var cell := Vector2i(floori(mid.x), floori(mid.z))
				if data.is_cell_in_map(cell) and absf(mid.y - data.get_level(cell) * lh) < 0.001:
					covered[cell] = true
		for cz in data.size.y:
			for cx in data.size.x:
				var cell := Vector2i(cx, cz)
				if data.get_ground(cell) != MapData.Ground.STONE_PATH:
					continue
				stone_cells += 1
				if not covered.has(cell):
					ok = false
					detail += "seed %d célula %s sem topo ruin_tile; " % [map_seed, cell]
	_check(tex_ok and ok and stone_cells > 0,
			"trilha de pedra: %d células STONE_PATH desenhadas com a textura ruin_tile (seeds 1-3)" % stone_cells, detail)


## Escadas nas 4 direções, de 1 e 2 níveis: raios verticais nos pisos dos degraus batem na
## malha na altura de get_height_at (2 degraus por nível, 0,5 de piso cada).
func _test_stairs_4_dirs(art: ArtLibrary) -> void:
	var ok := true
	var cases: int = 0
	var detail := ""
	for up: Vector2i in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
		for levels in [1, 2]:
			var data := _make_map(0)
			var perp := Vector2i(absi(up.y), absi(up.x))
			var origin := Vector2i(3, 3) - up * floori(levels / 2.0)
			var stair := MapStair.new()
			stair.up_direction = up
			stair.levels = levels
			for k in levels:
				for a in 2:
					var c: Vector2i = origin + perp * a + up * k
					stair.cells.append(c)
					data.heights[data.index_of(c)] = k
			# Patamar de cima e o resto da linha no nível de cima.
			for a in range(-1, 3):
				var top: Vector2i = origin + perp * a + up * levels
				if data.is_cell_in_map(top):
					data.heights[data.index_of(top)] = levels
			data.stairs.append(stair)
			data.invalidate_caches()
			var tris := _triangles(TerrainMeshBuilder.build(data, art))
			for c: Vector2i in stair.cells:
				for fx: float in [0.2, 0.45, 0.55, 0.8]:
					for fz: float in [0.3, 0.7]:
						var p := Vector2(c.x + fx, c.y + fz) if up.y == 0 else Vector2(c.x + fz, c.y + fx)
						var expected: float = data.get_height_at(p)
						var from := Vector3(p.x, 10.0, p.y)
						var hit: float = 10.0 - _nearest_hit(tris, from, Vector3.DOWN)
						cases += 1
						if absf(hit - expected) > 0.001:
							ok = false
							detail += "subida %s, %d níveis, ponto %s: malha %.3f, get_height_at %.3f; " % [up, levels, p, hit, expected]
	_check(ok, "escadas nas 4 direções e de 1 ou 2 níveis: piso da malha = get_height_at (%d pontos)" % cases, detail)


## Desnível de célula construída (built_mask) usa wall_face; fora dela, step_side.
func _test_built_walls(art: ArtLibrary) -> void:
	var data := _make_map(0)
	data.heights[data.index_of(Vector2i(2, 2))] = 1
	data.heights[data.index_of(Vector2i(4, 4))] = 1
	data.built_mask[data.index_of(Vector2i(2, 2))] = 1
	data.invalidate_caches()
	var mesh := TerrainMeshBuilder.build(data, art)
	var wall_mat: Material = art.terrain_material("wall_face")
	var built_walls: int = 0
	var natural_walls: int = 0
	var wrong := false
	for s in mesh.get_surface_count():
		var arrays: Array = mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		for i in range(0, verts.size(), 3):
			if absf(normals[i].y) > 0.5:
				continue
			var mid: Vector3 = (verts[i] + verts[i + 1] + verts[i + 2]) / 3.0
			var near_built: bool = mid.x > 1.9 and mid.x < 3.1 and mid.z > 1.9 and mid.z < 3.1
			var is_wall: bool = mesh.surface_get_material(s) == wall_mat
			if near_built:
				built_walls += 1
				wrong = wrong or not is_wall
			else:
				natural_walls += 1
				wrong = wrong or is_wall
	_check(not wrong and built_walls > 0 and natural_walls > 0,
			"desnível construído com wall_face (%d triângulos) e natural com step_side (%d)" % [built_walls, natural_walls])
