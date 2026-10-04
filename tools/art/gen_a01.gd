extends SceneTree
## Gera toda a arte da spec A01 (texturas + sprites) e as prévias de revisão.
## Rodar da raiz do projeto:
##   "$G" --headless --path . --script tools/art/gen_a01.gd
## Reproduzível: seeds fixas por arquivo, mesmo script -> mesmos PNG.

const L = preload("res://tools/art/art_lib.gd")
const TEX = preload("res://tools/art/gen_a01_textures.gd")
const SPR = preload("res://tools/art/gen_a01_sprites.gd")

const TEX_DIR: String = "res://assets/textures/"
const SPR_DIR: String = "res://assets/sprites/"
const PREVIEW_DIR: String = "res://docs/art-preview/"

const TEX_ORDER: Array[String] = [
	"grass_arena_0", "grass_arena_1", "grass_arena_2", "grass_arena_3",
	"grass_forest_0", "grass_forest_1", "dirt_0", "dirt_1",
	"ruin_tile", "step_side", "step_side_grass", "wall_face", "wall_top", "rock",
]
const SPR_ORDER: Array[String] = [
	"tree_big_0", "tree_big_1", "tree_big_2", "tree_small_0", "tree_small_1",
	"bush_0", "bush_1", "bush_2", "grass_tuft_0", "grass_tuft_1", "grass_tuft_2",
	"flower_0", "flower_1", "flower_2",
	"monolith_0", "monolith_0_rune", "monolith_1", "monolith_1_rune",
]

const BG: Color = Color("#3c3f44")
const BG_SPRITE: Color = Color("#808080")
const FG: Color = Color("#e6e6e6")
const MAX_W: int = 1600


func _initialize() -> void:
	for d: String in [TEX_DIR, SPR_DIR, PREVIEW_DIR]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(d))
	var textures: Dictionary = TEX.build_all()
	var sprites: Dictionary = SPR.build_all()
	for key: String in TEX_ORDER:
		_save(textures[key], TEX_DIR + key + ".png")
	for key: String in SPR_ORDER:
		_save(sprites[key], SPR_DIR + key + ".png")
	_save(_preview_textures(textures), PREVIEW_DIR + "a01-texturas.png")
	_save(_preview_sprites(sprites, textures), PREVIEW_DIR + "a01-sprites.png")
	_save(_preview_scene(sprites, textures), PREVIEW_DIR + "a01-cena.png")
	print("A01 GEN: %d texturas, %d sprites, 3 previas" % [TEX_ORDER.size(), SPR_ORDER.size()])
	quit(0)


func _save(img: Image, path: String) -> void:
	var err: Error = img.save_png(path)
	if err != OK:
		push_error("Falha ao salvar %s (%d)" % [path, err])


# ---------------------------------------------------------------------------
# Prévia das texturas
# ---------------------------------------------------------------------------

