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
	MapObject.ObjectKind.MUSHROOM: "mushroom",
}

var art: ArtLibrary = ArtLibrary.new()
var current_map: MapData = null


func show_map(map_data: MapData) -> void:
	current_map = map_data
	_clear()
	_add_mesh("Terrain", TerrainMeshBuilder.build(map_data, art))
	_add_mesh("Rocks", RockMeshBuilder.build(map_data, art))
	var prop_meshes: Dictionary = PropMeshBuilder.build(map_data, art)
	for prop_name: String in prop_meshes:
		_add_mesh("Prop_" + prop_name, prop_meshes[prop_name])
	_add_mesh("Skirt", SkirtMeshBuilder.build(map_data, art))
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
## chamadas de desenho). O material faz billboard só no eixo Y: o quad sempre fica de
## frente para a câmera, que gira em volta da arena. A runa usa a mesma posição do
## monólito; o deslocamento dela está no próprio quad (z local, ver ArtLibrary.sprite_mesh).
## Limitação conhecida: o billboard também vale na passada de sombra (pela câmera
## principal), então com o quad alinhado ao sol a sombra vira uma linha. Fica até a spec 006
## trocar esses sprites por modelos 3D.
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
			_append_position(runes, sprite_name, pos)
	_add_backdrop_forest(map_data, groups)
	for sprite_name: String in groups:
		_add_multimesh("Sprites_" + sprite_name, art.sprite_mesh(sprite_name), groups[sprite_name], true)
	for sprite_name: String in runes:
		_add_multimesh("Runes_" + sprite_name, art.sprite_mesh(sprite_name, true), runes[sprite_name], false)


func _add_backdrop_forest(map_data: MapData, groups: Dictionary) -> void:
	var skirt_y: float = SkirtMeshBuilder.skirt_height(map_data)
	var rng := RandomNumberGenerator.new()
	rng.seed = map_data.map_seed ^ 0xF09E57
	var trail_starts: Array[Vector2] = []
	for trail: MapTrail in map_data.trails:
		# Abertura na mata de fundo onde a trilha sai do mapa.
		trail_starts.append(Vector2(trail.border_cell.x + 0.5, trail.border_cell.y + 0.5))

	var min_x: float = -18.0
	var max_x: float = float(map_data.size.x) + 18.0
	var min_z: float = -20.0
	var max_z: float = float(map_data.size.y) + 12.0
	var step: float = 1.4

	var z: float = min_z
	var row: int = 0
	while z <= max_z:
		var x_offset: float = (0.7 if (row % 2 == 1) else 0.0)
		var x: float = min_x + x_offset
		while x <= max_x:
			var inside_map: bool = (x >= 0.0 and x < float(map_data.size.x) and z >= 0.0 and z < float(map_data.size.y))
			if not inside_map:
				var near_trail := false
				var p2 := Vector2(x, z)
				for ts: Vector2 in trail_starts:
					if p2.distance_to(ts) < 2.5:
						near_trail = true
						break
				if not near_trail:
					var jx: float = x + rng.randf_range(-0.35, 0.35)
					var jz: float = z + rng.randf_range(-0.35, 0.35)
					var pos := Vector3(jx, skirt_y, jz)
					var roll: float = rng.randf()
					if roll < 0.65:
						var v: int = rng.randi_range(0, 2)
						_append_position(groups, art.sprite_variant_name("tree_big", v), pos)
					elif roll < 0.88:
						var v: int = rng.randi_range(0, 1)
						_append_position(groups, art.sprite_variant_name("tree_small", v), pos)
					elif roll < 0.94:
						var v: int = 2
						_append_position(groups, art.sprite_variant_name("bush", v), pos)
					else:
						var v: int = 2
						_append_position(groups, art.sprite_variant_name("flower", v), pos)
			x += step
		z += step
		row += 1


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
