class_name MapData
extends RefCounted
## Dados puros do mapa (sem nós, sem visual, sem assets). Vêm da cena map.tscn por
## MapLayout.build_map_data(). Posições contínuas: Vector2(x, z) em unidades do mundo,
## origem no centro da arena, X para leste e Z para o sul.

## Quanto o clamp puxa o ponto para dentro do retângulo.
const CLAMP_INSET: float = 0.001

## Retângulo fixo da arena (alturas 0,0 em toda ela).
var arena_rect: Rect2 = Rect2()
var arena_center: Vector2 = Vector2.ZERO
var benches: Array[MapBench] = []
var height_areas: Array[MapHeightArea] = []
var stairs: Array[MapStair] = []
## Área montada na cena (usada pela câmera).
var bounds: Rect2 = Rect2()


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


## O ponto correspondente na outra metade: rotação de 180° em torno do centro da arena.
func mirror_point(pos: Vector2) -> Vector2:
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

## Altura do chão no ponto: na escada, a do degrau; senão o maior topo das áreas de
## altura que contêm o ponto; senão 0,0.
func get_height_at(pos: Vector2) -> float:
	for stair: MapStair in stairs:
		if _inside_rect(stair.rect, pos):
			return stair.height_at(pos)
	var result: float = 0.0
	for area: MapHeightArea in height_areas:
		if area.top > result and _inside_rect(area.rect, pos):
			result = area.top
	return result


## Maior altura de chão do mapa.
func get_max_height() -> float:
	var result: float = 0.0
	for area: MapHeightArea in height_areas:
		result = maxf(result, area.top)
	for stair: MapStair in stairs:
		result = maxf(result, stair.base_height + stair.step_rise * stair.step_count)
	return result


## Hash SHA-256 de todos os campos, em ordem fixa (usado para conferir determinismo).
func fingerprint() -> String:
	var buf := StreamPeerBuffer.new()
	buf.put_double(arena_center.x)
	buf.put_double(arena_center.y)
	_put_rect(buf, arena_rect)
	_put_rect(buf, bounds)
	buf.put_32(benches.size())
	for bench: MapBench in benches:
		buf.put_32(bench.team)
		_put_rect(buf, bench.rect)
		_put_rect(buf, bench.terrace_rect)
		buf.put_double(bench.height)
	buf.put_32(height_areas.size())
	for area: MapHeightArea in height_areas:
		_put_rect(buf, area.rect)
		buf.put_double(area.top)
	buf.put_32(stairs.size())
	for stair: MapStair in stairs:
		_put_rect(buf, stair.rect)
		buf.put_32(stair.up_direction.x)
		buf.put_32(stair.up_direction.y)
		buf.put_double(stair.base_height)
		buf.put_double(stair.step_rise)
		buf.put_double(stair.tread_depth)
		buf.put_32(stair.step_count)
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(buf.data_array)
	return hashing.finish().hex_encode()


func _put_rect(buf: StreamPeerBuffer, rect: Rect2) -> void:
	buf.put_double(rect.position.x)
	buf.put_double(rect.position.y)
	buf.put_double(rect.size.x)
	buf.put_double(rect.size.y)


static func _inside_rect(rect: Rect2, pos: Vector2) -> bool:
	return pos.x >= rect.position.x and pos.x < rect.end.x and pos.y >= rect.position.y and pos.y < rect.end.y


static func _clamp_rect(rect: Rect2, pos: Vector2) -> Vector2:
	if _inside_rect(rect, pos):
		return pos
	var inset := Vector2(CLAMP_INSET, CLAMP_INSET)
	return pos.clamp(rect.position + inset, rect.end - inset)
