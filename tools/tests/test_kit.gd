extends SceneTree
## Testes do kit (spec 011, fases 1 e 2, e spec 012 Fase 1): toda cena de scenes/kit/ abre, tem malha visível,
## o tamanho/pivô da tabela e os marcadores certos; materiais em assets/materials/; capeamento, quinas,
## árvores pintadas (lóbulos de cartões e andares de cartões), peças da ilha e decalques da arena.
## Rodar depois do comando de validação 1:
##   "$G" --headless --path . --script tools/tests/test_kit.gd

const KIT_DIR: String = "res://scenes/kit/"
const TOLERANCE: float = 0.001
## Beiral das lajes (2 texels) e musgo pendente passam da pegada: até 0,08 por lado.
const OVERHANG: float = 0.16
const MESH_DIR: String = "res://assets/models/kit/"
const MATERIAL_DIR: String = "res://assets/materials/"
## Cenas obrigatórias da tabela do Kit (nome -> pegada largura, fundo e altura).
const REQUIRED: Dictionary = {
	"step_low_2": Vector3(2, 0.5, 1), "step_low_1": Vector3(1, 0.5, 1), "step_low_corner": Vector3(1, 0.5, 1),
	"terrace_fill_4x3": Vector3(4, 0.5, 3), "terrace_fill_2x3": Vector3(2, 0.5, 3),
	"terrace_fill_1x3": Vector3(1, 0.5, 3), "terrace_fill_3x3": Vector3(3, 0.5, 3),
	"wall_high_2": Vector3(2, 1.0, 1), "wall_high_1": Vector3(1, 1.0, 1), "wall_high_corner": Vector3(1, 1.0, 1),
	"stair_outer_3": Vector3(3, 1.0, 2), "stair_inner_3": Vector3(3, 1.0, 1), "stair_low_3": Vector3(3, 0.5, 1),
	"terrace_fill_4x2": Vector3(4, 0.5, 2), "terrace_fill_3x2": Vector3(3, 0.5, 2),
	"stair_crest_in_3": Vector3(4, 1.0, 1), "stair_pass_out_3": Vector3(3, 0.75, 2), "stair_crest_3": Vector3(3, 1.0, 1),
	"stair_landing_3": Vector3(1, 0.5, 3),
}
## Marcadores esperados nas peças de escada e passagem: [StairArea, HeightArea]. As outras estruturais: [0, 1].
const STAIR_MARKERS: Dictionary = {
	"stair_outer_3": [1, 2], "stair_inner_3": [1, 2], "stair_low_3": [1, 0], "stair_crest_in_3": [1, 2],
	"stair_pass_out_3": [1, 0], "stair_crest_3": [0, 1], "stair_landing_3": [0, 1],
}
const REQUIRED_NAMES: PackedStringArray = [
	"island_top", "island_cliff", "island_under", "root_hang_a", "root_hang_b", "root_hang_c", "vine_hang_a", "vine_hang_b",
	"island_high", "high_spur", "high_block", "waterfall", "rainbow", "islet_ruins", "islet_ne", "islet_w", "islet_e",
	"rock_float_a", "rock_float_b", "rock_float_c", "rock_big", "ruin_column_a", "ruin_column_b", "ruin_column_c", "ruin_lintel",
	"cloud_a", "cloud_b", "cloud_c", "cloud_d", "cloud_e", "brazier_a", "bridge_rope_w", "bridge_rope_e", "landing_south",
	"landing_north", "platform_w", "path_ne", "pillar_stone", "arena_ground", "arena_slabs",
	"ground_inner", "ground_outer", "decal_arena_dirt", "decal_grass_light_0", "decal_grass_light_1",
	"decal_grass_light_2", "decal_grass_dark_0", "decal_grass_dark_1", "decal_forest_soil_0", "decal_forest_soil_1",
	"decal_trail_0", "decal_trail_1", "decal_trail_2", "decal_trail_3", "decal_trail_bend",
	"tree_broad_a", "tree_broad_b", "tree_broad_c", "tree_broad_d", "tree_broad_e",
	"tree_small_a", "tree_small_b", "tree_small_c",
	"conifer_a", "conifer_b", "conifer_c", "conifer_d", "conifer_e", "conifer_f",
	"bush_a", "bush_b", "bush_c", "bush_d", "log_a", "log_b", "log_c", "stump_a", "stump_b",
	"rock_a", "rock_b", "rock_c", "rock_d", "bench_wood", "crate", "crate_stack", "wood_pile",
	"mushrooms_a", "mushrooms_b", "mushrooms_c", "mushrooms_d", "flowers_a", "flowers_b", "flowers_c", "flowers_d",
	"tall_grass_a", "tall_grass_b", "tall_grass_c",
]

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
		print("FAIL: ", what, (" -> " + detail.left(600)) if detail != "" else "")


