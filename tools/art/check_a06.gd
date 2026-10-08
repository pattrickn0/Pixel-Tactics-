extends SceneTree
## Checagem automática da spec A06 (docs/specs/A06-arte-mapa-a-mao.md).
## Uma linha por arquivo; no fim "A06 CHECK: PASS" (código 0) ou "A06 CHECK: FAIL (n problemas)" (código 1).
## Rodar da raiz do projeto:
##   "$G" --headless --path . --script tools/art/check_a06.gd

const P = preload("res://tools/art/palette_a03.gd")
const TEX: String = "res://assets/textures/"

# [arquivo, largura, altura, tipo (o = opaco, a = alfa binário), normal map (1/0), eixos seamless, rampas permitidas]
const FILES: Array = [
	["ground/ground_grass_arena", 64, 64, "o", 0, "xy", "grass_arena flower_white flower_yellow flower_pink"],
	["ground/ground_grass_forest", 64, 64, "o", 0, "xy", "grass_forest bark"],
	["decals/decal_arena_dirt", 448, 352, "a", 0, "", "dirt grass_arena"],
	["decals/decal_grass_light_0", 160, 96, "a", 0, "", "grass_arena"],
	["decals/decal_grass_light_1", 128, 128, "a", 0, "", "grass_arena"],
	["decals/decal_grass_light_2", 96, 64, "a", 0, "", "grass_arena"],
	["decals/decal_grass_dark_0", 128, 96, "a", 0, "", "grass_arena"],
	["decals/decal_grass_dark_1", 96, 96, "a", 0, "", "grass_arena"],
	["decals/decal_forest_soil_0", 128, 96, "a", 0, "", "dark_earth grass_forest bark"],
	["decals/decal_forest_soil_1", 96, 128, "a", 0, "", "dark_earth grass_forest bark"],
	["decals/decal_trail_0", 96, 96, "a", 0, "", "stone moss grass_arena"],
	["decals/decal_trail_1", 96, 96, "a", 0, "", "stone moss grass_arena"],
	["decals/decal_trail_2", 96, 96, "a", 0, "", "stone moss grass_arena"],
	["decals/decal_trail_3", 96, 96, "a", 0, "", "stone moss grass_arena"],
	["decals/decal_trail_bend", 96, 96, "a", 0, "", "stone moss grass_arena"],
	["wall/wall_high_face", 256, 48, "o", 1, "x", "stone moss"],
	["wall/wall_low_face", 256, 16, "o", 1, "x", "stone moss"],
	["wall/wall_crest", 256, 32, "o", 1, "x", "stone moss grass_forest"],
	["wall/wall_cap", 256, 16, "o", 1, "x", "stone moss grass_forest"],
	["wall/wall_quoin", 32, 48, "o", 1, "", "stone moss"],
	["wall/wall_crest_corner", 32, 32, "o", 1, "", "stone moss grass_forest"],
	["wall/wall_cap_corner", 16, 16, "o", 1, "", "stone moss grass_forest"],
	["wall/stair_tread_0", 96, 16, "o", 1, "", "stone moss grass_arena"],
	["wall/stair_tread_1", 96, 16, "o", 1, "", "stone moss grass_arena"],
	["wall/stair_riser_0", 96, 8, "o", 1, "", "stone moss"],
	["wall/stair_riser_1", 96, 8, "o", 1, "", "stone moss"],
	["cards/moss_drape_0", 128, 12, "a", 0, "x", "moss"],
	["cards/moss_drape_1", 128, 12, "a", 0, "x", "moss"],
	["foliage/leaf_mass_green", 64, 64, "o", 0, "xy", "leaf_green"],
	["foliage/leaf_mass_olive", 64, 64, "o", 0, "xy", "leaf_olive"],
	["foliage/leaf_mass_cool", 64, 64, "o", 0, "xy", "leaf_cool"],
	["foliage/leaf_shell_green", 64, 64, "a", 0, "xy", "leaf_green"],
	["foliage/leaf_shell_olive", 64, 64, "a", 0, "xy", "leaf_olive"],
	["foliage/leaf_shell_cool", 64, 64, "a", 0, "xy", "leaf_cool"],
	["foliage/leaf_shell_cool_flower", 64, 64, "a", 0, "xy", "leaf_cool flower_pink flower_white"],
	["foliage/conifer_needles", 64, 32, "o", 0, "x", "conifer"],
	["foliage/conifer_fringe", 128, 16, "a", 0, "x", "conifer"],
	["props/log_bark", 64, 32, "o", 1, "x", "bark moss"],
	["props/crate_side", 24, 24, "o", 1, "", "bark"],
	["props/crate_top", 24, 24, "o", 1, "", "bark"],
	["props/wood_pile_end", 32, 32, "o", 0, "", "bark"],
]
const FORBIDDEN: Array[String] = ["RandomNumberGenerator", "FastNoiseLite", "randi", "randf", "seed"]

var _problems: int = 0
var _img: Dictionary = {}
var _idx: Dictionary = {}


func _initialize() -> void:
	for f: Array in FILES:
		_check_file(f)
	_check_sources()
	_check_ground()
	_check_dirt()
	_check_patches()
	_check_trail()
	_check_walls()
	_check_cards()
	_check_foliage()
	_check_normals()
	if _problems == 0:
		print("A06 CHECK: PASS")
		quit(0)
	else:
		print("A06 CHECK: FAIL (%d problemas)" % _problems)
		quit(1)


