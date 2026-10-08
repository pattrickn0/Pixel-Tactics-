extends SceneTree
## A08, leva 1: chão (grama a/b, máscara de mistura) e decalques da arena (terra, círculo, pedras).
## Grava em assets/textures/scenery/{ground,decals}/. Prévia: docs/art-preview/a08-chao.png (gen_a08_preview_chao.gd).
## Rodar da raiz do projeto (só um conjunto: -- grass | mask | dirt | ring | slabs):
##   "$G" --headless --path . --script tools/art/gen_a08_chao.gd

const PL = preload("res://tools/art/paint_lib.gd")
const SS: int = 2  # supersampling

# Paleta (direção de arte + medida na referência)
const GRASS: Array = ["#2C4520", "#3F5F22", "#5E8424", "#7FA22C", "#A8C447"]
const DIRT_DARK: Array = ["#6E4228", "#74502C", "#8A5E34"]
const DIRT_MID: Array = ["#AE7F3E", "#BC8C47"]
const DIRT_LIGHT: Array = ["#C89A55", "#D6AA66"]


func _initialize() -> void:
	var only: String = ""
	if OS.get_cmdline_user_args().size() > 0:
		only = OS.get_cmdline_user_args()[0]
	if only == "" or only == "grass":
		_grass("grass_a", 11, false)
		_grass("grass_b", 23, true)
	if only == "" or only == "mask":
		_blend_mask()
	if only == "" or only == "dirt":
		_arena_dirt()
	if only == "" or only == "ring":
		_arena_ring()
	if only == "" or only == "slabs":
		_arena_slabs()
	quit()


static func c(s: String) -> Color:
	return Color.html(s)


# ---------------------------------------------------------------------------
# Grama (512x512, 8 x 8 unidades, seamless nos 2 eixos)
# ---------------------------------------------------------------------------

func _grass(file: String, seed_base: int, variant_b: bool) -> void:
	var n: int = 512 * SS
	var cv := PL.Canvas.new(n, n, true, true)
	# (r1) tufos de 0,25 a 0,6 com topo claro e fendas escuras entre eles; manchas grandes fracas
	# rampa: fenda, base do tufo, meio, ponta, ponta ao sol
	var ramp: Array = []
	if variant_b:
		ramp = [c("#3E5619"), c("#506A1E"), c("#6A8A26"), c("#90AE32"), c("#AEC84C")]
	else:
		ramp = [c("#3F5A1A"), c("#4F6A1E"), c("#5E8424"), c("#7FA22C"), c("#A8C447")]
	var big: PackedFloat32Array = PL.pfield(n, n, 2, 3, seed_base * 1000 + 1, 1.0, 8, 0.55)
	var lean_f: PackedFloat32Array = PL.pfield(n, n, 3, 2, seed_base * 1000 + 3, 0.5, 8)
	# fundo: a fenda escura, com variação fraca
	for i: int in n * n:
		var col: Color = ramp[0].lerp(ramp[1], 0.25 + 0.3 * big[i])
		cv.r[i] = col.r
		cv.g[i] = col.g
		cv.b[i] = col.b
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_base * 7919 + 5
	var tufts: Array = []
	for k: int in 1300:
		tufts.append(Vector2(rng.randf() * n, rng.randf() * n))
	tufts.sort_custom(func(p: Vector2, q: Vector2) -> bool: return p.y < q.y)
	var u: float = 64.0 * SS
	# parâmetros sorteados antes, para poder repintar a faixa de cima no fim (ordem certa na volta)
	var plan: Array = []
	for p: Vector2 in tufts:
		var pi: int = cv.idx(int(p.x), int(p.y))
		var tone: float = 0.14 * (big[pi] - 0.5) + rng.randf_range(-0.05, 0.05)
		# inclinação comum (para cima e um pouco para a direita), variando devagar
		var lean: float = -PI * 0.5 + 0.35 + 0.8 * (lean_f[pi] - 0.5)
		var rad: float = u * rng.randf_range(0.14, 0.31)
		var base: Vector2 = p + Vector2(0.0, rad * 0.45)
		var blades: Array = []
		var order: Array = []
		for b: int in rng.randi_range(7, 10):
			order.append(rng.randf())
		order.sort()
		for f: float in order:
			# f = quão "na frente/em cima" a lâmina está: as de trás são mais escuras
			var ang: float = lean + rng.randf_range(-0.75, 0.75)
			var ln: float = rad * rng.randf_range(1.0, 1.7)
			var st: Vector2 = base + Vector2(rng.randf_range(-0.55, 0.55) * rad, rng.randf_range(-0.15, 0.2) * rad)
			var pts: PackedVector2Array = PL.arc_pts(st, ang, ln, rng.randf_range(-0.7, 0.7), 4)
			var w0: float = rad * rng.randf_range(0.16, 0.22)
			blades.append([pts, w0, 0.05 + 0.3 * f + tone, 0.48 + 0.64 * f + tone])
		plan.append([base, rad, blades])
	# Ordem de pintura correta na volta vertical: o que vaza de um tufo da borda de baixo para o alto
	# fica por baixo de tudo, e o que vaza de um tufo do alto para a borda de baixo fica por cima.
	var margin: float = u * 0.8
	var half: int = n / 2
	for e: Array in plan:
		if (e[0] as Vector2).y > n - margin:
			cv.clip_lo = 0
			cv.clip_hi = half
			_paint_tuft(cv, e, ramp)
	for e: Array in plan:
		var by: float = (e[0] as Vector2).y
		cv.clip_lo = half if by > n - margin else 0
		cv.clip_hi = half if by < margin else n
		_paint_tuft(cv, e, ramp)
	for e: Array in plan:
		if (e[0] as Vector2).y < margin:
			cv.clip_lo = half
			cv.clip_hi = n
			_paint_tuft(cv, e, ramp)
	cv.clip_lo = 0
	cv.clip_hi = n
	_grass_finish(cv, n, rng, big, variant_b, file)


func _paint_tuft(cv: PL.Canvas, e: Array, ramp: Array) -> void:
	var base: Vector2 = e[0]
	var rad: float = e[1]
	# sombra na base do tufo (fenda escura entre ele e o de baixo)
	cv.blob(base.x, base.y + rad * 0.12, rad * 1.05, rad * 0.55, 0.0, ramp[0].darkened(0.3), 0.9, 0.35)
	for bl: Array in e[2]:
		var w0: float = bl[1]
		cv.stroke(bl[0], PL.taper(4, w0, w0 * 0.25), PL.ramp_at(ramp, bl[2]), PL.ramp_at(ramp, bl[3]), 1.0)


