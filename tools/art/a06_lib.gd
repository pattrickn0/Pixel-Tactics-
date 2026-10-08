extends RefCounted
## Ajudantes da A06 (sem class_name; usar via preload).
## Nada aqui sorteia ou gera ruído: só formas geométricas a partir de tabelas escritas à mão
## nos geradores (polígonos, retângulos, carimbos de texto, máscaras).

const P = preload("res://tools/art/palette_a03.gd")
const CV = preload("res://tools/art/a03_canvas.gd")
const L = preload("res://tools/art/art_lib.gd")

const TEX: String = "res://assets/textures/"
const PREVIEW: String = "res://docs/art-preview/"


static func save_png(img: Image, res_path: String) -> void:
	var abs_path: String = ProjectSettings.globalize_path(res_path)
	DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
	var err: Error = img.save_png(abs_path)
	if err != OK:
		push_error("Falha ao gravar %s (%d)" % [res_path, err])


## Grava albedo (e, se pedido, o normal map) de uma tela. Pixels transparentes herdam o RGB do vizinho.
static func save_cv(cv: RefCounted, rel: String, with_normal: bool, has_alpha: bool) -> Image:
	var img: Image = cv.to_image()
	if has_alpha:
		fix_alpha_rgb(img)
	save_png(img, TEX + rel + ".png")
	if with_normal:
		save_png(cv.normal_image(), TEX + rel + "_n.png")
	return img


# ---------------------------------------------------------------------------
# Máscaras (PackedByteArray w*h, 1 = dentro)
# ---------------------------------------------------------------------------

static func new_mask(w: int, h: int) -> PackedByteArray:
	var m: PackedByteArray = PackedByteArray()
	m.resize(w * h)
	return m


## Preenche um polígono (lista plana x0,y0,x1,y1,...) testando o centro de cada pixel.
static func poly_mask(w: int, h: int, pts: Array) -> PackedByteArray:
	var m: PackedByteArray = new_mask(w, h)
	var n: int = pts.size() / 2
	for y: int in h:
		var yc: float = float(y) + 0.5
		var xs: Array[float] = []
		for i: int in n:
			var j: int = (i + 1) % n
			var x0: float = float(pts[i * 2])
			var y0: float = float(pts[i * 2 + 1])
			var x1: float = float(pts[j * 2])
			var y1: float = float(pts[j * 2 + 1])
			if (y0 <= yc and y1 > yc) or (y1 <= yc and y0 > yc):
				xs.append(x0 + (yc - y0) * (x1 - x0) / (y1 - y0))
		xs.sort()
		var k: int = 0
		while k + 1 < xs.size():
			var xa: int = ceili(xs[k] - 0.5)
			var xb: int = ceili(xs[k + 1] - 0.5) - 1
			for x: int in range(maxi(xa, 0), mini(xb, w - 1) + 1):
				m[y * w + x] = 1
			k += 2
	return m


## Pontos de um contorno em torno de (cx, cy): raios literais, um por passo de ângulo.
## O ângulo cresce no sentido horário na tela (0 = leste); sy achata o eixo vertical.
static func polar_pts(cx: float, cy: float, sy: float, step_deg: float, radii: Array, rot_deg: float = 0.0) -> Array:
	var out: Array = []
	for i: int in radii.size():
		var a: float = deg_to_rad(rot_deg + step_deg * float(i))
		var r: float = float(radii[i])
		out.append(cx + r * cos(a))
		out.append(cy + sy * r * sin(a))
	return out


static func m_or(a: PackedByteArray, b: PackedByteArray) -> PackedByteArray:
	var o: PackedByteArray = a.duplicate()
	for i: int in o.size():
		if b[i] != 0:
			o[i] = 1
	return o


static func m_sub(a: PackedByteArray, b: PackedByteArray) -> PackedByteArray:
	var o: PackedByteArray = a.duplicate()
	for i: int in o.size():
		if b[i] != 0:
			o[i] = 0
	return o


static func m_and(a: PackedByteArray, b: PackedByteArray) -> PackedByteArray:
	var o: PackedByteArray = a.duplicate()
	for i: int in o.size():
		if b[i] == 0:
			o[i] = 0
	return o


static func m_count(a: PackedByteArray) -> int:
	var n: int = 0
	for i: int in a.size():
		if a[i] != 0:
			n += 1
	return n


## Distância (4-vizinhança) até a máscara: 0 dentro, 1..maxd fora; 99 além de maxd.
static func dist4(m: PackedByteArray, w: int, h: int, maxd: int) -> PackedInt32Array:
	var d: PackedInt32Array = PackedInt32Array()
	d.resize(w * h)
	var q: PackedInt32Array = PackedInt32Array()
	for i: int in w * h:
		if m[i] != 0:
			d[i] = 0
			q.append(i)
		else:
			d[i] = 99
	var head: int = 0
	while head < q.size():
		var i: int = q[head]
		head += 1
		if d[i] >= maxd:
			continue
		var x: int = i % w
		var y: int = i / w
		for k: int in 4:
			var nx: int = x + [1, -1, 0, 0][k]
			var ny: int = y + [0, 0, 1, -1][k]
			if nx < 0 or ny < 0 or nx >= w or ny >= h:
				continue
			var ni: int = ny * w + nx
			if d[ni] == 99:
				d[ni] = d[i] + 1
				q.append(ni)
	return d