func _fail(key: String, reason: String) -> void:
	_problems += 1
	print("  FALHA %s: %s" % [key, reason])


func _y(c: Color) -> float:
	return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b


func _hx(s: String) -> int:
	return P.hx(s)


func _load(key: String, suffix: String = "") -> Image:
	var path: String = ProjectSettings.globalize_path(TEX + key + suffix + ".png")
	if not FileAccess.file_exists(path):
		return null
	var img: Image = Image.load_from_file(path)
	if img != null and img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	return img


## Índices de paleta por pixel: -1 transparente, -2 fora da paleta.
func _indices(img: Image) -> PackedInt32Array:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var out: PackedInt32Array = PackedInt32Array()
	out.resize(w * h)
	for y: int in h:
		for x: int in w:
			var c: Color = img.get_pixel(x, y)
			if c.a8 == 0:
				out[y * w + x] = -1
			else:
				var i: int = P.find((c.r8 << 16) | (c.g8 << 8) | c.b8)
				out[y * w + x] = i if i >= 0 else -2
	return out


func _ix(key: String) -> PackedInt32Array:
	return _idx[key]


func _w(key: String) -> int:
	return (_img[key] as Image).get_width()


func _count_of(key: String, hexes: Array, y0: int = 0, y1: int = -1) -> int:
	var ids: Array[int] = []
	for hxs: String in hexes:
		ids.append(_hx(hxs))
	var w: int = _w(key)
	var h: int = (_img[key] as Image).get_height()
	if y1 < 0:
		y1 = h - 1
	var ix: PackedInt32Array = _ix(key)
	var n: int = 0
	for y: int in range(y0, y1 + 1):
		for x: int in w:
			if ids.has(ix[y * w + x]):
				n += 1
	return n


func _frac(key: String, hexes: Array, y0: int = 0, y1: int = -1) -> float:
	var h: int = (_img[key] as Image).get_height()
	if y1 < 0:
		y1 = h - 1
	return float(_count_of(key, hexes, y0, y1)) / float(_w(key) * (y1 - y0 + 1))


func _mean_y(key: String, y0: int = 0, y1: int = -1) -> float:
	var img: Image = _img[key]
	if y1 < 0:
		y1 = img.get_height() - 1
	var s: float = 0.0
	for y: int in range(y0, y1 + 1):
		for x: int in img.get_width():
			s += _y(img.get_pixel(x, y))
	return s / float(img.get_width() * (y1 - y0 + 1))


# ---------------------------------------------------------------------------
# Arquivo: existência, tamanho, alfa, paleta, emenda
# ---------------------------------------------------------------------------

func _check_file(f: Array) -> void:
	var key: String = f[0]
	var img: Image = _load(key)
	if img == null:
		_fail(key, "arquivo não existe")
		return
	if img.get_width() != int(f[1]) or img.get_height() != int(f[2]):
		_fail(key, "tamanho %dx%d, esperado %dx%d" % [img.get_width(), img.get_height(), int(f[1]), int(f[2])])
		return
	_img[key] = img
	var ix: PackedInt32Array = _indices(img)
	_idx[key] = ix
	var w: int = img.get_width()
	var h: int = img.get_height()
	var allowed: PackedStringArray = String(f[6]).split(" ", false)
	var bad_alpha: int = 0
	var bad_pal: int = 0
	var bad_group: int = 0
	var colors: Dictionary = {}
	var opaque: int = 0
	for i: int in w * h:
		var a: int = img.get_pixel(i % w, i / w).a8
		if a != 0 and a != 255:
			bad_alpha += 1
		if f[3] == "o" and a != 255:
			bad_alpha += 1
		if ix[i] == -2:
			bad_pal += 1
		elif ix[i] >= 0:
			opaque += 1
			colors[ix[i]] = int(colors.get(ix[i], 0)) + 1
			if not allowed.has(P.ramp_of(ix[i])):
				bad_group += 1
	if bad_alpha > 0:
		_fail(key, "%d pixels com alfa inválido" % bad_alpha)
	if bad_pal > 0:
		_fail(key, "%d pixels fora da paleta" % bad_pal)
	if bad_group > 0:
		_fail(key, "%d pixels fora dos grupos permitidos (%s)" % [bad_group, String(f[6])])
	if f[3] == "a":
		# transparentes com RGB do vizinho opaco mais próximo: ao menos, nunca preto puro
		for i2: int in w * h:
			if ix[i2] == -1:
				var c: Color = img.get_pixel(i2 % w, i2 / w)
				if c.r8 + c.g8 + c.b8 == 0:
					_fail(key, "pixel transparente com RGB preto")
					break
	var seams: Array[String] = []
	for ax: int in 2:
		if String(f[5]).find("xy"[ax]) < 0:
			continue
		var r: float = _seam(img, ax, f[3] == "a")
		seams.append("%s %.2f" % ["xy"[ax], r])
		if r > 1.3:
			_fail(key, "emenda %s %.2f > 1,3" % ["xy"[ax], r])
	print("%s: %dx%d, %d cores, emenda [%s]" % [key, w, h, colors.size(), " ".join(seams)])


