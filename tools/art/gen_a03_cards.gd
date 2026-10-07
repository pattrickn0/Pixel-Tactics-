extends RefCounted
## Cartões com alfa binário da A03 (folhagem, conífera, franjas, capim, flores, cogumelos).
## Sem class_name: usar via preload. Luz pintada só de cima, sem contorno, sem sombra no chão.

const P = preload("res://tools/art/palette_a03.gd")
const Canvas = preload("res://tools/art/a03_canvas.gd")

## [nome, largura, altura]
const ORDER: Array = [
	["leaf_0", 32, 32], ["leaf_1", 32, 32], ["leaf_2", 32, 32], ["leaf_3", 32, 32],
	["leaf_olive_0", 32, 32], ["leaf_olive_1", 32, 32],
	["leaf_cool_0", 32, 32], ["leaf_cool_1", 32, 32], ["leaf_flower_0", 32, 32],
	["conifer_tier_0", 32, 32], ["conifer_tier_1", 32, 32],
	["moss_fringe_0", 32, 16], ["moss_fringe_1", 32, 16],
	["grass_fringe_0", 32, 16], ["grass_fringe_1", 32, 16],
	["grass_tuft_0", 16, 16], ["grass_tuft_1", 16, 16], ["grass_tuft_2", 16, 16],
	["tall_grass_0", 16, 32], ["tall_grass_1", 16, 32],
	["flower_0", 16, 16], ["flower_1", 16, 16], ["flower_2", 16, 16], ["flower_3", 16, 16],
	["mushroom_0", 16, 16], ["mushroom_1", 16, 16], ["mushroom_2", 16, 16], ["mushroom_3", 16, 16],
]

# Tons usados por rampa de folhagem: [fenda, base, baixo, meio, alto, luz, topo]
const LEAF_SLOTS: Dictionary = {
	"leaf_green": [1, 2, 3, 4, 5, 6, 7],
	"leaf_olive": [1, 2, 3, 4, 4, 5, 6],
	"leaf_cool": [1, 2, 3, 4, 4, 5, 6],
}


static func rng_for(key: String) -> RandomNumberGenerator:
	var r: RandomNumberGenerator = RandomNumberGenerator.new()
	r.seed = key.hash() ^ 0xCA03
	return r


static func build_all() -> Dictionary:
	var out: Dictionary = {}
	for i: int in 4:
		out["leaf_%d" % i] = _leaf_card(rng_for("leaf_%d" % i), "leaf_green", i, false)
	for i: int in 2:
		out["leaf_olive_%d" % i] = _leaf_card(rng_for("leaf_olive_%d" % i), "leaf_olive", i, false)
		out["leaf_cool_%d" % i] = _leaf_card(rng_for("leaf_cool_%d" % i), "leaf_cool", i, false)
	out["leaf_flower_0"] = _leaf_card(rng_for("leaf_cool_0"), "leaf_cool", 0, true)
	var tiers: Array = _conifer_tiers(rng_for("conifer_tier"))
	out["conifer_tier_0"] = tiers[0]
	out["conifer_tier_1"] = tiers[1]
	var mf: Array = _fringes(rng_for("moss_fringe"), "moss")
	out["moss_fringe_0"] = mf[0]
	out["moss_fringe_1"] = mf[1]
	var gf: Array = _fringes(rng_for("grass_fringe"), "grass")
	out["grass_fringe_0"] = gf[0]
	out["grass_fringe_1"] = gf[1]
	out["grass_tuft_0"] = _tuft(rng_for("grass_tuft_0"), "grass_arena", 16, Vector2i(5, 6), Vector2i(7, 11))
	out["grass_tuft_1"] = _tuft(rng_for("grass_tuft_1"), "grass_arena", 16, Vector2i(6, 7), Vector2i(6, 9))
	out["grass_tuft_2"] = _tuft(rng_for("grass_tuft_2"), "grass_forest", 16, Vector2i(5, 7), Vector2i(8, 12))
	out["tall_grass_0"] = _tuft(rng_for("tall_grass_0"), "grass_forest", 32, Vector2i(8, 9), Vector2i(16, 29))
	out["tall_grass_1"] = _tuft(rng_for("tall_grass_1"), "grass_forest", 32, Vector2i(7, 8), Vector2i(14, 25))
	out["flower_0"] = _flower(rng_for("flower_0"), "flower_pink", 3)
	out["flower_1"] = _flower(rng_for("flower_1"), "flower_white", 2)
	out["flower_2"] = _flower(rng_for("flower_2"), "flower_yellow", 3)
	out["flower_3"] = _flower(rng_for("flower_3"), "flower_blue", 2)
	out["mushroom_0"] = _mushrooms(rng_for("mushroom_0"), "mush_pink", 0)
	out["mushroom_1"] = _mushrooms(rng_for("mushroom_1"), "mush_blue", 1)
	out["mushroom_2"] = _mushrooms(rng_for("mushroom_2"), "mush_purple", 2)
	out["mushroom_3"] = _mushrooms(rng_for("mushroom_3"), "mush_orange", 3)
	return out


