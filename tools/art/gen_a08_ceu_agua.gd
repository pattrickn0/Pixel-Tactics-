extends SceneTree
## A08, leva 2: água (lâmina e espuma da cascata), névoa, nuvens (puffs e mar), chama e arco-íris.
## Grava em assets/textures/scenery/{water,fx,sky}/. Prévia: gen_a08_preview_leva2.gd.
##   "$G" --headless --path . --script tools/art/gen_a08_ceu_agua.gd [-- streaks | foam | mist | puffs | sea | fire | rainbow]

const PL = preload("res://tools/art/paint_lib.gd")
const SS: int = 2

const WATER: Array = ["#5A7E9C", "#7FA2BE", "#9DBCD4", "#B6D0E3", "#D3E6F1", "#EAF6FC"]
# Nuvem: base lavanda escura -> topo branco-quente (f2: branco de verdade no topo)
const CLOUD: Array = ["#8C8498", "#9C9CB8", "#C8C0D4", "#ECE6EE", "#FFF6EC"]
const FIRE: Array = ["#B8501C", "#E39041", "#FFDA81", "#FFF2C0"]
# Arco-íris dessaturado, de fora (v = 0) para dentro (v = 1)
const RAINBOW: Array = ["#E89A98", "#EEBC88", "#EEE09A", "#ACD8A0", "#98BCE8", "#B4A0DC"]


func _initialize() -> void:
	var only: String = ""
	if OS.get_cmdline_user_args().size() > 0:
		only = OS.get_cmdline_user_args()[0]
	if only == "" or only == "streaks":
		_fall_streaks()
	if only == "" or only == "foam":
		_fall_foam()
	if only == "" or only == "mist":
		_mist_puff()
	if only == "" or only == "puffs":
		_cloud_puffs()
	if only == "" or only == "sea":
		_cloud_sea()
	if only == "" or only == "fire":
		_fire()
	if only == "" or only == "rainbow":
		_rainbow()
	quit()


static func c(s: String) -> Color:
	return Color.html(s)


static func ramp_of(list: Array) -> Array:
	var out: Array = []
	for s: String in list:
		out.append(c(s))
	return out


## Campo periódico esticado na vertical: fBm em (w, h / k) lido com interpolação linear em y (riscos).
static func vstreak_field(w: int, h: int, k: int, cells: int, seed_value: int) -> PackedFloat32Array:
	var lh: int = h / k
	var f: PackedFloat32Array = PL.pfield(w, lh, cells, 3, seed_value, 0.3, 2, 0.55)
	var out := PackedFloat32Array()
	out.resize(w * h)
	for y: int in h:
		var fy: float = float(y) / k
		var y0: int = floori(fy)
		var t: float = fy - y0
		var r0: int = posmod(y0, lh) * w
		var r1: int = posmod(y0 + 1, lh) * w
		for x: int in w:
			out[y * w + x] = lerpf(f[r0 + x], f[r1 + x], t)
	return out


# ---------------------------------------------------------------------------
# Lâmina da cascata (256x512, opaca, seamless nos 2 eixos; o shader rola em v).
# Riscos verticais do azul (#7FA2BE) ao quase branco (#EAF6FC), mais claros no meio da largura.
# ---------------------------------------------------------------------------

