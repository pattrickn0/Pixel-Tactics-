extends SceneTree
## Checagem automática da spec A03 (docs/specs/A03-arte-minimalista.md).
## Lê os PNG do disco e mede os critérios automáticos. Uma linha por arquivo; no fim
## "A03 CHECK: PASS" (código 0) ou "A03 CHECK: FAIL (n problemas)" (código 1).
## Rodar da raiz do projeto:
##   "$G" --headless --path . --script tools/art/check_a03.gd

const P = preload("res://tools/art/palette_a03.gd")

const TEX_DIR: String = "res://assets/textures/"
const CARDS_DIR: String = "res://assets/textures/cards/"

# md5 dos cartões de runa antes da A03 (não podem mudar)
const RUNE_MD5: Dictionary = {
	"rune_0": "ad9e643e893aed717cdd60cbc72a0f00",
	"rune_1": "808b0749d24cbfcf2d73b1606721d741",
	"rune_2": "d7a1e437ed89befeac7a84ca393b12cc",
}

const DARK_SET: Array[String] = ["#1C2B2B", "#34403C", "#2E4A1E", "#496819"]

# Chão: [base, cobertura mínima do base, detalhe mín, detalhe máx, maior componente]
const GROUND: Dictionary = {
	"grass_arena_0": ["#5B9C47", 0.75, 0.03, 0.12, 6],
	"grass_arena_1": ["#5B9C47", 0.75, 0.03, 0.12, 6],
	"grass_arena_2": ["#5B9C47", 0.75, 0.03, 0.12, 6],
	"grass_arena_3": ["#5B9C47", 0.75, 0.04, 0.14, 9],
	"grass_arena_light_0": ["#73A949", 0.75, 0.03, 0.12, 6],
	"grass_arena_light_1": ["#73A949", 0.75, 0.03, 0.12, 6],
	"grass_arena_dark_0": ["#4E9343", 0.75, 0.03, 0.12, 6],
	"grass_arena_dark_1": ["#4E9343", 0.75, 0.03, 0.12, 6],
	"grass_forest_0": ["#3D853C", 0.70, 0.03, 0.15, 6],
	"grass_forest_1": ["#3D853C", 0.70, 0.03, 0.15, 6],
	"dirt_0": ["#C0AE71", 0.85, 0.02, 0.10, 6],
	"dirt_1": ["#C0AE71", 0.85, 0.02, 0.10, 6],
}

# Textura opaca: [tons mín, tons máx, famílias, topo, eixos seamless, normal map, limite de xadrez]
# (limite de xadrez: fração máxima de pixels em xadrez 2x2; -1 = não se aplica)
const TEXTURES: Dictionary = {
	"grass_arena_0": [2, 4, ["grass_arena"], true, "xy", false, 0.0],
	"grass_arena_1": [2, 4, ["grass_arena"], true, "xy", false, 0.0],
	"grass_arena_2": [2, 4, ["grass_arena"], true, "xy", false, 0.0],
	"grass_arena_3": [3, 7, ["grass_arena", "flowers"], true, "xy", false, 0.0],
	"grass_arena_light_0": [2, 4, ["grass_arena"], true, "xy", false, 0.0],
	"grass_arena_light_1": [2, 4, ["grass_arena"], true, "xy", false, 0.0],
	"grass_arena_dark_0": [2, 3, ["grass_arena"], true, "xy", false, 0.0],
	"grass_arena_dark_1": [2, 3, ["grass_arena"], true, "xy", false, 0.0],
	"grass_forest_0": [2, 4, ["grass_forest", "bark"], true, "xy", false, 0.0],
	"grass_forest_1": [2, 4, ["grass_forest", "bark"], true, "xy", false, 0.0],
	"dirt_0": [2, 3, ["dirt"], true, "xy", false, 0.0],
	"dirt_1": [2, 3, ["dirt"], true, "xy", false, 0.0],
	"stone_path_0": [4, 6, ["stone", "moss"], true, "xy", true, 0.05],
	"stone_path_1": [4, 6, ["stone", "moss"], true, "xy", true, 0.05],
	"wall_face": [5, 7, ["stone", "moss"], false, "x", true, 0.05],
	"wall_top": [4, 6, ["stone", "moss"], true, "xy", true, 0.05],
	# piso de degrau: emenda vertical medida à parte (as juntas ficam nas linhas 15 e 31, ver _check_tread)
	"stair_tread": [4, 6, ["stone", "moss", "grass_arena"], true, "x", true, 0.05],
	"stair_riser": [5, 7, ["stone", "moss"], false, "x", true, 0.05],
	"step_side": [4, 6, ["dark_earth", "stone", "moss"], false, "x", true, 0.05],
	"step_side_grass": [4, 7, ["dark_earth", "stone", "moss"], false, "x", true, 0.05],
	"rock": [4, 6, ["stone", "moss"], true, "xy", true, 0.05],
	"monolith_stone": [4, 6, ["cold_stone", "moss"], false, "xy", true, 0.05],
	"bark_0": [4, 6, ["bark", "moss"], false, "xy", true, 0.05],
	"bark_1": [3, 5, ["bark"], false, "xy", true, 0.05],
	"wood_end": [4, 6, ["bark"], false, "", true, 0.05],
	"moss": [3, 4, ["moss"], true, "xy", false, 0.05],
	"leaves_mass": [3, 5, ["leaf_green"], true, "xy", false, 0.05],
}

