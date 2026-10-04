extends RefCounted
## Ajudantes de desenho e de prévia para os geradores de arte (sem class_name).

const CLEAR: Color = Color(0, 0, 0, 0)

# Fonte 3x5 para rótulos das prévias (bits por linha, de cima para baixo)
const FONT: Dictionary = {
	"A": "010101111101101", "B": "110101110101110", "C": "011100100100011",
	"D": "110101101101110", "E": "111100110100111", "F": "111100110100100",
	"G": "011100101101011", "H": "101101111101101", "I": "111010010010111",
	"J": "001001001101010", "K": "101101110101101", "L": "100100100100111",
	"M": "101111111101101", "N": "110101101101101", "O": "010101101101010",
	"P": "110101110100100", "Q": "010101101110011", "R": "110101110101101",
	"S": "011100010001110", "T": "111010010010010", "U": "101101101101111",
	"V": "101101101101010", "W": "101101111111101", "X": "101101010101101",
	"Y": "101101010010010", "Z": "111001010100111",
	"0": "111101101101111", "1": "010110010010111", "2": "110001010100111",
	"3": "110001010001110", "4": "101101111001001", "5": "111100110001110",
	"6": "011100111101111", "7": "111001010010010", "8": "111101111101111",
	"9": "111101111001110", "_": "000000000000111", "-": "000000111000000",
	".": "000000000000010", " ": "000000000000000", "/": "001001010100100",
}


static func new_image(w: int, h: int, fill: Color = CLEAR) -> Image:
	var img: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(fill)
	return img


static func put(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


# Pinta com wrap (texturas seamless)
static func put_wrap(img: Image, x: int, y: int, c: Color) -> void:
	img.set_pixel(posmod(x, img.get_width()), posmod(y, img.get_height()), c)


static func get_wrap(img: Image, x: int, y: int) -> Color:
	return img.get_pixel(posmod(x, img.get_width()), posmod(y, img.get_height()))


static func same(a: Color, b: Color) -> bool:
	return a.to_rgba32() == b.to_rgba32()


static func is_opaque(img: Image, x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return false
	return img.get_pixel(x, y).a > 0.5


# Carimbo a partir de linhas de texto; cada caractere mapeia para uma cor ('.' = não pinta)
static func stamp(img: Image, rows: Array, ox: int, oy: int, colors: Dictionary, wrap: bool) -> void:
	for j: int in rows.size():
		var row: String = rows[j]
		for i: int in row.length():
			var ch: String = row[i]
			if not colors.has(ch):
				continue
			if wrap:
				put_wrap(img, ox + i, oy + j, colors[ch])
			else:
				put(img, ox + i, oy + j, colors[ch])


# Distância com wrap (toro de lado n)
static func wrap_delta(d: float, n: float) -> float:
	var r: float = fposmod(d + n * 0.5, n) - n * 0.5
	return r


# Pixels (com wrap) de uma "bolha" = união de círculos Vector3(cx, cy, r)
static func blob_pixels_wrap(circles: Array, n: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y: int in n:
		for x: int in n:
			var px: float = x + 0.5
			var py: float = y + 0.5
			for c: Vector3 in circles:
				var dx: float = wrap_delta(px - c.x, float(n))
				var dy: float = wrap_delta(py - c.y, float(n))
				if dx * dx + dy * dy <= c.z * c.z:
					out.append(Vector2i(x, y))
					break
	return out


# Ampliação Nearest
static func scaled(img: Image, k: int) -> Image:
	var out: Image = img.duplicate()
	out.resize(img.get_width() * k, img.get_height() * k, Image.INTERPOLATE_NEAREST)
	return out


static func tiled(img: Image, nx: int, ny: int) -> Image:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var out: Image = new_image(w * nx, h * ny)
	for j: int in ny:
		for i: int in nx:
			out.blit_rect(img, Rect2i(0, 0, w, h), Vector2i(i * w, j * h))
	return out


# Cola com alfa (sprites) ou direto (opaco)
static func paste(dst: Image, src: Image, x: int, y: int) -> void:
	dst.blend_rect(src, Rect2i(0, 0, src.get_width(), src.get_height()), Vector2i(x, y))


# Texto com a fonte 3x5, escala k
static func text(img: Image, s: String, x: int, y: int, k: int, c: Color) -> void:
	var cx: int = x
	for ch: String in s.to_upper():
		var bits: String = FONT.get(ch, FONT[" "])
		for j: int in 5:
			for i: int in 3:
				if bits[j * 3 + i] == "1":
					img.fill_rect(Rect2i(cx + i * k, y + j * k, k, k), c)
		cx += 4 * k


static func text_width(s: String, k: int) -> int:
	return s.length() * 4 * k


# Prévia em linhas: recebe itens [Image, rótulo] e quebra quando passa da largura máxima
static func flow_layout(items: Array, max_w: int, gap: int, label_k: int, bg: Color, fg: Color) -> Image:
	var label_h: int = 5 * label_k + 4
	var rows: Array = []
	var row: Array = []
	var row_w: int = gap
	for it: Array in items:
		var im: Image = it[0]
		var w: int = maxi(im.get_width(), text_width(it[1], label_k))
		if row.size() > 0 and row_w + w + gap > max_w:
			rows.append(row)
			row = []
			row_w = gap
		row.append(it)
		row_w += w + gap
	if row.size() > 0:
		rows.append(row)
	var total_w: int = 0
	var total_h: int = gap
	for r: Array in rows:
		var rw: int = gap
		var rh: int = 0
		for it: Array in r:
			var im: Image = it[0]
			rw += maxi(im.get_width(), text_width(it[1], label_k)) + gap
			rh = maxi(rh, im.get_height())
		total_w = maxi(total_w, rw)
		total_h += rh + label_h + gap
	var out: Image = new_image(total_w, total_h, bg)
	var y: int = gap
	for r: Array in rows:
		var x: int = gap
		var rh: int = 0
		for it: Array in r:
			var im: Image = it[0]
			text(out, it[1], x, y, label_k, fg)
			paste(out, im, x, y + label_h)
			x += maxi(im.get_width(), text_width(it[1], label_k)) + gap
			rh = maxi(rh, im.get_height())
		y += rh + label_h + gap
	return out
