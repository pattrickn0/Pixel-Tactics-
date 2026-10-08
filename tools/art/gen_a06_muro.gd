extends SceneTree
## A06, parte 2 (revisão 1): muro e escada de pedra seca, crista e capeamento em lajes irregulares,
## quinas, degraus + cortinas de musgo. Tudo vem de tabelas escritas à mão: fiadas de blocos
## (largura, tom, cantos lascados), polígonos de lajes e carimbos de musgo. Sem RNG e sem ruído.
## Rodar da raiz do projeto:
##   "$G" --headless --path . --script tools/art/gen_a06_muro.gd

const K = preload("res://tools/art/a06_lib.gd")
const CV = K.CV
const P = K.P

var jx: int # #1C2B2B (só nos cruzamentos)
var jn: int # #34403C (junta)
var sb: int # #7A7A66
var s0: int # #989680
var s1: int # #B9B597
var s2: int # #D3CCB4
var sc: int # #5C6250
var m1: int # #496819
var m2: int # #5E7C26
var m3: int # #789636
var m4: int # #8FAE48
var m5: int # #B0C860
var ga: int # #73A949 (grama da arena, só nas juntas dos degraus)
var gf: int # #539342
var gh: int # #6A9E4A
var stone: Array[int] = [] # tons dos blocos: 0 = #7A7A66, 1 = #989680, 2 = #B9B597, 3 = #D3CCB4 (só aresta)

# Musgo em 3 tons: 4 = #8FAE48 (ponta de luz), 3 = #789636, 2 = #5E7C26, 1 = #496819
const MOSS: Array = [
	["4433443", "4333322", ".332221", "..22211", "...111."],
	["443344", "433332", ".33222", "..2211", "...11."],
	["44433", "43332", ".3222", "..211"],
	["4433344334", "4333333322", ".33322222.1", "..2222221..", "...2211111."],
	["4334", "3332", ".322", "..21"],
	["443344334433", "433333333322", ".3322222222211", "..221111111...", "....1.11..."],
	["3344", "3332", ".222", "..21"],
	["44433443", "43333332", ".3332222", "..222211", "...2111."],
	["43", "32", ".2", ".2", ".1"],
	["4", "3", "2", "2", "1"],
	["44", "33", "32", ".2", ".2", ".1"],
	["34", "33", "22", ".2"],
]


func _initialize() -> void:
	jx = P.hx("#1C2B2B")
	jn = P.hx("#34403C")
	sb = P.hx("#7A7A66")
	s0 = P.hx("#989680")
	s1 = P.hx("#B9B597")
	s2 = P.hx("#D3CCB4")
	sc = P.hx("#5C6250")
	m1 = P.hx("#496819")
	m2 = P.hx("#5E7C26")
	m3 = P.hx("#789636")
	m4 = P.hx("#8FAE48")
	m5 = P.hx("#B0C860")
	ga = P.hx("#73A949")
	gf = P.hx("#539342")
	gh = P.hx("#6A9E4A")
	stone = [sb, s0, s1, s2]

	var face: RefCounted = _high_face()
	K.save_cv(face, "wall/wall_high_face", true, false)
	K.save_cv(_low_face(), "wall/wall_low_face", true, false)
	K.save_cv(_crest(), "wall/wall_crest", true, false)
	K.save_cv(_cap(), "wall/wall_cap", true, false)
	K.save_cv(_quoin(face), "wall/wall_quoin", true, false)
	K.save_cv(_crest_corner(), "wall/wall_crest_corner", true, false)
	K.save_cv(_cap_corner(), "wall/wall_cap_corner", true, false)
	K.save_cv(_tread(0), "wall/stair_tread_0", true, false)
	K.save_cv(_tread(1), "wall/stair_tread_1", true, false)
	K.save_cv(_riser(0), "wall/stair_riser_0", true, false)
	K.save_cv(_riser(1), "wall/stair_riser_1", true, false)
	K.save_cv(_drape(0), "cards/moss_drape_0", false, true)
	K.save_cv(_drape(1), "cards/moss_drape_1", false, true)
	print("A06 MURO: 11 opacos + 11 normais + 2 cartões gravados")
	quit()


# ---------------------------------------------------------------------------
# Musgo
# ---------------------------------------------------------------------------

func _moss(cv: RefCounted, list: Array) -> void:
	for e: Array in list:
		var rows: Array = MOSS[int(e[2])]
		for j: int in rows.size():
			var row: String = rows[j]
			for i: int in row.length():
				var ci: int = -1
				var z: float = 0.9
				match row[i]:
					"4":
						ci = m4
						z = 1.0
					"3":
						ci = m3
						z = 0.95
					"2":
						ci = m2
						z = 0.85
					"1":
						ci = m1
						z = 0.75
				if ci >= 0:
					cv.put(int(e[0]) + i, int(e[1]) + j, ci, z)


# ---------------------------------------------------------------------------
# Pedra seca: fiadas de blocos. Cada fiada é uma lista de largura / tom / cantos lascados / lasca.
# As linhas de junta ondulam ±1 px (tabelas de deslocamento por coluna).
# ---------------------------------------------------------------------------

func _off(table: Array, x: int) -> int:
	var v: int = 0
	for e: Array in table:
		if x >= int(e[0]):
			v = int(e[1])
	return v


func _ints(s: String) -> Array[int]:
	var out: Array[int] = []
	for tok: String in s.split(" ", false):
		out.append(tok.hex_to_int() if tok.length() == 1 and tok >= "a" else int(tok))
	return out


