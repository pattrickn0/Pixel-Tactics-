class_name KitPieces
extends RefCounted
## Construtores das malhas do kit (spec 011, fase 2). Cada função monta uma peça a partir das
## tabelas de KitTables, no espaço local da peça (pivô = centro da pegada, na base; frente = +Z).
## Nada aqui sorteia: a única "variação" é a escolha explícita de linhas das tabelas.

const T: float = KitMesher.TEXEL
## Grama do topo do terraço e do degrau (material provisório pintado, spec 012).
const GRASS: String = "grass_painted_inner"
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
		"stair_crest_in":
			stair_crest_in(m, s)
		"stair_pass_out":
			stair_pass_out(m, s)
		"stair_crest":
			stair_crest(m, s)
		"stair_landing":
			stair_landing(m, s)
		"ground":
			m.top(mat, -s.x * 0.5, -s.z * 0.5, s.x * 0.5, s.z * 0.5, 0.0)
		"decal":
			decal(m, s, mat)
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
		_:
			if not SceneryPieces.build(m, entry):
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


## Passagem sul/norte, parte de dentro (spec 012, decisão 2): dentro da espessura do muro, do terraço (0,5)
## sobe a 0,75 e chega à crista (1,0), com bochechas de 0,5 que fecham as pontas do muro. Sobe para -Z local;
## a face de trás (-Z) dá para o lance de fora (0,75), então leva o espelho do último degrau e a face das bochechas.
static func stair_crest_in(m: KitMesher, s: Vector3) -> void:
	stair(m, s, 2, 0.5, 3.0, true)
	var hz: float = s.z * 0.5
	var hw: float = 1.5
	var yb: float = WALL_H - KitTables.SLAB_THICKNESS * T
	m.quad("stair_riser_1", Vector3(-hw, 0.75, -hz), Vector3(hw, 0.75, -hz), Vector3(hw, WALL_H, -hz), Vector3(-hw, WALL_H, -hz),
			Vector3(0.0, 0.0, -1.0), Vector2(0.0, 1.0), Vector2(1.0, 1.0), Vector2(1.0, 0.0), Vector2(0.0, 0.0))
	for side in [-1.0, 1.0]:
		var sg: float = side
		m.wall_z(FACE_HIGH, minf(sg * hw, sg * (hw + 0.5)), maxf(sg * hw, sg * (hw + 0.5)), 0.0, yb, -hz, -1.0)


## Passagem sul/norte, lance de fora: 3 degraus de 0,25 (0 -> 0,75) de z local +0,5 a -1,0, largura 3,
## com laterais de pedra baixa. A faixa de z +0,5 a +1,0 fica livre (o patamar de lajes cobre).
static func stair_pass_out(m: KitMesher, _s: Vector3) -> void:
	var hw: float = 1.5
	for i in 3:
		var zf: float = 0.5 - 0.5 * float(i)
		var top_y: float = 0.25 * float(i + 1)
		var low_y: float = 0.25 * float(i)
		var kind: String = str(i % 2)
		m.quad("stair_tread_" + kind, Vector3(-hw, top_y, zf), Vector3(hw, top_y, zf), Vector3(hw, top_y, zf - 0.5), Vector3(-hw, top_y, zf - 0.5),
				Vector3.UP, Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 1.0), Vector2(0.0, 1.0))
		m.quad("stair_riser_" + kind, Vector3(-hw, low_y, zf), Vector3(hw, low_y, zf), Vector3(hw, top_y, zf), Vector3(-hw, top_y, zf),
				Vector3(0.0, 0.0, 1.0), Vector2(0.0, 1.0), Vector2(1.0, 1.0), Vector2(1.0, 0.0), Vector2(0.0, 0.0))
		m.wall_x(FACE_LOW, zf - 0.5, zf, 0.0, top_y, -hw, -1.0)
		m.wall_x(FACE_LOW, zf - 0.5, zf, 0.0, top_y, hw, 1.0)


## Portão oeste/leste, na crista (spec 012, item 3): o lance passa por cima do muro num piso de lajes em 1,0
## (2 de andável) com as bochechas de 0,5 no mesmo nível e o mesmo capeamento do lance de fora. Nenhuma
## crista de muro atravessa o lance. Largura 3 em X local, fundo 1 em Z.
static func stair_crest(m: KitMesher, s: Vector3) -> void:
	var hz: float = s.z * 0.5
	var hw: float = 1.0
	m.quad("stair_tread_0", Vector3(-hw, WALL_H, hz), Vector3(hw, WALL_H, hz), Vector3(hw, WALL_H, -hz), Vector3(-hw, WALL_H, -hz),
			Vector3.UP, Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 1.0), Vector2(0.0, 1.0))
	for side in [-1.0, 1.0]:
		var sg: float = side
		var outer_x: float = sg * (hw + 0.5)
		var inner_x: float = sg * hw
		_crest_strip_z(m, -hz, hz, inner_x, outer_x, WALL_H)
		slab_row(m, 1, -hz, outer_x, sg, KitTables.SLABS_CHEEK_1_OUT, WALL_H, "wall_cap_z", FACE_HIGH, false)
		slab_row(m, 1, -hz, inner_x, -sg, KitTables.SLABS_CHEEK_1_IN, WALL_H, "wall_cap_z", FACE_HIGH, false)


## Patamar do portão no terraço: piso de lajes em 0,5 (1 x 3) com as faces de pedra baixa.
static func stair_landing(m: KitMesher, s: Vector3) -> void:
	var hx: float = s.x * 0.5
	var hz: float = s.z * 0.5
	m.quad("stair_tread_1", Vector3(-hx, s.y, -hz), Vector3(hx, s.y, -hz), Vector3(hx, s.y, hz), Vector3(-hx, s.y, hz),
			Vector3.UP, Vector2(0.0, 0.0), Vector2(s.x / 2.0, 0.0), Vector2(s.x / 2.0, s.z / 2.0), Vector2(0.0, s.z / 2.0))
	m.wall_z(FACE_LOW, -hx, hx, 0.0, s.y, hz, 1.0)
	m.wall_z(FACE_LOW, -hx, hx, 0.0, s.y, -hz, -1.0)


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
