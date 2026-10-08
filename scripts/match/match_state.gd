class_name MatchState
extends RefCounted
## Estado mínimo da partida (sem visual, sem nós). Faz o papel do "host local": recebe o
## mapa pronto (único e fixo, vindo de scenes/map.tscn), guarda e avisa por sinal.

signal map_loaded(map_data: MapData)

## Semente da partida, só para o RNG de combate futuro (o mapa não depende dela).
var match_seed: int = 0
var map_data: MapData = null


## Recebe o mapa lido da cena (MapLayout.map_ready).
func set_map(new_map: MapData) -> void:
	map_data = new_map
	map_loaded.emit(map_data)


func has_map() -> bool:
	return map_data != null
