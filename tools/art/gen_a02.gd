extends SceneTree
## Gera toda a arte da spec A02 (18 texturas opacas + 18 normal maps + 18 cartões)
## e salva em assets/textures/ e assets/textures/cards/.
## Rodar da raiz do projeto:
##   "$G" --headless --path . --script tools/art/gen_a02.gd

const TEX = preload("res://tools/art/gen_a02_textures.gd")
const CRD = preload("res://tools/art/gen_a02_cards.gd")
const SPR = preload("res://tools/art/gen_a02_sprites.gd")

const TEX_DIR: String = "res://assets/textures/"
const CARDS_DIR: String = "res://assets/textures/cards/"
const SPR_DIR: String = "res://assets/sprites/"
const PREVIEW_DIR: String = "res://docs/art-preview/"
const ENABLED: bool = false # A02 substituída pela A03


func _initialize() -> void:
	# Guarda: a A02 virou histórico; rodar de novo sobrescreveria a arte da A03.
	if not ENABLED:
		printerr("A02 substituída pela A03 (docs/specs/A03-arte-minimalista.md). Use tools/art/gen_a03.gd.")
		quit(1)
		return
	for d: String in [TEX_DIR, CARDS_DIR, SPR_DIR, PREVIEW_DIR]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(d))

	print("Gerando texturas opacas e normal maps A02...")
	var textures: Dictionary = TEX.build_all()
	for key: String in TEX.ORDER:
		var cv = textures[key]
		var albedo_img: Image = cv.to_image()
		var normal_img: Image = cv.normal_image()
		_save(albedo_img, TEX_DIR + key + ".png")
		_save(normal_img, TEX_DIR + key + "_n.png")

	print("Gerando cartões com alfa recortado A02...")
	var cards: Dictionary = CRD.build_all()
	for key: String in CRD.ORDER:
		var cv = cards[key]
		var card_img: Image = cv.to_image()
		_save(card_img, CARDS_DIR + key + ".png")

	print("Gerando sprites naturais (árvores, pinheiros, arbustos, monólitos) A02...")
	var sprites: Dictionary = SPR.build_all()
	for key: String in SPR.ORDER:
		var s_img: Image = sprites[key]
		_save(s_img, SPR_DIR + key + ".png")

	print("A02 GEN CONCLUÍDO: %d texturas, %d normal maps, %d cartões, %d sprites" % [
		TEX.ORDER.size(), TEX.ORDER.size(), CRD.ORDER.size(), SPR.ORDER.size()
	])
	quit(0)


func _save(img: Image, path: String) -> void:
	var abs_path: String = ProjectSettings.globalize_path(path)
	var err: Error = img.save_png(abs_path)
	if err != OK:
		push_error("Falha ao salvar %s (%d)" % [abs_path, err])
