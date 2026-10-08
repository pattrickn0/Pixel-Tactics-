class_name MapLayout
extends Node3D
## Raiz de scenes/map.tscn. Única ponte cena -> dados: lê os marcadores (ArenaMarker,
## BenchMarker, HeightArea, StairArea) pelas transformações globais e monta o MapData.
## Peças estruturais (KitPiece com structural = true) precisam estar na grade de 0,5 e
## girar só em múltiplos de 90°; quem foge disso gera push_error com o nome do nó.

## Emitido por build_map_data com o mapa pronto.
signal map_ready(map_data: MapData)

## Grade das peças estruturais e tolerância de ponto flutuante.
const GRID: float = 0.5
const EPSILON: float = 0.001

## Desligado, as peças fora da grade só geram erro no log (o mapa sai igual).
@export var strict_snap: bool = true

## Erros encontrados na última chamada de build_map_data (para os testes).
var last_errors: PackedStringArray = PackedStringArray()


## Lê a cena e devolve o MapData; também emite map_ready.
func build_map_data() -> MapData:
	last_errors = PackedStringArray()
	var data := MapData.new()
	var arenas: Array[ArenaMarker] = []
	var bench_markers: Array[BenchMarker] = []
	var structure_rect := Rect2()
	var has_structure: bool = false
	for node: Node in _descendants(self):
		if node is KitPiece and (node as KitPiece).structural:
			_check_snap(node as KitPiece)
		if node is ArenaMarker:
			arenas.append(node as ArenaMarker)
		elif node is BenchMarker:
			bench_markers.append(node as BenchMarker)
		elif node is HeightArea:
			var area := node as HeightArea
			data.height_areas.append(MapHeightArea.new(area.world_rect(), area.world_top()))
			structure_rect = area.world_rect() if not has_structure else structure_rect.merge(area.world_rect())
			has_structure = true
		elif node is StairArea:
			var stair_node := node as StairArea
			var stair := MapStair.new()
			stair.rect = stair_node.world_rect()
			stair.up_direction = stair_node.up_direction()
			stair.base_height = stair_node.global_position.y
			stair.step_rise = stair_node.step_rise
			stair.tread_depth = stair_node.tread_depth
			stair.step_count = stair_node.step_count
			data.stairs.append(stair)
			structure_rect = stair.rect if not has_structure else structure_rect.merge(stair.rect)
			has_structure = true
	if arenas.size() == 1:
		data.arena_rect = arenas[0].world_rect()
		data.arena_center = data.arena_rect.get_center()
	else:
		_error("o mapa precisa de exatamente 1 ArenaMarker (achou %d)" % arenas.size())
	for marker: BenchMarker in bench_markers:
		var bench := MapBench.new()
		bench.team = marker.team
		bench.rect = marker.usable_rect()
		bench.terrace_rect = marker.terrace_rect()
		bench.height = _ground_height(data, bench.rect.get_center())
		data.benches.append(bench)
	data.benches.sort_custom(func(a: MapBench, b: MapBench) -> bool: return a.team < b.team)
	data.bounds = _bounds_of(structure_rect, data)
	map_ready.emit(data)
	return data


func _bounds_of(structure_rect: Rect2, data: MapData) -> Rect2:
	# Área montada à mão: ao menos de -24 a 24 em volta do centro da arena.
	var base := Rect2(data.arena_center - Vector2(24.0, 24.0), Vector2(48.0, 48.0))
	return base.merge(structure_rect)


## Maior topo, entre os HeightArea, que contém o ponto (0 se nenhum).
func _ground_height(data: MapData, pos: Vector2) -> float:
	var result: float = 0.0
	for area: MapHeightArea in data.height_areas:
		if area.top > result and area.rect.has_point(pos):
			result = area.top
	return result


func _check_snap(piece: KitPiece) -> void:
	var xform: Transform3D = piece.global_transform
	var pos: Vector3 = xform.origin
	for value: float in [pos.x, pos.z]:
		if absf(value / GRID - roundf(value / GRID)) > EPSILON / GRID:
			_error("peça estrutural fora da grade de 0,5: %s em %s" % [piece.name, pos])
			break
	var b: Basis = xform.basis
	var yaw_deg: float = rad_to_deg(atan2(b.z.x, b.z.z))
	if absf(yaw_deg / 90.0 - roundf(yaw_deg / 90.0)) > EPSILON or b.y.dot(Vector3.UP) < 1.0 - EPSILON:
		_error("peça estrutural com rotação fora de múltiplos de 90°: %s" % piece.name)


func _error(message: String) -> void:
	last_errors.append(message)
	if strict_snap:
		push_error("MapLayout: " + message)


static func _descendants(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		out.append(node)
		var children: Array[Node] = node.get_children()
		for i in range(children.size() - 1, -1, -1):
			stack.append(children[i])
	return out
