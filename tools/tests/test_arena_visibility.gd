extends SceneTree
## Visibilidade da arena e das reservas na câmera padrão (spec 007, critérios V1 a V3),
## seeds 1 a 50. A câmera sai dos @export padrão de MapCamera (inclinação, start_distance,
## FOV), mirando o centro da arena no nível do chão.
## Linha de visão: o raio do ponto até a câmera é percorrido célula a célula numa grade de
## 0,5 (o tamanho do piso de degrau: dentro de cada quadrado a altura de get_height_at é
## constante). Equivale a marchar de 0,05 em 0,05, sem pular quinas finas.
## Rodar depois do comando de validação 1:
##   "$G" --headless --path . --script tools/tests/test_arena_visibility.gd
## Imprime PASS/FAIL por verificação e sai com 0 (tudo passou) ou 1.

const SEEDS_FROM: int = 1
const SEEDS_TO: int = 50
## Altura acima do chão do ponto testado (meio de uma peça).
const PIECE_HEIGHT: float = 0.6
const GRID_STEP: float = 0.25
## Resolução da grade de alturas (piso de degrau).
const SUB: float = 0.5
## Proporção da tela das capturas (1280 x 720).
const ASPECT: float = 16.0 / 9.0
const V2_MIN: float = 0.95

var _failures: int = 0
var _passes: int = 0
var _pitch: float = 0.0
var _distance: float = 0.0
var _fov: float = 0.0
var _near: float = 0.3


func _initialize() -> void:
	var cam := MapCamera.new()
	_pitch = cam.pitch_degrees
	_distance = cam.start_distance
	_fov = cam.fov_degrees
	cam.free()
	print("INFO: câmera padrão: inclinação %.1f°, distância %.1f, FOV %.1f°, tela %.2f" % [_pitch, _distance, _fov, ASPECT])
	var gen := MapGenerator.new(MapGenConfig.new())
	var maps: Array[MapData] = []
	for s in range(SEEDS_FROM, SEEDS_TO + 1):
		maps.append(gen.generate(s))
	_test_v1(maps)
	_test_v2(maps)
	_test_v3(maps)
	print("")
	if _failures == 0:
		print("RESULTADO: PASS (%d verificações)" % _passes)
	else:
		print("RESULTADO: FAIL (%d de %d verificações falharam)" % [_failures, _passes + _failures])
	quit(0 if _failures == 0 else 1)


func _check(ok: bool, what: String, detail: String = "") -> void:
	if ok:
		_passes += 1
		print("PASS: ", what)
	else:
		_failures += 1
		print("FAIL: ", what, (" -> " + detail.left(600)) if detail != "" else "")


## Mesma conta de MapCamera._apply_basis e _apply_position.
func _camera(map: MapData, yaw: float) -> Transform3D:
	var basis := Basis(Vector3.UP, deg_to_rad(yaw)) * Basis(Vector3.RIGHT, -deg_to_rad(_pitch))
	var focus := Vector3(map.arena_center.x, map.arena_floor_level * WorldScale.LEVEL_HEIGHT, map.arena_center.y)
	return Transform3D(basis, focus + basis.z * _distance)


func _in_frustum(cam: Transform3D, p: Vector3) -> bool:
	var local: Vector3 = cam.affine_inverse() * p
	var depth: float = -local.z
	if depth <= _near:
		return false
	var tan_v: float = tan(deg_to_rad(_fov) * 0.5)
	return absf(local.y) / depth <= tan_v and absf(local.x) / depth <= tan_v * ASPECT


func _test_v1(maps: Array[MapData]) -> void:
	var ok := true
	var detail := ""
	for map: MapData in maps:
		for yaw: float in [0.0, 180.0]:
			var cam := _camera(map, yaw)
			for bench: MapBench in map.benches:
				var y: float = bench.level * WorldScale.LEVEL_HEIGHT + PIECE_HEIGHT
				var r: Rect2 = bench.rect
				for corner: Vector2 in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
					if not _in_frustum(cam, Vector3(corner.x, y, corner.y)):
						ok = false
						detail += "seed %d yaw %.0f reserva %d canto %s; " % [map.map_seed, yaw, bench.team, corner]
	_check(ok, "V1: em yaw 0 e 180, os 4 cantos da área útil das duas reservas (a 0,6) dentro do frustum", detail)


## Grade de alturas 0,5 × 0,5 do mapa, lida de get_height_at no centro de cada quadrado.
class HeightGrid extends RefCounted:
	var w: int = 0
	var h: int = 0
	var values: PackedFloat32Array = PackedFloat32Array()
	var max_height: float = 0.0

	func _init(map: MapData) -> void:
		w = map.size.x * 2
		h = map.size.y * 2
		values.resize(w * h)
		for sz in h:
			for sx in w:
				var v: float = map.get_height_at(Vector2((sx + 0.5) * SUB, (sz + 0.5) * SUB))
				values[sz * w + sx] = v
				max_height = maxf(max_height, v)


