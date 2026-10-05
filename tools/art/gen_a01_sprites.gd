extends RefCounted
## Sprites em pé da A01 (vista de frente, leve 3/4 de cima). Sem class_name: usar via preload.
## Monta por formas (bolhas, troncos, blocos), sombreia em 3 tons e só no fim aplica o contorno.

const P = preload("res://tools/art/palette.gd")
const L = preload("res://tools/art/art_lib.gd")

# Materiais (definem a cor do contorno)
const M_NONE: int = 0
const M_LEAF: int = 1
const M_WOOD: int = 2
const M_STONE: int = 3
const M_PLANT: int = 4


class Canvas:
	var w: int
	var h: int
	var img: Image
	var mat: PackedByteArray

	func _init(width: int, height: int) -> void:
		w = width
		h = height
		img = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		mat = PackedByteArray()
		mat.resize(w * h)

	func inside(x: int, y: int) -> bool:
		return x >= 0 and y >= 0 and x < w and y < h

	func put(x: int, y: int, c: Color, m: int) -> void:
		if inside(x, y):
			img.set_pixel(x, y, c)
			mat[y * w + x] = m

	func clear_px(x: int, y: int) -> void:
		if inside(x, y):
			img.set_pixel(x, y, Color(0, 0, 0, 0))
			mat[y * w + x] = M_NONE

	func m_at(x: int, y: int) -> int:
		if not inside(x, y):
			return M_NONE
		return mat[y * w + x]

	func c_at(x: int, y: int) -> Color:
		return img.get_pixel(x, y)

	func filled(x: int, y: int) -> bool:
		return m_at(x, y) != M_NONE

	func n4(x: int, y: int) -> int:
		var n: int = 0
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if filled(x + d.x, y + d.y):
				n += 1
		return n

	# Remove pontas de 1 px e preenche entalhes de 1 px na silhueta
	func smooth_silhouette(passes: int) -> void:
		for p: int in passes:
			var to_clear: Array[Vector2i] = []
			var to_fill: Array[Vector2i] = []
			for y: int in h:
				for x: int in w:
					if filled(x, y):
						if n4(x, y) <= 1:
							to_clear.append(Vector2i(x, y))
					elif n4(x, y) >= 3:
						to_fill.append(Vector2i(x, y))
			for q: Vector2i in to_clear:
				clear_px(q.x, q.y)
			for q: Vector2i in to_fill:
				var src: Vector2i = q
				for d: Vector2i in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)]:
					if filled(q.x + d.x, q.y + d.y):
						src = q + d
						break
				put(q.x, q.y, c_at(src.x, src.y), m_at(src.x, src.y))

	# Contorno de 1 px por fora (vizinhança 4); cor pelo material vizinho, na ordem de prioridade
	func outline(colors: Dictionary, priority: Array) -> void:
		var adds: Array = []
		for y: int in h:
			for x: int in w:
				if filled(x, y):
					continue
				var found: Array[int] = []
				for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var m: int = m_at(x + d.x, y + d.y)
					if m != M_NONE:
						found.append(m)
				if found.is_empty():
					continue
				var pick: int = found[0]
				for m: int in priority:
					if m in found:
						pick = m
						break
				adds.append([Vector2i(x, y), pick])
		for a: Array in adds:
			var q: Vector2i = a[0]
			put(q.x, q.y, colors[a[1]], a[1])

	# Pixel órfão (sem vizinho-8 da mesma cor) vira a cor mais comum em volta
	# keep: cores que nunca mudam; avoid: cores que não servem de substituta (ex.: contorno)
	func clean_orphans(keep: Array, avoid: Array = []) -> void:
		var changes: Array = []
		for y: int in h:
			for x: int in w:
				if not filled(x, y):
					continue
				var c: Color = c_at(x, y)
				if _has_color(keep, c) or _has_color(avoid, c):
					continue
				var counts: Dictionary = {}
				var alone: bool = true
				for dy: int in range(-1, 2):
					for dx: int in range(-1, 2):
						if dx == 0 and dy == 0:
							continue
						if not filled(x + dx, y + dy):
							continue
						var nc: Color = c_at(x + dx, y + dy)
						if nc.to_rgba32() == c.to_rgba32():
							alone = false
						if _has_color(avoid, nc):
							continue
						var k: int = nc.to_rgba32()
						counts[k] = int(counts.get(k, 0)) + 1
				if alone and not counts.is_empty():
					var best_k: int = 0
					var best_n: int = -1
					for k: int in counts:
						if counts[k] > best_n:
							best_n = counts[k]
							best_k = k
					changes.append([Vector2i(x, y), best_k])
		for ch: Array in changes:
			var q: Vector2i = ch[0]
			var k: int = ch[1]
			img.set_pixel(q.x, q.y, Color.hex(k))

	func _has_color(list: Array, c: Color) -> bool:
		for o: Color in list:
			if o.to_rgba32() == c.to_rgba32():
				return true
		return false


static func build_all() -> Dictionary:
	var out: Dictionary = {}
	for v: int in 3:
		out["tree_big_%d" % v] = tree_big(v)
	for v: int in 2:
		out["tree_small_%d" % v] = tree_small(v)
	for v: int in 3:
		out["bush_%d" % v] = bush(v)
	for v: int in 3:
		out["grass_tuft_%d" % v] = grass_tuft(v)
	for v: int in 3:
		out["flower_%d" % v] = flower(v)
	out["monolith_0"] = monolith_0()
	out["monolith_1"] = monolith_1()
	out["monolith_0_rune"] = rune_mask(out["monolith_0"])
	out["monolith_1_rune"] = rune_mask(out["monolith_1"])
	return out


