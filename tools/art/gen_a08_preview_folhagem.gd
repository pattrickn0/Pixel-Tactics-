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
	var canopy: Image = _canopy([warm, mid], bark, 9101)
	var canopy_c: Image = _canopy([cool, mid], bark, 9102)
	var ref_can: Image = PL.scaled(ref.get_region(REF_CANOPY), 520.0 / 64.0, Image.INTERPOLATE_LANCZOS)
	rows.append(_hcat([_labeled(canopy, "MONTAGEM DE COPA: 40 TUFOS WARM+MID, TINTA POR ALTURA"), _labeled(canopy_c, "COPA COOL+MID"),
		_labeled(ref_can, "REFERENCIA: COPA AO SOL (LESTE) X8")]))
	var tree: Image = _conifer(con, bark)
	var share: float = _light_share(tree, Color("#6E9A3A"))
	print("montagem de conífera: rampa clara em %.0f%% dos pixels da árvore" % (share * 100.0))
	var ref_con: Image = PL.scaled(ref.get_region(REF_CONIFER), 520.0 / 120.0, Image.INTERPOLATE_LANCZOS)
	rows.append(_hcat([_labeled(PL.on_bg(con, BG), "CONIFER_TIERS 1024X512 (0-5 ANDARES, 6-7 PONTAS)"), _labeled(tree, "MONTAGEM DE CONIFERA: RAMPA CLARA (>= #6E9A3A) EM %.0f%%" % (share * 100.0)),
		_labeled(ref_con, "REFERENCIA: CONIFERAS DO LESTE X4.3")]))
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
