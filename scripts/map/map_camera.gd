class_name MapCamera
extends Camera3D
## Câmera do mapa: órbita em perspectiva ao redor do centro da arena, inclinação fixa.
## Mudam só o yaw (até max_yaw_steps passos de 45° para cada lado do padrão) e a distância (zoom),
## os dois com suavização. Giro só pelo teclado (A/D) e pelos botões do HUD; Espaço volta ao padrão.
## Zoom pela roda do mouse. Nenhum botão do mouse gira a câmera (fica livre para as peças).

## Emitido sempre que o yaw (animado) muda; a atmosfera usa para o sol acompanhar a câmera.
signal yaw_changed(yaw_degrees: float)
## Emitido quando o yaw alvo muda; o HUD usa para desabilitar o botão do lado que chegou ao limite.
signal rotation_limits_changed(can_rotate_left: bool, can_rotate_right: bool)

## Distância do enquadramento da referência (docs/reference/ilha-flutuante.webp, specs 012 e 013):
## em yaw 0 a câmera fica em (0; 24,52; 43,81) mirando (0, 0, -4,3). Só para as capturas de medida e
## os testes que comparam com a referência; o jogo começa em start_distance (10% mais perto).
const REFERENCE_DISTANCE: float = 54.0

## Inclinação para baixo, em graus (fixa).
@export_range(15.0, 70.0, 0.5) var pitch_degrees: float = 27.0
## Campo de visão vertical, em graus.
@export_range(15.0, 70.0, 0.5) var fov_degrees: float = 37.0
## Limites do zoom. max_distance × cos(pitch) − focus_forward_offset fica ≤ 50 (spec 012):
## a órbita nunca chega na ilha alta nem nas ilhotas de fundo.
@export var min_distance: float = 14.0
@export var max_distance: float = 60.0
## Zoom inicial e do Espaço: 10% mais perto que REFERENCE_DISTANCE (pedido do usuário, 2026-10-09).
@export var start_distance: float = 48.6
## Quanto cada clique da roda muda a distância.
@export var zoom_step: float = 3.0
## Suavização do zoom (0 = instantâneo).
@export var zoom_smoothing: float = 12.0
## Suavização da rotação (0 = instantâneo).
@export var rotation_smoothing: float = 12.0
## Ângulo de giro em graus por passo (teclas A/D ou botões do HUD).
@export var rotation_step: float = 45.0
## Quantos passos de giro o jogador pode dar para cada lado do yaw 0 (1 = yaw de -45° a +45°).
@export_range(0, 4) var max_yaw_steps: int = 1
## O ponto mirado fica esta distância à frente do centro da arena, no sentido da vista
## (gira junto com o yaw). Só enquadramento: a órbita continua em volta do centro.
@export var focus_forward_offset: float = 4.3
## Altura acima do chão mais alto do mapa que precisa ficar nítida (copas).
@export var sharp_height: float = 6.0
## O desfoque de longe começa pelo menos esta distância depois do ponto mais longe do anfiteatro.
@export var dof_amphitheater_margin: float = 4.0
## Transição longa do desfoque de longe (do nítido ao desfoque máximo).
@export var dof_far_transition: float = 40.0
## A névoa começa depois da borda do mapa e chega no máximo após esta distância (30 a 50).
@export_range(30.0, 50.0, 1.0) var fog_length: float = 30.0

var distance: float = 0.0
var target_distance: float = 0.0
## Yaw atual (animado) e alvo, em graus. Pelo jogador (A/D, HUD) o alvo fica em
## [-max_yaw_degrees(), max_yaw_degrees()]; set_target_yaw (captura e testes) aceita qualquer ângulo.
var yaw_degrees: float = 0.0
var target_yaw_degrees: float = 0.0

