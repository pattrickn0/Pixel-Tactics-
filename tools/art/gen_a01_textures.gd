extends RefCounted
## Texturas 32x32 da A01 (terreno 3D). Sem class_name: usar via preload.
## Tudo é desenhado com coordenadas em módulo 32 (seamless).

const P = preload("res://tools/art/palette.gd")
const L = preload("res://tools/art/art_lib.gd")

const N: int = 32
const BAND: int = 3 # faixa de borda igual em todas as variantes de uma família
const MAX_LUMA_DIFF: float = 0.035 # folga abaixo do limite 0,06 do verificador


static func rng_for(key: String) -> RandomNumberGenerator:
	var r: RandomNumberGenerator = RandomNumberGenerator.new()
	r.seed = key.hash()
	return r


static func build_all() -> Dictionary:
	var out: Dictionary = {}
	for v: int in 4:
		out["grass_arena_%d" % v] = grass_arena(v)
	for v: int in 2:
		out["grass_forest_%d" % v] = grass_forest(v)
	for v: int in 2:
		out["dirt_%d" % v] = dirt(v)
	out["ruin_tile"] = ruin_tile()
	out["step_side"] = step_side()
	out["step_side_grass"] = step_side_grass(out["step_side"])
	out["wall_face"] = wall_face()
	out["wall_top"] = wall_top()
	out["rock"] = rock()
	return out


# ---------------------------------------------------------------------------
# Utilidades de família (faixa compartilhada + miolo variável)
# ---------------------------------------------------------------------------

static func luma(c: Color) -> float:
	return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b


# Diferença de luminância média: [esquerda-direita, cima-baixo]
static func luma_halves(img: Image) -> Vector2:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var l_sum: float = 0.0
	var r_sum: float = 0.0
	var t_sum: float = 0.0
	var b_sum: float = 0.0
	for y: int in h:
		for x: int in w:
			var v: float = luma(img.get_pixel(x, y))
			if x < w / 2.0:
				l_sum += v
			else:
				r_sum += v
			if y < h / 2.0:
				t_sum += v
			else:
				b_sum += v
	var half: float = w * h / 2.0
	return Vector2(absf(l_sum - r_sum) / half, absf(t_sum - b_sum) / half)


# Carimbo como lista de [Vector2i, Color] relativos
static func stamp_cells(rows: Array, colors: Dictionary) -> Array:
	var cells: Array = []
	for j: int in rows.size():
		var row: String = rows[j]
		for i: int in row.length():
			var ch: String = row[i]
			if colors.has(ch):
				cells.append([Vector2i(i, j), colors[ch]])
	return cells


# Bolha (união de círculos relativos ao centro) como células de uma cor
static func blob_cells(circles: Array, c: Color) -> Array:
	var cells: Array = []
	var min_x: int = 999
	var min_y: int = 999
	var max_x: int = -999
	var max_y: int = -999
	for cir: Vector3 in circles:
		min_x = mini(min_x, floori(cir.x - cir.z))
		min_y = mini(min_y, floori(cir.y - cir.z))
		max_x = maxi(max_x, ceili(cir.x + cir.z))
		max_y = maxi(max_y, ceili(cir.y + cir.z))
	for y: int in range(min_y, max_y + 1):
		for x: int in range(min_x, max_x + 1):
			for cir: Vector3 in circles:
				var dx: float = x + 0.5 - cir.x
				var dy: float = y + 0.5 - cir.y
				if dx * dx + dy * dy <= cir.z * cir.z:
					cells.append([Vector2i(x, y), c])
					break
	return cells


static func draw_cells(img: Image, cells: Array, ox: int, oy: int) -> void:
	for cell: Array in cells:
		var p: Vector2i = cell[0]
		L.put_wrap(img, ox + p.x, oy + p.y, cell[1])


# Ocupação (com wrap) para evitar sobreposição de detalhes
static func occ_free(occ: PackedByteArray, cells: Array, ox: int, oy: int, pad: int) -> bool:
	for cell: Array in cells:
		var p: Vector2i = cell[0]
		for dy: int in range(-pad, pad + 1):
			for dx: int in range(-pad, pad + 1):
				var x: int = posmod(ox + p.x + dx, N)
				var y: int = posmod(oy + p.y + dy, N)
				if occ[y * N + x] != 0:
					return false
	return true


