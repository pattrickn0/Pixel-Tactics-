extends RefCounted
## Prévias da A03 (docs/art-preview/a03-*.png). Sem class_name: usar via preload.
## Tudo é montado na CPU com Nearest; nenhuma luz direcional (só a luz pintada de cima).

const L = preload("res://tools/art/art_lib.gd")

const BG: Color = Color(0.36, 0.36, 0.38)
const BG_CARD: Color = Color(0.55, 0.55, 0.57)
const FG: Color = Color(0.95, 0.95, 0.95)
const MAX_W: int = 1600
const REF_PATH: String = "res://docs/reference/Gemini_Generated_Image_6oy5mo6oy5mo6oy5.jpg"


# ---------------------------------------------------------------------------
# Utilidades
# ---------------------------------------------------------------------------

static func _hash(x: int, y: int, s: int) -> int:
	var h: int = (x * 73856093) ^ (y * 19349663) ^ (s * 83492791)
	h = (h ^ (h >> 13)) * 1274126177
	return absi(h ^ (h >> 16))


static func _tex(tex: Dictionary, name: String, x: int, y: int) -> Color:
	var img: Image = tex[name]
	return img.get_pixel(posmod(x, img.get_width()), posmod(y, img.get_height()))


## Cola um cartão (alfa binário) com o canto em (x, y).
static func _card(dst: Image, card: Image, x: int, y: int) -> void:
	for j: int in card.get_height():
		for i: int in card.get_width():
			var c: Color = card.get_pixel(i, j)
			if c.a8 == 255:
				var px: int = x + i
				var py: int = y + j
				if px >= 0 and py >= 0 and px < dst.get_width() and py < dst.get_height():
					dst.set_pixel(px, py, c)


## Cola um cartão com a base (meio da última linha) em (bx, by).
static func _card_base(dst: Image, card: Image, bx: int, by: int) -> void:
	_card(dst, card, bx - card.get_width() / 2, by - card.get_height() + 1)


static func _fill_tex(dst: Image, rect: Rect2i, tex: Dictionary, name: String, ox: int = 0, oy: int = 0) -> void:
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			if x >= 0 and y >= 0 and x < dst.get_width() and y < dst.get_height():
				dst.set_pixel(x, y, _tex(tex, name, x - rect.position.x + ox, y - rect.position.y + oy))


static func _labeled(img: Image, label: String, k: int) -> Array:
	return [img, label]


# ---------------------------------------------------------------------------
# Mosaico de chão: escolha por texel com máscaras (simula o shader da 005)
# ---------------------------------------------------------------------------