func _run() -> void:
	var files: Array[String] = []
	for file_name: String in DirAccess.get_files_at(KIT_DIR):
		if file_name.ends_with(".tscn"):
			files.append(file_name.get_basename())
	files.sort()
	_check(files.size() >= REQUIRED.size() + REQUIRED_NAMES.size(), "kit tem as %d cenas da tabela (achou %d)" % [
			REQUIRED.size() + REQUIRED_NAMES.size(), files.size()])
	var missing: Array[String] = []
	for kit_name: String in REQUIRED.keys():
		if not files.has(kit_name):
			missing.append(kit_name)
	for kit_name: String in REQUIRED_NAMES:
		if not files.has(kit_name):
			missing.append(kit_name)
	_check(missing.is_empty(), "nenhuma cena da tabela do Kit falta", str(missing))

	var no_mesh: Array[String] = []
	var bad_root: Array[String] = []
	var empty_aabb: Array[String] = []
	var size_bad: Array[String] = []
	var marker_bad: Array[String] = []
	var off_grid: Array[String] = []
	for kit_name: String in files:
		var scene := load(KIT_DIR + kit_name + ".tscn") as PackedScene
		var piece := scene.instantiate() as KitPiece
		if piece == null:
			bad_root.append(kit_name)
			continue
		root.add_child(piece)
		await process_frame
		var mesh_node := piece.get_node_or_null("Mesh") as MeshInstance3D
		if mesh_node == null or mesh_node.mesh == null or mesh_node.mesh.get_surface_count() == 0:
			no_mesh.append(kit_name)
		elif mesh_node.get_aabb().size.length() < 0.1:
			empty_aabb.append(kit_name)
		if REQUIRED.has(kit_name):
			var want: Vector3 = REQUIRED[kit_name]
			if not (is_equal_approx(piece.size.x, want.x) and is_equal_approx(piece.size.z, want.z) and is_equal_approx(piece.size.y, want.y)):
				size_bad.append("%s: %s" % [kit_name, piece.size])
			if not piece.structural:
				marker_bad.append(kit_name + " não é structural")
			var heights: int = 0
			var stairs: int = 0
			for child: Node in piece.get_children():
				if child is HeightArea:
					heights += 1
				elif child is StairArea:
					stairs += 1
			var want_markers: Array = STAIR_MARKERS.get(kit_name, [0, 1])
			if stairs != int(want_markers[0]) or heights != int(want_markers[1]):
				marker_bad.append("%s: %d StairArea e %d HeightArea (esperado %s)" % [kit_name, stairs, heights, str(want_markers)])
			# A pegada da malha cabe na tabela (tolerância para o beiral).
			if mesh_node != null and mesh_node.mesh != null:
				var box: AABB = mesh_node.get_aabb()
				if box.size.x > want.x + OVERHANG or box.size.z > want.z + OVERHANG:
					off_grid.append("%s: malha %s" % [kit_name, box.size])
		piece.queue_free()
	_check(bad_root.is_empty(), "toda cena do kit tem KitPiece na raiz", str(bad_root))
	_check(no_mesh.is_empty(), "toda cena do kit tem malha visível", str(no_mesh))
	_check(empty_aabb.is_empty(), "nenhuma malha vazia ou minúscula", str(empty_aabb))
	_check(size_bad.is_empty(), "tamanhos das peças estruturais batem com a tabela", str(size_bad))
	_check(marker_bad.is_empty(), "peças estruturais com HeightArea / StairArea certos", str(marker_bad))
	_check(off_grid.is_empty(), "a malha cabe na pegada da tabela", str(off_grid))
	_check_materials_and_meshes(files)
	_check_wall_continuity()
	_check_slabs()
	_check_trees()
	_check_no_pixel_scenery()
	await _check_decals()
	print("")
	if _failures == 0:
		print("RESULTADO: PASS (%d verificações)" % _passes)
	else:
		print("RESULTADO: FAIL (%d de %d verificações falharam)" % [_failures, _passes + _failures])
	quit(0 if _failures == 0 else 1)


