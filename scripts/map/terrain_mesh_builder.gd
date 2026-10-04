class_name TerrainMeshBuilder
extends RefCounted
## Monta a ArrayMesh do terreno a partir do MapData: topo de cada célula, laterais dos
## degraus (1 quad por nível) e as escadas. Cantos de elevação são arredondados com chanfro
## e arcos circulares para aspecto orgânico (estilo HD-2D). Uma superfície por textura.

const SIDE_DIRS: Array = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
const BEVEL_R: float = 0.38
const BEVEL_K: float = 0.38 * 0.292893 # ~0.1113
const NORM_DIAG_1: float = 0.382683
const NORM_DIAG_2: float = 0.923880


static func build(data: MapData, art: ArtLibrary) -> ArrayMesh:
	var batches: Dictionary = {}
	var lh: float = WorldScale.LEVEL_HEIGHT
	var floor_level: int = data.get_level_range().x - 1

	for cz in data.size.y:
		for cx in data.size.x:
			var cell := Vector2i(cx, cz)
			var stair: bool = data.is_stair_cell(cell)
			if stair:
				_add_stair_cell(data, art, batches, cell)
			else:
				_build_cell(data, art, batches, cell, lh, floor_level)

	var mesh := ArrayMesh.new()
	for art_name: String in batches:
		var batch: MeshBatch = batches[art_name]
		batch.commit(mesh, art.terrain_material(art_name))
	return mesh


