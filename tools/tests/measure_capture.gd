extends SceneTree
## Mede uma captura PNG (spec 004). Uso, a partir da raiz do projeto:
##   "$G" --headless --path . --script tools/tests/measure_capture.gd -- docs/screenshots/004-s42-y0.png
## Imprime:
## - retângulo central (40% x 40%): luminância média, saturação média (HSV) e % de pixels
##   estourados (Y >= 0,97);
## - luminância média dos cantos de 8% x 8% (cima-direita, baixo-esquerda, baixo-direita) e a
##   razão média dos cantos / centro (o canto de cima-esquerda tem o HUD);
## - faixa de cima (15% da altura): pixels com a cor de fundo antiga #1F2E47 e linhas de uma cor só;
## - sombras: dos pixels fora da faixa de cima com Y entre 0,10 e 0,35, o matiz médio (média
##   circular, em graus) e a fração com matiz entre 180° e 260°. Pixels quase cinza (saturação
##   < 0,05) não têm matiz definido e ficam fora da conta de matiz.
## Y = luminância Rec. 709 sobre os valores da imagem (0 a 1).

const CENTER_FRACTION: float = 0.4
const CORNER_FRACTION: float = 0.08
const TOP_STRIP_FRACTION: float = 0.15
const CLIP_Y: float = 0.97
const SHADOW_Y_MIN: float = 0.10
const SHADOW_Y_MAX: float = 0.35
const HUE_BLUE_MIN: float = 180.0
const HUE_BLUE_MAX: float = 260.0
const MIN_SATURATION_FOR_HUE: float = 0.05
const OLD_BACKGROUND: Color = Color8(0x1F, 0x2E, 0x47)
## Tolerância por canal (em 0..255) para "a cor de fundo antiga".
const BACKGROUND_TOLERANCE: int = 2


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.is_empty():
		print("Uso: -- <caminho do PNG>")
		quit(1)
		return
	var code: int = 0
	for path: String in args:
		if not _measure(path):
			code = 1
	quit(code)


static func luma(c: Color) -> float:
	return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b


func _measure(path: String) -> bool:
	var abs_path: String = path
	if path.is_relative_path():
		abs_path = ProjectSettings.globalize_path("res://").path_join(path)
	var img := Image.load_from_file(abs_path)
	if img == null or img.is_empty():
		print("ERRO: não deu para abrir ", abs_path)
		return false
	img.convert(Image.FORMAT_RGB8)
	var w: int = img.get_width()
	var h: int = img.get_height()
	print("== %s (%dx%d)" % [path, w, h])

	# Centro.
	var cw: int = roundi(w * CENTER_FRACTION)
	var ch: int = roundi(h * CENTER_FRACTION)
	var center := Rect2i((w - cw) / 2, (h - ch) / 2, cw, ch)
	var sum_y: float = 0.0
	var sum_s: float = 0.0
	var clipped: int = 0
	for y in range(center.position.y, center.end.y):
		for x in range(center.position.x, center.end.x):
			var c: Color = img.get_pixel(x, y)
			var lum: float = luma(c)
			sum_y += lum
			sum_s += c.s
			if lum >= CLIP_Y:
				clipped += 1
	var n_center: float = float(cw * ch)
	var center_y: float = sum_y / n_center
	print("centro 40%%x40%%: luminância média %.3f; saturação média %.3f; estourados %.2f%%" % [
			center_y, sum_s / n_center, 100.0 * clipped / n_center])

	# Cantos.
	var kw: int = roundi(w * CORNER_FRACTION)
	var kh: int = roundi(h * CORNER_FRACTION)
	var corners: Dictionary = {
		"cima-direita": Rect2i(w - kw, 0, kw, kh),
		"baixo-esquerda": Rect2i(0, h - kh, kw, kh),
		"baixo-direita": Rect2i(w - kw, h - kh, kw, kh),
	}
	var corner_sum: float = 0.0
	var corner_text: String = ""
	for corner_name: String in corners:
		var r: Rect2i = corners[corner_name]
		var s: float = 0.0
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				s += luma(img.get_pixel(x, y))
		var mean: float = s / float(r.size.x * r.size.y)
		corner_sum += mean
		corner_text += "%s %.3f; " % [corner_name, mean]
	var corner_mean: float = corner_sum / corners.size()
	print("cantos 8%%x8%%: %smédia %.3f; razão cantos/centro %.3f" % [corner_text, corner_mean,
			corner_mean / maxf(center_y, 0.000001)])

	# Faixa de cima.
	var strip_h: int = roundi(h * TOP_STRIP_FRACTION)
	var bg_pixels: int = 0
	var flat_rows: int = 0
	for y in strip_h:
		var first: Color = img.get_pixel(0, y)
		var flat := true
		for x in w:
			var c: Color = img.get_pixel(x, y)
			if _near_background(c):
				bg_pixels += 1
			if flat and not c.is_equal_approx(first):
				flat = false
		if flat:
			flat_rows += 1
	print("faixa de cima (15%%, %d linhas): pixels #1F2E47 %d; linhas de uma cor só %d" % [strip_h, bg_pixels, flat_rows])

	# Sombras.
	var shadow_count: int = 0
	var hue_count: int = 0
	var blue_count: int = 0
	var sum_sin: float = 0.0
	var sum_cos: float = 0.0
	for y in range(strip_h, h):
		for x in w:
			var c: Color = img.get_pixel(x, y)
			var lum: float = luma(c)
			if lum < SHADOW_Y_MIN or lum > SHADOW_Y_MAX:
				continue
			shadow_count += 1
			if c.s < MIN_SATURATION_FOR_HUE:
				continue
			hue_count += 1
			var hue_deg: float = c.h * 360.0
			sum_sin += sin(deg_to_rad(hue_deg))
			sum_cos += cos(deg_to_rad(hue_deg))
			if hue_deg >= HUE_BLUE_MIN and hue_deg <= HUE_BLUE_MAX:
				blue_count += 1
	var mean_hue: float = fposmod(rad_to_deg(atan2(sum_sin, sum_cos)), 360.0) if hue_count > 0 else 0.0
	print("sombras (Y %.2f a %.2f, %d pixels, %d com matiz): matiz médio %.1f°; matiz 180°-260° %.1f%%" % [
			SHADOW_Y_MIN, SHADOW_Y_MAX, shadow_count, hue_count, mean_hue,
			100.0 * blue_count / maxf(float(hue_count), 1.0)])
	return true


func _near_background(c: Color) -> bool:
	return absi(c.r8 - OLD_BACKGROUND.r8) <= BACKGROUND_TOLERANCE \
			and absi(c.g8 - OLD_BACKGROUND.g8) <= BACKGROUND_TOLERANCE \
			and absi(c.b8 - OLD_BACKGROUND.b8) <= BACKGROUND_TOLERANCE
