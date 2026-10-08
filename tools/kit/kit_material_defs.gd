class_name KitMaterialDefs
extends RefCounted
## Tabela dos materiais do kit (spec 011). O construtor grava um .tres por linha em
## assets/materials/, todos com o shader kit_surface.gdshader. Trocar a textura na fase 3 =
## mudar o "tex" (ou o normal_texture direto no .tres), sem tocar nas malhas.
## Campos: tex (caminho em assets/textures/, sem .png), normal (usa <tex>_n.png), mode (0 UV da malha,
## 1 projeção, 2 faixa), world (projeção no mundo), scale (1 / tamanho da textura em unidades),
## v_top (y onde a face vertical começa), alpha (recorte, -1 = opaco), clamp, dither, axis (eixo da faixa).

const TEX_ROOT: String = "res://assets/textures/"
## Shader pixel art da 011 (só para referência: as peças do mapa usam os shaders pintados da 012).
const SHADER_PATH: String = "res://assets/materials/kit_surface.gdshader"
const SCENERY_TEX: String = "res://assets/textures/scenery/"
const STONE_SHADER_PATH: String = "res://assets/materials/scenery_stone.gdshader"
const OUT_DIR: String = "res://assets/materials/"
const SHADER_DIR: String = "res://assets/materials/"


static func all() -> Dictionary:
	var d: Dictionary = {}
	# Muro e degraus (pedra pintada da A08, spec 012 Fase 2): projeção no mundo, a textura corre contínua
	# de uma peça para a outra; v = 0 no topo da face (o musgo escorre de cima).
	var blocks: Vector2 = scenery_scale(512, 128)
	var top: Vector2 = scenery_scale(512, 128)
	var slabs: Vector2 = scenery_scale(512, 512)
	d["wall_high_face"] = _st("stone/wall_blocks", {"normal": true, "mode": 1, "scale": blocks, "v_top": 1.0, "dither": true})
	d["wall_high_face_out"] = _st("stone/wall_blocks_mossy", {"normal": true, "mode": 1, "scale": blocks, "v_top": 1.0, "dither": true})
	d["wall_low_face"] = _st("stone/wall_blocks", {"normal": true, "mode": 1, "scale": blocks, "v_top": 0.5})
	# Topo: wall_top em faixa (u ao longo do muro, v = distância da borda de fora, 1 tira = 1 unidade).
	d["wall_cap"] = _st("stone/wall_top", {"normal": true, "mode": 2, "scale": top, "dither": true, "moss": 0.2})
	d["wall_cap_z"] = _st("stone/wall_top", {"normal": true, "mode": 2, "scale": top, "dither": true, "axis": 1, "moss": 0.2})
	d["wall_cap_low"] = _st("stone/wall_top", {"normal": true, "mode": 2, "scale": top, "moss": 0.2})
	d["wall_crest"] = _st("stone/wall_top", {"normal": true, "mode": 2, "scale": top, "dither": true})
	d["wall_crest_z"] = _st("stone/wall_top", {"normal": true, "mode": 2, "scale": top, "dither": true, "axis": 1})
	# Quinas: topo projetado no mundo e as faces de fora com musgo (quina externa do muro alto).
	d["wall_crest_corner"] = _st("stone/wall_top", {"normal": true, "mode": 1, "scale": top, "dither": true})
	d["wall_cap_corner"] = _st("stone/wall_top", {"normal": true, "mode": 1, "scale": top})
	d["wall_quoin"] = _st("stone/wall_blocks_mossy", {"normal": true, "mode": 1, "scale": blocks, "v_top": 1.0, "dither": true})
	# Escadas: piso de lajes e espelho de blocos, no mundo.
	d["stair_tread_0"] = _st("stone/slabs", {"normal": true, "mode": 1, "scale": slabs, "moss": 0.4})
	d["stair_tread_1"] = _st("stone/slabs", {"normal": true, "mode": 1, "scale": slabs, "offset": Vector2(0.31, 0.57), "moss": 0.4})
	d["stair_riser_0"] = _st("stone/wall_blocks", {"normal": true, "mode": 1, "scale": blocks, "v_top": 0.5})
	d["stair_riser_1"] = _st("stone/wall_blocks", {"normal": true, "mode": 1, "scale": blocks, "v_top": 0.75})
	# Lajes dos patamares, da plataforma e do caminho (tom por laje pela cor do vértice).
	d["slab_painted"] = _st("stone/slabs", {"normal": true, "mode": 1, "scale": slabs, "shade": true, "moss": 0.3})
	# Casca pintada (256 x 512 = 4 x 8 unidades, v = 1 no chão): troncos, galhos, raízes de árvore e troncos caídos.
	var bark: Vector2 = scenery_scale(256, 512)
	d["bark"] = _st("foliage/bark", {"normal": true, "mode": 0, "scale": Vector2(bark.x, -bark.y), "offset": Vector2(0.0, 1.0),
			"dither": true, "margin": 3.0})
	d["bark_log"] = _st("foliage/bark", {"normal": true, "mode": 0, "scale": Vector2(bark.y, bark.x)})
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


