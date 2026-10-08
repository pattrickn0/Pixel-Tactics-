class_name SceneryPieces
extends RefCounted
## Construtores das peças do cenário pintado (spec 012, Fase 1): ilha (topo, penhasco em blocos, fundo
## cônico, raízes e cipós), árvores pintadas (lóbulos de cartões e andares de cartões), estruturas
## (patamares, lajes, pontes de corda, braseiros) e o que fica fora da ilha (ilha alta, cascata, arco-íris,
## ilhotas, ruínas, rochas e nuvens). Tudo sai das tabelas literais de IslandTables e KitTables: nada é
## sorteado. Materiais provisórios (KitMaterialDefs.scenery) até a arte da A08.

const T: float = KitMesher.TEXEL
## Direções dos cartões de cada lóbulo (copa) e o giro de cada cartão no próprio plano. Revisão 012-f2: 5 cartões
## grandes por lóbulo (meia largura CARD_HALF x raio), em vez de 9 pequenos (que liam como couve-flor).
const CARD_DIRS: Array[Vector3] = [
	Vector3(0.0, 1.0, 0.0), Vector3(0.82, 0.38, 0.42), Vector3(-0.78, 0.32, 0.55), Vector3(0.4, 0.3, -0.87),
	Vector3(-0.6, 0.42, -0.7),
]
const CARD_TURNS: Array[float] = [0.0, 61.0, 122.0, 203.0, 284.0]
const CARD_HALF: float = 1.05
## Família de folha da tabela -> material provisório.
const FAMILY_KEYS: Dictionary = {"green": "foliage_mid", "olive": "foliage_warm", "cool": "foliage_cool"}
## Tipos de cartão (canal b da cor do vértice, lido por scenery_foliage).
const CARD_CLUMP: float = 0.0
const CARD_TIER: float = 0.5
const CARD_SOLID: float = 1.0
## Retângulo do muro externo: o topo da ilha é o contorno menos ele.
const RING_RECT: Rect2 = Rect2(-14.0, -13.0, 28.0, 26.0)


## Peças novas do kit (entram em KitTables.catalog()). Campos como os de KitTables._e; "light" =
## [altura, alcance, energia] de um OmniLight3D sem sombra; "no_shadow" = não projeta sombra.
static func catalog() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	out.append(_e("island_top", "island_top", Vector3(62, 0, 44), {"no_shadow": true}))
	out.append(_e("island_cliff", "island_cliff", Vector3(62, 3.5, 44), {}))
	out.append(_e("island_under", "island_under", Vector3(56, 17, 40), {"no_shadow": true}))
	for i in IslandTables.ROOTS.size():
		out.append(_e("root_hang_%s" % "abc"[i], "root", Vector3(1.5, 5.5, 1.5), {"variant": i}))
	for i in IslandTables.SURFACE_ROOTS.size():
		out.append(_e("root_surface_%s" % "abc"[i], "root_surface", Vector3(2.6, 0.4, 3.9), {"variant": i}))
	for i in IslandTables.VINES.size():
		out.append(_e("vine_hang_%s" % "ab"[i], "vine", Vector3(0.8, 3.5, 0.8), {"variant": i, "no_shadow": true}))
	out.append(_e("island_high", "mass", Vector3(37, 30, 17), {"mass": "HIGH_ISLAND", "no_shadow": true}))
	out.append(_e("high_spur", "mass", Vector3(6, 16, 4), {"mass": "HIGH_SPUR", "no_shadow": true}))
	out.append(_e("high_block", "mass", Vector3(4, 12, 3), {"mass": "HIGH_BLOCK", "no_shadow": true}))
	out.append(_e("waterfall", "waterfall", Vector3(24, 21, 10), {"no_shadow": true}))
	out.append(_e("rainbow", "rainbow", Vector3(18, 12, 0.1), {"no_shadow": true}))
	out.append(_e("islet_ruins", "mass", Vector3(18, 11, 18), {"mass": "ISLET_RUINS", "no_shadow": true, "drums": true}))
	out.append(_e("islet_ne", "mass", Vector3(7, 7, 7), {"mass": "ISLET_NE", "no_shadow": true}))
	out.append(_e("islet_w", "mass", Vector3(7, 8, 7), {"mass": "ISLET_W"}))
	out.append(_e("islet_e", "mass", Vector3(6, 7, 6), {"mass": "ISLET_E"}))
	out.append(_e("rock_float_a", "mass", Vector3(1, 1.3, 1), {"mass": "ROCK_FLOAT_A", "rock": true, "no_shadow": true}))
	out.append(_e("rock_float_b", "mass", Vector3(1, 1.6, 1), {"mass": "ROCK_FLOAT_B", "rock": true, "no_shadow": true}))
	out.append(_e("rock_float_c", "mass", Vector3(1, 1.1, 1), {"mass": "ROCK_FLOAT_C", "rock": true, "no_shadow": true}))
	out.append(_e("rock_big", "mass", Vector3(8, 9.5, 8), {"mass": "ROCK_BIG", "rock": true, "vines": true, "no_shadow": true}))
	for name_i in ["a", "b", "c"]:
		out.append(_e("ruin_column_" + name_i, "column", Vector3(1.0, [3.4, 2.1, 0.9]["abc".find(name_i)], 1.0), {"variant": "abc".find(name_i)}))
	out.append(_e("ruin_lintel", "lintel", Vector3(4.4, 0.55, 0.8), {}))
	for i in IslandTables.CLOUDS.size():
		out.append(_e("cloud_%s" % "abcde"[i], "cloud", Vector3(14, 4, 6), {"variant": i, "no_shadow": true, "cull_margin": 4.0}))
	# Névoa da base da cascata (puffs de fx/mist_puff, com o desenho do aglomerado d) e o mar de nuvens embaixo.
	out.append(_e("mist_a", "cloud", Vector3(6, 3, 3), {"variant": 3, "material": "mist_puff", "no_shadow": true, "cull_margin": 3.0}))
	out.append(_e("cloud_sea", "cloud_sea", Vector3(400, 0, 400), {"no_shadow": true}))
	out.append(_e("brazier_a", "brazier", Vector3(0.5, 1.5, 0.5), {"obstacle": true, "light": [1.25, 3.5, 0.9]}))
	out.append(_e("bridge_rope_w", "bridge", Vector3(4.9, 2.2, 1.7), {"variant": 0}))
	out.append(_e("bridge_rope_e", "bridge", Vector3(3.6, 2.5, 1.7), {"variant": 1}))
	out.append(_e("landing_south", "slabs_area", Vector3(5, 0.06, 3.5), {"variant": 0}))
	out.append(_e("landing_north", "slabs_area", Vector3(4, 0.06, 1.5), {"variant": 1}))
	out.append(_e("platform_w", "slabs_area", Vector3(4, 0.06, 5.5), {"variant": 2}))
	out.append(_e("path_ne", "path", Vector3(10, 0.06, 21), {}))
	out.append(_e("pillar_stone", "pillar", Vector3(0.6, 1.1, 0.6), {"obstacle": true}))
	out.append(_e("arena_ground", "arena_ground", Vector3(20, 0, 18), {"no_shadow": true}))
	out.append(_e("arena_slabs", "arena_slabs", Vector3(12, 0.04, 9), {"no_shadow": true}))
	return out


static func _e(entry_name: String, build: String, size: Vector3, extra: Dictionary) -> Dictionary:
	var entry: Dictionary = extra.duplicate()
	entry["name"] = entry_name
	entry["build"] = build
	entry["size"] = size
	return entry