static func rng_for(key: String) -> RandomNumberGenerator:
	var r: RandomNumberGenerator = RandomNumberGenerator.new()
	r.seed = key.hash()
	return r


# ---------------------------------------------------------------------------
# Copas em bolhas
# ---------------------------------------------------------------------------


# Raio com lóbulos largos (borda de folhagem em "babados" arredondados)
static func _lobed_r(b: Array, px: float, py: float) -> float:
	var r: float = b[2]
	var ang: float = atan2(py - b[1], px - b[0])
	# Bolinhas com "cúspide" entre elas (borda de nuvem), sem facetas retas
	var lobes: float = maxf(4.0, roundf(TAU * r / 9.0))
	var s: float = absf(sin((lobes * ang + b[0] * 0.37 + b[1] * 0.11) * 0.5))
	return r - 1.4 + 2.8 * sqrt(s)


static func _in_circle(px: float, py: float, cx: float, cy: float, r: float) -> bool:
	var dx: float = px - cx
	var dy: float = py - cy
	return dx * dx + dy * dy <= r * r


# Tons por índice: 0 sombra, 1 base, 2 luz, 3 brilho, 4 toque, 5 fenda
const T_SHADOW: int = 0
const T_BASE: int = 1
const T_LIGHT: int = 2
const T_SHINE: int = 3
const T_ACCENT: int = 4
const T_CREVICE: int = 5


# bubbles: [cx, cy, r, nível] (nível 0 = topo, mais luz). tones: Dictionary ou Array de Dictionaries por nível
static func paint_canopy(cv: Canvas, bubbles: Array, tones: Variant, clip_bottom: int) -> void:
	var order: Array = bubbles.duplicate()
	order.sort_custom(func(a: Array, b: Array) -> bool: return a[1] < b[1])
	var owner_idx: PackedInt32Array = PackedInt32Array()
	owner_idx.resize(cv.w * cv.h)
	owner_idx.fill(-1)
	for i: int in order.size():
		var b: Array = order[i]
		var r: float = b[2] + 2.0
		for y: int in range(maxi(0, floori(b[1] - r)), mini(cv.h, ceili(b[1] + r) + 1)):
			if y > clip_bottom:
				continue
			for x: int in range(maxi(0, floori(b[0] - r)), mini(cv.w, ceili(b[0] + r) + 1)):
				var px: float = x + 0.5
				var py: float = y + 0.5
				if _in_circle(px, py, b[0], b[1], _lobed_r(b, px, py)):
					owner_idx[y * cv.w + x] = i
	var tone: PackedInt32Array = PackedInt32Array()
	tone.resize(cv.w * cv.h)
	tone.fill(-1)
	for y: int in cv.h:
		for x: int in cv.w:
			var i: int = owner_idx[y * cv.w + x]
			if i < 0:
				continue
			var b: Array = order[i]
			var cx: float = b[0]
			var cy: float = b[1]
			var r: float = b[2]
			var lvl: int = b[3]
			var tone_dict: Dictionary = tones[mini(lvl, tones.size() - 1)] if tones is Array else tones
			var px: float = x + 0.5
			var py: float = y + 0.5
			# Calota de luz no topo-esquerda generosa (estilo cartoon), base no meio, sombra em crescente embaixo-direita
			var t: int = T_BASE
			if not _in_circle(px, py, cx - 0.16 * r, cy - 0.18 * r, r * 0.94):
				t = T_SHADOW
			elif _in_circle(px, py, cx - 0.22 * r, cy - 0.30 * r, r * (0.80 - 0.08 * lvl)):
				t = T_LIGHT
				if _in_circle(px, py, cx - 0.30 * r, cy - 0.44 * r, r * (0.56 - 0.08 * lvl)):
					t = T_SHINE
					if tone_dict.has("accent") and _in_circle(px, py, cx - 0.38 * r, cy - 0.58 * r, r * 0.35):
						t = T_ACCENT
			tone[y * cv.w + x] = t
	# Tufos internos de folha dentro da área de base e luz: dão textura e volume de folhagem cartoon
	for i: int in order.size():
		var b: Array = order[i]
		var r: float = b[2]
		if r < 10.0:
			continue
		var n: int = 3 if r >= 14.0 else 2
		for k: int in n:
			var ang: float = 0.5 + k * TAU / n + b[0] * 0.05
			var sx: float = b[0] + cos(ang) * r * 0.42
			var sy: float = b[1] + sin(ang) * r * 0.42 + r * 0.08
			var rs: float = r * 0.32
			for y: int in range(maxi(0, floori(sy - rs - 1)), mini(cv.h, ceili(sy + rs + 2))):
				for x: int in range(maxi(0, floori(sx - rs - 1)), mini(cv.w, ceili(sx + rs + 2))):
					if not cv.inside(x, y) or owner_idx[y * cv.w + x] != i:
						continue
					var k_idx: int = y * cv.w + x
					var px: float = x + 0.5
					var py: float = y + 0.5
					if not _in_circle(px, py, sx, sy, rs):
						continue
					if tone[k_idx] == T_BASE:
						if py < sy + 0.5 and px < sx + rs * 0.6 and not _in_circle(px, py, sx + 0.9, sy + 1.2, rs):
							tone[k_idx] = T_LIGHT
					elif tone[k_idx] == T_LIGHT:
						if py < sy + 0.2 and px < sx + rs * 0.4 and not _in_circle(px, py, sx + 0.8, sy + 1.0, rs):
							tone[k_idx] = T_SHINE
	var keys: Array[String] = ["shadow", "base", "light", "shine", "accent", "crevice"]
	for y: int in cv.h:
		for x: int in cv.w:
			var i: int = owner_idx[y * cv.w + x]
			if i < 0:
				continue
			var b: Array = order[i]
			var lvl: int = b[3]
			var tone_dict: Dictionary = tones[mini(lvl, tones.size() - 1)] if tones is Array else tones
			var t: int = tone[y * cv.w + x]
			# Fenda escura onde uma bolha da frente encosta nesta
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx < 0 or ny < 0 or nx >= cv.w or ny >= cv.h:
					continue
				if owner_idx[ny * cv.w + nx] > i:
					t = T_CREVICE
					break
			cv.put(x, y, tone_dict[keys[t]], M_LEAF)



