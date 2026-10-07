class_name PlaceholderArt
extends RefCounted
## Arte placeholder gerada em código, com a paleta e os mesmos nomes/tamanhos da spec A01.
## Usada só quando o PNG correspondente não existe em assets/. RNG com seed fixa por nome.

## Textura de terreno = 1 unidade do mundo.
const TEXTURE_SIZE: int = WorldScale.TEXELS_PER_UNIT

## Tamanho do canvas de cada família de sprite.
const SPRITE_SIZES: Dictionary = {
	"tree_big": Vector2i(96, 128),
	"tree_small": Vector2i(64, 96),
	"bush": Vector2i(32, 32),
	"grass_tuft": Vector2i(16, 16),
	"flower": Vector2i(16, 16),
	"monolith_0": Vector2i(32, 96),
	"monolith_1": Vector2i(32, 64),
	"mushroom": Vector2i(16, 16),
}

# Camadas de material usadas para escolher a cor do contorno.
const LAYER_NONE: int = 0
const LAYER_LEAF: int = 1
const LAYER_WOOD: int = 2
const LAYER_GRASS: int = 3
const LAYER_STONE: int = 4


## Gera a imagem do placeholder pelo nome do arquivo (sem extensão).
static func make_image(art_name: String) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = art_name.hash()
	var variant: int = art_name.get_slice("_", art_name.get_slice_count("_") - 1).to_int()
	if art_name.begins_with("grass_arena"):
		return _grass(rng, Palette.GRASS_2, Palette.GRASS_1, Palette.GRASS_3, Palette.GRASS_0, variant == 3)
	if art_name.begins_with("grass_forest"):
		return _grass(rng, Palette.FOREST_GRASS_1, Palette.FOREST_GRASS_0, Palette.FOREST_GRASS_2, Palette.FOREST_GRASS_SPOT, false)
	if art_name.begins_with("dirt"):
		return _dirt(rng)
	match art_name:
		"ruin_tile":
			return _ruin_tile(rng)
		"step_side":
			return _step_side(rng, false)
		"step_side_grass":
			return _step_side(rng, true)
		"wall_face":
			return _wall_face(rng)
		"wall_top":
			return _wall_top(rng)
		"rock":
			return _rock(rng)
		"moss":
			var m := Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
			m.fill(Color(0.25, 0.45, 0.15, 1.0))
			return m
		"bark_0":
			var b := Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
			b.fill(Color(0.35, 0.22, 0.14, 1.0))
			return b
		"wood_end":
			var w := Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
			w.fill(Color(0.55, 0.42, 0.28, 1.0))
			return w
	if art_name.begins_with("stone_path"):
		return _ruin_tile(rng)
	if art_name.begins_with("tree_big"):
		return _tree(rng, SPRITE_SIZES["tree_big"], true)
	if art_name.begins_with("tree_small"):
		return _tree(rng, SPRITE_SIZES["tree_small"], false)
	if art_name.begins_with("bush"):
		return _bush(rng, variant == 2)
	if art_name.begins_with("grass_tuft"):
		return _grass_tuft(rng, variant == 2)
	if art_name.begins_with("flower"):
		return _flower(rng, variant)
	if art_name.begins_with("mushroom"):
		var mush := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
		mush.fill(Color(0.4, 0.3, 0.7, 1.0))
		return mush
	if art_name.begins_with("monolith"):
		var index: int = art_name.get_slice("_", 1).to_int()
		var rune_only: bool = art_name.ends_with("_rune")
		# A máscara usa a mesma seed do sprite, para as runas baterem.
		rng.seed = ("monolith_%d" % index).hash()
		return _monolith(rng, index, rune_only)
	if art_name.ends_with("_n"):
		var norm := Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
		norm.fill(Color(0.5, 0.5, 1.0, 1.0))
		return norm
	if art_name.begins_with("grass_fringe") or art_name.begins_with("moss_fringe"):
		var fringe := Image.create_empty(32, 16, false, Image.FORMAT_RGBA8)
		fringe.fill(Color(0.2, 0.45, 0.18, 1.0))
		return fringe
	push_warning("PlaceholderArt: nome desconhecido '%s'" % art_name)
	return _grass(rng, Palette.GRASS_2, Palette.GRASS_1, Palette.GRASS_3, Palette.GRASS_0, false)


