class_name ArtLibrary
extends RefCounted
## Texturas, materiais e malhas de sprite do mapa.
## Carrega os PNG de assets/ (nomes da spec A01) quando existem e foram importados;
## senão usa o placeholder de mesmo nome e tamanho (PlaceholderArt). Tudo fica em cache.

const TEXTURE_DIR: String = "res://assets/textures/"
const CARDS_DIR: String = "res://assets/textures/cards/"
const SPRITE_DIR: String = "res://assets/sprites/"

## Famílias com variantes e quantas a A01 define.
const TERRAIN_FAMILIES: Dictionary = {"grass_arena": 4, "grass_forest": 2, "dirt": 2}
const SPRITE_FAMILIES: Dictionary = {
	"tree_big": 3, "tree_small": 2, "bush": 3, "grass_tuft": 3, "flower": 3, "monolith": 2, "mushroom": 4,
}
## Intensidade da emissão da runa (passa do limiar do glow; o resto da cena não).
const RUNE_EMISSION: float = 4.0
## Distância da camada da runa à frente do monólito, em z local do billboard (evita z-fighting).
const RUNE_OFFSET: float = 0.02

## Ignora os PNG do disco (para testar só com placeholders).
var force_placeholders: bool = false

var _textures: Dictionary = {}
var _from_disk: Dictionary = {}
var _families: Dictionary = {}
var _materials: Dictionary = {}
var _sprite_meshes: Dictionary = {}


## Nome da textura de chão da família para a variante (variant % variantes disponíveis).
func terrain_variant_name(family: String, variant: int) -> String:
	var names: PackedStringArray = _family_names(family, int(TERRAIN_FAMILIES[family]), TEXTURE_DIR)
	return names[posmod(variant, names.size())]


## Nome do sprite da família para a variante (variant % variantes disponíveis).
func sprite_variant_name(family: String, variant: int) -> String:
	var dir: String = CARDS_DIR if family == "mushroom" else SPRITE_DIR
	var names: PackedStringArray = _family_names(family, int(SPRITE_FAMILIES[family]), dir)
	return names[posmod(variant, names.size())]


func get_terrain_texture(art_name: String) -> Texture2D:
	return _get_texture(art_name, TEXTURE_DIR)


func get_sprite_texture(art_name: String) -> Texture2D:
	if art_name.begins_with("mushroom"):
		return _get_texture(art_name, CARDS_DIR)
	return _get_texture(art_name, SPRITE_DIR)


## Máscara da runa do monólito: o PNG *_rune; se faltar, extraída do sprite; senão placeholder.
func get_rune_texture(monolith_name: String) -> Texture2D:
	var rune_name: String = monolith_name + "_rune"
	if _textures.has(rune_name):
		return _textures[rune_name]
	var sprite: Texture2D = get_sprite_texture(monolith_name)
	var tex: Texture2D = null
	if bool(_from_disk.get(monolith_name, false)):
		tex = _load_from_disk(SPRITE_DIR + rune_name + ".png")
		if tex == null:
			tex = _image_texture(PlaceholderArt.extract_rune_mask(sprite.get_image()))
	else:
		tex = _image_texture(PlaceholderArt.make_image(rune_name))
	_textures[rune_name] = tex
	return tex


func is_from_disk(art_name: String) -> bool:
	return bool(_from_disk.get(art_name, false))


## Material opaco do terreno, muro e pedras com normal map da A02.
func terrain_material(art_name: String) -> StandardMaterial3D:
	var key: String = "terrain:" + art_name
	if _materials.has(key):
		return _materials[key]
	var mat := _base_material(get_terrain_texture(art_name))
	mat.texture_repeat = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var norm_tex: Texture2D = _get_texture(art_name + "_n", TEXTURE_DIR)
	if norm_tex != null:
		mat.normal_enabled = true
		mat.normal_texture = norm_tex
		mat.normal_scale = 0.5
	_materials[key] = mat
	return mat


## Material dos sprites em pé: recorte de alfa, sem cull, projeta sombra.
func sprite_material(art_name: String) -> StandardMaterial3D:
	var key: String = "sprite:" + art_name
	if _materials.has(key):
		return _materials[key]
	var mat := _base_material(get_sprite_texture(art_name))
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.5
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.texture_repeat = false
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	# Quad vertical com normal para cima: recebe sombra de si mesmo de forma ruim.
	mat.disable_receive_shadows = true
	_materials[key] = mat
	return mat


