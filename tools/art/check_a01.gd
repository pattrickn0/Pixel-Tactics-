extends SceneTree
## Verifica os critérios automáticos da spec A01 nos PNG de assets/ (lidos do disco, sem depender do import).
## Rodar da raiz do projeto:
##   "$G" --headless --path . --script tools/art/check_a01.gd
## Imprime uma linha por arquivo e, no fim, "A01 CHECK: PASS" ou "A01 CHECK: FAIL (n problemas)". Sai com 0/1.

const P = preload("res://tools/art/palette.gd")

const TEX_DIR: String = "res://assets/textures/"
const SPR_DIR: String = "res://assets/sprites/"
const BAND: int = 3

# Textura -> máximo de cores distintas
const TEXTURES: Dictionary = {
	"grass_arena_0": 6, "grass_arena_1": 6, "grass_arena_2": 6, "grass_arena_3": 6,
	"grass_forest_0": 5, "grass_forest_1": 5,
	"dirt_0": 7, "dirt_1": 7,
	"ruin_tile": 8, "step_side": 7, "step_side_grass": 10,
	"wall_face": 8, "wall_top": 8, "rock": 6,
}

# Sprite -> [largura, altura, desenho min L, max L, min A, max A, máximo de cores]
const SPRITES: Dictionary = {
	"tree_big_0": [96, 128, 64, 94, 96, 127, 12],
	"tree_big_1": [96, 128, 64, 94, 96, 127, 12],
	"tree_big_2": [96, 128, 64, 94, 96, 127, 12],
	"tree_small_0": [64, 96, 48, 62, 64, 95, 12],
	"tree_small_1": [64, 96, 48, 62, 64, 95, 12],
	"bush_0": [32, 32, 20, 30, 16, 30, 9],
	"bush_1": [32, 32, 20, 30, 16, 30, 9],
	"bush_2": [32, 32, 20, 30, 16, 30, 9],
	"grass_tuft_0": [16, 16, 8, 14, 6, 14, 5],
	"grass_tuft_1": [16, 16, 8, 14, 6, 14, 5],
	"grass_tuft_2": [16, 16, 8, 14, 6, 14, 5],
	"flower_0": [16, 16, 8, 14, 8, 14, 7],
	"flower_1": [16, 16, 8, 14, 8, 14, 7],
	"flower_2": [16, 16, 8, 14, 8, 14, 7],
	"monolith_0": [32, 96, 20, 30, 80, 95, 12],
	"monolith_1": [32, 64, 20, 30, 48, 63, 12],
}

# Máscara -> [sprite de origem, número de regiões de runa]
const MASKS: Dictionary = {
	"monolith_0_rune": ["monolith_0", 2],
	"monolith_1_rune": ["monolith_1", 1],
}

const FAMILIES: Array = [
	["grass_arena_0", "grass_arena_1", "grass_arena_2", "grass_arena_3"],
	["grass_forest_0", "grass_forest_1"],
	["dirt_0", "dirt_1"],
]

var _palette: Dictionary = {}
var _outline: Dictionary = {}
var _rune: Dictionary = {}
var _grass: Dictionary = {}
var _problems: int = 0


func _initialize() -> void:
	for c: Color in P.ALL:
		_palette[c.to_rgba32()] = true
	for c: Color in P.OUTLINE_LIKE:
		_outline[c.to_rgba32()] = true
	for c: Color in P.RUNE:
		_rune[c.to_rgba32()] = true
	for c: Color in [P.GRASS_0, P.GRASS_1, P.GRASS_2, P.GRASS_3]:
		_grass[c.to_rgba32()] = true
	var images: Dictionary = {}
	for key: String in TEXTURES:
		images[key] = _check_texture(key)
	for key: String in SPRITES:
		images[key] = _check_sprite(key)
	for key: String in MASKS:
		_check_mask(key, images)
	for fam: Array in FAMILIES:
		_check_family(fam, images)
	_check_step_grass(images)
	if _problems == 0:
		print("A01 CHECK: PASS")
		quit(0)
	else:
		print("A01 CHECK: FAIL (%d problemas)" % _problems)
		quit(1)


func _load(path: String) -> Image:
	var abs_path: String = ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(abs_path):
		return null
	return Image.load_from_file(abs_path)


