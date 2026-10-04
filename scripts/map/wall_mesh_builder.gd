class_name WallMeshBuilder
extends RefCounted
## Muro baixo da arena: uma caixa por segmento, do lado de fora da borda.
## Faces com wall_face e topo com wall_top, UV em unidades do mundo.


static func build(data: MapData, art: ArtLibrary) -> ArrayMesh:
	var faces := MeshBatch.new()
	var tops := MeshBatch.new()
	var t: float = data.wall_thickness
	var base_y: float = data.arena_base_level * WorldScale.LEVEL_HEIGHT
	for seg: WallSegment in data.wall_segments:
		if seg.is_gap():
			continue
		var o := Vector2(seg.outward)
		var along: Vector2 = (seg.end - seg.start).normalized()
		var step := Vector2i(roundi(along.x), roundi(along.y))
		var s: Vector2 = seg.start
		var e: Vector2 = seg.end
		# Quina convexa: estende o segmento para fechar o canto de fora.
		if not data.is_arena_cell(seg.cell - step):
			s -= along * t
		if not data.is_arena_cell(seg.cell + step):
			e += along * t
		var s_out: Vector2 = s + o * t
		var e_out: Vector2 = e + o * t
		var top_y: float = base_y + seg.height
		tops.add_top_quad(s, e, e_out, s_out, top_y)
		faces.add_vertical_quad(s, e, base_y, top_y, -o, top_y)
		faces.add_vertical_quad(s_out, e_out, base_y, top_y, o, top_y)
		faces.add_vertical_quad(s, s_out, base_y, top_y, -along, top_y)
		faces.add_vertical_quad(e, e_out, base_y, top_y, along, top_y)
	var mesh := ArrayMesh.new()
	faces.commit(mesh, art.terrain_material("wall_face"))
	tops.commit(mesh, art.terrain_material("wall_top"))
	return mesh