## Pinta uma fiada k. ys = linhas de início das fiadas; offs[k] = ondulação da junta de cima da fiada k.
## spec: [x0, "larguras", "tons", "cantos (hex)", "lasca x", "lasca y"]
func _stone_course(cv: RefCounted, ys: Array, offs: Array, k: int, spec: Array, wrap_w: int) -> Array[int]:
	var ws: Array[int] = _ints(String(spec[1]))
	var ts: Array[int] = _ints(String(spec[2]))
	var cs: Array[int] = _ints(String(spec[3]))
	var sx: Array[int] = _ints(String(spec[4]))
	var sy: Array[int] = _ints(String(spec[5]))
	var total: int = 0
	for w: int in ws:
		total += w
	if total != wrap_w:
		push_error("fiada %d soma %d (esperado %d)" % [k, total, wrap_w])
	var joints: Array[int] = []
	var bx: int = int(spec[0])
	for b: int in ws.size():
		var w2: int = ws[b]
		var t: int = ts[b]
		for xi: int in w2 - 1:
			var x: int = bx + xi
			var xm: int = posmod(x, wrap_w) if wrap_w > 0 else x
			var top: int = int(ys[k]) + _off(offs[k], xm)
			var bot: int = int(ys[k + 1]) - 1 + _off(offs[k + 1], xm)
			for r: int in range(top, bot):
				var ci: int = stone[t]
				var z: float = 0.9
				if r == top:
					ci = stone[mini(t + 1, 3)]
					z = 1.0
				elif r == bot - 1 and t >= 1:
					ci = stone[t - 1]
					z = 0.55
				cv.put(x, r, ci, z)
		joints.append(posmod(bx + w2 - 1, wrap_w) if wrap_w > 0 else bx + w2 - 1)
		# cantos lascados: 2 px comidos pela junta
		var mk: int = cs[b]
		var xl: int = bx
		var xr: int = bx + w2 - 2
		var tl: int = int(ys[k]) + _off(offs[k], posmod(xl, wrap_w) if wrap_w > 0 else xl)
		var tr: int = int(ys[k]) + _off(offs[k], posmod(xr, wrap_w) if wrap_w > 0 else xr)
		var bl: int = int(ys[k + 1]) - 2 + _off(offs[k + 1], posmod(xl, wrap_w) if wrap_w > 0 else xl)
		var br: int = int(ys[k + 1]) - 2 + _off(offs[k + 1], posmod(xr, wrap_w) if wrap_w > 0 else xr)
		if mk & 1:
			cv.put(xl, tl, jn, 0.0)
			cv.put(xl + 1, tl, jn, 0.0)
		if mk & 2:
			cv.put(xr, tr, jn, 0.0)
			cv.put(xr - 1, tr, jn, 0.0)
		if mk & 4:
			cv.put(xl, bl, jn, 0.0)
			cv.put(xl, bl - 1, jn, 0.0)
		if mk & 8:
			cv.put(xr, br, jn, 0.0)
			cv.put(xr, br - 1, jn, 0.0)
		# lasca: 2 px de um tom vizinho
		var cx: int = bx + sx[b]
		var cxm: int = posmod(cx, wrap_w) if wrap_w > 0 else cx
		var cy: int = int(ys[k]) + _off(offs[k], cxm) + sy[b]
		var chip: int = stone[t - 1] if t >= 1 else stone[1]
		cv.put(cx, cy, chip, 0.7)
		cv.put(cx + 1, cy, chip, 0.7)
		bx += w2
	return joints


## Cruzamentos escuros onde uma junta vertical encosta na horizontal.
func _crosses(cv: RefCounted, ys: Array, offs: Array, k: int, joints: Array[int], wrap_w: int) -> void:
	for x: int in joints:
		var xm: int = posmod(x, wrap_w) if wrap_w > 0 else x
		cv.put(x, int(ys[k + 1]) - 1 + _off(offs[k + 1], xm), jx, 0.0)
		if k > 0:
			cv.put(x, int(ys[k]) - 1 + _off(offs[k], xm), jx, 0.0)


## Bloco que ocupa duas fiadas: [fiada, x, largura, tom, lasca x, lasca y]
func _tall_blocks(cv: RefCounted, ys: Array, offs: Array, list: Array, wrap_w: int) -> void:
	for tb: Array in list:
		var k: int = int(tb[0])
		var bx: int = int(tb[1])
		var w: int = int(tb[2])
		var t: int = int(tb[3])
		for xi: int in w - 1:
			var x: int = bx + xi
			var xm: int = posmod(x, wrap_w) if wrap_w > 0 else x
			var top: int = int(ys[k]) + _off(offs[k], xm)
			var bot: int = int(ys[k + 2]) - 1 + _off(offs[k + 2], xm)
			for r: int in range(top, bot):
				var ci: int = stone[t]
				var z: float = 0.9
				if r == top:
					ci = stone[mini(t + 1, 3)]
					z = 1.0
				elif r == bot - 1 and t >= 1:
					ci = stone[t - 1]
					z = 0.55
				cv.put(x, r, ci, z)
		var xmj: int = posmod(bx - 1, wrap_w) if wrap_w > 0 else bx - 1
		var topj: int = int(ys[k]) + _off(offs[k], xmj)
		var botj: int = int(ys[k + 2]) - 1 + _off(offs[k + 2], xmj)
		for r2: int in range(topj, botj + 1):
			cv.put(bx - 1, r2, jn, 0.0)
		var xmr: int = posmod(bx + w - 1, wrap_w) if wrap_w > 0 else bx + w - 1
		var topr: int = int(ys[k]) + _off(offs[k], xmr)
		var botr: int = int(ys[k + 2]) - 1 + _off(offs[k + 2], xmr)
		for r3: int in range(topr, botr + 1):
			cv.put(bx + w - 1, r3, jn, 0.0)
		var chip: int = stone[t - 1] if t >= 1 else stone[1]
		var cy: int = int(ys[k]) + int(tb[5])
		cv.put(bx + int(tb[4]), cy, chip, 0.7)
		cv.put(bx + int(tb[4]) + 1, cy, chip, 0.7)
		cv.put(bx + int(tb[4]) + 1, cy + 1, chip, 0.7)


