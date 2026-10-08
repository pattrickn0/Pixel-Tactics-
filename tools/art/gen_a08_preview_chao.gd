extends SceneTree
## A08: prévia do chão (docs/art-preview/a08-chao.png). Lê os PNG já gerados por gen_a08_chao.gd.
##   "$G" --headless --path . --script tools/art/gen_a08_preview_chao.gd

const PL = preload("res://tools/art/paint_lib.gd")

const BG := Color("#5a5a60")
const FG := Color("#f0ece4")
const ARENA := Vector2(20.0, 18.0)
const DIRT_POS := Vector2(0.3, -1.0)
const RING_POS := Vector2(0.4, -0.9)
# Pedras compridas do anel externo: [célula, ângulo (graus, 0 = leste, 90 = sul), raio]
const RING_STONES: Array = [[0, -150.0, 4.2], [1, -62.0, 3.8], [3, 8.0, 4.3], [2, 58.0, 3.6], [4, 128.0, 4.0]]
# Lajes gastas e pedrinhas: [célula, x, z, giro em graus]
const LOOSE: Array = [[5, -4.6, -0.3, 20.0], [5, -3.6, 1.0, -35.0], [5, 4.6, -3.2, 70.0], [6, -2.2, 2.6, 0.0], [7, 3.2, 1.9, 40.0], [6, 5.4, 0.8, 120.0], [7, -5.6, -2.6, 200.0]]
# Recorte da referência (906x509) que mostra a arena, e a escala dela (px por unidade, aprox.)
const REF_ARENA := Rect2i(292, 212, 338, 154)
const REF_DIRT := Rect2i(345, 255, 200, 70)