## Toda superfície usa um ShaderMaterial salvo em assets/materials/ e toda malha é um arquivo de assets/models/kit/.
func _check_materials_and_meshes(files: Array[String]) -> void:
	var bad_mat: Array[String] = []
	var bad_mesh: Array[String] = []
	for kit_name: String in files:
		var piece := (load(KIT_DIR + kit_name + ".tscn") as PackedScene).instantiate() as KitPiece
		var mesh_node := piece.get_node_or_null("Mesh") as MeshInstance3D
		if mesh_node != null and mesh_node.mesh != null:
			if not mesh_node.mesh.resource_path.begins_with(MESH_DIR):
				bad_mesh.append(kit_name)
			for i in mesh_node.mesh.get_surface_count():
				var mat := mesh_node.mesh.surface_get_material(i) as ShaderMaterial
				if mat == null or not mat.resource_path.begins_with(MATERIAL_DIR) or mat.shader == null:
					bad_mat.append("%s[%d]" % [kit_name, i])
		piece.free()
	_check(bad_mesh.is_empty(), "toda malha vem de assets/models/kit/*.res", str(bad_mesh))
	_check(bad_mat.is_empty(), "toda superfície usa um ShaderMaterial de assets/materials/*.tres", str(bad_mat))
	var bad_tex: Array[String] = []
	for key: String in KitMaterialDefs.all().keys():
		var mat := load(MATERIAL_DIR + key + ".tres") as ShaderMaterial
		if mat.get_shader_parameter("albedo_tex") as Texture2D == null:
			bad_tex.append(key)
	_check(bad_tex.is_empty(), "todo material tem albedo_tex (texturas existentes)", str(bad_tex))


## Posição u de uma faixa (capeamento, musgo) no mundo, como o shader calcula: dot(posição, eixo X local no mundo).
func _strip_u(piece_xf: Transform3D, local_x: float) -> float:
	var world: Vector3 = piece_xf * Vector3(local_x, 0.0, 0.0)
	var axis: Vector3 = piece_xf.basis * Vector3(1.0, 0.0, 0.0)
	return world.x * axis.x + world.z * axis.z


