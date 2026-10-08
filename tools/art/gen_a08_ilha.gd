extends SceneTree
## A08, leva 2: ilha (face do penhasco, fundo, raízes e cipós pendentes).
## Grava em assets/textures/scenery/island/. Prévia: gen_a08_preview_leva2.gd (a08-ilha-agua.png).
##   "$G" --headless --path . --script tools/art/gen_a08_ilha.gd [-- cliff | under | roots | vines]

const PL = preload("res://tools/art/paint_lib.gd")
const SS: int = 2
const U: float = 64.0 * SS  # px por unidade na tela de pintura

# Penhasco (sombra -> luz): fresta fria, terra escura, terra/rocha média, luz no topo dos blocos
const CLIFF: Array = ["#3E3640", "#4A3628", "#57402F", "#664A35", "#7A5A40", "#9A7656"]
# Fundo da ilha: mais escuro e frio, placas grandes
const UNDER: Array = ["#2E2A34", "#3A3440", "#463A3A", "#564436", "#6A4E3A", "#7E5C42"]
const ROOT: Array = ["#2E221A", "#3A291E", "#4A3426", "#5A4030", "#6E5038", "#86644A"]
const VINE: Array = ["#22381A", "#2C4520", "#3F5F22", "#56702A", "#6E8C30", "#87A23A"]
const MOSS: Array = ["#3F5F22", "#56702A", "#87A23A"]


func _initialize() -> void:
	var only: String = ""
	if OS.get_cmdline_user_args().size() > 0:
		only = OS.get_cmdline_user_args()[0]
	if only == "" or only == "cliff":
		_rock_face("island/cliff", CLIFF, 12001, 5, 4, 0.62, 0.3, 0.3, 6, 40.0)
	if only == "" or only == "under":
		_rock_face("island/under", UNDER, 12101, 3, 3, 0.9, 0.7, 0.0, 2, 70.0)
	if only == "" or only == "roots":
		_roots()
	if only == "" or only == "vines":
		_vines()
	quit()


static func c(s: String) -> Color:
	return Color.html(s)


static func ramp_of(list: Array) -> Array:
	var out: Array = []
	for s: String in list:
		out.append(c(s))
	return out


# ---------------------------------------------------------------------------
# Face de rocha (512x512 = 8 x 8 u, seamless nos 2 eixos): blocos de Voronoi periódico, com frestas
# escuras, topo de cada bloco mais claro (luz só de cima), base em sombra, faces com manchas grandes,
# estratos finos na terra, raízes finas e pouco musgo. Altura -> normal suave.
# ---------------------------------------------------------------------------

