class_name MeshMerger
extends Node
## Só visual (spec 012, item 9: ≤ 500 draw calls na câmera padrão). No jogo, junta as malhas estáticas do
## mapa por material: cada grupo de lotes vira uma MeshInstance3D com uma superfície por material, e as
## peças originais ficam escondidas (continuam na cena, com os marcadores e as pegadas, e o editor não muda).
## As faixas de UV de mundo do kit_surface (uv_mode 2) dependem do eixo local da peça: o eixo vai no UV2.

## Desligado, nada é juntado (para comparar no editor ou medir).
@export var enabled: bool = true
## Grupos juntados num lote só (o anfiteatro e a ilha, sempre no quadro).
@export var main_groups: PackedStringArray = ["Ground", "StepLow", "Terrace", "Walls", "Stairs", "Island", "Structures",
		"Decals", "Forest", "Props"]
## Grupos com lote próprio cada um (saem do quadro quando a câmera gira e podem ser descartados).
@export var separate_groups: PackedStringArray = ["Sky", "Fx"]

## Quantas MeshInstance3D foram escondidas na última junção.
var merged_sources: int = 0


## Junta as malhas dos grupos de map_root. Devolve o número de superfícies criadas.
func merge(map_root: Node3D) -> int:
	merged_sources = 0
	if not enabled or map_root == null:
		return 0
	var surfaces: int = 0
	var main_nodes: Array[Node] = []
	for group_name: String in main_groups:
		var group: Node = map_root.get_node_or_null(group_name)
		if group != null:
			main_nodes.append(group)
	surfaces += _merge_batch(map_root, main_nodes, "MergedMain")
	for group_name: String in separate_groups:
		var group: Node = map_root.get_node_or_null(group_name)
		if group != null:
			var only: Array[Node] = [group]
			surfaces += _merge_batch(map_root, only, "Merged" + group_name)
	return surfaces


