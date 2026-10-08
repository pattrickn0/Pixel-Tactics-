extends SceneTree
## A08, leva 2: props (tábuas, pontas de tronco, corda, ferro, pedra de ruína).
## Grava em assets/textures/scenery/props/. Prévia: gen_a08_preview_leva2.gd (a08-props.png).
##   "$G" --headless --path . --script tools/art/gen_a08_props.gd [-- planks | end | rope | iron | ruin]

const PL = preload("res://tools/art/paint_lib.gd")
const SS: int = 2
const U: float = 64.0 * SS

const WOOD: Array = ["#3A291E", "#4A3426", "#614530", "#7A5638", "#92704C", "#A88058"]
const END: Array = ["#5E4430", "#7A5638", "#8E6A48", "#A88058", "#B88E62", "#C49C6E"]
const ROPE: Array = ["#5E4C36", "#7A6448", "#9A8260", "#B49C76", "#C8B088", "#D6C29A"]
const IRON: Array = ["#26262C", "#303036", "#3A3A42", "#46464E", "#56565E", "#686870"]
const RUST: Array = ["#5A3A26", "#6E4A30"]
const RUIN: Array = ["#6E5C4C", "#8E7660", "#A88E74", "#BDA083", "#D0B896", "#E0CCAA"]
const MOSS: Array = ["#3F5F22", "#56702A", "#87A23A", "#A8B850"]


func _initialize() -> void:
	var only: String = ""
	if OS.get_cmdline_user_args().size() > 0:
		only = OS.get_cmdline_user_args()[0]
	if only == "" or only == "planks":
		_planks()
	if only == "" or only == "end":
		_wood_end()
	if only == "" or only == "rope":
		_rope()
	if only == "" or only == "iron":
		_iron()
	if only == "" or only == "ruin":
		_ruin()
	quit()


static func c(s: String) -> Color:
	return Color.html(s)


static func ramp_of(list: Array) -> Array:
	var out: Array = []
	for s: String in list:
		out.append(c(s))
	return out


## Campo periódico esticado na vertical (veios): fBm em (w, h / k) lido com interpolação em y.
static func vfield(w: int, h: int, k: int, cells: int, seed_value: int) -> PackedFloat32Array:
	var lh: int = h / k
	var f: PackedFloat32Array = PL.pfield(w, lh, cells, 3, seed_value, 0.4, 2, 0.55)
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
# Tábuas (256x256 = 4 x 4 u, seamless nos 2 eixos; as tábuas correm ao longo de v).
# 8 tábuas de larguras diferentes, frestas escuras, beira de cada tábua levemente chanfrada (sem lado
# iluminado), veios compridos, nós e algumas emendas de topo.
# ---------------------------------------------------------------------------

