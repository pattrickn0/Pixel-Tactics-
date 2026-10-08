extends SceneTree
## A06, parte 1: chão (grama 64x64) e decalques (terra da arena, manchas de grama, terra de mata, trilha).
## Tudo vem de tabelas escritas à mão: contornos (raios por ângulo, com o serrilhado escrito junto),
## posições de tracinhos, pedrinhas, ilhas, lajes. Sem RNG e sem ruído.
## Rodar da raiz do projeto:
##   "$G" --headless --path . --script tools/art/gen_a06_chao.gd

const K = preload("res://tools/art/a06_lib.gd")
const CV = K.CV
const P = K.P

var g_dark: int
var g_mid: int
var g_light: int
var g_pale: int
var f_dark: int
var f_mid: int
var f_light: int
var d_shade: int
var d_mid: int
var d_light: int
var d_dark2: int
var st_joint: int
var st_cross: int
var st0: int
var st1: int
var st2: int
var m_dark: int
var m_mid: int
var m_lite: int
var e_dark: int
var e_mid: int
var e_light: int
var e_dk: int
var b_leaf: int
var fl_white: int
var fl_yellow: int


func _initialize() -> void:
	g_dark = P.hx("#4E9343")
	g_mid = P.hx("#5B9C47")
	g_light = P.hx("#73A949")
	g_pale = P.hx("#98B654")
	f_dark = P.hx("#2C7036")
	f_mid = P.hx("#3D853C")
	f_light = P.hx("#539342")
	d_shade = P.hx("#8E7B4C")
	d_mid = P.hx("#A8955F")
	d_light = P.hx("#C0AE71")
	d_dark2 = P.hx("#D4C48C")
	st_joint = P.hx("#7A7A66")
	st_cross = P.hx("#5C6250")
	st0 = P.hx("#989680")
	st1 = P.hx("#B9B597")
	st2 = P.hx("#D3CCB4")
	m_dark = P.hx("#5E7C26")
	m_mid = P.hx("#789636")
	m_lite = P.hx("#789636")
	e_dk = P.hx("#3E3226")
	e_dark = P.hx("#5A4632")
	e_mid = P.hx("#7A6444")
	e_light = P.hx("#876547")
	b_leaf = P.hx("#876547")
	fl_white = P.hx("#F4F0E4")
	fl_yellow = P.hx("#F2D04A")

	var out: Dictionary = {}
	out["ground_grass_arena"] = _grass_arena()
	out["ground_grass_forest"] = _grass_forest()
	out["decal_arena_dirt"] = _dirt()
	out["decal_grass_light_0"] = _patch_light_0()
	out["decal_grass_light_1"] = _patch_light_1()
	out["decal_grass_light_2"] = _patch_light_2()
	out["decal_grass_dark_0"] = _patch_dark_0()
	out["decal_grass_dark_1"] = _patch_dark_1()
	out["decal_forest_soil_0"] = _soil_0()
	out["decal_forest_soil_1"] = _soil_1()
	var strip: Image = _end_strip()
	for v: int in 4:
		out["decal_trail_%d" % v] = _trail(v, strip)
	out["decal_trail_bend"] = _trail_bend(strip)
	_save_all(out)
	print("A06 CHAO: %d PNG gravados" % out.size())
	quit(0)


func _save_all(out: Dictionary) -> void:
	for key: String in out.keys():
		var sub: String = "ground/" if key.begins_with("ground_") else "decals/"
		var cv: RefCounted = out[key]
		K.save_cv(cv, sub + key, false, sub == "decals/")


# ---------------------------------------------------------------------------
# Grama 64x64 (seamless nos dois eixos)
# ---------------------------------------------------------------------------

# Tufos da grama da arena: [x, y, linhas separadas por "|"]. a = #73A949, b = #4E9343, c = #98B654
const ARENA_TUFTS: Array = [
	[5, 4, "a..a|aa.a|.bab|.b.."],
	[21, 9, "..a.|a.aa|bab.|.b.."],
	[38, 3, ".a.a|.aaa|b.b.|..b."],
	[55, 11, "a...|aa.a|.aab|..b."],
	[12, 19, "a.a.|.aa.|.bab|b..."],
	[30, 24, "..aa|a.a.|bab.|.b.."],
	[47, 20, "a.a.|aaa.|b.b.|.b.."],
	[58, 31, ".aa.|a.a.|b.b.|b..."],
	[4, 36, "a..a|.aa.|.bb.|..b."],
	[23, 41, "aa..|.a.a|b.ab|.b.."],
	[40, 35, ".a..|aa.a|b.ab|..b."],
	[53, 48, "a..a|a.aa|.bb.|b..."],
	[10, 53, "..a.|.aaa|ba.b|.b.."],
	[28, 57, "a.a.|.aaa|.b.b|b..."],
	[44, 56, "aa.a|.aa.|b.b.|..b."],
	[57, 54, "a.c.|aaa.|b.b.|.b.."],
]


func _grass_arena() -> RefCounted:
	var cv: RefCounted = CV.new(64, 64, true, true)
	cv.fill(g_mid, 0.0)
	var map: Dictionary = {"a": [g_light, 0.0], "b": [g_dark, 0.0], "c": [g_pale, 0.0]}
	for t: Array in ARENA_TUFTS:
		K.stamp(cv, String(t[2]).split("|"), int(t[0]), int(t[1]), map)
	return cv


# d = #2C7036, l = #539342, r = folha caída #876547
const FOREST_TUFTS: Array = [
	[3, 6, "l..l|ll.l|.dld|.d.."],
	[18, 2, "..l.|l.ll|dld.|.d.."],
	[33, 10, ".l.l|.lll|d.d.|..d."],
	[48, 4, "l...|ll.l|.ldd|..d."],
	[58, 14, "l.l.|.ll.|.dld|d..."],
	[9, 17, "..ll|l.l.|dld.|.d.."],
	[25, 22, "l.l.|lll.|d.d.|.d.."],
	[42, 27, ".ll.|l.l.|d.d.|d..."],
	[55, 33, "l..l|.ll.|.dd.|..d."],
	[2, 30, "ll..|.l.l|d.ld|.d.."],
	[16, 38, ".l..|ll.l|d.ld|..d."],
	[34, 43, "l..l|l.ll|.dd.|d..."],
	[50, 49, "..l.|.lll|dl.d|.d.."],
	[56, 56, "l.l.|.lll|.d.d|d..."],
	[8, 48, "ll.l|.ll.|d.d.|..d."],
	[24, 55, "l.l.|lll.|d.dd|.d.."],
	[40, 57, "..l.|l.l.|dlld|d..."],
	[28, 34, "l...|l.ll|.dd.|..d."],
	[12, 58, ".l.l|ll..|.dld|d..."],
	[57, 24, "l.ll|.l..|dd.d|.d.."],
]