## Monta a peça; devolve false se o construtor não é deste arquivo.
static func build(m: KitMesher, entry: Dictionary) -> bool:
	var s: Vector3 = entry["size"]
	var v: int = int(entry.get("variant", 0))
	match str(entry["build"]):
		"broad":
			painted_broad(m, v)
		"conifer":
			painted_conifer(m, v)
		"bush":
			painted_bush(m, v)
		"island_top":
			island_top(m)
		"island_cliff":
			island_cliff(m)
		"island_under":
			island_under(m)
		"root":
			var rc: Array = ROOT_CARDS[v]
			hang_cards(m, "roots_cards", float(rc[0]), float(rc[1]), int(rc[2]), int(rc[3]))
		"root_surface":
			_root_chains(m, IslandTables.SURFACE_ROOTS[v])
		"vine":
			var vc: Array = VINE_CARDS[v]
			hang_cards(m, "vines_cards", float(vc[0]), float(vc[1]), int(vc[2]), int(vc[3]))
		"mass":
			var data: Dictionary = mass_table(str(entry["mass"]))
			var rock: bool = bool(entry.get("rock", false))
			rock_mass(m, data, "grass_painted", "rock_painted" if rock else "cliff_painted", "rock_painted" if rock else "under_painted")
			if bool(entry.get("drums", false)):
				ruin_drums(m)
			if bool(entry.get("vines", false)):
				rock_vines(m)
		"waterfall":
			waterfall(m)
		"rainbow":
			rainbow(m)
		"column":
			column(m, v)
		"lintel":
			m.box("ruin_stone_box", "ruin_stone_box", Vector3(-s.x * 0.5, 0.0, -s.z * 0.5), Vector3(s.x * 0.5, s.y, s.z * 0.5))
		"cloud":
			cloud(m, IslandTables.CLOUDS[v], str(entry.get("material", "cloud_puff")))
		"cloud_sea":
			var hs: float = s.x * 0.5
			m.quad("cloud_sea", Vector3(-hs, 0.0, -hs), Vector3(hs, 0.0, -hs), Vector3(hs, 0.0, hs), Vector3(-hs, 0.0, hs), Vector3.UP)
		"brazier":
			brazier(m)
		"bridge":
			bridge(m, IslandTables.BRIDGE_W if v == 0 else IslandTables.BRIDGE_E)
		"slabs_area":
			slabs_area(m, v)
		"path":
			path(m, IslandTables.PATH_NE, IslandTables.PATH_NE_WIDTH)
		"pillar":
			pillar(m)
		"arena_ground":
			m.quad("arena_ground", Vector3(-10.0, 0.0, -9.0), Vector3(10.0, 0.0, -9.0), Vector3(10.0, 0.0, 9.0), Vector3(-10.0, 0.0, 9.0),
					Vector3.UP, Vector2(-10.0, -9.0), Vector2(10.0, -9.0), Vector2(10.0, 9.0), Vector2(-10.0, 9.0))
		"arena_slabs":
			arena_slabs(m)
		_:
			return false
	m.color = Color.WHITE
	m.gradient = Vector2.ZERO
	m.xf = Transform3D.IDENTITY
	return true


## Tabela de massa de rocha pelo nome.
static func mass_table(mass_name: String) -> Dictionary:
	match mass_name:
		"HIGH_ISLAND":
			return IslandTables.HIGH_ISLAND
		"HIGH_SPUR":
			return IslandTables.HIGH_SPUR
		"HIGH_BLOCK":
			return IslandTables.HIGH_BLOCK
		"ISLET_RUINS":
			return IslandTables.ISLET_RUINS
		"ISLET_NE":
			return IslandTables.ISLET_NE
		"ISLET_W":
			return IslandTables.ISLET_W
		"ISLET_E":
			return IslandTables.ISLET_E
		"ROCK_FLOAT_A":
			return IslandTables.ROCK_FLOAT_A
		"ROCK_FLOAT_B":
			return IslandTables.ROCK_FLOAT_B
		"ROCK_FLOAT_C":
			return IslandTables.ROCK_FLOAT_C
		"ROCK_BIG":
			return IslandTables.ROCK_BIG
	push_error("Massa de rocha desconhecida: " + mass_name)
	return {}


# ================================================================ geometria comum

## Área com sinal do polígono (x, z): positiva = anti-horária no plano (x, z).
static func _area(pts: PackedVector2Array) -> float:
	var a: float = 0.0
	for i in pts.size():
		var p: Vector2 = pts[i]
		var q: Vector2 = pts[(i + 1) % pts.size()]
		a += p.x * q.y - q.x * p.y
	return a * 0.5


## Normal para dentro da aresta a -> b (sinal pela orientação do polígono).
static func _inward(a: Vector2, b: Vector2, orient: float) -> Vector2:
	var e: Vector2 = (b - a).normalized()
	var n := Vector2(-e.y, e.x)
	return n if orient > 0.0 else -n


## Contorno recuado para dentro: cada vértice anda `amounts[i]` pela bissetriz.
static func _offset_ring(pts: PackedVector2Array, amounts: PackedFloat32Array) -> PackedVector2Array:
	var orient: float = _area(pts)
	var out := PackedVector2Array()
	var n: int = pts.size()
	for i in n:
		var prev: Vector2 = pts[(i - 1 + n) % n]
		var cur: Vector2 = pts[i]
		var nxt: Vector2 = pts[(i + 1) % n]
		var n0: Vector2 = _inward(prev, cur, orient)
		var n1: Vector2 = _inward(cur, nxt, orient)
		var bis: Vector2 = (n0 + n1).normalized()
		if bis == Vector2.ZERO:
			bis = n1
		var k: float = 1.0 / maxf(bis.dot(n1), 0.5)
		out.append(cur + bis * amounts[i] * k)
	return out


## Polígono plano virado para cima (triangulado pelo Geometry2D), UV no mundo.
static func _poly_top(m: KitMesher, key: String, pts: PackedVector2Array, y: float) -> void:
	var idx: PackedInt32Array = Geometry2D.triangulate_polygon(pts)
	for i in range(0, idx.size(), 3):
		var a: Vector2 = pts[idx[i]]
		var b: Vector2 = pts[idx[i + 1]]
		var c: Vector2 = pts[idx[i + 2]]
		m.tri_flat(key, Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), Vector3(c.x, y, c.y), Vector3.UP, a, b, c)


## Faces verticais de um anel (de y_top a y_bot), normal para fora de cada aresta.
static func _ring_faces(m: KitMesher, key: String, ring: PackedVector2Array, y_top: float, y_bot: float) -> void:
	var orient: float = _area(ring)
	var n: int = ring.size()
	for i in n:
		var a: Vector2 = ring[i]
		var b: Vector2 = ring[(i + 1) % n]
		if a.distance_to(b) < 0.001:
			continue
		var out: Vector2 = -_inward(a, b, orient)
		m.quad(key, Vector3(a.x, y_top, a.y), Vector3(b.x, y_top, b.y), Vector3(b.x, y_bot, b.y), Vector3(a.x, y_bot, a.y),
				Vector3(out.x, 0.0, out.y), Vector2(a.x + a.y, y_top), Vector2(b.x + b.y, y_top), Vector2(b.x + b.y, y_bot), Vector2(a.x + a.y, y_bot))


## Degrau horizontal entre dois anéis do mesmo número de pontos, na altura y (visível de cima e de baixo).
static func _ring_ledge(m: KitMesher, key: String, upper: PackedVector2Array, lower: PackedVector2Array, y: float) -> void:
	var n: int = upper.size()
	for i in n:
		var a: Vector2 = upper[i]
		var b: Vector2 = upper[(i + 1) % n]
		var c: Vector2 = lower[(i + 1) % n]
		var d: Vector2 = lower[i]
		if a.distance_to(d) < 0.01 and b.distance_to(c) < 0.01:
			continue
		var pa := Vector3(a.x, y, a.y)
		var pb := Vector3(b.x, y, b.y)
		var pc := Vector3(c.x, y, c.y)
		var pd := Vector3(d.x, y, d.y)
		m.quad(key, pa, pb, pc, pd, Vector3.UP)
		m.quad(key, pa, pb, pc, pd, Vector3.DOWN)


## Anéis ordenados pelo ângulo em volta do centro: costura de triângulos entre dois anéis (qualquer número
## de pontos) e, no fim, o leque até o ápice.
static func _cone(m: KitMesher, key: String, first: PackedVector2Array, first_y: float, rings: Array, apex: Vector3) -> void:
	var prev: PackedVector2Array = first
	var prev_y: float = first_y
	for ring_entry: Array in rings:
		var ring := PackedVector2Array(ring_entry[1])
		var y: float = float(ring_entry[0])
		_stitch(m, key, prev, prev_y, ring, y)
		prev = ring
		prev_y = y
	var center: Vector2 = _centroid(prev)
	for i in prev.size():
		var a: Vector2 = prev[i]
		var b: Vector2 = prev[(i + 1) % prev.size()]
		_cone_tri(m, key, Vector3(a.x, prev_y, a.y), Vector3(b.x, prev_y, b.y), apex, Vector3(center.x, (prev_y + apex.y) * 0.5, center.y))


