extends SceneTree
## Testes da cena principal (specs 001, 003 e 011). Rodar depois do comando de validação 1:
##   "$G" --headless --path . --script tools/tests/test_main_scene.gd
## Imprime PASS/FAIL por verificação e sai com 0 (tudo passou) ou 1.

const SETTLE_FRAMES: int = 6
## Máximo de quadros esperando a suavização da câmera chegar no alvo.
const CONVERGE_MAX_FRAMES: int = 2000
const HUD_BUTTONS: Array[String] = ["RotateLeftButton", "ResetRotateButton", "RotateRightButton"]
## Nomes que não podem mais existir no HUD (seed e botão de gerar mapa saíram na spec 011).
const REMOVED_HUD_NODES: Array[String] = ["SeedLabel", "GenerateButton", "SeedRow", "SeedInput", "UseSeedButton", "StatusLabel"]

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
		print("FAIL: ", what, (" -> " + detail) if detail != "" else "")


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _run() -> void:
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await _frames(SETTLE_FRAMES)

	_test_structure(main)
	await _test_map_scene(main)
	await _test_camera(main)
	await _test_camera_rotation(main)
	await _test_yaw_limit(main)
	await _test_camera_aim(main)
	await _test_hud_focus(main)
	_test_hud_without_seed(main)

	main.queue_free()
	await _frames(SETTLE_FRAMES)
	print("")
	if _failures == 0:
		print("RESULTADO: PASS (%d verificações)" % _passes)
	else:
		print("RESULTADO: FAIL (%d de %d verificações falharam)" % [_failures, _passes + _failures])
	quit(0 if _failures == 0 else 1)


func _test_structure(main: Node) -> void:
	var camera := main.get_node("MapCamera") as Camera3D
	var sun := main.get_node("Sun") as DirectionalLight3D
	var world := main.get_node("WorldEnvironment") as WorldEnvironment
	_check(main is Node3D, "cena principal é 3D (Node3D)")
	_check(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/main.tscn",
			"run/main_scene = res://scenes/main.tscn")
	_check(camera != null and camera.projection == Camera3D.PROJECTION_PERSPECTIVE, "Camera3D em perspectiva")
	_check(sun != null and sun.shadow_enabled, "DirectionalLight3D com sombras")
	var env: Environment = world.environment if world != null else null
	_check(env != null and env.glow_enabled and env.fog_enabled, "WorldEnvironment com glow e névoa")
	var attrs: CameraAttributesPractical = null
	if world != null:
		attrs = world.camera_attributes as CameraAttributesPractical
	# Spec 004: só o DOF de longe (fundo distante); o de perto fica desligado.
	_check(attrs != null and attrs.dof_blur_far_enabled and not attrs.dof_blur_near_enabled,
			"DOF de longe ligado e de perto desligado via CameraAttributesPractical")


## O mapa vem da cena map.tscn: o MatchState recebe o MapData e nada precisa ser gerado.
func _test_map_scene(main: Node) -> void:
	var map_node := main.get_node_or_null("Map") as MapLayout
	var match_state: MatchState = main.get("match_state")
	_check(map_node != null and map_node.scene_file_path == "res://scenes/map.tscn", "main.tscn instancia scenes/map.tscn (nó Map)")
	_check(main.get_node_or_null("MapRenderer") == null, "sem MapRenderer na cena principal")
	_check(match_state.has_map() and match_state.map_data.arena_rect == Rect2(-10, -9, 20, 18),
			"MatchState recebeu o mapa (arena 20 x 18) pelo sinal map_ready")
	var camera := main.get_node("MapCamera") as MapCamera
	_check(camera.pitch_degrees == 27.0, "câmera padrão com 27° de inclinação (spec 012)", str(camera.pitch_degrees))
	var focus: Vector3 = camera.get_focus_point()
	_check(focus.is_equal_approx(Vector3(0.0, 0.0, -4.3)), "em yaw 0 a câmera mira 4,3 à frente do centro da arena (0, 0, -4,3)", str(focus))
	_check(is_equal_approx(camera.start_distance, 48.6) and is_equal_approx(camera.start_distance, 0.9 * MapCamera.REFERENCE_DISTANCE)
			and is_equal_approx(camera.distance, camera.start_distance) and is_zero_approx(camera.yaw_degrees),
			"zoom inicial 48,6 (10% mais perto que a referência 54), yaw 0",
			"start %.2f, distância %.2f, yaw %.2f" % [camera.start_distance, camera.distance, camera.yaw_degrees])
	var orphans: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	_check(orphans == 0, "nenhum nó órfão", "%d órfãos" % orphans)