# ---------------------------------------------------------------------------
# Folhagem: aglomerado de "bolinhos" de folhas
# ---------------------------------------------------------------------------

static func _layout(rng: RandomNumberGenerator, variant: int) -> Array:
	# Vector3(cx, cy, r)
	var b: Array = []
	match variant:
		0: # redondo
			b.append(Vector3(16, 9.5, 6.0))
			b.append(Vector3(9.5, 14, 5.6))
			b.append(Vector3(22.5, 14.5, 5.8))
			b.append(Vector3(12.5, 20.5, 6.0))
			b.append(Vector3(20.5, 21, 5.6))
		1: # largo
			b.append(Vector3(11.5, 11, 5.8))
			b.append(Vector3(21, 10.5, 6.0))
			b.append(Vector3(6, 17, 5.2))
			b.append(Vector3(16, 18, 6.4))
			b.append(Vector3(26, 17.5, 5.0))
			b.append(Vector3(10.5, 22, 4.4))
			b.append(Vector3(21.5, 22, 4.4))
		2: # pendente
			b.append(Vector3(16, 8.5, 6.2))
			b.append(Vector3(9, 15, 5.2))
			b.append(Vector3(23, 15, 5.2))
			b.append(Vector3(8, 22.5, 4.2))
			b.append(Vector3(24, 22, 4.4))
			b.append(Vector3(16, 21, 4.8))
		3: # ralo (buracos entre os bolinhos)
			b.append(Vector3(15, 8.5, 5.4))
			b.append(Vector3(7.5, 15.5, 4.6))
			b.append(Vector3(23.5, 13.5, 5.2))
			b.append(Vector3(11.5, 23, 5.0))
			b.append(Vector3(22, 23.5, 4.8))
	var out: Array = []
	for v: Vector3 in b:
		# afasta um pouco do centro e engorda (cobertura de 45% a 80%)
		var c: Vector2 = Vector2(16, 16) + (Vector2(v.x, v.y) - Vector2(16, 16)) * 1.08
		out.append(Vector3(c.x + rng.randf_range(-0.7, 0.7), c.y + rng.randf_range(-0.6, 0.6), v.z * 1.12 + rng.randf_range(-0.3, 0.3)))
	# de trás (em cima) para a frente (embaixo)
	out.sort_custom(func(p: Vector3, q: Vector3) -> bool: return p.y < q.y)
	return out


