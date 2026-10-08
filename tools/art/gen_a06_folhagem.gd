extends SceneTree
## A06, parte 3: folhagem (miolo e casca dos lóbulos, coníferas) e props (tronco, caixote, lenha).
## Mapas de carimbos e listas de posições escritos à mão. Sem RNG e sem ruído.
## Rodar da raiz do projeto:
##   "$G" --headless --path . --script tools/art/gen_a06_folhagem.gd

const K = preload("res://tools/art/a06_lib.gd")
const CV = K.CV
const P = K.P

# ---------------------------------------------------------------------------
# Miolo dos lóbulos: 64 x 64 opaco. Malha 16 x 16 de carimbos (cada célula 4 x 4 px, linhas pares
# deslocadas 2 px). O dígito escolhe o carimbo; "." deixa a célula vazia (fundo escuro aparece).
# ---------------------------------------------------------------------------

# a = mais claro (só no alto de cada aglomerado), b, c, d = mais escuro
const STAMPS: Array = [
	[".aa..", "abbc.", "bbccd", ".cdd."],
	["..aa.", ".abbc", "abbcd", "bccd."],
	[".aab.", "abbbc", "bccd.", ".cdd."],
	["aab..", "abbc.", ".bccd", "..cdd"],
	[".ab..", "abbc.", "bccd.", ".cd.."],
	["..ab.", ".abbc", "bbccd", ".cdd."],
]
const MASS_MAP: Array = [
	"0312405132041253",
	"2504132051423014",
	"41302.1403152402",
	"1245032140513230",
	"3051421305241035",
	"5214030524310452",
	"0432513102.50123",
	"2105342510432051",
	"4351204315023413",
	"15.3041250314520",
	"3402513042151034",
	"5130425103421250",
	"0254130254013.21",
	"2413502143502314",
	"40251430.5431052",
	"1340251304215403",
]
# [tom base, a, b, c, d] por família
const MASS_TONES: Dictionary = {
	"green": ["#1F5530", "#5A9628", "#437B25", "#2F6A2A", "#1F5530"],
	"olive": ["#1B3429", "#6E8432", "#546A29", "#3B5328", "#2B4328"],
	"cool": ["#163F3E", "#3F8650", "#2F6A48", "#245747", "#1C4948"],
}


func _leaf_mass(fam: String, mode: int) -> RefCounted:
	var cv: RefCounted = CV.new(64, 64, true, true)
	var t: Array = MASS_TONES[fam]
	cv.fill(P.hx(t[0]), 0.0)
	var map: Dictionary = {"a": [P.hx(t[1]), 1.0], "b": [P.hx(t[2]), 0.8], "c": [P.hx(t[3]), 0.5], "d": [P.hx(t[4]), 0.3]}
	for cy: int in 16:
		for cx: int in 16:
			var row: String = MASS_MAP[cy] if mode != 1 else MASS_MAP[15 - cy]
			var ch: String = row[cx] if mode != 2 else row[15 - cx]
			if mode == 1:
				ch = row[15 - cx]
			if ch == ".":
				continue
			K.stamp(cv, STAMPS[int(ch)], cx * 4 + (cy % 2) * 2, cy * 4, map)
	cv.roll(0, 2) # a emenda vertical passa pelo meio dos carimbos
	return cv


# ---------------------------------------------------------------------------
# Casca dos lóbulos: 64 x 64 com alfa. Aglomerados irregulares; tons por terço de altura.
# ---------------------------------------------------------------------------