## Retângulo cheio na tela.
static func rect(cv: RefCounted, x: int, y: int, rw: int, rh: int, ci: int, zv: float) -> void:
	for j: int in rh:
		for i: int in rw:
			cv.put(x + i, y + j, ci, zv)


## Pinta onde a máscara vale 1.
static func paint_mask(cv: RefCounted, m: PackedByteArray, ci: int, zv: float) -> void:
	for y: int in cv.h:
		for x: int in cv.w:
			if m[y * cv.w + x] != 0:
				cv.put(x, y, ci, zv)


## Carimbo de texto: cada caractere do dicionário vira [índice de cor, altura]; '.' não pinta.
static func stamp(cv: RefCounted, rows: Array, ox: int, oy: int, map: Dictionary) -> void:
	for j: int in rows.size():
		var row: String = rows[j]
		for i: int in row.length():
			var ch: String = row[i]
			if map.has(ch):
				var e: Array = map[ch]
				cv.put(ox + i, oy + j, int(e[0]), float(e[1]))


## Faixa horizontal por comprimentos: "a12 b5 c9" (letra do dicionário + largura), a partir de x0.
static func runs(cv: RefCounted, y: int, x0: int, spec: String, map: Dictionary) -> int:
	var x: int = x0
	for tok: String in spec.split(" ", false):
		var ch: String = tok.substr(0, 1)
		var n: int = int(tok.substr(1))
		if map.has(ch):
			var e: Array = map[ch]
			for i: int in n:
				cv.put(x + i, y, int(e[0]), float(e[1]))
		x += n
	return x


# ---------------------------------------------------------------------------
# Alfa
# ---------------------------------------------------------------------------

## Pixels com alfa 0 recebem o RGB do vizinho opaco mais próximo (evita franja escura no mipmap).
static func fix_alpha_rgb(img: Image) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var seen: PackedByteArray = new_mask(w, h)
	var q: PackedInt32Array = PackedInt32Array()
	for i: int in w * h:
		if img.get_pixel(i % w, i / w).a > 0.5:
			seen[i] = 1
			q.append(i)
	var head: int = 0
	while head < q.size():
		var i: int = q[head]
		head += 1
		var x: int = i % w
		var y: int = i / w
		var src: Color = img.get_pixel(x, y)
		for k: int in 4:
			var nx: int = x + [1, -1, 0, 0][k]
			var ny: int = y + [0, 0, 1, -1][k]
			if nx < 0 or ny < 0 or nx >= w or ny >= h:
				continue
			var ni: int = ny * w + nx
			if seen[ni] == 0:
				seen[ni] = 1
				img.set_pixel(nx, ny, Color(src.r, src.g, src.b, 0.0))
				q.append(ni)


# ---------------------------------------------------------------------------
# Prévia
# ---------------------------------------------------------------------------

static func up(img: Image, k: int) -> Image:
	return L.scaled(img, k)


## Cola uma imagem (com alfa) sobre um fundo opaco.
static func over(dst: Image, src: Image, x: int, y: int) -> void:
	dst.blend_rect(src, Rect2i(0, 0, src.get_width(), src.get_height()), Vector2i(x, y))


## Repete uma imagem em x vezes nx e ny.
static func tile(img: Image, nx: int, ny: int) -> Image:
	return L.tiled(img, nx, ny)


static func load_tex(rel: String) -> Image:
	var img: Image = Image.load_from_file(ProjectSettings.globalize_path(TEX + rel + ".png"))
	img.convert(Image.FORMAT_RGBA8)
	return img


## Quebra trechos retos de borda (opaco ao lado de transparente) maiores que max_run:
## empurra o terço do meio do trecho 1 px para fora, copiando a cor do pixel de borda.
## Determinístico (sem sorteio): só impõe a regra de bordas recortadas em degraus pequenos.
static func break_edges(cv: RefCounted, max_run: int = 5) -> void:
	var w: int = cv.w
	var h: int = cv.h
	for _iter: int in 60:
		var changed: bool = false
		for dir: int in 4:
			var dx: int = [0, 0, -1, 1][dir]
			var dy: int = [-1, 1, 0, 0][dir]
			var along_x: bool = dy != 0
			var n_lines: int = h if along_x else w
			var line_len: int = w if along_x else h
			for ln: int in n_lines:
				var run_start: int = -1
				for k: int in line_len + 1:
					var is_edge: bool = false
					if k < line_len:
						var x: int = k if along_x else ln
						var y: int = ln if along_x else k
						is_edge = cv.c[y * w + x] >= 0
						if is_edge:
							var nx: int = x + dx
							var ny: int = y + dy
							is_edge = nx >= 0 and ny >= 0 and nx < w and ny < h and cv.c[ny * w + nx] < 0
					if is_edge:
						if run_start < 0:
							run_start = k
					elif run_start >= 0:
						var length: int = k - run_start
						if length > max_run:
							var a: int = run_start + length / 3
							var b: int = run_start + (2 * length) / 3
							for kk: int in range(a, b):
								var xx: int = kk if along_x else ln
								var yy: int = ln if along_x else kk
								cv.c[(yy + dy) * w + xx + dx] = cv.c[yy * w + xx]
								cv.z[(yy + dy) * w + xx + dx] = cv.z[yy * w + xx]
							changed = true
						run_start = -1
		if not changed:
			break