# ---------------------------------------------------------------------------
# Face do muro alto: 256 x 48. Fiadas de 7, 6, 9, 10 | 7, 9 (as 4 primeiras fecham as linhas 0 a 31).
# ---------------------------------------------------------------------------

const HIGH_Y: Array = [0, 7, 13, 22, 32, 39, 48]
# Ondulação de cada junta: [coluna, deslocamento em px]
const HIGH_OFF: Array = [
	[],
	[[0, 0], [30, 1], [66, 0], [104, -1], [140, 0], [188, 1], [230, 0]],
	[[0, 0], [22, -1], [58, 0], [96, 1], [130, 0], [172, -1], [214, 0], [246, 0]],
	[[0, 1], [36, 0], [80, -1], [118, 0], [160, 1], [202, 0], [240, 1]],
	[[0, 0], [25, 1], [60, 0], [95, 1], [130, 0], [170, 1], [205, 0], [235, 0]],
	[[0, 0], [44, 1], [90, 0], [128, -1], [170, 0], [222, 1], [250, 0]],
	[[0, 0], [40, 1], [70, 0], [120, 1], [150, 0], [200, 1], [235, 0]],
]
# [x da primeira junta, larguras, tons (0 = #7A7A66, 1 = #989680, 2 = #B9B597), cantos lascados (bits 1 a 8), lasca x, lasca y]
const HIGH_COURSES: Array = [
	[3, "14 9 17 11 22 8 15 19 10 13 23 7 16 12 20 9 18 13", "2 1 2 0 2 1 2 1 2 2 1 0 2 1 2 1 0 2", "1 0 6 0 9 2 0 5 0 8 0 4 3 0 a 0 c 1", "5 3 8 4 10 3 6 9 4 5 10 2 7 5 9 3 8 5", "2 3 1 4 2 3 1 2 4 3 1 2 4 3 2 1 3 2"],
	[11, "18 12 7 21 15 9 24 13 10 16 22 8 14 19 11 17 20", "1 2 2 0 2 1 2 1 2 0 2 2 1 2 0 1 2", "2 0 8 0 1 0 5 0 a 0 4 0 3 0 c 0 6", "6 4 2 9 5 3 10 6 4 7 10 3 5 8 4 6 9", "2 1 3 2 1 3 2 3 1 2 3 1 2 1 3 2 1"],
	[6, "12 20 8 16 23 10 14 7 19 13 24 9 15 18 11 17 20", "2 1 2 0 2 1 2 2 1 2 0 2 1 2 1 0 2", "4 0 3 0 9 0 6 1 0 5 0 a 0 2 0 8 0", "5 9 3 7 10 4 6 2 8 5 10 3 7 9 4 6 8", "3 5 2 4 1 6 3 4 2 5 3 1 6 2 4 5 3"],
	[14, "16 10 21 8 13 24 11 18 7 15 22 12 9 19 14 20 17", "1 2 2 0 2 1 2 1 2 0 2 1 2 2 0 1 2", "0 5 0 2 8 0 1 0 6 0 3 0 a 0 4 0 9", "8 4 10 3 6 10 5 9 2 7 10 4 3 8 6 9 5", "3 6 2 4 5 1 7 3 5 2 4 6 1 7 3 4 6"],
	[22, "9 15 23 12 18 8 21 14 10 24 13 17 7 19 11 16 19", "2 1 2 2 0 2 1 2 1 2 0 2 1 2 2 0 2", "0 6 0 1 0 a 0 4 0 3 0 5 0 8 0 2 0", "3 7 10 5 9 3 6 10 4 8 6 5 2 7 4 9 6", "2 4 1 3 2 1 4 3 2 4 1 2 3 1 4 2 3"],
	[9, "20 11 17 8 14 22 13 9 18 24 10 15 7 21 12 16 19", "2 1 2 0 2 1 2 2 1 2 0 2 1 2 1 0 2", "0 5 0 9 0 3 0 6 0 a 0 4 0 8 0 1 0", "9 5 8 3 10 4 6 2 7 10 3 5 2 9 4 6 8", "3 2 4 1 5 3 2 6 1 4 3 5 2 1 4 2 3"],
]
# Blocos que ocupam 2 fiadas: [fiada, x, largura, tom, lasca x, lasca y]
const HIGH_TALL: Array = [
	[0, 88, 15, 2, 4, 3],
	[1, 170, 13, 1, 3, 2],
	[2, 60, 14, 2, 5, 4],
	[2, 205, 16, 1, 6, 3],
	[4, 120, 12, 2, 4, 2],
]
# Musgo escorrendo: [x, y, forma]. Mais no topo e no terço de cima.
const HIGH_MOSS: Array = [
	[1, 0, 0], [9, 0, 7], [17, 0, 2], [26, 0, 1], [33, 0, 4], [41, 0, 2], [49, 0, 0], [58, 0, 7], [66, 0, 4],
	[73, 0, 2], [82, 0, 1], [91, 0, 6], [98, 0, 0], [107, 0, 7], [115, 0, 4], [123, 0, 2], [131, 0, 2], [140, 0, 1],
	[148, 0, 7], [157, 0, 0], [165, 0, 4], [174, 0, 4], [183, 0, 2], [191, 0, 6], [200, 0, 1], [209, 0, 7],
	[218, 0, 4], [226, 0, 0], [235, 0, 2], [244, 0, 7], [252, 0, 2],
	[5, 7, 2], [19, 8, 6], [31, 7, 4], [47, 7, 0], [60, 8, 6], [78, 7, 1], [92, 8, 2], [109, 7, 7], [124, 8, 4],
	[139, 7, 6], [155, 7, 0], [168, 8, 2], [182, 7, 1], [198, 8, 6], [212, 7, 4], [236, 8, 7],
	[12, 13, 4], [38, 13, 6], [66, 13, 2], [101, 13, 4], [133, 13, 6], [163, 13, 2], [198, 13, 4], [229, 13, 6],
	[251, 13, 2],
	[7, 22, 4], [28, 22, 6], [55, 22, 2], [86, 22, 4], [118, 22, 6], [147, 22, 4], [176, 22, 2], [210, 22, 6],
	[238, 22, 4], [250, 22, 2],
	[20, 32, 6], [52, 32, 4], [96, 32, 2], [140, 32, 6], [184, 32, 4], [228, 32, 6],
	[33, 40, 4], [88, 40, 6], [150, 40, 2], [210, 40, 4],
	[14, 6, 8], [36, 12, 9], [58, 6, 10], [75, 12, 11], [104, 21, 8], [127, 12, 9], [150, 21, 10], [167, 6, 11],
	[192, 12, 8], [214, 21, 9], [240, 12, 10], [26, 31, 11], [48, 21, 8], [70, 31, 9], [110, 38, 10], [135, 31, 11],
	[160, 38, 8], [182, 31, 9], [205, 38, 10], [230, 31, 11], [252, 38, 8], [3, 12, 9], [97, 6, 10], [120, 22, 11],
	[172, 22, 8], [244, 6, 9],
]


