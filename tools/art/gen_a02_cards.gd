extends RefCounted
## Cartões com alfa recortado da A02 (folhagem, coníferas, franja, capim, flores, runas).
## Sem class_name: usar via preload.

const P = preload("res://tools/art/palette_a02.gd")
const Canvas = preload("res://tools/art/a02_canvas.gd")

const ORDER: Array[String] = [
	"leaf_0", "leaf_1", "leaf_2", "leaf_3", "leaf_flower_0",
	"conifer_tier_0", "conifer_tier_1",
	"grass_fringe_0", "grass_fringe_1",
	"grass_tuft_0", "grass_tuft_1", "grass_tuft_2",
	"flower_0", "flower_1", "flower_2",
	"rune_0", "rune_1", "rune_2",
]


static func rng_for(key: String) -> RandomNumberGenerator:
	var r: RandomNumberGenerator = RandomNumberGenerator.new()
	r.seed = key.hash() ^ 0x5C02
	return r


static func build_all() -> Dictionary:
	var out: Dictionary = {}
	out["leaf_0"] = _build_leaf(0, rng_for("leaf_0"))
	out["leaf_1"] = _build_leaf(1, rng_for("leaf_1"))
	out["leaf_2"] = _build_leaf(2, rng_for("leaf_2"))
	out["leaf_3"] = _build_leaf(3, rng_for("leaf_3"))
	out["leaf_flower_0"] = _build_leaf_flower(rng_for("leaf_flower_0"))

	var conifer_shared: Dictionary = _gen_conifer_shared(rng_for("conifer_shared"))
	out["conifer_tier_0"] = _build_conifer_tier(0, conifer_shared, rng_for("conifer_tier_0"))
	out["conifer_tier_1"] = _build_conifer_tier(1, conifer_shared, rng_for("conifer_tier_1"))

	var fringe_shared: Dictionary = _gen_fringe_shared(rng_for("fringe_shared"))
	out["grass_fringe_0"] = _build_grass_fringe(0, fringe_shared, rng_for("grass_fringe_0"))
	out["grass_fringe_1"] = _build_grass_fringe(1, fringe_shared, rng_for("grass_fringe_1"))

	out["grass_tuft_0"] = _build_grass_tuft(0, rng_for("grass_tuft_0"))
	out["grass_tuft_1"] = _build_grass_tuft(1, rng_for("grass_tuft_1"))
	out["grass_tuft_2"] = _build_grass_tuft(2, rng_for("grass_tuft_2"))

	out["flower_0"] = _build_flower(0, rng_for("flower_0"))
	out["flower_1"] = _build_flower(1, rng_for("flower_1"))
	out["flower_2"] = _build_flower(2, rng_for("flower_2"))

	out["rune_0"] = _build_rune(0, rng_for("rune_0"))
	out["rune_1"] = _build_rune(1, rng_for("rune_1"))
	out["rune_2"] = _build_rune(2, rng_for("rune_2"))

	return out


# ---------------------------------------------------------------------------
# Tufo de Folhas (leaf_0..3, 32x32)
# ---------------------------------------------------------------------------
# variant: 0 = redondo, 1 = largo e achatado, 2 = pendente, 3 = ralo
static func _build_leaf(variant: int, rng: RandomNumberGenerator) -> Canvas:
	var cv: Canvas = Canvas.new(32, 32, false, false)
	var lv: PackedInt32Array = P.ramp("leaves")

	var cx: float = 15.5
	var cy: float = 15.5
	var rx: float = 13.0
	var ry: float = 13.0
	if variant == 1:
		rx = 14.0
		ry = 10.5
	elif variant == 2:
		rx = 12.0
		ry = 13.5
		cy = 14.0
	elif variant == 3:
		rx = 13.0
		ry = 12.5

	# Forma base: preenche elipse com margem livre de 1px
	for y: int in range(1, 31):
		for x: int in range(1, 31):
			var dx: float = (float(x) + 0.5 - cx) / rx
			var dy: float = (float(y) + 0.5 - cy) / ry
			var d2: float = dx * dx + dy * dy
			if d2 <= 1.0:
				# Variação interna garantindo uso dos tons 1 a 7
				var vert: float = 1.0 - (float(y) / 31.0) # 0 na base, 1 no topo
				var tone: int = clampi(roundi(1.2 + vert * 5.8), 1, 7)
				cv.put(x, y, lv[tone], 0.0)

	# Adiciona pontas serrilhadas recortadas de pixel
	for i: int in 14:
		var ang: float = rng.randf() * TAU
		var dist_r: float = rng.randf_range(0.85, 1.0)
		var px: int = clampi(roundi(cx + cos(ang) * rx * dist_r), 1, 30)
		var py: int = clampi(roundi(cy + sin(ang) * ry * dist_r), 1, 30)
		var t_tip: int = 7 if py < 12 else (5 if py < 20 else 2)
		cv.put(px, py, lv[t_tip], 0.0)

	# Furos para o tipo ralo (variant 3)
	if variant == 3:
		for h: int in 3:
			var hx: int = rng.randi_range(10, 21)
			var hy: int = rng.randi_range(11, 20)
			cv.put(hx, hy, -1, 0.0)
			cv.put(hx + 1, hy, -1, 0.0)
			cv.put(hx, hy + 1, -1, 0.0)

	_enforce_margin(cv)
	_clamp_coverage(cv, 540, 780, lv[4])
	_ensure_light_top(cv, lv)

	# Garante que os tons 1, 2, 3, 4, 5, 6, 7 fiquem protegidos contra limpeza de órfãos
	for t: int in range(1, 8):
		var target_y: int = roundi(30.0 - float(t - 1) * 4.2)
		for x: int in range(13, 19):
			if cv.get_c(x, target_y) >= 0:
				cv.put(x, target_y, lv[t], 0.0)
				cv.put(x + 1, target_y, lv[t], 0.0)
				cv.keep[cv.ofs(x, target_y)] = 1
				cv.keep[cv.ofs(x + 1, target_y)] = 1
				break

	cv.cleanup_orphans()
	cv.keep.fill(0)
	return cv


