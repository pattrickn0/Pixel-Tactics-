extends SceneTree
## Gera a arte da spec A04 (piso da reserva, tábuas de madeira mel):
## bench_floor_0/_1 (+ _n) em assets/textures/ e a prévia docs/art-preview/a04-piso-reserva.png.
## Rodar da raiz do projeto:
##   "$G" --headless --path . --script tools/art/gen_a04.gd

const P = preload("res://tools/art/palette_a03.gd")
const CV = preload("res://tools/art/a03_canvas.gd")
const L = preload("res://tools/art/art_lib.gd")

const TEX_DIR: String = "res://assets/textures/"
const PREVIEW_PATH: String = "res://docs/art-preview/a04-piso-reserva.png"
const N: int = 32
const PLANK: int = 8 # 7 linhas de madeira + 1 de fresta
const SEEDS: Array[int] = [40417, 41423]
const MOSAIC_SEED: int = 2026
const USE_KNOT: bool = false
# Emendas de topo [tábua, coluna]: uma coluna por tábua, desencontradas entre as variantes,
# para as juntas não se alinharem e as tábuas terem comprimentos de 1, 2, 3... unidades
const JOINTS: Array = [[Vector2i(0, 6), Vector2i(2, 19)], [Vector2i(1, 25), Vector2i(3, 12)]]
const Z_WOOD: float = 1.0
const Z_CHAMFER: float = 0.55
const Z_GAP: float = 0.0
const Z_MOSS: float = 0.3
# detalhes ficam longe das colunas 0 e 31, para _0 e _1 emendarem em qualquer ordem
const X_LO: int = 2
const X_HI: int = 29

const BG: Color = Color(0.36, 0.36, 0.38)
const FG: Color = Color(0.95, 0.95, 0.95)

var wood: int
var wood_mid: int
var wood_light: int
var gap: int
var gap_light: int
var knot: int
var moss: int


func _initialize() -> void:
	wood = P.hx("#C29A6C")
	wood_mid = P.hx("#A37C56")
	wood_light = P.hx("#D9BC86")
	gap = P.hx("#4B3339")
	gap_light = P.hx("#6B4C3E")
	knot = P.hx("#876547")
	moss = P.hx("#5E7C26")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art-preview/"))
	var tex: Dictionary = {}
	var normals: Dictionary = {}
	for v: int in 2:
		var cv: RefCounted = _build(v)
		var key: String = "bench_floor_%d" % v
		tex[key] = cv.to_image()
		normals[key] = cv.normal_image()
		_save(tex[key], TEX_DIR + key + ".png")
		_save(normals[key], TEX_DIR + key + "_n.png")
	_save(_preview(tex, normals), PREVIEW_PATH)
	print("A04 GEN: 4 PNG gravados + prévia")
	quit(0)


func _save(img: Image, path: String) -> void:
	var err: Error = img.save_png(ProjectSettings.globalize_path(path))
	if err != OK:
		push_error("Falha ao gravar %s (%d)" % [path, err])


# ---------------------------------------------------------------------------
# Textura
# ---------------------------------------------------------------------------

func _build(v: int) -> RefCounted:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = SEEDS[v]
	var cv: RefCounted = null
	for attempt: int in 200:
		cv = _build_once(v, rng)
		if cv != null and _good(cv):
			return cv
	push_error("A04: variante %d não atingiu os critérios" % v)
	return cv


