class_name TerrainMeshBuilder
extends RefCounted
## Monta a ArrayMesh do terreno a partir do MapData: topo de cada célula, laterais dos
## degraus (1 quad por nível) e as escadas (4 direções, 2 degraus por nível).
## Anfiteatro (built_mask): muro de pedra com cantos retos. Floresta: barranco com os
## cantos arredondados por chanfro (aspecto orgânico). Uma superfície por textura.

const SIDE_DIRS: Array = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
const BEVEL_R: float = 0.38
## Recuo do ponto do meio do chanfro (no arco de 45°).
const BEVEL_K: float = BEVEL_R * (1.0 - sqrt(0.5))
const NORM_DIAG_1: float = 0.382683
const NORM_DIAG_2: float = 0.923880


static func build(data: MapData, art: ArtLibrary) -> ArrayMesh:
	var batches: Dictionary = {}
	var lh: float = WorldScale.LEVEL_HEIGHT
	# Fora do mapa: um nível abaixo da borda mais baixa (a saia de chão, SkirtMeshBuilder, cobre o resto).
	var floor_level: int = data.get_border_min_level() - 1

	for cz in data.size.y:
		for cx in data.size.x:
			var cell := Vector2i(cx, cz)
			var stair: bool = data.is_stair_cell(cell)
			if stair:
				_add_stair_cell(data, batches, cell, floor_level)
			elif data.is_arena_cell(cell):
				_build_arena_floor_cell(data, art, batches, cell, lh)
			else:
				_build_cell(data, art, batches, cell, lh, floor_level)

	var mesh := ArrayMesh.new()
	for art_name: String in batches:
		var batch: MeshBatch = batches[art_name]
		if art_name.begins_with("card:"):
			var card_key: String = art_name.substr(5)
			batch.commit(mesh, art.card_material(card_key))
		else:
			batch.commit(mesh, art.terrain_material(art_name))
	return mesh


static func _build_arena_floor_cell(data: MapData, _art: ArtLibrary, batches: Dictionary, cell: Vector2i, lh: float) -> void:
	var cx: int = cell.x
	var cz: int = cell.y
	var y: float = data.get_level(cell) * lh
	var steps: int = 4
	var sub_size: float = 1.0 / steps

	for sz in steps:
		for sx in steps:
			var p0 := Vector2(cx + sx * sub_size, cz + sz * sub_size)
			var p1 := Vector2(cx + (sx + 1) * sub_size, cz + sz * sub_size)
			var p2 := Vector2(cx + (sx + 1) * sub_size, cz + (sz + 1) * sub_size)
			var p3 := Vector2(cx + sx * sub_size, cz + (sz + 1) * sub_size)
			var center := (p0 + p2) * 0.5

			var delta := center - Vector2(22.0, 22.0)
			var dist: float = delta.length()
			var ang: float = atan2(delta.y, delta.x)

			var rad: float = 4.8 + sin(ang * 3.0 + 0.4) * 0.7 + cos(ang * 5.0) * 0.4 + sin(center.x * 2.2) * 0.25 + cos(center.y * 2.8) * 0.25

			var tex_name: String = "grass_arena_0"
			if dist < rad - 0.25:
				var is_island: bool = (center.distance_to(Vector2(21.4, 21.0)) < 0.65) or (center.distance_to(Vector2(23.2, 22.8)) < 0.55) or (center.distance_to(Vector2(20.5, 22.5)) < 0.45)
				if is_island:
					tex_name = "grass_arena_0"
				else:
					tex_name = "dirt_0" if posmod(cell.x + cell.y + sx, 2) == 0 else "dirt_1"
			elif dist < rad + 0.35:
				tex_name = "grass_arena_light_0"
			else:
				var h: int = hash(Vector2i(floori(center.x * 4), floori(center.y * 4)))
				if posmod(h, 24) == 0:
					tex_name = "grass_arena_3"
				elif posmod(h, 6) == 0:
					tex_name = "grass_arena_1"
				else:
					tex_name = "grass_arena_0"

			_batch(batches, tex_name).add_top_quad(p0, p1, p2, p3, y)