static func _leaf_card(rng: RandomNumberGenerator, ramp: String, variant: int, flowers: bool) -> RefCounted:
	var slots: Array = LEAF_SLOTS[ramp]
	var col: Array[int] = []
	for s: int in slots:
		col.append(P.c(ramp, s))
	var CREV: int = col[0]
	var cv: RefCounted = Canvas.new(32, 32, false, false)
	var blobs: Array = _layout(rng, variant)
	# dono de cada pixel: o bolinho mais da frente que o contém (borda com leve ruído de folha)
	var owner: PackedInt32Array = PackedInt32Array()
	owner.resize(32 * 32)
	owner.fill(-1)
	# topo de cada bolinho por coluna (primeira linha dentro do círculo, mesmo se coberta)
	var top: PackedInt32Array = PackedInt32Array()
	top.resize(blobs.size() * 32)
	top.fill(99)
	var bumps: Array = []
	for k: int in blobs.size():
		var arr: PackedFloat32Array = PackedFloat32Array()
		for a: int in 16:
			arr.append(rng.randf_range(-0.7, 0.7))
		bumps.append(arr)
	for y: int in range(1, 31):
		for x: int in range(1, 31):
			for k: int in blobs.size():
				var bl: Vector3 = blobs[k]
				var dx: float = x + 0.5 - bl.x
				var dy: float = y + 0.5 - bl.y
				var ang: float = atan2(dy, dx)
				var ai: int = posmod(roundi(ang / TAU * 16.0), 16)
				var r: float = bl.z + (bumps[k] as PackedFloat32Array)[ai]
				if dx * dx + dy * dy <= r * r:
					owner[y * 32 + x] = k
					if top[k * 32 + x] == 99:
						top[k * 32 + x] = y
	# células de folha (Voronoi pequeno) para os tons formarem tufos, não faixas retas
	var leaf_pts: Array[Vector2] = []
	for gy: int in range(0, 11):
		for gx: int in range(0, 11):
			leaf_pts.append(Vector2(gx * 3.0 + 1.5 + rng.randf_range(-1.0, 1.0), gy * 3.0 + 1.5 + rng.randf_range(-1.0, 1.0)))
	var cell_jit: PackedInt32Array = PackedInt32Array()
	for i: int in leaf_pts.size():
		cell_jit.append(rng.randi_range(-1, 1))
	var tone_map: PackedInt32Array = PackedInt32Array()
	tone_map.resize(32 * 32)
	tone_map.fill(-1)
	for y: int in 32:
		for x: int in 32:
			var k: int = owner[y * 32 + x]
			if k < 0:
				continue
			var bl: Vector3 = blobs[k]
			# folha mais perto
			var bi: int = 0
			var bd: float = 1e9
			for i: int in leaf_pts.size():
				var d: float = leaf_pts[i].distance_squared_to(Vector2(x + 0.5, y + 0.5))
				if d < bd:
					bd = d
					bi = i
			var best: Vector2 = leaf_pts[bi]
			var ty: int = top[k * 32 + x]
			# up: 1 no alto do bolinho, 0 na altura do centro (lados)
			var up: float = (bl.y - (ty + 0.5)) / bl.z
			var cap: int = 0
			if up > 0.55:
				cap = 1
			if up > 0.78:
				cap = 2
			if up > 0.92:
				cap = 3
			if cap > 0:
				cap = clampi(cap + cell_jit[bi], 1, 3)
			var dd: int = y - ty
			var tone: int
			if dd < cap:
				# calota de luz: 1 a 3 linhas só no topo do bolinho
				if dd == 0:
					tone = 6 if (bl.y - bl.z < 16.0 and up > 0.86) else (5 if up > 0.7 else 4)
				elif dd == 1 and up > 0.93:
					tone = 5
				else:
					tone = 4
			else:
				var v: float = (best.y - bl.y) / bl.z
				if v < -0.05:
					tone = 3
				elif v < 0.45:
					tone = 2
				else:
					tone = 1
				# fundo de cada folha um tom abaixo (dá forma à folha)
				if y + 0.5 > best.y + 0.9 and tone > 1:
					tone -= 1
			tone_map[y * 32 + x] = tone
	# marcas de folha de 2 a 3 px um tom abaixo, quebrando a calota de cada bolinho
	for k: int in blobs.size():
		var bl: Vector3 = blobs[k]
		var n_marks: int = 2 if bl.z > 6.0 else 1
		var done: int = 0
		for t: int in 40:
			if done >= n_marks:
				break
			var x: int = roundi(bl.x + rng.randf_range(-bl.z * 0.6, bl.z * 0.6))
			if x < 1 or x > 29:
				continue
			var ty: int = top[k * 32 + x]
			if ty > 30 or owner[ty * 32 + x] != k or tone_map[ty * 32 + x] < 4:
				continue
			var pts: Array[Vector2i] = [Vector2i(x, ty + 1), Vector2i(x + 1, ty + 1)]
			if rng.randf() < 0.5:
				pts.append(Vector2i(x + 2, ty + 2))
			else:
				pts = [Vector2i(x, ty), Vector2i(x + 1, ty + 1)]
				if rng.randf() < 0.5:
					pts.append(Vector2i(x + 1, ty + 2))
			for p: Vector2i in pts:
				var o: int = p.y * 32 + p.x
				if p.x <= 30 and p.y <= 30 and owner[o] == k and tone_map[o] > 1:
					tone_map[o] -= 1
			done += 1
	for y: int in 32:
		for x: int in 32:
			var tn: int = tone_map[y * 32 + x]
			if tn >= 0:
				cv.put(x, y, col[tn], 0.0)
	# fenda: pixel do bolinho de trás logo acima do topo de um bolinho da frente
	for y: int in range(1, 31):
		for x: int in range(1, 31):
			var k: int = owner[y * 32 + x]
			var kb: int = owner[(y + 1) * 32 + x]
			if k >= 0 and kb > k:
				var front: Vector3 = blobs[kb]
				if front.y > (blobs[k] as Vector3).y + 1.0 and y + 1 < front.y and absf(x + 0.5 - front.x) < front.z * 0.55:
					cv.put(x, y, CREV, 0.0)
	# buracos no ralo
	if variant == 3:
		var holes: Array[Vector2i] = [Vector2i(15, 16), Vector2i(17, 17), Vector2i(8, 20)]
		for hp: Vector2i in holes:
			for p: Vector2i in [hp, hp + Vector2i(1, 0), hp + Vector2i(0, 1), hp + Vector2i(1, 1)]:
				cv.put(p.x, p.y, -1, 0.0)
	# pontas de folha na silhueta: para cima no topo, para o lado nos lados, para baixo na base
	var tips: Array = []
	for y: int in range(2, 30):
		for x: int in range(2, 30):
			var c: int = cv.get_c(x, y)
			if c < 0:
				continue
			var up_open: bool = cv.get_c(x, y - 1) < 0 and cv.get_c(x - 1, y - 1) < 0 and cv.get_c(x + 1, y - 1) < 0
			var down_open: bool = cv.get_c(x, y + 1) < 0 and cv.get_c(x - 1, y + 1) < 0 and cv.get_c(x + 1, y + 1) < 0
			var left_open: bool = cv.get_c(x - 1, y) < 0 and cv.get_c(x - 1, y - 1) < 0 and cv.get_c(x - 1, y + 1) < 0
			var right_open: bool = cv.get_c(x + 1, y) < 0 and cv.get_c(x + 1, y - 1) < 0 and cv.get_c(x + 1, y + 1) < 0
			if up_open and rng.randf() < 0.3:
				# a ponta de cima não acende mais que o tom "alto"
				var tc: int = c if P.tone_of(c) <= P.tone_of(col[4]) else col[4]
				tips.append([Vector2i(x, y - 1), tc])
			elif down_open and rng.randf() < 0.16:
				tips.append([Vector2i(x, y + 1), col[1]])
				if rng.randf() < 0.15:
					tips.append([Vector2i(x, y + 2), col[1]])
			elif left_open and not up_open and rng.randf() < 0.22:
				tips.append([Vector2i(x - 1, y), c if P.tone_of(c) <= P.tone_of(col[3]) else col[3]])
			elif right_open and not up_open and rng.randf() < 0.22:
				tips.append([Vector2i(x + 1, y), c if P.tone_of(c) <= P.tone_of(col[3]) else col[3]])
	for t: Array in tips:
		var p: Vector2i = t[0]
		if p.x >= 1 and p.y >= 1 and p.x <= 30 and p.y <= 30:
			cv.put(p.x, p.y, t[1], 0.0)
	# flores (variante florida): 3x3 ou 2x2, rosa e brancas, só sobre a folhagem
	if flowers:
		var fl: Array = [
			[[Vector2i(1, 0), "T"], [Vector2i(0, 1), "P"], [Vector2i(1, 1), "P"], [Vector2i(2, 1), "P"], [Vector2i(1, 2), "P"]],
			[[Vector2i(0, 0), "T"], [Vector2i(1, 0), "T"], [Vector2i(0, 1), "P"], [Vector2i(1, 1), "P"]],
		]
		var spots: Array[Vector2i] = [Vector2i(8, 10), Vector2i(19, 6), Vector2i(24, 16), Vector2i(13, 19), Vector2i(19, 23)]
		for i: int in spots.size():
			var pink: bool = i % 2 == 0
			var shape: Array = fl[i % 2]
			var o: Vector2i = spots[i] + Vector2i(rng.randi_range(-1, 1), rng.randi_range(-1, 1))
			var inside: bool = true
			for it: Array in shape:
				var p: Vector2i = o + (it[0] as Vector2i)
				if cv.get_c(p.x, p.y) < 0:
					inside = false
			if not inside:
				continue
			for it: Array in shape:
				var p: Vector2i = o + (it[0] as Vector2i)
				var c: int
				if pink:
					c = P.hx("#F8B8C8") if it[1] == "T" else P.hx("#E8829C")
				else:
					c = P.hx("#FFFDF6") if it[1] == "T" else P.hx("#F4F0E4")
				cv.put(p.x, p.y, c, 0.0)
	_drop_lonely(cv)
	return cv