func _grass_finish(cv: PL.Canvas, n: int, rng: RandomNumberGenerator, big: PackedFloat32Array, variant_b: bool, file: String) -> void:
	if variant_b:
		_clovers(cv, rng, big)
		_ground_flowers(cv, rng)
	# amacia a borda das lâminas (meio pixel final): tira o "grão" sem apagar a forma do tufo
	cv.r = PL.blur(cv.r, n, n, 1, true, true, 2)
	cv.g = PL.blur(cv.g, n, n, 1, true, true, 2)
	cv.b = PL.blur(cv.b, n, n, 1, true, true, 2)
	var out: PL.Canvas = cv.down2()
	var img: Image = out.to_image(true)
	PL.save_png(img, PL.TEX + "ground/" + file + ".png")
	var m: Dictionary = PL.camera_metrics(img)
	print("%s: escala 1/3 -> desvio L %.1f, |L - desfoque σ4| %.1f, L médio %.1f" % [file, m["std"], m["detail"], m["mean"]])


## Trevos: grupinhos de 3 folíolos redondos, verde mais frio que a grama.
func _clovers(cv: PL.Canvas, rng: RandomNumberGenerator, val: PackedFloat32Array) -> void:
	var dark: Color = c("#4E7A2E")
	var light: Color = c("#7FA23A")
	for g: int in 26:
		var gc := Vector2(rng.randf() * cv.w, rng.randf() * cv.h)
		var count: int = rng.randi_range(4, 9)
		for k: int in count:
			var p: Vector2 = gc + Vector2(rng.randf_range(-22, 22), rng.randf_range(-22, 22))
			var rot: float = rng.randf() * TAU
			var lr: float = rng.randf_range(3.6, 5.0)
			for l: int in 3:
				var a: float = rot + float(l) * TAU / 3.0
				var lc: Vector2 = p + Vector2(cos(a), sin(a)) * lr * 0.95
				cv.blob(lc.x, lc.y, lr, lr * 0.9, a, dark, 0.95, 0.6)
				cv.blob(lc.x, lc.y - lr * 0.25, lr * 0.6, lr * 0.5, a, light, 0.7, 0.3)


## Florzinhas planas: 5 pétalas e miolo, em grupinhos esparsos.
func _ground_flowers(cv: PL.Canvas, rng: RandomNumberGenerator) -> void:
	var cols: Array = [c("#F08CA8"), c("#F6F2E8"), c("#F4D04A"), c("#7FA8F0")]
	for g: int in 14:
		var gc := Vector2(rng.randf() * cv.w, rng.randf() * cv.h)
		var col: Color = cols[g % cols.size()]
		var count: int = rng.randi_range(2, 5)
		for k: int in count:
			var p: Vector2 = gc + Vector2(rng.randf_range(-26, 26), rng.randf_range(-26, 26))
			var pr: float = rng.randf_range(2.6, 3.6)
			var rot: float = rng.randf() * TAU
			for l: int in 5:
				var a: float = rot + float(l) * TAU / 5.0
				var lc: Vector2 = p + Vector2(cos(a), sin(a)) * pr * 0.9
				cv.blob(lc.x, lc.y, pr, pr * 0.75, a, col.darkened(0.08), 1.0, 0.6)
			cv.blob(p.x, p.y - 0.5, pr * 0.7, pr * 0.7, 0.0, col.lightened(0.15), 0.8, 0.4)
			cv.blob(p.x, p.y, pr * 0.45, pr * 0.45, 0.0, c("#F4D04A") if col != c("#F4D04A") else c("#E39041"), 1.0, 0.5)


# ---------------------------------------------------------------------------
# Máscara de mistura (256x256, cobre 32 x 32 unidades, seamless)
# R: grama a <-> b. G: áreas mais secas / com mais flores. B: variação de valor (livre para o shader).
# ---------------------------------------------------------------------------

func _blend_mask() -> void:
	var n: int = 256
	var fr: PackedFloat32Array = PL.pfield(n, n, 3, 3, 3101, 1.1, 2, 0.5)
	var fg: PackedFloat32Array = PL.pfield(n, n, 4, 3, 3202, 1.0, 2, 0.5)
	var fb: PackedFloat32Array = PL.pfield(n, n, 5, 3, 3303, 0.8, 2, 0.5)
	var bytes := PackedByteArray()
	bytes.resize(n * n * 4)
	for i: int in n * n:
		bytes[i * 4] = roundi(smoothstep(0.3, 0.72, fr[i]) * 255.0)
		bytes[i * 4 + 1] = roundi(smoothstep(0.45, 0.85, fg[i]) * 255.0)
		bytes[i * 4 + 2] = roundi(smoothstep(0.2, 0.8, fb[i]) * 255.0)
		bytes[i * 4 + 3] = 255
	PL.save_png(Image.create_from_data(n, n, false, Image.FORMAT_RGBA8, bytes), PL.TEX + "ground/blend_mask.png")


# ---------------------------------------------------------------------------
# Terra da arena (1024x768 = 16 x 12 unidades, alfa suave). x = leste, y = sul.
# ---------------------------------------------------------------------------

const DIRT_U: float = 64.0 * SS  # px por unidade na tela de pintura
# Braços curtos da mancha: [cx, cy, rx, ry, giro] em unidades, a partir do centro do decalque
const DIRT_ARMS: Array = [
	[-6.3, 1.2, 0.8, 0.5, 0.35], [6.2, -2.5, 0.8, 0.45, -0.55], [-1.9, 4.9, 0.85, 0.42, 0.15],
	[2.7, -4.85, 0.8, 0.4, -0.2], [5.0, 3.85, 0.65, 0.42, 0.8], [-5.2, -3.6, 0.6, 0.4, -0.7],
]
# Centro do círculo em relação ao centro da terra (Tabela B da 012: terra (0.3, -1.0), círculo (0.4, -0.9))
const RING_OFS := Vector2(0.1, 0.1)
const DIRT_SCALE: float = 0.955


static func sd_round_rect(p: Vector2, hx: float, hy: float, rad: float) -> float:
	var qx: float = absf(p.x) - hx + rad
	var qy: float = absf(p.y) - hy + rad
	var ox: float = maxf(qx, 0.0)
	var oy: float = maxf(qy, 0.0)
	return sqrt(ox * ox + oy * oy) + minf(maxf(qx, qy), 0.0) - rad