# Cores restritas dentro da família (subconjunto exato da tabela)
const RESTRICT: Dictionary = {
	"bark_1": ["#1A1426", "#2C212D", "#4B3339", "#6B4C3E"],
	"leaves_mass": ["#123B32", "#1F5530", "#2F6A2A", "#437B25"],
	"wood_end": ["#1A1426", "#2C212D", "#4B3339", "#6B4C3E", "#876547", "#A37C56", "#C29A6C", "#D9BC86"],
}

# Cartão: [largura, altura, tons mín, tons máx, famílias, tipo]
const CARDS: Dictionary = {
	"leaf_0": [32, 32, 4, 7, ["leaf_green"], "leaf"],
	"leaf_1": [32, 32, 4, 7, ["leaf_green"], "leaf"],
	"leaf_2": [32, 32, 4, 7, ["leaf_green"], "leaf"],
	"leaf_3": [32, 32, 4, 7, ["leaf_green"], "leaf"],
	"leaf_olive_0": [32, 32, 4, 7, ["leaf_olive"], "leaf"],
	"leaf_olive_1": [32, 32, 4, 7, ["leaf_olive"], "leaf"],
	"leaf_cool_0": [32, 32, 4, 7, ["leaf_cool"], "leaf"],
	"leaf_cool_1": [32, 32, 4, 7, ["leaf_cool"], "leaf"],
	"leaf_flower_0": [32, 32, 6, 10, ["leaf_cool", "flowers"], "leaf"],
	"conifer_tier_0": [32, 32, 4, 7, ["conifer"], "conifer"],
	"conifer_tier_1": [32, 32, 4, 7, ["conifer"], "conifer"],
	"moss_fringe_0": [32, 16, 3, 5, ["moss"], "fringe"],
	"moss_fringe_1": [32, 16, 3, 5, ["moss"], "fringe"],
	"grass_fringe_0": [32, 16, 3, 5, ["grass_forest"], "fringe"],
	"grass_fringe_1": [32, 16, 3, 5, ["grass_forest"], "fringe"],
	"grass_tuft_0": [16, 16, 2, 4, ["grass_arena"], "standing"],
	"grass_tuft_1": [16, 16, 2, 4, ["grass_arena"], "standing"],
	"grass_tuft_2": [16, 16, 2, 4, ["grass_forest"], "standing"],
	"tall_grass_0": [16, 32, 3, 4, ["grass_forest"], "standing"],
	"tall_grass_1": [16, 32, 3, 4, ["grass_forest"], "standing"],
	"flower_0": [16, 16, 3, 6, ["flowers", "grass_arena"], "standing"],
	"flower_1": [16, 16, 3, 6, ["flowers", "grass_arena"], "standing"],
	"flower_2": [16, 16, 3, 6, ["flowers", "grass_arena"], "standing"],
	"flower_3": [16, 16, 3, 6, ["flowers", "grass_arena"], "standing"],
	"mushroom_0": [16, 16, 3, 5, ["mushrooms"], "standing"],
	"mushroom_1": [16, 16, 3, 5, ["mushrooms"], "standing"],
	"mushroom_2": [16, 16, 3, 5, ["mushrooms"], "standing"],
	"mushroom_3": [16, 16, 3, 5, ["mushrooms"], "standing"],
}

var _problems: int = 0
var _dark_set: Dictionary = {}
var _files: int = 0


func _initialize() -> void:
	for hx: String in DARK_SET:
		_dark_set[P.hx(hx)] = true
	var tex: Dictionary = {}
	print("--- TEXTURAS OPACAS ---")
	for key: String in TEXTURES:
		var img: Image = _load(TEX_DIR + key + ".png", key, 32, 32)
		if img == null:
			continue
		tex[key] = img
		var nimg: Image = null
		if TEXTURES[key][5]:
			nimg = _load(TEX_DIR + key + "_n.png", key + "_n", 32, 32)
		_check_texture(key, img, nimg)
	print("--- RELAÇÕES ENTRE TEXTURAS ---")
	_check_relations(tex)
	print("--- CARTÕES ---")
	var cards: Dictionary = {}
	for key: String in CARDS:
		var spec: Array = CARDS[key]
		var img: Image = _load(CARDS_DIR + key + ".png", key, spec[0], spec[1])
		if img == null:
			continue
		cards[key] = img
		_check_card(key, img, spec)
	_check_card_pairs(cards)
	print("--- RUNAS (mantidas) ---")
	for key: String in RUNE_MD5:
		var path: String = ProjectSettings.globalize_path(CARDS_DIR + key + ".png")
		var md5: String = FileAccess.get_md5(path)
		if md5 != RUNE_MD5[key]:
			_fail(key, "md5 mudou (%s)" % md5)
		else:
			_ok(key, "md5 intacto")
	print("Arquivos A03 lidos: %d (esperado 68)" % _files)
	if _files != 68:
		_fail("total", "faltam arquivos: %d de 68" % _files)
	if _problems == 0:
		print("A03 CHECK: PASS")
		quit(0)
	else:
		print("A03 CHECK: FAIL (%d problemas)" % _problems)
		quit(1)


# ---------------------------------------------------------------------------
# Utilidades
# ---------------------------------------------------------------------------

