extends SceneTree
## A06: prévias (docs/art-preview/a06-chao.png, a06-muro.png, a06-folhagem-props.png).
## Lê os PNG já gravados pelos outros geradores a06 e monta as ampliações e as maquetes.
## Rodar depois de gen_a06_chao, gen_a06_muro e gen_a06_folhagem:
##   "$G" --headless --path . --script tools/art/gen_a06_preview.gd

const K = preload("res://tools/art/a06_lib.gd")
const L = K.L

const BG: Color = Color(0.36, 0.36, 0.38)
const FG: Color = Color(0.95, 0.95, 0.95)
const REF: String = "res://docs/reference/Gemini_Generated_Image_6oy5mo6oy5mo6oy5.jpg"


func _initialize() -> void:
	_chao()
	_muro()
	_folhagem()
	print("A06 PREVIEW: 3 prévias gravadas")
	quit(0)


func _ref_crop(x: int, y: int, w: int, h: int, out_w: int) -> Image:
	var img: Image = Image.load_from_file(ProjectSettings.globalize_path(REF))
	img.convert(Image.FORMAT_RGBA8)
	var c: Image = img.get_region(Rect2i(x, y, w, h))
	c.resize(out_w, int(float(out_w) * float(h) / float(w)), Image.INTERPOLATE_LANCZOS)
	return c


func _label(dst: Image, s: String, x: int, y: int) -> void:
	L.text(dst, s, x, y, 2, FG)


func _put(dst: Image, src: Image, x: int, y: int, name: String) -> void:
	_label(dst, name, x, y - 14)
	K.over(dst, src, x, y)


# ---------------------------------------------------------------------------
# Chão
# ---------------------------------------------------------------------------

func _chao() -> void:
	var dst: Image = L.new_image(1900, 3200, BG)
	var ga: Image = K.load_tex("ground/ground_grass_arena")
	var gf: Image = K.load_tex("ground/ground_grass_forest")
	_put(dst, K.up(ga, 4), 16, 30, "GROUND_GRASS_ARENA X4")
	_put(dst, K.up(gf, 4), 300, 30, "GROUND_GRASS_FOREST X4")
	_put(dst, K.tile(ga, 4, 3), 600, 30, "ARENA 4X3 (X1)")
	_put(dst, K.tile(gf, 4, 3), 870, 30, "FOREST 4X3 (X1)")

	# Decalques x1 e x2
	var y0: int = 320
	var names: Array[String] = ["decal_grass_light_0", "decal_grass_light_1", "decal_grass_light_2", "decal_grass_dark_0", "decal_grass_dark_1", "decal_forest_soil_0", "decal_forest_soil_1"]
	var x: int = 16
	var yrow: int = y0
	var rowh: int = 0
	for n: String in names:
		var im: Image = K.load_tex("decals/" + n)
		var big: Image = K.up(im, 2)
		if x + big.get_width() + 16 > 1880:
			x = 16
			yrow += rowh + 40
			rowh = 0
		_put(dst, big, x, yrow, n.to_upper() + " X2")
		x += big.get_width() + 20
		rowh = maxi(rowh, big.get_height())
	yrow += rowh + 40
	var dirt: Image = K.load_tex("decals/decal_arena_dirt")
	var bgd: Image = L.new_image(448, 352, BG)
	K.over(bgd, dirt, 0, 0)
	_put(dst, bgd, 16, yrow, "DECAL_ARENA_DIRT X1")
	var small: Image = L.new_image(1200, 352, BG)
	var xs: int = 0
	for n: String in names:
		var im2: Image = K.load_tex("decals/" + n)
		if xs + im2.get_width() > 1200:
			break
		K.over(small, im2, xs, 0)
		xs += im2.get_width() + 8
	_put(dst, small, 490, yrow, "OUTROS DECALQUES X1")
	yrow += 400

	# Maquete da arena: 20 x 18 a x1 e recorte da referência ao lado
	var mq: Image = K.tile(ga, 10, 9)
	var dx: int = 96
	var dy: int = 112
	K.over(mq, K.load_tex("decals/decal_grass_dark_1"), 20, 92)
	K.over(mq, K.load_tex("decals/decal_grass_light_0"), 420, 14)
	K.over(mq, K.load_tex("decals/decal_grass_light_1"), 24, 400)
	K.over(mq, K.load_tex("decals/decal_grass_dark_0"), 470, 430)
	K.over(mq, K.load_tex("decals/decal_grass_light_2"), 300, 500)
	K.over(mq, dirt, dx, dy)
	_put(dst, mq, 16, yrow, "MAQUETE DA ARENA 20X18 (X1)")
	var rc: Image = _ref_crop(850, 560, 1250, 640, 1100)
	_put(dst, rc, 700, yrow, "REFERENCIA: CLAREIRA")
	yrow += 620

	# Trilha: 4 variantes encadeadas (12 unidades) + curva, sobre grama de fora
	var strip: Image = K.tile(gf, 12, 6)
	strip = strip.get_region(Rect2i(0, 0, 768, 288))
	var chain: Image = L.new_image(768, 288)
	chain.blit_rect(strip, Rect2i(0, 0, 768, 288), Vector2i(0, 0))
	var order: Array[int] = [2, 0, 3, 1]
	for i: int in 4:
		K.over(chain, K.load_tex("decals/decal_trail_%d" % order[i]), i * 96, 0)
	var bend: Image = K.load_tex("decals/decal_trail_bend")
	K.over(chain, bend, 384, 0)
	var rot: Image = K.load_tex("decals/decal_trail_1")
	rot.rotate_90(CLOCKWISE)
	K.over(chain, rot, 384, 96)
	var rot2: Image = K.load_tex("decals/decal_trail_3")
	rot2.rotate_90(CLOCKWISE)
	K.over(chain, rot2, 384, 192)
	_put(dst, K.up(chain, 2), 16, yrow, "TRILHA ENCADEADA 12 UN. + CURVA E GIRADA (X2)")
	dst = dst.get_region(Rect2i(0, 0, 1900, yrow + 600))
	K.save_png(dst, K.PREVIEW + "a06-chao.png")


