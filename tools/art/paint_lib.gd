extends RefCounted
## Biblioteca de pintura da A08 (cenário pintado). Sem class_name: usar via preload.
## Tudo é determinístico: ruídos e sorteios recebem seeds literais dos geradores.
## Convenção de imagem: x para a direita, y para baixo. Cores em sRGB 0..1, alfa reto (não pré-multiplicado).

const TEX: String = "res://assets/textures/scenery/"
const PREVIEW: String = "res://docs/art-preview/"
const REF_PATH: String = "res://docs/reference/ilha-flutuante.webp"


# ---------------------------------------------------------------------------
# Tela de pintura: RGB + alfa + altura, com volta (toroidal) opcional em cada eixo
# ---------------------------------------------------------------------------

class Canvas extends RefCounted:
	var w: int
	var h: int
	var wrap_x: bool
	var wrap_y: bool
	var r: PackedFloat32Array
	var g: PackedFloat32Array
	var b: PackedFloat32Array
	var a: PackedFloat32Array
	var z: PackedFloat32Array

	func _init(width: int, height: int, wx: bool, wy: bool) -> void:
		w = width
		h = height
		wrap_x = wx
		wrap_y = wy
		var n: int = w * h
		r = PackedFloat32Array()
		g = PackedFloat32Array()
		b = PackedFloat32Array()
		a = PackedFloat32Array()
		z = PackedFloat32Array()
		r.resize(n)
		g.resize(n)
		b.resize(n)
		a.resize(n)
		z.resize(n)

	func fill(c: Color, alpha: float = 1.0) -> void:
		r.fill(c.r)
		g.fill(c.g)
		b.fill(c.b)
		a.fill(alpha)

	## Índice do pixel (x, y) com volta; -1 se cair fora numa direção sem volta.
	func idx(x: int, y: int) -> int:
		if x < 0 or x >= w:
			if not wrap_x:
				return -1
			x = posmod(x, w)
		if y < 0 or y >= h:
			if not wrap_y:
				return -1
			y = posmod(y, h)
		return y * w + x

	func get_c(i: int) -> Color:
		return Color(r[i], g[i], b[i], a[i])

	## Mistura "por cima" com alfa reto. mode 0 = over; mode 1 = atop (só onde já há tinta).
	func blend(i: int, c: Color, t: float, mode: int = 0) -> void:
		if t <= 0.0:
			return
		if t > 1.0:
			t = 1.0
		var da: float = a[i]
		if mode == 1:
			t *= da
			r[i] += (c.r - r[i]) * t
			g[i] += (c.g - g[i]) * t
			b[i] += (c.b - b[i]) * t
			return
		var oa: float = t + da * (1.0 - t)
		if oa <= 0.000001:
			return
		var kd: float = da * (1.0 - t) / oa
		var ks: float = t / oa
		r[i] = c.r * ks + r[i] * kd
		g[i] = c.g * ks + g[i] * kd
		b[i] = c.b * ks + b[i] * kd
		a[i] = oa

	## Mancha suave: elipse girada (raios rx, ry, ângulo rot) com queda suave a partir de "hard" (0..1).
	func blob(cx: float, cy: float, rx: float, ry: float, rot: float, c: Color, opacity: float, hard: float = 0.0, mode: int = 0, zh: float = 0.0) -> void:
		var rm: float = maxf(rx, ry) + 1.0
		var cs: float = cos(rot)
		var sn: float = sin(rot)
		var x0: int = floori(cx - rm)
		var x1: int = ceili(cx + rm)
		var y0: int = floori(cy - rm)
		var y1: int = ceili(cy + rm)
		for y: int in range(y0, y1 + 1):
			var py: float = float(y) + 0.5 - cy
			for x: int in range(x0, x1 + 1):
				var px: float = float(x) + 0.5 - cx
				var u: float = (px * cs + py * sn) / rx
				var v: float = (-px * sn + py * cs) / ry
				var d: float = sqrt(u * u + v * v)
				if d >= 1.0:
					continue
				var i: int = idx(x, y)
				if i < 0:
					continue
				var f: float = 1.0 - smoothstep(hard, 1.0, d)
				blend(i, c, f * opacity, mode)
				if zh != 0.0:
					z[i] = maxf(z[i], zh * sqrt(1.0 - d * d))

	## Pincelada: polilinha com raio por ponto, cor de c0 (início) a c1 (fim), borda antisserrilhada.
	## zmode: 0 = sem altura, 1 = altura máxima (perfil redondo, pico zh), 2 = soma.
	func stroke(pts: PackedVector2Array, radii: PackedFloat32Array, c0: Color, c1: Color, opacity: float, mode: int = 0, zh: float = 0.0, zmode: int = 0, soft: float = 1.0) -> void:
		var n: int = pts.size()
		if n < 2:
			return
		var rmax: float = 0.0
		var bx0: float = INF
		var by0: float = INF
		var bx1: float = -INF
		var by1: float = -INF
		for k: int in n:
			rmax = maxf(rmax, radii[k])
			bx0 = minf(bx0, pts[k].x)
			by0 = minf(by0, pts[k].y)
			bx1 = maxf(bx1, pts[k].x)
			by1 = maxf(by1, pts[k].y)
		var ox: int = floori(bx0 - rmax - 1.5)
		var oy: int = floori(by0 - rmax - 1.5)
		var lw: int = ceili(bx1 + rmax + 1.5) - ox + 1
		var lh: int = ceili(by1 + rmax + 1.5) - oy + 1
		var cov := PackedFloat32Array()
		cov.resize(lw * lh)
		var par := PackedFloat32Array()
		par.resize(lw * lh)
		var prof := PackedFloat32Array()
		prof.resize(lw * lh)
		var nseg: float = float(n - 1)
		for k: int in n - 1:
			var p: Vector2 = pts[k]
			var q: Vector2 = pts[k + 1]
			var ra: float = radii[k]
			var rb: float = radii[k + 1]
			var rr: float = maxf(ra, rb) + 1.5
			var sx0: int = floori(minf(p.x, q.x) - rr) - ox
			var sx1: int = ceili(maxf(p.x, q.x) + rr) - ox
			var sy0: int = floori(minf(p.y, q.y) - rr) - oy
			var sy1: int = ceili(maxf(p.y, q.y) + rr) - oy
			var d: Vector2 = q - p
			var dd: float = maxf(d.dot(d), 0.000001)
			for ly: int in range(maxi(sy0, 0), mini(sy1, lh - 1) + 1):
				var fy: float = float(ly + oy) + 0.5
				for lx: int in range(maxi(sx0, 0), mini(sx1, lw - 1) + 1):
					var fx: float = float(lx + ox) + 0.5
					var s: float = clampf(((fx - p.x) * d.x + (fy - p.y) * d.y) / dd, 0.0, 1.0)
					var ex: float = fx - (p.x + d.x * s)
					var ey: float = fy - (p.y + d.y * s)
					var dist: float = sqrt(ex * ex + ey * ey)
					var rad: float = ra + (rb - ra) * s
					var cv: float = clampf((rad - dist) / soft + 0.5, 0.0, 1.0)
					var li: int = ly * lw + lx
					if cv > cov[li]:
						cov[li] = cv
						par[li] = (float(k) + s) / nseg
						var nd: float = clampf(dist / maxf(rad, 0.001), 0.0, 1.0)
						prof[li] = sqrt(1.0 - nd * nd)
		for ly: int in lh:
			for lx: int in lw:
				var li: int = ly * lw + lx
				var cv: float = cov[li]
				if cv <= 0.0:
					continue
				var i: int = idx(lx + ox, ly + oy)
				if i < 0:
					continue
				blend(i, c0.lerp(c1, par[li]), cv * opacity, mode)
				if zmode == 1:
					z[i] = maxf(z[i], zh * prof[li] * cv)
				elif zmode == 2:
					z[i] += zh * prof[li] * cv * opacity

	## Preenche um polígono (varredura por linha, regra par-ímpar). Com supersampling a borda fica limpa.
	func poly_fill(pts: PackedVector2Array, c: Color, opacity: float = 1.0, mode: int = 0, zh: float = 0.0) -> void:
		var n: int = pts.size()
		var y0: float = INF
		var y1: float = -INF
		for p: Vector2 in pts:
			y0 = minf(y0, p.y)
			y1 = maxf(y1, p.y)
		for y: int in range(floori(y0), ceili(y1) + 1):
			var yc: float = float(y) + 0.5
			var xs: Array[float] = []
			for k: int in n:
				var p: Vector2 = pts[k]
				var q: Vector2 = pts[(k + 1) % n]
				if (p.y <= yc and q.y > yc) or (q.y <= yc and p.y > yc):
					xs.append(p.x + (yc - p.y) * (q.x - p.x) / (q.y - p.y))
			xs.sort()
			var j: int = 0
			while j + 1 < xs.size():
				for x: int in range(ceili(xs[j] - 0.5), ceili(xs[j + 1] - 0.5)):
					var i: int = idx(x, y)
					if i >= 0:
						blend(i, c, opacity, mode)
						if zh != 0.0:
							z[i] = maxf(z[i], zh)
				j += 2

	## Aplica uma cor sobre a tela inteira com peso por pixel (máscara 0..1).
	func tint(mask: PackedFloat32Array, c: Color, opacity: float, mode: int = 0) -> void:
		for i: int in w * h:
			var t: float = mask[i] * opacity
			if t > 0.0:
				blend(i, c, t, mode)

	## Pinta a tela com uma rampa de cores a partir de um campo 0..1.
	func paint_ramp(field: PackedFloat32Array, ramp: Array) -> void:
		var n: int = ramp.size()
		for i: int in w * h:
			var f: float = clampf(field[i], 0.0, 1.0) * float(n - 1)
			var k: int = mini(floori(f), n - 2)
			var c0: Color = ramp[k]
			var c: Color = c0.lerp(ramp[k + 1], f - float(k))
			r[i] = c.r
			g[i] = c.g
			b[i] = c.b

	## Reduz 2x (supersampling): média 2x2, cor ponderada pelo alfa (sem halo escuro na borda).
	func down2() -> Canvas:
		var nw: int = w / 2
		var nh: int = h / 2
		var o := Canvas.new(nw, nh, wrap_x, wrap_y)
		for y: int in nh:
			for x: int in nw:
				var i00: int = (2 * y) * w + 2 * x
				var i10: int = i00 + 1
				var i01: int = i00 + w
				var i11: int = i01 + 1
				var a00: float = a[i00]
				var a10: float = a[i10]
				var a01: float = a[i01]
				var a11: float = a[i11]
				var sa: float = a00 + a10 + a01 + a11
				var j: int = y * nw + x
				o.z[j] = (z[i00] + z[i10] + z[i01] + z[i11]) * 0.25
				o.a[j] = sa * 0.25
				if sa > 0.000001:
					o.r[j] = (r[i00] * a00 + r[i10] * a10 + r[i01] * a01 + r[i11] * a11) / sa
					o.g[j] = (g[i00] * a00 + g[i10] * a10 + g[i01] * a01 + g[i11] * a11) / sa
					o.b[j] = (b[i00] * a00 + b[i10] * a10 + b[i01] * a01 + b[i11] * a11) / sa
				else:
					o.r[j] = (r[i00] + r[i10] + r[i01] + r[i11]) * 0.25
					o.g[j] = (g[i00] + g[i10] + g[i01] + g[i11]) * 0.25
					o.b[j] = (b[i00] + b[i10] + b[i01] + b[i11]) * 0.25
		return o

	## Imagem RGBA8. Os canais ficam em 1..254 (nunca preto nem branco puro).
	## opaque = true força alfa 255. cut > 0 recorta o alfa (abaixo de cut vira 0).
	func to_image(opaque: bool, cut: float = 0.0) -> Image:
		var bytes := PackedByteArray()
		bytes.resize(w * h * 4)
		for i: int in w * h:
			var o: int = i * 4
			bytes[o] = clampi(roundi(r[i] * 255.0), 1, 254)
			bytes[o + 1] = clampi(roundi(g[i] * 255.0), 1, 254)
			bytes[o + 2] = clampi(roundi(b[i] * 255.0), 1, 254)
			var al: float = a[i]
			if opaque:
				bytes[o + 3] = 255
			elif cut > 0.0 and al < cut:
				bytes[o + 3] = 0
			else:
				bytes[o + 3] = clampi(roundi(al * 255.0), 0, 255)
		return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, bytes)