# ---------------------------------------------------------------------------
# Tronco com raízes e musgo
# ---------------------------------------------------------------------------

# Desenha tronco centrado em cx, de top_y até bottom_y, meia largura hw; raízes abrem embaixo
static func paint_trunk(cv: Canvas, cx: float, top_y: int, bottom_y: int, hw: float, spread: float, flare_h: int, roots: int) -> void:
	var gap_h: int = 4
	for y: int in range(top_y, bottom_y + 1):
		var t: float = clampf(float(y - (bottom_y - flare_h)) / flare_h, 0.0, 1.0)
		var half: float = hw + spread * t * t
		for x: int in cv.w:
			var px: float = x + 0.5
			var u: float = px - cx
			if absf(u) > half:
				continue
			# Fendas curtas entre as raízes, só nas últimas linhas
			var g: float = float(y - (bottom_y - gap_h)) / gap_h
			if g > 0.0:
				var gaps: Array[float] = []
				if roots == 3:
					gaps = [-(hw * 0.5 + spread * 0.3 * g), hw * 0.5 + spread * 0.3 * g]
				else:
					gaps = [0.0]
				var in_gap: bool = false
				for gx: float in gaps:
					if absf(u - gx) < 0.3 + 0.8 * g:
						in_gap = true
				if in_gap:
					continue
			var s: float = u / half
			var c: Color = P.WOOD_1
			if s < -0.42:
				c = P.WOOD_2
			elif s > 0.38:
				c = P.WOOD_0
			cv.put(x, y, c, M_WOOD)
	# Topo das raízes iluminado
	for y: int in range(bottom_y - flare_h, bottom_y + 1):
		for x: int in cv.w:
			if cv.m_at(x, y) == M_WOOD and cv.m_at(x, y - 1) == M_NONE and x + 0.5 < cx:
				cv.put(x, y, P.WOOD_2, M_WOOD)
	# Veios da casca
	var bark: Array = [[-1, 0.25, 6], [2, 0.45, 5], [-3, 0.6, 4]]
	for b: Array in bark:
		var bx: int = int(cx) + int(b[0])
		var by: int = top_y + int((bottom_y - flare_h - top_y) * float(b[1]))
		for k: int in int(b[2]):
			if cv.m_at(bx, by + k) == M_WOOD:
				cv.put(bx, by + k, P.WOOD_0, M_WOOD)
	# Musgo nas raízes e base (referência da clareira: troncos cobertos de musgo vivo)
	for y: int in range(bottom_y - flare_h + 1, bottom_y + 1):
		var t_m: float = float(y - (bottom_y - flare_h + 1)) / float(flare_h)
		var half: float = hw + spread * t_m * t_m
		for x: int in cv.w:
			if cv.m_at(x, y) != M_WOOD:
				continue
			var px: float = x + 0.5
			var u: float = px - cx
			var is_edge: bool = absf(absf(u) - half) <= 1.4
			# Musgo na borda esquerda do tronco e na base das raízes
			if y >= bottom_y - 2 and (x + y) % 2 == 0:
				cv.put(x, y, P.GRASS_1 if u < 0 else P.GRASS_0, M_WOOD)
			elif is_edge and u < 0:
				cv.put(x, y, P.GRASS_1, M_WOOD)


# Sombra da copa no tronco + linha de contorno da copa por cima do tronco
static func shade_trunk_under_canopy(cv: Canvas, band: int) -> void:
	for x: int in cv.w:
		var last_leaf: int = -1
		for y: int in cv.h:
			var m: int = cv.m_at(x, y)
			if m == M_LEAF:
				last_leaf = y
			elif m == M_WOOD and last_leaf >= 0:
				if y - last_leaf == 1:
					cv.put(x, last_leaf, P.OUTLINE_FOREST, M_LEAF)
				var wave: int = band + (1 if (x % 5) < 2 else 0)
				if y - last_leaf <= wave:
					cv.put(x, y, P.WOOD_0, M_WOOD)


# ---------------------------------------------------------------------------
# Árvores
# ---------------------------------------------------------------------------

