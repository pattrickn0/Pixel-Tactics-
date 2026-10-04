class_name MatchState
extends RefCounted
## Estado mínimo da partida (sem visual, sem nós). Faz o papel do "host local":
## recebe a intenção, valida, aplica e avisa por sinal. No multiplayer, só o
## autoritativo chama request_map; os clientes recebem a seed e geram o mesmo mapa.

signal map_generated(map_data: MapData)

var current_seed: int = 0
var map_data: MapData = null
var generator: MapGenerator


func _init(config: MapGenConfig = null) -> void:
	generator = MapGenerator.new(config)


## Intenção: "quero o mapa da seed N". Qualquer int é uma seed válida.
func request_map(map_seed: int) -> void:
	current_seed = map_seed
	map_data = generator.generate(map_seed)
	map_generated.emit(map_data)


func has_map() -> bool:
	return map_data != null