# ---------------------------------------------------------------------------
# Ruído de gradiente periódico (toroidal) e campos de baixa frequência
# ---------------------------------------------------------------------------

class PNoise extends RefCounted:
	var px: int
	var py: int
	var gx: PackedFloat32Array
	var gy: PackedFloat32Array

	func _init(period_x: int, period_y: int, seed_value: int) -> void:
		px = period_x
		py = period_y
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		gx = PackedFloat32Array()
		gy = PackedFloat32Array()
		gx.resize(px * py)
		gy.resize(px * py)
		for i: int in px * py:
			var ang: float = rng.randf() * TAU
			gx[i] = cos(ang)
			gy[i] = sin(ang)

	## Valor em -1..1 (aprox.), coordenadas em células da grade.
	func at(x: float, y: float) -> float:
		var xi: int = floori(x)
		var yi: int = floori(y)
		var fx: float = x - float(xi)
		var fy: float = y - float(yi)
		var x0: int = posmod(xi, px)
		var y0: int = posmod(yi, py)
		var x1: int = (x0 + 1) % px
		var y1: int = (y0 + 1) % py
		var i00: int = y0 * px + x0
		var i10: int = y0 * px + x1
		var i01: int = y1 * px + x0
		var i11: int = y1 * px + x1
		var n00: float = gx[i00] * fx + gy[i00] * fy
		var n10: float = gx[i10] * (fx - 1.0) + gy[i10] * fy
		var n01: float = gx[i01] * fx + gy[i01] * (fy - 1.0)
		var n11: float = gx[i11] * (fx - 1.0) + gy[i11] * (fy - 1.0)
		var u: float = fx * fx * fx * (fx * (fx * 6.0 - 15.0) + 10.0)
		var v: float = fy * fy * fy * (fy * (fy * 6.0 - 15.0) + 10.0)
		var nx0: float = n00 + (n10 - n00) * u
		var nx1: float = n01 + (n11 - n01) * u
		return (nx0 + (nx1 - nx0) * v) * 1.41