## Remove pixel opaco sem vizinho opaco (alfa solto) e fecha furo de 1 px.
static func _drop_lonely(cv: RefCounted) -> void:
	for y: int in cv.h:
		for x: int in cv.w:
			var n: int = 0
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if cv.get_c(x + d.x, y + d.y) >= 0:
					n += 1
			if cv.get_c(x, y) >= 0 and n == 0:
				cv.put(x, y, -1, 0.0)


# ---------------------------------------------------------------------------
# Conífera: camada de galhos com pontas serrilhadas
# ---------------------------------------------------------------------------

## Galho caindo (pena): topo em (x0, y0), ponta em (x0 + lean, y0 + length), largura máxima wd.
## Agulhas em traços diagonais descendo para fora; luz só na aresta de cima.
static func _frond(cv: RefCounted, x0: float, y0: float, length: float, lean: float, wd: float, shade: int) -> void:
	var pix: Dictionary = {}
	for y: int in range(floori(y0), ceili(y0 + length) + 1):
		var t: float = (y + 0.5 - y0) / length
		if t < 0.0 or t > 1.0:
			continue
		var xc: float = x0 + lean * t * t
		var hw: float = wd * 0.5 * (1.0 - t) * minf(1.0, 0.6 + t * 3.0)
		for x: int in range(floori(xc - hw - 1), ceili(xc + hw + 1) + 1):
			var sx: float = x + 0.5 - xc
			# serrilhado de agulha na borda: alterna por linha e por lado
			var e: float = hw - (0.7 if posmod(y + (1 if sx > 0.0 else 0), 2) == 1 else 0.0)
			if absf(sx) <= maxf(e, 0.45):
				pix[Vector2i(x, y)] = Vector2(t, sx)
	for p: Vector2i in pix:
		var tv: Vector2 = pix[p]
		var t: float = tv.x
		var tone: int = 6 if t < 0.2 else (5 if t < 0.48 else (4 if t < 0.76 else 3))
		var top_open: bool = not pix.has(p + Vector2i(0, -1))
		if top_open:
			tone = 7 if t < 0.4 else 6
		elif posmod(p.y - floori(absf(tv.y) * 0.9), 3) == 0:
			tone -= 1
		tone = clampi(tone - shade, 2, 7)
		cv.put(p.x, p.y, P.c("conifer", tone), 0.0)