## Linha de visão livre de p até a câmera? O raio sobe em direção à câmera, então em cada
## quadrado a parte mais baixa dele é a da entrada.
func _visible(grid: HeightGrid, p: Vector3, cam: Vector3) -> bool:
	var x0: float = p.x / SUB
	var z0: float = p.z / SUB
	var dx: float = cam.x / SUB - x0
	var dz: float = cam.z / SUB - z0
	var dy: float = cam.y - p.y
	var gx: int = floori(x0)
	var gz: int = floori(z0)
	var step_x: int = 1 if dx > 0.0 else -1
	var step_z: int = 1 if dz > 0.0 else -1
	var t_delta_x: float = absf(1.0 / dx) if dx != 0.0 else INF
	var t_delta_z: float = absf(1.0 / dz) if dz != 0.0 else INF
	var t_max_x: float = ((gx + (1 if dx > 0.0 else 0)) - x0) / dx if dx != 0.0 else INF
	var t_max_z: float = ((gz + (1 if dz > 0.0 else 0)) - z0) / dz if dz != 0.0 else INF
	var t: float = 0.0
	while t <= 1.0:
		if gx < 0 or gz < 0 or gx >= grid.w or gz >= grid.h:
			return true
		var y: float = p.y + dy * t
		if y > grid.max_height:
			return true
		if y < grid.values[gz * grid.w + gx] - 0.0001:
			return false
		if t_max_x < t_max_z:
			t = t_max_x
			t_max_x += t_delta_x
			gx += step_x
		else:
			t = t_max_z
			t_max_z += t_delta_z
			gz += step_z
	return true


## Fração dos pontos da grade de 0,25 no retângulo (a 0,6 do chão) com linha de visão livre.
func _visible_share(map: MapData, grid: HeightGrid, rect: Rect2, cam: Vector3) -> float:
	var total: int = 0
	var seen: int = 0
	var nx: int = roundi(rect.size.x / GRID_STEP)
	var nz: int = roundi(rect.size.y / GRID_STEP)
	for iz in nz:
		for ix in nx:
			var q := rect.position + Vector2((ix + 0.5) * GRID_STEP, (iz + 0.5) * GRID_STEP)
			var p := Vector3(q.x, map.get_height_at(q) + PIECE_HEIGHT, q.y)
			total += 1
			if _visible(grid, p, cam):
				seen += 1
	return float(seen) / float(maxi(total, 1))


func _test_v2(maps: Array[MapData]) -> void:
	var worst: Dictionary = {}
	var sums: Dictionary = {}
	var ok := true
	var detail := ""
	var grids: Array[HeightGrid] = []
	for map: MapData in maps:
		grids.append(HeightGrid.new(map))
	for yaw: float in [0.0, 90.0, 180.0, 270.0]:
		worst[yaw] = 1.0
		sums[yaw] = 0.0
		for i in maps.size():
			var map: MapData = maps[i]
			var share: float = _visible_share(map, grids[i], map.arena_rect, _camera(map, yaw).origin)
			worst[yaw] = minf(worst[yaw], share)
			sums[yaw] += share
			if share < V2_MIN:
				ok = false
				detail += "seed %d yaw %.0f: %.1f%%; " % [map.map_seed, yaw, share * 100.0]
		print("INFO: V2 yaw %3.0f: arena visível em média %.2f%%, pior seed %.2f%%"
				% [yaw, sums[yaw] / maps.size() * 100.0, worst[yaw] * 100.0])
	_check(ok, "V2: em yaw 0, 90, 180 e 270, pelo menos 95% da arena (grade 0,25, a 0,6) com linha de visão livre", detail)


func _test_v3(maps: Array[MapData]) -> void:
	var ok := true
	var detail := ""
	for map: MapData in maps:
		var grid := HeightGrid.new(map)
		for yaw: float in [0.0, 180.0]:
			var cam: Vector3 = _camera(map, yaw).origin
			for bench: MapBench in map.benches:
				var share: float = _visible_share(map, grid, bench.rect, cam)
				if share < 1.0:
					ok = false
					detail += "seed %d yaw %.0f reserva %d: %.2f%%; " % [map.map_seed, yaw, bench.team, share * 100.0]
	if ok:
		print("INFO: V3: 100%% da área útil das duas reservas visível em yaw 0 e 180 (seeds %d-%d)" % [SEEDS_FROM, SEEDS_TO])
	_check(ok, "V3: em yaw 0 e 180, 100% da área útil das duas reservas (grade 0,25, a 0,6) com linha de visão livre", detail)