func _grass_forest() -> RefCounted:
	var cv: RefCounted = CV.new(64, 64, true, true)
	cv.fill(f_mid, 0.0)
	var map: Dictionary = {"d": [f_dark, 0.0], "l": [f_light, 0.0], "r": [b_leaf, 0.0]}
	for t: Array in FOREST_TUFTS:
		K.stamp(cv, String(t[2]).split("|"), int(t[0]), int(t[1]), map)
	# duas folhas caídas
	K.stamp(cv, ["rr.", ".rr"], 21, 46, map)
	K.stamp(cv, [".rr", "rr."], 47, 40, map)
	return cv


# ---------------------------------------------------------------------------
# Terra da arena: 448 x 352 (14 x 11 unidades). Contorno, ilhas, dentes e ilhotas decalcados
# da clareira da referência (vértices x, y escritos à mão; a perspectiva foi corrigida a olho).
# ---------------------------------------------------------------------------

const DIRT_W: int = 448
const DIRT_H: int = 352
const DIRT_OUTLINE: Array = [
	24, 151, 36, 148, 45, 140, 60, 137, 79, 144, 92, 150, 106, 141,
	122, 144, 126, 135, 117, 126, 98, 122, 79, 115, 62, 116, 61, 104,
	79, 103, 98, 100, 106, 90, 123, 81, 131, 75, 149, 73, 166, 64,
	177, 51, 179, 40, 198, 37, 220, 32, 235, 27, 258, 29, 263, 40,
	285, 48, 292, 40, 312, 47, 314, 55, 315, 68, 340, 73, 351, 59,
	361, 36, 342, 32, 323, 30, 322, 14, 351, 13, 380, 17, 413, 16,
	424, 28, 421, 44, 402, 55, 391, 63, 380, 78, 382, 97, 390, 117,
	397, 130, 405, 147, 403, 166, 397, 178, 395, 190, 376, 200, 366, 216,
	356, 233, 340, 243, 319, 251, 304, 261, 302, 273, 312, 283, 315, 294,
	310, 307, 288, 320, 261, 323, 247, 322, 235, 312, 242, 299, 234, 288,
	216, 295, 204, 282, 190, 272, 176, 273, 176, 257, 152, 276, 125, 282,
	98, 285, 79, 283, 70, 272, 60, 260, 54, 251, 43, 263, 30, 260,
	19, 246, 19, 230, 32, 223, 51, 219, 62, 210, 62, 190, 54, 178,
	38, 174, 24, 171,
]
# Dentes colados na borda e ilhotas soltas (cada uma com seus vértices)
const DIRT_BITS: Array = [
	[421, 23, 429, 26, 428, 37, 422, 37],
	[257, 322, 266, 325, 270, 333, 262, 335, 258, 329],
	[16, 147, 25, 149, 25, 159, 18, 160],
	[413, 78, 420, 75, 422, 85, 416, 89],
	[176, 299, 186, 297, 188, 307, 181, 309],
	[326, 272, 335, 270, 336, 280, 329, 282],
]
# Ilhas de grama clara (buracos): vértices próprios, formas e tamanhos diferentes
const DIRT_ISLANDS: Array = [
	[102, 208, 111, 199, 125, 194, 137, 193, 145, 195, 141, 203, 134, 210, 132, 223, 126, 225, 122, 217, 117, 213, 106, 214],
	[317, 156, 323, 145, 334, 135, 348, 134, 361, 139, 356, 150, 348, 155, 342, 165, 334, 174, 327, 178, 323, 168],
	[151, 91, 159, 88, 163, 97, 158, 101, 152, 100],
	[216, 51, 225, 49, 234, 56, 228, 61, 219, 60],
	[187, 104, 198, 100, 204, 109, 196, 116, 189, 113],
	[351, 88, 361, 85, 368, 92, 362, 101, 353, 98],
	[286, 245, 296, 242, 306, 251, 304, 257, 293, 255, 287, 253],
]
# Onde o aro de grama clara engrossa: [cx, cy, raio, espessura]
const DIRT_ARO_ZONES: Array = [
	[60, 150, 50, 2], [100, 95, 60, 2], [240, 40, 70, 3], [380, 35, 50, 3], [410, 140, 50, 2], [330, 250, 70, 2],
	[230, 310, 60, 3], [80, 270, 60, 2], [300, 110, 40, 2], [125, 208, 40, 2], [334, 152, 40, 2],
]
# Tracinhos nas ilhas: [x, y, forma] (b = #5B9C47, p = #98B654)
const DIRT_ISLAND_TICKS: Array = [
	[112, 203, "bb"], [124, 207, "p|p"], [136, 200, "bb"], [120, 213, "b"],
	[326, 150, "bb"], [340, 147, "p|p"], [336, 160, "bb"], [346, 152, "b"],
	[156, 95, "b"], [224, 55, "p"], [196, 108, "bb"], [360, 92, "p"],
]
# Pedrinhas: [x, y, forma] (p = #A8955F, q = #D4C48C, s = #8E7B4C)
const DIRT_PEBBLES: Array = [
	[96, 150, "pp"], [140, 250, "q|q"], [182, 160, "pp"], [204, 120, "qq"], [250, 190, "p|p"],
	[286, 176, "qq"], [320, 112, "pp"], [330, 232, "q|q"], [372, 160, "pp"], [214, 280, "qq"],
	[120, 232, "p|p"], [188, 206, "qq"], [276, 250, "pp"], [304, 190, "q|q"], [156, 110, "pp"],
	[240, 130, "ps|.s"], [208, 168, "qq"], [262, 112, "p|p"], [338, 188, "pp"], [112, 160, "q|q"],
	[176, 270, "pp"], [304, 232, "qq"], [226, 70, "p|p"], [150, 130, "qq"], [350, 100, "pp"],
	[88, 238, "q|q"], [250, 262, "pp"], [194, 238, "qq"], [286, 214, "p|p"], [366, 224, "qq"],
]