func _report(key: String, errors: Array[String], info: String) -> void:
	if errors.is_empty():
		print("OK    %-18s %s" % [key, info])
	else:
		_problems += errors.size()
		print("FAIL  %-18s %s | %s" % [key, info, "; ".join(errors)])


func _px(img: Image, x: int, y: int) -> int:
	return img.get_pixel(x, y).to_rgba32()


func _alpha(img: Image, x: int, y: int) -> int:
	return int(round(img.get_pixel(x, y).a * 255.0))


# Cores opacas fora da paleta, alfas não binários, cores distintas
func _common(img: Image, errors: Array[String], max_colors: int, require_opaque: bool) -> Dictionary:
	var colors: Dictionary = {}
	var bad_pal: int = 0
	var bad_alpha: int = 0
	for y: int in img.get_height():
		for x: int in img.get_width():
			var a: int = _alpha(img, x, y)
			if require_opaque and a != 255:
				bad_alpha += 1
			elif a != 0 and a != 255:
				bad_alpha += 1
			if a == 255:
				var k: int = _px(img, x, y)
				colors[k] = true
				if not _palette.has(k):
					bad_pal += 1
	if bad_pal > 0:
		errors.append("%d px fora da paleta" % bad_pal)
	if bad_alpha > 0:
		errors.append("%d px com alfa invalido" % bad_alpha)
	if max_colors > 0 and colors.size() > max_colors:
		errors.append("%d cores (max %d)" % [colors.size(), max_colors])
	return colors


# Pixels opacos sem vizinho-8 da mesma cor
func _orphans(img: Image, wrap: bool) -> Vector2i:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var orphans: int = 0
	var opaque: int = 0
	for y: int in h:
		for x: int in w:
			if _alpha(img, x, y) != 255:
				continue
			opaque += 1
			var k: int = _px(img, x, y)
			var alone: bool = true
			for dy: int in range(-1, 2):
				for dx: int in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					var nx: int = x + dx
					var ny: int = y + dy
					if wrap:
						nx = posmod(nx, w)
						ny = posmod(ny, h)
					elif nx < 0 or ny < 0 or nx >= w or ny >= h:
						continue
					if _alpha(img, nx, ny) == 255 and _px(img, nx, ny) == k:
						alone = false
			if alone:
				orphans += 1
	return Vector2i(orphans, opaque)


func _luma(c: Color) -> float:
	return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b


func _check_texture(key: String) -> Image:
	var errors: Array[String] = []
	var img: Image = _load(TEX_DIR + key + ".png")
	if img == null:
		_fail(key, "arquivo ausente")
		return null
	if img.get_width() != 32 or img.get_height() != 32:
		errors.append("tamanho %dx%d (esperado 32x32)" % [img.get_width(), img.get_height()])
	if img.get_format() != Image.FORMAT_RGBA8:
		errors.append("formato %d (esperado RGBA8)" % img.get_format())
		img.convert(Image.FORMAT_RGBA8)
	var colors: Dictionary = _common(img, errors, TEXTURES[key], true)
	var orph: Vector2i = _orphans(img, true)
	var orph_pct: float = 100.0 * orph.x / maxf(1.0, orph.y)
	if orph_pct > 3.0:
		errors.append("orfaos %.1f%% (max 3%%)" % orph_pct)
	# Gradiente global: metades esquerda/direita e cima/baixo
	var l: float = 0.0
	var r: float = 0.0
	var t: float = 0.0
	var b: float = 0.0
	for y: int in 32:
		for x: int in 32:
			var v: float = _luma(img.get_pixel(x, y))
			if x < 16:
				l += v
			else:
				r += v
			if y < 16:
				t += v
			else:
				b += v
	var dlr: float = absf(l - r) / 512.0
	var dtb: float = absf(t - b) / 512.0
	if dlr > 0.06:
		errors.append("luma esq/dir %.3f (max 0.06)" % dlr)
	if dtb > 0.06 and key != "step_side_grass":
		errors.append("luma cima/baixo %.3f (max 0.06)" % dtb)
	_report(key, errors, "32x32 cores=%d orfaos=%.1f%% luma=%.3f/%.3f" % [colors.size(), orph_pct, dlr, dtb])
	return img