# Cores ricas cartoon: topo ensolarado verde-limão -> corpo esmeralda -> base bosque profundo
const BIG_TREE_TONES: Array = [
	# Nível 0: Topo ensolarado
	{
		"accent": P.GRASS_3,
		"shine": P.GRASS_3,
		"light": P.GRASS_2,
		"base": P.GRASS_1,
		"shadow": P.GRASS_0,
		"crevice": P.CANOPY_3,
	},
	# Nível 1: Miolo da copa
	{
		"accent": P.GRASS_3,
		"shine": P.GRASS_2,
		"light": P.GRASS_1,
		"base": P.CANOPY_4,
		"shadow": P.GRASS_0,
		"crevice": P.CANOPY_1,
	},
	# Nível 2: Sombra / understory
	{
		"accent": P.GRASS_2,
		"shine": P.GRASS_1,
		"light": P.CANOPY_4,
		"base": P.CANOPY_3,
		"shadow": P.CANOPY_1,
		"crevice": P.CANOPY_0,
	},
]

const SMALL_TREE_TONES: Array = [
	# Nível 0: Topo
	{
		"accent": P.GRASS_3,
		"shine": P.GRASS_3,
		"light": P.GRASS_2,
		"base": P.GRASS_1,
		"shadow": P.GRASS_0,
		"crevice": P.CANOPY_3,
	},
	# Nível 1: Base
	{
		"accent": P.GRASS_2,
		"shine": P.GRASS_1,
		"light": P.CANOPY_4,
		"base": P.CANOPY_3,
		"shadow": P.CANOPY_1,
		"crevice": P.CANOPY_0,
	},
]


static func tree_big(variant: int) -> Image:
	var cv: Canvas = Canvas.new(96, 128)
	var bubbles: Array = []
	var trunk_top: int = 76
	match variant:
		0: # redonda e larga
			bubbles = [
				[37.0, 21.0, 15.0, 0], [60.0, 22.0, 16.0, 0],
				[19.0, 45.0, 14.0, 1], [48.0, 42.0, 18.0, 0], [77.0, 46.0, 14.0, 1],
				[28.0, 70.0, 16.0, 2], [51.0, 73.0, 17.0, 1], [72.0, 70.0, 15.0, 2],
			]
		1: # oval e alta
			bubbles = [
				[48.0, 18.0, 14.0, 0],
				[34.0, 38.0, 15.0, 0], [60.0, 40.0, 15.0, 1],
				[48.0, 55.0, 17.0, 0],
				[30.0, 70.0, 14.0, 1], [64.0, 72.0, 14.0, 2],
				[46.0, 82.0, 15.0, 2],
			]
			trunk_top = 82
		_: # assimétrica (pende para a esquerda)
			bubbles = [
				[30.0, 26.0, 15.0, 0], [53.0, 20.0, 14.0, 0],
				[16.0, 50.0, 12.0, 1], [41.0, 46.0, 18.0, 0], [69.0, 40.0, 13.0, 1],
				[26.0, 72.0, 15.0, 2], [52.0, 72.0, 16.0, 1], [74.0, 64.0, 11.0, 2],
			]
			trunk_top = 78
	paint_trunk(cv, 48.0, trunk_top, 126, 7.5, 8.5, 13, 3)
	paint_canopy(cv, bubbles, BIG_TREE_TONES, 110)
	shade_trunk_under_canopy(cv, 5)
	cv.smooth_silhouette(2)
	cv.clean_orphans([P.CANOPY_4, P.CANOPY_3, P.GRASS_3, P.GRASS_2, P.GRASS_1, P.GRASS_0, P.OUTLINE_FOREST])
	cv.outline({M_LEAF: P.OUTLINE_FOREST, M_WOOD: P.OUTLINE_FOREST}, [M_LEAF, M_WOOD])
	return cv.img


static func tree_small(variant: int) -> Image:
	var cv: Canvas = Canvas.new(64, 96)
	var bubbles: Array = []
	var trunk_top: int = 52
	match variant:
		0:
			bubbles = [
				[32.0, 19.0, 13.0, 0],
				[18.0, 37.0, 11.0, 1], [32.0, 40.0, 14.0, 0], [46.0, 36.0, 11.0, 1],
				[32.0, 56.0, 12.0, 1],
			]
		_:
			bubbles = [
				[30.0, 16.0, 11.0, 0],
				[20.0, 34.0, 12.0, 0], [43.0, 31.0, 12.0, 1],
				[32.0, 50.0, 13.0, 1],
			]
			trunk_top = 48
	paint_trunk(cv, 32.0, trunk_top, 94, 4.5, 5.5, 9, 2)
	paint_canopy(cv, bubbles, SMALL_TREE_TONES, 78)
	shade_trunk_under_canopy(cv, 3)
	cv.smooth_silhouette(2)
	cv.clean_orphans([P.CANOPY_4, P.GRASS_3, P.GRASS_2, P.GRASS_1, P.OUTLINE_FOREST])
	cv.outline({M_LEAF: P.OUTLINE_FOREST, M_WOOD: P.OUTLINE_FOREST}, [M_LEAF, M_WOOD])
	return cv.img


# ---------------------------------------------------------------------------
# Arbustos
# ---------------------------------------------------------------------------