static func _build_cell(data: MapData, art: ArtLibrary, batches: Dictionary, cell: Vector2i, lh: float, floor_level: int) -> void:
	var cx: int = cell.x
	var cz: int = cell.y
	var lvl: int = data.get_level(cell)
	var ground: MapData.Ground = data.get_ground(cell)
	var top_name: String = _top_texture(art, ground, cell)
	var y: float = lvl * lh
	# Muro de pedra no anfiteatro, sem franja de grama.
	var built: bool = data.is_built_cell(cell)
	var grassy: bool = not built and (ground == MapData.Ground.ARENA_GRASS or ground == MapData.Ground.FOREST_GRASS)

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
	# Nível de baixo do arco de cada quina convexa: abaixo dele a quina é cheia
	# (o vizinho mais alto ainda está ali) e a parede reta do lado mais baixo vai até o canto.
	var nw_low: int = maxi(n_lvl, w_lvl)
	var ne_low: int = maxi(n_lvl, e_lvl)
	var se_low: int = maxi(s_lvl, e_lvl)
	var sw_low: int = maxi(s_lvl, w_lvl)

	# Paredes retas entre cantos
	if n_lvl < lvl and not _is_landing_of(data, cell, Vector2i(0, -1)):
		for l in range(n_lvl, lvl):
			var p_start := Vector2(cx + _corner_cut(nw_cvx, nw_low, l), cz)
			var p_end := Vector2(cx + 1.0 - _corner_cut(ne_cvx, ne_low, l), cz)
			_add_step_side(batches, p_start, p_end, l, lvl, lh, built, Vector2(0.0, -1.0), grassy, cell)

	if e_lvl < lvl and not _is_landing_of(data, cell, Vector2i(1, 0)):
		for l in range(e_lvl, lvl):
			var p_start := Vector2(cx + 1.0, cz + _corner_cut(ne_cvx, ne_low, l))
			var p_end := Vector2(cx + 1.0, cz + 1.0 - _corner_cut(se_cvx, se_low, l))
			_add_step_side(batches, p_start, p_end, l, lvl, lh, built, Vector2(1.0, 0.0), grassy, cell)

	if s_lvl < lvl and not _is_landing_of(data, cell, Vector2i(0, 1)):
		for l in range(s_lvl, lvl):
			var p_start := Vector2(cx + _corner_cut(sw_cvx, sw_low, l), cz + 1.0)
			var p_end := Vector2(cx + 1.0 - _corner_cut(se_cvx, se_low, l), cz + 1.0)
			_add_step_side(batches, p_start, p_end, l, lvl, lh, built, Vector2(0.0, 1.0), grassy, cell)

	if w_lvl < lvl and not _is_landing_of(data, cell, Vector2i(-1, 0)):
		for l in range(w_lvl, lvl):
			var p_start := Vector2(cx, cz + _corner_cut(nw_cvx, nw_low, l))
			var p_end := Vector2(cx, cz + 1.0 - _corner_cut(sw_cvx, sw_low, l))
			_add_step_side(batches, p_start, p_end, l, lvl, lh, built, Vector2(-1.0, 0.0), grassy, cell)

	# Cantos convexos (arredondados para fora)
	if nw_cvx:
		var p_w := Vector2(cx, cz + BEVEL_R)
		var p_mid := Vector2(cx + BEVEL_K, cz + BEVEL_K)
		var p_n := Vector2(cx + BEVEL_R, cz)
		var low_lvl: int = nw_low
		var norm1 := Vector2(-NORM_DIAG_1, -NORM_DIAG_2)
		var norm2 := Vector2(-NORM_DIAG_2, -NORM_DIAG_1)
		for l in range(low_lvl, lvl):
			_add_step_side(batches, p_n, p_mid, l, lvl, lh, false, norm1, grassy, cell)
			_add_step_side(batches, p_mid, p_w, l, lvl, lh, false, norm2, grassy, cell)
		var lower_g: MapData.Ground = data.get_ground(cell + Vector2i(0, -1)) if data.is_cell_in_map(cell + Vector2i(0, -1)) else ground
		var fill_tex: String = _top_texture(art, lower_g, cell)
		_batch(batches, fill_tex).add_top_polygon([Vector2(cx, cz), p_w, p_mid, p_n], low_lvl * lh)

	if ne_cvx:
		var p_n := Vector2(cx + 1.0 - BEVEL_R, cz)
		var p_mid := Vector2(cx + 1.0 - BEVEL_K, cz + BEVEL_K)
		var p_e := Vector2(cx + 1.0, cz + BEVEL_R)
		var low_lvl: int = ne_low
		var norm1 := Vector2(NORM_DIAG_1, -NORM_DIAG_2)
		var norm2 := Vector2(NORM_DIAG_2, -NORM_DIAG_1)
		for l in range(low_lvl, lvl):
			_add_step_side(batches, p_n, p_mid, l, lvl, lh, false, norm1, grassy, cell)
			_add_step_side(batches, p_mid, p_e, l, lvl, lh, false, norm2, grassy, cell)
		var lower_g: MapData.Ground = data.get_ground(cell + Vector2i(0, -1)) if data.is_cell_in_map(cell + Vector2i(0, -1)) else ground
		var fill_tex: String = _top_texture(art, lower_g, cell)
		_batch(batches, fill_tex).add_top_polygon([Vector2(cx + 1.0, cz), p_n, p_mid, p_e], low_lvl * lh)

	if se_cvx:
		var p_e := Vector2(cx + 1.0, cz + 1.0 - BEVEL_R)
		var p_mid := Vector2(cx + 1.0 - BEVEL_K, cz + 1.0 - BEVEL_K)
		var p_s := Vector2(cx + 1.0 - BEVEL_R, cz + 1.0)
		var low_lvl: int = se_low
		var norm1 := Vector2(NORM_DIAG_2, NORM_DIAG_1)
		var norm2 := Vector2(NORM_DIAG_1, NORM_DIAG_2)
		for l in range(low_lvl, lvl):
			_add_step_side(batches, p_e, p_mid, l, lvl, lh, false, norm1, grassy, cell)
			_add_step_side(batches, p_mid, p_s, l, lvl, lh, false, norm2, grassy, cell)
		var lower_g: MapData.Ground = data.get_ground(cell + Vector2i(0, 1)) if data.is_cell_in_map(cell + Vector2i(0, 1)) else ground
		var fill_tex: String = _top_texture(art, lower_g, cell)
		_batch(batches, fill_tex).add_top_polygon([Vector2(cx + 1.0, cz + 1.0), p_e, p_mid, p_s], low_lvl * lh)

	if sw_cvx:
		var p_s := Vector2(cx + BEVEL_R, cz + 1.0)
		var p_mid := Vector2(cx + BEVEL_K, cz + 1.0 - BEVEL_K)
		var p_w := Vector2(cx, cz + 1.0 - BEVEL_R)
		var low_lvl: int = sw_low
		var norm1 := Vector2(-NORM_DIAG_1, NORM_DIAG_2)
		var norm2 := Vector2(-NORM_DIAG_2, NORM_DIAG_1)
		for l in range(low_lvl, lvl):
			_add_step_side(batches, p_s, p_mid, l, lvl, lh, false, norm1, grassy, cell)
			_add_step_side(batches, p_mid, p_w, l, lvl, lh, false, norm2, grassy, cell)
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
			_add_step_side(batches, p_w, p_mid, l, high_lvl, lh, false, norm1, higher_grassy, cell)
			_add_step_side(batches, p_mid, p_n, l, high_lvl, lh, false, norm2, higher_grassy, cell)
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
			_add_step_side(batches, p_n, p_mid, l, high_lvl, lh, false, norm1, higher_grassy, cell)
			_add_step_side(batches, p_mid, p_e, l, high_lvl, lh, false, norm2, higher_grassy, cell)
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
			_add_step_side(batches, p_e, p_mid, l, high_lvl, lh, false, norm1, higher_grassy, cell)
			_add_step_side(batches, p_mid, p_s, l, high_lvl, lh, false, norm2, higher_grassy, cell)
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
			_add_step_side(batches, p_s, p_mid, l, high_lvl, lh, false, norm1, higher_grassy, cell)
			_add_step_side(batches, p_mid, p_w, l, high_lvl, lh, false, norm2, higher_grassy, cell)
		var high_tex: String = _top_texture(art, higher_g, cell)
		_batch(batches, high_tex).add_top_polygon([Vector2(cx, cz + 1.0), p_s, p_mid, p_w], high_lvl * lh)