func _seam(img: Image, axis: int, transparent_zero: bool) -> float:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var yv: PackedFloat32Array = PackedFloat32Array()
	yv.resize(w * h)
	for y: int in h:
		for x: int in w:
			var c: Color = img.get_pixel(x, y)
			yv[y * w + x] = 0.0 if (transparent_zero and c.a8 == 0) else _y(c)
	var interior: float = 0.0
	var edge: float = 0.0
	if axis == 0:
		for x: int in w - 1:
			for y: int in h:
				interior += absf(yv[y * w + x + 1] - yv[y * w + x])
		interior /= float((w - 1) * h)
		for y: int in h:
			edge += absf(yv[y * w] - yv[y * w + w - 1])
		edge /= float(h)
	else:
		for y: int in h - 1:
			for x: int in w:
				interior += absf(yv[(y + 1) * w + x] - yv[y * w + x])
		interior /= float((h - 1) * w)
		for x: int in w:
			edge += absf(yv[x] - yv[(h - 1) * w + x])
		edge /= float(w)
	if interior < 1e-6:
		return 0.0 if edge < 1e-6 else 99.0
	return edge / interior


# ---------------------------------------------------------------------------
# Código-fonte sem RNG
# ---------------------------------------------------------------------------

func _check_sources() -> void:
	var dir: DirAccess = DirAccess.open(ProjectSettings.globalize_path("res://tools/art/"))
	var n: int = 0
	for fn: String in dir.get_files():
		if fn.begins_with("gen_a06_") and fn.ends_with(".gd"):
			n += 1
			var txt: String = FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://tools/art/" + fn))
			for word: String in FORBIDDEN:
				if txt.find(word) >= 0:
					_fail(fn, "contém '%s'" % word)
	print("fontes gen_a06_*.gd conferidas: %d" % n)


# ---------------------------------------------------------------------------
# Chão
# ---------------------------------------------------------------------------

## Componentes (8-conectados) de pixels diferentes do tom base; devolve [bbox w, bbox h, assinatura].
func _components(ix: PackedInt32Array, w: int, h: int, base: int, wrap: bool) -> Array:
	var seen: PackedByteArray = PackedByteArray()
	seen.resize(w * h)
	var out: Array = []
	for s: int in w * h:
		if seen[s] != 0 or ix[s] == base:
			continue
		var stack: Array[int] = [s]
		seen[s] = 1
		var pts: Array[Vector2i] = []
		while not stack.is_empty():
			var p: int = stack.pop_back()
			var px: int = p % w
			var py: int = p / w
			pts.append(Vector2i(px, py))
			for dy: int in range(-1, 2):
				for dx: int in range(-1, 2):
					var nx: int = px + dx
					var ny: int = py + dy
					if wrap:
						nx = posmod(nx, w)
						ny = posmod(ny, h)
					elif nx < 0 or ny < 0 or nx >= w or ny >= h:
						continue
					var q: int = ny * w + nx
					if seen[q] == 0 and ix[q] != base:
						seen[q] = 1
						stack.append(q)
		var minx: int = 1 << 20
		var miny: int = 1 << 20
		var maxx: int = -1
		var maxy: int = -1
		for v: Vector2i in pts:
			minx = mini(minx, v.x)
			miny = mini(miny, v.y)
			maxx = maxi(maxx, v.x)
			maxy = maxi(maxy, v.y)
		var sig: Array[String] = []
		for v2: Vector2i in pts:
			sig.append("%d,%d,%d" % [v2.x - minx, v2.y - miny, ix[v2.y * w + v2.x]])
		sig.sort()
		out.append([maxx - minx + 1, maxy - miny + 1, ",".join(sig), pts.size()])
	return out


func _check_ground() -> void:
	var ga: String = "ground/ground_grass_arena"
	var gf: String = "ground/ground_grass_forest"
	if not _img.has(ga) or not _img.has(gf):
		return
	var base_a: float = _frac(ga, ["#5B9C47"])
	var detail_a: float = 1.0 - base_a
	if base_a < 0.75 or detail_a < 0.01 or detail_a > 0.06:
		_fail(ga, "base %.1f%% detalhe %.1f%%" % [base_a * 100.0, detail_a * 100.0])
	var base_f: float = _frac(gf, ["#3D853C"])
	var detail_f: float = 1.0 - base_f
	if base_f < 0.70 or detail_f < 0.03 or detail_f > 0.15:
		_fail(gf, "base %.1f%% detalhe %.1f%%" % [base_f * 100.0, detail_f * 100.0])
	var leaves: float = _frac(gf, ["#876547"])
	if leaves > 0.03:
		_fail(gf, "folhas caídas %.1f%% > 3%%" % [leaves * 100.0])
	for k: Array in [[ga, "#5B9C47"], [gf, "#3D853C"]]:
		var comps: Array = _components(_ix(k[0]), 64, 64, _hx(k[1]), true)
		var seen: Dictionary = {}
		for c: Array in comps:
			if int(c[0]) > 4 or int(c[1]) > 4:
				if seen.has(c[2]):
					_fail(k[0], "elemento maior que 4x4 repetido")
				seen[c[2]] = true
		# tracinhos todos diferentes entre si
		var sigs: Dictionary = {}
		for c2: Array in comps:
			if sigs.has(c2[2]):
				_fail(k[0], "dois tracinhos iguais")
			sigs[c2[2]] = true
	print("chão: arena base %.1f%% detalhe %.1f%%; mata base %.1f%% detalhe %.1f%%" % [base_a * 100.0, detail_a * 100.0, base_f * 100.0, detail_f * 100.0])


