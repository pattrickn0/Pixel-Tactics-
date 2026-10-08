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
	# recorte de linhas para a pintura (só linhas clip_lo <= y < clip_hi recebem tinta)
	var clip_lo: int = 0
	var clip_hi: int = 1 << 30

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
		var row: int = i / w
		if row < clip_lo or row >= clip_hi:
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
static func dilate_rgb(img: Image, passes: int = 24, wrap_x: bool = false) -> void:
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
	"<": "001010100010001", "*": "000101010101000", "|": "010010010010010",
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


## (r1) Métrica da grama na escala da câmera: reduz a 1/3 (Lanczos) e mede o desvio-padrão de L, a média
## de |L - desfoque gaussiano σ 4 px| (com volta) e o L médio.
## Com scale = 1 e wrap = false serve para medir um recorte da referência do mesmo jeito.
static func camera_metrics(img: Image, scale: float = 1.0 / 3.0, wrap: bool = true) -> Dictionary:
	var sm: Image = img.duplicate()
	sm.convert(Image.FORMAT_RGBA8)
	if scale != 1.0:
		sm.resize(roundi(img.get_width() * scale), roundi(img.get_height() * scale), Image.INTERPOLATE_LANCZOS)
	var w: int = sm.get_width()
	var h: int = sm.get_height()
	var d: PackedByteArray = sm.get_data()
	var L := PackedFloat32Array()
	L.resize(w * h)
	for i: int in w * h:
		L[i] = 0.299 * d[i * 4] + 0.587 * d[i * 4 + 1] + 0.114 * d[i * 4 + 2]
	var sigma: float = 4.0
	var rad: int = 12
	var ker := PackedFloat32Array()
	var ks: float = 0.0
	for k: int in range(-rad, rad + 1):
		var v: float = exp(-float(k * k) / (2.0 * sigma * sigma))
		ker.append(v)
		ks += v
	for k: int in ker.size():
		ker[k] /= ks
	var tmp := PackedFloat32Array()
	tmp.resize(w * h)
	var bl := PackedFloat32Array()
	bl.resize(w * h)
	for y: int in h:
		for x: int in w:
			var s: float = 0.0
			for k: int in range(-rad, rad + 1):
				s += L[y * w + (posmod(x + k, w) if wrap else clampi(x + k, 0, w - 1))] * ker[k + rad]
			tmp[y * w + x] = s
	for y: int in h:
		for x: int in w:
			var s: float = 0.0
			for k: int in range(-rad, rad + 1):
				s += tmp[(posmod(y + k, h) if wrap else clampi(y + k, 0, h - 1)) * w + x] * ker[k + rad]
			bl[y * w + x] = s
	var s1: float = 0.0
	var s2: float = 0.0
	var dt: float = 0.0
	for i: int in w * h:
		s1 += L[i]
		s2 += L[i] * L[i]
		dt += absf(L[i] - bl[i])
	var mean: float = s1 / float(w * h)
	return {"std": sqrt(maxf(s2 / float(w * h) - mean * mean, 0.0)), "detail": dt / float(w * h), "mean": mean}


## Pixel "de terra": marrom-alaranjado, não verde (R acima de G, G acima de B, saturação mínima).
static func is_dirt(c: Color) -> bool:
	return c.r > c.g * 1.08 and c.g > c.b * 1.05 and c.r > c.b * 1.35


# ---------------------------------------------------------------------------
# (r2) Granulação e estatísticas de cartão
# ---------------------------------------------------------------------------

## Luminância Rec. 709 (a da revisão 012-f2) de uma imagem RGBA8.
static func lum709(img: Image) -> PackedFloat32Array:
	var d: PackedByteArray = img.get_data()
	var n: int = img.get_width() * img.get_height()
	var L := PackedFloat32Array()
	L.resize(n)
	for i: int in n:
		L[i] = 0.2126 * d[i * 4] + 0.7152 * d[i * 4 + 1] + 0.0722 * d[i * 4 + 2]
	return L


