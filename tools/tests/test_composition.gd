extends SceneTree
## Composição do enquadramento da referência (spec 012, Tabela E): com os @export padrão da MapCamera (yaw 0,
## distância MapCamera.REFERENCE_DISTANCE = 54, 1280x720; o jogo começa 10% mais perto, em start_distance), cada âncora do mundo projeta a <= 0,025 (em u e em v) da posição medida na referência
## docs/reference/ilha-flutuante.webp. Também confere os limites da câmera da spec (pitch, FOV, distância,
## mira à frente e a órbita máxima).
## Rodar depois do comando de validação 1:
##   "$G" --headless --path . --script tools/tests/test_composition.gd
## Imprime PASS/FAIL por verificação e sai com 0 (tudo passou) ou 1.

const SCREEN: Vector2i = Vector2i(1280, 720)
const TOLERANCE: float = 0.025
## [nome, ponto do mundo, posição esperada na tela (u, v) normalizada a partir do canto de cima à esquerda].
const ANCHORS: Array = [
	["Crista NW", Vector3(-13.5, 1.0, -12.5), Vector2(0.304, 0.387)],
	["Crista NE", Vector3(13.5, 1.0, -12.5), Vector2(0.681, 0.387)],
	["Crista SW", Vector3(-13.5, 1.0, 12.5), Vector2(0.189, 0.768)],
	["Crista SE", Vector3(13.5, 1.0, 12.5), Vector2(0.781, 0.745)],
	["Degrau NW", Vector3(-10.25, 0.5, -9.25), Vector2(0.353, 0.432)],
	["Degrau NE", Vector3(10.25, 0.5, -9.25), Vector2(0.642, 0.432)],
	["Degrau SW", Vector3(-10.25, 0.5, 9.25), Vector2(0.296, 0.701)],
	["Degrau SE", Vector3(10.25, 0.5, 9.25), Vector2(0.698, 0.701)],
	["Tocha sul esquerda", Vector3(-1.75, 1.4, 12.5), Vector2(0.456, 0.756)],
	["Tocha sul direita", Vector3(1.75, 1.4, 12.5), Vector2(0.533, 0.756)],
	["Ponta do patamar sul", Vector3(0.0, 0.0, 18.5), Vector2(0.497, 0.953)],
	["Cabeceira oeste", Vector3(-18.7, 0.0, 7.8), Vector2(0.130, 0.688)],
	["Cabeceira leste", Vector3(16.4, 0.0, 11.8), Vector2(0.838, 0.770)],
	["Fim do caminho nordeste", Vector3(23.0, 0.0, -24.1), Vector2(0.762, 0.314)],
	["Centro do círculo", Vector3(0.4, 0.0, -0.9), Vector2(0.499, 0.544)],
]

var _failures: int = 0
var _passes: int = 0


func _initialize() -> void:
	@warning_ignore("missing_await")
	_run()


func _check(ok: bool, what: String, detail: String = "") -> void:
	if ok:
		_passes += 1
		print("PASS: ", what)
	else:
		_failures += 1
		print("FAIL: ", what, (" -> " + detail.left(600)) if detail != "" else "")


func _run() -> void:
	var defaults := MapCamera.new()
	var viewport := SubViewport.new()
	viewport.size = SCREEN
	viewport.disable_3d = false
	root.add_child(viewport)
	var cam := Camera3D.new()
	viewport.add_child(cam)
	await process_frame
	cam.fov = defaults.fov_degrees
	cam.near = 0.3
	cam.far = 400.0
	cam.global_transform = defaults.transform_for(0.0, MapCamera.REFERENCE_DISTANCE)
	await process_frame
	print("INFO: câmera padrão em %s, mirando %s" % [cam.global_position, defaults.focus_for(0.0)])
	_check(is_equal_approx(defaults.pitch_degrees, 27.0) and is_equal_approx(defaults.fov_degrees, 37.0)
			and is_equal_approx(MapCamera.REFERENCE_DISTANCE, 54.0) and is_equal_approx(defaults.focus_forward_offset, 4.3),
			"câmera da referência: pitch 27°, FOV 37°, distância 54, mira 4,3 à frente")
	var focus: Vector3 = defaults.focus_for(0.0)
	_check(focus.is_equal_approx(Vector3(0.0, 0.0, -4.3)) and cam.global_position.distance_to(Vector3(0.0, 24.515, 43.814)) < 0.01,
			"em yaw 0 a câmera fica em (0; 24,5; 43,8) e mira (0, 0, -4,3)", str(cam.global_position))
	var orbit_max: float = defaults.max_distance * cos(deg_to_rad(27.0)) - 4.3
	_check(defaults.max_distance <= 60.0 and orbit_max <= 50.0,
			"max_distance %.1f <= 60 e órbita máxima %.2f <= 50" % [defaults.max_distance, orbit_max])
	var bad: Array[String] = []
	var worst: float = 0.0
	for anchor: Array in ANCHORS:
		var world: Vector3 = anchor[1]
		var want: Vector2 = anchor[2]
		var px: Vector2 = cam.unproject_position(world)
		var got := Vector2(px.x / float(SCREEN.x), px.y / float(SCREEN.y))
		var err := Vector2(absf(got.x - want.x), absf(got.y - want.y))
		worst = maxf(worst, maxf(err.x, err.y))
		print("INFO: %-24s tela (%.3f, %.3f), esperado (%.3f, %.3f), erro (%.3f, %.3f)" % [anchor[0], got.x, got.y, want.x, want.y, err.x, err.y])
		if err.x > TOLERANCE or err.y > TOLERANCE or cam.is_position_behind(world):
			bad.append(str(anchor[0]))
	_check(bad.is_empty(), "as %d âncoras da Tabela E projetam a <= %.3f da referência (pior %.3f)" % [ANCHORS.size(), TOLERANCE, worst], str(bad))
	defaults.free()
	viewport.queue_free()
	await process_frame
	print("")
	if _failures == 0:
		print("RESULTADO: PASS (%d verificações)" % _passes)
	else:
		print("RESULTADO: FAIL (%d de %d verificações falharam)" % [_failures, _passes + _failures])
	quit(0 if _failures == 0 else 1)
