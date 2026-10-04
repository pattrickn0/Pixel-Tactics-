class_name WallSegment
extends RefCounted
## Trecho de 1 unidade do muro da arena (dado puro).
## Fica sobre a aresta entre uma célula da arena e uma de fora; a espessura vai para fora.

var start: Vector2 = Vector2.ZERO
var end: Vector2 = Vector2.ZERO
## Direção (vizinhança 4) da célula de dentro para a de fora.
var outward: Vector2i = Vector2i.ZERO
## Célula da arena do lado de dentro.
var cell: Vector2i = Vector2i.ZERO
## Altura acima do chão, em unidades. 0 = falha.
var height: float = 0.0


func is_gap() -> bool:
	return height <= 0.0


func midpoint() -> Vector2:
	return (start + end) * 0.5