static func _build_cell(data: MapData, art: ArtLibrary, batches: Dictionary, cell: Vector2i, lh: float, floor_level: int) -> void:
	var cx: int = cell.x
	var cz: int = cell.y
	var lvl: int = data.get_level(cell)
	var ground: MapData.Ground = data.get_ground(cell)
	var top_name: String = _top_texture(art, ground, cell)
	var y: float = lvl * lh
	var grassy: bool = (ground == MapData.Ground.ARENA_GRASS or ground == MapData.Ground.FOREST_GRASS)

	var nw_cvx: bool = _is_convex(data, cell, Vector2i(0, -1), Vector2i(-1, 0), floor_level)
	var ne_cvx: bool = _is_convex(data, cell, Vector2i(0, -1), Vector2i(1, 0), floor_level)
	var se_cvx: bool = _is_convex(data, cell, Vector2i(0, 1), Vector2i(1, 0), floor_level)
	var sw_cvx: bool = _is_convex(data, cell, Vector2i(0, 1), Vector2i(-1, 0), floor_level)

	var nw_ccv: bool = _is_concave(data, cell, Vector2i(0, -1), Vector2i(-1, 0), floor_level)
	var ne_ccv: bool = _is_concave(data, cell, Vector2i(0, -1), Vector2i(1, 0), floor_level)
	var se_ccv: bool = _is_concave(data, cell, Vector2i(0, 1), Vector2i(1, 0), floor_level)
	var sw_ccv: bool = _is_concave(data, cell, Vector2i(0, 1), Vector2i(-1, 0), floor_level)

	var nw_cut: bool = nw_cvx or nw_ccv
	var ne_cut: bool = ne_cvx or ne_ccv
	var se_cut: bool = se_cvx or se_ccv
	var sw_cut: bool = sw_cvx or sw_ccv

	# Topo da célula com cantos arredondados
	var pts: Array[Vector2] = []
	if nw_cut:
		pts.append(Vector2(cx, cz + BEVEL_R))
		pts.append(Vector2(cx + BEVEL_K, cz + BEVEL_K))
		pts.append(Vector2(cx + BEVEL_R, cz))
	else:
		pts.append(Vector2(cx, cz))

	if ne_cut:
		pts.append(Vector2(cx + 1.0 - BEVEL_R, cz))
		pts.append(Vector2(cx + 1.0 - BEVEL_K, cz + BEVEL_K))
		pts.append(Vector2(cx + 1.0, cz + BEVEL_R))
	else:
		pts.append(Vector2(cx + 1.0, cz))

	if se_cut:
		pts.append(Vector2(cx + 1.0, cz + 1.0 - BEVEL_R))
		pts.append(Vector2(cx + 1.0 - BEVEL_K, cz + 1.0 - BEVEL_K))
		pts.append(Vector2(cx + 1.0 - BEVEL_R, cz + 1.0))
	else:
		pts.append(Vector2(cx + 1.0, cz + 1.0))

	if sw_cut:
		pts.append(Vector2(cx + BEVEL_R, cz + 1.0))
		pts.append(Vector2(cx + BEVEL_K, cz + 1.0 - BEVEL_K))
		pts.append(Vector2(cx, cz + 1.0 - BEVEL_R))
	else:
		pts.append(Vector2(cx, cz + 1.0))

	_batch(batches, top_name).add_top_polygon(pts, y)

	# Níveis vizinhos cardinais
	var n_lvl: int = _get_level(data, cell + Vector2i(0, -1), floor_level)
	var e_lvl: int = _get_level(data, cell + Vector2i(1, 0), floor_level)
	var s_lvl: int = _get_level(data, cell + Vector2i(0, 1), floor_level)
	var w_lvl: int = _get_level(data, cell + Vector2i(-1, 0), floor_level)

	# Paredes retas entre cantos
	if n_lvl < lvl and not _is_stair(data, cell + Vector2i(0, -1)):
		var x_start: float = cx + (BEVEL_R if nw_cvx else 0.0)
		var x_end: float = cx + 1.0 - (BEVEL_R if ne_cvx else 0.0)
		var p_start := Vector2(x_start, cz)
		var p_end := Vector2(x_end, cz)
		for l in range(n_lvl, lvl):
			var side_name: String = "step_side_grass" if grassy and l == lvl - 1 else "step_side"
			_batch(batches, side_name).add_vertical_quad(p_start, p_end, l * lh, (l + 1) * lh, Vector2(0.0, -1.0), (l + 1) * lh)

	if e_lvl < lvl and not _is_stair(data, cell + Vector2i(1, 0)):
		var z_start: float = cz + (BEVEL_R if ne_cvx else 0.0)
		var z_end: float = cz + 1.0 - (BEVEL_R if se_cvx else 0.0)
		var p_start := Vector2(cx + 1.0, z_start)
		var p_end := Vector2(cx + 1.0, z_end)
		for l in range(e_lvl, lvl):
			var side_name: String = "step_side_grass" if grassy and l == lvl - 1 else "step_side"
			_batch(batches, side_name).add_vertical_quad(p_start, p_end, l * lh, (l + 1) * lh, Vector2(1.0, 0.0), (l + 1) * lh)

	if s_lvl < lvl and not _is_stair(data, cell + Vector2i(0, 1)):
		var x_start: float = cx + (BEVEL_R if sw_cvx else 0.0)
		var x_end: float = cx + 1.0 - (BEVEL_R if se_cvx else 0.0)
		var p_start := Vector2(x_start, cz + 1.0)
		var p_end := Vector2(x_end, cz + 1.0)
		for l in range(s_lvl, lvl):
			var side_name: String = "step_side_grass" if grassy and l == lvl - 1 else "step_side"
			_batch(batches, side_name).add_vertical_quad(p_start, p_end, l * lh, (l + 1) * lh, Vector2(0.0, 1.0), (l + 1) * lh)

	if w_lvl < lvl and not _is_stair(data, cell + Vector2i(-1, 0)):
		var z_start: float = cz + (BEVEL_R if nw_cvx else 0.0)
		var z_end: float = cz + 1.0 - (BEVEL_R if sw_cvx else 0.0)
		var p_start := Vector2(cx, z_start)
		var p_end := Vector2(cx, z_end)
		for l in range(w_lvl, lvl):
			var side_name: String = "step_side_grass" if grassy and l == lvl - 1 else "step_side"
			_batch(batches, side_name).add_vertical_quad(p_start, p_end, l * lh, (l + 1) * lh, Vector2(-1.0, 0.0), (l + 1) * lh)

	# Cantos convexos (arredondados para fora)
	if nw_cvx:
		var p_w := Vector2(cx, cz + BEVEL_R)
		var p_mid := Vector2(cx + BEVEL_K, cz + BEVEL_K)
		var p_n := Vector2(cx + BEVEL_R, cz)
		var low_lvl: int = maxi(n_lvl, w_lvl)
		var norm1 := Vector2(-NORM_DIAG_1, -NORM_DIAG_2)
		var norm2 := Vector2(-NORM_DIAG_2, -NORM_DIAG_1)
		for l in range(low_lvl, lvl):
			var side_name: String = "step_side_grass" if grassy and l == lvl - 1 else "step_side"
			_batch(batches, side_name).add_vertical_quad(p_n, p_mid, l * lh, (l + 1) * lh, norm1, (l + 1) * lh)
			_batch(batches, side_name).add_vertical_quad(p_mid, p_w, l * lh, (l + 1) * lh, norm2, (l + 1) * lh)
		var lower_g: MapData.Ground = data.get_ground(cell + Vector2i(0, -1)) if data.is_cell_in_map(cell + Vector2i(0, -1)) else ground
		var fill_tex: String = _top_texture(art, lower_g, cell)
		_batch(batches, fill_tex).add_top_polygon([Vector2(cx, cz), p_w, p_mid, p_n], low_lvl * lh)

	if ne_cvx:
		var p_n := Vector2(cx + 1.0 - BEVEL_R, cz)
		var p_mid := Vector2(cx + 1.0 - BEVEL_K, cz + BEVEL_K)
		var p_e := Vector2(cx + 1.0, cz + BEVEL_R)
		var low_lvl: int = maxi(n_lvl, e_lvl)
		var norm1 := Vector2(NORM_DIAG_1, -NORM_DIAG_2)
		var norm2 := Vector2(NORM_DIAG_2, -NORM_DIAG_1)
		for l in range(low_lvl, lvl):
			var side_name: String = "step_side_grass" if grassy and l == lvl - 1 else "step_side"
			_batch(batches, side_name).add_vertical_quad(p_n, p_mid, l * lh, (l + 1) * lh, norm1, (l + 1) * lh)
			_batch(batches, side_name).add_vertical_quad(p_mid, p_e, l * lh, (l + 1) * lh, norm2, (l + 1) * lh)
		var lower_g: MapData.Ground = data.get_ground(cell + Vector2i(0, -1)) if data.is_cell_in_map(cell + Vector2i(0, -1)) else ground
		var fill_tex: String = _top_texture(art, lower_g, cell)
		_batch(batches, fill_tex).add_top_polygon([Vector2(cx + 1.0, cz), p_n, p_mid, p_e], low_lvl * lh)

	if se_cvx:
		var p_e := Vector2(cx + 1.0, cz + 1.0 - BEVEL_R)
		var p_mid := Vector2(cx + 1.0 - BEVEL_K, cz + 1.0 - BEVEL_K)
		var p_s := Vector2(cx + 1.0 - BEVEL_R, cz + 1.0)
		var low_lvl: int = maxi(s_lvl, e_lvl)
		var norm1 := Vector2(NORM_DIAG_2, NORM_DIAG_1)
		var norm2 := Vector2(NORM_DIAG_1, NORM_DIAG_2)
		for l in range(low_lvl, lvl):
			var side_name: String = "step_side_grass" if grassy and l == lvl - 1 else "step_side"
			_batch(batches, side_name).add_vertical_quad(p_e, p_mid, l * lh, (l + 1) * lh, norm1, (l + 1) * lh)
			_batch(batches, side_name).add_vertical_quad(p_mid, p_s, l * lh, (l + 1) * lh, norm2, (l + 1) * lh)
		var lower_g: MapData.Ground = data.get_ground(cell + Vector2i(0, 1)) if data.is_cell_in_map(cell + Vector2i(0, 1)) else ground
		var fill_tex: String = _top_texture(art, lower_g, cell)
		_batch(batches, fill_tex).add_top_polygon([Vector2(cx + 1.0, cz + 1.0), p_e, p_mid, p_s], low_lvl * lh)

	if sw_cvx:
		var p_s := Vector2(cx + BEVEL_R, cz + 1.0)
		var p_mid := Vector2(cx + BEVEL_K, cz + 1.0 - BEVEL_K)
		var p_w := Vector2(cx, cz + 1.0 - BEVEL_R)
		var low_lvl: int = maxi(s_lvl, w_lvl)
		var norm1 := Vector2(-NORM_DIAG_1, NORM_DIAG_2)
		var norm2 := Vector2(-NORM_DIAG_2, NORM_DIAG_1)
		for l in range(low_lvl, lvl):
			var side_name: String = "step_side_grass" if grassy and l == lvl - 1 else "step_side"
			_batch(batches, side_name).add_vertical_quad(p_s, p_mid, l * lh, (l + 1) * lh, norm1, (l + 1) * lh)
			_batch(batches, side_name).add_vertical_quad(p_mid, p_w, l * lh, (l + 1) * lh, norm2, (l + 1) * lh)
		var lower_g: MapData.Ground = data.get_ground(cell + Vector2i(0, 1)) if data.is_cell_in_map(cell + Vector2i(0, 1)) else ground
		var fill_tex: String = _top_texture(art, lower_g, cell)
		_batch(batches, fill_tex).add_top_polygon([Vector2(cx, cz + 1.0), p_s, p_mid, p_w], low_lvl * lh)

	# Cantos côncavos (arredondados para dentro / filetes)
	if nw_ccv:
		var p_w := Vector2(cx, cz + BEVEL_R)
		var p_mid := Vector2(cx + BEVEL_K, cz + BEVEL_K)
		var p_n := Vector2(cx + BEVEL_R, cz)
		var high_lvl: int = mini(n_lvl, w_lvl)
		var norm1 := Vector2(NORM_DIAG_2, NORM_DIAG_1)
		var norm2 := Vector2(NORM_DIAG_1, NORM_DIAG_2)
		var higher_g: MapData.Ground = data.get_ground(cell + Vector2i(0, -1)) if data.is_cell_in_map(cell + Vector2i(0, -1)) else ground
		var higher_grassy: bool = (higher_g == MapData.Ground.ARENA_GRASS or higher_g == MapData.Ground.FOREST_GRASS)
		for l in range(lvl, high_lvl):
			var side_name: String = "step_side_grass" if higher_grassy and l == high_lvl - 1 else "step_side"
			_batch(batches, side_name).add_vertical_quad(p_w, p_mid, l * lh, (l + 1) * lh, norm1, (l + 1) * lh)
			_batch(batches, side_name).add_vertical_quad(p_mid, p_n, l * lh, (l + 1) * lh, norm2, (l + 1) * lh)
		var high_tex: String = _top_texture(art, higher_g, cell)
		_batch(batches, high_tex).add_top_polygon([Vector2(cx, cz), p_w, p_mid, p_n], high_lvl * lh)

	if ne_ccv:
		var p_n := Vector2(cx + 1.0 - BEVEL_R, cz)
		var p_mid := Vector2(cx + 1.0 - BEVEL_K, cz + BEVEL_K)
		var p_e := Vector2(cx + 1.0, cz + BEVEL_R)
		var high_lvl: int = mini(n_lvl, e_lvl)
		var norm1 := Vector2(-NORM_DIAG_1, NORM_DIAG_2)
		var norm2 := Vector2(-NORM_DIAG_2, NORM_DIAG_1)
		var higher_g: MapData.Ground = data.get_ground(cell + Vector2i(0, -1)) if data.is_cell_in_map(cell + Vector2i(0, -1)) else ground
		var higher_grassy: bool = (higher_g == MapData.Ground.ARENA_GRASS or higher_g == MapData.Ground.FOREST_GRASS)
		for l in range(lvl, high_lvl):
			var side_name: String = "step_side_grass" if higher_grassy and l == high_lvl - 1 else "step_side"
			_batch(batches, side_name).add_vertical_quad(p_n, p_mid, l * lh, (l + 1) * lh, norm1, (l + 1) * lh)
			_batch(batches, side_name).add_vertical_quad(p_mid, p_e, l * lh, (l + 1) * lh, norm2, (l + 1) * lh)
		var high_tex: String = _top_texture(art, higher_g, cell)
		_batch(batches, high_tex).add_top_polygon([Vector2(cx + 1.0, cz), p_n, p_mid, p_e], high_lvl * lh)

	if se_ccv:
		var p_e := Vector2(cx + 1.0, cz + 1.0 - BEVEL_R)
		var p_mid := Vector2(cx + 1.0 - BEVEL_K, cz + 1.0 - BEVEL_K)
		var p_s := Vector2(cx + 1.0 - BEVEL_R, cz + 1.0)
		var high_lvl: int = mini(s_lvl, e_lvl)
		var norm1 := Vector2(-NORM_DIAG_2, -NORM_DIAG_1)
		var norm2 := Vector2(-NORM_DIAG_1, -NORM_DIAG_2)
		var higher_g: MapData.Ground = data.get_ground(cell + Vector2i(0, 1)) if data.is_cell_in_map(cell + Vector2i(0, 1)) else ground
		var higher_grassy: bool = (higher_g == MapData.Ground.ARENA_GRASS or higher_g == MapData.Ground.FOREST_GRASS)
		for l in range(lvl, high_lvl):
			var side_name: String = "step_side_grass" if higher_grassy and l == high_lvl - 1 else "step_side"
			_batch(batches, side_name).add_vertical_quad(p_e, p_mid, l * lh, (l + 1) * lh, norm1, (l + 1) * lh)
			_batch(batches, side_name).add_vertical_quad(p_mid, p_s, l * lh, (l + 1) * lh, norm2, (l + 1) * lh)
		var high_tex: String = _top_texture(art, higher_g, cell)
		_batch(batches, high_tex).add_top_polygon([Vector2(cx + 1.0, cz + 1.0), p_e, p_mid, p_s], high_lvl * lh)

	if sw_ccv:
		var p_s := Vector2(cx + BEVEL_R, cz + 1.0)
		var p_mid := Vector2(cx + BEVEL_K, cz + 1.0 - BEVEL_K)
		var p_w := Vector2(cx, cz + 1.0 - BEVEL_R)
		var high_lvl: int = mini(s_lvl, w_lvl)
		var norm1 := Vector2(NORM_DIAG_1, -NORM_DIAG_2)
		var norm2 := Vector2(NORM_DIAG_2, -NORM_DIAG_1)
		var higher_g: MapData.Ground = data.get_ground(cell + Vector2i(0, 1)) if data.is_cell_in_map(cell + Vector2i(0, 1)) else ground
		var higher_grassy: bool = (higher_g == MapData.Ground.ARENA_GRASS or higher_g == MapData.Ground.FOREST_GRASS)
		for l in range(lvl, high_lvl):
			var side_name: String = "step_side_grass" if higher_grassy and l == high_lvl - 1 else "step_side"
			_batch(batches, side_name).add_vertical_quad(p_s, p_mid, l * lh, (l + 1) * lh, norm1, (l + 1) * lh)
			_batch(batches, side_name).add_vertical_quad(p_mid, p_w, l * lh, (l + 1) * lh, norm2, (l + 1) * lh)
		var high_tex: String = _top_texture(art, higher_g, cell)
		_batch(batches, high_tex).add_top_polygon([Vector2(cx, cz + 1.0), p_s, p_mid, p_w], high_lvl * lh)