func _planks() -> void:
	var n: int = 256 * SS
	var cv := PL.Canvas.new(n, n, true, true)
	var ramp: Array = ramp_of(WOOD)
	var rng := RandomNumberGenerator.new()
	rng.seed = 14001
	var widths: Array = PL.split_len(rng, n, U * 0.4, U * 0.62)
	var grain: PackedFloat32Array = vfield(n, n, 16, 22, 14002)
	var grain2: PackedFloat32Array = vfield(n, n, 8, 9, 14003)
	var xs: Array = []
	var x: float = 0.0
	var tones: Array = []
	var joints: Array = []
	for wv: float in widths:
		xs.append(x)
		x += wv
		tones.append(rng.randf_range(-0.15, 0.15))
		joints.append(rng.randf() * n if rng.randf() < 0.6 else -1.0)
	for y: int in n:
		for xi: int in n:
			var i: int = y * n + xi
			var k: int = xs.size() - 1
			for j: int in xs.size():
				if xi < float(xs[j]) + float(widths[j]):
					k = j
					break
			var lx: float = xi - float(xs[k])
			var e: float = minf(lx, float(widths[k]) - lx)
			# emenda de topo (corte transversal) em algumas tábuas
			if float(joints[k]) >= 0.0:
				var dy: float = absf(wrapf(float(y) - float(joints[k]), -n * 0.5, n * 0.5))
				e = minf(e, dy * 1.3)
			var t: float = 0.58 + float(tones[k]) + 0.16 * (grain[i] - 0.5) + 0.1 * (grain2[i] - 0.5)
			t -= 0.18 * (1.0 - smoothstep(0.0, 9.0, e))
			var gap: float = 1.0 - smoothstep(1.5, 3.5, e)
			var col: Color = PL.ramp_at(ramp, clampf(t, 0.1, 1.0)).lerp(ramp[0], gap * 0.9)
			cv.r[i] = col.r
			cv.g[i] = col.g
			cv.b[i] = col.b
			cv.a[i] = 1.0
			cv.z[i] = smoothstep(0.0, 10.0, e) * 0.85 + 0.15 * grain[i]
	# veios escuros finos e nós
	for k: int in 140:
		var p := Vector2(rng.randf() * n, rng.randf() * n)
		var length: float = rng.randf_range(60.0, 220.0)
		var pts := PackedVector2Array()
		for s: int in 6:
			pts.append(p + Vector2(sin(float(s) * 0.8 + k) * 1.5, length * float(s) / 5.0))
		cv.stroke(pts, PackedFloat32Array([0.6, 1.4, 1.8, 1.6, 1.2, 0.5]), ramp[2], ramp[2], 0.5, 1, -0.2, 2)
	for k: int in 7:
		var p := Vector2(rng.randf() * n, rng.randf() * n)
		var r: float = rng.randf_range(6.0, 11.0)
		cv.blob(p.x, p.y, r * 0.8, r * 1.3, 0.0, ramp[1], 0.9, 0.5, 1)
		cv.blob(p.x, p.y, r * 0.4, r * 0.6, 0.0, ramp[0], 0.9, 0.4, 1)
		cv.blob(p.x, p.y - r * 0.9, r * 0.3, r * 0.6, 0.0, ramp[4], 0.4, 0.3, 1)
	var out: PL.Canvas = cv.down2()
	var rp: Array = PL.roll_pair(out.to_image(true), PL.normal_map(out.z, out.w, out.h, 3.0, 2, true, true), true, true)
	PL.save_png(rp[0], PL.TEX + "props/wood_planks.png")
	PL.save_png(rp[1], PL.TEX + "props/wood_planks_n.png")


# ---------------------------------------------------------------------------
# Ponta de tronco (256x256): disco de anéis (centro um pouco fora do meio), rachaduras radiais e anel de
# casca na borda (raio 0,47 do quadro); fora do disco, casca (para a UV da tampa nunca mostrar fundo).
# ---------------------------------------------------------------------------