func _load(path: String, key: String, w: int, h: int) -> Image:
	var abs_path: String = ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(abs_path):
		_fail(key, "arquivo não existe: %s" % path)
		return null
	var img: Image = Image.load_from_file(abs_path)
	if img == null:
		_fail(key, "não abriu: %s" % path)
		return null
	_files += 1
	if img.get_format() != Image.FORMAT_RGBA8:
		_fail(key, "formato não é RGBA8 (%d)" % img.get_format())
		img.convert(Image.FORMAT_RGBA8)
	if img.get_width() != w or img.get_height() != h:
		_fail(key, "tamanho %dx%d (esperado %dx%d)" % [img.get_width(), img.get_height(), w, h])
		return null
	return img


func _fail(key: String, reason: String) -> void:
	_problems += 1
	print("FAIL  %-20s | %s" % [key, reason])


func _ok(key: String, info: String) -> void:
	print("ok    %-20s | %s" % [key, info])


func _rgb(c: Color) -> int:
	return (c.r8 << 16) | (c.g8 << 8) | c.b8


func _y(c: Color) -> float:
	return 0.299 * c.r8 / 255.0 + 0.587 * c.g8 / 255.0 + 0.114 * c.b8 / 255.0


## Índice da paleta de cada pixel (-1 = transparente, -2 = fora da paleta).
func _indices(img: Image) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	out.resize(img.get_width() * img.get_height())
	for y: int in img.get_height():
		for x: int in img.get_width():
			var c: Color = img.get_pixel(x, y)
			var o: int = y * img.get_width() + x
			if c.a8 == 0:
				out[o] = -1
			else:
				out[o] = P.find(_rgb(c))
				if out[o] < 0:
					out[o] = -2
	return out


## Diferença de Y na emenda / diferença média entre vizinhos do interior. Eixo 0 = x, 1 = y.
func _seam_ratio(img: Image, axis: int, transparent_zero: bool) -> float:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var yv: PackedFloat32Array = PackedFloat32Array()
	yv.resize(w * h)
	for y: int in h:
		for x: int in w:
			var c: Color = img.get_pixel(x, y)
			yv[y * w + x] = 0.0 if (transparent_zero and c.a8 == 0) else _y(c)
	var interior: float = 0.0
	var edge: float = 0.0
	if axis == 0:
		for x: int in w - 1:
			for y: int in h:
				interior += absf(yv[y * w + x + 1] - yv[y * w + x])
		interior /= float((w - 1) * h)
		for y: int in h:
			edge += absf(yv[y * w] - yv[y * w + w - 1])
		edge /= float(h)
	else:
		for y: int in h - 1:
			for x: int in w:
				interior += absf(yv[(y + 1) * w + x] - yv[y * w + x])
		interior /= float((h - 1) * w)
		for x: int in w:
			edge += absf(yv[x] - yv[(h - 1) * w + x])
		edge /= float(w)
	if interior < 1e-6:
		return 0.0 if edge < 1e-6 else 99.0
	return edge / interior


func _pearson(a: PackedFloat32Array, b: PackedFloat32Array) -> float:
	var n: float = float(a.size())
	var ma: float = 0.0
	var mb: float = 0.0
	for i: int in a.size():
		ma += a[i]
		mb += b[i]
	ma /= n
	mb /= n
	var cov: float = 0.0
	var va: float = 0.0
	var vb: float = 0.0
	for i: int in a.size():
		cov += (a[i] - ma) * (b[i] - mb)
		va += (a[i] - ma) * (a[i] - ma)
		vb += (b[i] - mb) * (b[i] - mb)
	if va < 1e-9 or vb < 1e-9:
		return 0.0
	return cov / sqrt(va * vb)


## Fração de pixels que fazem parte de um xadrez 2x2 de dois tons (com wrap).
func _checker_frac(idx: PackedInt32Array, w: int, h: int) -> float:
	var mark: PackedByteArray = PackedByteArray()
	mark.resize(w * h)
	for y: int in h:
		for x: int in w:
			var a: int = idx[y * w + x]
			var b: int = idx[y * w + (x + 1) % w]
			var c: int = idx[((y + 1) % h) * w + x]
			var d: int = idx[((y + 1) % h) * w + (x + 1) % w]
			if a == d and b == c and a != b:
				mark[y * w + x] = 1
				mark[y * w + (x + 1) % w] = 1
				mark[((y + 1) % h) * w + x] = 1
				mark[((y + 1) % h) * w + (x + 1) % w] = 1
	var n: int = 0
	for v: int in mark:
		n += v
	return float(n) / float(w * h)


## Paleta, famílias e contagem de tons. Devolve o número de tons e acumula erros.
func _palette_check(key: String, idx: PackedInt32Array, fams: Array, errs: Array[String]) -> int:
	var tones: Dictionary = {}
	var bad: int = 0
	var wrong_fam: Dictionary = {}
	for v: int in idx:
		if v == -1:
			continue
		if v == -2:
			bad += 1
			continue
		tones[v] = true
		if not fams.has(P.family_of(v)):
			wrong_fam[P.family_of(v)] = true
	if bad > 0:
		errs.append("%d px fora da paleta" % bad)
	if not wrong_fam.is_empty():
		errs.append("famílias não permitidas: %s" % ", ".join(PackedStringArray(wrong_fam.keys())))
	if RESTRICT.has(key):
		var allowed: Dictionary = {}
		for hx: String in RESTRICT[key]:
			allowed[P.hx(hx)] = true
		for t: int in tones:
			if not allowed.has(t):
				errs.append("cor #%06X fora do subconjunto pedido" % P.rgb(t))
	return tones.size()