## Roda do mouse além dos limites: distância limitada e rotação igual.
func _test_camera(main: Node) -> void:
	var camera := main.get_node("MapCamera") as MapCamera
	var basis_before: Basis = camera.basis
	var center: Vector2 = root.get_visible_rect().size * 0.5
	for i in 40:
		_wheel(MOUSE_BUTTON_WHEEL_UP, center)
	await _frames(SETTLE_FRAMES)
	var in_limits_in: bool = _camera_in_limits(camera)
	_check(is_equal_approx(camera.target_distance, camera.min_distance),
			"roda para frente além do limite para no min_distance", "alvo %.2f" % camera.target_distance)
	for i in 80:
		_wheel(MOUSE_BUTTON_WHEEL_DOWN, center)
	await _frames(SETTLE_FRAMES)
	var in_limits_out: bool = _camera_in_limits(camera)
	_check(is_equal_approx(camera.target_distance, camera.max_distance),
			"roda para trás além do limite para no max_distance", "alvo %.2f" % camera.target_distance)
	_check(in_limits_in and in_limits_out, "distância sempre entre min_distance e max_distance",
			"distância %.2f" % camera.distance)
	_check(camera.basis.is_equal_approx(basis_before), "a câmera não gira com o zoom")


func _wheel(button: MouseButton, pos: Vector2) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	ev.pressed = true
	ev.position = pos
	ev.global_position = pos
	root.push_input(ev)


func _camera_in_limits(camera: MapCamera) -> bool:
	return camera.distance >= camera.min_distance - 0.001 and camera.distance <= camera.max_distance + 0.001


func _key(code: Key, unicode: int = 0) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.unicode = unicode
	ev.pressed = true
	root.push_input(ev)
	var up := ev.duplicate() as InputEventKey
	up.pressed = false
	root.push_input(up)


## Espera a suavização da câmera chegar no alvo (yaw e distância).
func _wait_camera(camera: MapCamera) -> void:
	for _i in CONVERGE_MAX_FRAMES:
		if is_equal_approx(camera.yaw_degrees, camera.target_yaw_degrees) \
				and is_equal_approx(camera.distance, camera.target_distance):
			return
		await process_frame


## Diferença de ângulo em [-180, 180).
func _angle_diff(a: float, b: float) -> float:
	return wrapf(a - b, -180.0, 180.0)


## A/D giram um passo, Espaço volta ao padrão, o reset nunca dá mais de meia volta e
## nenhum botão do mouse gira a câmera.
func _test_camera_rotation(main: Node) -> void:
	var camera := main.get_node("MapCamera") as MapCamera
	camera.reset_to_default(true)
	await _frames(2)
	var step: float = camera.rotation_step

	# (a) A/D mudam o yaw alvo em -/+ rotation_step.
	var before: float = camera.target_yaw_degrees
	_key(KEY_A, 97)
	await _frames(1)
	var after_a: float = camera.target_yaw_degrees
	_key(KEY_D, 100)
	await _frames(1)
	var after_d: float = camera.target_yaw_degrees
	_check(is_equal_approx(_angle_diff(after_a, before), -step) and is_equal_approx(_angle_diff(after_d, after_a), step),
			"A gira o alvo em -rotation_step e D em +rotation_step",
			"A: %.1f -> %.1f; D: -> %.1f" % [before, after_a, after_d])

	# (b) Espaço volta a yaw 0 e start_distance.
	camera.set_target_yaw(135.0, true)
	camera.set_target_distance(camera.min_distance, true)
	_key(KEY_SPACE, 32)
	await _frames(1)
	var targets_ok: bool = is_equal_approx(camera.target_yaw_degrees, 0.0) \
			and is_equal_approx(camera.target_distance, camera.start_distance)
	await _wait_camera(camera)
	_check(targets_ok and is_zero_approx(camera.yaw_degrees) and is_equal_approx(camera.distance, camera.start_distance),
			"Espaço volta a câmera a yaw 0 e start_distance",
			"yaw %.2f (alvo %.2f), distância %.2f" % [camera.yaw_degrees, camera.target_yaw_degrees, camera.distance])

	# (c) O reset vai pelo caminho mais curto e o yaw não acumula voltas.
	var paths: Array[float] = []
	camera.set_target_yaw(725.0, true)
	camera.reset_to_default()
	paths.append(absf(camera.target_yaw_degrees - camera.yaw_degrees))
	camera.reset_to_default(true)
	for _i in 16:
		camera.rotate_by(step)
	camera.rotate_by(5.0)
	var target_in_range: bool = camera.target_yaw_degrees >= -180.0 and camera.target_yaw_degrees < 180.0
	await _frames(3)
	camera.reset_to_default()
	paths.append(absf(camera.target_yaw_degrees - camera.yaw_degrees))
	camera.set_target_yaw(170.0, true)
	camera.reset_to_default()
	paths.append(absf(camera.target_yaw_degrees - camera.yaw_degrees))
	var paths_ok := true
	for p: float in paths:
		if p > 180.0 + 0.001:
			paths_ok = false
	_check(paths_ok and target_in_range, "reset depois de yaw 725 (captura) e de 16 giros seguidos percorre no máximo 180°",
			"caminhos %s; alvo em [-180, 180): %s" % [str(paths), str(target_in_range)])
	await _wait_camera(camera)

	# Botões do mouse (esquerdo, direito, do meio) com movimento não giram a câmera.
	camera.reset_to_default(true)
	var center: Vector2 = root.get_visible_rect().size * 0.5
	for button: MouseButton in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
		var press := InputEventMouseButton.new()
		press.button_index = button
		press.pressed = true
		press.position = center
		press.global_position = center
		root.push_input(press)
		var motion := InputEventMouseMotion.new()
		motion.position = center + Vector2(200.0, 0.0)
		motion.global_position = motion.position
		motion.relative = Vector2(200.0, 0.0)
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT | MOUSE_BUTTON_MASK_MIDDLE
		root.push_input(motion)
		var release := press.duplicate() as InputEventMouseButton
		release.pressed = false
		root.push_input(release)
	await _frames(2)
	_check(is_zero_approx(camera.yaw_degrees) and is_zero_approx(camera.target_yaw_degrees),
			"botões do mouse não giram a câmera", "yaw %.2f" % camera.yaw_degrees)


