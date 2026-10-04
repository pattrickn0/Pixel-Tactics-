class_name MapRenderer
extends Node3D
## Visual 3D do mapa. Só lê o MapData recebido por map_generated; não tem regra de jogo.
## A cada mapa novo apaga tudo do anterior e monta de novo (sem recarregar a cena).

## Família de sprite de cada tipo de objeto (ROCK é malha 3D).
const SPRITE_FAMILY: Dictionary = {
	MapObject.ObjectKind.TREE_BIG: "tree_big",
	MapObject.ObjectKind.TREE_SMALL: "tree_small",
	MapObject.ObjectKind.BUSH: "bush",
	MapObject.ObjectKind.GRASS_TUFT: "grass_tuft",
	MapObject.ObjectKind.FLOWER: "flower",
	MapObject.ObjectKind.MONOLITH: "monolith",
}
## A camada da runa fica um pouco à frente do monólito (evita z-fighting).
const RUNE_OFFSET: float = 0.02

var art: ArtLibrary = ArtLibrary.new()
var current_map: MapData = null


func show_map(map_data: MapData) -> void:
	current_map = map_data
	_clear()
	_add_mesh("Terrain", TerrainMeshBuilder.build(map_data, art))
	_add_mesh("Walls", WallMeshBuilder.build(map_data, art))
	_add_mesh("Rocks", RockMeshBuilder.build(map_data, art))
	_add_sprites(map_data)


func _clear() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()


func _add_mesh(node_name: String, mesh: ArrayMesh) -> void:
	if mesh.get_surface_count() == 0:
		return
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mi)


## Sprites em pé agrupados por textura num MultiMeshInstance3D cada (poucos nós, poucas
## chamadas de desenho). A câmera nunca gira e olha para -Z, então quads fixos no plano
## X/Y equivalem ao billboard só no eixo Y.
func _add_sprites(map_data: MapData) -> void:
	var groups: Dictionary = {}
	var runes: Dictionary = {}
	for obj: MapObject in map_data.objects:
		if not SPRITE_FAMILY.has(obj.kind):
			continue
		var sprite_name: String = art.sprite_variant_name(SPRITE_FAMILY[obj.kind], obj.variant)
		var pos := Vector3(obj.position.x, map_data.get_height_at(obj.position), obj.position.y)
		_append_position(groups, sprite_name, pos)
		if obj.kind == MapObject.ObjectKind.MONOLITH:
			_append_position(runes, sprite_name, pos + Vector3(0.0, 0.0, RUNE_OFFSET))
	for sprite_name: String in groups:
		_add_multimesh("Sprites_" + sprite_name, art.sprite_mesh(sprite_name), groups[sprite_name], true)
	for sprite_name: String in runes:
		_add_multimesh("Runes_" + sprite_name, art.sprite_mesh(sprite_name, true), runes[sprite_name], false)


func _append_position(groups: Dictionary, key: String, pos: Vector3) -> void:
	if not groups.has(key):
		groups[key] = PackedVector3Array()
	var list: PackedVector3Array = groups[key]
	list.append(pos)


func _add_multimesh(node_name: String, mesh: Mesh, positions: PackedVector3Array, cast_shadow: bool) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = positions.size()
	for i in positions.size():
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, positions[i]))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadow \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
