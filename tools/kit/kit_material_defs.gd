class_name KitMaterialDefs
extends RefCounted
## Tabela dos materiais do kit (spec 011). O construtor grava um .tres por linha em
## assets/materials/, todos com o shader kit_surface.gdshader. Trocar a textura na fase 3 =
## mudar o "tex" (ou o normal_texture direto no .tres), sem tocar nas malhas.
## Campos: tex (caminho em assets/textures/, sem .png), normal (usa <tex>_n.png), mode (0 UV da malha,
## 1 projeção, 2 faixa), world (projeção no mundo), scale (1 / tamanho da textura em unidades),
## v_top (y onde a face vertical começa), alpha (recorte, -1 = opaco), clamp, dither, axis (eixo da faixa).

const TEX_ROOT: String = "res://assets/textures/"
const SHADER_PATH: String = "res://assets/materials/kit_surface.gdshader"
const OUT_DIR: String = "res://assets/materials/"


static func all() -> Dictionary:
	var d: Dictionary = {}
	# Muro e degraus (pedra): projeção no mundo, a textura corre contínua de uma peça para a outra.
	d["wall_high_face"] = _d("wall/wall_high_face", {"normal": true, "mode": 1, "scale": Vector2(1.0 / 8.0, 1.0 / 1.5), "v_top": 1.5, "dither": true})
	d["wall_low_face"] = _d("wall/wall_low_face", {"normal": true, "mode": 1, "scale": Vector2(1.0 / 8.0, 1.0 / 0.5), "v_top": 0.5})
	d["wall_cap"] = _d("wall/wall_cap", {"mode": 2, "scale": Vector2(1.0 / 8.0, 1.0 / 0.5), "dither": true})
	d["wall_cap_z"] = _d("wall/wall_cap", {"mode": 2, "scale": Vector2(1.0 / 8.0, 1.0 / 0.5), "dither": true, "axis": 1})
	d["wall_cap_low"] = _d("wall/wall_cap", {"mode": 2, "scale": Vector2(1.0 / 8.0, 1.0 / 0.5)})
	d["wall_crest"] = _d("wall/wall_crest", {"mode": 2, "scale": Vector2(1.0 / 8.0, 1.0), "dither": true})
	d["wall_crest_corner"] = _d("wall/wall_crest_corner", {"mode": 0, "dither": true})
	d["wall_cap_corner"] = _d("wall/wall_cap_corner", {"mode": 0})
	d["moss_drape_0"] = _d("cards/moss_drape_0", {"mode": 2, "scale": Vector2(1.0 / 4.0, 1.0 / 0.375), "alpha": 0.5, "dither": true})
	d["moss_drape_1"] = _d("cards/moss_drape_1", {"mode": 2, "scale": Vector2(1.0 / 4.0, 1.0 / 0.375), "alpha": 0.5, "dither": true})
	d["moss_drape_0_z"] = _d("cards/moss_drape_0", {"mode": 2, "scale": Vector2(1.0 / 4.0, 1.0 / 0.375), "alpha": 0.5, "dither": true, "axis": 1})
	d["moss_drape_1_z"] = _d("cards/moss_drape_1", {"mode": 2, "scale": Vector2(1.0 / 4.0, 1.0 / 0.375), "alpha": 0.5, "dither": true, "axis": 1})
	d["stair_tread_0"] = _d("wall/stair_tread_0", {"normal": true, "mode": 0})
	d["stair_tread_1"] = _d("wall/stair_tread_1", {"normal": true, "mode": 0})
	d["stair_riser_0"] = _d("wall/stair_riser_0", {"normal": true, "mode": 0})
	d["stair_riser_1"] = _d("wall/stair_riser_1", {"normal": true, "mode": 0})
	# Chão: grama em UV de mundo (64 texels = 2 unidades).
	d["ground_grass_arena"] = _d("ground/ground_grass_arena", {"mode": 1, "scale": Vector2(0.5, 0.5)})
	d["ground_grass_forest"] = _d("ground/ground_grass_forest", {"mode": 1, "scale": Vector2(0.5, 0.5)})
	# Decalques (alfa recortado, UV 0..1 da malha).
	for decal_name: String in KitTables.DECAL_SIZES.keys():
		d[decal_name] = _d("decals/" + decal_name, {"mode": 0, "alpha": 0.5, "clamp": true})
	# Folhagem: projeção no espaço do objeto, miolo opaco e casca recortada.
	for family: String in ["green", "olive", "cool"]:
		d["leaf_mass_" + family] = _d("foliage/leaf_mass_" + family, {"mode": 1, "world": false, "scale": Vector2(0.5, 0.5), "dither": true, "margin": 3.0})
		d["leaf_shell_" + family] = _d("foliage/leaf_shell_" + family, {"mode": 1, "world": false, "scale": Vector2(0.5, 0.5), "alpha": 0.5, "dither": true, "margin": 3.0})
	d["leaf_shell_cool_flower"] = _d("foliage/leaf_shell_cool_flower", {"mode": 1, "world": false, "scale": Vector2(0.5, 0.5), "alpha": 0.5, "dither": true, "margin": 3.0})
	d["conifer_needles"] = _d("foliage/conifer_needles", {"mode": 0, "scale": Vector2(0.5, 1.0), "dither": true, "margin": 3.0})
	d["conifer_fringe"] = _d("foliage/conifer_fringe", {"mode": 0, "scale": Vector2(1.0 / 4.0, 1.0 / 0.5), "alpha": 0.5, "dither": true, "margin": 3.0})
	# Madeira, pedra e props.
	d["bark_0"] = _d("bark_0", {"normal": true, "mode": 0, "dither": true, "margin": 3.0})
	d["bark_1"] = _d("bark_1", {"normal": true, "mode": 0, "dither": true, "margin": 3.0})
	d["wood_end"] = _d("wood_end", {"mode": 0})
	d["rock"] = _d("rock", {"mode": 1, "world": false})
	d["log_bark"] = _d("props/log_bark", {"normal": true, "mode": 0, "scale": Vector2(0.5, 1.0)})
	d["crate_side"] = _d("props/crate_side", {"normal": true, "mode": 0})
	d["crate_top"] = _d("props/crate_top", {"normal": true, "mode": 0})
	d["wood_pile_end"] = _d("props/wood_pile_end", {"mode": 0})
	d["bench_floor_0"] = _d("bench_floor_0", {"normal": true, "mode": 0})
	# Cartões cruzados (capim, flores, cogumelos).
	for i in 4:
		d["card_flower_%d" % i] = _d("cards/flower_%d" % i, {"mode": 0, "alpha": 0.5, "clamp": true})
		d["card_mushroom_%d" % i] = _d("cards/mushroom_%d" % i, {"mode": 0, "alpha": 0.5, "clamp": true})
	for i in 2:
		d["card_tall_grass_%d" % i] = _d("cards/tall_grass_%d" % i, {"mode": 0, "alpha": 0.5, "clamp": true})
	d["card_grass_tuft_2"] = _d("cards/grass_tuft_2", {"mode": 0, "alpha": 0.5, "clamp": true})
	return d