## Giro limitado (pedido do usuário, 2026-10-09): um passo para cada lado do padrão (yaw de -45° a +45°).
## No limite, a tecla e o botão do mesmo lado não fazem nada (o botão fica desabilitado); o outro lado volta.
func _test_yaw_limit(main: Node) -> void:
	var camera := main.get_node("MapCamera") as MapCamera
	var left_button := main.get_node("%RotateLeftButton") as Button
	var right_button := main.get_node("%RotateRightButton") as Button
	camera.reset_to_default(true)
	await _frames(2)
	var limit: float = camera.max_yaw_degrees()
	_check(camera.max_yaw_steps == 1 and is_equal_approx(camera.rotation_step, 45.0) and is_equal_approx(limit, 45.0),
			"giro limitado a 1 passo de 45° para cada lado (max_yaw_steps = 1)", "limite %.1f" % limit)
	_check(not left_button.disabled and not right_button.disabled, "em yaw 0 os dois botões de giro ficam habilitados")

	# Esquerda: A, A, A param em -45; o botão esquerdo desabilita e não gira; D volta a 0.
	var left_ok := true
	var detail := ""
	for _i in 3:
		_key(KEY_A, 97)
		await _frames(1)
	if not is_equal_approx(camera.target_yaw_degrees, -limit):
		left_ok = false
		detail += "3x A: alvo %.1f; " % camera.target_yaw_degrees
	var buttons_left: bool = left_button.disabled and not right_button.disabled
	left_button.pressed.emit()
	await _frames(1)
	if not is_equal_approx(camera.target_yaw_degrees, -limit):
		left_ok = false
		detail += "botão esquerdo no limite: alvo %.1f; " % camera.target_yaw_degrees
	_key(KEY_D, 100)
	await _frames(1)
	if not is_zero_approx(camera.target_yaw_degrees):
		left_ok = false
		detail += "D depois do limite: alvo %.1f; " % camera.target_yaw_degrees
	_check(left_ok, "A para em -45° (A e botão esquerdo no limite não fazem nada) e D volta a 0", detail)

	# Direita: D, D, D param em +45; o botão direito desabilita; o botão esquerdo volta a 0.
	var right_ok := true
	detail = ""
	for _i in 3:
		_key(KEY_D, 100)
		await _frames(1)
	if not is_equal_approx(camera.target_yaw_degrees, limit):
		right_ok = false
		detail += "3x D: alvo %.1f; " % camera.target_yaw_degrees
	var buttons_right: bool = right_button.disabled and not left_button.disabled
	right_button.pressed.emit()
	await _frames(1)
	if not is_equal_approx(camera.target_yaw_degrees, limit):
		right_ok = false
		detail += "botão direito no limite: alvo %.1f; " % camera.target_yaw_degrees
	left_button.pressed.emit()
	await _frames(1)
	if not is_zero_approx(camera.target_yaw_degrees):
		right_ok = false
		detail += "botão esquerdo depois do limite: alvo %.1f; " % camera.target_yaw_degrees
	_check(right_ok, "D para em +45° (D e botão direito no limite não fazem nada) e o botão esquerdo volta a 0", detail)
	_check(buttons_left and buttons_right and not left_button.disabled and not right_button.disabled,
			"no limite, só o botão do mesmo lado fica desabilitado; de volta a 0, os dois habilitam",
			"esq. no limite %s, dir. no limite %s" % [str(buttons_left), str(buttons_right)])

	# Espaço no limite volta a yaw 0 e ao zoom inicial.
	camera.rotate_by(limit, true)
	camera.set_target_distance(camera.max_distance, true)
	_key(KEY_SPACE, 32)
	await _wait_camera(camera)
	_check(is_zero_approx(camera.yaw_degrees) and is_equal_approx(camera.distance, 48.6),
			"Espaço no limite volta a yaw 0 e distância 48,6", "yaw %.2f, distância %.2f" % [camera.yaw_degrees, camera.distance])


