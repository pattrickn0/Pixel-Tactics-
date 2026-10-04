class_name RockMeshBuilder
extends RefCounted
## Pedras grandes 3D: malha low poly gerada em código (forma por variante), textura rock.

## Por variante: lados da base, raio, altura.
const SHAPES: Array = [
	Vector3(7.0, 0.42, 0.5), # pedregulho redondo
	Vector3(6.0, 0.46, 0.3), # laje achatada
	Vector3(5.0, 0.32, 0.72), # bloco alto
]


static func build(data: MapData, art: ArtLibrary) -> ArrayMesh:
	var batch := MeshBatch.new()
	for obj: MapObject in data.objects:
		if obj.kind != MapObject.ObjectKind.ROCK:
			continue
		# Forma vem de um RNG semeado pela posição: mesmo mapa = mesmas pedras.
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(obj.position)
		var base := Vector3(obj.position.x, data.get_height_at(obj.position), obj.position.y)
		_add_rock(batch, rng, base, SHAPES[posmod(obj.variant, SHAPES.size())])
	var mesh := ArrayMesh.new()
	batch.commit(mesh, art.terrain_material("rock"))
	return mesh


static func _add_rock(batch: MeshBatch, rng: RandomNumberGenerator, base: Vector3, shape: Vector3) -> void:
	var sides: int = int(shape.x)
	var radius: float = shape.y
	var height: float = shape.z
	var rot: float = rng.randf() * TAU
	var bottom: Array[Vector3] = []
	var middle: Array[Vector3] = []
	for k in sides:
		var ang: float = rot + TAU * k / sides + rng.randf_range(-0.2, 0.2)
		var r: float = radius * rng.randf_range(0.85, 1.08)
		# A base afunda um pouco no chão para não flutuar.
		bottom.append(base + Vector3(cos(ang) * r, -0.05, sin(ang) * r))
		var rm: float = r * rng.randf_range(0.68, 0.82)
		middle.append(base + Vector3(cos(ang + 0.2) * rm, height * rng.randf_range(0.5, 0.66), sin(ang + 0.2) * rm))
	var top := base + Vector3(rng.randf_range(-0.06, 0.06), height, rng.randf_range(-0.06, 0.06))
	var inside := base + Vector3(0.0, height * 0.35, 0.0)
	for k in sides:
		var k2: int = (k + 1) % sides
		_add_face(batch, bottom[k], bottom[k2], middle[k2], inside)
		_add_face(batch, bottom[k], middle[k2], middle[k], inside)
		_add_face(batch, middle[k], middle[k2], top, inside)


## Triângulo com normal plana (visual low poly) virada para fora; UV por projeção de caixa.
static func _add_face(batch: MeshBatch, a: Vector3, b: Vector3, c: Vector3, inside: Vector3) -> void:
	# No Godot a frente é horária: (b - a) x (c - a) aponta para dentro.
	var cr: Vector3 = (b - a).cross(c - a)
	var centroid: Vector3 = (a + b + c) / 3.0
	if cr.dot(centroid - inside) > 0.0:
		var tmp: Vector3 = b
		b = c
		c = tmp
		cr = -cr
	var n: Vector3 = -cr.normalized()
	batch.add_triangle(a, b, c, n, _box_uv(a, n), _box_uv(b, n), _box_uv(c, n))


static func _box_uv(p: Vector3, n: Vector3) -> Vector2:
	var an := n.abs()
	if an.y >= an.x and an.y >= an.z:
		return Vector2(p.x, p.z)
	if an.x >= an.z:
		return Vector2(p.z, -p.y)
	return Vector2(p.x, -p.y)
