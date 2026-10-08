class_name KitPieces
extends RefCounted
## Construtores das malhas do kit (spec 011, fase 2). Cada função monta uma peça a partir das
## tabelas de KitTables, no espaço local da peça (pivô = centro da pegada, na base; frente = +Z).
## Nada aqui sorteia: a única "variação" é a escolha explícita de linhas das tabelas.

const T: float = KitMesher.TEXEL
const GRASS: String = "ground_grass_arena"
const FACE_HIGH: String = "wall_high_face"
const FACE_LOW: String = "wall_low_face"
## Altura do degrau baixo e do muro alto (topo).
const STEP_H: float = 0.5
const WALL_H: float = 1.0
## v do capeamento amostrado nas pontas e no lado de dentro das lajes (linha 2 de 16, dentro da pedra).
const SLAB_SIDE_V: float = 0.12
## Altura da textura wall_quoin (e das faces do muro) em unidades: 48 texels.
const QUOIN_TEX_H: float = 1.5


static func build(entry: Dictionary) -> KitMesher:
	var m := KitMesher.new()
	var s: Vector3 = entry["size"]
	var v: int = int(entry.get("variant", 0))
	var mat: String = str(entry.get("material", ""))
	match str(entry["build"]):
		"step_low":
			step_low(m, s)
		"step_low_corner":
			step_low_corner(m, s)
		"terrace":
			terrace(m, s)
		"wall":
			wall(m, s)
		"wall_corner":
			wall_corner(m, s)
		"stair_outer":
			stair(m, s, 4, 0.0, 2.0, true)
		"stair_inner":
			stair(m, s, 2, 0.5, 2.0, true)
		"stair_low":
			stair(m, s, 2, 0.0, 3.0, false)
		"ground":
			m.top(mat, -s.x * 0.5, -s.z * 0.5, s.x * 0.5, s.z * 0.5, 0.0)
		"decal":
			decal(m, s, mat)
		"broad":
			tree_broad(m, v, 1, Transform3D.IDENTITY)
		"conifer":
			conifer(m, v, 1, Transform3D.IDENTITY)
		"bush":
			bush(m, v)
		"log":
			log_piece(m, s)
		"stump":
			stump(m, s)
		"rock":
			rock(m, s, v)
		"bench":
			bench(m, s)
		"crate":
			crate(m, Vector3.ZERO, s.x)
		"crate_stack":
			crate_stack(m, s)
		"wood_pile":
			wood_pile(m)
		"cross":
			cross(m, s, mat, float(v))
		"backdrop":
			backdrop(m, v)
		_:
			push_error("Construtor desconhecido: " + str(entry["build"]))
	return m


# ================================================================ fila de lajes e musgo

## Ponto no plano da fila: eixo 0 = fila ao longo de X (borda em z = b); eixo 1 = ao longo de Z (borda em x = b).
static func _p(axis: int, a: float, b: float, y: float) -> Vector3:
	return Vector3(a, y, b) if axis == 0 else Vector3(b, y, a)


static func _dir(axis: int, sgn: float) -> Vector3:
	return Vector3(0.0, 0.0, sgn) if axis == 0 else Vector3(sgn, 0.0, 0.0)


## Fila de lajes individuais (capeamento). `slabs` = linhas [largura, fundo, beiral, subida] em texels.
## `top_y` = altura da crista; as lajes têm 4 texels de espessura, passam do plano da face (beiral) e
## o topo sobe 1 a 2 texels, variando de laje para laje: o contorno nunca é uma régua.
## A face de fora usa o material da face (continua o muro); as pontas e o lado de dentro usam o
## material do capeamento (uma linha de pedra clara), para não aparecer o traço escuro do topo da face.
static func slab_row(m: KitMesher, axis: int, start: float, edge: float, sgn: float, slabs: Array, top_y: float,
		cap_key: String, face_key: String, inner_from_base: bool) -> void:
	var a: float = start
	var yb: float = top_y - KitTables.SLAB_THICKNESS * T
	var side_v: Vector2 = Vector2(0.0, SLAB_SIDE_V)
	for slab: Array in slabs:
		var w: float = float(slab[0]) * T
		var d: float = float(slab[1]) * T
		var o: float = float(slab[2]) * T
		var h: float = float(slab[3]) * T
		var a1: float = a + w
		var out_edge: float = edge + sgn * o
		var in_edge: float = edge - sgn * d
		var yt: float = top_y + h
		var n_out: Vector3 = _dir(axis, sgn)
		var n_along: Vector3 = _dir(1 - axis, 1.0) if axis == 0 else Vector3(0.0, 0.0, 1.0)
		# Topo (v = distância da borda de fora, em unidades).
		m.quad(cap_key, _p(axis, a, out_edge, yt), _p(axis, a1, out_edge, yt), _p(axis, a1, in_edge, yt), _p(axis, a, in_edge, yt),
				Vector3.UP, Vector2(a, 0.0), Vector2(a1, 0.0), Vector2(a1, o + d), Vector2(a, o + d))
		# Face de fora (a espessura da laje, sobre a face do muro).
		m.quad(face_key, _p(axis, a, out_edge, yb), _p(axis, a1, out_edge, yb), _p(axis, a1, out_edge, yt), _p(axis, a, out_edge, yt), n_out)
		# Pontas (visíveis quando a vizinha é mais baixa) e lado de dentro (1 a 2 texels sobre a crista).
		m.quad(cap_key, _p(axis, a, out_edge, yb), _p(axis, a, in_edge, yb), _p(axis, a, in_edge, yt), _p(axis, a, out_edge, yt), -n_along,
				side_v, side_v, side_v, side_v)
		m.quad(cap_key, _p(axis, a1, out_edge, yb), _p(axis, a1, in_edge, yb), _p(axis, a1, in_edge, yt), _p(axis, a1, out_edge, yt), n_along,
				side_v, side_v, side_v, side_v)
		var inner_y0: float = yb if inner_from_base else top_y
		m.quad(cap_key, _p(axis, a, in_edge, inner_y0), _p(axis, a1, in_edge, inner_y0), _p(axis, a1, in_edge, yt), _p(axis, a, in_edge, yt), -n_out,
				side_v, side_v, side_v, side_v)
		a = a1


