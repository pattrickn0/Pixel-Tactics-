class_name ArenaReliefGenerator
extends RefCounted
## Relevo justo dentro da arena (função pura do RNG recebido e da config).
## Gera só a minha metade (sul, linhas j >= d/2) como retângulos por nível e copia para a
## outra metade (rotação de 180° ou reflexão em z). Depois valida a forma e põe as escadas
## internas, sempre em pares simétricos. Se a forma falha, tenta de novo (com limite).
## Coordenadas locais da arena: célula (i, j), índice j * w + i, j cresce para o sul.

const NEIGHBORS_4: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]


## Resultado: níveis acima do chão e escadas internas (base_level relativo ao chão).
class Result extends RefCounted:
	var w: int = 0
	var d: int = 0
	var levels: PackedInt32Array = PackedInt32Array()
	var stairs: Array[MapStair] = []
	var mode: MapData.ReliefMode = MapData.ReliefMode.CENTRAL
	var peak: int = 0
	## Pico sorteado (peak fica menor quando a forma não comporta).
	var peak_target: int = 0
	## Verdadeiro se nenhuma tentativa passou e a forma reserva foi usada.
	var fallback: bool = false


var _cfg: MapGenConfig
var _w: int = 0
var _d: int = 0
## Primeira linha da minha metade (sul).
var _mid: int = 0
var _symmetry: MapData.ReliefSymmetry = MapData.ReliefSymmetry.ROTATION
var _mode: MapData.ReliefMode = MapData.ReliefMode.CENTRAL
var _peak_target: int = 0


func _init(w: int, d: int, cfg: MapGenConfig) -> void:
	_w = w
	_d = d
	_cfg = cfg
	_mid = floori(d / 2.0)
	_symmetry = cfg.relief_symmetry


func generate(rng: RandomNumberGenerator) -> Result:
	var cfg := _cfg
	_mode = MapData.ReliefMode.CENTRAL if rng.randf() < cfg.relief_central_chance else MapData.ReliefMode.PER_SIDE
	var peak_max: int = maxi(cfg.relief_peak_max, 1)
	var peak_min: int = clampi(cfg.relief_peak_min, 1, peak_max)
	# Sorteio do pico: o maior com chance relief_peak_high_chance, senão um dos outros.
	var peak_target: int = peak_max
	if peak_min < peak_max and rng.randf() >= cfg.relief_peak_high_chance:
		peak_target = rng.randi_range(peak_min, peak_max - 1)
	_peak_target = peak_target
	# O que a forma do modo comporta (ex.: no PER_SIDE, 7 linhas só dão 2 níveis com escada).
	peak_target = mini(peak_target, _max_feasible_peak())
	var attempts: int = maxi(cfg.relief_max_attempts, 1)
	for attempt in attempts:
		# Na primeira metade das tentativas exige o pico sorteado; depois aceita menor.
		var levels: PackedInt32Array = _try_shape(rng, peak_target, attempt >= floori(attempts / 2.0))
		if levels.is_empty():
			continue
		var peak: int = _max_level(levels)
		if not shape_ok(levels, peak):
			continue
		var stairs: Array[MapStair] = _place_stairs(rng, levels, peak)
		if stairs.is_empty():
			continue
		return _result(levels, stairs, peak, false)
	return _fallback(rng)


## Maior pico que cabe na altura disponível do morro: cada nível entra 1 célula de um lado
## e 2 do lado da escada (degrau + chegada), e o topo precisa de 4 células para a escada.
func _max_feasible_peak() -> int:
	var rows: int = _level1_zone().size.y
	if _mode == MapData.ReliefMode.CENTRAL:
		rows *= 2
	return maxi(floori((rows - 2) / 2.0), 1)


## O par de uma célula na outra metade.
func partner_cell(c: Vector2i) -> Vector2i:
	if _symmetry == MapData.ReliefSymmetry.MIRROR:
		return Vector2i(c.x, _d - 1 - c.y)
	return Vector2i(_w - 1 - c.x, _d - 1 - c.y)


