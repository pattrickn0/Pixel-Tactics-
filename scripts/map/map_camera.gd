class_name MapCamera
extends Camera3D
## Câmera do mapa: órbita em perspectiva ao redor do centro da arena.
## Suporta zoom (distância) e rotação (yaw/azimute) suave.
## Controle de rotação via botão direito/meio do mouse (arrastar), teclas Q/E ou setas, e botões da HUD.

## Inclinação para baixo, em graus (fixa).
@export_range(15.0, 70.0, 0.5) var pitch_degrees: float = 27
## Campo de visão vertical, em graus.
@export_range(15.0, 70.0, 0.5) var fov_degrees: float = 35.0
@export var min_distance: float = 8.0
@export var max_distance: float = 32.0
@export var start_distance: float = 28.0
## Quanto cada clique da roda muda a distância.
@export var zoom_step: float = 3.0
## Suavização do zoom (0 = instantâneo).
@export var zoom_smoothing: float = 12.0
## Suavização da rotação (0 = instantâneo).
@export var rotation_smoothing: float = 12.0
## Ângulo de giro em graus por passo (teclas Q/E ou botões).
@export var rotation_step: float = 45.0
## Sensibilidade ao arrastar com o mouse (graus por pixel).
@export var mouse_sensitivity: float = 0.35
## No zoom máximo, o alvo desce esta fração da profundidade da arena para o sul.
@export_range(0.0, 0.4, 0.01) var focus_south_ratio: float = 0.0
## Folga em volta da arena (muro, monólitos) que precisa ficar nítida.
@export var sharp_margin: float = 3.0
## Altura até onde a borda da arena precisa ficar nítida (monólitos).
@export var sharp_height: float = 3.0
@export var dof_near_transition: float = 6.0
@export var dof_far_transition: float = 18.0
## A névoa começa logo depois da arena e chega no máximo após esta distância.
@export var fog_length: float = 22.0

var distance: float = 0.0
var target_distance: float = 0.0
var yaw_degrees: float = 0.0
var target_yaw_degrees: float = 0.0

var _arena_center: Vector2 = Vector2.ZERO
var _arena_size: Vector2 = Vector2.ZERO
var _base_height: float = 0.0
var _environment: Environment = null
var _attributes: CameraAttributesPractical = null
var _is_dragging_rotation: bool = false


func _ready() -> void:
	projection = Camera3D.PROJECTION_PERSPECTIVE
	fov = fov_degrees
	near = 0.3
	far = 400.0
	distance = clampf(start_distance, min_distance, max_distance)
	target_distance = distance
	yaw_degrees = 0.0
	target_yaw_degrees = 0.0
	_apply_basis()
	_apply_position()


func _apply_basis() -> void:
	var pitch_rad: float = -deg_to_rad(pitch_degrees)
	var yaw_rad: float = deg_to_rad(yaw_degrees)
	basis = Basis(Vector3.UP, yaw_rad) * Basis(Vector3.RIGHT, pitch_rad)


## Recebe o ambiente e os atributos de câmera para manter DOF e névoa em volta da arena.
func setup_effects(environment_res: Environment, attributes_res: CameraAttributesPractical) -> void:
	_environment = environment_res
	_attributes = attributes_res
	_update_depth_effects()


## Reage a map_generated: reposiciona no centro da arena nova, mantendo a distância e rotação.
func focus_on_map(map_data: MapData) -> void:
	_arena_center = map_data.arena_center
	_arena_size = map_data.arena_rect.size
	_base_height = map_data.arena_base_level * WorldScale.LEVEL_HEIGHT
	_apply_position()


## "min", "max" ou "default".
func set_zoom_preset(preset: String) -> void:
	match preset:
		"min":
			set_target_distance(min_distance, true)
		"max":
			set_target_distance(max_distance, true)
		_:
			set_target_distance(start_distance, true)


func set_target_distance(value: float, immediate: bool = false) -> void:
	target_distance = clampf(value, min_distance, max_distance)
	if immediate or zoom_smoothing <= 0.0:
		distance = target_distance
		_apply_position()


func rotate_left() -> void:
	rotate_by(-rotation_step)


func rotate_right() -> void:
	rotate_by(rotation_step)


func rotate_by(delta_degrees: float, immediate: bool = false) -> void:
	set_target_yaw(target_yaw_degrees + delta_degrees, immediate)