## Tamanhos dos componentes conexos (vizinhança 8) de pixels diferentes de 'base'.
func _components(idx: PackedInt32Array, w: int, h: int, base: int) -> Array[int]:
	var seen: PackedByteArray = PackedByteArray()
	seen.resize(w * h)
	var sizes: Array[int] = []
	for y: int in h:
		for x: int in w:
			if seen[y * w + x] != 0 or idx[y * w + x] == base:
				continue
			var stack: Array[Vector2i] = [Vector2i(x, y)]
			seen[y * w + x] = 1
			var n: int = 0
			while not stack.is_empty():
				var p: Vector2i = stack.pop_back()
				n += 1
				for j: int in range(-1, 2):
					for i: int in range(-1, 2):
						var q: Vector2i = p + Vector2i(i, j)
						if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h:
							continue
						if seen[q.y * w + q.x] == 0 and idx[q.y * w + q.x] != base:
							seen[q.y * w + q.x] = 1
							stack.append(q)
			sizes.append(n)
	return sizes


# ---------------------------------------------------------------------------
# Texturas opacas
# ---------------------------------------------------------------------------

func _check_texture(key: String, img: Image, nimg: Image) -> void:
	var spec: Array = TEXTURES[key]
	var errs: Array[String] = []
	var info: Array[String] = []
	var w: int = 32
	var h: int = 32
	var idx: PackedInt32Array = _indices(img)
	for v: int in idx:
		if v == -1:
			errs.append("alfa != 255")
			break
	var nt: int = _palette_check(key, idx, spec[2], errs)
	info.append("tons %d" % nt)
	if nt < spec[0] or nt > spec[1]:
		errs.append("tons %d fora de %d..%d" % [nt, spec[0], spec[1]])
	# gradiente global
	var yl: float = 0.0
	var yr: float = 0.0
	var yt: float = 0.0
	var yb: float = 0.0
	var ys: PackedFloat32Array = PackedFloat32Array()
	for y: int in h:
		for x: int in w:
			var yy: float = _y(img.get_pixel(x, y))
			ys.append(yy)
			if x < 16:
				yl += yy
			else:
				yr += yy
			if y < 16:
				yt += yy
			else:
				yb += yy
	var dlr: float = absf(yl - yr) / 512.0
	var dtb: float = absf(yt - yb) / 512.0
	if dlr > 0.04:
		errs.append("gradiente E/D %.3f" % dlr)
	if spec[3] and dtb > 0.04:
		errs.append("gradiente C/B %.3f" % dtb)
	# emenda
	var seam: String = spec[4]
	var seams: Array[String] = []
	for ax: int in 2:
		if seam.find("xy"[ax]) < 0:
			continue
		var r: float = _seam_ratio(img, ax, false)
		seams.append("%s %.2f" % ["xy"[ax], r])
		if r > 1.3:
			errs.append("emenda %s: %.2f > 1,3" % ["xy"[ax], r])
		if nimg != null:
			var rn: float = _seam_ratio(nimg, ax, false)
			seams.append("n%s %.2f" % ["xy"[ax], rn])
			if rn > 1.3:
				errs.append("emenda do normal %s: %.2f > 1,3" % ["xy"[ax], rn])
	if not seams.is_empty():
		info.append("emenda " + " ".join(seams))
	# xadrez
	var chk: float = _checker_frac(idx, w, h)
	if spec[6] >= 0.0 and chk > spec[6] + 1e-6:
		errs.append("xadrez %.1f%%" % (chk * 100.0))
	# chão minimalista
	if GROUND.has(key):
		var g: Array = GROUND[key]
		var base: int = P.hx(g[0])
		var nb: int = 0
		for v: int in idx:
			if v == base:
				nb += 1
		var cov: float = float(nb) / 1024.0
		var det: float = 1.0 - cov
		info.append("base %.1f%% detalhe %.1f%%" % [cov * 100.0, det * 100.0])
		if cov < g[1]:
			errs.append("cobertura do base %.1f%% < %.0f%%" % [cov * 100.0, g[1] * 100.0])
		if det < g[2] - 1e-6 or det > g[3] + 1e-6:
			errs.append("detalhe %.1f%% fora de %.0f..%.0f%%" % [det * 100.0, g[2] * 100.0, g[3] * 100.0])
		for i: int in 32:
			for p: Vector2i in [Vector2i(i, 0), Vector2i(i, 31), Vector2i(0, i), Vector2i(31, i)]:
				if idx[p.y * 32 + p.x] != base:
					errs.append("borda fora do base em (%d,%d)" % [p.x, p.y])
					break
		var comps: Array[int] = _components(idx, w, h, base)
		if not comps.is_empty():
			info.append("clusters %d..%d (n=%d)" % [comps.min(), comps.max(), comps.size()])
			if comps.min() < 2 or comps.max() > g[4]:
				errs.append("cluster fora de 2..%d (%d..%d)" % [g[4], comps.min(), comps.max()])
		if key.begins_with("grass_forest"):
			var litter: int = 0
			for v: int in idx:
				if v == P.hx("#876547"):
					litter += 1
			if litter > 30:
				errs.append("folhinha caída %d px > 3%%" % litter)
	# juntas e musgo
	var moss_n: int = 0
	var stone_dark: int = 0
	var j_mid: int = 0
	var j_cross: int = 0
	for v: int in idx:
		if v >= 0 and P.family_of(v) == "moss":
			moss_n += 1
		if v == P.hx("#34403C") or v == P.hx("#1C2B2B"):
			stone_dark += 1
		if v == P.hx("#7A7A66"):
			j_mid += 1
		if v == P.hx("#5C6250"):
			j_cross += 1
	if key.begins_with("stone_path"):
		# calçamento: juntas em #7A7A66, #5C6250 só nos cruzamentos, musgo; sem junta escura
		var jf: float = float(j_mid + j_cross + moss_n) / 1024.0
		var xf: float = float(j_cross) / 1024.0
		info.append("juntas %.1f%% (cruzamentos %.1f%%)" % [jf * 100.0, xf * 100.0])
		if jf < 0.10 or jf > 0.20:
			errs.append("juntas %.1f%% fora de 10..20%%" % (jf * 100.0))
		if xf > 0.04:
			errs.append("#5C6250 em %.1f%% > 4%%" % (xf * 100.0))
		if stone_dark > 0:
			errs.append("%d px em #34403C/#1C2B2B (junta escura vira contorno)" % stone_dark)
	if key == "wall_face":
		var mf: float = float(moss_n) / 1024.0
		info.append("musgo %.1f%%" % (mf * 100.0))
		if mf < 0.05 or mf > 0.20:
			errs.append("musgo %.1f%% fora de 5..20%%" % (mf * 100.0))
		for row: int in [15, 31]:
			var f: float = _dark_row(idx, row)
			if f < 0.6:
				errs.append("linha %d com %.0f%% escuro < 60%%" % [row, f * 100.0])
		for band: int in 2:
			var n_rows: int = 0
			for row: int in range(band * 16, band * 16 + 15):
				if _dark_row(idx, row) >= 0.4:
					n_rows += 1
			if n_rows < 2:
				errs.append("faixa %s com %d linhas internas de junta (< 2)" % ["AB"[band], n_rows])
	if key == "stair_riser":
		for row: int in [7, 15, 23, 31]:
			var f: float = _dark_row(idx, row)
			if f < 0.6:
				errs.append("linha %d com %.0f%% escuro < 60%%" % [row, f * 100.0])
		# nariz claro em cima de cada faixa; junta vertical nunca em #34403C
		var noses: Array[String] = []
		for row: int in [0, 8, 16, 24]:
			var f: float = _row_frac(idx, row, ["#B9B597", "#D3CCB4"])
			noses.append("%.0f" % (f * 100.0))
			if f < 0.7:
				errs.append("nariz (linha %d) com %.0f%% claro < 70%%" % [row, f * 100.0])
			for y: int in range(row, row + 7):
				if _row_frac(idx, y, ["#34403C", "#1C2B2B"]) > 0.0:
					errs.append("junta escura dentro da faixa (linha %d)" % y)
					break
		info.append("nariz %s%%" % "/".join(PackedStringArray(noses)))
	if key == "stair_tread":
		_check_tread(img, nimg, idx, errs, info)
	if key == "wall_top":
		var mf: float = float(moss_n) / 1024.0
		info.append("musgo %.1f%%" % (mf * 100.0))
		if mf < 0.5:
			errs.append("musgo %.1f%% < 50%%" % (mf * 100.0))
		_check_wall_top(idx, errs, info)
	# normal map
	if nimg != null:
		var nx: PackedFloat32Array = PackedFloat32Array()
		var ny: PackedFloat32Array = PackedFloat32Array()
		var sx: float = 0.0
		var sy: float = 0.0
		var sz: float = 0.0
		var low: int = 0
		var bad_len: int = 0
		var bad_z: int = 0
		for y: int in h:
			for x: int in w:
				var c: Color = nimg.get_pixel(x, y)
				if c.a8 != 255:
					errs.append("normal com alfa != 255")
				var v: Vector3 = Vector3(c.r8 / 255.0 * 2.0 - 1.0, c.g8 / 255.0 * 2.0 - 1.0, c.b8 / 255.0 * 2.0 - 1.0)
				if absf(v.length() - 1.0) > 0.06:
					bad_len += 1
				if v.z < 0.6:
					bad_z += 1
				if v.z < 0.98:
					low += 1
				sx += v.x
				sy += v.y
				sz += v.z
				nx.append(v.x)
				ny.append(v.y)
		sx /= 1024.0
		sy /= 1024.0
		sz /= 1024.0
		var lowf: float = float(low) / 1024.0
		var px: float = _pearson(ys, nx)
		var py: float = _pearson(ys, ny)
		info.append("N: z %.3f relevo %.0f%% corr x %.2f y %.2f" % [sz, lowf * 100.0, px, py])
		if bad_len > 0:
			errs.append("normal com comprimento fora de 1±0,06 em %d px" % bad_len)
		if bad_z > 0:
			errs.append("normal com Z < 0,6 em %d px" % bad_z)
		if absf(sx) > 0.05 or absf(sy) > 0.05:
			errs.append("média do normal x %.3f y %.3f fora de ±0,05" % [sx, sy])
		if sz < 0.9:
			errs.append("Z médio %.3f < 0,9" % sz)
		if lowf < 0.15:
			errs.append("relevo: só %.0f%% com Z < 0,98" % (lowf * 100.0))
		if absf(px) > 0.2:
			errs.append("luz lateral: corr(Y, nx) = %.2f" % px)
		if (spec[3] or key == "rock") and absf(py) > 0.2:
			errs.append("luz pintada: corr(Y, ny) = %.2f" % py)
	if errs.is_empty():
		_ok(key, ", ".join(info))
	else:
		_fail(key, "; ".join(errs) + "  [" + ", ".join(info) + "]")