func partner_dir(dir: Vector2i) -> Vector2i:
	if _symmetry == MapData.ReliefSymmetry.MIRROR:
		return Vector2i(dir.x, -dir.y)
	return -dir


func _result(levels: PackedInt32Array, stairs: Array[MapStair], peak: int, fallback: bool) -> Result:
	var res := Result.new()
	res.w = _w
	res.d = _d
	res.levels = levels
	res.stairs = stairs
	res.mode = _mode
	res.peak = peak
	res.peak_target = _peak_target
	res.fallback = fallback
	return res


# --- Forma ---------------------------------------------------------------------

func _try_shape(rng: RandomNumberGenerator, peak_target: int, allow_lower: bool) -> PackedInt32Array:
	var levels := PackedInt32Array()
	levels.resize(_w * _d)
	levels.fill(0)
	var rects: Array[Rect2i] = _level1_rects(rng, peak_target)
	if rects.is_empty():
		return PackedInt32Array()
	var mask: PackedByteArray = _full_mask(rects)
	_add_mask(levels, mask)
	var peak: int = 1
	for k in range(2, peak_target + 1):
		var allowed: PackedByteArray = _erode8(mask)
		for j in _mid:
			for i in _w:
				allowed[j * _w + i] = 0
		# Os níveis do meio precisam comportar os de cima.
		var upper: Array[Rect2i] = _upper_rects(rng, allowed, 2 * (peak_target - k) + maxi(_cfg.relief_rect_min, 3), k < peak_target)
		if upper.is_empty():
			break
		mask = _full_mask(upper)
		_add_mask(levels, mask)
		peak = k
	if peak < peak_target and not allow_lower:
		return PackedInt32Array()
	return levels


## Zona do nível 1 na minha metade (fora das margens; no PER_SIDE, longe da linha do meio).
func _level1_zone() -> Rect2i:
	var sm: int = maxi(_cfg.relief_short_margin, 0)
	var lm: int = maxi(_cfg.relief_long_margin, 0)
	var j0: int = _mid
	if _mode == MapData.ReliefMode.PER_SIDE:
		j0 += maxi(_cfg.relief_midline_gap, 0)
	return Rect2i(sm, j0, _w - 2 * sm, _d - lm - j0)


## O primeiro retângulo já tem o tamanho que comporta o pico (cada nível de cima fica
## 1 célula para dentro e precisa de 3 de largura).
func _level1_rects(rng: RandomNumberGenerator, peak_target: int) -> Array[Rect2i]:
	var zone: Rect2i = _level1_zone()
	var rmin: int = maxi(_cfg.relief_rect_min, 3)
	var rmax_w: int = mini(_cfg.relief_rect_max, zone.size.x)
	var rects: Array[Rect2i] = []
	if zone.size.x < rmin or zone.size.y < 2:
		return rects
	var need: int = 2 * (peak_target - 1) + rmin
	var first := Rect2i()
	if _mode == MapData.ReliefMode.CENTRAL:
		# Encosta na linha do meio cobrindo as 2 colunas centrais: junto com a cópia, um morro só.
		var mid_i: int = floori(_w / 2.0)
		var rw: int = rng.randi_range(mini(maxi(need, 4), rmax_w), rmax_w)
		var lo: int = maxi(zone.position.x, mid_i + 1 - rw)
		var hi: int = mini(mid_i - 1, zone.end.x - rw)
		if lo > hi:
			return rects
		var rh: int = rng.randi_range(mini(maxi(ceili(need / 2.0), 2), zone.size.y), zone.size.y)
		# Área: o retângulo e a cópia não passam de relief_area_max da arena.
		var cap: int = floori(_cfg.relief_area_max * _w * _d * 0.5)
		rh = mini(rh, maxi(floori(float(cap) / rw), 2))
		var i0: int = rng.randi_range(lo, hi)
		# Às vezes centrado (junção reta com a cópia); senão, deslocado (forma em "S").
		if (_w - rw) % 2 == 0 and rng.randf() < 0.5:
			i0 = clampi(floori((_w - rw) / 2.0), lo, hi)
		first = Rect2i(i0, _mid, rw, rh)
	else:
		if zone.size.y < rmin:
			return rects
		var rh: int = rng.randi_range(mini(maxi(need, rmin), zone.size.y), zone.size.y)
		var cap: int = floori(_cfg.relief_area_max * _w * _d * 0.5)
		var rw_max: int = clampi(floori(float(cap) / rh), mini(maxi(need, rmin), rmax_w), rmax_w)
		var rw: int = rng.randi_range(mini(maxi(need, rmin), rmax_w), rw_max)
		first = Rect2i(rng.randi_range(zone.position.x, zone.end.x - rw), rng.randi_range(zone.position.y, zone.end.y - rh), rw, rh)
	rects.append(first)
	var cap: int = floori(_cfg.relief_area_max * _w * _d * 0.5)
	var extra: int = rng.randi_range(1, maxi(_cfg.relief_rects_max, 1)) - 1
	for _e in extra:
		for _try in 30:
			var rw: int = rng.randi_range(rmin, rmax_w)
			var rh: int = rng.randi_range(rmin, maxi(rmin, zone.size.y))
			if rh > zone.size.y:
				break
			var r := Rect2i(rng.randi_range(zone.position.x, zone.end.x - rw), rng.randi_range(zone.position.y, zone.end.y - rh), rw, rh)
			if not _touches_any(r, rects):
				continue
			var grown: Array[Rect2i] = rects.duplicate()
			grown.append(r)
			if _union_area(grown) > cap:
				continue
			rects.append(r)
			break
	return rects