static func _get_level(data: MapData, cell: Vector2i, floor_level: int) -> int:
	if not data.is_cell_in_map(cell):
		return floor_level
	return data.get_level(cell)


static func _is_stair(data: MapData, cell: Vector2i) -> bool:
	if not data.is_cell_in_map(cell):
		return false
	return data.is_stair_cell(cell)


static func _is_convex(data: MapData, cell: Vector2i, d1: Vector2i, d2: Vector2i, floor_level: int) -> bool:
	var lvl: int = data.get_level(cell)
	var l1: int = _get_level(data, cell + d1, floor_level)
	var l2: int = _get_level(data, cell + d2, floor_level)
	if l1 >= lvl or l2 >= lvl:
		return false
	if _is_stair(data, cell) or _is_stair(data, cell + d1) or _is_stair(data, cell + d2):
		return false
	return true


static func _is_concave(data: MapData, cell: Vector2i, d1: Vector2i, d2: Vector2i, floor_level: int) -> bool:
	var lvl: int = data.get_level(cell)
	var l1: int = _get_level(data, cell + d1, floor_level)
	var l2: int = _get_level(data, cell + d2, floor_level)
	var l_diag: int = _get_level(data, cell + d1 + d2, floor_level)
	if l1 <= lvl or l2 <= lvl or l_diag <= lvl:
		return false
	if _is_stair(data, cell) or _is_stair(data, cell + d1) or _is_stair(data, cell + d2) or _is_stair(data, cell + d1 + d2):
		return false
	return true