func _high_face() -> RefCounted:
	var cv: RefCounted = CV.new(256, 48, true, false)
	cv.fill(jn, 0.0)
	var js: Array = []
	for k: int in 6:
		js.append(_stone_course(cv, HIGH_Y, HIGH_OFF, k, HIGH_COURSES[k], 256))
	for k2: int in 6:
		_crosses(cv, HIGH_Y, HIGH_OFF, k2, js[k2], 256)
	_tall_blocks(cv, HIGH_Y, HIGH_OFF, HIGH_TALL, 256)
	_moss(cv, HIGH_MOSS)
	return cv


# ---------------------------------------------------------------------------
# Face do degrau baixo: 256 x 16 (2 fiadas de blocos baixos)
# ---------------------------------------------------------------------------

const LOW_Y: Array = [0, 8, 16]
const LOW_OFF: Array = [[], [[0, 0], [40, 1], [100, 0], [160, -1], [210, 0]], []]
const LOW_COURSES: Array = [
	[9, "16 10 22 8 19 13 24 9 15 21 12 18 7 23 14 19 6", "2 1 2 0 2 1 2 2 1 2 0 2 1 2 1 2 0", "1 0 6 0 a 0 5 0 8 0 3 0 4 0 9 0 2", "5 3 8 3 7 5 10 3 6 8 4 7 2 9 5 7 3", "2 3 1 4 2 5 3 1 4 2 5 3 1 2 4 3 1"],
	[17, "20 9 14 24 11 17 8 22 13 19 10 24 15 7 18 12 13", "1 2 0 2 1 2 2 1 0 2 1 2 2 0 1 2 1", "0 5 0 9 0 2 0 6 0 3 0 a 0 4 0 8 0", "7 3 5 10 4 6 3 8 5 7 3 10 6 2 5 4 5", "3 1 4 2 5 3 1 4 2 5 3 1 4 2 3 5 1"],
]
const LOW_MOSS: Array = [[18, 0, 2], [64, 0, 4], [120, 0, 6], [176, 0, 4], [226, 0, 2], [40, 8, 8], [150, 8, 9], [202, 8, 10]]


func _low_face() -> RefCounted:
	var cv: RefCounted = CV.new(256, 16, true, false)
	cv.fill(jn, 0.0)
	var js: Array = []
	for k: int in 2:
		js.append(_stone_course(cv, LOW_Y, LOW_OFF, k, LOW_COURSES[k], 256))
	for k2: int in 2:
		_crosses(cv, LOW_Y, LOW_OFF, k2, js[k2], 256)
	_moss(cv, LOW_MOSS)
	return cv


# ---------------------------------------------------------------------------
# Espelhos da escada: 96 x 8, uma fiada
# ---------------------------------------------------------------------------

const RISER_Y: Array = [0, 8]
const RISER_OFF: Array = [[], []]
const RISER_COURSES: Array = [
	[0, "14 22 12 20 10 18", "2 1 2 0 2 1", "1 0 6 0 a 0", "5 8 4 7 3 6", "2 3 1 4 2 3"],
	[0, "18 9 21 13 24 11", "1 2 0 2 1 2", "0 5 0 9 0 2", "6 3 7 4 9 3", "3 1 4 2 5 1"],
]
const RISER_MOSS: Array = [[[30, 0, 4], [70, 0, 9]], [[16, 0, 4], [58, 0, 8]]]


func _riser(v: int) -> RefCounted:
	var cv: RefCounted = CV.new(96, 8, false, false)
	cv.fill(jn, 0.0)
	_stone_course(cv, RISER_Y, RISER_OFF, 0, RISER_COURSES[v], 96)
	_moss(cv, RISER_MOSS[v])
	return cv