## Desfoque gaussiano separável (borda presa), sigma em px.
static func gauss(f: PackedFloat32Array, w: int, h: int, sigma: float) -> PackedFloat32Array:
	var rad: int = ceili(sigma * 3.0)
	var ker := PackedFloat32Array()
	var ks: float = 0.0
	for k: int in range(-rad, rad + 1):
		var v: float = exp(-float(k * k) / (2.0 * sigma * sigma))
		ker.append(v)
		ks += v
	for k: int in ker.size():
		ker[k] /= ks
	var tmp := PackedFloat32Array()
	tmp.resize(w * h)
	var out := PackedFloat32Array()
	out.resize(w * h)
	for y: int in h:
		for x: int in w:
			var s: float = 0.0
			for k: int in range(-rad, rad + 1):
				s += f[y * w + clampi(x + k, 0, w - 1)] * ker[k + rad]
			tmp[y * w + x] = s
	for y: int in h:
		for x: int in w:
			var s: float = 0.0
			for k: int in range(-rad, rad + 1):
				s += tmp[clampi(y + k, 0, h - 1) * w + x] * ker[k + rad]
			out[y * w + x] = s
	return out


## Granulação da revisão 012-f2: média |L - G2(L)| ÷ média |G2(L) - G10(L)| numa caixa (σ em px).
## Mede "couve-flor": detalhe fino demais para o tamanho das massas. Referência: 0,74 a 0,84.
static func granulation(img: Image, rc: Rect2i) -> float:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var L: PackedFloat32Array = lum709(img)
	var g2: PackedFloat32Array = gauss(L, w, h, 2.0)
	var g10: PackedFloat32Array = gauss(L, w, h, 10.0)
	var a: float = 0.0
	var b: float = 0.0
	for y: int in range(rc.position.y, rc.end.y):
		for x: int in range(rc.position.x, rc.end.x):
			var i: int = y * w + x
			a += absf(L[i] - g2[i])
			b += absf(g2[i] - g10[i])
	return a / maxf(b, 0.0001)


## (r2) Estatísticas de uma célula de tufo de folha (alfa >= 128 = opaco, L = 0,299 R + 0,587 G + 0,114 B):
## cover = fração da célula coberta; dark = fração dos opacos com L < 0,55 × mediana; dark_low = fração
## desses escuros no terço de baixo da célula; dtb = |L médio do terço de cima - do terço de baixo|.
static func clump_stats(img: Image, rc: Rect2i) -> Dictionary:
	var d: PackedByteArray = img.get_data()
	var w: int = img.get_width()
	var ls: Array[float] = []
	var ys: Array[int] = []
	for y: int in range(rc.position.y, rc.end.y):
		for x: int in range(rc.position.x, rc.end.x):
			var i: int = y * w + x
			if d[i * 4 + 3] < 128:
				continue
			ls.append(0.299 * d[i * 4] + 0.587 * d[i * 4 + 1] + 0.114 * d[i * 4 + 2])
			ys.append(y - rc.position.y)
	var n: int = ls.size()
	if n == 0:
		return {"cover": 0.0, "dark": 0.0, "dark_low": 0.0, "dtb": 0.0}
	var sorted: Array[float] = ls.duplicate()
	sorted.sort()
	var med: float = sorted[n / 2]
	var h3: float = float(rc.size.y) / 3.0
	var nd: int = 0
	var ndl: int = 0
	var st: float = 0.0
	var nt: int = 0
	var sb: float = 0.0
	var nb: int = 0
	for k: int in n:
		var yy: float = float(ys[k])
		if ls[k] < 0.55 * med:
			nd += 1
			if yy >= 2.0 * h3:
				ndl += 1
		if yy < h3:
			st += ls[k]
			nt += 1
		elif yy >= 2.0 * h3:
			sb += ls[k]
			nb += 1
	return {"cover": float(n) / float(rc.size.x * rc.size.y), "dark": float(nd) / float(n),
		"dark_low": float(ndl) / float(maxi(nd, 1)) if nd > 0 else 1.0,
		"dtb": absf(st / float(maxi(nt, 1)) - sb / float(maxi(nb, 1))), "tb": st / float(maxi(nt, 1)) - sb / float(maxi(nb, 1)), "median": med}


