class_name MeshBatch
extends RefCounted
## Acumula triângulos de uma superfície (um material) e grava numa ArrayMesh.
## Frente = sentido horário visto de fora (convenção do Godot).

var vertices: PackedVector3Array = PackedVector3Array()
var normals: PackedVector3Array = PackedVector3Array()
var uvs: PackedVector2Array = PackedVector2Array()


func is_empty() -> bool:
	return vertices.is_empty()


## Quad com cantos em ordem: cima-esquerda, cima-direita, baixo-direita, baixo-esquerda (vistos de frente).
func add_quad(top_left: Vector3, top_right: Vector3, bottom_right: Vector3, bottom_left: Vector3, normal: Vector3,
		uv_tl: Vector2, uv_tr: Vector2, uv_br: Vector2, uv_bl: Vector2) -> void:
	add_triangle(top_left, top_right, bottom_right, normal, uv_tl, uv_tr, uv_br)
	add_triangle(top_left, bottom_right, bottom_left, normal, uv_tl, uv_br, uv_bl)


func add_triangle(a: Vector3, b: Vector3, c: Vector3, normal: Vector3, uv_a: Vector2, uv_b: Vector2, uv_c: Vector2) -> void:
	vertices.append(a)
	vertices.append(b)
	vertices.append(c)
	for _i in 3:
		normals.append(normal)
	uvs.append(uv_a)
	uvs.append(uv_b)
	uvs.append(uv_c)


## Quad horizontal virado para cima, cantos (x, z) em qualquer ordem cíclica.
## UV em unidades do mundo (1 textura por unidade).
func add_top_quad(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, y: float) -> void:
	var pts: Array[Vector2] = [p0, p1, p2, p3]
	var area: float = 0.0
	for i in 4:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % 4]
		area += a.x * b.y - b.x * a.y
	if area < 0.0:
		pts.reverse()
	var v: Array[Vector3] = []
	for p: Vector2 in pts:
		v.append(Vector3(p.x, y, p.y))
	add_quad(v[0], v[1], v[2], v[3], Vector3.UP, pts[0], pts[1], pts[2], pts[3])


## Polígono horizontal virado para cima, cantos (x, z) em ordem cíclica.
## UV em unidades do mundo (1 textura por unidade).
func add_top_polygon(pts: Array[Vector2], y: float) -> void:
	var n: int = pts.size()
	if n < 3:
		return
	if n == 4:
		add_top_quad(pts[0], pts[1], pts[2], pts[3], y)
		return
	var area: float = 0.0
	for i in n:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % n]
		area += a.x * b.y - b.x * a.y
	var p: Array[Vector2] = pts.duplicate()
	if area < 0.0:
		p.reverse()
	var v0 := Vector3(p[0].x, y, p[0].y)
	for i in range(1, n - 1):
		var v1 := Vector3(p[i].x, y, p[i].y)
		var v2 := Vector3(p[i + 1].x, y, p[i + 1].y)
		add_triangle(v0, v1, v2, Vector3.UP, p[0], p[i], p[i + 1])


## Face vertical entre os pontos p e q (plano X/Z), de y0 a y1, virada para normal (x, z).
## UV em unidades do mundo: u ao longo da face, v = v_top - y (topo da textura em v_top).
func add_vertical_quad(p: Vector2, q: Vector2, y0: float, y1: float, normal: Vector2, v_top: float) -> void:
	var right := Vector2(normal.y, -normal.x)
	var left_pt: Vector2 = p
	var right_pt: Vector2 = q
	if (q - p).dot(right) < 0.0:
		left_pt = q
		right_pt = p
	var u_l: float = left_pt.dot(right)
	var u_r: float = right_pt.dot(right)
	var n3 := Vector3(normal.x, 0.0, normal.y)
	add_quad(
		Vector3(left_pt.x, y1, left_pt.y), Vector3(right_pt.x, y1, right_pt.y),
		Vector3(right_pt.x, y0, right_pt.y), Vector3(left_pt.x, y0, left_pt.y),
		n3,
		Vector2(u_l, v_top - y1), Vector2(u_r, v_top - y1), Vector2(u_r, v_top - y0), Vector2(u_l, v_top - y0))


func commit(mesh: ArrayMesh, material: Material) -> void:
	if is_empty():
		return
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var st := SurfaceTool.new()
	st.create_from_arrays(arrays)
	st.generate_tangents()
	st.commit(mesh)
	mesh.surface_set_material(mesh.get_surface_count() - 1, material)