# ---------------------------------------------------------------------------
# Lajes vistas de cima (crista e capeamento): polígonos escritos à mão, bordas #989680,
# junta entre lajes de 2 px (borda de cada uma), miolo #B9B597 com brilho #D3CCB4.
# ---------------------------------------------------------------------------

func _slab_set(cv: RefCounted, polys: Array, lip_row0: bool) -> void:
	var w: int = cv.w
	var h: int = cv.h
	var lab: PackedInt32Array = PackedInt32Array()
	lab.resize(w * h)
	lab.fill(-1)
	for i: int in polys.size():
		var m: PackedByteArray = K.poly_mask(w, h, polys[i])
		for p: int in w * h:
			if m[p] != 0:
				lab[p] = i
	for y: int in h:
		for x: int in w:
			var l: int = lab[y * w + x]
			if l < 0:
				continue
			var edge: bool = false
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx >= 0 and ny >= 0 and nx < w and ny < h and lab[ny * w + nx] != l:
					edge = true
			if edge:
				cv.put(x, y, s0, 0.8)
				continue
			if lip_row0 and y == 0:
				cv.put(x, y, s2, 1.0)
				continue
			var pillow: bool = true
			for dy: int in range(-2, 3):
				for dx: int in range(-2, 3):
					var qx: int = x + dx
					var qy: int = y + dy
					if qx >= 0 and qy >= 0 and qx < w and qy < h and lab[qy * w + qx] != l:
						pillow = false
			cv.put(x, y, s2 if pillow else s1, 1.0)


# Blobs de musgo (5 = #B0C860, 4 = #8FAE48, 3 = #789636, 2 = #5E7C26) e de grama de fora (h = #6A9E4A, g = #539342)
const BLOBS: Array = [
	["...555...", ".55544455.", "544433344.", ".43332233.", "..222222.."],
	["..555..", ".54445.", "5443345", ".43322.", "..322.."],
	["5555.", "54445", "43334", ".222."],
	["...5555555...", ".55544444445.", "5444433333344", ".43333222233.", "..3322222222.", "....22222...."],
	["..55.", ".5445", "54334", ".3322"],
	["555555", "544444", ".43333", "..2222"],
	["..5555..", ".544445.", "54433345", ".4333322", "..32222."],
	["55.55", "54445", ".433.", "..22."],
	["h.h.h", "hghgh", ".ggg."],
	["..3333..", ".33222233", "3322222233", ".332222.3", "..3333.."],
	["33333", "32223", "32223", ".333."],
	["..333333..", ".3322222233", "332222222233", ".3222222233.", "..33333333.."],
]


func _blobs(cv: RefCounted, list: Array) -> void:
	for e: Array in list:
		var rows: Array = BLOBS[int(e[2])]
		for j: int in rows.size():
			var row: String = rows[j]
			for i: int in row.length():
				var ci: int = -1
				var z: float = 0.6
				match row[i]:
					"5":
						ci = m5
						z = 0.7
					"4":
						ci = m4
						z = 0.5
					"3":
						ci = m3
					"2":
						ci = m2
						z = 0.5
					"h":
						ci = gh
					"g":
						ci = gf
				if ci >= 0:
					cv.put(int(e[0]) + i, int(e[1]) + j, ci, z)


# ---------------------------------------------------------------------------
# Crista (vista de cima): 256 x 32. Linha 0 = lado externo (floresta). Coluna 0 = junta.
# ---------------------------------------------------------------------------

const CREST_A: Array = [
	[1, 0, 20, 0, 22, 5, 21, 10, 9, 11, 3, 8],
	[24, 0, 47, 0, 49, 6, 44, 10, 28, 9, 25, 5],
	[51, 1, 66, 0, 69, 4, 67, 9, 55, 10, 52, 6],
	[71, 0, 98, 0, 100, 5, 96, 10, 84, 11, 73, 8],
	[102, 0, 116, 1, 118, 7, 113, 9, 104, 9],
	[133, 0, 154, 0, 156, 6, 150, 10, 139, 11, 134, 7],
	[158, 1, 176, 0, 179, 5, 175, 9, 162, 10, 159, 6],
	[181, 0, 205, 0, 206, 4, 202, 10, 188, 9, 185, 6, 182, 3],
	[208, 0, 221, 1, 224, 6, 219, 10, 211, 9],
	[226, 0, 253, 0, 254, 5, 251, 10, 237, 11, 228, 7],
]
const CREST_B: Array = [
	[1, 22, 17, 21, 19, 26, 18, 31, 3, 32, 1, 27],
	[20, 23, 41, 22, 43, 28, 40, 32, 22, 32, 21, 27],
	[44, 21, 63, 22, 64, 27, 62, 32, 47, 32, 45, 28],
	[66, 22, 90, 21, 92, 26, 89, 32, 70, 32, 67, 27],
	[93, 23, 107, 22, 110, 28, 107, 32, 95, 31],
	[112, 21, 138, 22, 139, 28, 135, 32, 116, 32, 113, 27],
	[141, 22, 153, 23, 155, 29, 150, 32, 143, 31],
	[157, 21, 183, 22, 185, 27, 181, 32, 162, 32, 158, 28],
	[187, 22, 203, 21, 206, 27, 202, 32, 190, 31],
	[208, 23, 230, 22, 232, 28, 229, 32, 211, 32, 209, 27],
	[234, 22, 254, 21, 254, 28, 252, 32, 238, 32, 235, 27],
]
# [x, y, forma]
const CREST_BLOBS: Array = [
	[3, 8, 7], [30, 9, 2], [58, 8, 4], [92, 9, 7], [118, 8, 3], [160, 8, 4], [196, 8, 7], [228, 9, 2],
	[10, 11, 1], [38, 11, 5], [70, 10, 6], [104, 11, 0], [146, 10, 2], [172, 11, 6], [214, 10, 0], [240, 11, 5],
	[2, 14, 4], [22, 14, 6], [50, 14, 3], [84, 14, 0], [112, 14, 5], [136, 13, 1], [166, 14, 7], [190, 14, 3],
	[220, 14, 4], [246, 14, 6],
	[14, 17, 2], [44, 17, 7], [74, 16, 4], [100, 17, 6], [128, 17, 0], [152, 17, 5], [182, 17, 1], [206, 17, 2],
	[232, 17, 7],
	[6, 19, 5], [34, 19, 0], [62, 19, 6], [96, 19, 4], [122, 20, 2], [150, 19, 7], [178, 20, 3], [202, 19, 5],
	[238, 20, 1],
	[26, 15, 8], [95, 13, 8], [158, 15, 8], [226, 13, 8],
	[18, 12, 9], [56, 15, 11], [88, 11, 10], [124, 16, 9], [140, 12, 11], [176, 15, 10], [200, 12, 9], [244, 16, 10],
	[40, 16, 10], [108, 17, 9], [166, 11, 10], [214, 18, 11],
]