func _dirt() -> RefCounted:
	var w: int = DIRT_W
	var h: int = DIRT_H
	var solid: PackedByteArray = K.poly_mask(w, h, DIRT_OUTLINE)
	for bit: Array in DIRT_BITS:
		solid = K.m_or(solid, K.poly_mask(w, h, bit))
	var holes: PackedByteArray = K.new_mask(w, h)
	for isl: Array in DIRT_ISLANDS:
		holes = K.m_or(holes, K.poly_mask(w, h, isl))
	solid = K.m_or(solid, holes)
	var dirt: PackedByteArray = K.m_sub(solid, holes)
	var dist: PackedInt32Array = K.dist4(dirt, w, h, 3)
	var cv: RefCounted = CV.new(w, h, false, false)
	for y: int in h:
		for x: int in w:
			var i: int = y * w + x
			if dirt[i] != 0:
				cv.put(x, y, d_light, 0.0)
				continue
			var t: int = 1
			for z: Array in DIRT_ARO_ZONES:
				var dx: float = float(x - int(z[0]))
				var dy: float = float(y - int(z[1]))
				if dx * dx + dy * dy <= float(int(z[2]) * int(z[2])):
					t = maxi(t, int(z[3]))
			if dist[i] <= t or holes[i] != 0:
				cv.put(x, y, g_light, 0.0)
	K.break_edges(cv, 5) # limpeza final de retas que sobraram
	var tmap: Dictionary = {"b": [g_mid, 0.0], "p": [g_pale, 0.0]}
	for t2: Array in DIRT_ISLAND_TICKS:
		_stamp_if(cv, String(t2[2]).split("|"), int(t2[0]), int(t2[1]), tmap, g_light, 2)
	var pmap: Dictionary = {"p": [d_mid, 0.0], "q": [d_dark2, 0.0], "s": [d_shade, 0.0]}
	for t3: Array in DIRT_PEBBLES:
		_stamp_if(cv, String(t3[2]).split("|"), int(t3[0]), int(t3[1]), pmap, d_light)
	return cv


## Carimba só onde o pixel atual já é a cor "on" (assim o detalhe nunca invade o aro nem a borda).
func _stamp_if(cv: RefCounted, rows: Array, ox: int, oy: int, map: Dictionary, on: int, margin: int = 0) -> void:
	for j: int in rows.size():
		var row: String = rows[j]
		for i: int in row.length():
			for dy: int in range(-margin, margin + 1):
				for dx: int in range(-margin, margin + 1):
					if cv.get_c(ox + i + dx, oy + j + dy) != on:
						return
	K.stamp(cv, rows, ox, oy, map)


# ---------------------------------------------------------------------------
# Manchas de grama: contornos de vértices escritos à mão (reentrâncias e um lado mais comprido)
# ---------------------------------------------------------------------------

# clara: base #73A949, tracinhos #98B654 (p) e #5B9C47 (m)
const LIGHT0: Array = [
	6, 52, 10, 40, 20, 34, 30, 30, 42, 32, 50, 24, 62, 16, 78, 14, 92, 20, 100, 16, 116, 18, 128, 26, 140, 30,
	152, 40, 154, 52, 146, 62, 134, 66, 124, 76, 108, 80, 96, 74, 84, 82, 66, 84, 50, 78, 40, 70, 26, 72, 14, 66,
]
const LIGHT0_TICKS: Array = [
	[34, 46, "pp"], [60, 30, "m|m"], [92, 36, "pp"], [118, 38, "m|m"], [46, 62, "m|m"],
	[78, 54, "pp"], [104, 62, "m|m"], [128, 48, "pp"], [70, 40, "m|m"],
]
const LIGHT1: Array = [
	30, 12, 46, 8, 62, 14, 76, 10, 92, 18, 104, 30, 100, 42, 114, 52, 118, 68, 108, 80, 112, 94, 96, 108,
	78, 114, 64, 108, 50, 116, 34, 108, 24, 92, 10, 84, 8, 66, 18, 52, 14, 36, 22, 22,
]
const LIGHT1_TICKS: Array = [
	[40, 36, "pp"], [70, 28, "m|m"], [84, 58, "pp"], [48, 76, "m|m"], [74, 92, "pp"],
	[58, 52, "m|m"], [32, 60, "pp"], [90, 76, "m|m"],
]
const LIGHT2: Array = [
	8, 40, 14, 28, 26, 22, 34, 12, 48, 10, 58, 16, 72, 14, 86, 22, 88, 34, 80, 44, 70, 48, 62, 56, 48, 54,
	36, 58, 24, 54, 14, 50,
]
const LIGHT2_TICKS: Array = [
	[28, 32, "pp"], [52, 22, "m|m"], [64, 36, "pp"], [38, 44, "m|m"], [74, 28, "pp"],
]
# escura: base #4E9343, tracinhos #5B9C47 (m)
const DARK0: Array = [
	8, 44, 16, 30, 30, 24, 46, 26, 60, 14, 78, 12, 94, 20, 108, 18, 120, 30, 118, 46, 110, 58, 116, 72, 100, 80,
	88, 74, 78, 84, 62, 82, 54, 70, 40, 76, 26, 70, 16, 60,
]
const DARK0_TICKS: Array = [
	[30, 40, "mm"], [58, 30, "m|m"], [88, 40, "mm"], [44, 58, "m|m"], [74, 62, "mm"], [100, 44, "m|m"],
]
const DARK1: Array = [
	14, 30, 26, 20, 40, 22, 52, 10, 68, 14, 80, 28, 84, 44, 78, 58, 84, 72, 70, 84, 56, 80, 46, 88, 32, 82,
	26, 68, 12, 60, 8, 44,
]
const DARK1_TICKS: Array = [
	[34, 40, "mm"], [54, 30, "m|m"], [58, 58, "mm"], [40, 64, "m|m"], [66, 46, "mm"],
]


func _patch(w: int, h: int, pts: Array, base: int, ticks: Array, tmap: Dictionary) -> RefCounted:
	var m: PackedByteArray = K.poly_mask(w, h, pts)
	var cv: RefCounted = CV.new(w, h, false, false)
	K.paint_mask(cv, m, base, 0.0)
	K.break_edges(cv, 5) # limpeza final de retas que sobraram
	for t: Array in ticks:
		_stamp_if(cv, String(t[2]).split("|"), int(t[0]), int(t[1]), tmap, base)
	return cv


