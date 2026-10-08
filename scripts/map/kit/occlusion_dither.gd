class_name OcclusionDither
extends Node
## Dither de oclusão (spec 011): entrega aos materiais do kit com dither_on a posição da câmera
## e a área da arena; o shader apaga em pontos (Bayer) o que fica entre a câmera e a arena.
## Muda só uniforms dos .tres compartilhados, então vale para todas as árvores e muros de uma vez.

const MATERIALS_DIR: String = "res://assets/materials/"

## Quanto do que oclui some (0 a 1).
@export_range(0.0, 1.0, 0.05) var density: float = 0.6

var _materials: Array[ShaderMaterial] = []
var _arena_rect: Vector4 = Vector4(-10.0, -9.0, 10.0, 9.0)


func _ready() -> void:
	for file_name: String in DirAccess.get_files_at(MATERIALS_DIR):
		var clean: String = file_name.trim_suffix(".remap")
		if not clean.ends_with(".tres"):
			continue
		var mat := load(MATERIALS_DIR + clean) as ShaderMaterial
		if mat != null and mat.get_shader_parameter("dither_on") == true:
			_materials.append(mat)
	_push_settings()


## Liga ao MatchState.map_loaded: a arena do mapa decide a área protegida.
func set_arena(map_data: MapData) -> void:
	var rect: Rect2 = map_data.arena_rect
	_arena_rect = Vector4(rect.position.x, rect.position.y, rect.end.x, rect.end.y)
	_push_settings()


func _process(_delta: float) -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		return
	for mat: ShaderMaterial in _materials:
		mat.set_shader_parameter("cam_pos", cam.global_position)


func _push_settings() -> void:
	for mat: ShaderMaterial in _materials:
		mat.set_shader_parameter("arena_rect", _arena_rect)
		mat.set_shader_parameter("dither_density", density)