## Galho em arco: coroa em (cx, cy), meia-largura span, pontas caindo 'droop' px, espessura no meio 'thick'.
## Luz só na aresta de cima; traços de agulha paralelos ao arco; pontas finas pendentes.
static func _branch(cv: RefCounted, cx: float, cy: float, span: float, droop: float, thick: float, shade: int) -> void:
	var pix: Dictionary = {}
	for x: int in range(floori(cx - span) - 1, ceili(cx + span) + 2):
		var u: float = (x + 0.5 - cx) / span
		if absf(u) > 1.0:
			continue
		var c: float = cy + droop * u * u
		var t: float = thick * pow(1.0 - u * u, 0.6) + 1.0
		# pontas: a parte de baixo se alonga e afina (agulhas pendentes)
		var y0: float = c - 0.3 * t
		var y1: float = c + 0.7 * t + 2.5 * pow(absf(u), 3.0)
		# serrilhado de agulhas na borda de baixo (dentes de 1 a 3 px, alternados)
		var h: int = posmod(x * 7 + int(cx * 13.0) + int(cy * 5.0), 5)
		y1 += [0.0, 2.0, 0.5, 3.0, 1.0][h] * (0.4 + 0.6 * absf(u))
		for y: int in range(floori(y0), ceili(y1) + 1):
			if y + 0.5 >= y0 and y + 0.5 <= y1:
				pix[Vector2i(x, y)] = Vector2(u, (y + 0.5 - y0) / maxf(y1 - y0, 1.0))
	for p: Vector2i in pix:
		var uv: Vector2 = pix[p]
		var tone: int
		if not pix.has(p + Vector2i(0, -1)):
			tone = 7 if absf(uv.x) < 0.45 else 6
		elif not pix.has(p + Vector2i(0, -2)):
			tone = 6 if absf(uv.x) < 0.6 else 5
		elif uv.y < 0.45:
			tone = 5
		elif uv.y < 0.75:
			tone = 4
		else:
			tone = 3
		# traço de agulha: linha mais escura paralela ao arco
		if tone <= 5 and posmod(p.y - floori(uv.x * uv.x * 6.0), 3) == 0:
			tone -= 1
		tone = clampi(tone - shade, 2, 7)
		cv.put(p.x, p.y, P.c("conifer", tone), 0.0)