const SHELL_SHAPES: Array = [
	["....####......", "..########.#..", ".############.", "##############", "##############", ".#############", "..###########.", "...##.#######.", ".....####.##..", ".......##....."],
	["..##.##..", ".#######.", "#########", "#########", ".########", "..######.", "...####..", "....#.#.."],
	[".#####.###..", "############", "############", ".###########", "..#########.", "....####.##.", "......##...."],
	["......####......", "...##########.##", "..##############", ".###############.", "################", "################", ".###############", "..##############", "...############.", ".....###.#####..", "......##..####..", ".........##....."],
	[".##.##.", "#######", "#######", ".######", "..####.", "...#.#."],
	["..###.###..", ".#########.", "###########", "###########", ".##########", "..#########", "....#####..", "...##..##..", "......#...."],
	[".###..", "######", "######", ".#####", "..##.#"],
	["...#####.....", ".###########.", "#############", "#############", ".############", "..####.#####.", "....##...###.", "..........#.."],
]
# [x, y, forma]: grandes, médios e pequenos, em posições irregulares
const SHELL_PLACE: Array = [
	[2, 2, 3], [32, 1, 0], [50, 13, 3], [13, 24, 0], [40, 32, 3], [2, 44, 0], [28, 48, 3], [52, 50, 0],
	[20, 12, 5], [47, 0, 7], [3, 22, 2], [28, 22, 7], [54, 30, 5], [16, 36, 2], [56, 44, 7], [12, 56, 5], [40, 52, 2],
	[0, 15, 4], [24, 36, 6], [36, 18, 1], [60, 20, 4], [22, 0, 6], [0, 32, 1], [46, 24, 6], [34, 44, 4], [8, 50, 6],
	[50, 40, 1], [62, 58, 4], [18, 28, 6], [44, 8, 4], [58, 56, 6], [10, 40, 4], [22, 60, 4],
]
# por família: [forma + d, dx, dy]
const SHELL_FAMILY: Dictionary = {
	"green": [0, 0, 4],
	"olive": [1, 5, 9],
	"cool": [3, 9, 11],
}
# [realce, claro, médio, escuro] (os 2 mais claros só no terço de cima)
const SHELL_TONES: Dictionary = {
	"green": ["#9CC230", "#76AB2A", "#5A9628", "#437B25"],
	"olive": ["#A6B04A", "#869736", "#6E8432", "#546A29"],
	"cool": ["#7CC070", "#58A758", "#3F8650", "#2F6A48"],
}
# Flores do arbusto: [índice do aglomerado, dx, dy dentro dele, cor (p = rosa, w = branca)]
const FLOWERS: Array = [[0, 8, 4, "p"], [3, 6, 4, "w"], [5, 7, 4, "p"], [10, 5, 3, "w"], [2, 6, 3, "p"], [4, 8, 4, "w"], [6, 7, 4, "p"], [7, 5, 4, "w"]]


func _leaf_shell(fam: String, flowers: bool) -> RefCounted:
	var cv: RefCounted = CV.new(64, 64, true, true)
	var f: Array = SHELL_FAMILY[fam]
	var tn: Array = SHELL_TONES[fam]
	var ids: Array[int] = []
	for tt: String in tn:
		ids.append(P.hx(tt))
	for pl: Array in SHELL_PLACE:
		var shape: Array = SHELL_SHAPES[(int(pl[2]) + int(f[0])) % 6]
		var ox: int = int(pl[0]) + int(f[1])
		var oy: int = int(pl[1]) + int(f[2])
		var hgt: int = shape.size()
		for j: int in hgt:
			var row: String = shape[j]
			var ci: int = ids[2]
			var z: float = 0.6
			if j == 0:
				ci = ids[0]
				z = 1.0
			elif j * 3 < hgt:
				ci = ids[1]
				z = 0.9
			elif j * 3 >= hgt * 2:
				ci = ids[3]
				z = 0.3
			for i: int in row.length():
				if row[i] == "#":
					cv.put(ox + i, oy + j, ci, z)
	if flowers:
		var pink: Array[int] = [P.hx("#C4506E"), P.hx("#E8829C"), P.hx("#F8B8C8")]
		var white: Array[int] = [P.hx("#D8D4C4"), P.hx("#F4F0E4"), P.hx("#FFFDF6")]
		for fl: Array in FLOWERS:
			var pl2: Array = SHELL_PLACE[int(fl[0])]
			var x: int = int(pl2[0]) + int(f[1]) + int(fl[1]) - 1
			var y: int = int(pl2[1]) + int(f[2]) + int(fl[2]) - 1
			var col: Array[int] = pink if fl[3] == "p" else white
			cv.put(x + 1, y, col[1], 1.0)
			cv.put(x, y + 1, col[1], 1.0)
			cv.put(x + 2, y + 1, col[1], 1.0)
			cv.put(x + 1, y + 2, col[0], 1.0)
			cv.put(x + 1, y + 1, col[2], 1.0)
	return cv


# ---------------------------------------------------------------------------
# Conífera: agulhas 64 x 32 (opaco, seamless na horizontal) e franja 128 x 16 (alfa)
# ---------------------------------------------------------------------------

