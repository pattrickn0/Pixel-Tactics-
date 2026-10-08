extends SceneTree
## A08: prévia da folhagem (docs/art-preview/a08-folhagem.png). Lê os PNG de gen_a08_folhagem.gd.
## Inclui uma montagem 2D de copa (34 tufos de trás para frente) e uma de conífera (andares empilhados),
## com tinta por altura simulando o gradiente do shader, ao lado de recortes da referência.
##   "$G" --headless --path . --script tools/art/gen_a08_preview_folhagem.gd

const PL = preload("res://tools/art/paint_lib.gd")

const BG := Color("#808080")
const PANEL := Color("#5a5a60")
const FG := Color("#f0ece4")
const SKY := Color("#C9D3EA")
const REF_CANOPY := Rect2i(718, 186, 64, 64)
const REF_CONIFER := Rect2i(736, 120, 64, 120)


func _initialize() -> void:
	var warm: Image = PL.load_tex("foliage/leaf_clumps_warm")
	var mid: Image = PL.load_tex("foliage/leaf_clumps_mid")
	var cool: Image = PL.load_tex("foliage/leaf_clumps_cool")
	var con: Image = PL.load_tex("foliage/conifer_tiers")
	var bark: Image = PL.load_tex("foliage/bark")
	var tufts: Image = PL.load_tex("foliage/grass_tufts")
	var flowers: Image = PL.load_tex("foliage/flowers")
	var ref: Image = PL.load_ref()
	var rows: Array = []
	rows.append(_hcat([_labeled(PL.on_bg(PL.scaled(warm, 0.5), BG), "LEAF_CLUMPS_WARM 50%"), _labeled(PL.on_bg(PL.scaled(mid, 0.5), BG), "LEAF_CLUMPS_MID 50%"),
		_labeled(PL.on_bg(PL.scaled(cool, 0.5), BG), "LEAF_CLUMPS_COOL 50%")]))
	# (r2) copas montadas como no jogo (5 lóbulos x 5 cartões grandes, luz da esfera da copa), em 64 px/u e
	# reduzidas a 20 px/u (escala da câmera), com a granulação do miolo ao lado da granulação da referência
	var ref_hd: Image = ref.duplicate()
	ref_hd.resize(1280, 720, Image.INTERPOLATE_LANCZOS)
	var ref_g: Array = []
	for rc: Rect2i in [Rect2i(170, 250, 130, 130), Rect2i(1000, 250, 100, 150), Rect2i(800, 150, 140, 80), Rect2i(990, 290, 160, 210)]:
		ref_g.append("%.2f" % PL.granulation(ref_hd, rc))
	var crow: Array = []
	for e: Array in [[[warm, mid], 9101, "WARM+MID"], [[cool, mid], 9102, "COOL+MID"], [[warm, mid, cool], 9103, "AS 3"]]:
		var cm: Dictionary = PL.crown_montage(e[0], int(e[1]))
		var sm: Image = cm["small"]
		var box: Rect2i = cm["box_in"]
		var sm3: Image = PL.scaled(sm, 3.0, Image.INTERPOLATE_NEAREST)
		PL.frame(sm3, Rect2i(box.position * 3, box.size * 3), Color("#00e5ff"), 2)
		print("copa %s: granulação %.2f (miolo), %.2f (copa inteira)" % [e[2], cm["g_in"], cm["g_all"]])
		crow.append(_labeled(cm["img"], "COPA %s 64 PX/U" % e[2]))
		crow.append(_labeled(sm3, "A 20 PX/U (X3): GRANULACAO %.2f" % cm["g_in"]))
	var ref_can: Image = PL.scaled(ref.get_region(REF_CANOPY), 384.0 / 64.0, Image.INTERPOLATE_LANCZOS)
	crow.append(_labeled(ref_can, "REF. COPA (LESTE) X6; GRANULACAO NAS CAIXAS: " + " ".join(ref_g)))
	rows.append(_hcat(crow))
	var tree: Image = _conifer2(con, bark)
	var share: float = _light_share(tree, Color("#6E9A3A"))
	print("montagem de conífera: rampa clara em %.0f%% dos pixels da árvore" % (share * 100.0))
	var ref_con: Image = PL.scaled(ref.get_region(REF_CONIFER), 520.0 / 120.0, Image.INTERPOLATE_LANCZOS)
	var tstats: PackedStringArray = []
	for k: int in 6:
		var st: Dictionary = PL.tier_stats(con, Rect2i((k % 4) * 256, (k / 4) * 256, 256, 256))
		tstats.append("%d: IOU %.2f %d CACHOS %.1fX" % [k, st["iou"], st["clumps"], st["ratio"]])
	rows.append(_hcat([_labeled(PL.on_bg(con, BG), "CONIFER_TIERS (0-5 ANDARES, 6-7 PONTAS)"),
		_labeled(tree, "MONTAGEM: ALTURA 8 U, BASE 3 U, 7 A 9 CARTOES/ANDAR; CLARA %.0f%%" % (share * 100.0)),
		_labeled(ref_con, "REFERENCIA: CONIFERAS DO LESTE X4.3")]))
	var tl := Image.create(1900, 22, false, Image.FORMAT_RGBA8)
	tl.fill(PANEL)
	PL.text(tl, "ANDARES R2 - " + "  ".join(tstats), 12, 4, 2, FG)
	rows.append(tl)
	var bark_v: Image = PL.tiled(bark, 2, 1)
	var bark_n: Image = PL.load_tex("foliage/bark_n")
	rows.append(_hcat([_labeled(bark_v, "BARK 256X512 REPETIDA 2X1"), _labeled(bark_n, "BARK_N"),
		_labeled(PL.on_bg(PL.scaled(tufts, 1.5), BG), "GRASS_TUFTS 512X256 X1.5 (CIMA: BAIXOS DA ARENA; BAIXO: ALTOS)"),
		_labeled(PL.on_bg(PL.scaled(flowers, 2.0), BG), "FLOWERS 256 X2 (12 GRUPOS, LINHA 4 VAZIA)")]))
	PL.save_png(_vcat(rows), PL.PREVIEW + "a08-folhagem.png")
	quit()


