extends RefCounted
## Tela de desenho da A02: cor (índice global da paleta, -1 = transparente) + mapa de altura.
## Albedo e altura são desenhados juntos; o normal map sai só da altura.
## Sem class_name: usar via preload.

const P = preload("res://tools/art/palette_a02.gd")

var w: int
var h: int
var wrap_x: bool
var wrap_y: bool
var c: PackedInt32Array
var z: PackedFloat32Array
var lock: PackedByteArray
var keep: PackedByteArray # pixels protegidos da limpeza de órfãos
var strength: float = 1.0 # força do normal map
var max_slope: float = 2.0 # inclinação máxima (garante Z >= 0,44)


func _init(width: int, height: int, wx: bool = true, wy: bool = true) -> void:
	w = width
	h = height
	wrap_x = wx
	wrap_y = wy
	c.resize(w * h)
	c.fill(-1)
	z.resize(w * h)
	z.fill(0.0)
	lock.resize(w * h)
	lock.fill(0)
	keep.resize(w * h)
	keep.fill(0)


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
	if o < 0 or lock[o] != 0:
		return
	c[o] = ci
	z[o] = zv


func put_c(x: int, y: int, ci: int) -> void:
	var o: int = ofs(x, y)
	if o < 0 or lock[o] != 0:
		return
	c[o] = ci


func put_z(x: int, y: int, zv: float) -> void:
	var o: int = ofs(x, y)
	if o < 0 or lock[o] != 0:
		return
	z[o] = zv


func get_c(x: int, y: int) -> int:
	var o: int = ofs(x, y)
	return -1 if o < 0 else c[o]


func get_z(x: int, y: int) -> float:
	var o: int = ofs(x, y)
	return 0.0 if o < 0 else z[o]


func fill(ci: int, zv: float) -> void:
	c.fill(ci)
	z.fill(zv)


func clone() -> RefCounted:
	var o: RefCounted = get_script().new(w, h, wrap_x, wrap_y)
	o.c = c.duplicate()
	o.z = z.duplicate()
	o.lock = lock.duplicate()
	o.keep = keep.duplicate()
	o.strength = strength
	o.max_slope = max_slope
	return o


## Desloca tudo (com wrap): novo[x] = antigo[x - dx].
func roll(dx: int, dy: int) -> void:
	var nc: PackedInt32Array = c.duplicate()
	var nz: PackedFloat32Array = z.duplicate()
	var nk: PackedByteArray = keep.duplicate()
	for y: int in h:
		for x: int in w:
			var src: int = posmod(y - dy, h) * w + posmod(x - dx, w)
			nc[y * w + x] = c[src]
			nz[y * w + x] = z[src]
			nk[y * w + x] = keep[src]
	c = nc
	z = nz
	keep = nk