## (r2) Estatísticas de um andar de conífera (alfa >= 128 = opaco):
## iou = IoU da máscara com o espelho horizontal (em volta do centroide x);
## clumps = cachos na saia (máximos do perfil de baixo separados por entalhes de >= 4 px, "peakdet");
## ratio = largura do maior cacho ÷ a do menor (largura = distância entre entalhes vizinhos);
## straight = maior trecho do perfil de baixo que cabe numa reta com ±1,5 px, ÷ largura da célula.
static func tier_stats(img: Image, rc: Rect2i) -> Dictionary:
	var d: PackedByteArray = img.get_data()
	var w: int = img.get_width()
	var cw: int = rc.size.x
	var ch: int = rc.size.y
	var m := PackedByteArray()
	m.resize(cw * ch)
	var sx: float = 0.0
	var n: int = 0
	for y: int in ch:
		for x: int in cw:
			var i: int = (rc.position.y + y) * w + rc.position.x + x
			if d[i * 4 + 3] >= 128:
				m[y * cw + x] = 1
				sx += x
				n += 1
	var cxi: int = roundi(sx / float(maxi(n, 1)))
	var inter: int = 0
	var uni: int = 0
	for y: int in ch:
		for x: int in cw:
			var a: int = m[y * cw + x]
			var xm: int = 2 * cxi - x
			var b: int = m[y * cw + xm] if xm >= 0 and xm < cw else 0
			if a == 1 and b == 1:
				inter += 1
			if a == 1 or b == 1:
				uni += 1
	# perfil de baixo
	var prof: Array[float] = []
	for x: int in cw:
		var by: int = -1
		for y: int in range(ch - 1, -1, -1):
			if m[y * cw + x] == 1:
				by = y
				break
		if by >= 0:
			prof.append(float(by))
	var np: int = prof.size()
	# trecho reto mais longo
	var best: int = 0
	for i: int in np:
		var j: int = i + best + 1
		while j < np:
			var ok: bool = true
			for k: int in range(i + 1, j):
				var t: float = float(k - i) / float(j - i)
				if absf(prof[k] - (prof[i] + (prof[j] - prof[i]) * t)) > 1.5:
					ok = false
					break
			if not ok:
				break
			best = j - i
			j += 1
	# cachos: peakdet com delta 4 (y maior = mais baixo)
	var delta: float = 4.0
	var peaks: Array[int] = []
	var notches: Array[int] = [0]
	var look_max: bool = true
	var mx: float = -INF
	var mn: float = INF
	var mxi: int = 0
	var mni: int = 0
	for k: int in np:
		var v: float = prof[k]
		if v > mx:
			mx = v
			mxi = k
		if v < mn:
			mn = v
			mni = k
		if look_max and v < mx - delta:
			peaks.append(mxi)
			mn = v
			mni = k
			look_max = false
		elif not look_max and v > mn + delta:
			notches.append(mni)
			mx = v
			mxi = k
			look_max = true
	if look_max and mx > mn + delta and mxi > notches[notches.size() - 1]:
		peaks.append(mxi)
	notches.append(np - 1)
	var wmin: float = INF
	var wmax: float = 0.0
	for k: int in range(1, notches.size()):
		var ww: float = float(notches[k] - notches[k - 1])
		if ww < 3.0:
			continue
		wmin = minf(wmin, ww)
		wmax = maxf(wmax, ww)
	return {"iou": float(inter) / float(maxi(uni, 1)), "clumps": peaks.size(), "ratio": wmax / maxf(wmin, 1.0),
		"straight": float(best) / float(cw)}


## (r2) Estatísticas da arena_dirt (opaco = alfa >= 128; L = 0,299 R + 0,587 G + 0,114 B):
## dark = L <= 95; light = L >= 159; green = G > R; crown = L médio na coroa de raio 1,3 a 3,0 (u) do
## centro do círculo (0,1 u a leste e 0,1 u ao sul do centro do decalque) menos o L médio da mancha.
static func dirt_stats(img: Image) -> Dictionary:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var d: PackedByteArray = img.get_data()
	var rc := Vector2(w * 0.5 + 6.4, h * 0.5 + 6.4)
	var n: int = 0
	var nd: int = 0
	var nl: int = 0
	var ng: int = 0
	var sl: float = 0.0
	var cl: float = 0.0
	var cn: int = 0
	var acc := Vector3.ZERO
	for y: int in h:
		for x: int in w:
			var i: int = (y * w + x) * 4
			if d[i + 3] < 128:
				continue
			var l: float = 0.299 * d[i] + 0.587 * d[i + 1] + 0.114 * d[i + 2]
			n += 1
			sl += l
			acc += Vector3(d[i], d[i + 1], d[i + 2])
			if l <= 95.0:
				nd += 1
			if l >= 159.0:
				nl += 1
			if d[i + 1] > d[i]:
				ng += 1
			var rr: float = Vector2(x + 0.5, y + 0.5).distance_to(rc) / 64.0
			if rr >= 1.3 and rr <= 3.0:
				cl += l
				cn += 1
	var fn: float = float(maxi(n, 1))
	acc /= fn * 255.0
	return {"dark": nd / fn, "light": nl / fn, "green": ng / fn, "mean_l": sl / fn,
		"crown": cl / float(maxi(cn, 1)) - sl / fn, "color": Color(acc.x, acc.y, acc.z)}