func _cell(atlas: Image, k: int, cell: int, cols: int) -> Image:
	return atlas.get_region(Rect2i((k % cols) * cell, (k / cols) * cell, cell, cell))


## Copa redonda: tufos num hemisfério, de trás para frente; tufos de baixo e de trás mais escuros e frios.
func _canopy(atlases: Array, bark: Image, seed_value: int) -> Image:
	var out := Image.create(520, 520, false, Image.FORMAT_RGBA8)
	out.fill(SKY)
	var trunk: Image = bark.get_region(Rect2i(96, 0, 64, 220))
	trunk.resize(40, 200, Image.INTERPOLATE_LANCZOS)
	out.blend_rect(trunk, Rect2i(0, 0, 40, 200), Vector2i(240, 300))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var items: Array = []
	# miolo: tufos escuros de fundo, para a copa não ter furo
	for k: int in 8:
		var th0: float = TAU * float(k) / 8.0
		items.append([cos(th0) * 0.35, sin(th0) * 0.3, 0.0, rng.randi_range(0, 15), 1 % atlases.size(), 0.55])
	for k: int in 40:
		var th: float = rng.randf() * TAU
		var rr: float = pow(rng.randf(), 0.65)
		var x: float = cos(th) * rr
		var y: float = sin(th) * rr * 0.86
		var z: float = sqrt(maxf(1.0 - rr * rr, 0.0))
		items.append([x, y, z, rng.randi_range(0, 15), rng.randi_range(0, atlases.size() - 1), rng.randf_range(0.42, 0.55)])
	items.sort_custom(func(a: Array, b: Array) -> bool: return float(a[2]) < float(b[2]))
	var light := Vector3(-0.3, 0.75, 0.6).normalized()
	for it: Array in items:
		var atlas: Image = atlases[int(it[4])]
		var card: Image = _cell(atlas, int(it[3]), 256, 4)
		var s: float = it[5]
		card.resize(roundi(256 * s), roundi(256 * s), Image.INTERPOLATE_LANCZOS)
		var n := Vector3(float(it[0]), -float(it[1]), float(it[2])).normalized()
		var f: float = 0.6 + 0.5 * clampf(n.dot(light), 0.0, 1.0)
		_tint(card, f)
		var cx: float = 260.0 + float(it[0]) * 165.0
		var cy: float = 210.0 + float(it[1]) * 165.0
		out.blend_rect(card, Rect2i(0, 0, card.get_width(), card.get_height()), Vector2i(roundi(cx - card.get_width() * 0.5), roundi(cy - card.get_height() * 0.5)))
	return out


func _conifer(con: Image, bark: Image) -> Image:
	var out := Image.create(520, 520, false, Image.FORMAT_RGBA8)
	out.fill(SKY)
	var trunk: Image = bark.get_region(Rect2i(100, 0, 40, 160))
	trunk.resize(26, 120, Image.INTERPOLATE_LANCZOS)
	out.blend_rect(trunk, Rect2i(0, 0, 26, 120), Vector2i(247, 395))
	# do andar mais baixo (célula 0) até a ponta (célula 6); cada andar sobe e encolhe
	var cells: Array = [0, 1, 2, 3, 4, 5, 6]
	var y: float = 455.0
	var s: float = 0.98
	for j: int in cells.size():
		var card: Image = con.get_region(Rect2i((int(cells[j]) % 4) * 256, (int(cells[j]) / 4) * 256, 256, 256))
		var sz: int = roundi(256 * s)
		card.resize(sz, sz, Image.INTERPOLATE_LANCZOS)
		_tint(card, 0.94 + 0.01 * j)
		out.blend_rect(card, Rect2i(0, 0, sz, sz), Vector2i(roundi(260 - sz * 0.5), roundi(y - sz * 0.9)))
		y -= sz * 0.4
		s *= 0.87
	return out