## Musgo pendente preso no beiral: cartão contínuo ao longo do trecho, à frente da face.
static func drape(m: KitMesher, axis: int, a0: float, a1: float, edge: float, sgn: float, top_y: float, key: String) -> void:
	var y_top: float = top_y - KitTables.SLAB_THICKNESS * T + 2.0 * T
	var y_bot: float = y_top - KitTables.DRAPE_HEIGHT
	var b: float = edge + sgn * (2.0 * T + 0.01)
	m.quad(key, _p(axis, a0, b, y_top), _p(axis, a1, b, y_top), _p(axis, a1, b, y_bot), _p(axis, a0, b, y_bot), _dir(axis, sgn),
			Vector2(a0, 0.0), Vector2(a1, 0.0), Vector2(a1, KitTables.DRAPE_HEIGHT), Vector2(a0, KitTables.DRAPE_HEIGHT))


# ================================================================ degrau baixo, terraço, muro

static func step_low(m: KitMesher, s: Vector3) -> void:
	var hx: float = s.x * 0.5
	var hz: float = s.z * 0.5
	var slabs: Array = KitTables.SLABS_STEP_2 if s.x > 1.5 else KitTables.SLABS_STEP_1
	# Face de pedra clara na frente (+Z) e nas pontas; atrás só a grama do topo.
	m.wall_z(FACE_LOW, -hx, hx, 0.0, STEP_H, hz, 1.0)
	m.wall_x(FACE_LOW, -hz, hz, 0.0, STEP_H, -hx, -1.0)
	m.wall_x(FACE_LOW, -hz, hz, 0.0, STEP_H, hx, 1.0)
	m.top(GRASS, -hx, -hz, hx, hz, STEP_H)
	slab_row(m, 0, -hx, hz, 1.0, slabs, STEP_H, "wall_cap_low", FACE_LOW, false)


## Quina do degrau: só o quarto de capeamento (canto +X/+Z) que fecha o L entre as duas fileiras.
## wall_cap_corner (16x16): linha 0 e coluna 15 = beiradas sobre as faces; coluna 0 e linha 15 = onde
## o capeamento encosta. Aqui as beiradas ficam em +X e +Z: u = (z - z0) e v = (x1 - x), em texels.
static func step_low_corner(m: KitMesher, s: Vector3) -> void:
	var hx: float = s.x * 0.5
	var hz: float = s.z * 0.5
	m.wall_z(FACE_LOW, -hx, hx, 0.0, STEP_H, hz, 1.0)
	m.wall_x(FACE_LOW, -hz, hz, 0.0, STEP_H, hx, 1.0)
	m.top(GRASS, -hx, -hz, hx, hz, STEP_H)
	var w: float = 14.0 * T
	var o: float = 2.0 * T
	var h: float = 2.0 * T
	var yb: float = STEP_H - KitTables.SLAB_THICKNESS * T
	var yt: float = STEP_H + h
	var x0: float = hx - w
	var z0: float = hz - w
	var x1: float = hx + o
	var z1: float = hz + o
	var k: float = 1.0 / (16.0 * T)
	m.quad("wall_cap_corner", Vector3(x0, yt, z0), Vector3(x1, yt, z0), Vector3(x1, yt, z1), Vector3(x0, yt, z1), Vector3.UP,
			Vector2((z0 - z0) * k, (x1 - x0) * k), Vector2((z0 - z0) * k, (x1 - x1) * k),
			Vector2((z1 - z0) * k, (x1 - x1) * k), Vector2((z1 - z0) * k, (x1 - x0) * k))
	var side: Vector2 = Vector2(0.0, SLAB_SIDE_V)
	m.quad("wall_cap_low", Vector3(x0, yb, z1), Vector3(x1, yb, z1), Vector3(x1, yt, z1), Vector3(x0, yt, z1), Vector3(0.0, 0.0, 1.0), side, side, side, side)
	m.quad("wall_cap_low", Vector3(x1, yb, z0), Vector3(x1, yb, z1), Vector3(x1, yt, z1), Vector3(x1, yt, z0), Vector3(1.0, 0.0, 0.0), side, side, side, side)
	m.quad("wall_cap_low", Vector3(x0, yb, z0), Vector3(x1, yb, z0), Vector3(x1, yt, z0), Vector3(x0, yt, z0), Vector3(0.0, 0.0, -1.0), side, side, side, side)
	m.quad("wall_cap_low", Vector3(x0, yb, z0), Vector3(x0, yb, z1), Vector3(x0, yt, z1), Vector3(x0, yt, z0), Vector3(-1.0, 0.0, 0.0), side, side, side, side)


static func terrace(m: KitMesher, s: Vector3) -> void:
	var hx: float = s.x * 0.5
	var hz: float = s.z * 0.5
	m.top(GRASS, -hx, -hz, hx, hz, s.y)
	m.wall_z(FACE_LOW, -hx, hx, 0.0, s.y, hz, 1.0)
	m.wall_z(FACE_LOW, -hx, hx, 0.0, s.y, -hz, -1.0)
	m.wall_x(FACE_LOW, -hz, hz, 0.0, s.y, -hx, -1.0)
	m.wall_x(FACE_LOW, -hz, hz, 0.0, s.y, hx, 1.0)