## (r2) Pedra solta de arena_slabs numa célula: pedra = alfa >= 128 e saturação (máx - mín) / máx < 0,25;
## light = fração da pedra com L >= 186 (#C8BEA6 = 190); contact = cor média dos pixels opacos que não são
## pedra a até 4 px de um pixel de pedra (a sombra de contato, alvo #4A3A28 a #5C4630).
static func slab_stats(img: Image, rc: Rect2i) -> Dictionary:
	var w: int = img.get_width()
	var d: PackedByteArray = img.get_data()
	var cw: int = rc.size.x
	var chh: int = rc.size.y
	var stone := PackedByteArray()
	stone.resize(cw * chh)
	var ns: int = 0
	var nl: int = 0
	for y: int in chh:
		for x: int in cw:
			var i: int = ((rc.position.y + y) * w + rc.position.x + x) * 4
			if d[i + 3] < 128:
				continue
			var mx: float = maxf(d[i], maxf(d[i + 1], d[i + 2]))
			var mn: float = minf(d[i], minf(d[i + 1], d[i + 2]))
			if mx > 0.0 and (mx - mn) / mx < 0.25:
				stone[y * cw + x] = 1
				ns += 1
				if 0.299 * d[i] + 0.587 * d[i + 1] + 0.114 * d[i + 2] >= 186.0:
					nl += 1
	var acc := Vector3.ZERO
	var nc: int = 0
	for y: int in chh:
		for x: int in cw:
			if stone[y * cw + x] == 1:
				continue
			var i: int = ((rc.position.y + y) * w + rc.position.x + x) * 4
			if d[i + 3] < 128:
				continue
			var near: bool = false
			for dy: int in range(-4, 5):
				for dx: int in range(-4, 5):
					var xx: int = x + dx
					var yy: int = y + dy
					if xx >= 0 and yy >= 0 and xx < cw and yy < chh and stone[yy * cw + xx] == 1:
						near = true
						break
				if near:
					break
			if near:
				acc += Vector3(d[i], d[i + 1], d[i + 2])
				nc += 1
	acc /= float(maxi(nc, 1)) * 255.0
	return {"stone": ns, "light": float(nl) / float(maxi(ns, 1)), "contact": Color(acc.x, acc.y, acc.z)}


## (r2) Montagem de uma copa como no jogo (spec 012-f2, ajuste 4): 5 lóbulos de raio 1,15 u, cada um com
## 5 cartões grandes (meia largura de 0,9 a 1,2 × o raio), de trás para frente. Cada pixel recebe a luz
## da esfera da copa (normal 100% da copa, luz única) e AO pela profundidade do cartão, imitando o shader.
## Pinta em 64 px/u e reduz para 20 px/u (escala da câmera). Devolve a imagem grande, a pequena e a
## granulação (PL.granulation) numa caixa do miolo da copa e numa caixa da copa inteira.
const CROWN_LOBES: Array = [[0.0, 1.0], [-1.15, 0.25], [1.1, 0.3], [-0.55, -0.6], [0.6, -0.55]]
const CROWN_SKY := Color("#C9D3EA")


