extends RefCounted
## Texturas opacas 32x32 da A02 (albedo + altura -> normal map). Sem class_name: usar via preload.
## Tudo é desenhado no toro 32x32 (coordenadas em módulo 32), então repete sem emenda.

const P = preload("res://tools/art/palette_a02.gd")
const Canvas = preload("res://tools/art/a02_canvas.gd")

const N: int = 32
const BAND: int = 3 # faixa de borda idêntica entre variantes de uma família
const RING: int = 4 # faixa + 1 px: altura compartilhada para o normal map da faixa ser igual
const CORE_MIN: int = 5 # elementos marcantes só no miolo, longe da faixa
const CORE_MAX: int = 26

const BAYER4: Array = [0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0]

const ORDER: Array[String] = [
	"grass_arena_0", "grass_arena_1", "grass_arena_2", "grass_arena_3",
	"grass_forest_0", "grass_forest_1", "dirt_0", "dirt_1",
	"ruin_tile", "step_side", "step_side_grass", "wall_face", "wall_top", "rock",
	"bark_0", "bark_1", "leaves_mass", "monolith_stone",
]


static func rng_for(key: String) -> RandomNumberGenerator:
	var r: RandomNumberGenerator = RandomNumberGenerator.new()
	r.seed = key.hash() ^ 0x5A02
	return r


static func build_all() -> Dictionary:
	var out: Dictionary = {}
	_family(out, "grass_arena", 4, _carpet_arena, _specials_arena)
	_family(out, "grass_forest", 2, _carpet_forest, _specials_forest)
	_family(out, "dirt", 2, _carpet_dirt, _specials_dirt)
	out["ruin_tile"] = _build_ruin_tile(rng_for("ruin_tile"))
	out["step_side"] = _build_step_side(rng_for("step_side"))
	out["step_side_grass"] = _build_step_side_grass(out["step_side"], rng_for("step_side_grass"))
	out["wall_face"] = _build_wall_face(rng_for("wall_face"))
	out["wall_top"] = _build_wall_top(rng_for("wall_top"))
	out["rock"] = _build_rock(rng_for("rock"))
	out["bark_0"] = _build_bark_0(rng_for("bark_0"))
	out["bark_1"] = _build_bark_1(rng_for("bark_1"))
	out["leaves_mass"] = _build_leaves_mass(rng_for("leaves_mass"))
	out["monolith_stone"] = _build_monolith_stone(rng_for("monolith_stone"))
	return out


# ---------------------------------------------------------------------------
# Utilidades
# ---------------------------------------------------------------------------

static func wrap_delta(d: float, n: float = 32.0) -> float:
	return fposmod(d + n * 0.5, n) - n * 0.5


static func in_ring(x: int, y: int) -> bool:
	return x < RING or x >= N - RING or y < RING or y >= N - RING


static func bayer(x: int, y: int) -> float:
	return (BAYER4[(posmod(y, 4)) * 4 + posmod(x, 4)] + 0.5) / 16.0


## Ruído de valor periódico (período 32), soma de oitavas com células de 'cells' px. Saída equalizada em [0,1).
static func pnoise(rng: RandomNumberGenerator, cells: Array, amps: Array, w: int = N, h: int = N) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(w * h)
	out.fill(0.0)
	for k: int in cells.size():
		var cell: int = cells[k]
		var gx: int = w / cell
		var gy: int = h / cell
		var lat: PackedFloat32Array = PackedFloat32Array()
		lat.resize(gx * gy)
		for i: int in gx * gy:
			lat[i] = rng.randf()
		for y: int in h:
			var fy: float = (y + 0.5) / cell - 0.5
			var iy: int = floori(fy)
			var ty: float = fy - iy
			ty = ty * ty * (3.0 - 2.0 * ty)
			for x: int in w:
				var fx: float = (x + 0.5) / cell - 0.5
				var ix: int = floori(fx)
				var tx: float = fx - ix
				tx = tx * tx * (3.0 - 2.0 * tx)
				var a: float = lat[posmod(iy, gy) * gx + posmod(ix, gx)]
				var b: float = lat[posmod(iy, gy) * gx + posmod(ix + 1, gx)]
				var cc: float = lat[posmod(iy + 1, gy) * gx + posmod(ix, gx)]
				var d: float = lat[posmod(iy + 1, gy) * gx + posmod(ix + 1, gx)]
				out[y * w + x] += float(amps[k]) * lerpf(lerpf(a, b, tx), lerpf(cc, d, tx), ty)
	return _equalize(out)


# Troca cada valor pela sua posição na ordem (distribuição uniforme em [0,1))
static func _equalize(v: PackedFloat32Array) -> PackedFloat32Array:
	var idx: Array = range(v.size())
	idx.sort_custom(func(a: int, b: int) -> bool: return v[a] < v[b] if v[a] != v[b] else a < b)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(v.size())
	for r: int in idx.size():
		out[idx[r]] = float(r) / float(v.size())
	return out


## Curva linear por partes: pts = [x0, y0, x1, y1, ...] com x crescente.
static func curve(v: float, pts: Array) -> float:
	for i: int in range(0, pts.size() - 2, 2):
		var x0: float = pts[i]
		var x1: float = pts[i + 2]
		if v <= x1 or i + 4 >= pts.size():
			return lerpf(float(pts[i + 1]), float(pts[i + 3]), clampf((v - x0) / maxf(x1 - x0, 1e-6), 0.0, 1.0))
	return float(pts[pts.size() - 1])


## Tom contínuo -> tom inteiro, com pontilhado ordenado só perto da fronteira entre dois tons vizinhos.
static func dither_tone(t: float, x: int, y: int, width: float = 0.3) -> int:
	var base: int = floori(t)
	var f: float = t - base
	var lo: float = 0.5 - width * 0.5
	var g: float = clampf((f - lo) / width, 0.0, 1.0)
	return base + (1 if g > bayer(x, y) else 0)