## Muro alto reto: face interna (+Z) de 1,0 acima do terraço, face externa (-Z) de 1,5, crista de
## musgo com lajes de capeamento nas duas bordas e musgo pendente em cada face.
static func wall(m: KitMesher, s: Vector3) -> void:
	var hx: float = s.x * 0.5
	var yb: float = WALL_H - KitTables.SLAB_THICKNESS * T
	var long_piece: bool = s.x > 1.5
	m.wall_z(FACE_HIGH, -hx, hx, 0.5, yb, 0.5, 1.0)
	m.wall_z(FACE_HIGH, -hx, hx, 0.0, yb, -0.5, -1.0)
	m.top("wall_crest", -hx, -0.5, hx, 0.5, WALL_H, 0.0, 1.0)
	slab_row(m, 0, -hx, 0.5, 1.0, KitTables.SLABS_WALL_2_INNER if long_piece else KitTables.SLABS_WALL_1_INNER,
			WALL_H, "wall_cap", FACE_HIGH, false)
	slab_row(m, 0, -hx, -0.5, -1.0, KitTables.SLABS_WALL_2_OUTER if long_piece else KitTables.SLABS_WALL_1_OUTER,
			WALL_H, "wall_cap", FACE_HIGH, false)
	drape(m, 0, -hx, hx, 0.5, 1.0, WALL_H, "moss_drape_1")
	drape(m, 0, -hx, hx, -0.5, -1.0, WALL_H, "moss_drape_0")


## Quina externa do muro alto (faces -X e -Z). As duas faces usam wall_quoin (32x48 = 1 x 1,5, coluna
## 31 na aresta, coluna 0 continua a face do muro). Os blocos de amarração salientes seguem as fiadas
## pintadas: em cada fiada um bloco é longo e invade o canto, e o outro fica rente (alterna por fiada).
## Topo da quina: wall_crest_corner girada 90° sem espelhar (linha 0 e coluna 31 para fora).
static func wall_corner(m: KitMesher, _s: Vector3) -> void:
	var yb: float = WALL_H - KitTables.SLAB_THICKNESS * T
	_quoin_face_z(m, -0.5, 0.5, 0.0, yb, -0.5)
	_quoin_face_x(m, -0.5, 0.5, 0.0, yb, -0.5)
	# Topo da quina: u = 0,5 - z e v = x + 0,5 (outer em -X e -Z; a crista encosta em +X e +Z).
	m.quad("wall_crest_corner", Vector3(-0.5, WALL_H, -0.5), Vector3(0.5, WALL_H, -0.5), Vector3(0.5, WALL_H, 0.5), Vector3(-0.5, WALL_H, 0.5),
			Vector3.UP, Vector2(1.0, 0.0), Vector2(1.0, 1.0), Vector2(0.0, 1.0), Vector2(0.0, 0.0))
	# Blocos de amarração: fiadas de baixo para cima [altura em texels, comprimento em texels, longo?].
	var p: float = 2.0 * T
	var y: float = 0.0
	for course: Array in KitTables.QUOIN_COURSES:
		var ch: float = float(course[0]) * T
		var length: float = float(course[1]) * T
		var is_long: bool = bool(course[2])
		# Fiada longa: o bloco da face -Z invade o canto; fiada curta: o da face -X.
		_quoin_block_z(m, -0.5 - (p if is_long else 0.0), -0.5 + length, y, y + ch, -0.5 - p, is_long)
		_quoin_block_x(m, -0.5 - (0.0 if is_long else p), -0.5 + length, y, y + ch, -0.5 - p, not is_long)
		y += ch
	# Lajes de capeamento: bloco de canto (wall_cap_corner girada igual à quina do degrau) + uma laje em cada fila.
	var cb: Array = KitTables.SLABS_CORNER_BLOCK
	var cw: float = float(cb[0]) * T
	var co: float = float(cb[2]) * T
	var cyt: float = WALL_H + float(cb[3]) * T
	var cx0: float = -0.5 - co
	var cx1: float = -0.5 + cw
	# Janela de (cw + co) texels do canto da textura 16x16 (beiradas = linha 0 e coluna 15).
	var k: float = 1.0 / (16.0 * T)
	m.quad("wall_cap_corner", Vector3(cx0, cyt, cx0), Vector3(cx1, cyt, cx0), Vector3(cx1, cyt, cx1), Vector3(cx0, cyt, cx1), Vector3.UP,
			Vector2(1.0, 0.0), Vector2(1.0, (cx1 - cx0) * k), Vector2(1.0 - (cx1 - cx0) * k, (cx1 - cx0) * k), Vector2(1.0 - (cx1 - cx0) * k, 0.0))
	var side: Vector2 = Vector2(0.0, SLAB_SIDE_V)
	m.quad("wall_cap", Vector3(cx0, yb, cx0), Vector3(cx1, yb, cx0), Vector3(cx1, cyt, cx0), Vector3(cx0, cyt, cx0), Vector3(0.0, 0.0, -1.0), side, side, side, side)
	m.quad("wall_cap_z", Vector3(cx0, yb, cx0), Vector3(cx0, yb, cx1), Vector3(cx0, cyt, cx1), Vector3(cx0, cyt, cx0), Vector3(-1.0, 0.0, 0.0), side, side, side, side)
	m.quad("wall_cap_z", Vector3(cx1, yb, cx0), Vector3(cx1, yb, cx1), Vector3(cx1, cyt, cx1), Vector3(cx1, cyt, cx0), Vector3(1.0, 0.0, 0.0), side, side, side, side)
	m.quad("wall_cap", Vector3(cx0, yb, cx1), Vector3(cx1, yb, cx1), Vector3(cx1, cyt, cx1), Vector3(cx0, cyt, cx1), Vector3(0.0, 0.0, 1.0), side, side, side, side)
	slab_row(m, 0, cx1, -0.5, -1.0, KitTables.SLABS_CORNER_Z, WALL_H, "wall_cap", FACE_HIGH, false)
	slab_row(m, 1, cx1, -0.5, -1.0, KitTables.SLABS_CORNER_X, WALL_H, "wall_cap_z", FACE_HIGH, false)
	# Musgo pendente: um cartão por face, sem se cruzarem na quina.
	drape(m, 0, -0.5, 0.5, -0.5, -1.0, WALL_H, "moss_drape_0")
	drape(m, 1, -0.5, 0.5, -0.5, -1.0, WALL_H, "moss_drape_1_z")