## Campo fBm periódico em 0..1 (normalizado por mín/máx), com distorção de domínio.
## cells = células da oitava base em x (em y, proporcional ao formato). Avaliado em 1/div da resolução
## e ampliado em cúbica com volta, porque é de baixa frequência.
static func pfield(w: int, h: int, cells: int, octaves: int, seed_value: int, warp: float = 0.0, div: int = 4, gain: float = 0.5) -> PackedFloat32Array:
	var lw: int = w / div
	var lh: int = h / div
	var cy: int = maxi(1, roundi(float(cells) * float(h) / float(w)))
	var octs: Array = []
	for o: int in octaves:
		var m: int = 1 << o
		octs.append(PNoise.new(cells * m, cy * m, seed_value + o * 101))
	var wpx := PNoise.new(maxi(1, cells), cy, seed_value + 7001)
	var wpy := PNoise.new(maxi(1, cells), cy, seed_value + 7919)
	var f := PackedFloat32Array()
	f.resize(lw * lh)
	for y: int in lh:
		var v: float = (float(y) + 0.5) / float(lh)
		for x: int in lw:
			var u: float = (float(x) + 0.5) / float(lw)
			var uu: float = u
			var vv: float = v
			if warp != 0.0:
				uu += warp * wpx.at(u * float(cells), v * float(cy)) / float(cells)
				vv += warp * wpy.at(u * float(cells), v * float(cy)) / float(cy)
			var s: float = 0.0
			var amp: float = 1.0
			for o: int in octaves:
				var nz: PNoise = octs[o]
				s += amp * nz.at(uu * float(nz.px), vv * float(nz.py))
				amp *= gain
			f[y * lw + x] = s
	normalize(f)
	if div == 1:
		return f
	return resize_field(f, lw, lh, div, true, true)


