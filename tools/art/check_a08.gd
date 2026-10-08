extends SceneTree
## Checagem automática da A08, leva 1 (docs/specs/A08-arte-pintada-ilha.md).
## Uma linha por arquivo; no fim "A08 CHECK: PASS" (código 0) ou "A08 CHECK: FAIL (n problemas)" (código 1).
## Também imprime o md5 de cada PNG (para conferir o determinismo rodando os geradores duas vezes).
##   "$G" --headless --path . --script tools/art/check_a08.gd
##
## Definições usadas:
## - Luminância L = 0,299 R + 0,587 G + 0,114 B (0 a 255).
## - Distância RGB normalizada = distância euclidiana / (255 * raiz de 3) (0 = igual, 1 = preto x branco).
## - Ruído por pixel = média de |L - média 3x3 de L| nos pixels opacos (alfa 255 no 3x3 inteiro).
## - Variação = desvio-padrão de L depois de um desfoque de caixa com janela de 1/8 da largura.
## - (r1) Grama na escala da câmera: PL.camera_metrics (redução a 1/3 por Lanczos, desfoque gaussiano σ 4 px).
## - (r1) Musgo do wall_top: pixel com saturação (máx - mín) / máx > 0,36 e G >= 0,85 R (a pedra bege fica
##   abaixo de 0,3; o musgo amarelo-esverdeado, acima de 0,44).
## - (r1) Normal map OpenGL: com a altura aproximada pela luminância desfocada do albedo, a correlação de
##   (R - 128) com o gradiente da altura para a direita e a de (G - 128) com o gradiente para cima têm o
##   mesmo sinal (no DirectX, o G sai invertido e os sinais ficam opostos).
## - Halo = pixel com alfa 0 a até 4 px (vizinhança 8) de um pixel com alfa >= 128 cujo RGB fica a > 10%
##   do RGB desse opaco mais próximo.

const PL = preload("res://tools/art/paint_lib.gd")
const TEX: String = "res://assets/textures/scenery/"