## Material da camada da runa: emissiva (só ela passa do limiar do glow), sem sombra.
func rune_material(monolith_name: String) -> StandardMaterial3D:
	var key: String = "rune:" + monolith_name
	if _materials.has(key):
		return _materials[key]
	var rune: Texture2D = get_rune_texture(monolith_name)
	var mat := _base_material(rune)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.5
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.texture_repeat = false
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	mat.render_priority = 1
	mat.disable_receive_shadows = true
	mat.emission_enabled = true
	mat.emission = Color.BLACK
	mat.emission_texture = rune
	mat.emission_energy_multiplier = RUNE_EMISSION
	_materials[key] = mat
	return mat


## Quad em pé com o tamanho do sprite (1 px = 1/32 unidade, sem escala), âncora no
## centro da base. A normal aponta para cima: o sprite recebe a mesma luz que o chão em volta.
## A camada da runa fica RUNE_OFFSET à frente em z local: com o billboard, +z local aponta
## para a câmera, então a runa fica na frente do monólito em qualquer ângulo.
func sprite_mesh(art_name: String, rune_layer: bool = false) -> ArrayMesh:
	var key: String = art_name + (":rune" if rune_layer else "")
	if _sprite_meshes.has(key):
		return _sprite_meshes[key]
	var tex: Texture2D = get_sprite_texture(art_name)
	var w: float = tex.get_width() * WorldScale.PIXEL_SIZE
	var h: float = tex.get_height() * WorldScale.PIXEL_SIZE
	var z: float = RUNE_OFFSET if rune_layer else 0.0
	var batch := MeshBatch.new()
	batch.add_quad(
		Vector3(-w * 0.5, h, z), Vector3(w * 0.5, h, z), Vector3(w * 0.5, 0.0, z), Vector3(-w * 0.5, 0.0, z),
		Vector3.UP, Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 1.0), Vector2(0.0, 1.0))
	var mesh := ArrayMesh.new()
	batch.commit(mesh, rune_material(art_name) if rune_layer else sprite_material(art_name))
	_sprite_meshes[key] = mesh
	return mesh


## Material de cartão recortado 3D (ex: franja de grama, folhas, flores).
func card_material(card_name: String) -> StandardMaterial3D:
	var key: String = "card:" + card_name
	if _materials.has(key):
		return _materials[key]
	var tex: Texture2D = _get_texture(card_name, CARDS_DIR)
	var mat := _base_material(tex)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.5
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.texture_repeat = true
	_materials[key] = mat
	return mat


func _base_material(tex: Texture2D) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.metallic_specular = 0.0
	mat.roughness = 1.0
	return mat


func _get_texture(art_name: String, dir: String) -> Texture2D:
	var cache_key: String = dir + art_name
	if _textures.has(cache_key):
		return _textures[cache_key]
	var tex: Texture2D = null
	if not force_placeholders:
		tex = _load_from_disk(dir + art_name + ".png")
	if tex != null:
		_from_disk[art_name] = true
	else:
		tex = _image_texture(PlaceholderArt.make_image(art_name))
	_textures[cache_key] = tex
	return tex


## Só carrega se o PNG já foi importado (tem .import); senão o load daria erro.
func _load_from_disk(path: String) -> Texture2D:
	if force_placeholders or not FileAccess.file_exists(path + ".import") or not ResourceLoader.exists(path):
		return null
	return ResourceLoader.load(path, "Texture2D") as Texture2D


func _image_texture(img: Image) -> ImageTexture:
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## Nomes disponíveis da família: os PNG que existem; se nenhum existe, todos (placeholders).
func _family_names(family: String, count: int, dir: String) -> PackedStringArray:
	if _families.has(family):
		return _families[family]
	var all_names := PackedStringArray()
	var on_disk := PackedStringArray()
	for i in count:
		var art_name: String = "%s_%d" % [family, i]
		all_names.append(art_name)
		if not force_placeholders and FileAccess.file_exists(dir + art_name + ".png.import"):
			on_disk.append(art_name)
	var names: PackedStringArray = on_disk if not on_disk.is_empty() else all_names
	_families[family] = names
	return names