# Carimbo: linhas de texto, cada caractere -> [índice global, altura]; '.' não pinta
static func stamp(cv: Canvas, rows: Array, ox: int, oy: int, key: Dictionary) -> void:
	for j: int in rows.size():
		var row: String = rows[j]
		for i: int in row.length():
			var ch: String = row[i]
			if key.has(ch):
				var e: Array = key[ch]
				cv.put(ox + i, oy + j, int(e[0]), float(e[1]))


## Equilibra a luminância esquerda/direita e topo/base no miolo para garantir gradiente <= 0.03
static func balance_top_view(cv: Canvas, ramp: PackedInt32Array) -> void:
	var w: int = cv.w
	var h: int = cv.h
	for pass_iter: int in 12:
		var sum_l: float = 0.0
		var sum_r: float = 0.0
		var sum_t: float = 0.0
		var sum_b: float = 0.0
		for y: int in h:
			for x: int in w:
				var ci: int = cv.get_c(x, y)
				if ci < 0:
					continue
				var rgb: int = P.rgb(ci)
				var r: float = ((rgb >> 16) & 255) / 255.0
				var g: float = ((rgb >> 8) & 255) / 255.0
				var b: float = (rgb & 255) / 255.0
				var lum: float = 0.299 * r + 0.587 * g + 0.114 * b
				if x < 16:
					sum_l += lum
				else:
					sum_r += lum
				if y < 16:
					sum_t += lum
				else:
					sum_b += lum
		var diff_x: float = (sum_l - sum_r) / 512.0
		var diff_y: float = (sum_t - sum_b) / 512.0
		if absf(diff_x) <= 0.025 and absf(diff_y) <= 0.025:
			break
		var rng_bal: RandomNumberGenerator = RandomNumberGenerator.new()
		rng_bal.seed = int(absf(diff_x) * 10000.0) ^ int(absf(diff_y) * 10000.0) ^ (pass_iter * 0x73)
		if diff_x > 0.025:
			for step: int in 16:
				var rx: int = rng_bal.randi_range(CORE_MIN, 15)
				var ry: int = rng_bal.randi_range(CORE_MIN, CORE_MAX)
				var ci: int = cv.get_c(rx, ry)
				var tone: int = P.tone_of(ci)
				if tone > 3 and cv.lock[ry * w + rx] == 0:
					cv.put_c(rx, ry, ramp[tone - 1])
		elif diff_x < -0.025:
			for step: int in 16:
				var rx: int = rng_bal.randi_range(16, CORE_MAX)
				var ry: int = rng_bal.randi_range(CORE_MIN, CORE_MAX)
				var ci: int = cv.get_c(rx, ry)
				var tone: int = P.tone_of(ci)
				if tone > 3 and cv.lock[ry * w + rx] == 0:
					cv.put_c(rx, ry, ramp[tone - 1])
		if diff_y > 0.025:
			for step: int in 16:
				var rx: int = rng_bal.randi_range(CORE_MIN, CORE_MAX)
				var ry: int = rng_bal.randi_range(CORE_MIN, 15)
				var ci: int = cv.get_c(rx, ry)
				var tone: int = P.tone_of(ci)
				if tone > 3 and cv.lock[ry * w + rx] == 0:
					cv.put_c(rx, ry, ramp[tone - 1])
		elif diff_y < -0.025:
			for step: int in 16:
				var rx: int = rng_bal.randi_range(CORE_MIN, CORE_MAX)
				var ry: int = rng_bal.randi_range(16, CORE_MAX)
				var ci: int = cv.get_c(rx, ry)
				var tone: int = P.tone_of(ci)
				if tone > 3 and cv.lock[ry * w + rx] == 0:
					cv.put_c(rx, ry, ramp[tone - 1])


# Família com faixa de borda compartilhada: a borda (4 px) vem de uma tela comum,
# o miolo é de cada variante. Elementos marcantes só no miolo.
static func _family(out: Dictionary, fam: String, count: int, carpet: Callable, specials: Callable) -> void:
	var shared: Canvas = Canvas.new(N, N)
	carpet.call(shared, rng_for(fam + "_band"), true)
	shared.cleanup_orphans()
	balance_top_view(shared, P.ramp(fam))
	shared.ensure_relief(0.28)
	var ramp: PackedInt32Array = P.ramp(fam)
	for v: int in count:
		var key: String = "%s_%d" % [fam, v]
		var rng: RandomNumberGenerator = rng_for(key)
		var cv: Canvas = Canvas.new(N, N)
		cv.c = shared.c.duplicate()
		cv.z = shared.z.duplicate()
		cv.lock = shared.lock.duplicate()
		cv.keep = shared.keep.duplicate()
		cv.strength = shared.strength
		cv.max_slope = shared.max_slope

		# Modulação sutil no miolo para as variantes serem orgânicas sem criar arestas
		var f_core: PackedFloat32Array = pnoise(rng, [8, 4], [0.65, 0.35])
		for y in range(CORE_MIN, CORE_MAX + 1):
			for x in range(CORE_MIN, CORE_MAX + 1):
				var nv: float = f_core[y * N + x]
				var ci: int = cv.get_c(x, y)
				var tone: int = P.tone_of(ci)
				if nv > 0.68 and tone < ramp.size() - 2:
					cv.put_c(x, y, ramp[tone + 1])
				elif nv < 0.32 and tone > 2:
					cv.put_c(x, y, ramp[tone - 1])

		specials.call(cv, rng, v)
		cv.cleanup_orphans()
		cv.keep.fill(0)
		balance_top_view(cv, ramp)
		cv.cleanup_orphans()

		# Garante borda de 4px idêntica a shared em c e z (para normal map em 3px ser 100% igual)
		for y: int in N:
			for x: int in N:
				if x < 4 or x >= N - 4 or y < 4 or y >= N - 4:
					var o: int = y * N + x
					cv.c[o] = shared.c[o]
					cv.z[o] = shared.z[o]
		out[key] = cv