## dirt_cells: PackedByteArray tw*th (1 = célula de terra). Devolve imagem tw*32 x th*32.
static func floor_mosaic(tex: Dictionary, tw: int, th: int, dirt_cells: PackedByteArray, seed: int) -> Image:
	var w: int = tw * 32
	var h: int = th * 32
	var out: Image = L.new_image(w, h, Color.BLACK)
	var n_dirt: FastNoiseLite = FastNoiseLite.new()
	n_dirt.seed = seed
	n_dirt.noise_type = FastNoiseLite.TYPE_SIMPLEX
	n_dirt.frequency = 1.0 / 56.0
	n_dirt.fractal_octaves = 2
	var n_fine: FastNoiseLite = FastNoiseLite.new()
	n_fine.seed = seed + 1
	n_fine.noise_type = FastNoiseLite.TYPE_SIMPLEX
	n_fine.frequency = 1.0 / 13.0
	n_fine.fractal_octaves = 1
	var n_patch: FastNoiseLite = FastNoiseLite.new()
	n_patch.seed = seed + 2
	n_patch.noise_type = FastNoiseLite.TYPE_SIMPLEX
	n_patch.frequency = 1.0 / 190.0
	n_patch.fractal_octaves = 2
	# campo das manchas e limiares por quantil (20% clara, 15% escura)
	var patch: PackedFloat32Array = PackedFloat32Array()
	patch.resize(w * h)
	for y: int in h:
		for x: int in w:
			patch[y * w + x] = n_patch.get_noise_2d(x, y) + 0.12 * n_fine.get_noise_2d(x + 500, y + 500)
	var sorted: PackedFloat32Array = patch.duplicate()
	sorted.sort()
	var t_dark: float = sorted[int(sorted.size() * 0.15)]
	var t_light: float = sorted[int(sorted.size() * 0.80)]
	for y: int in h:
		for x: int in w:
			# campo de terra: valor das células interpolado + ruído
			var u: float = (x + 0.5) / 32.0 - 0.5
			var v: float = (y + 0.5) / 32.0 - 0.5
			var cx: int = floori(u)
			var cy: int = floori(v)
			var fx: float = u - cx
			var fy: float = v - cy
			fx = fx * fx * (3.0 - 2.0 * fx)
			fy = fy * fy * (3.0 - 2.0 * fy)
			var c00: float = _cell(dirt_cells, tw, th, cx, cy)
			var c10: float = _cell(dirt_cells, tw, th, cx + 1, cy)
			var c01: float = _cell(dirt_cells, tw, th, cx, cy + 1)
			var c11: float = _cell(dirt_cells, tw, th, cx + 1, cy + 1)
			var f: float = lerpf(lerpf(c00, c10, fx), lerpf(c01, c11, fx), fy)
			f += 0.34 * n_dirt.get_noise_2d(x, y) + 0.2 * n_fine.get_noise_2d(x, y)
			var tx: int = x / 32
			var ty: int = y / 32
			var hv: int = _hash(tx, ty, seed)
			var name: String
			if f > 0.5:
				name = "dirt_%d" % (hv % 2)
			elif f > 0.44:
				name = "grass_arena_light_%d" % (hv % 2)
			else:
				var pv: float = patch[y * w + x]
				if pv > t_light:
					name = "grass_arena_light_%d" % (hv % 2)
				elif pv < t_dark:
					name = "grass_arena_dark_%d" % (hv % 2)
				else:
					var r: int = hv % 10
					name = "grass_arena_3" if r == 0 else "grass_arena_%d" % (r % 3)
			out.set_pixel(x, y, _tex(tex, name, x, y))
	return out


static func _cell(cells: PackedByteArray, tw: int, th: int, x: int, y: int) -> float:
	if x < 0 or y < 0 or x >= tw or y >= th:
		return 0.0
	return float(cells[y * tw + x])


## Células de terra: mancha elíptica no meio + ilhas, pela seed.
static func dirt_blob(tw: int, th: int, cx: float, cy: float, rx: float, ry: float, seed: int) -> PackedByteArray:
	var cells: PackedByteArray = PackedByteArray()
	cells.resize(tw * th)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed
	for y: int in th:
		for x: int in tw:
			var dx: float = (x + 0.5 - cx) / rx
			var dy: float = (y + 0.5 - cy) / ry
			var d: float = dx * dx + dy * dy
			cells[y * tw + x] = 1 if d < 1.0 + rng.randf_range(-0.25, 0.15) else 0
	return cells


# ---------------------------------------------------------------------------
# a03-texturas.png
# ---------------------------------------------------------------------------