func _rock_face(rel: String, ramp_s: Array, seed_value: int, cells_x: int, cells_y: int, aniso: float, sub_share: float,
		moss_share: float, root_count: int, warp_px: float) -> void:
	var n: int = 512 * SS
	var cv := PL.Canvas.new(n, n, true, true)
	var ramp: Array = ramp_of(ramp_s)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var vor := PL.Voronoi.new(n, n, cells_x, cells_y, 0.85, seed_value + 10, aniso)
	var sub := PL.Voronoi.new(n, n, cells_x * 2 + 1, cells_y * 2 + 1, 0.9, seed_value + 11, aniso)
	var nb: int = cells_x * cells_y
	var tone: Array = []
	var earth: Array = []
	var mossy: Array = []
	var split: Array = []
	for b: int in nb:
		tone.append(rng.randf_range(-0.16, 0.16))
		earth.append(rng.randf() < 0.45)
		mossy.append(rng.randf() < moss_share)
		split.append(rng.randf() < sub_share)
	var wx: PackedFloat32Array = PL.pfield(n, n, 4, 2, seed_value + 1, 0.6, 8)
	var wy: PackedFloat32Array = PL.pfield(n, n, 4, 2, seed_value + 2, 0.6, 8)
	var face: PackedFloat32Array = PL.pfield(n, n, 6, 3, seed_value + 3, 0.8, 4)
	var strat: PackedFloat32Array = PL.pfield(n, n, 3, 2, seed_value + 4, 0.5, 8)
	var fis: PackedFloat32Array = PL.pfield(n, n, 10, 2, seed_value + 5, 0.4, 4)
	var big: PackedFloat32Array = PL.pfield(n, n, 2, 2, seed_value + 6, 0.8, 8)
	var top_edge := PackedFloat32Array()
	top_edge.resize(n * n)
	var block_id := PackedInt32Array()
	block_id.resize(n * n)
	for y: int in n:
		for x: int in n:
			var i: int = y * n + x
			var xx: float = x + (wx[i] - 0.5) * warp_px
			var yy: float = y + (wy[i] - 0.5) * warp_px
			var vo: Array = vor.at(xx, yy)
			var id: int = vo[0]
			block_id[i] = id
			var e: float = vo[2]
			var dv: Vector2 = (vo[3] as Vector2).normalized()
			# fratura secundária dentro de alguns blocos (mais fina e mais rasa)
			var e2: float = 999.0
			var dv2 := Vector2.ZERO
			if bool(split[id]):
				var vs: Array = sub.at(xx, yy)
				e2 = vs[2]
				dv2 = (vs[3] as Vector2).normalized()
			var up: float = clampf(-dv.y, 0.0, 1.0)  # vizinho acima: borda de cima do bloco
			var dn: float = clampf(dv.y, 0.0, 1.0)  # vizinho abaixo: base do bloco
			var sd: float = 1.0 - absf(dv.y)
			var t: float = 0.52 + float(tone[id]) + 0.16 * (face[i] - 0.5) + 0.22 * (big[i] - 0.5)
			t += 0.22 * up * (1.0 - smoothstep(0.0, 34.0, e)) - 0.26 * dn * (1.0 - smoothstep(0.0, 46.0, e)) - 0.07 * sd * (1.0 - smoothstep(0.0, 22.0, e))
			if e2 < 60.0:
				t += 0.1 * clampf(-dv2.y, 0.0, 1.0) * (1.0 - smoothstep(0.0, 20.0, e2)) - 0.12 * clampf(dv2.y, 0.0, 1.0) * (1.0 - smoothstep(0.0, 26.0, e2))
			if bool(earth[id]):
				t += 0.05 * sin((yy * 0.09) + strat[i] * 8.0) * smoothstep(0.3, 0.7, strat[i]) + 0.03
			else:
				t -= 0.02
			var z: float = smoothstep(0.0, 22.0, e) * 0.8 + 0.12 * face[i] + 0.08 * smoothstep(0.0, 12.0, e2)
			var col: Color = PL.ramp_at(ramp, clampf(t, 0.1, 1.0))
			# frestas: escura e estreita na borda principal, mais rasa na secundária
			var fw: float = 2.5 + 4.5 * fis[i]
			var fk: float = 1.0 - smoothstep(fw * 0.5, fw, e)
			var fk2: float = (1.0 - smoothstep(1.0, 3.0, e2)) * 0.4
			fk = maxf(fk, fk2)
			col = col.lerp(ramp[1].lerp(ramp[0], 0.5), fk * 0.9)
			z *= 1.0 - fk * 0.9
			cv.r[i] = col.r
			cv.g[i] = col.g
			cv.b[i] = col.b
			cv.a[i] = 1.0
			cv.z[i] = z
			top_edge[i] = up * (1.0 - smoothstep(0.0, 26.0, e)) * (1.0 - fk)
	# Pinceladas largas nas faces (planos chapados, sem grão)
	for k: int in 650:
		var p := Vector2(rng.randf() * n, rng.randf() * n)
		var i: int = cv.idx(int(p.x), int(p.y))
		if cv.z[i] < 0.55:
			continue
		var base: Color = cv.get_c(i)
		var sh: float = rng.randf_range(-0.07, 0.06)
		var col: Color = base.lightened(sh) if sh > 0.0 else base.darkened(-sh)
		var ang: float = PI * 0.5 + rng.randf_range(-0.3, 0.3) if rng.randf() < 0.6 else rng.randf_range(-0.3, 0.3)
		var pts: PackedVector2Array = PL.arc_pts(p, ang, rng.randf_range(30.0, 100.0), rng.randf_range(-0.3, 0.3), 4)
		var r0: float = rng.randf_range(7.0, 15.0)
		cv.stroke(pts, PackedFloat32Array([r0 * 0.4, r0, r0, r0 * 0.8, r0 * 0.3]), col, col, rng.randf_range(0.3, 0.5), 1)
	# Musgo no topo de alguns blocos (pouco)
	var mramp: Array = ramp_of(MOSS)
	for k: int in 2600:
		var p := Vector2(rng.randf() * n, rng.randf() * n)
		var i: int = cv.idx(int(p.x), int(p.y))
		if not bool(mossy[block_id[i]]) or top_edge[i] < 0.5:
			continue
		var r: float = rng.randf_range(4.0, 8.0)
		var tt: float = rng.randf()
		cv.blob(p.x, p.y, r * 2.2, r, rng.randf_range(-0.2, 0.2), PL.ramp_at(mramp, tt * 0.5), 0.9, 0.5)
		cv.blob(p.x, p.y - r * 0.3, r * 1.4, r * 0.45, 0.0, PL.ramp_at(mramp, tt * 0.5 + 0.4), 0.7, 0.3)
		cv.z[i] = maxf(cv.z[i], 0.9)
	# Raízes finas atravessando a face (escuras nas beiradas, mais claras no meio)
	var rramp: Array = ramp_of(ROOT)
	for k: int in root_count:
		var p0 := Vector2(rng.randf() * n, rng.randf() * n)
		var pts := PackedVector2Array()
		var ang: float = PI * 0.5 + rng.randf_range(-0.6, 0.6)
		var p: Vector2 = p0
		var seg: int = 12
		var length: float = rng.randf_range(220.0, 460.0)
		for s: int in seg + 1:
			pts.append(p)
			ang += rng.randf_range(-0.3, 0.3)
			ang = lerp_angle(ang, PI * 0.5, 0.1)
			p += Vector2(cos(ang), sin(ang)) * length / seg
		var r0: float = rng.randf_range(6.0, 10.0)
		var radii: PackedFloat32Array = PL.taper(seg, r0, 1.5, 1.2)
		cv.blob(pts[0].x, pts[0].y, r0 * 2.2, r0 * 1.4, 0.0, ramp[1], 0.6, 0.3, 1)
		cv.stroke(pts, radii, rramp[1], rramp[0], 1.0, 0, 0.7, 1)
		var radii2 := PackedFloat32Array()
		for v: float in radii:
			radii2.append(v * 0.5)
		cv.stroke(pts, radii2, rramp[4], rramp[3], 0.8)
	var out: PL.Canvas = cv.down2()
	var rp: Array = PL.roll_pair(out.to_image(true), PL.normal_map(out.z, out.w, out.h, 3.2, 3, true, true), true, true)
	PL.save_png(rp[0], PL.TEX + rel + ".png")
	PL.save_png(rp[1], PL.TEX + rel + "_n.png")