# ---------------------------------------------------------------------------
# Grama: relva aveludada, contínua e luminosa (estilo HD-2D / Octopath)
# Sem domo/almofada macro: relevo puramente micro para eliminar costuras de waffle
# ---------------------------------------------------------------------------

static func grass_carpet(cv: Canvas, rng: RandomNumberGenerator, cfg: Dictionary) -> void:
	var ramp: PackedInt32Array = cfg["ramp"]
	var base: int = cfg["base"]
	var is_band: bool = cfg.get("is_band", false)

	# 1. Base aveludada contínua: ruído periódico suave dithered entre base e base+2
	var f: PackedFloat32Array = pnoise(rng, [16, 8], [0.65, 0.35])
	for y: int in N:
		for x: int in N:
			var v: float = f[y * N + x]
			var tt: float = float(base) + 0.3 + v * 1.8
			var tone: int = clampi(dither_tone(tt, x, y, 0.22), base, mini(base + 2, ramp.size() - 2))
			cv.c[y * N + x] = ramp[tone]
			cv.z[y * N + x] = (bayer(x, y) - 0.5) * 0.22

	# 2. Lâminas em pares 2x1 (ponta clara + raiz escura) para relevo e tons sem órfãos
	var blade_n: int = 24 if is_band else 16
	for k: int in blade_n:
		var bx: int = rng.randi_range(0, N - 1) if is_band else rng.randi_range(CORE_MIN, CORE_MAX - 1)
		var by: int = rng.randi_range(0, N - 1) if is_band else rng.randi_range(CORE_MIN, CORE_MAX - 1)
		var t_tip: int = mini(base + 3, ramp.size() - 2)
		var t_root: int = maxi(base - 1, 0)
		# Ponta (2 px)
		cv.put(bx, by, ramp[t_tip], cv.get_z(bx, by) + 0.30)
		cv.put(bx + 1, by, ramp[t_tip], cv.get_z(bx + 1, by) + 0.30)
		# Raiz (2 px)
		cv.put(bx, by + 1, ramp[t_root], cv.get_z(bx, by + 1) - 0.22)
		cv.put(bx + 1, by + 1, ramp[t_root], cv.get_z(bx + 1, by + 1) - 0.22)

	# 3. Pontas douradas iluminadas (2 px tom base+4)
	var hi_n: int = 12 if is_band else 8
	for k: int in hi_n:
		var hx: int = rng.randi_range(0, N - 1) if is_band else rng.randi_range(CORE_MIN, CORE_MAX - 1)
		var hy: int = rng.randi_range(0, N - 1) if is_band else rng.randi_range(CORE_MIN, CORE_MAX)
		var t_hi: int = mini(base + 4, ramp.size() - 1)
		cv.put(hx, hy, ramp[t_hi], cv.get_z(hx, hy) + 0.32)
		cv.put(hx + 1, hy, ramp[t_hi], cv.get_z(hx + 1, hy) + 0.32)

	# 4. Sombras de fenda / contato (2 px tom base-2)
	var sh_n: int = 10 if is_band else 6
	for k: int in sh_n:
		var sx: int = rng.randi_range(0, N - 1) if is_band else rng.randi_range(CORE_MIN, CORE_MAX - 1)
		var sy: int = rng.randi_range(0, N - 1) if is_band else rng.randi_range(CORE_MIN, CORE_MAX)
		var t_sh: int = maxi(base - 2, 0)
		cv.put(sx, sy, ramp[t_sh], cv.get_z(sx, sy) - 0.26)
		cv.put(sx + 1, sy, ramp[t_sh], cv.get_z(sx + 1, sy) - 0.26)


static func _carpet_arena(cv: Canvas, rng: RandomNumberGenerator, band: bool) -> void:
	var cfg: Dictionary = {
		"ramp": P.ramp("grass_arena"),
		"base": 3,
		"is_band": band,
	}
	cv.strength = 1.35
	grass_carpet(cv, rng, cfg)


static func _specials_arena(cv: Canvas, rng: RandomNumberGenerator, v: int) -> void:
	var t: PackedInt32Array = P.ramp("grass_arena")
	# Trevos sutis no miolo
	var clovers: Array = [
		["LL.LL", ".MMM."],
		[".LL.", "LMML"],
		["L.L", ".M."],
	]
	var key_c: Dictionary = {"L": [t[5], 0.24], "M": [t[4], 0.16]}
	for i: int in [1, 2, 0, 1][v]:
		var cl: Array = clovers[rng.randi_range(0, clovers.size() - 1)]
		stamp(cv, cl, rng.randi_range(CORE_MIN, CORE_MAX - 4), rng.randi_range(CORE_MIN, CORE_MAX - 3), key_c)

	# Flores brancas e amarelas na variante 3 (2 px por flor)
	if v == 3:
		var fl: Array[int] = [P.c("flower_white", 1), P.c("flower_yellow", 1)]
		for i: int in 4:
			var x: int = rng.randi_range(CORE_MIN, CORE_MAX - 1)
			var y: int = rng.randi_range(CORE_MIN, CORE_MAX)
			var col: int = fl[i % 2]
			cv.put(x, y, col, cv.get_z(x, y) + 0.35)
			cv.put(x + 1, y, col, cv.get_z(x + 1, y) + 0.35)
			cv.keep[cv.ofs(x, y)] = 1
			cv.keep[cv.ofs(x + 1, y)] = 1