static func _union_area(rects: Array[Rect2i]) -> int:
	var cells: Dictionary = {}
	for r: Rect2i in rects:
		for j in range(r.position.y, r.end.y):
			for i in range(r.position.x, r.end.x):
				cells[Vector2i(i, j)] = true
	return cells.size()


## Retângulos de um nível de cima: dentro de allowed (núcleo do nível de baixo, só na
## minha metade). Vazio se nenhum cabe.
func _upper_rects(rng: RandomNumberGenerator, allowed: PackedByteArray, first_min: int, more_above: bool) -> Array[Rect2i]:
	var rects: Array[Rect2i] = []
	var rmin: int = maxi(_cfg.relief_rect_min, 3)
	# Com mais níveis em cima, quase sempre centrado (o núcleo do morro fica largo).
	var centered: float = 0.9 if more_above else 0.6
	var first: Rect2i = _random_fitting_rect(rng, allowed, first_min, [], true, centered)
	if first.size == Vector2i.ZERO and first_min > rmin:
		first = _random_fitting_rect(rng, allowed, rmin, [], true, centered)
	if first.size == Vector2i.ZERO:
		return rects
	rects.append(first)
	if rng.randf() < 0.4:
		var second: Rect2i = _random_fitting_rect(rng, allowed, rmin, rects, false, centered)
		if second.size != Vector2i.ZERO:
			rects.append(second)
	return rects