# ---------------------------------------------------------------------------
# Raízes pendentes: atlas de 4 faixas de 128 x 1024 (512x1024), alfa recortado.
# Cada raiz sai grossa do topo da faixa (v = 0, presa na borda da ilha), desce torcendo, se ramifica e
# afina. Meio mais claro (volume), beiradas escuras; nada de luz lateral.
# ---------------------------------------------------------------------------

func _roots() -> void:
	var cw: int = 128 * SS
	var h: int = 1024 * SS
	var cv := PL.Canvas.new(cw * 4, h, false, false)
	var ramp: Array = ramp_of(ROOT)
	cv.fill(ramp[2], 0.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12201
	for k: int in 4:
		var x0: float = k * cw
		var cx: float = x0 + cw * 0.5
		var r0: float = cw * rng.randf_range(0.17, 0.22)
		var length: float = h * rng.randf_range(0.82, 0.95)
		_root_branch(cv, rng, Vector2(cx + rng.randf_range(-0.08, 0.08) * cw, -4.0), PI * 0.5 + rng.randf_range(-0.12, 0.12), length, r0, x0 + 6.0, x0 + cw - 6.0, ramp, 2)
	var img: Image = cv.down2().to_image(false)
	PL.dilate_rgb(img, 24)
	PL.save_png(img, PL.TEX + "island/roots_hang.png")


func _root_branch(cv: PL.Canvas, rng: RandomNumberGenerator, p0: Vector2, ang0: float, length: float, r0: float, xmin: float, xmax: float, ramp: Array, depth: int) -> void:
	var seg: int = 24
	var pts := PackedVector2Array()
	var p: Vector2 = p0
	var ang: float = ang0
	var step: float = length / seg
	for s: int in seg + 1:
		pts.append(p)
		ang += rng.randf_range(-0.16, 0.16)
		ang = lerp_angle(ang, PI * 0.5, 0.12)
		var np: Vector2 = p + Vector2(cos(ang), sin(ang)) * step
		var margin: float = r0 * (1.0 - float(s) / seg) + 3.0
		np.x = clampf(np.x, xmin + margin, xmax - margin)
		p = np
	var radii: PackedFloat32Array = PL.taper(seg, r0, 1.6, 0.8)
	# ramos: saem do meio para os lados e caem
	if depth > 0:
		for b: int in rng.randi_range(1, 2):
			var at: int = rng.randi_range(5, 14)
			var side: float = -1.0 if rng.randf() < 0.5 else 1.0
			_root_branch(cv, rng, pts[at], PI * 0.5 + side * rng.randf_range(0.35, 0.7), length * rng.randf_range(0.3, 0.5), radii[at] * 0.55, xmin, xmax, ramp, depth - 1)
	# corpo: escuro, meio claro (volume), fio de luz no centro, sulcos de casca
	cv.stroke(pts, radii, ramp[1], ramp[0], 1.0)
	var mid := PackedFloat32Array()
	var core := PackedFloat32Array()
	for v: float in radii:
		mid.append(v * 0.72)
		core.append(v * 0.3)
	cv.stroke(pts, mid, ramp[3], ramp[2], 1.0)
	cv.stroke(pts, core, ramp[5], ramp[3], 0.55)
	for s: int in range(1, seg, 2):
		var q: Vector2 = pts[s]
		var d: Vector2 = (pts[s + 1] - pts[s - 1]).normalized()
		var nrm := Vector2(-d.y, d.x)
		var off: float = rng.randf_range(-0.5, 0.5) * radii[s]
		var a: Vector2 = q + nrm * off
		cv.stroke(PackedVector2Array([a, a + d * radii[s] * 1.6]), PackedFloat32Array([maxf(radii[s] * 0.1, 1.0), 0.8]), ramp[1], ramp[1], 0.7)


# ---------------------------------------------------------------------------
# Cipós pendentes: atlas de 4 faixas de 128 x 1024 (512x1024), alfa recortado.
# Talo fino ondulando do topo (v = 0) para baixo, com folhas alternadas e cachos; a ponta acaba em folhas.
# ---------------------------------------------------------------------------

func _vines() -> void:
	var cw: int = 128 * SS
	var h: int = 1024 * SS
	var cv := PL.Canvas.new(cw * 4, h, false, false)
	var ramp: Array = ramp_of(VINE)
	cv.fill(ramp[2], 0.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12301
	for k: int in 4:
		var x0: float = k * cw
		var length: float = h * rng.randf_range(0.7, 0.96)
		var strands: int = 1 if k % 2 == 0 else 2
		for s: int in strands:
			var cx: float = x0 + cw * (0.5 if strands == 1 else (0.36 + 0.28 * s))
			_vine(cv, rng, Vector2(cx, -4.0), length * (1.0 if s == 0 else 0.62), x0 + 14.0, x0 + cw - 14.0, ramp)
	var img: Image = cv.down2().to_image(false)
	PL.dilate_rgb(img, 24)
	PL.save_png(img, PL.TEX + "island/vines_hang.png")


func _vine(cv: PL.Canvas, rng: RandomNumberGenerator, p0: Vector2, length: float, xmin: float, xmax: float, ramp: Array) -> void:
	var seg: int = 40
	var pts := PackedVector2Array()
	var ph: float = rng.randf() * TAU
	var amp: float = rng.randf_range(8.0, 22.0)
	var wl: float = rng.randf_range(160.0, 280.0)
	for s: int in seg + 1:
		var y: float = p0.y + length * float(s) / seg
		var x: float = p0.x + sin(y / wl * TAU + ph) * amp * (0.4 + 0.6 * float(s) / seg)
		pts.append(Vector2(clampf(x, xmin, xmax), y))
	cv.stroke(pts, PL.taper(seg, 5.0, 2.6), ramp[2], ramp[1], 1.0)
	cv.stroke(pts, PL.taper(seg, 2.0, 1.0), ramp[4], ramp[3], 0.7)
	# folhas alternadas (as de cima mais escuras: sombra da borda), cachos em alguns nós
	var y_step: float = rng.randf_range(22.0, 30.0)
	var y: float = p0.y + 30.0
	var side: float = 1.0
	while y < p0.y + length:
		var f: float = (y - p0.y) / length
		var s_idx: int = clampi(int(f * seg), 0, seg - 1)
		var q: Vector2 = pts[s_idx].lerp(pts[s_idx + 1], f * seg - s_idx)
		var count: int = 1 if rng.randf() < 0.5 else (2 if rng.randf() < 0.6 else 3)
		for c2: int in count:
			var ang: float = PI * 0.5 + side * rng.randf_range(0.7, 1.25) + rng.randf_range(-0.2, 0.2)
			var ll: float = rng.randf_range(32.0, 52.0)
			var t: float = clampf(0.35 + 0.45 * f + rng.randf_range(-0.12, 0.12), 0.1, 0.95)
			var lp: PackedVector2Array = PL.arc_pts(q, ang, ll, side * rng.randf_range(0.2, 0.6), 4)
			var wv: float = ll * rng.randf_range(0.26, 0.34)
			lp[4].x = clampf(lp[4].x, xmin - 10.0, xmax + 10.0)
			cv.stroke(lp, PackedFloat32Array([1.5, wv * 0.8, wv, wv * 0.7, 0.8]), PL.ramp_at(ramp, t - 0.15), PL.ramp_at(ramp, t + 0.05), 1.0)
			cv.stroke(PL.arc_pts(q, ang, ll * 0.75, 0.0, 2), PackedFloat32Array([0.8, 1.0, 0.6]), PL.ramp_at(ramp, t - 0.25), PL.ramp_at(ramp, t - 0.1), 0.6)
			side = -side
		y += y_step * rng.randf_range(0.7, 1.3)
	# ponta: cachinho de folhas
	var tip: Vector2 = pts[seg]
	for k: int in 5:
		var ang: float = PI * 0.5 + rng.randf_range(-1.1, 1.1)
		var ll: float = rng.randf_range(24.0, 38.0)
		cv.stroke(PL.arc_pts(tip + Vector2(0, -8), ang, ll, rng.randf_range(-0.4, 0.4), 4), PackedFloat32Array([1.5, ll * 0.25, ll * 0.3, ll * 0.2, 0.8]), ramp[2], ramp[4], 1.0)
