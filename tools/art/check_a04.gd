extends SceneTree
## Checagem automática da spec A04 (docs/specs/A04-piso-reserva.md).
## Uma linha por arquivo; no fim "A04 CHECK: PASS" (código 0) ou "A04 CHECK: FAIL (n problemas)" (código 1).
## Rodar da raiz do projeto:
##   "$G" --headless --path . --script tools/art/check_a04.gd

const P = preload("res://tools/art/palette_a03.gd")
const TEX_DIR: String = "res://assets/textures/"
const KEYS: Array[String] = ["bench_floor_0", "bench_floor_1"]
const N: int = 32
const GAP_ROWS: Array[int] = [7, 15, 23, 31]

var _problems: int = 0


func _initialize() -> void:
	var alb: Dictionary = {}
	var nrm: Dictionary = {}
	for key: String in KEYS:
		alb[key] = _load(key)
		nrm[key] = _load(key + "_n")
	for key: String in KEYS:
		if alb[key] != null and nrm[key] != null:
			_check_albedo(key, alb[key], nrm[key])
			_check_normal(key + "_n", nrm[key], alb[key])
	if alb[KEYS[0]] != null and alb[KEYS[1]] != null and nrm[KEYS[0]] != null and nrm[KEYS[1]] != null:
		_check_pair(alb, nrm)
	if _problems == 0:
		print("A04 CHECK: PASS")
		quit(0)
	else:
		print("A04 CHECK: FAIL (%d problemas)" % _problems)
		quit(1)


func _load(key: String) -> Image:
	var path: String = ProjectSettings.globalize_path(TEX_DIR + key + ".png")
	if not FileAccess.file_exists(path):
		_fail(key, "arquivo não existe")
		return null
	var img: Image = Image.load_from_file(path)
	if img == null:
		_fail(key, "não abriu")
		return null
	if img.get_format() != Image.FORMAT_RGBA8:
		_fail(key, "formato não é RGBA8 (%d)" % img.get_format())
		img.convert(Image.FORMAT_RGBA8)
	if img.get_width() != N or img.get_height() != N:
		_fail(key, "tamanho %dx%d" % [img.get_width(), img.get_height()])
		return null
	for y: int in N:
		for x: int in N:
			if img.get_pixel(x, y).a8 != 255:
				_fail(key, "alfa != 255 em (%d,%d)" % [x, y])
				return img
	return img


func _fail(key: String, reason: String) -> void:
	_problems += 1
	print("FAIL  %-17s | %s" % [key, reason])


func _report(key: String, errs: Array[String], info: Array[String]) -> void:
	if errs.is_empty():
		print("ok    %-17s | %s" % [key, ", ".join(info)])
	else:
		for e: String in errs:
			_fail(key, e)
		print("      %-17s | %s" % [key, ", ".join(info)])


func _y(c: Color) -> float:
	return 0.299 * c.r8 / 255.0 + 0.587 * c.g8 / 255.0 + 0.114 * c.b8 / 255.0


func _ymap(img: Image) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(N * N)
	for y: int in N:
		for x: int in N:
			out[y * N + x] = _y(img.get_pixel(x, y))
	return out


func _is_gap(ci: int) -> bool:
	return ci == P.hx("#4B3339") or ci == P.hx("#6B4C3E") or (ci >= 0 and P.family_of(ci) == "moss")


## Emenda: diferença média de Y entre a última linha/coluna de a e a primeira de b, dividida
## pela média das vizinhas do interior de a e b. No eixo y o piso é periódico (fresta a cada
## 8 linhas), então o interior comparável são os pares de mesma fase da emenda (7-8, 15-16, 23-24):
## a emenda conta como invisível se não destoa da passagem fresta -> tábua do meio do tile.
func _seam(a: PackedFloat32Array, b: PackedFloat32Array, axis: int) -> float:
	var edge: float = 0.0
	var interior: float = 0.0
	var n_int: int = 0
	for i: int in N:
		if axis == 0:
			edge += absf(a[i * N + N - 1] - b[i * N])
		else:
			edge += absf(a[(N - 1) * N + i] - b[i])
	edge /= float(N)
	for m: PackedFloat32Array in [a, b]:
		for k: int in N - 1:
			if axis == 1 and k % 8 != 7:
				continue
			for i: int in N:
				if axis == 0:
					interior += absf(m[i * N + k + 1] - m[i * N + k])
				else:
					interior += absf(m[(k + 1) * N + i] - m[k * N + i])
				n_int += 1
	interior /= float(n_int)
	if interior < 1e-6:
		return 0.0 if edge < 1e-6 else 99.0
	return edge / interior