func _wood_end() -> void:
	var n: int = 256 * SS
	var cv := PL.Canvas.new(n, n, false, false)
	var ramp: Array = ramp_of(END)
	var bark: Array = ramp_of(WOOD)
	var rng := RandomNumberGenerator.new()
	rng.seed = 14101
	var ctr := Vector2(n * 0.53, n * 0.48)
	var nz := FastNoiseLite.new()
	nz.seed = 14102
	nz.frequency = 1.0 / 60.0
	var R: float = n * 0.47
	for y: int in n:
		for x: int in n:
			var i: int = y * n + x
			var p := Vector2(x + 0.5, y + 0.5)
			var d: float = p.distance_to(Vector2(n, n) * 0.5) / R
			var dr: float = p.distance_to(ctr) + 6.0 * nz.get_noise_2d(p.x, p.y)
			var col: Color
			var z: float = 0.0
			if d > 1.0:
				col = PL.ramp_at(bark, 0.25 + 0.12 * nz.get_noise_2d(p.x * 1.2, p.y * 1.2))
				z = 0.3
			elif d > 0.92:
				# casca: escura, com sulcos
				col = PL.ramp_at(bark, 0.22 + 0.2 * (0.5 + 0.5 * nz.get_noise_2d(p.x * 1.6, p.y * 1.6)))
				z = 0.6
			else:
				# anéis: alternância suave de claro e escuro, mais apertados para fora
				var ring: float = 0.5 + 0.5 * sin(dr / (5.5 + 3.0 * (1.0 - d)) * TAU * 0.5)
				var t: float = 0.55 + 0.18 * (ring - 0.5) + 0.08 * nz.get_noise_2d(p.x * 0.5, p.y * 0.5)
				t -= 0.25 * (1.0 - smoothstep(0.0, 0.08, dr / R))  # medula escura
				t -= 0.12 * smoothstep(0.8, 0.92, d)  # alburno mais escuro perto da casca
				col = PL.ramp_at(ramp, clampf(t, 0.0, 1.0))
				z = 0.8 + 0.05 * ring
			cv.r[i] = col.r
			cv.g[i] = col.g
			cv.b[i] = col.b
			cv.a[i] = 1.0
			cv.z[i] = z
	# rachaduras radiais (do centro para fora, finas e escuras)
	for k: int in 5:
		var a: float = rng.randf() * TAU
		var r0: float = R * rng.randf_range(0.15, 0.4)
		var r1: float = R * rng.randf_range(0.6, 0.9)
		var pts := PackedVector2Array()
		for s: int in 5:
			var rr: float = lerpf(r0, r1, float(s) / 4.0)
			var aa: float = a + 0.05 * sin(float(s) * 2.0 + k)
			pts.append(ctr + Vector2(cos(aa), sin(aa)) * rr)
		cv.stroke(pts, PackedFloat32Array([0.6, 2.0, 2.6, 1.8, 0.6]), ramp[0], ramp[0], 0.9, 0, -0.5, 2)
	var out: PL.Canvas = cv.down2()
	PL.save_png(out.to_image(true), PL.TEX + "props/wood_end.png")
	PL.save_png(PL.normal_map(out.z, out.w, out.h, 2.5, 2, false, false), PL.TEX + "props/wood_end_n.png")


# ---------------------------------------------------------------------------
# Corda (64x256, seamless nos 2 eixos; u dá a volta na corda, v corre ao longo dela).
# 3 pernas trançadas em diagonal (8 voltas no quadro), cada perna com volume (meio claro, beira escura).
# ---------------------------------------------------------------------------

func _rope() -> void:
	var w: int = 64 * SS
	var h: int = 256 * SS
	var cv := PL.Canvas.new(w, h, true, true)
	var ramp: Array = ramp_of(ROPE)
	var fib: PackedFloat32Array = PL.pfield(w, h, 4, 2, 14201, 0.5, 2)
	var twist: float = float(h) / 8.0  # comprimento de uma volta
	for y: int in h:
		for x: int in w:
			var i: int = y * w + x
			# coordenada ao longo da diagonal: 3 pernas por volta
			var s: float = float(x) / w * 3.0 + float(y) / twist * 3.0
			var f: float = s - floorf(s)  # posição na perna (0..1, atravessando)
			var bulge: float = sin(f * PI)
			var t: float = 0.18 + 0.72 * pow(bulge, 0.6) + 0.12 * (fib[i] - 0.5)
			# fibras finas ao longo da perna (pouco contraste)
			t += 0.05 * sin((float(x) / w * 3.0 - float(y) / twist * 9.0) * TAU * 2.0) * bulge
			var col: Color = PL.ramp_at(ramp, clampf(t, 0.0, 1.0))
			cv.r[i] = col.r
			cv.g[i] = col.g
			cv.b[i] = col.b
			cv.a[i] = 1.0
	var out: PL.Canvas = cv.down2()
	PL.save_png(out.to_image(true), PL.TEX + "props/rope.png")


