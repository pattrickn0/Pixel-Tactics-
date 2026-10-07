extends SceneTree
## Testes da atmosfera de dia claro (spec 004). Rodar depois do comando de validação 1:
##   "$G" --headless --path . --script tools/tests/test_atmosphere.gd
## Imprime PASS/FAIL por verificação e sai com 0 (tudo passou) ou 1.

const SETTLE_FRAMES: int = 6
const SUN_COLOR: Color = Color8(0xFF, 0xF3, 0xDC)
const AMBIENT_COLOR: Color = Color8(0x7F, 0xA8, 0x98)
const FOG_COLOR: Color = Color8(0xA6, 0xC4, 0xCE)
const COLOR_TOLERANCE: float = 0.01
const MAX_DOF_AMOUNT: float = 0.05
const DOF_AMPHITHEATER_MARGIN: float = 4.0

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
	var match_state: MatchState = main.get("match_state")
	match_state.request_map(42)
	await _frames(SETTLE_FRAMES)

	_test_sun(main)
	_test_config(main)
	_test_depth(main)
	_test_fx_off(main)
	_test_ssao_switch(main)
	_test_sun_follow(main)
	_test_no_vignette(main)

	main.queue_free()
	await _frames(SETTLE_FRAMES)
	print("")
	if _failures == 0:
		print("RESULTADO: PASS (%d verificações)" % _passes)
	else:
		print("RESULTADO: FAIL (%d de %d verificações falharam)" % [_failures, _passes + _failures])
	quit(0 if _failures == 0 else 1)


func _env(main: Node) -> Environment:
	return (main.get_node("WorldEnvironment") as WorldEnvironment).environment


func _attrs(main: Node) -> CameraAttributesPractical:
	return (main.get_node("WorldEnvironment") as WorldEnvironment).camera_attributes as CameraAttributesPractical


func _color_near(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) <= COLOR_TOLERANCE and absf(a.g - b.g) <= COLOR_TOLERANCE and absf(a.b - b.b) <= COLOR_TOLERANCE


## Direção de onde a luz vem (oposta a -Z do sol), no plano X/Z, e elevação em graus.
func _sun_from(sun: DirectionalLight3D) -> Vector3:
	return sun.global_transform.basis.z.normalized()


func _test_sun(main: Node) -> void:
	var sun := main.get_node("Sun") as DirectionalLight3D
	var atmosphere := main.get_node("Atmosphere") as Atmosphere
	var from: Vector3 = _sun_from(sun)
	var elevation: float = rad_to_deg(asin(from.y))
	_check(_color_near(sun.light_color, SUN_COLOR), "sol com cor #FFF3DC", str(sun.light_color))
	_check(elevation >= 50.0 and elevation <= 60.0, "sol com elevação entre 50° e 60°", "%.1f°" % elevation)
	# Sudoeste: vem de x negativo (oeste) e z positivo (sul).
	_check(from.x < 0.0 and from.z > 0.0 and absf(absf(from.x) - absf(from.z)) < 0.1,
			"sol vindo do sudoeste", "direção de origem %s" % str(from))
	_check(sun.shadow_enabled and sun.directional_shadow_mode == DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS,
			"sol com sombras ligadas e 4 splits")
	_check(sun.shadow_blur > 0.0, "sombra direcional com borda suave (shadow_blur %.2f)" % sun.shadow_blur)
	_check(atmosphere.sun_follows_camera == false, "sun_follows_camera é false por padrão")


