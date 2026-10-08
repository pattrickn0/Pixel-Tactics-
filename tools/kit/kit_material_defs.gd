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
	# Fase 3 (arte A08 leva 2): raízes de superfície e caules (casca), pedra dos pilares e braseiros (blocos do
	# muro), ruínas (tambores de coluna), madeira das pontes, corda e ferro.
	d["bark_root"] = _st("foliage/bark", {"normal": true, "mode": 0, "scale": Vector2(bark.x, bark.y)})
	d["stone_painted"] = _st("stone/wall_blocks", {"normal": true, "mode": 1, "scale": blocks, "v_top": 1.0, "moss": 0.35,
			"dither": true, "margin": 3.0})
	d["ruin_stone"] = _st("props/ruin_stone", {"normal": true, "mode": 0, "scale": Vector2(1.0 / 16.0, 1.0 / 16.0), "moss": 0.55,
			"dither": true, "margin": 3.0})
	d["ruin_stone_box"] = _st("props/ruin_stone", {"normal": true, "mode": 1, "scale": Vector2(1.0 / 16.0, 1.0 / 16.0), "moss": 0.55,
			"dither": true, "margin": 3.0})
	d["wood_painted"] = _st("props/wood_planks", {"normal": true, "mode": 0, "scale": scenery_scale(256, 256)})
	# Corda: u dá a volta (1 / circunferência da corda de 0,035), v ao longo (8 voltas a cada 4 unidades).
	d["rope_painted"] = _st("props/rope", {"mode": 0, "scale": Vector2(1.0 / (TAU * 0.035), 0.25)})
	d["iron_painted"] = _st("props/iron", {"normal": true, "mode": 1, "scale": scenery_scale(128, 128), "dither": true, "margin": 3.0})
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
	# Penhasco, fundo e rochas (A08 leva 2, Fase 3): triplanar com island/cliff e island/under (8 x 8 unidades).
	var cliff: Dictionary = {"albedo_tex": SCENERY_TEX + "island/cliff.png", "normal_tex": SCENERY_TEX + "island/cliff_n.png",
			"tex_units": 512.0 / float(WorldScale.SCENERY_TEXELS_PER_UNIT)}
	var under: Dictionary = {"albedo_tex": SCENERY_TEX + "island/under.png", "normal_tex": SCENERY_TEX + "island/under_n.png",
			"tex_units": 512.0 / float(WorldScale.SCENERY_TEXELS_PER_UNIT)}
	d["cliff_painted"] = _s("scenery_cliff", _with(cliff, {"gradient_range": Vector2(-7.0, 0.5), "deep_amount": 0.55,
			"top_color": Color("#4a5e1c"), "top_amount": 0.9}))
	d["under_painted"] = _s("scenery_cliff", _with(under, {"gradient_range": Vector2(-20.0, -2.0), "deep_amount": 0.8}))
	d["rock_painted"] = _s("scenery_cliff", _with(cliff, {"local_gradient": true, "gradient_range": Vector2(-6.0, 0.5), "deep_amount": 0.75,
			"tint": Color(0.75, 0.72, 0.72), "air_strength": 0.0,
			"top_color": Color("#4f6a22"), "top_amount": 0.9, "dither_on": true, "dither_margin": 1.0}))
	# Raízes pendentes e cipós (A08 leva 2): cartões com uma faixa vertical do atlas (4 x 1), v = 0 preso em cima.
	var hang: Dictionary = {"atlas_cols": 4, "atlas_rows": 1, "atlas_size": Vector2(512.0, 1024.0), "wrap_light": 0.5, "rim_amount": 0.2,
			"under_amount": 0.0, "detail_soften": 0.2, "core_color": Color("#1e2a14")}
	d["roots_cards"] = _s("scenery_foliage", _with(hang, {"atlas": SCENERY_TEX + "island/roots_hang.png",
			"shade_low": Color(0.62, 0.6, 0.66), "shade_high": Color(1.0, 0.98, 0.95)}))
	d["vines_cards"] = _s("scenery_foliage", _with(hang, {"atlas": SCENERY_TEX + "island/vines_hang.png",
			"shade_low": Color(0.55, 0.62, 0.66), "shade_high": Color(1.0, 1.0, 0.92)}))
	# Folhagem pintada (A08): atlas de tufos 4x4 (três famílias) e andares de conífera 4x2.
	var leaf: Dictionary = {"atlas_cols": 4, "atlas_rows": 4, "atlas_size": Vector2(1024.0, 1024.0), "dither_on": true, "dither_margin": 3.0,
			"wrap_light": 0.35, "rim_amount": 1.0, "rim_color": Color(1.0, 0.8, 0.45), "air_strength": 0.07}
	d["foliage_warm"] = _s("scenery_foliage", _with(leaf, {"atlas": SCENERY_TEX + "foliage/leaf_clumps_warm.png",
			"shade_low": Color(0.3, 0.37, 0.48), "shade_high": Color(1.1, 1.0, 0.7), "core_color": Color("#26361a")}))
	d["foliage_mid"] = _s("scenery_foliage", _with(leaf, {"atlas": SCENERY_TEX + "foliage/leaf_clumps_mid.png",
			"shade_low": Color(0.28, 0.36, 0.5), "shade_high": Color(1.14, 1.04, 0.72), "core_color": Color("#1e3218")}))
	d["foliage_cool"] = _s("scenery_foliage", _with(leaf, {"atlas": SCENERY_TEX + "foliage/leaf_clumps_cool.png",
			"shade_low": Color(0.26, 0.34, 0.5), "shade_high": Color(1.04, 0.98, 0.8), "core_color": Color("#182c1e")}))
	d["foliage_conifer"] = _s("scenery_foliage", {"atlas": SCENERY_TEX + "foliage/conifer_tiers.png", "atlas_cols": 4, "atlas_rows": 2,
			"atlas_size": Vector2(1024.0, 512.0), "shade_low": Color(0.17, 0.24, 0.34), "shade_high": Color(0.62, 0.7, 0.62),
			"core_color": Color("#10200d"), "dither_on": true, "dither_margin": 3.0, "wrap_light": 0.35, "rim_amount": 0.5})
	# Céu, água e efeitos (A08 leva 2, Fase 3).
	d["cloud_puff"] = _s("cloud_puff", {"atlas": SCENERY_TEX + "sky/cloud_puffs.png", "atlas_cols": 2, "atlas_rows": 2})
	d["mist_puff"] = _s("cloud_puff", {"atlas": SCENERY_TEX + "fx/mist_puff.png", "atlas_cols": 1, "atlas_rows": 1, "energy": 1.3,
			"deep_amount": 0.0, "sun_amount": 0.1})
	var sea: Dictionary = _s("cloud_sea", {"sea": SCENERY_TEX + "sky/cloud_sea.png"})
	# Desenhado antes das outras transparências (fica embaixo de tudo).
	sea["priority"] = -20
	d["cloud_sea"] = sea
	d["water_fall"] = _s("water_fall", {"streaks": SCENERY_TEX + "water/fall_streaks.png", "foam": SCENERY_TEX + "water/fall_foam.png"})
	d["rainbow"] = _s("rainbow", {"bands": SCENERY_TEX + "fx/rainbow.png"})
	d["flame"] = _s("flame", {"flipbook": SCENERY_TEX + "fx/fire_flipbook.png"})
	d["firefly"] = _s("firefly", {})
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
	if entry.has("priority"):
		mat.render_priority = int(entry["priority"])
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