func _flip_x(img: Image) -> Image:
	var o: Image = img.duplicate()
	o.flip_x()
	return o


func _tile_w(img: Image, w: int) -> Image:
	var o: Image = L.new_image(w, img.get_height())
	var x: int = 0
	while x < w:
		o.blit_rect(img, Rect2i(0, 0, mini(img.get_width(), w - x), img.get_height()), Vector2i(x, 0))
		x += img.get_width()
	return o


func _muro() -> void:
	var dst: Image = L.new_image(1900, 3000, BG)
	var face: Image = K.load_tex("wall/wall_high_face")
	var low: Image = K.load_tex("wall/wall_low_face")
	var crest: Image = K.load_tex("wall/wall_crest")
	var cap: Image = K.load_tex("wall/wall_cap")
	var quoin: Image = K.load_tex("wall/wall_quoin")
	var ccorner: Image = K.load_tex("wall/wall_crest_corner")
	var capc: Image = K.load_tex("wall/wall_cap_corner")
	var t0: Image = K.load_tex("wall/stair_tread_0")
	var t1: Image = K.load_tex("wall/stair_tread_1")
	var r0: Image = K.load_tex("wall/stair_riser_0")
	var r1: Image = K.load_tex("wall/stair_riser_1")
	var d0: Image = K.load_tex("cards/moss_drape_0")
	var d1: Image = K.load_tex("cards/moss_drape_1")
	var y: int = 30
	# texturas: tiras x2, peças pequenas x4
	_put(dst, K.up(face, 3), 16, y, "WALL_HIGH_FACE X3")
	_put(dst, K.up(K.load_tex("wall/wall_high_face_n"), 2), 800, y, "WALL_HIGH_FACE_N X2")
	y += 160
	_put(dst, K.up(low, 3), 16, y, "WALL_LOW_FACE X3")
	_put(dst, K.up(cap, 3), 800, y, "WALL_CAP X3")
	y += 80
	_put(dst, K.up(crest, 3), 16, y, "WALL_CREST X3")
	_put(dst, K.up(quoin, 4), 800, y, "WALL_QUOIN X4")
	_put(dst, K.up(ccorner, 4), 950, y, "CREST_CORNER X4")
	_put(dst, K.up(capc, 4), 1100, y, "CAP_CORNER X4")
	y += 230
	_put(dst, K.up(t0, 4), 16, y, "STAIR_TREAD_0 X4")
	_put(dst, K.up(t1, 4), 430, y, "STAIR_TREAD_1 X4")
	_put(dst, K.up(r0, 4), 850, y, "STAIR_RISER_0 X4")
	_put(dst, K.up(r1, 4), 1250, y, "STAIR_RISER_1 X4")
	y += 100
	_put(dst, K.up(d0, 4), 16, y, "MOSS_DRAPE_0 X4")
	_put(dst, K.up(d1, 4), 560, y, "MOSS_DRAPE_1 X4")
	y += 100

	# Elevação do muro alto (12 unidades = 384 px), x2: crista de cima + face externa 1,5 + cortinas
	var hi: Image = L.new_image(384, 80 + 8)
	hi.blit_rect(_tile_w(crest, 384), Rect2i(0, 0, 384, 32), Vector2i(0, 0))
	hi.blit_rect(_tile_w(face, 384), Rect2i(0, 0, 384, 48), Vector2i(0, 32))
	K.over(hi, d0, 0, 32)
	K.over(hi, d1, 128, 32)
	K.over(hi, d0, 256, 32)
	# degrau baixo: capeamento + face 0,5
	var lo: Image = L.new_image(384, 32)
	lo.blit_rect(_tile_w(cap, 384), Rect2i(0, 0, 384, 16), Vector2i(0, 0))
	lo.blit_rect(_tile_w(low, 384), Rect2i(0, 0, 384, 16), Vector2i(0, 16))
	# face interna (1,0): so as linhas 0 a 31
	var inner: Image = L.new_image(384, 32)
	inner.blit_rect(_tile_w(face, 384), Rect2i(0, 0, 384, 32), Vector2i(0, 0))
	# quina: face + quoin | quoin espelhado + face
	var corner: Image = L.new_image(320, 48 + 32)
	corner.blit_rect(_tile_w(face, 128), Rect2i(0, 0, 128, 48), Vector2i(0, 32))
	corner.blit_rect(quoin, Rect2i(0, 0, 32, 48), Vector2i(128, 32))
	var qf: Image = _flip_x(quoin)
	corner.blit_rect(qf, Rect2i(0, 0, 32, 48), Vector2i(160, 32))
	var ff: Image = _flip_x(_tile_w(face, 128))
	corner.blit_rect(ff, Rect2i(0, 0, 128, 48), Vector2i(192, 32))
	corner.blit_rect(_tile_w(crest, 128), Rect2i(0, 0, 128, 32), Vector2i(0, 0))
	corner.blit_rect(ccorner, Rect2i(0, 0, 32, 32), Vector2i(128, 0))
	K.over(corner, ccorner, 160, 0)
	corner.blit_rect(_tile_w(crest, 128), Rect2i(0, 0, 128, 32), Vector2i(192, 0))
	# escada: lance de 3 unidades, degraus de 0,25 (espelho) e 0,5 (piso), 2 variantes
	var st: Image = L.new_image(96, 8 * 4 + 16 * 3 + 8)
	var sy: int = 0
	var rr: Array[Image] = [r0, r1, r0, r1]
	var tt: Array[Image] = [t0, t1, t1, t0]
	for k: int in 3:
		st.blit_rect(tt[k], Rect2i(0, 0, 96, 16), Vector2i(0, sy))
		sy += 16
		st.blit_rect(rr[k], Rect2i(0, 0, 96, 8), Vector2i(0, sy))
		sy += 8
	_put(dst, K.up(hi, 2), 16, y, "ELEVACAO MURO ALTO 12 UN. (X2): CRISTA + FACE 1,5 + CORTINAS")
	var rf: Image = _ref_crop(1040, 1100, 860, 290, 768)
	_put(dst, rf, 840, y, "REFERENCIA: MURO DA FRENTE")
	y += 280
	_put(dst, K.up(lo, 2), 16, y, "DEGRAU BAIXO: CAPEAMENTO + FACE 0,5 (X2)")
	_put(dst, K.up(inner, 2), 800, y, "FACE INTERNA 1,0 = LINHAS 0-31 (X2)")
	y += 100
	_put(dst, K.up(corner, 2), 16, y, "QUINA: QUOIN + CREST_CORNER (X2)")
	_put(dst, K.up(st, 3), 800, y, "LANCE DE ESCADA 3 UN. (X3)")
	y += 260
	var ref2: Image = _ref_crop(560, 1080, 520, 420, 520)
	_put(dst, ref2, 16, y, "REFERENCIA: ESCADA E QUINA")
	y += 440
	dst = dst.get_region(Rect2i(0, 0, 1900, y))
	K.save_png(dst, K.PREVIEW + "a06-muro.png")