func _patch_light_0() -> RefCounted:
	return _patch(160, 96, LIGHT0, g_light, LIGHT0_TICKS, {"p": [g_pale, 0.0], "m": [g_mid, 0.0]})


func _patch_light_1() -> RefCounted:
	return _patch(128, 128, LIGHT1, g_light, LIGHT1_TICKS, {"p": [g_pale, 0.0], "m": [g_mid, 0.0]})


func _patch_light_2() -> RefCounted:
	return _patch(96, 64, LIGHT2, g_light, LIGHT2_TICKS, {"p": [g_pale, 0.0], "m": [g_mid, 0.0]})


func _patch_dark_0() -> RefCounted:
	return _patch(128, 96, DARK0, g_dark, DARK0_TICKS, {"m": [g_mid, 0.0]})


func _patch_dark_1() -> RefCounted:
	return _patch(96, 96, DARK1, g_dark, DARK1_TICKS, {"m": [g_mid, 0.0]})


# ---------------------------------------------------------------------------
# Terra de mata (terra escura, raízes, folhas, borda de grama de fora)
# ---------------------------------------------------------------------------

const SOIL0_R: Array = [
	58, 55, 59, 54, 57, 52, 55, 50, 53, 56, 52, 55, 51, 56, 53, 58, 55, 59, 56, 52,
	55, 50, 54, 49, 53, 57, 54, 58, 55, 51, 55, 52, 57, 54, 58, 55,
]
const SOIL1_R: Array = [
	38, 41, 37, 40, 36, 39, 35, 38, 41, 37, 40, 36, 39, 42, 38, 41, 37, 40, 36, 39,
	35, 38, 41, 37, 40, 36, 39, 42, 38, 41, 37, 40, 36, 39, 35, 38,
]
# Pontos claros (#7A6444) e escuros (#3E3226): [x, y, forma] (l = claro, d = escuro)
const SOIL0_SPECKS: Array = [
	[30, 30, "ll"], [48, 24, "l|l"], [70, 28, "lll"], [92, 34, "ll"], [38, 46, "d|d"], [60, 44, "dd"],
	[84, 50, "l|l"], [104, 44, "ll"], [44, 62, "ll"], [72, 66, "dd"], [96, 62, "l|l"], [56, 76, "ll"],
	[26, 52, "dd"], [112, 54, "l|l"], [66, 20, "dd"], [82, 72, "d|d"],
]
const SOIL1_SPECKS: Array = [
	[30, 30, "ll"], [56, 26, "l|l"], [40, 48, "dd"], [62, 52, "ll"], [34, 70, "l|l"], [58, 76, "dd"],
	[44, 92, "ll"], [64, 98, "d|d"], [30, 104, "ll"], [52, 40, "dd"], [66, 78, "l|l"], [38, 60, "ll"],
]
# Raízes: [cor (r = #876547, d = #3E3226), x0, y0, x1, y1, ...] (polilinha)
const SOIL0_ROOTS: Array = [
	["r", 20, 44, 34, 50, 48, 46, 62, 52, 76, 48, 92, 54, 108, 50],
	["r", 48, 46, 56, 34, 60, 22],
	["r", 62, 52, 66, 64, 62, 74],
	["r", 92, 54, 98, 66, 108, 70],
	["d", 22, 47, 36, 53, 50, 49, 64, 55],
]
const SOIL1_ROOTS: Array = [
	["r", 48, 24, 46, 42, 50, 60, 46, 78, 50, 96, 48, 108],
	["r", 46, 42, 34, 48, 26, 58],
	["r", 50, 60, 62, 66, 70, 76],
	["r", 46, 78, 36, 86, 30, 96],
	["d", 50, 26, 48, 44, 52, 62, 48, 80],
]
# Folhas caídas: [x, y, forma]
const SOIL0_LEAVES: Array = [[40, 36, "rr|.rr"], [78, 38, ".rr|rr."], [100, 56, "rr|.rr"], [52, 68, "rrr"], [86, 62, ".rr|rr."]]
const SOIL1_LEAVES: Array = [[36, 38, "rr|.rr"], [58, 44, ".rr|rr."], [38, 80, "rrr"], [56, 90, "rr|.rr"], [44, 106, ".rr|rr."]]
# Onde a borda de grama engrossa para 2 px: [cx, cy, raio]
const SOIL0_THICK: Array = [[30, 60, 20], [100, 30, 22], [70, 82, 18]]
const SOIL1_THICK: Array = [[30, 30, 22], [66, 100, 24], [36, 80, 16]]


func _soil(w: int, h: int, cx: float, cy: float, sy: float, radii: Array, specks: Array, roots: Array, leaves: Array, thick: Array) -> RefCounted:
	var m: PackedByteArray = K.poly_mask(w, h, K.polar_pts(cx, cy, sy, 10.0, radii))
	var outside: PackedByteArray = PackedByteArray()
	outside.resize(w * h)
	for i: int in w * h:
		outside[i] = 1 if m[i] == 0 else 0
	var din: PackedInt32Array = K.dist4(outside, w, h, 2)
	var cv: RefCounted = CV.new(w, h, false, false)
	K.paint_mask(cv, m, e_dark, 0.0)
	var smap: Dictionary = {"l": [e_mid, 0.0], "d": [e_dk, 0.0]}
	for s: Array in specks:
		_stamp_if(cv, String(s[2]).split("|"), int(s[0]), int(s[1]), smap, e_dark)
	for r: Array in roots:
		var col: int = e_light if r[0] == "r" else e_dk
		for k: int in range(1, r.size() - 2, 2):
			for p: Vector2i in CV.line_pts(int(r[k]), int(r[k + 1]), int(r[k + 2]), int(r[k + 3])):
				if cv.get_c(p.x, p.y) >= 0:
					cv.put(p.x, p.y, col, 0.0)
	var lmap: Dictionary = {"r": [e_light, 0.0]}
	for l: Array in leaves:
		_stamp_if(cv, String(l[2]).split("|"), int(l[0]), int(l[1]), lmap, e_dark)
	# borda de grama de fora por dentro, 1 px (2 px nas zonas marcadas)
	for y: int in h:
		for x: int in w:
			var i: int = y * w + x
			if m[i] == 0:
				continue
			var t: int = 1
			for z: Array in thick:
				var dx: float = float(x - int(z[0]))
				var dy: float = float(y - int(z[1]))
				if dx * dx + dy * dy <= float(int(z[2]) * int(z[2])):
					t = 2
			if din[i] <= t:
				cv.put(x, y, f_dark, 0.0)
	K.break_edges(cv, 5)
	return cv