# ---------------------------------------------------------------------------
# Ferro escuro (128x128, seamless nos 2 eixos): batido (mossas largas), manchas de ferrugem quente.
# ---------------------------------------------------------------------------

func _iron() -> void:
	var n: int = 128 * SS
	var cv := PL.Canvas.new(n, n, true, true)
	var ramp: Array = ramp_of(IRON)
	var rng := RandomNumberGenerator.new()
	rng.seed = 14301
	var big: PackedFloat32Array = PL.pfield(n, n, 3, 3, 14302, 0.8, 4)
	var rust: PackedFloat32Array = PL.pfield(n, n, 4, 3, 14303, 1.0, 4)
	for i: int in n * n:
		var t: float = 0.45 + 0.25 * (big[i] - 0.5)
		var col: Color = PL.ramp_at(ramp, t)
		var rs: float = smoothstep(0.66, 0.8, rust[i])
		col = col.lerp(c(RUST[0]).lerp(c(RUST[1]), big[i]), rs * 0.6)
		cv.r[i] = col.r
		cv.g[i] = col.g
		cv.b[i] = col.b
		cv.a[i] = 1.0
		cv.z[i] = 0.5 + 0.2 * big[i]
	# mossas de martelo: côncavas (borda de cima escura, de baixo clara: luz de cima)
	for k: int in 46:
		var p := Vector2(rng.randf() * n, rng.randf() * n)
		var r: float = rng.randf_range(7.0, 16.0)
		cv.blob(p.x, p.y, r, r * 0.9, rng.randf() * TAU, ramp[2], 0.35, 0.3, 0, 0.0)
		cv.blob(p.x, p.y - r * 0.35, r * 0.8, r * 0.35, 0.0, ramp[1], 0.3, 0.2)
		cv.blob(p.x, p.y + r * 0.45, r * 0.7, r * 0.3, 0.0, ramp[4], 0.3, 0.2)
		for yy: int in range(floori(p.y - r), ceili(p.y + r)):
			for xx: int in range(floori(p.x - r), ceili(p.x + r)):
				var d: float = Vector2(xx + 0.5, yy + 0.5).distance_to(p) / r
				if d < 1.0:
					var i: int = cv.idx(xx, yy)
					cv.z[i] -= 0.25 * (1.0 - d * d)
	var out: PL.Canvas = cv.down2()
	PL.save_png(out.to_image(true), PL.TEX + "props/iron.png")
	PL.save_png(PL.normal_map(out.z, out.w, out.h, 2.5, 2, true, true), PL.TEX + "props/iron_n.png")


# ---------------------------------------------------------------------------
# Pedra de ruína (512x512 = 8 x 8 u, seamless nos 2 eixos): fiadas de blocos (tambores e lintel), pedra
# clara (#8E7660 a #E0CCAA) com chanfro claro no topo de cada bloco, juntas escuras quentes, lascas e
# musgo no ressalto de cima dos blocos (onde a chuva assenta). O musgo forte do topo da coluna fica com o
# shader (musgo pela normal).
# ---------------------------------------------------------------------------

