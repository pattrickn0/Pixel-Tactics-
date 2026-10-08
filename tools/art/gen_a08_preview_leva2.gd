extends SceneTree
## A08, leva 2: prévias (docs/art-preview/a08-ilha-agua.png, a08-ceu-fx.png, a08-props.png).
## Lê os PNG de gen_a08_ilha.gd, gen_a08_ceu_agua.gd e gen_a08_props.gd e põe cada grupo ao lado do
## recorte equivalente da referência (docs/reference/ilha-flutuante.webp, 906x509).
##   "$G" --headless --path . --script tools/art/gen_a08_preview_leva2.gd

const PL = preload("res://tools/art/paint_lib.gd")
const CA = preload("res://tools/art/gen_a08_ceu_agua.gd")

const PANEL := Color("#5a5a60")
const FG := Color("#f0ece4")
const SKY := Color("#C9D3EA")
const SKY_HI := Color("#8FB0D8")

# Recortes da referência (906x509)
const REF_CLIFF := Rect2i(240, 448, 200, 61)
const REF_ROOTS := Rect2i(40, 330, 140, 179)
const REF_FALL := Rect2i(390, 0, 130, 140)
const REF_RAINBOW := Rect2i(470, 50, 130, 90)
const REF_CLOUD_BL := Rect2i(0, 380, 160, 129)
const REF_CLOUD_R := Rect2i(810, 200, 96, 150)
const REF_TORCH := Rect2i(392, 362, 44, 40)
const REF_BRIDGE := Rect2i(30, 320, 160, 70)
const REF_RUINS := Rect2i(150, 28, 125, 62)
# Caixa "nuvem embaixo à esquerda" da 012 (30, 560, 120, 140 em 1280x720)
const BOX_CLOUD_BL := Rect2i(21, 396, 85, 99)


func _initialize() -> void:
	var ref: Image = PL.load_ref()
	_ilha_agua(ref)
	_ceu_fx(ref)
	_props(ref)
	quit()


func _ref(ref: Image, rc: Rect2i, height: int) -> Image:
	return PL.scaled(ref.get_region(rc), float(height) / rc.size.y, Image.INTERPOLATE_LANCZOS)