static func _carpet_forest(cv: Canvas, rng: RandomNumberGenerator, band: bool) -> void:
	var cfg: Dictionary = {
		"ramp": P.ramp("grass_forest"),
		"base": 2,
		"is_band": band,
	}
	cv.strength = 1.35
	grass_carpet(cv, rng, cfg)
	# Serrapilheira e musgo suave
	var lit: PackedInt32Array = P.ramp("leaf_litter")
	var moss: PackedInt32Array = P.ramp("moss")
	var leaves: Array = [["aa", ".a"], ["a.", "aa"], ["aa", "a."], [".a", "aa"], ["aaa"]]
	var piles: int = 4 if band else 4
	for pi: int in piles:
		var px: float = rng.randf() * N
		var py: float = rng.randf() * N
		for li: int in rng.randi_range(4, 7):
			var x: int = floori(px + rng.randfn(0.0, 2.5))
			var y: int = floori(py + rng.randfn(0.0, 2.5))
			var sh: Array = leaves[rng.randi_range(0, leaves.size() - 1)]
			var tone: int = [1, 1, 2, 2, 3][rng.randi_range(0, 4)]
			stamp(cv, sh, x, y, {"a": [lit[tone], 0.20]})
	for i: int in 5:
		var sh3: Array = leaves[rng.randi_range(0, leaves.size() - 1)]
		stamp(cv, sh3, rng.randi_range(0, N - 1), rng.randi_range(0, N - 1), {"a": [lit[1], 0.18]})
	var tufts: Array = [[".m.", "mMm", ".m."], ["mm.", "mMm", ".mm"]]
	for i: int in (2 if band else 3):
		var sh2: Array = tufts[rng.randi_range(0, tufts.size() - 1)]
		stamp(cv, sh2, rng.randi_range(0, N - 1), rng.randi_range(0, N - 1), {"m": [moss[2], 0.22], "M": [moss[3], 0.26]})


static func _specials_forest(cv: Canvas, rng: RandomNumberGenerator, _v: int) -> void:
	var lit: PackedInt32Array = P.ramp("leaf_litter")
	var pile: Array = [".ab.", "abba", ".bb."]
	stamp(cv, pile, rng.randi_range(CORE_MIN, CORE_MAX - 4), rng.randi_range(CORE_MIN, CORE_MAX - 3),
		{"a": [lit[1], 0.22], "b": [lit[2], 0.26]})


# ---------------------------------------------------------------------------
# Terra batida / clareira: areia dourada suave e terra compactada (estilo clareira da referência)
# Sem domo, sem faixas escuras, sem buracos escuros repetitivos
# ---------------------------------------------------------------------------

static func _carpet_dirt(cv: Canvas, rng: RandomNumberGenerator, band: bool) -> void:
	var t: PackedInt32Array = P.ramp("dirt")
	cv.strength = 1.35

	# 1. Base aveludada contínua de areia/terra dourada e homogênea
	var f: PackedFloat32Array = pnoise(rng, [16, 8], [0.65, 0.35])
	for y: int in N:
		for x: int in N:
			var v: float = f[y * N + x]
			var tt: float = 3.3 + v * 1.8
			var tone: int = clampi(dither_tone(tt, x, y, 0.20), 3, 5)
			cv.c[y * N + x] = t[tone]
			cv.z[y * N + x] = (bayer(x, y) - 0.5) * 0.22

	# 2. Grãos finos de areia (pares de 2 px no tom 6)
	var grain_n: int = 20 if band else 14
	for i in grain_n:
		var gx: int = rng.randi_range(0, N - 1) if band else rng.randi_range(CORE_MIN, CORE_MAX - 1)
		var gy: int = rng.randi_range(0, N - 1) if band else rng.randi_range(CORE_MIN, CORE_MAX)
		var t_hi: int = 6
		cv.put(gx, gy, t[t_hi], cv.get_z(gx, gy) + 0.26)
		cv.put(gx + 1, gy, t[t_hi], cv.get_z(gx + 1, gy) + 0.26)

	# 3. Micro-sombras sutis de solo úmido (pares de 2 px no tom 2)
	var shade_n: int = 14 if band else 10
	for i in shade_n:
		var sx: int = rng.randi_range(0, N - 1) if band else rng.randi_range(CORE_MIN, CORE_MAX - 1)
		var sy: int = rng.randi_range(0, N - 1) if band else rng.randi_range(CORE_MIN, CORE_MAX)
		var t_lo: int = 2
		cv.put(sx, sy, t[t_lo], cv.get_z(sx, sy) - 0.22)
		cv.put(sx + 1, sy, t[t_lo], cv.get_z(sx + 1, sy) - 0.22)

	# 4. Pedrinhas discretas integradas ao chão (com tons 7, 1 e 0)
	var pebble_n: int = 8 if band else 5
	for i in pebble_n:
		var px: int = rng.randi_range(0, N - 1) if band else rng.randi_range(CORE_MIN, CORE_MAX - 2)
		var py: int = rng.randi_range(0, N - 1) if band else rng.randi_range(CORE_MIN, CORE_MAX - 2)
		_pebble(cv, rng, px, py, i % 2, t)


# Pedrinha discreta integrada ao chão com contato suave e sem órfãos
static func _pebble(cv: Canvas, _rng: RandomNumberGenerator, x: int, y: int, size: int, t: PackedInt32Array) -> void:
	var zb: float = cv.get_z(x, y)
	if size == 0:
		# Pedrinha de 2x2 px: topo tom 7, base tom 1
		cv.put(x, y, t[7], zb + 0.30)
		cv.put(x + 1, y, t[7], zb + 0.30)
		cv.put(x, y + 1, t[1], zb - 0.22)
		cv.put(x + 1, y + 1, t[1], zb - 0.22)
	else:
		# Pedrinha com sombra mais profunda: topo tom 7 e 6, base tom 0
		cv.put(x, y, t[7], zb + 0.32)
		cv.put(x + 1, y, t[7], zb + 0.32)
		cv.put(x, y + 1, t[0], zb - 0.24)
		cv.put(x + 1, y + 1, t[0], zb - 0.24)