var _arena_center: Vector2 = Vector2.ZERO
var _arena_size: Vector2 = Vector2.ZERO
var _base_height: float = 0.0
## Caixa do mapa e do anfiteatro (plano X/Z) e altura do chão mais alto do mapa.
var _map_rect: Rect2 = Rect2()
var _amphitheater_rect: Rect2 = Rect2()
var _map_top_height: float = 0.0
var _environment: Environment = null
var _attributes: CameraAttributesPractical = null


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
	yaw_changed.emit(yaw_degrees)


## Recebe o ambiente e os atributos de câmera para manter DOF e névoa além do mapa.
func setup_effects(environment_res: Environment, attributes_res: CameraAttributesPractical) -> void:
	_environment = environment_res
	_attributes = attributes_res
	_update_depth_effects()


## Reage a MatchState.map_loaded: mira o centro da arena, mantendo a distância e a rotação.
func focus_on_map(map_data: MapData) -> void:
	_arena_center = map_data.arena_center
	_arena_size = map_data.arena_rect.size
	_base_height = 0.0
	_map_rect = map_data.bounds
	_amphitheater_rect = _structure_bounds(map_data)
	_map_top_height = map_data.get_max_height()
	_apply_position()


## Caixa dos chãos elevados e escadas (o anfiteatro); a arena se não houver nenhum.
static func _structure_bounds(map_data: MapData) -> Rect2:
	var result: Rect2 = map_data.arena_rect
	for area: MapHeightArea in map_data.height_areas:
		result = result.merge(area.rect)
	for stair: MapStair in map_data.stairs:
		result = result.merge(stair.rect)
	return result


## "min", "max", "reference" (REFERENCE_DISTANCE, só captura) ou "default".
func set_zoom_preset(preset: String) -> void:
	match preset:
		"min":
			set_target_distance(min_distance, true)
		"max":
			set_target_distance(max_distance, true)
		"reference":
			set_target_distance(REFERENCE_DISTANCE, true)
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


## Giro relativo do jogador: soma ao alvo, preso entre -max_yaw_degrees() e +max_yaw_degrees().
## No limite, o giro para o mesmo lado não faz nada.
func rotate_by(delta_degrees: float, immediate: bool = false) -> void:
	var limit: float = max_yaw_degrees()
	target_yaw_degrees = clampf(target_yaw_degrees + delta_degrees, -limit, limit)
	_finish_yaw_change(immediate)


## Maior |yaw| que o jogador alcança (rotation_step × max_yaw_steps).
func max_yaw_degrees() -> float:
	return rotation_step * float(maxi(max_yaw_steps, 0))


func can_rotate_left() -> bool:
	return target_yaw_degrees > -max_yaw_degrees() + 0.001


func can_rotate_right() -> bool:
	return target_yaw_degrees < max_yaw_degrees() - 0.001


## Yaw absoluto, sem o limite do jogador (captura --yaw e testes): vai pelo caminho mais curto
## (no máximo 180°) até o ângulo pedido.
func set_target_yaw(value_degrees: float, immediate: bool = false) -> void:
	target_yaw_degrees = yaw_degrees + wrapf(value_degrees - yaw_degrees, -180.0, 180.0)
	_finish_yaw_change(immediate)


## Volta ao padrão: yaw 0 (pelo caminho mais curto) e zoom inicial.
func reset_to_default(immediate: bool = false) -> void:
	set_target_yaw(0.0, immediate)
	set_target_distance(start_distance, immediate)


func _finish_yaw_change(immediate: bool) -> void:
	if immediate or rotation_smoothing <= 0.0:
		yaw_degrees = target_yaw_degrees
	_wrap_yaw()
	_apply_basis()
	_apply_position()
	rotation_limits_changed.emit(can_rotate_left(), can_rotate_right())


## Mantém o alvo em [-180, 180) somando o mesmo múltiplo de 360 no atual: o ângulo na
## tela não muda (sem salto) e o yaw não acumula voltas.
func _wrap_yaw() -> void:
	var shift: float = wrapf(target_yaw_degrees, -180.0, 180.0) - target_yaw_degrees
	target_yaw_degrees += shift
	yaw_degrees += shift


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			set_target_distance(target_distance - zoom_step)
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			set_target_distance(target_distance + zoom_step)
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
			elif k.keycode == KEY_SPACE:
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


