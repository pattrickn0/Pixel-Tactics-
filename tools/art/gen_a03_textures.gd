extends RefCounted
## Texturas opacas 32x32 da A03 (albedo + altura -> normal map). Sem class_name: usar via preload.
## Tudo é desenhado no toro 32x32 (coordenadas em módulo 32), então repete sem emenda.
## Chão: tom base dominante, detalhe esparso em tracinhos. Pedra e madeira: formas e juntas.

const P = preload("res://tools/art/palette_a03.gd")
const Canvas = preload("res://tools/art/a03_canvas.gd")

const N: int = 32

## Ordem de gravação: [nome, tem normal map]
const ORDER: Array = [
	["grass_arena_0", false], ["grass_arena_1", false], ["grass_arena_2", false], ["grass_arena_3", false],
	["grass_arena_light_0", false], ["grass_arena_light_1", false],
	["grass_arena_dark_0", false], ["grass_arena_dark_1", false],
	["grass_forest_0", false], ["grass_forest_1", false],
	["dirt_0", false], ["dirt_1", false],
	["stone_path_0", true], ["stone_path_1", true],
	["wall_face", true], ["wall_top", true], ["stair_tread", true], ["stair_riser", true],
	["step_side", true], ["step_side_grass", true], ["rock", true], ["monolith_stone", true],
	["bark_0", true], ["bark_1", true], ["wood_end", true], ["moss", false], ["leaves_mass", false],
]

const DIRS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1),
	Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
]


static func rng_for(key: String) -> RandomNumberGenerator:
	var r: RandomNumberGenerator = RandomNumberGenerator.new()
	r.seed = key.hash() ^ 0xA03A03
	return r


static func build_all() -> Dictionary:
	var out: Dictionary = {}
	var ga: int = P.hx("#5B9C47")
	var ga_light: int = P.hx("#73A949")
	var ga_dark: int = P.hx("#4E9343")
	var ga_tip: int = P.hx("#98B654")
	for i: int in 4:
		var key: String = "grass_arena_%d" % i
		out[key] = _ground_grass(rng_for(key), ga, ga_light, ga_dark, ga_tip, Vector2i(7, 10), 2,
				Vector2(0.042 if i == 3 else 0.032, 0.11), i == 3, false)
	for i: int in 2:
		var key: String = "grass_arena_light_%d" % i
		out[key] = _ground_grass(rng_for(key), ga_light, ga_tip, ga, -1, Vector2i(7, 10), 0,
				Vector2(0.032, 0.11), false, false)
	for i: int in 2:
		var key: String = "grass_arena_dark_%d" % i
		out[key] = _ground_grass(rng_for(key), ga_dark, ga, -1, -1, Vector2i(8, 10), 0,
				Vector2(0.032, 0.11), false, false)
	for i: int in 2:
		var key: String = "grass_forest_%d" % i
		out[key] = _ground_grass(rng_for(key), P.hx("#3D853C"), P.hx("#539342"), P.hx("#2C7036"), -1,
				Vector2i(9, 11), 0, Vector2(0.035, 0.12), false, false)
	for i: int in 2:
		var key: String = "dirt_%d" % i
		out[key] = _dirt(rng_for(key))
	var paths: Array = []
	var rp: RandomNumberGenerator = rng_for("stone_path")
	for attempt: int in 60:
		paths = _stone_paths(rp)
		if grad_ok(paths[0], true) and grad_ok(paths[1], true) and seam_ok(paths[0]) and seam_ok(paths[1]):
			break
	out["stone_path_0"] = paths[0]
	out["stone_path_1"] = paths[1]
	out["wall_face"] = _retry(_wall_face, "wall_face", false)
	out["wall_top"] = _retry(_wall_top, "wall_top", true)
	out["stair_tread"] = _retry(_stair_tread, "stair_tread", true)
	out["stair_riser"] = _retry(_stair_riser, "stair_riser", false)
	out["step_side"] = _retry(_step_side, "step_side", false)
	out["rock"] = _retry(_rock, "rock", true)
	out["monolith_stone"] = _retry(_monolith, "monolith_stone", false)
	out["bark_0"] = _retry(_bark_0, "bark_0", false)
	out["bark_1"] = _retry(_bark_1, "bark_1", false)
	out["wood_end"] = _wood_end(rng_for("wood_end"))
	fix_checker(out["wood_end"])
	out["moss"] = _retry(_moss, "moss", true)
	out["leaves_mass"] = _retry(_leaves_mass, "leaves_mass", true)
	for item: Array in ORDER:
		if item[1] and out.has(item[0]):
			(out[item[0]] as RefCounted).tune_relief(0.22)
	# emenda: escolhe o deslocamento (com wrap) que põe a costura no par de colunas/linhas mais calmo
	for key: String in ["wall_face", "stair_riser", "step_side"]:
		best_roll(out[key], true, false, false)
	for key: String in ["wall_top", "rock", "bark_0", "bark_1"]:
		best_roll(out[key], true, true, true)
	# piso de degrau: só na horizontal (as juntas ficam nas linhas 15 e 31, o nariz em 0 e 16)
	best_roll(out["stair_tread"], true, false, true)
	for key: String in ["moss", "leaves_mass"]:
		best_roll(out[key], true, true, false)
	best_roll(out["monolith_stone"], true, false, true)
	best_roll(out["monolith_stone"], false, true, true, 4)
	# a lateral com grama nasce do barranco já deslocado (linhas 16 a 31 idênticas)
	out["step_side_grass"] = _step_side_grass(out["step_side"], rng_for("step_side_grass"))
	out["step_side_grass"].tune_relief(0.22)
	return out


# ---------------------------------------------------------------------------
# Utilidades
# ---------------------------------------------------------------------------

static func wrap_delta(d: float, n: float = 32.0) -> float:
	return fposmod(d + n * 0.5, n) - n * 0.5


static func wdist(a: Vector2, b: Vector2) -> float:
	return Vector2(wrap_delta(a.x - b.x), wrap_delta(a.y - b.y)).length()


## Tamanhos dos componentes conexos (vizinhança 8, sem wrap) dos pixels diferentes de base.
static func components(cv: RefCounted, base: int) -> Array[int]:
	var seen: PackedByteArray = PackedByteArray()
	seen.resize(cv.w * cv.h)
	var sizes: Array[int] = []
	for y: int in cv.h:
		for x: int in cv.w:
			var o: int = y * cv.w + x
			if seen[o] != 0 or cv.c[o] == base:
				continue
			var stack: Array[Vector2i] = [Vector2i(x, y)]
			seen[o] = 1
			var n: int = 0
			while not stack.is_empty():
				var p: Vector2i = stack.pop_back()
				n += 1
				for j: int in range(-1, 2):
					for i: int in range(-1, 2):
						var q: Vector2i = p + Vector2i(i, j)
						if q.x < 0 or q.y < 0 or q.x >= cv.w or q.y >= cv.h:
							continue
						var oq: int = q.y * cv.w + q.x
						if seen[oq] == 0 and cv.c[oq] != base:
							seen[oq] = 1
							stack.append(q)
			sizes.append(n)
	return sizes


## Pinta uma marca (lista de [Vector2i, cor]) em (ox, oy).
static func paint_mark(cv: RefCounted, mark: Array, ox: int, oy: int, zv: float = 0.0) -> void:
	for it: Array in mark:
		var p: Vector2i = it[0]
		cv.put(ox + p.x, oy + p.y, it[1], zv)


## Confere se a marca cabe em [lo, hi] e não encosta (vizinhança 8) em nada fora do base.
static func mark_fits(cv: RefCounted, mark: Array, ox: int, oy: int, base: int, lo: int, hi: int) -> bool:
	for it: Array in mark:
		var p: Vector2i = it[0] + Vector2i(ox, oy)
		if p.x < lo or p.y < lo or p.x > hi or p.y > hi:
			return false
		for j: int in range(-1, 2):
			for i: int in range(-1, 2):
				if cv.get_c(p.x + i, p.y + j) != base:
					return false
	return true