## Campo de FastNoiseLite (não periódico, para decalques e cartões), 0..1, com distorção de domínio.
## freq em ciclos por pixel da imagem final.
static func nfield(w: int, h: int, freq: float, octaves: int, seed_value: int, warp_amp: float = 0.0, div: int = 4) -> PackedFloat32Array:
	var n := FastNoiseLite.new()
	n.seed = seed_value
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = freq * float(div)
	n.fractal_type = FastNoiseLite.FRACTAL_FBM
	n.fractal_octaves = octaves
	if warp_amp > 0.0:
		n.domain_warp_enabled = true
		n.domain_warp_type = FastNoiseLite.DOMAIN_WARP_SIMPLEX
		n.domain_warp_amplitude = warp_amp / float(div)
		n.domain_warp_frequency = freq * float(div) * 0.7
	var lw: int = w / div
	var lh: int = h / div
	var f := PackedFloat32Array()
	f.resize(lw * lh)
	for y: int in lh:
		for x: int in lw:
			f[y * lw + x] = n.get_noise_2d(float(x), float(y))
	normalize(f)
	if div == 1:
		return f
	return resize_field(f, lw, lh, div, false, false)


static func normalize(f: PackedFloat32Array) -> void:
	var lo: float = INF
	var hi: float = -INF
	for v: float in f:
		lo = minf(lo, v)
		hi = maxf(hi, v)
	var k: float = 1.0 / maxf(hi - lo, 0.000001)
	for i: int in f.size():
		f[i] = (f[i] - lo) * k