# [arquivo, largura, altura, alfa (o = opaco, c = recortado, s = suave), normal map, eixos seamless,
#  limite de ruído (0 = não se aplica), checa variação, tons base (cor média a <= 12% do mais próximo)]
const FILES: Array = [
	["ground/grass_a", 512, 512, "o", false, "xy", 5.0, true, ["#7FA22C", "#7F8033"]],
	["ground/grass_b", 512, 512, "o", false, "xy", 5.0, true, ["#7FA22C", "#7F8033"]],
	["ground/blend_mask", 256, 256, "o", false, "xy", 0.0, false, []],
	["decals/arena_dirt", 1024, 768, "s", false, "", 8.0, true, ["#AE813F", "#B3843D"]],
	["decals/arena_ring", 384, 384, "s", false, "", 8.0, false, ["#AE813F", "#7E5634", "#C8AA78"]],
	["decals/arena_slabs", 1024, 512, "s", false, "", 8.0, false, ["#B8AE98", "#7E786A", "#947C5A"]],
	["stone/wall_blocks", 512, 128, "o", true, "xy", 8.0, true, ["#C2B58C"]],
	["stone/wall_blocks_mossy", 512, 128, "o", true, "xy", 8.0, true, ["#87A23A", "#56702A", "#C2B58C"]],
	["stone/wall_top", 512, 128, "o", true, "x", 8.0, true, ["#D2C46D"]],
	["stone/slabs", 512, 512, "o", true, "xy", 8.0, true, ["#BBA366", "#B0975E"]],
	["foliage/leaf_clumps_warm", 1024, 1024, "c", false, "", 10.0, false, ["#8DB040", "#5E8A30"]],
	["foliage/leaf_clumps_mid", 1024, 1024, "c", false, "", 10.0, false, ["#5E8A30"]],
	["foliage/leaf_clumps_cool", 1024, 1024, "c", false, "", 10.0, false, ["#5E8A30", "#4E7A2E"]],
	["foliage/conifer_tiers", 1024, 512, "c", false, "", 10.0, false, ["#2C4A1E", "#384F21", "#4E7A2E"]],
	["foliage/bark", 256, 512, "o", true, "y", 8.0, true, ["#7A5638"]],
	["foliage/grass_tufts", 512, 256, "c", false, "", 10.0, false, ["#5E8424", "#7FA22C"]],
	# flores: metade pétala (média das 5 cores) e metade caule/folha (#5E8424)
	["foliage/flowers", 256, 256, "c", false, "", 10.0, false, ["#979D70"]],
	# Leva 2
	["island/cliff", 512, 512, "o", true, "xy", 8.0, true, ["#5C4330", "#6E5038", "#4A3628"]],
	["island/under", 512, 512, "o", true, "xy", 8.0, true, ["#4E4140", "#54443A", "#3E3640"]],
	["island/roots_hang", 512, 1024, "c", false, "", 10.0, false, ["#5A4030", "#4A3426"]],
	["island/vines_hang", 512, 1024, "c", false, "", 10.0, false, ["#3F5F22", "#56702A"]],
	["water/fall_streaks", 256, 512, "o", false, "xy", 8.0, false, ["#B6D0E3", "#BCCEDC"]],
	["water/fall_foam", 512, 128, "s", false, "x", 10.0, false, ["#EAF6FC", "#D3E6F1"]],
	["fx/mist_puff", 256, 256, "s", false, "", 8.0, false, ["#ECE6EE", "#DCD6E6"]],
	["sky/cloud_puffs", 1024, 1024, "s", false, "", 8.0, false, ["#ECE6EE", "#C8C0D4"]],
	["sky/cloud_sea", 1024, 1024, "o", false, "xy", 8.0, false, ["#ECE6EE", "#C8C0D4"]],
	["fx/fire_flipbook", 512, 192, "s", false, "", 10.0, false, ["#E39041", "#FFDA81"]],
	["fx/rainbow", 256, 32, "s", false, "", 0.0, false, []],
	["props/wood_planks", 256, 256, "o", true, "xy", 8.0, true, ["#7A5638", "#A88058"]],
	["props/wood_end", 256, 256, "o", true, "", 8.0, false, ["#A88058", "#7A5638"]],
	["props/rope", 64, 256, "o", false, "xy", 8.0, false, ["#B49C76", "#A88C64"]],
	["props/iron", 128, 128, "o", true, "xy", 8.0, false, ["#46464E", "#3A3A42"]],
	["props/ruin_stone", 512, 512, "o", true, "xy", 8.0, true, ["#BDA083"]],
]
const SCRIPTS: Array[String] = [
	"res://tools/art/paint_lib.gd", "res://tools/art/gen_a08_chao.gd", "res://tools/art/gen_a08_pedra.gd",
	"res://tools/art/gen_a08_folhagem.gd", "res://tools/art/gen_a08_paleta.gd",
	"res://tools/art/gen_a08_ilha.gd", "res://tools/art/gen_a08_ceu_agua.gd", "res://tools/art/gen_a08_props.gd",
]
const CA = preload("res://tools/art/gen_a08_ceu_agua.gd")

var _problems: int = 0


func _initialize() -> void:
	for e: Array in FILES:
		_check_file(e)
	_check_r1()
	_check_r2()
	_check_leva2()
	_check_scripts()
	if _problems == 0:
		print("A08 CHECK: PASS")
		quit(0)
	else:
		print("A08 CHECK: FAIL (%d problemas)" % _problems)
		quit(1)


func _fail(msg: String) -> void:
	_problems += 1
	print("  FALHA: " + msg)


