extends SceneTree
## Construtor das nuvens volumétricas (spec 013). Rodar da raiz do projeto, depois do comando de validação 1:
##   "$G" --headless --path . --script tools/kit/build_clouds.gd
## Grava, a partir da tabela literal CloudTables (tools/kit/cloud_tables.gd):
## - assets/models/clouds/<massa>.res: o volume-proxy (caixa fechada, desenhada por dentro pelo shader);
## - assets/materials/clouds/cloud_<massa>.tres: o material do cloud_volume.gdshader com a forma da massa;
## - assets/models/clouds/island_shadow_mask.png: a pegada da ilha vista de cima (contorno da ilha e ilhotas das
##   pontes, das tabelas), lida pelas nuvens para a sombra da ilha (decisão 5). A ilha alta (y 6,5) fica de fora:
##   projetada no plano y = 0 a sombra dela cairia no lugar errado (na névoa da cascata).
## Sem sorteio: rodar de novo regrava arquivos idênticos. Não mexe em scenes/map.tscn (isso é do place_decor.gd).

const MODEL_DIR: String = "res://assets/models/clouds/"
const MATERIAL_DIR: String = "res://assets/materials/clouds/"
const SHADER_PATH: String = "res://assets/materials/cloud_volume.gdshader"
const MASK_PATH: String = "res://assets/models/clouds/island_shadow_mask.png"
## Retângulo da máscara no mundo (x0, z0, x1, z1); o mesmo valor está em project.godot (island_shadow_rect).
const MASK_RECT: Rect2 = Rect2(-64.0, -96.0, 128.0, 128.0)
const MASK_SIZE: int = 512
## Superamostragem da borda da pegada (borda macia de 1 px).
const MASK_SUB: int = 4
const MAX_LOBES: int = 32


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MODEL_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MATERIAL_DIR))
	var shader := load(SHADER_PATH) as Shader
	if shader == null:
		push_error("Shader das nuvens inexistente: " + SHADER_PATH)
		quit(1)
		return
	var count: int = 0
	for mass: Dictionary in CloudTables.MASSES:
		var mass_name: String = str(mass["name"])
		if mass.get("lobes", []).size() > MAX_LOBES:
			push_error("%s: mais de %d lóbulos" % [mass_name, MAX_LOBES])
			quit(1)
			return
		var box: AABB = mass["proxy"]
		var mesh_err: Error = save_stable(proxy_mesh(box), MODEL_DIR + mass_name + ".res")
		var mat_err: Error = save_stable(make_material(shader, mass), MATERIAL_DIR + "cloud_" + mass_name + ".tres")
		if mesh_err != OK or mat_err != OK:
			push_error("Falha ao gravar a massa %s (%d, %d)" % [mass_name, mesh_err, mat_err])
			quit(1)
			return
		count += 1
	var mask: Image = island_mask()
	var err: Error = mask.save_png(ProjectSettings.globalize_path(MASK_PATH))
	print("Nuvens: %d massas (proxy + material) e a máscara da sombra da ilha %dx%d (erro %d)" % [count, MASK_SIZE, MASK_SIZE, err])
	quit(0 if err == OK else 1)


## Grava com identificadores fixos: o Godot sorteia o id da malha principal (.res) e o do shader externo (.tres) a
## cada gravação. Fixando os dois, duas gerações dão o mesmo arquivo (md5).
static func save_stable(res: Resource, path: String) -> Error:
	res.resource_scene_unique_id = "main"
	var mat := res as ShaderMaterial
	if mat != null and mat.shader != null:
		mat.shader.set_id_for_path(ProjectSettings.localize_path(path), "1_shader")
	return ResourceSaver.save(res, path)


## Caixa fechada com as faces para fora (o shader desenha as de trás: cull_front).
static func proxy_mesh(box: AABB) -> ArrayMesh:
	var lo: Vector3 = box.position
	var hi: Vector3 = box.end
	var c: Array[Vector3] = []
	for k in 8:
		c.append(Vector3(hi.x if k & 1 else lo.x, hi.y if k & 2 else lo.y, hi.z if k & 4 else lo.z))
	# Faces: [cantos em ordem horária vista de fora, normal].
	var faces: Array = [
		[[1, 3, 7, 5], Vector3.RIGHT], [[4, 6, 2, 0], Vector3.LEFT], [[2, 6, 7, 3], Vector3.UP],
		[[0, 1, 5, 4], Vector3.DOWN], [[5, 7, 6, 4], Vector3.BACK], [[0, 2, 3, 1], Vector3.FORWARD],
	]
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	for f: Array in faces:
		var q: Array = f[0]
		for idx: int in [0, 1, 2, 0, 2, 3]:
			verts.append(c[int(q[idx])])
			normals.append(f[1])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Material da massa: forma da tabela + parâmetros extras ("params") da linha.
