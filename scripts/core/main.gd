extends Node3D
## Liga os sistemas da cena principal: cria o MatchState (host local), conecta os
## sinais e lê os argumentos de linha de comando (depois de "--"):
## --zoom=min|max|default, --yaw=graus, --distance=N, --overview, --capture=arquivo.png,
## --fx=off (desliga DOF, bloom, névoa e SSAO), --ssao=off, --merge=off (não junta as malhas do mapa),
## --hud=off (esconde o HUD; só para as capturas de comparação com a referência),
## --focus-offset=N (desloca o ponto mirado N unidades no sentido da vista; negativo = para a câmera).
## --distance, --overview e --focus-offset são só para captura (fogem dos limites do zoom de jogo).
## Só captura (spec 013): --capture-frames=N (quadros de espera antes de salvar; o raymarch das nuvens no Vulkan
## por software é lento) e --cam-from=x,y,z --cam-to=x,y,z (câmera livre olhando de um ponto para outro).
## Na captura, o tempo das nuvens fica parado em 0 (imagem reproduzível).

## Quadros de espera antes de medir (sombras, glow e DOF estabilizarem).
const CAPTURE_DELAY_FRAMES: int = 60
## Quadros medidos (média de FPS) antes de salvar a captura.
const CAPTURE_MEASURE_FRAMES: int = 60
## Vista de cima da ilha inteira (--overview): inclinação e distância.
const OVERVIEW_PITCH: float = 50.0
const OVERVIEW_DISTANCE: float = 105.0

var match_state: MatchState = null

@onready var _map: MapLayout = $Map
@onready var _camera: MapCamera = $MapCamera
@onready var _hud: Hud = $HUD
@onready var _world_env: WorldEnvironment = $WorldEnvironment
@onready var _atmosphere: Atmosphere = $Atmosphere
@onready var _dither: OcclusionDither = $OcclusionDither
@onready var _merger: MeshMerger = $MeshMerger
@onready var _sky_globals: SkyGlobals = $SkyGlobals


func _ready() -> void:
	var args: Dictionary = _parse_user_args()
	match_state = MatchState.new()
	# O mapa é único e fixo: a cena map.tscn entrega os dados e o resto reage.
	_map.map_ready.connect(match_state.set_map)
	match_state.map_loaded.connect(_camera.focus_on_map)
	match_state.map_loaded.connect(_dither.set_arena)
	_hud.rotate_left_requested.connect(_camera.rotate_left)
	_hud.rotate_right_requested.connect(_camera.rotate_right)
	_hud.reset_rotation_requested.connect(_camera.reset_to_default)
	_camera.setup_effects(_world_env.environment, _world_env.camera_attributes as CameraAttributesPractical)
	_camera.yaw_changed.connect(_atmosphere.on_camera_yaw_changed)

	if str(args.get("fx", "")) == "off":
		_atmosphere.set_effects_enabled(false)
	if str(args.get("ssao", "")) == "off":
		_atmosphere.ssao_enabled = false
	if str(args.get("hud", "")) == "off":
		_hud.visible = false

	if args.has("zoom"):
		_camera.set_zoom_preset(str(args["zoom"]))
	if args.has("focus-offset"):
		_camera.focus_forward_offset = float(args["focus-offset"])
	if args.has("overview"):
		_camera.set_capture_view(OVERVIEW_PITCH, OVERVIEW_DISTANCE)
	if args.has("distance"):
		_camera.set_capture_view(_camera.pitch_degrees, float(args["distance"]))
	if args.has("yaw"):
		_camera.set_target_yaw(float(args["yaw"]), true)
	_map.build_map_data()
	# Só visual: junta as malhas do mapa por material (menos draw calls). --merge=off desliga.
	if str(args.get("merge", "")) != "off":
		_merger.merge(_map)
	if args.has("capture"):
		# Captura não é interativa: tecla perdida (janela nova pega o foco) não gira a câmera.
		_camera.set_process_unhandled_input(false)
		_sky_globals.freeze()
		if args.has("cam-from") and args.has("cam-to"):
			_camera.set_process(false)
			_camera.look_at_from_position(_parse_vec3(str(args["cam-from"])), _parse_vec3(str(args["cam-to"])), Vector3.UP)
		var delay: int = int(args.get("capture-frames", CAPTURE_DELAY_FRAMES))
		var measure: int = CAPTURE_MEASURE_FRAMES if not args.has("capture-frames") else maxi(2, delay / 4)
		# Roda em paralelo (espera quadros e fecha o jogo); não precisa de await aqui.
		@warning_ignore("missing_await")
		_capture_and_quit(str(args["capture"]), maxi(delay, 1), measure)


## "--chave=valor" vira {chave: valor}; "--chave" sozinho vira {chave: ""}.
func _parse_user_args() -> Dictionary:
	var result: Dictionary = {}
	for arg: String in OS.get_cmdline_user_args():
		if not arg.begins_with("--"):
			continue
		var body: String = arg.substr(2)
		var eq: int = body.find("=")
		if eq < 0:
			result[body] = ""
		else:
			result[body.substr(0, eq)] = body.substr(eq + 1)
	return result


## "x,y,z" -> Vector3.
static func _parse_vec3(text: String) -> Vector3:
	var parts: PackedStringArray = text.split(",")
	if parts.size() != 3:
		push_error("Vetor inválido (esperado x,y,z): " + text)
		return Vector3.ZERO
	return Vector3(float(parts[0]), float(parts[1]), float(parts[2]))


func _capture_and_quit(path: String, delay_frames: int, measure_frames: int) -> void:
	# Sem vsync, a média de FPS mede o custo real do quadro (e não a taxa do monitor).
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var viewport_rid: RID = get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(viewport_rid, true)
	for _i in delay_frames:
		await get_tree().process_frame
	var start_usec: int = Time.get_ticks_usec()
	var gpu_ms: float = 0.0
	for _i in measure_frames:
		await get_tree().process_frame
		gpu_ms += RenderingServer.viewport_get_measured_render_time_gpu(viewport_rid)
	var elapsed: float = float(Time.get_ticks_usec() - start_usec) / 1_000_000.0
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	print("Medição %dx%d: FPS médio (últimos %d quadros) %.2f; GPU %.1f ms/quadro; draw calls %d; primitivas %d" % [
			image.get_width(), image.get_height(), measure_frames, measure_frames / maxf(elapsed, 0.000001),
			gpu_ms / float(measure_frames),
			int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
			int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))])
	var abs_path: String = path
	if path.is_relative_path():
		abs_path = ProjectSettings.globalize_path("res://").path_join(path)
	DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
	var err: Error = image.save_png(abs_path)
	if err != OK:
		push_error("Falha ao salvar a captura em %s (erro %d)" % [abs_path, err])
	else:
		print("Captura salva: ", abs_path)
	get_tree().quit()
