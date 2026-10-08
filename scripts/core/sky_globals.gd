@tool
class_name SkyGlobals
extends Node
## Publica a luz do sol e o tempo das nuvens em uniforms GLOBAIS de shader (spec 013, decisões 3 e 8): a direção
## (para o sol), a cor e a energia saem só do nó Sun, a cada quadro. Nenhum shader tem a direção escrita. As nuvens
## andam devagar (deriva do ruído, forma e posição fixas); na captura o tempo fica parado em 0.
## Só visual: nenhuma regra de jogo. Os globais estão declarados em project.godot ([shader_globals]).

@export var sun: DirectionalLight3D = null
## Deriva lenta do ruído das nuvens (decisão provisória N1). Desligado, as nuvens ficam paradas.
@export var drift_enabled: bool = true
## Multiplica o tempo das nuvens (1 = o ruído anda drift_speed unidades/s, definido no material).
@export_range(0.0, 2.0, 0.05) var drift_rate: float = 1.0

## Últimos valores publicados (os testes leem daqui; o servidor de renderização headless não guarda os globais).
var published_direction: Vector3 = Vector3.ZERO
var published_color: Color = Color.WHITE
var published_energy: float = 0.0
var cloud_time: float = 0.0
## Parado (captura): o tempo das nuvens fica em 0 e não anda.
var frozen: bool = false


func _ready() -> void:
	publish()


func _process(delta: float) -> void:
	if not frozen and drift_enabled and not Engine.is_editor_hint():
		cloud_time += delta * drift_rate
	publish()


## Para o tempo das nuvens em 0 (capturas reproduzíveis).
func freeze() -> void:
	frozen = true
	cloud_time = 0.0
	publish()


## Direção PARA o sol (mundo), a partir do nó: a luz direcional anda no -Z dela.
static func sun_direction_of(light: DirectionalLight3D) -> Vector3:
	return light.global_transform.basis.z.normalized()


func publish() -> void:
	if sun == null:
		return
	published_direction = sun_direction_of(sun) if sun.is_inside_tree() else sun.transform.basis.z.normalized()
	published_color = sun.light_color
	published_energy = sun.light_energy if sun.visible else 0.0
	RenderingServer.global_shader_parameter_set(&"sun_direction", published_direction)
	RenderingServer.global_shader_parameter_set(&"sun_color", published_color)
	RenderingServer.global_shader_parameter_set(&"sun_energy", published_energy)
	RenderingServer.global_shader_parameter_set(&"cloud_time", cloud_time)