static func make_material(shader: Shader, mass: Dictionary) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.render_priority = int(mass.get("priority", 0))
	var lobes := PackedVector4Array()
	var axes := PackedVector3Array()
	var top: float = -1e9
	for l: Array in mass.get("lobes", []):
		lobes.append(Vector4(float(l[0]), float(l[1]), float(l[2]), float(l[3])))
		var ax := Vector3(float(l[4]), float(l[5]), float(l[6])) if l.size() >= 7 else Vector3.ONE
		axes.append(ax)
		top = maxf(top, float(l[1]) + float(l[3]) * ax.y)
	var count: int = lobes.size()
	while lobes.size() < MAX_LOBES:
		lobes.append(Vector4.ZERO)
		axes.append(Vector3.ONE)
	mat.set_shader_parameter("lobes", lobes)
	mat.set_shader_parameter("lobe_axes", axes)
	mat.set_shader_parameter("lobe_count", count)
	var box: AABB = mass["proxy"]
	mat.set_shader_parameter("proxy_min", box.position)
	mat.set_shader_parameter("proxy_max", box.end)
	if mass.has("layer"):
		var layer: Array = mass["layer"]
		mat.set_shader_parameter("layer_mode", true)
		mat.set_shader_parameter("layer_top", float(layer[0]))
		mat.set_shader_parameter("layer_amp", float(layer[1]))
		mat.set_shader_parameter("layer_cell", float(layer[2]))
		top = float(layer[0]) + float(layer[1])
	mat.set_shader_parameter("top_height", float(mass.get("top", top)))
	mat.set_shader_parameter("base_height", float(mass.get("base", -6.0)))
	var keys: Dictionary = {"base_soft": "base_softness", "edge": "edge_softness", "noise_scale": "noise_scale",
			"noise": "noise_strength", "density": "density", "blend": "blend_k"}
	for key: String in keys.keys():
		if mass.has(key):
			mat.set_shader_parameter(keys[key], float(mass[key]))
	# Deslocamento fixo do ruído por massa (massas vizinhas não repetem o mesmo desenho).
	var p: Vector3 = mass["pos"]
	mat.set_shader_parameter("noise_offset", Vector3(fposmod(p.x * 0.37, 50.0), fposmod(p.y * 0.21, 50.0), fposmod(p.z * 0.29, 50.0)))
	var params: Dictionary = mass.get("params", {})
	var names: Array = params.keys()
	names.sort()
	for param: String in names:
		mat.set_shader_parameter(param, params[param])
	return mat


## Pegada (1 = ilha) vista de cima no plano y = 0: ilha principal e ilhotas das pontes (perto de y = 0).
static func island_mask() -> Image:
	var polys: Array[PackedVector2Array] = [IslandTables.ISLAND_OUTLINE]
	for item: Array in MapDecorTable.ITEMS:
		var piece: String = str(item[1])
		var data: Dictionary = {}
		if piece == "islet_w":
			data = IslandTables.ISLET_W
		elif piece == "islet_e":
			data = IslandTables.ISLET_E
		else:
			continue
		var moved := PackedVector2Array()
		for v: Vector2 in data["top"]:
			moved.append(v + Vector2(float(item[2]), float(item[4])))
		polys.append(moved)
	var boxes: Array[Rect2] = []
	for poly: PackedVector2Array in polys:
		var r := Rect2(poly[0], Vector2.ZERO)
		for v: Vector2 in poly:
			r = r.expand(v)
		boxes.append(r.grow(0.5))
	var img := Image.create(MASK_SIZE, MASK_SIZE, false, Image.FORMAT_L8)
	var texel: Vector2 = MASK_RECT.size / float(MASK_SIZE)
	for y in MASK_SIZE:
		for x in MASK_SIZE:
			var hits: int = 0
			var cell := Rect2(MASK_RECT.position + Vector2(float(x), float(y)) * texel, texel)
			for k in polys.size():
				if not boxes[k].intersects(cell):
					continue
				for sy in MASK_SUB:
					for sx in MASK_SUB:
						var p := cell.position + Vector2((float(sx) + 0.5) / MASK_SUB * texel.x, (float(sy) + 0.5) / MASK_SUB * texel.y)
						if Geometry2D.is_point_in_polygon(p, polys[k]):
							hits += 1
			var v: float = minf(float(hits) / float(MASK_SUB * MASK_SUB), 1.0)
			img.set_pixel(x, y, Color(v, v, v))
	return img