## UV de wall_quoin (32x48 = 1 x 1,5): coluna 31 na aresta (u = 1 em -0,5), linha 0 no topo do muro;
## com o muro de 1,0 aparecem só as 32 linhas de cima. Clamp no material.
static func _quoin_uv(along: float, y: float) -> Vector2:
	return Vector2(0.5 - along, (WALL_H - y) / QUOIN_TEX_H)


## Face -Z (normal -Z) em z, de x0 a x1.
static func _quoin_face_z(m: KitMesher, x0: float, x1: float, y0: float, y1: float, z: float) -> void:
	m.quad("wall_quoin", Vector3(x0, y0, z), Vector3(x1, y0, z), Vector3(x1, y1, z), Vector3(x0, y1, z), Vector3(0.0, 0.0, -1.0),
			_quoin_uv(x0, y0), _quoin_uv(x1, y0), _quoin_uv(x1, y1), _quoin_uv(x0, y1))


## Face -X (normal -X) em x, de z0 a z1.
static func _quoin_face_x(m: KitMesher, z0: float, z1: float, y0: float, y1: float, x: float) -> void:
	m.quad("wall_quoin", Vector3(x, y0, z0), Vector3(x, y0, z1), Vector3(x, y1, z1), Vector3(x, y1, z0), Vector3(-1.0, 0.0, 0.0),
			_quoin_uv(z0, y0), _quoin_uv(z1, y0), _quoin_uv(z1, y1), _quoin_uv(z0, y1))


## Bloco saliente na face -Z: de x0 a x1, de y0 a y1, com a frente em z_out. `closes_corner` fecha o
## lado -X (o bloco invade o canto); o lado +X (fim do bloco) sempre aparece. A frente leva wall_quoin;
## o topo e os lados (2 texels) levam o material do capeamento (pedra clara, sem UV degenerado).
static func _quoin_block_z(m: KitMesher, x0: float, x1: float, y0: float, y1: float, z_out: float, closes_corner: bool) -> void:
	var z_in: float = -0.5
	var side: Vector2 = Vector2(0.0, SLAB_SIDE_V)
	m.quad("wall_quoin", Vector3(x0, y0, z_out), Vector3(x1, y0, z_out), Vector3(x1, y1, z_out), Vector3(x0, y1, z_out), Vector3(0.0, 0.0, -1.0),
			_quoin_uv(x0, y0), _quoin_uv(x1, y0), _quoin_uv(x1, y1), _quoin_uv(x0, y1))
	m.quad("wall_cap", Vector3(x0, y1, z_out), Vector3(x1, y1, z_out), Vector3(x1, y1, z_in), Vector3(x0, y1, z_in), Vector3.UP, side, side, side, side)
	m.quad("wall_cap", Vector3(x1, y0, z_out), Vector3(x1, y0, z_in), Vector3(x1, y1, z_in), Vector3(x1, y1, z_out), Vector3(1.0, 0.0, 0.0), side, side, side, side)
	if closes_corner:
		m.quad("wall_cap", Vector3(x0, y0, z_out), Vector3(x0, y0, z_in), Vector3(x0, y1, z_in), Vector3(x0, y1, z_out), Vector3(-1.0, 0.0, 0.0), side, side, side, side)


## Bloco saliente na face -X: de z0 a z1, com a frente em x_out. `closes_corner` fecha o lado -Z.
static func _quoin_block_x(m: KitMesher, z0: float, z1: float, y0: float, y1: float, x_out: float, closes_corner: bool) -> void:
	var x_in: float = -0.5
	var side: Vector2 = Vector2(0.0, SLAB_SIDE_V)
	m.quad("wall_quoin", Vector3(x_out, y0, z0), Vector3(x_out, y0, z1), Vector3(x_out, y1, z1), Vector3(x_out, y1, z0), Vector3(-1.0, 0.0, 0.0),
			_quoin_uv(z0, y0), _quoin_uv(z1, y0), _quoin_uv(z1, y1), _quoin_uv(z0, y1))
	m.quad("wall_cap_z", Vector3(x_out, y1, z0), Vector3(x_out, y1, z1), Vector3(x_in, y1, z1), Vector3(x_in, y1, z0), Vector3.UP, side, side, side, side)
	m.quad("wall_cap_z", Vector3(x_out, y0, z1), Vector3(x_in, y0, z1), Vector3(x_in, y1, z1), Vector3(x_out, y1, z1), Vector3(0.0, 0.0, 1.0), side, side, side, side)
	if closes_corner:
		m.quad("wall_cap_z", Vector3(x_out, y0, z0), Vector3(x_in, y0, z0), Vector3(x_in, y1, z0), Vector3(x_out, y1, z0), Vector3(0.0, 0.0, -1.0), side, side, side, side)


# ================================================================ escadas