func _check_file(e: Array) -> void:
	var rel: String = e[0]
	var path: String = TEX + rel + ".png"
	if not FileAccess.file_exists(path):
		_fail(rel + ": não existe")
		return
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	img.convert(Image.FORMAT_RGBA8)
	var w: int = img.get_width()
	var h: int = img.get_height()
	var md5: String = FileAccess.get_md5(path)
	var notes: Array[String] = []
	if w != int(e[1]) or h != int(e[2]):
		_fail("%s: %dx%d (esperado %dx%d)" % [rel, w, h, e[1], e[2]])
	var data: PackedByteArray = img.get_data()
	var n: int = w * h
	var L := PackedFloat32Array()
	L.resize(n)
	var A := PackedByteArray()
	A.resize(n)
	var sr: float = 0.0
	var sg: float = 0.0
	var sb: float = 0.0
	var cnt: int = 0
	var bw: int = 0
	for i: int in n:
		var r: int = data[i * 4]
		var g: int = data[i * 4 + 1]
		var b: int = data[i * 4 + 2]
		A[i] = data[i * 4 + 3]
		L[i] = 0.299 * r + 0.587 * g + 0.114 * b
		if A[i] >= 128:
			sr += r
			sg += g
			sb += b
			cnt += 1
			if (r == 0 and g == 0 and b == 0) or (r == 255 and g == 255 and b == 255):
				bw += 1
	var kind: String = e[3]
	if kind == "o":
		for i: int in n:
			if A[i] != 255:
				_fail(rel + ": opaco com alfa < 255")
				break
	if bw > 0 and not rel.ends_with("blend_mask"):
		_fail("%s: %d pixels preto ou branco puro" % [rel, bw])
	# Seamless (albedo)
	var axes: String = e[5]
	for ax: String in axes:
		var ratio: float = _seam_ratio(data, w, h, ax == "x")
		notes.append("emenda %s %.2f" % [ax, ratio])
		if ratio > 1.5:
			_fail("%s: emenda em %s (%.2f > 1,5)" % [rel, ax, ratio])
	# Ruído por pixel
	var nlim: float = e[6]
	if nlim > 0.0:
		var nz: float = _pixel_noise(L, A, w, h)
		notes.append("ruído %.2f/%.0f" % [nz, nlim])
		if nz > nlim:
			_fail("%s: ruído por pixel %.2f > %.1f" % [rel, nz, nlim])
	# Variação grande
	if bool(e[7]):
		var vs: float = _blur_std(L, A, w, h, kind == "o", axes)
		notes.append("variação %.1f" % vs)
		if vs < 4.0:
			_fail("%s: chapada (desvio após desfoque %.1f < 4)" % [rel, vs])
	# Cor média
	var bases: Array = e[8]
	if bases.size() > 0 and cnt > 0:
		var mean := Color(sr / cnt / 255.0, sg / cnt / 255.0, sb / cnt / 255.0)
		var best: float = 9.0
		var best_hex: String = ""
		for hx: String in bases:
			var d: float = PL.cdist(mean, Color.html(hx))
			if d < best:
				best = d
				best_hex = hx
		notes.append("média #%s (%.1f%% de %s)" % [mean.to_html(false).to_upper(), best * 100.0, best_hex])
		if best > 0.12:
			_fail("%s: cor média #%s a %.1f%% de %s" % [rel, mean.to_html(false), best * 100.0, best_hex])
	# Halo
	if kind != "o":
		var halo: Vector2i = _halo(data, w, h)
		notes.append("halo %d/%d" % [halo.x, halo.y])
		if halo.x > 0:
			_fail("%s: %d pixels transparentes com RGB de halo (de %d perto do recorte)" % [rel, halo.x, halo.y])
	# Normal map
	if bool(e[4]):
		var npath: String = TEX + rel + "_n.png"
		if not FileAccess.file_exists(npath):
			_fail(rel + "_n: não existe")
		else:
			var nimg := Image.load_from_file(ProjectSettings.globalize_path(npath))
			nimg.convert(Image.FORMAT_RGBA8)
			if nimg.get_size() != img.get_size():
				_fail(rel + "_n: tamanho diferente do albedo")
			var nd: PackedByteArray = nimg.get_data()
			var zs: float = 0.0
			for i: int in nimg.get_width() * nimg.get_height():
				zs += float(nd[i * 4 + 2]) / 255.0 * 2.0 - 1.0
			var zm: float = zs / float(nimg.get_width() * nimg.get_height())
			notes.append("_n z %.3f" % zm)
			if zm < 0.85:
				_fail("%s_n: Z médio %.3f < 0,85" % [rel, zm])
			for ax: String in axes:
				var ratio: float = _seam_ratio(nd, nimg.get_width(), nimg.get_height(), ax == "x")
				notes.append("_n emenda %s %.2f" % [ax, ratio])
				if ratio > 1.5:
					_fail("%s_n: emenda em %s (%.2f)" % [rel, ax, ratio])
			print("  md5 %s  %s_n.png" % [FileAccess.get_md5(npath), rel])
	print("%s %dx%d: %s" % [rel, w, h, ", ".join(notes)])
	print("  md5 %s  %s.png" % [md5, rel])