static func crown_montage(atlases: Array, seed_value: int) -> Dictionary:
	var ppu: float = 64.0
	var size: int = 384
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(CROWN_SKY)
	var cc := Vector2(size * 0.5, size * 0.55)
	var R: float = 2.3
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var cards: Array = []
	for lb: Array in CROWN_LOBES:
		var lx: float = lb[0]
		var ly: float = lb[1]
		var lr: float = 1.15
		var lz: float = sqrt(maxf(R * R - lx * lx - ly * ly, 0.0))
		for k: int in 5:
			var ox: float = rng.randf_range(-0.35, 0.35) * lr
			var oy: float = rng.randf_range(-0.35, 0.35) * lr
			cards.append([lx + ox, ly + oy, lz + rng.randf_range(-0.5, 0.5) * lr, rng.randf_range(0.9, 1.2) * lr,
				rng.randi_range(0, 15), rng.randi_range(0, atlases.size() - 1), rng.randf() < 0.5])
	cards.sort_custom(func(a: Array, b: Array) -> bool: return float(a[2]) < float(b[2]))
	var light := Vector3(-0.35, 0.8, 0.5).normalized()
	for cd: Array in cards:
		var atlas: Image = atlases[int(cd[5])]
		var cell: Image = atlas.get_region(Rect2i((int(cd[4]) % 4) * 256, (int(cd[4]) / 4) * 256, 256, 256))
		if bool(cd[6]):
			cell.flip_x()
		var px: int = roundi(float(cd[3]) * 2.0 * ppu)
		cell.resize(px, px, Image.INTERPOLATE_LANCZOS)
		var x0: int = roundi(cc.x + float(cd[0]) * ppu - px * 0.5)
		var y0: int = roundi(cc.y - float(cd[1]) * ppu - px * 0.5)
		for y: int in px:
			for x: int in px:
				var c: Color = cell.get_pixel(x, y)
				if c.a < 0.5:
					continue
				var X: int = x0 + x
				var Y: int = y0 + y
				if X < 0 or Y < 0 or X >= size or Y >= size:
					continue
				var wx: float = (X - cc.x) / ppu / R
				var wy: float = -(Y - cc.y) / ppu / R
				var q: float = wx * wx + wy * wy
				var n := Vector3(wx, wy, sqrt(maxf(1.0 - minf(q, 1.0), 0.0))).normalized()
				var dif: float = clampf(n.dot(light) * 0.6 + 0.4, 0.0, 1.0)
				var ao: float = clampf(0.55 + 0.45 * float(cd[2]) / R, 0.4, 1.0)
				var f: float = (0.5 + 0.75 * dif) * ao
				img.set_pixel(X, Y, Color(minf(c.r * f, 1.0), minf(c.g * f, 1.0), minf(c.b * f * (1.05 - 0.1 * dif), 1.0)))
	var s: float = 20.0 / ppu
	var small: Image = img.duplicate()
	small.resize(roundi(size * s), roundi(size * s), Image.INTERPOLATE_LANCZOS)
	var ccs: Vector2 = cc * s
	var rin := Rect2i(roundi(ccs.x - 26.0), roundi(ccs.y - 28.0), 52, 48)
	var rall := Rect2i(roundi(ccs.x - 48.0), roundi(ccs.y - 52.0), 96, 92)
	return {"img": img, "small": small, "g_in": granulation(small, rin), "g_all": granulation(small, rall), "box_in": rin, "box_all": rall}


# ---------------------------------------------------------------------------
# Leva 2: blocos em fiadas (penhasco, fundo da ilha, ruína), periódicos nos 2 eixos
# ---------------------------------------------------------------------------

## Divide um comprimento total em pedaços de min a max (soma exata, pedaços escalados no fim).
static func split_len(rng: RandomNumberGenerator, total: float, lo: float, hi: float) -> Array:
	var parts: Array = []
	var s: float = 0.0
	while s < total - lo * 0.5:
		var v: float = rng.randf_range(lo, hi)
		parts.append(v)
		s += v
	var k: float = total / s
	for i: int in parts.size():
		parts[i] = float(parts[i]) * k
	return parts


## Fiadas de blocos: [{y0, h, off, xs: [início de cada bloco], ws, ids}] cobrindo w x h com volta.
static func block_rows(rng: RandomNumberGenerator, w: float, h: float, row_lo: float, row_hi: float, bw_lo: float, bw_hi: float) -> Array:
	var rows: Array = []
	var y: float = 0.0
	var id: int = 0
	for rh: float in split_len(rng, h, row_lo, row_hi):
		var ws: Array = split_len(rng, w, bw_lo, bw_hi)
		var xs: Array = []
		var x: float = 0.0
		var ids: Array = []
		for bw: float in ws:
			xs.append(x)
			x += bw
			ids.append(id)
			id += 1
		rows.append({"y0": y, "h": rh, "off": rng.randf() * w, "xs": xs, "ws": ws, "ids": ids})
		y += rh
	return rows


