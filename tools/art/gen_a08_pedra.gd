extends SceneTree
## A08, leva 1: pedra (muro em blocos, muro com musgo, topo de muro, lajes), com normal maps suaves.
## Grava em assets/textures/scenery/stone/. Prévia: gen_a08_preview_pedra.gd.
##   "$G" --headless --path . --script tools/art/gen_a08_pedra.gd [-- blocks | top | slabs]

const PL = preload("res://tools/art/paint_lib.gd")
const SS: int = 2

# Fiadas do muro (altura em px finais, somam 128 = 2 unidades) e deslocamento vertical do padrão,
# para nenhuma junta cair na borda da textura.
const COURSES: Array = [34, 26, 38, 30]
const COURSE_Y0: int = 9
const STONE: Array = ["#5C5646", "#8E8466", "#A99D78", "#C2B58C", "#D2C59C", "#E0D2A8"]
const MOSS: Array = ["#2C4520", "#3F5F22", "#56702A", "#87A23A"]

var _layout: Array = []  # blocos: [x0, y0, largura, altura, tom] em px da tela de pintura


func _initialize() -> void:
	var only: String = ""
	if OS.get_cmdline_user_args().size() > 0:
		only = OS.get_cmdline_user_args()[0]
	if only == "" or only == "blocks":
		_build_layout(7101)
		var plain: Array = _wall_blocks(false)
		var mossy: Array = _wall_blocks(true)
		# corte horizontal da repetição numa coluna calma das duas versões (albedo e _n), igual nas duas
		# (as fiadas das duas continuam alinhadas)
		var rx: int = PL.best_roll_multi([plain[0], mossy[0], plain[1], mossy[1]], true)
		for e: Array in [["wall_blocks", plain], ["wall_blocks_mossy", mossy]]:
			var imgs: Array = e[1]
			PL.save_png(PL.roll(imgs[0], rx, 0), PL.TEX + "stone/" + str(e[0]) + ".png")
			PL.save_png(PL.roll(imgs[1], rx, 0), PL.TEX + "stone/" + str(e[0]) + "_n.png")
	if only == "" or only == "top":
		_wall_top()
	if only == "" or only == "slabs":
		_slabs()
	quit()


static func c(s: String) -> Color:
	return Color.html(s)


static func sd_box(p: Vector2, hx: float, hy: float, rad: float) -> float:
	var qx: float = absf(p.x) - hx + rad
	var qy: float = absf(p.y) - hy + rad
	return Vector2(maxf(qx, 0.0), maxf(qy, 0.0)).length() + minf(maxf(qx, qy), 0.0) - rad


# ---------------------------------------------------------------------------
# Layout dos blocos (compartilhado entre wall_blocks e wall_blocks_mossy)
# ---------------------------------------------------------------------------

