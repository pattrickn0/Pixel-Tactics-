extends SceneTree
## A08, leva 1: folhagem (tufos de folha em 3 famílias, andares de conífera, casca, tufos de capim, flores).
## Grava em assets/textures/scenery/foliage/. Prévia: gen_a08_preview_folhagem.gd.
##   "$G" --headless --path . --script tools/art/gen_a08_folhagem.gd [-- clumps | conifer | bark | tufts | flowers]

const PL = preload("res://tools/art/paint_lib.gd")
const SS: int = 2

# Famílias de folhosa (sombra -> luz). warm = verde-amarelada, mid = verde-média, cool = verde-fria.
const FAMILIES: Dictionary = {
	"warm": ["#2E4A24", "#33522A", "#5E8A30", "#8DB040", "#AFC858", "#C8D870"],
	"mid": ["#26421F", "#2F5026", "#467432", "#6A9838", "#8DB040", "#A8C25A"],
	"cool": ["#1F3A26", "#28462E", "#3C6236", "#587F44", "#7C9C5A", "#98B472"],
}
const CONIFER: Array = ["#14260F", "#1A3016", "#2C4A1E", "#3E6326", "#4E7A2E", "#8EB048"]
const GRASS: Array = ["#2C4520", "#3F5F22", "#5E8424", "#7FA22C", "#A8C447"]
const FLOWERS: Dictionary = {
	"pink": "#F08CA8", "white": "#F6F2E8", "yellow": "#F4D04A", "blue": "#7FA8F0", "lilac": "#B898E0",
}


func _initialize() -> void:
	var only: String = ""
	if OS.get_cmdline_user_args().size() > 0:
		only = OS.get_cmdline_user_args()[0]
	if only == "" or only == "clumps":
		var k: int = 0
		for fam: String in ["warm", "mid", "cool"]:
			_leaf_clumps(fam, 8101 + k * 100)
			k += 1
	if only == "" or only == "conifer":
		_conifer_tiers()
	if only == "" or only == "bark":
		_bark()
	if only == "" or only == "tufts":
		_grass_tufts()
	if only == "" or only == "flowers":
		_flowers()
	quit()


static func c(s: String) -> Color:
	return Color.html(s)


static func ramp_of(list: Array) -> Array:
	var out: Array = []
	for s: String in list:
		out.append(c(s))
	return out


## Folha: polilinha curva com perfil largo no meio e ponta fina.
static func leaf(cv: PL.Canvas, p: Vector2, ang: float, length: float, width: float, bend: float, c0: Color, c1: Color, opacity: float = 1.0) -> void:
	var pts: PackedVector2Array = PL.arc_pts(p, ang, length, bend, 4)
	var radii := PackedFloat32Array([width * 0.3, width * 0.85, width, width * 0.7, width * 0.12])
	cv.stroke(pts, radii, c0, c1, opacity)


static func save_card(cv: PL.Canvas, rel: String) -> Image:
	var img: Image = cv.down2().to_image(false)
	PL.dilate_rgb(img, 24)
	PL.save_png(img, PL.TEX + rel + ".png")
	return img


# ---------------------------------------------------------------------------
# Tufos de folha: atlas 4 x 4 de células 256 (1024x1024), alfa recortado.
# Cada tufo é um hemisfério de folhas (de trás para frente), luz de cima e da frente:
# topo claro, miolo escuro nas frestas, borda feita de folhas apontando para fora.
# ---------------------------------------------------------------------------