# L = #86A83E, l = #5C8C40, m = #40743C, c = #2C5E38, b = #1F4D34, d = #0E3330
# Tufos de agulhas que caem para fora, com as pontas claras em cima
const NEEDLE_STAMPS: Array = [
	[".L.l.L.l.L.", ".mlmcmlmcm.", ".cmcbcmcbc.", "..cb.bc.bc.", "...b..b..b.", "...d..d...."],
	["L..l..L..", "mlmcmlmcm", "cmcbcmcbc", ".cb.cb.cb", "..b..b..d"],
	["L.l.....L...", "mlmcl..lmc..", ".cmcmlmcbc..", "..cbcbcb.bc.", "...b.bd..bd.", "......d...d."],
	[".L.l.L..", "lmcmlmcl", "mcbcmcbm", ".cb.bc.b", ".b..d.b."],
	["l..L..l.L.", "mcmlmcmlmc", ".bcmbcbmcb", "..b.cb.bd.", "...d..d..."],
]
# [x, y, forma]: fileiras desencontradas (as de baixo pintam por cima)
const NEEDLE_PLACE: Array = [
	[0, 0, 0], [11, 0, 3], [22, 0, 1], [35, 0, 4], [46, 0, 2], [57, 0, 0],
	[5, 5, 4], [17, 5, 2], [28, 5, 0], [40, 5, 3], [51, 5, 1], [60, 5, 4],
	[1, 11, 3], [13, 11, 0], [24, 11, 4], [34, 11, 1], [47, 11, 2], [58, 11, 3],
	[7, 17, 1], [19, 17, 4], [31, 17, 2], [42, 17, 0], [53, 17, 3], [62, 17, 1],
	[2, 23, 2], [12, 23, 1], [25, 23, 3], [37, 23, 4], [49, 23, 0], [59, 23, 2],
]


func _needles() -> RefCounted:
	var cv: RefCounted = CV.new(64, 32, true, false)
	cv.fill(P.hx("#16402F"), 0.0)
	var map: Dictionary = {
		"L": [P.hx("#86A83E"), 1.0], "l": [P.hx("#5C8C40"), 0.9], "m": [P.hx("#40743C"), 0.7],
		"c": [P.hx("#2C5E38"), 0.5], "b": [P.hx("#1F4D34"), 0.3], "d": [P.hx("#0E3330"), 0.1],
	}
	for p: Array in NEEDLE_PLACE:
		K.stamp(cv, NEEDLE_STAMPS[int(p[2])], int(p[0]), int(p[1]), map)
	return cv


# Pontas da franja: [x, largura da base, comprimento abaixo da linha 2, inclinação em px]
const FRINGE: Array = [
	[1, 5, 7, 1], [6, 4, 10, -1], [10, 5, 5, 0], [15, 6, 12, 2], [21, 4, 8, -1], [25, 5, 4, 1],
	[30, 6, 11, 0], [36, 4, 6, -2], [40, 5, 9, 1], [45, 5, 3, 0], [50, 6, 12, -1], [56, 4, 7, 2],
	[60, 5, 10, 0], [65, 5, 5, -1], [70, 6, 11, 1], [76, 4, 8, 0], [80, 5, 4, -2], [85, 6, 12, 1],
	[91, 4, 6, 0], [95, 5, 9, -1], [100, 5, 3, 2], [105, 6, 11, 0], [111, 4, 7, -1], [115, 5, 10, 1],
	[120, 5, 5, 0], [125, 5, 8, -2],
]
const FRINGE_TIPS: Array = [3, 9, 14, 21, 27, 33, 38, 44, 52, 58, 63, 69, 75, 82, 88, 94, 99, 107, 113, 119, 124]


func _fringe() -> RefCounted:
	var cv: RefCounted = CV.new(128, 16, true, false)
	var c_top: int = P.hx("#40743C")
	var c_mid: int = P.hx("#2C5E38")
	var c_low: int = P.hx("#1F4D34")
	var c_tip: int = P.hx("#16402F")
	var c_lit: int = P.hx("#5C8C40")
	for x: int in 128:
		cv.put(x, 0, c_top, 1.0)
		cv.put(x, 1, c_mid, 0.7)
		cv.put(x, 2, c_low, 0.4)
	for s: Array in FRINGE:
		var w: int = int(s[1])
		var ln: int = int(s[2])
		var lean: int = int(s[3])
		for r: int in ln:
			var cur_w: int = maxi(1, w - (w - 1) * r / maxi(ln - 1, 1))
			var off: int = lean * r / ln + (w - cur_w) / 2
			var ci: int = c_mid
			if r * 3 >= ln * 2:
				ci = c_low
			if r == ln - 1:
				ci = c_tip
			for i: int in cur_w:
				cv.put(int(s[0]) + off + i, 3 + r, ci, 0.5)
	for x: int in FRINGE_TIPS:
		cv.put(x, 0, c_lit, 1.0)
		cv.put(x + 1, 0, c_lit, 1.0)
	return cv