## Bloco em (x, y) (coordenadas já distorcidas; volta em w e h). Devolve [id, dist. ao topo, à base,
## à esquerda, à direita, v (0 no topo do bloco, 1 na base), largura, altura].
static func block_at(rows: Array, w: float, h: float, x: float, y: float) -> Array:
	var yy: float = fposmod(y, h)
	var row: Dictionary = rows[rows.size() - 1]
	for r: Dictionary in rows:
		if yy < float(r["y0"]) + float(r["h"]):
			row = r
			break
	var ly: float = yy - float(row["y0"])
	var rh: float = row["h"]
	var xx: float = fposmod(x - float(row["off"]), w)
	var xs: Array = row["xs"]
	var ws: Array = row["ws"]
	var k: int = xs.size() - 1
	for j: int in xs.size():
		if xx < float(xs[j]) + float(ws[j]):
			k = j
			break
	var lx: float = xx - float(xs[k])
	var bw: float = ws[k]
	return [int(row["ids"][k]), ly, rh - ly, lx, bw - lx, ly / rh, bw, rh]


## Voronoi periódico (toroidal) em grade com sorteio: um ponto por célula da grade (gx x gy células).
## ay < 1 alonga as células na vertical. Devolve, por pixel (em 1/div da resolução, ampliado sem
## interpolação para os índices): id (F1), id2 (F2) e borda = (F2 - F1) / 2 em px (métrica anisotrópica).
class Voronoi extends RefCounted:
	var w: int
	var h: int
	var gx: int
	var gy: int
	var px: PackedFloat32Array
	var py: PackedFloat32Array
	var ay: float

	func _init(width: int, height: int, cells_x: int, cells_y: int, jitter: float, seed_value: int, aniso_y: float = 1.0) -> void:
		w = width
		h = height
		gx = cells_x
		gy = cells_y
		ay = aniso_y
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		px = PackedFloat32Array()
		py = PackedFloat32Array()
		var cw: float = float(w) / gx
		var ch: float = float(h) / gy
		for j: int in gy:
			for i: int in gx:
				var sx: float = 0.5 + rng.randf_range(-jitter, jitter) * 0.5
				var sy: float = 0.5 + rng.randf_range(-jitter, jitter) * 0.5
				px.append((i + sx) * cw)
				py.append((j + sy) * ch)

	## [id, id2, borda (px), vetor do ponto F1 para o ponto F2 (com volta)]
	func at(x: float, y: float) -> Array:
		var cw: float = float(w) / gx
		var ch: float = float(h) / gy
		var ci: int = floori(x / cw)
		var cj: int = floori(y / ch)
		var d1: float = INF
		var d2: float = INF
		var i1: int = 0
		var i2: int = 0
		var v1 := Vector2.ZERO
		var v2 := Vector2.ZERO
		for dj: int in range(-2, 3):
			for di: int in range(-2, 3):
				var ii: int = ci + di
				var jj: int = cj + dj
				var k: int = posmod(jj, gy) * gx + posmod(ii, gx)
				# posição do ponto com a volta aplicada
				var sx: float = px[k] + floorf(float(ii) / gx) * w
				var sy: float = py[k] + floorf(float(jj) / gy) * h
				var dx: float = sx - x
				var dy: float = (sy - y) * ay
				var d: float = dx * dx + dy * dy
				if d < d1:
					d2 = d1
					i2 = i1
					v2 = v1
					d1 = d
					i1 = k
					v1 = Vector2(sx, sy)
				elif d < d2:
					d2 = d
					i2 = k
					v2 = Vector2(sx, sy)
		# distância à borda (bissetriz entre F1 e F2), na métrica anisotrópica
		var p := Vector2(x, y * ay)
		var a := Vector2(v1.x, v1.y * ay)
		var b := Vector2(v2.x, v2.y * ay)
		var m: Vector2 = (a + b) * 0.5
		var nrm: Vector2 = (b - a).normalized()
		var edge: float = (m - p).dot(nrm)
		return [i1, i2, edge, v2 - v1]


## Rola albedo e normal juntos para a emenda cair num trecho liso (best_roll_multi nos eixos pedidos).
## Rolar não muda a textura repetida, só o ponto de corte (aceito na revisão 1 da A08).
static func roll_pair(albedo: Image, normal: Image, ax: bool, ay: bool) -> Array:
	var imgs: Array = [albedo] if normal == null else [albedo, normal]
	var dx: int = best_roll_multi(imgs, true) if ax else 0
	var dy: int = best_roll_multi(imgs, false) if ay else 0
	var a2: Image = roll(albedo, dx, dy)
	var n2: Image = roll(normal, dx, dy) if normal != null else null
	return [a2, n2]
