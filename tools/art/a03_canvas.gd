extends RefCounted
## Tela de desenho da A03: cor (índice global da paleta, -1 = transparente) + mapa de altura.
## Albedo e altura são desenhados juntos; o normal map sai só da altura (com wrap).
## Sem class_name: usar via preload.

const P = preload("res://tools/art/palette_a03.gd")

var w: int
var h: int
var wrap_x: bool
var wrap_y: bool
var c: PackedInt32Array
var z: PackedFloat32Array
var strength: float = 1.0 # força do normal map
var max_slope: float = 1.2 # inclinação máxima (Z >= 0,64)


func _init(width: int, height: int, wx: bool = true, wy: bool = true) -> void:
	w = width
	h = height
	wrap_x = wx
	wrap_y = wy
	c.resize(w * h)
	c.fill(-1)
	z.resize(w * h)
	z.fill(0.0)


func ofs(x: int, y: int) -> int:
	if wrap_x:
		x = posmod(x, w)
	elif x < 0 or x >= w:
		return -1
	if wrap_y:
		y = posmod(y, h)
	elif y < 0 or y >= h:
		return -1
	return y * w + x


func put(x: int, y: int, ci: int, zv: float) -> void:
	var o: int = ofs(x, y)
	if o >= 0:
		c[o] = ci
		z[o] = zv


func put_c(x: int, y: int, ci: int) -> void:
	var o: int = ofs(x, y)
	if o >= 0:
		c[o] = ci


func put_z(x: int, y: int, zv: float) -> void:
	var o: int = ofs(x, y)
	if o >= 0:
		z[o] = zv


func get_c(x: int, y: int) -> int:
	var o: int = ofs(x, y)
	return -1 if o < 0 else c[o]


func get_z(x: int, y: int) -> float:
	var o: int = ofs(x, y)
	return 0.0 if o < 0 else z[o]


func fill(ci: int, zv: float = 0.0) -> void:
	c.fill(ci)
	z.fill(zv)


func clone() -> RefCounted:
	var o: RefCounted = get_script().new(w, h, wrap_x, wrap_y)
	o.c = c.duplicate()
	o.z = z.duplicate()
	o.strength = strength
	o.max_slope = max_slope
	return o


## Desloca tudo com wrap: novo[x] = antigo[x - dx].
func roll(dx: int, dy: int) -> void:
	var nc: PackedInt32Array = c.duplicate()
	var nz: PackedFloat32Array = z.duplicate()
	for y: int in h:
		for x: int in w:
			var src: int = posmod(y - dy, h) * w + posmod(x - dx, w)
			nc[y * w + x] = c[src]
			nz[y * w + x] = z[src]
	c = nc
	z = nz


## Pixels de uma reta de Bresenham.
static func line_pts(x0: int, y0: int, x1: int, y1: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var dx: int = absi(x1 - x0)
	var dy: int = -absi(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx + dy
	var x: int = x0
	var y: int = y0
	while true:
		out.append(Vector2i(x, y))
		if x == x1 and y == y1:
			break
		var e2: int = 2 * err
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy
	return out


func to_image() -> Image:
	var data: PackedByteArray = PackedByteArray()
	data.resize(w * h * 4)
	for i: int in w * h:
		var ci: int = c[i]
		if ci < 0:
			continue
		var v: int = P.rgb(ci)
		data[i * 4] = (v >> 16) & 255
		data[i * 4 + 1] = (v >> 8) & 255
		data[i * 4 + 2] = v & 255
		data[i * 4 + 3] = 255
	return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, data)


# Altura com wrap nos dois eixos (as laterais empilham faixas A, B, A...)
func _zs(x: int, y: int) -> float:
	return z[posmod(y, h) * w + posmod(x, w)]


func _grad(x: int, y: int, s: float) -> Vector2:
	var dhx: float = (_zs(x + 1, y) - _zs(x - 1, y)) * 0.5
	var dhy: float = (_zs(x, y + 1) - _zs(x, y - 1)) * 0.5
	# Convenção OpenGL: +X à direita, +Y para o topo da textura (linha menor)
	var g: Vector2 = Vector2(-s * dhx, s * dhy)
	if g.length() > max_slope:
		g = g.normalized() * max_slope
	return g


## Normal map RGB8 com alfa 255.
func normal_image() -> Image:
	var data: PackedByteArray = PackedByteArray()
	data.resize(w * h * 4)
	for y: int in h:
		for x: int in w:
			var g: Vector2 = _grad(x, y, strength)
			var n: Vector3 = Vector3(g.x, g.y, 1.0).normalized()
			var o: int = (y * w + x) * 4
			data[o] = clampi(roundi((n.x * 0.5 + 0.5) * 255.0), 0, 255)
			data[o + 1] = clampi(roundi((n.y * 0.5 + 0.5) * 255.0), 0, 255)
			data[o + 2] = clampi(roundi((n.z * 0.5 + 0.5) * 255.0), 0, 255)
			data[o + 3] = 255
	return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, data)


## [fração com Z < 0,98, Z médio] para uma força.
func relief_stats(s: float) -> Vector2:
	var low: int = 0
	var sum_z: float = 0.0
	for y: int in h:
		for x: int in w:
			var g: Vector2 = _grad(x, y, s)
			var nz: float = 1.0 / sqrt(1.0 + g.length_squared())
			sum_z += nz
			if nz < 0.98:
				low += 1
	return Vector2(float(low) / float(w * h), sum_z / float(w * h))


## Escolhe a menor força que dá relevo nas juntas (>= alvo de Z < 0,98) mantendo Z médio >= 0,92.
func tune_relief(target_low: float = 0.2) -> void:
	var s: float = 0.3
	while s < 3.0:
		var st: Vector2 = relief_stats(s)
		if st.y < 0.92:
			s /= 1.08
			break
		if st.x >= target_low:
			break
		s *= 1.08
	strength = s