static func occ_mark(occ: PackedByteArray, cells: Array, ox: int, oy: int) -> void:
	for cell: Array in cells:
		var p: Vector2i = cell[0]
		occ[posmod(oy + p.y, N) * N + posmod(ox + p.x, N)] = 1


# O carimbo cabe inteiro no miolo (fora da faixa de borda)?
static func in_core(cells: Array, ox: int, oy: int) -> bool:
	for cell: Array in cells:
		var p: Vector2i = cell[0]
		var x: int = ox + p.x
		var y: int = oy + p.y
		if x < BAND or y < BAND or x >= N - BAND or y >= N - BAND:
			return false
	return true


# Espalha detalhes no miolo, sem encostar na faixa nem em outros detalhes
static func scatter_core(img: Image, occ: PackedByteArray, rng: RandomNumberGenerator, pool: Array, count: int, pad: int) -> void:
	var placed: int = 0
	var tries: int = 0
	while placed < count and tries < 400:
		tries += 1
		var cells: Array = pool[rng.randi_range(0, pool.size() - 1)]
		var ox: int = rng.randi_range(0, N - 1)
		var oy: int = rng.randi_range(0, N - 1)
		if not in_core(cells, ox, oy):
			continue
		if not occ_free(occ, cells, ox, oy, pad):
			continue
		draw_cells(img, cells, ox, oy)
		occ_mark(occ, cells, ox, oy)
		placed += 1


# ---------------------------------------------------------------------------
# Grama da arena
# ---------------------------------------------------------------------------

# Espalha em grade com jitter (distribuição uniforme, sem fileiras diagonais)
static func scatter_grid(img: Image, occ: PackedByteArray, rng: RandomNumberGenerator, pool: Array, grid: int, keep: float, pad: int) -> void:
	var span: float = float(N - 2 * BAND) / grid
	var cells: Array[Vector2i] = []
	for j: int in grid:
		for i: int in grid:
			cells.append(Vector2i(i, j))
	for c: Vector2i in cells:
		if rng.randf() > keep:
			continue
		var stamp: Array = pool[rng.randi_range(0, pool.size() - 1)]
		var size: Vector2i = Vector2i.ZERO
		for cell: Array in stamp:
			var p: Vector2i = cell[0]
			size = Vector2i(maxi(size.x, p.x + 1), maxi(size.y, p.y + 1))
		for attempt: int in 24:
			var cx: float = BAND + (c.x + rng.randf()) * span
			var cy: float = BAND + (c.y + rng.randf()) * span
			var ox: int = int(cx - size.x / 2.0)
			var oy: int = int(cy - size.y / 2.0)
			if in_core(stamp, ox, oy) and occ_free(occ, stamp, ox, oy, pad):
				draw_cells(img, stamp, ox, oy)
				occ_mark(occ, stamp, ox, oy)
				break


static func _arena_tufts() -> Array:
	var c: Dictionary = {"L": P.GRASS_3, "S": P.GRASS_1, "X": P.GRASS_0}
	return [
		stamp_cells([
			".L..L.",
			"LLL.LL",
			".LLLLS",
			"..SSXX",
		], c),
		stamp_cells([
			"L.L.",
			"LLLL",
			".LLS",
			"..SS",
		], c),
		stamp_cells([
			".L.L..",
			"LL.LL.",
			"LLLLLS",
			".SSSXX",
		], c),
	]


# Marquinhas em "v" (folhas de grama vistas de cima), tom de sombra
static func _arena_marks() -> Array:
	var c: Dictionary = {"S": P.GRASS_1}
	return [
		stamp_cells(["S.S", ".S."], c),
		stamp_cells(["S..S", ".SS."], c),
	]


static func _arena_patches() -> Array:
	var c: Color = P.GRASS_1
	return [
		blob_cells([Vector3(0, 0, 3.2), Vector3(2.5, 1.0, 2.6), Vector3(-1.5, 1.8, 2.2)], c),
		blob_cells([Vector3(0, 0, 2.8), Vector3(2.0, -1.0, 2.2)], c),
		blob_cells([Vector3(0, 0, 3.6), Vector3(-2.0, 1.5, 2.4), Vector3(2.4, 1.6, 2.0)], c),
	]


