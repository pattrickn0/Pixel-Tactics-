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
const SHADER_DIR: String = "res://assets/materials/"


static func all() -> Dictionary:
	var d: Dictionary = {}
	# Muro e degraus (pedra): projeção no mundo, a textura corre contínua de uma peça para a outra.
	d["wall_high_face"] = _d("wall/wall_high_face", {"normal": true, "mode": 1, "scale": Vector2(1.0 / 8.0, 1.0 / 1.5), "v_top": 1.0, "dither": true})
	d["wall_low_face"] = _d("wall/wall_low_face", {"normal": true, "mode": 1, "scale": Vector2(1.0 / 8.0, 1.0 / 0.5), "v_top": 0.5})
	# Pedra com normal map fraco (normal_scale 0,5; a spec pede de 0,4 a 0,7).
	d["wall_cap"] = _d("wall/wall_cap", {"normal": true, "mode": 2, "scale": Vector2(1.0 / 8.0, 1.0 / 0.5), "dither": true})
	d["wall_cap_z"] = _d("wall/wall_cap", {"normal": true, "mode": 2, "scale": Vector2(1.0 / 8.0, 1.0 / 0.5), "dither": true, "axis": 1})
	d["wall_cap_low"] = _d("wall/wall_cap", {"normal": true, "mode": 2, "scale": Vector2(1.0 / 8.0, 1.0 / 0.5)})
	d["wall_crest"] = _d("wall/wall_crest", {"normal": true, "mode": 2, "scale": Vector2(1.0 / 8.0, 1.0), "dither": true})
	d["wall_crest_z"] = _d("wall/wall_crest", {"normal": true, "mode": 2, "scale": Vector2(1.0 / 8.0, 1.0), "dither": true, "axis": 1})
	# Quinas (UV da malha, girada sem espelhar; clamp para o bloco de amarração que invade o canto).
	d["wall_crest_corner"] = _d("wall/wall_crest_corner", {"normal": true, "mode": 0, "dither": true})
	d["wall_cap_corner"] = _d("wall/wall_cap_corner", {"normal": true, "mode": 0})
	d["wall_quoin"] = _d("wall/wall_quoin", {"normal": true, "mode": 0, "clamp": true, "dither": true})
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
	d["rock"] = _d("rock", {"normal": true, "mode": 1, "world": false, "tint": Color(0.7, 0.66, 0.62)})
	d["log_bark"] = _d("props/log_bark", {"normal": true, "mode": 0, "scale": Vector2(0.5, 1.0)})
	d["crate_side"] = _d("props/crate_side", {"normal": true, "mode": 0})
	d["crate_top"] = _d("props/crate_top", {"normal": true, "mode": 0})
	d["wood_pile_end"] = _d("props/wood_pile_end", {"mode": 0, "clamp": true})
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
	if entry.has("tint"):
		mat.set_shader_parameter("tint", entry["tint"])
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


# ================================================================ cenário pintado (provisório, spec 012 Fase 1)