static func sd_ellipse(p: Vector2, e: Array) -> float:
	var q: Vector2 = (p - Vector2(e[0], e[1])).rotated(-float(e[4]))
	var rx: float = e[2]
	var ry: float = e[3]
	var k: float = Vector2(q.x / rx, q.y / ry).length()
	return (k - 1.0) * minf(rx, ry)


static func smin(a: float, b: float, k: float) -> float:
	var h: float = clampf(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
	return lerpf(b, a, h) - k * h * (1.0 - h)


## Distância com sinal (em unidades) da mancha de terra, sem o esfiapado.
static func dirt_sdf(pp: Vector2) -> float:
	var p: Vector2 = pp / DIRT_SCALE
	var d: float = sd_round_rect(p, 6.35, 4.8, 2.6)
	for e: Array in DIRT_ARMS:
		d = smin(d, sd_ellipse(p, e), 0.7)
	return d * DIRT_SCALE


# (r2) Entradas de grama na borda: [ângulo (graus, 0 = leste, 90 = sul), fundo (u), meia largura da boca (u)]
const GRASS_INLETS: Array = [
	[8.0, 0.55, 0.22], [31.0, 0.9, 0.3], [52.0, 0.4, 0.18], [77.0, 0.7, 0.26], [101.0, 0.35, 0.16],
	[118.0, 0.95, 0.32], [146.0, 0.5, 0.2], [171.0, 0.8, 0.28], [196.0, 0.45, 0.2], [214.0, 0.65, 0.24],
	[241.0, 0.3, 0.15], [263.0, 1.0, 0.3], [289.0, 0.55, 0.22], [318.0, 0.75, 0.26], [342.0, 0.4, 0.18],
]
const DIRT_DARK_TARGET: float = 0.3  # fração dos opacos em terra escura (L <= 95) na camada base
const RING_CROWN_R: float = 3.4  # (r2) sem manchas claras até esse raio do centro do círculo (sem halo)


## (r2) Borda + entradas de grama: distância com sinal (u) da mancha recortada pelos dedos de grama.
static func inlet_sd(p: Vector2, inlets: Array) -> float:
	var best: float = INF
	for e: Array in inlets:
		var base: Vector2 = e[0]
		var tip: Vector2 = e[1]
		var hw: float = e[2]
		var d: Vector2 = tip - base
		var t: float = clampf((p - base).dot(d) / maxf(d.dot(d), 0.0001), 0.0, 1.0)
		var rad: float = hw * (1.0 - 0.8 * t)
		best = minf(best, (p - (base + d * t)).length() - rad)
	return best


func _arena_dirt() -> void:
	var w: int = 1024 * SS
	var h: int = 768 * SS
	var cx: float = w * 0.5
	var cy: float = h * 0.5
	var cv := PL.Canvas.new(w, h, false, false)
	cv.fill(c("#A87A3C"), 0.0)
	# Campos de baixa frequência (FastNoiseLite, seeds literais)
	var n_shape: PackedFloat32Array = PL.nfield(w, h, 1.0 / 700.0, 3, 4101, 120.0, 8)
	var n_fray: PackedFloat32Array = PL.nfield(w, h, 1.0 / 46.0, 3, 4102, 30.0, 2)
	var n_frag: PackedFloat32Array = PL.nfield(w, h, 1.0 / 40.0, 2, 4103, 24.0, 2)
	var n_dark: PackedFloat32Array = PL.nfield(w, h, 1.0 / 520.0, 4, 4104, 180.0, 8)
	var n_light: PackedFloat32Array = PL.nfield(w, h, 1.0 / 300.0, 4, 4105, 140.0, 8)
	var n_mid: PackedFloat32Array = PL.nfield(w, h, 1.0 / 160.0, 3, 4106, 60.0, 4)
	var n_rim: PackedFloat32Array = PL.nfield(w, h, 1.0 / 200.0, 2, 4107, 40.0, 8)
	# Entradas de grama: base na borda (raio em que a distância cruza 0), ponta para dentro
	var inlets: Array = []
	for e: Array in GRASS_INLETS:
		var ang: float = deg_to_rad(float(e[0]))
		var dir := Vector2(cos(ang), sin(ang))
		var r: float = 0.5
		while dirt_sdf(dir * r) < -0.05 and r < 9.0:
			r += 0.05
		var base: Vector2 = dir * (r + 0.25)
		var tip: Vector2 = dir * (r - float(e[1]) - 0.15) + Vector2(-dir.y, dir.x) * float(e[1]) * 0.3
		inlets.append([base, tip, float(e[2])])
	# Distância base em 1/4 da resolução, ampliada (com as entradas)
	var lw: int = w / 4
	var lh: int = h / 4
	var dlow := PackedFloat32Array()
	dlow.resize(lw * lh)
	for y: int in lh:
		for x: int in lw:
			var p := Vector2((float(x * 4) + 2.0 - cx) / DIRT_U, (float(y * 4) + 2.0 - cy) / DIRT_U)
			dlow[y * lw + x] = maxf(dirt_sdf(p), -inlet_sd(p, inlets))
	var dist: PackedFloat32Array = PL.resize_field(dlow, lw, lh, 4, false, false)
	# Campo da terra escura: faixa junto à borda sul/oeste + manchas grandes, inclusive encostando no anel
	var ring_c := Vector2(cx, cy) + RING_OFS * DIRT_U
	var dk_field := PackedFloat32Array()
	dk_field.resize(w * h)
	var alpha := PackedFloat32Array()
	alpha.resize(w * h)
	for y: int in h:
		var ny: float = (float(y) - cy) / DIRT_U / 4.8
		for x: int in w:
			var i: int = y * w + x
			var nx: float = (float(x) - cx) / DIRT_U / 6.35
			var d: float = dist[i] + 0.55 * (n_shape[i] - 0.5)
			var df: float = d + 0.2 * (n_fray[i] - 0.5)
			var al: float = 1.0 - smoothstep(-0.035, 0.035, df)
			if d > 0.0 and d < 0.45:
				al = maxf(al, smoothstep(0.02, 0.0, (0.64 + 0.9 * d) - n_frag[i]))
			elif d <= 0.0 and d > -0.6:
				al *= 1.0 - smoothstep(0.0, 0.02, n_frag[i] - (0.66 + 1.0 * (-d)))
			alpha[i] = al
			var sw: float = 0.16 * ny - 0.13 * nx
			var swn: float = clampf(0.5 + 2.4 * sw, 0.0, 1.0)
			var band: float = smoothstep(-2.3, -0.4, d) * swn
			var rr: float = Vector2(x + 0.5, y + 0.5).distance_to(ring_c) / DIRT_U
			var near_ring: float = smoothstep(3.6, 2.2, rr)
			dk_field[i] = 0.55 * band + 0.62 * n_dark[i] + 0.04 * (n_mid[i] - 0.5) + 0.2 * near_ring
	# Limiar da terra escura escolhido por busca binária para DIRT_DARK_TARGET dos opacos
	var lo: float = 0.3
	var hi: float = 1.2
	for it: int in 18:
		var th: float = (lo + hi) * 0.5
		var nd: int = 0
		var na: int = 0
		for i: int in range(0, w * h, 7):
			if alpha[i] < 0.5:
				continue
			na += 1
			if dk_field[i] > th + 0.03:
				nd += 1
		if float(nd) / float(maxi(na, 1)) > DIRT_DARK_TARGET:
			lo = th
		else:
			hi = th
	var th_dark: float = (lo + hi) * 0.5
	var c_mid0: Color = c(DIRT_MID[0])
	var c_mid1: Color = c(DIRT_MID[1])
	var c_l0: Color = c(DIRT_LIGHT[0])
	var c_l1: Color = c(DIRT_LIGHT[1])
	var c_d0: Color = c(DIRT_DARK[1])
	var c_d1: Color = c("#7A5530")
	var c_rim0: Color = c("#6E4228")
	var c_rim1: Color = c("#7E5A2C")
	var dark_mask := PackedFloat32Array()
	dark_mask.resize(w * h)
	for y: int in h:
		var ny: float = (float(y) - cy) / DIRT_U / 4.8
		for x: int in w:
			var i: int = y * w + x
			var al: float = alpha[i]
			if al <= 0.0:
				continue
			var nx: float = (float(x) - cx) / DIRT_U / 6.35
			var d: float = dist[i] + 0.55 * (n_shape[i] - 0.5)
			var df: float = d + 0.2 * (n_fray[i] - 0.5)
			var m: float = n_mid[i]
			var col: Color = c_mid0.lerp(c_mid1, smoothstep(0.15, 0.6, m))
			var sw: float = 0.16 * ny - 0.13 * nx
			# Em volta do círculo a terra é média (batida), um pouco mais escura que o resto do miolo
			var rr0: float = Vector2(x + 0.5, y + 0.5).distance_to(ring_c) / DIRT_U
			col = col.lerp(c("#9C6E3A"), 0.55 * smoothstep(3.8, 2.4, rr0))
			# Luz em manchas pequenas e soltas, longe do anel (sem halo em volta do círculo)
			var rr: float = Vector2(x + 0.5, y + 0.5).distance_to(ring_c) / DIRT_U
			var away: float = smoothstep(RING_CROWN_R - 0.2, RING_CROWN_R + 0.4, rr)
			var lt: float = smoothstep(0.66, 0.71, n_light[i] - 0.5 * sw + 0.04 * (m - 0.5)) * away
			col = col.lerp(c_l0.lerp(c_l1, smoothstep(0.7, 0.85, n_light[i])), lt * 0.9)
			var dk: float = smoothstep(th_dark, th_dark + 0.06, dk_field[i])
			dark_mask[i] = dk
			var band: float = smoothstep(-2.3, -0.4, d) * clampf(0.5 + 2.4 * sw, 0.0, 1.0)
			col = col.lerp(c_d0.lerp(c_d1, clampf(smoothstep(0.35, 0.7, m) * 0.7 + 0.5 * (1.0 - band), 0.0, 1.0)), dk)
			# Borda escura avermelhada de 0,08 a 0,58 de largura (varia devagar)
			var rim_w: float = 0.08 + 0.5 * n_rim[i]
			var rw: float = 1.0 - smoothstep(rim_w * 0.5, rim_w, -df)
			col = col.lerp(c_rim0.lerp(c_rim1, n_rim[i]), rw * 0.9)
			cv.r[i] = col.r
			cv.g[i] = col.g
			cv.b[i] = col.b
			cv.a[i] = al
	var rng := RandomNumberGenerator.new()
	rng.seed = 41108
	# Pinceladas de detalhe (só na terra): manchas curtas com tons vizinhos, em várias direções
	for k: int in 3200:
		var p := Vector2(rng.randf() * w, rng.randf() * h)
		var i: int = cv.idx(int(p.x), int(p.y))
		if cv.a[i] < 0.9:
			continue
		var base: Color = cv.get_c(i)
		var shade: float = rng.randf_range(-0.09, 0.06)
		var col: Color = base.darkened(-shade) if shade < 0.0 else base.lightened(shade)
		var ang: float = rng.randf_range(-0.6, 0.6) + (PI * 0.5 if rng.randf() < 0.25 else 0.0)
		var pts: PackedVector2Array = PL.arc_pts(p, ang, rng.randf_range(18.0, 56.0), rng.randf_range(-0.6, 0.6), 4)
		var r0: float = rng.randf_range(3.0, 7.5)
		var radii := PackedFloat32Array([r0 * 0.5, r0, r0, r0 * 0.8, r0 * 0.35])
		cv.stroke(pts, radii, col, col, rng.randf_range(0.35, 0.6), 1)
	# Seixos e grãos
	_dirt_bits(cv, rng)
	# Plantinhas: 26 tufos de 0,4 a 0,8 (rosetas e touceiras), mais perto da borda, fora do círculo
	var placed: Array = []
	var tries: int = 0
	while placed.size() < 26 and tries < 6000:
		tries += 1
		var p := Vector2(rng.randf_range(-6.4, 6.4), rng.randf_range(-4.8, 4.8))
		var i: int = cv.idx(int(cx + p.x * DIRT_U), int(cy + p.y * DIRT_U))
		if cv.a[i] < 0.99 or dirt_sdf(p) > -0.35:
			continue
		if p.distance_to(RING_OFS) < 2.0:
			continue
		var ok: bool = true
		for q: Vector2 in placed:
			if q.distance_to(p) < 1.15:
				ok = false
		if not ok:
			continue
		placed.append(p)
		var size: float = rng.randf_range(0.42, 0.8)
		if placed.size() % 3 == 0:
			_sprig(cv, Vector2(cx, cy) + p * DIRT_U, size * DIRT_U, rng)
		else:
			_rosette(cv, Vector2(cx, cy) + p * DIRT_U, size * DIRT_U, rng)
	var out: PL.Canvas = cv.down2()
	var img: Image = out.to_image(false)
	PL.dilate_rgb(img, 16)
	PL.save_png(img, PL.TEX + "decals/arena_dirt.png")
	_print_dirt_stats(img, dark_mask, w, h)
	print("arena_dirt: %d plantinhas, %d entradas de grama, limiar escuro %.3f" % [placed.size(), inlets.size(), th_dark])
	var ds: Dictionary = PL.dirt_stats(img)
	print("arena_dirt r2: escuro %.1f%% (25-35), claro %.1f%% (<= 10), verde %.1f%% (2-5), coroa %+.1f (<= +3), média #%s a %.1f%% de #A57A3F (<= 5)" % [
		ds["dark"] * 100.0, ds["light"] * 100.0, ds["green"] * 100.0, ds["crown"], (ds["color"] as Color).to_html(false).to_upper(), PL.cdist(ds["color"], c("#A57A3F")) * 100.0])


func _dirt_bits(cv: PL.Canvas, rng: RandomNumberGenerator) -> void:
	# Pedacinhos escuros avermelhados (folhas secas, torrões)
	var reds: Array = [c("#6E4228"), c("#5E3A22"), c("#8A4A2C"), c("#7E5634")]
	for k: int in 340:
		var p := Vector2(rng.randf() * cv.w, rng.randf() * cv.h)
		var i: int = cv.idx(int(p.x), int(p.y))
		if cv.a[i] < 0.95:
			continue
		var col: Color = reds[rng.randi() % reds.size()]
		var r: float = rng.randf_range(2.4, 5.0)
		var rot: float = rng.randf() * TAU
		cv.blob(p.x, p.y, r * rng.randf_range(1.0, 1.9), r, rot, col, 0.9, 0.55, 1)
		cv.blob(p.x - 0.6, p.y - r * 0.35, r * 0.7, r * 0.45, rot, col.lightened(0.18), 0.6, 0.4, 1)
	# Grãos claros
	for k: int in 260:
		var p := Vector2(rng.randf() * cv.w, rng.randf() * cv.h)
		var i: int = cv.idx(int(p.x), int(p.y))
		if cv.a[i] < 0.95:
			continue
		var r: float = rng.randf_range(1.6, 3.2)
		cv.blob(p.x, p.y, r * 1.2, r, rng.randf() * TAU, c("#D6AA66").lightened(0.12), 0.85, 0.5, 1)
	# Seixos cinza-bege, topo mais claro
	for k: int in 46:
		var p := Vector2(rng.randf() * cv.w, rng.randf() * cv.h)
		var i: int = cv.idx(int(p.x), int(p.y))
		if cv.a[i] < 0.99:
			continue
		var r: float = rng.randf_range(4.5, 11.0)
		var rot: float = rng.randf() * TAU
		var e: float = rng.randf_range(1.1, 1.6)
		cv.blob(p.x, p.y + r * 0.15, r * e + 2.5, r + 2.5, rot, c("#6E4A2E"), 0.45, 0.3, 1)
		cv.blob(p.x, p.y, r * e, r, rot, c("#8E8466"), 1.0, 0.75, 1)
		cv.blob(p.x, p.y - r * 0.2, r * e * 0.75, r * 0.7, rot, c("#A89E86"), 0.9, 0.5, 1)
		cv.blob(p.x - r * 0.1, p.y - r * 0.38, r * e * 0.42, r * 0.36, rot, c("#C4BAA2"), 0.8, 0.4, 1)


## Roseta de folhas largas (vista de cima): base escura, ponta clara, folha de cima por último.
func _rosette(cv: PL.Canvas, p: Vector2, size: float, rng: RandomNumberGenerator) -> void:
	var leaves: int = rng.randi_range(6, 9)
	var rot: float = rng.randf() * TAU
	var rad: float = size * 0.5
	for l: int in leaves:
		var a: float = rot + float(l) * TAU / float(leaves) + rng.randf_range(-0.25, 0.25)
		var ln: float = rad * rng.randf_range(0.75, 1.05)
		var pts: PackedVector2Array = PL.arc_pts(p, a, ln, rng.randf_range(-0.5, 0.5), 4)
		var wv: float = ln * rng.randf_range(0.26, 0.34)
		var radii := PackedFloat32Array([wv * 0.35, wv * 0.85, wv, wv * 0.75, wv * 0.2])
		cv.stroke(pts, radii, c("#2C4520"), c("#87A23A"), 1.0, 0)
		var mid: PackedVector2Array = PL.arc_pts(p + (pts[1] - p) * 0.4, a, ln * 0.6, 0.0, 2)
		cv.stroke(mid, PackedFloat32Array([wv * 0.25, wv * 0.35, wv * 0.12]), c("#5E8424"), c("#A8C447"), 0.55, 0)
	cv.blob(p.x, p.y, rad * 0.3, rad * 0.28, 0.0, c("#3F5F22"), 0.9, 0.4)


## Touceira de capim: lâminas finas saindo de um ponto.
func _sprig(cv: PL.Canvas, p: Vector2, size: float, rng: RandomNumberGenerator) -> void:
	var blades: int = rng.randi_range(9, 14)
	for b: int in blades:
		var a: float = rng.randf() * TAU
		var ln: float = size * 0.5 * rng.randf_range(0.6, 1.0)
		var pts: PackedVector2Array = PL.arc_pts(p + Vector2(rng.randf_range(-3, 3), rng.randf_range(-3, 3)), a, ln, rng.randf_range(-0.9, 0.9), 4)
		cv.stroke(pts, PL.taper(4, rng.randf_range(2.6, 3.6), 0.7), c("#3F5F22"), c("#8DAE34"), 1.0, 0)


func _print_dirt_stats(img: Image, dark_mask: PackedFloat32Array, w: int, h: int) -> void:
	var st: Dictionary = PL.lum_stats(img, Rect2i(0, 0, img.get_width(), img.get_height()))
	var x0: int = img.get_width()
	var x1: int = 0
	var y0: int = img.get_height()
	var y1: int = 0
	for y: int in img.get_height():
		for x: int in img.get_width():
			if img.get_pixel(x, y).a >= 0.5:
				x0 = mini(x0, x)
				x1 = maxi(x1, x)
				y0 = mini(y0, y)
				y1 = maxi(y1, y)
	var dk: float = 0.0
	for v: float in dark_mask:
		dk += v
	print("arena_dirt: média #%s, L %.1f, desvio %.1f, opaco %.2f x %.2f u, terra batida %.0f%% (px %d)" % [
		(st["color"] as Color).to_html(false).to_upper(), st["mean"], st["std"],
		float(x1 - x0 + 1) / 64.0, float(y1 - y0 + 1) / 64.0, 100.0 * dk / float(st["n"] * SS * SS), st["n"]])


# ---------------------------------------------------------------------------
# Centro do círculo (384x384 = 6 x 6 unidades, alfa suave): disco escuro com miolo claro e dois
# crescentes claros a oeste e a leste (abertos ao norte e ao sul). Centro do decalque = centro do círculo.
# ---------------------------------------------------------------------------

func _arena_ring() -> void:
	var n: int = 384 * SS
	var u: float = 64.0 * SS
	var cc := Vector2(n * 0.5, n * 0.5)
	var cv := PL.Canvas.new(n, n, false, false)
	cv.fill(c("#7E5634"), 0.0)
	var nz := FastNoiseLite.new()
	nz.seed = 5201
	nz.frequency = 1.0 / 90.0
	nz.fractal_octaves = 3
	var n_tone: PackedFloat32Array = PL.nfield(n, n, 1.0 / 120.0, 3, 5202, 40.0, 4)
	var n_core: PackedFloat32Array = PL.nfield(n, n, 1.0 / 70.0, 2, 5203, 30.0, 2)
	# (r1) cores medidas na referência: anel de terra só um pouco mais escura, miolo claro grande,
	# crescentes claros com pouco contraste
	var disk0: Color = c("#8A5A36")
	var disk1: Color = c("#925F3B")
	var disk2: Color = c("#9A6440")
	var core0: Color = c("#D8A862")
	var core1: Color = c("#E2AE64")
	var cres0: Color = c("#DBAF5C")
	var cres1: Color = c("#E5B96F")
	for y: int in n:
		for x: int in n:
			var i: int = y * n + x
			var p: Vector2 = (Vector2(x + 0.5, y + 0.5) - cc) / u
			var ang: float = atan2(p.y, p.x)
			var rho: float = Vector2(p.x, p.y * 1.04).length()
			var wob: float = nz.get_noise_2d(cos(ang) * 60.0, sin(ang) * 60.0)
			var tone: float = n_tone[i]
			# Disco escuro (raio ~1,3, borda torta)
			var rd: float = 1.3 + 0.16 * wob + 0.05 * (n_core[i] - 0.5)
			var a_disk: float = 1.0 - smoothstep(rd - 0.05, rd + 0.05, rho)
			# Crescentes (oeste e leste): faixa de r 1,36 até 1,9 no meio, afinando até 0 a ±64°
			var a_cres: float = 0.0
			var cres_t: float = 0.0
			for side: int in 2:
				var a0: float = PI if side == 0 else 0.0
				var da: float = absf(wrapf(ang - a0, -PI, PI))
				# assimetria: cada crescente puxa mais para um lado e tem espessura própria
				var skew: float = 0.28 if side == 0 else -0.2
				var dsk: float = wrapf(ang - a0, -PI, PI) - skew * 0.35
				da = absf(dsk)
				var half: float = deg_to_rad((62.0 if side == 0 else 56.0) + 10.0 * wob)
				if da < half:
					var prof: float = pow(1.0 - (da / half) * (da / half), 0.6)
					var r_in: float = 1.36 + 0.1 * wob
					var thick: float = 0.55 if side == 0 else 0.48
					var r_out: float = r_in + thick * prof * (1.0 + 0.35 * (n_tone[i] - 0.5))
					var e_in: float = smoothstep(r_in - 0.04, r_in + 0.05, rho)
					var e_out: float = 1.0 - smoothstep(r_out - 0.06, r_out + 0.04, rho)
					var aa: float = e_in * e_out
					if aa > a_cres:
						a_cres = aa
						cres_t = clampf((rho - r_in) / maxf(r_out - r_in, 0.001), 0.0, 1.0)
			if a_disk <= 0.0 and a_cres <= 0.0:
				continue
			if a_disk > 0.0:
				var col: Color = disk0.lerp(disk1, smoothstep(0.25, 0.6, tone)).lerp(disk2, smoothstep(0.65, 0.9, tone) * 0.7)
				# Miolo claro torto: mancha deslocada para leste-norte com um lóbulo
				# Miolo claro grande e torto (raio ~0,7), fora do centro, com dois lóbulos
				var q: Vector2 = p - Vector2(0.14, -0.04)
				var qq: Vector2 = Vector2(q.x * 0.88, q.y * 1.12).rotated(0.5)
				var lobe: float = (p - Vector2(0.42, 0.36)).length() / 0.36
				var lobe2: float = (p - Vector2(-0.22, -0.28)).length() / 0.3
				var core_d: float = minf(minf(qq.length() / 0.7, lobe), lobe2) + 0.35 * (n_core[i] - 0.5)
				var core: float = 1.0 - smoothstep(0.82, 1.1, core_d)
				col = col.lerp(core0.lerp(core1, smoothstep(0.3, 0.8, n_core[i] + 0.3 * (1.0 - core_d))), core)
				# borda de fora do anel um pouco mais escura (terra batida)
				col = col.darkened(0.04 * smoothstep(0.95, 1.25, rho))
				cv.r[i] = col.r
				cv.g[i] = col.g
				cv.b[i] = col.b
				cv.a[i] = a_disk
			if a_cres > 0.0:
				var cc2: Color = cres0.lerp(cres1, smoothstep(0.3, 0.75, tone) * (1.0 - 0.6 * absf(cres_t - 0.5) * 2.0))
				cc2 = cc2.darkened(0.04 * (1.0 - smoothstep(0.0, 0.22, cres_t)))
				cv.blend(i, cc2, a_cres * 0.92)
	# Pinceladas tangenciais suaves nos crescentes e no disco (terra alisada)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5204
	for k: int in 900:
		var ang: float = rng.randf() * TAU
		var rho: float = rng.randf_range(0.2, 1.85)
		var p0: Vector2 = cc + Vector2(cos(ang), sin(ang)) * rho * u
		var i: int = cv.idx(int(p0.x), int(p0.y))
		if i < 0 or cv.a[i] < 0.95:
			continue
		var base: Color = cv.get_c(i)
		var sh: float = rng.randf_range(-0.07, 0.07)
		var col: Color = base.lightened(sh) if sh > 0.0 else base.darkened(-sh)
		var length: float = rng.randf_range(14.0, 40.0)
		var pts: PackedVector2Array = PL.arc_pts(p0, ang + PI * 0.5, length, length / (rho * u), 3)
		var r0: float = rng.randf_range(2.5, 5.0)
		cv.stroke(pts, PackedFloat32Array([r0 * 0.4, r0, r0 * 0.9, r0 * 0.3]), col, col, rng.randf_range(0.3, 0.55), 1)
	# Grãos escuros e claros esparsos
	for k: int in 45:
		var ang: float = rng.randf() * TAU
		var rho: float = rng.randf_range(0.1, 1.9)
		var p0: Vector2 = cc + Vector2(cos(ang), sin(ang)) * rho * u
		var i: int = cv.idx(int(p0.x), int(p0.y))
		if i < 0 or cv.a[i] < 0.95:
			continue
		var dark: bool = rng.randf() < 0.8 and rho > 0.9
		var col: Color = c("#7E5634") if dark else c("#E5B96F").lightened(0.08)
		var r: float = rng.randf_range(1.6, 3.6)
		cv.blob(p0.x, p0.y, r * 1.3, r, rng.randf() * TAU, col, 0.6, 0.5, 1)
	# Torrões de terra média que quebram a borda dos crescentes e do disco
	for k: int in 14:
		var ang: float = rng.randf() * TAU
		var rho: float = rng.randf_range(1.2, 1.95)
		var p0: Vector2 = cc + Vector2(cos(ang), sin(ang)) * rho * u
		var r: float = rng.randf_range(4.0, 9.0)
		var i: int = cv.idx(int(p0.x), int(p0.y))
		if i < 0 or cv.a[i] < 0.5:
			continue
		cv.blob(p0.x, p0.y, r * 1.5, r, ang + PI * 0.5, c("#C89A55"), 0.6, 0.5, 1)
	var img: Image = cv.down2().to_image(false)
	PL.dilate_rgb(img, 16)
	PL.save_png(img, PL.TEX + "decals/arena_ring.png")
	var dm: Color = disk_mean(img)
	print("arena_ring: média do disco (r <= 1,3) #%s, a %.1f%% de #B27541" % [dm.to_html(false).to_upper(), PL.cdist(dm, c("#B27541")) * 100.0])


## Média de cor dos pixels com alfa >= 0,5 dentro do raio 1,3 (83 px) do centro do arena_ring.
static func disk_mean(img: Image) -> Color:
	var ctr := Vector2(img.get_width(), img.get_height()) * 0.5
	var acc := Vector3.ZERO
	var cnt: int = 0
	for y: int in img.get_height():
		for x: int in img.get_width():
			if Vector2(x + 0.5, y + 0.5).distance_to(ctr) > 1.3 * 64.0:
				continue
			var col: Color = img.get_pixel(x, y)
			if col.a < 0.5:
				continue
			acc += Vector3(col.r, col.g, col.b)
			cnt += 1
	acc /= float(maxi(cnt, 1))
	return Color(acc.x, acc.y, acc.z)


# ---------------------------------------------------------------------------
# Pedras soltas (atlas 1024x512, 4 x 2 células de 256 = 4 x 4 unidades, alfa suave)
# Células 0..4: pedras compridas e curvas do anel externo (arco com o lado convexo para cima/norte
# da célula: o centro do arco fica R unidades abaixo do centro da célula). 5: laje gasta. 6, 7: pedrinhas.
# ---------------------------------------------------------------------------

# [comprimento, largura, raio do arco (= raio no anel), seed]
const LONG_STONES: Array = [
	[1.75, 0.4, 4.3, 6101], [1.45, 0.36, 3.8, 6102], [1.25, 0.32, 3.6, 6103],
	[1.62, 0.38, 4.4, 6104], [1.35, 0.34, 4.0, 6105],
]


func _arena_slabs() -> void:
	var cell: int = 256 * SS
	var u: float = 64.0 * SS
	var cv := PL.Canvas.new(cell * 4, cell * 2, false, false)
	cv.fill(c("#6E4A2E"), 0.0)
	for k: int in 5:
		var e: Array = LONG_STONES[k]
		var org := Vector2((k % 4) * cell, (k / 4) * cell)
		_long_stone(cv, org, cell, u, float(e[0]), float(e[1]), float(e[2]), int(e[3]))
	_worn_slab(cv, Vector2(1 * cell, cell), cell, u, 6201)
	_pebbles(cv, Vector2(2 * cell, cell), cell, u, 6301, 6)
	_pebbles(cv, Vector2(3 * cell, cell), cell, u, 6302, 4)
	var img: Image = cv.down2().to_image(false)
	PL.dilate_rgb(img, 16)
	PL.save_png(img, PL.TEX + "decals/arena_slabs.png")
	for k: int in 8:
		var st: Dictionary = PL.slab_stats(img, Rect2i((k % 4) * 256, (k / 4) * 256, 256, 256))
		var cc: Color = st["contact"]
		print("arena_slabs célula %d: topo claro %.0f%% da pedra (>= 20), contato #%s (a %.1f%% de #534030)" % [k, float(st["light"]) * 100.0, cc.to_html(false).to_upper(), PL.cdist(cc, c("#534030")) * 100.0])


## Pinta uma pedra chata a partir de um campo de distância (em unidades; < 0 dentro).
## (r2) Volume só com luz de cima: topo claro (#C8BEA6 a #D8CCB0) no miolo, lados escurecendo para a
## beira, sombra de contato escura e quente (#4A3A28 a #5C4630, 0,03 a 0,08) em toda a volta, e terra
## escura cobrindo uma parte da beira (meio enterrada).
func _stone_px(cv: PL.Canvas, i: int, sd: float, facet: float, crack: float, bury: float, ramp: Array) -> void:
	# sombra de contato: faixa estreita colada na pedra, depois terra escura bem suave
	var cw: float = 0.035 + 0.04 * bury
	if sd > -0.01:
		var sh: float = 1.0 - smoothstep(cw * 0.6, cw + 0.015, sd)
		var soft: float = (1.0 - smoothstep(cw, cw + 0.09, sd)) * 0.45
		if soft > 0.0:
			cv.blend(i, c("#6E4A2E"), soft)
		if sh > 0.0:
			cv.blend(i, c("#4A3A28").lerp(c("#5C4630"), clampf(facet, 0.0, 1.0)), sh * 0.95)
	var inside: float = 1.0 - smoothstep(-0.012, 0.012, sd)
	if inside <= 0.0:
		return
	var depth: float = clampf(-sd / 0.17, 0.0, 1.0)
	# lados (perto da beira) escuros, topo claro; facetas largas
	var t: float = 0.1 + 0.9 * pow(depth, 0.7)
	var lv: float = facet * 3.0
	var fl: float = floorf(lv)
	t += 0.26 * ((fl + smoothstep(0.4, 0.6, lv - fl)) / 3.0 - 0.5)
	var col: Color = PL.ramp_at(ramp, clampf(t, 0.0, 1.0))
	col = col.darkened(0.25 * crack)
	# terra cobrindo um pedaço da beira
	var b: float = smoothstep(0.56, 0.64, bury) * (1.0 - smoothstep(0.3, 0.85, depth))
	col = col.lerp(c("#6E4A2E"), b * 0.9)
	cv.blend(i, col, inside)
	cv.z[i] = 1.0


func _long_stone(cv: PL.Canvas, org: Vector2, cell: int, u: float, length: float, width: float, radius: float, seed_value: int) -> void:
	var nz := FastNoiseLite.new()
	nz.seed = seed_value
	nz.frequency = 1.0 / 60.0
	nz.fractal_octaves = 3
	var nb := FastNoiseLite.new()
	nb.seed = seed_value + 50
	nb.frequency = 1.0 / 95.0
	var center := org + Vector2(cell * 0.5, cell * 0.5 + width * 0.25 * u)
	var arc_c := center + Vector2(0.0, radius * u)
	var lh: float = length * 0.5
	var ramp: Array = [c("#5E584C"), c("#7E786A"), c("#988F7C"), c("#B8AE98"), c("#C8BEA6"), c("#D8CCB0")]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 7
	var asym: float = rng.randf_range(-0.25, 0.25)
	for y: int in cell:
		for x: int in cell:
			var px := Vector2(org.x + x + 0.5, org.y + y + 0.5)
			var rel: Vector2 = (px - arc_c) / u
			var rho: float = rel.length()
			var phi: float = atan2(rel.y, rel.x) + PI * 0.5
			var s: float = phi * radius
			var across: float = rho - radius
			var tt: float = clampf(s / lh, -1.0, 1.0)
			var wh: float = width * 0.5 * (1.0 - 0.3 * tt * tt) * (1.0 + asym * tt * 0.5)
			var ex: float = maxf(absf(s) - (lh - wh), 0.0)
			var sd: float = Vector2(ex, across).length() - wh
			sd += 0.05 * nz.get_noise_2d(px.x, px.y)
			if sd > 0.2:
				continue
			var i: int = cv.idx(int(px.x), int(px.y))
			var facet: float = nz.get_noise_2d(px.x * 0.35 + 300.0, px.y * 0.35) * 0.5 + 0.5
			_stone_px(cv, i, sd, facet, 0.0, nb.get_noise_2d(px.x, px.y) * 0.5 + 0.5, ramp)
	# Rachadura curta e lascas
	var ang0: float = rng.randf_range(-0.3, 0.3)
	var p0: Vector2 = center + Vector2(rng.randf_range(-0.3, 0.3) * u, -width * 0.25 * u)
	var pts: PackedVector2Array = PL.arc_pts(p0, PI * 0.5 + ang0, width * 0.55 * u, rng.randf_range(-0.8, 0.8), 3)
	cv.stroke(pts, PackedFloat32Array([1.6, 1.4, 1.2, 0.6]), c("#6A6456"), c("#6A6456"), 0.75, 1)


func _worn_slab(cv: PL.Canvas, org: Vector2, cell: int, u: float, seed_value: int) -> void:
	var nz := FastNoiseLite.new()
	nz.seed = seed_value
	nz.frequency = 1.0 / 70.0
	nz.fractal_octaves = 3
	var nb := FastNoiseLite.new()
	nb.seed = seed_value + 50
	nb.frequency = 1.0 / 95.0
	var center := org + Vector2(cell * 0.5, cell * 0.5)
	# Laje de ~0,8 x 0,6, cantos gastos (retângulo arredondado girado + ruído)
	var ramp: Array = [c("#6A6456"), c("#857C68"), c("#A0967F"), c("#BCB198"), c("#CDC2A8"), c("#D6CAAE")]
	for y: int in cell:
		for x: int in cell:
			var px := Vector2(org.x + x + 0.5, org.y + y + 0.5)
			var q: Vector2 = ((px - center) / u).rotated(-0.32)
			var sd: float = sd_round_rect(q, 0.42, 0.3, 0.12) + 0.045 * nz.get_noise_2d(px.x, px.y)
			if sd > 0.2:
				continue
			var i: int = cv.idx(int(px.x), int(px.y))
			var facet: float = nz.get_noise_2d(px.x * 0.5 + 500.0, px.y * 0.5) * 0.5 + 0.5
			_stone_px(cv, i, sd, facet, 0.0, nb.get_noise_2d(px.x, px.y) * 0.5 + 0.5, ramp)
	var pts: PackedVector2Array = PL.arc_pts(center + Vector2(-0.2, -0.18) * u, 0.9, 0.38 * u, 0.7, 4)
	cv.stroke(pts, PackedFloat32Array([1.8, 1.6, 1.4, 1.0, 0.6]), c("#6A6456"), c("#6A6456"), 0.7, 1)


func _pebbles(cv: PL.Canvas, org: Vector2, cell: int, u: float, seed_value: int, count: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var center := org + Vector2(cell * 0.5, cell * 0.5)
	var ramp: Array = [c("#6E6A5E"), c("#8A8372"), c("#A89F88"), c("#C2B89E"), c("#D2C6AC")]
	var stones: Array = []
	for k: int in count:
		var p: Vector2 = center + Vector2(rng.randf_range(-0.55, 0.55), rng.randf_range(-0.45, 0.45)) * u
		stones.append([p, rng.randf_range(0.06, 0.13), rng.randf_range(1.0, 1.6), rng.randf() * PI])
	var nz := FastNoiseLite.new()
	nz.seed = seed_value + 3
	nz.frequency = 1.0 / 30.0
	for y: int in cell:
		for x: int in cell:
			var px := Vector2(org.x + x + 0.5, org.y + y + 0.5)
			var best: float = 9.0
			for st: Array in stones:
				var q: Vector2 = ((px - (st[0] as Vector2)) / u).rotated(-float(st[3]))
				var r: float = st[1]
				var e: float = st[2]
				var sd: float = (Vector2(q.x / e, q.y).length() - r) * minf(1.0, e)
				best = minf(best, sd)
			best += 0.012 * nz.get_noise_2d(px.x, px.y)
			if best > 0.2:
				continue
			var i: int = cv.idx(int(px.x), int(px.y))
			_stone_px(cv, i, best * 2.6, nz.get_noise_2d(px.x + 99.0, px.y) * 0.5 + 0.5, 0.0, 0.0, ramp)