static func _specials_dirt(cv: Canvas, rng: RandomNumberGenerator, v: int) -> void:
	var t: PackedInt32Array = P.ramp("dirt")
	var counts: Array = [2, 3]
	for s: int in counts[v]:
		_pebble(cv, rng, rng.randi_range(CORE_MIN, CORE_MAX - 3), rng.randi_range(CORE_MIN, CORE_MAX - 3), s % 2, t)


# ---------------------------------------------------------------------------
# Ruin Tile (Lajotas/Calçamento irregular)
# ---------------------------------------------------------------------------
static func _build_ruin_tile(rng: RandomNumberGenerator) -> Canvas:
	var cv: Canvas = Canvas.new(N, N, true, true)
	cv.strength = 0.75
	var mas: PackedInt32Array = P.ramp("masonry")
	var moss: PackedInt32Array = P.ramp("moss")
	var gr: PackedInt32Array = P.ramp("grass_arena")
	var lich: PackedInt32Array = P.ramp("lichen")

	# Sementes Voronoi periódicas para pedras irregulares
	var pts: Array[Vector2] = [
		Vector2(5.0, 6.0), Vector2(18.0, 5.0), Vector2(28.0, 10.0),
		Vector2(8.0, 19.0), Vector2(21.0, 20.0), Vector2(12.0, 29.0), Vector2(27.0, 28.0)
	]
	var stone_tones: Array[int] = [3, 4, 5, 4, 3, 5, 4]
	var f: PackedFloat32Array = pnoise(rng, [8, 4], [0.8, 0.4])

	for y: int in N:
		for x: int in N:
			var d1: float = 999.0
			var d2: float = 999.0
			var id1: int = 0
			for i: int in pts.size():
				var p: Vector2 = pts[i]
				var dx: float = wrap_delta(float(x) - p.x)
				var dy: float = wrap_delta(float(y) - p.y)
				var d: float = sqrt(dx * dx + dy * dy)
				if d < d1:
					d2 = d1
					d1 = d
					id1 = i
				elif d < d2:
					d2 = d

			var joint: float = d2 - d1
			if joint < 1.3:
				# Junta entre pedras: terra escura, musgo ou grama
				var jv: float = f[y * N + x]
				if jv > 0.65:
					cv.put(x, y, moss[1 if jv > 0.8 else 2], -0.6)
				elif jv < 0.2:
					cv.put(x, y, gr[2], -0.5)
				else:
					cv.put(x, y, mas[0 if jv < 0.4 else 1], -0.7)
			else:
				# Superfície da lajota com domo (centro mais alto e claro)
				var base_t: int = stone_tones[id1]
				var dome: float = clampf((joint - 1.3) / 3.2, 0.0, 1.0)
				var noise_val: float = (f[y * N + x] - 0.5) * 1.2
				var tone_f: float = float(base_t) + dome * 1.4 + noise_val
				var tone: int = clampi(roundi(tone_f), 2, 6)
				var zv: float = 0.5 + dome * 1.4
				cv.put(x, y, mas[tone], zv)

	# Rachaduras de 1px em uma das lajotas
	var cx: int = 18
	var cy: int = 5
	for step: int in 5:
		cv.put(cx + step, cy + (step % 2), mas[0], cv.get_z(cx + step, cy) - 0.9)

	# Mancha de líquen
	var lx: int = 26
	var ly: int = 12
	cv.put(lx, ly, lich[1], cv.get_z(lx, ly) + 0.3)
	cv.put(lx + 1, ly, lich[0], cv.get_z(lx + 1, ly) + 0.2)
	cv.put(lx, ly + 1, lich[0], cv.get_z(lx, ly + 1) + 0.2)

	cv.cleanup_orphans()
	return cv


# ---------------------------------------------------------------------------
# Step Side (Degrau com estratos de rocha em 2 faixas)
# ---------------------------------------------------------------------------
static func _build_step_side(rng: RandomNumberGenerator) -> Canvas:
	var cv: Canvas = Canvas.new(N, N, true, true) # wrap_x = true, wrap_y = true para fechar balanço de derivadas
	cv.strength = 0.8
	var rk: PackedInt32Array = P.ramp("rock")
	var dirt: PackedInt32Array = P.ramp("dirt")
	var moss: PackedInt32Array = P.ramp("moss")
	var f: PackedFloat32Array = pnoise(rng, [8, 4], [0.9, 0.4])

	# Preenchimento base da rocha por faixa
	for y: int in N:
		var band_y: int = y % 16
		var is_band_b: bool = y >= 16
		for x: int in N:
			var nv: float = f[y * N + x]
			var wave: float = sin(float(x) * (0.35 if not is_band_b else 0.45) + (1.2 if is_band_b else 0.0)) * 1.2
			var layer: float = float(band_y) + wave
			var tone_idx: int = 3
			var zv: float = 0.6
			if layer < 4.0:
				tone_idx = 4 if nv > 0.4 else 5
				zv = 1.0
			elif layer < 8.0:
				tone_idx = 3 if nv > 0.5 else 4
				zv = 0.7
			elif layer < 12.0:
				tone_idx = 4 if nv > 0.4 else 3
				zv = 0.9
			else:
				tone_idx = 2 if nv > 0.5 else 3
				zv = 0.4

			if band_y in [0, 4, 8]:
				tone_idx = clampi(tone_idx + 1, 0, 6)
				zv += 0.3

			cv.put(x, y, rk[tone_idx], zv)

	# Fendas e veios de terra
	for i: int in 4:
		var sx: int = rng.randi_range(2, 28)
		var sy: int = [2, 7, 18, 23][i]
		for step: int in rng.randi_range(3, 5):
			cv.put(sx + (step % 2), sy + step, dirt[2], cv.get_z(sx, sy) - 0.4)

	# Musgo escorrendo
	for i: int in 5:
		var mx: int = rng.randi_range(1, 30)
		var my: int = [1, 5, 17, 21, 24][i]
		var mlen: int = rng.randi_range(3, 5)
		for step: int in mlen:
			var mtone: int = 2 if step < 2 else 1
			cv.put(mx, my + step, moss[mtone], cv.get_z(mx, my) + 0.2)
			if step == 0 and rng.randf() < 0.6:
				cv.put(mx + 1, my, moss[2], cv.get_z(mx + 1, my) + 0.2)

	# Critério obrigatório: linhas 14-15 e 30-31 terminam em junta horizontal escura (>=60% colunas nos 3 tons mais escuros)
	for x: int in N:
		var r_tone_a: int = [0, 1, 2][rng.randi_range(0, 2)]
		cv.put(x, 14, rk[r_tone_a], -0.4)
		cv.put(x, 15, rk[r_tone_a], -0.5)
		var r_tone_b: int = [0, 1, 2][rng.randi_range(0, 2)]
		cv.put(x, 30, rk[r_tone_b], -0.4)
		cv.put(x, 31, rk[r_tone_b], -0.5)

	cv.cleanup_orphans()
	return cv