func _test_config(main: Node) -> void:
	var env: Environment = _env(main)
	var attrs: CameraAttributesPractical = _attrs(main)
	_check(env.background_mode == Environment.BG_SKY and env.sky != null and env.sky.sky_material is ProceduralSkyMaterial,
			"fundo de céu (ProceduralSkyMaterial)")
	var sky_mat := env.sky.sky_material as ProceduralSkyMaterial
	_check(_color_near(sky_mat.sky_top_color, Color8(0x78, 0xAE, 0xDB)) and _color_near(sky_mat.sky_horizon_color, Color8(0xBF, 0xD8, 0xE0))
			and _color_near(sky_mat.ground_horizon_color, FOG_COLOR) and _color_near(sky_mat.ground_bottom_color, FOG_COLOR),
			"céu com zênite #78AEDB, horizonte #BFD8E0 e chão no tom da névoa")
	_check(env.ambient_light_source == Environment.AMBIENT_SOURCE_COLOR and _color_near(env.ambient_light_color, AMBIENT_COLOR),
			"luz ambiente #7FA898")
	_check(env.fog_enabled and env.fog_mode == Environment.FOG_MODE_DEPTH and _color_near(env.fog_light_color, FOG_COLOR)
			and env.fog_sun_scatter <= 0.05 and not env.volumetric_fog_enabled,
			"névoa de profundidade #A6C4CE, sem espalhamento do sol e sem névoa volumétrica")
	_check(env.glow_enabled and env.glow_hdr_threshold >= 1.0, "glow com limiar HDR >= 1,0 (%.2f)" % env.glow_hdr_threshold)
	_check(not attrs.dof_blur_near_enabled, "DOF de perto desligado")
	_check(attrs.dof_blur_far_enabled and attrs.dof_blur_amount <= MAX_DOF_AMOUNT,
			"DOF de longe ligado com força <= 0,05 (%.3f)" % attrs.dof_blur_amount)
	_check(env.adjustment_color_correction == null, "sem adjustment_color_correction")
	var eps: float = 0.001
	_check(not env.adjustment_enabled or (env.adjustment_contrast >= 1.0 - eps and env.adjustment_contrast <= 1.05 + eps
			and env.adjustment_saturation >= 1.05 - eps and env.adjustment_saturation <= 1.10 + eps),
			"ajuste de cor leve (contraste %.2f, saturação %.2f)" % [env.adjustment_contrast, env.adjustment_saturation])
	_check(main.get_node("MapRenderer").get_node_or_null("Skirt") != null, "saia de chão montada além da borda do mapa")


## Em vários yaws e zooms, a névoa começa depois do ponto mais longe do mapa e o DOF de
## longe começa depois do anfiteatro + 4.
func _test_depth(main: Node) -> void:
	var camera := main.get_node("MapCamera") as MapCamera
	var env: Environment = _env(main)
	var attrs: CameraAttributesPractical = _attrs(main)
	var map: MapData = (main.get("match_state") as MatchState).map_data
	var ground_y: float = map.arena_floor_level * WorldScale.LEVEL_HEIGHT
	var built_lo := Vector2(INF, INF)
	var built_hi := Vector2(-INF, -INF)
	for cz in map.size.y:
		for cx in map.size.x:
			if map.is_built_cell(Vector2i(cx, cz)):
				built_lo = built_lo.min(Vector2(cx, cz))
				built_hi = built_hi.max(Vector2(cx + 1, cz + 1))
	var fog_ok := true
	var dof_ok := true
	var detail := ""
	for yaw: float in [0.0, 45.0, 135.0, 225.0, 300.0]:
		for preset: String in ["min", "default", "max"]:
			camera.set_zoom_preset(preset)
			camera.set_target_yaw(yaw, true)
			var cam_pos: Vector3 = camera.global_position
			var map_far: float = 0.0
			for corner: Vector2 in [Vector2.ZERO, Vector2(map.size.x, 0), Vector2(map.size), Vector2(0, map.size.y)]:
				map_far = maxf(map_far, cam_pos.distance_to(Vector3(corner.x, ground_y, corner.y)))
			var amph_far: float = 0.0
			for corner: Vector2 in [built_lo, Vector2(built_hi.x, built_lo.y), built_hi, Vector2(built_lo.x, built_hi.y)]:
				amph_far = maxf(amph_far, cam_pos.distance_to(Vector3(corner.x, ground_y, corner.y)))
			var fog_len: float = env.fog_depth_end - env.fog_depth_begin
			if env.fog_depth_begin < map_far or fog_len < 30.0 - 0.001 or fog_len > 50.0 + 0.001:
				fog_ok = false
				detail += "yaw %.0f %s: névoa %.1f-%.1f, mapa até %.1f; " % [yaw, preset, env.fog_depth_begin, env.fog_depth_end, map_far]
			if attrs.dof_blur_far_distance < amph_far + DOF_AMPHITHEATER_MARGIN:
				dof_ok = false
				detail += "yaw %.0f %s: DOF %.1f, anfiteatro até %.1f; " % [yaw, preset, attrs.dof_blur_far_distance, amph_far]
	_check(fog_ok, "névoa começa depois da borda do mapa e chega ao máximo 30 a 50 depois", detail)
	_check(dof_ok, "DOF de longe começa depois do anfiteatro + 4 (todos os yaws e zooms)", detail)
	camera.reset_to_default(true)


