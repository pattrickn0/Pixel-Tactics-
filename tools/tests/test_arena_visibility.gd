extends SceneTree
## Visibilidade da arena e das reservas na câmera padrão (spec 011): para yaw 0, 90, 180 e 270,
## todo ponto de uma grade de 0,5 na arena (recuada 0,25) e nas reservas tem linha de visão
## até a câmera sem cruzar o terreno (get_height_at ao longo do raio); em yaw 45, 135, 225 e
## 315 pelo menos 97%. A câmera sai dos @export padrão de MapCamera (inclinação, FOV, mira 4,3 à frente do
## centro; spec 012) e é testada na distância da referência (54), na inicial do jogo (start_distance) e na máxima. Oclusores: o
## terreno e as peças com volume dos grupos Structures e Props (braseiros, pilares, pontes, bancos, troncos).
## As árvores, rochas e ilhotas têm dither (spec 011 Fase 2 e spec 012), então não contam.
## O raio do ponto até a câmera é percorrido célula a célula numa grade de 0,5 (o tamanho do
## piso de degrau: dentro de cada quadrado a altura de get_height_at é constante).
## Rodar depois do comando de validação 1:
##   "$G" --headless --path . --script tools/tests/test_arena_visibility.gd
## Imprime PASS/FAIL por verificação e sai com 0 (tudo passou) ou 1.

const MAP_PATH: String = "res://scenes/map.tscn"
## Altura acima do chão do ponto testado (meio de uma peça).
const PIECE_HEIGHT: float = 0.6
const GRID_STEP: float = 0.5
## Resolução da grade de alturas (piso de degrau).
const SUB: float = 0.5
## Proporção da tela das capturas (1280 x 720).
const ASPECT: float = 16.0 / 9.0
const DIAGONAL_MIN: float = 0.97

var _failures: int = 0
var _passes: int = 0
var _pitch: float = 0.0
var _distance: float = 0.0
var _fov: float = 0.0
var _near: float = 0.3
var _cam: MapCamera = null
## Caixas (AABB no mundo) das peças com volume que podem tapar a arena.
var _boxes: Array[AABB] = []


func _initialize() -> void:
	@warning_ignore("missing_await")
	_run()


func _run() -> void:
	_cam = MapCamera.new()
	_pitch = _cam.pitch_degrees
	_distance = MapCamera.REFERENCE_DISTANCE
	_fov = _cam.fov_degrees
	print("INFO: câmera padrão: inclinação %.1f°, distância %.1f (máxima %.1f), FOV %.1f°, mira %.1f à frente, tela %.2f" % [
			_pitch, _distance, _cam.max_distance, _fov, _cam.focus_forward_offset, ASPECT])
	var layout := (load(MAP_PATH) as PackedScene).instantiate() as MapLayout
	root.add_child(layout)
	await process_frame
	var map: MapData = layout.build_map_data()
	_collect_boxes(layout)
	print("INFO: %d peças com volume como oclusores" % _boxes.size())
	var grid := HeightGrid.new(map)
	# Enquadramento: na distância da referência e no zoom inicial do jogo.
	for dist: float in [MapCamera.REFERENCE_DISTANCE, _cam.start_distance]:
		_distance = dist
		_test_frustum(map)
	for dist: float in [MapCamera.REFERENCE_DISTANCE, _cam.start_distance, _cam.max_distance]:
		_distance = dist
		_test_orthogonal(map, grid)
		_test_diagonal(map, grid)
	_cam.free()
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


## Mesma conta de MapCamera (transform_for: órbita em volta do centro da arena, mira à frente).
func _camera(_map: MapData, yaw: float) -> Transform3D:
	return _cam.transform_for(yaw, _distance)


## Peças com volume dos grupos Structures e Props viram caixas oclusoras (as que têm dither de oclusão em
## todos os materiais, como os braseiros, ficam pontilhadas e não tapam a arena nem as reservas).
func _collect_boxes(layout: Node3D) -> void:
	for group_name: String in ["Structures", "Props"]:
		var group: Node = layout.get_node_or_null(group_name)
		if group == null:
			continue
		for child: Node in group.get_children():
			var piece := child as KitPiece
			if piece == null or piece.size.y * piece.scale.y < 0.2:
				continue
			var mesh_node := piece.get_node_or_null("Mesh") as MeshInstance3D
			if mesh_node == null or mesh_node.mesh == null or _all_dithered(mesh_node.mesh):
				continue
			_boxes.append(mesh_node.global_transform * mesh_node.get_aabb())


## Todos os materiais opacos da malha têm dither de oclusão (a chama, emissiva e recortada, não conta).
static func _all_dithered(mesh: Mesh) -> bool:
	for i in mesh.get_surface_count():
		var mat := mesh.surface_get_material(i) as ShaderMaterial
		if mat == null:
			return false
		if mat.shader != null and mat.shader.resource_path.ends_with("flame.gdshader"):
			continue
		if mat.get_shader_parameter("dither_on") != true:
			return false
	return true


## O segmento de p até a câmera cruza alguma caixa oclusora?
func _blocked_by_box(p: Vector3, cam: Vector3) -> bool:
	for box: AABB in _boxes:
		if box.has_point(p):
			continue
		if box.intersects_segment(p, cam) != null:
			return true
	return false


func _in_frustum(cam: Transform3D, p: Vector3) -> bool:
	var local: Vector3 = cam.affine_inverse() * p
	var depth: float = -local.z
	if depth <= _near:
		return false
	var tan_v: float = tan(deg_to_rad(_fov) * 0.5)
	return absf(local.y) / depth <= tan_v and absf(local.x) / depth <= tan_v * ASPECT