## (r2) Conífera na proporção nova (spec 012-f2): altura 8 u, base 3 u (altura = 2,67 x base), 7 andares
## (células 0..5 + ponta 6) com raios fora de uma reta, 7 a 9 cartões por andar em ângulos variados
## (cartão em pé passando pelo tronco: largura vista = |cos| do ângulo), de trás para frente.
const CON_TIERS: Array = [[1.5, 2.3, 8], [1.36, 3.2, 9], [1.4, 4.05, 7], [1.12, 4.9, 8], [0.98, 5.75, 9], [0.84, 6.6, 7], [0.62, 7.15, 8]]


func _conifer2(con: Image, bark: Image) -> Image:
	var ppu: float = 56.0
	var out := Image.create(400, 520, false, Image.FORMAT_RGBA8)
	out.fill(SKY)
	var base := Vector2(200.0, 505.0)
	var trunk: Image = bark.get_region(Rect2i(100, 0, 40, 160))
	trunk.resize(18, 120, Image.INTERPOLATE_LANCZOS)
	out.blend_rect(trunk, Rect2i(0, 0, 18, 120), Vector2i(191, 395))
	var rng := RandomNumberGenerator.new()
	rng.seed = 9201
	for j: int in CON_TIERS.size():
		var e: Array = CON_TIERS[j]
		var r: float = e[0]
		var y: float = e[1]
		var m: int = e[2]
		var cell_k: int = j if j < 6 else 6
		var src: Image = con.get_region(Rect2i((cell_k % 4) * 256, (cell_k / 4) * 256, 256, 256))
		var cards: Array = []
		for k: int in m:
			var th: float = TAU * float(k) / m + rng.randf_range(-0.21, 0.21)
			cards.append([th, sin(th), r * rng.randf_range(0.85, 1.15), rng.randf() < 0.5])
		cards.sort_custom(func(p: Array, q: Array) -> bool: return float(p[1]) < float(q[1]))
		for cd: Array in cards:
			var cw: int = maxi(8, roundi(2.0 * float(cd[2]) * ppu * maxf(absf(cos(float(cd[0]))), 0.22)))
			var chh: int = roundi(2.0 * float(cd[2]) * ppu)
			var im: Image = src.duplicate()
			if bool(cd[3]):
				im.flip_x()
			im.resize(cw, chh, Image.INTERPOLATE_LANCZOS)
			_tint(im, 0.86 + 0.16 * (0.5 + 0.5 * float(cd[1])))
			var top: float = base.y - y * ppu - chh * 0.1
			out.blend_rect(im, Rect2i(0, 0, cw, chh), Vector2i(roundi(base.x - cw * 0.5), roundi(top)))
	return out


## Fração dos pixels da árvore (cor diferente do céu) com luminância >= a da cor de corte.
func _light_share(img: Image, cut: Color) -> float:
	var lc: float = PL.lum(cut)
	var n: int = 0
	var k: int = 0
	for y: int in img.get_height():
		for x: int in img.get_width():
			var c: Color = img.get_pixel(x, y)
			if PL.cdist(c, SKY) < 0.02 or c.g < c.r:
				continue
			n += 1
			if PL.lum(c) >= lc:
				k += 1
	return float(k) / float(maxi(n, 1))


func _tint(img: Image, f: float) -> void:
	for yy: int in img.get_height():
		for xx: int in img.get_width():
			var cc: Color = img.get_pixel(xx, yy)
			if cc.a > 0.0:
				img.set_pixel(xx, yy, Color(minf(cc.r * f, 1.0), minf(cc.g * f, 1.0), minf(cc.b * f * 0.97, 1.0), cc.a))


func _labeled(img: Image, label: String) -> Image:
	var out := Image.create(maxi(img.get_width(), PL.text_width(label, 2)), img.get_height() + 18, false, Image.FORMAT_RGBA8)
	out.fill(PANEL)
	PL.text(out, label, 0, 2, 2, FG)
	out.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(0, 18))
	return out


func _hcat(imgs: Array) -> Image:
	var w: int = 12
	var h: int = 0
	for im: Image in imgs:
		w += im.get_width() + 12
		h = maxi(h, im.get_height())
	var out := Image.create(w, h + 24, false, Image.FORMAT_RGBA8)
	out.fill(PANEL)
	var x: int = 12
	for im: Image in imgs:
		out.blit_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i(x, 12))
		x += im.get_width() + 12
	return out


func _vcat(imgs: Array) -> Image:
	var w: int = 0
	var h: int = 0
	for im: Image in imgs:
		w = maxi(w, im.get_width())
		h += im.get_height()
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	out.fill(PANEL)
	var y: int = 0
	for im: Image in imgs:
		out.blit_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i(0, y))
		y += im.get_height()
	return out