# Detalhes que cruzam a borda: iguais em todas as variantes
static func _arena_shared(img: Image, occ: PackedByteArray) -> void:
	var patches: Array = _arena_patches()
	var tufts: Array = _arena_tufts()
	var marks: Array = _arena_marks()
	var items: Array = [
		[patches[0], 30, 1],
		[tufts[0], 13, 29],
		[tufts[1], 29, 16],
		[patches[1], 17, 31],
		[marks[0], 4, 30],
		[marks[1], 30, 25],
	]
	for it: Array in items:
		draw_cells(img, it[0], it[1], it[2])
		occ_mark(occ, it[0], it[1], it[2])


static func grass_arena(variant: int) -> Image:
	var rng: RandomNumberGenerator = rng_for("grass_arena_%d" % variant)
	var best: Image = null
	for attempt: int in 60:
		var img: Image = L.new_image(N, N, P.GRASS_2)
		var occ: PackedByteArray = PackedByteArray()
		occ.resize(N * N)
		_arena_shared(img, occ)
		scatter_core(img, occ, rng, _arena_patches(), 1, 1)
		scatter_grid(img, occ, rng, _arena_tufts(), 2, 0.8, 1)
		scatter_grid(img, occ, rng, _arena_marks(), 2, 0.6, 1)
		if variant == 3:
			var fc: Dictionary = {"Y": P.FLOWER_YELLOW, "W": P.FLOWER_WHITE, "S": P.GRASS_1}
			var flowers: Array = [
				stamp_cells(["YY.", "YYS"], fc),
				stamp_cells(["WW.", "WWS"], fc),
			]
			scatter_core(img, occ, rng, flowers, 3, 1)
		best = img
		var d: Vector2 = luma_halves(img)
		if d.x <= MAX_LUMA_DIFF and d.y <= MAX_LUMA_DIFF:
			break
	return best


# ---------------------------------------------------------------------------
# Grama da mata
# ---------------------------------------------------------------------------

static func _forest_tufts() -> Array:
	var c: Dictionary = {"L": P.GRASS_1, "S": P.FGRASS_0}
	return [
		stamp_cells([
			".L..L.",
			"LLL.LL",
			".LLLLS",
			"..SSSS",
		], c),
		stamp_cells([
			"L.L.",
			"LLLL",
			".LSS",
		], c),
		stamp_cells([
			"L..L",
			"LLLS",
			".SS.",
		], c),
	]


# Mancha escura com sombra pontual azulada na borda de baixo-direita
static func _forest_blob(circles: Array) -> Array:
	var cells: Array = blob_cells(circles, P.FGRASS_0)
	var inside: Dictionary = {}
	for cell: Array in cells:
		inside[cell[0]] = true
	var out: Array = []
	for cell: Array in cells:
		var p: Vector2i = cell[0]
		var c: Color = cell[1]
		var rim: bool = not inside.has(p + Vector2i(1, 0)) or not inside.has(p + Vector2i(0, 1))
		if rim and p.x > 0 and p.y > 0:
			c = P.CANOPY_3
		out.append([p, c])
	return out


static func _forest_patches() -> Array:
	return [
		_forest_blob([Vector3(0, 0, 3.0), Vector3(2.6, 1.0, 2.4), Vector3(-2.0, 1.6, 2.0)]),
		_forest_blob([Vector3(0, 0, 2.6), Vector3(2.0, -1.0, 2.0)]),
	]


static func _forest_shared(img: Image, occ: PackedByteArray) -> void:
	var patches: Array = _forest_patches()
	var tufts: Array = _forest_tufts()
	var items: Array = [
		[patches[0], 31, 30],
		[tufts[0], 14, 30],
		[tufts[1], 30, 13],
		[patches[1], 1, 17],
		[tufts[2], 21, 1],
	]
	for it: Array in items:
		draw_cells(img, it[0], it[1], it[2])
		occ_mark(occ, it[0], it[1], it[2])


static func grass_forest(variant: int) -> Image:
	var rng: RandomNumberGenerator = rng_for("grass_forest_%d" % variant)
	var best: Image = null
	for attempt: int in 60:
		var img: Image = L.new_image(N, N, P.GRASS_0)
		var occ: PackedByteArray = PackedByteArray()
		occ.resize(N * N)
		_forest_shared(img, occ)
		scatter_core(img, occ, rng, _forest_patches(), 1, 1)
		scatter_grid(img, occ, rng, _forest_tufts(), 2, 0.85, 1)
		best = img
		var d: Vector2 = luma_halves(img)
		if d.x <= MAX_LUMA_DIFF and d.y <= MAX_LUMA_DIFF:
			break
	return best