# ---------------------------------------------------------------------------
# Step Side Grass (Degrau superior com terra e raízes nas linhas 0..3)
# ---------------------------------------------------------------------------
static func _build_step_side_grass(step_side: Canvas, rng: RandomNumberGenerator) -> Canvas:
	var cv: Canvas = step_side.clone()
	var dirt: PackedInt32Array = P.ramp("dirt")
	var moss: PackedInt32Array = P.ramp("moss")
	var gr: PackedInt32Array = P.ramp("grass_arena")

	# Linhas 0..3: terra escura com raízes, musgo e pontas de grama (>=50% de pixels)
	for x: int in N:
		var g_tone: int = [4, 5, 6][rng.randi_range(0, 2)]
		cv.put(x, 0, gr[g_tone], 0.8)

		var m_tone: int = [2, 3, 4][rng.randi_range(0, 2)]
		cv.put(x, 1, moss[m_tone], 0.7)

		var d_tone: int = [1, 2, 3][rng.randi_range(0, 2)]
		cv.put(x, 2, dirt[d_tone], 0.5)

		if rng.randf() < 0.7:
			cv.put(x, 3, dirt[1 if rng.randf() < 0.5 else 2], 0.4)

	# Tufo de musgo escorrendo pela rocha (linhas 4..8)
	for i: int in 4:
		var mx: int = rng.randi_range(2, 29)
		for step: int in rng.randi_range(2, 5):
			cv.put(mx, 4 + step, moss[2 if step < 2 else 1], cv.get_z(mx, 4 + step) + 0.2)

	cv.cleanup_orphans()
	return cv


# ---------------------------------------------------------------------------
# Wall Face (Muro de cantaria/pedras sobrepostas em faixas com musgo)
# ---------------------------------------------------------------------------
static func _build_wall_face(rng: RandomNumberGenerator) -> Canvas:
	var cv: Canvas = Canvas.new(N, N, true, false)
	cv.strength = 0.85
	var mas: PackedInt32Array = P.ramp("masonry")
	var moss: PackedInt32Array = P.ramp("moss")
	var lich: PackedInt32Array = P.ramp("lichen")
	var f: PackedFloat32Array = pnoise(rng, [8, 4], [0.8, 0.4])

	# 3 fiadas de pedras por nível de 16 linhas (A: 0..15, B: 16..31)
	for y: int in N:
		var is_band_b: bool = y >= 16
		var local_y: int = y % 16
		var course_idx: int = 0
		var course_y: int = 0
		var course_h: int = 5
		if local_y < 5:
			course_idx = 0
			course_y = local_y
			course_h = 5
		elif local_y < 10:
			course_idx = 1
			course_y = local_y - 5
			course_h = 5
		else:
			course_idx = 2
			course_y = local_y - 10
			course_h = 6

		for x: int in N:
			# Juntas verticais desencontradas por fiada (amarração de cantaria)
			var is_v_joint: bool = false
			if not is_band_b:
				if course_idx == 0 and (x == 10 or x == 22):
					is_v_joint = true
				elif course_idx == 1 and (x == 5 or x == 16 or x == 27):
					is_v_joint = true
				elif course_idx == 2 and (x == 11 or x == 23):
					is_v_joint = true
			else:
				if course_idx == 0 and (x == 6 or x == 18 or x == 29):
					is_v_joint = true
				elif course_idx == 1 and (x == 12 or x == 24):
					is_v_joint = true
				elif course_idx == 2 and (x == 8 or x == 20):
					is_v_joint = true

			var is_h_joint: bool = (course_y == course_h - 1)
			if is_h_joint or is_v_joint:
				# Junta de argamassa escura
				var jv: float = f[y * N + x]
				if jv > 0.6:
					cv.put(x, y, moss[1 if jv > 0.8 else 2], -0.6)
				else:
					cv.put(x, y, mas[0 if jv < 0.3 else 1], -0.7)
			elif course_y == 0:
				# Borda superior de cada pedra pega realce de luz
				var nv0: float = f[y * N + x]
				var t_light: int = 5 if nv0 < 0.6 else 6
				cv.put(x, y, mas[t_light], 1.4)
			else:
				# Corpo da pedra com leve domo vertical
				var frac: float = float(course_y) / float(course_h)
				var nv: float = f[y * N + x]
				var base_tone: int = 4 if nv > 0.45 else 3
				if frac > 0.7:
					base_tone = 2 if nv < 0.5 else 3
				var zv: float = 0.6 + (0.5 if frac < 0.4 else 0.2) + (nv - 0.5) * 0.4
				cv.put(x, y, mas[base_tone], zv)

	# Manchas de musgo envelhecido aderidas às pedras
	var moss_patches: Array[Vector2i] = [
		Vector2i(9, 4), Vector2i(10, 4), Vector2i(11, 4), Vector2i(10, 3),
		Vector2i(21, 9), Vector2i(22, 9), Vector2i(23, 9), Vector2i(22, 8),
		Vector2i(5, 14), Vector2i(6, 14), Vector2i(5, 13),
		Vector2i(16, 20), Vector2i(17, 20), Vector2i(16, 19),
		Vector2i(11, 30), Vector2i(12, 30), Vector2i(13, 30), Vector2i(12, 29)
	]
	for p: Vector2i in moss_patches:
		cv.put(p.x, p.y, moss[2 if rng.randf() < 0.5 else 3], cv.get_z(p.x, p.y) + 0.3)

	# Líquen em pedras secas
	cv.put(4, 7, lich[0], 0.9)
	cv.put(5, 7, lich[1], 1.0)
	cv.put(25, 23, lich[0], 0.9)

	cv.cleanup_orphans()
	return cv