static func _build_leaf_flower(rng: RandomNumberGenerator) -> Canvas:
	var cv: Canvas = _build_leaf(0, rng)
	var fl_lilac: PackedInt32Array = P.ramp("flower_lilac")
	var fl_white: PackedInt32Array = P.ramp("flower_white")
	var fl_y: PackedInt32Array = P.ramp("flower_yellow")

	# 6 florzinhas de 2x2 a 3x3 espalhadas
	var positions: Array[Vector2i] = [
		Vector2i(10, 8), Vector2i(20, 9), Vector2i(14, 15),
		Vector2i(8, 18), Vector2i(22, 19), Vector2i(16, 24)
	]
	for idx: int in positions.size():
		var pos: Vector2i = positions[idx]
		var is_lilac: bool = (idx % 2 == 0)
		var pet_ramp: PackedInt32Array = fl_lilac if is_lilac else fl_white
		var pet_col: int = pet_ramp[1]
		# Pétalas
		cv.put(pos.x, pos.y, pet_col, 0.0)
		cv.put(pos.x + 1, pos.y, pet_col, 0.0)
		cv.put(pos.x, pos.y + 1, pet_col, 0.0)
		cv.put(pos.x + 1, pos.y + 1, pet_col, 0.0)
		# Miolo amarelo
		cv.put(pos.x, pos.y, fl_y[1], 0.0)

	_enforce_margin(cv)
	return cv


# ---------------------------------------------------------------------------
# Conifer Tier (conifer_tier_0..1, 32x32)
# ---------------------------------------------------------------------------
static func _gen_conifer_shared(rng: RandomNumberGenerator) -> Dictionary:
	var cnf: PackedInt32Array = P.ramp("conifer")
	var cols: Dictionary = {}
	for x: int in [0, 1, 30, 31]:
		var col_vals: PackedInt32Array = PackedInt32Array()
		col_vals.resize(32)
		for y: int in 32:
			if y < 16:
				var t: int = clampi(roundi(4.5 - float(y) * 0.2 + rng.randf_range(-0.4, 0.4)), 1, 6)
				col_vals[y] = cnf[t]
			elif y < 27:
				var t: int = clampi(roundi(3.0 - float(y - 16) * 0.2), 0, 4)
				col_vals[y] = cnf[t]
			else:
				col_vals[y] = -1
		cols[x] = col_vals
	return cols