func _test_fx_off(main: Node) -> void:
	var atmosphere := main.get_node("Atmosphere") as Atmosphere
	var env: Environment = _env(main)
	var attrs: CameraAttributesPractical = _attrs(main)
	var sun := main.get_node("Sun") as DirectionalLight3D
	atmosphere.set_effects_enabled(false)
	_check(not attrs.dof_blur_far_enabled and not attrs.dof_blur_near_enabled and not env.glow_enabled
			and not env.fog_enabled and not env.ssao_enabled,
			"--fx=off desliga DOF, bloom, névoa e SSAO")
	_check(sun.shadow_enabled and env.background_mode == Environment.BG_SKY
			and main.get_node("MapRenderer").get_node_or_null("Skirt") != null,
			"--fx=off mantém sol, sombras, céu e saia")
	atmosphere.set_effects_enabled(true)
	_check(attrs.dof_blur_far_enabled and env.glow_enabled and env.fog_enabled and env.ssao_enabled
			and not attrs.dof_blur_near_enabled,
			"religar os efeitos volta ao padrão da cena")


func _test_ssao_switch(main: Node) -> void:
	var atmosphere := main.get_node("Atmosphere") as Atmosphere
	var env: Environment = _env(main)
	atmosphere.ssao_enabled = false
	var off_ok: bool = not env.ssao_enabled
	atmosphere.ssao_enabled = true
	_check(off_ok and env.ssao_enabled, "interruptor do SSAO (@export ssao_enabled) liga e desliga")


func _test_sun_follow(main: Node) -> void:
	var atmosphere := main.get_node("Atmosphere") as Atmosphere
	var camera := main.get_node("MapCamera") as MapCamera
	var sun := main.get_node("Sun") as DirectionalLight3D

	atmosphere.set_sun_follows_camera(false)
	camera.set_target_yaw(0.0, true)
	var before: float = sun.rotation_degrees.y
	camera.set_target_yaw(90.0, true)
	var diff_off: float = wrapf(sun.rotation_degrees.y - before, -180.0, 180.0)
	_check(is_zero_approx(diff_off), "com sun_follows_camera = false, o sol não gira com a câmera", "%.2f°" % diff_off)

	camera.set_target_yaw(0.0, true)
	atmosphere.set_sun_follows_camera(true)
	before = sun.rotation_degrees.y
	camera.set_target_yaw(90.0, true)
	var diff_on: float = wrapf(sun.rotation_degrees.y - before, -180.0, 180.0)
	_check(is_equal_approx(diff_on, 90.0), "com sun_follows_camera = true, set_target_yaw(90) gira o sol 90°", "%.2f°" % diff_on)

	atmosphere.set_sun_follows_camera(false)
	camera.reset_to_default(true)


func _test_no_vignette(main: Node) -> void:
	var found: Array[String] = []
	var stack: Array[Node] = [main]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if String(node.name).to_lower().contains("vignet"):
			found.append(str(node.get_path()))
		if node is CanvasItem:
			var mat := (node as CanvasItem).material as ShaderMaterial
			if mat != null and mat.shader != null and mat.shader.code.to_lower().contains("vignet"):
				found.append(str(node.get_path()))
		for child: Node in node.get_children():
			stack.append(child)
	_check(found.is_empty(), "sem nó de vinheta na cena", str(found))
