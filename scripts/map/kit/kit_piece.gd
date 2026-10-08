@tool
class_name KitPiece
extends Node3D
## Peça do kit do mapa (spec 011). Cada cena de scenes/kit/ tem um KitPiece na raiz, um filho
## "Mesh" (MeshInstance3D com a malha de assets/models/kit/, gerada por tools/kit/build_kit.gd)
## e os marcadores de altura/escada (HeightArea, StairArea) quando a peça é estrutural.
## Pivô: centro da pegada, na base. Frente = +Z local.

## Largura (X), altura (Y) e fundo (Z) da peça, em unidades do mundo.
@export var size: Vector3 = Vector3(1.0, 0.5, 1.0)
## Peça do anel/escadas: a posição fica na grade de 0,5 e a rotação em múltiplos de 90°.
@export var structural: bool = false
## Árvore ou prop: entra no grupo map_obstacle (regras futuras e testes).
@export var obstacle: bool = false


func _ready() -> void:
	if obstacle and not Engine.is_editor_hint():
		add_to_group("map_obstacle")


## Pegada da peça no plano X/Z do mundo (largura × fundo, sob a transformação global).
func get_footprint() -> Rect2:
	return MarkerBox.rect_of(global_transform, Rect2(Vector2(-size.x, -size.z) * 0.5, Vector2(size.x, size.z)))