static func textures_sheet(tex: Dictionary, normals: Dictionary, order: Array) -> Image:
	var items: Array = []
	for it: Array in order:
		var name: String = it[0]
		var img: Image = tex[name]
		var block: Image = L.new_image(128 + 6 + 256, 256, BG)
		L.paste(block, L.scaled(img, 4), 0, 0)
		if normals.has(name):
			L.paste(block, L.scaled(normals[name], 2), 32, 136)
			L.text(block, "N", 4, 136, 2, FG)
		L.paste(block, L.scaled(L.tiled(img, 4, 4), 2), 134, 0)
		items.append([block, name])
	var sheet: Image = L.flow_layout(items, MAX_W, 12, 2, BG, FG)
	# demos
	var demos: Array = []
	var cells: PackedByteArray = dirt_blob(24, 14, 12.0, 7.2, 6.5, 4.0, 77)
	# ilhas de terra menores
	for p: Vector2i in [Vector2i(3, 3), Vector2i(4, 3), Vector2i(20, 11), Vector2i(21, 11), Vector2i(21, 2)]:
		cells[p.y * 24 + p.x] = 1
	var mosaic: Image = floor_mosaic(tex, 24, 14, cells, 9001)
	demos.append([mosaic, "MOSAICO DE CHAO 24X14 TILES X1"])
	demos.append([L.scaled(mosaic.get_region(Rect2i(90, 150, 200, 140)), 3), "DETALHE DO MOSAICO X3"])
	var demo_items: Array = []
	demo_items.append([L.scaled(_wall_demo(tex), 3), "MURO 2 NIVEIS + TOPO + FRANJA X3"])
	demo_items.append([L.scaled(_stair_demo(tex), 3), "ESCADA 2 NIVEIS X3"])
	demo_items.append([L.scaled(_path_demo(tex, 3), 2), "CALCAMENTO COM BORDA DE GRAMA X2"])
	var d1: Image = L.flow_layout(demos, MAX_W, 12, 2, BG, FG)
	var d2: Image = L.flow_layout(demo_items, MAX_W, 12, 2, BG, FG)
	return _stack([sheet, d1, d2])


static func _stack(imgs: Array) -> Image:
	var w: int = 0
	var h: int = 0
	for im: Image in imgs:
		w = maxi(w, im.get_width())
		h += im.get_height()
	var out: Image = L.new_image(w, h, BG)
	var y: int = 0
	for im: Image in imgs:
		out.blit_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i(0, y))
		y += im.get_height()
	return out


## Muro: chão de cima, topo de musgo, face A+B com franja de musgo, chão da arena embaixo.
static func _wall_demo(tex: Dictionary) -> Image:
	var w: int = 160
	var img: Image = L.new_image(w, 96, BG)
	_fill_tex(img, Rect2i(0, 0, w, 16), tex, "grass_forest_0")
	_fill_tex(img, Rect2i(0, 16, w, 16), tex, "wall_top")
	_fill_tex(img, Rect2i(0, 32, w, 32), tex, "wall_face")
	for k: int in 5:
		_card(img, tex["moss_fringe_%d" % (k % 2)], k * 32, 32)
	_fill_tex(img, Rect2i(0, 64, w, 32), tex, "grass_arena_0")
	return img


## Degraus como na vista do jogo: o piso (faixa de 16 linhas) aparece achatado em 5 linhas,
## do fundo (linha 15, junta) até o nariz (linha 0), em cima da faixa de 8 linhas do espelho.
const TREAD_ROWS: int = 5

static func _stair_steps(img: Image, tex: Dictionary, x0: int, y0: int, w: int, steps: int) -> int:
	var y: int = y0
	for k: int in steps:
		var band: int = k % 2
		for j: int in TREAD_ROWS:
			var src: int = band * 16 + 15 - roundi(j * 15.0 / (TREAD_ROWS - 1))
			for x: int in w:
				if y >= 0 and y < img.get_height():
					img.set_pixel(x0 + x, y, _tex(tex, "stair_tread", x, src))
			y += 1
		_fill_tex(img, Rect2i(x0, y, w, 8), tex, "stair_riser", 0, (k % 4) * 8)
		y += 8
	return y


