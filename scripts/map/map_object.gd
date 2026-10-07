class_name MapObject
extends RefCounted
## Objeto de decoração do mapa (dado puro). A posição é contínua no plano X/Z.

enum ObjectKind { TREE_BIG, TREE_SMALL, BUSH, GRASS_TUFT, FLOWER, ROCK, MONOLITH, MUSHROOM }

## Quantas variantes cada tipo tem (números da spec de arte A01; ROCK = formas 3D).
const VARIANT_COUNTS: Dictionary = {
	ObjectKind.TREE_BIG: 3,
	ObjectKind.TREE_SMALL: 2,
	ObjectKind.BUSH: 3,
	ObjectKind.GRASS_TUFT: 3,
	ObjectKind.FLOWER: 3,
	ObjectKind.ROCK: 3,
	ObjectKind.MONOLITH: 2,
	ObjectKind.MUSHROOM: 4,
}

var kind: ObjectKind = ObjectKind.TREE_BIG
var position: Vector2 = Vector2.ZERO
var variant: int = 0


func _init(p_kind: ObjectKind = ObjectKind.TREE_BIG, p_position: Vector2 = Vector2.ZERO, p_variant: int = 0) -> void:
	kind = p_kind
	position = p_position
	variant = p_variant


static func variant_count(p_kind: ObjectKind) -> int:
	return int(VARIANT_COUNTS[p_kind])