func _ilha_agua(ref: Image) -> void:
	var cliff: Image = PL.load_tex("island/cliff")
	var under: Image = PL.load_tex("island/under")
	var rows: Array = []
	rows.append(_hcat([
		_labeled(PL.scaled(PL.tiled(cliff, 2, 2), 0.5), "CLIFF 512 (8X8 U) 2X2 A 50%"),
		_labeled(PL.scaled(PL.load_tex("island/cliff_n"), 0.5), "CLIFF_N 50%"),
		_labeled(PL.scaled(PL.tiled(under, 2, 2), 0.5), "UNDER 2X2 A 50%"),
		_labeled(PL.scaled(PL.load_tex("island/under_n"), 0.5), "UNDER_N 50%"),
		_labeled(_ref(ref, REF_CLIFF, 230), "REFERENCIA: PENHASCO DA FRENTE"),
	]))
	# maquete: face do penhasco (cliff em cima, escurecendo para o fundo) com raízes e cipós pendurados
	var mock := Image.create(640, 512, false, Image.FORMAT_RGBA8)
	mock.fill(SKY)
	var face: Image = PL.scaled(PL.tiled(cliff, 3, 1), 640.0 / 1536.0)
	var und: Image = PL.scaled(PL.tiled(under, 3, 1), 640.0 / 1536.0)
	for y: int in 300:
		for x: int in 640:
			var c: Color
			if y < 200:
				c = face.get_pixel(x, y)
			else:
				c = und.get_pixel(x, y - 200).lerp(SKY, smoothstep(220.0, 300.0, float(y)))
			# escurece e esfria para baixo (o shader faz isso no jogo)
			var k: float = clampf(float(y) / 300.0, 0.0, 1.0)
			mock.set_pixel(x, y, Color(c.r * (1.0 - 0.3 * k), c.g * (1.0 - 0.3 * k), c.b * (1.0 - 0.2 * k)))
	var roots: Image = PL.load_tex("island/roots_hang")
	var vines: Image = PL.load_tex("island/vines_hang")
	for e: Array in [[roots, 0, 40, 0.42], [roots, 2, 330, 0.36], [vines, 1, 180, 0.4], [vines, 3, 470, 0.38], [roots, 3, 560, 0.3], [vines, 0, 90, 0.35]]:
		var strip: Image = (e[0] as Image).get_region(Rect2i(int(e[1]) * 128, 0, 128, 1024))
		strip = PL.scaled(strip, float(e[3]))
		mock.blend_rect(strip, Rect2i(Vector2i.ZERO, strip.get_size()), Vector2i(int(e[2]), 150))
	rows.append(_hcat([
		_labeled(PL.on_bg(PL.scaled(roots, 0.5), SKY), "ROOTS_HANG 512X1024 50% (4 FAIXAS DE 128)"),
		_labeled(PL.on_bg(PL.scaled(vines, 0.5), SKY), "VINES_HANG 512X1024 50%"),
		_labeled(mock, "MAQUETE: FACE + FUNDO + RAIZES E CIPOS"),
		_labeled(_ref(ref, REF_ROOTS, 512), "REFERENCIA: BORDA OESTE"),
	]))
	# cascata: lâmina com espuma no alto e névoa embaixo
	var streaks: Image = PL.load_tex("water/fall_streaks")
	var foam: Image = PL.load_tex("water/fall_foam")
	var mist: Image = PL.load_tex("fx/mist_puff")
	var fall := Image.create(512, 512, false, Image.FORMAT_RGBA8)
	fall.fill(SKY)
	var lam: Image = PL.tiled(streaks, 2, 1)
	fall.blit_rect(lam, Rect2i(0, 0, 512, 512), Vector2i(0, 0))
	var f2: Image = PL.tiled(foam, 1, 1)
	fall.blend_rect(f2, Rect2i(0, 0, 512, 128), Vector2i(0, 0))
	for k: int in 7:
		var m: Image = PL.scaled(mist, 0.9 + 0.15 * (k % 3))
		fall.blend_rect(m, Rect2i(Vector2i.ZERO, m.get_size()), Vector2i(-60 + k * 85, 360 + (k % 2) * 30))
	rows.append(_hcat([
		_labeled(PL.tiled(streaks, 2, 1), "FALL_STREAKS 256X512 2X1"),
		_labeled(PL.on_bg(PL.tiled(foam, 1, 2), SKY_HI), "FALL_FOAM 512X128 (2 COPIAS)"),
		_labeled(PL.on_bg(mist, SKY_HI), "MIST_PUFF 256"),
		_labeled(fall, "MAQUETE: LAMINA + ESPUMA + NEVOA"),
		_labeled(_ref(ref, REF_FALL, 512), "REFERENCIA: CASCATA DO MEIO"),
	]))
	var out: Image = _vcat(rows)
	PL.save_png(out, PL.PREVIEW + "a08-ilha-agua.png")