## Maior trecho reto de borda (linha ou coluna) de um decalque.
func _max_edge_run(ix: PackedInt32Array, w: int, h: int) -> int:
	var best: int = 0
	for dir: int in 4:
		var dx: int = [0, 0, -1, 1][dir]
		var dy: int = [-1, 1, 0, 0][dir]
		if dy != 0:
			for y: int in h:
				var run: int = 0
				for x: int in w:
					var edge: bool = ix[y * w + x] != -1 and (y + dy < 0 or y + dy >= h or ix[(y + dy) * w + x] == -1)
					run = run + 1 if edge else 0
					best = maxi(best, run)
		else:
			for x: int in w:
				var run2: int = 0
				for y: int in h:
					var edge2: bool = ix[y * w + x] != -1 and (x + dx < 0 or x + dx >= w or ix[y * w + x + dx] == -1)
					run2 = run2 + 1 if edge2 else 0
					best = maxi(best, run2)
	return best


func _check_dirt() -> void:
	var key: String = "decals/decal_arena_dirt"
	if not _img.has(key):
		return
	var w: int = 448
	var h: int = 352
	var ix: PackedInt32Array = _ix(key)
	var dirt_ids: Array[int] = [_hx("#A8955F"), _hx("#C0AE71"), _hx("#D4C48C"), _hx("#8E7B4C")]
	var aro: int = _hx("#73A949")
	var opaque: int = 0
	var dirt: int = 0
	var main: int = 0
	for i: int in w * h:
		if ix[i] >= 0:
			opaque += 1
		if dirt_ids.has(ix[i]):
			dirt += 1
			if ix[i] == dirt_ids[1]:
				main += 1
	var op_frac: float = float(opaque) / float(w * h)
	if op_frac < 0.45 or op_frac > 0.75:
		_fail(key, "opacos %.1f%% fora de 45–75%%" % [op_frac * 100.0])
	if float(dirt) / float(opaque) < 0.70:
		_fail(key, "terra %.1f%% dos opacos < 70%%" % [100.0 * float(dirt) / float(opaque)])
	if float(main) / float(dirt) < 0.85:
		_fail(key, "#C0AE71 %.1f%% da terra < 85%%" % [100.0 * float(main) / float(dirt)])
	# terra nunca encosta em transparente nem em grama que não seja o aro
	var bad: int = 0
	for y: int in h:
		for x: int in w:
			if not dirt_ids.has(ix[y * w + x]):
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx < 0 or ny < 0 or nx >= w or ny >= h:
					bad += 1
					continue
				var q: int = ix[ny * w + nx]
				if q == -1 or (P.ramp_of(q) == "grass_arena" and q != aro):
					bad += 1
	if bad > 0:
		_fail(key, "%d pixels de terra sem aro de grama clara" % bad)
	# ilhas de grama dentro do contorno: componentes de não-terra opaca que não tocam transparente
	var seen: PackedByteArray = PackedByteArray()
	seen.resize(w * h)
	var islands: int = 0
	for s: int in w * h:
		if seen[s] != 0 or ix[s] < 0 or dirt_ids.has(ix[s]):
			continue
		var stack: Array[int] = [s]
		seen[s] = 1
		var touches: bool = false
		while not stack.is_empty():
			var p: int = stack.pop_back()
			var px: int = p % w
			var py: int = p / w
			for d2: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx2: int = px + d2.x
				var ny2: int = py + d2.y
				if nx2 < 0 or ny2 < 0 or nx2 >= w or ny2 >= h:
					touches = true
					continue
				var q2: int = ny2 * w + nx2
				if ix[q2] == -1:
					touches = true
				elif seen[q2] == 0 and not dirt_ids.has(ix[q2]):
					seen[q2] = 1
					stack.append(q2)
		if not touches:
			islands += 1
	if islands < 4:
		_fail(key, "%d ilhas de grama (mínimo 4)" % islands)
	var run: int = _max_edge_run(ix, w, h)
	if run > 6:
		_fail(key, "trecho reto de borda com %d px (máx. 6)" % run)
	print("terra da arena: opacos %.1f%%, terra %.1f%%, ilhas %d, maior trecho reto %d" % [op_frac * 100.0, 100.0 * float(dirt) / float(opaque), islands, run])


func _mask(key: String) -> Array:
	var ix: PackedInt32Array = _ix(key)
	var w: int = _w(key)
	var h: int = (_img[key] as Image).get_height()
	var rows: Array = []
	for y: int in h:
		var r: String = ""
		for x: int in w:
			r += "1" if ix[y * w + x] != -1 else "0"
		rows.append(r)
	return rows


func _rot(rows: Array) -> Array:
	var h: int = rows.size()
	var w: int = String(rows[0]).length()
	var out: Array = []
	for x: int in w:
		var r: String = ""
		for y: int in range(h - 1, -1, -1):
			r += String(rows[y])[x]
		out.append(r)
	return out