func _initialize() -> void:
	var ga: Image = PL.load_tex("ground/grass_a")
	var gb: Image = PL.load_tex("ground/grass_b")
	var mask: Image = PL.load_tex("ground/blend_mask")
	var dirt: Image = PL.load_tex("decals/arena_dirt")
	var ring: Image = PL.load_tex("decals/arena_ring")
	var slabs: Image = PL.load_tex("decals/arena_slabs")
	var ref: Image = PL.load_ref()
	var blocks: Array = []
	# 1. Grama a e b misturadas pela máscara, mosaico 3 x 3 (24 x 24 unidades), em 32 px/u
	var mos: Image = _ground(ga, gb, mask, Vector2(24, 24), 32.0, Vector2(-12, -12))
	var row1: Image = _hcat([_labeled(PL.scaled(ga, 0.75), "GRASS_A 512 (8X8 U) 75%"), _labeled(PL.scaled(gb, 0.75), "GRASS_B 512 75%"),
		_labeled(_mask_view(mask), "BLEND_MASK 256 (R / G / B) X1.5"), _labeled(mos, "A+B PELA MASCARA, MOSAICO 3X3 (24X24 U) 32 PX/U")])
	blocks.append(row1)
	# 2. Maquete de cima (arena 20 x 18) em 32 px/u e recorte da referência ampliado
	var top: Image = _arena_mock(ga, gb, mask, dirt, ring, slabs, 32.0)
	var ref_top: Image = ref.get_region(REF_ARENA)
	ref_top = PL.scaled(ref_top, 640.0 / float(REF_ARENA.size.x), Image.INTERPOLATE_LANCZOS)
	var row2: Image = _hcat([_labeled(top, "MAQUETE DE CIMA: ARENA 20X18, 32 PX/U (TERRA + CIRCULO + PEDRAS)"), _labeled(ref_top, "REFERENCIA: A ARENA (RECORTE AMPLIADO)"),
		_labeled(_decals_view(dirt, ring, slabs), "DECALQUES SOBRE CINZA: ARENA_DIRT 50%, ARENA_RING 100%, ARENA_SLABS 50%")])
	blocks.append(row2)
	# 3. Maquete a 27 graus (Z achatado por sin 27 = 0,45) na escala da referência no meio da arena
	# (a parede interna oeste-leste da arena mede ~303 px para 20 u: ~15,2 px/u)
	var s: float = 15.2
	var m27: Image = _arena_mock(ga, gb, mask, dirt, ring, slabs, s)
	m27.resize(m27.get_width(), roundi(m27.get_height() * sin(deg_to_rad(27.0))), Image.INTERPOLATE_LANCZOS)
	var ref_c: Image = ref.get_region(REF_ARENA)
	# Estatística: só os pixels de cor de terra, na janela da mancha
	var mock_dirt_rc := Rect2i(roundi((10.0 + DIRT_POS.x - 7.0) * s), roundi((9.0 + DIRT_POS.y - 5.4) * s * 0.454), roundi(14.0 * s), roundi(10.8 * s * 0.454))
	var st_m: Dictionary = PL.lum_stats(m27, mock_dirt_rc, true)
	var ref_dirt_rc := Rect2i(REF_DIRT.position - REF_ARENA.position, REF_DIRT.size)
	var st_r: Dictionary = PL.lum_stats(ref_c, ref_dirt_rc, true)
	var k: float = 2.5
	var m27b: Image = PL.scaled(m27, k, Image.INTERPOLATE_LANCZOS)
	var refb: Image = PL.scaled(ref_c, k, Image.INTERPOLATE_LANCZOS)
	PL.frame(m27b, Rect2i(Vector2i(Vector2(mock_dirt_rc.position) * k), Vector2i(Vector2(mock_dirt_rc.size) * k)), Color("#00e5ff"), 2)
	PL.frame(refb, Rect2i(Vector2i(Vector2(ref_dirt_rc.position) * k), Vector2i(Vector2(ref_dirt_rc.size) * k)), Color("#00e5ff"), 2)
	var lab_m: String = "MAQUETE 27 GRAUS (ALBEDO, SEM LUZ) 15 PX/U X2.5: TERRA L MEDIA %.0f DESVIO %.1f COR #%s" % [st_m["mean"], st_m["std"], (st_m["color"] as Color).to_html(false).to_upper()]
	var lab_r: String = "REFERENCIA X2.5: TERRA L MEDIA %.0f DESVIO %.1f COR #%s" % [st_r["mean"], st_r["std"], (st_r["color"] as Color).to_html(false).to_upper()]
	blocks.append(_hcat([_labeled(m27b, lab_m), _labeled(refb, lab_r)]))
	print("27 graus: maquete L %.1f desvio %.1f #%s | referência L %.1f desvio %.1f #%s" % [st_m["mean"], st_m["std"], (st_m["color"] as Color).to_html(false), st_r["mean"], st_r["std"], (st_r["color"] as Color).to_html(false)])
	# 4. (r1) Grama na escala da câmera: grass_a e grass_b reduzidas a 1/3 (~21 px/u), 2 x 2, ao lado da
	# grama da arena da referência (caixa da frente), com desvio de L, |L - desfoque σ4| e L médio
	var grow: Array = []
	for e: Array in [["GRASS_A", ga], ["GRASS_B", gb]]:
		var im: Image = e[1]
		var m: Dictionary = PL.camera_metrics(im)
		var small: Image = PL.tiled(im, 2, 2)
		small.resize(roundi(1024 / 3.0), roundi(1024 / 3.0), Image.INTERPOLATE_LANCZOS)
		grow.append(_labeled(PL.scaled(small, 2.0, Image.INTERPOLATE_NEAREST), "%s A 1/3 (X2 NA TELA): DESVIO %.1f, DETALHE %.1f, L %.0f" % [e[0], m["std"], m["detail"], m["mean"]]))
	var ref_grass: Image = ref.get_region(Rect2i(297, 318, 128, 36))
	var mr: Dictionary = PL.camera_metrics(ref_grass, 1.0, false)
	grow.append(_labeled(PL.scaled(ref_grass, 4.0, Image.INTERPOLATE_NEAREST), "REFERENCIA GRAMA DA ARENA (FRENTE) X4: DESVIO %.1f, DETALHE %.1f, L %.0f" % [mr["std"], mr["detail"], mr["mean"]]))
	print("grama a 1/3 vs referência: ver a08-chao.png (ref: desvio %.1f, detalhe %.1f, L %.1f)" % [mr["std"], mr["detail"], mr["mean"]])
	blocks.append(_hcat(grow))
	var out: Image = _vcat(blocks)
	PL.text(out, "A08 LEVA 1 (R1) - CHAO. JANELA CIANO = PIXELS DE TERRA DA MEDIA E DO DESVIO. DETALHE = MEDIA DE |L - DESFOQUE GAUSSIANO 4 PX|", 12, out.get_height() - 22, 2, FG)
	PL.save_png(out, PL.PREVIEW + "a08-chao.png")
	quit()