## Amplia um campo k vezes com interpolação cúbica (nativa), com volta ou borda presa.
static func resize_field(f: PackedFloat32Array, w: int, h: int, k: int, wrap_x: bool, wrap_y: bool) -> PackedFloat32Array:
	var p: int = 3
	var pw: int = w + 2 * p
	var ph: int = h + 2 * p
	var padded := PackedFloat32Array()
	padded.resize(pw * ph)
	for y: int in ph:
		var sy: int = y - p
		sy = posmod(sy, h) if wrap_y else clampi(sy, 0, h - 1)
		for x: int in pw:
			var sx: int = x - p
			sx = posmod(sx, w) if wrap_x else clampi(sx, 0, w - 1)
			padded[y * pw + x] = f[sy * w + sx]
	var img := Image.create_from_data(pw, ph, false, Image.FORMAT_RF, padded.to_byte_array())
	img.resize(pw * k, ph * k, Image.INTERPOLATE_CUBIC)
	var crop: Image = img.get_region(Rect2i(p * k, p * k, w * k, h * k))
	return crop.get_data().to_float32_array()


## Desfoque de caixa separável (2 passadas = tenda), com volta ou borda presa.
static func blur(f: PackedFloat32Array, w: int, h: int, radius: int, wrap_x: bool, wrap_y: bool, passes: int = 2) -> PackedFloat32Array:
	if radius <= 0:
		return f
	var cur: PackedFloat32Array = f.duplicate()
	var tmp := PackedFloat32Array()
	tmp.resize(w * h)
	var inv: float = 1.0 / float(2 * radius + 1)
	for _p: int in passes:
		for y: int in h:
			var row: int = y * w
			var s: float = 0.0
			for k: int in range(-radius, radius + 1):
				var xx: int = posmod(k, w) if wrap_x else clampi(k, 0, w - 1)
				s += cur[row + xx]
			for x: int in w:
				tmp[row + x] = s * inv
				var xo: int = x - radius
				var xi: int = x + radius + 1
				xo = posmod(xo, w) if wrap_x else clampi(xo, 0, w - 1)
				xi = posmod(xi, w) if wrap_x else clampi(xi, 0, w - 1)
				s += cur[row + xi] - cur[row + xo]
		for x: int in w:
			var s2: float = 0.0
			for k: int in range(-radius, radius + 1):
				var yy: int = posmod(k, h) if wrap_y else clampi(k, 0, h - 1)
				s2 += tmp[yy * w + x]
			for y: int in h:
				cur[y * w + x] = s2 * inv
				var yo: int = y - radius
				var yi: int = y + radius + 1
				yo = posmod(yo, h) if wrap_y else clampi(yo, 0, h - 1)
				yi = posmod(yi, h) if wrap_y else clampi(yi, 0, h - 1)
				s2 += tmp[yi * w + x] - tmp[yo * w + x]
	return cur


