class_name MapTrail
extends RefCounted
## Trilha de terra que vem de uma borda do mapa até a arena (dado puro).

enum Border { NORTH, EAST, SOUTH, WEST }

var side: Border = Border.SOUTH
## Célula na borda do mapa onde a trilha começa.
var start_cell: Vector2i = Vector2i.ZERO
## Todas as células de terra da trilha fora da arena, na ordem do caminho.
var cells: Array[Vector2i] = []
## Células de terra que a trilha pintou dentro da arena (entrada que se dissolve).
var arena_cells: Array[Vector2i] = []