## Extrai a máscara da runa (só os pixels do grupo Runa) de um sprite de monólito.
static func extract_rune_mask(sprite: Image) -> Image:
	var src := sprite.duplicate() as Image
	if src.is_compressed():
		src.decompress()
	src.clear_mipmaps()
	src.convert(Image.FORMAT_RGBA8)
	var mask := Image.create_empty(src.get_width(), src.get_height(), false, Image.FORMAT_RGBA8)
	for y in src.get_height():
		for x in src.get_width():
			var c: Color = src.get_pixel(x, y)
			if Palette.is_rune_color(c):
				mask.set_pixel(x, y, c)
	return mask


# --- Utilidades de desenho -------------------------------------------------

static func _new_texture(base: Color) -> Image:
	var img := Image.create_empty(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(base)
	return img


## Pinta com repetição nas bordas (texturas sem emenda).
static func _put_wrap(img: Image, x: int, y: int, c: Color) -> void:
	img.set_pixel(posmod(x, img.get_width()), posmod(y, img.get_height()), c)


static func _blob_wrap(img: Image, cx: int, cy: int, r: float, c: Color) -> void:
	var ri: int = ceili(r)
	for dy in range(-ri, ri + 1):
		for dx in range(-ri, ri + 1):
			if dx * dx + dy * dy <= r * r + 0.5:
				_put_wrap(img, cx + dx, cy + dy, c)


static func _in_image(img: Image, x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height()


## Contorno de 1 px por fora da silhueta: pixel transparente vizinho (vizinhança 4) de um
## pixel opaco recebe a cor de contorno do material vizinho. Deixa 1 px de folga no canvas.
static func _outline(img: Image, layers: PackedByteArray, colors: Dictionary) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var src := img.duplicate() as Image
	for y in range(1, h):
		for x in range(1, w - 1):
			if src.get_pixel(x, y).a > 0.5:
				continue
			for d: Vector2i in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if _in_image(src, nx, ny) and src.get_pixel(nx, ny).a > 0.5:
					img.set_pixel(x, y, colors.get(int(layers[ny * w + nx]), Palette.OUTLINE_WOODS))
					break


# --- Texturas 32×32 ---------------------------------------------------------

static func _grass(rng: RandomNumberGenerator, base: Color, blob: Color, tuft: Color, shadow: Color, flowers: bool) -> Image:
	var img := _new_texture(base)
	for _i in 14:
		_blob_wrap(img, rng.randi_range(0, 31), rng.randi_range(0, 31), rng.randf_range(0.8, 2.0), blob)
	for _i in 18:
		# Tufo visto de cima: luz em cima-esquerda, sombra embaixo-direita.
		var x: int = rng.randi_range(0, 31)
		var y: int = rng.randi_range(0, 31)
		_put_wrap(img, x, y, tuft)
		_put_wrap(img, x + 1, y, tuft)
		_put_wrap(img, x + 2, y - 1, tuft)
		_put_wrap(img, x + 1, y + 1, shadow)
		_put_wrap(img, x + 2, y + 1, blob)
		_put_wrap(img, x + 3, y, blob)
	if flowers:
		for _i in 3:
			var x: int = rng.randi_range(0, 31)
			var y: int = rng.randi_range(0, 31)
			var c: Color = Palette.FLOWER_YELLOW if rng.randf() < 0.5 else Palette.FLOWER_WHITE
			_blob_wrap(img, x, y, 0.8, c)
	return img


static func _dirt(rng: RandomNumberGenerator) -> Image:
	var img := _new_texture(Palette.DIRT_2)
	for _i in 14:
		_blob_wrap(img, rng.randi_range(0, 31), rng.randi_range(0, 31), rng.randf_range(0.6, 1.8), Palette.DIRT_3)
	for _i in 12:
		_blob_wrap(img, rng.randi_range(0, 31), rng.randi_range(0, 31), rng.randf_range(0.5, 1.2), Palette.DIRT_1)
	for _i in 6:
		var x: int = rng.randi_range(0, 31)
		var y: int = rng.randi_range(0, 31)
		_put_wrap(img, x, y, Palette.COLD_STONE_3)
		_put_wrap(img, x + 1, y, Palette.COLD_STONE_2)
		_put_wrap(img, x, y + 1, Palette.COLD_STONE_2)
		_put_wrap(img, x + 1, y + 1, Palette.DIRT_0)
	return img


static func _ruin_tile(rng: RandomNumberGenerator) -> Image:
	var img := _new_texture(Palette.GRASS_1)
	for _i in 10:
		_put_wrap(img, rng.randi_range(0, 31), rng.randi_range(0, 31), Palette.GRASS_0)
	for py in 2:
		for px in 2:
			var x0: int = 1 + px * 16
			var y0: int = 1 + py * 16
			for y in range(y0, y0 + 14):
				for x in range(x0, x0 + 14):
					var corner: bool = (x == x0 or x == x0 + 13) and (y == y0 or y == y0 + 13)
					if corner:
						continue
					var c: Color = Palette.COLD_STONE_3
					if y == y0 or x == x0:
						c = Palette.COLD_STONE_4
					elif y == y0 + 13 or x == x0 + 13:
						c = Palette.COLD_STONE_2
					img.set_pixel(x, y, c)
			# Rachadura fina em algumas placas.
			if rng.randf() < 0.6:
				var cx: int = x0 + rng.randi_range(3, 9)
				var cy: int = y0 + rng.randi_range(3, 7)
				for k in rng.randi_range(3, 5):
					img.set_pixel(cx + k, cy + int(k * 0.6), Palette.COLD_STONE_1)
	return img


static func _step_side(rng: RandomNumberGenerator, with_grass: bool) -> Image:
	# A franja não pode mudar os blocos: usa sempre a seed da lateral sem grama.
	rng.seed = "step_side".hash()
	var img := _new_texture(Palette.EARTH_STONE_0)
	for row in 2:
		var y0: int = row * 16
		var x: int = rng.randi_range(0, 10)
		var x_end: int = x + 32
		while x < x_end:
			var bw: int = rng.randi_range(10, 14)
			if x_end - (x + bw) < 8:
				bw = x_end - x
			_rounded_block(img, x, y0, bw, 16)
			x += bw
	if with_grass:
		rng.seed = "step_side_grass".hash()
		for x in 32:
			for y in 3:
				img.set_pixel(x, y, Palette.GRASS_2 if y < 2 else Palette.GRASS_1)
		var x := 0
		while x < 32:
			var dw: int = rng.randi_range(3, 5)
			var dl: int = rng.randi_range(3, 9)
			for dx in dw:
				# Gota arredondada: as colunas das pontas são mais curtas.
				var edge: bool = dx == 0 or dx == dw - 1
				var length: int = dl - (2 if edge else 0)
				for y in range(2, 2 + length):
					var c: Color = Palette.GRASS_1
					if y == 1 + length:
						c = Palette.GRASS_0
					elif dx == 1 and y < 4:
						c = Palette.GRASS_2
					img.set_pixel(posmod(x + dx, 32), y, c)
			x += dw + rng.randi_range(0, 2)
	return img


## Bloco de pedra terrosa arredondado (lateral de degrau), com repetição horizontal.
static func _rounded_block(img: Image, x0: int, y0: int, bw: int, bh: int) -> void:
	for y in range(y0 + 1, y0 + bh - 1):
		for dx in range(1, bw - 1):
			var top: bool = y <= y0 + 2
			var bottom: bool = y >= y0 + bh - 3
			var corner: bool = (dx == 1 or dx == bw - 2) and (y == y0 + 1 or y == y0 + bh - 2)
			if corner:
				continue
			var c: Color = Palette.EARTH_STONE_2
			if top:
				c = Palette.EARTH_STONE_3
				if dx <= 4 and y == y0 + 1:
					c = Palette.EARTH_STONE_4
			elif bottom or dx >= bw - 3:
				c = Palette.EARTH_STONE_1
			_put_wrap(img, x0 + dx, y, c)


static func _wall_face(rng: RandomNumberGenerator) -> Image:
	var img := _new_texture(Palette.EARTH_STONE_0)
	var mossy: int = rng.randi_range(0, 3)
	for row in 4:
		var y0: int = row * 8
		var offset: int = 8 if row % 2 == 1 else 0
		for b in 2:
			var x0: int = offset + b * 16
			for y in range(y0 + 1, y0 + 7):
				for dx in range(1, 15):
					var c: Color = Palette.EARTH_STONE_2
					if y == y0 + 1:
						c = Palette.EARTH_STONE_4 if dx <= 3 else Palette.EARTH_STONE_3
					elif y == y0 + 6 or dx == 14:
						c = Palette.EARTH_STONE_1
					if (dx == 1 or dx == 14) and (y == y0 + 1 or y == y0 + 6):
						continue
					_put_wrap(img, x0 + dx, y, c)
			if row * 2 + b == mossy:
				for dx in range(3, 9):
					_put_wrap(img, x0 + dx, y0 + 1, Palette.GRASS_1)
				_put_wrap(img, x0 + 4, y0 + 2, Palette.GRASS_0)
	return img


static func _wall_top(rng: RandomNumberGenerator) -> Image:
	var img := _new_texture(Palette.EARTH_STONE_0)
	for by in 2:
		for bx in 2:
			var x0: int = bx * 16 + (8 if by == 1 else 0)
			var y0: int = by * 16
			for y in range(y0 + 1, y0 + 15):
				for dx in range(1, 15):
					var c: Color = Palette.EARTH_STONE_3
					if y == y0 + 1 or dx == 1:
						c = Palette.EARTH_STONE_4
					elif y == y0 + 14 or dx == 14:
						c = Palette.EARTH_STONE_1
					_put_wrap(img, x0 + dx, y, c)
	_blob_wrap(img, rng.randi_range(0, 31), rng.randi_range(0, 31), 1.2, Palette.GRASS_1)
	return img


static func _rock(rng: RandomNumberGenerator) -> Image:
	var img := _new_texture(Palette.COLD_STONE_2)
	var seeds: Array[Vector2] = []
	for _i in 7:
		seeds.append(Vector2(rng.randi_range(0, 31), rng.randi_range(0, 31)))
	var owner_of := PackedInt32Array()
	owner_of.resize(32 * 32)
	for y in 32:
		for x in 32:
			var best: int = 0
			var best_d: float = INF
			for k in seeds.size():
				var d := Vector2(x, y) - seeds[k]
				d = Vector2(wrapf(d.x, -16.0, 16.0), wrapf(d.y, -16.0, 16.0))
				if d.length_squared() < best_d:
					best_d = d.length_squared()
					best = k
			owner_of[y * 32 + x] = best
	for y in 32:
		for x in 32:
			var k: int = owner_of[y * 32 + x]
			var c: Color = Palette.COLD_STONE_3 if k % 2 == 0 else Palette.COLD_STONE_2
			if owner_of[y * 32 + (x + 1) % 32] != k or owner_of[((y + 1) % 32) * 32 + x] != k:
				c = Palette.COLD_STONE_1
			img.set_pixel(x, y, c)
	return img


# --- Sprites em pé ----------------------------------------------------------

## Bolha da copa com 3 tons (luz em cima-esquerda, sombra embaixo-direita) e aro escuro.
static func _bubble(img: Image, layers: PackedByteArray, center: Vector2, r: float, tones: Array, glow: bool) -> void:
	var w: int = img.get_width()
	var ri: int = ceili(r)
	for dy in range(-ri, ri + 1):
		for dx in range(-ri, ri + 1):
			var x: int = roundi(center.x) + dx
			var y: int = roundi(center.y) + dy
			if x < 2 or x > w - 3 or y < 2 or y > img.get_height() - 1:
				continue
			var dist: float = sqrt(float(dx * dx + dy * dy))
			if dist > r:
				continue
			var nx: float = dx / r
			var ny: float = dy / r
			var c: Color = tones[1]
			if dist > r - 1.0 and (nx + ny) > -0.2:
				c = tones[0]
			elif nx * 0.6 + ny * 0.8 > 0.3:
				c = tones[0]
			elif nx * 0.6 + ny * 0.8 < -0.35:
				c = tones[2]
			if glow and Vector2(nx + 0.3, ny + 0.5).length() < 0.28:
				c = tones[3]
			img.set_pixel(x, y, c)
			layers[y * w + x] = LAYER_LEAF


static func _tree(rng: RandomNumberGenerator, canvas: Vector2i, big: bool) -> Image:
	var img := Image.create_empty(canvas.x, canvas.y, false, Image.FORMAT_RGBA8)
	var layers := PackedByteArray()
	layers.resize(canvas.x * canvas.y)
	layers.fill(LAYER_NONE)
	var tones: Array = [Palette.WOODS_0, Palette.WOODS_1, Palette.WOODS_2, Palette.WOODS_3] if big \
			else [Palette.WOODS_1, Palette.WOODS_2, Palette.WOODS_3, Palette.WOODS_4]
	var cx: float = canvas.x * 0.5
	var crown_bottom: float = canvas.y * 0.74
	# Tronco com raízes abertas tocando a última linha.
	var trunk_w: int = 12 if big else 8
	for y in range(int(crown_bottom) - 8, canvas.y):
		var spread: int = maxi(0, y - (canvas.y - 4))
		var half: int = int(trunk_w * 0.5) + spread
		for x in range(int(cx) - half, int(cx) + half):
			var c: Color = Palette.WOOD_1
			if x < int(cx) - half + 3:
				c = Palette.WOOD_2
			elif x >= int(cx) + half - 3:
				c = Palette.WOOD_0
			if y < int(crown_bottom) + 2:
				c = Palette.WOOD_0
			img.set_pixel(x, y, c)
			layers[y * canvas.x + x] = LAYER_WOOD
	# Copa: bolhas de trás (em cima) para a frente (embaixo).
	var count: int = 8 if big else 5
	var r_min: float = 13.0 if big else 9.0
	var r_max: float = 18.0 if big else 12.0
	var bubbles: Array[Vector3] = []
	for i in count:
		var r: float = rng.randf_range(r_min, r_max)
		var ang: float = rng.randf_range(0.0, TAU)
		var spread: float = rng.randf_range(0.2, 1.0)
		var by: float = canvas.y * 0.36 + sin(ang) * canvas.y * 0.2 * spread
		var bx: float = cx + cos(ang) * canvas.x * 0.28 * spread
		if i == 0:
			bx = cx
			by = canvas.y * 0.3
		bx = clampf(bx, r + 2.0, canvas.x - r - 3.0)
		by = clampf(by, r + 2.0, crown_bottom - r * 0.4)
		bubbles.append(Vector3(bx, by, r))
	bubbles.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.y < b.y)
	var top_y: float = bubbles[0].y
	for bub: Vector3 in bubbles:
		_bubble(img, layers, Vector2(bub.x, bub.y), bub.z, tones, bub.y < top_y + canvas.y * 0.12)
	_outline(img, layers, {LAYER_LEAF: Palette.OUTLINE_WOODS, LAYER_WOOD: Palette.OUTLINE_STONE})
	return img


static func _bush(rng: RandomNumberGenerator, with_flowers: bool) -> Image:
	var img := Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
	var layers := PackedByteArray()
	layers.resize(32 * 32)
	layers.fill(LAYER_NONE)
	var tones: Array = [Palette.WOODS_1, Palette.WOODS_2, Palette.WOODS_3, Palette.WOODS_4]
	var bubbles: Array[Vector3] = [
		Vector3(16 + rng.randi_range(-1, 1), 14 + rng.randi_range(-2, 1), rng.randf_range(7.0, 8.5)),
		Vector3(10 + rng.randi_range(-1, 1), 21, rng.randf_range(7.0, 8.5)),
		Vector3(22 + rng.randi_range(-1, 1), 21, rng.randf_range(7.0, 8.5)),
	]
	for bub: Vector3 in bubbles:
		_bubble(img, layers, Vector2(bub.x, bub.y), bub.z, tones, bub.y < 16)
	# Base reta e larga na última linha.
	for x in range(6, 26):
		for y in range(26, 32):
			if img.get_pixel(x, y).a < 0.5:
				img.set_pixel(x, y, Palette.WOODS_1)
				layers[y * 32 + x] = LAYER_LEAF
	if with_flowers:
		for _i in 4:
			var fx: int = rng.randi_range(8, 22)
			var fy: int = rng.randi_range(10, 24)
			img.set_pixel(fx, fy, Palette.FLOWER_LILAC_1)
			img.set_pixel(fx + 1, fy, Palette.FLOWER_LILAC_1)
			img.set_pixel(fx, fy + 1, Palette.FLOWER_LILAC_0)
			img.set_pixel(fx + 1, fy + 1, Palette.FLOWER_LILAC_0)
	_outline(img, layers, {LAYER_LEAF: Palette.OUTLINE_WOODS})
	return img


static func _grass_tuft(rng: RandomNumberGenerator, forest: bool) -> Image:
	var img := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	var layers := PackedByteArray()
	layers.resize(16 * 16)
	layers.fill(LAYER_NONE)
	var tones: Array = [Palette.WOODS_1, Palette.WOODS_2, Palette.WOODS_3, Palette.WOODS_4] if forest \
			else [Palette.GRASS_0, Palette.GRASS_1, Palette.GRASS_2, Palette.GRASS_3]
	var blades: int = rng.randi_range(4, 6)
	for b in blades:
		var bx: float = 8.0 + (b - (blades - 1) * 0.5) * 1.6
		var height: float = rng.randf_range(7.0, 12.0)
		var lean: float = (bx - 8.0) * 0.5 + rng.randf_range(-1.0, 1.0)
		for step in int(height):
			var t: float = step / height
			var y: int = 15 - step
			var x_mid: float = bx + lean * t
			var half: float = 1.5 * (1.0 - t) + 0.4
			for x in range(roundi(x_mid - half), roundi(x_mid + half) + 1):
				if x < 2 or x > 13 or y < 2:
					continue
				var c: Color = tones[1]
				if t > 0.75:
					c = tones[3]
				elif t > 0.4:
					c = tones[2]
				elif x > x_mid:
					c = tones[0]
				img.set_pixel(x, y, c)
				layers[y * 16 + x] = LAYER_GRASS
	_outline(img, layers, {LAYER_GRASS: Palette.OUTLINE_WOODS if forest else Palette.OUTLINE_GRASS_1})
	return img


static func _flower(rng: RandomNumberGenerator, variant: int) -> Image:
	var img := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	var layers := PackedByteArray()
	layers.resize(16 * 16)
	layers.fill(LAYER_NONE)
	var petal: Color = Palette.FLOWER_YELLOW
	var shade: Color = Palette.DIRT_2
	var core: Color = Palette.DIRT_2
	if variant == 1:
		petal = Palette.FLOWER_WHITE
		core = Palette.FLOWER_YELLOW
		shade = Palette.FLOWER_WHITE
	elif variant == 2:
		petal = Palette.FLOWER_LILAC_1
		shade = Palette.FLOWER_LILAC_0
		core = Palette.FLOWER_YELLOW
	var heads: int = rng.randi_range(2, 3)
	for k in heads:
		var sx: int = 5 + k * 3 + rng.randi_range(0, 1)
		var top: int = rng.randi_range(5, 8)
		for y in range(top, 15):
			img.set_pixel(sx, y, Palette.GRASS_1)
			layers[y * 16 + sx] = LAYER_GRASS
		img.set_pixel(sx + 1, 12, Palette.GRASS_0)
		layers[12 * 16 + sx + 1] = LAYER_GRASS
		for d: Vector2i in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)]:
			img.set_pixel(sx + d.x, top - 1 + d.y, shade if d.y > 0 else petal)
			layers[(top - 1 + d.y) * 16 + sx + d.x] = LAYER_GRASS
		img.set_pixel(sx, top - 1, core)
		layers[(top - 1) * 16 + sx] = LAYER_GRASS
	_outline(img, layers, {LAYER_GRASS: Palette.OUTLINE_GRASS_1})
	return img