static func ellipse_pts(cx: float, cy: float, rx: float, ry: float) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y: int in range(floori(cy - ry) - 1, ceili(cy + ry) + 2):
		for x: int in range(floori(cx - rx) - 1, ceili(cx + rx) + 2):
			var dx: float = (x + 0.5 - cx) / rx
			var dy: float = (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				out.append(Vector2i(x, y))
	return out


## Voronoi no toro: para cada pixel, [id mais perto, d2 - d1].
static func voronoi(seeds: Array, weights: Array) -> Array:
	var ids: PackedInt32Array = PackedInt32Array()
	var gap: PackedFloat32Array = PackedFloat32Array()
	ids.resize(N * N)
	gap.resize(N * N)
	for y: int in N:
		for x: int in N:
			var p: Vector2 = Vector2(x + 0.5, y + 0.5)
			var d1: float = 1e9
			var d2: float = 1e9
			var best: int = -1
			for k: int in seeds.size():
				var d: float = wdist(p, seeds[k]) * float(weights[k])
				if d < d1:
					d2 = d1
					d1 = d
					best = k
				elif d < d2:
					d2 = d
			ids[y * N + x] = best
			gap[y * N + x] = d2 - d1
	return [ids, gap]


## Tenta o gerador com o mesmo RNG até não ter gradiente global (máx. 40 vezes).
static func _retry(builder: Callable, key: String, top: bool) -> RefCounted:
	var rng: RandomNumberGenerator = rng_for(key)
	var cv: RefCounted = null
	for attempt: int in 40:
		cv = builder.call(rng)
		if grad_ok(cv, top):
			break
	return cv


static func _luma_of(ci: int) -> float:
	return P.luma(ci) if ci >= 0 else 0.0


## Diferença de luminância média entre metades (E/D e, se topo, C/B) <= 0,03.
static func grad_ok(cv: RefCounted, top: bool) -> bool:
	var l: float = 0.0
	var r: float = 0.0
	var t: float = 0.0
	var b: float = 0.0
	for y: int in cv.h:
		for x: int in cv.w:
			var v: float = _luma_of(cv.get_c(x, y))
			if x < cv.w / 2:
				l += v
			else:
				r += v
			if y < cv.h / 2:
				t += v
			else:
				b += v
	var n: float = cv.w * cv.h * 0.5
	if absf(l - r) / n > 0.03:
		return false
	return not top or absf(t - b) / n <= 0.03


## A costura (par 31 -> 0) não pode destoar do interior, no albedo e no normal map (margem: 1,15).
static func seam_ok(cv: RefCounted) -> bool:
	cv.tune_relief(0.22)
	for img: Image in [cv.to_image(), cv.normal_image()]:
		for axis: int in 2:
			var d: PackedFloat32Array = _pair_diffs(img, axis)
			var total: float = 0.0
			for v: float in d:
				total += v
			var edge: float = d[d.size() - 1]
			if edge > 1.15 * (total - edge) / (d.size() - 1):
				return false
	return true


## Fecha xadrez 2x2 de dois tons: o pixel de fundo da diagonal vira a cor da marca (forma "L").
static func fix_checker(cv: RefCounted, base: int = -99) -> void:
	for it: int in 6:
		var changed: bool = false
		for y: int in cv.h:
			for x: int in cv.w:
				var a: int = cv.get_c(x, y)
				var b: int = cv.get_c(x + 1, y)
				var c: int = cv.get_c(x, y + 1)
				var d: int = cv.get_c(x + 1, y + 1)
				if a == d and b == c and a != b:
					# preenche com a cor que não é o fundo (no chão, o fundo é o base)
					var fill_c: int = a
					var keep_c: int = b
					if a == base:
						fill_c = b
						keep_c = a
					elif b != base and P.luma(b) < P.luma(a):
						fill_c = b
						keep_c = a
					var zf: float = cv.get_z(x, y) if fill_c == a else cv.get_z(x + 1, y)
					if keep_c == b:
						cv.put(x + 1, y, fill_c, zf)
					else:
						cv.put(x, y, fill_c, zf)
					changed = true
		if not changed:
			break


## Por eixo: diferença média de Y entre colunas (ou linhas) vizinhas i -> i+1, com wrap.
static func _pair_diffs(img: Image, axis: int) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	var w: int = img.get_width()
	var h: int = img.get_height()
	var n: int = w if axis == 0 else h
	for i: int in n:
		var s: float = 0.0
		var m: int = h if axis == 0 else w
		for j: int in m:
			var c0: Color = img.get_pixel(i, j) if axis == 0 else img.get_pixel(j, i)
			var c1: Color = img.get_pixel((i + 1) % w, j) if axis == 0 else img.get_pixel(j, (i + 1) % h)
			s += absf((0.299 * c0.r + 0.587 * c0.g + 0.114 * c0.b) - (0.299 * c1.r + 0.587 * c1.g + 0.114 * c1.b))
		out.append(s / m)
	return out


## Desloca a textura (com wrap) para a costura cair no par mais calmo do eixo.
## max_shift: 0 = qualquer deslocamento; senão, só até max_shift pixels.
static func best_roll(cv: RefCounted, along_x: bool, along_y: bool, with_normal: bool, max_shift: int = 0) -> void:
	for axis: int in 2:
		if (axis == 0 and not along_x) or (axis == 1 and not along_y):
			continue
		var da: PackedFloat32Array = _pair_diffs(cv.to_image(), axis)
		var dn: PackedFloat32Array = _pair_diffs(cv.normal_image(), axis) if with_normal else PackedFloat32Array()
		var n: int = da.size()
		var ta: float = 0.0
		var tn: float = 0.0
		for i: int in n:
			ta += da[i]
			if with_normal:
				tn += dn[i]
		# média de luminância por coluna (ou linha), para não criar gradiente entre metades
		var lum: PackedFloat32Array = PackedFloat32Array()
		lum.resize(n)
		for i: int in n:
			var sum_l: float = 0.0
			for j: int in n:
				sum_l += _luma_of(cv.get_c(i, j) if axis == 0 else cv.get_c(j, i))
			lum[i] = sum_l / n
		var best: int = n - 1
		var best_cost: float = 1e9
		for i: int in n:
			var shift: int = n - 1 - i
			if max_shift > 0 and mini(shift, n - shift) > max_shift:
				continue
			var half_a: float = 0.0
			var half_b: float = 0.0
			for j: int in n:
				if j < n / 2:
					half_a += lum[posmod(j - shift, n)]
				else:
					half_b += lum[posmod(j - shift, n)]
			if absf(half_a - half_b) / (n / 2) > 0.03:
				continue
			var ra: float = da[i] / maxf((ta - da[i]) / (n - 1), 1e-6)
			var cost: float = ra
			if with_normal:
				cost = maxf(cost, dn[i] / maxf((tn - dn[i]) / (n - 1), 1e-6))
			if cost < best_cost - 1e-4:
				best_cost = cost
				best = i
		var sh: int = n - 1 - best
		if sh != 0:
			if axis == 0:
				cv.roll(sh, 0)
			else:
				cv.roll(0, sh)


# ---------------------------------------------------------------------------
# Chão: grama e terra
# ---------------------------------------------------------------------------

## Tracinho: reta de 2 a 3 px numa das 8 direções, com 1 ou 2 tons.
static func _grass_mark(rng: RandomNumberGenerator, a: int, b: int) -> Array:
	var d: Vector2i = DIRS[rng.randi_range(0, 7)]
	var length: int = rng.randi_range(2, 3)
	var out: Array = []
	for k: int in length:
		out.append([d * k, a])
	if b >= 0:
		var kind: int = rng.randi_range(0, 2)
		if kind == 0:
			# raiz: prolonga a reta no outro tom
			out.append([d * length, b])
		elif kind == 1:
			# sombra paralela de 1 a 2 px
			var perp: Vector2i = Vector2i(-d.y, d.x) * (1 if rng.randf() < 0.5 else -1)
			if perp.x != 0 and perp.y != 0:
				perp = Vector2i(perp.x, 0)
			for k: int in rng.randi_range(1, 2):
				out.append([d * k + perp, b])
		else:
			# "v": segundo braço curto saindo da raiz
			var d2: Vector2i = DIRS[posmod(DIRS.find(d) + (2 if rng.randf() < 0.5 else -2), 8)]
			out.append([d2, b])
			if rng.randf() < 0.5:
				out.append([d2 * 2, b])
	# remove repetidos (pode acontecer na sombra)
	var seen: Dictionary = {}
	var uniq: Array = []
	for it: Array in out:
		if not seen.has(it[0]):
			seen[it[0]] = true
			uniq.append(it)
	return uniq


static func _ground_grass(rng: RandomNumberGenerator, base: int, a: int, b: int, tip: int,
		n_marks: Vector2i, max_tips: int, detail: Vector2, flowers: bool, litter: bool) -> RefCounted:
	for attempt: int in 400:
		var cv: RefCounted = Canvas.new(N, N)
		cv.fill(base)
		var centers: Array[Vector2] = []
		var target: int = rng.randi_range(n_marks.x, n_marks.y)
		var tips_left: int = rng.randi_range(1, max_tips) if max_tips > 0 else 0
		var tries: int = 0
		var placed: int = 0
		# flores primeiro (variante florida): 1 ou 2, de 3 a 4 px
		if flowers:
			var shapes: Array = [
				[[Vector2i(1, 0), 0], [Vector2i(0, 1), 0], [Vector2i(1, 1), 1], [Vector2i(2, 1), 0]],
				[[Vector2i(0, 0), 0], [Vector2i(1, 0), 0], [Vector2i(0, 1), 0], [Vector2i(1, 1), 1]],
				[[Vector2i(0, 0), 0], [Vector2i(1, 1), 1], [Vector2i(2, 0), 0]],
			]
			var petals: Array[int] = [P.hx("#E8829C"), P.hx("#F4F0E4")]
			var nf: int = rng.randi_range(1, 2)
			var fi: int = 0
			while fi < nf and tries < 200:
				tries += 1
				var shape: Array = shapes[rng.randi_range(0, shapes.size() - 1)]
				var petal: int = petals[fi % 2]
				var mark: Array = []
				for it: Array in shape:
					mark.append([it[0], petal if it[1] == 0 else P.hx("#F2D04A")])
				var ox: int = rng.randi_range(4, 26)
				var oy: int = rng.randi_range(4, 26)
				if not _far(centers, Vector2(ox, oy), 7.0) or not mark_fits(cv, mark, ox, oy, base, 2, 29):
					continue
				paint_mark(cv, mark, ox, oy)
				centers.append(Vector2(ox, oy))
				fi += 1
		if litter:
			var leaf_shapes: Array = [
				[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)],
				[Vector2i(0, 0), Vector2i(1, 1)],
				[Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)],
				[Vector2i(0, 1), Vector2i(1, 0), Vector2i(2, 0)],
			]
			var nl: int = 1
			var li: int = 0
			while li < nl and tries < 300:
				tries += 1
				var mark: Array = []
				for p: Vector2i in leaf_shapes[rng.randi_range(0, leaf_shapes.size() - 1)]:
					mark.append([p, P.hx("#876547")])
				var ox: int = rng.randi_range(3, 27)
				var oy: int = rng.randi_range(3, 27)
				if not _far(centers, Vector2(ox, oy), 6.0) or not mark_fits(cv, mark, ox, oy, base, 2, 29):
					continue
				paint_mark(cv, mark, ox, oy)
				centers.append(Vector2(ox, oy))
				li += 1
		while placed < target and tries < 600:
			tries += 1
			var prim: int = a
			var comp: int = -1
			if b < 0:
				comp = a if rng.randf() < 0.7 else -1
			else:
				prim = a if rng.randf() < 0.7 else b
				comp = (b if prim == a else a) if rng.randf() < 0.6 else -1
			var mark: Array = _grass_mark(rng, prim, comp)
			var with_tip: bool = tips_left > 0 and tip >= 0 and rng.randf() < 0.35
			if with_tip:
				# ponta clara rara: prolonga o tracinho para trás
				mark.append([Vector2i(0, 0) - (mark[1][0] as Vector2i), tip])
			var ox: int = rng.randi_range(3, 28)
			var oy: int = rng.randi_range(3, 28)
			if not _far(centers, Vector2(ox, oy), 5.0) or not mark_fits(cv, mark, ox, oy, base, 2, 29):
				continue
			paint_mark(cv, mark, ox, oy)
			centers.append(Vector2(ox, oy))
			placed += 1
			if with_tip:
				tips_left -= 1
		fix_checker(cv, base)
		# critérios: fração de detalhe e tamanho dos componentes
		var non_base: int = 0
		for i: int in N * N:
			if cv.c[i] != base:
				non_base += 1
		var frac: float = float(non_base) / float(N * N)
		if frac < detail.x or frac > detail.y:
			continue
		var ok: bool = true
		for s: int in components(cv, base):
			if s < 2 or s > (9 if flowers else 6):
				ok = false
		if ok:
			return cv
	push_error("Chão não convergiu")
	return Canvas.new(N, N)