## Normal map (OpenGL: verde = +Y para cima) da altura desfocada, por Sobel.
static func normal_map(zf: PackedFloat32Array, w: int, h: int, strength: float, blur_r: int, wrap_x: bool, wrap_y: bool) -> Image:
	var zz: PackedFloat32Array = blur(zf, w, h, blur_r, wrap_x, wrap_y) if blur_r > 0 else zf
	var bytes := PackedByteArray()
	bytes.resize(w * h * 4)
	for y: int in h:
		var ym: int = posmod(y - 1, h) if wrap_y else maxi(y - 1, 0)
		var yp: int = posmod(y + 1, h) if wrap_y else mini(y + 1, h - 1)
		for x: int in w:
			var xm: int = posmod(x - 1, w) if wrap_x else maxi(x - 1, 0)
			var xp: int = posmod(x + 1, w) if wrap_x else mini(x + 1, w - 1)
			var tl: float = zz[ym * w + xm]
			var tc: float = zz[ym * w + x]
			var tr: float = zz[ym * w + xp]
			var ml: float = zz[y * w + xm]
			var mr: float = zz[y * w + xp]
			var bl: float = zz[yp * w + xm]
			var bc: float = zz[yp * w + x]
			var br: float = zz[yp * w + xp]
			var dx: float = ((tr + 2.0 * mr + br) - (tl + 2.0 * ml + bl)) * 0.125
			var dy: float = ((bl + 2.0 * bc + br) - (tl + 2.0 * tc + tr)) * 0.125
			var n := Vector3(-dx * strength, dy * strength, 1.0).normalized()
			var o: int = (y * w + x) * 4
			bytes[o] = clampi(roundi((n.x * 0.5 + 0.5) * 255.0), 0, 255)
			bytes[o + 1] = clampi(roundi((n.y * 0.5 + 0.5) * 255.0), 0, 255)
			bytes[o + 2] = clampi(roundi((n.z * 0.5 + 0.5) * 255.0), 0, 255)
			bytes[o + 3] = 255
	return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, bytes)


# ---------------------------------------------------------------------------
# Cor
# ---------------------------------------------------------------------------

static func hx(s: String) -> Color:
	return Color.html(s)


## Rampa linear por partes (lista de cores, t de 0 a 1).
static func ramp_at(ramp: Array, t: float) -> Color:
	var n: int = ramp.size()
	if t <= 0.0:
		return ramp[0]
	if t >= 1.0:
		return ramp[n - 1]
	var f: float = t * float(n - 1)
	var k: int = floori(f)
	var c0: Color = ramp[k]
	var c1: Color = ramp[mini(k + 1, n - 1)]
	return c0.lerp(c1, f - float(k))


static func lum(c: Color) -> float:
	return (0.299 * c.r + 0.587 * c.g + 0.114 * c.b) * 255.0


## Distância RGB normalizada (0 = igual, 1 = preto x branco).
static func cdist(c1: Color, c2: Color) -> float:
	var dr: float = c1.r - c2.r
	var dg: float = c1.g - c2.g
	var db: float = c1.b - c2.b
	return sqrt(dr * dr + dg * dg + db * db) / sqrt(3.0)


# ---------------------------------------------------------------------------
# Alfa: RGB dilatado para fora do recorte (sem halo nos mipmaps)
# ---------------------------------------------------------------------------