## Lance de escada: degraus de piso 0,5 e espelho 0,25 subindo para -Z. Bochechas de muro de 0,5
## (com o mesmo capeamento) nas duas laterais quando `cheeks`; sem cheeks, as pontas são de pedra.
static func stair(m: KitMesher, s: Vector3, steps: int, base: float, walk: float, cheeks: bool) -> void:
	var hz: float = s.z * 0.5
	var hw: float = walk * 0.5
	var tread_u0: float = (s.x * 0.5 - hw) / s.x
	var tread_u1: float = 1.0 - tread_u0
	for i in steps:
		var zf: float = hz - 0.5 * float(i)
		var top_y: float = base + 0.25 * float(i + 1)
		var low_y: float = base + 0.25 * float(i)
		var kind: String = str(i % 2)
		m.quad("stair_tread_" + kind, Vector3(-hw, top_y, zf), Vector3(hw, top_y, zf), Vector3(hw, top_y, zf - 0.5), Vector3(-hw, top_y, zf - 0.5),
				Vector3.UP, Vector2(tread_u0, 0.0), Vector2(tread_u1, 0.0), Vector2(tread_u1, 1.0), Vector2(tread_u0, 1.0))
		m.quad("stair_riser_" + kind, Vector3(-hw, low_y, zf), Vector3(hw, low_y, zf), Vector3(hw, top_y, zf), Vector3(-hw, top_y, zf),
				Vector3(0.0, 0.0, 1.0), Vector2(tread_u0, 1.0), Vector2(tread_u1, 1.0), Vector2(tread_u1, 0.0), Vector2(tread_u0, 0.0))
		if not cheeks:
			m.wall_x(FACE_LOW, zf - 0.5, zf, base, top_y, -hw, -1.0)
			m.wall_x(FACE_LOW, zf - 0.5, zf, base, top_y, hw, 1.0)
	if not cheeks:
		return
	var yb: float = WALL_H - KitTables.SLAB_THICKNESS * T
	var cheek_depth: int = roundi(s.z)
	for side in [-1.0, 1.0]:
		var sg: float = side
		var outer_x: float = sg * (hw + 0.5)
		var inner_x: float = sg * hw
		# Flancos (fora e dentro) e a ponta da frente.
		m.wall_x(FACE_HIGH, -hz, hz, base, yb, outer_x, sg)
		m.wall_x(FACE_HIGH, -hz, hz, base, yb, inner_x, -sg)
		m.wall_z(FACE_HIGH, minf(inner_x, outer_x), maxf(inner_x, outer_x), base, yb, hz, 1.0)
		# Topo: faixa de crista (musgo) com uma fiada de lajes em cada borda, como o muro alto.
		_crest_strip_z(m, -hz, hz, inner_x, outer_x, WALL_H)
		slab_row(m, 1, -hz, outer_x, sg, KitTables.SLABS_CHEEK_2_OUT if cheek_depth == 2 else KitTables.SLABS_CHEEK_1_OUT,
				WALL_H, "wall_cap_z", FACE_HIGH, false)
		slab_row(m, 1, -hz, inner_x, -sg, KitTables.SLABS_CHEEK_2_IN if cheek_depth == 2 else KitTables.SLABS_CHEEK_1_IN,
				WALL_H, "wall_cap_z", FACE_HIGH, false)


## Faixa de crista ao longo de Z entre x_in e x_out (v = 0 no lado de fora, em x_out).
static func _crest_strip_z(m: KitMesher, z0: float, z1: float, x_in: float, x_out: float, y: float) -> void:
	var span: float = absf(x_out - x_in)
	m.quad("wall_crest_z", Vector3(x_out, y, z0), Vector3(x_out, y, z1), Vector3(x_in, y, z1), Vector3(x_in, y, z0), Vector3.UP,
			Vector2(z0, 0.0), Vector2(z1, 0.0), Vector2(z1, span), Vector2(z0, span))


# ================================================================ chão e decalques

static func decal(m: KitMesher, s: Vector3, mat: String) -> void:
	var hx: float = s.x * 0.5
	var hz: float = s.z * 0.5
	m.quad(mat, Vector3(-hx, 0.0, -hz), Vector3(hx, 0.0, -hz), Vector3(hx, 0.0, hz), Vector3(-hx, 0.0, hz), Vector3.UP,
			Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 1.0), Vector2(0.0, 1.0))


# ================================================================ árvores

## Folhosa: tronco que afina, raízes, galhos e a copa de lóbulos 3D. `lod` 1 = completa
## (miolo + casca recortada); 0 = só o miolo, menos facetas (fundo de mata).
static func tree_broad(m: KitMesher, variant: int, lod: int, xf: Transform3D) -> void:
	m.xf = xf
	var t: Dictionary = KitTables.BROAD[variant]
	var family: String = str(t["family"])
	var trunk: Array = t["trunk"]
	var sides: int = int(t["sides"])
	var r0: float = float(trunk[1])
	var r1: float = float(trunk[2])
	m.tube("bark_0", "wood_end", Vector3.ZERO, Vector3(0.0, float(trunk[0]), 0.0), r0, r1, sides, false, true)
	for root: Array in t["roots"]:
		var ang: float = deg_to_rad(float(root[0]))
		var dir := Vector3(cos(ang), 0.0, sin(ang))
		m.tube("bark_0", "wood_end", dir * r0 * 0.6 + Vector3(0.0, 0.45, 0.0), dir * (r0 + float(root[1])) + Vector3(0.0, -0.05, 0.0),
				r0 * 0.5, r0 * 0.18, 4, false, false)
	for branch: Array in t["branches"]:
		var tip: Vector3 = branch[1]
		var br: float = float(branch[2])
		m.tube("bark_0", "wood_end", Vector3(0.0, float(branch[0]), 0.0), tip, br, br * 0.55, 5, false, false)
	var crown: Vector3 = t["crown"]
	var lobe_sides: int = 10 if lod > 0 else 7
	var lobe_rings: int = 6 if lod > 0 else 4
	var turn: float = 0.0
	for lobe: Vector4 in t["lobes"]:
		var c := Vector3(lobe.x, lobe.y, lobe.z)
		var r: float = lobe.w
		m.blob("leaf_mass_" + family, c, Vector3(r, r * 0.85, r), lobe_sides, lobe_rings, crown, 0.55, turn)
		if lod > 0:
			m.blob("leaf_shell_" + family, c, Vector3(r * 1.14, r * 0.97, r * 1.14), lobe_sides, lobe_rings, crown, 0.75, turn + 0.3)
		turn += 0.37
	m.xf = Transform3D.IDENTITY