## Materiais PROVISÓRIOS do cenário pintado (até a A08): sem textura, cor por gradiente e ruído com seed
## fixa no shader, com a paleta-alvo de docs/direcao-de-arte.md. Cada linha: shader (arquivo em
## assets/materials/, sem extensão) e params (uniforms). Trocar pela arte da A08 = mudar o shader/params.
static func scenery() -> Dictionary:
	var d: Dictionary = {}
	d["grass_painted"] = _s("scenery_grass", {"grass_dark": Color("#3a4818"), "grass_mid": Color("#56661f"),
			"grass_light": Color("#748228"), "grass_sun": Color("#929e36")})
	d["grass_painted_inner"] = _s("scenery_grass", {"offset": Vector2(37.0, 11.0), "grass_dark": Color("#4e5a1e"),
			"grass_mid": Color("#6e7c26"), "grass_light": Color("#8a9430"), "grass_sun": Color("#a8ac44")})
	d["cliff_painted"] = _s("scenery_solid", {"color_low": Color("#3e3640"), "color_high": Color("#7a5a3e"),
			"color_patch": Color("#6e5038"), "patch_scale": 0.22, "patch_amount": 0.45, "stroke_scale": 1.2, "stroke_amount": 0.1,
			"top_color": Color("#56661f"), "top_amount": 0.95, "top_sharpness": 6.0,
			"world_gradient": true, "world_gradient_range": Vector2(-9.0, 0.5)})
	d["under_painted"] = _s("scenery_solid", {"color_low": Color("#3a3440"), "color_high": Color("#6e5038"),
			"color_patch": Color("#4a3628"), "patch_scale": 0.12, "patch_amount": 0.4, "stroke_scale": 0.8, "stroke_amount": 0.1,
			"world_gradient": true, "world_gradient_range": Vector2(-22.0, -3.0)})
	d["rock_painted"] = _s("scenery_solid", {"color_low": Color("#4a3e3a"), "color_high": Color("#9a7656"),
			"color_patch": Color("#6e5038"), "patch_scale": 0.5, "patch_amount": 0.35, "stroke_amount": 0.08,
			"top_color": Color("#6f9a30"), "top_amount": 0.9, "top_sharpness": 5.0, "dither_on": true, "dither_margin": 1.0})
	d["slab_painted"] = _s("scenery_solid", {"color_low": Color("#a8925e"), "color_high": Color("#d6bb8d"),
			"color_patch": Color("#8e7c56"), "patch_scale": 1.1, "patch_amount": 0.4, "stroke_scale": 3.0, "stroke_amount": 0.07})
	d["stone_painted"] = _s("scenery_solid", {"color_low": Color("#8e7660"), "color_high": Color("#e0ccaa"),
			"color_patch": Color("#bda083"), "patch_scale": 0.9, "patch_amount": 0.35, "stroke_amount": 0.06,
			"top_color": Color("#87a23a"), "top_amount": 0.7, "top_sharpness": 4.0, "dither_on": true, "dither_margin": 3.0})
	d["wood_painted"] = _s("scenery_solid", {"color_low": Color("#4a3426"), "color_high": Color("#a88058"),
			"color_patch": Color("#7a5638"), "patch_scale": 1.4, "patch_amount": 0.4, "stroke_scale": 4.0, "stroke_amount": 0.1})
	d["bark_painted"] = _s("scenery_solid", {"color_low": Color("#3e2c20"), "color_high": Color("#7a5638"),
			"color_patch": Color("#5a4030"), "patch_scale": 1.2, "patch_amount": 0.4, "stroke_scale": 3.0, "stroke_amount": 0.12,
			"top_color": Color("#56702a"), "top_amount": 0.5, "dither_on": true, "dither_margin": 3.0})
	d["root_painted"] = _s("scenery_solid", {"color_low": Color("#3a2a22"), "color_high": Color("#6e5038"),
			"color_patch": Color("#4a3426"), "patch_scale": 0.8, "patch_amount": 0.4, "stroke_amount": 0.1})
	d["rope_painted"] = _s("scenery_solid", {"color_low": Color("#8a6a48"), "color_high": Color("#c8aa7a"),
			"color_patch": Color("#a88058"), "patch_amount": 0.2})
	d["iron_painted"] = _s("scenery_solid", {"color_low": Color("#2a2624"), "color_high": Color("#4e4640"),
			"color_patch": Color("#3a3430"), "patch_amount": 0.2, "dither_on": true, "dither_margin": 3.0})
	d["foliage_warm"] = _s("scenery_foliage", {"color_low": Color("#3a4a22"), "color_mid": Color("#6f8a34"),
			"color_high": Color("#c0c864"), "dither_on": true, "dither_margin": 3.0})
	d["foliage_mid"] = _s("scenery_foliage", {"color_low": Color("#2e4422"), "color_mid": Color("#587a2e"),
			"color_high": Color("#a0b450"), "dither_on": true, "dither_margin": 3.0})
	d["foliage_cool"] = _s("scenery_foliage", {"color_low": Color("#24402a"), "color_mid": Color("#4a6e3a"),
			"color_high": Color("#8aa660"), "dither_on": true, "dither_margin": 3.0})
	d["foliage_conifer"] = _s("scenery_foliage", {"color_low": Color("#1e3418"), "color_mid": Color("#3a5a24"),
			"color_high": Color("#8aa648"), "dither_on": true, "dither_margin": 3.0})
	d["cloud_puff"] = _s("cloud_puff", {})
	d["water_fall"] = _s("water_fall", {})
	d["rainbow"] = _s("rainbow", {})
	d["flame"] = _s("flame", {})
	d["arena_ground"] = _s("arena_ground", {})
	d["tuft_grass"] = _s("scenery_tuft", {})
	d["tuft_flower"] = _s("scenery_tuft", {"flower_mode": true})
	return d


static func _s(shader_name: String, params: Dictionary) -> Dictionary:
	return {"shader": shader_name, "params": params}


## Material provisório do cenário: ShaderMaterial com o shader e os uniforms da linha.
static func make_scenery(entry: Dictionary) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER_DIR + str(entry["shader"]) + ".gdshader") as Shader
	var params: Dictionary = entry["params"]
	var keys: Array = params.keys()
	keys.sort()
	for key: String in keys:
		mat.set_shader_parameter(key, params[key])
	return mat