## Os pixels com alfa 0 recebem o RGB do pixel com alfa >= 128 mais próximo (busca em largura,
## vizinhança 8, em ondas de 1 px, até "passes" px); os que sobrarem recebem a média da parte opaca.
## Assim o filtro e os mipmaps nunca puxam cor de fora do recorte (sem halo).
static func dilate_rgb(img: Image, passes: int = 24) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var data: PackedByteArray = img.get_data()
	var src := PackedInt32Array()
	src.resize(w * h)
	src.fill(-1)
	var frontier: Array[int] = []
	var sr: float = 0.0
	var sg: float = 0.0
	var sb: float = 0.0
	var cnt: int = 0
	for i: int in w * h:
		if data[i * 4 + 3] >= 128:
			src[i] = i
			frontier.append(i)
			sr += data[i * 4]
			sg += data[i * 4 + 1]
			sb += data[i * 4 + 2]
			cnt += 1
	for _p: int in passes:
		if frontier.is_empty():
			break
		var nf: Array[int] = []
		for i: int in frontier:
			var x: int = i % w
			var y: int = i / w
			for dy: int in range(-1, 2):
				for dx: int in range(-1, 2):
					var xx: int = x + dx
					var yy: int = y + dy
					if xx < 0 or yy < 0 or xx >= w or yy >= h:
						continue
					var j: int = yy * w + xx
					if src[j] == -1:
						src[j] = src[i]
						nf.append(j)
		frontier = nf
	var mr: int = roundi(sr / maxf(cnt, 1))
	var mg: int = roundi(sg / maxf(cnt, 1))
	var mb: int = roundi(sb / maxf(cnt, 1))
	for i: int in w * h:
		if data[i * 4 + 3] != 0:
			continue
		var j: int = src[i]
		if j >= 0:
			data[i * 4] = data[j * 4]
			data[i * 4 + 1] = data[j * 4 + 1]
			data[i * 4 + 2] = data[j * 4 + 2]
		else:
			data[i * 4] = mr
			data[i * 4 + 1] = mg
			data[i * 4 + 2] = mb
	img.set_data(w, h, false, Image.FORMAT_RGBA8, data)


## Escolhe onde "cortar" uma textura periódica: o deslocamento (múltiplo de step) cuja coluna/linha de
## emenda tem a menor diferença entre vizinhas. Rolar não muda a textura repetida, só o ponto de corte.
static func best_roll(img: Image, along_x: bool, step: int = 4) -> int:
	return best_roll_multi([img], along_x, step)


## Igual a best_roll, somando a diferença de várias imagens do mesmo tamanho (corte comum).
static func best_roll_multi(imgs: Array, along_x: bool, step: int = 4) -> int:
	var img0: Image = imgs[0]
	var w: int = img0.get_width()
	var h: int = img0.get_height()
	var datas: Array = []
	for im: Image in imgs:
		datas.append(im.get_data())
	var best: float = INF
	var best_k: int = 0
	var n: int = w if along_x else h
	for k: int in range(0, n, step):
		var s: float = 0.0
		var m: int = h if along_x else w
		for data: PackedByteArray in datas:
			for t: int in m:
				var i: int = (t * w + posmod(k - 1, w)) if along_x else (posmod(k - 1, h) * w + t)
				var j: int = (t * w + k) if along_x else (k * w + t)
				s += absf(data[i * 4] - data[j * 4]) + absf(data[i * 4 + 1] - data[j * 4 + 1]) + absf(data[i * 4 + 2] - data[j * 4 + 2])
		if s < best:
			best = s
			best_k = k
	return best_k


## Rola a imagem (com volta): o pixel (dx, dy) vira o (0, 0).
static func roll(img: Image, dx: int, dy: int) -> Image:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var o := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var src: Image = img.duplicate()
	src.convert(Image.FORMAT_RGBA8)
	for part: Array in [[dx, dy, 0, 0], [0, dy, w - dx, 0], [dx, 0, 0, h - dy], [0, 0, w - dx, h - dy]]:
		var sx: int = part[0]
		var sy: int = part[1]
		var rw: int = (w - dx) if sx == dx else dx
		var rh: int = (h - dy) if sy == dy else dy
		if rw > 0 and rh > 0:
			o.blit_rect(src, Rect2i(sx, sy, rw, rh), Vector2i(part[2], part[3]))
	return o


# ---------------------------------------------------------------------------
# Formas
# ---------------------------------------------------------------------------