## Conífera: tronco e andares de cone com a borda de baixo serrilhada na própria geometria
## (pontas e reentrâncias da tabela) mais a faixa conifer_fringe pendurada em volta.
static func conifer(m: KitMesher, variant: int, lod: int, xf: Transform3D) -> void:
	m.xf = xf
	var c: Dictionary = KitTables.CONIFERS[variant]
	var tiers: Array = c["tiers"]
	var last: Array = tiers[tiers.size() - 1]
	var trunk_top: float = float(last[0]) + float(last[1]) * 0.55
	m.tube("bark_1", "wood_end", Vector3.ZERO, Vector3(0.0, trunk_top, 0.0), 0.15, 0.05, 5, false, false)
	for tier: Array in tiers:
		_conifer_tier(m, tier, lod)
	m.xf = Transform3D.IDENTITY


static func _tier_normal(phi: float) -> Vector3:
	return Vector3(cos(phi) * 0.9, 0.55, sin(phi) * 0.9).normalized()


static func _conifer_tier(m: KitMesher, tier: Array, _lod: int) -> void:
	var y0: float = float(tier[0])
	var h: float = float(tier[1])
	var rb: float = float(tier[2])
	var rt: float = float(tier[3])
	var rot: float = deg_to_rad(float(tier[4]))
	var pattern: Array = KitTables.CONIFER_PATTERNS[int(tier[5])]
	var n: int = pattern.size()
	var y_top: float = y0 + h
	var key: String = "conifer_needles"
	for i in n:
		var th: float = rot + TAU * float(i) / float(n)
		var th_next: float = rot + TAU * float(i + 1) / float(n)
		var th_prev: float = rot + TAU * float(i - 1) / float(n)
		var pi_mod: Vector2 = pattern[i]
		var p_prev: Vector2 = pattern[posmod(i - 1, n)]
		var p_next: Vector2 = pattern[posmod(i + 1, n)]
		var top_i: Vector3 = Vector3(cos(th) * rt, y_top, sin(th) * rt)
		var top_next: Vector3 = Vector3(cos(th_next) * rt, y_top, sin(th_next) * rt)
		var tip: Vector3 = Vector3(cos(th) * rb * pi_mod.x, y0 - pi_mod.y * h, sin(th) * rb * pi_mod.x)
		var notch_i: Vector3 = _notch(th, TAU / float(n), rb, pi_mod.x, p_next.x, y0, h)
		var notch_prev: Vector3 = _notch(th_prev, TAU / float(n), rb, p_prev.x, pi_mod.x, y0, h)
		var arc_r: float = rb
		var u_tip: float = th * arc_r
		var u_next: float = (th + TAU / float(n) * 0.5) * arc_r
		var u_prev: float = (th - TAU / float(n) * 0.5) * arc_r
		var half: float = TAU / float(n) * 0.5
		var uv_top: Vector2 = Vector2(u_tip, 0.0)
		var uv_tip: Vector2 = Vector2(u_tip, y_top - tip.y)
		var uv_n: Vector2 = Vector2(u_next, y_top - notch_i.y)
		var uv_p: Vector2 = Vector2(u_prev, y_top - notch_prev.y)
		var n_top: Vector3 = _tier_normal(th)
		var n_tip: Vector3 = _tier_normal(th)
		var n_notch: Vector3 = _tier_normal(th + half)
		var n_notch_prev: Vector3 = _tier_normal(th - half)
		m.tri(key, top_i, tip, notch_i, n_top, n_tip, n_notch, uv_top, uv_tip, uv_n)
		m.tri(key, top_i, notch_prev, tip, n_top, n_notch_prev, n_tip, uv_top, uv_p, uv_tip)
		if rt > 0.01:
			var uv_top_next: Vector2 = Vector2((th + 2.0 * half) * arc_r, 0.0)
			m.tri(key, top_i, notch_i, top_next, n_top, n_notch, _tier_normal(th_next), uv_top, uv_n, uv_top_next)
	# Tampa de cima e fundo (fecham a malha para a sombra e para as vistas de cima).
	var ring: Array[Vector2] = []
	var under: Array[Vector2] = []
	for i in n:
		var th2: float = rot + TAU * float(i) / float(n)
		if rt > 0.01:
			ring.append(Vector2(cos(th2) * rt, sin(th2) * rt))
		var nr: float = rb * 0.7 * float(KitTables.CONIFER_PATTERNS[int(tier[5])][i].x)
		under.append(Vector2(cos(th2 + PI / float(n)) * nr, sin(th2 + PI / float(n)) * nr))
	if rt > 0.01:
		m.disc(key, ring, y_top, true, Vector2(0.5, 0.5), 1.0)
	m.disc(key, under, y0 + 0.1 * h, false)
	# Faixa de franja pendurada abaixo da borda serrilhada (alfa recortado).
	var band_sides: int = n * 2
	var slope: float = (rb - rt) / h
	var y_a: float = y0 + 0.1 * h
	var y_b: float = y_a - 0.5
	var r_a: float = (rb - (rb - rt) * 0.1) * 1.02
	var r_b: float = r_a + slope * 0.5
	for k in band_sides:
		var a0: float = rot + TAU * float(k) / float(band_sides)
		var a1: float = rot + TAU * float(k + 1) / float(band_sides)
		var nrm: Vector3 = _tier_normal((a0 + a1) * 0.5)
		m.quad("conifer_fringe", Vector3(cos(a0) * r_a, y_a, sin(a0) * r_a), Vector3(cos(a1) * r_a, y_a, sin(a1) * r_a),
				Vector3(cos(a1) * r_b, y_b, sin(a1) * r_b), Vector3(cos(a0) * r_b, y_b, sin(a0) * r_b), nrm,
				Vector2(a0 * r_a, 0.0), Vector2(a1 * r_a, 0.0), Vector2(a1 * r_a, 0.5), Vector2(a0 * r_a, 0.5))