## Fração da linha nas cores dadas.
func _row_frac(idx: PackedInt32Array, row: int, hexes: Array) -> float:
	var allowed: Dictionary = {}
	for hx: String in hexes:
		allowed[P.hx(hx)] = true
	var n: int = 0
	for x: int in 32:
		if allowed.has(idx[row * 32 + x]):
			n += 1
	return float(n) / 32.0


## Piso de degrau: junta nas linhas 15 e 31, nariz claro nas linhas 0 e 16, musgo e grama de 4% a 8%.
## Emenda vertical: o par 31 -> 0 não destoa do par 15 -> 16 (a mesma passagem junta -> nariz).
func _check_tread(img: Image, nimg: Image, idx: PackedInt32Array, errs: Array[String], info: Array[String]) -> void:
	for row: int in [15, 31]:
		var f: float = _row_frac(idx, row, ["#7A7A66", "#5C6250", "#789636", "#5E7C26", "#73A949"])
		if f < 0.9:
			errs.append("linha %d com %.0f%% de junta < 90%%" % [row, f * 100.0])
	for row: int in [0, 16]:
		var f: float = _row_frac(idx, row, ["#D3CCB4"])
		if f < 0.6:
			errs.append("nariz (linha %d) com %.0f%% #D3CCB4 < 60%%" % [row, f * 100.0])
	var green: int = 0
	for v: int in idx:
		if v >= 0 and (P.family_of(v) == "moss" or P.family_of(v) == "grass_arena"):
			green += 1
	var gf: float = float(green) / 1024.0
	info.append("musgo+grama %.1f%%" % (gf * 100.0))
	if gf < 0.04 or gf > 0.08:
		errs.append("musgo+grama %.1f%% fora de 4..8%%" % (gf * 100.0))
	for im: Image in [img, nimg]:
		if im == null:
			continue
		var edge: float = 0.0
		var mid: float = 0.0
		for x: int in 32:
			edge += absf(_y(im.get_pixel(x, 0)) - _y(im.get_pixel(x, 31)))
			mid += absf(_y(im.get_pixel(x, 16)) - _y(im.get_pixel(x, 15)))
		var r: float = edge / maxf(mid, 1e-6)
		info.append("emenda y/faixa %.2f" % r)
		if r > 1.3:
			errs.append("emenda y %.2f > 1,3 vez a passagem 15 -> 16" % r)


