extends SceneTree
## Testes da atmosfera de dia claro (spec 004 e spec 012 Fase 2: sol #FFE9C8 do oeste-noroeste a 40-48°, céu
## próprio, ambiente lavanda, névoa de profundidade lavanda depois da borda e de altura abaixo de -3, SSAO e bloom
## leves, desfoque fraco só no fundo, Filmic/AgX, MSAA 4x sem TAA/FXAA e sem vinheta).
## Rodar depois do comando de validação 1:
##   "$G" --headless --path . --script tools/tests/test_atmosphere.gd
## Imprime PASS/FAIL por verificação e sai com 0 (tudo passou) ou 1.

const SETTLE_FRAMES: int = 6
const SUN_COLOR: Color = Color8(0xFF, 0xE9, 0xC8)
const AMBIENT_COLOR: Color = Color8(0xB8, 0xC4, 0xDC)
const FOG_COLOR: Color = Color8(0xDC, 0xD6, 0xE6)
const COLOR_TOLERANCE: float = 0.01
## Fase 2 da 012: desfoque do fundo bem mais fraco que o da Fase 1 (0,04).
const MAX_DOF_AMOUNT: float = 0.025
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

	_test_sun(main)
	_test_config(main)
	_test_depth(main)
	_test_fx_off(main)
	_test_ssao_switch(main)
	_test_sun_follow(main)
	_test_no_vignette(main)
	_test_phase2_post(main)

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
	_check(_color_near(sun.light_color, SUN_COLOR), "sol com cor #FFE9C8", str(sun.light_color))
	_check(elevation >= 40.0 and elevation <= 48.0, "sol com elevação entre 40° e 48°", "%.1f°" % elevation)
	# Oeste-noroeste: vem de x negativo (oeste), um pouco de z negativo (norte), mais oeste que norte.
	_check(from.x < 0.0 and from.z < 0.0 and absf(from.x) > 2.0 * absf(from.z),
			"sol vindo do oeste-noroeste", "direção de origem %s" % str(from))
	_check(sun.shadow_enabled and sun.directional_shadow_mode == DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS,
			"sol com sombras ligadas e 4 splits")
	_check(sun.shadow_blur > 0.0, "sombra direcional com borda suave (shadow_blur %.2f)" % sun.shadow_blur)
	_check(atmosphere.sun_follows_camera == false, "sun_follows_camera é false por padrão")


func _test_config(main: Node) -> void:
	var env: Environment = _env(main)
	var attrs: CameraAttributesPractical = _attrs(main)
	var sky_mat := env.sky.sky_material as ShaderMaterial if env.sky != null else null
	_check(env.background_mode == Environment.BG_SKY and sky_mat != null and sky_mat.shader != null
			and sky_mat.shader.resource_path.ends_with("sky_day.gdshader"),
			"fundo de céu com o shader próprio (sky_day.gdshader)")
	var below: Variant = sky_mat.get_shader_parameter("below") if sky_mat != null else null
	var below_color: Color = below if below is Color else Color.BLACK
	_check(below_color.get_luminance() > 0.6, "o céu abaixo do horizonte é claro (lavanda), sem chão escuro", str(below_color))
	_check(env.ambient_light_source == Environment.AMBIENT_SOURCE_COLOR and _color_near(env.ambient_light_color, AMBIENT_COLOR),
			"luz ambiente lavanda-azulada #B8C4DC")
	_check(env.fog_enabled and env.fog_mode == Environment.FOG_MODE_DEPTH and _color_near(env.fog_light_color, FOG_COLOR)
			and env.fog_sun_scatter <= 0.05 and not env.volumetric_fog_enabled,
			"névoa de profundidade lavanda #DCD6E6, sem espalhamento do sol e sem névoa volumétrica")
	_check(env.glow_enabled and env.glow_hdr_threshold >= 1.0, "glow com limiar HDR >= 1,0 (%.2f)" % env.glow_hdr_threshold)
	_check(not attrs.dof_blur_near_enabled, "DOF de perto desligado")
	_check(attrs.dof_blur_far_enabled and attrs.dof_blur_amount <= MAX_DOF_AMOUNT,
			"DOF de longe ligado com força <= 0,025 (%.3f)" % attrs.dof_blur_amount)
	_check(env.adjustment_color_correction == null, "sem adjustment_color_correction")
	var eps: float = 0.001
	_check(not env.adjustment_enabled or (env.adjustment_contrast >= 1.0 - eps and env.adjustment_contrast <= 1.05 + eps
			and env.adjustment_saturation >= 1.05 - eps and env.adjustment_saturation <= 1.10 + eps),
			"ajuste de cor leve (contraste %.2f, saturação %.2f)" % [env.adjustment_contrast, env.adjustment_saturation])
	_check(_has_island(main), "topo da ilha montado (grupo Island) e sem o chão de fundo antigo (ground_far)")