## Duas peças wall_high_2 vizinhas: u do capeamento e do musgo é o mesmo nas duas bordas da emenda
## (u de mundo), nas quatro orientações; as faces usam projeção no mundo (sem u por peça).
func _check_wall_continuity() -> void:
	var worst: float = 0.0
	for yaw in [0.0, 90.0, 180.0, 270.0]:
		var basis := Basis(Vector3.UP, deg_to_rad(yaw))
		var along: Vector3 = basis * Vector3(1.0, 0.0, 0.0)
		var a := Transform3D(basis, Vector3(3.0, 0.0, 5.0))
		var b := Transform3D(basis, Vector3(3.0, 0.0, 5.0) + along * 2.0)
		# Borda direita de A (local +1) e borda esquerda de B (local -1) são o mesmo ponto do mundo.
		worst = maxf(worst, absf(_strip_u(a, 1.0) - _strip_u(b, -1.0)))
	_check(worst < 0.001, "u do capeamento continua sem salto na emenda de dois wall_high_2 (%.5f)" % worst)
	for key: String in ["wall_high_face", "wall_low_face", "ground_grass_arena", "ground_grass_forest"]:
		var mat := load(MATERIAL_DIR + key + ".tres") as ShaderMaterial
		var mode: int = int(mat.get_shader_parameter("uv_mode"))
		var world_space: Variant = mat.get_shader_parameter("world_space")
		_check(mode == 1 and (world_space == null or world_space == true), "%s usa UV de mundo (projeção no mundo)" % key)
	for key: String in ["wall_cap", "wall_crest", "wall_cap_z", "wall_crest_z"]:
		var mat := load(MATERIAL_DIR + key + ".tres") as ShaderMaterial
		_check(int(mat.get_shader_parameter("uv_mode")) == 2, "%s corre contínuo em faixa (u de mundo)" % key)
	# Fase 2 da 012: pedra pintada (scenery_stone) com filtro linear, mipmaps e anisotrópico, a 64 px por unidade.
	var shader_text: String = FileAccess.get_file_as_string("res://assets/materials/scenery_stone.gdshader")
	var filters_ok: bool = true
	for hint: String in ["albedo_tex : source_color, filter_linear_mipmap_anisotropic", "normal_tex : hint_normal, filter_linear_mipmap_anisotropic"]:
		if not shader_text.contains(hint):
			filters_ok = false
	_check(filters_ok, "a pedra pintada amostra com filtro linear, mipmaps e anisotrópico")
	_check(shader_text.contains("cross(dFdx(v_pos), dFdy(v_pos))"), "o eixo da projeção vem da normal geométrica da face (não da normal da copa)")
	var blocks := load(MATERIAL_DIR + "wall_high_face.tres") as ShaderMaterial
	var want_scale := Vector2(float(WorldScale.SCENERY_TEXELS_PER_UNIT) / 512.0, float(WorldScale.SCENERY_TEXELS_PER_UNIT) / 128.0)
	_check(WorldScale.SCENERY_TEXELS_PER_UNIT == 64 and (blocks.get_shader_parameter("uv_scale") as Vector2).is_equal_approx(want_scale),
			"muro a 64 px por unidade (uv_scale %s)" % str(blocks.get_shader_parameter("uv_scale")))
	var out_face := load(MATERIAL_DIR + "wall_high_face_out.tres") as ShaderMaterial
	_check(str((out_face.get_shader_parameter("albedo_tex") as Texture2D).resource_path).ends_with("wall_blocks_mossy.png"),
			"face externa do muro alto com wall_blocks_mossy")
	for key: String in ["wall_cap", "wall_cap_z", "wall_cap_low", "wall_crest", "wall_crest_z", "wall_crest_corner", "wall_cap_corner", "wall_quoin", "wall_high_face", "slab_painted", "bark"]:
		var mat := load(MATERIAL_DIR + key + ".tres") as ShaderMaterial
		var scale: float = float(mat.get_shader_parameter("normal_scale"))
		_check(mat.get_shader_parameter("use_normal") == true and scale >= 0.4 and scale <= 0.7, "%s usa normal map de pedra com força %.2f (0,4 a 0,7)" % [key, scale])
	var used_keys: Dictionary = {}
	for mesh_name: String in ["wall_high_corner", "wood_pile", "step_low_corner", "stair_outer_3"]:
		var mesh := load(MESH_DIR + mesh_name + ".res") as ArrayMesh
		for i in mesh.get_surface_count():
			used_keys[(mesh.surface_get_material(i) as ShaderMaterial).resource_path.get_file().get_basename()] = true
	for key: String in ["wall_quoin", "wall_crest_corner", "wall_cap_corner", "wood_pile_end", "wall_crest_z"]:
		_check(used_keys.has(key), "%s está ligada a uma malha do kit" % key)


