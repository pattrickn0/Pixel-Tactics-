class_name MapData
extends RefCounted
## Dados puros de um mapa gerado (sem nós, sem visual, sem assets).
## Célula (cx, cz) ocupa X em [cx, cx+1) e Z em [cz, cz+1). Arrays planos: cz * size.x + cx.
## Posições contínuas: Vector2(x, z) em unidades do mundo. Z cresce para o sul.

enum Ground { ARENA_GRASS, FOREST_GRASS, DIRT, STONE_PATH }
## Relevo da arena: um morro central que cruza a linha do meio ou um morro por metade.
enum ReliefMode { CENTRAL, PER_SIDE }
## Como a metade do inimigo copia a minha: rotação de 180° ou reflexão em z.
enum ReliefSymmetry { ROTATION, MIRROR }

## Degraus por nível de escada (cada um sobe meio nível e tem 0,5 de piso).
const STAIR_STEPS_PER_LEVEL: int = 2
## Quanto o clamp puxa o ponto para dentro do retângulo.
const CLAMP_INSET: float = 0.001

var map_seed: int = 0
var size: Vector2i = Vector2i.ZERO
var heights: PackedInt32Array = PackedInt32Array()
var ground: PackedByteArray = PackedByteArray()
## Derivado de arena_rect (1 nas células da arena).
var arena_mask: PackedByteArray = PackedByteArray()
## 1 nas células do anfiteatro (arena, reservas e anéis): desnível vira muro de pedra.
var built_mask: PackedByteArray = PackedByteArray()
var arena_floor_level: int = 0
var arena_center: Vector2 = Vector2.ZERO
## Retângulo fixo da arena (em unidades, alinhado às células).
var arena_rect: Rect2 = Rect2()
var relief_mode: ReliefMode = ReliefMode.CENTRAL
var relief_symmetry: ReliefSymmetry = ReliefSymmetry.ROTATION
## Nível mais alto do relevo da arena, acima do chão.
var relief_peak: int = 0
var benches: Array[MapBench] = []
var stairs: Array[MapStair] = []
var trails: Array[MapTrail] = []
var objects: Array[MapObject] = []

# Caches derivados (não entram no fingerprint).
var _stair_up: Dictionary = {}
var _caches_ready: bool = false


func index_of(cell: Vector2i) -> int:
	return cell.y * size.x + cell.x


func is_cell_in_map(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y


func cell_at(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x), floori(pos.y))


func is_arena_cell(cell: Vector2i) -> bool:
	return is_cell_in_map(cell) and arena_mask[index_of(cell)] == 1


func is_built_cell(cell: Vector2i) -> bool:
	return is_cell_in_map(cell) and built_mask[index_of(cell)] == 1


func get_level(cell: Vector2i) -> int:
	return heights[index_of(cell)]


func get_ground(cell: Vector2i) -> Ground:
	return ground[index_of(cell)] as Ground


func is_stair_cell(cell: Vector2i) -> bool:
	_ensure_caches()
	return _stair_up.has(cell)


## Direção de subida da escada na célula (ZERO se a célula não é escada).
func stair_up_at(cell: Vector2i) -> Vector2i:
	_ensure_caches()
	return _stair_up.get(cell, Vector2i.ZERO)


## Nível mínimo e máximo do terreno (x = mínimo, y = máximo).
func get_level_range() -> Vector2i:
	var lo: int = heights[0]
	var hi: int = heights[0]
	for level: int in heights:
		lo = mini(lo, level)
		hi = maxi(hi, level)
	return Vector2i(lo, hi)


## Menor nível das células da borda do mapa (a saia de chão de fora fica nele).
func get_border_min_level() -> int:
	var lo: int = heights[0]
	for cx in size.x:
		lo = mini(lo, mini(get_level(Vector2i(cx, 0)), get_level(Vector2i(cx, size.y - 1))))
	for cz in size.y:
		lo = mini(lo, mini(get_level(Vector2i(0, cz)), get_level(Vector2i(size.x - 1, cz))))
	return lo


# --- Arena -------------------------------------------------------------------

## Verdadeiro dentro do retângulo da arena (x0 <= x < x1 e z0 <= z < z1).
func is_inside_arena(pos: Vector2) -> bool:
	return _inside_rect(arena_rect, pos)


## Devolve pos se já está na arena; senão, o ponto mais próximo do retângulo, puxado
## CLAMP_INSET para dentro (o resultado sempre passa em is_inside_arena).
func clamp_to_arena(pos: Vector2) -> Vector2:
	return _clamp_rect(arena_rect, pos)


## Distância de pos até o retângulo da arena (0 dentro).
func distance_to_arena(pos: Vector2) -> float:
	return pos.distance_to(pos.clamp(arena_rect.position, arena_rect.end))