func _soil_0() -> RefCounted:
	return _soil(128, 96, 64.0, 48.0, 0.6, SOIL0_R, SOIL0_SPECKS, SOIL0_ROOTS, SOIL0_LEAVES, SOIL0_THICK)


func _soil_1() -> RefCounted:
	return _soil(96, 128, 48.0, 64.0, 1.4, SOIL1_R, SOIL1_SPECKS, SOIL1_ROOTS, SOIL1_LEAVES, SOIL1_THICK)


# ---------------------------------------------------------------------------
# Trilha de lajes (96 x 96). Cada laje é um polígono de 4 a 7 vértices escritos à mão.
# As lajes de dentro vêm de uma malha de linhas de vértices (as lajes de uma fiada dividem os
# vértices das linhas de cima e de baixo); as lajes das pontas são polígonos fixos, iguais nas peças.
# ---------------------------------------------------------------------------

const TR: int = 96
# Lajes das pontas: desenhadas em x e em x + 96 (a laje atravessa a emenda). Tons: 0 = #989680, 1 = #B9B597, 2 = #D3CCB4
const END_POLYS: Array = [
	[-13, 4, 10, 4, 11, 13, 9, 21, -12, 21, -14, 12],
	[-12, 22, 10, 22, 9, 28, 11, 34, -13, 34, -11, 28],
	[-13, 35, 9, 35, 11, 42, 10, 48, -12, 48, -14, 41],
	[-12, 49, 11, 49, 9, 55, 10, 61, -13, 61, -11, 55],
	[-13, 62, 10, 62, 11, 68, 9, 74, -12, 74, -14, 68],
	[-12, 75, 9, 75, 11, 83, 10, 91, -13, 91, -11, 83],
]
const END_TONES: Array = [1, 0, 1, 2, 1, 0]
# Malha de cada variante: [7 linhas de 6 vértices (x, y), 6 fiadas de pares (vértice de cima, vértice de baixo)
# das arestas verticais, tons por laje]
const TRAIL_MESH: Array = [
	[
		[[12, 7, 28, 5, 43, 8, 57, 6, 70, 7, 82, 5], [12, 21, 30, 19, 42, 22, 56, 20, 69, 18, 82, 21],
			[12, 34, 26, 32, 44, 34, 55, 32, 71, 35, 82, 33], [12, 46, 31, 48, 41, 46, 58, 48, 68, 46, 82, 47],
			[12, 61, 27, 59, 46, 61, 56, 59, 73, 60, 82, 62], [12, 74, 32, 72, 43, 74, 54, 73, 70, 75, 82, 73],
			[12, 91, 26, 89, 46, 91, 60, 90, 72, 89, 82, 91]],
		[[0, 0, 1, 1, 3, 2, 5, 5], [0, 0, 2, 1, 4, 3, 5, 5], [0, 0, 1, 2, 3, 3, 5, 5], [0, 0, 2, 1, 3, 3, 4, 4, 5, 5],
			[0, 0, 1, 1, 3, 2, 5, 5], [0, 0, 2, 2, 4, 3, 5, 5]],
		[[1, 0, 1], [2, 1, 0], [1, 1, 2], [0, 1, 1, 0], [1, 2, 1], [1, 0, 1]],
	],
	[
		[[12, 6, 25, 8, 41, 5, 55, 7, 68, 6, 82, 8], [12, 19, 27, 21, 40, 18, 58, 20, 66, 22, 82, 19],
			[12, 33, 29, 31, 43, 34, 52, 32, 70, 33, 82, 35], [12, 47, 24, 49, 45, 46, 57, 48, 69, 47, 82, 45],
			[12, 60, 31, 62, 42, 59, 55, 61, 71, 60, 82, 62], [12, 75, 26, 73, 44, 75, 58, 74, 67, 72, 82, 75],
			[12, 90, 30, 92, 41, 90, 56, 91, 70, 92, 82, 90]],
		[[0, 0, 2, 1, 3, 3, 5, 5], [0, 0, 1, 1, 3, 2, 5, 5], [0, 0, 2, 2, 4, 3, 5, 5], [0, 0, 1, 1, 2, 3, 4, 4, 5, 5],
			[0, 0, 2, 1, 3, 3, 5, 5], [0, 0, 1, 2, 3, 3, 5, 5]],
		[[1, 2, 1], [0, 1, 1], [1, 0, 1], [1, 1, 0, 1], [0, 1, 1], [1, 0, 2]],
	],
	[
		[[12, 8, 30, 6, 40, 7, 59, 5, 72, 8, 82, 6], [12, 22, 26, 20, 43, 21, 54, 19, 70, 22, 82, 20],
			[12, 36, 31, 34, 41, 35, 57, 33, 68, 35, 82, 34], [12, 48, 28, 50, 42, 47, 56, 49, 73, 48, 82, 50],
			[12, 62, 25, 60, 45, 61, 59, 63, 69, 60, 82, 61], [12, 76, 33, 74, 44, 76, 53, 74, 71, 75, 82, 77],
			[12, 89, 28, 91, 47, 90, 58, 92, 74, 90, 82, 92]],
		[[0, 0, 1, 1, 3, 3, 5, 5], [0, 0, 2, 2, 3, 3, 5, 5], [0, 0, 1, 1, 2, 3, 4, 4, 5, 5], [0, 0, 2, 1, 4, 3, 5, 5],
			[0, 0, 1, 1, 3, 3, 4, 4, 5, 5], [0, 0, 2, 1, 3, 3, 5, 5]],
		[[0, 1, 1], [1, 1, 0], [1, 2, 0, 1], [1, 0, 1], [0, 1, 1, 1], [1, 1, 0]],
	],
	[
		[[12, 7, 27, 9, 45, 5, 56, 8, 71, 6, 82, 7], [12, 20, 29, 18, 41, 21, 57, 19, 68, 21, 82, 18],
			[12, 34, 28, 35, 46, 32, 54, 34, 72, 33, 82, 36], [12, 47, 32, 45, 40, 48, 59, 47, 67, 49, 82, 46],
			[12, 59, 26, 61, 44, 60, 55, 62, 74, 59, 82, 61], [12, 73, 30, 75, 45, 72, 57, 74, 69, 73, 82, 75],
			[12, 91, 27, 90, 43, 92, 58, 89, 73, 91, 82, 90]],
		[[0, 0, 2, 1, 3, 3, 5, 5], [0, 0, 1, 1, 3, 2, 4, 4, 5, 5], [0, 0, 2, 2, 3, 3, 5, 5],
			[0, 0, 1, 1, 2, 2, 4, 3, 5, 5], [0, 0, 2, 1, 4, 3, 5, 5], [0, 0, 1, 1, 3, 2, 5, 5]],
		[[1, 1, 0], [0, 1, 1, 2], [1, 0, 1], [1, 1, 0, 1], [2, 1, 1], [1, 0, 1]],
	],
]
# Contorno de cima e de baixo (fronteira em y, de x = 0 a 96). Pontas fixas: y = 12 e y = 84.
const TRAIL_TOP: Array = [
	[0, 12, 3, 12, 9, 10, 14, 13, 21, 9, 27, 12, 33, 14, 39, 11, 46, 9, 52, 12, 58, 14, 64, 10, 70, 8, 76, 11, 82, 13, 88, 11, 93, 12, 96, 12],
	[0, 12, 3, 12, 8, 13, 15, 10, 20, 8, 26, 11, 32, 9, 38, 12, 45, 14, 51, 11, 57, 9, 63, 12, 69, 14, 75, 10, 81, 8, 87, 11, 93, 12, 96, 12],
	[0, 12, 3, 12, 10, 14, 16, 11, 22, 13, 28, 9, 34, 12, 41, 10, 47, 13, 53, 14, 60, 11, 66, 9, 72, 12, 78, 14, 84, 10, 89, 12, 93, 12, 96, 12],
	[0, 12, 3, 12, 7, 10, 13, 8, 19, 11, 25, 13, 31, 10, 37, 8, 44, 11, 50, 14, 56, 12, 62, 9, 68, 11, 74, 13, 80, 14, 86, 10, 93, 12, 96, 12],
]
const TRAIL_BOT: Array = [
	[0, 84, 3, 84, 9, 86, 15, 83, 22, 87, 28, 84, 34, 81, 40, 85, 47, 88, 53, 84, 59, 81, 65, 85, 71, 87, 77, 83, 83, 86, 88, 82, 93, 84, 96, 84],
	[0, 84, 3, 84, 8, 81, 14, 85, 21, 88, 27, 85, 33, 87, 39, 83, 46, 81, 52, 85, 58, 88, 64, 84, 70, 81, 76, 85, 82, 87, 88, 84, 93, 84, 96, 84],
	[0, 84, 3, 84, 11, 87, 17, 84, 23, 81, 29, 85, 35, 88, 42, 85, 48, 82, 54, 85, 61, 87, 67, 84, 73, 81, 79, 84, 85, 87, 90, 85, 93, 84, 96, 84],
	[0, 84, 3, 84, 8, 86, 14, 88, 20, 85, 26, 82, 32, 85, 38, 87, 45, 84, 51, 81, 57, 84, 63, 87, 69, 85, 75, 82, 81, 85, 87, 83, 93, 84, 96, 84],
]
# Espessura do aro (2 px) por trecho em x: [x0, x1] (fora deles, 1 px). As pontas (0-2 e 93-95) são sempre 2.
const AR_TOP_V: Array = [
	[[0, 2], [93, 95], [20, 27], [58, 63], [76, 80]],
	[[0, 2], [93, 95], [14, 19], [45, 50], [82, 86]],
	[[0, 2], [93, 95], [30, 36], [61, 66], [72, 76]],
	[[0, 2], [93, 95], [10, 16], [40, 46], [66, 72]],
]
const AR_BOT_V: Array = [
	[[0, 2], [93, 95], [10, 15], [44, 52], [70, 75]],
	[[0, 2], [93, 95], [24, 30], [54, 60], [78, 84]],
	[[0, 2], [93, 95], [16, 22], [48, 54], [86, 90]],
	[[0, 2], [93, 95], [26, 32], [56, 62], [74, 80]],
]
# Musgo nas juntas: [x, y, w, h] (retângulos; só afeta pixels de junta e vizinhos de junta)
const TRAIL_MOSS: Array = [
	[[24, 30, 12, 4], [64, 48, 8, 10], [44, 66, 14, 4], [52, 20, 5, 10]],
	[[28, 44, 4, 12], [50, 36, 14, 4], [66, 62, 10, 5], [34, 22, 8, 5]],
	[[22, 52, 12, 4], [48, 22, 4, 14], [70, 44, 12, 4], [56, 70, 10, 4]],
	[[30, 26, 4, 10], [52, 46, 14, 4], [68, 64, 4, 12], [40, 70, 10, 4]],
]