func _build_layout(seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_layout.clear()
	var w: int = 512 * SS
	var y: int = COURSE_Y0 * SS
	var offset: float = rng.randf() * w
	for ci: int in COURSES.size():
		var ch: int = int(COURSES[ci]) * SS
		# comprimentos de bloco de 0,55 a 1,45 unidade, fechando a volta em 512
		var lens: Array = []
		var total: int = 0
		while total < w:
			var ln: int = roundi(rng.randf_range(40.0, 100.0)) * SS
			lens.append(ln)
			total += ln
		var extra: int = total - w
		lens[lens.size() - 1] = int(lens[lens.size() - 1]) - extra
		if int(lens[lens.size() - 1]) < 30 * SS:
			var last: int = lens.pop_back()
			lens[lens.size() - 1] = int(lens[lens.size() - 1]) + last
		var x: float = offset
		for ln: int in lens:
			var tone: float = rng.randf_range(-1.0, 1.0)
			# Alguns blocos se dividem em dois de meia altura (fiadas irregulares)
			if rng.randf() < 0.12 and ch >= 34 * SS:
				var hh: int = ch / 2 + rng.randi_range(-2, 2) * SS
				var l2: int = ln if rng.randf() < 0.5 else roundi(ln * rng.randf_range(0.45, 0.6))
				_layout.append([x, y, ln, hh, tone])
				_layout.append([x, y + hh, l2, ch - hh, rng.randf_range(-1.0, 1.0)])
				if l2 < ln:
					_layout.append([x + l2, y + hh, ln - l2, ch - hh, rng.randf_range(-1.0, 1.0)])
			else:
				_layout.append([x, y, ln, ch, tone])
			x += ln
		y += ch
		offset += rng.randf_range(0.3, 0.7) * 70.0 * SS


## Para um pixel (com volta), devolve [distância com sinal ao bloco (px, < 0 dentro), x local 0..1,
## y local 0..1 (0 = topo), tom do bloco, índice do bloco].
func _block_at(px: float, py: float, w: float, h: float) -> Array:
	var best: Array = [1e9, 0.0, 0.0, 0.0, -1]
	for bi: int in _layout.size():
		var b: Array = _layout[bi]
		var bx: float = b[0]
		var by: float = b[1]
		var bw: float = b[2]
		var bh: float = b[3]
		var lx: float = fposmod(px - bx, w)
		var ly: float = fposmod(py - by, h)
		if lx > bw + 8.0 * SS and lx < w - 8.0 * SS:
			continue
		if ly > bh + 8.0 * SS and ly < h - 8.0 * SS:
			continue
		if lx > w * 0.5:
			lx -= w
		if ly > h * 0.5:
			ly -= h
		var q := Vector2(lx - bw * 0.5, ly - bh * 0.5)
		var sd: float = sd_box(q, bw * 0.5, bh * 0.5, 5.0 * SS)
		if sd < best[0]:
			best = [sd, clampf(lx / bw, 0.0, 1.0), clampf(ly / bh, 0.0, 1.0), b[4], bi]
	return best


# ---------------------------------------------------------------------------
# Muro em blocos (512x128 = 8 x 2 unidades, seamless nos 2 eixos)
# ---------------------------------------------------------------------------

func _wall_blocks(mossy: bool) -> Array:
	var w: int = 512 * SS
	var h: int = 128 * SS
	var cv := PL.Canvas.new(w, h, true, true)
	cv.fill(c(STONE[0]))
	var n_face: PackedFloat32Array = PL.pfield(w, h, 16, 3, 7201, 0.8, 2, 0.55)
	var n_edge: PackedFloat32Array = PL.pfield(w, h, 48, 2, 7202, 0.6, 2, 0.5)
	var n_moss: PackedFloat32Array = PL.pfield(w, h, 20, 3, 7203, 1.0, 2, 0.5)
	var n_big: PackedFloat32Array = PL.pfield(w, h, 2, 2, 7204, 0.8, 4, 0.5)
	var bevel: float = 7.0 * SS
	var joint: float = 2.2 * SS
	for y: int in h:
		for x: int in w:
			var i: int = y * w + x
			var bl: Array = _block_at(x + 0.5, y + 0.5, w, h)
			# junta torta: a borda do bloco varia com ruído (lascas)
			var sd: float = float(bl[0]) + joint + (n_edge[i] - 0.5) * 3.2 * SS
			var tone: float = bl[3]
			if sd > 0.0:
				# junta: escura e funda, um pouco mais clara perto do bloco
				var jc: Color = c(STONE[0]).lerp(c(STONE[1]), clampf(1.0 - sd / (2.0 * SS), 0.0, 1.0) * 0.35)
				cv.r[i] = jc.r
				cv.g[i] = jc.g
				cv.b[i] = jc.b
				cv.z[i] = 0.0
				continue
			var depth: float = clampf(-sd / bevel, 0.0, 1.0)
			var ly: float = bl[2]
			# face: tom do bloco + planos (facetas) de baixa frequência
			var f: float = n_face[i]
			var lv: float = f * 3.0
			var fl: float = floorf(lv)
			var facet: float = (fl + smoothstep(0.35, 0.65, lv - fl)) / 3.0
			var t: float = 0.56 + 0.1 * tone + 0.16 * (facet - 0.5) + 0.34 * (n_big[i] - 0.5)
			# luz de cima: topo do bloco um pouco mais claro que a base
			t += 0.06 * (0.5 - ly)
			# chanfro: claro em cima, escuro embaixo, neutro dos lados
			var bev: float = 1.0 - smoothstep(0.0, 1.0, depth)
			if bev > 0.0:
				var top_w: float = smoothstep(0.62, 0.15, ly)
				var bot_w: float = smoothstep(0.38, 0.85, ly)
				t += bev * (0.5 * top_w - 0.38 * bot_w - 0.1 * (1.0 - top_w - bot_w))
			var col: Color = PL.ramp_at(_stone_ramp(), clampf(t, 0.0, 1.0))
			var warm: float = sin(float(bl[4]) * 2.39)
			col = col.lerp(c("#B4AE96"), 0.22 * maxf(warm, 0.0)).lerp(c("#C8AE7E"), 0.18 * maxf(-warm, 0.0))
			cv.r[i] = col.r
			cv.g[i] = col.g
			cv.b[i] = col.b
			cv.z[i] = 0.55 + 0.45 * smoothstep(0.0, 1.0, depth) + 0.06 * (facet - 0.5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7301 if not mossy else 7302
	_cracks(cv, rng, 14)
	# Musgo em algumas juntas (as horizontais seguram mais)
	_joint_moss(cv, rng, n_moss, 0.66 if not mossy else 0.58)
	var moss_cov: float = 0.0
	if mossy:
		moss_cov = _drape_moss(cv, rng, n_moss)
	var out: PL.Canvas = cv.down2()
	if mossy:
		print("wall_blocks_mossy: musgo cobre %.0f%%" % (moss_cov * 100.0))
	return [out.to_image(true), PL.normal_map(out.z, out.w, out.h, 5.0, 2, true, true)]


func _stone_ramp() -> Array:
	var out: Array = []
	for s: String in STONE:
		out.append(c(s))
	return out


## Rachaduras finas nos blocos (traço escuro com borda clara embaixo não: luz só de cima).
func _cracks(cv: PL.Canvas, rng: RandomNumberGenerator, count: int) -> void:
	for k: int in count:
		var p := Vector2(rng.randf() * cv.w, rng.randf() * cv.h)
		var i: int = cv.idx(int(p.x), int(p.y))
		if cv.z[i] < 0.9:
			continue
		var ang: float = rng.randf_range(0.6, 2.5)
		var pts: PackedVector2Array = PL.arc_pts(p, ang, rng.randf_range(10.0, 26.0) * SS, rng.randf_range(-1.2, 1.2), 4)
		cv.stroke(pts, PL.taper(4, 1.3 * SS * 0.5 + 0.6, 0.5), c(STONE[1]), c(STONE[2]), 0.85)


## Musgo nas juntas: tufinhos de folha onde o ruído passa do limiar e a junta está perto.
func _joint_moss(cv: PL.Canvas, rng: RandomNumberGenerator, n_moss: PackedFloat32Array, th: float) -> void:
	for k: int in 2600:
		var p := Vector2(rng.randf() * cv.w, rng.randf() * cv.h)
		var i: int = cv.idx(int(p.x), int(p.y))
		if cv.z[i] > 0.3 or n_moss[i] < th:
			continue
		var r: float = rng.randf_range(2.0, 3.6) * SS
		var col: Color = PL.ramp_at(_moss_ramp(), rng.randf_range(0.25, 0.75))
		cv.blob(p.x, p.y - r * 0.2, r * 1.2, r, rng.randf() * PI, col, 0.95, 0.55, 0, 0.6)
		cv.blob(p.x, p.y - r * 0.5, r * 0.7, r * 0.5, 0.0, col.lightened(0.18), 0.7, 0.3)


func _moss_ramp() -> Array:
	var out: Array = []
	for s: String in MOSS:
		out.append(c(s))
	return out


## Musgo e folhagem escura escorrendo do topo (y = 0) e saindo das juntas. Devolve a cobertura.
func _drape_moss(cv: PL.Canvas, rng: RandomNumberGenerator, n_moss: PackedFloat32Array) -> float:
	var w: int = cv.w
	var h: int = cv.h
	# densidade: cheia no topo (com volta: o fim da textura encosta no topo da repetição de baixo)
	var dens := PackedFloat32Array()
	dens.resize(w * h)
	var drip_len := PackedFloat32Array()
	drip_len.resize(w)
	var n_drip: PackedFloat32Array = PL.pfield(w, 8, 24, 2, 7401, 0.5, 1, 0.5)
	for x: int in w:
		drip_len[x] = 0.16 + 0.7 * pow(n_drip[x], 1.4)
	for y: int in h:
		var fy: float = float(y) / float(h)
		for x: int in w:
			var i: int = y * w + x
			var top: float = 1.0 - smoothstep(0.1, drip_len[x], fy)
			var bottom: float = smoothstep(0.92, 1.0, fy) * 0.9
			var d: float = maxf(top, bottom) + 0.5 * (n_moss[i] - 0.5)
			# tufos saindo das juntas (mais na metade de cima)
			if cv.z[i] < 0.45:
				d += 0.3 * (1.0 - smoothstep(0.0, 0.9, fy)) + 0.25 * smoothstep(0.55, 0.75, n_moss[i])
			dens[i] = clampf(d, 0.0, 1.0)
			# pedra úmida e na sombra do musgo: escurece e esfria
			var damp: float = 0.14 + smoothstep(0.15, 0.6, dens[i]) * 0.36
			if damp > 0.0:
				cv.r[i] = lerpf(cv.r[i], cv.r[i] * 0.55, damp)
				cv.g[i] = lerpf(cv.g[i], cv.g[i] * 0.62, damp)
				cv.b[i] = lerpf(cv.b[i], cv.b[i] * 0.55, damp)
	var moss_a := PackedFloat32Array()
	moss_a.resize(w * h)
	# base escura (fresta entre as folhas)
	for i: int in w * h:
		var t0: float = smoothstep(0.5, 0.6, dens[i])
		if t0 > 0.0:
			cv.blend(i, c(MOSS[0]).lerp(c("#24381C"), 0.5), t0)
			cv.z[i] = maxf(cv.z[i], 0.9 * t0)
	var leaves: Array = []
	for k: int in 9000:
		var p := Vector2(rng.randf() * w, rng.randf() * h)
		var i: int = cv.idx(int(p.x), int(p.y))
		if rng.randf() > smoothstep(0.4, 0.6, dens[i]):
			continue
		leaves.append(p)
	leaves.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.y < b.y)
	var ramp: Array = _moss_ramp()
	for p: Vector2 in leaves:
		var i: int = cv.idx(int(p.x), int(p.y))
		var r: float = rng.randf_range(3.4, 7.5) * SS
		var t: float = clampf(0.08 + 0.5 * n_moss[i] + rng.randf_range(-0.15, 0.15), 0.0, 0.75)
		var col: Color = PL.ramp_at(ramp, t)
		var rot: float = rng.randf_range(-0.6, 0.6) + PI * 0.5
		cv.blob(p.x, p.y, r, r * 0.72, rot, col, 1.0, 0.55, 0, 1.0 + 0.3 * rng.randf())
		cv.blob(p.x, p.y - r * 0.32, r * 0.6, r * 0.4, rot, PL.ramp_at(ramp, t + 0.18), 0.75, 0.3)
		for yy: int in range(int(p.y - r), int(p.y + r) + 1):
			for xx: int in range(int(p.x - r), int(p.x + r) + 1):
				if Vector2(xx + 0.5 - p.x, yy + 0.5 - p.y).length() < r * 0.8:
					var j: int = cv.idx(xx, yy)
					moss_a[j] = 1.0
	# Fios pendentes (cipó fino com folhinhas) descendo do topo
	for k: int in 12:
		var x0: float = rng.randf() * w
		var length: float = rng.randf_range(0.35, 0.75) * h
		var pts := PackedVector2Array()
		var steps: int = 10
		for s: int in steps + 1:
			var yy: float = length * float(s) / float(steps)
			pts.append(Vector2(x0 + sin(yy * 0.05 + k) * 4.0 * SS, yy))
		cv.stroke(pts, PL.taper(steps, 1.4 * SS, 0.8 * SS), c(MOSS[1]), c(MOSS[0]), 1.0, 0, 0.8, 1)
		for s: int in steps:
			var q: Vector2 = pts[s]
			var side: float = 1.0 if s % 2 == 0 else -1.0
			var lr: float = rng.randf_range(3.0, 4.6) * SS * (1.0 - 0.45 * float(s) / float(steps))
			cv.blob(q.x + side * lr * 0.8, q.y + lr * 0.3, lr, lr * 0.6, side * 0.6, PL.ramp_at(ramp, rng.randf_range(0.25, 0.6)), 1.0, 0.55, 0, 0.9)
			for yy: int in range(int(q.y - lr), int(q.y + lr) + 1):
				for xx: int in range(int(q.x + side * lr * 0.8 - lr), int(q.x + side * lr * 0.8 + lr) + 1):
					moss_a[cv.idx(xx, yy)] = 1.0
	var cov: float = 0.0
	for v: float in moss_a:
		cov += v
	return cov / float(w * h)


# ---------------------------------------------------------------------------
# Topo de muro e de degrau (512x128 = 8 x 2 unidades, seamless horizontal). (r1)
# Duas faixas iguais de 1 unidade (y 0..63 e 64..127). Em cada faixa: duas fileiras de lajes de
# cobertura bege-claras, com musgo amarelo-esverdeado claro só nas bordas e nas juntas (25% a 40%).
# A borda de cima de cada faixa (y = 0 e y = 64) é a de FORA do muro (mais musgo); a de baixo
# (y = 63 e y = 127) é a de DENTRO (arena/terraço), com só um fio de musgo.
# ---------------------------------------------------------------------------

const TOP_STONE: Array = ["#8E8466", "#B4A884", "#C8BB94", "#D2C59C", "#DCCEA4", "#E0D2A8"]
const TOP_MOSS: Array = ["#87A23A", "#A8B050", "#B8BA60", "#C8C470"]


func _wall_top() -> void:
	var w: int = 512 * SS
	var h: int = 128 * SS
	var cv := PL.Canvas.new(w, h, true, false)
	var stone: Array = []
	for hx: String in TOP_STONE:
		stone.append(c(hx))
	cv.fill(stone[1])
	var rng := RandomNumberGenerator.new()
	rng.seed = 7501
	var n_face: PackedFloat32Array = PL.pfield(w, h, 16, 3, 7502, 0.8, 2, 0.55)
	var n_edge: PackedFloat32Array = PL.pfield(w, h, 48, 2, 7503, 0.6, 2, 0.5)
	var n_moss: PackedFloat32Array = PL.pfield(w, h, 12, 3, 7504, 1.0, 2, 0.5)
	var n_big: PackedFloat32Array = PL.pfield(w, h, 3, 2, 7505, 0.8, 4, 0.5)
	# lajes: [x0, y0, comprimento, largura, tom]; 2 faixas x 2 fileiras de 0,5 unidade
	var caps: Array = []
	for strip: int in 2:
		for row: int in 2:
			var x: float = rng.randf() * w
			var total: float = 0.0
			while total < w - 40.0 * SS:
				var ln: float = rng.randf_range(40.0, 84.0) * SS
				if total + ln > w - 30.0 * SS:
					ln = w - total
				caps.append([x + total, (strip * 64 + row * 32) * SS, ln, 32 * SS, rng.randf_range(-1.0, 1.0)])
				total += ln
	var bevel: float = 5.0 * SS
	for y: int in h:
		for x: int in w:
			var i: int = y * w + x
			var best: float = 1e9
			var tone: float = 0.0
			for cp: Array in caps:
				var yy: float = y + 0.5 - float(cp[1])
				if yy < -8.0 * SS or yy > float(cp[3]) + 8.0 * SS:
					continue
				var lx: float = fposmod(x + 0.5 - float(cp[0]), w)
				if lx > float(cp[2]) + 8.0 * SS and lx < w - 8.0 * SS:
					continue
				if lx > w * 0.5:
					lx -= w
				var q := Vector2(lx - float(cp[2]) * 0.5, yy - float(cp[3]) * 0.5)
				var sd: float = sd_box(q, float(cp[2]) * 0.5, float(cp[3]) * 0.5, 5.0 * SS)
				if sd < best:
					best = sd
					tone = cp[4]
			var sd2: float = best + 1.6 * SS + (n_edge[i] - 0.5) * 2.4 * SS
			if sd2 > 0.0:
				# junta rasa e clara (a crista é a moldura clara da arena)
				var jc: Color = stone[0].lerp(stone[1], 0.45)
				cv.r[i] = jc.r
				cv.g[i] = jc.g
				cv.b[i] = jc.b
				cv.z[i] = 0.0
				continue
			var depth: float = clampf(-sd2 / bevel, 0.0, 1.0)
			var f: float = n_face[i]
			var lv: float = f * 3.0
			var fl: float = floorf(lv)
			var facet: float = (fl + smoothstep(0.35, 0.65, lv - fl)) / 3.0
			# visto de cima: centro claro, chanfro um pouco mais escuro
			var t: float = 0.78 + 0.07 * tone + 0.12 * (facet - 0.5) + 0.46 * (n_big[i] - 0.5) - 0.32 * (1.0 - smoothstep(0.0, 1.0, depth))
			var col: Color = PL.ramp_at(stone, clampf(t, 0.0, 1.0))
			cv.r[i] = col.r
			cv.g[i] = col.g
			cv.b[i] = col.b
			cv.z[i] = 0.55 + 0.45 * smoothstep(0.0, 1.0, depth) + 0.05 * (facet - 0.5)
	_cracks(cv, rng, 8)
	# Musgo: borda de fora (larga), junta do meio, borda de dentro (fio) e juntas de través
	var moss: Array = []
	for hx: String in TOP_MOSS:
		moss.append(c(hx))
	var dens := PackedFloat32Array()
	dens.resize(w * h)
	for y: int in h:
		var fy: float = fposmod(float(y) / SS, 64.0) / 64.0
		for x: int in w:
			var i: int = y * w + x
			var nm: float = n_moss[i] - 0.5 + 0.5 * (n_big[i] - 0.5)
			var outer: float = 1.0 - smoothstep(0.04, 0.11, fy + 0.1 * nm)
			var mid: float = 1.0 - smoothstep(0.025, 0.06, absf(fy - 0.5) + 0.05 * nm)
			var inner: float = 1.0 - smoothstep(0.015, 0.035, 1.0 - fy + 0.03 * nm)
			var cross: float = 0.0
			if cv.z[i] < 0.3:
				cross = smoothstep(0.45, 0.6, n_moss[i])
			dens[i] = maxf(maxf(outer, mid * smoothstep(0.25, 0.5, n_moss[i] + 0.2)), maxf(inner * 0.8, cross))
	var mask := PackedByteArray()
	mask.resize(w * h)
	var leaves: Array = []
	for k: int in 30000:
		var p := Vector2(rng.randf() * w, rng.randf() * h)
		var i: int = cv.idx(int(p.x), int(p.y))
		if rng.randf() > smoothstep(0.35, 0.65, dens[i]):
			continue
		leaves.append(p)
	leaves.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.y < b.y)
	for p: Vector2 in leaves:
		var i: int = cv.idx(int(p.x), int(p.y))
		var r: float = rng.randf_range(1.8, 3.6) * SS
		var t: float = clampf(0.35 + 0.5 * n_moss[i] + rng.randf_range(-0.2, 0.2), 0.0, 1.0)
		cv.blob(p.x, p.y, r, r * 0.8, rng.randf() * PI, PL.ramp_at(moss, t * 0.85), 1.0, 0.55, 0, 1.0)
		cv.blob(p.x, p.y - r * 0.25, r * 0.55, r * 0.4, 0.0, PL.ramp_at(moss, t + 0.2), 0.6, 0.3)
		for yy: int in range(int(p.y - r * 0.8), int(p.y + r * 0.8) + 1):
			for xx: int in range(int(p.x - r * 0.8), int(p.x + r * 0.8) + 1):
				var j: int = cv.idx(xx, yy)
				if j >= 0:
					mask[j] = 1
	# algumas lâminas de grama saindo do musgo
	for k: int in 500:
		var p := Vector2(rng.randf() * w, rng.randf() * h)
		var i: int = cv.idx(int(p.x), int(p.y))
		if mask[i] == 0:
			continue
		var pts: PackedVector2Array = PL.arc_pts(p, rng.randf() * TAU, rng.randf_range(6.0, 13.0) * SS, rng.randf_range(-0.8, 0.8), 3)
		cv.stroke(pts, PL.taper(3, 1.2 * SS, 0.35 * SS), moss[0], moss[3], 0.9)
	var cov: int = 0
	for v: int in mask:
		cov += v
	var out: PL.Canvas = cv.down2()
	var img: Image = out.to_image(true)
	var mean := Vector3.ZERO
	for i: int in out.w * out.h:
		mean += Vector3(out.r[i], out.g[i], out.b[i])
	mean /= float(out.w * out.h)
	var mc := Color(mean.x, mean.y, mean.z)
	print("wall_top: musgo cobre %.0f%%, média #%s (a %.1f%% de #D2C46D)" % [100.0 * float(cov) / float(w * h), mc.to_html(false).to_upper(), PL.cdist(mc, c("#D2C46D")) * 100.0])
	PL.save_png(img, PL.TEX + "stone/wall_top.png")
	PL.save_png(PL.normal_map(out.z, out.w, out.h, 5.0, 2, true, false), PL.TEX + "stone/wall_top_n.png")


