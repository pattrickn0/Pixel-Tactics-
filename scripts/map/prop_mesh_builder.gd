class_name PropMeshBuilder
extends RefCounted
## Constrói os props 3D característicos da imagem de referência (troncos caídos com musgo,
## banco de madeira, caixotes, pilares de canto e cogumelos).
## Texturas utilizadas: bark_0, moss, wood_end, wall_face, wall_top.

static func build(data: MapData, art: ArtLibrary) -> Dictionary:
	var batches: Dictionary = {}
	_add_logs(batches, data)
	_add_bench_and_crates(batches, data)
	_add_corner_pillars(batches, data)
	
	var meshes: Dictionary = {}
	for mat_name: String in batches:
		var batch: MeshBatch = batches[mat_name]
		var mesh := ArrayMesh.new()
		batch.commit(mesh, art.terrain_material(mat_name))
		meshes[mat_name] = mesh
	return meshes


## Adiciona troncos caídos (cilindros low-poly com casca, topo de musgo e anéis nas pontas)
static func _add_logs(batches: Dictionary, data: MapData) -> void:
	# Posições dos troncos fiéis à referência:
	# 1. Terraço direito frontal (Tier 1)
	# 2. Terraço esquerdo frontal (Tier 1)
	# 3. Terraço superior esquerdo (Tier 2)
	# 4. Terraço superior direito (Tier 2)
	var log_defs: Array = [
		{"pos": Vector2(29.2, 26.5), "rot": deg_to_rad(-45.0), "len": 3.0, "rad": 0.32},
		{"pos": Vector2(14.2, 25.5), "rot": deg_to_rad(38.0), "len": 2.6, "rad": 0.30},
		{"pos": Vector2(17.2, 14.5), "rot": deg_to_rad(15.0), "len": 2.8, "rad": 0.32},
		{"pos": Vector2(25.5, 12.5), "rot": deg_to_rad(0.0), "len": 2.4, "rad": 0.30},
	]
	
	for def: Dictionary in log_defs:
		var p2: Vector2 = def["pos"]
		var y: float = data.get_height_at(p2) + 0.18
		var center := Vector3(p2.x, y, p2.y)
		var angle: float = def["rot"]
		var length: float = def["len"]
		var radius: float = def["rad"]
		_build_log(batches, center, angle, length, radius)


static func _build_log(batches: Dictionary, center: Vector3, angle: float, length: float, radius: float) -> void:
	var bark_batch: MeshBatch = _get_batch(batches, "bark_0")
	var moss_batch: MeshBatch = _get_batch(batches, "moss")
	var end_batch: MeshBatch = _get_batch(batches, "wood_end")
	
	var axis := Vector3(cos(angle), 0.0, sin(angle))
	var right := Vector3(-sin(angle), 0.0, cos(angle))
	var up := Vector3.UP
	
	var half_len: float = length * 0.5
	var p_start: Vector3 = center - axis * half_len
	var p_end: Vector3 = center + axis * half_len
	
	var sides: int = 7
	var circle_start: Array[Vector3] = []
	var circle_end: Array[Vector3] = []
	var normals: Array[Vector3] = []
	
	for i in sides:
		var a: float = TAU * float(i) / float(sides)
		var norm: Vector3 = (right * cos(a) + up * sin(a)).normalized()
		normals.append(norm)
		circle_start.append(p_start + norm * radius)
		circle_end.append(p_end + norm * radius)
		
	for i in sides:
		var i_next: int = (i + 1) % sides
		var a0: Vector3 = circle_start[i]
		var a1: Vector3 = circle_start[i_next]
		var b1: Vector3 = circle_end[i_next]
		var b0: Vector3 = circle_end[i]
		
		var avg_norm: Vector3 = (normals[i] + normals[i_next]).normalized()
		# As faces que apontam para cima ganham musgo!
		var use_moss: bool = avg_norm.y > 0.45
		var target_batch: MeshBatch = moss_batch if use_moss else bark_batch
		
		var u0: float = float(i) / float(sides)
		var u1: float = float(i + 1) / float(sides)
		target_batch.add_quad(
			a0, a1, b1, b0,
			avg_norm,
			Vector2(0.0, u0), Vector2(0.0, u1), Vector2(length, u1), Vector2(length, u0)
		)
		
	# Tampas das pontas com os anéis de madeira (wood_end)
	for i in range(1, sides - 1):
		end_batch.add_triangle(
			circle_start[0], circle_start[i + 1], circle_start[i],
			-axis,
			Vector2(circle_start[0].x, circle_start[0].z),
			Vector2(circle_start[i + 1].x, circle_start[i + 1].z),
			Vector2(circle_start[i].x, circle_start[i].z)
		)
		end_batch.add_triangle(
			circle_end[0], circle_end[i], circle_end[i + 1],
			axis,
			Vector2(circle_end[0].x, circle_end[0].z),
			Vector2(circle_end[i].x, circle_end[i].z),
			Vector2(circle_end[i + 1].x, circle_end[i + 1].z)
		)