static func _build_conifer_tier(variant: int, shared_cols: Dictionary, rng: RandomNumberGenerator) -> Canvas:
	var cv: Canvas = Canvas.new(32, 32, true, false)
	var cnf: PackedInt32Array = P.ramp("conifer")

	for y: int in 16:
		for x: int in 32:
			var vert: float = 1.0 - (float(y) / 16.0)
			var stroke: float = sin(float(x) * 1.2 + float(y) * 0.8) * 0.4
			var tone: int = clampi(roundi(2.2 + vert * 3.4 + stroke), 1, 6)
			cv.put(x, y, cnf[tone], 0.0)

	for x: int in 32:
		var tip_len: int = roundi(5.0 + sin(float(x + variant * 7) * 0.6) * 4.0 + rng.randf_range(0.0, 3.0))
		var max_y: int = mini(16 + tip_len, 30)
		if x in [7, 15, 23] and variant == 0:
			max_y = 31
		elif x in [5, 13, 21] and variant == 1:
			max_y = 31

		for y: int in range(16, max_y + 1):
			var dist_tip: float = float(y - 16) / maxf(float(tip_len), 1.0)
			var tone: int = clampi(roundi(3.2 - dist_tip * 2.2), 0, 4)
			cv.put(x, y, cnf[tone], 0.0)

	for x: int in [0, 1, 30, 31]:
		var col_vals: PackedInt32Array = shared_cols[x]
		for y: int in 32:
			cv.put(x, y, col_vals[y], 0.0)

	cv.cleanup_orphans()
	return cv


# ---------------------------------------------------------------------------
# Grass Fringe (grass_fringe_0..1, 32x16)
# ---------------------------------------------------------------------------
static func _gen_fringe_shared(rng: RandomNumberGenerator) -> Dictionary:
	var gr: PackedInt32Array = P.ramp("grass_arena")
	var moss: PackedInt32Array = P.ramp("moss")
	var cols: Dictionary = {}
	for x: int in [0, 1, 30, 31]:
		var col_vals: PackedInt32Array = PackedInt32Array()
		col_vals.resize(16)
		for y: int in 16:
			if y < 4:
				col_vals[y] = gr[clampi(roundi(5.0 - float(y) * 0.5), 3, 6)]
			elif y < 11:
				col_vals[y] = moss[clampi(roundi(3.0 - float(y - 4) * 0.3), 1, 3)]
			else:
				col_vals[y] = -1
		cols[x] = col_vals
	return cols


static func _build_grass_fringe(variant: int, shared_cols: Dictionary, rng: RandomNumberGenerator) -> Canvas:
	var cv: Canvas = Canvas.new(32, 16, true, false)
	var gr: PackedInt32Array = P.ramp("grass_arena")
	var moss: PackedInt32Array = P.ramp("moss")

	for y: int in 4:
		for x: int in 32:
			var tone: int = clampi(roundi(5.2 - float(y) * 0.6 + rng.randf_range(-0.4, 0.4)), 3, 6)
			cv.put(x, y, gr[tone], 0.0)

	for x: int in 32:
		var hang_len: int = roundi(4.0 + sin(float(x + variant * 8) * 0.7) * 3.5 + rng.randf_range(0.0, 3.0))
		var max_y: int = mini(4 + hang_len, 14)
		if x in [8, 18, 26] and variant == 0:
			max_y = 15
		elif x in [6, 16, 24] and variant == 1:
			max_y = 15

		for y: int in range(4, max_y + 1):
			var is_moss: bool = (y >= 8 or rng.randf() < 0.35)
			if is_moss:
				var mt: int = clampi(roundi(3.2 - float(y - 4) * 0.25), 1, 4)
				cv.put(x, y, moss[mt], 0.0)
			else:
				var gt: int = clampi(roundi(4.2 - float(y - 4) * 0.3), 2, 5)
				cv.put(x, y, gr[gt], 0.0)

	for x: int in [0, 1, 30, 31]:
		var col_vals: PackedInt32Array = shared_cols[x]
		for y: int in 16:
			cv.put(x, y, col_vals[y], 0.0)

	cv.cleanup_orphans()
	return cv


# ---------------------------------------------------------------------------
# Grass Tuft (grass_tuft_0..2, 16x16)
# ---------------------------------------------------------------------------
static func _build_grass_tuft(variant: int, rng: RandomNumberGenerator) -> Canvas:
	var cv: Canvas = Canvas.new(16, 16, false, false)
	var ramp: PackedInt32Array = P.ramp("grass_forest" if variant == 2 else "grass_arena")

	# Base comum centrada na linha 15 com tom 1
	var base_x: int = 7
	cv.put(base_x, 15, ramp[1], 0.0)
	cv.put(base_x + 1, 15, ramp[1], 0.0)
	cv.put(base_x, 14, ramp[2], 0.0)
	cv.put(base_x + 1, 14, ramp[2], 0.0)

	# 6 a 8 lâminas finas subindo cobrindo tons de 1 a 6
	var num_blades: int = rng.randi_range(6, 8)
	for b: int in num_blades:
		var target_x: int = clampi(roundi(base_x + rng.randf_range(-4.5, 5.5)), 2, 13)
		var height: int = rng.randi_range(9, 14)
		var target_y: int = 15 - height
		var pts: Array[Vector2i] = Canvas.line_pts(base_x + (b % 2), 14, target_x, target_y)
		for p: Vector2i in pts:
			if p.y == 0 or p.x == 0 or p.x == 15:
				continue
			var vert: float = float(15 - p.y) / float(height) # 0 na base, 1 no topo
			var tone: int = clampi(roundi(2.0 + vert * 4.0), 1, mini(6, ramp.size() - 1))
			cv.put(p.x, p.y, ramp[tone], 0.0)

	cv.cleanup_orphans()
	return cv