static func _far(centers: Array[Vector2], p: Vector2, dmin: float) -> bool:
	for q: Vector2 in centers:
		if q.distance_to(p) < dmin:
			return false
	return true


static func _dirt(rng: RandomNumberGenerator) -> RefCounted:
	var base: int = P.hx("#C0AE71")
	var L: int = P.hx("#D4C48C")
	var D: int = P.hx("#A8955F")
	# pedrinhas: miolo claro em cima, base escura embaixo (sem lado)
	var pebbles: Array = [
		["LL", "DD"], [".L.", "DLD"], ["LL.", "DDD"], [".LL", "DDD"], ["LLL", ".DD"],
		["L.", "DD"], [".L", "DD"], ["LL", "DD", ".D"],
	]
	var cracks: Array = [["DD"], ["D.", ".D"], [".D", "D."]]
	for attempt: int in 400:
		var cv: RefCounted = Canvas.new(N, N)
		cv.fill(base)
		var centers: Array[Vector2] = []
		var n: int = rng.randi_range(4, 5)
		var placed: int = 0
		var tries: int = 0
		var used: Dictionary = {}
		while placed < n and tries < 300:
			tries += 1
			var k: int = rng.randi_range(0, pebbles.size() - 1)
			if used.has(k):
				continue
			var mark: Array = _rows_to_mark(pebbles[k], {"L": L, "D": D})
			var ox: int = rng.randi_range(3, 27)
			var oy: int = rng.randi_range(3, 27)
			if not _far(centers, Vector2(ox, oy), 7.0) or not mark_fits(cv, mark, ox, oy, base, 2, 29):
				continue
			paint_mark(cv, mark, ox, oy)
			centers.append(Vector2(ox, oy))
			used[k] = true
			placed += 1
		# 0 a 1 rachadinha de 2 px
		if rng.randf() < 0.6:
			for t: int in 50:
				var mark: Array = _rows_to_mark(cracks[rng.randi_range(0, cracks.size() - 1)], {"D": D})
				var ox: int = rng.randi_range(3, 27)
				var oy: int = rng.randi_range(3, 27)
				if _far(centers, Vector2(ox, oy), 6.0) and mark_fits(cv, mark, ox, oy, base, 2, 29):
					paint_mark(cv, mark, ox, oy)
					break
		fix_checker(cv, base)
		var non_base: int = 0
		for i: int in N * N:
			if cv.c[i] != base:
				non_base += 1
		var frac: float = float(non_base) / float(N * N)
		if frac < 0.022 or frac > 0.06:
			continue
		var ok: bool = true
		for s: int in components(cv, base):
			if s < 2 or s > 6:
				ok = false
		if ok:
			return cv
	push_error("Terra não convergiu")
	return Canvas.new(N, N)


static func _rows_to_mark(rows: Array, colors: Dictionary) -> Array:
	var out: Array = []
	for j: int in rows.size():
		var row: String = rows[j]
		for i: int in row.length():
			if colors.has(row[i]):
				out.append([Vector2i(i, j), colors[row[i]]])
	return out


# ---------------------------------------------------------------------------
# Pedra
# ---------------------------------------------------------------------------

## Larguras (com a junta) que somam 'total', cada uma em [lo, hi].
static func _split(rng: RandomNumberGenerator, total: int, lo: int, hi: int) -> Array[int]:
	for attempt: int in 200:
		var out: Array[int] = []
		var rest: int = total
		while rest > hi:
			var wmax: int = mini(hi, rest - lo)
			if wmax < lo:
				break
			var wv: int = rng.randi_range(lo, wmax)
			out.append(wv)
			rest -= wv
		if rest >= lo and rest <= hi:
			out.append(rest)
			return out
	return [total]


## Fiada de pedras entre as linhas y0..y1 (inclusive) com juntas verticais de 1 px.
## Devolve as posições x das juntas. 'tones' = [topo, corpo, base] por estilo.
static func _course(cv: RefCounted, rng: RandomNumberGenerator, y0: int, y1: int, lo: int, hi: int,
		prev: Array[int], styles: Array, joint: int, round_p: float) -> Array[int]:
	var widths: Array[int] = []
	var joints: Array[int] = []
	for attempt: int in 80:
		widths = _split(rng, N, lo, hi)
		var off: int = rng.randi_range(0, N - 1)
		joints = []
		var acc: int = off
		for wv: int in widths:
			acc += wv
			joints.append(posmod(acc - 1, N))
		var ok: bool = true
		for jx: int in joints:
			for px: int in prev:
				if absi(wrap_delta(float(jx - px))) < 3:
					ok = false
		if ok:
			break
	# pinta pedras
	var start: int = joints[joints.size() - 1] + 1
	for k: int in joints.size():
		var x_end: int = joints[k] # junta
		var length: int = posmod(x_end - start, N)
		var st: Array = styles[rng.randi_range(0, styles.size() - 1)]
		for i: int in length:
			var x: int = start + i
			for y: int in range(y0, y1 + 1):
				var col: int = st[1]
				if y == y0:
					col = st[0]
				elif y == y1:
					col = st[2]
				cv.put(x, y, col, 1.0)
		# cantos arredondados
		var corners: Array[Vector2i] = [Vector2i(start, y0), Vector2i(start + length - 1, y0),
				Vector2i(start, y1), Vector2i(start + length - 1, y1)]
		for p: Vector2i in corners:
			if rng.randf() < round_p:
				cv.put(p.x, p.y, joint, 0.0)
		cv_put_col(cv, x_end, y0, y1, joint)
		start = x_end + 1
	return joints


static func cv_put_col(cv: RefCounted, x: int, y0: int, y1: int, col: int) -> void:
	for y: int in range(y0, y1 + 1):
		cv.put(x, y, col, 0.0)


## Chanfro: pixel de pedra (z = 1) vizinho de junta (z = 0) desce para 0,55.
static func _chamfer(cv: RefCounted, zh: float = 1.0, zc: float = 0.55) -> void:
	var nz: PackedFloat32Array = cv.z.duplicate()
	for y: int in cv.h:
		for x: int in cv.w:
			if cv.get_z(x, y) < zh - 0.01:
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if cv.get_z(x + d.x, y + d.y) < 0.2:
					nz[cv.ofs(x, y)] = zc
					break
	cv.z = nz


static func _wall_face(rng: RandomNumberGenerator) -> RefCounted:
	var J: int = P.hx("#34403C")
	var light: Array = [P.hx("#D3CCB4"), P.hx("#B9B597"), P.hx("#989680")]
	var dark: Array = [P.hx("#B9B597"), P.hx("#989680"), P.hx("#989680")]
	var cv: RefCounted = Canvas.new(N, N)
	cv.fill(J, 0.0)
	# 2 faixas x 3 fiadas; juntas horizontais nas linhas 4, 10, 15 (A) e 21, 26, 31 (B)
	var courses: Array = [[0, 3], [5, 9], [11, 14], [16, 20], [22, 25], [27, 30]]
	var prev: Array[int] = []
	for crs: Array in courses:
		prev = _course(cv, rng, crs[0], crs[1], 7, 14, prev, [light, light, dark], J, 0.45)
	_chamfer(cv)
	# musgo: escorre de 3 juntas horizontais e cobre o topo da pedra de baixo
	var M_dark: int = P.hx("#496819")
	var M: int = P.hx("#789636")
	var M_light: int = P.hx("#8FAE48")
	var joint_rows: Array[int] = [4, 10, 15, 21, 26, 31]
	var picks: Array[int] = [0, 1, 2, 3, 4, 5]
	picks.remove_at(rng.randi_range(0, 5))
	picks.remove_at(rng.randi_range(0, 4))
	var done: Dictionary = {}
	for pi: int in picks:
		if done.has(pi):
			continue
		done[pi] = true
		var jy: int = joint_rows[pi]
		var x0: int = rng.randi_range(0, N - 1)
		var length: int = rng.randi_range(8, 13)
		for i: int in length:
			var x: int = x0 + i
			cv.put(x, jy, M_dark, 0.35)
			# topo da pedra de baixo coberto de musgo (1 a 2 linhas)
			if cv.get_z(x, jy + 1) > 0.2 and i > 0 and i < length - 1:
				cv.put(x, jy + 1, M_light if (i / 2) % 2 == 0 else M, 0.9)
				if i > 1 and i < length - 2 and cv.get_z(x, jy + 2) > 0.2 and rng.randf() < 0.7:
					cv.put(x, jy + 2, M, 0.85)
		# fios escorrendo (1 a 3 px) a partir da junta
		var nd: int = rng.randi_range(2, 3)
		for k: int in nd:
			var x: int = x0 + 1 + rng.randi_range(0, length - 3)
			var dl: int = rng.randi_range(2, 3)
			for t: int in dl:
				var yy: int = jy + 1 + t
				if cv.get_z(x, yy) < 0.2 and t > 0:
					break
				cv.put(x, yy, M if t < dl - 1 else M_dark, 0.8)
	return cv


