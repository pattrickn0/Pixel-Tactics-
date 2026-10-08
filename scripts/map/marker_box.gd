@tool
class_name MarkerBox
extends Node3D
## Base dos marcadores da cena (só dados). No editor desenha uma caixa de linhas para o
## usuário ver o que o marcador cobre; no jogo não desenha nada.
## size = largura (X local) × fundo (Z local), em unidades do mundo.

@export var size: Vector2 = Vector2.ONE:
	set(value):
		size = value
		_refresh_gizmo()

var _gizmo: MeshInstance3D = null


func _ready() -> void:
	_refresh_gizmo()


## Cor da caixa no editor.
func gizmo_color() -> Color:
	return Color(1.0, 1.0, 0.0)


## Altura da caixa no editor.
func gizmo_height() -> float:
	return 0.1


func _refresh_gizmo() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	if _gizmo == null:
		_gizmo = MeshInstance3D.new()
		_gizmo.name = "Gizmo"
		_gizmo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_gizmo)
	var half := Vector3(size.x * 0.5, 0.0, size.y * 0.5)
	var top: float = gizmo_height()
	var pts: Array[Vector3] = [
		Vector3(-half.x, 0.0, -half.z), Vector3(half.x, 0.0, -half.z),
		Vector3(half.x, 0.0, half.z), Vector3(-half.x, 0.0, half.z),
	]
	var verts := PackedVector3Array()
	for i in 4:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[(i + 1) % 4]
		verts.append(a)
		verts.append(b)
		verts.append(a + Vector3(0.0, top, 0.0))
		verts.append(b + Vector3(0.0, top, 0.0))
		verts.append(a)
		verts.append(a + Vector3(0.0, top, 0.0))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = gizmo_color()
	mesh.surface_set_material(0, mat)
	_gizmo.mesh = mesh


## Retângulo do marcador no plano X/Z do mundo (caixa envolvente se a rotação não for
## múltiplo de 90°). Usa a transformação global.
func world_rect() -> Rect2:
	return MarkerBox.rect_of(global_transform, Rect2(-size * 0.5, size))


## Caixa envolvente, no plano X/Z do mundo, de um retângulo (X/Z locais) sob a transformação.
static func rect_of(xform: Transform3D, local_rect: Rect2) -> Rect2:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for corner: Vector2 in [local_rect.position, Vector2(local_rect.end.x, local_rect.position.y),
			local_rect.end, Vector2(local_rect.position.x, local_rect.end.y)]:
		var w: Vector3 = xform * Vector3(corner.x, 0.0, corner.y)
		lo = lo.min(Vector2(w.x, w.z))
		hi = hi.max(Vector2(w.x, w.z))
	# Arredonda o ruído de ponto flutuante da rotação (a grade das peças é de 1/32).
	lo = (lo * 1024.0).round() / 1024.0
	hi = (hi * 1024.0).round() / 1024.0
	return Rect2(lo, hi - lo)