func _crest() -> RefCounted:
	var cv: RefCounted = CV.new(256, 32, true, false)
	cv.fill(m4, 0.45)
	_slab_set(cv, CREST_A + CREST_B, false)
	_blobs(cv, CREST_BLOBS)
	for y: int in range(0, 10):
		cv.put(0, y, s0, 0.8)
		cv.put(255, y, s0, 0.8)
	for y2: int in range(22, 32):
		cv.put(0, y2, s0, 0.8)
		cv.put(255, y2, s0, 0.8)
	# a emenda: a coluna 255 é cópia da coluna 0 e a altura fica plana em volta dela (normal sem salto)
	for y3: int in 32:
		cv.put(255, y3, cv.get_c(0, y3), cv.get_z(0, y3))
		for xz: int in [254, 1, 2]:
			cv.put_z(xz, y3, cv.get_z(0, y3))
	return cv


# ---------------------------------------------------------------------------
# Capeamento do degrau baixo: 256 x 16. Linha 0 = beirada sobre a face. Coluna 0 = junta.
# ---------------------------------------------------------------------------

const CAP_SLABS: Array = [
	[1, 0, 17, 0, 18, 6, 16, 13, 5, 14, 2, 8],
	[20, 0, 36, 0, 38, 7, 34, 14, 23, 13],
	[38, 0, 49, 0, 50, 6, 47, 13, 40, 12],
	[52, 0, 72, 0, 73, 5, 70, 14, 56, 13, 53, 7],
	[75, 0, 88, 0, 89, 7, 85, 12, 77, 13],
	[91, 0, 106, 0, 107, 6, 104, 14, 94, 13, 92, 6],
	[109, 0, 119, 0, 120, 8, 117, 13, 111, 13],
	[122, 0, 142, 0, 143, 6, 140, 14, 128, 13, 124, 8],
	[145, 0, 162, 0, 163, 7, 160, 13, 149, 14, 146, 6],
	[165, 0, 176, 0, 177, 5, 173, 12, 167, 13],
	[179, 0, 199, 0, 200, 7, 196, 14, 184, 13, 180, 7],
	[202, 0, 215, 0, 216, 6, 212, 13, 205, 14],
	[218, 0, 237, 0, 238, 5, 234, 13, 224, 14, 219, 8],
	[240, 0, 254, 0, 254, 7, 250, 14, 244, 13, 241, 6],
]
const CAP_BLOBS: Array = [
	[3, 12, 4], [34, 12, 2], [66, 12, 5], [92, 12, 4], [121, 12, 5], [150, 12, 7], [177, 12, 4], [213, 12, 7],
	[238, 12, 2],
	[10, 10, 7], [102, 10, 7], [210, 10, 7], [132, 9, 7],
]


func _cap() -> RefCounted:
	var cv: RefCounted = CV.new(256, 16, true, false)
	cv.fill(m4, 0.45)
	_slab_set(cv, CAP_SLABS, true)
	_blobs(cv, CAP_BLOBS)
	for y: int in range(0, 11):
		cv.put(0, y, s0, 0.8)
	for y3: int in 16:
		cv.put(255, y3, cv.get_c(0, y3), cv.get_z(0, y3))
		for xz: int in [254, 1, 2]:
			cv.put_z(xz, y3, cv.get_z(0, y3))
	return cv


# ---------------------------------------------------------------------------
# Quina: 32 x 48 (face + blocos de amarração) e topos de canto
# ---------------------------------------------------------------------------

# Blocos de amarração por fiada: [fiada, largura, tom, cantos, lasca x, lasca y]; encostados na coluna 31
const QUOIN: Array = [
	[0, 27, 2, 2, 8, 2],
	[1, 12, 2, 0, 4, 1],
	[2, 23, 1, 4, 6, 4],
	[3, 14, 2, 8, 5, 3],
	[4, 29, 2, 1, 12, 2],
	[5, 10, 1, 0, 3, 4],
]
const QUOIN_MOSS: Array = [[10, 0, 2], [24, 0, 8], [4, 7, 8], [18, 13, 4], [12, 22, 8]]