# ---------------------------------------------------------------------------
# Terra da trilha
# ---------------------------------------------------------------------------

static func _dirt_pebbles() -> Array:
	var c: Dictionary = {"L": P.CSTONE_3, "M": P.CSTONE_2, "S": P.DIRT_1}
	return [
		stamp_cells([
			".L..",
			"LLM.",
			".MSS",
		], c),
		stamp_cells([
			"LL.",
			"MMS",
			"..S",
		], c),
	]


static func _dirt_specks() -> Array:
	var c: Dictionary = {"S": P.DIRT_1, "X": P.DIRT_0}
	return [
		stamp_cells(["SS", ".X"], c),
		stamp_cells(["S.", "SX"], c),
		stamp_cells(["SS"], c),
	]


static func _dirt_worn() -> Array:
	var worn: Color = P.DIRT_3
	return [
		blob_cells([Vector3(0, 0, 2.8), Vector3(2.2, 0.8, 2.2)], worn),
		blob_cells([Vector3(0, 0, 2.2), Vector3(-1.6, 1.0, 1.8)], worn),
	]


static func _dirt_shared(img: Image, occ: PackedByteArray) -> void:
	var worn: Array = _dirt_worn()
	var pebbles: Array = _dirt_pebbles()
	var specks: Array = _dirt_specks()
	var items: Array = [
		[worn[0], 31, 2],
		[pebbles[0], 15, 30],
		[specks[0], 30, 20],
		[specks[1], 1, 9],
		[worn[1], 22, 31],
		[specks[2], 7, 31],
	]
	for it: Array in items:
		draw_cells(img, it[0], it[1], it[2])
		occ_mark(occ, it[0], it[1], it[2])


static func dirt(variant: int) -> Image:
	var rng: RandomNumberGenerator = rng_for("dirt_%d" % variant)
	var best: Image = null
	for attempt: int in 60:
		var img: Image = L.new_image(N, N, P.DIRT_2)
		var occ: PackedByteArray = PackedByteArray()
		occ.resize(N * N)
		_dirt_shared(img, occ)
		scatter_core(img, occ, rng, _dirt_worn(), 1, 1)
		scatter_core(img, occ, rng, _dirt_pebbles(), 1, 2)
		scatter_grid(img, occ, rng, _dirt_specks(), 3, 0.5, 1)
		best = img
		var d: Vector2 = luma_halves(img)
		if d.x <= MAX_LUMA_DIFF and d.y <= MAX_LUMA_DIFF:
			break
	return best


# ---------------------------------------------------------------------------
# Lajotas de ruína
# ---------------------------------------------------------------------------

static func ruin_tile() -> Image:
	var img: Image = L.new_image(N, N, P.GRASS_0)
	var rng: RandomNumberGenerator = rng_for("ruin_tile")
	# Placas: [x0, y0, largura, altura] incluindo a junta de 2 px (direita/baixo)
	var slabs: Array = [
		[0, 0, 15, 16], [15, 0, 17, 16],
		[7, 16, 16, 16], [23, 16, 16, 16],
	]
	# Quinas gastas (raio extra) por placa: [tl, tr, bl, br]
	var worn: Array = [[1, 2, 1, 1], [1, 1, 2, 1], [2, 1, 1, 1], [1, 1, 1, 2]]
	for s_i: int in slabs.size():
		var s: Array = slabs[s_i]
		_draw_slab(img, s[0], s[1], s[2] - 2, s[3] - 2, worn[s_i])
	# Rachaduras finas saindo da borda das placas (com ramo)
	var cr: Color = P.CSTONE_1
	var cracks: Array = [
		[[4, 12], [5, 11], [5, 10], [6, 9], [7, 9], [8, 8], [6, 8], [6, 7]],
		[[28, 16], [28, 17], [29, 18], [29, 19], [30, 20], [31, 20], [28, 19], [27, 20]],
		[[22, 1], [23, 2], [24, 3], [24, 4]],
	]
	for crack: Array in cracks:
		for p: Array in crack:
			L.put_wrap(img, p[0], p[1], cr)
	# Lasca: canto mais escuro numa placa
	for p: Array in [[19, 26], [20, 26], [20, 27], [21, 27], [21, 28]]:
		L.put_wrap(img, p[0], p[1], P.CSTONE_2)
	# Grama nas juntas: tufinhos claros que avançam um pouco sobre a placa
	var gc: Dictionary = {"G": P.GRASS_1}
	var tufts: Array = [[13, 6], [5, 14], [21, 30], [30, 18], [26, 14]]
	for t: Array in tufts:
		if rng.randf() < 0.5:
			L.stamp(img, ["GG", ".G"], t[0], t[1], gc, true)
		else:
			L.stamp(img, [".G", "GG"], t[0], t[1], gc, true)
	return img