## Juntas verticais por faixa. choose(rng) devolve as larguras (com a junta) de uma faixa.
## As juntas de faixas vizinhas (inclusive a última com a primeira) ficam a >= min_off px.
static func _band_joints(rng: RandomNumberGenerator, bands: int, choose: Callable, min_off: int) -> Array:
	for attempt: int in 400:
		var all: Array = []
		for b: int in bands:
			var placed: bool = false
			for t: int in 120:
				var widths: Array[int] = choose.call(rng)
				var acc: int = rng.randi_range(0, N - 1)
				var joints: Array[int] = []
				for wv: int in widths:
					acc += wv
					joints.append(posmod(acc - 1, N))
				if b > 0 and not _joints_far(joints, all[b - 1], min_off):
					continue
				if b == bands - 1 and bands > 2 and not _joints_far(joints, all[0], min_off):
					continue
				all.append(joints)
				placed = true
				break
			if not placed:
				break
		if all.size() == bands:
			return all
	push_error("_band_joints: sem solução")
	return []


static func _joints_far(a: Array[int], b: Array, min_off: int) -> bool:
	for x: int in a:
		for y: Variant in b:
			if absi(roundi(wrap_delta(float(x - int(y))))) < min_off:
				return false
	return true


## Todos os pontos e seus vizinhos (vizinhança 8) estão na cor base.
static func _free(cv: RefCounted, pts: Array[Vector2i], base: int) -> bool:
	for p: Vector2i in pts:
		for j: int in range(-1, 2):
			for i: int in range(-1, 2):
				if cv.get_c(p.x + i, p.y + j) != base:
					return false
	return true


## Espelho de degrau: 4 faixas de 8 linhas. Cada faixa é um bloco comprido (1 ou 2 pedras):
## nariz claro em cima, corpo médio, aresta de baixo mais escura e junta escura na linha 7.
static func _stair_riser(rng: RandomNumberGenerator) -> RefCounted:
	var J: int = P.hx("#34403C")
	var V: int = P.hx("#7A7A66")
	var E: int = P.hx("#989680")
	var B: int = P.hx("#B9B597")
	var H: int = P.hx("#D3CCB4")
	var M: int = P.hx("#789636")
	var Md: int = P.hx("#5E7C26")
	var cv: RefCounted = Canvas.new(N, N)
	cv.fill(J, 0.0)
	var choose: Callable = func(r: RandomNumberGenerator) -> Array[int]:
		if r.randf() < 0.45:
			var one: Array[int] = [N]
			return one
		return _split(r, N, 14, 18)
	var bands: Array = _band_joints(rng, 4, choose, 6)
	for b: int in 4:
		var y0: int = b * 8
		var joints: Array = bands[b]
		var start: int = int(joints[joints.size() - 1]) + 1
		for k: int in joints.size():
			var jx: int = joints[k]
			var length: int = posmod(jx - start, N)
			var style: int = rng.randi_range(0, 2)
			var nose: int = B if style == 2 else H
			for i: int in length:
				var x: int = start + i
				cv.put(x, y0, nose, 1.0)
				cv.put(x, y0 + 1, B, 0.95)
				for y: int in range(y0 + 2, y0 + 6):
					cv.put(x, y, B if (style == 0 and y == y0 + 2) else E, 0.85)
				cv.put(x, y0 + 6, V, 0.55)
			# canto do nariz gasto, junto da junta
			if nose == H:
				cv.put(start, y0, B, 0.95)
				if rng.randf() < 0.5:
					cv.put(start + length - 1, y0, B, 0.95)
			# marcas de 2 a 3 px no corpo (trinca ou lasca clara), longe das juntas
			var nm: int = 2 if length > 20 else 1
			for t: int in nm:
				var mx: int = start + rng.randi_range(3, maxi(3, length - 6))
				var my: int = y0 + rng.randi_range(3, 4)
				var ml: int = rng.randi_range(2, 3)
				var crack: bool = t == 0
				for q: int in ml:
					cv.put(mx + q, my, V if crack else B, 0.7 if crack else 0.9)
			# junta vertical em tom médio; no nariz, só um tom abaixo
			cv.put(jx, y0, E, 0.6)
			for y: int in range(y0 + 1, y0 + 7):
				cv.put(jx, y, V, 0.3)
			start = jx + 1
	# musgo de 4 a 6 px em cima do nariz, em 1 ou 2 faixas
	var b1: int = rng.randi_range(0, 3)
	var mbands: Array[int] = [b1]
	if rng.randf() < 0.6:
		mbands.append(posmod(b1 + 2, 4))
	for b: int in mbands:
		var y0: int = b * 8
		var x0: int = rng.randi_range(0, N - 1)
		var length: int = rng.randi_range(4, 6)
		for i: int in length:
			cv.put(x0 + i, y0, M, 1.1)
			if i > 0 and i < length - 1:
				cv.put(x0 + i, y0 + 1, Md if i % 3 != 1 else M, 1.0)
		cv.put(x0 + rng.randi_range(1, length - 2), y0 + 2, Md, 0.95)
	return cv


## Piso de degrau: 2 faixas de 16 linhas (piso de 0,5). Linha 0/16 = nariz claro (frente do degrau),
## linha 15/31 = junta (fundo, embaixo do próximo espelho). Lajes de 16 px, junta de 1 px, sem moldura.
static func _stair_tread(rng: RandomNumberGenerator) -> RefCounted:
	var J: int = P.hx("#7A7A66")
	var E: int = P.hx("#989680")
	var B: int = P.hx("#B9B597")
	var H: int = P.hx("#D3CCB4")
	var M: int = P.hx("#789636")
	var G: int = P.hx("#73A949")
	var cv: RefCounted = Canvas.new(N, N)
	cv.fill(B, 1.0)
	var choose: Callable = func(r: RandomNumberGenerator) -> Array[int]:
		return _split(r, N, 16, 20)
	var bands: Array = _band_joints(rng, 2, choose, 7)
	for r: int in 2:
		var y0: int = r * 16
		for x: int in N:
			cv.put(x, y0, H, 1.0)
			cv.put(x, y0 + 15, J, 0.0)
		var joints: Array = bands[r]
		for k: int in joints.size():
			var jx: int = joints[k]
			for y: int in range(y0, y0 + 15):
				cv.put(jx, y, J, 0.0)
	# desgaste: tracinhos de 2 a 3 px (um tom abaixo) e manchas claras, sem encostar em nada
	var placed: int = 0
	for t: int in 400:
		if placed >= 10:
			break
		var mx: int = rng.randi_range(0, N - 1)
		var my: int = posmod(rng.randi_range(3, 12) + 16 * (placed % 2), N)
		var ml: int = rng.randi_range(2, 3)
		var light: bool = placed % 3 == 1
		var pts: Array[Vector2i] = []
		var diag: bool = rng.randf() < 0.4
		for q: int in ml:
			pts.append(Vector2i(mx + q, my + (q / 2 if diag else 0)))
		if not _free(cv, pts, B):
			continue
		for p: Vector2i in pts:
			cv.put(p.x, p.y, H if light else E, 1.05 if light else 0.85)
		placed += 1
	# chanfro só na altura (a cor da laje não muda: sem moldura)
	_chamfer(cv, 1.0, 0.6)
	# musgo e grama nas juntas: 3 a 4 tufos
	var n_tufts: int = rng.randi_range(3, 4)
	var centers: Array[Vector2] = []
	for t: int in 300:
		if centers.size() >= n_tufts:
			break
		var pts: Array = []
		var c: Vector2
		if centers.size() % 3 != 2:
			# ao longo da junta de trás
			var jy: int = 15 + 16 * rng.randi_range(0, 1)
			var x0: int = rng.randi_range(0, N - 1)
			var length: int = rng.randi_range(6, 9)
			c = Vector2(x0 + length * 0.5, jy)
			var gap: int = rng.randi_range(2, length - 3)
			for i: int in length:
				pts.append([Vector2i(x0 + i, jy), M, 0.3])
				if i > 0 and i < length - 1 and i != gap:
					pts.append([Vector2i(x0 + i, jy - 1), M, 0.5])
				# o tufo passa por cima do nariz do degrau de trás
				if i > 1 and i < length - 2 and i != gap + 1:
					pts.append([Vector2i(x0 + i, jy + 1), M, 0.5])
			for i: int in [1, length - 2]:
				pts.append([Vector2i(x0 + i, jy - 1), G, 0.6])
				pts.append([Vector2i(x0 + i, jy - 2), G, 0.6])
		else:
			# na junta lateral
			var r: int = rng.randi_range(0, 1)
			var js: Array = bands[r]
			var jx: int = js[rng.randi_range(0, js.size() - 1)]
			var y0: int = r * 16 + rng.randi_range(4, 8)
			var length: int = rng.randi_range(4, 6)
			var side: int = 1 if rng.randf() < 0.5 else -1
			c = Vector2(jx, y0 + length * 0.5)
			for i: int in length:
				pts.append([Vector2i(jx, y0 + i), M, 0.3])
				if i > 0 and i < length - 1:
					pts.append([Vector2i(jx + side, y0 + i), M, 0.5])
			pts.append([Vector2i(jx - side, y0 + 1), G, 0.6])
			pts.append([Vector2i(jx - side, y0), G, 0.6])
		if not _wfar(centers, c, 9.0):
			continue
		for it: Array in pts:
			var p: Vector2i = it[0]
			cv.put(p.x, p.y, it[1], it[2])
		centers.append(c)
	return cv