static func _batch(batches: Dictionary, art_name: String) -> MeshBatch:
	if not batches.has(art_name):
		batches[art_name] = MeshBatch.new()
	return batches[art_name]


## Variante de textura por hash determinístico da célula (só visual).
static func _top_texture(art: ArtLibrary, ground: MapData.Ground, cell: Vector2i) -> String:
	var h: int = hash(cell)
	match ground:
		MapData.Ground.ARENA_GRASS:
			return art.terrain_variant_name("grass_arena", h)
		MapData.Ground.DIRT:
			return art.terrain_variant_name("dirt", h)
		MapData.Ground.RUIN_TILE:
			return art.terrain_variant_name("grass_arena", h)
		_:
			return art.terrain_variant_name("grass_forest", h)


## Escada: degraus subindo do lado sul (perto da câmera) para o norte.
static func _add_stair_cell(data: MapData, art: ArtLibrary, batches: Dictionary, cell: Vector2i) -> void:
	var lh: float = WorldScale.LEVEL_HEIGHT
	var steps: int = MapData.STAIR_STEPS
	var base_y: float = data.get_level(cell) * lh
	var step_h: float = lh / steps
	var step_d: float = 1.0 / steps
	var tread := _batch(batches, art.terrain_variant_name("dirt", hash(cell)))
	var riser := _batch(batches, "wall_face")
	var side := _batch(batches, "step_side")
	var x0: float = cell.x
	var x1: float = cell.x + 1.0
	var z_south: float = cell.y + 1.0
	var west_open: bool = not data.is_stair_cell(cell + Vector2i(-1, 0))
	var east_open: bool = not data.is_stair_cell(cell + Vector2i(1, 0))
	for i in steps:
		var y_lo: float = base_y + i * step_h
		var y_hi: float = base_y + (i + 1) * step_h
		var z_front: float = z_south - i * step_d
		var z_back: float = z_south - (i + 1) * step_d
		var p0 := Vector2(x0, z_back)
		var p1 := Vector2(x1, z_back)
		var p2 := Vector2(x1, z_front)
		var p3 := Vector2(x0, z_front)
		tread.add_top_quad(p0, p1, p2, p3, y_hi)
		riser.add_vertical_quad(p3, p2, y_lo, y_hi, Vector2(0.0, 1.0), y_hi)
		if west_open:
			side.add_vertical_quad(p0, p3, base_y, y_hi, Vector2(-1.0, 0.0), base_y + lh)
		if east_open:
			side.add_vertical_quad(p2, p1, base_y, y_hi, Vector2(1.0, 0.0), base_y + lh)
