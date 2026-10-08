@tool
class_name BenchMarker
extends MarkerBox
## Marca a reserva de um time. size = faixa inteira (terrace_rect). usable_margin tira a
## borda da área útil: (esquerda, topo, direita, fundo) em eixos locais, "topo" = -Z local.
## A altura do piso vem do HeightArea das peças do terraço, no ponto central da área útil.

## 0 = sul (embaixo na câmera padrão), 1 = norte.
@export_range(0, 1) var team: int = 0
@export var usable_margin: Vector4 = Vector4(0.5, 0.5, 0.5, 0.25):
	set(value):
		usable_margin = value
		_refresh_gizmo()


func _init() -> void:
	size = Vector2(20.0, 3.0)


func gizmo_color() -> Color:
	return Color(0.2, 0.6, 1.0)


func gizmo_height() -> float:
	return 0.3


## Faixa inteira da reserva no mundo.
func terrace_rect() -> Rect2:
	return world_rect()


## Área útil no mundo.
func usable_rect() -> Rect2:
	var local_pos := -size * 0.5 + Vector2(usable_margin.x, usable_margin.y)
	var local_size := size - Vector2(usable_margin.x + usable_margin.z, usable_margin.y + usable_margin.w)
	return MarkerBox.rect_of(global_transform, Rect2(local_pos, local_size))
