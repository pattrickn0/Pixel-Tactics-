class_name SkirtMeshBuilder
extends RefCounted
## Saia de chão além da borda do mapa (só visual, fora do MapData): um anel de grama da
## floresta na altura do chão mais alto da borda, largo o bastante para o alto da tela
## mostrar chão (ou névoa) em qualquer yaw e no zoom máximo. Onde a borda do mapa é mais
## baixa que a saia, um barranco virado para dentro fecha o desnível.

## Largura do anel além da borda do mapa, em unidades.
const SKIRT_WIDTH: float = 48.0


## Nível da saia: o chão mais alto da borda do mapa.
static func skirt_level(data: MapData) -> int:
	var hi: int = data.get_level(Vector2i(0, 0))
	for cx in data.size.x:
		hi = maxi(hi, maxi(data.get_level(Vector2i(cx, 0)), data.get_level(Vector2i(cx, data.size.y - 1))))
	for cz in data.size.y:
		hi = maxi(hi, maxi(data.get_level(Vector2i(0, cz)), data.get_level(Vector2i(data.size.x - 1, cz))))
	return hi


static func skirt_height(data: MapData) -> float:
	return skirt_level(data) * WorldScale.LEVEL_HEIGHT


static func build(data: MapData, art: ArtLibrary) -> ArrayMesh:
	var lh: float = WorldScale.LEVEL_HEIGHT
	var top_level: int = skirt_level(data)
	var y: float = top_level * lh
	var w: float = SKIRT_WIDTH
	var mx: float = float(data.size.x)
	var mz: float = float(data.size.y)
	var top := MeshBatch.new()
	top.add_top_quad(Vector2(-w, -w), Vector2(mx + w, -w), Vector2(mx + w, 0.0), Vector2(-w, 0.0), y)
	top.add_top_quad(Vector2(-w, mz), Vector2(mx + w, mz), Vector2(mx + w, mz + w), Vector2(-w, mz + w), y)
	top.add_top_quad(Vector2(-w, 0.0), Vector2(0.0, 0.0), Vector2(0.0, mz), Vector2(-w, mz), y)
	top.add_top_quad(Vector2(mx, 0.0), Vector2(mx + w, 0.0), Vector2(mx + w, mz), Vector2(mx, mz), y)

	# Barranco na borda, virado para dentro do mapa. Vai do chão mais baixo de fora do
	# terreno (um nível abaixo da borda mais baixa) até a saia: abaixo do topo de cada célula
	# fica escondido, e ele também fecha os chanfros das quinas coladas na borda.
	var bottom_level: int = data.get_border_min_level() - 1
	var side := MeshBatch.new()
	var side_grass := MeshBatch.new()
	for cx in data.size.x:
		var x0: float = float(cx)
		_add_wall(side, side_grass, Vector2(x0, 0.0), Vector2(x0 + 1.0, 0.0), Vector2(0.0, 1.0), bottom_level, top_level)
		_add_wall(side, side_grass, Vector2(x0, mz), Vector2(x0 + 1.0, mz), Vector2(0.0, -1.0), bottom_level, top_level)
	for cz in data.size.y:
		var z0: float = float(cz)
		_add_wall(side, side_grass, Vector2(0.0, z0), Vector2(0.0, z0 + 1.0), Vector2(1.0, 0.0), bottom_level, top_level)
		_add_wall(side, side_grass, Vector2(mx, z0), Vector2(mx, z0 + 1.0), Vector2(-1.0, 0.0), bottom_level, top_level)

	var mesh := ArrayMesh.new()
	top.commit(mesh, art.terrain_material(art.terrain_variant_name("grass_forest", 0)))
	side.commit(mesh, art.terrain_material("step_side"))
	side_grass.commit(mesh, art.terrain_material("step_side_grass"))
	return mesh


## Um quad por nível (faixas de 16 texels, como as laterais do terreno); o de cima com grama.
static func _add_wall(side: MeshBatch, side_grass: MeshBatch, p: Vector2, q: Vector2, normal: Vector2,
		bottom_level: int, top_level: int) -> void:
	var lh: float = WorldScale.LEVEL_HEIGHT
	for l in range(bottom_level, top_level):
		var batch: MeshBatch = side_grass if l == top_level - 1 else side
		batch.add_vertical_quad(p, q, l * lh, (l + 1) * lh, normal, (l + 1) * lh)