func _quoin(face: RefCounted) -> RefCounted:
	var cv: RefCounted = CV.new(32, 48, false, false)
	for y: int in 48:
		for x: int in 32:
			cv.put(x, y, face.get_c(x, y), face.get_z(x, y))
	for q: Array in QUOIN:
		var k: int = int(q[0])
		var w: int = int(q[1])
		var t: int = int(q[2])
		var bx: int = 32 - w + 1
		for xi: int in w:
			var x2: int = bx + xi
			if x2 > 31:
				continue
			var top: int = int(HIGH_Y[k]) + _off(HIGH_OFF[k], x2)
			var bot: int = int(HIGH_Y[k + 1]) - 1 + _off(HIGH_OFF[k + 1], x2)
			if xi == 0:
				for r0: int in range(top, bot + 1):
					cv.put(x2 - 1, r0, jn, 0.0)
			for r: int in range(top, bot):
				var ci: int = stone[t]
				var z: float = 0.9
				if r == top:
					ci = stone[mini(t + 1, 3)]
					z = 1.0
				elif r == bot - 1 and t >= 1:
					ci = stone[t - 1]
					z = 0.55
				cv.put(x2, r, ci, z)
		var topb: int = int(HIGH_Y[k]) + _off(HIGH_OFF[k], 20)
		var chip: int = stone[t - 1]
		cv.put(bx + int(q[4]), topb + int(q[5]), chip, 0.7)
		cv.put(bx + int(q[4]) + 1, topb + int(q[5]), chip, 0.7)
		var mk: int = int(q[3])
		var bot2: int = int(HIGH_Y[k + 1]) - 2
		if mk & 1:
			cv.put(bx + 1, topb, jn, 0.0)
			cv.put(bx + 2, topb, jn, 0.0)
		if mk & 2:
			cv.put(30, topb, jn, 0.0)
			cv.put(29, topb, jn, 0.0)
		if mk & 4:
			cv.put(bx + 1, bot2, jn, 0.0)
			cv.put(bx + 1, bot2 - 1, jn, 0.0)
		if mk & 8:
			cv.put(30, bot2, jn, 0.0)
			cv.put(30, bot2 - 1, jn, 0.0)
	_moss(cv, QUOIN_MOSS)
	return cv


# Quina da crista: L nas bordas externas (linha 0 e coluna 31), laje do canto interno nas linhas 22-31 x colunas 0-9.
# Junta #989680 na coluna 0 (linhas 0-9 e 22-31) e na linha 31 (colunas 0-9 e 22-31).
const CREST_CORNER_SLABS: Array = [
	[1, 0, 15, 0, 15, 10, 2, 10],
	[15, 0, 23, 0, 23, 9, 15, 10],
	[23, 0, 32, 0, 32, 10, 23, 10],
	[23, 10, 32, 10, 32, 21, 24, 21],
	[24, 21, 32, 21, 32, 31, 24, 31],
	[1, 22, 10, 22, 10, 31, 1, 31],
]
const CREST_CORNER_BLOBS: Array = [[2, 11, 4], [11, 12, 7], [3, 16, 5], [12, 17, 1], [7, 19, 2], [16, 12, 4], [15, 20, 8], [18, 16, 7]]


func _crest_corner() -> RefCounted:
	var cv: RefCounted = CV.new(32, 32, false, false)
	cv.fill(m4, 0.45)
	_slab_set(cv, CREST_CORNER_SLABS, false)
	_blobs(cv, CREST_CORNER_BLOBS)
	for y: int in range(0, 10):
		cv.put(0, y, s0, 0.8)
	for y2: int in range(22, 32):
		cv.put(0, y2, s0, 0.8)
	for x: int in range(0, 10):
		cv.put(x, 31, s0, 0.8)
	for x2: int in range(22, 32):
		cv.put(x2, 31, s0, 0.8)
	return cv


const CAP_CORNER_SLAB: Array = [[1, 0, 16, 0, 16, 12, 14, 14, 4, 14, 1, 11]]


func _cap_corner() -> RefCounted:
	var cv: RefCounted = CV.new(16, 16, false, false)
	cv.fill(m4, 0.45)
	_slab_set(cv, CAP_CORNER_SLAB, true)
	for y: int in 16:
		cv.put(15, y, s2 if cv.get_c(15, y) == s0 or cv.get_c(15, y) == s1 else cv.get_c(15, y), 1.0)
	_blobs(cv, [[1, 11, 7], [10, 12, 4]])
	for y2: int in range(0, 11):
		cv.put(0, y2, s0, 0.8)
	for x: int in 16:
		cv.put(x, 15, s0, 0.8)
	return cv


# ---------------------------------------------------------------------------
# Escada: pisos 96 x 16. Juntas verticais tortas (polilinhas), lascas e trincas desenhadas uma a uma.
# ---------------------------------------------------------------------------