## Diferença média entre a borda e a borda oposta / diferença média entre vizinhas do interior.
func _seam_ratio(data: PackedByteArray, w: int, h: int, along_x: bool) -> float:
	var edge: float = 0.0
	var inner: float = 0.0
	var ni: int = 0
	if along_x:
		for y: int in h:
			edge += _pdiff(data, y * w + w - 1, y * w)
		for x: int in range(1, w - 2):
			for y: int in h:
				inner += _pdiff(data, y * w + x, y * w + x + 1)
				ni += 1
		edge /= float(h)
	else:
		for x: int in w:
			edge += _pdiff(data, (h - 1) * w + x, x)
		for y: int in range(1, h - 2):
			for x: int in w:
				inner += _pdiff(data, y * w + x, (y + 1) * w + x)
				ni += 1
		edge /= float(w)
	inner /= float(ni)
	return edge / maxf(inner, 0.0001)


func _pdiff(data: PackedByteArray, i: int, j: int) -> float:
	return (absf(data[i * 4] - data[j * 4]) + absf(data[i * 4 + 1] - data[j * 4 + 1]) + absf(data[i * 4 + 2] - data[j * 4 + 2])) / 3.0


func _pixel_noise(L: PackedFloat32Array, A: PackedByteArray, w: int, h: int) -> float:
	var s: float = 0.0
	var m: int = 0
	for y: int in range(1, h - 1):
		for x: int in range(1, w - 1):
			var ok: bool = true
			var acc: float = 0.0
			for dy: int in range(-1, 2):
				for dx: int in range(-1, 2):
					var j: int = (y + dy) * w + x + dx
					if A[j] != 255:
						ok = false
					acc += L[j]
			if not ok:
				continue
			s += absf(L[y * w + x] - acc / 9.0)
			m += 1
	return s / float(maxi(m, 1))


func _blur_std(L: PackedFloat32Array, A: PackedByteArray, w: int, h: int, opaque: bool, axes: String) -> float:
	var r: int = maxi(1, w / 16)
	var bl: PackedFloat32Array = PL.blur(L, w, h, r, axes.contains("x"), axes.contains("y"), 1)
	var s: float = 0.0
	var s2: float = 0.0
	var m: int = 0
	for i: int in w * h:
		if not opaque and A[i] < 255:
			continue
		s += bl[i]
		s2 += bl[i] * bl[i]
		m += 1
	var mean: float = s / maxf(float(m), 1.0)
	return sqrt(maxf(s2 / maxf(float(m), 1.0) - mean * mean, 0.0))


## Devolve (pixels com halo, pixels transparentes conferidos).
func _halo(data: PackedByteArray, w: int, h: int) -> Vector2i:
	var src := PackedInt32Array()
	src.resize(w * h)
	src.fill(-1)
	var frontier: Array[int] = []
	for i: int in w * h:
		if data[i * 4 + 3] >= 128:
			src[i] = i
			frontier.append(i)
	var dist := PackedByteArray()
	dist.resize(w * h)
	for step: int in 4:
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
						dist[j] = step + 1
						nf.append(j)
		frontier = nf
	var bad: int = 0
	var checked: int = 0
	for i: int in w * h:
		if data[i * 4 + 3] != 0 or src[i] < 0 or dist[i] == 0:
			continue
		checked += 1
		var j: int = src[i]
		var d: float = Vector3(data[i * 4] - data[j * 4], data[i * 4 + 1] - data[j * 4 + 1], data[i * 4 + 2] - data[j * 4 + 2]).length() / (255.0 * sqrt(3.0))
		if d > 0.1:
			bad += 1
	return Vector2i(bad, checked)