const BUSH_TONES: Dictionary = {
	"accent": P.GRASS_3,
	"shine": P.GRASS_3,
	"light": P.GRASS_2,
	"base": P.GRASS_1,
	"shadow": P.GRASS_0,
	"crevice": P.CANOPY_3,
}


static func bush(variant: int) -> Image:
	var cv: Canvas = Canvas.new(32, 32)
	var bubbles: Array = []
	match variant:
		0:
			bubbles = [[11.5, 22.0, 8.0, 1], [20.5, 21.0, 8.5, 1], [16.0, 14.0, 7.5, 0]]
		1:
			bubbles = [[10.5, 23.0, 6.5, 1], [16.0, 17.0, 8.0, 0], [21.5, 22.0, 6.5, 1], [16.0, 26.0, 6.0, 1]]
		_:
			bubbles = [[11.5, 20.0, 8.0, 0], [20.5, 19.0, 8.0, 0], [16.0, 25.0, 7.0, 1]]
	paint_canopy(cv, bubbles, BUSH_TONES, 30)
	_flatten_base(cv, 30, M_LEAF, P.GRASS_0)
	if variant == 0:
		var fl: Dictionary = {"W": P.FLOWER_WHITE, "Y": P.FLOWER_YELLOW}
		for p: Vector2i in [Vector2i(10, 15), Vector2i(20, 13), Vector2i(15, 21), Vector2i(23, 22)]:
			L.stamp(cv.img, ["WW", "WY"], p.x, p.y, fl, false)
	elif variant == 1:
		var fl: Dictionary = {"Y": P.FLOWER_YELLOW, "D": P.DIRT_1}
		for p: Vector2i in [Vector2i(9, 16), Vector2i(18, 12), Vector2i(22, 19), Vector2i(13, 23)]:
			L.stamp(cv.img, ["YY", "YD"], p.x, p.y, fl, false)
	elif variant == 2:
		var fl: Dictionary = {"F": P.FLOWER_LILAC_1, "D": P.FLOWER_LILAC_0, "P": P.FLOWER_PINK}
		for p: Vector2i in [Vector2i(9, 14), Vector2i(19, 11), Vector2i(24, 18), Vector2i(13, 21), Vector2i(19, 24)]:
			L.stamp(cv.img, ["FF.", "FPD", ".DD"], p.x, p.y, fl, false)
	cv.smooth_silhouette(2)
	cv.clean_orphans([P.GRASS_3, P.FLOWER_LILAC_0, P.FLOWER_LILAC_1, P.FLOWER_WHITE, P.FLOWER_YELLOW, P.FLOWER_PINK])
	cv.outline({M_LEAF: P.OUTLINE_FOREST}, [M_LEAF])
	return cv.img


# Garante base reta na linha y (entre o primeiro e o último pixel preenchido logo acima)
static func _flatten_base(cv: Canvas, y: int, m: int, c: Color) -> void:
	var min_x: int = cv.w
	var max_x: int = -1
	for yy: int in range(y - 3, y + 1):
		for x: int in cv.w:
			if cv.filled(x, yy):
				min_x = mini(min_x, x)
				max_x = maxi(max_x, x)
	# Base com pelo menos 18 px (16 + contorno), centrada no canvas
	var mid: float = cv.w / 2.0
	var half: float = maxf(9.0, maxf(mid - min_x, max_x + 1 - mid) - 1.0)
	var x0: int = int(mid - half)
	var x1: int = int(mid + half) - 1
	for yy: int in range(y - 2, y + 1):
		var inset: int = 1 if yy == y - 2 else 0
		for x: int in range(x0 + inset, x1 - inset + 1):
			if not cv.filled(x, yy):
				cv.put(x, yy, c, m)


# ---------------------------------------------------------------------------
# Capim e flores (16x16)
# ---------------------------------------------------------------------------

const DIRS4: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]


# Folha pontuda por linhas: 1 px na ponta (tx, ty) até base_w px na base (bx, by), curvando para fora
static func blade_pixels(tx: float, ty: int, bx: float, by: int, base_w: float, bend: float = 1.6) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y: int in range(ty, by + 1):
		var t: float = float(y - ty) / float(by - ty)
		var cx: float = bx + (tx - bx) * pow(1.0 - t, bend)
		var hw: float = 0.5 + (base_w - 1.0) * 0.5 * minf(1.0, t * 1.3)
		for x: int in range(floori(cx - hw) - 1, ceili(cx + hw) + 1):
			var d: float = x + 0.5 - cx
			if d >= -hw and d < hw:
				out.append(Vector2i(x, y))
	return out


# Pinta um conjunto de pixels com contorno próprio por cima do que já existe (até a linha ring_until)
static func paint_with_ring(cv: Canvas, px: Array[Vector2i], colors: Array[Color], outline_c: Color, ring_until: int) -> void:
	var mine: Dictionary = {}
	for p: Vector2i in px:
		mine[p] = true
	for p: Vector2i in px:
		for d: Vector2i in DIRS4:
			var q: Vector2i = p + d
			if mine.has(q) or not cv.inside(q.x, q.y):
				continue
			if cv.filled(q.x, q.y) and q.y >= ring_until:
				continue
			cv.put(q.x, q.y, outline_c, M_PLANT)
	for i: int in px.size():
		cv.put(px[i].x, px[i].y, colors[i], M_PLANT)