## Escada: 4 degraus (2 níveis), piso achatado + espelho, com muros dos lados.
static func _stair_demo(tex: Dictionary) -> Image:
	var w: int = 96
	var img: Image = L.new_image(w + 64, 16 + 4 * (TREAD_ROWS + 8) + 16, BG)
	_fill_tex(img, Rect2i(0, 0, w + 64, 16), tex, "grass_forest_1")
	var y: int = _stair_steps(img, tex, 32, 16, w, 4)
	# muros dos lados (2 níveis)
	_fill_tex(img, Rect2i(0, 16, 32, 16), tex, "wall_top")
	_fill_tex(img, Rect2i(w + 32, 16, 32, 16), tex, "wall_top")
	_fill_tex(img, Rect2i(0, 32, 32, 32), tex, "wall_face")
	_fill_tex(img, Rect2i(w + 32, 32, 32, 32), tex, "wall_face")
	_fill_tex(img, Rect2i(0, 64, 32, y - 64 + 16), tex, "grass_arena_1")
	_fill_tex(img, Rect2i(w + 32, 64, 32, y - 64 + 16), tex, "grass_arena_2")
	_fill_tex(img, Rect2i(32, y, w, 16), tex, "grass_arena_0")
	return img


## Trilha de calçamento sinuosa com aro de grama clara, na grama da arena.
static func _path_demo(tex: Dictionary, seed: int) -> Image:
	var w: int = 320
	var h: int = 160
	var img: Image = L.new_image(w, h, BG)
	var n: FastNoiseLite = FastNoiseLite.new()
	n.seed = seed
	n.frequency = 1.0 / 30.0
	for y: int in h:
		for x: int in w:
			var yc: float = 80.0 + 26.0 * sin(x / 55.0)
			var d: float = absf(y + 0.5 - yc) - 34.0 - 6.0 * n.get_noise_2d(x, y)
			var hv: int = _hash(x / 32, y / 32, seed)
			var name: String
			if d < 0.0:
				name = "stone_path_%d" % (hv % 2)
			elif d < 2.0:
				name = "grass_arena_light_%d" % (hv % 2)
			else:
				name = "grass_arena_%d" % (hv % 3)
			img.set_pixel(x, y, _tex(tex, name, x, y))
	return img


# ---------------------------------------------------------------------------
# a03-cartoes.png
# ---------------------------------------------------------------------------

static func cards_sheet(tex: Dictionary, cards: Dictionary, order: Array) -> Image:
	var items: Array = []
	for it: Array in order:
		var img: Image = cards[it[0]]
		var block: Image = L.new_image(img.get_width() * 4, img.get_height() * 4, BG_CARD)
		L.paste(block, L.scaled(img, 4), 0, 0)
		items.append([block, it[0]])
	var a: Image = L.flow_layout(items, MAX_W, 10, 2, BG, FG)
	var items2: Array = []
	for ground: String in ["grass_arena_0", "grass_forest_0"]:
		for it: Array in order:
			var img: Image = cards[it[0]]
			var bg: Image = L.new_image(img.get_width() + 8, img.get_height() + 8, BG)
			_fill_tex(bg, Rect2i(0, 0, bg.get_width(), bg.get_height()), tex, ground)
			_card(bg, img, 4, 4)
			items2.append([L.scaled(bg, 2), ""])
	var b: Image = L.flow_layout(items2, MAX_W, 6, 2, BG, FG)
	L.text(b, "X2 SOBRE GRASS_ARENA_0 E GRASS_FOREST_0", 6, 0, 2, FG)
	return _stack([a, b])


# ---------------------------------------------------------------------------
# a03-cena.png (composição x1; gravada a x2)
# ---------------------------------------------------------------------------

const SW: int = 512
const SH: int = 400