static func _add_step_side(batches: Dictionary, p_start: Vector2, p_end: Vector2, l: int, lvl_top: int, lh: float, built: bool, normal: Vector2, is_grassy: bool, cell: Vector2i) -> void:
	var on_top: bool = is_grassy and (l == lvl_top - 1)
	var side_name: String = "step_side_grass" if on_top else "step_side"
	if built:
		side_name = "wall_face"
		on_top = false
	_batch(batches, side_name).add_vertical_quad(p_start, p_end, l * lh, (l + 1) * lh, normal, (l + 1) * lh)
	if on_top:
		var fvar: int = posmod(cell.x * 11 + cell.y * 17 + l, 2)
		_add_fringe_quad(batches, p_start, p_end, (l + 1) * lh, normal, fvar)
	elif built and l == lvl_top - 1:
		_add_wall_top_quad(batches, p_start, p_end, (l + 1) * lh, normal)
		var mvar: int = posmod(cell.x * 7 + cell.y * 13 + l, 2)
		_add_moss_fringe_quad(batches, p_start, p_end, (l + 1) * lh, normal, mvar)


static func _add_wall_top_quad(batches: Dictionary, p_start: Vector2, p_end: Vector2, y_top: float, normal: Vector2) -> void:
	var width: float = 0.42
	var p0 := p_start
	var p1 := p_end
	var p2 := p_end - normal * width
	var p3 := p_start - normal * width
	_batch(batches, "wall_top").add_top_quad(p0, p1, p2, p3, y_top + 0.002)


