@tool
class_name ArenaMarker
extends MarkerBox
## Marca a arena (área de luta). Uma só por mapa; o chão dentro dela fica em altura 0,0.


func _init() -> void:
	size = Vector2(20.0, 18.0)


func gizmo_color() -> Color:
	return Color(1.0, 0.3, 0.2)