func _preview_textures(tex: Dictionary) -> Image:
	var items: Array = []
	for key: String in TEX_ORDER:
		var t: Image = tex[key]
		var single: Image = L.scaled(t, 4)
		var rep: Image = L.scaled(L.tiled(t, 4, 4), 2)
		var cell: Image = L.new_image(single.get_width() + 4 + rep.get_width(), rep.get_height(), BG)
		cell.blit_rect(single, Rect2i(Vector2i.ZERO, single.get_size()), Vector2i.ZERO)
		cell.blit_rect(rep, Rect2i(Vector2i.ZERO, rep.get_size()), Vector2i(single.get_width() + 4, 0))
		items.append([cell, key + "  X4 / 4X4 X2"])
	# Mosaico 8x8 das 4 variantes da grama da arena
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 2001
	var mosaic: Image = L.new_image(32 * 8, 32 * 8)
	for j: int in 8:
		for i: int in 8:
			var t: Image = tex["grass_arena_%d" % rng.randi_range(0, 3)]
			mosaic.blit_rect(t, Rect2i(0, 0, 32, 32), Vector2i(i * 32, j * 32))
	items.append([L.scaled(mosaic, 2), "GRASS_ARENA 0-3 MOSAICO 8X8 X2"])
	# Mosaico 8x8 da mata e da terra
	var mosaic_f: Image = L.new_image(32 * 8, 32 * 8)
	for j: int in 8:
		for i: int in 8:
			var name_f: String = "grass_forest_%d" % rng.randi_range(0, 1)
			if i == 3 or i == 4:
				name_f = "dirt_%d" % rng.randi_range(0, 1)
			mosaic_f.blit_rect(tex[name_f], Rect2i(0, 0, 32, 32), Vector2i(i * 32, j * 32))
	items.append([L.scaled(mosaic_f, 2), "GRASS_FOREST + DIRT MOSAICO X2"])
	# Degrau de 3 níveis: step_side_grass em cima de 2 step_side
	var col: Image = L.new_image(96, 96)
	for i: int in 3:
		col.blit_rect(tex["step_side_grass"], Rect2i(0, 0, 32, 32), Vector2i(i * 32, 0))
		col.blit_rect(tex["step_side"], Rect2i(0, 0, 32, 32), Vector2i(i * 32, 32))
		col.blit_rect(tex["step_side"], Rect2i(0, 0, 32, 32), Vector2i(i * 32, 64))
	items.append([L.scaled(col, 2), "DEGRAU 3 NIVEIS X2"])
	# Muro: topo (16 px) + face (16 px) repetidos
	var wall: Image = L.new_image(128, 32)
	for i: int in 4:
		wall.blit_rect(tex["wall_top"], Rect2i(0, 0, 32, 16), Vector2i(i * 32, 0))
		wall.blit_rect(tex["wall_face"], Rect2i(0, 0, 32, 16), Vector2i(i * 32, 16))
	items.append([L.scaled(wall, 2), "MURO TOPO+FACE 16PX X2"])
	return L.flow_layout(items, MAX_W, 8, 2, BG, FG)


# ---------------------------------------------------------------------------
# Prévia dos sprites
# ---------------------------------------------------------------------------

func _preview_sprites(spr: Dictionary, tex: Dictionary) -> Image:
	var items_a: Array = []
	for key: String in SPR_ORDER:
		var s: Image = spr[key]
		var cell: Image = L.new_image(s.get_width() * 4, s.get_height() * 4, BG_SPRITE)
		L.paste(cell, L.scaled(s, 4), 0, 0)
		items_a.append([cell, key])
	var strip_a: Image = L.flow_layout(items_a, MAX_W, 8, 2, BG, FG)
	var items_b: Array = []
	for key: String in SPR_ORDER:
		if key.ends_with("_rune"):
			continue
		var s: Image = spr[key]
		var gw: int = ceili(s.get_width() / 32.0) * 32 + 32
		var gh: int = ceili(s.get_height() / 32.0) * 32 + 16
		var ground: Image = L.new_image(gw, gh)
		for j: int in ceili(gh / 32.0):
			for i: int in ceili(gw / 32.0):
				ground.blit_rect(tex["grass_arena_0"], Rect2i(0, 0, 32, 32), Vector2i(i * 32, j * 32))
		L.paste(ground, s, (gw - s.get_width()) >> 1, gh - 8 - s.get_height())
		items_b.append([L.scaled(ground, 2), key])
	var strip_b: Image = L.flow_layout(items_b, MAX_W, 8, 2, BG, FG)
	var out: Image = L.new_image(maxi(strip_a.get_width(), strip_b.get_width()), strip_a.get_height() + strip_b.get_height() + 16, BG)
	out.blit_rect(strip_a, Rect2i(Vector2i.ZERO, strip_a.get_size()), Vector2i.ZERO)
	out.blit_rect(strip_b, Rect2i(Vector2i.ZERO, strip_b.get_size()), Vector2i(0, strip_a.get_height() + 16))
	return out


# ---------------------------------------------------------------------------
# Composição 2D para comparar com a clareira (não é tela do jogo)
# ---------------------------------------------------------------------------