## Critérios da revisão r1 (docs/specs/revisoes/A08.md).
func _check_r1() -> void:
	for rel: String in ["ground/grass_a", "ground/grass_b"]:
		var img: Image = PL.load_tex(rel)
		var m: Dictionary = PL.camera_metrics(img)
		print("r1 %s a 1/3: desvio L %.1f (>= 22), |L - desfoque σ4| %.1f (>= 10), L médio %.1f (105 a 125)" % [rel, m["std"], m["detail"], m["mean"]])
		if float(m["std"]) < 22.0 or float(m["detail"]) < 10.0 or float(m["mean"]) < 105.0 or float(m["mean"]) > 125.0:
			_fail(rel + ": fora do critério de escala da câmera (r1)")
	# wall_top: musgo de 25% a 40%
	var wt: Image = PL.load_tex("stone/wall_top")
	var d: PackedByteArray = wt.get_data()
	var moss: int = 0
	for i: int in wt.get_width() * wt.get_height():
		var r: float = d[i * 4]
		var g: float = d[i * 4 + 1]
		var b: float = d[i * 4 + 2]
		var mx: float = maxf(r, maxf(g, b))
		if mx > 0.0 and (mx - minf(r, minf(g, b))) / mx > 0.36 and g >= 0.85 * r:
			moss += 1
	var cov: float = float(moss) / float(wt.get_width() * wt.get_height())
	print("r1 stone/wall_top: musgo %.0f%% (25%% a 40%%)" % (cov * 100.0))
	if cov < 0.25 or cov > 0.4:
		_fail("stone/wall_top: musgo %.0f%% fora de 25%% a 40%%" % (cov * 100.0))
	# arena_ring: média do disco (r <= 1,3) a <= 10% de #B27541
	var ring: Image = PL.load_tex("decals/arena_ring")
	var ctr := Vector2(ring.get_width(), ring.get_height()) * 0.5
	var acc := Vector3.ZERO
	var cnt: int = 0
	for y: int in ring.get_height():
		for x: int in ring.get_width():
			if Vector2(x + 0.5, y + 0.5).distance_to(ctr) > 1.3 * 64.0:
				continue
			var c: Color = ring.get_pixel(x, y)
			if c.a < 0.5:
				continue
			acc += Vector3(c.r, c.g, c.b)
			cnt += 1
	acc /= float(maxi(cnt, 1))
	var dm := Color(acc.x, acc.y, acc.z)
	var dd: float = PL.cdist(dm, Color("#B27541"))
	print("r1 decals/arena_ring: média do disco #%s, a %.1f%% de #B27541 (<= 10%%)" % [dm.to_html(false).to_upper(), dd * 100.0])
	if dd > 0.1:
		_fail("decals/arena_ring: disco a %.1f%% de #B27541" % (dd * 100.0))
	# conifer_tiers: rampa clara (L >= L de #6E9A3A) em >= 15% dos opacos do atlas
	var con: Image = PL.load_tex("foliage/conifer_tiers")
	var cd: PackedByteArray = con.get_data()
	var lc: float = PL.lum(Color("#6E9A3A"))
	var n_op: int = 0
	var n_li: int = 0
	for i: int in con.get_width() * con.get_height():
		if cd[i * 4 + 3] < 128:
			continue
		n_op += 1
		if 0.299 * cd[i * 4] + 0.587 * cd[i * 4 + 1] + 0.114 * cd[i * 4 + 2] >= lc:
			n_li += 1
	var share: float = float(n_li) / float(maxi(n_op, 1))
	print("r1 foliage/conifer_tiers: rampa clara em %.0f%% dos opacos (>= 15%%; a montagem da prévia imprime a sua)" % (share * 100.0))
	if share < 0.15:
		_fail("foliage/conifer_tiers: rampa clara em %.0f%% (< 15%%)" % (share * 100.0))
	# Convenção OpenGL dos normal maps
	for rel: String in ["stone/wall_blocks", "stone/wall_blocks_mossy", "stone/wall_top", "stone/slabs", "foliage/bark",
			"island/cliff", "island/under", "props/wood_planks", "props/ruin_stone"]:
		var sg: Vector2 = _normal_sign(PL.load_tex(rel), PL.load_tex(rel + "_n"))
		var ok: bool = sg.x != 0.0 and signf(sg.x) == signf(sg.y)
		print("r1 %s_n: correlação R x grad. direita %.3f, G x grad. para cima %.3f -> %s" % [rel, sg.x, sg.y, "OpenGL" if ok else "?"])
		if not ok:
			_fail(rel + "_n: não parece OpenGL")


func _normal_sign(alb: Image, nrm: Image) -> Vector2:
	var w: int = alb.get_width()
	var h: int = alb.get_height()
	var ad: PackedByteArray = alb.get_data()
	var nd: PackedByteArray = nrm.get_data()
	var L := PackedFloat32Array()
	L.resize(w * h)
	for i: int in w * h:
		L[i] = 0.299 * ad[i * 4] + 0.587 * ad[i * 4 + 1] + 0.114 * ad[i * 4 + 2]
	var hb: PackedFloat32Array = PL.blur(L, w, h, 2, true, true, 2)
	var sx: float = 0.0
	var sy: float = 0.0
	for y: int in range(1, h - 1):
		for x: int in range(1, w - 1):
			var i: int = y * w + x
			var gx: float = hb[i + 1] - hb[i - 1]
			var gy_up: float = hb[i - w] - hb[i + w]
			sx += (float(nd[i * 4]) - 128.0) * gx
			sy += (float(nd[i * 4 + 1]) - 128.0) * gy_up
	var k: float = 1.0 / float(w * h)
	return Vector2(sx * k, sy * k)