static func _add_moss_fringe_quad(batches: Dictionary, p_start: Vector2, p_end: Vector2, y_top: float, normal: Vector2, fringe_var: int) -> void:
	var batch: MeshBatch = _batch(batches, "card:moss_fringe_%d" % fringe_var)
	var right := Vector2(normal.y, -normal.x)
	var left_pt: Vector2 = p_start
	var right_pt: Vector2 = p_end
	if (p_end - p_start).dot(right) < 0.0:
		left_pt = p_end
		right_pt = p_start
	var u_l: float = left_pt.dot(right)
	var u_r: float = right_pt.dot(right)

	var top_l := Vector3(left_pt.x - normal.x * 0.02, y_top + 0.005, left_pt.y - normal.y * 0.02)
	var top_r := Vector3(right_pt.x - normal.x * 0.02, y_top + 0.005, right_pt.y - normal.y * 0.02)
	var bot_r := Vector3(right_pt.x + normal.x * 0.04, y_top - 0.22, right_pt.y + normal.y * 0.04)
	var bot_l := Vector3(left_pt.x + normal.x * 0.04, y_top - 0.22, left_pt.y + normal.y * 0.04)

	var norm3 := Vector3(normal.x * 0.25, 0.95, normal.y * 0.25).normalized()
	batch.add_quad(
		top_l, top_r, bot_r, bot_l,
		norm3,
		Vector2(u_l, 0.0), Vector2(u_r, 0.0), Vector2(u_r, 1.0), Vector2(u_l, 1.0)
	)


static func _add_fringe_quad(batches: Dictionary, p_start: Vector2, p_end: Vector2, y_top: float, normal: Vector2, fringe_var: int) -> void:
	var batch: MeshBatch = _batch(batches, "card:grass_fringe_%d" % fringe_var)
	var right := Vector2(normal.y, -normal.x)
	var left_pt: Vector2 = p_start
	var right_pt: Vector2 = p_end
	if (p_end - p_start).dot(right) < 0.0:
		left_pt = p_end
		right_pt = p_start
	var u_l: float = left_pt.dot(right)
	var u_r: float = right_pt.dot(right)

	# Âncora no topo da quina (recuo 0.03 para dentro, elevação 0.01)
	var top_l := Vector3(left_pt.x - normal.x * 0.03, y_top + 0.01, left_pt.y - normal.y * 0.03)
	var top_r := Vector3(right_pt.x - normal.x * 0.03, y_top + 0.01, right_pt.y - normal.y * 0.03)

	# Borda inferior pendente (desce 0.20, projeta 0.05 para fora ~14 graus)
	var bot_r := Vector3(right_pt.x + normal.x * 0.05, y_top - 0.20, right_pt.y + normal.y * 0.05)
	var bot_l := Vector3(left_pt.x + normal.x * 0.05, y_top - 0.20, left_pt.y + normal.y * 0.05)

	# Normal inclinada para cima para ter iluminação coerente com o topo da grama
	var norm3 := Vector3(normal.x * 0.25, 0.95, normal.y * 0.25).normalized()
	batch.add_quad(
		top_l, top_r, bot_r, bot_l,
		norm3,
		Vector2(u_l, 0.0), Vector2(u_r, 0.0), Vector2(u_r, 1.0), Vector2(u_l, 1.0)
	)


## Corte da parede reta na quina: BEVEL_R só do nível de baixo do arco para cima.
static func _corner_cut(convex: bool, low_lvl: int, l: int) -> float:
	return BEVEL_R if convex and l >= low_lvl else 0.0


static func _get_level(data: MapData, cell: Vector2i, floor_level: int) -> int:
	if not data.is_cell_in_map(cell):
		return floor_level
	return data.get_level(cell)