func _check_patches() -> void:
	var keys: Array[String] = ["decals/decal_grass_light_0", "decals/decal_grass_light_1", "decals/decal_grass_light_2", "decals/decal_grass_dark_0", "decals/decal_grass_dark_1", "decals/decal_forest_soil_0", "decals/decal_forest_soil_1"]
	for k: String in keys:
		if not _img.has(k):
			return
	var masks: Dictionary = {}
	for k2: String in keys:
		var run: int = _max_edge_run(_ix(k2), _w(k2), (_img[k2] as Image).get_height())
		if run > 6:
			_fail(k2, "trecho reto de borda com %d px (máx. 6)" % run)
		masks[k2] = _mask(k2)
	for i: int in keys.size():
		for j: int in range(i + 1, keys.size()):
			var b: Array = masks[keys[j]]
			for r: int in 4:
				if masks[keys[i]] == b:
					_fail(keys[i], "máscara igual à de %s (giro %d)" % [keys[j], r * 90])
				b = _rot(b)
	print("manchas: bordas e formas conferidas")


# ---------------------------------------------------------------------------
# Trilha
# ---------------------------------------------------------------------------

func _check_trail() -> void:
	var ks: Array[String] = ["decals/decal_trail_0", "decals/decal_trail_1", "decals/decal_trail_2", "decals/decal_trail_3", "decals/decal_trail_bend"]
	for k: String in ks:
		if not _img.has(k):
			return
	var ref: Image = _img[ks[0]]
	for k2: String in ks:
		var im: Image = _img[k2]
		for y: int in 96:
			for x: int in [0, 1]:
				if not _same(ref.get_pixel(x, y), im.get_pixel(x, y)):
					_fail(k2, "colunas 0-1 diferentes da variante 0 em y=%d" % y)
					break
			if k2 != ks[4]:
				for x2: int in [94, 95]:
					if not _same(ref.get_pixel(x2 - 94, y), im.get_pixel(x2, y)):
						_fail(k2, "colunas 94-95 diferentes das colunas 0-1 em y=%d" % y)
						break
	# curva: linhas 94-95 = faixa girada
	var bend: Image = _img[ks[4]]
	for x3: int in 96:
		for k3: int in [0, 1]:
			if not _same(bend.get_pixel(x3, 94 + k3), ref.get_pixel(94 + k3, 95 - x3)):
				_fail(ks[4], "linhas 94-95 não casam com a faixa girada em x=%d" % x3)
				break
	for k4: String in ks:
		var ix: PackedInt32Array = _ix(k4)
		var op: int = 0
		var jn: int = 0
		for i: int in 96 * 96:
			if ix[i] >= 0:
				op += 1
				if ix[i] == _hx("#7A7A66") or ix[i] == _hx("#5C6250"):
					jn += 1
		var fr: float = float(jn) / float(op)
		if fr < 0.10 or fr > 0.20:
			_fail(k4, "juntas %.1f%% fora de 10–20%%" % [fr * 100.0])
		if k4 != ks[4]:
			for x4: int in 96:
				var cnt: int = 0
				for y4: int in 96:
					if ix[y4 * 96 + x4] >= 0:
						cnt += 1
				if cnt < 64 or cnt > 84:
					_fail(k4, "largura %d px na coluna %d (64–84)" % [cnt, x4])
					break
		print("%s: juntas %.1f%%" % [k4, fr * 100.0])


func _same(a: Color, b: Color) -> bool:
	return a.a8 == b.a8 and (a.a8 == 0 or (a.r8 == b.r8 and a.g8 == b.g8 and a.b8 == b.b8))


# ---------------------------------------------------------------------------
# Muro e escada
# ---------------------------------------------------------------------------

func _distinct(key: String, y0: int, y1: int) -> int:
	var w: int = _w(key)
	var ix: PackedInt32Array = _ix(key)
	var s: Dictionary = {}
	for y: int in range(y0, y1 + 1):
		for x: int in w:
			s[ix[y * w + x]] = true
	return s.size()