static func _poisson(rng: RandomNumberGenerator, dmin: float, max_n: int, existing: Array, lo: float, hi: float) -> Array:
	var out: Array = []
	var tries: int = 0
	while out.size() < max_n and tries < 4000:
		tries += 1
		var p: Vector2 = Vector2(rng.randf_range(lo, hi), rng.randf_range(lo, hi))
		var ok: bool = true
		for q: Vector2 in existing:
			if wdist(p, q) < dmin:
				ok = false
		for q: Vector2 in out:
			if wdist(p, q) < dmin:
				ok = false
		if ok:
			out.append(p)
	return out


## Extensão (largura e altura, com wrap) de cada laje está em [lo, hi].
static func _slabs_ok(ids: PackedInt32Array, seeds: Array, lo: int, hi: int) -> bool:
	for k: int in seeds.size():
		var s: Vector2 = seeds[k]
		var mn: Vector2 = Vector2(99, 99)
		var mx: Vector2 = Vector2(-99, -99)
		var n: int = 0
		for y: int in N:
			for x: int in N:
				if ids[y * N + x] != k:
					continue
				n += 1
				var d: Vector2 = Vector2(roundi(wrap_delta(x + 0.5 - s.x)), roundi(wrap_delta(y + 0.5 - s.y)))
				mn = Vector2(minf(mn.x, d.x), minf(mn.y, d.y))
				mx = Vector2(maxf(mx.x, d.x), maxf(mx.y, d.y))
		if n == 0:
			return false
		var w: int = int(mx.x - mn.x) + 1
		var h: int = int(mx.y - mn.y) + 1
		if w < lo or w > hi or h < lo or h > hi:
			return false
	return true


## Calçamento: lajes de 10 a 18 px, juntas de 1 px em #7A7A66, #5C6250 só nos cruzamentos, musgo.
static func _stone_paths(rng: RandomNumberGenerator) -> Array:
	# todas as lajes no tom base; a variação vem dos veios claros e das trincas dentro delas
	var body_choices: Array[int] = [P.hx("#B9B597")]
	for attempt: int in 400:
		var seeds: Array = _poisson(rng, 10.5, 10, [], 0.0, 32.0)
		if seeds.size() < 6:
			continue
		var weights: Array = []
		for k: int in seeds.size():
			weights.append(rng.randf_range(0.86, 1.14))
		var ids0: PackedInt32Array = voronoi(seeds, weights)[0]
		if not _slabs_ok(ids0, seeds, 10, 18):
			continue
		# lajes do miolo (longe da borda): só elas mudam na variante 1
		var inner: Array[int] = []
		for k: int in seeds.size():
			var q: Vector2 = seeds[k]
			if minf(minf(q.x, 32.0 - q.x), minf(q.y, 32.0 - q.y)) >= 8.5:
				inner.append(k)
		if inner.is_empty():
			continue
		var tones: Array = _slab_tones(rng, ids0, seeds.size(), body_choices)
		# variante 1: as lajes do miolo se deslocam e trocam de tom; a faixa de 3 px da borda fica igual
		var found: bool = false
		var seeds1: Array = []
		var tones1: Array = []
		var ids1: PackedInt32Array = PackedInt32Array()
		for t: int in 120:
			seeds1 = seeds.duplicate()
			for k: int in inner:
				seeds1[k] = (seeds[k] as Vector2) + Vector2(rng.randf_range(-3.5, 3.5), rng.randf_range(-3.5, 3.5))
			ids1 = voronoi(seeds1, weights)[0]
			if not _slabs_ok(ids1, seeds1, 10, 18):
				continue
			var same: bool = true
			for y: int in N:
				for x: int in N:
					if (x < 3 or y < 3 or x >= N - 3 or y >= N - 3) and ids0[y * N + x] != ids1[y * N + x]:
						same = false
			if same:
				found = true
				break
		if not found:
			continue
		tones1 = tones.duplicate()
		var v0: RefCounted = _path_render(rng, ids0, tones)
		var v1: RefCounted = _path_render(rng, ids1, tones1)
		# faixa de 2 px nas bordas idêntica à da variante 0 (as duas emendam entre si)
		for y: int in N:
			for x: int in N:
				if x < 2 or y < 2 or x >= N - 2 or y >= N - 2:
					v1.put(x, y, v0.get_c(x, y), v0.get_z(x, y))
		return [v0, v1]
	push_error("stone_path: sem solução")
	return [Canvas.new(N, N), Canvas.new(N, N)]


## Tom de cada laje, evitando o mesmo tom em lajes vizinhas quando dá.
static func _slab_tones(rng: RandomNumberGenerator, ids: PackedInt32Array, n: int, choices: Array[int]) -> Array:
	var nb: Array = []
	for k: int in n:
		nb.append({})
	for y: int in N:
		for x: int in N:
			var a: int = ids[y * N + x]
			for q: int in [ids[y * N + (x + 1) % N], ids[((y + 1) % N) * N + x]]:
				if q != a:
					(nb[a] as Dictionary)[q] = true
					(nb[q] as Dictionary)[a] = true
	var tones: Array = []
	tones.resize(n)
	for k: int in n:
		var pick: int = choices[rng.randi_range(0, choices.size() - 1)]
		for t: int in 6:
			var clash: bool = false
			for q: int in (nb[k] as Dictionary):
				if tones[q] != null and int(tones[q]) == pick and pick != choices[0]:
					clash = true
			if not clash:
				break
			pick = choices[rng.randi_range(0, choices.size() - 1)]
		tones[k] = pick
	return tones