static func scene(tex: Dictionary, cards: Dictionary) -> Image:
	var img: Image = L.new_image(SW, SH, BG)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 3003
	# terraço de cima (grama de fora) e trilha de calçamento até a escada
	var n: FastNoiseLite = FastNoiseLite.new()
	n.seed = 41
	n.frequency = 1.0 / 26.0
	for y: int in 160:
		for x: int in SW:
			var xc: float = 272.0 + 18.0 * sin(y / 40.0)
			var d: float = absf(x + 0.5 - xc) - 40.0 - 5.0 * n.get_noise_2d(x, y)
			var hv: int = _hash(x / 32, y / 32, 5)
			var name: String = "grass_forest_%d" % (hv % 2)
			if d < 0.0:
				name = "stone_path_%d" % (hv % 2)
			elif d < 2.0:
				name = "grass_arena_light_%d" % (hv % 2)
			img.set_pixel(x, y, _tex(tex, name, x, y))
	# arena (chão por texel com mancha de terra)
	var cells: PackedByteArray = dirt_blob(16, 6, 8.5, 3.6, 4.6, 2.4, 12)
	var arena: Image = floor_mosaic(tex, 16, 6, cells, 4242)
	img.blit_rect(arena, Rect2i(0, 0, SW, 192), Vector2i(0, 208))
	# muro: topo de musgo + face A/B + franja
	_fill_tex(img, Rect2i(0, 160, 224, 16), tex, "wall_top")
	_fill_tex(img, Rect2i(320, 160, SW - 320, 16), tex, "wall_top", 320, 0)
	_fill_tex(img, Rect2i(0, 176, 224, 32), tex, "wall_face")
	_fill_tex(img, Rect2i(320, 176, SW - 320, 32), tex, "wall_face", 320, 0)
	for k: int in 7:
		_card(img, cards["moss_fringe_%d" % (k % 2)], k * 32, 176)
	for k: int in 6:
		_card(img, cards["moss_fringe_%d" % ((k + 1) % 2)], 320 + k * 32, 176)
	# pilares nos lados da escada
	for px: int in [216, 312]:
		_fill_tex(img, Rect2i(px, 156, 16, 16), tex, "wall_top", 8, 0)
		_fill_tex(img, Rect2i(px, 172, 16, 36), tex, "wall_face", px, 0)
	# escada de 2 níveis, saindo para a arena
	_stair_steps(img, tex, 232, 160, 80, 4)
	# capim e flores na arena
	for p: Vector2i in [Vector2i(40, 240), Vector2i(120, 300), Vector2i(470, 270), Vector2i(380, 360), Vector2i(70, 380)]:
		_card_base(img, cards["grass_tuft_%d" % (p.x % 2)], p.x, p.y)
	for p: Vector2i in [Vector2i(95, 262), Vector2i(430, 330), Vector2i(180, 372), Vector2i(350, 250)]:
		_card_base(img, cards["flower_%d" % (p.x % 4)], p.x, p.y)
	# conífera de mentira
	_fake_conifer(img, tex, cards, 76, 150, rng)
	# arbusto
	_fake_bush(img, tex, cards, 170, 152, rng)
	# folhosa de mentira (verde e oliva misturados)
	var mixed: Array[String] = ["leaf_0", "leaf_olive_0", "leaf_1", "leaf_2", "leaf_olive_1", "leaf_3"]
	var vis: float = _fake_broadleaf(img, tex, cards, 440, 150, rng, mixed)
	print("A03 prévia: folhosa da cena, leaves_mass visível em %.0f%% da metade de baixo" % (vis * 100.0))
	# tronco caído com cogumelos e capim alto
	_fake_log(img, tex, 330, 104, 74, 18)
	_card_base(img, cards["mushroom_1"], 322, 126)
	_card_base(img, cards["mushroom_0"], 412, 124)
	_card_base(img, cards["tall_grass_0"], 206, 150)
	_card_base(img, cards["tall_grass_1"], 362, 152)
	_card_base(img, cards["grass_tuft_2"], 150, 90)
	# toco
	_fake_stump(img, tex, 140, 120, 22, 14)
	_card_base(img, cards["mushroom_2"], 160, 124)
	_card_base(img, cards["mushroom_3"], 40, 140)
	_card_base(img, cards["flower_1"], 112, 128)
	return img