## Sorteia um tamanho e uma posição em que o retângulo cabe inteiro em allowed (e encosta
## em must_touch, se não vazio). Com 2 linhas, só no CENTRAL e colado na linha do meio
## (a cópia completa a espessura). Com leave_room, fica menor que a caixa permitida em
## pelo menos um eixo (sobra lugar para a escada e a chegada dela). Rect2i() se nada cabe.
func _random_fitting_rect(rng: RandomNumberGenerator, allowed: PackedByteArray, rmin: int, must_touch: Array[Rect2i],
		leave_room: bool, centered_chance: float) -> Rect2i:
	var rmax: int = maxi(_cfg.relief_rect_max, rmin)
	# Colado na linha do meio do CENTRAL, a cópia dobra a espessura.
	var min_h: int = maxi(ceili(rmin / 2.0), 2) if _mode == MapData.ReliefMode.CENTRAL else rmin
	# Caixa das células permitidas: limita o tamanho sorteado.
	var lo := Vector2i(_w, _d)
	var hi := Vector2i(-1, -1)
	for j in range(_mid, _d):
		for i in _w:
			if allowed[j * _w + i] == 1:
				lo = Vector2i(mini(lo.x, i), mini(lo.y, j))
				hi = Vector2i(maxi(hi.x, i), maxi(hi.y, j))
	var box_w: int = mini(hi.x - lo.x + 1, rmax)
	var box_h: int = mini(hi.y - lo.y + 1, rmax)
	if box_w < rmin or box_h < min_h:
		return Rect2i()
	for attempt in 12:
		# A última tentativa usa o menor retângulo possível.
		var rw: int = rmin if attempt == 11 else rng.randi_range(rmin, box_w)
		var rh: int = min_h if attempt == 11 else rng.randi_range(min_h, box_h)
		if leave_room and rw >= box_w and rh >= box_h:
			if rng.randf() < 0.5 and box_w - 1 >= rmin:
				rw = box_w - 1
			elif box_h - 1 >= min_h:
				rh = box_h - 1
		var fits: Array[Rect2i] = []
		var centered: Array[Rect2i] = []
		for j0 in range(_mid, _d - rh + 1):
			if rh < rmin and j0 != _mid:
				continue
			for i0 in range(0, _w - rw + 1):
				var r := Rect2i(i0, j0, rw, rh)
				if not _rect_inside(r, allowed):
					continue
				if not must_touch.is_empty() and not _touches_any(r, must_touch):
					continue
				fits.append(r)
				if _is_centered(r):
					centered.append(r)
		if not fits.is_empty():
			# Colado na linha do meio, prefere o centrado: a junção com a cópia fica reta.
			if not centered.is_empty() and rng.randf() < centered_chance:
				return centered[rng.randi_range(0, centered.size() - 1)]
			return fits[rng.randi_range(0, fits.size() - 1)]
	return Rect2i()


## Colado na linha do meio e centrado: junto com a cópia vira um retângulo só.
func _is_centered(r: Rect2i) -> bool:
	if _mode != MapData.ReliefMode.CENTRAL or r.position.y != _mid:
		return false
	return _symmetry == MapData.ReliefSymmetry.MIRROR or r.position.x + r.end.x == _w


func _rect_inside(r: Rect2i, allowed: PackedByteArray) -> bool:
	for j in range(r.position.y, r.end.y):
		for i in range(r.position.x, r.end.x):
			if allowed[j * _w + i] == 0:
				return false
	return true


## Sobrepõe algum retângulo da lista (ou divide uma aresta com ele).
static func _touches_any(r: Rect2i, rects: Array[Rect2i]) -> bool:
	var grown := r.grow(1)
	for other: Rect2i in rects:
		if grown.intersects(other) and (r.intersects(other) or _shares_edge(r, other)):
			return true
	return false


static func _shares_edge(a: Rect2i, b: Rect2i) -> bool:
	var overlap_x: bool = a.position.x < b.end.x and b.position.x < a.end.x
	var overlap_z: bool = a.position.y < b.end.y and b.position.y < a.end.y
	var touch_x: bool = a.end.x == b.position.x or b.end.x == a.position.x
	var touch_z: bool = a.end.y == b.position.y or b.end.y == a.position.y
	return (overlap_x and touch_z) or (overlap_z and touch_x)


## Máscara da arena inteira: os retângulos (minha metade) mais a cópia na outra metade.
func _full_mask(rects: Array[Rect2i]) -> PackedByteArray:
	var mask := PackedByteArray()
	mask.resize(_w * _d)
	mask.fill(0)
	for r: Rect2i in rects:
		for j in range(r.position.y, r.end.y):
			for i in range(r.position.x, r.end.x):
				var p: Vector2i = partner_cell(Vector2i(i, j))
				mask[j * _w + i] = 1
				mask[p.y * _w + p.x] = 1
	return mask


func _add_mask(levels: PackedInt32Array, mask: PackedByteArray) -> void:
	for idx in mask.size():
		if mask[idx] == 1:
			levels[idx] += 1