## Chão de grama: grass_a/grass_b (64 px/u, 8 u por quadro) misturadas pela máscara (R, 32 u por quadro).
func _ground(ga: Image, gb: Image, mask: Image, size_u: Vector2, s: float, origin: Vector2) -> Image:
	var tile_px: int = roundi(8.0 * s)
	var a: Image = ga.duplicate()
	a.resize(tile_px, tile_px, Image.INTERPOLATE_LANCZOS)
	var b: Image = gb.duplicate()
	b.resize(tile_px, tile_px, Image.INTERPOLATE_LANCZOS)
	var w: int = roundi(size_u.x * s)
	var h: int = roundi(size_u.y * s)
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y: int in h:
		for x: int in w:
			var wx: float = origin.x + (x + 0.5) / s
			var wz: float = origin.y + (y + 0.5) / s
			var tx: int = posmod(floori(wx * s), tile_px)
			var ty: int = posmod(floori(wz * s), tile_px)
			var mx: int = posmod(floori(wx / 32.0 * 256.0), 256)
			var my: int = posmod(floori(wz / 32.0 * 256.0), 256)
			var t: float = mask.get_pixel(mx, my).r
			out.set_pixel(x, y, a.get_pixel(tx, ty).lerp(b.get_pixel(tx, ty), t))
	return out


func _arena_mock(ga: Image, gb: Image, mask: Image, dirt: Image, ring: Image, slabs: Image, s: float) -> Image:
	var img: Image = _ground(ga, gb, mask, ARENA, s, -ARENA * 0.5)
	var ctr := ARENA * 0.5
	_place(img, dirt, (ctr + DIRT_POS) * s, 0.0, s / 64.0)
	_place(img, ring, (ctr + RING_POS) * s, 0.0, s / 64.0)
	for e: Array in RING_STONES:
		var ang: float = deg_to_rad(float(e[1]))
		var p: Vector2 = ctr + RING_POS + Vector2(cos(ang), sin(ang)) * float(e[2])
		_place(img, _cell(slabs, int(e[0])), p * s, ang + PI * 0.5, s / 64.0)
	for e: Array in LOOSE:
		_place(img, _cell(slabs, int(e[0])), (ctr + Vector2(e[1], e[2])) * s, deg_to_rad(float(e[3])), s / 64.0)
	return img


func _cell(atlas: Image, k: int) -> Image:
	return atlas.get_region(Rect2i((k % 4) * 256, (k / 4) * 256, 256, 256))


## Cola src (com alfa) centrado em c, girado por ang e escalado por k (amostragem bilinear inversa).
func _place(dst: Image, src: Image, c: Vector2, ang: float, k: float) -> void:
	var sw: float = src.get_width()
	var sh: float = src.get_height()
	var src_s: Image = src.duplicate()
	if k < 0.75:
		src_s.resize(maxi(1, roundi(sw * k * 1.5)), maxi(1, roundi(sh * k * 1.5)), Image.INTERPOLATE_LANCZOS)
	var ks: float = src_s.get_width() / sw
	var rad: float = 0.5 * sqrt(sw * sw + sh * sh) * k + 2.0
	var cs: float = cos(-ang)
	var sn: float = sin(-ang)
	for y: int in range(maxi(0, floori(c.y - rad)), mini(dst.get_height(), ceili(c.y + rad))):
		for x: int in range(maxi(0, floori(c.x - rad)), mini(dst.get_width(), ceili(c.x + rad))):
			var d := Vector2(x + 0.5 - c.x, y + 0.5 - c.y) / k
			var q := Vector2(d.x * cs - d.y * sn, d.x * sn + d.y * cs) + Vector2(sw, sh) * 0.5
			if q.x < 0.0 or q.y < 0.0 or q.x >= sw or q.y >= sh:
				continue
			var sc: Color = _bilinear(src_s, q * ks)
			if sc.a <= 0.0:
				continue
			var dc: Color = dst.get_pixel(x, y)
			dst.set_pixel(x, y, Color(dc.r + (sc.r - dc.r) * sc.a, dc.g + (sc.g - dc.g) * sc.a, dc.b + (sc.b - dc.b) * sc.a, 1.0))