# blades: [ponta x, ponta y, base x, base y, largura da base, cores {tip, light, mid}], de trás para frente
static func paint_blades(cv: Canvas, blades: Array, outline_c: Color, ring_until: int, bend: float = 1.6) -> void:
	for b: Array in blades:
		var px: Array[Vector2i] = blade_pixels(b[0], b[1], b[2], b[3], b[4], bend)
		var cols: Dictionary = b[5]
		var row_min: Dictionary = {}
		for p: Vector2i in px:
			row_min[p.y] = mini(int(row_min.get(p.y, 999)), p.x)
		var colors: Array[Color] = []
		for p: Vector2i in px:
			var t: float = float(p.y - int(b[1])) / float(int(b[3]) - int(b[1]))
			var c: Color = cols["mid"]
			if t < 0.3:
				c = cols["tip"]
			elif p.x == row_min[p.y]:
				c = cols["light"]
			colors.append(c)
		paint_with_ring(cv, px, colors, outline_c, ring_until)


static func grass_tuft(variant: int) -> Image:
	var cv: Canvas = Canvas.new(16, 16)
	var back: Dictionary = {"tip": P.GRASS_2, "light": P.GRASS_1, "mid": P.GRASS_0}
	var front: Dictionary = {"tip": P.GRASS_3, "light": P.GRASS_2, "mid": P.GRASS_1}
	var outline_c: Color = P.OUTLINE_PLANT
	var blades: Array = []
	# Folhas de trás altas e de frente baixas: as pontas de trás aparecem separadas no topo
	match variant:
		0:
			blades = [
				[4.5, 3, 7.0, 14, 3.0, back], [11.5, 4, 9.0, 14, 3.0, back],
				[2.5, 8, 6.5, 14, 3.0, front], [13.5, 9, 9.5, 14, 3.0, front],
				[8.0, 7, 8.0, 14, 3.0, front],
			]
		1:
			blades = [
				[3.5, 6, 6.5, 14, 3.0, back], [8.5, 3, 8.0, 14, 3.0, back],
				[13.0, 6, 9.5, 14, 3.0, back],
				[5.5, 9, 7.0, 14, 3.0, front], [11.0, 10, 9.0, 14, 3.0, front],
			]
		_:
			back = {"tip": P.CANOPY_3, "light": P.CANOPY_2, "mid": P.CANOPY_1}
			front = {"tip": P.CANOPY_4, "light": P.CANOPY_3, "mid": P.CANOPY_2}
			outline_c = P.OUTLINE_FOREST
			blades = [
				[3.0, 5, 6.5, 14, 3.0, back], [7.5, 3, 7.5, 14, 3.0, back],
				[12.5, 4, 9.5, 14, 3.0, back],
				[2.5, 10, 6.0, 14, 3.0, front], [9.5, 8, 8.5, 14, 3.0, front],
				[13.5, 10, 10.0, 14, 3.0, front],
			]
	paint_blades(cv, blades, outline_c, 13, 1.3)
	cv.clean_orphans([], [outline_c])
	return cv.img


static func flower(variant: int) -> Image:
	var cv: Canvas = Canvas.new(16, 16)
	var petal: Color = P.FLOWER_YELLOW
	var petal_dark: Color = P.FLOWER_YELLOW
	var center: Color = P.DIRT_2
	match variant:
		1:
			petal = P.FLOWER_WHITE
			petal_dark = P.FLOWER_WHITE
			center = P.FLOWER_YELLOW
		2:
			petal = P.FLOWER_LILAC_1
			petal_dark = P.FLOWER_LILAC_0
			center = P.FLOWER_YELLOW
	var leaf: Dictionary = {"tip": P.GRASS_1, "light": P.GRASS_1, "mid": P.GRASS_0}
	# Cabeças: [x, y, grande?]
	var heads: Array = [[2, 4, true], [8, 3, false], [10, 6, true]]
	var leaves: Array = [[3.0, 10, 6.5, 14, 3.0, leaf], [13.0, 11, 9.5, 14, 3.0, leaf]]
	if variant == 1:
		heads = [[2, 6, false], [6, 3, true], [11, 5, false]]
		leaves = [[2.5, 11, 6.5, 14, 3.0, leaf], [12.5, 9, 9.5, 14, 3.0, leaf]]
	elif variant == 2:
		heads = [[3, 4, false], [8, 5, true], [11, 3, false]]
		leaves = [[3.5, 9, 6.5, 14, 3.0, leaf], [13.0, 11, 9.5, 14, 3.0, leaf]]
	paint_blades(cv, leaves, P.OUTLINE_PLANT, 13)
	var stem_starts: Array[Vector2i] = []
	for hd: Array in heads:
		# Cabeça grande: pétalas em anel com miolo 2x2; pequena: botão em cruz
		var rows: Array = [".PP.", "PCCP", "PCCD", ".DD."] if hd[2] else [".P.", "PPD", ".D."]
		var cmap: Dictionary = {"P": petal, "C": center, "D": petal_dark}
		var px: Array[Vector2i] = []
		var colors: Array[Color] = []
		for j: int in rows.size():
			var row: String = rows[j]
			for i: int in row.length():
				var ch: String = row[i]
				if cmap.has(ch):
					px.append(Vector2i(int(hd[0]) + i, int(hd[1]) + j))
					colors.append(cmap[ch])
		paint_with_ring(cv, px, colors, P.OUTLINE_PLANT, 99)
		var size: int = 4 if hd[2] else 3
		stem_starts.append(Vector2i(int(hd[0]) + (size >> 1), int(hd[1]) + size + 1))
	# Hastes (1 px, tom mais escuro da grama) ligando cada cabeça à base
	for s: Vector2i in stem_starts:
		var bx: float = 8.0
		for y: int in range(s.y, 14):
			var t: float = float(y - s.y) / maxf(1.0, 13.0 - s.y)
			var x: int = int(round(lerpf(float(s.x), bx, t * t)))
			if not cv.filled(x, y):
				cv.put(x, y, P.GRASS_0, M_PLANT)
	cv.clean_orphans([P.GRASS_0, center], [P.OUTLINE_PLANT])
	return cv.img