func _check_sprite(key: String) -> Image:
	var spec: Array = SPRITES[key]
	var errors: Array[String] = []
	var img: Image = _load(SPR_DIR + key + ".png")
	if img == null:
		_fail(key, "arquivo ausente")
		return null
	var w: int = img.get_width()
	var h: int = img.get_height()
	if w != spec[0] or h != spec[1]:
		errors.append("tamanho %dx%d (esperado %dx%d)" % [w, h, spec[0], spec[1]])
	if img.get_format() != Image.FORMAT_RGBA8:
		errors.append("formato %d (esperado RGBA8)" % img.get_format())
		img.convert(Image.FORMAT_RGBA8)
	var colors: Dictionary = _common(img, errors, spec[6], false)
	# Bordas livres
	for x: int in w:
		if _alpha(img, x, 0) != 0:
			errors.append("primeira linha nao transparente")
			break
	for y: int in h:
		if _alpha(img, 0, y) != 0 or _alpha(img, w - 1, y) != 0:
			errors.append("coluna lateral nao transparente")
			break
	# Base na última linha, centralizada
	var min_x: int = w
	var max_x: int = -1
	var count: int = 0
	for x: int in w:
		if _alpha(img, x, h - 1) == 255:
			count += 1
			min_x = mini(min_x, x)
			max_x = maxi(max_x, x)
	var base_off: float = 99.0
	if count < 2:
		errors.append("ultima linha com %d px opacos (min 2)" % count)
	else:
		base_off = absf((min_x + max_x + 1) / 2.0 - w / 2.0)
		if base_off > 2.0:
			errors.append("base fora do centro (%.1f px)" % base_off)
	# Caixa do desenho
	var bx0: int = w
	var by0: int = h
	var bx1: int = -1
	var by1: int = -1
	for y: int in h:
		for x: int in w:
			if _alpha(img, x, y) == 255:
				bx0 = mini(bx0, x)
				by0 = mini(by0, y)
				bx1 = maxi(bx1, x)
				by1 = maxi(by1, y)
	var bw: int = bx1 - bx0 + 1
	var bh: int = by1 - by0 + 1
	if bw < spec[2] or bw > spec[3] or bh < spec[4] or bh > spec[5]:
		errors.append("desenho %dx%d fora de %d-%d x %d-%d" % [bw, bh, spec[2], spec[3], spec[4], spec[5]])
	# Contorno: pixels opacos na borda da silhueta devem ser de cor de contorno
	var edge: int = 0
	var edge_ok: int = 0
	for y: int in h:
		for x: int in w:
			if _alpha(img, x, y) != 255:
				continue
			var on_edge: bool = false
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx < 0 or ny < 0 or nx >= w or ny >= h or _alpha(img, nx, ny) == 0:
					on_edge = true
					break
			if on_edge:
				edge += 1
				if _outline.has(_px(img, x, y)):
					edge_ok += 1
	var need: float = 75.0 if (w == 16 and h == 16) else 90.0
	var edge_pct: float = 100.0 * edge_ok / maxf(1.0, edge)
	if edge_pct < need:
		errors.append("contorno %.1f%% (min %.0f%%)" % [edge_pct, need])
	var orph: Vector2i = _orphans(img, false)
	var orph_pct: float = 100.0 * orph.x / maxf(1.0, orph.y)
	if orph_pct > 3.0:
		errors.append("orfaos %.1f%% (max 3%%)" % orph_pct)
	_report(key, errors, "%dx%d desenho=%dx%d cores=%d contorno=%.0f%% orfaos=%.1f%% base=%.1f" % [w, h, bw, bh, colors.size(), edge_pct, orph_pct, base_off])
	return img