## Em vários yaws e zooms, a névoa começa depois do ponto mais longe do mapa e o DOF de
## longe começa depois do anfiteatro + 4.
func _test_depth(main: Node) -> void:
	var camera := main.get_node("MapCamera") as MapCamera
	var env: Environment = _env(main)
	var attrs: CameraAttributesPractical = _attrs(main)
	var map: MapData = (main.get("match_state") as MatchState).map_data
	var ground_y: float = 0.0
	var built_lo: Vector2 = map.arena_rect.position
	var built_hi: Vector2 = map.arena_rect.end
	for area: MapHeightArea in map.height_areas:
		built_lo = built_lo.min(area.rect.position)
		built_hi = built_hi.max(area.rect.end)
	var fog_ok := true
	var dof_ok := true
	var detail := ""
	for yaw: float in [0.0, 45.0, 135.0, 225.0, 300.0]:
		for preset: String in ["min", "default", "max"]:
			camera.set_zoom_preset(preset)
			camera.set_target_yaw(yaw, true)
			var cam_pos: Vector3 = camera.global_position
			var map_far: float = 0.0
			for corner: Vector2 in [map.bounds.position, Vector2(map.bounds.end.x, map.bounds.position.y), map.bounds.end,
					Vector2(map.bounds.position.x, map.bounds.end.y)]:
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


func _has_island(main: Node) -> bool:
	var map: Node = main.get_node("Map")
	var island: Node = map.get_node_or_null("Island")
	if island == null:
		return false
	var has_top := false
	for child: Node in island.get_children():
		has_top = has_top or str(child.scene_file_path).ends_with("/island_top.tscn")
	for child: Node in map.get_node("Ground").get_children():
		if str(child.scene_file_path).ends_with("/ground_far.tscn"):
			return false
	return has_top


func _test_fx_off(main: Node) -> void:
	var atmosphere := main.get_node("Atmosphere") as Atmosphere
	var env: Environment = _env(main)
	var attrs: CameraAttributesPractical = _attrs(main)
	var sun := main.get_node("Sun") as DirectionalLight3D
	atmosphere.set_effects_enabled(false)
	_check(not attrs.dof_blur_far_enabled and not attrs.dof_blur_near_enabled and not env.glow_enabled
			and not env.fog_enabled and not env.ssao_enabled,
			"--fx=off desliga DOF, bloom, névoa e SSAO")
	_check(sun.shadow_enabled and env.background_mode == Environment.BG_SKY and _has_island(main),
			"--fx=off mantém sol, sombras, céu e a ilha")
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


## Fase 2 da 012: tonemap que preserva as cores, névoa de altura abaixo de -3, SSAO leve e antisserrilhado MSAA 4x
## sem TAA nem FXAA (borram o pixel dos personagens).
func _test_phase2_post(main: Node) -> void:
	var env: Environment = _env(main)
	_check(env.tonemap_mode == Environment.TONE_MAPPER_FILMIC or env.tonemap_mode == Environment.TONE_MAPPER_AGX,
			"tonemap Filmic ou AgX (modo %d)" % env.tonemap_mode)
	_check(env.fog_height_density > 0.0 and absf(env.fog_height + 3.0) <= 0.01,
			"névoa de altura abaixo de -3 (altura %.2f, densidade %.3f)" % [env.fog_height, env.fog_height_density])
	_check(env.ssao_enabled and env.ssao_intensity <= 2.0, "SSAO leve (intensidade %.2f)" % env.ssao_intensity)
	_check(env.glow_enabled and env.glow_intensity <= 0.5 and env.glow_bloom <= 0.05,
			"bloom leve (intensidade %.2f, bloom %.2f)" % [env.glow_intensity, env.glow_bloom])
	var msaa: int = int(ProjectSettings.get_setting("rendering/anti_aliasing/quality/msaa_3d", 0))
	var fxaa: int = int(ProjectSettings.get_setting("rendering/anti_aliasing/quality/screen_space_aa", 0))
	var taa: bool = bool(ProjectSettings.get_setting("rendering/anti_aliasing/quality/use_taa", false))
	_check(msaa == Viewport.MSAA_4X and fxaa == 0 and not taa, "MSAA 4x, sem FXAA e sem TAA (msaa %d, ssaa %d, taa %s)" % [msaa, fxaa, str(taa)])