static func _conifer_tiers(rng: RandomNumberGenerator) -> Array:
	# galhos em arco em posições soltas (sem grade), de trás para a frente.
	# Os que encostam nas colunas 30 a 1 são compartilhados pelas duas variantes.
	var shared: Array = []
	for row: Array in [[0.0, 1.0, 2], [16.0, 6.0, 1], [0.0, 11.5, 0]]:
		shared.append([float(row[0]) + rng.randf_range(-0.6, 0.6), float(row[1]) + rng.randf_range(-0.8, 0.8),
				rng.randf_range(6.5, 7.5), rng.randf_range(6.0, 9.0), rng.randf_range(5.0, 6.0), row[2]])
	shared.append([16.0 + rng.randf_range(-1.0, 1.0), rng.randf_range(0.0, 2.0), 7.0, 6.0, 5.0, 2])
	var out: Array = []
	for v: int in 2:
		var r2: RandomNumberGenerator = RandomNumberGenerator.new()
		r2.seed = rng.seed + 101 * (v + 1)
		var cv: RefCounted = null
		for attempt: int in 60:
			var arcs: Array = shared.duplicate()
			# galhos próprios da variante: miolo (colunas 2 a 29)
			for k: int in 5:
				var span: float = r2.randf_range(5.0, 7.0)
				var cx: float = r2.randf_range(3.0 + span, 28.0 - span)
				var cy: float = r2.randf_range(3.0, 12.0)
				var shade: int = 0 if cy > 9.0 else (1 if cy > 5.0 else 2)
				arcs.append([cx, cy, span, r2.randf_range(5.0, 10.0), r2.randf_range(4.5, 6.0), shade])
			arcs.sort_custom(func(a: Array, b: Array) -> bool: return float(a[1]) < float(b[1]))
			cv = Canvas.new(32, 32, true, false)
			for y: int in 16:
				for x: int in 32:
					cv.put(x, y, P.c("conifer", 1 if y < 8 else 2), 0.0)
			for a: Array in arcs:
				_branch(cv, a[0], a[1], a[2], a[3], a[4], a[5])
			# 4 a 7 dentes na linha 20 e linha 31 quase vazia
			var runs: int = 0
			for x: int in 32:
				if cv.get_c(x, 20) >= 0 and cv.get_c(x - 1, 20) < 0:
					runs += 1
			var low: int = 0
			for x: int in 32:
				if cv.get_c(x, 31) >= 0:
					low += 1
			if runs >= 4 and runs <= 7 and low <= 6:
				break
		out.append(cv)
	return out


# ---------------------------------------------------------------------------
# Franjas (musgo e grama caindo pela borda) 32x16
# ---------------------------------------------------------------------------

static func _fringes(rng: RandomNumberGenerator, kind: String) -> Array:
	var c_top: int
	var c_body: int
	var c_low: int
	var c_shadow: int
	if kind == "moss":
		c_top = P.hx("#8FAE48")
		c_body = P.hx("#789636")
		c_low = P.hx("#5E7C26")
		c_shadow = P.hx("#496819")
	else:
		c_top = P.hx("#6A9E4A")
		c_body = P.hx("#539342")
		c_low = P.hx("#539342")
		c_shadow = P.hx("#3D853C")
	var out: Array = []
	for v: int in 2:
		var r2: RandomNumberGenerator = RandomNumberGenerator.new()
		r2.seed = rng.seed + 37 * (v + 1)
		var cv: RefCounted = Canvas.new(32, 16, true, false)
		for x: int in 32:
			cv.put(x, 0, c_top, 0.0)
			cv.put(x, 1, c_body, 0.0)
			cv.put(x, 2, c_body if (x + v) % 5 != 0 else c_shadow, 0.0)
		# x das peças: uma na emenda (compartilhada) e 4 a 5 no miolo
		var pieces: Array = [[0, 3.0, 0]]
		var xs: Array = [5, 10, 16, 21, 26] if v == 0 else [6, 12, 17, 23]
		for x0: int in xs:
			pieces.append([x0 + r2.randi_range(-1, 1), r2.randf_range(2.0, 3.4), r2.randi_range(0, 2)])
		for pc: Array in pieces:
			var px: int = pc[0]
			var hw: float = pc[1]
			var r3: RandomNumberGenerator = r2
			if px == 0:
				r3 = RandomNumberGenerator.new()
				r3.seed = rng.seed + 999
			_fringe_piece(cv, r3, px, hw, kind, c_top, c_body, c_low, c_shadow)
		# emenda: a coluna 31 repete a 0 (a peça da emenda fica simétrica)
		for y: int in 16:
			cv.put(31, y, cv.get_c(0, y), 0.0)
		out.append(cv)
	var a: RefCounted = out[0]
	var b: RefCounted = out[1]
	for y: int in 16:
		for x: int in [0, 1, 30, 31]:
			b.put(x, y, a.get_c(x, y), 0.0)
	return out