func _checker_frac(idx: PackedInt32Array) -> float:
	var mark: PackedByteArray = PackedByteArray()
	mark.resize(N * N)
	for y: int in N:
		for x: int in N:
			var a: int = idx[y * N + x]
			var b: int = idx[y * N + (x + 1) % N]
			var c: int = idx[((y + 1) % N) * N + x]
			var d: int = idx[((y + 1) % N) * N + (x + 1) % N]
			if a == d and b == c and a != b:
				for o: int in [y * N + x, y * N + (x + 1) % N, ((y + 1) % N) * N + x, ((y + 1) % N) * N + (x + 1) % N]:
					mark[o] = 1
	var n: int = 0
	for v: int in mark:
		n += v
	return float(n) / float(N * N)


## Emendas de topo: [tábua, coluna] com >= 6 px de fresta nas 7 linhas da tábua.
func _joints(idx: PackedInt32Array) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for p: int in 4:
		for x: int in N:
			var n: int = 0
			for y: int in range(p * 8, p * 8 + 7):
				if _is_gap(idx[y * N + x]):
					n += 1
			if n >= 6:
				out.append(Vector2i(p, x))
	return out


func _indices(img: Image) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	out.resize(N * N)
	for y: int in N:
		for x: int in N:
			var c: Color = img.get_pixel(x, y)
			out[y * N + x] = P.find((c.r8 << 16) | (c.g8 << 8) | c.b8)
	return out


func _check_albedo(key: String, img: Image, nimg: Image) -> void:
	var errs: Array[String] = []
	var info: Array[String] = []
	var idx: PackedInt32Array = _indices(img)
	var tones: Dictionary = {}
	var n_wood: int = 0
	var n_gap: int = 0
	for ci: int in idx:
		if ci < 0:
			errs.append("cor fora da paleta")
			break
		var fam: String = P.family_of(ci)
		if fam != "bark" and fam != "moss":
			errs.append("cor %06X fora de Casca e madeira/Musgo" % P.rgb(ci))
			break
		if ci == P.hx("#1A1426") or ci == P.hx("#2C212D"):
			errs.append("usa #1A1426/#2C212D")
			break
		tones[ci] = true
		if ci == P.hx("#C29A6C"):
			n_wood += 1
		if _is_gap(ci):
			n_gap += 1
	var fw: float = n_wood / 1024.0
	var fg: float = n_gap / 1024.0
	info.append("tons %d" % tones.size())
	info.append("C29A6C %.1f%%" % (fw * 100.0))
	info.append("frestas %.1f%%" % (fg * 100.0))
	if tones.size() < 4 or tones.size() > 6:
		errs.append("tons %d fora de 4..6" % tones.size())
	if fw < 0.45:
		errs.append("#C29A6C %.1f%% < 45%%" % (fw * 100.0))
	if fg < 0.08 or fg > 0.16:
		errs.append("frestas %.1f%% fora de 8..16%%" % (fg * 100.0))
	for r: int in GAP_ROWS:
		var n: int = 0
		for x: int in N:
			if _is_gap(idx[r * N + x]):
				n += 1
		if n < 0.85 * N:
			errs.append("linha %d com %.0f%% de fresta" % [r, n * 100.0 / N])
	var js: Array[Vector2i] = _joints(idx)
	info.append("emendas %s" % str(js))
	if js.size() < 1 or js.size() > 2:
		errs.append("%d emendas de topo (esperado 1..2)" % js.size())
	for j: Vector2i in js:
		if j.y == 0 or j.y == N - 1:
			errs.append("emenda de topo na coluna %d" % j.y)
	# luminância e gradiente
	var ys: PackedFloat32Array = _ymap(img)
	var m: float = 0.0
	var h: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
	for y: int in N:
		for x: int in N:
			var v: float = ys[y * N + x]
			m += v
			h[0 if x < 16 else 1] += v
			h[2 if y < 16 else 3] += v
	m /= 1024.0
	var dlr: float = absf(h[0] - h[1]) / 512.0
	var dtb: float = absf(h[2] - h[3]) / 512.0
	info.append("Y %.3f" % m)
	info.append("E/D %.3f C/B %.3f" % [dlr, dtb])
	if m < 0.50 or m > 0.62:
		errs.append("luminância %.3f fora de 0,50..0,62" % m)
	if dlr > 0.04 or dtb > 0.04:
		errs.append("gradiente E/D %.3f C/B %.3f > 0,04" % [dlr, dtb])
	# emenda (albedo e normal)
	var yn: PackedFloat32Array = _ymap(nimg)
	var seams: Array[String] = []
	for ax: int in 2:
		var r: float = _seam(ys, ys, ax)
		var rn: float = _seam(yn, yn, ax)
		seams.append("%s %.2f n%s %.2f" % ["xy"[ax], r, "xy"[ax], rn])
		if r > 1.3 or rn > 1.3:
			errs.append("emenda %s: albedo %.2f normal %.2f > 1,3" % ["xy"[ax], r, rn])
	info.append("emenda " + " ".join(seams))
	var chk: float = _checker_frac(idx)
	info.append("xadrez %.1f%%" % (chk * 100.0))
	if chk > 0.05:
		errs.append("xadrez %.1f%% > 5%%" % (chk * 100.0))
	_report(key, errs, info)