## 0 na metade sul da arena (z >= centro), 1 na norte, -1 fora da arena.
func arena_side_of(pos: Vector2) -> int:
	if not is_inside_arena(pos):
		return -1
	return 0 if pos.y >= arena_center.y else 1


## O ponto correspondente na outra metade: rotação de 180° em torno do centro da arena
## ou reflexão em z (modo espelho).
func mirror_point(pos: Vector2) -> Vector2:
	if relief_symmetry == ReliefSymmetry.MIRROR:
		return Vector2(pos.x, 2.0 * arena_center.y - pos.y)
	return 2.0 * arena_center - pos


# --- Reservas ----------------------------------------------------------------

func get_bench(team: int) -> MapBench:
	for bench: MapBench in benches:
		if bench.team == team:
			return bench
	return null


func is_inside_bench(pos: Vector2, team: int) -> bool:
	var bench: MapBench = get_bench(team)
	return bench != null and _inside_rect(bench.rect, pos)


## Igual a clamp_to_arena, sobre a área útil da reserva do time.
func clamp_to_bench(pos: Vector2, team: int) -> Vector2:
	var bench: MapBench = get_bench(team)
	if bench == null:
		return pos
	return _clamp_rect(bench.rect, pos)


# --- Altura --------------------------------------------------------------------

## Altura do topo do chão no ponto (na escada, a altura do degrau). Fora do mapa usa a borda.
func get_height_at(pos: Vector2) -> float:
	var cell := Vector2i(clampi(floori(pos.x), 0, size.x - 1), clampi(floori(pos.y), 0, size.y - 1))
	var level: float = float(get_level(cell))
	var up: Vector2i = stair_up_at(cell)
	if up != Vector2i.ZERO:
		# Quanto o ponto já andou dentro da célula, no sentido da subida (0 a 1).
		var t: float = 0.0
		if up.x > 0:
			t = pos.x - cell.x
		elif up.x < 0:
			t = cell.x + 1.0 - pos.x
		elif up.y > 0:
			t = pos.y - cell.y
		else:
			t = cell.y + 1.0 - pos.y
		var steps: int = STAIR_STEPS_PER_LEVEL
		var step: int = clampi(floori(t * steps), 0, steps - 1)
		level += float(step + 1) / steps
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
	buf.put_data(built_mask)
	buf.put_32(arena_floor_level)
	buf.put_double(arena_center.x)
	buf.put_double(arena_center.y)
	_put_rect(buf, arena_rect)
	buf.put_32(relief_mode)
	buf.put_32(relief_symmetry)
	buf.put_32(relief_peak)
	buf.put_32(benches.size())
	for bench: MapBench in benches:
		buf.put_32(bench.team)
		_put_rect(buf, bench.rect)
		_put_rect(buf, bench.terrace_rect)
		buf.put_32(bench.level)
	buf.put_32(stairs.size())
	for stair: MapStair in stairs:
		buf.put_32(stair.base_level)
		buf.put_32(stair.levels)
		buf.put_32(stair.up_direction.x)
		buf.put_32(stair.up_direction.y)
		_put_cells(buf, stair.cells)
	buf.put_32(trails.size())
	for trail: MapTrail in trails:
		buf.put_32(trail.side)
		buf.put_32(trail.start_cell.x)
		buf.put_32(trail.start_cell.y)
		buf.put_32(trail.border_cell.x)
		buf.put_32(trail.border_cell.y)
		buf.put_32(1 if trail.stone else 0)
		buf.put_32(trail.branch_count)
		_put_cells(buf, trail.cells)
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


func _put_rect(buf: StreamPeerBuffer, rect: Rect2) -> void:
	buf.put_double(rect.position.x)
	buf.put_double(rect.position.y)
	buf.put_double(rect.size.x)
	buf.put_double(rect.size.y)


func _put_cells(buf: StreamPeerBuffer, cells: Array[Vector2i]) -> void:
	buf.put_32(cells.size())
	for cell: Vector2i in cells:
		buf.put_32(cell.x)
		buf.put_32(cell.y)


static func _inside_rect(rect: Rect2, pos: Vector2) -> bool:
	return pos.x >= rect.position.x and pos.x < rect.end.x and pos.y >= rect.position.y and pos.y < rect.end.y


static func _clamp_rect(rect: Rect2, pos: Vector2) -> Vector2:
	if _inside_rect(rect, pos):
		return pos
	var inset := Vector2(CLAMP_INSET, CLAMP_INSET)
	return pos.clamp(rect.position + inset, rect.end - inset)


func _ensure_caches() -> void:
	if _caches_ready:
		return
	_caches_ready = true
	_stair_up.clear()
	for stair: MapStair in stairs:
		for cell: Vector2i in stair.cells:
			_stair_up[cell] = stair.up_direction


## Chamado pelo gerador quando terminou de preencher os campos.
func invalidate_caches() -> void:
	_caches_ready = false