## Em yaw 0 e 180 os cantos da arena, das reservas e da face externa do muro sul/norte cabem na tela.
func _test_frustum(map: MapData) -> void:
	var ok := true
	var detail := ""
	for yaw: float in [0.0, 180.0]:
		var cam := _camera(map, yaw)
		var points: Array[Vector3] = []
		for corner: Vector2 in _corners(map.arena_rect):
			points.append(Vector3(corner.x, 0.0, corner.y))
		for bench: MapBench in map.benches:
			for corner: Vector2 in _corners(bench.rect):
				points.append(Vector3(corner.x, bench.height + PIECE_HEIGHT, corner.y))
		if yaw == 0.0:
			# Face externa do muro sul: da base (chão) ao topo da crista, nas duas pontas.
			for x: float in [-14.0, 14.0]:
				points.append(Vector3(x, 0.0, 13.0))
				points.append(Vector3(x, 1.0, 13.0))
		for p: Vector3 in points:
			if not _in_frustum(cam, p):
				ok = false
				detail += "yaw %.0f ponto %s; " % [yaw, p]
	_check(ok, "distância %.1f (yaw 0 e 180): arena, reservas e face externa do muro sul dentro do frustum" % _distance, detail)


func _corners(rect: Rect2) -> Array[Vector2]:
	return [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]


## Grade de alturas 0,5 × 0,5 do mapa, lida de get_height_at no centro de cada quadrado.
class HeightGrid extends RefCounted:
	var origin: Vector2 = Vector2.ZERO
	var w: int = 0
	var h: int = 0
	var values: PackedFloat32Array = PackedFloat32Array()
	var max_height: float = 0.0

	func _init(map: MapData) -> void:
		origin = map.bounds.position
		w = roundi(map.bounds.size.x / 0.5)
		h = roundi(map.bounds.size.y / 0.5)
		values.resize(w * h)
		for sz in h:
			for sx in w:
				var v: float = map.get_height_at(origin + Vector2((sx + 0.5) * 0.5, (sz + 0.5) * 0.5))
				values[sz * w + sx] = v
				max_height = maxf(max_height, v)


## Linha de visão livre de p até a câmera? O raio sobe em direção à câmera, então em cada
## quadrado a parte mais baixa dele é a da entrada.
func _visible(grid: HeightGrid, p: Vector3, cam: Vector3) -> bool:
	var x0: float = (p.x - grid.origin.x) / SUB
	var z0: float = (p.z - grid.origin.y) / SUB
	var dx: float = (cam.x - grid.origin.x) / SUB - x0
	var dz: float = (cam.z - grid.origin.y) / SUB - z0
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


## Fração dos pontos da grade de 0,5 no retângulo (recuado `inset`, a 0,6 do chão) com linha de visão livre.
func _visible_share(map: MapData, grid: HeightGrid, rect: Rect2, inset: float, cam: Vector3) -> float:
	var inner: Rect2 = rect.grow(-inset)
	var total: int = 0
	var seen: int = 0
	var nx: int = floori(inner.size.x / GRID_STEP) + 1
	var nz: int = floori(inner.size.y / GRID_STEP) + 1
	for iz in nz:
		for ix in nx:
			var q: Vector2 = inner.position + Vector2(ix * GRID_STEP, iz * GRID_STEP)
			var p := Vector3(q.x, map.get_height_at(q) + PIECE_HEIGHT, q.y)
			total += 1
			if _visible(grid, p, cam) and not _blocked_by_box(p, cam):
				seen += 1
	return float(seen) / float(maxi(total, 1))


func _test_orthogonal(map: MapData, grid: HeightGrid) -> void:
	var ok := true
	var detail := ""
	for yaw: float in [0.0, 90.0, 180.0, 270.0]:
		var cam: Vector3 = _camera(map, yaw).origin
		var arena_share: float = _visible_share(map, grid, map.arena_rect, 0.25, cam)
		if arena_share < 1.0:
			ok = false
			detail += "yaw %.0f arena %.2f%%; " % [yaw, arena_share * 100.0]
		for bench: MapBench in map.benches:
			var share: float = _visible_share(map, grid, bench.rect, 0.0, cam)
			if share < 1.0:
				ok = false
				detail += "yaw %.0f reserva %d %.2f%%; " % [yaw, bench.team, share * 100.0]
	_check(ok, "distância %.1f, yaw 0, 90, 180 e 270: 100%% da arena (recuada 0,25) e das reservas com linha de visão livre" % _distance, detail)


func _test_diagonal(map: MapData, grid: HeightGrid) -> void:
	var ok := true
	var detail := ""
	for yaw: float in [45.0, 135.0, 225.0, 315.0]:
		var cam: Vector3 = _camera(map, yaw).origin
		var arena_share: float = _visible_share(map, grid, map.arena_rect, 0.25, cam)
		print("INFO: distância %.1f, yaw %3.0f: arena visível %.2f%%" % [_distance, yaw, arena_share * 100.0])
		if arena_share < DIAGONAL_MIN:
			ok = false
			detail += "yaw %.0f arena %.2f%%; " % [yaw, arena_share * 100.0]
		for bench: MapBench in map.benches:
			var share: float = _visible_share(map, grid, bench.rect, 0.0, cam)
			print("INFO: distância %.1f, yaw %3.0f: reserva %d visível %.2f%%" % [_distance, yaw, bench.team, share * 100.0])
			if share < DIAGONAL_MIN:
				ok = false
				detail += "yaw %.0f reserva %d %.2f%%; " % [yaw, bench.team, share * 100.0]
	_check(ok, "distância %.1f, yaw 45, 135, 225 e 315: pelo menos 97%% da arena e das reservas com linha de visão livre" % _distance, detail)