## Pedra, lajes e casca pintadas (spec 012, Fase 2): shader scenery_stone, textura em scenery/.
static func _st(tex: String, extra: Dictionary) -> Dictionary:
	var entry: Dictionary = _d("scenery/" + tex, extra)
	entry["shader"] = STONE_SHADER_PATH
	return entry


## uv_scale de uma textura do cenário com w x h px: 1 / tamanho em unidades (64 px por unidade).
static func scenery_scale(width_px: int, height_px: int) -> Vector2:
	var tpu: float = float(WorldScale.SCENERY_TEXELS_PER_UNIT)
	return Vector2(tpu / float(width_px), tpu / float(height_px))


static func _d(tex: String, extra: Dictionary) -> Dictionary:
	var entry: Dictionary = extra.duplicate()
	entry["tex"] = tex
	return entry


## Monta o ShaderMaterial de uma linha da tabela (texturas carregadas do projeto).
static func make(entry: Dictionary) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load(str(entry.get("shader", SHADER_PATH))) as Shader
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
	if entry.has("offset"):
		mat.set_shader_parameter("uv_offset", entry["offset"])
	if entry.has("moss"):
		mat.set_shader_parameter("moss_amount", float(entry["moss"]))
	if bool(entry.get("shade", false)):
		mat.set_shader_parameter("shade_from_color", true)
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


# ================================================================ cenário pintado (spec 012)