static func _is_stair(data: MapData, cell: Vector2i) -> bool:
	if not data.is_cell_in_map(cell):
		return false
	return data.is_stair_cell(cell)


## Verdadeiro se o vizinho em dir é uma escada que chega nesta célula (ela é o patamar de
## cima): a face entre as duas fica escondida embaixo do último degrau.
static func _is_landing_of(data: MapData, cell: Vector2i, dir: Vector2i) -> bool:
	return _is_stair(data, cell + dir) and data.stair_up_at(cell + dir) == -dir


static func _is_convex(data: MapData, cell: Vector2i, d1: Vector2i, d2: Vector2i, floor_level: int) -> bool:
	if data.is_built_cell(cell):
		return false
	var lvl: int = data.get_level(cell)
	var l1: int = _get_level(data, cell + d1, floor_level)
	var l2: int = _get_level(data, cell + d2, floor_level)
	if l1 >= lvl or l2 >= lvl:
		return false
	if _is_stair(data, cell) or _is_stair(data, cell + d1) or _is_stair(data, cell + d2):
		return false
	return true


static func _is_concave(data: MapData, cell: Vector2i, d1: Vector2i, d2: Vector2i, floor_level: int) -> bool:
	if data.is_built_cell(cell):
		return false
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
		MapData.Ground.STONE_PATH:
			return "ruin_tile"
		_:
			return art.terrain_variant_name("grass_forest", h)


## Escada: 2 degraus por nível subindo em up_direction (qualquer das 4 direções), em pedra.
## Piso do degrau com stair_tread; espelho e laterais com stair_riser. A lateral só aparece onde
## o vizinho é mais baixo que o degrau (o muro do vizinho mais alto cobre o resto).
static func _add_stair_cell(data: MapData, batches: Dictionary, cell: Vector2i, floor_level: int) -> void:
	var lh: float = WorldScale.LEVEL_HEIGHT
	var steps: int = MapData.STAIR_STEPS_PER_LEVEL
	var up: Vector2i = data.stair_up_at(cell)
	var base_y: float = data.get_level(cell) * lh
	var step_h: float = lh / steps
	var step_d: float = 1.0 / steps
	var tread := _batch(batches, "wall_top")
	var stone := _batch(batches, "wall_face")
	var fwd := Vector2(up)
	var right := Vector2(-up.y, up.x)
	var center := Vector2(cell) + Vector2(0.5, 0.5)
	# Laterais: altura do topo do vizinho de cada lado (escada igual ao lado = sem lateral).
	var side_tops: Array[float] = []
	for sgn: int in [-1, 1]:
		var nb: Vector2i = cell + Vector2i(roundi(right.x), roundi(right.y)) * sgn
		if _is_stair(data, nb) and data.stair_up_at(nb) == up:
			side_tops.append(INF)
		else:
			side_tops.append(_get_level(data, nb, floor_level) * lh)
	for i in steps:
		var y_lo: float = base_y + i * step_h
		var y_hi: float = y_lo + step_h
		var u0: float = i * step_d - 0.5
		var u1: float = (i + 1) * step_d - 0.5
		var a: Vector2 = center + fwd * u0 - right * 0.5
		var b: Vector2 = center + fwd * u0 + right * 0.5
		var c: Vector2 = center + fwd * u1 + right * 0.5
		var d: Vector2 = center + fwd * u1 - right * 0.5
		var v_top: float = ceilf(y_hi / lh - 0.001) * lh
		tread.add_top_quad(a, b, c, d, y_hi)
		stone.add_vertical_quad(a, b, y_lo, y_hi, -fwd, v_top)
		if side_tops[0] < y_hi:
			var side_lo0: float = maxf(side_tops[0], y_lo)
			if side_lo0 < y_hi:
				stone.add_vertical_quad(a, d, side_lo0, y_hi, -right, v_top)
		if side_tops[1] < y_hi:
			var side_lo1: float = maxf(side_tops[1], y_lo)
			if side_lo1 < y_hi:
				stone.add_vertical_quad(b, c, side_lo1, y_hi, right, v_top)
		if i == steps - 1:
			var back_nb: Vector2i = cell + up
			var back_top: float = _get_level(data, back_nb, floor_level) * lh if not (_is_stair(data, back_nb) and data.stair_up_at(back_nb) == up) else y_hi
			if back_top < y_hi:
				stone.add_vertical_quad(c, d, back_top, y_hi, fwd, v_top)