static func _fringe_piece(cv: RefCounted, rng: RandomNumberGenerator, px: int, hw: float, kind: String,
		c_top: int, c_body: int, c_low: int, c_shadow: int) -> void:
	if kind == "moss":
		# tufo arredondado pendurado (linhas 3 a 6) + fios
		var depth: int = rng.randi_range(2, 4)
		for y: int in range(3, 3 + depth):
			var t: float = float(y - 2) / float(depth + 1)
			var half: float = hw * sqrt(maxf(0.0, 1.0 - t * t))
			for x: int in range(px - ceili(half), px + ceili(half) + 1):
				if absf(x - px) <= half:
					cv.put(x, y, c_body if y < 2 + depth else c_low, 0.0)
		var n_strands: int = rng.randi_range(1, 2)
		for s: int in n_strands:
			var sx: int = px + rng.randi_range(-1, 1) * (s + 1)
			var length: int = rng.randi_range(2, 7)
			var y0: int = 2 + depth
			for t: int in length:
				var yy: int = y0 + t
				if yy > 14:
					break
				cv.put(sx, yy, c_low if t < length - 1 else c_shadow, 0.0)
	else:
		# lâminas de grama caindo pela quina, inclinadas
		var n_bl: int = rng.randi_range(2, 3)
		for s: int in n_bl:
			var sx: int = px + rng.randi_range(-2, 2)
			var length: int = rng.randi_range(3, 9)
			var drift: int = 1 if rng.randf() < 0.5 else -1
			var x: int = sx
			for t: int in length:
				var yy: int = 3 + t
				if yy > 14:
					break
				cv.put(x, yy, c_body if t < length - 2 else c_top, 0.0)
				if t % 3 == 2:
					x += drift
		# sombra embaixo da quina, só perto da peça
		cv.put(px, 3, c_shadow, 0.0)
		cv.put(px + 1, 3, c_body, 0.0)


# ---------------------------------------------------------------------------
# Capim, capim alto, flores e cogumelos (16x16 e 16x32)
# ---------------------------------------------------------------------------

## Lâmina curva de (bx, by) até (tx, ty): pontos conectados.
static func _blade_pts(bx: float, by: float, tx: float, ty: float, bend: float) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var steps: int = 48
	var last: Vector2i = Vector2i(-99, -99)
	for i: int in steps + 1:
		var t: float = float(i) / steps
		# curva: desloca o meio para fora
		var x: float = lerpf(bx, tx, t * t * 0.6 + t * 0.4) + bend * sin(PI * t) * 0.0
		var y: float = lerpf(by, ty, t)
		var p: Vector2i = Vector2i(floori(x), floori(y))
		if p != last:
			out.append(p)
			last = p
	return out


static func _tuft(rng: RandomNumberGenerator, ramp: String, height: int, n_blades: Vector2i, hrange: Vector2i) -> RefCounted:
	var base_c: int = P.c(ramp, 1)
	var body: int = P.c(ramp, 2)
	var tip: int = P.c(ramp, 3)
	var cv: RefCounted = Canvas.new(16, height, false, false)
	var n: int = rng.randi_range(n_blades.x, n_blades.y)
	var bottom: int = height - 1
	# leque: lâminas do meio mais altas, as de fora abrem e curvam
	for i: int in n:
		var a: float = lerpf(-1.0, 1.0, (i + 0.5) / n) + rng.randf_range(-0.12, 0.12)
		var bh: int = clampi(roundi(lerpf(float(hrange.y), float(hrange.x), absf(a)) + rng.randf_range(-1.5, 1.5)), hrange.x, hrange.y)
		var bx: float = 7.5 + a * 1.2
		var tx: float = clampf(7.5 + a * (1.0 + bh * 0.55), 1.5, 14.4)
		var top_y: int = bottom - bh + 1
		var last: Vector2i = Vector2i(-99, -99)
		for k: int in bh * 3 + 1:
			var t: float = float(k) / float(bh * 3)
			var x: float = bx + (tx - bx) * pow(t, 1.15)
			var y: float = float(bottom) + 0.5 - t * (bh - 0.01)
			var p: Vector2i = Vector2i(floori(x), floori(y))
			if p == last or p.y < 1 or p.x < 1 or p.x > 14:
				continue
			last = p
			var from_top: int = p.y - top_y
			var c: int = body
			if from_top <= (2 if height == 32 else 1):
				c = tip
			elif p.y >= bottom - 1:
				c = base_c
			if cv.get_c(p.x, p.y) == tip and c != tip:
				continue
			cv.put(p.x, p.y, c, 0.0)
	_drop_lonely(cv)
	return cv