static func _centroid(pts: PackedVector2Array) -> Vector2:
	var c := Vector2.ZERO
	for p: Vector2 in pts:
		c += p
	return c / float(maxi(pts.size(), 1))


## Pontos do anel em ordem de ângulo crescente em volta de `center`, a partir do menor ângulo.
static func _angle_sorted(pts: PackedVector2Array, center: Vector2) -> Array:
	var list: Array = []
	for p: Vector2 in pts:
		list.append([wrapf((p - center).angle(), 0.0, TAU), p])
	list.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	return list


static func _stitch(m: KitMesher, key: String, upper: PackedVector2Array, y_up: float, lower: PackedVector2Array, y_lo: float) -> void:
	var center: Vector2 = _centroid(lower)
	var a: Array = _angle_sorted(upper, center)
	var b: Array = _angle_sorted(lower, center)
	var na: int = a.size()
	var nb: int = b.size()
	var ia: int = 0
	var ib: int = 0
	var axis := Vector3(center.x, (y_up + y_lo) * 0.5, center.y)
	while ia < na or ib < nb:
		var pa: Vector2 = a[ia % na][1]
		var pb: Vector2 = b[ib % nb][1]
		var next_a: float = float(a[(ia + 1) % na][0]) + (TAU if ia + 1 >= na else 0.0)
		var next_b: float = float(b[(ib + 1) % nb][0]) + (TAU if ib + 1 >= nb else 0.0)
		var advance_a: bool = ib >= nb or (ia < na and next_a <= next_b)
		if advance_a:
			var pa2: Vector2 = a[(ia + 1) % na][1]
			_cone_tri(m, key, Vector3(pa.x, y_up, pa.y), Vector3(pa2.x, y_up, pa2.y), Vector3(pb.x, y_lo, pb.y), axis)
			ia += 1
		else:
			var pb2: Vector2 = b[(ib + 1) % nb][1]
			_cone_tri(m, key, Vector3(pa.x, y_up, pa.y), Vector3(pb2.x, y_lo, pb2.y), Vector3(pb.x, y_lo, pb.y), axis)
			ib += 1


## Triângulo do fundo com a normal virada para longe do eixo (e para baixo).
static func _cone_tri(m: KitMesher, key: String, a: Vector3, b: Vector3, c: Vector3, axis: Vector3) -> void:
	var n: Vector3 = (b - a).cross(c - a)
	if n.length() < 0.000001:
		return
	n = n.normalized()
	var mid: Vector3 = (a + b + c) / 3.0
	var out := Vector3(mid.x - axis.x, -0.6, mid.z - axis.z)
	if n.dot(out) < 0.0:
		n = -n
	m.tri_flat(key, a, b, c, n)


## Massa de rocha (ilha alta, ilhotas, rochas): topo de grama, faixas em blocos, fundo cônico.
static func rock_mass(m: KitMesher, data: Dictionary, top_key: String, cliff_key: String, under_key: String) -> void:
	var top := PackedVector2Array(data["top"])
	var ty: float = float(data["top_y"])
	_poly_top(m, top_key, top, ty)
	var jog: Array = data["jog"]
	var prev: PackedVector2Array = top
	var bottom: float = ty
	var band_index: int = 0
	for band: Array in data["bands"]:
		var amounts := PackedFloat32Array()
		var base: float = float(band[2])
		for i in top.size():
			amounts.append(0.0 if base <= 0.0 else maxf(base + float(jog[(i + band_index) % jog.size()]), 0.05))
		var ring: PackedVector2Array = _offset_ring(top, amounts)
		if band_index > 0:
			_ring_ledge(m, cliff_key, prev, ring, ty + float(band[0]))
		_ring_faces(m, cliff_key, ring, ty + float(band[0]), ty + float(band[1]))
		prev = ring
		bottom = ty + float(band[1])
		band_index += 1
	var rings: Array = []
	for ring_entry: Array in data["rings"]:
		rings.append([ty + float(ring_entry[0]), ring_entry[1]])
	var apex: Vector3 = data["apex"]
	_cone(m, under_key, prev, bottom, rings, Vector3(apex.x, ty + apex.y, apex.z))


# ================================================================ ilha principal

## Topo da ilha: o contorno menos o retângulo do muro, em células de 1 x 1 (a grade leva o AO do pé do
## muro externo na cor do vértice, spec 012 Fase 2).
const ISLAND_AO_WIDTH: float = 1.6
const ISLAND_AO_MIN: float = 0.62


static func island_top(m: KitMesher) -> void:
	var r: Rect2 = RING_RECT
	var ring_poly: PackedVector2Array = _rect_poly(r)
	var outline: PackedVector2Array = IslandTables.ISLAND_OUTLINE
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p: Vector2 in outline:
		lo = lo.min(p)
		hi = hi.max(p)
	m.ao_rect = r
	m.ao_width = ISLAND_AO_WIDTH
	m.ao_min = ISLAND_AO_MIN
	m.ao_inside = false
	for gz in range(floori(lo.y), ceili(hi.y)):
		for gx in range(floori(lo.x), ceili(hi.x)):
			var cell: PackedVector2Array = _rect_poly(Rect2(float(gx), float(gz), 1.0, 1.0))
			if r.encloses(Rect2(float(gx), float(gz), 1.0, 1.0)):
				continue
			for piece: PackedVector2Array in Geometry2D.intersect_polygons(cell, outline):
				for part: PackedVector2Array in Geometry2D.clip_polygons(piece, ring_poly):
					_poly_top(m, "grass_painted", part, 0.0)
	m.ao_width = 0.0


## Chão da arena (20 x 18) em células de 0,5: AO pela cor do vértice perto da borda (pé dos degraus).
const ARENA_AO_WIDTH: float = 0.9
const ARENA_AO_MIN: float = 0.74


static func arena_ground_grid(m: KitMesher, key: String, s: Vector3) -> void:
	var hx: float = s.x * 0.5
	var hz: float = s.z * 0.5
	m.ao_rect = Rect2(-hx, -hz, s.x, s.z)
	m.ao_width = ARENA_AO_WIDTH
	m.ao_min = ARENA_AO_MIN
	m.ao_inside = true
	var step: float = 0.5
	var nx: int = roundi(s.x / step)
	var nz: int = roundi(s.z / step)
	for iz in nz:
		for ix in nx:
			var x0: float = -hx + step * float(ix)
			var z0: float = -hz + step * float(iz)
			m.top(key, x0, z0, x0 + step, z0 + step, 0.0, z0, z0 + step)
	m.ao_width = 0.0


static func _rect_poly(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])


## Penhasco em blocos: cada faixa é o contorno recuado (CLIFF_INSETS) e entre as faixas fica o degrau.
static func island_cliff(m: KitMesher) -> void:
	var outline: PackedVector2Array = IslandTables.ISLAND_OUTLINE
	var prev := PackedVector2Array()
	for b in IslandTables.CLIFF_BANDS.size():
		var band: Array = IslandTables.CLIFF_BANDS[b]
		var ring: PackedVector2Array = _offset_ring(outline, _cliff_amounts(b))
		if b > 0:
			_ring_ledge(m, "cliff_painted", prev, ring, float(band[0]))
		_ring_faces(m, "cliff_painted", ring, float(band[0]), float(band[1]))
		prev = ring