## Ponto mirado: o centro da arena deslocado focus_forward_offset no sentido da vista.
func get_focus_point() -> Vector3:
	return focus_for(yaw_degrees)


## Centro da órbita (centro da arena, no chão).
func get_orbit_center() -> Vector3:
	return Vector3(_arena_center.x, _base_height, _arena_center.y)


## Ponto mirado para um yaw qualquer (sem mexer na câmera).
func focus_for(yaw: float) -> Vector3:
	var yaw_rad: float = deg_to_rad(yaw)
	# Em yaw 0 a câmera olha para -Z (norte).
	var forward := Vector3(-sin(yaw_rad), 0.0, -cos(yaw_rad))
	return get_orbit_center() + forward * focus_forward_offset


## Transformação da câmera para um yaw e uma distância (mesma conta de _apply_basis/_apply_position).
## Usada pelos testes de composição e de visibilidade.
func transform_for(yaw: float, dist: float) -> Transform3D:
	var b := Basis(Vector3.UP, deg_to_rad(yaw)) * Basis(Vector3.RIGHT, -deg_to_rad(pitch_degrees))
	return Transform3D(b, focus_for(yaw) + b.z * dist)


## Raio horizontal da órbita (do centro da arena até a câmera) numa distância.
func orbit_radius(dist: float) -> float:
	return dist * cos(deg_to_rad(pitch_degrees)) - focus_forward_offset


## Câmera só para captura (--overview): mais alta e mais longe, mostra a ilha inteira.
## Fora dos limites do zoom de jogo; não é usada no jogo.
func set_capture_view(pitch: float, dist: float) -> void:
	pitch_degrees = pitch
	min_distance = minf(min_distance, dist)
	max_distance = maxf(max_distance, dist)
	set_target_distance(dist, true)
	_apply_basis()
	_apply_position()


func _apply_position() -> void:
	# basis.z aponta para trás da câmera: posição = alvo + trás × distância.
	position = get_focus_point() + basis.z * distance
	_update_depth_effects()


## DOF: só o fundo distante desfoca. Começa depois do ponto mais longe do mapa inteiro
## (anfiteatro e mata), e nunca antes do anfiteatro + dof_amphitheater_margin.
## Névoa: começa depois do ponto mais longe do chão do mapa (em distância, como a névoa do Godot).
func _update_depth_effects() -> void:
	if _map_rect.size == Vector2.ZERO:
		return
	var view := Transform3D(basis, position).affine_inverse()
	var heights: Array[float] = [_base_height, _map_top_height + sharp_height]
	var map_depth: float = 0.0
	for p: Vector3 in _box_corners(_map_rect, heights):
		map_depth = maxf(map_depth, -(view * p).z)
	# A névoa usa o chão do mapa (sem as copas): assim ela já aparece logo além da borda.
	var map_dist: float = 0.0
	for p: Vector3 in _box_corners(_map_rect, [_base_height, _map_top_height] as Array[float]):
		map_dist = maxf(map_dist, position.distance_to(p))
	var amph_dist: float = 0.0
	for p: Vector3 in _box_corners(_amphitheater_rect, heights):
		amph_dist = maxf(amph_dist, position.distance_to(p))
	if _attributes != null:
		_attributes.dof_blur_far_distance = maxf(map_depth, amph_dist + dof_amphitheater_margin)
		_attributes.dof_blur_far_transition = dof_far_transition
	if _environment != null:
		_environment.fog_depth_begin = map_dist
		_environment.fog_depth_end = map_dist + fog_length


static func _box_corners(rect: Rect2, heights: Array[float]) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for corner: Vector2 in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
		for h: float in heights:
			out.append(Vector3(corner.x, h, corner.y))
	return out