func _in_ranges(x: int, ranges: Array) -> bool:
	for r: Array in ranges:
		if x >= int(r[0]) and x <= int(r[1]):
			return true
	return false


## Lajes de uma malha: devolve [[vértices, tom], ...].
func _mesh_cells(mesh: Array) -> Array:
	var polys: Array = mesh[0]
	var rows: Array = mesh[1]
	var tones: Array = mesh[2]
	var cells: Array = []
	for r: int in 6:
		var top: Array = polys[r]
		var bot: Array = polys[r + 1]
		var e: Array = rows[r]
		var n: int = e.size() / 2
		for i: int in n - 1:
			var a0: int = e[i * 2]
			var c0: int = e[i * 2 + 1]
			var a1: int = e[(i + 1) * 2]
			var c1: int = e[(i + 1) * 2 + 1]
			var pts: Array = []
			for k: int in range(a0, a1 + 1):
				pts.append(top[k * 2])
				pts.append(top[k * 2 + 1])
			for k2: int in range(c1, c0 - 1, -1):
				pts.append(bot[k2 * 2])
				pts.append(bot[k2 * 2 + 1])
			cells.append([pts, int(tones[r][i])])
	return cells


func _shift(pts: Array, dx: float) -> Array:
	var out: Array = []
	for i: int in pts.size() / 2:
		out.append(float(pts[i * 2]) + dx)
		out.append(float(pts[i * 2 + 1]))
	return out


## Gira 90 graus horário: (fx, fy) -> (96 - fy, fx).
func _rot_cw(pts: Array) -> Array:
	var out: Array = []
	for i: int in pts.size() / 2:
		out.append(96.0 - float(pts[i * 2 + 1]))
		out.append(float(pts[i * 2]))
	return out