static func _draw_slab(img: Image, x0: int, y0: int, w: int, h: int, worn: Array) -> void:
	for j: int in h:
		for i: int in w:
			if not _in_worn_rect(i, j, w, h, worn):
				continue
			var c: Color = P.CSTONE_3
			var right_out: bool = not _in_worn_rect(i + 1, j, w, h, worn)
			# Espessura da placa: 2 px de sombra embaixo
			var down_out: bool = not _in_worn_rect(i, j + 1, w, h, worn) or not _in_worn_rect(i, j + 2, w, h, worn)
			var left_out: bool = not _in_worn_rect(i - 1, j, w, h, worn)
			var up_out: bool = not _in_worn_rect(i, j - 1, w, h, worn)
			if right_out or down_out:
				c = P.CSTONE_2
			elif left_out or up_out:
				c = P.CSTONE_4
			L.put_wrap(img, x0 + i, y0 + j, c)


static func _in_worn_rect(i: int, j: int, w: int, h: int, worn: Array) -> bool:
	if i < 0 or j < 0 or i >= w or j >= h:
		return false
	# Distância ao canto, com raio por quina (Manhattan: chanfro gasto)
	var rr: Array = [
		[worn[0], i, j], [worn[1], w - 1 - i, j],
		[worn[2], i, h - 1 - j], [worn[3], w - 1 - i, h - 1 - j],
	]
	for r: Array in rr:
		if r[1] + r[2] < r[0]:
			return false
	return true


# ---------------------------------------------------------------------------
# Lateral de degrau (pedra terrosa em blocos gordos)
# ---------------------------------------------------------------------------

# Blocos: [x0, y0, largura da célula, altura da célula, recuo no topo, fração da calota]
# Duas fileiras de 16 px; larguras e recuos diferentes para não parecer pão de forma
const STEP_BLOCKS: Array = [
	[0, 0, 20, 16, 0, 0.40],
	[20, 0, 12, 16, 2, 0.46],
	[9, 16, 13, 16, 1, 0.42],
	[22, 16, 19, 16, 0, 0.38],
]


static func step_side() -> Image:
	var img: Image = L.new_image(N, N, P.OUTLINE_STONE)
	var rng: RandomNumberGenerator = rng_for("step_side")
	for b: Array in STEP_BLOCKS:
		var inset: int = b[4]
		_draw_boulder(img, b[0], b[1] + inset, b[2] - 1, b[3] - 1 - inset, b[5], rng)
	return img


static func _in_round_rect(i: int, j: int, w: int, h: int, r: float) -> bool:
	if i < 0 or j < 0 or i >= w or j >= h:
		return false
	var cx: float = i + 0.5
	var cy: float = j + 0.5
	var dx: float = maxf(maxf(r - cx, 0.0), cx - (w - r))
	var dy: float = maxf(maxf(r - cy, 0.0), cy - (h - r))
	return dx * dx + dy * dy <= r * r + 0.3


