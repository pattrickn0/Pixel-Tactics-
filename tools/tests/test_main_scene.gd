extends SceneTree
## Testes da cena principal (spec 001). Rodar depois do comando de validação 1:
##   "$G" --headless --path . --script tools/tests/test_main_scene.gd
## Imprime PASS/FAIL por verificação e sai com 0 (tudo passou) ou 1.

const REPEAT_SEED_TEXT: String = "777"
const SETTLE_FRAMES: int = 6

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
	await _test_hud_seed(main)
	await _test_placeholders(main)

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
	_check(attrs != null and attrs.dof_blur_far_enabled and attrs.dof_blur_near_enabled,
			"DOF ligado via CameraAttributesPractical")


## Pede a mesma seed 5 vezes pelo HUD: a contagem de nós não cresce e não sobra órfão.
func _test_regeneration(main: Node) -> void:
	var input := main.get_node("%SeedInput") as LineEdit
	var use_button := main.get_node("%UseSeedButton") as Button
	var counts: Array[int] = []
	for i in 5:
		input.text = REPEAT_SEED_TEXT
		use_button.pressed.emit()
		await _frames(SETTLE_FRAMES)
		counts.append(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	var match_state: MatchState = main.get("match_state")
	_check(match_state.current_seed == REPEAT_SEED_TEXT.to_int(), "HUD pediu a seed %s" % REPEAT_SEED_TEXT)
	_check(counts[0] == counts[4], "regenerar a mesma seed 5 vezes não vaza nós",
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