func _preview_scene(spr: Dictionary, tex: Dictionary) -> Image:
	var cols: int = 14
	var rows: int = 11
	var img: Image = L.new_image(cols * 32, rows * 32, BG)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 160858
	var wall_y: int = 128
	var gap_x0: int = 224
	var gap_x1: int = 288
	# Chão: mata no fundo com trilha, arena no meio, terraço e chão baixo na frente
	for j: int in rows:
		for i: int in cols:
			var key: String = "grass_arena_%d" % rng.randi_range(0, 3)
			if j < 5:
				key = "grass_forest_%d" % rng.randi_range(0, 1)
				if i == 7 or i == 8:
					key = "dirt_%d" % rng.randi_range(0, 1)
			elif j >= 10:
				key = "grass_forest_%d" % rng.randi_range(0, 1)
				if i == 7 or i == 8:
					key = "dirt_%d" % rng.randi_range(0, 1)
			img.blit_rect(tex[key], Rect2i(0, 0, 32, 32), Vector2i(i * 32, j * 32))
	# Lajotas soltas na arena
	for p: Vector2i in [Vector2i(3, 6), Vector2i(4, 6), Vector2i(3, 7)]:
		img.blit_rect(tex["ruin_tile"], Rect2i(0, 0, 32, 32), p * 32)
	# Sprites atrás do muro (mata)
	var back: Array = [
		["tree_big_1", 30, 118], ["tree_big_0", 120, 112], ["tree_big_2", 330, 114], ["tree_big_0", 425, 120],
		["tree_small_0", 80, 124], ["tree_small_1", 190, 122], ["tree_small_0", 380, 126],
		["bush_0", 160, 127], ["bush_2", 300, 127], ["bush_1", 262, 116], ["grass_tuft_2", 210, 110],
		["grass_tuft_2", 285, 96],
	]
	_draw_sprites(img, spr, back)
	# Muro: topo (16 px) e face (16 px), com falha onde a trilha entra
	for i: int in cols:
		var x: int = i * 32
		if x >= gap_x0 and x < gap_x1:
			continue
		img.blit_rect(tex["wall_top"], Rect2i(0, 0, 32, 16), Vector2i(x, wall_y))
		img.blit_rect(tex["wall_face"], Rect2i(0, 0, 32, 16), Vector2i(x, wall_y + 16))
	# Arena: monólitos na lateral, capim e flores
	var mid: Array = [
		["monolith_0", 34, 186], ["monolith_1", 66, 190],
		["grass_tuft_0", 110, 200], ["grass_tuft_1", 180, 236], ["flower_0", 150, 214],
		["flower_1", 300, 206], ["grass_tuft_0", 330, 240], ["flower_2", 390, 226],
		["grass_tuft_1", 250, 180], ["bush_2", 420, 196], ["flower_0", 230, 246],
	]
	_draw_sprites(img, spr, mid)
	# Frente do terraço: franja de grama + lateral de pedra
	for i: int in cols:
		img.blit_rect(tex["step_side_grass"], Rect2i(0, 0, 32, 32), Vector2i(i * 32, 256))
		img.blit_rect(tex["step_side"], Rect2i(0, 0, 32, 32), Vector2i(i * 32, 288))
	var front: Array = [
		["grass_tuft_1", 40, 344], ["flower_2", 120, 348], ["bush_1", 370, 350], ["grass_tuft_0", 300, 340],
	]
	_draw_sprites(img, spr, front)
	return L.scaled(img, 2)


func _draw_sprites(img: Image, spr: Dictionary, list: Array) -> void:
	var sorted: Array = list.duplicate()
	sorted.sort_custom(func(a: Array, b: Array) -> bool: return a[2] < b[2])
	for it: Array in sorted:
		var s: Image = spr[it[0]]
		# Âncora: centro da borda de baixo
		L.paste(img, s, int(it[1]) - (s.get_width() >> 1), int(it[2]) - s.get_height())