func _leaf_clumps(fam: String, seed_value: int) -> void:
	var cell: int = 256 * SS
	var cv := PL.Canvas.new(cell * 4, cell * 4, false, false)
	var ramp: Array = ramp_of(FAMILIES[fam])
	cv.fill(ramp[1], 0.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var light := Vector3(0.0, 0.72, 0.69).normalized()  # de cima e da frente (y para cima)
	for k: int in 16:
		var org := Vector2((k % 4) * cell, (k / 4) * cell)
		var ctr: Vector2 = org + Vector2(cell * 0.5, cell * 0.52)
		var rad: float = rng.randf_range(0.36, 0.43) * cell
		var squash: float = rng.randf_range(0.82, 1.0)
		var ph1: float = rng.randf() * TAU
		var ph2: float = rng.randf() * TAU
		var lobes: int = rng.randi_range(3, 5)
		var lsize: float = rng.randf_range(0.9, 1.2)
		# Miolo escuro (fresta entre as folhas)
		cv.blob(ctr.x, ctr.y + rad * 0.02, rad * 0.8, rad * 0.8 * squash, 0.0, ramp[0], 1.0, 0.97)
		var leaves: Array = []
		var count: int = rng.randi_range(330, 420)
		for l: int in count:
			# ponto no hemisfério da frente, mais denso na borda (silhueta cheia)
			var th: float = rng.randf() * TAU
			var rr: float = sqrt(rng.randf()) * 0.96 + 0.04
			if rng.randf() < 0.35:
				rr = rng.randf_range(0.82, 1.0)
			var lobe: float = 1.0 + 0.09 * sin(float(lobes) * th + ph1) + 0.05 * sin(float(lobes + 2) * th + ph2)
			var x: float = cos(th) * rr
			var y: float = sin(th) * rr
			var z: float = sqrt(maxf(1.0 - rr * rr, 0.0))
			leaves.append([x, y, z, th, lobe])
		leaves.sort_custom(func(a: Array, b: Array) -> bool: return float(a[2]) < float(b[2]))
		for lf: Array in leaves:
			var x: float = lf[0]
			var y: float = lf[1]
			var z: float = lf[2]
			var lobe: float = lf[4]
			var p: Vector2 = ctr + Vector2(x, y * squash) * rad * lobe * 0.86
			var n := Vector3(x, -y, z).normalized()
			var dif: float = clampf((n.dot(light) + 0.35) / 1.35, 0.0, 1.0)
			var t: float = clampf(0.12 + 0.82 * dif + rng.randf_range(-0.1, 0.1), 0.0, 1.0)
			# folha aponta para fora (na borda) e um pouco para baixo (peso)
			var ang: float = atan2(y, x) + rng.randf_range(-0.7, 0.7)
			if z > 0.75:
				ang = rng.randf() * TAU
			ang = lerp_angle(ang, PI * 0.5, 0.18)
			var ll: float = rng.randf_range(24.0, 36.0) * lsize
			var lw: float = rng.randf_range(7.0, 10.0) * lsize
			var start: Vector2 = p - Vector2(cos(ang), sin(ang)) * ll * 0.35
			var c0: Color = PL.ramp_at(ramp, t - 0.14)
			var c1: Color = PL.ramp_at(ramp, t + 0.04)
			leaf(cv, start, ang, ll, lw, rng.randf_range(-0.6, 0.6), c0, c1)
			# brilho na metade de cima da folha (luz só de cima)
			if t > 0.45:
				var hl: Vector2 = start + Vector2(0.0, -lw * 0.3)
				leaf(cv, hl, ang, ll * 0.7, lw * 0.4, 0.0, PL.ramp_at(ramp, t + 0.08), PL.ramp_at(ramp, t + 0.16), 0.55)
	save_card(cv, "foliage/leaf_clumps_" + fam)


# ---------------------------------------------------------------------------
# Andares de conífera: atlas 4 x 2 de células 256 (1024x512).
# Células 0..5: andares (do mais largo ao mais estreito); 6, 7: pontas da copa (extra).
# O topo do andar fica no alto da célula e os galhos serrilhados caem para baixo.
# ---------------------------------------------------------------------------

func _conifer_tiers() -> void:
	var cell: int = 256 * SS
	var cv := PL.Canvas.new(cell * 4, cell * 2, false, false)
	var ramp: Array = ramp_of(CONIFER)
	cv.fill(ramp[1], 0.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 8401
	var widths: Array = [0.39, 0.37, 0.35, 0.32, 0.29, 0.26]
	for k: int in 6:
		var org := Vector2((k % 4) * cell, (k / 4) * cell)
		_tier(cv, rng, org, cell, float(widths[k]), 0.08, 0.84, ramp)
	for k: int in 2:
		var org := Vector2((6 + k) % 4 * cell, cell)
		_tier(cv, rng, org, cell, 0.17 + 0.03 * k, 0.05, 0.9, ramp)
	save_card(cv, "foliage/conifer_tiers")


func _tier(cv: PL.Canvas, rng: RandomNumberGenerator, org: Vector2, cell: int, half_w: float, top: float, bottom: float, ramp: Array) -> void:
	var cx: float = org.x + cell * 0.5
	var y_top: float = org.y + cell * top
	var y_bot: float = org.y + cell * bottom
	var hw: float = cell * half_w
	var hgt: float = y_bot - y_top
	# 1. Fundo escuro: triângulo de lados levemente côncavos (galhos caídos) com a barra serrilhada
	var poly := PackedVector2Array()
	poly.append(Vector2(cx, y_top))
	for s: int in range(1, 9):
		var t: float = float(s) / 8.0
		poly.append(Vector2(cx + hw * 0.92 * pow(t, 0.85), y_top + hgt * 0.9 * t))
	var teeth: int = rng.randi_range(7, 10)
	for s: int in range(teeth * 2 + 1):
		var t: float = 1.0 - float(s) / float(teeth * 2)
		var x: float = cx + hw * 0.92 * (2.0 * t - 1.0)
		var tip: bool = s % 2 == 0
		var yy: float = y_bot - (0.0 if tip else rng.randf_range(0.05, 0.1) * hgt) - hgt * 0.1 * (1.0 - absf(2.0 * t - 1.0)) * 0.0
		poly.append(Vector2(x, yy))
	for s: int in range(8, 0, -1):
		var t: float = float(s) / 8.0
		poly.append(Vector2(cx - hw * 0.92 * pow(t, 0.85), y_top + hgt * 0.9 * t))
	cv.poly_fill(poly, ramp[1])
	# 2. Almofadas de agulhas em fileiras (de cima para baixo: a de baixo cobre a de cima)
	var rows: int = 6
	for r: int in rows:
		var ty: float = (float(r) + 0.8) / float(rows)
		var yy: float = y_top + hgt * ty * 0.9
		var span: float = hw * 0.92 * pow(ty, 0.85)
		var pads: int = maxi(2, roundi(span / (cell * 0.05))) + 1
		for k: int in pads:
			var fx: float = float(k) / float(pads - 1) * 2.0 - 1.0
			var px: float = cx + fx * span * 1.02 + rng.randf_range(-5.0, 5.0)
			var pc := Vector2(px, yy + rng.randf_range(-6.0, 6.0) + absf(fx) * hgt * 0.03)
			var sz: float = cell * rng.randf_range(0.09, 0.12) * (0.75 + 0.4 * ty)
			var lit: float = 0.2 + 0.22 * (1.0 - absf(fx)) + 0.08 * (1.0 - ty)
			_needle_pad(cv, rng, pc, sz, fx, lit, ramp)
	# 3. Ponta de cima (o ápice do andar), clara
	_needle_pad(cv, rng, Vector2(cx, y_top + hgt * 0.1), cell * 0.06, 0.0, 0.55, ramp)


## Almofada de galho de conífera vista de lado: agulhas caindo (escuras embaixo) e pontas de cima claras.
func _needle_pad(cv: PL.Canvas, rng: RandomNumberGenerator, p: Vector2, sz: float, side: float, lit: float, ramp: Array) -> void:
	var out_dir: float = 0.0 if side >= 0.0 else PI
	# agulhas de baixo: caem para fora e para baixo
	for n: int in 22:
		var a: float = PI * 0.5 + rng.randf_range(-1.2, 1.2) + side * 0.6
		var ln: float = sz * rng.randf_range(0.7, 1.25)
		var pts: PackedVector2Array = PL.arc_pts(p + Vector2(rng.randf_range(-0.4, 0.4) * sz, rng.randf_range(-0.3, 0.1) * sz), a, ln, rng.randf_range(-0.5, 0.5), 3)
		cv.stroke(pts, PL.taper(3, 2.0 * SS * 0.7 + 0.4, 0.5), PL.ramp_at(ramp, lit - 0.12), PL.ramp_at(ramp, lit + 0.06), 1.0)
	# agulhas de cima: curtas, saindo para cima e para fora, claras (luz do céu)
	for n: int in 14:
		var a: float = -PI * 0.5 + rng.randf_range(-1.2, 1.2) * 0.9 + side * 0.7
		var ln: float = sz * rng.randf_range(0.45, 0.8)
		var pts: PackedVector2Array = PL.arc_pts(p + Vector2(rng.randf_range(-0.45, 0.45) * sz, rng.randf_range(-0.05, 0.25) * sz), a, ln, rng.randf_range(-0.4, 0.4), 3)
		cv.stroke(pts, PL.taper(3, 1.9 * SS * 0.7 + 0.4, 0.5), PL.ramp_at(ramp, lit + 0.1), PL.ramp_at(ramp, lit + 0.38), 1.0)


# ---------------------------------------------------------------------------
# Casca (256x512 = 4 x 8 unidades, seamless nos 2 eixos; pedido: vertical). Fibras verticais e
# musgo na base: y = 512 (v = 1) fica no chão; o musgo ocupa de ~0,1 a ~2 unidades acima da base.
# ---------------------------------------------------------------------------

func _bark() -> void:
	var w: int = 256 * SS
	var h: int = 512 * SS
	var cv := PL.Canvas.new(w, h, true, true)
	var ramp: Array = [c("#3A291E"), c("#4A3426"), c("#634630"), c("#7A5638"), c("#937048"), c("#A88058")]
	var rng := RandomNumberGenerator.new()
	rng.seed = 8501
	# campo esticado na vertical: muda devagar em y (fibras)
	var f1: PackedFloat32Array = PL.pfield(w, h / 8, 6, 3, 8502, 0.4, 2, 0.5)
	var f2: PackedFloat32Array = PL.pfield(w, h, 3, 2, 8503, 0.8, 4, 0.5)
	var val := PackedFloat32Array()
	val.resize(w * h)
	# f1 tem 1/8 da altura: cada linha dele cobre 8 linhas da casca (fibras compridas, periódico)
	for y: int in h:
		var ys: int = y / 8
		for x: int in w:
			var v: float = 0.6 * f1[ys * w + x] + 0.4 * f2[y * w + x]
			val[y * w + x] = smoothstep(0.15, 0.85, v)
	for i: int in w * h:
		var col: Color = PL.ramp_at(ramp, 0.25 + 0.55 * val[i])
		cv.r[i] = col.r
		cv.g[i] = col.g
		cv.b[i] = col.b
		cv.a[i] = 1.0
		cv.z[i] = val[i] * 0.6
	# Placas e sulcos: traços verticais compridos e ondulados
	for k: int in 260:
		var x0: float = rng.randf() * w
		var y0: float = rng.randf() * h
		var length: float = rng.randf_range(60.0, 220.0)
		var pts := PackedVector2Array()
		for s: int in 9:
			var t: float = float(s) / 8.0
			pts.append(Vector2(x0 + sin(t * 3.0 + k) * rng.randf_range(2.0, 5.0), y0 + t * length))
		var dark: bool = rng.randf() < 0.55
		if dark:
			cv.stroke(pts, PL.taper(8, rng.randf_range(2.5, 4.5), 1.0), ramp[0], ramp[1], 0.85, 0, -0.5, 2)
		else:
			cv.stroke(pts, PL.taper(8, rng.randf_range(3.0, 6.0), 1.5), ramp[4], ramp[3], 0.55, 0, 0.35, 2)
	# Nós
	for k: int in 5:
		var p := Vector2(rng.randf() * w, rng.randf() * h * 0.8)
		var r: float = rng.randf_range(10.0, 18.0)
		cv.blob(p.x, p.y, r * 0.7, r, 0.0, ramp[1], 1.0, 0.6, 0, 0.0)
		cv.blob(p.x, p.y - r * 0.15, r * 0.4, r * 0.6, 0.0, ramp[0], 1.0, 0.5, 0, 0.0)
		cv.blob(p.x, p.y - r * 0.6, r * 0.5, r * 0.25, 0.0, ramp[4], 0.6, 0.4)
	# Musgo na base (perto de y = h, passando pela volta)
	var mramp: Array = [c("#2C4520"), c("#3F5F22"), c("#56702A"), c("#87A23A")]
	var nm: PackedFloat32Array = PL.pfield(w, h, 4, 3, 8504, 1.0, 2, 0.5)
	var spots: Array = []
	for k: int in 2600:
		var p := Vector2(rng.randf() * w, rng.randf() * h)
		var dist: float = 1.0 - p.y / h  # distância à base (y = h)
		var nmv: float = nm[cv.idx(int(p.x), int(p.y))]
		var dens: float = smoothstep(0.012, 0.035, dist) * (1.0 - smoothstep(0.06, 0.26, dist)) * smoothstep(0.3, 0.55, nmv + 0.3 * (1.0 - smoothstep(0.03, 0.1, dist)))
		if rng.randf() > dens:
			continue
		spots.append(p)
	spots.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.y < b.y)
	for p: Vector2 in spots:
		var r: float = rng.randf_range(6.0, 12.0)
		var t: float = rng.randf_range(0.0, 0.75)
		cv.blob(p.x, p.y, r * 1.25, r, rng.randf_range(-0.4, 0.4), PL.ramp_at(mramp, t), 1.0, 0.6, 0, 0.75)
		cv.blob(p.x, p.y - r * 0.35, r * 0.65, r * 0.4, 0.0, PL.ramp_at(mramp, t + 0.22), 0.65, 0.3)
	var out: PL.Canvas = cv.down2()
	PL.save_png(out.to_image(true), PL.TEX + "foliage/bark.png")
	PL.save_png(PL.normal_map(out.z, out.w, out.h, 4.0, 2, true, true), PL.TEX + "foliage/bark_n.png")


# ---------------------------------------------------------------------------
# Tufos de capim: atlas 4 x 2 de células 128 (512x256). Linha de cima: 4 tufos baixos (arena,
# largos e curtos, ocupam a metade de baixo da célula). Linha de baixo: 4 tufos altos (fora).
# A base de cada tufo fica na borda de baixo da célula.
# ---------------------------------------------------------------------------

func _grass_tufts() -> void:
	var cell: int = 128 * SS
	var cv := PL.Canvas.new(cell * 4, cell * 2, false, false)
	var ramp: Array = ramp_of(GRASS)
	cv.fill(ramp[2], 0.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 8601
	for k: int in 8:
		var tall: bool = k >= 4
		var org := Vector2((k % 4) * cell, (k / 4) * cell)
		var base := org + Vector2(cell * 0.5, cell - 4.0 * SS)
		var height: float = cell * (rng.randf_range(0.82, 0.9) if tall else rng.randf_range(0.36, 0.46))
		var spread: float = cell * (0.3 if tall else 0.4)
		var blades: int = rng.randi_range(22, 30) if tall else rng.randi_range(18, 26)
		var order: Array = []
		for b: int in blades:
			order.append([rng.randf(), b])
		order.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
		for e: Array in order:
			var front: float = e[0]
			var x0: float = rng.randf_range(-1.0, 1.0) * spread * 0.45
			var lean: float = x0 / spread * 1.4 + rng.randf_range(-0.35, 0.35)
			var ln: float = height * rng.randf_range(0.55, 1.0) / cos(clampf(lean * 0.6, -1.0, 1.0))
			var ang: float = -PI * 0.5 + lean * 0.6
			var bend: float = lean * rng.randf_range(0.4, 1.0)
			var pts: PackedVector2Array = PL.arc_pts(base + Vector2(x0, 0.0), ang, ln, bend, 5)
			var t: float = 0.35 + 0.55 * front
			var wb: float = rng.randf_range(2.4, 3.6) * SS
			cv.stroke(pts, PL.taper(5, wb, 0.5), PL.ramp_at(ramp, t - 0.35), PL.ramp_at(ramp, t + 0.12), 1.0)
	save_card(cv, "foliage/grass_tufts")


# ---------------------------------------------------------------------------
# Flores: atlas 4 x 4 de células 64 (256x256). Linhas 0..2: 12 grupinhos; linha 3: vazia.
# Base de cada grupinho na borda de baixo da célula.
# ---------------------------------------------------------------------------

const FLOWER_SETS: Array = [
	["pink"], ["white"], ["yellow"], ["blue"], ["lilac"], ["pink", "white"],
	["yellow", "white"], ["blue", "lilac"], ["pink"], ["white", "yellow"], ["yellow"], ["lilac", "pink"],
]


func _flowers() -> void:
	var cell: int = 64 * SS
	var cv := PL.Canvas.new(cell * 4, cell * 4, false, false)
	var ramp: Array = ramp_of(GRASS)
	cv.fill(ramp[2], 0.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 8701
	for k: int in 12:
		var org := Vector2((k % 4) * cell, (k / 4) * cell)
		var base := org + Vector2(cell * 0.5, cell - 3.0 * SS)
		var cols: Array = FLOWER_SETS[k]
		# folhas na base
		for l: int in rng.randi_range(4, 6):
			var a: float = -PI * 0.5 + rng.randf_range(-1.1, 1.1)
			leaf(cv, base + Vector2(rng.randf_range(-6, 6) * SS, 0), a, rng.randf_range(12.0, 20.0) * SS * 0.5, rng.randf_range(2.4, 3.4) * SS * 0.6, rng.randf_range(-0.6, 0.6), ramp[1], ramp[3])
		var blooms: int = rng.randi_range(3, 6)
		var heads: Array = []
		for b: int in blooms:
			var top := base + Vector2(rng.randf_range(-0.34, 0.34) * cell, -rng.randf_range(0.42, 0.78) * cell)
			var stem := PackedVector2Array([base + Vector2(rng.randf_range(-3, 3) * SS, 0), (base + top) * 0.5 + Vector2(rng.randf_range(-3, 3) * SS, 0), top])
			cv.stroke(stem, PackedFloat32Array([1.3 * SS * 0.6, 1.0 * SS * 0.6, 0.8 * SS * 0.6]), ramp[1], ramp[2], 1.0)
			heads.append([top, cols[b % cols.size()]])
		heads.sort_custom(func(a: Array, b: Array) -> bool: return (a[0] as Vector2).y < (b[0] as Vector2).y)
		for hd: Array in heads:
			var p: Vector2 = hd[0]
			var col: Color = c(FLOWERS[hd[1]])
			var pr: float = rng.randf_range(3.6, 5.0) * SS * 0.7
			var rot: float = rng.randf() * TAU
			for l: int in 5:
				var a: float = rot + float(l) * TAU / 5.0
				var lc: Vector2 = p + Vector2(cos(a), sin(a)) * pr * 0.85
				# pétala de baixo um pouco mais escura, de cima mais clara (luz de cima)
				var sh: float = -sin(a) * 0.12
				var pc: Color = col.lightened(sh) if sh > 0.0 else col.darkened(-sh)
				cv.blob(lc.x, lc.y, pr, pr * 0.72, a, pc, 1.0, 0.6)
			var mid_c: Color = c("#F4D04A") if hd[1] != "yellow" else c("#E39041")
			cv.blob(p.x, p.y, pr * 0.5, pr * 0.5, 0.0, mid_c, 1.0, 0.5)
	save_card(cv, "foliage/flowers")