static func _d(tex: String, extra: Dictionary) -> Dictionary:
	var entry: Dictionary = extra.duplicate()
	entry["tex"] = tex
	return entry


## Monta o ShaderMaterial de uma linha da tabela (texturas carregadas do projeto).
static func make(entry: Dictionary) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER_PATH) as Shader
	var tex: Texture2D = load(TEX_ROOT + str(entry["tex"]) + ".png") as Texture2D
	mat.set_shader_parameter("albedo_tex", tex)
	if bool(entry.get("normal", false)):
		var normal_path: String = TEX_ROOT + str(entry["tex"]) + "_n.png"
		var normal_tex: Texture2D = load(normal_path) as Texture2D
		if normal_tex != null:
			mat.set_shader_parameter("normal_tex", normal_tex)
			mat.set_shader_parameter("use_normal", true)
			mat.set_shader_parameter("normal_scale", 0.5)
	mat.set_shader_parameter("uv_mode", int(entry.get("mode", 0)))
	if entry.has("world"):
		mat.set_shader_parameter("world_space", bool(entry["world"]))
	if entry.has("axis"):
		mat.set_shader_parameter("strip_axis", int(entry["axis"]))
	if entry.has("scale"):
		mat.set_shader_parameter("uv_scale", entry["scale"])
	if entry.has("v_top"):
		mat.set_shader_parameter("v_top", float(entry["v_top"]))
	if entry.has("alpha"):
		mat.set_shader_parameter("alpha_cut", float(entry["alpha"]))
	if bool(entry.get("clamp", false)):
		mat.set_shader_parameter("clamp_uv", true)
	if bool(entry.get("dither", false)):
		mat.set_shader_parameter("dither_on", true)
		mat.set_shader_parameter("dither_margin", float(entry.get("margin", 0.0)))
	return mat
