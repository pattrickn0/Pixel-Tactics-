extends SceneTree
## Testes da cena principal (specs 001 e 003). Rodar depois do comando de validação 1:
##   "$G" --headless --path . --script tools/tests/test_main_scene.gd
## Imprime PASS/FAIL por verificação e sai com 0 (tudo passou) ou 1.

const REPEAT_SEED_TEXT: String = "777"
const SETTLE_FRAMES: int = 6
## Quantas vezes o teste de regenerar pede a mesma seed.
const REGEN_COUNT: int = 10
## Máximo de quadros esperando a suavização da câmera chegar no alvo.
const CONVERGE_MAX_FRAMES: int = 2000
const HUD_BUTTONS: Array[String] = [
	"GenerateButton", "UseSeedButton", "RotateLeftButton", "ResetRotateButton", "RotateRightButton",
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
		print("FAIL: ", what, (" -> " + detail) if detail != "" else "")


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _run() -> void:
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await _frames(SETTLE_FRAMES)

	_test_structure(main)
	await _test_regeneration(main)
	await _test_camera(main)
	await _test_camera_rotation(main)
	await _test_camera_aim(main)
	await _test_hud_focus(main)
	await _test_hud_seed(main)
	await _test_placeholders(main)
	_test_sprites(main)

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


## Pede a mesma seed 10 vezes pelo HUD: a contagem de nós não cresce e não sobra órfão.
func _test_regeneration(main: Node) -> void:
	var input := main.get_node("%SeedInput") as LineEdit
	var use_button := main.get_node("%UseSeedButton") as Button
	var counts: Array[int] = []
	for i in REGEN_COUNT:
		input.text = REPEAT_SEED_TEXT
		use_button.pressed.emit()
		await _frames(SETTLE_FRAMES)
		counts.append(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	var match_state: MatchState = main.get("match_state")
	_check(match_state.current_seed == REPEAT_SEED_TEXT.to_int(), "HUD pediu a seed %s" % REPEAT_SEED_TEXT)
	_check(counts[0] == counts[REGEN_COUNT - 1], "regenerar a mesma seed %d vezes não vaza nós" % REGEN_COUNT,
			"nós depois de cada pedido: %s" % str(counts))
	var renderer := main.get_node("MapRenderer") as MapRenderer
	_check(renderer.get_child_count() > 0, "o renderer montou o mapa (%d nós)" % renderer.get_child_count())
	var orphans: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	_check(orphans == 0, "nenhum nó órfão depois de regenerar", "%d órfãos" % orphans)


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
	_check(paths_ok and target_in_range, "reset depois de yaw 725 (e de 16 giros seguidos) percorre no máximo 180°",
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


## (d) Em yaw 0, 90, 180 e 270, a câmera mira o centro da arena, dentro dos limites de distância.
func _test_camera_aim(main: Node) -> void:
	var camera := main.get_node("MapCamera") as MapCamera
	var match_state: MatchState = main.get("match_state")
	var map: MapData = match_state.map_data
	var center := Vector3(map.arena_center.x, map.arena_floor_level * WorldScale.LEVEL_HEIGHT, map.arena_center.y)
	var ok := true
	var detail := ""
	for yaw: float in [0.0, 90.0, 180.0, 270.0]:
		camera.set_target_yaw(yaw, true)
		var xf: Transform3D = camera.global_transform
		var to_center: Vector3 = (center - xf.origin).normalized()
		var forward: Vector3 = -xf.basis.z.normalized()
		var dist: float = xf.origin.distance_to(center)
		var in_limits: bool = dist >= camera.min_distance - 0.001 and dist <= camera.max_distance + 0.001
		if (to_center - forward).length() > 0.001 or not in_limits or not is_equal_approx(_angle_diff(camera.yaw_degrees, yaw), 0.0):
			ok = false
			detail += "yaw %.0f: desvio %.4f, distância %.2f; " % [yaw, (to_center - forward).length(), dist]
	_check(ok, "em yaw 0, 90, 180 e 270 a câmera mira o centro da arena, com distância entre os limites", detail)
	camera.reset_to_default(true)
	await _frames(2)


## (e) Depois de clicar em qualquer botão do HUD, Espaço só reseta a câmera (não gera
## mapa nem gira). O campo da seed solta o foco depois de Enter e de "Usar seed".
func _test_hud_focus(main: Node) -> void:
	var camera := main.get_node("MapCamera") as MapCamera
	var match_state: MatchState = main.get("match_state")
	var input := main.get_node("%SeedInput") as LineEdit
	var none_ok := true
	for button_name: String in HUD_BUTTONS:
		if (main.get_node("%" + button_name) as Button).focus_mode != Control.FOCUS_NONE:
			none_ok = false
	_check(none_ok, "os 5 botões do HUD com focus_mode = none")

	input.text = "123"
	var clicks_ok := true
	var space_ok := true
	var detail := ""
	for button_name: String in HUD_BUTTONS:
		var button := main.get_node("%" + button_name) as Button
		var seed_before: int = match_state.current_seed
		var yaw_before: float = camera.target_yaw_degrees
		# No headless o push_input de mouse não chega aos botões: o clique é o sinal pressed.
		button.pressed.emit()
		await _frames(2)
		# O clique precisa ter chegado no botão (gerou mapa ou mexeu na câmera).
		var reacted: bool = match_state.current_seed != seed_before or not is_equal_approx(camera.target_yaw_degrees, yaw_before) \
				or button_name == "ResetRotateButton"
		if not reacted:
			clicks_ok = false
			detail += "clique em %s sem efeito; " % button_name
		camera.set_target_yaw(90.0, true)
		var seed_after_click: int = match_state.current_seed
		var map_after_click: MapData = match_state.map_data
		_key(KEY_SPACE, 32)
		await _frames(2)
		if match_state.current_seed != seed_after_click or match_state.map_data != map_after_click \
				or not is_zero_approx(camera.target_yaw_degrees) or button.has_focus():
			space_ok = false
			detail += "%s: depois do Espaço seed %d->%d, yaw alvo %.1f, foco %s; " % [button_name, seed_after_click,
					match_state.current_seed, camera.target_yaw_degrees, str(button.has_focus())]
		input.text = "123"
	_check(clicks_ok, "cliques nos 5 botões do HUD chegam aos botões", detail)
	_check(space_ok, "depois de clicar em qualquer botão do HUD, Espaço só reseta a câmera", detail)

	input.grab_focus()
	input.text = "321"
	input.text_submitted.emit(input.text)
	await _frames(2)
	var enter_ok: bool = not input.has_focus() and match_state.current_seed == 321
	input.grab_focus()
	input.text = "654"
	(main.get_node("%UseSeedButton") as Button).pressed.emit()
	await _frames(2)
	var use_ok: bool = not input.has_focus() and match_state.current_seed == 654
	camera.set_target_yaw(90.0, true)
	_key(KEY_SPACE, 32)
	await _frames(2)
	_check(enter_ok and use_ok and match_state.current_seed == 654 and is_zero_approx(camera.target_yaw_degrees),
			"campo da seed solta o foco depois de Enter e de \"Usar seed\"; Espaço volta para a câmera",
			"enter %s, usar seed %s, seed %d" % [str(enter_ok), str(use_ok), match_state.current_seed])
	camera.reset_to_default(true)
	await _frames(2)


## Seed inválida não troca o mapa; seed válida troca e aparece no rótulo.
func _test_hud_seed(main: Node) -> void:
	var match_state: MatchState = main.get("match_state")
	var input := main.get_node("%SeedInput") as LineEdit
	var use_button := main.get_node("%UseSeedButton") as Button
	var seed_label := main.get_node("%SeedLabel") as Label
	var status := main.get_node("%StatusLabel") as Label
	var seed_before: int = match_state.current_seed
	var map_before: MapData = match_state.map_data
	input.text = "abc"
	use_button.pressed.emit()
	await _frames(2)
	_check(match_state.current_seed == seed_before and match_state.map_data == map_before,
			"seed \"abc\" não muda a seed nem o mapa")
	_check(status.text == Hud.INVALID_SEED_TEXT, "seed \"abc\" mostra \"Seed inválida\"", status.text)
	input.text = "42"
	input.text_submitted.emit(input.text)
	await _frames(2)
	_check(match_state.current_seed == 42 and match_state.map_data.map_seed == 42,
			"seed \"42\" (Enter) troca para a seed 42")
	_check(seed_label.text == "Seed: 42", "rótulo mostra a seed 42", seed_label.text)
	_check(Hud.is_valid_seed_text("-12345") and Hud.is_valid_seed_text("9223372036854775807")
			and not Hud.is_valid_seed_text("99999999999999999999"),
			"seeds negativas e grandes (int64) aceitas; fora do int64 recusadas")


## Sem arte em disco (placeholders): o mapa monta com texturas geradas em código.
func _test_placeholders(main: Node) -> void:
	var renderer := main.get_node("MapRenderer") as MapRenderer
	var match_state: MatchState = main.get("match_state")
	var real_art: ArtLibrary = renderer.art
	renderer.art = ArtLibrary.new()
	renderer.art.force_placeholders = true
	match_state.request_map(7)
	await _frames(SETTLE_FRAMES)
	var all_generated := true
	for art_name: String in ["grass_arena_0", "step_side_grass", "wall_face", "rock"]:
		if renderer.art.is_from_disk(art_name) or not (renderer.art.get_terrain_texture(art_name) is ImageTexture):
			all_generated = false
	for art_name: String in ["tree_big_0", "bush_2", "grass_tuft_2", "flower_1", "monolith_0", "monolith_1"]:
		var tex: Texture2D = renderer.art.get_sprite_texture(art_name)
		if not (tex is ImageTexture):
			all_generated = false
	var mono := renderer.art.get_sprite_texture("monolith_0")
	var sizes_ok: bool = mono.get_width() == 32 and mono.get_height() == 96 \
			and renderer.art.get_sprite_texture("tree_big_1").get_size() == Vector2(96, 128)
	_check(all_generated and renderer.get_child_count() > 0, "mapa monta só com placeholders (sem arte em disco)")
	_check(sizes_ok, "placeholders com os tamanhos da A01")
	renderer.art = real_art
	match_state.request_map(42)
	await _frames(SETTLE_FRAMES)


## Sprites sem escala (32 texels por unidade) e runa (f) na frente do monólito em z local,
## na mesma posição do monólito.
func _test_sprites(main: Node) -> void:
	var renderer := main.get_node("MapRenderer") as MapRenderer
	var art: ArtLibrary = renderer.art
	var scale_ok := true
	var detail := ""
	for family: String in ArtLibrary.SPRITE_FAMILIES:
		for v in int(ArtLibrary.SPRITE_FAMILIES[family]):
			var sprite_name: String = art.sprite_variant_name(family, v)
			var tex: Texture2D = art.get_sprite_texture(sprite_name)
			var box: AABB = art.sprite_mesh(sprite_name).get_aabb()
			var expected := Vector2(tex.get_width(), tex.get_height()) * WorldScale.PIXEL_SIZE
			if not Vector2(box.size.x, box.size.y).is_equal_approx(expected):
				scale_ok = false
				detail += "%s %s (esperado %s); " % [sprite_name, Vector2(box.size.x, box.size.y), expected]
	_check(scale_ok, "nenhum sprite escalado (tamanho = pixels / 32)", detail)

	var rune_ok := true
	for v in int(ArtLibrary.SPRITE_FAMILIES["monolith"]):
		var mesh: ArrayMesh = art.sprite_mesh(art.sprite_variant_name("monolith", v), true)
		var verts: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for p: Vector3 in verts:
			if p.z <= 0.0:
				rune_ok = false
	_check(rune_ok, "vértices do quad da runa com z local > 0 (na frente do monólito com billboard)")

	var same_pos := true
	var rune_nodes: int = 0
	for child: Node in renderer.get_children():
		if not child.name.begins_with("Runes_"):
			continue
		rune_nodes += 1
		var sprite_node := renderer.get_node_or_null(NodePath(String(child.name).replace("Runes_", "Sprites_"))) as MultiMeshInstance3D
		var runes: MultiMesh = (child as MultiMeshInstance3D).multimesh
		if sprite_node == null or sprite_node.multimesh.instance_count != runes.instance_count:
			same_pos = false
			continue
		for i in runes.instance_count:
			if not runes.get_instance_transform(i).origin.is_equal_approx(sprite_node.multimesh.get_instance_transform(i).origin):
				same_pos = false
	_check(same_pos and rune_nodes > 0, "runas na mesma posição do monólito (%d grupos)" % rune_nodes)