## Topo do muro: elementos claros (pedra e musgo claro) maiores que 2x2 aparecem no máximo 3 vezes;
## 2 a 3 falhas de pedra.
func _check_wall_top(idx: PackedInt32Array, errs: Array[String], info: Array[String]) -> void:
	var light: Dictionary = {P.hx("#B9B597"): true, P.hx("#D3CCB4"): true, P.hx("#989680"): true, P.hx("#8FAE48"): true}
	var stone: Dictionary = {P.hx("#B9B597"): true, P.hx("#D3CCB4"): true}
	var seen: PackedByteArray = PackedByteArray()
	seen.resize(1024)
	var big: int = 0
	var stones: int = 0
	for y0: int in 32:
		for x0: int in 32:
			if seen[y0 * 32 + x0] != 0 or not light.has(idx[y0 * 32 + x0]):
				continue
			var stack: Array[Vector2i] = [Vector2i(x0, y0)]
			seen[y0 * 32 + x0] = 1
			var mn: Vector2i = Vector2i(x0, y0)
			var mx: Vector2i = Vector2i(x0, y0)
			var has_stone: bool = false
			while not stack.is_empty():
				var p: Vector2i = stack.pop_back()
				mn = Vector2i(mini(mn.x, p.x), mini(mn.y, p.y))
				mx = Vector2i(maxi(mx.x, p.x), maxi(mx.y, p.y))
				if stone.has(idx[p.y * 32 + p.x]):
					has_stone = true
				for j: int in range(-1, 2):
					for i: int in range(-1, 2):
						var q: Vector2i = p + Vector2i(i, j)
						if q.x < 0 or q.y < 0 or q.x > 31 or q.y > 31:
							continue
						var o: int = q.y * 32 + q.x
						if seen[o] == 0 and light.has(idx[o]):
							seen[o] = 1
							stack.append(q)
			if mx.x - mn.x + 1 > 2 or mx.y - mn.y + 1 > 2:
				big += 1
			if has_stone:
				stones += 1
	info.append("pedras %d, claros > 2x2: %d" % [stones, big])
	if big > 3:
		errs.append("%d elementos claros maiores que 2x2 (> 3)" % big)
	if stones < 2 or stones > 3:
		errs.append("%d falhas de pedra (esperado 2..3)" % stones)


func _dark_row(idx: PackedInt32Array, row: int) -> float:
	var n: int = 0
	for x: int in 32:
		if _dark_set.has(idx[row * 32 + x]):
			n += 1
	return float(n) / 32.0