## Reta de Bresenham (com wrap conforme a tela).
func line(x0: int, y0: int, x1: int, y1: int, ci: int, zv: float) -> void:
	var dx: int = absi(x1 - x0)
	var dy: int = -absi(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx + dy
	var x: int = x0
	var y: int = y0
	while true:
		put(x, y, ci, zv)
		if x == x1 and y == y1:
			break
		var e2: int = 2 * err
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy


## Pixels de uma reta (sem pintar).
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


## Pixels de uma elipse girada (centro em coordenadas de pixel contínuas).
static func ellipse_pts(cx: float, cy: float, rx: float, ry: float, ang: float) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var r: float = maxf(rx, ry) + 1.0
	var ca: float = cos(ang)
	var sa: float = sin(ang)
	for y: int in range(floori(cy - r), ceili(cy + r) + 1):
		for x: int in range(floori(cx - r), ceili(cx + r) + 1):
			var px: float = x + 0.5 - cx
			var py: float = y + 0.5 - cy
			var u: float = px * ca + py * sa
			var v: float = -px * sa + py * ca
			if (u * u) / (rx * rx) + (v * v) / (ry * ry) <= 1.0:
				out.append(Vector2i(x, y))
	return out


func opaque_count() -> int:
	var n: int = 0
	for i: int in c.size():
		if c[i] >= 0:
			n += 1
	return n


## Troca cada pixel órfão (sem vizinho de mesma cor nos 8) pela cor vizinha mais próxima em tom.
func cleanup_orphans() -> int:
	var fixed: int = 0
	for y: int in h:
		for x: int in w:
			var o: int = y * w + x
			var ci: int = c[o]
			if ci < 0 or keep[o] != 0:
				continue
			var best: int = -1
			var best_d: int = 999
			var orphan: bool = true
			for j: int in range(-1, 2):
				for i: int in range(-1, 2):
					if i == 0 and j == 0:
						continue
					var nc: int = get_c(x + i, y + j)
					if nc == ci:
						orphan = false
						break
					if nc < 0:
						continue
					var d: int = 50
					if P.group_of(nc) == P.group_of(ci):
						d = absi(P.tone_of(nc) - P.tone_of(ci))
					if d < best_d:
						best_d = d
						best = nc
				if not orphan:
					break
			if orphan and best >= 0:
				c[o] = best
				fixed += 1
	return fixed


## Remove pixels opacos sem nenhum vizinho opaco (alfa solto) e fecha furos de 1 px.
func cleanup_alpha() -> void:
	for y: int in h:
		for x: int in w:
			var o: int = y * w + x
			var n: int = 0
			for j: int in range(-1, 2):
				for i: int in range(-1, 2):
					if (i != 0 or j != 0) and get_c(x + i, y + j) >= 0:
						n += 1
			if c[o] >= 0 and n == 0:
				c[o] = -1


func to_image() -> Image:
	var data: PackedByteArray = PackedByteArray()
	data.resize(w * h * 4)
	for i: int in w * h:
		var ci: int = c[i]
		if ci < 0:
			data[i * 4 + 3] = 0
			continue
		var v: int = P.rgb(ci)
		data[i * 4] = (v >> 16) & 255
		data[i * 4 + 1] = (v >> 8) & 255
		data[i * 4 + 2] = v & 255
		data[i * 4 + 3] = 255
	return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, data)


## Normal map (convenção OpenGL): n = normalize(-s*dh/dx, +s*dh/dlinha, 1), diferenças centrais com wrap.
func normal_image() -> Image:
	var data: PackedByteArray = PackedByteArray()
	data.resize(w * h * 4)
	for y: int in h:
		for x: int in w:
			var dhx: float = (_zs(x + 1, y) - _zs(x - 1, y)) * 0.5
			var dhy: float = (_zs(x, y + 1) - _zs(x, y - 1)) * 0.5
			var g: Vector2 = Vector2(-strength * dhx, strength * dhy)
			if g.length() > max_slope:
				g = g.normalized() * max_slope
			var n: Vector3 = Vector3(g.x, g.y, 1.0).normalized()
			var o: int = (y * w + x) * 4
			data[o] = clampi(roundi((n.x * 0.5 + 0.5) * 255.0), 0, 255)
			data[o + 1] = clampi(roundi((n.y * 0.5 + 0.5) * 255.0), 0, 255)
			data[o + 2] = clampi(roundi((n.z * 0.5 + 0.5) * 255.0), 0, 255)
			data[o + 3] = 255
	return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, data)


# Altura com wrap (ou prende na borda se o eixo não tem wrap)
func _zs(x: int, y: int) -> float:
	x = posmod(x, w) if wrap_x else clampi(x, 0, w - 1)
	y = posmod(y, h) if wrap_y else clampi(y, 0, h - 1)
	return z[y * w + x]


## Ajusta strength gradualmente para garantir relevo (Z < 0.97 em >= target_pct)
func ensure_relief(target_pct: float = 0.28) -> void:
	for step: int in 12:
		var low_z: int = 0
		for y: int in h:
			for x: int in w:
				var dhx: float = (_zs(x + 1, y) - _zs(x - 1, y)) * 0.5
				var dhy: float = (_zs(x, y + 1) - _zs(x, y - 1)) * 0.5
				var g: Vector2 = Vector2(-strength * dhx, strength * dhy)
				if g.length() > max_slope:
					g = g.normalized() * max_slope
				var nz: float = 1.0 / sqrt(1.0 + g.length_squared())
				if nz < 0.97:
					low_z += 1
		var pct: float = float(low_z) / float(w * h)
		if pct >= target_pct or strength >= 2.5:
			break
		strength *= 1.15