static func _monolith(rng: RandomNumberGenerator, index: int, rune_only: bool) -> Image:
	var canvas: Vector2i = SPRITE_SIZES["monolith_%d" % clampi(index, 0, 1)]
	var img := Image.create_empty(canvas.x, canvas.y, false, Image.FORMAT_RGBA8)
	var mask := Image.create_empty(canvas.x, canvas.y, false, Image.FORMAT_RGBA8)
	var layers := PackedByteArray()
	layers.resize(canvas.x * canvas.y)
	layers.fill(LAYER_NONE)
	var x0: int = 5
	var x1: int = 26
	var half_w: float = (x1 - x0) * 0.5
	var mid_x: float = (x0 + x1) * 0.5
	for x in range(x0, x1 + 1):
		var top: int
		if index == 0:
			# Topo arredondado.
			var dx: float = (x - mid_x) / half_w
			top = 2 + roundi(half_w * (1.0 - sqrt(maxf(0.0, 1.0 - dx * dx))))
		else:
			# Topo quebrado na diagonal.
			top = 4 + roundi((x - x0) * 0.45) + (1 if x % 3 == 0 else 0)
		for y in range(top, canvas.y):
			var c: Color = Palette.COLD_STONE_2
			if x <= x0 + 2:
				c = Palette.COLD_STONE_4
			elif x <= mid_x:
				c = Palette.COLD_STONE_3
			elif x >= x1 - 4:
				c = Palette.COLD_STONE_1
			if y >= canvas.y - 6 and rng.randf() < 0.55 - (canvas.y - y) * 0.06:
				c = Palette.GRASS_0 if rng.randf() < 0.5 else Palette.GRASS_1
			img.set_pixel(x, y, c)
			layers[y * canvas.x + x] = LAYER_STONE
	# Rachaduras finas.
	for _i in 3:
		var cx: int = rng.randi_range(x0 + 4, x1 - 6)
		var cy: int = rng.randi_range(16, canvas.y - 14)
		for k in rng.randi_range(4, 7):
			var px: int = cx + (k >> 1)
			if px < x1:
				img.set_pixel(px, cy + k, Palette.COLD_STONE_0)
	# Runas redondas: aro, base, núcleo, brilho em cima-esquerda.
	var rune_ys: Array[int] = [30]
	if index == 0:
		rune_ys = [28, 54]
	for ry: int in rune_ys:
		for dy in range(-4, 5):
			for dx in range(-4, 5):
				var d: float = sqrt(float(dx * dx + dy * dy))
				if d > 4.2:
					continue
				var c: Color = Palette.RUNE_1
				if d > 3.2:
					c = Palette.RUNE_0
				elif d < 1.8:
					c = Palette.RUNE_2
				if dx == -1 and dy == -2:
					c = Palette.RUNE_3
				img.set_pixel(roundi(mid_x) + dx, ry + dy, c)
				mask.set_pixel(roundi(mid_x) + dx, ry + dy, c)
	if rune_only:
		return mask
	_outline(img, layers, {LAYER_STONE: Palette.OUTLINE_WOODS})
	return img
