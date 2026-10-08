@tool
class_name HeightArea
extends MarkerBox
## Marca um pedaço de chão com topo plano. top é relativo à altura do nó (y global).
## Cada peça estrutural do kit traz os seus como filhos.

@export var top: float = 0.5:
	set(value):
		top = value
		_refresh_gizmo()


func gizmo_color() -> Color:
	return Color(0.3, 1.0, 0.3)


func gizmo_height() -> float:
	return maxf(top, 0.05)


## Altura absoluta do topo.
func world_top() -> float:
	return global_position.y + top