static func _fake_conifer(img: Image, tex: Dictionary, cards: Dictionary, cx: int, base_y: int, rng: RandomNumberGenerator) -> void:
	# tronco curto
	_fill_tex(img, Rect2i(cx - 5, base_y - 24, 10, 26), tex, "bark_1")
	# 6 andares em trapézio, de baixo para cima
	var tiers: int = 6
	for k: int in tiers:
		var bottom_w: float = lerpf(104.0, 34.0, float(k) / (tiers - 1))
		var top_w: float = bottom_w * 0.42 if k < tiers - 1 else 2.0
		var y0: int = base_y - 46 - k * 19
		var card: Image = cards["conifer_tier_%d" % (k % 2)]
		var uofs: int = rng.randi_range(0, 31)
		for j: int in 32:
			var wv: float = lerpf(top_w, bottom_w, float(j) / 31.0)
			var half: int = roundi(wv * 0.5)
			for dx: int in range(-half, half):
				var c: Color = card.get_pixel(posmod(dx + uofs, 32), j)
				if c.a8 == 255:
					var px: int = cx + dx
					var py: int = y0 + j
					if px >= 0 and py >= 0 and px < img.get_width() and py < img.get_height():
						img.set_pixel(px, py, c)


## Devolve a fração da metade de baixo da copa em que o leaves_mass fica visível.
static func _fake_broadleaf(img: Image, tex: Dictionary, cards: Dictionary, cx: int, base_y: int,
		rng: RandomNumberGenerator, names: Array[String]) -> float:
	var ccx: int = cx
	var ccy: int = base_y - 92
	# tronco com raízes
	_fill_tex(img, Rect2i(cx - 7, ccy, 14, base_y - ccy), tex, "bark_0")
	_fill_tex(img, Rect2i(cx - 10, base_y - 5, 20, 5), tex, "bark_0")
	_fill_tex(img, Rect2i(cx - 12, base_y - 2, 24, 2), tex, "bark_0")
	# massa escura da copa
	for y: int in range(ccy - 44, ccy + 40):
		for x: int in range(ccx - 56, ccx + 56):
			var dx: float = (x + 0.5 - ccx) / 50.0
			var dy: float = (y + 0.5 - ccy) / 38.0
			if dx * dx + dy * dy <= 1.0 and x >= 0 and y >= 0 and x < img.get_width():
				img.set_pixel(x, y, _tex(tex, "leaves_mass", x, y))
	# cartões de aglomerado numa elipse (de trás/em cima para a frente/embaixo).
	# Na metade de baixo ficam mais espaçados, para a massa escura aparecer entre eles.
	var pts: Array[Vector2i] = []
	var tries: int = 0
	while pts.size() < 24 and tries < 4000:
		tries += 1
		var a: float = rng.randf_range(0, TAU)
		var r: float = sqrt(rng.randf())
		var p: Vector2i = Vector2i(roundi(ccx + cos(a) * r * 42.0), roundi(ccy + sin(a) * r * 30.0))
		var dmin: float = 12.5 if p.y < ccy else 23.0
		var ok: bool = true
		for q: Vector2i in pts:
			if q.distance_to(p) < (12.5 if (p.y < ccy and q.y < ccy) else dmin):
				ok = false
		if ok:
			pts.append(p)
	pts.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y)
	var covered: Dictionary = {}
	for i: int in pts.size():
		var name: String = names[_hash(pts[i].x, pts[i].y, 1) % names.size()]
		var card: Image = cards[name]
		_card(img, card, pts[i].x - 16, pts[i].y - 16)
		for j: int in 32:
			for k: int in 32:
				if card.get_pixel(k, j).a8 == 255:
					covered[Vector2i(pts[i].x - 16 + k, pts[i].y - 16 + j)] = true
	# fração visível da massa na metade de baixo
	var n_low: int = 0
	var n_vis: int = 0
	for y: int in range(ccy, ccy + 40):
		for x: int in range(ccx - 56, ccx + 56):
			var dx: float = (x + 0.5 - ccx) / 50.0
			var dy: float = (y + 0.5 - ccy) / 38.0
			if dx * dx + dy * dy <= 1.0:
				n_low += 1
				if not covered.has(Vector2i(x, y)):
					n_vis += 1
	return float(n_vis) / maxf(1.0, float(n_low))