func _check_mask(key: String, images: Dictionary) -> void:
	var src_key: String = MASKS[key][0]
	var regions_expected: int = MASKS[key][1]
	var errors: Array[String] = []
	var img: Image = _load(SPR_DIR + key + ".png")
	var src: Image = images.get(src_key)
	if img == null or src == null:
		_fail(key, "arquivo ausente (mascara ou sprite)")
		return
	if img.get_format() != Image.FORMAT_RGBA8:
		errors.append("formato %d (esperado RGBA8)" % img.get_format())
		img.convert(Image.FORMAT_RGBA8)
	if img.get_size() != src.get_size():
		errors.append("tamanho %s diferente de %s" % [img.get_size(), src.get_size()])
		_report(key, errors, "")
		return
	_common(img, errors, 0, false)
	var w: int = img.get_width()
	var h: int = img.get_height()
	var wrong: int = 0
	var missing: int = 0
	for y: int in h:
		for x: int in w:
			var m_op: bool = _alpha(img, x, y) == 255
			var s_rune: bool = _alpha(src, x, y) == 255 and _rune.has(_px(src, x, y))
			if m_op and (_px(img, x, y) != _px(src, x, y) or not _rune.has(_px(img, x, y))):
				wrong += 1
			if s_rune and not m_op:
				missing += 1
	if wrong > 0:
		errors.append("%d px da mascara nao batem com runa do sprite" % wrong)
	if missing > 0:
		errors.append("%d px de runa do sprite ausentes na mascara" % missing)
	# Regiões conectadas (vizinhança 8)
	var seen: Dictionary = {}
	var regions: int = 0
	for y: int in h:
		for x: int in w:
			var p: Vector2i = Vector2i(x, y)
			if _alpha(img, x, y) != 255 or seen.has(p):
				continue
			regions += 1
			var stack: Array[Vector2i] = [p]
			seen[p] = true
			while not stack.is_empty():
				var q: Vector2i = stack.pop_back()
				for dy: int in range(-1, 2):
					for dx: int in range(-1, 2):
						var n: Vector2i = q + Vector2i(dx, dy)
						if n.x < 0 or n.y < 0 or n.x >= w or n.y >= h or seen.has(n):
							continue
						if _alpha(img, n.x, n.y) == 255:
							seen[n] = true
							stack.append(n)
	if regions != regions_expected:
		errors.append("%d regioes de runa (esperado %d)" % [regions, regions_expected])
	_report(key, errors, "%dx%d regioes=%d" % [w, h, regions])


func _check_family(fam: Array, images: Dictionary) -> void:
	var errors: Array[String] = []
	var first: Image = images.get(fam[0])
	if first == null:
		return
	for i: int in range(1, fam.size()):
		var other: Image = images.get(fam[i])
		if other == null:
			continue
		var band_diff: int = 0
		for y: int in 32:
			for x: int in 32:
				var in_band: bool = x < BAND or y < BAND or x >= 32 - BAND or y >= 32 - BAND
				if in_band and _px(first, x, y) != _px(other, x, y):
					band_diff += 1
		if band_diff > 0:
			errors.append("%s: %d px diferentes na faixa" % [fam[i], band_diff])
	# Miolos diferentes entre si (todos os pares)
	for i: int in fam.size():
		for j: int in range(i + 1, fam.size()):
			var a: Image = images.get(fam[i])
			var b: Image = images.get(fam[j])
			if a == null or b == null:
				continue
			var same: bool = true
			for y: int in range(BAND, 32 - BAND):
				for x: int in range(BAND, 32 - BAND):
					if _px(a, x, y) != _px(b, x, y):
						same = false
			if same:
				errors.append("miolos iguais: %s e %s" % [fam[i], fam[j]])
	_report("familia " + str(fam[0]).rsplit("_", true, 1)[0], errors, "faixa de %d px" % BAND)


func _check_step_grass(images: Dictionary) -> void:
	var errors: Array[String] = []
	var a: Image = images.get("step_side")
	var b: Image = images.get("step_side_grass")
	if a == null or b == null:
		return
	var diff: int = 0
	for y: int in range(16, 32):
		for x: int in 32:
			if _px(a, x, y) != _px(b, x, y):
				diff += 1
	if diff > 0:
		errors.append("%d px diferentes nas 16 linhas de baixo" % diff)
	for x: int in 32:
		if not _grass.has(_px(b, x, 0)):
			errors.append("primeira linha com cor fora da Grama")
			break
	_report("step_side_grass/base", errors, "16 linhas de baixo iguais a step_side")


func _fail(key: String, msg: String) -> void:
	var errors: Array[String] = [msg]
	_report(key, errors, "")