func _build_once(v: int, rng: RandomNumberGenerator) -> RefCounted:
	var cv: RefCounted = CV.new(N, N)
	cv.fill(wood, Z_WOOD)
	# ocupação: detalhes não encostam uns nos outros nem nas emendas
	var busy: PackedByteArray = PackedByteArray()
	busy.resize(N * N)
	for p: int in 4:
		var y0: int = p * PLANK
		for x: int in N:
			cv.put_z(x, y0, Z_CHAMFER)
			cv.put_z(x, y0 + 6, Z_CHAMFER)
			cv.put(x, y0 + 7, gap, Z_GAP)
	for j: Vector2i in JOINTS[v]:
		var y0: int = j.x * PLANK
		for y: int in range(y0, y0 + 7):
			cv.put(j.y, y, gap, Z_GAP)
			for dx: int in [-1, 1]:
				cv.put_z(j.y + dx, y, minf(cv.get_z(j.y + dx, y), Z_CHAMFER))
			for dx: int in range(-2, 3):
				busy[y * N + j.y + dx] = 1
	# musgo só sobre frestas (variante 1): tufo no pé de uma emenda + tufinho numa fresta
	if v == 1:
		var j: Vector2i = JOINTS[1][rng.randi_range(0, 1)]
		var g: int = j.x * PLANK + 7
		var tuft: Array[Vector2i] = [Vector2i(j.y, g - 1), Vector2i(j.y - 1, g), Vector2i(j.y, g), Vector2i(j.y + 1, g)]
		for q: Vector2i in tuft:
			cv.put(q.x, q.y, moss, Z_MOSS)
		_mark_gap(busy, tuft)
		var placed: bool = false
		for t: int in 60:
			var gp: int = rng.randi_range(0, 3)
			if gp == j.x:
				continue
			var gy: int = gp * PLANK + 7
			var ln: int = rng.randi_range(2, 3)
			var x0: int = rng.randi_range(X_LO, X_HI - ln + 1)
			var pts: Array[Vector2i] = _run(x0, gy, ln)
			if _gap_free(v, busy, pts):
				for q: Vector2i in pts:
					cv.put(q.x, q.y, moss, Z_MOSS)
				_mark_gap(busy, pts)
				placed = true
				break
		if not placed:
			return null
	# trechos #6B4C3E nas frestas: 2 trechos em frestas diferentes
	var used_gaps: Array[int] = []
	for k: int in 2:
		var ok: bool = false
		for t: int in 60:
			var gp: int = rng.randi_range(0, 3)
			if used_gaps.has(gp):
				continue
			var ln: int = rng.randi_range(2, 4)
			var x0: int = rng.randi_range(X_LO, X_HI - ln + 1)
			var pts: Array[Vector2i] = _run(x0, gp * PLANK + 7, ln)
			if _gap_free(v, busy, pts):
				for q: Vector2i in pts:
					cv.put_c(q.x, q.y, gap_light)
				_mark_gap(busy, pts)
				used_gaps.append(gp)
				ok = true
				break
		if not ok:
			return null
	# nó (opcional na spec): desligado, porque com 2 variantes ele vira um pontilhado na grade
	if USE_KNOT and v == 0:
		var ok: bool = false
		for t: int in 60:
			var p: int = rng.randi_range(0, 3)
			var y: int = p * PLANK + rng.randi_range(2, 3)
			var x: int = rng.randi_range(X_LO + 1, X_HI - 3)
			var pts: Array[Vector2i] = [Vector2i(x, y), Vector2i(x + 1, y), Vector2i(x + 2, y),
				Vector2i(x, y + 1), Vector2i(x + 1, y + 1), Vector2i(x + 2, y + 1)]
			if _free(busy, pts):
				for q: Vector2i in pts:
					var core: bool = q.x == x + 1
					cv.put(q.x, q.y, gap_light if core else knot, 0.7 if core else 0.85)
				_mark(busy, pts)
				ok = true
				break
		if not ok:
			return null
	# veios #A37C56: 1 px de altura, 6 a 14 px, em tábuas diferentes, às vezes com um degrau
	var n_veins: int = rng.randi_range(2, 3)
	var vein_planks: Array[int] = []
	for k: int in n_veins:
		var ok: bool = false
		for t: int in 80:
			var p: int = rng.randi_range(0, 3)
			if vein_planks.has(p):
				continue
			var ln: int = rng.randi_range(6, 14)
			var r: int = rng.randi_range(1, 5)
			var x0: int = rng.randi_range(X_LO, X_HI - ln + 1)
			var pts: Array[Vector2i] = []
			var step_at: int = -1
			var r2: int = r
			if rng.randf() < 0.5:
				step_at = rng.randi_range(3, ln - 3)
				r2 = r + (1 if r <= 3 else -1)
			for i: int in ln:
				var rr: int = r2 if (step_at >= 0 and i >= step_at) else r
				pts.append(Vector2i(x0 + i, p * PLANK + rr))
			if _free(busy, pts):
				for q: Vector2i in pts:
					cv.put(q.x, q.y, wood_mid, minf(cv.get_z(q.x, q.y), 0.9))
				_mark(busy, pts)
				vein_planks.append(p)
				ok = true
				break
		if not ok:
			return null
	# trechos claros #D9BC86 no miolo da tábua (linhas 2 a 4)
	var n_light: int = rng.randi_range(1, 2)
	for k: int in n_light:
		var ok: bool = false
		for t: int in 80:
			var p: int = rng.randi_range(0, 3)
			var ln: int = rng.randi_range(3, 6)
			var x0: int = rng.randi_range(X_LO, X_HI - ln + 1)
			var pts: Array[Vector2i] = _run(x0, p * PLANK + rng.randi_range(2, 4), ln)
			if _free(busy, pts):
				for q: Vector2i in pts:
					cv.put_c(q.x, q.y, wood_light)
				_mark(busy, pts)
				ok = true
				break
		if not ok:
			return null
	return cv