static func _flower(rng: RandomNumberGenerator, ramp: String, n: int) -> RefCounted:
	var cv: RefCounted = Canvas.new(16, 16, false, false)
	var stem: int = P.hx("#73A949")
	var leaf_dark: int = P.hx("#5B9C47")
	var nr: int = 3 if ramp != "flower_blue" else 2
	var petal_dark: int = P.c(ramp, 0)
	var petal: int = P.c(ramp, 1)
	var petal_light: int = P.c(ramp, nr - 1)
	var center: int = P.hx("#F2D04A") if ramp != "flower_yellow" else P.hx("#D8A830")
	if ramp == "flower_white":
		petal_dark = P.hx("#D8D4C4")
	# hastes saindo da base, cabeças em alturas diferentes
	var heads: Array[Vector2i] = []
	var configs: Array = [[Vector2i(7, 5), 7], [Vector2i(3, 8), 7], [Vector2i(12, 7), 8]] if n == 3 else [[Vector2i(5, 5), 7], [Vector2i(11, 7), 8]]
	for k: int in n:
		var cfg: Array = configs[k]
		var head: Vector2i = cfg[0] + Vector2i(rng.randi_range(-1, 1), rng.randi_range(0, 1))
		heads.append(head)
		var bx: int = int(cfg[1])
		var pts: Array[Vector2i] = Canvas.line_pts(bx, 15, head.x, head.y + 2)
		for p: Vector2i in pts:
			cv.put(p.x, p.y, stem, 0.0)
	# 1 ou 2 folhas na base
	var leaves: Array = [[Vector2i(6, 13), Vector2i(4, 12)], [Vector2i(9, 12), Vector2i(11, 11)]]
	var nl: int = rng.randi_range(1, 2)
	for k: int in nl:
		var lf: Array = leaves[k]
		var a: Vector2i = lf[0]
		var b: Vector2i = lf[1]
		cv.put(a.x, a.y, leaf_dark, 0.0)
		cv.put((a.x + b.x) / 2, (a.y + b.y) / 2 + 0, stem, 0.0)
		cv.put(b.x, b.y, stem, 0.0)
	# cabeças: cruz 3x3 (pétala de cima mais clara, de baixo mais escura, miolo amarelo)
	for h: Vector2i in heads:
		cv.put(h.x, h.y - 1, petal_light, 0.0)
		cv.put(h.x - 1, h.y, petal, 0.0)
		cv.put(h.x + 1, h.y, petal, 0.0)
		cv.put(h.x, h.y + 1, petal_dark, 0.0)
		cv.put(h.x, h.y, center, 0.0)
		# cantos de cima arredondando a flor maior
		if rng.randf() < 0.5:
			cv.put(h.x - 1, h.y - 1, petal_light, 0.0)
			cv.put(h.x + 1, h.y - 1, petal_light, 0.0)
	return cv


static func _mushrooms(rng: RandomNumberGenerator, ramp: String, variant: int) -> RefCounted:
	var cv: RefCounted = Canvas.new(16, 16, false, false)
	var dark: int = P.c(ramp, 0)
	var mid: int = P.c(ramp, 1)
	var light: int = P.c(ramp, 2)
	var stem_l: int = P.hx("#E8E0C8")
	var stem_d: int = P.hx("#B8AE98")
	# [x do pé, altura total, meia-largura do chapéu, altura do chapéu]
	var specs: Array = []
	match variant:
		0:
			specs = [[5, 6, 2.6, 3], [10, 9, 3.6, 4]]
		1:
			specs = [[4, 6, 2.8, 3], [10, 10, 4.2, 4]]
		2:
			specs = [[8, 9, 4.0, 4], [3, 5, 2.2, 2]]
		3:
			specs = [[4, 7, 2.8, 3], [8, 9, 3.2, 3], [12, 6, 2.4, 3]]
	# o maior por último (fica na frente)
	specs.sort_custom(func(a: Array, b: Array) -> bool: return int(a[1]) < int(b[1]))
	for sp: Array in specs:
		var sx: int = sp[0]
		var total: int = sp[1]
		var hw: float = sp[2]
		var ch: int = sp[3]
		var top: int = 16 - total
		var stem_w: int = 2 if hw > 3.0 else 1
		# pé
		for y: int in range(top + ch, 16):
			for i: int in stem_w:
				cv.put(sx + i, y, stem_d if y == 15 or y == top + ch else stem_l, 0.0)
		# chapéu em cúpula
		var cx: float = sx + stem_w * 0.5
		for y: int in range(top, top + ch):
			var t: float = (y - top + 0.5) / ch
			var half: float = hw * sqrt(clampf(1.0 - pow(1.0 - t, 2.0) * 0.0 - pow(1.0 - t, 2.2), 0.0, 1.0))
			half = maxf(half, 1.0)
			for x: int in range(floori(cx - half), ceili(cx + half)):
				if absf(x + 0.5 - cx) <= half:
					var c: int = mid
					if t < 0.34:
						c = light
					elif y == top + ch - 1:
						c = dark if absf(x + 0.5 - cx) < half - 1.0 else mid
					cv.put(x, y, c, 0.0)
		# luz de cima: todo pixel do chapéu exposto em cima é claro
		for y: int in range(top, top + ch - 1):
			for x: int in range(0, 16):
				if cv.get_c(x, y) == mid and cv.get_c(x, y - 1) < 0:
					cv.put(x, y, light, 0.0)
		# pintas claras no chapéu grande
		if hw > 3.0:
			var yy: int = top + ch / 2
			cv.put(roundi(cx - hw * 0.5), yy, light, 0.0)
			cv.put(roundi(cx + hw * 0.4), yy, light, 0.0)
	return cv