static func _cliff_amounts(band: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for v: Vector4 in IslandTables.CLIFF_INSETS:
		out.append([v.x, v.y, v.z, v.w][band])
	return out


## Fundo cônico da ilha (da última faixa do penhasco até o ápice) e os esporões.
static func island_under(m: KitMesher) -> void:
	var last: int = IslandTables.CLIFF_BANDS.size() - 1
	var ring: PackedVector2Array = _offset_ring(IslandTables.ISLAND_OUTLINE, _cliff_amounts(last))
	var y0: float = float(IslandTables.CLIFF_BANDS[last][1])
	_cone(m, "under_painted", ring, y0, IslandTables.UNDER_RINGS, IslandTables.UNDER_APEX)
	for spur: Array in IslandTables.UNDER_SPURS:
		var c: Vector3 = spur[0]
		var r: float = float(spur[1])
		var tip: Vector3 = spur[2]
		var pts := PackedVector2Array()
		for k in 6:
			var ang: float = TAU * float(k) / 6.0 + 0.4 * float(k % 2)
			var rr: float = r * (1.0 if k % 2 == 0 else 0.78)
			pts.append(Vector2(c.x + cos(ang) * rr, c.z + sin(ang) * rr))
		_cone(m, "under_painted", pts, c.y, [], tip)


## Raiz (pendente ou de superfície): cadeias de tubos que afinam (pivô na borda ou no pé do muro, +Z para fora).
static func _root_chains(m: KitMesher, chains: Array) -> void:
	for chain: Array in chains:
		for i in range(chain.size() - 1):
			var a: Vector4 = chain[i]
			var b: Vector4 = chain[i + 1]
			m.tube("bark_root", "bark_root", Vector3(a.x, a.y, a.z), Vector3(b.x, b.y, b.z), a.w, b.w, 6, i == 0, true)


## Raízes pendentes e cipós (arte A08 leva 2: island/roots_hang e island/vines_hang, 4 faixas verticais de
## 128 x 1024, v = 0 preso na borda): [comprimento, largura, faixa do cartão da frente, faixa do cartão cruzado].
const ROOT_CARDS: Array = [[5.0, 0.8, 0, 3], [5.8, 0.9, 1, 2], [3.6, 0.65, 2, 0]]
const VINE_CARDS: Array = [[3.3, 0.48, 0, 2], [2.3, 0.42, 1, 3]]


## Dois cartões cruzados pendurados do pivô (topo da borda, +Z para fora): o da frente paralelo à face e o
## outro girado 58°, para não sumir de lado. Canal r da cor = altura (gradiente), normal para fora e um pouco
## para cima.
static func hang_cards(m: KitMesher, key: String, length: float, width: float, strip: int, alt_strip: int) -> void:
	m.gradient = Vector2(-length, 0.1)
	m.color = Color(0.0, 1.0, CARD_CLUMP, 0.3)
	for k in 2:
		var ang: float = deg_to_rad(0.0 if k == 0 else 58.0)
		var t := Vector3(cos(ang), 0.0, -sin(ang))
		var n := Vector3(sin(ang), 0.3, cos(ang)).normalized()
		var c := Vector3(0.0, 0.0, 0.14)
		var hw: float = width * 0.5
		var id: float = float(strip if k == 0 else alt_strip)
		var top := Vector3(0.0, 0.1, 0.0)
		var bot := Vector3(0.0, -length, 0.0)
		m.tri(key, c + top - t * hw, c + top + t * hw, c + bot + t * hw, n, n, n, Vector2(0.0, id), Vector2(1.0, id), Vector2(1.0, id + 0.999))
		m.tri(key, c + top - t * hw, c + bot + t * hw, c + bot - t * hw, n, n, n, Vector2(0.0, id), Vector2(1.0, id + 0.999), Vector2(0.0, id + 0.999))
	m.gradient = Vector2.ZERO
	m.color = Color.WHITE


## Cartão quadrado centrado em c (eixos t e b, meio lado h); UV = (u, v + número do cartão).
static func _card(m: KitMesher, key: String, c: Vector3, t: Vector3, b: Vector3, h: float, n: Vector3, card_id: int) -> void:
	var id: float = float(card_id)
	var p0: Vector3 = c - t * h + b * h
	var p1: Vector3 = c + t * h + b * h
	var p2: Vector3 = c + t * h - b * h
	var p3: Vector3 = c - t * h - b * h
	m.tri(key, p0, p1, p2, n, n, n, Vector2(0.0, id), Vector2(1.0, id), Vector2(1.0, id + 0.999))
	m.tri(key, p0, p2, p3, n, n, n, Vector2(0.0, id), Vector2(1.0, id + 0.999), Vector2(0.0, id + 0.999))


# ================================================================ árvores pintadas (provisórias)

## Folhosa: tronco, raízes e galhos da tabela; copa de lóbulos = miolo maciço + 9 cartões de tufo.
static func painted_broad(m: KitMesher, variant: int) -> void:
	var t: Dictionary = KitTables.BROAD[variant]
	var sc: float = float(KitTables.BROAD_SCALE[variant])
	var key: String = FAMILY_KEYS[str(t["family"])]
	m.xf = Transform3D(Basis.IDENTITY.scaled(Vector3(sc, sc, sc)), Vector3.ZERO)
	var trunk: Array = t["trunk"]
	var r0: float = float(trunk[1])
	var r1: float = float(trunk[2])
	m.gradient = Vector2(0.0, float(trunk[0]) * sc)
	m.color = Color(0.5, 1.0, 0.0, 0.0)
	m.tube("bark", "bark", Vector3.ZERO, Vector3(0.0, float(trunk[0]), 0.0), r0, r1, int(t["sides"]), false, true)
	for root: Array in t["roots"]:
		var ang: float = deg_to_rad(float(root[0]))
		var dir := Vector3(cos(ang), 0.0, sin(ang))
		m.tube("bark", "bark", dir * r0 * 0.6 + Vector3(0.0, 0.45, 0.0), dir * (r0 + float(root[1])) + Vector3(0.0, -0.05, 0.0),
				r0 * 0.5, r0 * 0.18, 5, false, false)
	for branch: Array in t["branches"]:
		var tip: Vector3 = branch[1]
		var br: float = float(branch[2])
		m.tube("bark", "bark", Vector3(0.0, float(branch[0]), 0.0), tip, br, br * 0.55, 5, false, false)
	_crown(m, key, t["lobes"], t["crown"], sc, float(variant) * 0.1)
	m.xf = Transform3D.IDENTITY


## Copa: para cada lóbulo, um miolo maciço achatado e 9 cartões de tufo em volta (normais da copa).
## A copa pintada é mais cheia e mais baixa que a tabela da 011: lóbulos crescem CROWN_GROW em volta
## do centro da copa e descem CROWN_DROP.
const CROWN_GROW: float = 1.22
const CROWN_DROP: float = 0.7


static func _crown(m: KitMesher, key: String, lobes: Array, crown_in: Vector3, sc: float, variation: float) -> void:
	var crown: Vector3 = crown_in - Vector3(0.0, CROWN_DROP, 0.0)
	var y_lo: float = INF
	var y_hi: float = -INF
	# Elipsoide da copa inteira: a normal de todo cartão sai dele (uma luz só por copa).
	var reach_xz: float = 0.0
	var reach_y: float = 0.0
	for lobe: Vector4 in lobes:
		var ly: float = crown.y + (lobe.y - crown_in.y) * CROWN_GROW
		y_lo = minf(y_lo, ly - lobe.w * CROWN_GROW)
		y_hi = maxf(y_hi, ly + lobe.w * CROWN_GROW)
		reach_xz = maxf(reach_xz, Vector2(lobe.x - crown_in.x, lobe.z - crown_in.z).length() * CROWN_GROW + lobe.w * CROWN_GROW)
	reach_y = maxf(y_hi - crown.y, crown.y - y_lo)
	var radii := Vector3(reach_xz, reach_y, reach_xz)
	m.gradient = Vector2(y_lo * sc, y_hi * sc)
	var card: int = 0
	var lobe_index: int = 0
	for lobe: Vector4 in lobes:
		var c: Vector3 = crown + (Vector3(lobe.x, lobe.y, lobe.z) - crown_in) * CROWN_GROW
		var r: float = lobe.w * CROWN_GROW
		m.color = Color(0.0, 0.8, CARD_SOLID, variation)
		m.blob(key, c, Vector3(r * 0.78, r * 0.66, r * 0.78), 8, 5, crown, 1.0, float(lobe_index) * 0.37)
		for k in CARD_DIRS.size():
			var dir: Vector3 = CARD_DIRS[k].normalized()
			var center: Vector3 = c + dir * r * 0.42
			var helper: Vector3 = Vector3.UP if absf(dir.y) < 0.9 else Vector3.RIGHT
			var ax: Vector3 = dir.cross(helper).normalized()
			var ay: Vector3 = dir.cross(ax).normalized()
			var turn: float = deg_to_rad(CARD_TURNS[k] + 37.0 * float(lobe_index))
			var tx: Vector3 = ax * cos(turn) + ay * sin(turn)
			var ty: Vector3 = dir.cross(tx).normalized()
			_crown_card(m, key, center, tx, ty, r * CARD_HALF, crown, radii, card, variation)
			card += 1
		lobe_index += 1


## Cartão de tufo da copa: normal por vértice = normal do elipsoide da copa naquele ponto (esférica, contínua
## de um cartão para o outro) e AO pela profundidade (canal g: perto do centro da copa fica mais escuro).
static func _crown_card(m: KitMesher, key: String, c: Vector3, t: Vector3, b: Vector3, h: float, crown: Vector3,
		radii: Vector3, card_id: int, variation: float) -> void:
	var id: float = float(card_id)
	var pts: Array[Vector3] = [c - t * h + b * h, c + t * h + b * h, c + t * h - b * h, c - t * h - b * h]
	var uvs: Array[Vector2] = [Vector2(0.0, id), Vector2(1.0, id), Vector2(1.0, id + 0.999), Vector2(0.0, id + 0.999)]
	var nrm: Array[Vector3] = []
	var ao: Array[float] = []
	for p: Vector3 in pts:
		var q: Vector3 = (p - crown) / radii
		nrm.append((q / radii).normalized() if q.length() > 0.001 else Vector3.UP)
		ao.append(lerpf(CROWN_AO_MIN, 1.0, smoothstep(0.3, 0.95, q.length())))
	m.color = Color(0.0, 1.0, CARD_CLUMP, variation)
	m.tri_g(key, pts[0], pts[1], pts[2], nrm[0], nrm[1], nrm[2], uvs[0], uvs[1], uvs[2], ao[0], ao[1], ao[2])
	m.tri_g(key, pts[0], pts[2], pts[3], nrm[0], nrm[2], nrm[3], uvs[0], uvs[2], uvs[3], ao[0], ao[2], ao[3])


## Luz mínima (canal g) no miolo da copa.
const CROWN_AO_MIN: float = 0.36


## Raio da copa pintada de uma folhosa (maior distância horizontal de um lóbulo ao tronco), já com a escala.
## É o que vai em KitPiece.size (largura = 2 x raio) e o que o teste de mata usa para "copa encavalada".
static func broad_crown_radius(variant: int) -> float:
	var t: Dictionary = KitTables.BROAD[variant]
	var crown: Vector3 = t["crown"]
	var r: float = 0.0
	for lobe: Vector4 in t["lobes"]:
		r = maxf(r, Vector2(lobe.x - crown.x, lobe.z - crown.z).length() * CROWN_GROW + lobe.w * CROWN_GROW)
	return r * float(KitTables.BROAD_SCALE[variant])


## Altura do topo da copa pintada de uma folhosa, já com a escala.
static func broad_height(variant: int) -> float:
	var t: Dictionary = KitTables.BROAD[variant]
	var crown: Vector3 = t["crown"]
	var top: float = 0.0
	for lobe: Vector4 in t["lobes"]:
		top = maxf(top, crown.y - CROWN_DROP + (lobe.y - crown.y) * CROWN_GROW + lobe.w * CROWN_GROW)
	return top * float(KitTables.BROAD_SCALE[variant])


## Raio da base (maior alcance dos cartões, com a variação da tabela e o desvio do andar) e altura de uma
## conífera pintada, já com a escala. Base = 2 x raio (revisão 012-f2: de 2,0 a 3,2).
static func conifer_radius(variant: int) -> float:
	var r: float = 0.0
	var tiers: Array = KitTables.CONIFERS[variant]["tiers"]
	for t in tiers.size():
		var tier: Array = tiers[t]
		var off := Vector2(float(tier[5]), float(tier[6]))
		for i in int(tier[4]):
			var reach: float = float(tier[2]) * _conifer_card_var(variant, t, i).y
			r = maxf(r, reach + off.length())
	return r * float(KitTables.CONIFER_SCALE[variant])


static func conifer_height(variant: int) -> float:
	var tiers: Array = KitTables.CONIFERS[variant]["tiers"]
	var last: Array = tiers[tiers.size() - 1]
	return (float(last[0]) + float(last[1]) + 0.05) * float(KitTables.CONIFER_SCALE[variant])


static func _conifer_card_var(variant: int, tier: int, card: int) -> Vector2:
	var table: Array[Vector2] = KitTables.CONIFER_CARD_VAR
	return table[(3 * card + 5 * tier + 7 * variant) % table.size()]


## Largura do cartão (fração do alcance) e queda da saia (fração da altura do andar).
const TIER_CARD_WIDTH: float = 0.72
const TIER_DROOP: float = 0.16


## Conífera (revisão 012-f2): tronco e andares; cada andar = cone maciço escuro por dentro + 7 a 9 cartões
## inclinados com o desenho do andar (atlas conifer_tiers, arte A08), do eixo até a saia. Ângulo e alcance
## de cada cartão variam pela tabela; a normal é suave por vértice (radial + para cima), sem faceta.
static func painted_conifer(m: KitMesher, variant: int) -> void:
	var c: Dictionary = KitTables.CONIFERS[variant]
	var sc: float = float(KitTables.CONIFER_SCALE[variant])
	m.xf = Transform3D(Basis.IDENTITY.scaled(Vector3(sc, sc, sc)), Vector3.ZERO)
	var tiers: Array = c["tiers"]
	var last: Array = tiers[tiers.size() - 1]
	var top_y: float = float(last[0]) + float(last[1])
	m.gradient = Vector2(0.0, 1.2 * sc)
	m.color = Color(0.5, 1.0, 0.0, 0.0)
	m.tube("bark", "bark", Vector3.ZERO, Vector3(0.0, float(c["trunk"]), 0.0), 0.15, 0.05, 6, false, false)
	m.gradient = Vector2(float(tiers[0][0]) * sc, top_y * sc)
	for t in tiers.size():
		var tier: Array = tiers[t]
		var y0: float = float(tier[0])
		var h: float = float(tier[1])
		var reach0: float = float(tier[2])
		var rot: float = deg_to_rad(float(tier[3]))
		var cards: int = int(tier[4])
		var axis := Vector3(float(tier[5]), 0.0, float(tier[6]))
		var tip: bool = t == tiers.size() - 1
		# Miolo escuro (sombra própria entre os andares).
		m.color = Color(0.0, 1.0, CARD_SOLID, float(variant) * 0.1)
		m.tube("foliage_conifer", "foliage_conifer", axis + Vector3(0.0, y0 + 0.1 * h, 0.0), axis + Vector3(0.0, y0 + h * 0.8, 0.0),
				reach0 * 0.5, 0.06, 8, true, false)
		# Célula do atlas conifer_tiers: andares 0 a 5 do mais largo ao mais estreito; pontas 6 e 7.
		var cell: int = mini(5, roundi(float(t) * 5.0 / float(maxi(tiers.size() - 2, 1))))
		if tip:
			cell = 6 + variant % 2
		var droop: float = TIER_DROOP * h
		for i in cards:
			var var_i: Vector2 = _conifer_card_var(variant, t, i)
			var th: float = rot + TAU * float(i) / float(cards) + deg_to_rad(var_i.x)
			var reach: float = reach0 * var_i.y
			var half_w: float = reach * TIER_CARD_WIDTH
			var radial := Vector3(cos(th), 0.0, sin(th))
			var tangent := Vector3(-sin(th), 0.0, cos(th))
			# Cartão inclinado: o topo junto do eixo (ponta do andar), a saia embaixo, na borda do andar.
			var top_c: Vector3 = axis + radial * 0.06 + Vector3(0.0, y0 + h + 0.05, 0.0)
			var bot_c: Vector3 = axis + radial * reach + Vector3(0.0, y0 - droop * var_i.y, 0.0)
			var p0: Vector3 = top_c - tangent * half_w * 0.35
			var p1: Vector3 = top_c + tangent * half_w * 0.35
			var p2: Vector3 = bot_c + tangent * half_w
			var p3: Vector3 = bot_c - tangent * half_w
			var n0: Vector3 = _conifer_normal(p0 - axis, 0.9)
			var n1: Vector3 = _conifer_normal(p1 - axis, 0.9)
			var n2: Vector3 = _conifer_normal(p2 - axis, 0.45)
			var n3: Vector3 = _conifer_normal(p3 - axis, 0.45)
			var id: float = float(cell)
			m.color = Color(0.0, 1.0, CARD_TIER, float(variant) * 0.1)
			m.tri("foliage_conifer", p0, p1, p2, n0, n1, n2, Vector2(0.0, id), Vector2(1.0, id), Vector2(1.0, id + 0.999))
			m.tri("foliage_conifer", p0, p2, p3, n0, n2, n3, Vector2(0.0, id), Vector2(1.0, id + 0.999), Vector2(0.0, id + 0.999))
	m.xf = Transform3D.IDENTITY


## Normal suave da conífera num ponto (relativo ao eixo do andar): radial na horizontal + `up` para cima.
static func _conifer_normal(rel: Vector3, up: float) -> Vector3:
	var flat := Vector3(rel.x, 0.0, rel.z)
	if flat.length() < 0.001:
		return Vector3.UP
	return (flat.normalized() + Vector3(0.0, up, 0.0)).normalized()


static func painted_bush(m: KitMesher, variant: int) -> void:
	var lobes: Array = KitTables.BUSHES[variant]
	_crown(m, "foliage_cool" if variant % 2 == 0 else "foliage_mid", lobes, Vector3(0.0, 0.3, 0.0), 1.0, 0.5 + float(variant) * 0.1)


# ================================================================ fora da ilha

## Lâminas da cascata e o rio no topo da ilha alta (coordenadas do mundo; peça na origem).
## Cor do vértice: r = largura da lâmina / 32 e g = altura da queda / 32 (o shader apaga as bordas).
static func waterfall(m: KitMesher) -> void:
	var top: float = IslandTables.WATERFALL_TOP
	var lip: float = IslandTables.WATERFALL_LIP
	var z: float = IslandTables.WATERFALL_Z
	var bottom: float = IslandTables.WATERFALL_BOTTOM
	var river_y: float = IslandTables.HIGH_TOP_Y + 0.03
	var fall: float = river_y - bottom
	# Perfil: do rio (topo da ilha alta) desce pela quina curva até o lábio e cai reto.
	var prof: Array[Vector2] = [Vector2(lip, river_y), Vector2(lip + 0.3, top - 0.05), Vector2(z, top - 0.6), Vector2(z, top - 4.0),
			Vector2(z + 0.05, top - 9.0), Vector2(z + 0.1, bottom)]
	for sheet: Array in IslandTables.WATERFALL_SHEETS:
		var x0: float = float(sheet[0])
		var x1: float = float(sheet[1])
		m.color = Color((x1 - x0) / 32.0, fall / 32.0, 0.0, 1.0)
		var dist: float = 0.0
		for i in range(prof.size() - 1):
			var a: Vector2 = prof[i]
			var b: Vector2 = prof[i + 1]
			var seg: float = a.distance_to(b)
			var n := Vector3(0.0, (b.x - a.x), -(b.y - a.y)).normalized()
			if n.z < 0.0:
				n = -n
			m.quad("water_fall", Vector3(x0, a.y, a.x), Vector3(x1, a.y, a.x), Vector3(x1, b.y, b.x), Vector3(x0, b.y, b.x), n,
					Vector2(0.0, dist), Vector2(x1 - x0, dist), Vector2(x1 - x0, dist + seg), Vector2(0.0, dist + seg))
			dist += seg
	var river: Array = IslandTables.RIVER
	var rx0: float = float(river[0])
	var rx1: float = float(river[1])
	var back: float = float(river[2])
	m.color = Color((rx1 - rx0) / 32.0, 1.0, 0.0, 1.0)
	m.quad("water_fall", Vector3(rx0, river_y, back), Vector3(rx1, river_y, back), Vector3(rx1, river_y, lip), Vector3(rx0, river_y, lip),
			Vector3.UP, Vector2(0.0, 2.0), Vector2(rx1 - rx0, 2.0), Vector2(rx1 - rx0, 2.0 + lip - back), Vector2(0.0, 2.0 + lip - back))
	m.color = Color.WHITE


## Fita do arco-íris no plano z RAINBOW_Z (UV.x ao longo, UV.y de fora para dentro).
static func rainbow(m: KitMesher) -> void:
	var arc: PackedVector2Array = IslandTables.RAINBOW_ARC
	var z: float = IslandTables.RAINBOW_Z
	var hw: float = IslandTables.RAINBOW_WIDTH * 0.5
	var center: Vector2 = Vector2(8.26, -10.73)
	var n: int = arc.size()
	for i in range(n - 1):
		var a: Vector2 = arc[i]
		var b: Vector2 = arc[i + 1]
		var oa: Vector2 = (a - center).normalized()
		var ob: Vector2 = (b - center).normalized()
		var ua: float = float(i) / float(n - 1)
		var ub: float = float(i + 1) / float(n - 1)
		var a_out: Vector2 = a + oa * hw
		var a_in: Vector2 = a - oa * hw
		var b_out: Vector2 = b + ob * hw
		var b_in: Vector2 = b - ob * hw
		m.quad("rainbow", Vector3(a_out.x, a_out.y, z), Vector3(b_out.x, b_out.y, z), Vector3(b_in.x, b_in.y, z), Vector3(a_in.x, a_in.y, z),
				Vector3(0.0, 0.0, 1.0), Vector2(ua, 0.0), Vector2(ub, 0.0), Vector2(ub, 1.0), Vector2(ua, 1.0))


## Coluna de ruína em tambores (revisão: na referência são tambores de coluna, não tijolo): base, tambores de
## alturas e raios da tabela com um sulco entre eles e capitel (a = inteira, b = quebrada, c = toco).
const DRUM_HEIGHTS: Array[float] = [0.62, 0.55, 0.68, 0.58, 0.64, 0.6]
const DRUM_RADII: Array[float] = [0.34, 0.355, 0.33, 0.345, 0.335, 0.35]
const DRUM_SHIFT: Array[float] = [0.0, 0.02, -0.015, 0.025, -0.01, 0.015]


static func column(m: KitMesher, variant: int) -> void:
	var heights: Array[float] = [3.4, 2.1, 0.9]
	var h: float = heights[variant]
	m.gradient = Vector2(0.0, h)
	m.box("ruin_stone_box", "ruin_stone_box", Vector3(-0.5, 0.0, -0.5), Vector3(0.5, 0.28, 0.5))
	var shaft_top: float = h - (0.3 if variant == 0 else 0.0)
	var y: float = 0.28
	var i: int = variant * 2
	while y < shaft_top - 0.05:
		var dh: float = minf(DRUM_HEIGHTS[i % DRUM_HEIGHTS.size()], shaft_top - y)
		var r: float = DRUM_RADII[i % DRUM_RADII.size()]
		var off := Vector3(DRUM_SHIFT[i % DRUM_SHIFT.size()], 0.0, -DRUM_SHIFT[(i + 2) % DRUM_SHIFT.size()])
		var top_y: float = y + dh
		# Sulco: o tambor afina 0,03 na junta de cima.
		m.tube("ruin_stone", "ruin_stone", off + Vector3(0.0, y, 0.0), off + Vector3(0.0, top_y - 0.05, 0.0), r, r * 0.97, 10, false, false)
		m.tube("ruin_stone", "ruin_stone", off + Vector3(0.0, top_y - 0.05, 0.0), off + Vector3(0.0, top_y, 0.0), r * 0.9, r * 0.9, 10, false,
				top_y >= shaft_top - 0.05)
		y = top_y
		i += 1
	if variant == 0:
		m.box("ruin_stone_box", "ruin_stone_box", Vector3(-0.52, shaft_top, -0.52), Vector3(0.52, h, 0.52))


## Tambores caídos no topo da ilhota das ruínas (coordenadas locais da ilhota).
static func ruin_drums(m: KitMesher) -> void:
	m.gradient = Vector2(0.0, 0.8)
	m.tube("ruin_stone", "ruin_stone", Vector3(1.6, 0.34, 2.8), Vector3(2.1, 0.34, 3.1), 0.34, 0.34, 10, true, true)
	m.tube("ruin_stone", "ruin_stone", Vector3(2.15, 0.34, 3.13), Vector3(2.6, 0.34, 3.4), 0.33, 0.33, 10, true, true)
	m.tube("ruin_stone", "ruin_stone", Vector3(-3.4, 0.3, 1.8), Vector3(-2.7, 0.3, 2.6), 0.3, 0.3, 10, true, true)
	m.tube("ruin_stone", "ruin_stone", Vector3(3.6, 0.32, -1.4), Vector3(4.5, 0.32, -0.9), 0.32, 0.32, 10, true, true)
	m.gradient = Vector2.ZERO


## Cipós pendurados da rocha grande (coordenadas locais da rocha).
static func rock_vines(m: KitMesher) -> void:
	var xf_saved: Transform3D = m.xf
	var k: int = 0
	for spot: Vector3 in [Vector3(-2.8, -1.0, 1.6), Vector3(1.4, -2.0, 2.6), Vector3(3.2, -1.4, -0.4), Vector3(-0.6, -3.4, 2.0)]:
		m.xf = Transform3D(Basis(Vector3.UP, deg_to_rad(70.0 * float(k))).scaled(Vector3(1.6, 1.6, 1.6)), spot)
		var vc: Array = VINE_CARDS[k % 2]
		hang_cards(m, "vines_cards", float(vc[0]), float(vc[1]), (int(vc[2]) + k) % 4, int(vc[3]))
		k += 1
	m.xf = xf_saved


## Nuvem (A08 leva 2, Fase 3): cada puff da tabela vira um quad em billboard (shader cloud_puff) com uma célula
## do atlas; o tamanho cobre a esfera da tabela (o desenho ocupa 85% da largura e 60% da altura da célula).
## A ordem dos puffs na malha é a de desenho dentro do aglomerado: de trás (z local menor) para a frente.
const CLOUD_PUFF_SCALE: float = 1.45


static func cloud(m: KitMesher, puffs: Array, key: String) -> void:
	var ordered: Array = puffs.duplicate()
	ordered.sort_custom(func(a: Vector4, b: Vector4) -> bool: return a.z < b.z)
	var k: int = 0
	for p: Vector4 in ordered:
		var half: float = p.w * CLOUD_PUFF_SCALE
		var c := Vector3(p.x, p.y - p.w * 0.13, p.z)
		_billboard(m, key, c, half, (k * 3 + puffs.size()) % 4 if key == "cloud_puff" else 0, 2 if key == "cloud_puff" else 1,
				0.2 + 0.15 * float(k % 5))
		k += 1
	m.color = Color.WHITE


## Topo visível (local) de uma nuvem da tabela: o desenho vai até 14% da célula (72% da meia altura acima do centro).
static func cloud_visible_top(variant: int) -> float:
	var top: float = -INF
	for p: Vector4 in IslandTables.CLOUDS[variant]:
		top = maxf(top, p.y - p.w * 0.13 + p.w * CLOUD_PUFF_SCALE * 0.72)
	return top


## Quad de billboard no plano XY local centrado em c (meia largura half), com a célula do atlas (cols x cols) e
## uma folga mínima no UV (o shader tira o canto do quad de fract(UV)). COLOR.r = half / 32, COLOR.a = tom.
static func _billboard(m: KitMesher, key: String, c: Vector3, half: float, cell: int, cols: int, shade: float) -> void:
	var du: float = 1.0 / float(cols)
	var u0: float = float(cell % cols) * du
	var v0: float = float(cell / cols) * du
	var e: float = 0.002
	m.color = Color(half / 32.0, 0.0, 0.0, shade)
	m.quad(key, c + Vector3(-half, half, 0.0), c + Vector3(half, half, 0.0), c + Vector3(half, -half, 0.0), c + Vector3(-half, -half, 0.0),
			Vector3(0.0, 0.0, 1.0), Vector2(u0 + e, v0 + e), Vector2(u0 + du - e, v0 + e), Vector2(u0 + du - e, v0 + du - e),
			Vector2(u0 + e, v0 + du - e))


# ================================================================ estruturas

## Braseiro: base, pedestal de pedra, bacia de ferro e a chama em 2 cartões cruzados (a luz vem da cena).
static func brazier(m: KitMesher) -> void:
	m.gradient = Vector2(0.0, 0.8)
	m.box("stone_painted", "stone_painted", Vector3(-0.25, 0.0, -0.25), Vector3(0.25, 0.12, 0.25))
	m.box("stone_painted", "stone_painted", Vector3(-0.19, 0.12, -0.19), Vector3(0.19, 0.7, 0.19))
	m.gradient = Vector2.ZERO
	m.color = Color(0.5, 1.0, 0.0, 1.0)
	m.tube("iron_painted", "iron_painted", Vector3(0.0, 0.68, 0.0), Vector3(0.0, 0.9, 0.0), 0.15, 0.27, 8, true, false)
	m.disc("iron_painted", _circle(0.25, 8), 0.86, true)
	m.color = Color.WHITE
	for k in 2:
		var ang: float = deg_to_rad(30.0 + 90.0 * float(k))
		var d := Vector3(cos(ang), 0.0, sin(ang)) * 0.22
		var n := Vector3(-sin(ang), 0.0, cos(ang))
		for side in [1.0, -1.0]:
			m.quad("flame", Vector3(0.0, 1.48, 0.0) - d, Vector3(0.0, 1.48, 0.0) + d, Vector3(0.0, 0.84, 0.0) + d, Vector3(0.0, 0.84, 0.0) - d,
					n * float(side), Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 1.0), Vector2(0.0, 1.0))