func set_target_yaw(value_degrees: float, immediate: bool = false) -> void:
	target_yaw_degrees = value_degrees
	if immediate or rotation_smoothing <= 0.0:
		yaw_degrees = target_yaw_degrees
		_apply_basis()
		_apply_position()


## Reseta a câmera para a posição e rotação padrão (Norte e zoom inicial).
func reset_to_default(immediate: bool = false) -> void:
	set_target_yaw(0.0, immediate)
	set_target_distance(start_distance, immediate)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			set_target_distance(target_distance - zoom_step)
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			set_target_distance(target_distance + zoom_step)
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			_is_dragging_rotation = mb.pressed
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _is_dragging_rotation:
		var mm := event as InputEventMouseMotion
		target_yaw_degrees -= mm.relative.x * mouse_sensitivity
		yaw_degrees = target_yaw_degrees
		_apply_basis()
		_apply_position()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo:
			if k.keycode == KEY_A:
				rotate_left()
				get_viewport().set_input_as_handled()
			elif k.keycode == KEY_D:
				rotate_right()
				get_viewport().set_input_as_handled()
			elif k.keycode == KEY_SPACE or k.keycode == KEY_R:
				reset_to_default()
				get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	var moved := false
	if not is_equal_approx(distance, target_distance):
		var weight: float = 1.0 - exp(-zoom_smoothing * delta)
		distance = lerpf(distance, target_distance, weight)
		if absf(distance - target_distance) < 0.01:
			distance = target_distance
		distance = clampf(distance, min_distance, max_distance)
		moved = true

	if not is_equal_approx(yaw_degrees, target_yaw_degrees):
		var weight_rot: float = 1.0 - exp(-rotation_smoothing * delta)
		yaw_degrees = lerpf(yaw_degrees, target_yaw_degrees, weight_rot)
		if absf(yaw_degrees - target_yaw_degrees) < 0.01:
			yaw_degrees = target_yaw_degrees
		_apply_basis()
		moved = true

	if moved:
		_apply_position()


## Ponto mirado: centro da arena.
func get_focus_point() -> Vector3:
	var t: float = 0.0
	if max_distance > min_distance:
		t = clampf((distance - min_distance) / (max_distance - min_distance), 0.0, 1.0)
	var south_offset: float = _arena_size.y * focus_south_ratio * t
	var center3 := Vector3(_arena_center.x, _base_height, _arena_center.y)
	if south_offset > 0.0:
		var forward := -Vector3(basis.z.x, 0.0, basis.z.z).normalized()
		center3 -= forward * south_offset
	return center3


func _apply_position() -> void:
	# basis.z aponta para trás da câmera: posição = alvo + trás × distância.
	position = get_focus_point() + basis.z * distance
	_update_depth_effects()


## DOF: nítido de pouco antes da arena até pouco depois dela (com muro e monólitos).
## Névoa: começa depois da arena.
func _update_depth_effects() -> void:
	if _arena_size == Vector2.ZERO:
		return
	var view := Transform3D(basis, position).affine_inverse()
	var near_depth: float = INF
	var far_depth: float = 0.0
	var far_dist: float = 0.0
	var lo := _arena_center - _arena_size * 0.5 - Vector2.ONE * sharp_margin
	var hi := _arena_center + _arena_size * 0.5 + Vector2.ONE * sharp_margin
	for corner: Vector2 in [lo, Vector2(hi.x, lo.y), hi, Vector2(lo.x, hi.y)]:
		for h: float in [_base_height, _base_height + sharp_height]:
			var p := Vector3(corner.x, h, corner.y)
			var depth: float = -(view * p).z
			near_depth = minf(near_depth, depth)
			far_depth = maxf(far_depth, depth)
			far_dist = maxf(far_dist, position.distance_to(p))
	if _attributes != null:
		_attributes.dof_blur_near_distance = maxf(near_depth, 0.05)
		_attributes.dof_blur_near_transition = clampf(near_depth * 0.5, 0.01, dof_near_transition)
		_attributes.dof_blur_far_distance = far_depth
		_attributes.dof_blur_far_transition = dof_far_transition
	if _environment != null:
		_environment.fog_depth_begin = far_dist
		_environment.fog_depth_end = far_dist + fog_length