## Núcleo (vizinhança 8): fica a célula cujos 8 vizinhos também estão na máscara.
## O nível de cima fica dentro dele, então vizinhos diferem no máximo 1 nível.
func _erode8(mask: PackedByteArray) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(_w * _d)
	out.fill(0)
	for j in range(1, _d - 1):
		for i in range(1, _w - 1):
			var full := true
			for dj in range(-1, 2):
				for di in range(-1, 2):
					if mask[(j + dj) * _w + i + di] == 0:
						full = false
			if full:
				out[j * _w + i] = 1
	return out


func _max_level(levels: PackedInt32Array) -> int:
	var hi: int = 0
	for v: int in levels:
		hi = maxi(hi, v)
	return hi


# --- Validação ---------------------------------------------------------------

## Confere as regras de forma da spec na arena inteira.
func shape_ok(levels: PackedInt32Array, peak: int) -> bool:
	var n: int = _w * _d
	var elevated: int = 0
	for v: int in levels:
		if v >= 1:
			elevated += 1
	var share: float = float(elevated) / float(n)
	if share < _cfg.relief_area_min or share > _cfg.relief_area_max:
		return false
	for k in range(1, peak + 1):
		var mask := PackedByteArray()
		mask.resize(n)
		for idx in n:
			mask[idx] = 1 if levels[idx] >= k else 0
		if not open_ok(mask, _w, _d) or not runs_ok(mask, _w, _d, 2):
			return false
	for j in _d:
		for i in _w:
			var v: int = levels[j * _w + i]
			if i + 1 < _w and absi(v - levels[j * _w + i + 1]) > 1:
				return false
			if j + 1 < _d and absi(v - levels[(j + 1) * _w + i]) > 1:
				return false
	# Chão: uma região só, tocando as duas bordas compridas.
	var floor_comps: Array = _components(levels, func(v: int) -> bool: return v == 0)
	if floor_comps.size() != 1:
		return false
	var touches_n := false
	var touches_s := false
	for c: Vector2i in floor_comps[0]:
		touches_n = touches_n or c.y == 0
		touches_s = touches_s or c.y == _d - 1
	if not touches_n or not touches_s:
		return false
	# Modo: um morro que cruza o meio, ou um por metade.
	var hills: Array = _components(levels, func(v: int) -> bool: return v >= 1)
	if _mode == MapData.ReliefMode.CENTRAL:
		if hills.size() != 1:
			return false
		var north := false
		var south := false
		for c: Vector2i in hills[0]:
			north = north or c.y < _mid
			south = south or c.y >= _mid
		return north and south
	if hills.size() != 2:
		return false
	for hill: Array in hills:
		var north_n: int = 0
		for c: Vector2i in hill:
			if c.y < _mid:
				north_n += 1
		if north_n != 0 and north_n != hill.size():
			return false
	return true


## Passa na abertura 3×3 (nenhuma parte com menos de 3 células de largura).
static func open_ok(mask: PackedByteArray, w: int, d: int) -> bool:
	var cells: Dictionary = {}
	for j in d:
		for i in w:
			if mask[j * w + i] == 1:
				cells[Vector2i(i, j)] = true
	return MapGenerator.open_3x3(cells).size() == cells.size()


## Todo trecho reto do contorno (fora da arena conta como fora da máscara) tem pelo
## menos min_run células.
static func runs_ok(mask: PackedByteArray, w: int, d: int, min_run: int) -> bool:
	for dir: Vector2i in NEIGHBORS_4:
		var along_x: bool = dir.x == 0
		var lines: int = d if along_x else w
		var length: int = w if along_x else d
		for line in lines:
			var run: int = 0
			for t in length + 1:
				var edge := false
				if t < length:
					var c := Vector2i(t, line) if along_x else Vector2i(line, t)
					var nb: Vector2i = c + dir
					var nb_in: bool = nb.x >= 0 and nb.y >= 0 and nb.x < w and nb.y < d and mask[nb.y * w + nb.x] == 1
					edge = mask[c.y * w + c.x] == 1 and not nb_in
				if edge:
					run += 1
				else:
					if run > 0 and run < min_run:
						return false
					run = 0
	return true