func _check_relations(tex: Dictionary) -> void:
	if tex.has("step_side") and tex.has("step_side_grass"):
		var a: Image = tex["step_side"]
		var b: Image = tex["step_side_grass"]
		var diff: int = 0
		for y: int in range(16, 32):
			for x: int in 32:
				if a.get_pixel(x, y) != b.get_pixel(x, y):
					diff += 1
		if diff > 0:
			_fail("step_side_grass", "linhas 16..31 diferem de step_side em %d px" % diff)
		else:
			_ok("step_side_grass", "linhas 16..31 idênticas a step_side")
	if tex.has("stone_path_0") and tex.has("stone_path_1"):
		var a: Image = tex["stone_path_0"]
		var b: Image = tex["stone_path_1"]
		var diff: int = 0
		var inner: int = 0
		for y: int in 32:
			for x: int in 32:
				var same: bool = a.get_pixel(x, y) == b.get_pixel(x, y)
				if x < 2 or y < 2 or x >= 30 or y >= 30:
					if not same:
						diff += 1
				elif not same:
					inner += 1
		if diff > 0:
			_fail("stone_path_1", "faixa de 2 px difere da variante 0 em %d px" % diff)
		elif inner < 40:
			_fail("stone_path_1", "variante quase igual à 0 (%d px diferentes)" % inner)
		else:
			_ok("stone_path_1", "faixa de 2 px igual à variante 0; miolo difere em %d px" % inner)


# ---------------------------------------------------------------------------
# Cartões
# ---------------------------------------------------------------------------

func _check_card(key: String, img: Image, spec: Array) -> void:
	var errs: Array[String] = []
	var info: Array[String] = []
	var w: int = img.get_width()
	var h: int = img.get_height()
	var kind: String = spec[5]
	var seamless: bool = kind == "conifer" or kind == "fringe"
	for y: int in h:
		for x: int in w:
			var a: int = img.get_pixel(x, y).a8
			if a != 0 and a != 255:
				errs.append("alfa não binário em (%d,%d)" % [x, y])
				break
	var idx: PackedInt32Array = _indices(img)
	var nt: int = _palette_check(key, idx, spec[4], errs)
	info.append("tons %d" % nt)
	if nt < spec[2] or nt > spec[3]:
		errs.append("tons %d fora de %d..%d" % [nt, spec[2], spec[3]])
	var opaque: int = 0
	for v: int in idx:
		if v != -1:
			opaque += 1
	var opq: Callable = func(x: int, y: int) -> bool:
		if y < 0 or y >= h:
			return false
		if seamless:
			x = posmod(x, w)
		elif x < 0 or x >= w:
			return false
		return idx[y * w + x] != -1
	var row_frac: Callable = func(y: int) -> float:
		var n: int = 0
		for x: int in w:
			if idx[y * w + x] != -1:
				n += 1
		return float(n) / float(w)
	match kind:
		"leaf":
			var cov: float = float(opaque) / float(w * h)
			info.append("cobertura %.0f%%" % (cov * 100.0))
			if cov < 0.45 or cov > 0.80:
				errs.append("cobertura %.0f%% fora de 45..80%%" % (cov * 100.0))
			_check_leaf_light(idx, w, h, opaque, spec[4][0], errs, info)
			for i: int in 32:
				if opq.call(i, 0) or opq.call(i, 31) or opq.call(0, i) or opq.call(31, i):
					errs.append("margem de 1 px ocupada")
					break
		"conifer":
			for y: int in 14:
				if row_frac.call(y) < 1.0:
					errs.append("linha %d não está cheia" % y)
					break
			if row_frac.call(31) > 0.25:
				errs.append("linha 31 com %.0f%% opaco" % (row_frac.call(31) * 100.0))
			var runs: int = _runs(idx, w, 20)
			info.append("dentes na linha 20: %d" % runs)
			if runs < 4 or runs > 7:
				errs.append("linha 20 com %d trechos (esperado 4..7)" % runs)
		"fringe":
			for y: int in 3:
				if row_frac.call(y) < 1.0:
					errs.append("linha %d não está cheia" % y)
					break
			if row_frac.call(15) > 0.15:
				errs.append("linha 15 com %.0f%% opaco" % (row_frac.call(15) * 100.0))
		"standing":
			for x: int in w:
				if opq.call(x, 0):
					errs.append("linha 0 ocupada")
					break
			for y: int in h:
				if opq.call(0, y) or opq.call(w - 1, y):
					errs.append("coluna 0 ou %d ocupada" % (w - 1))
					break
			var n_last: int = 0
			var sum_x: float = 0.0
			for x: int in w:
				if opq.call(x, h - 1):
					n_last += 1
					sum_x += x
			if n_last < 2:
				errs.append("última linha com %d px opacos (< 2)" % n_last)
			else:
				var mid: float = sum_x / n_last
				info.append("base em x %.1f" % mid)
				if absf(mid - (w - 1) * 0.5) > 2.0:
					errs.append("base fora do centro (x médio %.1f)" % mid)
	if seamless:
		var r: float = _seam_ratio(img, 0, true)
		info.append("emenda x %.2f" % r)
		if r > 1.3:
			errs.append("emenda x %.2f > 1,3" % r)
	# sem contorno
	var sum_all: float = 0.0
	var sum_top: float = 0.0
	var n_top: int = 0
	var n_border: int = 0
	var n_border_dark: int = 0
	var darkest: Dictionary = {}
	for fam: String in spec[4]:
		for i: int in P.darkest_of_family(fam, 2):
			darkest[i] = true
	for y: int in h:
		for x: int in w:
			var v: int = idx[y * w + x]
			if v < 0:
				continue
			var yy: float = P.luma(v)
			sum_all += yy
			if y > 0 and not opq.call(x, y - 1):
				sum_top += yy
				n_top += 1
			var border: bool = false
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var qx: int = x + d.x
				var qy: int = y + d.y
				if qy < 0 or qy >= h:
					continue
				if not seamless and (qx < 0 or qx >= w):
					continue
				if not opq.call(qx, qy):
					border = true
			if border:
				n_border += 1
				if darkest.has(v):
					n_border_dark += 1
	if opaque > 0:
		var mean_all: float = sum_all / opaque
		if n_top > 0:
			var mean_top: float = sum_top / n_top
			info.append("topo %.2f >= média %.2f" % [mean_top, mean_all])
			if mean_top < mean_all - 1e-6:
				errs.append("borda de cima mais escura que a média (%.3f < %.3f)" % [mean_top, mean_all])
		if n_border > 0:
			var fd: float = float(n_border_dark) / float(n_border)
			info.append("borda escura %.0f%%" % (fd * 100.0))
			if fd > 0.30:
				errs.append("borda nos 2 tons mais escuros: %.0f%% > 30%%" % (fd * 100.0))
	if errs.is_empty():
		_ok(key, ", ".join(info))
	else:
		_fail(key, "; ".join(errs) + "  [" + ", ".join(info) + "]")


