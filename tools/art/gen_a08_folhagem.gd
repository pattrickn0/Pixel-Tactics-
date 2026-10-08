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
	if only == "" or only.begins_with("clumps"):
		var k: int = 0
		for fam: String in ["warm", "mid", "cool"]:
			if only == "" or only == "clumps" or only == "clumps_" + fam:
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


static func save_card(cv: PL.Canvas, rel: String) -> Image:  # devolve a imagem gravada
	var img: Image = cv.down2().to_image(false)
	PL.dilate_rgb(img, 24)
	PL.save_png(img, PL.TEX + rel + ".png")
	return img


# ---------------------------------------------------------------------------
# Tufos de folha: atlas 4 x 4 de células 256 (1024x1024), alfa recortado.
# (r2) Cada célula é uma massa de folhas lobada (4 a 7 lóbulos sobrepostos), não uma bola:
# os lóbulos são pintados de baixo para cima, cada um com a crista um pouco mais clara e uma sombra
# suave por cima do lóbulo de baixo (as reentrâncias escuras ficam embaixo). Gradiente geral fraco
# (a luz da copa vem do shader). A borda é feita de grupos de folhas de 6 a 14 px.
# ---------------------------------------------------------------------------

const LOBE_CREST: float = 0.17  # crista do lóbulo mais clara
const LOBE_UNDER: float = 0.24  # beira de baixo do lóbulo mais escura (reentrância)
const LOBE_BAL: float = 0.26  # compensa o escuro das bordas de baixo (gradiente geral fraco)
const LOBE_DOME: float = 0.15  # miolo do lóbulo mais claro e a beira mais escura (simétrico: não pesa no topo x base)
const TB_TARGET: float = 12.0  # topo - base (L) alvo por célula (limite da spec: 25)
const LEAF_AO: float = 0.12  # fresta entre grupos de folhas (fraca: detalhe fino não pode dominar)
const CLUMP_COVER: float = 0.5  # alvo de cobertura da célula pelo corpo (as folhas da borda somam um pouco)