static func _path_render(rng: RandomNumberGenerator, ids: PackedInt32Array, tones: Array) -> RefCounted:
	var J: int = P.hx("#7A7A66")
	var X: int = P.hx("#5C6250")
	var M: int = P.hx("#789636")
	var E: int = P.hx("#989680")
	var B: int = P.hx("#B9B597")
	var H: int = P.hx("#D3CCB4")
	var cv: RefCounted = Canvas.new(N, N)
	# junta de 1 px: o pixel cuja laje da direita ou de baixo é outra
	var other: PackedInt32Array = PackedInt32Array()
	other.resize(N * N)
	other.fill(-1)
	for y: int in N:
		for x: int in N:
			var o: int = y * N + x
			var a: int = ids[o]
			var r: int = ids[y * N + (x + 1) % N]
			var d: int = ids[((y + 1) % N) * N + x]
			if r != a or d != a:
				other[o] = r if r != a else d
				var dg: int = ids[((y + 1) % N) * N + (x + 1) % N]
				var distinct: Dictionary = {a: true, r: true, d: true, dg: true}
				cv.put(x, y, X if distinct.size() >= 3 else J, 0.0)
			else:
				cv.put(x, y, int(tones[a]), 1.0)
	_chamfer(cv, 1.0, 0.6)
	# manchas claras de desgaste (forma irregular) em parte das lajes, a 1 px das juntas
	for k: int in tones.size():
		if rng.randf() > 0.5:
			continue
		var body: int = tones[k]
		var light: int = H if body == B else B
		for t: int in 80:
			var cx: int = rng.randi_range(4, N - 5)
			var cy: int = rng.randi_range(4, N - 5)
			if ids[cy * N + cx] != k or cv.get_c(cx, cy) != body or cv.get_z(cx, cy) < 0.99:
				continue
			# veio claro: 2 linhas tortas de 2 a 5 px (não redondo)
			var pts: Array[Vector2i] = []
			var l0: int = rng.randi_range(3, 5)
			var l1: int = rng.randi_range(2, 4)
			var o1: int = rng.randi_range(-1, 2)
			for i: int in l0:
				pts.append(Vector2i(cx + i, cy))
			for i: int in l1:
				pts.append(Vector2i(cx + o1 + i, cy + 1))
			var n_ok: int = 0
			for p: Vector2i in pts:
				if p.x < 3 or p.y < 3 or p.x > N - 4 or p.y > N - 4:
					continue
				if cv.get_c(p.x, p.y) == body and cv.get_z(p.x, p.y) > 0.99:
					cv.put(p.x, p.y, light, 1.05)
					n_ok += 1
			if n_ok > 0:
				break
	fix_checker(cv)
	# marcas nas lajes: trinca de 2 a 3 px um tom abaixo, ou lasca clara (longe das juntas e da borda)
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, -1), Vector2i(0, 1)]
	for k: int in tones.size():
		var body: int = tones[k]
		var n_marks: int = rng.randi_range(1, 2)
		var done: int = 0
		for t: int in 120:
			if done >= n_marks:
				break
			var x0: int = rng.randi_range(3, N - 6)
			var y0: int = rng.randi_range(3, N - 5)
			if ids[y0 * N + x0] != k or cv.get_c(x0, y0) != body:
				continue
			var d: Vector2i = dirs[rng.randi_range(0, 3)]
			var ml: int = rng.randi_range(2, 3)
			var pts: Array[Vector2i] = []
			for q: int in ml:
				pts.append(Vector2i(x0, y0) + d * q)
			var ok: bool = _free(cv, pts, body)
			for p: Vector2i in pts:
				if p.x < 3 or p.y < 3 or p.x > N - 4 or p.y > N - 4:
					ok = false
			if not ok:
				continue
			var col: int = B
			if body == B:
				col = E if done == 0 else H
			for p: Vector2i in pts:
				cv.put(p.x, p.y, col, 0.8 if P.luma(col) < P.luma(body) else 1.05)
			done += 1
	# musgo em 3 trechos de junta (o meio de cada trecho entre duas lajes)
	var pairs: Dictionary = {}
	for y: int in range(3, N - 3):
		for x: int in range(3, N - 3):
			var o: int = y * N + x
			if other[o] < 0 or cv.c[o] != J:
				continue
			var a: int = ids[o]
			var key: int = mini(a, other[o]) * 100 + maxi(a, other[o])
			if not pairs.has(key):
				pairs[key] = []
			(pairs[key] as Array).append(Vector2i(x, y))
	var keys: Array = []
	for key: int in pairs:
		if (pairs[key] as Array).size() >= 8:
			keys.append(key)
	keys.sort()
	var n_moss: int = mini(3, keys.size())
	for t: int in n_moss:
		var key: int = keys.pop_at(rng.randi_range(0, keys.size() - 1))
		var pts: Array = pairs[key]
		var mnx: int = 99
		var mxx: int = -99
		var mny: int = 99
		var mxy: int = -99
		for q: Vector2i in pts:
			mnx = mini(mnx, q.x)
			mxx = maxi(mxx, q.x)
			mny = mini(mny, q.y)
			mxy = maxi(mxy, q.y)
		var by_x: bool = (mxx - mnx) >= (mxy - mny)
		# ordena ao longo do trecho
		pts.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			if by_x:
				return a.x < b.x or (a.x == b.x and a.y < b.y)
			return a.y < b.y or (a.y == b.y and a.x < b.x))
		var lo: int = pts.size() / 4
		var hi: int = pts.size() * 3 / 4
		var spill: int = 0
		for k: int in range(lo, hi):
			var q: Vector2i = pts[k]
			cv.put(q.x, q.y, M, 0.3)
			# o musgo invade a laje em 1 ou 2 pontos (tufo, não linha)
			if spill < 2 and k > lo and k < hi - 1 and rng.randf() < 0.3:
				for dd: Vector2i in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(1, 0)]:
					var s: Vector2i = q + dd
					var cs: int = cv.get_c(s.x, s.y)
					if cs == E or cs == B or cs == H:
						cv.put(s.x, s.y, M, 0.5)
						spill += 1
						break
	return cv


## Topo do muro: musgo com tufos claros (até 2x2) sobre sombra, e 2 a 3 falhas de pedra alongadas.
static func _wall_top(rng: RandomNumberGenerator) -> RefCounted:
	var Md: int = P.hx("#5E7C26")
	var M: int = P.hx("#789636")
	var Ml: int = P.hx("#8FAE48")
	var E: int = P.hx("#989680")
	var B: int = P.hx("#B9B597")
	var H: int = P.hx("#D3CCB4")
	var cv: RefCounted = Canvas.new(N, N)
	cv.fill(M, 1.2)
	# falhas de pedra: irregulares, alongadas, borda de baixo em #989680
	var stones: Array = [
		["BHBB..", ".BBBBB", "..EEEE"],
		[".BBB", "BBBB", "EEE."],
		["BBB", "EEE"],
		["BBHB.", ".EEEE"],
		["BBBB.", "BBBBB", ".EE.E"],
		[".BBBB", "EEEE."],
	]
	var n_st: int = rng.randi_range(2, 3)
	var placed: Array[Vector2] = []
	var order: Array[int] = [0, 1, 2, 3, 4, 5]
	for t: int in 2000:
		if placed.size() >= n_st:
			break
		var p: Vector2 = Vector2(rng.randi_range(0, N - 1), rng.randi_range(0, N - 1))
		var ok: bool = true
		for q: Vector2 in placed:
			# longe e fora da mesma linha (sem fileira de bolinhas ao longo do muro)
			if wdist(p, q) < 11.0 or absf(wrap_delta(p.y - q.y)) < 7.0:
				ok = false
		if not ok:
			continue
		var rows: Array = stones[order.pop_at(rng.randi_range(0, order.size() - 1))]
		var mark: Array = _rows_to_mark(rows, {"B": B, "H": H, "E": E})
		for it: Array in mark:
			var c: int = it[1]
			var q: Vector2i = (it[0] as Vector2i) + Vector2i(int(p.x), int(p.y))
			cv.put(q.x, q.y, c, 0.55 if c == E else (0.75 if c == H else 0.7))
		placed.append(p)
	# almofadas de musgo: corpo mais alto (só no normal map), sombra #5E7C26 na borda de baixo
	# e 1 ou 2 tufos claros (até 2x2) no alto de cada uma
	var tufts: Array = [["LL"], ["L.", "LL"], ["LL", "LL"], [".L", "LL"], ["LL", "L."]]
	var avoid: Array[Vector2] = []
	for q: Vector2 in placed:
		avoid.append(q + Vector2(2, 1))
	var cush: Array[Vector2] = []
	for t: int in 3000:
		if cush.size() >= 7:
			break
		var c: Vector2 = Vector2(rng.randf_range(0, 32), rng.randf_range(0, 32))
		if not _wfar(cush, c, 9.0) or not _wfar(avoid, c, 6.5):
			continue
		cush.append(c)
	for c: Vector2 in cush:
		var rx: float = rng.randf_range(3.2, 5.2)
		var ry: float = rng.randf_range(2.0, 3.0)
		for p: Vector2i in ellipse_pts(c.x, c.y, rx, ry):
			if cv.get_c(p.x, p.y) == M:
				cv.put_z(p.x, p.y, 1.45)
		# sombra: arco de baixo, 1 px (2 px no meio)
		# arco torto e incompleto (não vira um "sorriso" repetido)
		var a0: int = -floori(rx) + 1 + rng.randi_range(0, 1)
		var a1: int = floori(rx) - rng.randi_range(0, 2)
		var lift: int = 0
		for dx: int in range(a0, a1):
			var u: float = (dx + 0.5) / rx
			if rng.randf() < 0.3:
				lift = 1 - lift
			var yb: int = floori(c.y + ry * sqrt(maxf(0.0, 1.0 - u * u))) - lift
			var x: int = floori(c.x) + dx
			for yy: int in [yb, yb + 1] if absf(u) < 0.35 else [yb]:
				if cv.get_c(x, yy) == M:
					cv.put(x, yy, Md, 1.0)
		# tufos claros no alto da almofada
		var nt: int = rng.randi_range(1, 2)
		for k: int in nt:
			for t: int in 30:
				var rows: Array = tufts[rng.randi_range(0, tufts.size() - 1)]
				var o: Vector2i = Vector2i(floori(c.x + rng.randf_range(-rx * 0.5, rx * 0.4)), floori(c.y - ry + rng.randf_range(0.5, 1.5)))
				var mark: Array = _rows_to_mark(rows, {"L": Ml})
				var pts: Array[Vector2i] = []
				for it: Array in mark:
					pts.append((it[0] as Vector2i) + o)
				if not _free(cv, pts, M):
					continue
				for p: Vector2i in pts:
					cv.put(p.x, p.y, Ml, 1.6)
				break
	fix_checker(cv)
	return cv


## Distância mínima no toro.
static func _wfar(centers: Array[Vector2], p: Vector2, dmin: float) -> bool:
	for q: Vector2 in centers:
		if wdist(q, p) < dmin:
			return false
	return true