static func _draw_boulder(img: Image, x0: int, y0: int, w: int, h: int, cap_frac: float, rng: RandomNumberGenerator) -> void:
	var r: float = 4.5
	var half: float = w / 2.0
	for j: int in h:
		for i: int in w:
			if not _in_round_rect(i, j, w, h, r):
				continue
			# Topo do bloco (luz) em forma de cúpula
			var u: float = (i + 0.5 - half) / half
			var cap: float = h * cap_frac * (1.0 - 0.45 * u * u)
			var c: Color = P.ESTONE_1
			if j < cap:
				c = P.ESTONE_3
			elif j < cap + 2.0:
				c = P.ESTONE_2
			# Borda de baixo/direita em sombra
			if not _in_round_rect(i + 1, j, w, h, r) or not _in_round_rect(i, j + 1, w, h, r):
				if j >= cap:
					c = P.ESTONE_0
			L.put_wrap(img, x0 + i, y0 + j, c)
	# Brilho em cima-esquerda
	var gx: int = int(w * 0.22) + rng.randi_range(0, 1)
	var gw: int = maxi(3, int(w * 0.28))
	for i: int in gw:
		L.put_wrap(img, x0 + gx + i, y0 + 1, P.ESTONE_4)
	for i: int in gw - 2:
		L.put_wrap(img, x0 + gx + i, y0 + 2, P.ESTONE_4)
	# Uma fenda curta na face
	var fx: int = rng.randi_range(int(w * 0.45), int(w * 0.7))
	var fy: int = int(h * 0.62)
	L.put_wrap(img, x0 + fx, y0 + fy, P.ESTONE_0)
	L.put_wrap(img, x0 + fx + 1, y0 + fy + 1, P.ESTONE_0)
	L.put_wrap(img, x0 + fx + 1, y0 + fy + 2, P.ESTONE_0)


# ---------------------------------------------------------------------------
# Lateral com franja de grama
# ---------------------------------------------------------------------------

static func step_side_grass(base: Image) -> Image:
	var img: Image = base.duplicate()
	# Altura da franja por coluna: faixa contínua de 4 px + "gotas" arredondadas
	var band: float = 4.0
	var depth: PackedFloat32Array = PackedFloat32Array()
	depth.resize(N)
	for x: int in N:
		depth[x] = band
	# Gotas: [centro x, meia largura, comprimento abaixo da faixa]; largas para a ponta ficar redonda
	var drops: Array = [[4.5, 4.6, 5.0], [12.5, 2.8, 3.0], [20.0, 5.4, 7.0], [28.5, 3.4, 3.4]]
	for d: Array in drops:
		for x: int in N:
			var dx: float = L.wrap_delta(x + 0.5 - d[0], float(N))
			var t: float = absf(dx) / d[1]
			if t < 1.0:
				# Perfil de superelipse: lados retos, fundo bem arredondado
				var drop_len: float = band + d[2] * pow(1.0 - pow(t, 2.6), 0.55)
				depth[x] = maxf(depth[x], drop_len)
	var bottoms: PackedInt32Array = PackedInt32Array()
	for x: int in N:
		bottoms.append(int(round(depth[x])))
	for x: int in N:
		var bottom: int = bottoms[x]
		for y: int in bottom:
			var c: Color = P.GRASS_1
			if y < 2:
				c = P.GRASS_2
			# Contorno de baixo da franja (inclui a lateral das gotas)
			var edge: bool = y >= bottom - 1
			if not edge and y >= 2:
				var l_b: int = bottoms[posmod(x - 1, N)]
				var r_b: int = bottoms[posmod(x + 1, N)]
				edge = y >= l_b or y >= r_b
			if edge:
				c = P.GRASS_0
			L.put_wrap(img, x, y, c)
	# Brilho no lado esquerdo das gotas maiores e tufinhos claros na faixa
	var tc: Dictionary = {"T": P.GRASS_2}
	L.stamp(img, ["T", "T", "T"], 2, 3, tc, true)
	L.stamp(img, ["T", "T", "T", "T"], 17, 3, tc, true)
	L.stamp(img, ["T.T", "TTT"], 9, 1, tc, true)
	L.stamp(img, ["T.T", "TTT"], 25, 1, tc, true)
	return img


# ---------------------------------------------------------------------------
# Face do muro (cantaria)
# ---------------------------------------------------------------------------

const WALL_ROWS: Array = [
	[0, 8, 0, [16, 8, 8]],
	[8, 8, 4, [8, 16, 8]],
	[16, 8, 10, [16, 16]],
	[24, 8, 2, [16, 8, 8]],
]


static func wall_face() -> Image:
	var img: Image = L.new_image(N, N, P.ESTONE_0)
	var rng: RandomNumberGenerator = rng_for("wall_face")
	var blocks: Array = []
	for row: Array in WALL_ROWS:
		var x: int = row[2]
		for bw: int in row[3]:
			blocks.append([x, row[0], bw - 1, row[1] - 1])
			x += bw
	for b: Array in blocks:
		_draw_ashlar(img, b[0], b[1], b[2], b[3], rng)
	# Musgo no topo de dois blocos
	var mc: Dictionary = {"M": P.GRASS_1, "D": P.GRASS_0}
	L.stamp(img, [
		"MMMMMM",
		"MMMMMD",
		".DMD..",
		"..D...",
	], 6, 16, mc, true)
	L.stamp(img, [
		"MMMM",
		"DMMD",
		".DD.",
	], 21, 0, mc, true)
	return img