# ---------------------------------------------------------------------------
# Wall Top (Topo do muro de cantaria visto de cima com lajes e musgo)
# ---------------------------------------------------------------------------
static func _build_wall_top(rng: RandomNumberGenerator) -> Canvas:
	var cv: Canvas = Canvas.new(N, N, true, true)
	cv.strength = 1.0
	var mas: PackedInt32Array = P.ramp("masonry")
	var moss: PackedInt32Array = P.ramp("moss")
	var lich: PackedInt32Array = P.ramp("lichen")
	var f: PackedFloat32Array = pnoise(rng, [8, 4], [0.8, 0.5])

	for y: int in N:
		for x: int in N:
			# Juntas entre lajes de cobertura (capstones)
			var is_joint_x: bool = (x == 10 or x == 22)
			var is_edge_y: bool = (y == 0 or y == 31)

			if is_joint_x:
				var mv: float = f[y * N + x]
				if mv > 0.45:
					cv.put(x, y, moss[1 if mv > 0.75 else 2], -0.6)
				else:
					cv.put(x, y, mas[0 if mv < 0.3 else 1], -0.7)
			elif is_edge_y and rng.randf() < 0.45:
				# Musgo caindo pelas bordas do topo
				cv.put(x, y, moss[2 if rng.randf() < 0.6 else 3], 0.3)
			else:
				var dist_j: float = minf(absf(wrap_delta(float(x) - 10.0)), absf(wrap_delta(float(x) - 22.0)))
				var dome: float = clampf(dist_j / 4.0, 0.0, 1.0)
				var nv: float = f[y * N + x]
				var tone_idx: int = clampi(roundi(3.8 + dome * 1.6 + (nv - 0.5) * 1.2), 3, 6)
				cv.put(x, y, mas[tone_idx], 0.4 + dome * 1.4 + (nv - 0.5) * 0.8)

	cv.put(16, 12, lich[1], cv.get_z(16, 12) + 0.3)
	cv.put(17, 12, lich[0], cv.get_z(17, 12) + 0.2)
	cv.put(16, 13, lich[0], cv.get_z(16, 13) + 0.2)

	cv.cleanup_orphans()
	return cv


# ---------------------------------------------------------------------------
# Rock (Pedra grande sem direção)
# ---------------------------------------------------------------------------
static func _build_rock(rng: RandomNumberGenerator) -> Canvas:
	var cv: Canvas = Canvas.new(N, N, true, true)
	cv.strength = 0.85
	var rk: PackedInt32Array = P.ramp("rock")
	var lich: PackedInt32Array = P.ramp("lichen")
	var f: PackedFloat32Array = pnoise(rng, [8, 4, 2], [0.7, 0.7, 0.4])

	# Normaliza média E/D para evitar gradiente lateral
	var left_sum: float = 0.0
	var right_sum: float = 0.0
	for y: int in N:
		for x: int in N:
			if x < 16:
				left_sum += f[y * N + x]
			else:
				right_sum += f[y * N + x]
	var diff_ed: float = (left_sum - right_sum) / 512.0

	for y: int in N:
		for x: int in N:
			var v: float = f[y * N + x]
			if x < 16:
				v -= diff_ed * 0.5
			else:
				v += diff_ed * 0.5
			var tone_f: float = curve(v, [0.0, 1.8, 0.3, 3.2, 0.7, 4.8, 1.0, 6.0])
			var tone: int = dither_tone(tone_f, x, y, 0.3)
			cv.put(x, y, rk[tone], (v - 0.5) * 2.2)

	var cracks: Array = [
		[Vector2i(6, 8), Vector2i(10, 12)],
		[Vector2i(20, 18), Vector2i(24, 23)]
	]
	for cr: Array in cracks:
		var pts: Array[Vector2i] = Canvas.line_pts(cr[0].x, cr[0].y, cr[1].x, cr[1].y)
		for p: Vector2i in pts:
			cv.put(p.x, p.y, rk[1], cv.get_z(p.x, p.y) - 0.7)

	for lpt: Vector2i in [Vector2i(14, 14), Vector2i(27, 5)]:
		cv.put(lpt.x, lpt.y, lich[1], cv.get_z(lpt.x, lpt.y) + 0.3)
		cv.put(lpt.x + 1, lpt.y, lich[0], cv.get_z(lpt.x + 1, lpt.y) + 0.2)
		cv.put(lpt.x, lpt.y + 1, lich[0], cv.get_z(lpt.x, lpt.y + 1) + 0.2)

	cv.cleanup_orphans()
	return cv