# ---------------------------------------------------------------------------
# Monólitos
# ---------------------------------------------------------------------------

const RUNE_ROWS: Array = [
	"..RRRR..",
	".RBBBBR.",
	"RBHHCCBR",
	"RBCCCCBR",
	"RBCCCCBR",
	"RBCCCCBR",
	".RBBBBR.",
	"..RRRR..",
]


# Runa 8x8 com soquete escuro em volta
static func _rune(cv: Canvas, x0: int, y0: int) -> void:
	var cmap: Dictionary = {"R": P.RUNE_RING, "B": P.RUNE_BASE, "C": P.RUNE_CORE, "H": P.RUNE_SHINE}
	var cells: Dictionary = {}
	for j: int in RUNE_ROWS.size():
		var row: String = RUNE_ROWS[j]
		for i: int in row.length():
			var ch: String = row[i]
			if cmap.has(ch):
				cells[Vector2i(x0 + i, y0 + j)] = cmap[ch]
	for p: Vector2i in cells:
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
			var q: Vector2i = p + d
			if not cells.has(q) and cv.filled(q.x, q.y):
				cv.put(q.x, q.y, P.CSTONE_1, M_STONE)
	for p: Vector2i in cells:
		cv.put(p.x, p.y, cells[p], M_STONE)


static func _line(cv: Canvas, a: Vector2i, b: Vector2i, c: Color) -> void:
	var n: int = maxi(absi(b.x - a.x), absi(b.y - a.y))
	for k: int in n + 1:
		var t: float = float(k) / maxf(1.0, float(n))
		var x: int = int(round(lerpf(float(a.x), float(b.x), t)))
		var y: int = int(round(lerpf(float(a.y), float(b.y), t)))
		if cv.filled(x, y):
			cv.put(x, y, c, M_STONE)


static func _polyline_y(pts: Array, x: float) -> float:
	for k: int in pts.size() - 1:
		var a: Vector2 = pts[k]
		var b: Vector2 = pts[k + 1]
		if x >= a.x and x <= b.x:
			return lerpf(a.y, b.y, (x - a.x) / maxf(0.001, b.x - a.x))
	var last: Vector2 = pts[pts.size() - 1]
	return last.y


# Corpo de pedra fria: left/right por linha (inclusive), top por coluna; lado direito em sombra
static func _stone_body(cv: Canvas, left: PackedInt32Array, right: PackedInt32Array, top: PackedInt32Array, bottom: int, side_w: int, ao: Array) -> void:
	for y: int in range(0, bottom + 1):
		var xl: int = left[y]
		var xr: int = right[y]
		if xl > xr:
			continue
		for x: int in range(xl, xr + 1):
			if y < top[x]:
				continue
			var side_x: int = xr - side_w
			var c: Color = P.CSTONE_3
			if x > side_x:
				c = P.CSTONE_1
			elif x == side_x:
				c = P.CSTONE_2
			elif x == xl or (x == xl + 1 and y < bottom - 40):
				c = P.CSTONE_4
			elif _in_any(x + 0.5, y + 0.5, ao):
				c = P.CSTONE_2
			# Borda de cima: luz na face, meio-tom no lado
			var d: int = y - top[x]
			if d <= 1 and x < side_x:
				c = P.CSTONE_4
			elif d == 0 and x >= side_x:
				c = P.CSTONE_2
			cv.put(x, y, c, M_STONE)


# Ponto dentro de algum círculo Vector3(cx, cy, r)?
static func _in_any(px: float, py: float, circles: Array) -> bool:
	for c: Vector3 in circles:
		if _in_circle(px, py, c.x, c.y, c.z):
			return true
	return false


# Musgo: bolhas na base; topo de cada bolha mais claro na face
static func _moss(cv: Canvas, circles: Array, right: PackedInt32Array, side_w: int) -> void:
	var moss: Dictionary = {}
	for y: int in cv.h:
		for x: int in cv.w:
			if cv.m_at(x, y) != M_STONE:
				continue
			for cir: Vector3 in circles:
				var dx: float = x + 0.5 - cir.x
				var dy: float = y + 0.5 - cir.y
				if dx * dx + dy * dy <= cir.z * cir.z:
					moss[Vector2i(x, y)] = true
					break
	for p: Vector2i in moss:
		var c: Color = P.GRASS_0
		var on_face: bool = p.x < right[p.y] - side_w
		if on_face and (not moss.has(p + Vector2i(0, -1)) or not moss.has(p + Vector2i(0, -2))):
			c = P.GRASS_1
		cv.put(p.x, p.y, c, M_STONE)