static func _draw_ashlar(img: Image, x0: int, y0: int, w: int, h: int, rng: RandomNumberGenerator) -> void:
	for j: int in h:
		for i: int in w:
			# Quinas arredondadas: o pixel do canto vira junta
			var corner: bool = (i == 0 or i == w - 1) and (j == 0 or j == h - 1)
			if corner:
				continue
			var c: Color = P.ESTONE_2
			if j == h - 1 or i == w - 1:
				c = P.ESTONE_1
			elif j == 0 or i == 0:
				c = P.ESTONE_3
			L.put_wrap(img, x0 + i, y0 + j, c)
	# Brilho cima-esquerda
	L.put_wrap(img, x0 + 1, y0 + 1, P.ESTONE_4)
	L.put_wrap(img, x0 + 2, y0 + 1, P.ESTONE_4)
	L.put_wrap(img, x0 + 1, y0 + 2, P.ESTONE_4)
	# Detalhe: lasca/rachadura em blocos largos
	if w >= 12 and rng.randf() < 0.75:
		var fx: int = rng.randi_range(6, w - 5)
		L.put_wrap(img, x0 + fx, y0 + h - 2, P.ESTONE_1)
		L.put_wrap(img, x0 + fx + 1, y0 + h - 2, P.ESTONE_1)
		L.put_wrap(img, x0 + fx + 1, y0 + h - 3, P.ESTONE_1)


# ---------------------------------------------------------------------------
# Topo do muro
# ---------------------------------------------------------------------------

const WALL_TOP_ROWS: Array = [
	[0, 16, 0, [18, 14]],
	[16, 16, 9, [14, 18]],
]


static func wall_top() -> Image:
	var img: Image = L.new_image(N, N, P.ESTONE_1)
	for row: Array in WALL_TOP_ROWS:
		var x: int = row[2]
		for bw: int in row[3]:
			_draw_top_block(img, x, row[0], bw - 1, row[1] - 1)
			L.put_wrap(img, x + bw - 1, row[0] + row[1] - 1, P.ESTONE_0)
			x += bw
	# Rachaduras e musgo
	var cr: Color = P.ESTONE_1
	for p: Array in [[6, 6], [7, 7], [8, 7], [9, 8], [24, 23], [25, 22], [26, 22]]:
		L.put_wrap(img, p[0], p[1], cr)
	var mc: Dictionary = {"M": P.GRASS_1, "D": P.GRASS_0}
	L.stamp(img, [
		".MM.",
		"MMMD",
		"MMDD",
	], 16, 13, mc, true)
	L.stamp(img, [
		"MM",
		"MD",
	], 4, 27, mc, true)
	return img


static func _draw_top_block(img: Image, x0: int, y0: int, w: int, h: int) -> void:
	for j: int in h:
		for i: int in w:
			var corner: bool = (i == 0 or i == w - 1) and (j == 0 or j == h - 1)
			if corner:
				continue
			var c: Color = P.ESTONE_3
			if j == h - 1 or i == w - 1:
				c = P.ESTONE_2
			elif j == 0 or i == 0:
				c = P.ESTONE_4
			L.put_wrap(img, x0 + i, y0 + j, c)
	# Mancha de luz na face do bloco
	for i: int in range(2, mini(6, w - 2)):
		L.put_wrap(img, x0 + i, y0 + 2, P.ESTONE_4)
	L.put_wrap(img, x0 + 2, y0 + 3, P.ESTONE_4)
	L.put_wrap(img, x0 + 3, y0 + 3, P.ESTONE_4)


# ---------------------------------------------------------------------------
# Pedra grande (superfície sem direção)
# ---------------------------------------------------------------------------

static func rock() -> Image:
	var rng: RandomNumberGenerator = rng_for("rock")
	var best: Image = null
	for attempt: int in 80:
		var img: Image = _rock_try(rng)
		best = img
		var d: Vector2 = luma_halves(img)
		if d.x <= MAX_LUMA_DIFF and d.y <= MAX_LUMA_DIFF:
			break
	return best