# ---------------------------------------------------------------------------
# Props
# ---------------------------------------------------------------------------

# a = #6B4C3E, b = #6B4C3E, c = #876547, d = #A37C56, e = #C29A6C, y = #789636, z = #8FAE48
const LOG_ROWS: Array = [
	"y5 z6 d4 y8 z9 y3 c3 y6 z7 y4 d3 z3 y3",
	"z4 y7 c3 y6 z9 d4 y5 z8 c2 y6 d4 z6",
	"y4 z6 d5 z8 y5 c6 y4 z7 d3 y7 c3 y6",
	"c5 y7 z6 d6 y5 z8 c4 z6 d5 y5 c3 c4",
	"d6 y5 z6 c8 y7 d5 z5 y6 y4 z5 d7",
	"c8 y6 d7 z5 c9 y4 d6 z5 y7 y3 c4",
	"d9 y5 c8 d6 z4 c11 y3 d9 z3 d6",
	"c12 y4 d10 c9 z3 d14 c7 y2 c3",
	"e14 d9 e12 d11 e8 e10",
	"d10 e12 d8 e15 d9 d10",
	"e9 d13 e11 d9 e14 e8",
	"d12 e8 d10 e13 d9 d12",
	"e11 d9 c4 d12 e10 d8 e10",
	"d8 e12 d10 c5 d9 e11 d9",
	"d14 c6 d9 e8 d12 c5 d10",
	"c7 d12 c9 d10 c6 d11 c9",
	"d9 c11 d8 c10 d12 c6 d8",
	"c13 d8 c9 d7 c12 d6 c9",
	"c10 d6 c14 b4 c9 d10 c11",
	"c8 b5 c12 d7 c10 b4 c10 c8",
	"c12 b6 c9 b4 c13 d5 c9 c6",
	"b8 c11 b7 c9 b10 c8 b11",
	"c9 b10 c8 b12 c7 b9 c9",
	"b12 c8 b9 c10 b14 b11",
	"b10 c9 b13 a3 b9 c8 b12",
	"c7 b14 c8 b9 a4 b10 c12",
	"b11 a5 b10 c6 b14 a4 b14",
	"b9 a8 b12 a6 b10 c5 b14",
	"a10 b12 a9 b11 a8 b14",
	"b8 a14 b9 a11 b10 a12",
	"a16 b8 a12 b10 a18",
	"a22 b6 a24 b5 a7",
]


func _log() -> RefCounted:
	var cv: RefCounted = CV.new(64, 32, true, false)
	var map: Dictionary = {
		"a": [P.hx("#6B4C3E"), 0.3], "b": [P.hx("#6B4C3E"), 0.4], "c": [P.hx("#876547"), 0.6],
		"d": [P.hx("#A37C56"), 0.8], "e": [P.hx("#C29A6C"), 1.0], "y": [P.hx("#789636"), 0.9],
		"z": [P.hx("#8FAE48"), 1.0],
	}
	for y: int in LOG_ROWS.size():
		var end_x: int = K.runs(cv, y, 0, LOG_ROWS[y], map)
		if end_x != 64:
			push_error("log_bark: linha %d soma %d" % [y, end_x])
	return cv


func _crate_side() -> RefCounted:
	var cv: RefCounted = CV.new(24, 24, false, false)
	var gap: int = P.hx("#6B4C3E")
	var edge: int = P.hx("#876547")
	var bar: int = P.hx("#A37C56")
	var wood: int = P.hx("#C29A6C")
	var lite: int = P.hx("#D9BC86")
	cv.fill(wood, 0.8)
	# 3 tábuas verticais de 8 px: fresta à esquerda de cada uma, veio claro
	for b: int in 3:
		var x0: int = b * 8
		for y: int in 24:
			cv.put(x0, y, gap, 0.1)
			cv.put(x0 + 3, y, lite if (y % 7) < 4 else wood, 0.9)
			cv.put(x0 + 5, y, edge if (y % 5) == 2 else wood, 0.7)
	# quadro externo e travessas em Z
	for i: int in 24:
		cv.put(i, 0, edge, 0.5)
		cv.put(i, 23, edge, 0.5)
		cv.put(23, i, edge, 0.5)
	for x: int in range(1, 23):
		for y: int in range(3, 7):
			cv.put(x, y, bar if y < 6 else edge, 1.0 if y < 6 else 0.6)
		for y: int in range(17, 21):
			cv.put(x, y, bar if y < 20 else edge, 1.0 if y < 20 else 0.6)
	for p: Vector2i in CV.line_pts(20, 6, 3, 17):
		for k: int in 3:
			cv.put(p.x + k - 1, p.y, bar if k < 2 else edge, 1.0 if k < 2 else 0.6)
	# pregos nas pontas das travessas
	for n: Array in [[3, 4], [20, 4], [3, 18], [20, 18]]:
		cv.put(int(n[0]), int(n[1]), edge, 0.4)
	return cv


