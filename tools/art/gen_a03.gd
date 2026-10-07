extends SceneTree
## Gera toda a arte da spec A03 (27 texturas opacas + 13 normal maps + 28 cartões = 68 PNG)
## e as prévias em docs/art-preview/. Os cartões rune_* não são tocados.
## Rodar da raiz do projeto:
##   "$G" --headless --path . --script tools/art/gen_a03.gd

const TEX = preload("res://tools/art/gen_a03_textures.gd")
const CRD = preload("res://tools/art/gen_a03_cards.gd")
const PRV = preload("res://tools/art/gen_a03_preview.gd")
const L = preload("res://tools/art/art_lib.gd")

const TEX_DIR: String = "res://assets/textures/"
const CARDS_DIR: String = "res://assets/textures/cards/"
const PREVIEW_DIR: String = "res://docs/art-preview/"


func _initialize() -> void:
	for d: String in [TEX_DIR, CARDS_DIR, PREVIEW_DIR]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(d))
	var saved: int = 0
	print("A03: texturas opacas e normal maps...")
	var tcv: Dictionary = TEX.build_all()
	var tex: Dictionary = {}
	var normals: Dictionary = {}
	for it: Array in TEX.ORDER:
		var key: String = it[0]
		tex[key] = tcv[key].to_image()
		_save(tex[key], TEX_DIR + key + ".png")
		saved += 1
		if it[1]:
			normals[key] = tcv[key].normal_image()
			_save(normals[key], TEX_DIR + key + "_n.png")
			saved += 1
	print("A03: cartões...")
	var ccv: Dictionary = CRD.build_all()
	var cards: Dictionary = {}
	for it: Array in CRD.ORDER:
		var key: String = it[0]
		cards[key] = ccv[key].to_image()
		_save(cards[key], CARDS_DIR + key + ".png")
		saved += 1
	print("A03: prévias...")
	var all: Dictionary = tex.duplicate()
	all.merge(cards)
	_save(PRV.textures_sheet(all, normals, TEX.ORDER), PREVIEW_DIR + "a03-texturas.png")
	_save(PRV.cards_sheet(tex, cards, CRD.ORDER), PREVIEW_DIR + "a03-cartoes.png")
	var sc: Image = PRV.scene(all, cards)
	_save(L.scaled(sc, 2), PREVIEW_DIR + "a03-cena.png")
	_save(PRV.comparison(sc, tex, cards), PREVIEW_DIR + "a03-comparacao.png")
	print("A03 GEN: %d PNG gravados" % saved)
	quit(0)


func _save(img: Image, path: String) -> void:
	var err: Error = img.save_png(ProjectSettings.globalize_path(path))
	if err != OK:
		push_error("Falha ao gravar %s (%d)" % [path, err])