const TREAD_JOINTS: Array = [
	[[27, 1, 28, 3, 26, 6, 27, 9, 29, 12, 28, 14], [60, 1, 59, 4, 61, 7, 60, 10, 62, 13, 61, 14]],
	[[18, 1, 19, 4, 17, 7, 18, 10, 20, 13], [46, 1, 45, 3, 47, 6, 46, 9, 48, 12, 47, 14], [73, 1, 74, 5, 72, 8, 73, 11, 75, 14]],
]
const TREAD_TONES: Array = [[2, 1, 2], [1, 2, 1, 2]]
# Lascas: [x, y, forma] (a = #989680, b = #B9B597, c = #7A7A66); cada forma é diferente
const TREAD_CHIPS: Array = [
	[[17, 4, "aa"], [36, 9, "a|aa"], [47, 6, ".b|bb"], [70, 11, "bb|b."], [86, 4, "a.|aa|a."], [8, 12, "bbb"]],
	[[4, 9, "bb|b"], [24, 6, "aa|.a"], [38, 12, "b.b"], [53, 4, "a|a|a"], [63, 10, ".aa|aa."], [80, 7, "bbb|.b."], [92, 12, "aa"]],
]
# Trincas: polilinhas x0, y0, x1, y1, ... em #7A7A66
const TREAD_CRACKS: Array = [
	[[12, 3, 14, 6, 13, 9, 15, 11], [40, 2, 41, 5, 43, 7], [80, 6, 79, 9, 81, 12]],
	[[7, 4, 9, 7, 8, 10], [30, 2, 32, 4, 31, 7, 33, 10], [58, 8, 57, 11, 59, 13], [88, 3, 89, 6, 87, 9], [66, 2, 68, 4]],
]
const TREAD_MOSS: Array = [
	[[28, 7, "m"], [28, 8, "m"], [27, 9, "m"], [61, 12, "m"], [60, 13, "g"]],
	[[19, 6, "m"], [18, 7, "m"], [74, 11, "g"], [74, 12, "g"], [47, 13, "m"]],
]


func _tread(v: int) -> RefCounted:
	var cv: RefCounted = CV.new(96, 16, false, false)
	for x: int in 96:
		cv.put(x, 0, s2, 1.0)
		cv.put(x, 15, sc, 0.0)
	# lajes: para cada linha, o tom muda a cada junta torta
	var joints: Array = TREAD_JOINTS[v]
	var jx_at: Array = []
	for j: Array in joints:
		var col: Dictionary = {}
		for k: int in range(0, j.size() - 2, 2):
			for p: Vector2i in CV.line_pts(int(j[k]), int(j[k + 1]), int(j[k + 2]), int(j[k + 3])):
				col[p.y] = p.x
		jx_at.append(col)
	for y: int in range(1, 15):
		var cuts: Array[int] = []
		for jj: int in jx_at.size():
			var d: Dictionary = jx_at[jj]
			cuts.append(int(d[y]) if d.has(y) else 999)
		for x2: int in 96:
			var seg: int = 0
			for c: int in cuts:
				if c < x2:
					seg += 1
			var t: int = int(TREAD_TONES[v][seg])
			var ci: int = stone[t]
			var z: float = 0.85
			if y == 14 and t >= 1:
				ci = stone[t - 1]
				z = 0.6
			cv.put(x2, y, ci, z)
	for jj2: int in jx_at.size():
		var d2: Dictionary = jx_at[jj2]
		for y2: int in d2.keys():
			cv.put(int(d2[y2]), int(y2), sb, 0.2)
	var cmap: Dictionary = {"a": [s0, 0.7], "b": [s1, 0.7], "c": [sb, 0.4]}
	for ch: Array in TREAD_CHIPS[v]:
		K.stamp(cv, String(ch[2]).split("|"), int(ch[0]), int(ch[1]), cmap)
	for cr: Array in TREAD_CRACKS[v]:
		for k2: int in range(0, cr.size() - 2, 2):
			for p2: Vector2i in CV.line_pts(int(cr[k2]), int(cr[k2 + 1]), int(cr[k2 + 2]), int(cr[k2 + 3])):
				cv.put(p2.x, p2.y, sb, 0.4)
	for m: Array in TREAD_MOSS[v]:
		cv.put(int(m[0]), int(m[1]), m2 if m[2] == "m" else ga, 0.5)
	return cv


# ---------------------------------------------------------------------------
# Cortinas de musgo: 128 x 12, alfa. Cada cortina = [x, largura, comprimento total a partir da linha 0].
# ---------------------------------------------------------------------------

const DRAPES: Array = [
	[[4, 2, 5], [8, 1, 8], [12, 3, 4], [17, 2, 6], [21, 1, 9], [24, 2, 4], [29, 3, 6], [34, 1, 3], [37, 2, 7],
		[42, 2, 5], [47, 1, 10], [50, 3, 4], [56, 2, 6], [60, 1, 4], [64, 2, 8], [69, 3, 5], [74, 1, 3],
		[78, 2, 7], [83, 2, 4], [88, 1, 9], [91, 3, 6], [97, 2, 5], [101, 1, 4], [105, 2, 7], [110, 3, 4],
		[115, 1, 6], [118, 2, 5], [122, 2, 8], [126, 4, 5]],
	[[5, 3, 4], [10, 1, 7], [14, 2, 5], [19, 3, 9], [25, 1, 4], [28, 2, 6], [33, 2, 8], [38, 1, 3],
		[41, 3, 5], [47, 2, 7], [52, 1, 4], [55, 3, 6], [61, 2, 10], [66, 1, 5], [69, 2, 4], [74, 3, 7],
		[80, 1, 3], [83, 2, 8], [88, 3, 5], [94, 1, 6], [97, 2, 4], [102, 2, 9], [107, 1, 5], [110, 3, 6],
		[116, 2, 4], [120, 1, 7], [123, 2, 5], [126, 4, 5]],
]


func _drape(v: int) -> RefCounted:
	var cv: RefCounted = CV.new(128, 12, true, false)
	for x: int in 128:
		cv.put(x, 0, m4, 0.0)
		cv.put(x, 1, m3, 0.0)
	for d: Array in DRAPES[v]:
		for i: int in int(d[1]):
			var x: int = int(d[0]) + i
			var ln: int = int(d[2])
			for y: int in range(2, ln):
				var c: int = m2
				if y == ln - 1 and ln > 4:
					c = m1
				cv.put(x, y, c, 0.0)
	return cv
