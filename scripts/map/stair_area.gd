@tool
class_name StairArea
extends MarkerBox
## Marca o trecho andável de um lance de escada. Sobe para -Z local. A altura base é o y
## global do nó (chão de onde o lance sai); cada degrau sobe step_rise e mede tread_depth.

@export_range(1, 12) var step_count: int = 6:
	set(value):
		step_count = value
		_refresh_gizmo()
@export var step_rise: float = 0.25
@export var tread_depth: float = 0.5


func gizmo_color() -> Color:
	return Color(1.0, 0.6, 0.1)


func gizmo_height() -> float:
	return step_rise * float(step_count)


## Direção de subida no mundo (múltiplo de 90°).
func up_direction() -> Vector2i:
	var dir: Vector3 = global_transform.basis * Vector3(0.0, 0.0, -1.0)
	if absf(dir.x) > absf(dir.z):
		return Vector2i(1 if dir.x > 0.0 else -1, 0)
	return Vector2i(0, 1 if dir.z > 0.0 else -1)