static func _notch(th: float, step: float, rb: float, m0: float, m1: float, y0: float, h: float) -> Vector3:
	var a: float = th + step * 0.5
	var r: float = rb * 0.7 * (m0 + m1) * 0.5
	return Vector3(cos(a) * r, y0 + 0.1 * h, sin(a) * r)


static func bush(m: KitMesher, variant: int) -> void:
	var lobes: Array = KitTables.BUSHES[variant]
	var flower: bool = variant == 3
	var crown := Vector3(0.0, 0.3, 0.0)
	var turn: float = 0.0
	for lobe: Vector4 in lobes:
		var c := Vector3(lobe.x, lobe.y, lobe.z)
		var r: float = lobe.w
		m.blob("leaf_mass_cool", c, Vector3(r, r * 0.85, r), 9, 5, crown, 0.4, turn)
		m.blob("leaf_shell_cool_flower" if flower else "leaf_shell_cool", c, Vector3(r * 1.14, r * 0.97, r * 1.14), 9, 5, crown, 0.6, turn + 0.3)
		turn += 0.41


# ================================================================ props

## Tronco caído: cilindro de 8 lados que afina, musgo no topo e pontas com anéis.
static func log_piece(m: KitMesher, s: Vector3) -> void:
	var half_len: float = s.x * 0.5
	var ry: float = s.y * 0.5
	var rz: float = s.z * 0.5
	var sides: int = 8
	for k in sides:
		var p0: float = TAU * float(k) / float(sides)
		var p1: float = TAU * float(k + 1) / float(sides)
		var taper: float = 0.92
		var a0: Vector3 = Vector3(-half_len, ry + cos(p0) * ry, sin(p0) * rz)
		var a1: Vector3 = Vector3(-half_len, ry + cos(p1) * ry, sin(p1) * rz)
		var b0: Vector3 = Vector3(half_len, ry + cos(p0) * ry * taper, sin(p0) * rz * taper)
		var b1: Vector3 = Vector3(half_len, ry + cos(p1) * ry * taper, sin(p1) * rz * taper)
		var mid: float = (p0 + p1) * 0.5
		var nrm := Vector3(0.0, cos(mid), sin(mid))
		var v0: float = absf(wrapf(p0, -PI, PI)) / PI
		var v1: float = absf(wrapf(p1, -PI, PI)) / PI
		m.quad("log_bark", a0, b0, b1, a1, nrm, Vector2(0.0, v0), Vector2(s.x, v0), Vector2(s.x, v1), Vector2(0.0, v1))
	for end in [-1.0, 1.0]:
		var e: float = end
		var r_scale: float = 1.0 if e < 0.0 else 0.92
		for k in sides:
			var p0: float = TAU * float(k) / float(sides)
			var p1: float = TAU * float(k + 1) / float(sides)
			var c := Vector3(e * half_len, ry, 0.0)
			var q0 := Vector3(e * half_len, ry + cos(p0) * ry * r_scale, sin(p0) * rz * r_scale)
			var q1 := Vector3(e * half_len, ry + cos(p1) * ry * r_scale, sin(p1) * rz * r_scale)
			m.tri_flat("wood_end", c, q0, q1, Vector3(e, 0.0, 0.0), Vector2(0.5, 0.5),
					Vector2(0.5 + sin(p0) * rz * r_scale, 0.5 + cos(p0) * ry * r_scale), Vector2(0.5 + sin(p1) * rz * r_scale, 0.5 + cos(p1) * ry * r_scale))


static func stump(m: KitMesher, s: Vector3) -> void:
	var r: float = s.x * 0.5
	m.tube("bark_0", "wood_end", Vector3.ZERO, Vector3(0.0, s.y, 0.0), r * 1.1, r * 0.9, 7, false, true)
	for root_deg in [15.0, 140.0, 265.0]:
		var ang: float = deg_to_rad(float(root_deg))
		var dir := Vector3(cos(ang), 0.0, sin(ang))
		m.tube("bark_0", "wood_end", dir * r * 0.7 + Vector3(0.0, s.y * 0.4, 0.0), dir * (r * 1.5) + Vector3(0.0, -0.03, 0.0),
				r * 0.3, r * 0.1, 4, false, false)


static func rock(m: KitMesher, s: Vector3, variant: int) -> void:
	var t: Dictionary = KitTables.ROCKS[variant]
	m.faceted("rock", Vector2.ZERO, Vector2(s.x * 0.5, s.z * 0.5), s.y, t["rings"], t["apex"], float(variant) * 0.35)


## Caixa com UV 0..1 por face (lados) e no topo; as larguras das texturas vêm em `tex_units`.
static func uv_box(m: KitMesher, side_key: String, top_key: String, lo: Vector3, hi: Vector3, tex_units: Vector2 = Vector2.ONE) -> void:
	var w: float = (hi.x - lo.x) / tex_units.x
	var d: float = (hi.z - lo.z) / tex_units.x
	var ht: float = (hi.y - lo.y) / tex_units.y
	m.quad(top_key, Vector3(lo.x, hi.y, lo.z), Vector3(hi.x, hi.y, lo.z), Vector3(hi.x, hi.y, hi.z), Vector3(lo.x, hi.y, hi.z), Vector3.UP,
			Vector2(0.0, 0.0), Vector2(w, 0.0), Vector2(w, d), Vector2(0.0, d))
	m.quad(side_key, Vector3(lo.x, lo.y, hi.z), Vector3(hi.x, lo.y, hi.z), Vector3(hi.x, hi.y, hi.z), Vector3(lo.x, hi.y, hi.z), Vector3(0.0, 0.0, 1.0),
			Vector2(0.0, ht), Vector2(w, ht), Vector2(w, 0.0), Vector2(0.0, 0.0))
	m.quad(side_key, Vector3(hi.x, lo.y, lo.z), Vector3(lo.x, lo.y, lo.z), Vector3(lo.x, hi.y, lo.z), Vector3(hi.x, hi.y, lo.z), Vector3(0.0, 0.0, -1.0),
			Vector2(0.0, ht), Vector2(w, ht), Vector2(w, 0.0), Vector2(0.0, 0.0))
	m.quad(side_key, Vector3(hi.x, lo.y, hi.z), Vector3(hi.x, lo.y, lo.z), Vector3(hi.x, hi.y, lo.z), Vector3(hi.x, hi.y, hi.z), Vector3(1.0, 0.0, 0.0),
			Vector2(0.0, ht), Vector2(d, ht), Vector2(d, 0.0), Vector2(0.0, 0.0))
	m.quad(side_key, Vector3(lo.x, lo.y, lo.z), Vector3(lo.x, lo.y, hi.z), Vector3(lo.x, hi.y, hi.z), Vector3(lo.x, hi.y, lo.z), Vector3(-1.0, 0.0, 0.0),
			Vector2(0.0, ht), Vector2(d, ht), Vector2(d, 0.0), Vector2(0.0, 0.0))


