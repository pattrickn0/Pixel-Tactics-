class_name Atmosphere
extends Node
## Comportamento da atmosfera (os valores ficam nos recursos da cena, editáveis no inspetor):
## liga/desliga os efeitos de pós (--fx=off), faz o sol acompanhar a câmera (opcional) e
## controla o SSAO. Só visual: nenhuma regra de jogo.

@export var sun: DirectionalLight3D = null
@export var world_environment: WorldEnvironment = null
## Ligado: o yaw do sol soma o yaw da câmera (mantém a direção relativa da vista padrão).
@export var sun_follows_camera: bool = false
## SSAO leve (assenta troncos, pedras e o pé dos muros).
@export var ssao_enabled: bool = true:
	set(value):
		ssao_enabled = value
		_apply_effects()

## Efeitos de pós (DOF, bloom, névoa, SSAO). Sol, sombras, céu e saia ficam sempre.
var effects_enabled: bool = true

## Yaw do sol na vista padrão (câmera em yaw 0), lido da cena.
var _base_sun_yaw: float = 0.0
var _camera_yaw: float = 0.0
# Valores da cena, para restaurar ao religar os efeitos.
var _scene_glow: bool = true
var _scene_fog: bool = true
var _scene_dof_far: bool = true
var _ready_done: bool = false


func _ready() -> void:
	if sun != null:
		_base_sun_yaw = sun.rotation_degrees.y
	var env: Environment = _environment()
	if env != null:
		_scene_glow = env.glow_enabled
		_scene_fog = env.fog_enabled
	var attrs: CameraAttributesPractical = _attributes()
	if attrs != null:
		_scene_dof_far = attrs.dof_blur_far_enabled
	_ready_done = true
	_apply_effects()


## Equivale ao argumento --fx=off (false) ou ao padrão (true).
func set_effects_enabled(enabled: bool) -> void:
	effects_enabled = enabled
	_apply_effects()


## Reage a MapCamera.yaw_changed.
func on_camera_yaw_changed(yaw_degrees: float) -> void:
	_camera_yaw = yaw_degrees
	_apply_sun_yaw()


func set_sun_follows_camera(enabled: bool) -> void:
	sun_follows_camera = enabled
	_apply_sun_yaw()


func _apply_sun_yaw() -> void:
	if sun == null:
		return
	var yaw: float = _base_sun_yaw + (_camera_yaw if sun_follows_camera else 0.0)
	sun.rotation_degrees.y = yaw


func _apply_effects() -> void:
	if not _ready_done:
		return
	var env: Environment = _environment()
	if env != null:
		env.glow_enabled = _scene_glow and effects_enabled
		env.fog_enabled = _scene_fog and effects_enabled
		env.ssao_enabled = ssao_enabled and effects_enabled
	var attrs: CameraAttributesPractical = _attributes()
	if attrs != null:
		attrs.dof_blur_far_enabled = _scene_dof_far and effects_enabled
		# O DOF de perto fica sempre desligado (nada perto da câmera é desfocado).
		attrs.dof_blur_near_enabled = false


func _environment() -> Environment:
	return world_environment.environment if world_environment != null else null


func _attributes() -> CameraAttributesPractical:
	if world_environment == null:
		return null
	return world_environment.camera_attributes as CameraAttributesPractical