func _check_normal(key: String, nimg: Image, img: Image) -> void:
	var errs: Array[String] = []
	var info: Array[String] = []
	var sx: float = 0.0
	var sy: float = 0.0
	var sz: float = 0.0
	var low: int = 0
	var bad_len: int = 0
	var bad_z: int = 0
	var ax: PackedFloat32Array = PackedFloat32Array()
	var ay: PackedFloat32Array = PackedFloat32Array()
	var al: PackedFloat32Array = PackedFloat32Array()
	for y: int in N:
		for x: int in N:
			var c: Color = nimg.get_pixel(x, y)
			var n: Vector3 = Vector3(c.r8 / 255.0 * 2.0 - 1.0, c.g8 / 255.0 * 2.0 - 1.0, c.b8 / 255.0 * 2.0 - 1.0)
			if absf(n.length() - 1.0) > 0.06:
				bad_len += 1
			if n.z < 0.6:
				bad_z += 1
			if n.z < 0.98:
				low += 1
			sx += n.x
			sy += n.y
			sz += n.z
			ax.append(n.x)
			ay.append(n.y)
			al.append(_y(img.get_pixel(x, y)))
	sx /= 1024.0
	sy /= 1024.0
	sz /= 1024.0
	var fl: float = low / 1024.0
	var px: float = _pearson(al, ax)
	var py: float = _pearson(al, ay)
	info.append("média X %.3f Y %.3f Z %.3f" % [sx, sy, sz])
	info.append("Z<0,98 %.1f%%" % (fl * 100.0))
	info.append("pearson X %.2f Y %.2f" % [px, py])
	if bad_len > 0:
		errs.append("%d px com comprimento fora de 1 +- 0,06" % bad_len)
	if bad_z > 0:
		errs.append("%d px com Z < 0,6" % bad_z)
	if absf(sx) > 0.05 or absf(sy) > 0.05:
		errs.append("média X/Y fora de +-0,05")
	if sz < 0.9:
		errs.append("média Z %.3f < 0,9" % sz)
	if fl < 0.15:
		errs.append("Z<0,98 em %.1f%% < 15%%" % (fl * 100.0))
	if absf(px) > 0.2 or absf(py) > 0.2:
		errs.append("correlação albedo x normal fora de +-0,2")
	_report(key, errs, info)


## _0 ao lado de _1 (nos dois sentidos e nos dois eixos), albedo e normal.
func _check_pair(alb: Dictionary, nrm: Dictionary) -> void:
	var errs: Array[String] = []
	var info: Array[String] = []
	var y0: PackedFloat32Array = _ymap(alb[KEYS[0]])
	var y1: PackedFloat32Array = _ymap(alb[KEYS[1]])
	var n0: PackedFloat32Array = _ymap(nrm[KEYS[0]])
	var n1: PackedFloat32Array = _ymap(nrm[KEYS[1]])
	var worst: float = 0.0
	for ax: int in 2:
		for pr: Array in [[y0, y1], [y1, y0], [n0, n1], [n1, n0]]:
			var r: float = _seam(pr[0], pr[1], ax)
			worst = maxf(worst, r)
			if r > 1.3:
				errs.append("emenda 0/1 eixo %s: %.2f > 1,3" % ["xy"[ax], r])
	var j0: Array[Vector2i] = _joints(_indices(alb[KEYS[0]]))
	var j1: Array[Vector2i] = _joints(_indices(alb[KEYS[1]]))
	for a: Vector2i in j0:
		for b: Vector2i in j1:
			if a.y == b.y:
				errs.append("emenda de topo na mesma coluna %d em _0 e _1" % a.y)
	info.append("pior emenda %.2f" % worst)
	_report("par _0/_1", errs, info)


func _pearson(a: PackedFloat32Array, b: PackedFloat32Array) -> float:
	var n: float = float(a.size())
	var ma: float = 0.0
	var mb: float = 0.0
	for i: int in a.size():
		ma += a[i]
		mb += b[i]
	ma /= n
	mb /= n
	var cov: float = 0.0
	var va: float = 0.0
	var vb: float = 0.0
	for i: int in a.size():
		cov += (a[i] - ma) * (b[i] - mb)
		va += (a[i] - ma) * (a[i] - ma)
		vb += (b[i] - mb) * (b[i] - mb)
	if va < 1e-9 or vb < 1e-9:
		return 0.0
	return cov / sqrt(va * vb)
