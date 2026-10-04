class_name MapData
extends RefCounted
## Dados puros de um mapa gerado (sem nós, sem visual, sem assets).
## Célula (cx, cz) ocupa X em [cx, cx+1) e Z em [cz, cz+1). Arrays planos: cz * size.x + cx.
## Posições contínuas: Vector2(x, z) em unidades do mundo.

enum Ground { ARENA_GRASS, FOREST_GRASS, DIRT, RUIN_TILE }

## Degraus de cada escada (cada um com 1/STAIR_STEPS de nível).
const STAIR_STEPS: int = 4
## Quanto o clamp puxa o ponto para dentro da célula da arena.
const CLAMP_INSET: float = 0.001

var map_seed: int = 0
var size: Vector2i = Vector2i.ZERO
var heights: PackedInt32Array = PackedInt32Array()
var ground: PackedByteArray = PackedByteArray()
var arena_mask: PackedByteArray = PackedByteArray()
var arena_base_level: int = 0
var arena_center: Vector2 = Vector2.ZERO
## Caixa da arena (em unidades, alinhada às células).
var arena_rect: Rect2 = Rect2()
var wall_thickness: float = 0.5
var wall_segments: Array[WallSegment] = []
var stairs: Array[MapStair] = []
var trails: Array[MapTrail] = []
var objects: Array[MapObject] = []

# Caches derivados (não entram no fingerprint).
var _stair_cells: Dictionary = {}
var _arena_border_cells: Array[Vector2i] = []
var _caches_ready: bool = false


func index_of(cell: Vector2i) -> int:
	return cell.y * size.x + cell.x


func is_cell_in_map(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y


func cell_at(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x), floori(pos.y))


func is_arena_cell(cell: Vector2i) -> bool:
	return is_cell_in_map(cell) and arena_mask[index_of(cell)] == 1


func get_level(cell: Vector2i) -> int:
	return heights[index_of(cell)]


func get_ground(cell: Vector2i) -> Ground:
	return ground[index_of(cell)] as Ground


func is_stair_cell(cell: Vector2i) -> bool:
	_ensure_caches()
	return _stair_cells.has(cell)


## Nível mínimo e máximo do terreno (x = mínimo, y = máximo).
func get_level_range() -> Vector2i:
	var lo: int = heights[0]
	var hi: int = heights[0]
	for level: int in heights:
		lo = mini(lo, level)
		hi = maxi(hi, level)
	return Vector2i(lo, hi)


## Verdadeiro se a célula que contém pos é da arena (fora do mapa = falso).
func is_inside_arena(pos: Vector2) -> bool:
	return is_arena_cell(cell_at(pos))


## Devolve pos se já está na arena; senão, o ponto mais próximo da união das células
## da arena, puxado um pouco para dentro (o resultado sempre passa em is_inside_arena).
func clamp_to_arena(pos: Vector2) -> Vector2:
	if is_inside_arena(pos):
		return pos
	var best_cell: Vector2i = _nearest_arena_border_cell(pos)
	var lo := Vector2(best_cell) + Vector2(CLAMP_INSET, CLAMP_INSET)
	var hi := Vector2(best_cell) + Vector2(1.0 - CLAMP_INSET, 1.0 - CLAMP_INSET)
	return pos.clamp(lo, hi)


## Distância de pos até a união das células da arena (0 dentro).
func distance_to_arena(pos: Vector2) -> float:
	if is_inside_arena(pos):
		return 0.0
	var best_cell: Vector2i = _nearest_arena_border_cell(pos)
	var nearest: Vector2 = pos.clamp(Vector2(best_cell), Vector2(best_cell) + Vector2.ONE)
	return pos.distance_to(nearest)


## Altura do topo do chão no ponto (na escada, a altura do degrau). Fora do mapa usa a borda.
func get_height_at(pos: Vector2) -> float:
	var cell := Vector2i(clampi(floori(pos.x), 0, size.x - 1), clampi(floori(pos.y), 0, size.y - 1))
	var level: float = float(get_level(cell))
	if is_stair_cell(cell):
		# Os degraus sobem do lado sul da célula (perto da câmera) para o norte.
		var climbed: float = clampf(float(cell.y + 1) - pos.y, 0.0, 1.0)
		var step: int = clampi(floori(climbed * STAIR_STEPS), 0, STAIR_STEPS - 1)
		level += float(step + 1) / STAIR_STEPS
	return level * WorldScale.LEVEL_HEIGHT