func _fall_streaks() -> void:
	var w: int = 256 * SS
	var h: int = 512 * SS
	var cv := PL.Canvas.new(w, h, true, true)
	var ramp: Array = ramp_of(WATER)
	var s1: PackedFloat32Array = vstreak_field(w, h, 16, 18, 13001)
	var s2: PackedFloat32Array = vstreak_field(w, h, 8, 7, 13002)
	var big: PackedFloat32Array = PL.pfield(w, h, 2, 2, 13003, 0.8, 8)
	for y: int in h:
		for x: int in w:
			var i: int = y * w + x
			var mid: float = 0.5 - 0.5 * cos(TAU * float(x) / w)  # 0 nas bordas, 1 no meio
			var t: float = 0.5 + 0.34 * (s1[i] - 0.5) * 2.0 * 0.6 + 0.16 * (s2[i] - 0.5) * 2.0 + 0.16 * mid + 0.06 * (big[i] - 0.5)
			var col: Color = PL.ramp_at(ramp, clampf(t, 0.08, 0.98))
			cv.r[i] = col.r
			cv.g[i] = col.g
			cv.b[i] = col.b
			cv.a[i] = 1.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 13004
	# riscos de espuma (claros) e de água funda (escuros), compridos e finos
	for k: int in 220:
		var p := Vector2(rng.randf() * w, rng.randf() * h)
		var length: float = rng.randf_range(120.0, 420.0)
		var light: bool = rng.randf() < 0.65
		var pts := PackedVector2Array()
		for s: int in 7:
			pts.append(p + Vector2(sin(float(s) * 0.9 + k) * 2.0, length * float(s) / 6.0))
		var r0: float = rng.randf_range(1.6, 4.0)
		var col: Color = ramp[5] if light else ramp[1]
		cv.stroke(pts, PackedFloat32Array([0.6, r0 * 0.7, r0, r0, r0 * 0.8, r0 * 0.5, 0.5]), col, col, rng.randf_range(0.25, 0.5) if light else rng.randf_range(0.15, 0.3), 0)
	var out: PL.Canvas = cv.down2()
	PL.save_png(out.to_image(true), PL.TEX + "water/fall_streaks.png")


# ---------------------------------------------------------------------------
# Espuma da quina (512x128, alfa suave, seamless na horizontal): faixa densa de espuma no alto
# (v de 0 a ~0,35) e cortinas de gota caindo e sumindo até a borda de baixo.
# ---------------------------------------------------------------------------