func _bilinear(img: Image, p: Vector2) -> Color:
	var x: float = p.x - 0.5
	var y: float = p.y - 0.5
	var x0: int = clampi(floori(x), 0, img.get_width() - 1)
	var y0: int = clampi(floori(y), 0, img.get_height() - 1)
	var x1: int = mini(x0 + 1, img.get_width() - 1)
	var y1: int = mini(y0 + 1, img.get_height() - 1)
	var fx: float = clampf(x - floorf(x), 0.0, 1.0)
	var fy: float = clampf(y - floorf(y), 0.0, 1.0)
	var c00: Color = img.get_pixel(x0, y0)
	var c10: Color = img.get_pixel(x1, y0)
	var c01: Color = img.get_pixel(x0, y1)
	var c11: Color = img.get_pixel(x1, y1)
	# alfa pré-multiplicado na interpolação (sem halo)
	var a: float = lerpf(lerpf(c00.a, c10.a, fx), lerpf(c01.a, c11.a, fx), fy)
	if a <= 0.0:
		return Color(0, 0, 0, 0)
	var r: float = lerpf(lerpf(c00.r * c00.a, c10.r * c10.a, fx), lerpf(c01.r * c01.a, c11.r * c11.a, fx), fy) / a
	var g: float = lerpf(lerpf(c00.g * c00.a, c10.g * c10.a, fx), lerpf(c01.g * c01.a, c11.g * c11.a, fx), fy) / a
	var b: float = lerpf(lerpf(c00.b * c00.a, c10.b * c10.a, fx), lerpf(c01.b * c01.a, c11.b * c11.a, fx), fy) / a
	return Color(r, g, b, a)


func _mask_view(mask: Image) -> Image:
	var out := Image.create(mask.get_width() * 3 + 16, mask.get_height(), false, Image.FORMAT_RGBA8)
	out.fill(BG)
	for ch: int in 3:
		for y: int in mask.get_height():
			for x: int in mask.get_width():
				var c: Color = mask.get_pixel(x, y)
				var v: float = c.r if ch == 0 else (c.g if ch == 1 else c.b)
				out.set_pixel(x + ch * (mask.get_width() + 8), y, Color(v, v, v))
	return PL.scaled(out, 1.5)


func _decals_view(dirt: Image, ring: Image, slabs: Image) -> Image:
	var d: Image = PL.on_bg(PL.scaled(dirt, 0.5), Color("#808080"))
	var r: Image = PL.on_bg(ring, Color("#808080"))
	var s: Image = PL.on_bg(PL.scaled(slabs, 0.5), Color("#808080"))
	var top: Image = _hcat([d, r])
	return _vcat([top, s])


func _labeled(img: Image, label: String) -> Image:
	var out := Image.create(maxi(img.get_width(), PL.text_width(label, 2)), img.get_height() + 18, false, Image.FORMAT_RGBA8)
	out.fill(BG)
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
	out.fill(BG)
	var x: int = 12
	for im: Image in imgs:
		out.blit_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i(x, 12))
		x += im.get_width() + 12
	return out


func _vcat(imgs: Array) -> Image:
	var w: int = 0
	var h: int = 30
	for im: Image in imgs:
		w = maxi(w, im.get_width())
		h += im.get_height()
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	out.fill(BG)
	var y: int = 0
	for im: Image in imgs:
		out.blit_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i(0, y))
		y += im.get_height()
	return out