func _ceu_fx(ref: Image) -> void:
	var puffs: Image = PL.load_tex("sky/cloud_puffs")
	var sea: Image = PL.load_tex("sky/cloud_sea")
	var fire: Image = PL.load_tex("fx/fire_flipbook")
	var rainbow: Image = PL.load_tex("fx/rainbow")
	var st: Dictionary = CA.cloud_stats(puffs)
	var rs: Dictionary = PL.lum_stats(ref, BOX_CLOUD_BL)
	var rows: Array = []
	# aglomerado: mar embaixo, puffs empilhados por cima (com tinta de luz como o shader faria: nada)
	var clus := Image.create(640, 512, false, Image.FORMAT_RGBA8)
	for y: int in 512:
		var c: Color = SKY_HI.lerp(Color("#EAD9DC"), float(y) / 512.0)
		for x: int in 640:
			clus.set_pixel(x, y, c)
	var seas: Image = PL.scaled(sea, 0.5)
	for y: int in 160:
		for x: int in 640:
			var c: Color = seas.get_pixel(x % 512, y + 100)
			clus.set_pixel(x, 352 + y, c)
	for e: Array in [[2, 0.55, 300, 210], [0, 0.5, -60, 230], [3, 0.6, 120, 250], [1, 0.45, 380, 270], [0, 0.4, 230, 300]]:
		var k: int = e[0]
		var cell: Image = puffs.get_region(Rect2i((k % 2) * 512, (k / 2) * 512, 512, 512))
		cell = PL.scaled(cell, float(e[1]))
		clus.blend_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), Vector2i(int(e[2]), int(e[3]) - cell.get_height() / 2))
	rows.append(_hcat([
		_labeled(PL.on_bg(PL.scaled(puffs, 0.5), SKY_HI), "CLOUD_PUFFS 1024 50%%: L>=235 EM %.0f%% DOS OPACOS, BASE #%s" % [float(st["white"]) * 100.0, (st["base"] as Color).to_html(false).to_upper()]),
		_labeled(clus, "MAQUETE: AGLOMERADO SOBRE O MAR"),
		_labeled(_ref(ref, REF_CLOUD_BL, 400), "REF. NUVEM EMBAIXO ESQ. (CAIXA #%s)" % (rs["color"] as Color).to_html(false).to_upper()),
		_labeled(_ref(ref, REF_CLOUD_R, 400), "REF. NUVEM DIREITA"),
	]))
	var fire_day := PL.on_bg(PL.scaled(fire, 1.5), Color("#7A8A5A"))
	var fire_dark := PL.on_bg(PL.scaled(fire, 1.5), Color("#2A2A30"))
	var rb := Image.create(512, 256, false, Image.FORMAT_RGBA8)
	for y: int in 256:
		var c: Color = SKY.lerp(Color("#EAF6FC"), float(y) / 256.0)
		for x: int in 512:
			rb.set_pixel(x, y, c)
	# fita em arco (só para ver as faixas na curva)
	for y: int in 256:
		for x: int in 512:
			var d: float = Vector2(x - 256, y - 300).length()
			if d < 160.0 or d > 224.0:
				continue
			var v: float = (224.0 - d) / 64.0
			var u: float = clampf((atan2(y - 300.0, x - 256.0) + PI) / PI, 0.0, 1.0)
			var c: Color = rainbow.get_pixel(int(u * 255.0), clampi(int(v * 32.0), 0, 31))
			var a: float = c.a * 0.6 * smoothstep(0.0, 0.25, u) * smoothstep(1.0, 0.75, u)
			rb.set_pixel(x, y, rb.get_pixel(x, y).lerp(Color(c.r, c.g, c.b), a))
	rows.append(_hcat([
		_labeled(PL.scaled(PL.tiled(sea, 2, 2), 0.25), "CLOUD_SEA 1024 2X2 A 25%"),
		_labeled(fire_day, "FIRE_FLIPBOOK 4 QUADROS 128X192 X1.5"),
		_labeled(fire_dark, "IDEM SOBRE ESCURO"),
		_labeled(_ref(ref, REF_TORCH, 288), "REF. TOCHA SUL"),
	]))
	rows.append(_hcat([
		_labeled(PL.on_bg(PL.scaled(rainbow, 2.0), SKY), "RAINBOW 256X32 X2 (V=0 FORA/VERMELHO)"),
		_labeled(rb, "MAQUETE: FITA EM ARCO (ALFA 60%)"),
		_labeled(_ref(ref, REF_RAINBOW, 256), "REFERENCIA: ARCO-IRIS"),
	]))
	PL.save_png(_vcat(rows), PL.PREVIEW + "a08-ceu-fx.png")


func _props(ref: Image) -> void:
	var rows: Array = []
	rows.append(_hcat([
		_labeled(PL.tiled(PL.load_tex("props/wood_planks"), 2, 2), "WOOD_PLANKS 256 (4X4 U) 2X2"),
		_labeled(PL.load_tex("props/wood_planks_n"), "WOOD_PLANKS_N"),
		_labeled(PL.load_tex("props/wood_end"), "WOOD_END 256"),
		_labeled(PL.load_tex("props/wood_end_n"), "WOOD_END_N"),
		_labeled(PL.scaled(PL.tiled(PL.load_tex("props/rope"), 2, 2), 1.0), "ROPE 64X256 2X2"),
		_labeled(_ref(ref, REF_BRIDGE, 240), "REFERENCIA: PONTE OESTE"),
	]))
	rows.append(_hcat([
		_labeled(PL.scaled(PL.tiled(PL.load_tex("props/iron"), 2, 2), 1.5), "IRON 128 2X2 X1.5"),
		_labeled(PL.scaled(PL.load_tex("props/iron_n"), 1.5), "IRON_N X1.5"),
		_labeled(PL.scaled(PL.tiled(PL.load_tex("props/ruin_stone"), 2, 2), 0.5), "RUIN_STONE 512 (8X8 U) 2X2 A 50%"),
		_labeled(PL.scaled(PL.load_tex("props/ruin_stone_n"), 0.5), "RUIN_STONE_N 50%"),
		_labeled(_ref(ref, REF_RUINS, 300), "REFERENCIA: RUINAS"),
	]))
	PL.save_png(_vcat(rows), PL.PREVIEW + "a08-props.png")


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