func _check_walls() -> void:
	var hf: String = "wall/wall_high_face"
	if _img.has(hf):
		for rng: Array in [[0, 47], [0, 31]]:
			var y0: int = rng[0]
			var y1: int = rng[1]
			var nc: int = _distinct(hf, y0, y1)
			var jn: float = _frac(hf, ["#34403C", "#1C2B2B"], y0, y1)
			var ms: float = _frac(hf, ["#496819", "#5E7C26", "#789636", "#8FAE48", "#B0C860"], y0, y1)
			var ly: float = _mean_y(hf, y0, y1)
			var mt: int = 0
			for mh: String in ["#496819", "#5E7C26", "#789636"]:
				if _count_of(hf, [mh], y0, y1) > 0:
					mt += 1
			if nc < 5 or nc > 10:
				_fail(hf, "linhas %d-%d: %d cores (5–10)" % [y0, y1, nc])
			if jn < 0.14 or jn > 0.26:
				_fail(hf, "linhas %d-%d: juntas %.1f%% (14–26)" % [y0, y1, jn * 100.0])
			if ms < 0.08 or ms > 0.20:
				_fail(hf, "linhas %d-%d: musgo %.1f%% (8–20)" % [y0, y1, ms * 100.0])
			if mt < 3:
				_fail(hf, "linhas %d-%d: só %d tons de musgo (3)" % [y0, y1, mt])
			if ly < 0.45 or ly > 0.58:
				_fail(hf, "linhas %d-%d: luminância %.3f (0,45–0,58)" % [y0, y1, ly])
			print("%s linhas %d-%d: cores %d, juntas %.1f%%, musgo %.1f%%, Y %.3f" % [hf, y0, y1, nc, jn * 100.0, ms * 100.0, ly])
		var ix: PackedInt32Array = _ix(hf)
		for y: int in 48:
			var n: int = 0
			for x: int in 256:
				if ix[y * 256 + x] == _hx("#34403C") or ix[y * 256 + x] == _hx("#1C2B2B"):
					n += 1
			if n >= 230:
				_fail(hf, "linha %d com %d%% de junta" % [y, n * 100 / 256])
		_check_windows(hf)
	var lf: String = "wall/wall_low_face"
	if _img.has(lf):
		print("%s: cores %d, Y %.3f" % [lf, _distinct(lf, 0, 15), _mean_y(lf)])
	var ga: float = _mean_y("ground/ground_grass_arena") if _img.has("ground/ground_grass_arena") else 0.5
	var stone_light: Array = ["#B9B597", "#D3CCB4"]
	var moss_all: Array = ["#496819", "#5E7C26", "#789636", "#8FAE48", "#B0C860"]
	if _img.has("wall/wall_crest"):
		var m: float = _frac("wall/wall_crest", moss_all)
		var sl: float = _frac("wall/wall_crest", stone_light)
		var ly2: float = _mean_y("wall/wall_crest")
		if m < 0.40 or m > 0.65:
			_fail("wall_crest", "musgo %.1f%% (40–65)" % [m * 100.0])
		if sl < 0.25:
			_fail("wall_crest", "pedra clara %.1f%% (>= 25)" % [sl * 100.0])
		if ly2 < ga + 0.08:
			_fail("wall_crest", "luminância %.3f < grama + 0,08 (%.3f)" % [ly2, ga + 0.08])
		print("wall_crest: musgo %.1f%%, pedra clara %.1f%%, Y %.3f (grama %.3f)" % [m * 100.0, sl * 100.0, ly2, ga])
	if _img.has("wall/wall_cap"):
		var m2: float = _frac("wall/wall_cap", moss_all)
		var sl2: float = _frac("wall/wall_cap", stone_light)
		var ly3: float = _mean_y("wall/wall_cap")
		var near: float = _frac("wall/wall_cap", moss_all, 8, 15)
		var far: float = _frac("wall/wall_cap", moss_all, 0, 7)
		if m2 < 0.20 or m2 > 0.40:
			_fail("wall_cap", "musgo %.1f%% (20–40)" % [m2 * 100.0])
		if sl2 < 0.25:
			_fail("wall_cap", "pedra clara %.1f%% (>= 25)" % [sl2 * 100.0])
		if ly3 < ga + 0.08:
			_fail("wall_cap", "luminância %.3f < grama + 0,08" % ly3)
		if near <= far:
			_fail("wall_cap", "musgo não é maior perto da linha 15")
		print("wall_cap: musgo %.1f%%, pedra clara %.1f%%, Y %.3f" % [m2 * 100.0, sl2 * 100.0, ly3])
	if _img.has("props/log_bark"):
		var lm: float = _frac("props/log_bark", ["#5E7C26", "#789636", "#8FAE48"], 0, 7)
		if lm < 0.5 or lm > 0.8:
			_fail("props/log_bark", "musgo nas linhas 0-7: %.0f%% (50–80)" % [lm * 100.0])
		print("log_bark: musgo nas linhas 0-7 %.0f%%" % [lm * 100.0])
	for v: int in 2:
		var tk: String = "wall/stair_tread_%d" % v
		if _img.has(tk):
			var r0: float = _frac(tk, ["#D3CCB4"], 0, 0)
			var r15: float = _frac(tk, ["#5C6250"], 15, 15)
			if r0 < 0.80:
				_fail(tk, "linha 0 com %.0f%% de #D3CCB4" % [r0 * 100.0])
			if r15 < 0.80:
				_fail(tk, "linha 15 com %.0f%% de #5C6250" % [r15 * 100.0])
			print("%s: linha 0 %.0f%%, linha 15 %.0f%%" % [tk, r0 * 100.0, r15 * 100.0])
	_check_slab_windows("wall/wall_crest", 32)
	_check_slab_windows("wall/wall_cap", 16)
	_check_edges_and_corners()
	if _img.has("wall/wall_quoin") and _img.has(hf):
		# coluna 0 da quina = coluna 0 da face
		var q: Image = _img["wall/wall_quoin"]
		var f: Image = _img[hf]
		for y2: int in 48:
			if not _same(q.get_pixel(0, y2), f.get_pixel(0, y2)):
				_fail("wall_quoin", "coluna 0 diferente da face em y=%d" % y2)
				break


