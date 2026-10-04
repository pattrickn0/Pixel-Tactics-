extends Node3D
## Liga os sistemas da cena principal: cria o MatchState (host local), conecta os
## sinais e lê os argumentos de linha de comando (--seed, --zoom, --capture, --placeholder-art).

## Quadros de espera antes de salvar a captura (sombras, glow e DOF estabilizarem).
const CAPTURE_DELAY_FRAMES: int = 60

var match_state: MatchState = null

@onready var _renderer: MapRenderer = $MapRenderer
@onready var _camera: MapCamera = $MapCamera
@onready var _hud: Hud = $HUD
@onready var _world_env: WorldEnvironment = $WorldEnvironment


func _ready() -> void:
	var args: Dictionary = _parse_user_args()
	match_state = MatchState.new()
	# Visual reage ao estado; HUD só manda intenção.
	match_state.map_generated.connect(_renderer.show_map)
	match_state.map_generated.connect(_camera.focus_on_map)
	match_state.map_generated.connect(_hud.show_map_info)
	_hud.map_requested.connect(match_state.request_map)
	_hud.rotate_left_requested.connect(_camera.rotate_left)
	_hud.rotate_right_requested.connect(_camera.rotate_right)
	_hud.reset_rotation_requested.connect(_camera.reset_to_default)
	_camera.setup_effects(_world_env.environment, _world_env.camera_attributes as CameraAttributesPractical)

	if args.has("placeholder-art"):
		_renderer.art.force_placeholders = true
	if args.has("zoom"):
		_camera.set_zoom_preset(str(args["zoom"]))
	if args.has("yaw"):
		_camera.set_target_yaw(float(args["yaw"]), true)
	var seed_text: String = str(args.get("seed", "")).strip_edges()
	if Hud.is_valid_seed_text(seed_text):
		match_state.request_map(seed_text.to_int())
	else:
		_hud.request_random_map()
	if args.has("capture"):
		# Roda em paralelo (espera quadros e fecha o jogo); não precisa de await aqui.
		@warning_ignore("missing_await")
		_capture_and_quit(str(args["capture"]))


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


func _capture_and_quit(path: String) -> void:
	for _i in CAPTURE_DELAY_FRAMES:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
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