## Pontos de uma curva (arco de círculo) a partir de p0, direção ang, comprimento len e curvatura bend
## (radianos de giro ao longo do comprimento todo). n segmentos.
static func arc_pts(p0: Vector2, ang: float, length: float, bend: float, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	var p: Vector2 = p0
	out.append(p)
	var step: float = length / float(n)
	var a: float = ang - bend * 0.5 / float(n)
	for k: int in n:
		a += bend / float(n)
		p += Vector2(cos(a), sin(a)) * step
		out.append(p)
	return out


## Raios afinando de r0 a r1 (n+1 pontos), com curva de potência.
static func taper(n: int, r0: float, r1: float, pw: float = 1.0) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for k: int in n + 1:
		var t: float = pow(float(k) / float(n), pw)
		out.append(r0 + (r1 - r0) * t)
	return out


# ---------------------------------------------------------------------------
# Gravação e prévia
# ---------------------------------------------------------------------------

static func save_png(img: Image, res_path: String) -> void:
	var abs_path: String = ProjectSettings.globalize_path(res_path)
	DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
	var err: Error = img.save_png(abs_path)
	if err != OK:
		push_error("Falha ao gravar %s (%d)" % [res_path, err])


static func load_ref() -> Image:
	var img := Image.new()
	var err: Error = img.load_webp_from_buffer(FileAccess.get_file_as_bytes(REF_PATH))
	if err != OK:
		push_error("Não abriu a referência")
	img.convert(Image.FORMAT_RGBA8)
	return img


static func load_tex(rel: String) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path(TEX + rel + ".png"))
	img.convert(Image.FORMAT_RGBA8)
	return img


static func scaled(img: Image, k: float, interp: int = Image.INTERPOLATE_BILINEAR) -> Image:
	var o: Image = img.duplicate()
	o.resize(maxi(1, roundi(img.get_width() * k)), maxi(1, roundi(img.get_height() * k)), interp)
	return o


static func tiled(img: Image, nx: int, ny: int) -> Image:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var o := Image.create(w * nx, h * ny, false, Image.FORMAT_RGBA8)
	for j: int in ny:
		for i: int in nx:
			o.blit_rect(img, Rect2i(0, 0, w, h), Vector2i(i * w, j * h))
	return o


## Imagem com alfa sobre um fundo liso (para prévia).
static func on_bg(img: Image, bg: Color) -> Image:
	var o := Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
	o.fill(bg)
	o.blend_rect(img, Rect2i(0, 0, img.get_width(), img.get_height()), Vector2i.ZERO)
	return o


# Fonte 3x5 para os rótulos das prévias (bits por linha, de cima para baixo)
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
	"#": "101111101111101", ":": "000010000010000", "=": "000111000111000",
	"%": "101001010100101", ",": "000000000010100", "(": "010100100100010",
	")": "010001001001010", "+": "000010111010000", ">": "100010001010100",
	"<": "001010100010001", "*": "000101010101000",
}


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


## Retângulo vazado (marcação de região na prévia).
static func frame(img: Image, rc: Rect2i, c: Color, t: int = 1) -> void:
	img.fill_rect(Rect2i(rc.position.x, rc.position.y, rc.size.x, t), c)
	img.fill_rect(Rect2i(rc.position.x, rc.end.y - t, rc.size.x, t), c)
	img.fill_rect(Rect2i(rc.position.x, rc.position.y, t, rc.size.y), c)
	img.fill_rect(Rect2i(rc.end.x - t, rc.position.y, t, rc.size.y), c)


## Média e desvio-padrão da luminância (0..255) dos pixels com alfa >= 128 de uma região.
## Com dirt_only, só conta pixels de cor de terra (R > G > B, R bem acima de B).
static func lum_stats(img: Image, rc: Rect2i, dirt_only: bool = false) -> Dictionary:
	var s: float = 0.0
	var s2: float = 0.0
	var n: int = 0
	var cr: float = 0.0
	var cg: float = 0.0
	var cb: float = 0.0
	for y: int in range(rc.position.y, rc.end.y):
		for x: int in range(rc.position.x, rc.end.x):
			var c: Color = img.get_pixel(x, y)
			if c.a < 0.5:
				continue
			if dirt_only and not is_dirt(c):
				continue
			var l: float = lum(c)
			s += l
			s2 += l * l
			cr += c.r
			cg += c.g
			cb += c.b
			n += 1
	if n == 0:
		return {"mean": 0.0, "std": 0.0, "n": 0, "color": Color.BLACK}
	var m: float = s / n
	return {"mean": m, "std": sqrt(maxf(s2 / n - m * m, 0.0)), "n": n, "color": Color(cr / n, cg / n, cb / n)}


## Pixel "de terra": marrom-alaranjado, não verde (R acima de G, G acima de B, saturação mínima).
static func is_dirt(c: Color) -> bool:
	return c.r > c.g * 1.08 and c.g > c.b * 1.05 and c.r > c.b * 1.35
