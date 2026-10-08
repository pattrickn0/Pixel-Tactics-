class_name MapHeightArea
extends RefCounted
## Retângulo de chão com topo plano (dado puro). Vem de um marcador HeightArea da cena.
## Retângulo semiaberto: [x0, x1) × [z0, z1).

var rect: Rect2 = Rect2()
var top: float = 0.0


func _init(p_rect: Rect2 = Rect2(), p_top: float = 0.0) -> void:
	rect = p_rect
	top = p_top