## Critérios da revisão r2 (docs/specs/revisoes/A08.md, revisão 2): tufos de folha, andares de conífera,
## terra e pedras da arena. As contas estão em paint_lib (clump_stats, crown_montage, tier_stats,
## dirt_stats, slab_stats), as mesmas que os geradores e as prévias imprimem.
func _check_r2() -> void:
	var atl: Array = []
	for fam: String in ["warm", "mid", "cool"]:
		var img: Image = PL.load_tex("foliage/leaf_clumps_" + fam)
		atl.append(img)
		var cmin: float = 9.0
		var cmax: float = 0.0
		var dmax: float = 0.0
		var lmin: float = 9.0
		var tmax: float = 0.0
		for k: int in 16:
			var st: Dictionary = PL.clump_stats(img, Rect2i((k % 4) * 256, (k / 4) * 256, 256, 256))
			cmin = minf(cmin, st["cover"])
			cmax = maxf(cmax, st["cover"])
			dmax = maxf(dmax, st["dark"])
			lmin = minf(lmin, st["dark_low"])
			tmax = maxf(tmax, st["dtb"])
		var g: Dictionary = PL.crown_montage([img], 7001)
		print("r2 leaf_clumps_%s: cobertura %.0f%% a %.0f%% (45 a 65), escuro máx %.1f%% (<= 8), escuro no terço de baixo mín %.0f%% (>= 60), topo-base máx %.1f (<= 25), granulação da copa %.2f (<= 0,95)" % [
			fam, cmin * 100.0, cmax * 100.0, dmax * 100.0, lmin * 100.0, tmax, g["g_in"]])
		if cmin < 0.45 or cmax > 0.65 or dmax > 0.08 or lmin < 0.6 or tmax > 25.0 or float(g["g_in"]) > 0.95:
			_fail("foliage/leaf_clumps_" + fam + ": fora dos critérios r2")
	var gm: Dictionary = PL.crown_montage(atl, 9101)
	print("r2 copa montada com as 3 famílias: granulação %.2f (<= 0,95; referência 0,74 a 0,84)" % gm["g_in"])
	if float(gm["g_in"]) > 0.95:
		_fail("leaf_clumps: granulação da copa montada %.2f" % gm["g_in"])
	var con: Image = PL.load_tex("foliage/conifer_tiers")
	for k: int in 6:
		var st: Dictionary = PL.tier_stats(con, Rect2i((k % 4) * 256, (k / 4) * 256, 256, 256))
		print("r2 conifer_tiers andar %d: IoU espelho %.2f (<= 0,85), cachos %d (4 a 8), maior/menor %.2f (>= 1,6), trecho reto %.0f%% (<= 12)" % [k, st["iou"], st["clumps"], st["ratio"], float(st["straight"]) * 100.0])
		if float(st["iou"]) > 0.85 or int(st["clumps"]) < 4 or int(st["clumps"]) > 8 or float(st["ratio"]) < 1.6 or float(st["straight"]) > 0.12:
			_fail("foliage/conifer_tiers: andar %d fora dos critérios r2" % k)
	var ds: Dictionary = PL.dirt_stats(PL.load_tex("decals/arena_dirt"))
	var dd: float = PL.cdist(ds["color"], Color("#A57A3F"))
	print("r2 decals/arena_dirt: escuro %.1f%% (25 a 35), claro %.1f%% (<= 10), verde %.1f%% (2 a 5), coroa do anel %+.1f (<= +3), média #%s a %.1f%% da r1 #A57A3F (<= 5)" % [
		ds["dark"] * 100.0, ds["light"] * 100.0, ds["green"] * 100.0, ds["crown"], (ds["color"] as Color).to_html(false).to_upper(), dd * 100.0])
	if ds["dark"] < 0.25 or ds["dark"] > 0.35 or ds["light"] > 0.1 or ds["green"] < 0.02 or ds["green"] > 0.05 or ds["crown"] > 3.0 or dd > 0.05:
		_fail("decals/arena_dirt: fora dos critérios r2")
	var sl: Image = PL.load_tex("decals/arena_slabs")
	for k: int in 8:
		var st: Dictionary = PL.slab_stats(sl, Rect2i((k % 4) * 256, (k / 4) * 256, 256, 256))
		var cd: float = PL.cdist(st["contact"], Color("#534030"))
		print("r2 arena_slabs célula %d: topo claro %.0f%% da pedra (>= 20), sombra de contato #%s a %.1f%% de #534030 (<= 10)" % [k, float(st["light"]) * 100.0, (st["contact"] as Color).to_html(false).to_upper(), cd * 100.0])
		if float(st["light"]) < 0.2 or cd > 0.1:
			_fail("decals/arena_slabs: célula %d fora dos critérios r2" % k)