func _folhagem() -> void:
	var dst: Image = L.new_image(1900, 2400, BG)
	var y: int = 30
	var x: int = 16
	var fams: Array[String] = ["green", "olive", "cool"]
	for f: String in fams:
		_put(dst, K.up(K.load_tex("foliage/leaf_mass_" + f), 4), x, y, "LEAF_MASS_" + f.to_upper() + " X4")
		x += 280
	x += 20
	for f2: String in fams:
		_put(dst, K.up(K.load_tex("foliage/leaf_shell_" + f2), 4), x, y, "LEAF_SHELL_" + f2.to_upper() + " X4")
		x += 280
	y += 300
	x = 16
	_put(dst, K.up(K.load_tex("foliage/leaf_shell_cool_flower"), 4), x, y, "LEAF_SHELL_COOL_FLOWER X4")
	x += 280
	# casca sobre o miolo da mesma familia (2x2 repeticoes, x3)
	for f3: String in fams:
		var mass: Image = K.tile(K.load_tex("foliage/leaf_mass_" + f3), 2, 2)
		var shell: Image = K.tile(K.load_tex("foliage/leaf_shell_" + f3), 2, 2)
		var comp: Image = mass.duplicate()
		K.over(comp, shell, 0, 0)
		_put(dst, K.up(comp, 3), x, y, "CASCA SOBRE MIOLO " + f3.to_upper() + " X3")
		x += 410
	y += 400
	x = 16
	var mass2: Image = K.tile(K.load_tex("foliage/leaf_mass_cool"), 2, 2)
	var shell2: Image = K.tile(K.load_tex("foliage/leaf_shell_cool_flower"), 2, 2)
	K.over(mass2, shell2, 0, 0)
	_put(dst, K.up(mass2, 3), x, y, "ARBUSTO FLORIDO X3")
	var need: Image = K.load_tex("foliage/conifer_needles")
	var fr: Image = K.load_tex("foliage/conifer_fringe")
	_put(dst, K.up(K.tile(need, 2, 1), 4), 420, y, "CONIFER_NEEDLES X4 (2 REPETICOES)")
	_put(dst, K.up(fr, 4), 420, y + 180, "CONIFER_FRINGE X4")
	# andar de conifera montado: agulhas + franja embaixo (x3), tres repeticoes
	var tier: Image = L.new_image(192, 32 + 16, BG)
	tier.blit_rect(K.tile(need, 3, 1), Rect2i(0, 0, 192, 32), Vector2i(0, 0))
	K.over(tier, fr.get_region(Rect2i(0, 0, 128, 16)), 0, 28)
	K.over(tier, fr.get_region(Rect2i(0, 0, 64, 16)), 128, 28)
	_put(dst, K.up(tier, 4), 1000, y, "ANDAR DE CONIFERA: AGULHAS + FRANJA X4")
	y += 430
	x = 16
	_put(dst, K.up(K.load_tex("props/log_bark"), 4), x, y, "LOG_BARK X4")
	_put(dst, K.up(K.load_tex("props/log_bark_n"), 2), x, y + 150, "LOG_BARK_N X2")
	x += 290
	_put(dst, K.up(K.load_tex("props/crate_side"), 4), x, y, "CRATE_SIDE X4")
	x += 120
	_put(dst, K.up(K.load_tex("props/crate_top"), 4), x, y, "CRATE_TOP X4")
	x += 120
	_put(dst, K.up(K.load_tex("props/wood_pile_end"), 4), x, y, "WOOD_PILE_END X4")
	x += 150
	var lg: Image = K.tile(K.load_tex("props/log_bark"), 3, 1)
	_put(dst, K.up(lg, 3), x, y, "TRONCO CAIDO 6 UN. (X3)")
	y += 230
	_put(dst, _ref_crop(850, 1300, 700, 236, 700), 16, y, "REFERENCIA: COPAS DA FRENTE")
	_put(dst, _ref_crop(0, 0, 640, 560, 560), 740, y, "REFERENCIA: CONIFERAS")
	y += 580
	dst = dst.get_region(Rect2i(0, 0, 1900, y))
	K.save_png(dst, K.PREVIEW + "a06-folhagem-props.png")