## Adiciona banco rústico e caixotes de madeira no terraço superior ao fundo
static func _add_bench_and_crates(batches: Dictionary, data: MapData) -> void:
	var bark_batch: MeshBatch = _get_batch(batches, "bark_0")
	var wood_batch: MeshBatch = _get_batch(batches, "wood_end")
	
	# Banco de madeira
	var bench_pos := Vector2(21.0, 12.5)
	var bench_y: float = data.get_height_at(bench_pos)
	_add_box(wood_batch, Vector3(bench_pos.x, bench_y + 0.35, bench_pos.y), Vector3(1.6, 0.12, 0.45))
	# Pernas do banco
	_add_box(bark_batch, Vector3(bench_pos.x - 0.6, bench_y + 0.16, bench_pos.y), Vector3(0.14, 0.32, 0.35))
	_add_box(bark_batch, Vector3(bench_pos.x + 0.6, bench_y + 0.16, bench_pos.y), Vector3(0.14, 0.32, 0.35))
	
	# Caixotes de madeira
	var crate_pos := Vector2(23.0, 12.5)
	var crate_y: float = data.get_height_at(crate_pos)
	_add_box(wood_batch, Vector3(crate_pos.x, crate_y + 0.32, crate_pos.y), Vector3(0.65, 0.65, 0.65))
	_add_box(wood_batch, Vector3(crate_pos.x + 0.65, crate_y + 0.22, crate_pos.y + 0.1), Vector3(0.48, 0.45, 0.48))


## Pilares de canto nas quinas do anfiteatro
static func _add_corner_pillars(batches: Dictionary, data: MapData) -> void:
	var wall_batch: MeshBatch = _get_batch(batches, "wall_face")
	var top_batch: MeshBatch = _get_batch(batches, "wall_top")
	
	var pillar_positions: Array[Vector2] = [
		Vector2(13.5, 30.2), Vector2(17.5, 30.2), # Flanqueando escada SW
		Vector2(30.8, 29.8), # Canto SE
		Vector2(31.2, 14.2), # Canto NE
		Vector2(12.8, 14.2), # Canto NW
	]
	
	for pos: Vector2 in pillar_positions:
		var y: float = data.get_height_at(pos)
		var size := Vector3(0.72, 0.35, 0.72)
		var center := Vector3(pos.x, y + size.y * 0.5, pos.y)
		_add_box_with_batches(wall_batch, top_batch, center, size)


static func _add_box(batch: MeshBatch, center: Vector3, size: Vector3) -> void:
	_add_box_with_batches(batch, batch, center, size)


static func _add_box_with_batches(side_batch: MeshBatch, top_batch: MeshBatch, center: Vector3, size: Vector3) -> void:
	var hx: float = size.x * 0.5
	var hy: float = size.y * 0.5
	var hz: float = size.z * 0.5
	
	var p000 := center + Vector3(-hx, -hy, -hz)
	var p100 := center + Vector3(hx, -hy, -hz)
	var p110 := center + Vector3(hx, hy, -hz)
	var p010 := center + Vector3(-hx, hy, -hz)
	
	var p001 := center + Vector3(-hx, -hy, hz)
	var p101 := center + Vector3(hx, -hy, hz)
	var p111 := center + Vector3(hx, hy, hz)
	var p011 := center + Vector3(-hx, hy, hz)
	
	# Topo (+Y)
	top_batch.add_quad(p010, p110, p111, p011, Vector3.UP, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1))
	# Frente (+Z)
	side_batch.add_quad(p001, p101, p111, p011, Vector3.FORWARD, Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0))
	# Traseira (-Z)
	side_batch.add_quad(p100, p000, p010, p110, Vector3.BACK, Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0))
	# Direita (+X)
	side_batch.add_quad(p101, p100, p110, p111, Vector3.RIGHT, Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0))
	# Esquerda (-X)
	side_batch.add_quad(p000, p001, p011, p010, Vector3.LEFT, Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0))


static func _get_batch(batches: Dictionary, art_name: String) -> MeshBatch:
	if not batches.has(art_name):
		batches[art_name] = MeshBatch.new()
	return batches[art_name]