## Regiões (vizinhança 4) das células cujo nível passa no filtro, em ordem de varredura.
func _components(levels: PackedInt32Array, accept: Callable) -> Array:
	var seen := PackedByteArray()
	seen.resize(_w * _d)
	seen.fill(0)
	var comps: Array = []
	for j in _d:
		for i in _w:
			var idx: int = j * _w + i
			if seen[idx] == 1 or not accept.call(levels[idx]):
				continue
			var comp: Array[Vector2i] = [Vector2i(i, j)]
			seen[idx] = 1
			var head: int = 0
			while head < comp.size():
				var c: Vector2i = comp[head]
				head += 1
				for dir: Vector2i in NEIGHBORS_4:
					var nb: Vector2i = c + dir
					if nb.x < 0 or nb.y < 0 or nb.x >= _w or nb.y >= _d:
						continue
					var nidx: int = nb.y * _w + nb.x
					if seen[nidx] == 0 and accept.call(levels[nidx]):
						seen[nidx] = 1
						comp.append(nb)
			comps.append(comp)
	return comps


# --- Escadas internas --------------------------------------------------------------

## Uma escada (e o par dela) para cada região de nível k sem escada. Vazio se alguma
## região não tem lugar para escada ou se algum ponto elevado fica sem acesso.
func _place_stairs(rng: RandomNumberGenerator, levels: PackedInt32Array, peak: int) -> Array[MapStair]:
	var stairs: Array[MapStair] = []
	var none: Array[MapStair] = []
	var reserved: Dictionary = {}
	for k in range(1, peak + 1):
		var comps: Array = _components(levels, func(v: int) -> bool: return v == k)
		var comp_of: Dictionary = {}
		for ci in comps.size():
			for c: Vector2i in comps[ci]:
				comp_of[c] = ci
		var served: Dictionary = {}
		for ci in comps.size():
			if served.has(ci):
				continue
			var cands: Array = _stair_candidates(levels, comps[ci], k, reserved)
			if cands.is_empty():
				return none
			var pick: Array = cands[rng.randi_range(0, cands.size() - 1)]
			var cells: Array[Vector2i] = pick[0]
			var up: Vector2i = pick[1]
			for pair in 2:
				var stair := MapStair.new()
				stair.base_level = k - 1
				stair.levels = 1
				stair.up_direction = up if pair == 0 else partner_dir(up)
				for c: Vector2i in cells:
					stair.cells.append(c if pair == 0 else partner_cell(c))
				stairs.append(stair)
				for c: Vector2i in _stair_footprint(stair):
					reserved[c] = true
				for c: Vector2i in stair.landing_cells():
					served[comp_of[c]] = true
	if not _all_reachable(levels, stairs):
		return none
	return stairs


## Candidatos [células, subida] para a região comp (nível k): 2 de largura, 1 de
## comprimento, num trecho reto de pelo menos relief_stair_run_min células, sem encostar
## nas pontas do trecho, fora das margens e sem tocar escadas já postas (nem o próprio par).
func _stair_candidates(levels: PackedInt32Array, comp: Array, k: int, reserved: Dictionary) -> Array:
	var sw: int = maxi(_cfg.stair_width, 1)
	var run_min: int = maxi(_cfg.relief_stair_run_min, sw + 2)
	var cands: Array = []
	for up: Vector2i in NEIGHBORS_4:
		var perp := Vector2i(absi(up.y), absi(up.x))
		var edge: Dictionary = {}
		for c: Vector2i in comp:
			var below: Vector2i = c - up
			if _in_arena(below) and levels[below.y * _w + below.x] == k - 1:
				edge[c] = true
		for c: Vector2i in comp:
			if not edge.has(c) or edge.has(c - perp):
				continue
			var length: int = 0
			while edge.has(c + perp * length):
				length += 1
			if length < run_min:
				continue
			for p in range(1, length - sw):
				var cells: Array[Vector2i] = []
				for q in sw:
					cells.append(c + perp * (p + q) - up)
				if _stair_ok(levels, cells, up, k, reserved):
					cands.append([cells, up])
	return cands


