class_name MapStair
extends RefCounted
## Escada de pedra (dado puro). Sobe em direção a up_direction (qualquer das 4 direções).
## Cada nível tem MapData.STAIR_STEPS_PER_LEVEL degraus e ocupa 1 célula na direção da
## subida; a escada ocupa width × levels células. A célula k (contada a partir de baixo)
## guarda em MapData.heights o nível base_level + k.

var cells: Array[Vector2i] = []
var up_direction: Vector2i = Vector2i(0, -1)
## Nível do chão de onde a escada sai (na chegada de baixo).
var base_level: int = 0
## Quantos níveis a escada sobe (1 ou 2).
var levels: int = 1


## Células de chegada embaixo (na frente do primeiro degrau, fora da escada).
func arrival_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell: Vector2i in cells:
		var below: Vector2i = cell - up_direction
		if not cells.has(below):
			result.append(below)
	return result


## Células de chegada em cima (logo depois do último degrau, fora da escada).
func landing_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell: Vector2i in cells:
		var above: Vector2i = cell + up_direction
		if not cells.has(above):
			result.append(above)
	return result