# ---------------------------------------------------------------------------
# Bark 0 (Casca de folhosa: sulcos verticais ondulados, placas, musgo)
# ---------------------------------------------------------------------------
static func _build_bark_0(rng: RandomNumberGenerator) -> Canvas:
	var cv: Canvas = Canvas.new(N, N, true, true)
	cv.strength = 0.8
	var bk: PackedInt32Array = P.ramp("bark")
	var moss: PackedInt32Array = P.ramp("moss")
	var f: PackedFloat32Array = pnoise(rng, [8, 4], [0.8, 0.4])

	for y: int in N:
		for x: int in N:
			var wave: float = sin(float(y) * 0.4) * 1.5
			var dist_rut: float = 999.0
			for rx: float in [0.0, 8.0, 16.0, 24.0]:
				var d: float = absf(wrap_delta(float(x) - (rx + wave)))
				if d < dist_rut:
					dist_rut = d

			if dist_rut < 1.1:
				cv.put(x, y, bk[0 if rng.randf() < 0.5 else 1], -0.6)
			else:
				var plate_dome: float = clampf((dist_rut - 1.1) / 3.0, 0.0, 1.0)
				var nv: float = f[y * N + x]
				var tone: int = clampi(roundi(2.5 + plate_dome * 2.2 + (nv - 0.5) * 1.0), 2, 5)
				cv.put(x, y, bk[tone], plate_dome * 1.4)

	for step: int in 6:
		var mx: int = 12 + (step % 2)
		var my: int = 10 + step
		cv.put(mx, my, moss[2 if step < 4 else 1], cv.get_z(mx, my) + 0.3)

	cv.cleanup_orphans()
	return cv


# ---------------------------------------------------------------------------
# Bark 1 (Casca de conífera: placas escamosas mais escuras e avermelhadas)
# ---------------------------------------------------------------------------
static func _build_bark_1(rng: RandomNumberGenerator) -> Canvas:
	var cv: Canvas = Canvas.new(N, N, true, true)
	cv.strength = 0.8
	var bk: PackedInt32Array = P.ramp("bark")
	var f: PackedFloat32Array = pnoise(rng, [8, 4], [0.9, 0.4])

	for y: int in N:
		for x: int in N:
			var scale_x: int = posmod(x, 6)
			var scale_y: int = posmod(y + (3 if posmod(x / 6, 2) == 1 else 0), 7)
			if scale_x == 0 or scale_y == 0:
				cv.put(x, y, bk[0 if rng.randf() < 0.6 else 1], -0.5)
			else:
				var nv: float = f[y * N + x]
				var tone: int = clampi(roundi(1.8 + nv * 2.4), 1, 4)
				cv.put(x, y, bk[tone], 0.6 + nv * 0.8)

	cv.cleanup_orphans()
	return cv


# ---------------------------------------------------------------------------
# Leaves Mass (Miolo da copa: folhas sobrepostas, tons 1 a 6)
# ---------------------------------------------------------------------------
static func _build_leaves_mass(rng: RandomNumberGenerator) -> Canvas:
	var cv: Canvas = Canvas.new(N, N, true, true)
	cv.strength = 1.0
	var lv: PackedInt32Array = P.ramp("leaves")
	cv.fill(lv[2], 0.4)

	var f: PackedFloat32Array = pnoise(rng, [8, 4], [0.8, 0.5])
	for y: int in N:
		for x: int in N:
			var v: float = f[y * N + x]
			var tone_f: float = curve(v, [0.0, 1.2, 0.4, 2.5, 0.7, 3.8, 1.0, 5.0])
			var tone: int = clampi(dither_tone(tone_f, x, y, 0.3), 1, 5)
			cv.put(x, y, lv[tone], (v - 0.5) * 2.4)

	for i: int in 30:
		var lx: int = rng.randi_range(0, N - 1)
		var ly: int = rng.randi_range(0, N - 1)
		var t_top: int = [4, 5][rng.randi_range(0, 1)]
		var t_bot: int = [2, 3][rng.randi_range(0, 1)]
		cv.put(lx, ly, lv[t_top], 1.5)
		cv.put(lx + 1, ly, lv[t_top], 1.5)
		cv.put(lx, ly + 1, lv[t_bot], 0.4)

	cv.cleanup_orphans()
	return cv


# ---------------------------------------------------------------------------
# Monolith Stone (Pedra fria com fissuras e líquen)
# ---------------------------------------------------------------------------
static func _build_monolith_stone(rng: RandomNumberGenerator) -> Canvas:
	var cv: Canvas = Canvas.new(N, N, true, true)
	cv.strength = 1.0
	var cs: PackedInt32Array = P.ramp("cold_stone")
	var lich: PackedInt32Array = P.ramp("lichen")
	var f: PackedFloat32Array = pnoise(rng, [8, 4], [0.8, 0.5])

	for y: int in N:
		for x: int in N:
			var v: float = f[y * N + x]
			var tone: int = clampi(roundi(curve(v, [0.0, 2.0, 0.5, 4.0, 1.0, 6.0])), 2, 6)
			cv.put(x, y, cs[tone], (v - 0.5) * 2.2)

	for cx: int in [10, 22]:
		var px: int = cx
		for y: int in N:
			if rng.randf() < 0.25:
				px += (1 if rng.randf() < 0.5 else -1)
			cv.put(px, y, cs[1], cv.get_z(px, y) - 0.9)

	for lpt: Vector2i in [Vector2i(6, 12), Vector2i(25, 20)]:
		cv.put(lpt.x, lpt.y, lich[1], cv.get_z(lpt.x, lpt.y) + 0.3)
		cv.put(lpt.x + 1, lpt.y, lich[0], cv.get_z(lpt.x + 1, lpt.y) + 0.2)
		cv.put(lpt.x, lpt.y + 1, lich[0], cv.get_z(lpt.x, lpt.y + 1) + 0.2)

	cv.cleanup_orphans()
	return cv