static func _fake_bush(img: Image, tex: Dictionary, cards: Dictionary, cx: int, base_y: int, rng: RandomNumberGenerator) -> void:
	var ccy: int = base_y - 14
	for y: int in range(ccy - 12, ccy + 14):
		for x: int in range(cx - 26, cx + 26):
			var dx: float = (x + 0.5 - cx) / 22.0
			var dy: float = (y + 0.5 - ccy) / 11.0
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, _tex(tex, "leaves_mass", x, y))
	var spots: Array[Vector2i] = [Vector2i(-14, -6), Vector2i(10, -8), Vector2i(-2, -12), Vector2i(-16, 4), Vector2i(14, 3), Vector2i(0, 2)]
	for i: int in spots.size():
		var name: String = ["leaf_cool_0", "leaf_cool_1", "leaf_flower_0"][i % 3]
		_card(img, cards[name], cx + spots[i].x - 16, ccy + spots[i].y - 16)


## Tronco caído deitado: casca com sulcos na horizontal, musgo em cima, anéis na ponta direita.
static func _fake_log(img: Image, tex: Dictionary, x0: int, y0: int, length: int, dia: int) -> void:
	var bark: Image = tex["bark_0"]
	var moss: Image = tex["moss"]
	var wood: Image = tex["wood_end"]
	for j: int in dia:
		for i: int in length:
			# casca girada 90°: u ao longo do tronco vira v da textura
			var c: Color = bark.get_pixel(posmod(j, 32), posmod(i, 32))
			# musgo cobrindo o topo, com borda de baixo irregular
			var moss_h: int = 5 + int(_hash(i / 3, 0, 9) % 3)
			if j < moss_h and i > 2 and i < length - 6:
				c = moss.get_pixel(posmod(i, 32), posmod(j, 32))
			img.set_pixel(x0 + i, y0 + j, c)
	# ponta cortada: elipse com os anéis
	var rx: float = 5.5
	var ry: float = dia * 0.5
	var ecx: float = x0 + length
	var ecy: float = y0 + dia * 0.5
	for j: int in range(-ceili(ry), ceili(ry) + 1):
		for i: int in range(-ceili(rx), ceili(rx) + 1):
			var dx: float = (i + 0.5) / rx
			var dy: float = (j + 0.5) / ry
			if dx * dx + dy * dy <= 1.0:
				var u: int = clampi(int(16.0 + dx * 16.0), 0, 31)
				var v: int = clampi(int(16.0 + dy * 16.0), 0, 31)
				img.set_pixel(int(ecx) + i, int(ecy) + j, wood.get_pixel(u, v))


## Toco: casca em pé com o topo cortado (anéis) e um tufo de musgo.
static func _fake_stump(img: Image, tex: Dictionary, cx: int, base_y: int, wd: int, ht: int) -> void:
	var x0: int = cx - wd / 2
	var top: int = base_y - ht
	_fill_tex(img, Rect2i(x0, top, wd, ht), tex, "bark_0")
	_fill_tex(img, Rect2i(x0 - 2, base_y - 3, wd + 4, 3), tex, "bark_0")
	var wood: Image = tex["wood_end"]
	var rx: float = wd * 0.5
	var ry: float = 4.5
	for j: int in range(-5, 6):
		for i: int in range(-ceili(rx), ceili(rx) + 1):
			var dx: float = (i + 0.5) / rx
			var dy: float = (j + 0.5) / ry
			if dx * dx + dy * dy <= 1.0:
				var u: int = clampi(int(16.0 + dx * 16.0), 0, 31)
				var v: int = clampi(int(16.0 + dy * 16.0), 0, 31)
				img.set_pixel(cx + i, top + j, wood.get_pixel(u, v))
	_fill_tex(img, Rect2i(x0, top + 5, 6, 4), tex, "moss")