static func _circle(r: float, sides: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for i in sides:
		var a: float = TAU * float(i) / float(sides)
		out.append(Vector2(cos(a), sin(a)) * r)
	return out


## Pilar de pedra do patamar sul (0,5 x 1,0 x 0,5 com capa).
static func pillar(m: KitMesher) -> void:
	m.gradient = Vector2(0.0, 1.1)
	m.box("stone_painted", "stone_painted", Vector3(-0.25, 0.0, -0.25), Vector3(0.25, 1.0, 0.25))
	m.box("stone_painted", "stone_painted", Vector3(-0.3, 1.0, -0.3), Vector3(0.3, 1.1, 0.3))


## Ponte de corda: tábuas sobre a catenária da tabela (local +X da cabeceira até a ilhota), longarinas,
## 2 postes em cada ponta, corrimão de corda e cordas pendentes.
static func bridge(m: KitMesher, curve: PackedVector2Array) -> void:
	var hw: float = IslandTables.BRIDGE_WIDTH * 0.5
	var n: int = curve.size()
	for i in range(n - 1):
		var a: Vector2 = curve[i]
		var b: Vector2 = curve[i + 1]
		m.color = Color(0.45 if i % 2 == 0 else 0.7, 1.0, 0.0, 1.0)
		_plank(m, Vector3(a.x + 0.03, a.y, -hw), Vector3(b.x - 0.03, b.y, -hw), 2.0 * hw, 0.07, 0.53 * float(i))
		for side in [-1.0, 1.0]:
			var zs: float = float(side) * (hw - 0.1)
			m.tube("wood_painted", "wood_painted", Vector3(a.x, a.y - 0.09, zs), Vector3(b.x, b.y - 0.09, zs), 0.05, 0.05, 4, false, false)
	m.color = Color(0.6, 1.0, 0.0, 1.0)
	var ends: Array[Vector2] = [curve[0], curve[n - 1]]
	for e: Vector2 in ends:
		for side in [-1.0, 1.0]:
			var zs: float = float(side) * (hw + 0.08)
			m.box("wood_painted", "wood_painted", Vector3(e.x - 0.09, e.y - 0.35, zs - 0.09), Vector3(e.x + 0.09, e.y + 1.05, zs + 0.09))
	m.color = Color(0.5, 1.0, 0.0, 1.0)
	for side in [-1.0, 1.0]:
		var zs: float = float(side) * (hw + 0.08)
		for i in range(n - 1):
			var t0: float = float(i) / float(n - 1)
			var t1: float = float(i + 1) / float(n - 1)
			var a := Vector3(curve[i].x, curve[i].y + 0.95 - 0.12 * 4.0 * t0 * (1.0 - t0), zs)
			var b := Vector3(curve[i + 1].x, curve[i + 1].y + 0.95 - 0.12 * 4.0 * t1 * (1.0 - t1), zs)
			m.tube("rope_painted", "rope_painted", a, b, 0.035, 0.035, 4, false, false)
			if i % 2 == 1:
				m.tube("rope_painted", "rope_painted", a, Vector3(a.x, curve[i].y + 0.02, zs * 0.95), 0.02, 0.02, 3, false, false)
	m.color = Color.WHITE


## Tábua inclinada de a a b (cantos do lado -Z), largura w em Z, espessura th. UV de wood_planks: u ao longo da
## ponte (a partir de u0, que muda por tábua) e v através dela (as tábuas pintadas correm em v).
static func _plank(m: KitMesher, a: Vector3, b: Vector3, w: float, th: float, u0: float) -> void:
	var dz := Vector3(0.0, 0.0, w)
	var down := Vector3(0.0, -th, 0.0)
	var along: Vector3 = (b - a).normalized()
	var up: Vector3 = Vector3(0.0, 0.0, 1.0).cross(along).normalized()
	if up.y < 0.0:
		up = -up
	var u1: float = u0 + a.distance_to(b)
	m.quad("wood_painted", a, b, b + dz, a + dz, up, Vector2(u0, 0.0), Vector2(u1, 0.0), Vector2(u1, w), Vector2(u0, w))
	m.quad("wood_painted", a + down, b + down, b + dz + down, a + dz + down, -up, Vector2(u0, 0.0), Vector2(u1, 0.0), Vector2(u1, w), Vector2(u0, w))
	m.quad("wood_painted", a, b, b + down, a + down, Vector3(0.0, 0.0, -1.0), Vector2(u0, 0.0), Vector2(u1, 0.0), Vector2(u1, th), Vector2(u0, th))
	m.quad("wood_painted", a + dz, b + dz, b + dz + down, a + dz + down, Vector3(0.0, 0.0, 1.0), Vector2(u0, w), Vector2(u1, w), Vector2(u1, w + th),
			Vector2(u0, w + th))
	m.quad("wood_painted", a, a + dz, a + dz + down, a + down, -along, Vector2(u0, 0.0), Vector2(u0, w), Vector2(u0 + th, w), Vector2(u0 + th, 0.0))
	m.quad("wood_painted", b, b + dz, b + dz + down, b + down, along, Vector2(u1, 0.0), Vector2(u1, w), Vector2(u1 + th, w), Vector2(u1 + th, 0.0))


## Laje plana irregular (4 cantos com folgas da tabela), topo em y, com a borda de 0,04.
static func _slab(m: KitMesher, corners: Array[Vector2], y: float, shade: float) -> void:
	m.color = Color(shade, 1.0, 0.0, 1.0)
	var pts: Array[Vector3] = []
	for c: Vector2 in corners:
		pts.append(Vector3(c.x, y, c.y))
	m.quad("slab_painted", pts[0], pts[1], pts[2], pts[3], Vector3.UP)
	for i in 4:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[(i + 1) % 4]
		var mid: Vector3 = (a + b) * 0.5
		var center: Vector3 = (pts[0] + pts[1] + pts[2] + pts[3]) * 0.25
		var out: Vector3 = (mid - center)
		out.y = 0.0
		m.quad("slab_painted", a, b, b - Vector3(0.0, 0.05, 0.0), a - Vector3(0.0, 0.05, 0.0), out.normalized())


static func _jit(i: int) -> float:
	return float(IslandTables.SLAB_JITTER[i % IslandTables.SLAB_JITTER.size()])


## Lajes numa área: 0 = patamar sul (meia elipse), 1 = patamar norte curto, 2 = plataforma oeste.
## Linhas em Z com comprimentos do ciclo; lajes em X com larguras do ciclo; cantos com as folgas do ciclo.
static func slabs_area(m: KitMesher, variant: int) -> void:
	var half: Vector2 = [Vector2(2.5, 1.75), Vector2(2.0, 0.75), Vector2(2.0, 2.75)][variant]
	var gap: float = 0.07
	var z: float = -half.y
	var row: int = variant * 3
	var k: int = variant * 5
	while z < half.y - 0.2:
		var depth: float = minf(float(IslandTables.SLAB_LENGTHS[row % IslandTables.SLAB_LENGTHS.size()]) * 0.8, half.y - z)
		var z1: float = z + depth
		var wx: float = half.x
		if variant == 0:
			# Meia elipse a partir da borda de cima (z = -half.y), raio 3,5 em Z.
			var tz: float = clampf((z + depth * 0.5 + half.y) / 3.5, 0.0, 1.0)
			wx = half.x * sqrt(maxf(1.0 - tz * tz, 0.05))
		var x: float = -wx
		while x < wx - 0.15:
			var w: float = minf(float(IslandTables.SLAB_WIDTHS[k % IslandTables.SLAB_WIDTHS.size()]), wx - x)
			var corners: Array[Vector2] = [Vector2(x + _jit(k), z + _jit(k + 1)), Vector2(x + w - gap + _jit(k + 2), z + _jit(k + 3)),
					Vector2(x + w - gap + _jit(k + 4), z1 - gap + _jit(k + 5)), Vector2(x + _jit(k + 6), z1 - gap + _jit(k + 7))]
			_slab(m, corners, 0.04, 0.35 + 0.1 * float(k % 6))
			x += w
			k += 1
		z = z1
		row += 1
	m.color = Color.WHITE


## Caminho de lajes ao longo da linha central (coordenadas do mundo), com um alargamento no fim.
static func path(m: KitMesher, line: PackedVector2Array, width: float) -> void:
	var gap: float = 0.07
	var k: int = 3
	for s in range(line.size() - 1):
		var a: Vector2 = line[s]
		var b: Vector2 = line[s + 1]
		var dir: Vector2 = (b - a).normalized()
		var side := Vector2(-dir.y, dir.x)
		var length: float = a.distance_to(b)
		var hw: float = width * 0.5 + (0.6 if s == line.size() - 2 else 0.0)
		var t: float = 0.0
		var row: int = s * 2
		while t < length - 0.1:
			var depth: float = minf(float(IslandTables.SLAB_LENGTHS[row % IslandTables.SLAB_LENGTHS.size()]), length - t)
			var x: float = -hw
			while x < hw - 0.15:
				var w: float = minf(float(IslandTables.SLAB_WIDTHS[k % IslandTables.SLAB_WIDTHS.size()]), hw - x)
				var p0: Vector2 = a + dir * (t + _jit(k)) + side * (x + _jit(k + 1))
				var p1: Vector2 = a + dir * (t + _jit(k + 2)) + side * (x + w - gap + _jit(k + 3))
				var p2: Vector2 = a + dir * (t + depth - gap + _jit(k + 4)) + side * (x + w - gap + _jit(k + 5))
				var p3: Vector2 = a + dir * (t + depth - gap + _jit(k + 6)) + side * (x + _jit(k + 7))
				var quad_pts: Array[Vector2] = [p0, p1, p2, p3]
				_slab(m, quad_pts, 0.04, 0.35 + 0.1 * float(k % 6))
				x += w
				k += 1
			t += depth
			row += 1
	m.color = Color.WHITE


## Pedras soltas da arena (planas, coordenadas do mundo): o anel externo quebrado e as lajes e pedrinhas,
## cada uma um quad do tamanho da célula do atlas arena_slabs (alfa recortado). Imagem: x = leste, y = sul.
static func arena_slabs(m: KitMesher) -> void:
	var c0: Vector2 = IslandTables.ARENA_RING_CENTER
	for e: Array in IslandTables.ARENA_RING_STONES:
		var ang: float = deg_to_rad(float(e[1]))
		var outward := Vector2(cos(ang), sin(ang))
		# O "sul" da célula aponta para o centro do anel (o lado convexo, ao norte da célula, fica para fora).
		_stone_card(m, int(e[0]), c0 + outward * float(e[2]), -outward)
	for e: Array in IslandTables.ARENA_LOOSE_STONES:
		var turn: float = deg_to_rad(float(e[3]))
		_stone_card(m, int(e[0]), Vector2(float(e[1]), float(e[2])), Vector2(0.0, 1.0).rotated(turn))


## Quad plano de uma célula do atlas 4x2 centrado em c, com o "sul" da imagem na direção south (x, z).
static func _stone_card(m: KitMesher, cell: int, c: Vector2, south: Vector2) -> void:
	var h: float = IslandTables.ARENA_STONE_CELL * 0.5
	var s: Vector2 = south.normalized() * h
	var e := Vector2(s.y, -s.x)
	var u0: float = float(cell % 4) * 0.25
	var v0: float = float(cell / 4) * 0.5
	var y: float = 0.03
	var nw: Vector2 = c - e - s
	var ne: Vector2 = c + e - s
	var se: Vector2 = c + e + s
	var sw: Vector2 = c - e + s
	m.quad("arena_stones", Vector3(nw.x, y, nw.y), Vector3(ne.x, y, ne.y), Vector3(se.x, y, se.y), Vector3(sw.x, y, sw.y), Vector3.UP,
			Vector2(u0, v0), Vector2(u0 + 0.25, v0), Vector2(u0 + 0.25, v0 + 0.5), Vector2(u0, v0 + 0.5))