func _fall_foam() -> void:
	var w: int = 512 * SS
	var h: int = 128 * SS
	var cv := PL.Canvas.new(w, h, true, false)
	var ramp: Array = ramp_of(WATER)
	cv.fill(ramp[4], 0.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 13101
	# cortinas: riscos que descem da faixa, ficando transparentes para baixo
	for k: int in 260:
		var x: float = rng.randf() * w
		var y0: float = h * rng.randf_range(0.2, 0.35)
		var length: float = h * rng.randf_range(0.25, 0.65)
		var pts := PackedVector2Array()
		for s: int in 6:
			pts.append(Vector2(x + rng.randf_range(-1.0, 1.0), y0 + length * float(s) / 5.0))
		var r0: float = rng.randf_range(2.0, 5.0)
		var col: Color = PL.ramp_at(ramp, rng.randf_range(0.7, 1.0))
		var op: float = rng.randf_range(0.35, 0.7)
		for s: int in 5:
			var seg := PackedVector2Array([pts[s], pts[s + 1]])
			var fade: float = 1.0 - float(s) / 5.0
			cv.stroke(seg, PackedFloat32Array([r0 * (0.5 + 0.5 * fade), r0 * (0.4 + 0.5 * fade)]), col, col, op * fade * fade)
	# gotas soltas
	for k: int in 180:
		var p := Vector2(rng.randf() * w, h * rng.randf_range(0.35, 0.9))
		var r: float = rng.randf_range(1.5, 3.2)
		var fade: float = 1.0 - smoothstep(0.35, 0.95, p.y / h)
		cv.blob(p.x, p.y, r, r * 1.3, 0.0, ramp[5], 0.8 * fade, 0.5)
	# faixa de espuma: bolhas sobrepostas, mais claras em cima (luz de cima)
	for k: int in 900:
		var x: float = rng.randf() * w
		var y: float = h * clampf(0.16 + 0.1 * rng.randfn(0.0, 1.0), 0.04, 0.36)
		var r: float = rng.randf_range(7.0, 18.0)
		var t: float = clampf(0.75 + 0.25 * (1.0 - y / (h * 0.36)) + rng.randf_range(-0.12, 0.05), 0.5, 1.0)
		cv.blob(x, y + r * 0.25, r * 1.2, r * 0.9, 0.0, PL.ramp_at(ramp, t - 0.12), 0.6, 0.1)
		cv.blob(x, y - r * 0.1, r * 1.0, r * 0.7, 0.0, PL.ramp_at(ramp, t), 0.7, 0.15)
	var out: PL.Canvas = cv.down2()
	var img: Image = out.to_image(false)
	PL.dilate_rgb(img, 64, true)
	img = PL.roll(img, PL.best_roll(img, true, 2), 0)
	PL.save_png(img, PL.TEX + "water/fall_foam.png")


# ---------------------------------------------------------------------------
# Puff de névoa (256x256, alfa suave): branco-lavanda, borda fofa, some antes da borda do quadro.
# ---------------------------------------------------------------------------

func _mist_puff() -> void:
	var n: int = 256 * SS
	var cv := PL.Canvas.new(n, n, false, false)
	cv.fill(c("#E6E2EE"), 0.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 13201
	var ctr := Vector2(n * 0.5, n * 0.52)
	var blobs: Array = []
	for k: int in 26:
		var a: float = rng.randf() * TAU
		var rr: float = sqrt(rng.randf()) * n * 0.17
		var p: Vector2 = ctr + Vector2(cos(a) * rr * 1.15, sin(a) * rr * 0.8)
		blobs.append([p, n * rng.randf_range(0.14, 0.23)])
	blobs.sort_custom(func(p: Array, q: Array) -> bool: return (p[0] as Vector2).y > (q[0] as Vector2).y)
	for b: Array in blobs:
		var p: Vector2 = b[0]
		var r: float = b[1]
		var top: float = clampf(1.0 - (p.y - (ctr.y - n * 0.2)) / (n * 0.4), 0.0, 1.0)
		cv.blob(p.x, p.y, r, r * 0.9, 0.0, c("#DCD6E6").lerp(c("#F6F2F8"), top), 0.55, 0.0)
		cv.blob(p.x, p.y - r * 0.2, r * 0.7, r * 0.55, 0.0, c("#F6F2F8"), 0.35, 0.0)
	# garante alfa 0 na borda do quadro (o puff nunca é cortado)
	for y: int in n:
		for x: int in n:
			var d: float = Vector2(x + 0.5, y + 0.5).distance_to(Vector2(n, n) * 0.5) / (n * 0.5)
			var i: int = y * n + x
			cv.a[i] *= 1.0 - smoothstep(0.82, 0.97, d)
	var img: Image = cv.down2().to_image(false)
	PL.dilate_rgb(img, 32)
	PL.save_png(img, PL.TEX + "fx/mist_puff.png")


# ---------------------------------------------------------------------------
# Nuvens: cúmulos (atlas 2 x 2 de 512, alfa suave). Bossas redondas no alto (couve-flor), base mais
# reta. Cada pixel mostra a bossa mais à frente; luz de cima: topo branco-quente (#FFF6EC), base lavanda
# escura (#9C9CB8 a #8C8498), frestas entre bossas em lavanda.
# ---------------------------------------------------------------------------

func _cloud_puffs() -> void:
	var cell: int = 512 * SS
	var cv := PL.Canvas.new(cell * 2, cell * 2, false, false)
	var ramp: Array = ramp_of(CLOUD)
	cv.fill(ramp[2], 0.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 13301
	for k: int in 4:
		var org := Vector2i((k % 2) * cell, (k / 2) * cell)
		var bumps: Array = []
		var base_y: float = cell * rng.randf_range(0.7, 0.76)
		var span: float = cell * rng.randf_range(0.3, 0.34)
		var cx: float = cell * 0.5 + rng.randf_range(-0.03, 0.03) * cell
		# cúpula principal e bossas em arco por cima, menores nas pontas
		var nb: int = rng.randi_range(7, 10)
		for j: int in nb:
			var f: float = (float(j) + rng.randf_range(-0.25, 0.25)) / float(nb - 1) * 2.0 - 1.0
			var r: float = cell * (0.2 - 0.1 * absf(f)) * rng.randf_range(0.8, 1.15)
			var x: float = cx + f * span
			var y: float = base_y - r * 0.6 - cell * 0.27 * (1.0 - f * f) * rng.randf_range(0.75, 1.1)
			bumps.append([Vector2(x, y), r])
		# corpo: bossas largas no miolo (sem buraco embaixo)
		for j: int in 3:
			var f: float = float(j - 1) * 0.55
			bumps.append([Vector2(cx + f * span, base_y - cell * 0.1), cell * rng.randf_range(0.15, 0.19)])
		for j: int in rng.randi_range(4, 7):
			var x: float = cx + rng.randf_range(-0.8, 0.8) * span
			var r: float = cell * rng.randf_range(0.07, 0.12)
			bumps.append([Vector2(x, base_y - r * rng.randf_range(0.2, 0.6)), r])
		var top_y: float = INF
		for b: Array in bumps:
			top_y = minf(top_y, (b[0] as Vector2).y - float(b[1]))
		_cloud_cell(cv, org, cell, bumps, base_y, top_y, ramp, rng)
	var img: Image = cv.down2().to_image(false)
	PL.dilate_rgb(img, 32)
	PL.save_png(img, PL.TEX + "sky/cloud_puffs.png")
	var st: Dictionary = cloud_stats(img)
	print("cloud_puffs: L >= 235 em %.0f%% dos opacos (>= 15), base #%s" % [float(st["white"]) * 100.0, (st["base"] as Color).to_html(false).to_upper()])


## (f2) Fração dos opacos (alfa >= 128) com L >= 235 e cor média do quinto de baixo da parte opaca de
## cada célula (a base da nuvem).
static func cloud_stats(img: Image) -> Dictionary:
	var w: int = img.get_width()
	var d: PackedByteArray = img.get_data()
	var n: int = 0
	var nw: int = 0
	var acc := Vector3.ZERO
	var nb: int = 0
	var cell: int = w / 2
	for k: int in 4:
		var ox: int = (k % 2) * cell
		var oy: int = (k / 2) * cell
		var y0: int = cell
		var y1: int = 0
		for y: int in cell:
			for x: int in cell:
				var i: int = ((oy + y) * w + ox + x) * 4
				if d[i + 3] < 128:
					continue
				y0 = mini(y0, y)
				y1 = maxi(y1, y)
				n += 1
				if 0.299 * d[i] + 0.587 * d[i + 1] + 0.114 * d[i + 2] >= 235.0:
					nw += 1
		var yb: int = y1 - (y1 - y0) / 5
		for y: int in range(yb, y1 + 1):
			for x: int in cell:
				var i: int = ((oy + y) * w + ox + x) * 4
				if d[i + 3] < 128:
					continue
				acc += Vector3(d[i], d[i + 1], d[i + 2])
				nb += 1
	acc /= float(maxi(nb, 1)) * 255.0
	return {"white": float(nw) / float(maxi(n, 1)), "base": Color(acc.x, acc.y, acc.z)}


## Uma nuvem: a altura é a união suave (log-soma-exp) das bossas, então as bossas se fundem sem quina;
## a normal vem do gradiente da altura. Tom = luz de cima (normal) + gradiente vertical (topo branco,
## base lavanda) - frestas (altura abaixo da média local).
const CLOUD_K: float = 14.0


func _cloud_cell(cv: PL.Canvas, org: Vector2i, cell: int, bumps: Array, base_y: float, top_y: float, ramp: Array, rng: RandomNumberGenerator) -> void:
	var n: int = cell * cell
	var S := PackedFloat32Array()
	S.resize(n)
	var cov := PackedFloat32Array()
	cov.resize(n)
	var edge_n := FastNoiseLite.new()
	edge_n.seed = 13310 + org.x + org.y
	edge_n.frequency = 1.0 / 90.0
	for b: Array in bumps:
		var c0: Vector2 = b[0]
		var r: float = b[1]
		var zb: float = (c0.y - top_y) * 0.12  # bossas de baixo um pouco à frente
		for y: int in range(maxi(0, floori(c0.y - r - 4.0)), mini(cell, ceili(c0.y + r + 4.0))):
			for x: int in range(maxi(0, floori(c0.x - r - 4.0)), mini(cell, ceili(c0.x + r + 4.0))):
				var dx: float = (x + 0.5 - c0.x) / r
				var dy: float = (y + 0.5 - c0.y) / r
				var d0: float = sqrt(dx * dx + dy * dy)
				var dd: float = d0 + 0.04 * edge_n.get_noise_2d(x + org.x, y + org.y)
				var i: int = y * cell + x
				cov[i] = maxf(cov[i], clampf((1.0 - dd) * r / 14.0, 0.0, 1.0))
				if d0 >= 1.0:
					continue
				var h: float = zb + r * sqrt(1.0 - d0 * d0)
				S[i] += exp(h / CLOUD_K)
	var H := PackedFloat32Array()
	H.resize(n)
	for i: int in n:
		H[i] = CLOUD_K * log(S[i]) if S[i] > 0.0 else 0.0
	var Hs: PackedFloat32Array = PL.blur(H, cell, cell, 2, false, false, 2)
	var Hb: PackedFloat32Array = PL.blur(H, cell, cell, 22, false, false, 2)
	var light := Vector3(0.0, 0.8, 0.6).normalized()
	for y: int in cell:
		var v: float = clampf((float(y) - top_y) / maxf(base_y - top_y, 1.0), 0.0, 1.0)
		for x: int in cell:
			var i: int = y * cell + x
			var a: float = cov[i]
			# base mais reta: corta embaixo com borda macia
			a *= 1.0 - smoothstep(base_y - 4.0, base_y + 20.0, float(y) + 10.0 * edge_n.get_noise_2d(x + org.x + 500.0, 0.0))
			if a <= 0.0:
				continue
			var gx: float = (Hs[y * cell + mini(x + 1, cell - 1)] - Hs[y * cell + maxi(x - 1, 0)]) * 0.5
			var gy: float = (Hs[mini(y + 1, cell - 1) * cell + x] - Hs[maxi(y - 1, 0) * cell + x]) * 0.5
			var nn := Vector3(-gx, gy, 1.0).normalized()
			var dif: float = clampf(nn.dot(light) * 0.5 + 0.5, 0.0, 1.0)
			var t: float = 0.42 * dif + 0.72 * (1.0 - v) - 0.02
			t -= 0.3 * clampf((Hb[i] - H[i]) / 30.0, 0.0, 1.0)
			t -= 0.22 * smoothstep(0.7, 1.0, v)
			var col: Color = PL.ramp_at(ramp, clampf(t, 0.0, 1.0))
			var j: int = (org.y + y) * cv.w + org.x + x
			cv.r[j] = col.r
			cv.g[j] = col.g
			cv.b[j] = col.b
			cv.a[j] = a


# ---------------------------------------------------------------------------
# Mar de nuvens visto de cima (1024x1024, opaco, seamless nos 2 eixos): bossas de vários tamanhos
# num toro; o miolo de cada bossa branco-quente e as frestas em lavanda (luz de cima, sem lado).
# ---------------------------------------------------------------------------

func _cloud_sea() -> void:
	var n: int = 1024
	var ramp: Array = ramp_of(CLOUD)
	var rng := RandomNumberGenerator.new()
	rng.seed = 13401
	var S := PackedFloat32Array()
	S.resize(n * n)
	var big: PackedFloat32Array = PL.pfield(n, n, 3, 3, 13402, 0.9, 8)
	var k_s: float = 10.0
	# bossas grandes (montes) e pequenas por cima; a altura base vem do campo grande
	for k: int in 520:
		var p := Vector2(rng.randf() * n, rng.randf() * n)
		var g: float = big[int(p.y) * n + int(p.x)]
		var r: float = rng.randf_range(26.0, 70.0) * (0.6 + 0.8 * g)
		var zb: float = g * 50.0
		for y: int in range(floori(p.y - r), ceili(p.y + r) + 1):
			for x: int in range(floori(p.x - r), ceili(p.x + r) + 1):
				var dx: float = (x + 0.5 - p.x) / r
				var dy: float = (y + 0.5 - p.y) / r
				var dd: float = dx * dx + dy * dy
				if dd >= 1.0:
					continue
				var i: int = posmod(y, n) * n + posmod(x, n)
				S[i] += exp((zb + r * 0.75 * sqrt(1.0 - dd)) / k_s)
	# chão de nuvem por baixo de tudo (sem buraco)
	for i: int in n * n:
		S[i] += exp((big[i] * 30.0 - 10.0) / k_s)
	var H := PackedFloat32Array()
	H.resize(n * n)
	var hlo: float = INF
	var hhi: float = -INF
	for i: int in n * n:
		H[i] = k_s * log(S[i])
		hlo = minf(hlo, H[i])
		hhi = maxf(hhi, H[i])
	var Hs: PackedFloat32Array = PL.blur(H, n, n, 1, true, true, 2)
	var Hb: PackedFloat32Array = PL.blur(H, n, n, 20, true, true, 2)
	var light := Vector3(0.25, 0.35, 0.9).normalized()
	var bytes := PackedByteArray()
	bytes.resize(n * n * 4)
	for y: int in n:
		for x: int in n:
			var i: int = y * n + x
			var gx: float = (Hs[y * n + posmod(x + 1, n)] - Hs[y * n + posmod(x - 1, n)]) * 0.5
			var gy: float = (Hs[posmod(y + 1, n) * n + x] - Hs[posmod(y - 1, n) * n + x]) * 0.5
			var nn := Vector3(-gx, gy, 1.2).normalized()
			# luz quase de cima (o mar é visto de cima e gira com a câmera: sem lado forte)
			var dif: float = clampf(nn.z * 0.75 + 0.25 * nn.dot(light), 0.0, 1.0)
			var hn: float = (H[i] - hlo) / maxf(hhi - hlo, 1.0)
			var t: float = -0.02 + 0.42 * dif + 0.62 * pow(hn, 1.7)
			t -= 0.4 * clampf((Hb[i] - H[i]) / 26.0, 0.0, 1.0)
			var col: Color = PL.ramp_at(ramp, clampf(t, 0.05, 1.0))
			bytes[i * 4] = clampi(roundi(col.r * 255.0), 1, 254)
			bytes[i * 4 + 1] = clampi(roundi(col.g * 255.0), 1, 254)
			bytes[i * 4 + 2] = clampi(roundi(col.b * 255.0), 1, 254)
			bytes[i * 4 + 3] = 255
	PL.save_png(Image.create_from_data(n, n, false, Image.FORMAT_RGBA8, bytes), PL.TEX + "sky/cloud_sea.png")


# ---------------------------------------------------------------------------
# Chama (512x192: 4 quadros de 128x192, alfa suave). Base no pé do quadro, línguas subindo.
# O ruído é periódico em y com período de 4 quadros: o quadro 4 seria igual ao 0 (laço sem salto).
# ---------------------------------------------------------------------------

func _fire() -> void:
	var fw: int = 128 * SS
	var fh: int = 192 * SS
	var cv := PL.Canvas.new(fw * 4, fh, false, false)
	var ramp: Array = ramp_of(FIRE)
	cv.fill(ramp[1], 0.0)
	var n1 := PL.PNoise.new(4, 8, 13501)
	var n2 := PL.PNoise.new(8, 16, 13502)
	for k: int in 4:
		for y: int in fh:
			var v: float = float(y) / fh  # 0 em cima
			var hgt: float = 1.0 - v  # altura acima do pé
			for x: int in fw:
				var u: float = (float(x) + 0.5) / fw
				# deslocamento lateral ondulando, mais forte em cima
				var sway: float = 0.08 * n1.at(u * 4.0 + 1.7, v * 8.0 + float(k) * 2.0) * hgt
				# perfil em gota: pé arredondado, afinando até a ponta (s = 0 no pé, 1 na ponta)
				var sp: float = clampf((0.93 - v) / 0.86, 0.0, 1.0)
				var qb: float = clampf(1.0 - sp / 0.26, 0.0, 1.0)
				var hw: float = 0.3 * pow(1.0 - sp, 1.3) * sqrt(1.0 - qb * qb) + 0.001
				var shape: float = 1.0 - absf(u - 0.5 - sway) / hw
				var turb: float = 0.5 + 0.5 * (0.65 * n1.at(u * 4.0, v * 8.0 + float(k) * 2.0) + 0.35 * n2.at(u * 8.0, v * 16.0 + float(k) * 4.0))
				var f: float = shape - 0.95 * turb * sp + 0.15 * (1.0 - sp)
				if v > 0.93:
					f = -1.0
				if f <= 0.0:
					continue
				var inten: float = clampf(f / 0.8, 0.0, 1.0)
				var col: Color = PL.ramp_at(ramp, clampf(pow(inten, 1.35) * 1.05 + 0.12 * (v - 0.6), 0.0, 1.0))
				var i: int = y * cv.w + k * fw + x
				cv.r[i] = col.r
				cv.g[i] = col.g
				cv.b[i] = col.b
				cv.a[i] = smoothstep(0.0, 0.12, f)
	var img: Image = cv.down2().to_image(false)
	PL.dilate_rgb(img, 24)
	PL.save_png(img, PL.TEX + "fx/fire_flipbook.png")


# ---------------------------------------------------------------------------
# Arco-íris (256x32, alfa suave): 6 faixas suaves ao longo de v (vermelho em v = 0, por fora; violeta em
# v = 1, por dentro), dessaturadas, apagando nas bordas de cima e de baixo. Igual ao longo de u.
# ---------------------------------------------------------------------------

func _rainbow() -> void:
	var w: int = 256
	var h: int = 32
	var ramp: Array = ramp_of(RAINBOW)
	var bytes := PackedByteArray()
	bytes.resize(w * h * 4)
	for y: int in h:
		var v: float = (float(y) + 0.5) / h
		# faixas: centro de cada uma em (k + 0,5) / 6, misturadas suavemente
		var f: float = clampf((v - 0.08) / 0.84, 0.0, 1.0) * 5.0
		var k0: int = mini(floori(f), 4)
		var t: float = smoothstep(0.25, 0.75, f - k0)
		var col: Color = (ramp[k0] as Color).lerp(ramp[k0 + 1], t)
		var a: float = smoothstep(0.0, 0.2, v) * (1.0 - smoothstep(0.8, 1.0, v)) * 0.85
		for x: int in w:
			var o: int = (y * w + x) * 4
			bytes[o] = clampi(roundi(col.r * 255.0), 1, 254)
			bytes[o + 1] = clampi(roundi(col.g * 255.0), 1, 254)
			bytes[o + 2] = clampi(roundi(col.b * 255.0), 1, 254)
			bytes[o + 3] = clampi(roundi(a * 255.0), 0, 255)
	PL.save_png(Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, bytes), PL.TEX + "fx/rainbow.png")