func _merge_batch(map_root: Node3D, roots: Array[Node], batch_name: String) -> int:
	var to_local: Transform3D = map_root.global_transform.affine_inverse()
	# chave (material + sombra) -> acumulador
	var acc: Dictionary = {}
	var order: Array = []
	var sources: Array[MeshInstance3D] = []
	for root: Node in roots:
		for node: Node in _descendants(root):
			var mi := node as MeshInstance3D
			if mi == null or not mi.visible or not (mi.mesh is ArrayMesh):
				continue
			var mesh := mi.mesh as ArrayMesh
			var xf: Transform3D = to_local * mi.global_transform
			for s in mesh.get_surface_count():
				if mesh.surface_get_primitive_type(s) != Mesh.PRIMITIVE_TRIANGLES:
					continue
				var mat: Material = mi.get_active_material(s)
				var key: String = "%d_%d" % [mat.get_instance_id() if mat != null else 0, int(mi.cast_shadow)]
				if not acc.has(key):
					acc[key] = _Acc.new(mat, mi.cast_shadow)
					order.append(key)
				(acc[key] as _Acc).add(mesh.surface_get_arrays(s), xf, _strip_axis(mat))
			sources.append(mi)
	if order.is_empty():
		return 0
	var shadow_mesh := ArrayMesh.new()
	var plain_mesh := ArrayMesh.new()
	for key: String in order:
		var a: _Acc = acc[key]
		a.commit(shadow_mesh if a.shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF else plain_mesh)
	var count: int = 0
	for pair: Array in [[shadow_mesh, GeometryInstance3D.SHADOW_CASTING_SETTING_ON, "Shadow"],
			[plain_mesh, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Plain"]]:
		var mesh: ArrayMesh = pair[0]
		if mesh.get_surface_count() == 0:
			continue
		var out := MeshInstance3D.new()
		out.name = batch_name + str(pair[2])
		out.mesh = mesh
		out.cast_shadow = pair[1]
		map_root.add_child(out)
		count += mesh.get_surface_count()
	for mi: MeshInstance3D in sources:
		mi.visible = false
	merged_sources += sources.size()
	return count


## Eixo local da faixa (kit_surface com uv_mode 2): 0 = X, 1 = Z; -1 = não é faixa.
static func _strip_axis(mat: Material) -> int:
	var sm := mat as ShaderMaterial
	if sm == null or sm.get_shader_parameter("uv_mode") == null:
		return -1
	if int(sm.get_shader_parameter("uv_mode")) != 2:
		return -1
	var axis: Variant = sm.get_shader_parameter("strip_axis")
	return 0 if axis == null else int(axis)


static func _descendants(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		out.append(node)
		for child: Node in node.get_children():
			stack.append(child)
	return out


## Acumula os triângulos de um material (sem índice), já no espaço do mapa.
class _Acc extends RefCounted:
	var material: Material = null
	var shadow: GeometryInstance3D.ShadowCastingSetting = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var tangents := PackedFloat32Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var uv2s := PackedVector2Array()
	var has_tangents: bool = true

	func _init(mat: Material, cast: GeometryInstance3D.ShadowCastingSetting) -> void:
		material = mat
		shadow = cast

	func add(arrays: Array, xf: Transform3D, strip_axis: int) -> void:
		var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var n: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var t: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT] if arrays[Mesh.ARRAY_TANGENT] != null else PackedFloat32Array()
		var c: PackedColorArray = arrays[Mesh.ARRAY_COLOR] if arrays[Mesh.ARRAY_COLOR] != null else PackedColorArray()
		var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		if not idx.is_empty():
			v = _expand3(v, idx)
			n = _expand3(n, idx)
			c = _expand_c(c, idx) if not c.is_empty() else c
			uv = _expand2(uv, idx) if not uv.is_empty() else uv
			t = _expand_t(t, idx) if not t.is_empty() else t
		var count: int = v.size()
		var rot := Transform3D(xf.basis.orthonormalized(), Vector3.ZERO)
		verts.append_array(xf * v)
		normals.append_array(rot * n)
		if c.size() == count:
			colors.append_array(c)
		else:
			var white := PackedColorArray()
			white.resize(count)
			white.fill(Color.WHITE)
			colors.append_array(white)
		if uv.size() == count:
			uvs.append_array(uv)
		else:
			var zero := PackedVector2Array()
			zero.resize(count)
			uvs.append_array(zero)
		var axis := Vector2.ZERO
		if strip_axis >= 0:
			var local: Vector3 = Vector3(1.0, 0.0, 0.0) if strip_axis == 0 else Vector3(0.0, 0.0, 1.0)
			var w: Vector3 = xf.basis * local
			axis = Vector2(w.x, w.z)
		var axes := PackedVector2Array()
		axes.resize(count)
		axes.fill(axis)
		uv2s.append_array(axes)
		if t.size() == count * 4:
			for i in count:
				var tv: Vector3 = rot.basis * Vector3(t[i * 4], t[i * 4 + 1], t[i * 4 + 2])
				tangents.append(tv.x)
				tangents.append(tv.y)
				tangents.append(tv.z)
				tangents.append(t[i * 4 + 3])
		else:
			has_tangents = false

	func commit(mesh: ArrayMesh) -> void:
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_COLOR] = colors
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		arrays[Mesh.ARRAY_TEX_UV2] = uv2s
		if has_tangents and tangents.size() == verts.size() * 4:
			arrays[Mesh.ARRAY_TANGENT] = tangents
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(mesh.get_surface_count() - 1, material)

	static func _expand3(a: PackedVector3Array, idx: PackedInt32Array) -> PackedVector3Array:
		var out := PackedVector3Array()
		out.resize(idx.size())
		for i in idx.size():
			out[i] = a[idx[i]]
		return out

	static func _expand2(a: PackedVector2Array, idx: PackedInt32Array) -> PackedVector2Array:
		var out := PackedVector2Array()
		out.resize(idx.size())
		for i in idx.size():
			out[i] = a[idx[i]]
		return out

	static func _expand_c(a: PackedColorArray, idx: PackedInt32Array) -> PackedColorArray:
		var out := PackedColorArray()
		out.resize(idx.size())
		for i in idx.size():
			out[i] = a[idx[i]]
		return out

	static func _expand_t(a: PackedFloat32Array, idx: PackedInt32Array) -> PackedFloat32Array:
		var out := PackedFloat32Array()
		out.resize(idx.size() * 4)
		for i in idx.size():
			for k in 4:
				out[i * 4 + k] = a[idx[i] * 4 + k]
		return out