## Janelas 12x8 alinhadas ao canto de cada bloco não podem se repetir.
func _check_windows(key: String) -> void:
	var ix: PackedInt32Array = _ix(key)
	var jn: Array[int] = [_hx("#34403C"), _hx("#1C2B2B")]
	var seen: Dictionary = {}
	var dup: int = 0
	var total: int = 0
	for y: int in 40:
		for x: int in 256:
			var c: int = ix[y * 256 + x]
			if jn.has(c):
				continue
			var left: int = ix[y * 256 + posmod(x - 1, 256)]
			var up: int = ix[(y - 1) * 256 + x] if y > 0 else jn[0]
			if not jn.has(left) or not jn.has(up):
				continue
			var sig: String = ""
			for j: int in 8:
				for i: int in 12:
					sig += "%d," % ix[(y + j) * 256 + posmod(x + i, 256)]
			total += 1
			if seen.has(sig):
				dup += 1
				print("    janela repetida em (%d,%d) e %s" % [x, y, seen[sig]])
			seen[sig] = "(%d,%d)" % [x, y]
	if dup > 0:
		_fail(key, "%d janelas 12x8 repetidas (de %d)" % [dup, total])
	print("%s: janelas 12x8 de bloco: %d, repetidas %d" % [key, total, dup])


## Janelas 12x8 ancoradas no canto de cada laje (pixel de pedra sem pedra à esquerda nem em cima) não podem se repetir.
func _check_slab_windows(key: String, h: int) -> void:
	if not _img.has(key):
		return
	var ix: PackedInt32Array = _ix(key)
	var w: int = 256
	var stone_ids: Array[int] = [_hx("#989680"), _hx("#B9B597"), _hx("#D3CCB4")]
	var seen: Dictionary = {}
	var dup: int = 0
	var total: int = 0
	for y: int in h - 8:
		for x: int in range(1, w - 12):
			if not stone_ids.has(ix[y * w + x]):
				continue
			if stone_ids.has(ix[y * w + x - 1]):
				continue
			if y > 0 and stone_ids.has(ix[(y - 1) * w + x]):
				continue
			var sig: String = ""
			for j: int in 8:
				for i: int in 12:
					sig += "%d," % ix[(y + j) * w + x + i]
			total += 1
			if seen.has(sig):
				dup += 1
				print("    janela de laje repetida em (%d,%d) e %s" % [x, y, seen[sig]])
			seen[sig] = "(%d,%d)" % [x, y]
	if dup > 0:
		_fail(key, "%d janelas 12x8 de laje repetidas (de %d)" % [dup, total])
	print("%s: janelas 12x8 de laje: %d, repetidas %d" % [key, total, dup])


func _check_edges_and_corners() -> void:
	var s0: int = _hx("#989680")
	if _img.has("wall/wall_crest"):
		var ix: PackedInt32Array = _ix("wall/wall_crest")
		for y: int in 32:
			if (y < 10 or y >= 22) and ix[y * 256] != s0:
				_fail("wall_crest", "coluna 0 não é junta #989680 em y=%d" % y)
				break
	if _img.has("wall/wall_cap"):
		var ixc: PackedInt32Array = _ix("wall/wall_cap")
		for y2: int in 11:
			if ixc[y2 * 256] != s0:
				_fail("wall_cap", "coluna 0 não é junta em y=%d" % y2)
				break
	if _img.has("wall/wall_crest_corner"):
		var ixk: PackedInt32Array = _ix("wall/wall_crest_corner")
		for y3: int in 32:
			if (y3 < 10 or y3 >= 22) and ixk[y3 * 32] != s0:
				_fail("wall_crest_corner", "coluna 0 sem junta em y=%d" % y3)
				break
		for x: int in 32:
			if (x < 10 or x >= 22) and ixk[31 * 32 + x] != s0:
				_fail("wall_crest_corner", "linha 31 sem junta em x=%d" % x)
				break
		# L: linha 0 e coluna 31 são pedra
		for x2: int in range(1, 32):
			if P.ramp_of(ixk[x2]) != "stone":
				_fail("wall_crest_corner", "linha 0 não é pedra em x=%d" % x2)
				break
		for y4: int in range(0, 31):
			if P.ramp_of(ixk[y4 * 32 + 31]) != "stone":
				_fail("wall_crest_corner", "coluna 31 não é pedra em y=%d" % y4)
				break
	if _img.has("wall/wall_cap_corner"):
		var ixp: PackedInt32Array = _ix("wall/wall_cap_corner")
		for y5: int in 11:
			if ixp[y5 * 16] != s0:
				_fail("wall_cap_corner", "coluna 0 sem junta em y=%d" % y5)
				break
		for x3: int in 16:
			if ixp[15 * 16 + x3] != s0:
				_fail("wall_cap_corner", "linha 15 sem junta em x=%d" % x3)
				break
		for x4: int in range(1, 16):
			if P.ramp_of(ixp[x4]) != "stone":
				_fail("wall_cap_corner", "linha 0 não é pedra em x=%d" % x4)
				break


# ---------------------------------------------------------------------------
# Cartões
# ---------------------------------------------------------------------------

func _col_len(ix: PackedInt32Array, w: int, h: int, x: int) -> int:
	var n: int = 0
	for y: int in h:
		if ix[y * w + x] >= 0:
			n += 1
		else:
			break
	return n