static func _rock_try(rng: RandomNumberGenerator) -> Image:
	var img: Image = L.new_image(N, N, P.CSTONE_2)
	var crack: Dictionary = {}
	# Fendas longas em camadas (estratos) que atravessam o tile e fecham no mesmo y (seamless)
	var starts: Array[int] = [3, 14, 24]
	var lines: Array = []
	for li: int in starts.size():
		var y0: float = starts[li] + rng.randf_range(-1.0, 1.0)
		var pts: Array[Vector2] = [Vector2(0.0, y0)]
		var x: float = 0.0
		while x < N - 7.0:
			x += rng.randf_range(4.0, 7.0)
			pts.append(Vector2(x, y0 + rng.randf_range(-2.5, 2.5)))
		pts.append(Vector2(float(N), y0))
		lines.append(pts)
		for s_i: int in pts.size() - 1:
			for p: Vector2i in _raster_line(pts[s_i], pts[s_i + 1]):
				crack[Vector2i(posmod(p.x, N), posmod(p.y, N))] = li
	# Ramos curtos descendo das fendas
	for b: int in 4:
		var line: Array = lines[b % lines.size()]
		var a: Vector2 = line[1 + b % (line.size() - 2)]
		var dir: Vector2 = Vector2(rng.randf_range(-0.8, 0.8), 1.0).normalized()
		var e: Vector2 = a + dir * rng.randf_range(3.0, 5.0)
		for p: Vector2i in _raster_line(a, e):
			crack[Vector2i(posmod(p.x, N), posmod(p.y, N))] = 9
	for p: Vector2i in crack:
		L.put_wrap(img, p.x, p.y, P.CSTONE_1)
	# Lábio iluminado logo abaixo de cada fenda (topo da placa de baixo)
	var lips: Array[Vector2i] = []
	for p: Vector2i in crack:
		var q: Vector2i = Vector2i(p.x, posmod(p.y + 1, N))
		if not crack.has(q):
			L.put_wrap(img, q.x, q.y, P.CSTONE_3)
			lips.append(q)
	# Facetas: em um trecho de cada fenda, o topo da placa de baixo pega mais luz (2-3 px)
	for li: int in lines.size():
		var xa: int = rng.randi_range(0, N - 1)
		var wlen: int = rng.randi_range(7, 11)
		for q: Vector2i in lips:
			var above: Vector2i = Vector2i(q.x, posmod(q.y - 1, N))
			if crack.get(above, -1) != li:
				continue
			if posmod(q.x - xa, N) >= wlen:
				continue
			var depth: int = 2 if posmod(q.x - xa, N) in [0, wlen - 1] else 3
			for k: int in range(1, depth):
				var r: Vector2i = Vector2i(q.x, posmod(q.y + k, N))
				if not crack.has(r):
					L.put_wrap(img, r.x, r.y, P.CSTONE_3)
	# Trecho mais fundo numa fenda
	var deep: Array = lines[1]
	for p: Vector2i in _raster_line(deep[1], deep[2]):
		L.put_wrap(img, p.x, p.y, P.CSTONE_0)
	# Brilho raro: 2 px num lábio da primeira fenda
	var lips_set: Dictionary = {}
	for q: Vector2i in lips:
		lips_set[q] = true
	for q: Vector2i in lips:
		var right: Vector2i = Vector2i(posmod(q.x + 1, N), q.y)
		var above: Vector2i = Vector2i(q.x, posmod(q.y - 1, N))
		if lips_set.has(right) and crack.get(above, -1) == 0 and q.x > 6:
			L.put_wrap(img, q.x, q.y, P.CSTONE_4)
			L.put_wrap(img, right.x, right.y, P.CSTONE_4)
			break
	return img


# Linha de 1 px (8-conectada) entre dois pontos
static func _raster_line(a: Vector2, b: Vector2) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var n: int = int(maxf(absf(b.x - a.x), absf(b.y - a.y))) + 1
	var last: Vector2i = Vector2i(-9999, -9999)
	for i: int in n + 1:
		var q: Vector2 = a.lerp(b, float(i) / n)
		var p: Vector2i = Vector2i(floori(q.x), floori(q.y))
		if p != last:
			out.append(p)
			last = p
	return out