# ---------------------------------------------------------------------------
# a03-comparacao.png
# ---------------------------------------------------------------------------

## pairs: [rótulo, Rect2i na referência (px da imagem), Rect2i na cena x1 (texels)]
const PAIRS: Array = [
	["GRAMA COM TERRA", Rect2i(1150, 830, 300, 200), Rect2i(100, 272, 60, 40)],
	["MURO COM MUSGO", Rect2i(1150, 1170, 300, 200), Rect2i(20, 150, 60, 40)],
	["ESCADA", Rect2i(830, 990, 250, 200), Rect2i(222, 160, 50, 40)],
	["CALCAMENTO", Rect2i(560, 1190, 300, 180), Rect2i(230, 40, 60, 36)],
	["CONIFERA", Rect2i(30, 120, 300, 300), Rect2i(46, 24, 60, 60)],
	["FOLHOSA DA CENA VERDE E OLIVA", Rect2i(760, 230, 250, 250), Rect2i(400, 22, 50, 50)],
	["TRONCO CAIDO", Rect2i(640, 820, 220, 140), Rect2i(362, 96, 44, 28)],
	["COGUMELOS", Rect2i(1745, 1260, 110, 80), Rect2i(310, 108, 22, 16)],
]


## Copas isoladas para comparar família com família: [rótulo, recorte da referência, cartões]
const CROWNS: Array = [
	["FOLHOSA AMARELADA X LEAF_OLIVE", Rect2i(760, 230, 250, 250), ["leaf_olive_0", "leaf_olive_1"]],
	["FOLHOSA VERDE DA FRENTE X LEAF", Rect2i(2490, 1040, 260, 260), ["leaf_0", "leaf_1", "leaf_2", "leaf_3"]],
]


## Copa de mentira sozinha sobre grass_forest, recortada em 52x52 texels no alto da copa.
static func _crown(tex: Dictionary, cards: Dictionary, names: Array[String], seed: int) -> Image:
	var img: Image = L.new_image(140, 160, BG)
	_fill_tex(img, Rect2i(0, 0, 140, 160), tex, "grass_forest_0")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed
	_fake_broadleaf(img, tex, cards, 70, 150, rng, names)
	return img.get_region(Rect2i(44, 20, 52, 52))


static func comparison(scene1x: Image, tex: Dictionary, cards: Dictionary) -> Image:
	var ref: Image = Image.load_from_file(ProjectSettings.globalize_path(REF_PATH))
	ref.convert(Image.FORMAT_RGBA8)
	var pairs: Array = []
	for pr: Array in PAIRS:
		pairs.append([pr[0], pr[1], scene1x.get_region(pr[2])])
	for i: int in CROWNS.size():
		var cr: Array = CROWNS[i]
		var names: Array[String] = []
		names.assign(cr[2])
		pairs.append([cr[0], cr[1], _crown(tex, cards, names, 700 + i)])
	var items: Array = []
	for pr: Array in pairs:
		var rr: Rect2i = pr[1]
		var a: Image = ref.get_region(rr)
		var b: Image = L.scaled(pr[2], 5)
		var hgt: int = maxi(a.get_height(), b.get_height())
		var block: Image = L.new_image(a.get_width() + 8 + b.get_width(), hgt + 12, BG)
		L.text(block, "REF", 0, 0, 2, FG)
		L.text(block, "A03 X5", a.get_width() + 8, 0, 2, FG)
		block.blit_rect(a, Rect2i(Vector2i.ZERO, a.get_size()), Vector2i(0, 12))
		block.blit_rect(b, Rect2i(Vector2i.ZERO, b.get_size()), Vector2i(a.get_width() + 8, 12))
		items.append([block, pr[0]])
	return L.flow_layout(items, MAX_W, 14, 2, BG, FG)