func _check_cards() -> void:
	for v: int in 2:
		var k: String = "cards/moss_drape_%d" % v
		if not _img.has(k):
			continue
		var ix: PackedInt32Array = _ix(k)
		var op: int = 0
		for i: int in 128 * 12:
			if ix[i] >= 0:
				op += 1
		var cov: float = float(op) / float(128 * 12)
		var short: int = 0
		for x: int in 128:
			if ix[x] < 0 or ix[128 + x] < 0:
				_fail(k, "linhas 0-1 não opacas em x=%d" % x)
				break
			var ln: int = _col_len(ix, 128, 12, x)
			if ln > 10:
				_fail(k, "cortina de %d px em x=%d (máx. 10)" % [ln, x])
			if ln <= 6:
				short += 1
		var r11: int = 0
		for x2: int in 128:
			if ix[11 * 128 + x2] >= 0:
				r11 += 1
		if cov < 0.25 or cov > 0.45:
			_fail(k, "cobertura %.1f%% (25–45)" % [cov * 100.0])
		if r11 > 6:
			_fail(k, "linha 11 com %d px (máx. 5%%)" % r11)
		if short * 2 < 128:
			_fail(k, "a maioria das cortinas deveria ter <= 6 px")
		print("%s: cobertura %.1f%%, colunas <= 6 px: %d" % [k, cov * 100.0, short])
	if _img.has("cards/moss_drape_0") and _img.has("cards/moss_drape_1"):
		var a: Image = _img["cards/moss_drape_0"]
		var b: Image = _img["cards/moss_drape_1"]
		for y: int in 12:
			for x: int in [0, 1, 126, 127]:
				if not _same(a.get_pixel(x, y), b.get_pixel(x, y)):
					_fail("moss_drape", "colunas de emenda diferentes entre as duas variantes (%d,%d)" % [x, y])


func _check_foliage() -> void:
	for f: String in ["green", "olive", "cool", "cool_flower"]:
		var k: String = "foliage/leaf_shell_" + f
		if not _img.has(k):
			continue
		var ix: PackedInt32Array = _ix(k)
		var n: int = 0
		for i: int in 64 * 64:
			if ix[i] >= 0:
				n += 1
		var cov: float = float(n) / 4096.0
		if cov < 0.45 or cov > 0.70:
			_fail(k, "cobertura %.1f%% (45–70)" % [cov * 100.0])
		print("%s: cobertura %.1f%%" % [k, cov * 100.0])
	if _img.has("foliage/leaf_shell_cool_flower"):
		var ix2: PackedInt32Array = _ix("foliage/leaf_shell_cool_flower")
		var fl: int = 0
		for i2: int in 64 * 64:
			if ix2[i2] >= 0 and P.family_of(ix2[i2]) == "flowers":
				fl += 1
		if fl < 6 * 5:
			_fail("leaf_shell_cool_flower", "poucas flores (%d px)" % fl)
	if _img.has("foliage/conifer_fringe"):
		var fx: PackedInt32Array = _ix("foliage/conifer_fringe")
		for y: int in 3:
			for x: int in 128:
				if fx[y * 128 + x] < 0:
					_fail("conifer_fringe", "linhas 0-2 não opacas em (%d,%d)" % [x, y])
					return
		var worst: int = 0
		for x2: int in 128:
			worst = maxi(worst, _col_len(fx, 128, 16, x2))
		if worst > 15:
			_fail("conifer_fringe", "ponta de %d px" % worst)


# ---------------------------------------------------------------------------
# Normal maps
# ---------------------------------------------------------------------------

func _check_normals() -> void:
	for f: Array in FILES:
		if int(f[4]) != 1:
			continue
		var key: String = f[0] + "_n"
		var img: Image = _load(f[0], "_n")
		if img == null:
			_fail(key, "arquivo não existe")
			continue
		if img.get_width() != int(f[1]) or img.get_height() != int(f[2]):
			_fail(key, "tamanho diferente do albedo")
			continue
		var w: int = img.get_width()
		var h: int = img.get_height()
		var sx: float = 0.0
		var sy: float = 0.0
		var sz: float = 0.0
		var minz: float = 1.0
		var maxdev: float = 0.0
		for y: int in h:
			for x: int in w:
				var c: Color = img.get_pixel(x, y)
				if c.a8 != 255:
					_fail(key, "alfa != 255")
					return
				var n: Vector3 = Vector3(c.r * 2.0 - 1.0, c.g * 2.0 - 1.0, c.b * 2.0 - 1.0)
				sx += n.x
				sy += n.y
				sz += n.z
				minz = minf(minz, n.z)
				maxdev = maxf(maxdev, absf(n.length() - 1.0))
		var cnt: float = float(w * h)
		var seam_txt: String = ""
		for ax: int in 2:
			if String(f[5]).find("xy"[ax]) >= 0:
				var r: float = _seam(img, ax, false)
				seam_txt += " emenda %s %.2f" % ["xy"[ax], r]
				if r > 1.3:
					_fail(key, "emenda %s %.2f > 1,3" % ["xy"[ax], r])
		if maxdev > 0.06:
			_fail(key, "comprimento do vetor desvia %.3f" % maxdev)
		if minz < 0.6:
			_fail(key, "Z mínimo %.2f < 0,6" % minz)
		if absf(sx / cnt) > 0.05 or absf(sy / cnt) > 0.05:
			_fail(key, "médias X %.3f Y %.3f fora de ±0,05" % [sx / cnt, sy / cnt])
		if sz / cnt < 0.9:
			_fail(key, "Z médio %.3f < 0,9" % [sz / cnt])
		print("%s: Zmin %.2f, médias X %.3f Y %.3f Z %.3f,%s" % [key, minz, sx / cnt, sy / cnt, sz / cnt, seam_txt])