## Luz da folhagem (revisão 1 da A03): os 2 tons mais claros da família somam no máximo 12%
## dos pixels opacos e o mais claro no máximo 4% (e só na metade de cima do cartão);
## os 3 tons mais escuros usados da família somam 30% ou mais.
func _check_leaf_light(idx: PackedInt32Array, w: int, h: int, opaque: int, fam: String, errs: Array[String], info: Array[String]) -> void:
	var ramp: Array[int] = []
	for i: int in P.count():
		if P.family_of(i) == fam:
			ramp.append(i)
	ramp.sort_custom(func(a: int, b: int) -> bool: return P.luma(a) < P.luma(b))
	var cnt: Dictionary = {}
	var low_lightest: int = 0
	for y: int in h:
		for x: int in w:
			var v: int = idx[y * w + x]
			if v < 0:
				continue
			cnt[v] = int(cnt.get(v, 0)) + 1
			if v == ramp[ramp.size() - 1] and y >= h / 2:
				low_lightest += 1
	var l1: float = float(cnt.get(ramp[ramp.size() - 1], 0)) / opaque
	var l2: float = l1 + float(cnt.get(ramp[ramp.size() - 2], 0)) / opaque
	var used: Array[int] = []
	for i: int in ramp:
		if cnt.has(i):
			used.append(i)
	var d3: int = 0
	for i: int in mini(3, used.size()):
		d3 += int(cnt[used[i]])
	var df: float = float(d3) / opaque
	info.append("luz 2 tons %.1f%% / 1 tom %.1f%%, escuros %.0f%%" % [l2 * 100.0, l1 * 100.0, df * 100.0])
	if l2 > 0.12 + 1e-6:
		errs.append("2 tons mais claros em %.1f%% > 12%%" % (l2 * 100.0))
	if l1 > 0.04 + 1e-6:
		errs.append("tom mais claro em %.1f%% > 4%%" % (l1 * 100.0))
	if low_lightest > 0:
		errs.append("tom mais claro na metade de baixo (%d px)" % low_lightest)
	if df < 0.30:
		errs.append("3 tons mais escuros em %.0f%% < 30%%" % (df * 100.0))


## Trechos opacos separados numa linha (circular).
func _runs(idx: PackedInt32Array, w: int, row: int) -> int:
	var n: int = 0
	for x: int in w:
		var here: bool = idx[row * w + x] != -1
		var prev: bool = idx[row * w + posmod(x - 1, w)] != -1
		if here and not prev:
			n += 1
	if n == 0:
		var full: bool = idx[row * w] != -1
		return 1 if full else 0
	return n


func _check_card_pairs(cards: Dictionary) -> void:
	for pair: Array in [["conifer_tier_0", "conifer_tier_1"], ["moss_fringe_0", "moss_fringe_1"], ["grass_fringe_0", "grass_fringe_1"]]:
		if not cards.has(pair[0]) or not cards.has(pair[1]):
			continue
		var a: Image = cards[pair[0]]
		var b: Image = cards[pair[1]]
		var diff: int = 0
		var inner: int = 0
		for y: int in a.get_height():
			for x: int in 32:
				var same: bool = a.get_pixel(x, y) == b.get_pixel(x, y)
				if x in [0, 1, 30, 31]:
					if not same:
						diff += 1
				elif not same:
					inner += 1
		if diff > 0:
			_fail(pair[1], "colunas 0, 1, 30, 31 diferem de %s em %d px" % [pair[0], diff])
		elif inner < 20:
			_fail(pair[1], "variante quase igual a %s" % pair[0])
		else:
			_ok(pair[1], "colunas 0, 1, 30, 31 iguais a %s" % pair[0])
