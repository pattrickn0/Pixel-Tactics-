class_name MapStair
extends RefCounted
## Lance de escada (dado puro). Vem de um marcador StairArea da cena.
## O degrau k (a partir de baixo) tem altura base_height + step_rise × (k + 1) e ocupa
## tread_depth de comprimento no sentido de up_direction.

var rect: Rect2 = Rect2()
## Sentido da subida no plano X/Z (uma das 4 direções).
var up_direction: Vector2i = Vector2i(0, -1)
## Altura do chão de onde a escada sai (do lado de baixo).
var base_height: float = 0.0
var step_rise: float = 0.25
var tread_depth: float = 0.5
var step_count: int = 1


## Altura do degrau em pos (assume que pos está dentro de rect).
func height_at(pos: Vector2) -> float:
	var walked: float = 0.0
	var origin: Vector2 = rect.position
	var far: Vector2 = rect.end
	if up_direction.x > 0:
		walked = pos.x - origin.x
	elif up_direction.x < 0:
		walked = far.x - pos.x
	elif up_direction.y > 0:
		walked = pos.y - origin.y
	else:
		walked = far.y - pos.y
	var step: int = clampi(floori(walked / tread_depth), 0, step_count - 1)
	return base_height + step_rise * float(step + 1)