func _ruin() -> void:
	var n: int = 512 * SS
	var cv := PL.Canvas.new(n, n, true, true)
	var ramp: Array = ramp_of(RUIN)
	var mramp: Array = ramp_of(MOSS)
	var rng := RandomNumberGenerator.new()
	rng.seed = 14401
	var rows: Array = PL.block_rows(rng, n, n, U * 0.8, U * 1.2, U * 1.3, U * 2.6)
	var nb: int = 0
	for r: Dictionary in rows:
		nb += (r["xs"] as Array).size()
	var tone: Array = []
	for b: int in nb:
		tone.append(rng.randf_range(-0.14, 0.14))
	var wx: PackedFloat32Array = PL.pfield(n, n, 6, 2, 14402, 0.5, 8)
	var wy: PackedFloat32Array = PL.pfield(n, n, 6, 2, 14403, 0.5, 8)
	var face: PackedFloat32Array = PL.pfield(n, n, 7, 3, 14404, 0.8, 4)
	var wear: PackedFloat32Array = PL.pfield(n, n, 12, 2, 14405, 0.6, 4)
	var moss_n: PackedFloat32Array = PL.pfield(n, n, 10, 3, 14406, 0.9, 4)
	var big: PackedFloat32Array = PL.pfield(n, n, 2, 2, 14407, 0.8, 8)
	var top_e := PackedFloat32Array()
	top_e.resize(n * n)
	for y: int in n:
		for x: int in n:
			var i: int = y * n + x
			var bk: Array = PL.block_at(rows, n, n, x + (wx[i] - 0.5) * 10.0, y + (wy[i] - 0.5) * 8.0)
			var id: int = bk[0]
			var et: float = bk[1]
			var eb: float = bk[2]
			var es: float = minf(bk[3], bk[4])
			# cantos gastos: a junta alarga onde a pedra lascou
			var jw: float = 2.5 + 6.0 * smoothstep(0.55, 0.85, wear[i])
			var e: float = minf(minf(et, eb), es)
			var t: float = 0.56 + float(tone[id]) + 0.14 * (face[i] - 0.5) + 0.16 * (big[i] - 0.5)
			t += 0.2 * (1.0 - smoothstep(0.0, 16.0, et)) - 0.2 * (1.0 - smoothstep(0.0, 22.0, eb)) - 0.06 * (1.0 - smoothstep(0.0, 14.0, es))
			var col: Color = PL.ramp_at(ramp, clampf(t, 0.05, 1.0))
			var jk: float = 1.0 - smoothstep(jw * 0.5, jw, e)
			col = col.lerp(c("#5C4C3E"), jk * 0.85)
			cv.r[i] = col.r
			cv.g[i] = col.g
			cv.b[i] = col.b
			cv.a[i] = 1.0
			cv.z[i] = smoothstep(0.0, 14.0, e) * (1.0 - jk) + 0.1 * face[i]
			top_e[i] = (1.0 - smoothstep(0.0, 22.0, et)) * (1.0 - jk)
	# musgo no ressalto de cima dos blocos (manchas, não faixa contínua)
	for k: int in 5200:
		var p := Vector2(rng.randf() * n, rng.randf() * n)
		var i: int = cv.idx(int(p.x), int(p.y))
		if top_e[i] < 0.35 or moss_n[i] < 0.45:
			continue
		var r: float = rng.randf_range(4.0, 8.0)
		var tt: float = rng.randf_range(0.1, 0.6)
		cv.blob(p.x, p.y, r * 3.0, r, rng.randf_range(-0.12, 0.12), PL.ramp_at(mramp, tt), 0.85, 0.35, 0, 0.0)
		cv.blob(p.x, p.y - r * 0.3, r * 2.0, r * 0.45, 0.0, PL.ramp_at(mramp, tt + 0.3), 0.6, 0.2)
		cv.z[i] = maxf(cv.z[i], 0.95)
	# lascas e rachaduras finas
	for k: int in 26:
		var p := Vector2(rng.randf() * n, rng.randf() * n)
		var pts: PackedVector2Array = PL.arc_pts(p, rng.randf_range(0.6, 2.5), rng.randf_range(20.0, 60.0), rng.randf_range(-1.0, 1.0), 4)
		cv.stroke(pts, PackedFloat32Array([0.5, 1.4, 1.6, 1.2, 0.4]), c("#6E5C4C"), c("#6E5C4C"), 0.7, 0, -0.4, 2)
	var out: PL.Canvas = cv.down2()
	var rp: Array = PL.roll_pair(out.to_image(true), PL.normal_map(out.z, out.w, out.h, 3.0, 3, true, true), true, true)
	PL.save_png(rp[0], PL.TEX + "props/ruin_stone.png")
	PL.save_png(rp[1], PL.TEX + "props/ruin_stone_n.png")