## Rótulos das lajes: jobs = [vértices, id, região (máscara ou null)], pintados na ordem.
func _label_map(jobs: Array) -> PackedInt32Array:
	var lab: PackedInt32Array = PackedInt32Array()
	lab.resize(TR * TR)
	lab.fill(-1)
	for j: Array in jobs:
		var m: PackedByteArray = K.poly_mask(TR, TR, j[0])
		var reg: Variant = j[2]
		for i: int in TR * TR:
			if m[i] != 0 and (reg == null or (reg as PackedByteArray)[i] != 0):
				lab[i] = int(j[1])
	return lab


## Pinta lajes, juntas (1 px entre lajes e o vão que sobra), aresta clara de cima e musgo.
func _paint_labels(cv: RefCounted, mask: PackedByteArray, ring: PackedByteArray, lab: PackedInt32Array, tone_by_id: Dictionary, tor_x: bool, moss: Array) -> void:
	var w: int = TR
	var h: int = TR
	var tones: Array[int] = [st0, st1, st2]
	var joint: PackedByteArray = K.new_mask(w, h)
	for y: int in h:
		for x: int in w:
			var i: int = y * w + x
			if mask[i] == 0 or ring[i] != 0:
				continue
			var l: int = lab[i]
			if l < 0:
				joint[i] = 1
				continue
			var lr: int = lab[i + 1] if x + 1 < w else (lab[y * w] if tor_x else l)
			var ld: int = lab[i + w] if y + 1 < h else l
			if (lr >= 0 and lr != l) or (ld >= 0 and ld != l):
				joint[i] = 1
	for y: int in h:
		for x: int in w:
			var i: int = y * w + x
			if mask[i] == 0:
				continue
			if ring[i] != 0:
				cv.put(x, y, g_light, 0.0)
				continue
			var l: int = lab[i]
			if joint[i] != 0:
				var lr2: int = lab[i + 1] if x + 1 < w else (lab[y * w] if tor_x else l)
				var ld2: int = lab[i + w] if y + 1 < h else l
				var ldg: int = lab[i + w + 1] if (x + 1 < w and y + 1 < h) else l
				var distinct: Array = [l]
				for q: int in [lr2, ld2, ldg]:
					if not distinct.has(q):
						distinct.append(q)
				cv.put(x, y, st_cross if distinct.size() >= 3 else st_joint, 0.0)
				continue
			var tone: int = int(tone_by_id[l])
			if y > 0 and mask[i - w] != 0 and lab[i - w] != l and ring[i - w] == 0:
				tone = mini(tone + 1, 2)
			cv.put(x, y, tones[tone], 0.0)
	for r: Array in moss:
		var rx: int = int(r[0])
		var ry: int = int(r[1])
		var rw: int = int(r[2])
		var rh: int = int(r[3])
		var hit: Array[Vector2i] = []
		for y: int in range(ry, ry + rh):
			for x: int in range(rx, rx + rw):
				if x < 0 or y < 0 or x >= w or y >= h:
					continue
				if joint[y * w + x] != 0 and ring[y * w + x] == 0 and mask[y * w + x] != 0:
					hit.append(Vector2i(x, y))
		for p: Vector2i in hit:
			cv.put(p.x, p.y, m_dark, 0.0)
		for p: Vector2i in hit:
			for d: Vector2i in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)]:
				var qx: int = p.x + d.x
				var qy: int = p.y + d.y
				if qx < rx or qy < ry or qx >= rx + rw or qy >= ry + rh or qx < 0 or qy < 0 or qx >= w or qy >= h:
					continue
				var qi: int = qy * w + qx
				if mask[qi] != 0 and ring[qi] == 0 and joint[qi] == 0:
					cv.put(qx, qy, m_mid, 0.0)


func _ring(mask: PackedByteArray, w: int, h: int, top_ranges: Array, bot_ranges: Array, y_split: int) -> PackedByteArray:
	var outside: PackedByteArray = PackedByteArray()
	outside.resize(w * h)
	for i: int in w * h:
		outside[i] = 1 if mask[i] == 0 else 0
	var din: PackedInt32Array = K.dist4(outside, w, h, 2)
	var ring: PackedByteArray = K.new_mask(w, h)
	for y: int in h:
		for x: int in w:
			var i: int = y * w + x
			if mask[i] == 0:
				continue
			var t: int = 1
			if y < y_split:
				t = 2 if _in_ranges(x, top_ranges) else 1
			else:
				t = 2 if _in_ranges(x, bot_ranges) else 1
			if din[i] <= t:
				ring[i] = 1
	return ring


## Lajes das pontas (ids 0 a 5) nas duas posições de emenda.
func _end_jobs(mode: int) -> Array:
	var jobs: Array = []
	for i: int in END_POLYS.size():
		if mode == 0 or mode == 1:
			jobs.append([_shift(END_POLYS[i], 0.0), i, null])
		if mode == 0:
			jobs.append([_shift(END_POLYS[i], 96.0), i, null])
		if mode == 2:
			jobs.append([_rot_cw(_shift(END_POLYS[i], 96.0)), 20 + i, null])
	return jobs


func _end_tones() -> Dictionary:
	var d: Dictionary = {}
	for i: int in END_TONES.size():
		d[i] = END_TONES[i]
		d[20 + i] = END_TONES[i]
	return d


## Faixa de encaixe canônica: só as lajes das pontas, contorno reto (linhas 12 a 83), aro de 2 px.
func _end_strip() -> Image:
	var mask: PackedByteArray = K.poly_mask(TR, TR, [0, 12, 96, 12, 96, 84, 0, 84])
	var ring: PackedByteArray = _ring(mask, TR, TR, [[0, 95]], [[0, 95]], 48)
	var cv: RefCounted = CV.new(TR, TR, false, false)
	_paint_labels(cv, mask, ring, _label_map(_end_jobs(0)), _end_tones(), true, [])
	return cv.to_image()


func _apply_strip(cv: RefCounted, strip: Image) -> void:
	for y: int in TR:
		for x: int in [0, 1, 94, 95]:
			var c: Color = strip.get_pixel(x, y)
			if c.a > 0.5:
				cv.put(x, y, P.find((c.r8 << 16) | (c.g8 << 8) | c.b8), 0.0)
			else:
				cv.put(x, y, -1, 0.0)


