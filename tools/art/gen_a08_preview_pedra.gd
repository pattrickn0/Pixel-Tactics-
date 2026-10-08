extends SceneTree
## A08: prévia da pedra (docs/art-preview/a08-pedra.png). Lê os PNG gerados por gen_a08_pedra.gd.
##   "$G" --headless --path . --script tools/art/gen_a08_preview_pedra.gd

const PL = preload("res://tools/art/paint_lib.gd")

const BG := Color("#5a5a60")
const FG := Color("#f0ece4")
const REF_WALL := Rect2i(226, 352, 250, 62)


func _initialize() -> void:
	var wb: Image = PL.load_tex("stone/wall_blocks")
	var wm: Image = PL.load_tex("stone/wall_blocks_mossy")
	var wt: Image = PL.load_tex("stone/wall_top")
	var sl: Image = PL.load_tex("stone/slabs")
	var ref: Image = PL.load_ref()
	var rows: Array = []
	var k: float = 2.0
	rows.append(_labeled(PL.scaled(_elevation(wb, wt, 64), k), "ELEVACAO 8 U, FACE 1.0 + TOPO (WALL_TOP ACHATADO 0.45), WALL_BLOCKS X2"))
	rows.append(_labeled(PL.scaled(_elevation(wm, wt, 64), k), "ELEVACAO 8 U, FACE 1.0 + TOPO, WALL_BLOCKS_MOSSY (FACE EXTERNA) X2"))
	rows.append(_hcat([_labeled(PL.scaled(_elevation(wb, wt, 32), k), "FACE 0.5 + TOPO, WALL_BLOCKS X2"),
		_labeled(PL.scaled(_elevation(wm, wt, 32), k), "FACE 0.5 + TOPO, MOSSY X2")]))
	var refc: Image = PL.scaled(ref.get_region(REF_WALL), 4.0, Image.INTERPOLATE_LANCZOS)
	rows.append(_labeled(refc, "REFERENCIA: MURO SUL (CRISTA COM MUSGO, FACE EXTERNA ESCURA E ESCADA) X4"))
	var mos: Image = PL.scaled(PL.tiled(sl, 2, 2), 0.5)
	var tex_row: Array = [_labeled(mos, "SLABS 2X2 (16X16 U) 50%"), _labeled(sl, "SLABS 512 (8X8 U) 100%")]
	var stack: Array = []
	for e: Array in [["wall_blocks", wb], ["wall_blocks_mossy", wm], ["wall_top", wt]]:
		var img: Image = e[1]
		stack.append(_labeled(PL.tiled(img, 1, 2), str(e[0]).to_upper() + " 512X128, REPETIDA 1X2"))
	tex_row.append(_vcat(stack))
	var nstack: Array = []
	for nm: String in ["wall_blocks_n", "wall_blocks_mossy_n", "wall_top_n"]:
		nstack.append(_labeled(PL.scaled(PL.load_tex("stone/" + nm), 0.5), nm.to_upper() + " 50%"))
	nstack.append(_labeled(PL.scaled(PL.load_tex("stone/slabs_n"), 0.5), "SLABS_N 50%"))
	tex_row.append(_vcat(nstack))
	rows.append(_hcat(tex_row))
	var out: Image = _vcat(rows)
	PL.save_png(out, PL.PREVIEW + "a08-pedra.png")
	quit()


## Elevação de 8 unidades: topo achatado (faixa de 1 u do wall_top a 0,45) sobre a face (rows linhas).
func _elevation(face: Image, top: Image, rows: int) -> Image:
	var t: Image = top.get_region(Rect2i(0, 0, 512, 64))
	t.resize(512, 29, Image.INTERPOLATE_LANCZOS)
	var f: Image = face.get_region(Rect2i(0, 0, 512, rows))
	var out := Image.create(512, 29 + rows, false, Image.FORMAT_RGBA8)
	out.blit_rect(t, Rect2i(0, 0, 512, 29), Vector2i.ZERO)
	out.blit_rect(f, Rect2i(0, 0, 512, rows), Vector2i(0, 29))
	return out


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
	var h: int = 12
	for im: Image in imgs:
		w = maxi(w, im.get_width())
		h += im.get_height() + 12
	var out := Image.create(w + 24, h, false, Image.FORMAT_RGBA8)
	out.fill(BG)
	var y: int = 12
	for im: Image in imgs:
		out.blit_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i(12, y))
		y += im.get_height() + 12
	return out