func _crate_top() -> RefCounted:
	var cv: RefCounted = CV.new(24, 24, false, false)
	var gap: int = P.hx("#6B4C3E")
	var edge: int = P.hx("#876547")
	var wood: int = P.hx("#C29A6C")
	var lite: int = P.hx("#D9BC86")
	var bar: int = P.hx("#A37C56")
	cv.fill(wood, 0.8)
	for b: int in 3:
		var y0: int = b * 8
		for x: int in 24:
			cv.put(x, y0, gap, 0.1)
			cv.put(x, y0 + 3, lite if (x % 8) < 5 else wood, 0.9)
			cv.put(x, y0 + 6, edge if (x % 6) == 1 else wood, 0.7)
	for i: int in 24:
		for k: int in 2:
			cv.put(i, k, bar, 1.0)
			cv.put(i, 23 - k, bar, 1.0)
			cv.put(k, i, bar, 1.0)
			cv.put(23 - k, i, bar, 1.0)
	return cv


# Pilha de lenha vista da ponta: [cx, cy, raio, anéis de fora para dentro (b #6B4C3E, c #876547, d #A37C56, e #C29A6C, f #D9BC86)]
const WOOD_LOGS: Array = [
	[6, 26, 6, "bcdedee"],
	[18, 26, 6, "bcedfed"],
	[28, 27, 4, "bcdef"],
	[12, 15, 6, "bcdfdee"],
	[24, 15, 5, "bcedfe"],
	[18, 5, 5, "bcefdd"],
	[4, 9, 3, "bcdf"],
]


func _wood_pile() -> RefCounted:
	var cv: RefCounted = CV.new(32, 32, false, false)
	var col: Dictionary = {
		"b": P.hx("#6B4C3E"), "c": P.hx("#876547"), "d": P.hx("#A37C56"), "e": P.hx("#C29A6C"), "f": P.hx("#D9BC86"),
	}
	cv.fill(P.hx("#4B3339"), 0.0)
	for lg: Array in WOOD_LOGS:
		var rings: String = lg[3]
		var r: float = float(lg[2])
		var n: int = rings.length()
		for y: int in 32:
			for x: int in 32:
				var dx: float = float(x) + 0.5 - float(lg[0])
				var dy: float = float(y) + 0.5 - float(lg[1])
				var d: float = sqrt(dx * dx + dy * dy)
				if d > r:
					continue
				var k: int = mini(int(d / r * float(n)), n - 1)
				cv.put(x, y, int(col[rings[k]]), 0.5)
	return cv


func _initialize() -> void:
	for fam: String in ["green", "olive", "cool"]:
		var mode: int = 0
		if fam == "olive":
			mode = 1
		elif fam == "cool":
			mode = 2
		K.save_cv(_leaf_mass(fam, mode), "foliage/leaf_mass_" + fam, false, false)
		K.save_cv(_leaf_shell(fam, false), "foliage/leaf_shell_" + fam, false, true)
	K.save_cv(_leaf_shell("cool", true), "foliage/leaf_shell_cool_flower", false, true)
	K.save_cv(_needles(), "foliage/conifer_needles", false, false)
	K.save_cv(_fringe(), "foliage/conifer_fringe", false, true)
	K.save_cv(_log(), "props/log_bark", true, false)
	K.save_cv(_crate_side(), "props/crate_side", true, false)
	K.save_cv(_crate_top(), "props/crate_top", true, false)
	K.save_cv(_wood_pile(), "props/wood_pile_end", false, false)
	print("A06 FOLHAGEM: 9 de folhagem + 4 props gravados")
	quit(0)