## Capeamento em lajes individuais: larguras variadas, beiral de 1 a 2 texels, topo variando 1 a 2.
func _check_slabs() -> void:
	var rows: Dictionary = {
		"wall_high_2 interna": KitTables.SLABS_WALL_2_INNER, "wall_high_2 externa": KitTables.SLABS_WALL_2_OUTER,
		"wall_high_1 interna": KitTables.SLABS_WALL_1_INNER, "wall_high_1 externa": KitTables.SLABS_WALL_1_OUTER,
		"degrau 2": KitTables.SLABS_STEP_2, "degrau 1": KitTables.SLABS_STEP_1,
		"bochecha 2 fora": KitTables.SLABS_CHEEK_2_OUT, "bochecha 2 dentro": KitTables.SLABS_CHEEK_2_IN,
		"bochecha 1 fora": KitTables.SLABS_CHEEK_1_OUT, "bochecha 1 dentro": KitTables.SLABS_CHEEK_1_IN,
	}
	var lengths: Dictionary = {
		"wall_high_2 interna": 64, "wall_high_2 externa": 64, "wall_high_1 interna": 32, "wall_high_1 externa": 32,
		"degrau 2": 64, "degrau 1": 32, "bochecha 2 fora": 64, "bochecha 2 dentro": 64, "bochecha 1 fora": 32, "bochecha 1 dentro": 32,
	}
	var problems: Array[String] = []
	for row_name: String in rows.keys():
		var total: int = 0
		for slab: Array in rows[row_name]:
			total += int(slab[0])
			if int(slab[0]) < 10 or int(slab[0]) > 25 or int(slab[2]) < 1 or int(slab[2]) > 2 or int(slab[3]) < 1 or int(slab[3]) > 2:
				problems.append("%s: laje fora das faixas %s" % [row_name, slab])
		if total != int(lengths[row_name]):
			problems.append("%s: soma %d != %d" % [row_name, total, lengths[row_name]])
	_check(problems.is_empty(), "lajes: larguras de 0,3 a 0,8, beiral 1 a 2 texels, topo 1 a 2 texels, somas certas", str(problems))
	# Muro alto: lajes de 6 a 9 texels de fundo (o musgo da crista fica visível); bochechas de 6 a 7 por borda.
	var depth_bad: Array[String] = []
	for row_name: String in rows.keys():
		if row_name.begins_with("degrau"):
			continue
		var max_depth: int = 7 if row_name.begins_with("bochecha") else 9
		for slab: Array in rows[row_name]:
			if int(slab[1]) < 6 or int(slab[1]) > max_depth:
				depth_bad.append("%s: fundo %d" % [row_name, int(slab[1])])
	_check(depth_bad.is_empty(), "lajes do muro e das bochechas com 6 a 9 texels de fundo", str(depth_bad))
	for row_name: String in ["wall_high_2 interna", "wall_high_2 externa"]:
		var widths: Dictionary = {}
		for slab: Array in rows[row_name]:
			widths[int(slab[0])] = true
		_check(widths.size() >= 4, "%s tem >= 4 larguras de laje distintas (%d)" % [row_name, widths.size()])
	# A malha do muro tem de fato as lajes na geometria (superfície de capeamento com muitos triângulos).
	var wall_mesh := load(MESH_DIR + "wall_high_2.res") as ArrayMesh
	var cap_tris: int = 0
	for i in wall_mesh.get_surface_count():
		var mat := wall_mesh.surface_get_material(i) as ShaderMaterial
		if mat != null and mat.resource_path.ends_with("/wall_cap.tres"):
			cap_tris = (wall_mesh.surface_get_arrays(i)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	_check(cap_tris >= 10, "wall_high_2 modela as lajes de capeamento na geometria (%d triângulos)" % cap_tris)


## Árvores pintadas (spec 012): folhosas com 6 a 14 lóbulos, coníferas com 5 a 9 andares; copa feita de muitos
## cartões de folhagem (material scenery_foliage) mais o tronco (scenery_solid). Nenhuma árvore em cartão único.
func _check_trees() -> void:
	var bad: Array[String] = []
	for i in KitTables.BROAD.size():
		var lobes: int = (KitTables.BROAD[i]["lobes"] as Array).size()
		if lobes < 6 or lobes > 14:
			bad.append("folhosa %d: %d lóbulos" % [i, lobes])
	_check(bad.is_empty(), "cada folhosa tem de 6 a 14 lóbulos", str(bad))
	bad.clear()
	for i in KitTables.CONIFERS.size():
		var tiers: Array = KitTables.CONIFERS[i]["tiers"]
		if tiers.size() < 5 or tiers.size() > 9:
			bad.append("conífera %d: %d andares" % [i, tiers.size()])
	_check(bad.is_empty(), "cada conífera tem de 5 a 9 andares", str(bad))
	bad.clear()
	# Revisão 012-f2: coníferas altas e estreitas (base = 2 x o maior alcance dos cartões, de 2,0 a 3,2; altura de
	# 6 a 9 e >= 2,4 x base), de 7 a 9 cartões por andar e alcances fora de uma reta (pelo menos 1 andar sobe).
	for i in KitTables.CONIFERS.size():
		var base: float = 2.0 * SceneryPieces.conifer_radius(i)
		var height: float = SceneryPieces.conifer_height(i)
		var tiers_i: Array = KitTables.CONIFERS[i]["tiers"]
		var cards_ok: bool = true
		var bumps: int = 0
		for t in tiers_i.size():
			var cards: int = int(tiers_i[t][4])
			cards_ok = cards_ok and cards >= 7 and cards <= 9
			if t > 0 and t < tiers_i.size() - 1 and float(tiers_i[t][2]) > float(tiers_i[t - 1][2]):
				bumps += 1
		if base < 2.0 or base > 3.2 or height < 6.0 or height > 9.0 or height < 2.4 * base or not cards_ok or bumps < 1:
			bad.append("conífera %d: base %.2f, altura %.2f, cartões ok %s, andares fora da reta %d" % [i, base, height, str(cards_ok), bumps])
	_check(bad.is_empty(), "coníferas: base de 2,0 a 3,2, altura de 6 a 9 e >= 2,4 x base, 7 a 9 cartões por andar, raios irregulares", str(bad))
	bad.clear()
	for tree_name: String in ["tree_broad_a", "tree_broad_e", "tree_small_a", "conifer_a", "conifer_f", "bush_a"]:
		var mesh := load(MESH_DIR + tree_name + ".res") as ArrayMesh
		var foliage_tris: int = 0
		var has_bark: bool = tree_name.begins_with("bush")
		for i in mesh.get_surface_count():
			var mat := mesh.surface_get_material(i) as ShaderMaterial
			var tris: int = (mesh.surface_get_arrays(i)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
			if mat.shader.resource_path.ends_with("scenery_foliage.gdshader"):
				foliage_tris += tris
			elif mat.resource_path.ends_with("/bark.tres"):
				has_bark = true
		if foliage_tris < 150 or not has_bark:
			bad.append("%s: %d triângulos de folhagem, tronco %s" % [tree_name, foliage_tris, str(has_bark)])
	_check(bad.is_empty(), "árvores são volume de cartões de folhagem (scenery_foliage) com tronco de casca pintada", str(bad))
	# Fase 2: folhagem com o atlas da A08, alpha scissor + alpha-to-coverage.
	var foliage_text: String = FileAccess.get_file_as_string("res://assets/materials/scenery_foliage.gdshader")
	_check(foliage_text.contains("alpha_to_coverage") and foliage_text.contains("ALPHA_SCISSOR_THRESHOLD")
			and foliage_text.contains("ALPHA_ANTIALIASING_EDGE"), "folhagem com alpha scissor + alpha-to-coverage")
	var atlas_bad: Array[String] = []
	for key: String in ["foliage_warm", "foliage_mid", "foliage_cool", "foliage_conifer"]:
		var mat := load(MATERIAL_DIR + key + ".tres") as ShaderMaterial
		var tex := mat.get_shader_parameter("atlas") as Texture2D
		if tex == null or not tex.resource_path.begins_with("res://assets/textures/scenery/foliage/"):
			atlas_bad.append(key)
	_check(atlas_bad.is_empty(), "folhagem usa os atlas pintados da A08", str(atlas_bad))


## Decalques: tamanho = PNG / 32 (decalques da A06, guardados no kit); no mapa, os decalques provisórios da
## arena (spec 012) são planos (sem relevo) e ficam no grupo Decals.
func _check_decals() -> void:
	var bad: Array[String] = []
	for decal_name: String in KitTables.DECAL_SIZES.keys():
		var size: Vector2 = KitTables.DECAL_SIZES[decal_name]
		var tex := load("res://assets/textures/decals/" + decal_name + ".png") as Texture2D
		if tex == null or not (is_equal_approx(float(tex.get_width()) / 32.0, size.x) and is_equal_approx(float(tex.get_height()) / 32.0, size.y)):
			bad.append(decal_name)
	_check(bad.is_empty(), "tamanho de cada decalque = PNG / 32", str(bad))
	var map_scene := (load("res://scenes/map.tscn") as PackedScene).instantiate()
	root.add_child(map_scene)
	await process_frame
	bad.clear()
	var found: Array[String] = []
	var decals: Node = map_scene.get_node_or_null("Decals")
	if decals != null:
		for child: Node in decals.get_children():
			var piece := child as KitPiece
			if piece == null:
				continue
			found.append(str(piece.scene_file_path.get_file().get_basename()))
			var mesh_node := piece.get_node("Mesh") as MeshInstance3D
			if mesh_node.get_aabb().size.y > 0.1:
				bad.append("%s com %.2f de altura" % [piece.name, mesh_node.get_aabb().size.y])
	_check(found.has("arena_ground") and found.has("arena_slabs") and bad.is_empty(),
			"decalques da arena (terra, círculo e lajes soltas) presentes e planos", str(found) + " " + str(bad))
	map_scene.queue_free()


## Fase 2 da 012: nenhuma peça usada no mapa amostra textura com Nearest (o kit_surface pixel art fica só para
## referência) e nenhum shader do cenário pede filtro Nearest.
func _check_no_pixel_scenery() -> void:
	var map_text: String = FileAccess.get_file_as_string("res://scenes/map.tscn")
	var bad: Array[String] = []
	for line: String in map_text.split("\n"):
		if not line.contains("path=\"res://scenes/kit/"):
			continue
		var kit_path: String = line.get_slice("path=\"", 1).get_slice("\"", 0)
		var piece := (load(kit_path) as PackedScene).instantiate() as KitPiece
		var mesh_node := piece.get_node_or_null("Mesh") as MeshInstance3D
		if mesh_node != null and mesh_node.mesh != null:
			for i in mesh_node.mesh.get_surface_count():
				var mat := mesh_node.mesh.surface_get_material(i) as ShaderMaterial
				if mat != null and mat.shader != null and mat.shader.code.contains("filter_nearest"):
					bad.append("%s[%s]" % [kit_path.get_file(), mat.resource_path.get_file()])
		piece.free()
	_check(bad.is_empty(), "nenhuma peça do mapa usa textura com filtro Nearest (cenário pintado)", str(bad))


func _descendants(node: Node) -> Array[Node]:
	var out: Array[Node] = []
	for child: Node in node.get_children():
		out.append(child)
		out.append_array(_descendants(child))
	return out