func _trail(v: int, strip: Image) -> RefCounted:
	var top: Array = TRAIL_TOP[v]
	var bot: Array = TRAIL_BOT[v]
	var poly: Array = []
	poly.append_array(top)
	for i: int in range(bot.size() / 2 - 1, -1, -1):
		poly.append(bot[i * 2])
		poly.append(bot[i * 2 + 1])
	var mask: PackedByteArray = K.poly_mask(TR, TR, poly)
	var ring: PackedByteArray = _ring(mask, TR, TR, AR_TOP_V[v], AR_BOT_V[v], 48)
	var jobs: Array = _end_jobs(0)
	var tones: Dictionary = _end_tones()
	var cells: Array = _mesh_cells(TRAIL_MESH[v])
	for i: int in cells.size():
		jobs.append([cells[i][0], 100 + i, null])
		tones[100 + i] = cells[i][1]
	var cv: RefCounted = CV.new(TR, TR, false, false)
	_paint_labels(cv, mask, ring, _label_map(jobs), tones, true, TRAIL_MOSS[v])
	_apply_strip(cv, strip)
	return cv


# Curva: entra pela esquerda, sai por baixo. Contorno em L com bordas escritas à mão.
const BEND_POLY: Array = [
	0, 12, 3, 12, 9, 10, 15, 13, 21, 9, 27, 12, 33, 14, 39, 10, 45, 8, 51, 12, 57, 14, 63, 10, 69, 9, 74, 11,
	79, 10, 84, 13, 87, 18, 86, 24, 88, 30, 86, 36, 88, 42, 87, 48, 85, 54, 88, 60, 86, 66, 88, 72, 86, 78,
	87, 84, 85, 90, 84, 96,
	12, 96, 13, 93, 11, 90, 13, 87, 10, 85, 6, 86, 3, 84, 0, 84,
]
# Parte de cima da curva (braço horizontal e o canto): malha própria com vértices até x = 90
const BEND_MESH: Array = [
	[[12, 6, 30, 8, 46, 5, 62, 7, 76, 6, 90, 8], [12, 20, 28, 18, 47, 21, 60, 19, 78, 21, 90, 19],
		[12, 34, 31, 33, 44, 35, 63, 32, 75, 34, 90, 36], [12, 47, 27, 49, 48, 46, 61, 48, 77, 47, 90, 48],
		[12, 61, 32, 60, 45, 62, 62, 60, 74, 61, 90, 59], [12, 75, 29, 73, 47, 75, 60, 74, 72, 76, 90, 74],
		[12, 90, 30, 91, 46, 90, 61, 92, 76, 90, 90, 92]],
	[[0, 0, 1, 1, 3, 3, 4, 4, 5, 5], [0, 0, 2, 1, 3, 3, 5, 5], [0, 0, 1, 2, 3, 3, 4, 4, 5, 5], [0, 0, 2, 2, 3, 3, 5, 5],
		[0, 0, 1, 1, 3, 3, 5, 5], [0, 0, 2, 2, 4, 3, 5, 5]],
	[[1, 2, 1, 0], [0, 1, 2], [1, 1, 0, 1], [2, 1, 1], [1, 0, 1], [1, 1, 2]],
]
# A malha de cima vale acima desta linha irregular; abaixo dela entra o braço vertical (variante 3 girada)
const BEND_CUT: Array = [-1, -1, 97, -1, 97, 57, 84, 54, 72, 58, 60, 54, 48, 58, 36, 55, 24, 58, 12, 54, -1, 57]
const BEND_MOSS: Array = [[26, 30, 12, 4], [50, 50, 4, 12], [66, 58, 12, 4], [36, 66, 4, 10]]


func _trail_bend(strip: Image) -> RefCounted:
	var mask: PackedByteArray = K.poly_mask(TR, TR, BEND_POLY)
	var outside: PackedByteArray = PackedByteArray()
	outside.resize(TR * TR)
	for i: int in TR * TR:
		outside[i] = 1 if mask[i] == 0 else 0
	var din: PackedInt32Array = K.dist4(outside, TR, TR, 2)
	var ring: PackedByteArray = K.new_mask(TR, TR)
	for y: int in TR:
		for x: int in TR:
			var i2: int = y * TR + x
			if mask[i2] == 0:
				continue
			var t: int = 1
			if (y < 20 and (x < 4 or _in_ranges(x, [[20, 28], [58, 64]]))) or (x > 80 and (y > 92 or _in_ranges(y, [[28, 36], [60, 68]]))):
				t = 2
			if x < 4 or y > 91:
				t = 2
			if din[i2] <= t:
				ring[i2] = 1
	var region_h: PackedByteArray = K.poly_mask(TR, TR, BEND_CUT)
	var region_v: PackedByteArray = K.new_mask(TR, TR)
	for i3: int in TR * TR:
		region_v[i3] = 1 if region_h[i3] == 0 else 0
	var jobs: Array = _end_jobs(1)
	jobs.append_array(_end_jobs(2))
	# as lajes da ponta esquerda só valem em x < 12; as de baixo, em y >= 84
	var tones: Dictionary = _end_tones()
	var hc: Array = _mesh_cells(BEND_MESH)
	for i4: int in hc.size():
		jobs.append([hc[i4][0], 100 + i4, region_h])
		tones[100 + i4] = hc[i4][1]
	var vc: Array = _mesh_cells(TRAIL_MESH[3])
	for i5: int in vc.size():
		jobs.append([_rot_cw(vc[i5][0]), 200 + i5, region_v])
		tones[200 + i5] = vc[i5][1]
	var cv: RefCounted = CV.new(TR, TR, false, false)
	_paint_labels(cv, mask, ring, _label_map(jobs), tones, false, BEND_MOSS)
	# entrada pela esquerda: colunas 0-1 = faixa; saída por baixo: linhas 94-95 = faixa girada
	for y2: int in TR:
		for x2: int in [0, 1]:
			var c: Color = strip.get_pixel(x2, y2)
			cv.put(x2, y2, P.find((c.r8 << 16) | (c.g8 << 8) | c.b8) if c.a > 0.5 else -1, 0.0)
	for x3: int in TR:
		for k: int in [0, 1]:
			var c2: Color = strip.get_pixel(94 + k, 95 - x3)
			cv.put(x3, 94 + k, P.find((c2.r8 << 16) | (c2.g8 << 8) | c2.b8) if c2.a > 0.5 else -1, 0.0)
	return cv