static func monolith_0() -> Image:
	var cv: Canvas = Canvas.new(32, 96)
	var bottom: int = 94
	var side_w: int = 6
	var left: PackedInt32Array = PackedInt32Array()
	var right: PackedInt32Array = PackedInt32Array()
	# Laterais retas (como o monólito central da clareira)
	for y: int in cv.h:
		left.append(4)
		right.append(27)
	# Topo em arco, com o pico um pouco à direita (encosta iluminada mais longa)
	var top: PackedInt32Array = PackedInt32Array()
	var peak: float = 17.5
	var ry: float = 11.0
	for x: int in cv.w:
		var rad: float = (peak - 4.0) if x + 0.5 < peak else (28.0 - peak)
		var u: float = clampf((x + 0.5 - peak) / rad, -1.0, 1.0)
		top.append(5 + int(round(ry * (1.0 - sqrt(1.0 - u * u)))))
	# Base escurecida (contato com o chão), borda irregular
	var ao: Array = [Vector3(7.0, 93.0, 13.0), Vector3(15.0, 97.0, 15.0), Vector3(21.0, 95.0, 11.0)]
	_stone_body(cv, left, right, top, bottom, side_w, ao)
	# Rachaduras finas (linhas de 1 px)
	var cracks: Array = [
		[Vector2i(7, 38), Vector2i(10, 41), Vector2i(11, 45)],
		[Vector2i(16, 66), Vector2i(19, 69)],
		[Vector2i(22, 15), Vector2i(23, 19), Vector2i(22, 23)],
		[Vector2i(24, 48), Vector2i(25, 53)],
		[Vector2i(6, 86), Vector2i(9, 82)],
	]
	for cr: Array in cracks:
		for k: int in cr.size() - 1:
			_line(cv, cr[k], cr[k + 1], P.CSTONE_0)
	_rune(cv, 9, 21)
	_rune(cv, 10, 49)
	_moss(cv, [Vector3(6.5, 95.0, 5.0), Vector3(13.0, 97.0, 4.5), Vector3(20.0, 96.0, 4.0), Vector3(26.0, 94.5, 4.5)], right, side_w)
	cv.clean_orphans(P.RUNE + [P.CSTONE_0])
	cv.outline({M_STONE: P.OUTLINE_FOREST}, [M_STONE])
	return cv.img


static func monolith_1() -> Image:
	var cv: Canvas = Canvas.new(32, 64)
	var bottom: int = 62
	var side_w: int = 6
	var left: PackedInt32Array = PackedInt32Array()
	var right: PackedInt32Array = PackedInt32Array()
	for y: int in cv.h:
		var inset: int = 1 if y < 36 else 0
		left.append(4 + inset)
		right.append(27 - inset)
	# Topo quebrado em diagonal (alto à esquerda), com um degrau na fratura
	var break_line: Array = [Vector2(4, 13), Vector2(11, 15), Vector2(13, 19), Vector2(19, 20), Vector2(28, 25)]
	var top: PackedInt32Array = PackedInt32Array()
	for x: int in cv.w:
		top.append(int(round(_polyline_y(break_line, x + 0.5))))
	var ao: Array = [Vector3(7.0, 61.0, 10.0), Vector3(15.0, 64.0, 11.0), Vector3(21.0, 63.0, 9.0)]
	_stone_body(cv, left, right, top, bottom, side_w, ao)
	# Superfície da quebra vista de cima: faixa clara e lábio escuro embaixo
	for x: int in range(5, 27):
		var t0: int = top[x]
		var side_x: int = right[t0] - side_w
		var face: bool = x < side_x
		for k: int in 3:
			cv.put(x, t0 + k, P.CSTONE_4 if face else P.CSTONE_3, M_STONE)
		cv.put(x, t0 + 3, P.CSTONE_2 if face else P.CSTONE_1, M_STONE)
	var cracks: Array = [
		[Vector2i(6, 44), Vector2i(9, 47), Vector2i(10, 51)],
		[Vector2i(23, 30), Vector2i(24, 35)],
		[Vector2i(15, 24), Vector2i(17, 27)],
	]
	for cr: Array in cracks:
		for k: int in cr.size() - 1:
			_line(cv, cr[k], cr[k + 1], P.CSTONE_0)
	_rune(cv, 10, 31)
	_moss(cv, [Vector3(7.0, 63.0, 4.5), Vector3(14.0, 65.0, 4.0), Vector3(22.0, 64.0, 4.5), Vector3(27.0, 62.0, 3.5)], right, side_w)
	cv.clean_orphans(P.RUNE + [P.CSTONE_0])
	cv.outline({M_STONE: P.OUTLINE_FOREST}, [M_STONE])
	return cv.img


# Máscara: só os pixels do grupo Runa, nas mesmas posições
static func rune_mask(src: Image) -> Image:
	var out: Image = L.new_image(src.get_width(), src.get_height())
	var rune_keys: Array[int] = []
	for c: Color in P.RUNE:
		rune_keys.append(c.to_rgba32())
	for y: int in src.get_height():
		for x: int in src.get_width():
			var c: Color = src.get_pixel(x, y)
			if c.a > 0.5 and c.to_rgba32() in rune_keys:
				out.set_pixel(x, y, c)
	return out
