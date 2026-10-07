class_name MapTrail
extends RefCounted
## Trilha da floresta: sai do topo de uma escada de entrada e vai até a borda do mapa
## (dado puro). Pode ter um ramal, que entra em cells também.

enum Border { NORTH, EAST, SOUTH, WEST }

## Lado do anfiteatro de onde a trilha sai.
var side: Border = Border.WEST
## Primeira célula da trilha (no topo da escada de entrada).
var start_cell: Vector2i = Vector2i.ZERO
## Célula da trilha principal na borda do mapa.
var border_cell: Vector2i = Vector2i.ZERO
## Todas as células da trilha (com o ramal), na ordem em que foram pintadas.
var cells: Array[Vector2i] = []
## Trilha de pedra (STONE_PATH) ou de terra (DIRT).
var stone: bool = false
var branch_count: int = 0