## Leva 2: critério (f2) das nuvens e conferências de forma dos atlas.
func _check_leva2() -> void:
	var st: Dictionary = CA.cloud_stats(PL.load_tex("sky/cloud_puffs"))
	var base: Color = st["base"]
	var db: float = minf(PL.cdist(base, Color("#9C9CB8")), PL.cdist(base, Color("#8C8498")))
	print("leva 2 sky/cloud_puffs: L >= 235 em %.0f%% dos opacos (>= 15), base (quinto de baixo) #%s a %.1f%% de #9C9CB8/#8C8498 (<= 12)" % [float(st["white"]) * 100.0, base.to_html(false).to_upper(), db * 100.0])
	if float(st["white"]) < 0.15 or db > 0.12:
		_fail("sky/cloud_puffs: branco do topo ou base lavanda fora do critério (f2)")
	# névoa e nuvens: alfa 0 na borda do quadro (o puff nunca aparece cortado)
	for rel: String in ["fx/mist_puff", "sky/cloud_puffs"]:
		var img: Image = PL.load_tex(rel)
		var w: int = img.get_width()
		var h: int = img.get_height()
		var edge: int = 0
		for x: int in w:
			if img.get_pixel(x, 0).a8 > 0 or img.get_pixel(x, h - 1).a8 > 0:
				edge += 1
		for y: int in h:
			if img.get_pixel(0, y).a8 > 0 or img.get_pixel(w - 1, y).a8 > 0:
				edge += 1
		print("leva 2 %s: pixels com alfa > 0 na borda do quadro: %d (0)" % [rel, edge])
		if edge > 0:
			_fail(rel + ": puff cortado na borda do quadro")
	# chama: 4 quadros diferentes entre si e com o pé na parte de baixo do quadro
	var fire: Image = PL.load_tex("fx/fire_flipbook")
	var diffs: PackedStringArray = []
	for k: int in 4:
		var a: Image = fire.get_region(Rect2i(k * 128, 0, 128, 192))
		var b: Image = fire.get_region(Rect2i(((k + 1) % 4) * 128, 0, 128, 192))
		var dsum: float = 0.0
		for y: int in 192:
			for x: int in 128:
				dsum += absf(a.get_pixel(x, y).a - b.get_pixel(x, y).a)
		diffs.append("%.1f%%" % (dsum / (128.0 * 192.0) * 100.0))
	print("leva 2 fx/fire_flipbook: diferença de alfa entre quadros vizinhos (laço 0-1-2-3-0): " + ", ".join(diffs))


## Seeds literais e nada de randomize()/rand global nos geradores.
func _check_scripts() -> void:
	var re_rand := RegEx.create_from_string("(?<![\\w.])(randomize|randi|randf|randi_range|randf_range)\\s*\\(")
	var re_time := RegEx.create_from_string("Time\\.|get_ticks|get_unix_time")
	for path: String in SCRIPTS:
		var src: String = FileAccess.get_file_as_string(path)
		var ln: int = 0
		for line: String in src.split("\n"):
			ln += 1
			var code: String = line.split("#")[0]
			if re_rand.search(code) != null:
				_fail("%s:%d: sorteio global (%s)" % [path.get_file(), ln, line.strip_edges()])
			if re_time.search(code) != null:
				_fail("%s:%d: depende do relógio (%s)" % [path.get_file(), ln, line.strip_edges()])
	print("geradores: sem randomize/rand global e sem relógio (%d scripts)" % SCRIPTS.size())