func _stair_ok(levels: PackedInt32Array, cells: Array[Vector2i], up: Vector2i, k: int, reserved: Dictionary) -> bool:
	var sm: int = maxi(_cfg.relief_short_margin, 0)
	var lm: int = maxi(_cfg.relief_long_margin, 0)
	var own := MapStair.new()
	own.up_direction = up
	own.cells = cells
	var mate := MapStair.new()
	mate.up_direction = partner_dir(up)
	for c: Vector2i in cells:
		if c.x < sm or c.x >= _w - sm or c.y < lm or c.y >= _d - lm:
			return false
		if levels[c.y * _w + c.x] != k - 1:
			return false
		var below: Vector2i = c - up
		if not _in_arena(below) or levels[below.y * _w + below.x] != k - 1:
			return false
		mate.cells.append(partner_cell(c))
	var own_cells: Array[Vector2i] = _stair_footprint(own)
	var mate_cells: Array[Vector2i] = _stair_footprint(mate)
	for c: Vector2i in own_cells:
		if reserved.has(c) or mate_cells.has(c):
			return false
	for c: Vector2i in mate_cells:
		if reserved.has(c):
			return false
	return true


## Células que outra escada não pode ocupar: a escada, as chegadas embaixo e em cima e
## os vizinhos dos lados.
func _stair_footprint(stair: MapStair) -> Array[Vector2i]:
	var result: Array[Vector2i] = stair.cells.duplicate()
	result.append_array(stair.arrival_cells())
	result.append_array(stair.landing_cells())
	var perp := Vector2i(absi(stair.up_direction.y), absi(stair.up_direction.x))
	for c: Vector2i in stair.cells:
		for side: Vector2i in [c + perp, c - perp]:
			if not stair.cells.has(side) and not result.has(side):
				result.append(side)
	return result


## Busca que anda no mesmo nível e só sobe/desce de nível pelas escadas: a partir do
## chão, alcança toda célula elevada?
func _all_reachable(levels: PackedInt32Array, stairs: Array[MapStair]) -> bool:
	var links: Dictionary = {}
	for stair: MapStair in stairs:
		for c: Vector2i in stair.cells:
			var top: Vector2i = c + stair.up_direction
			links[Vector4i(c.x, c.y, top.x, top.y)] = true
			links[Vector4i(top.x, top.y, c.x, c.y)] = true
	var seen := PackedByteArray()
	seen.resize(_w * _d)
	seen.fill(0)
	var queue: Array[Vector2i] = []
	for j in _d:
		for i in _w:
			if levels[j * _w + i] == 0:
				seen[j * _w + i] = 1
				queue.append(Vector2i(i, j))
	var head: int = 0
	while head < queue.size():
		var c: Vector2i = queue[head]
		head += 1
		for dir: Vector2i in NEIGHBORS_4:
			var nb: Vector2i = c + dir
			if not _in_arena(nb) or seen[nb.y * _w + nb.x] == 1:
				continue
			var same: bool = levels[nb.y * _w + nb.x] == levels[c.y * _w + c.x]
			if same or links.has(Vector4i(c.x, c.y, nb.x, nb.y)):
				seen[nb.y * _w + nb.x] = 1
				queue.append(nb)
	return seen.count(0) == 0


func _in_arena(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < _w and c.y < _d


# --- Forma reserva -----------------------------------------------------------------

## Morro central simples (retângulo simétrico, pico 1); só se nenhuma tentativa passou.
func _fallback(rng: RandomNumberGenerator) -> Result:
	_mode = MapData.ReliefMode.CENTRAL
	var levels := PackedInt32Array()
	levels.resize(_w * _d)
	levels.fill(0)
	var hw: int = maxi(roundi(_w * 0.2), 2)
	var hd: int = maxi(roundi(_d * 0.2), 2)
	for j in range(_mid - hd, _mid + hd):
		for i in range(floori(_w / 2.0) - hw, floori(_w / 2.0) + hw):
			levels[j * _w + i] = 1
	var stairs: Array[MapStair] = _place_stairs(rng, levels, 1)
	return _result(levels, stairs, 1, true)