func _leaf_clumps(fam: String, seed_value: int) -> void:
	var cell: int = 256 * SS
	var cv := PL.Canvas.new(cell * 4, cell * 4, false, false)
	var ramp: Array = ramp_of(FAMILIES[fam])
	cv.fill(ramp[2], 0.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var tone_n := FastNoiseLite.new()
	tone_n.seed = seed_value + 2
	tone_n.frequency = 1.0 / 110.0
	var edge_n := FastNoiseLite.new()
	edge_n.seed = seed_value + 3
	edge_n.frequency = 1.0 / 60.0
	for k: int in 16:
		var org := Vector2i((k % 4) * cell, (k / 4) * cell)
		var lobes: Array = _clump_layout(rng, cell)
		_paint_clump(cv, rng, tone_n, edge_n, org, cell, lobes, ramp)
		_balance_cell(cv, org, cell)
	var img: Image = save_card(cv, "foliage/leaf_clumps_" + fam)
	var mn: Dictionary = {"cover": 9.0, "dark": 0.0, "dark_low": 9.0, "dtb": 0.0}
	var mx_cover: float = 0.0
	var tbs: PackedStringArray = []
	for k: int in 16:
		var st: Dictionary = PL.clump_stats(img, Rect2i((k % 4) * 256, (k / 4) * 256, 256, 256))
		mn["cover"] = minf(mn["cover"], st["cover"])
		mx_cover = maxf(mx_cover, st["cover"])
		mn["dark"] = maxf(mn["dark"], st["dark"])
		mn["dark_low"] = minf(mn["dark_low"], st["dark_low"])
		mn["dtb"] = maxf(mn["dtb"], st["dtb"])
		tbs.append("%+.0f" % float(st["tb"]))
	print("  topo - base por célula: " + " ".join(tbs))
	print("leaf_clumps_%s: cobertura %.0f%% a %.0f%%, escuro máx %.1f%%, escuro embaixo mín %.0f%%, topo-base máx %.1f" % [
		fam, mn["cover"] * 100.0, mx_cover * 100.0, mn["dark"] * 100.0, mn["dark_low"] * 100.0, mn["dtb"]])


## Altura da "cúpula" dos lóbulos num ponto (o lóbulo mais à frente vence) e o índice dele; -1 fora.
## Os lóbulos de cima ficam um pouco mais à frente (a copa é vista de cima e de lado).
static func _dome(p: Vector2, lobes: Array, wob: float) -> Vector2:
	var best: float = -INF
	var bi: int = -1
	for j: int in lobes.size():
		var c: Vector2 = lobes[j][0]
		var r: float = lobes[j][1]
		var d: float = p.distance_to(c) / r + wob
		if d >= 1.0:
			continue
		var h: float = r * sqrt(1.0 - d * d) + c.y * 0.3
		if h > best:
			best = h
			bi = j
	return Vector2(best, bi)


## Uma célula: a massa é coberta de grupos de folhas (6 a 14 px) empilhados por altura (z-buffer).
## Cada grupo é um leque de 3 a 5 folhas pontudas caindo para fora e para baixo. Cada pixel mostra a
## folha mais alta; o tom vem da folha (as que apontam para cima, mais claras; meia folha de cima mais
## clara), da cúpula do lóbulo (fraco: a luz da copa é do shader) e escurece nas reentrâncias.
func _paint_clump(cv: PL.Canvas, rng: RandomNumberGenerator, tone_n: FastNoiseLite, edge_n: FastNoiseLite, org: Vector2i, cell: int, lobes: Array, ramp: Array) -> void:
	var n: int = cell * cell
	var H := PackedFloat32Array()
	H.resize(n)
	H.fill(-1.0e9)
	var tone := PackedFloat32Array()
	tone.resize(n)
	var win := PackedInt32Array()
	win.resize(n)
	win.fill(-1)
	var lobe_of := PackedInt32Array()
	lobe_of.resize(n)
	lobe_of.fill(-1)
	# fundo: miolo sombreado por baixo das folhas (as frestas mostram verde-médio escuro, não buraco)
	for y: int in cell:
		for x: int in cell:
			var p := Vector2(x + 0.5, y + 0.5)
			var dm: Vector2 = _dome(p, lobes, 0.16 * edge_n.get_noise_2d(p.x + org.x, p.y + org.y) + 0.1)
			if dm.y >= 0.0:
				var i: int = y * cell + x
				H[i] = -1.0e8
				win[i] = -2
				lobe_of[i] = int(dm.y)
				tone[i] = -0.2
	var bumps: Array = []
	var step: float = 13.0
	var gy: float = step * 0.5
	while gy < cell:
		var gx: float = step * 0.5
		while gx < cell:
			var p := Vector2(gx + rng.randf_range(-0.45, 0.45) * step, gy + rng.randf_range(-0.45, 0.45) * step)
			var wob: float = 0.16 * edge_n.get_noise_2d(p.x + org.x, p.y + org.y)
			var dm: Vector2 = _dome(p, lobes, wob)
			if dm.y >= 0.0:
				bumps.append([p, rng.randf_range(16.0, 27.0), dm.x, int(dm.y)])
			gx += step
		gy += step
	for bi: int in bumps.size():
		var b: Array = bumps[bi]
		var c: Vector2 = b[0]
		var rad: float = b[1]
		var hb: float = b[2]
		var lc: Vector2 = lobes[int(b[3])][0]
		var lr: float = lobes[int(b[3])][1]
		var outv: Vector2 = (c - lc) / lr
		# leque: para fora do lóbulo na borda, para baixo no miolo
		var dir: float = lerp_angle(PI * 0.5, outv.angle(), clampf(outv.length() * 1.3 - 0.3, 0.0, 1.0))
		dir += rng.randf_range(-0.5, 0.5)
		var leaves: Array = []
		var nl: int = rng.randi_range(3, 5)
		for l: int in nl:
			var ang: float = dir + (float(l) - (nl - 1) * 0.5) * rng.randf_range(0.45, 0.7) + rng.randf_range(-0.15, 0.15)
			var ln: float = rad * rng.randf_range(0.85, 1.2)
			var lt: float = 0.03 * clampf(-sin(ang), -1.0, 1.0) + rng.randf_range(-0.04, 0.04)
			leaves.append([Vector2(cos(ang), sin(ang)), ln, ln * rng.randf_range(0.36, 0.46), lt])
		var reach: float = rad * 1.25
		for y: int in range(maxi(0, floori(c.y - reach)), mini(cell, ceili(c.y + reach) + 1)):
			for x: int in range(maxi(0, floori(c.x - reach)), mini(cell, ceili(c.x + reach) + 1)):
				var q := Vector2(x + 0.5, y + 0.5) - c
				var i: int = y * cell + x
				for lf: Array in leaves:
					var ax: Vector2 = lf[0]
					var ln: float = lf[1]
					var s: float = q.dot(ax) / ln + 0.12
					if s <= 0.0 or s >= 1.0:
						continue
					var across: float = q.x * -ax.y + q.y * ax.x
					var wd: float = float(lf[2]) * 0.5 * pow(sin(PI * pow(s, 0.8)), 0.75)
					var u: float = across / maxf(wd, 0.001)
					if absf(u) >= 1.0:
						continue
					var h: float = hb + rad * 0.7 * (1.0 - 0.6 * s) * sqrt(1.0 - u * u)
					if h > H[i]:
						H[i] = h
						win[i] = bi
						lobe_of[i] = int(b[3])
						# meia folha voltada para cima um pouco mais clara (luz só de cima)
						var up: float = -signf(ax.x) * u if absf(ax.x) > 0.2 else 0.0
						tone[i] = float(lf[3]) + 0.05 * clampf(up, -1.0, 1.0) - 0.06 * s
	# reentrância: a fresta (fundo) conta como 14 abaixo do topo da cúpula do lóbulo; fora, bem abaixo
	var Hb := PackedFloat32Array()
	Hb.resize(n)
	var hmin: float = 1.0e9
	for i: int in n:
		if win[i] >= 0:
			hmin = minf(hmin, H[i])
	for i: int in n:
		if win[i] == -2:
			var dm: Vector2 = _dome(Vector2(i % cell + 0.5, i / cell + 0.5), lobes, 0.0)
			H[i] = (dm.x if dm.y >= 0.0 else hmin) - 14.0
		Hb[i] = H[i] if win[i] != -1 else hmin - 6.0
	Hb = PL.blur(Hb, cell, cell, 6, false, false, 2)
	var mtop: float = INF
	var mbot: float = -INF
	for lb: Array in lobes:
		mtop = minf(mtop, (lb[0] as Vector2).y - float(lb[1]))
		mbot = maxf(mbot, (lb[0] as Vector2).y + float(lb[1]))
	for y: int in cell:
		for x: int in cell:
			var i: int = y * cell + x
			if win[i] == -1:
				continue
			var lc: Vector2 = lobes[lobe_of[i]][0]
			var lr: float = lobes[lobe_of[i]][1]
			# cúpula do lóbulo: só a parte de cima um pouco mais clara e a de baixo um pouco mais escura
			var v: float = clampf((y + 0.5 - lc.y) / lr, -1.0, 1.0)
			var tn: float = tone[i]
			if win[i] == -2:
				# fresta: clara no alto da massa, escura só embaixo (as reentrâncias ficam no terço de baixo)
				var my: float = clampf((float(y) - mtop) / maxf(mbot - mtop, 1.0), 0.0, 1.0)
				tn = -0.04 - 0.38 * smoothstep(0.6, 0.88, my)
			var gyy: float = clampf((float(y) - mtop) / maxf(mbot - mtop, 1.0), 0.0, 1.0)
			var t: float = 0.53 + tn + LOBE_CREST * clampf(-v - 0.05, 0.0, 1.0) - LOBE_UNDER * smoothstep(0.0, 0.95, v) + LOBE_BAL * (gyy - 0.5)
			var dl: float = clampf(Vector2(x + 0.5 - lc.x, y + 0.5 - lc.y).length() / lr, 0.0, 1.0)
			t += LOBE_DOME * (0.55 - dl * dl) + float(lobes[lobe_of[i]][2])
			t += 0.06 * tone_n.get_noise_2d(x + org.x, y + org.y)
			# reentrância mais funda embaixo do lóbulo (a parte de cima da copa quase não tem fresta escura)
			var ao: float = clampf((Hb[i] - H[i]) / 14.0, 0.0, 1.0)
			t -= ao * LEAF_AO
			# escuro de verdade só no terço de baixo da massa
			if y < cell * 2 / 3:
				t = maxf(t, 0.34)
			var col: Color = PL.ramp_at(ramp, clampf(t, 0.02, 0.95))
			var j: int = (org.y + y) * cv.w + org.x + x
			cv.r[j] = col.r
			cv.g[j] = col.g
			cv.b[j] = col.b
			cv.a[j] = 1.0


## Gradiente geral da célula: se o terço de cima passar do de baixo por mais de TB_TARGET de L, inclina
## as cores na vertical (multiplicador linear) até ficar nesse alvo (a luz da copa vem do shader).
func _balance_cell(cv: PL.Canvas, org: Vector2i, cell: int) -> void:
	var st: float = 0.0
	var sb: float = 0.0
	var nt: int = 0
	var nb: int = 0
	for y: int in cell:
		var third: int = y * 3 / cell
		if third == 1:
			continue
		for x: int in cell:
			var j: int = (org.y + y) * cv.w + org.x + x
			if cv.a[j] < 0.5:
				continue
			var l: float = (0.299 * cv.r[j] + 0.587 * cv.g[j] + 0.114 * cv.b[j]) * 255.0
			if third == 0:
				st += l
				nt += 1
			else:
				sb += l
				nb += 1
	var lt: float = st / float(maxi(nt, 1))
	var lb: float = sb / float(maxi(nb, 1))
	var tb: float = lt - lb
	if absf(tb - TB_TARGET) < 3.0:
		return
	var g: float = 3.0 * (tb - TB_TARGET) / maxf(lt + lb, 1.0)
	for y: int in cell:
		var f: float = 1.0 + g * (float(y) / float(cell) - 0.5)
		for x: int in cell:
			var j: int = (org.y + y) * cv.w + org.x + x
			cv.r[j] = clampf(cv.r[j] * f, 0.0, 1.0)
			cv.g[j] = clampf(cv.g[j] * f, 0.0, 1.0)
			cv.b[j] = clampf(cv.b[j] * f, 0.0, 1.0)


## Lóbulos de uma célula: [centro (em px da célula), raio]. Um lóbulo grande no meio e 3 a 6 em volta,
## com o conjunto ajustado para caber na célula (margem para as folhas) e cobrir ~CLUMP_COVER.
func _clump_layout(rng: RandomNumberGenerator, cell: int) -> Array:
	var lobes: Array = []
	var main := Vector2(cell * rng.randf_range(0.46, 0.54), cell * rng.randf_range(0.5, 0.56))
	lobes.append([main, cell * rng.randf_range(0.19, 0.23), rng.randf_range(-0.05, 0.05)])
	var n: int = rng.randi_range(3, 6)
	var a0: float = rng.randf() * TAU
	for j: int in n:
		var ang: float = a0 + float(j) * TAU / float(n) + rng.randf_range(-0.45, 0.45)
		var dist: float = cell * rng.randf_range(0.23, 0.31)
		var c: Vector2 = main + Vector2(cos(ang) * dist * 1.15, sin(ang) * dist * 0.8)
		lobes.append([c, cell * rng.randf_range(0.11, 0.18), rng.randf_range(-0.07, 0.07)])
	# encaixa na célula (margem para as folhas) e ajusta os raios até a cobertura alvo
	var margin: float = cell * 0.05
	var mid := Vector2(cell * 0.5, cell * 0.52)
	for it: int in 14:
		var x0: float = INF
		var x1: float = -INF
		var y0: float = INF
		var y1: float = -INF
		for lb: Array in lobes:
			var c: Vector2 = lb[0]
			var r: float = lb[1]
			x0 = minf(x0, c.x - r)
			x1 = maxf(x1, c.x + r)
			y0 = minf(y0, c.y - r)
			y1 = maxf(y1, c.y + r)
		var shift := Vector2(mid.x - (x0 + x1) * 0.5, mid.y - (y0 + y1) * 0.5)
		var sc: float = minf(1.0, minf((cell - 2.0 * margin) / maxf(x1 - x0, 1.0), (cell - 2.0 * margin) / maxf(y1 - y0, 1.0)))
		for lb: Array in lobes:
			lb[0] = mid + ((lb[0] as Vector2) + shift - mid) * sc
			lb[1] = float(lb[1]) * sc
		var cov: float = _lobe_cover(lobes, cell)
		var kc: float = clampf(sqrt(CLUMP_COVER / maxf(cov, 0.01)), 0.95, 1.05)
		for lb: Array in lobes:
			lb[1] = float(lb[1]) * kc
	return lobes


func _lobe_cover(lobes: Array, cell: int) -> float:
	var g: int = 48
	var hit: int = 0
	for y: int in g:
		for x: int in g:
			var p := Vector2((x + 0.5) * cell / g, (y + 0.5) * cell / g)
			for lb: Array in lobes:
				if p.distance_to(lb[0]) < float(lb[1]):
					hit += 1
					break
	return float(hit) / float(g * g)


# ---------------------------------------------------------------------------
# Andares de conífera: atlas 4 x 2 de células 256 (1024x512).
# Células 0..5: andares (do mais largo ao mais estreito); 6, 7: pontas da copa.
# O topo do andar fica no alto da célula e os galhos caem para baixo.
# (r2) Andar assimétrico: ápice fora do meio, um lado mais comprido e mais caído, saia de 4 a 8 cachos
# de larguras diferentes em espaçamento irregular, pontas dos galhos caindo, sombra seguindo os cachos.
# ---------------------------------------------------------------------------

# [meia largura esquerda, meia largura direita, deslocamento do ápice, cachos, caimento (lado), seed]
const TIERS: Array = [
	[0.41, 0.33, -0.05, 7, 1.0, 8411], [0.32, 0.4, 0.06, 6, -1.0, 8412], [0.37, 0.29, -0.03, 6, 0.6, 8413],
	[0.27, 0.34, 0.05, 5, -0.8, 8414], [0.3, 0.24, -0.04, 5, 1.0, 8415], [0.21, 0.27, 0.03, 5, -1.0, 8417],
]


func _conifer_tiers() -> void:
	var cell: int = 256 * SS
	var cv := PL.Canvas.new(cell * 4, cell * 2, false, false)
	var ramp: Array = ramp_of(CONIFER)
	ramp.append(c("#B8C858"))
	cv.fill(ramp[1], 0.0)
	for k: int in 6:
		var e: Array = TIERS[k]
		var org := Vector2((k % 4) * cell, (k / 4) * cell)
		var rng := RandomNumberGenerator.new()
		rng.seed = int(e[5])
		_shelf2(cv, rng, org, cell, float(e[0]), float(e[1]), float(e[2]), 0.1, 0.9, int(e[3]), float(e[4]), ramp)
	for k: int in 2:
		var org := Vector2((6 + k) % 4 * cell, cell)
		var rng := RandomNumberGenerator.new()
		rng.seed = 8421 + k
		_tip(cv, rng, org, cell, 0.14 + 0.03 * k, 0.07 if k == 0 else -0.08, 3 + k, ramp)
	var img: Image = save_card(cv, "foliage/conifer_tiers")
	print("conifer_tiers: rampa clara (L >= L de #6E9A3A) em %.0f%% dos opacos" % (100.0 * light_share(img, c("#6E9A3A"))))
	for k: int in 6:
		var st: Dictionary = PL.tier_stats(img, Rect2i((k % 4) * 256, (k / 4) * 256, 256, 256))
		print("  andar %d: IoU espelho %.2f, cachos %d, maior/menor %.2f, trecho reto %.0f%%" % [k, st["iou"], st["clumps"], st["ratio"], st["straight"] * 100.0])


## Fração dos pixels opacos (alfa >= 128) com luminância >= a da cor de corte.
static func light_share(img: Image, cut: Color) -> float:
	var lc: float = PL.lum(cut)
	var d: PackedByteArray = img.get_data()
	var n: int = 0
	var k: int = 0
	for i: int in img.get_width() * img.get_height():
		if d[i * 4 + 3] < 128:
			continue
		n += 1
		if 0.299 * d[i * 4] + 0.587 * d[i * 4 + 1] + 0.114 * d[i * 4 + 2] >= lc:
			k += 1
	return float(k) / float(maxi(n, 1))


## Larguras dos cachos (somam 1): sorteadas, com o maior >= 1,8 x o menor garantido.
static func clump_widths(rng: RandomNumberGenerator, n: int) -> Array:
	var ws: Array = []
	var tot: float = 0.0
	for j: int in n:
		ws.append(rng.randf_range(0.65, 1.35))
	var lo: int = rng.randi_range(0, n - 1)
	var hi: int = (lo + 1 + rng.randi_range(0, n - 2)) % n
	ws[lo] = 0.55
	ws[hi] = 1.45
	for v: float in ws:
		tot += v
	for j: int in n:
		ws[j] = float(ws[j]) / tot
	return ws


func _shelf2(cv: PL.Canvas, rng: RandomNumberGenerator, org: Vector2, cell: int, hl: float, hr: float, apex_dx: float, top: float, bottom: float, clumps: int, droop: float, ramp: Array) -> void:
	var cx: float = org.x + cell * 0.5
	var ax: float = cx + cell * apex_dx
	var y_top: float = org.y + cell * top
	var y_bot: float = org.y + cell * bottom
	var xl: float = cx - cell * hl
	var xr: float = cx + cell * hr
	var span: float = xr - xl
	var ws: Array = clump_widths(rng, clumps)
	# linha da saia (de onde os cachos caem): torta, mais baixa no lado que cai mais
	var base_drop: float = (y_bot - y_top) * 0.42
	var skirt_y: Callable = func(x: float) -> float:
		var u: float = (x - xl) / span * 2.0 - 1.0
		return y_top + (y_bot - y_top) * 0.7 + base_drop * 0.12 * droop * u + base_drop * 0.08 * u * u
	# cachos: [centro x, meia largura, queda]
	var cl: Array = []
	var x: float = xl
	for j: int in clumps:
		var w: float = float(ws[j]) * span
		var hw: float = w * 0.5 * rng.randf_range(1.02, 1.12)
		var end: bool = j == 0 or j == clumps - 1
		var fall: float = hw * rng.randf_range(1.3, 1.8) + (cell * 0.03 if end else 0.0)
		cl.append([x + w * 0.5 + rng.randf_range(-0.06, 0.06) * w, hw, fall, end, j == 0])
		x += w
	# 1. corpo: do ápice até a saia, bordas levemente curvas (galhos), ápice fino e um pouco torto
	var body := PackedVector2Array()
	body.append(Vector2(ax, y_top))
	for s: int in range(1, 7):
		var f: float = float(s) / 6.0
		var xx: float = ax + (xr - ax) * f
		body.append(Vector2(xx + cell * 0.012 * sin(f * 5.0 + 1.0), lerpf(y_top, skirt_y.call(xr), pow(f, 0.85)) ))
	for s: int in range(6, -1, -1):
		var f: float = float(s) / 6.0
		var xx: float = xl + (ax - xl) * (1.0 - f)
		body.append(Vector2(xx - cell * 0.012 * sin(f * 4.0 + 2.0), lerpf(y_top, skirt_y.call(xl), pow(f, 0.85))))
	cv.poly_fill(body, ramp[3])
	# 2. faixa de sombra embaixo do corpo, seguindo os cachos (escura entre eles)
	for e: Array in cl:
		var px: float = e[0]
		var hw: float = e[1]
		var sy: float = skirt_y.call(px)
		cv.blob(px, sy + float(e[2]) * 0.1, hw * 1.2, float(e[2]) * 0.45, 0.0, ramp[0], 1.0, 0.5, 1)
	# 3. superfície de cima: toques redondos, claros no alto, escurecendo para a saia
	var dabs: Array = []
	for k: int in 230:
		var ty: float = sqrt(rng.randf())
		var u: float = rng.randf_range(-1.0, 1.0)
		var xx: float = ax + (u * (xr - ax) if u > 0.0 else -u * (xl - ax)) * ty * 0.92
		var yy: float = lerpf(y_top, skirt_y.call(xx), ty) - cell * 0.02
		dabs.append(Vector2(xx, yy))
	dabs.sort_custom(func(p: Vector2, q: Vector2) -> bool: return p.y < q.y)
	for p: Vector2 in dabs:
		var fy: float = clampf((p.y - y_top) / maxf(skirt_y.call(p.x) - y_top, 1.0), 0.0, 1.0)
		var t: float = clampf(1.1 - 0.36 * fy + rng.randf_range(-0.07, 0.05), 0.0, 1.0)
		var r: float = cell * rng.randf_range(0.022, 0.04)
		cv.blob(p.x, p.y + r * 0.25, r * 1.2, r * 0.8, rng.randf_range(-0.3, 0.3), PL.ramp_at(ramp, t - 0.16), 1.0, 0.7)
		cv.blob(p.x, p.y - r * 0.15, r * 0.85, r * 0.5, 0.0, PL.ramp_at(ramp, t), 1.0, 0.6)
	# 4. cachos caindo (de trás para frente: os do meio por último), metade de cima clara
	var order: Array = cl.duplicate()
	order.sort_custom(func(p: Array, q: Array) -> bool: return absf(float(p[0]) - ax) > absf(float(q[0]) - ax))
	for e: Array in order:
		_droop_clump(cv, rng, e, skirt_y.call(float(e[0])), cell, ramp)
	# 5. ponta clara no ápice
	cv.blob(ax, y_top + cell * 0.02, cell * 0.018, cell * 0.03, 0.15 * apex_dx * 10.0, PL.ramp_at(ramp, 0.92), 1.0, 0.6)


## Cacho caindo: tufo de agulhas que sai da saia e cai (mais largo em cima, ponta arredondada embaixo),
## claro em cima e escuro na ponta. Nas pontas do andar o galho cai mais e para fora.
func _droop_clump(cv: PL.Canvas, rng: RandomNumberGenerator, e: Array, sy: float, cell: int, ramp: Array) -> void:
	var px: float = e[0]
	var hw: float = e[1]
	var fall: float = e[2]
	var end: bool = e[3]
	var left: bool = e[4]
	var lean: float = 0.0
	if end:
		lean = -0.45 if left else 0.45
	var top := Vector2(px, sy - fall * 0.3)
	var tip := Vector2(px + lean * fall * 0.6, sy + fall)
	# silhueta em gota: pincelada larga do ombro (dentro do corpo) até a ponta
	var mid1: Vector2 = top.lerp(tip, 0.4) + Vector2(lean * fall * 0.08, 0.0)
	var mid2: Vector2 = top.lerp(tip, 0.75) + Vector2(lean * fall * 0.12, 0.0)
	cv.stroke(PackedVector2Array([top, mid1, mid2, tip]), PackedFloat32Array([hw * 0.95, hw * 0.9, hw * 0.62, hw * 0.22]), PL.ramp_at(ramp, 0.55), ramp[1], 1.0)
	# agulhas: traços curtos caindo, do claro (em cima) para o escuro (na ponta)
	var nn: int = maxi(12, roundi(hw * 1.5))
	var strokes: Array = []
	for k: int in nn:
		var f: float = rng.randf()
		var u: float = rng.randf_range(-0.9, 0.9) * (1.0 - 0.45 * f)
		var st: Vector2 = Vector2(lerpf(top.x, tip.x, f * 0.72) + u * hw * 0.85, lerpf(top.y, tip.y, f * 0.72) - hw * 0.25 * (1.0 - f))
		strokes.append([st, f, u])
	strokes.sort_custom(func(p: Array, q: Array) -> bool: return float(p[1]) < float(q[1]))
	for sk: Array in strokes:
		var st: Vector2 = sk[0]
		var f: float = sk[1]
		var u: float = sk[2]
		var ang: float = PI * 0.5 + lean * 0.8 + u * 0.35 + rng.randf_range(-0.2, 0.2)
		var ln: float = fall * rng.randf_range(0.28, 0.5)
		var pts: PackedVector2Array = PL.arc_pts(st, ang, ln, rng.randf_range(-0.3, 0.3), 3)
		var t0: float = clampf(0.86 - 0.55 * f + rng.randf_range(-0.07, 0.05), 0.2, 0.95)
		cv.stroke(pts, PackedFloat32Array([hw * 0.16, hw * 0.14, hw * 0.09, 1.2]), PL.ramp_at(ramp, t0), PL.ramp_at(ramp, t0 - 0.32), 1.0)
	# luz de cima no ombro do cacho: toques pequenos e soltos (não uma tampa)
	for k: int in maxi(3, roundi(hw / 6.0)):
		var q: Vector2 = top + Vector2(rng.randf_range(-0.7, 0.7) * hw, fall * rng.randf_range(0.0, 0.25))
		var rr: float = hw * rng.randf_range(0.14, 0.24)
		cv.blob(q.x, q.y, rr * 1.3, rr * 0.8, rng.randf_range(-0.4, 0.4), PL.ramp_at(ramp, rng.randf_range(0.72, 0.92)), 0.9, 0.55, 1)


## Ponta da copa: fina e um pouco torta, com 3 ou 4 cachinhos.
func _tip(cv: PL.Canvas, rng: RandomNumberGenerator, org: Vector2, cell: int, half_w: float, bend: float, clumps: int, ramp: Array) -> void:
	var cx: float = org.x + cell * 0.5
	var y_top: float = org.y + cell * 0.04
	var y_bot: float = org.y + cell * 0.92
	var spine: Callable = func(f: float) -> float:
		return cx + cell * bend * (1.0 - f) * (1.0 - f) * 0.9 - cell * bend * 0.25
	# corpo estreito: polígono ao longo da espinha torta
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for s: int in 9:
		var f: float = float(s) / 8.0
		var y: float = lerpf(y_top, y_bot - cell * 0.12, f)
		var hw: float = cell * half_w * pow(f, 0.8) * (1.0 + 0.08 * sin(f * 9.0 + bend * 20.0))
		left.append(Vector2(spine.call(f) - hw * (1.0 + 0.1 * signf(bend)), y))
		right.append(Vector2(spine.call(f) + hw * (1.0 - 0.1 * signf(bend)), y))
	var poly := PackedVector2Array()
	for p: Vector2 in right:
		poly.append(p)
	for s: int in range(8, -1, -1):
		poly.append(left[s])
	cv.poly_fill(poly, ramp[2])
	for k: int in 120:
		var f: float = sqrt(rng.randf())
		var y: float = lerpf(y_top, y_bot - cell * 0.12, f)
		var hw: float = cell * half_w * pow(f, 0.8) * 0.85
		var x: float = spine.call(f) + rng.randf_range(-1.0, 1.0) * hw
		var t: float = clampf(1.0 - 0.5 * f + rng.randf_range(-0.08, 0.05), 0.0, 1.0)
		var r: float = cell * rng.randf_range(0.016, 0.028)
		cv.blob(x, y + r * 0.2, r * 1.15, r * 0.8, 0.0, PL.ramp_at(ramp, t - 0.18), 1.0, 0.7)
		cv.blob(x, y - r * 0.15, r * 0.8, r * 0.5, 0.0, PL.ramp_at(ramp, t), 1.0, 0.6)
	# cachinhos caindo na base, de larguras diferentes
	var ws: Array = clump_widths(rng, clumps)
	var span: float = cell * half_w * 2.1
	var x0: float = spine.call(1.0) - span * 0.5
	var sy: float = y_bot - cell * 0.14
	for j: int in clumps:
		var w: float = float(ws[j]) * span
		var e: Array = [x0 + w * 0.5, w * 0.55, w * 0.7, j == 0 or j == clumps - 1, j == 0]
		x0 += w
		cv.blob(float(e[0]), sy, float(e[1]) * 1.1, float(e[2]) * 0.5, 0.0, ramp[0], 1.0, 0.5)
		_droop_clump(cv, rng, e, sy, cell, ramp)
	cv.blob(spine.call(0.0), y_top + cell * 0.01, cell * 0.012, cell * 0.03, bend, PL.ramp_at(ramp, 0.95), 1.0, 0.5)


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