static func _step_side(rng: RandomNumberGenerator) -> RefCounted:
	var D0: int = P.hx("#3E3226")
	var D1: int = P.hx("#5A4632")
	var D2: int = P.hx("#7A6444")
	var S: int = P.hx("#7A7A66")
	var SL: int = P.hx("#989680")
	var Mo: int = P.hx("#5E7C26")
	var cv: RefCounted = Canvas.new(N, N)
	cv.fill(D1, 0.6)
	for band: int in 2:
		var y_end: int = band * 16 + 15
		# junta escura e irregular no fim da faixa
		for x: int in N:
			cv.put(x, y_end, D0, 0.0)
		var x: int = rng.randi_range(0, 5)
		while x < N + 2:
			var run: int = rng.randi_range(2, 5)
			for i: int in run:
				cv.put(x + i, y_end - 1, D0, 0.1)
			if rng.randf() < 0.4:
				cv.put(x + 1, y_end - 2, D0, 0.2)
				cv.put(x + 2, y_end - 2, D0, 0.2)
			x += run + rng.randi_range(3, 7)
		# 2 pedras por faixa (uma grande, uma pequena), formas irregulares, abaixo da linha 4 na A
		var xs: float = rng.randf_range(0, 32)
		for k: int in 2:
			var big: bool = k == 0
			var rx: float = rng.randf_range(5.0, 6.8) if big else rng.randf_range(2.8, 3.8)
			var ry: float = rng.randf_range(2.8, 3.6) if big else rng.randf_range(2.0, 2.6)
			var cx: float = xs + k * rng.randf_range(13.0, 19.0)
			var cy: float = band * 16 + (rng.randf_range(7.5, 9.0) if big else rng.randf_range(9.0, 11.0))
			var pts: Array[Vector2i] = ellipse_pts(cx, cy, rx, ry)
			pts.append_array(ellipse_pts(cx + rng.randf_range(-rx * 0.6, rx * 0.6), cy + rng.randf_range(0.3, 1.2), rx * 0.6, ry * 0.8))
			var top: Dictionary = {}
			for p: Vector2i in pts:
				var key: int = posmod(p.x, N)
				top[key] = mini(int(top.get(key, 999)), p.y)
			for p: Vector2i in pts:
				var col: int = S
				if p.y <= int(top[posmod(p.x, N)]) + 1:
					col = SL
				cv.put(p.x, p.y, col, 1.0)
			# sombra embaixo da pedra
			var bottom: Dictionary = {}
			for p: Vector2i in pts:
				var key: int = posmod(p.x, N)
				bottom[key] = maxi(int(bottom.get(key, -999)), p.y)
			for key: int in bottom:
				cv.put(key, int(bottom[key]) + 1, D0, 0.2)
			# musgo no topo de uma das pedras
			if k == 0:
				var tx: int = roundi(cx) - 2
				for i: int in rng.randi_range(4, 6):
					var xx: int = tx + i
					if top.has(posmod(xx, N)):
						cv.put(xx, int(top[posmod(xx, N)]), Mo, 1.1)
		# torrões de terra: topo claro e fenda escura
		for t: int in 5:
			var ox: int = rng.randi_range(0, N - 1)
			var oy: int = band * 16 + rng.randi_range(1, 12)
			if cv.get_c(ox, oy) != D1 or cv.get_c(ox + 3, oy) != D1 or cv.get_c(ox, oy + 1) != D1:
				continue
			var length: int = rng.randi_range(2, 4)
			for i: int in length:
				cv.put(ox + i, oy, D2, 0.8)
			if rng.randf() < 0.6 and cv.get_c(ox + 1, oy + 1) == D1:
				cv.put(ox + 1, oy + 1, D0, 0.3)
				cv.put(ox + 2, oy + 1, D0, 0.3)
	_chamfer(cv, 1.0, 0.75)
	return cv


static func _step_side_grass(side: RefCounted, rng: RandomNumberGenerator) -> RefCounted:
	var D0: int = P.hx("#3E3226")
	var D1: int = P.hx("#5A4632")
	var D2: int = P.hx("#7A6444")
	var cv: RefCounted = side.clone()
	# linhas 0 a 3: terra escura (embaixo da franja de grama) com raízes
	for y: int in 4:
		for x: int in N:
			cv.put(x, y, D0, 0.3)
	# borda de baixo da terra escura irregular
	var x: int = rng.randi_range(0, 4)
	while x < N:
		var run: int = rng.randi_range(2, 5)
		if rng.randf() < 0.6:
			for i: int in run:
				if cv.get_c(x + i, 4) == D1:
					cv.put(x + i, 4, D0, 0.35)
		x += run + rng.randi_range(2, 5)
	# raízes: fios de 1 px descendo e ondulando
	var nr: int = 3
	var x0: float = rng.randf_range(0, 32)
	for r: int in nr:
		var rx: int = roundi(x0 + r * 10.7 + rng.randf_range(-2, 2))
		var length: int = rng.randi_range(5, 9)
		var drift: int = 1 if rng.randf() < 0.5 else -1
		var yy: int = 0
		for t: int in length:
			cv.put(rx, yy, D2 if t < length - 2 else D1, 0.6)
			yy += 1
			if t % 3 == 2:
				rx += drift
		# raiz lateral curta
		cv.put(rx - drift, 1, D2, 0.6)
		cv.put(rx - 2 * drift, 2, D1, 0.6)
	return cv


static func _rock(rng: RandomNumberGenerator) -> RefCounted:
	var C: int = P.hx("#5C6250")
	var tones: Array[int] = [P.hx("#B9B597"), P.hx("#989680"), P.hx("#7A7A66"), P.hx("#989680")]
	var seeds: Array = []
	var weights: Array = []
	var base: Vector2 = Vector2(rng.randf_range(0, 32), rng.randf_range(0, 32))
	for k: int in 4:
		var p: Vector2 = base + Vector2((k % 2) * 16.0 + (k / 2) * 8.0, (k / 2) * 16.0) + Vector2(rng.randf_range(-3, 3), rng.randf_range(-3, 3))
		seeds.append(Vector2(fposmod(p.x, 32.0), fposmod(p.y, 32.0)))
		weights.append(rng.randf_range(0.9, 1.1))
	var vr: Array = voronoi(seeds, weights)
	var ids: PackedInt32Array = vr[0]
	var gap: PackedFloat32Array = vr[1]
	var cv: RefCounted = Canvas.new(N, N)
	for y: int in N:
		for x: int in N:
			var o: int = y * N + x
			if gap[o] < 1.1:
				cv.put(x, y, C, 0.0)
			else:
				cv.put(x, y, tones[ids[o]], 1.0)
	_chamfer(cv, 1.0, 0.6)
	# grão: 2 marcas por faceta, um tom acima ou abaixo
	for k: int in seeds.size():
		for t: int in 2:
			for attempt: int in 30:
				var s: Vector2 = seeds[k]
				var ox: int = roundi(s.x + rng.randf_range(-6, 6))
				var oy: int = roundi(s.y + rng.randf_range(-6, 6))
				var d: Vector2i = DIRS[rng.randi_range(0, 3)]
				var ok: bool = true
				for q: int in 3:
					var px: Vector2i = Vector2i(ox, oy) + d * q
					for j: int in range(-1, 2):
						for i: int in range(-1, 2):
							if cv.get_c(px.x + i, px.y + j) != tones[k] or cv.get_z(px.x + i, px.y + j) < 0.9:
								ok = false
				if not ok:
					continue
				# só tons já usados: a faceta mais clara ganha grão escuro, as outras alternam
				var up: bool = t == 0 and tones[k] != P.hx("#B9B597")
				var col: int = P.shift(tones[k], 1 if up else -1)
				for q: int in rng.randi_range(2, 3):
					var px: Vector2i = Vector2i(ox, oy) + d * q
					cv.put(px.x, px.y, col, 1.0)
				break
	# 2 manchas de musgo
	var M: int = P.hx("#789636")
	var Md: int = P.hx("#5E7C26")
	for m: int in 2:
		var cx: float = rng.randf_range(0, 32)
		var cy: float = rng.randf_range(0, 32)
		var pts: Array[Vector2i] = ellipse_pts(cx, cy, rng.randf_range(2.8, 4.2), rng.randf_range(1.8, 2.6))
		pts.append_array(ellipse_pts(cx + rng.randf_range(-3, 3), cy + rng.randf_range(-1, 1), 2.2, 1.6))
		for p: Vector2i in pts:
			cv.put(p.x, p.y, M, 1.15)
		for p: Vector2i in ellipse_pts(cx + 0.5, cy + 0.5, 1.6, 0.9):
			cv.put(p.x, p.y, Md, 1.05)
	return cv


static func _monolith(rng: RandomNumberGenerator) -> RefCounted:
	var K: int = P.hx("#33454C")
	var Dk: int = P.hx("#4E6266")
	var B: int = P.hx("#6E8482")
	var L: int = P.hx("#93A6A0")
	var cv: RefCounted = Canvas.new(N, N)
	cv.fill(B, 0.5)
	# grão grosso: manchas de 4 a 8 px
	var centers: Array[Vector2] = []
	var target: int = 12
	var tries: int = 0
	while centers.size() < target and tries < 500:
		tries += 1
		var p: Vector2 = Vector2(rng.randf_range(0, 32), rng.randf_range(0, 32))
		var ok: bool = true
		for q: Vector2 in centers:
			if wdist(p, q) < 6.0:
				ok = false
		if not ok:
			continue
		centers.append(p)
		var light: bool = centers.size() % 2 == 0
		var rx: float = rng.randf_range(1.4, 2.4)
		var ry: float = rng.randf_range(0.9, 1.5)
		for px: Vector2i in ellipse_pts(p.x, p.y, rx, ry):
			cv.put(px.x, px.y, L if light else Dk, 0.65 if light else 0.35)
	# 2 rachaduras quase verticais
	for k: int in 2:
		var x: int = rng.randi_range(0, N - 1) + k * 16
		var y: int = rng.randi_range(0, N - 1)
		var length: int = rng.randi_range(12, 20)
		for t: int in length:
			cv.put(x, y + t, K, 0.0)
			if t % 4 == 3:
				x += 1 if rng.randf() < 0.5 else -1
				cv.put(x, y + t, K, 0.0)
	# musgo na base (atravessa a linha 31 -> 0 para emendar)
	var Mo: int = P.hx("#496819")
	var Ml: int = P.hx("#5E7C26")
	for k: int in 2:
		var cx: float = rng.randf_range(0, 32) + k * 16.0
		var w: int = rng.randi_range(5, 8)
		var x0: int = roundi(cx)
		for i: int in w:
			var hgt: int = 2 + int(i > 0 and i < w - 1) + int(i > 1 and i < w - 2)
			for t: int in hgt:
				cv.put(x0 + i, 31 - t + 1, Mo if t < hgt - 1 else Ml, 0.7)
	return cv


# ---------------------------------------------------------------------------
# Madeira e folhagem
# ---------------------------------------------------------------------------