# ---------------------------------------------------------------------------
# Flower (flower_0..2, 16x16)
# ---------------------------------------------------------------------------
static func _build_flower(variant: int, rng: RandomNumberGenerator) -> Canvas:
	var cv: Canvas = Canvas.new(16, 16, false, false)
	var gr: PackedInt32Array = P.ramp("grass_arena")
	var fl_group: String = ["flower_yellow", "flower_white", "flower_lilac"][variant]
	var fl_ramp: PackedInt32Array = P.ramp(fl_group)
	var y_ramp: PackedInt32Array = P.ramp("flower_yellow")

	# Base comum centrada na linha 15
	var base_x: int = 7
	cv.put(base_x, 15, gr[1], 0.0)
	cv.put(base_x + 1, 15, gr[1], 0.0)
	cv.put(base_x, 14, gr[2], 0.0)
	cv.put(base_x + 1, 14, gr[2], 0.0)

	# 2 hastes com folhas e flores
	var flower_heads: Array[Vector2i] = [
		Vector2i(4, 4), Vector2i(10, 3)
	]
	for idx: int in flower_heads.size():
		var hpos: Vector2i = flower_heads[idx]
		var pts: Array[Vector2i] = Canvas.line_pts(base_x, 14, hpos.x + 1, hpos.y + 2)
		for p: Vector2i in pts:
			if p.y == 0 or p.x == 0 or p.x == 15:
				continue
			cv.put(p.x, p.y, gr[3], 0.0)

		# Folhas saindo da haste (2 px cada tom)
		var lx: int = clampi(hpos.x + (2 if hpos.x < 8 else -1), 1, 14)
		var ly: int = clampi(hpos.y + 5, 2, 13)
		cv.put(lx, ly, gr[4], 0.0)
		cv.put(lx + 1, ly, gr[4], 0.0)
		cv.put(lx, ly - 1, gr[5], 0.0)
		cv.put(lx + 1, ly - 1, gr[5], 0.0)

		# Pétalas 3x2: topo com fl_ramp[2], meio com fl_ramp[1], base com fl_ramp[0]
		cv.put(hpos.x, hpos.y, fl_ramp[2], 0.0)
		cv.put(hpos.x + 1, hpos.y, fl_ramp[2], 0.0)
		cv.put(hpos.x + 2, hpos.y, fl_ramp[1], 0.0)

		cv.put(hpos.x, hpos.y + 1, fl_ramp[1], 0.0)
		cv.put(hpos.x + 1, hpos.y + 1, y_ramp[1], 0.0)
		cv.put(hpos.x + 2, hpos.y + 1, y_ramp[0], 0.0)

		cv.put(hpos.x, hpos.y + 2, fl_ramp[0], 0.0)
		cv.put(hpos.x + 1, hpos.y + 2, fl_ramp[0], 0.0)
		cv.put(hpos.x + 2, hpos.y + 2, fl_ramp[1], 0.0)

		# Protege todos os pixels da flor
		for dy: int in 3:
			for dx: int in 3:
				var ofs: int = cv.ofs(hpos.x + dx, hpos.y + dy)
				if ofs >= 0:
					cv.keep[ofs] = 1

	cv.cleanup_orphans()
	cv.keep.fill(0)
	return cv