# ---------------------------------------------------------------------------
# Lajes grandes irregulares (512x512 = 8 x 8 unidades, seamless nos 2 eixos)
# Voronoi periódico (grade 6 x 6 com sorteio e algumas células unidas), bordas tortas, grama nas juntas.
# ---------------------------------------------------------------------------

const SLAB_N: int = 5


func _slabs() -> void:
	var w: int = 512 * SS
	var cs: float = float(w) / float(SLAB_N)
	var cv := PL.Canvas.new(w, w, true, true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7601
	var pts: Array = []
	var ids := PackedInt32Array()
	var tones := PackedFloat32Array()
	for j: int in SLAB_N:
		for i: int in SLAB_N:
			pts.append(Vector2((i + rng.randf_range(0.2, 0.8)) * cs, (j + rng.randf_range(0.2, 0.8)) * cs))
			ids.append(j * SLAB_N + i)
			tones.append(rng.randf_range(-1.0, 1.0))
	# une algumas células vizinhas (lajes maiores)
	for k: int in 4:
		var a: int = rng.randi_range(0, SLAB_N * SLAB_N - 1)
		var b: int = (a + 1) % (SLAB_N * SLAB_N) if rng.randf() < 0.5 else (a + SLAB_N) % (SLAB_N * SLAB_N)
		ids[b] = ids[a]
	var wx: PackedFloat32Array = PL.pfield(w, w, 5, 3, 7602, 0.5, 4, 0.5)
	var wy: PackedFloat32Array = PL.pfield(w, w, 5, 3, 7603, 0.5, 4, 0.5)
	var n_face: PackedFloat32Array = PL.pfield(w, w, 12, 3, 7604, 0.8, 2, 0.55)
	var n_edge: PackedFloat32Array = PL.pfield(w, w, 40, 2, 7605, 0.6, 2, 0.5)
	var n_moss: PackedFloat32Array = PL.pfield(w, w, 10, 3, 7606, 1.0, 2, 0.5)
	var ramp: Array = [c("#6E6044"), c("#8E7C56"), c("#A89060"), c("#BBA366"), c("#C9AF7A"), c("#D6BB8D")]
	var bevel: float = 7.0 * SS
	var edge_d := PackedFloat32Array()
	edge_d.resize(w * w)
	for y: int in w:
		for x: int in w:
			var i: int = y * w + x
			var p := Vector2(x + 0.5 + (wx[i] - 0.5) * 26.0 * SS, y + 0.5 + (wy[i] - 0.5) * 26.0 * SS)
			var ci: int = floori(p.x / cs)
			var cj: int = floori(p.y / cs)
			var best: float = 1e12
			var bp := Vector2.ZERO
			var bid: int = -1
			var cand: Array = []
			for dj: int in range(-2, 3):
				for di: int in range(-2, 3):
					var ii: int = ci + di
					var jj: int = cj + dj
					var k: int = posmod(jj, SLAB_N) * SLAB_N + posmod(ii, SLAB_N)
					var q: Vector2 = pts[k] + Vector2(floori(float(ii) / SLAB_N) * w, floori(float(jj) / SLAB_N) * w)
					cand.append([q, ids[k]])
					var d2: float = p.distance_squared_to(q)
					if d2 < best:
						best = d2
						bp = q
						bid = ids[k]
			var ed: float = 1e9
			for cd: Array in cand:
				if int(cd[1]) == bid:
					continue
				var q: Vector2 = cd[0]
				var nrm: Vector2 = (q - bp).normalized()
				ed = minf(ed, (p - (bp + q) * 0.5).dot(nrm) * -1.0)
			ed = absf(ed)
			var sd: float = -ed + 3.0 * SS + (n_edge[i] - 0.5) * 4.0 * SS
			edge_d[i] = sd
			if sd > 0.0:
				var jc: Color = c("#3F5F22").lerp(c("#5E8424"), n_moss[i])
				cv.r[i] = jc.r
				cv.g[i] = jc.g
				cv.b[i] = jc.b
				cv.z[i] = 0.1
				continue
			var depth: float = clampf(-sd / bevel, 0.0, 1.0)
			var f: float = n_face[i]
			var lv: float = f * 3.0
			var fl: float = floorf(lv)
			var facet: float = (fl + smoothstep(0.35, 0.65, lv - fl)) / 3.0
			var tone: float = tones[bid % tones.size()]
			var t: float = 0.66 + 0.08 * tone + 0.18 * (facet - 0.5) - 0.34 * (1.0 - smoothstep(0.0, 1.0, depth))
			var col: Color = PL.ramp_at(ramp, clampf(t, 0.0, 1.0))
			cv.r[i] = col.r
			cv.g[i] = col.g
			cv.b[i] = col.b
			cv.z[i] = 0.5 + 0.5 * smoothstep(0.0, 1.0, depth) + 0.06 * (facet - 0.5)
	_cracks_slab(cv, rng, ramp)
	# Grama e musgo nas juntas, transbordando um pouco para a laje
	var mramp: Array = [c("#3F5F22"), c("#5E8424"), c("#87A23A"), c("#A8C447")]
	for k: int in 9000:
		var p := Vector2(rng.randf() * w, rng.randf() * w)
		var i: int = cv.idx(int(p.x), int(p.y))
		if edge_d[i] < -2.0 * SS:
			continue
		var t: float = clampf(0.2 + 0.6 * n_moss[i] + rng.randf_range(-0.2, 0.2), 0.0, 1.0)
		if rng.randf() < 0.55:
			var r: float = rng.randf_range(2.0, 3.8) * SS
			cv.blob(p.x, p.y, r, r * 0.8, rng.randf() * PI, PL.ramp_at(mramp, t * 0.7), 1.0, 0.55, 0, 0.45)
			cv.blob(p.x, p.y - r * 0.25, r * 0.55, r * 0.4, 0.0, PL.ramp_at(mramp, t * 0.7 + 0.2), 0.6, 0.3)
		else:
			var pts2: PackedVector2Array = PL.arc_pts(p, rng.randf() * TAU, rng.randf_range(7.0, 15.0) * SS, rng.randf_range(-0.8, 0.8), 3)
			cv.stroke(pts2, PL.taper(3, 1.3 * SS, 0.4 * SS), PL.ramp_at(mramp, t * 0.5), PL.ramp_at(mramp, t * 0.5 + 0.45), 0.9)
	var out: PL.Canvas = cv.down2()
	var alb: Image = out.to_image(true)
	var nrm: Image = PL.normal_map(out.z, out.w, out.h, 5.0, 2, true, true)
	# corte da repetição numa coluna/linha sem junta (a textura repetida é a mesma)
	var rx: int = PL.best_roll(alb, true)
	var ry: int = PL.best_roll(alb, false)
	PL.save_png(PL.roll(alb, rx, ry), PL.TEX + "stone/slabs.png")
	PL.save_png(PL.roll(nrm, rx, ry), PL.TEX + "stone/slabs_n.png")


func _cracks_slab(cv: PL.Canvas, rng: RandomNumberGenerator, ramp: Array) -> void:
	for k: int in 12:
		var p := Vector2(rng.randf() * cv.w, rng.randf() * cv.h)
		var i: int = cv.idx(int(p.x), int(p.y))
		if cv.z[i] < 0.95:
			continue
		var pts: PackedVector2Array = PL.arc_pts(p, rng.randf() * TAU, rng.randf_range(18.0, 40.0) * SS, rng.randf_range(-1.4, 1.4), 5)
		cv.stroke(pts, PL.taper(5, 1.3, 0.5), ramp[1], ramp[2], 0.8)
	# Manchas gastas (mais claras) e de líquen
	for k: int in 40:
		var p := Vector2(rng.randf() * cv.w, rng.randf() * cv.h)
		var i: int = cv.idx(int(p.x), int(p.y))
		if cv.z[i] < 0.95:
			continue
		var r: float = rng.randf_range(6.0, 16.0) * SS
		var col: Color = ramp[5] if k % 3 != 0 else c("#9AA05A")
		cv.blob(p.x, p.y, r * 1.4, r, rng.randf() * PI, col, 0.22, 0.2, 1)
