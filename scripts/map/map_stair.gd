class_name MapStair
extends RefCounted
## Escada de um terraço da arena (dado puro).
## Ocupa as células de baixo (nível base) e sobe em direção a up_direction.

var cells: Array[Vector2i] = []
## Nesta fase sempre sobe para o norte (-Z), com os degraus virados para a câmera.
var up_direction: Vector2i = Vector2i(0, -1)
var base_level: int = 0