## Hash SHA-256 de todos os campos, em ordem fixa (usado para conferir determinismo).
func fingerprint() -> String:
	var buf := StreamPeerBuffer.new()
	buf.put_64(map_seed)
	buf.put_32(size.x)
	buf.put_32(size.y)
	buf.put_data(heights.to_byte_array())
	buf.put_data(ground)
	buf.put_data(arena_mask)
	buf.put_32(arena_base_level)
	buf.put_double(arena_center.x)
	buf.put_double(arena_center.y)
	buf.put_double(arena_rect.position.x)
	buf.put_double(arena_rect.position.y)
	buf.put_double(arena_rect.size.x)
	buf.put_double(arena_rect.size.y)
	buf.put_double(wall_thickness)
	buf.put_32(wall_segments.size())
	for seg: WallSegment in wall_segments:
		buf.put_double(seg.start.x)
		buf.put_double(seg.start.y)
		buf.put_double(seg.end.x)
		buf.put_double(seg.end.y)
		buf.put_32(seg.outward.x)
		buf.put_32(seg.outward.y)
		buf.put_32(seg.cell.x)
		buf.put_32(seg.cell.y)
		buf.put_double(seg.height)
	buf.put_32(stairs.size())
	for stair: MapStair in stairs:
		buf.put_32(stair.base_level)
		buf.put_32(stair.up_direction.x)
		buf.put_32(stair.up_direction.y)
		_put_cells(buf, stair.cells)
	buf.put_32(trails.size())
	for trail: MapTrail in trails:
		buf.put_32(trail.side)
		buf.put_32(trail.start_cell.x)
		buf.put_32(trail.start_cell.y)
		_put_cells(buf, trail.cells)
		_put_cells(buf, trail.arena_cells)
	buf.put_32(objects.size())
	for obj: MapObject in objects:
		buf.put_32(obj.kind)
		buf.put_double(obj.position.x)
		buf.put_double(obj.position.y)
		buf.put_32(obj.variant)
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(buf.data_array)
	return hashing.finish().hex_encode()


func _put_cells(buf: StreamPeerBuffer, cells: Array[Vector2i]) -> void:
	buf.put_32(cells.size())
	for cell: Vector2i in cells:
		buf.put_32(cell.x)
		buf.put_32(cell.y)


## A célula de borda da arena mais próxima de pos (pos fora da arena).
## O ponto mais próximo da união sempre fica numa célula que tem vizinho de fora.
func _nearest_arena_border_cell(pos: Vector2) -> Vector2i:
	_ensure_caches()
	var best_cell := Vector2i.ZERO
	var best_dist: float = INF
	for cell: Vector2i in _arena_border_cells:
		var nearest: Vector2 = pos.clamp(Vector2(cell), Vector2(cell) + Vector2.ONE)
		var dist: float = pos.distance_squared_to(nearest)
		if dist < best_dist:
			best_dist = dist
			best_cell = cell
	return best_cell


func _ensure_caches() -> void:
	if _caches_ready:
		return
	_caches_ready = true
	_stair_cells.clear()
	for stair: MapStair in stairs:
		for cell: Vector2i in stair.cells:
			_stair_cells[cell] = true
	_arena_border_cells.clear()
	for cz in size.y:
		for cx in size.x:
			var cell := Vector2i(cx, cz)
			if not is_arena_cell(cell):
				continue
			if (not is_arena_cell(cell + Vector2i.LEFT) or not is_arena_cell(cell + Vector2i.RIGHT)
					or not is_arena_cell(cell + Vector2i.UP) or not is_arena_cell(cell + Vector2i.DOWN)):
				_arena_border_cells.append(cell)


## Chamado pelo gerador quando terminou de preencher os campos.
func invalidate_caches() -> void:
	_caches_ready = false