func _run(x0: int, y: int, ln: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for i: int in ln:
		out.append(Vector2i(x0 + i, y))
	return out


func _free(busy: PackedByteArray, pts: Array[Vector2i]) -> bool:
	for q: Vector2i in pts:
		if q.x < X_LO or q.x > X_HI or busy[q.y * N + q.x] != 0:
			return false
	return true


# Na fresta: livre e longe (2 px) das colunas de emenda que encostam nela
func _gap_free(v: int, busy: PackedByteArray, pts: Array[Vector2i]) -> bool:
	if not _free(busy, pts):
		return false
	for q: Vector2i in pts:
		for j: Vector2i in JOINTS[v]:
			if absi(q.x - j.y) <= 2:
				return false
	return true


# Marca os pixels e a vizinhança 8 (margem de 1 px)
func _mark(busy: PackedByteArray, pts: Array[Vector2i]) -> void:
	for q: Vector2i in pts:
		for dy: int in range(-1, 2):
			for dx: int in range(-1, 2):
				busy[posmod(q.y + dy, N) * N + posmod(q.x + dx, N)] = 1


# Na fresta a margem é só horizontal (não bloqueia a madeira vizinha)
func _mark_gap(busy: PackedByteArray, pts: Array[Vector2i]) -> void:
	for q: Vector2i in pts:
		for dx: int in range(-2, 3):
			busy[q.y * N + posmod(q.x + dx, N)] = 1


func _good(cv: RefCounted) -> bool:
	var tones: Dictionary = {}
	var n_wood: int = 0
	var n_gap: int = 0
	var lum: float = 0.0
	var halves: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
	for y: int in N:
		for x: int in N:
			var ci: int = cv.get_c(x, y)
			tones[ci] = true
			if ci == wood:
				n_wood += 1
			if ci == gap or ci == gap_light or P.family_of(ci) == "moss":
				n_gap += 1
			var yy: float = P.luma(ci)
			lum += yy
			halves[0 if x < 16 else 1] += yy
			halves[2 if y < 16 else 3] += yy
	lum /= 1024.0
	var ok: bool = tones.size() >= 4 and tones.size() <= 6
	ok = ok and n_wood >= 0.47 * 1024.0
	ok = ok and n_gap >= 0.09 * 1024.0 and n_gap <= 0.15 * 1024.0
	ok = ok and lum >= 0.51 and lum <= 0.61
	ok = ok and absf(halves[0] - halves[1]) / 512.0 <= 0.03 and absf(halves[2] - halves[3]) / 512.0 <= 0.03
	return ok


# ---------------------------------------------------------------------------
# Prévia
# ---------------------------------------------------------------------------

static func _hash(x: int, y: int, s: int) -> int:
	var h: int = (x * 73856093) ^ (y * 19349663) ^ (s * 83492791)
	h = (h ^ (h >> 13)) * 1274126177
	return absi(h ^ (h >> 16))


func _load(name: String) -> Image:
	var img: Image = Image.load_from_file(ProjectSettings.globalize_path(TEX_DIR + name + ".png"))
	if img == null:
		push_error("A04: não abriu %s" % name)
		return L.new_image(N, N, Color.MAGENTA)
	img.convert(Image.FORMAT_RGBA8)
	return img


func _variant(tex: Dictionary, tx: int, ty: int) -> Image:
	return tex["bench_floor_%d" % (_hash(tx, ty, MOSAIC_SEED) % 2)]


func _mosaic(tex: Dictionary, nx: int, ny: int) -> Image:
	var out: Image = L.new_image(nx * N, ny * N)
	for ty: int in ny:
		for tx: int in nx:
			out.blit_rect(_variant(tex, tx, ty), Rect2i(0, 0, N, N), Vector2i(tx * N, ty * N))
	return out


## Trecho da reserva (20 x 3) entre o muro do terraço (em cima) e a grama da arena (embaixo).
func _strip(tex: Dictionary, stone_cols: int) -> Image:
	var grass: Image = _load("grass_arena_0")
	var face: Image = _load("wall_face")
	var top: Image = _load("wall_top")
	var stone: Image = _load("stone_path_0")
	var w: int = (20 + stone_cols) * N
	var out: Image = L.new_image(w, 16 + 32 + 96 + 32, BG)
	for tx: int in 20:
		out.blit_rect(top, Rect2i(0, 0, N, 16), Vector2i(tx * N, 0))
		out.blit_rect(face, Rect2i(0, 0, N, N), Vector2i(tx * N, 16))
		out.blit_rect(grass, Rect2i(0, 0, N, N), Vector2i(tx * N, 48 + 96))
	out.blit_rect(_mosaic(tex, 20, 3), Rect2i(0, 0, 20 * N, 96), Vector2i(0, 48))
	for ty: int in 3:
		for tx: int in stone_cols:
			out.blit_rect(stone, Rect2i(0, 0, N, N), Vector2i((20 + tx) * N, 48 + ty * N))
	return out


func _preview(tex: Dictionary, normals: Dictionary) -> Image:
	var a: Image = tex["bench_floor_0"]
	var b: Image = tex["bench_floor_1"]
	var pair: Image = L.new_image(2 * N, 2 * N)
	pair.blit_rect(a, Rect2i(0, 0, N, N), Vector2i(0, 0))
	pair.blit_rect(b, Rect2i(0, 0, N, N), Vector2i(N, 0))
	pair.blit_rect(b, Rect2i(0, 0, N, N), Vector2i(0, N))
	pair.blit_rect(a, Rect2i(0, 0, N, N), Vector2i(N, N))
	var items: Array = [
		[L.scaled(a, 4), "BENCH_FLOOR_0"],
		[L.scaled(b, 4), "BENCH_FLOOR_1"],
		[L.scaled(normals["bench_floor_0"], 4), "BENCH_FLOOR_0_N"],
		[L.scaled(normals["bench_floor_1"], 4), "BENCH_FLOOR_1_N"],
		[L.scaled(pair, 4), "0 + 1 LADO A LADO"],
		[L.scaled(L.tiled(a, 4, 4), 4), "0 4X4"],
		[L.scaled(L.tiled(b, 4, 4), 4), "1 4X4"],
		[L.scaled(_mosaic(tex, 4, 4), 4), "MISTO 4X4"],
		[L.scaled(_strip(tex, 0), 2), "RESERVA 20X3 X2 - MURO EM CIMA / ARENA EMBAIXO"],
		[L.scaled(_strip(tex, 3), 2), "RESERVA + STONE_PATH_0 X2"],
	]
	return L.flow_layout(items, 1600, 16, 3, BG, FG)