## (d) Em yaw 0, 90, 180 e 270, a câmera mira o ponto 4,3 à frente do centro da arena (gira com o yaw), orbita
## o centro (raio horizontal = distância x cos(pitch) - 4,3) e fica dentro dos limites de distância.
func _test_camera_aim(main: Node) -> void:
	var camera := main.get_node("MapCamera") as MapCamera
	var match_state: MatchState = main.get("match_state")
	var map: MapData = match_state.map_data
	var center := Vector3(map.arena_center.x, 0.0, map.arena_center.y)
	var ok := true
	var detail := ""
	for yaw: float in [0.0, 90.0, 180.0, 270.0]:
		camera.set_target_yaw(yaw, true)
		var xf: Transform3D = camera.global_transform
		var forward: Vector3 = -xf.basis.z.normalized()
		var flat := Vector3(forward.x, 0.0, forward.z).normalized()
		var aim: Vector3 = center + flat * camera.focus_forward_offset
		var to_aim: Vector3 = (aim - xf.origin).normalized()
		var dist: float = xf.origin.distance_to(aim)
		var radius: float = Vector2(xf.origin.x - center.x, xf.origin.z - center.z).length()
		var in_limits: bool = dist >= camera.min_distance - 0.001 and dist <= camera.max_distance + 0.001
		if (to_aim - forward).length() > 0.001 or not in_limits or not is_equal_approx(_angle_diff(camera.yaw_degrees, yaw), 0.0) \
				or absf(radius - camera.orbit_radius(camera.distance)) > 0.01:
			ok = false
			detail += "yaw %.0f: desvio %.4f, distância %.2f, raio %.2f; " % [yaw, (to_aim - forward).length(), dist, radius]
	_check(ok, "em yaw 0, 90, 180 e 270 a câmera mira 4,3 à frente do centro da arena e orbita o centro, com distância entre os limites", detail)
	camera.reset_to_default(true)
	await _frames(2)


## (e) Depois de clicar em qualquer botão do HUD, Espaço só reseta a câmera (não gira
## sozinha nem deixa o botão com foco).
func _test_hud_focus(main: Node) -> void:
	var camera := main.get_node("MapCamera") as MapCamera
	var none_ok := true
	for button_name: String in HUD_BUTTONS:
		if (main.get_node("%" + button_name) as Button).focus_mode != Control.FOCUS_NONE:
			none_ok = false
	_check(none_ok, "os 3 botões do HUD com focus_mode = none")

	var clicks_ok := true
	var space_ok := true
	var detail := ""
	for button_name: String in HUD_BUTTONS:
		var button := main.get_node("%" + button_name) as Button
		var yaw_before: float = camera.target_yaw_degrees
		# No headless o push_input de mouse não chega aos botões: o clique é o sinal pressed.
		button.pressed.emit()
		await _frames(2)
		# O clique precisa ter chegado no botão (mexeu na câmera).
		var reacted: bool = not is_equal_approx(camera.target_yaw_degrees, yaw_before) or button_name == "ResetRotateButton"
		if not reacted:
			clicks_ok = false
			detail += "clique em %s sem efeito; " % button_name
		camera.set_target_yaw(90.0, true)
		_key(KEY_SPACE, 32)
		await _frames(2)
		if not is_zero_approx(camera.target_yaw_degrees) or button.has_focus():
			space_ok = false
			detail += "%s: depois do Espaço yaw alvo %.1f, foco %s; " % [button_name, camera.target_yaw_degrees, str(button.has_focus())]
	_check(clicks_ok, "cliques nos 3 botões do HUD chegam aos botões", detail)
	_check(space_ok, "depois de clicar em qualquer botão do HUD, Espaço só reseta a câmera", detail)
	camera.reset_to_default(true)
	await _frames(2)


## O HUD não tem mais seed, botão "Gerar mapa" nem rótulo de status.
func _test_hud_without_seed(main: Node) -> void:
	var found: Array[String] = []
	for node_name: String in REMOVED_HUD_NODES:
		if main.get_node_or_null("%" + node_name) != null:
			found.append(node_name)
	_check(found.is_empty(), "HUD sem seed, \"Gerar mapa\" e status", str(found))
	var has_signal: bool = false
	for sig: Dictionary in (main.get_node("HUD") as Hud).get_signal_list():
		if str(sig["name"]) == "map_requested":
			has_signal = true
	_check(not has_signal, "o HUD não tem o sinal map_requested")