## Banco de tábuas: assento de 3 tábuas com frestas e dois pés de tábua.
static func bench(m: KitMesher, s: Vector3) -> void:
	var hx: float = s.x * 0.5
	var seat_y0: float = s.y - 0.07
	for zc in [-0.21, 0.0, 0.21]:
		var z: float = zc
		uv_box(m, "bench_floor_0", "bench_floor_0", Vector3(-hx, seat_y0, z - 0.09), Vector3(hx, s.y, z + 0.09))
	for side in [-1.0, 1.0]:
		var x: float = side * (hx - 0.18)
		uv_box(m, "bench_floor_0", "bench_floor_0", Vector3(x - 0.06, 0.0, -0.24), Vector3(x + 0.06, seat_y0, 0.24))


static func crate(m: KitMesher, at: Vector3, size: float) -> void:
	var h: float = size * 0.5
	uv_box(m, "crate_side", "crate_top", at + Vector3(-h, 0.0, -h), at + Vector3(h, size, h), Vector2(0.75, 0.75))


static func crate_stack(m: KitMesher, s: Vector3) -> void:
	crate(m, Vector3(-0.22, 0.0, -0.2), 0.55)
	crate(m, Vector3(0.24, 0.0, 0.18), 0.55)
	crate(m, Vector3(0.0, 0.55, 0.0), 0.45)


## Pilha de lenha: bloco de casca de 1 x 0,9 x 1 com as pontas (+Z e -Z) em wood_pile_end
## (a pilha vista de ponta, 32x32 = 1 unidade), janela de 29 texels de altura.
static func wood_pile(m: KitMesher) -> void:
	var h: float = 0.9
	var v0: float = 1.0 - h
	m.top("bark_0", -0.5, -0.5, 0.5, 0.5, h)
	m.quad("bark_0", Vector3(-0.5, 0.0, -0.5), Vector3(-0.5, 0.0, 0.5), Vector3(-0.5, h, 0.5), Vector3(-0.5, h, -0.5), Vector3(-1.0, 0.0, 0.0),
			Vector2(0.0, h), Vector2(1.0, h), Vector2(1.0, 0.0), Vector2(0.0, 0.0))
	m.quad("bark_0", Vector3(0.5, 0.0, -0.5), Vector3(0.5, 0.0, 0.5), Vector3(0.5, h, 0.5), Vector3(0.5, h, -0.5), Vector3(1.0, 0.0, 0.0),
			Vector2(0.0, h), Vector2(1.0, h), Vector2(1.0, 0.0), Vector2(0.0, 0.0))
	m.quad("wood_pile_end", Vector3(-0.5, 0.0, 0.5), Vector3(0.5, 0.0, 0.5), Vector3(0.5, h, 0.5), Vector3(-0.5, h, 0.5), Vector3(0.0, 0.0, 1.0),
			Vector2(0.0, 1.0), Vector2(1.0, 1.0), Vector2(1.0, v0), Vector2(0.0, v0))
	m.quad("wood_pile_end", Vector3(-0.5, 0.0, -0.5), Vector3(0.5, 0.0, -0.5), Vector3(0.5, h, -0.5), Vector3(-0.5, h, -0.5), Vector3(0.0, 0.0, -1.0),
			Vector2(1.0, 1.0), Vector2(0.0, 1.0), Vector2(0.0, v0), Vector2(1.0, v0))


## Cartões cruzados fixos: 3 cartões girados de 60° a partir do ângulo da peça, visíveis dos dois lados.
static func cross(m: KitMesher, s: Vector3, mat: String, angle_deg: float) -> void:
	for k in 3:
		var ang: float = deg_to_rad(angle_deg + 60.0 * float(k))
		var d := Vector3(cos(ang), 0.0, sin(ang)) * s.x * 0.5
		var n := Vector3(-sin(ang), 0.0, cos(ang))
		var up := Vector3(0.0, s.y, 0.0)
		for side in [1.0, -1.0]:
			m.quad(mat, -d + up, d + up, d, -d, n * float(side), Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 1.0), Vector2(0.0, 1.0))


## Aglomerado de fundo: árvores da tabela, menos detalhadas (só miolo nas folhosas).
static func backdrop(m: KitMesher, variant: int) -> void:
	for item: Array in KitTables.BACKDROPS[variant]:
		var scale: float = float(item[5])
		var basis := Basis(Vector3.UP, deg_to_rad(float(item[4]))).scaled(Vector3(scale, scale, scale))
		var xf := Transform3D(basis, Vector3(float(item[2]), 0.0, float(item[3])))
		if str(item[0]) == "c":
			conifer(m, int(item[1]), 0, xf)
		else:
			tree_broad(m, int(item[1]), 0, xf)