## Materiais do cenário pintado (spec 012). Com a arte da A08, leva 1 (Fase 2): chão, folhagem, tufos,
## flores e decalques da arena. Ainda PROVISÓRIOS (sem textura, gradiente e ruído com seed fixa, paleta-alvo
## de docs/direcao-de-arte.md) até a leva 2: penhasco, fundo, rochas, ruínas, madeira, corda, ferro, nuvens,
## cascata, arco-íris e chama. Cada linha: shader (arquivo em assets/materials/, sem extensão) e params
## (uniforms; um caminho de PNG vira a textura).
static func scenery() -> Dictionary:
	var d: Dictionary = {}
	# Chão pintado (A08): grass_a/b misturadas pela blend_mask, UV de mundo (64 px por unidade).
	var grass_units: float = 512.0 / float(WorldScale.SCENERY_TEXELS_PER_UNIT)
	var ground: Dictionary = {"grass_a": SCENERY_TEX + "ground/grass_a.png", "grass_b": SCENERY_TEX + "ground/grass_b.png",
			"blend_mask": SCENERY_TEX + "ground/blend_mask.png", "tile_units": grass_units, "mask_units": 4.0 * grass_units}
	d["grass_painted"] = _s("scenery_ground", _with(ground, {"tint": Color(0.8, 0.8, 0.74), "patch_amount": 0.2}))
	d["grass_painted_inner"] = _s("scenery_ground", _with(ground, {"offset": Vector2(37.0, 11.0), "tint": Color(0.9, 0.86, 0.78),
			"patch_amount": 0.2}))
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
	d["stone_painted"] = _s("scenery_solid", {"color_low": Color("#8e7660"), "color_high": Color("#e0ccaa"),
			"color_patch": Color("#bda083"), "patch_scale": 0.9, "patch_amount": 0.35, "stroke_amount": 0.06,
			"top_color": Color("#87a23a"), "top_amount": 0.7, "top_sharpness": 4.0, "dither_on": true, "dither_margin": 3.0})
	d["wood_painted"] = _s("scenery_solid", {"color_low": Color("#4a3426"), "color_high": Color("#a88058"),
			"color_patch": Color("#7a5638"), "patch_scale": 1.4, "patch_amount": 0.4, "stroke_scale": 4.0, "stroke_amount": 0.1})
	d["root_painted"] = _s("scenery_solid", {"color_low": Color("#3a2a22"), "color_high": Color("#6e5038"),
			"color_patch": Color("#4a3426"), "patch_scale": 0.8, "patch_amount": 0.4, "stroke_amount": 0.1})
	d["rope_painted"] = _s("scenery_solid", {"color_low": Color("#8a6a48"), "color_high": Color("#c8aa7a"),
			"color_patch": Color("#a88058"), "patch_amount": 0.2})
	d["iron_painted"] = _s("scenery_solid", {"color_low": Color("#2a2624"), "color_high": Color("#4e4640"),
			"color_patch": Color("#3a3430"), "patch_amount": 0.2, "dither_on": true, "dither_margin": 3.0})
	# Folhagem pintada (A08): atlas de tufos 4x4 (três famílias) e andares de conífera 4x2.
	var leaf: Dictionary = {"atlas_cols": 4, "atlas_rows": 4, "atlas_size": Vector2(1024.0, 1024.0), "dither_on": true, "dither_margin": 3.0,
			"wrap_light": 0.35, "rim_amount": 0.5}
	d["foliage_warm"] = _s("scenery_foliage", _with(leaf, {"atlas": SCENERY_TEX + "foliage/leaf_clumps_warm.png",
			"shade_low": Color(0.4, 0.47, 0.56), "shade_high": Color(1.06, 1.04, 0.82), "core_color": Color("#26361a")}))
	d["foliage_mid"] = _s("scenery_foliage", _with(leaf, {"atlas": SCENERY_TEX + "foliage/leaf_clumps_mid.png",
			"shade_low": Color(0.38, 0.46, 0.58), "shade_high": Color(1.12, 1.1, 0.84), "core_color": Color("#1e3218")}))
	d["foliage_cool"] = _s("scenery_foliage", _with(leaf, {"atlas": SCENERY_TEX + "foliage/leaf_clumps_cool.png",
			"shade_low": Color(0.36, 0.44, 0.6), "shade_high": Color(1.05, 1.06, 0.9), "core_color": Color("#182c1e")}))
	d["foliage_conifer"] = _s("scenery_foliage", {"atlas": SCENERY_TEX + "foliage/conifer_tiers.png", "atlas_cols": 4, "atlas_rows": 2,
			"atlas_size": Vector2(1024.0, 512.0), "shade_low": Color(0.26, 0.36, 0.46), "shade_high": Color(0.86, 0.94, 0.84),
			"core_color": Color("#10200d"), "dither_on": true, "dither_margin": 3.0, "wrap_light": 0.35, "rim_amount": 0.5})
	d["cloud_puff"] = _s("cloud_puff", {})
	d["light_shaft"] = _s("light_shaft", {})
	d["water_fall"] = _s("water_fall", {})
	d["rainbow"] = _s("rainbow", {})
	d["flame"] = _s("flame", {})
	# Decalques da arena (A08): terra + centro do círculo (alfa suave) e pedras soltas (atlas 4x2).
	d["arena_ground"] = _s("arena_ground", {"dirt_tex": SCENERY_TEX + "decals/arena_dirt.png", "ring_tex": SCENERY_TEX + "decals/arena_ring.png"})
	d["arena_stones"] = _s("scenery_decal", {"atlas": SCENERY_TEX + "decals/arena_slabs.png"})
	# Tufos (grass_tufts 4x2: linha de cima baixos da arena, de baixo altos) e flores (flowers 4x4, 12 grupos).
	var tufts: Dictionary = {"atlas": SCENERY_TEX + "foliage/grass_tufts.png", "atlas_cols": 4, "atlas_rows": 2, "atlas_size": Vector2(512.0, 256.0)}
	d["tuft_grass_arena"] = _s("scenery_tuft", _with(tufts, {"first_cell": 0, "cell_count": 4}))
	d["tuft_grass"] = _s("scenery_tuft", _with(tufts, {"first_cell": 4, "cell_count": 4}))
	d["tuft_flower"] = _s("scenery_tuft", {"atlas": SCENERY_TEX + "foliage/flowers.png", "atlas_cols": 4, "atlas_rows": 4,
			"atlas_size": Vector2(256.0, 256.0), "first_cell": 0, "cell_count": 12})
	return d


## Junta dois dicionários de parâmetros (o segundo vence).
static func _with(base: Dictionary, extra: Dictionary) -> Dictionary:
	var out: Dictionary = base.duplicate()
	out.merge(extra, true)
	return out


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
		var value: Variant = params[key]
		# Caminho de PNG vira a textura importada.
		if value is String and str(value).ends_with(".png"):
			value = load(str(value)) as Texture2D
		mat.set_shader_parameter(key, value)
	return mat