# ---------------------------------------------------------------------------
# Rune (rune_0..2, 16x16)
# ---------------------------------------------------------------------------
static func _build_rune(variant: int, rng: RandomNumberGenerator) -> Canvas:
	var cv: Canvas = Canvas.new(16, 16, false, false)
	var rn: PackedInt32Array = P.ramp("rune")

	var glyphs: Array[Array] = [
		# Glifo 0: Losango rúnico com cruz interna
		[
			Vector2i(7, 3), Vector2i(8, 3),
			Vector2i(5, 5), Vector2i(6, 5), Vector2i(9, 5), Vector2i(10, 5),
			Vector2i(4, 7), Vector2i(7, 7), Vector2i(8, 7), Vector2i(11, 7),
			Vector2i(4, 8), Vector2i(7, 8), Vector2i(8, 8), Vector2i(11, 8),
			Vector2i(5, 10), Vector2i(6, 10), Vector2i(9, 10), Vector2i(10, 10),
			Vector2i(7, 12), Vector2i(8, 12),
		],
		# Glifo 1: Triskele angular / runa de poder
		[
			Vector2i(7, 2), Vector2i(8, 2),
			Vector2i(7, 3), Vector2i(8, 3), Vector2i(11, 3), Vector2i(12, 3),
			Vector2i(7, 4), Vector2i(8, 4), Vector2i(10, 4),
			Vector2i(7, 5), Vector2i(8, 5), Vector2i(9, 5),
			Vector2i(6, 6), Vector2i(7, 6), Vector2i(8, 6), Vector2i(9, 6),
			Vector2i(4, 7), Vector2i(5, 7), Vector2i(7, 7), Vector2i(8, 7),
			Vector2i(3, 8), Vector2i(7, 8), Vector2i(8, 8),
			Vector2i(7, 9), Vector2i(8, 9), Vector2i(10, 9),
			Vector2i(7, 10), Vector2i(8, 10), Vector2i(9, 10),
			Vector2i(7, 11), Vector2i(8, 11),
			Vector2i(6, 12), Vector2i(7, 12),
		],
		# Glifo 2: Runa nórdica com asas e núcleo luminoso
		[
			Vector2i(4, 4), Vector2i(11, 4),
			Vector2i(5, 5), Vector2i(10, 5),
			Vector2i(6, 6), Vector2i(7, 6), Vector2i(8, 6), Vector2i(9, 6),
			Vector2i(7, 7), Vector2i(8, 7),
			Vector2i(5, 8), Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8), Vector2i(9, 8), Vector2i(10, 8),
			Vector2i(7, 9), Vector2i(8, 9),
			Vector2i(6, 10), Vector2i(7, 10), Vector2i(8, 10), Vector2i(9, 10),
			Vector2i(5, 11), Vector2i(10, 11),
			Vector2i(4, 12), Vector2i(11, 12),
		]
	]

	var points: Array = glyphs[variant]
	# Aro externo (rn[0]) e corpo médio (rn[1])
	for i: int in points.size():
		var p: Vector2i = points[i]
		cv.put(p.x, p.y, rn[0 if i % 2 == 0 else 1], 0.0)

	# Núcleo brilhante (rn[2])
	for p: Vector2i in points:
		var has_neighbors: int = 0
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if cv.get_c(p.x + d.x, p.y + d.y) >= 0:
				has_neighbors += 1
		if has_neighbors >= 2:
			cv.put(p.x, p.y, rn[2], 0.0)

	# Brilho pontual intenso (rn[3], 2 px)
	cv.put(7, 7, rn[3], 0.0)
	cv.put(8, 7, rn[3], 0.0)

	_enforce_margin(cv)
	return cv


# ---------------------------------------------------------------------------
# Auxiliares de Validação de Cartões
# ---------------------------------------------------------------------------
static func _enforce_margin(cv: Canvas) -> void:
	for x: int in cv.w:
		cv.put(x, 0, -1, 0.0)
		cv.put(x, cv.h - 1, -1, 0.0)
	for y: int in cv.h:
		cv.put(0, y, -1, 0.0)
		cv.put(cv.w - 1, y, -1, 0.0)


static func _clamp_coverage(cv: Canvas, min_c: int, max_c: int, fill_tone: int) -> void:
	var cur: int = cv.opaque_count()
	var cx: float = float(cv.w) * 0.5
	var cy: float = float(cv.h) * 0.5
	while cur < min_c:
		var found: bool = false
		for y: int in range(2, cv.h - 2):
			for x: int in range(2, cv.w - 2):
				if cv.get_c(x, y) < 0:
					# Vizinho de pixel opaco
					if cv.get_c(x + 1, y) >= 0 or cv.get_c(x - 1, y) >= 0 or cv.get_c(x, y + 1) >= 0 or cv.get_c(x, y - 1) >= 0:
						cv.put(x, y, fill_tone, 0.0)
						cur += 1
						found = true
						if cur >= min_c:
							break
			if cur >= min_c:
				break
		if not found:
			break


static func _ensure_light_top(cv: Canvas, ramp: PackedInt32Array) -> void:
	for x: int in cv.w:
		for y: int in cv.h:
			if cv.get_c(x, y) >= 0:
				# Primeiro pixel opaco vindo de cima
				if cv.get_c(x, y - 1) < 0:
					var cur_t: int = P.tone_of(cv.get_c(x, y))
					if cur_t < 4:
						cv.put(x, y, ramp[clampi(cur_t + 3, 4, ramp.size() - 1)], 0.0)
				break