static func _bark_0(rng: RandomNumberGenerator) -> RefCounted:
	var G0: int = P.hx("#2C212D")
	var G1: int = P.hx("#4B3339")
	var PL: int = P.hx("#6B4C3E")
	var HL: int = P.hx("#876547")
	var cv: RefCounted = Canvas.new(N, N)
	cv.fill(PL, 1.0)
	# 5 sulcos verticais ondulados (período 32 para emendar)
	var gx: Array[float] = []
	var off: float = rng.randf_range(0, 6.4)
	for k: int in 5:
		gx.append(off + k * 6.4 + rng.randf_range(-0.8, 0.8))
	var groove_x: Array = []
	for k: int in 5:
		var amp: float = rng.randf_range(0.8, 1.4)
		var ph: float = rng.randf_range(0, TAU)
		var freq: int = rng.randi_range(1, 2)
		var wide: bool = k % 2 == 0
		var xs: Array[int] = []
		for y: int in N:
			var x: int = roundi(gx[k] + amp * sin(TAU * freq * y / 32.0 + ph))
			xs.append(x)
			cv.put(x, y, G0, 0.0)
			if wide:
				cv.put(x + 1, y, G1, 0.3)
		groove_x.append(xs)
	# quebras horizontais nas placas: topo da placa claro
	for k: int in 5:
		var xa: Array = groove_x[k]
		var xb: Array = groove_x[(k + 1) % 5]
		var y: int = rng.randi_range(0, 8)
		while y < N:
			var x_from: int = int(xa[y]) + (2 if k % 2 == 0 else 1)
			var x_to: int = int(xb[y]) + (32 if k == 4 else 0)
			for x: int in range(x_from, x_to):
				cv.put(x, y, G1, 0.35)
				cv.put(x, y + 1, HL, 1.0)
			y += rng.randi_range(8, 12)
	# musgo em 1 placa
	var Mo: int = P.hx("#5E7C26")
	var Ml: int = P.hx("#789636")
	var k: int = rng.randi_range(0, 4)
	var xa: Array = groove_x[k]
	var y0: int = rng.randi_range(0, 31)
	for t: int in 6:
		var yy: int = y0 + t
		var x_from: int = int(xa[posmod(yy, N)]) + (2 if k % 2 == 0 else 1)
		var wv: int = 3 if t == 0 or t == 5 else 4
		for i: int in wv:
			if cv.get_c(x_from + i, yy) == PL or cv.get_c(x_from + i, yy) == HL:
				cv.put(x_from + i, yy, Ml if t < 2 else Mo, 1.1)
	return cv


static func _bark_1(rng: RandomNumberGenerator) -> RefCounted:
	var C0: int = P.hx("#1A1426")
	var C1: int = P.hx("#2C212D")
	var C2: int = P.hx("#4B3339")
	var C3: int = P.hx("#6B4C3E")
	var cv: RefCounted = Canvas.new(N, N)
	cv.fill(C2, 1.0)
	# colunas de placas (5 a 8 px de largura), cada uma partida em escamas de 6 a 11 px de altura
	var widths: Array[int] = _split(rng, N, 5, 8)
	var x0: int = rng.randi_range(0, N - 1)
	for wv: int in widths:
		var heights: Array[int] = _split(rng, N, 6, 11)
		var y0: int = rng.randi_range(0, N - 1)
		for hv: int in heights:
			for i: int in wv:
				for t: int in hv:
					var col: int = C2
					var zv: float = 1.0
					if i == 0:
						col = C0
						zv = 0.0
					elif t == hv - 1:
						col = C1
						zv = 0.45
					elif t == 0:
						col = C3
					elif t == 1 and i > 1 and i < wv - 1:
						col = C3
					cv.put(x0 + i, y0 + t, col, zv)
			# canto de baixo arredondado
			cv.put(x0 + wv - 1, y0 + hv - 1, C0, 0.0)
			cv.put(x0 + 1, y0 + hv - 1, C0, 0.0)
			y0 += hv
		x0 += wv
	return cv


static func _wood_end(rng: RandomNumberGenerator) -> RefCounted:
	var BO: int = P.hx("#4B3339")
	var BI: int = P.hx("#6B4C3E")
	var CR: int = P.hx("#876547")
	var R1: int = P.hx("#A37C56")
	var R2: int = P.hx("#C29A6C")
	var W: int = P.hx("#D9BC86")
	var cv: RefCounted = Canvas.new(N, N)
	var ph: float = rng.randf_range(0, TAU)
	var rings: Array = [[3.0, R2], [6.2, R1], [9.2, R2], [12.0, R1]]
	for y: int in N:
		for x: int in N:
			var dx: float = x + 0.5 - 16.0
			var dy: float = y + 0.5 - 16.0
			var r: float = sqrt(dx * dx + dy * dy)
			var a: float = atan2(dy, dx)
			var rr: float = r + 0.45 * sin(3.0 * a + ph) * clampf(r / 8.0, 0.0, 1.0)
			var col: int = W
			var zv: float = 1.0
			if rr >= 14.4:
				col = BO
				zv = 0.7
			elif rr >= 12.9:
				col = BI
				zv = 0.9
			elif r < 1.2:
				col = R2
				zv = 0.85
			else:
				for ring: Array in rings:
					if absf(rr - float(ring[0])) < 0.5:
						col = ring[1]
						zv = 0.8
			cv.put(x, y, col, zv)
	# rachadura radial
	var ang: float = rng.randf_range(0, TAU)
	var p0: Vector2i = Vector2i(roundi(16.0 + 2.5 * cos(ang)), roundi(16.0 + 2.5 * sin(ang)))
	var p1: Vector2i = Vector2i(roundi(16.0 + 11.5 * cos(ang)), roundi(16.0 + 11.5 * sin(ang)))
	var pts: Array[Vector2i] = Canvas.line_pts(p0.x, p0.y, p1.x, p1.y)
	for i: int in pts.size():
		cv.put(pts[i].x, pts[i].y, CR, 0.4)
	return cv


static func _moss(rng: RandomNumberGenerator) -> RefCounted:
	var Md: int = P.hx("#5E7C26")
	var M: int = P.hx("#789636")
	var Ml: int = P.hx("#8FAE48")
	var Mh: int = P.hx("#B0C860")
	var cv: RefCounted = Canvas.new(N, N)
	cv.fill(M, 1.0)
	var tufts: Array = [["LL", "LL"], [".L.", "LHL"], ["LL.", ".LL"], ["HL", "LL"], ["LLL", ".L."], ["L.", "LL"], [".L", "LL", ".L"]]
	var crev: Array = [["DD"], ["D.", ".D"], [".D", "D."], ["DDD"], ["D", "D"]]
	var centers: Array[Vector2] = []
	for t: int in 300:
		var is_tuft: bool = t % 5 < 3
		var rows: Array = tufts[rng.randi_range(0, tufts.size() - 1)] if is_tuft else crev[rng.randi_range(0, crev.size() - 1)]
		var ox: int = rng.randi_range(0, N - 1)
		var oy: int = rng.randi_range(0, N - 1)
		var ok: bool = true
		for q: Vector2 in centers:
			if wdist(Vector2(ox, oy), q) < 4.2:
				ok = false
		var mark: Array = _rows_to_mark(rows, {"L": Ml, "H": Mh, "D": Md})
		for it: Array in mark:
			var p: Vector2i = (it[0] as Vector2i) + Vector2i(ox, oy)
			for j: int in range(-1, 2):
				for i: int in range(-1, 2):
					if cv.get_c(p.x + i, p.y + j) != M:
						ok = false
		if not ok:
			continue
		for it: Array in mark:
			var p: Vector2i = (it[0] as Vector2i) + Vector2i(ox, oy)
			cv.put(p.x, p.y, it[1], 1.0)
		centers.append(Vector2(ox, oy))
	return cv


static func _leaves_mass(rng: RandomNumberGenerator) -> RefCounted:
	var L0: int = P.hx("#123B32")
	var L1: int = P.hx("#1F5530")
	var L2: int = P.hx("#2F6A2A")
	var L3: int = P.hx("#437B25")
	var cv: RefCounted = Canvas.new(N, N)
	cv.fill(L1, 1.0)
	# aglomerados de folhas: topo um tom acima, fenda escura embaixo
	var clumps: Array = [
		[".T.", "BBB", ".D."], ["TT.", "BBB", ".DD"], [".TT", "BB.", "D.."], ["TT", "BB", "D."],
		["T..", "BB.", ".BD"], [".T", "BB", "BD"],
	]
	var centers: Array[Vector2] = []
	for t: int in 300:
		var rows: Array = clumps[rng.randi_range(0, clumps.size() - 1)]
		var ox: int = rng.randi_range(0, N - 1)
		var oy: int = rng.randi_range(0, N - 1)
		var ok: bool = true
		for q: Vector2 in centers:
			if wdist(Vector2(ox, oy), q) < 5.0:
				ok = false
		var mark: Array = _rows_to_mark(rows, {"T": L3, "B": L2, "D": L0})
		for it: Array in mark:
			var p: Vector2i = (it[0] as Vector2i) + Vector2i(ox, oy)
			for j: int in range(-1, 2):
				for i: int in range(-1, 2):
					if cv.get_c(p.x + i, p.y + j) != L1:
						ok = false
		if not ok:
			continue
		for it: Array in mark:
			var p: Vector2i = (it[0] as Vector2i) + Vector2i(ox, oy)
			cv.put(p.x, p.y, it[1], 1.0)
		centers.append(Vector2(ox, oy))
	return cv
