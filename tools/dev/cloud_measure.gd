class_name CloudMeasure
extends RefCounted
## Medidas das nuvens da spec 013 ("Como medir" e critérios), usadas por compare_images.gd --clouds.
## L = 0,2126 R + 0,7152 G + 0,0722 B (sRGB 0..255); S = (máx - mín) / máx. Ar = S < 0,30 e L > 115 e não verde
## (G > R + 6 e G > B + 6); ar erodido = mínimo 7 x 7 (tira franja de folhas, cipós e rochas). Iluminado = ar erodido
## com L >= 215. Toda medida "do ar" usa o ar erodido. Estrutura = Pearson do L desfocado (gaussiano 6 px) nos
## pixels de ar das duas imagens; perfil = média de L do ar em faixas de 20 px (Pearson e erro médio); gradiente =
## módulo das diferenças centrais do L desfocado com 1 px, no ar.

## Massas da Tabela N1: [nome, caixa (x0, y0, largura, altura), classe (0 principal, 1 secundária, 2 = M8),
## L P10, P50, P90, cor média, fração iluminada].
const MASSES: Array = [
	["M1", Rect2i(100, 40, 280, 180), 1, 200.0, 230.0, 242.0, "#EDDBC9", 0.72],
	["M2", Rect2i(380, 40, 155, 220), 0, 198.0, 215.0, 239.0, "#E5D6D2", 0.51],
	["M3", Rect2i(0, 220, 180, 300), 0, 167.0, 192.0, 236.0, "#D2C2C2", 0.26],
	["M4", Rect2i(40, 540, 260, 180), 1, 160.0, 182.0, 219.0, "#C0B8BE", 0.14],
	["M5", Rect2i(800, 40, 200, 220), 0, 171.0, 195.0, 231.0, "#CDC3CC", 0.29],
	["M6", Rect2i(1000, 0, 280, 230), 0, 162.0, 198.0, 227.0, "#CCC0C6", 0.28],
	["M7", Rect2i(1140, 230, 140, 290), 1, 160.0, 179.0, 214.0, "#BAB5BE", 0.09],
	["M8", Rect2i(980, 580, 300, 140), 2, 139.0, 150.0, 156.0, "#8C96AD", 0.0],
]
## Tabela N2: tons P5, P50 e P95 de cada massa (M1 P5 tem mistura com a ilhota e não vale como alvo).
const TONES: Dictionary = {
	"M1": ["", "#F6E3D1", "#FEF4D6"], "M2": ["#CDBFC8", "#E5D4D1", "#FEF1E0"], "M3": ["#A9A1B1", "#D1BCBE", "#FEEFD7"],
	"M4": ["#929DB4", "#BFB3BD", "#F1DDCA"], "M5": ["#9B9AA8", "#CCBFCD", "#F7E8E3"], "M6": ["#8F98AF", "#D5C2C6", "#F7E4D7"],
	"M7": ["#8F9FB7", "#B7B1BE", "#EED8CB"], "M8": ["#818597", "#8D97AD", "#9FA3B6"],
}
## Limites [principal, secundária]: estrutura, perfil r, perfil MAE, IoU, centróide, L, fração, cor, tons, gradiente
## (faixa da razão e teto do P95).
const LIM_STRUCT: Array[float] = [0.60, 0.50]
const LIM_PROF_R: Array[float] = [0.75, 0.60]
const LIM_PROF_MAE: Array[float] = [10.0, 14.0]
const LIM_IOU: Array[float] = [0.45, 0.35]
const LIM_CENTROID: Array[float] = [25.0, 35.0]
const LIM_L: Array[float] = [10.0, 14.0]
const LIM_FRAC: Array[float] = [0.10, 0.12]
const LIM_COLOR: Array[float] = [0.04, 0.05]
const LIM_TONE: Array[float] = [0.06, 0.08]
const LIM_GRAD_LO: Array[float] = [0.75, 0.70]
const LIM_GRAD_HI: Array[float] = [1.30, 1.40]
const LIT_L: float = 215.0
const ERODE: int = 7
const BAND: int = 20
## Margem das janelas de cálculo (3 sigma do desfoque maior + erosão): dentro da caixa o resultado é o da imagem inteira.
const MARGIN: int = 22


## Dados de uma imagem numa janela: L, cor, ar erodido, L desfocado (6 e 1 px).
class MeasureWindow extends RefCounted:
	var rect: Rect2i
	var lum := PackedFloat32Array()
	var rgb := PackedVector3Array()
	var air := PackedByteArray()
	var blur6 := PackedFloat32Array()
	var blur1 := PackedFloat32Array()

	func idx(x: int, y: int) -> int:
		return (y - rect.position.y) * rect.size.x + (x - rect.position.x)


static func analyze(img: Image, box: Rect2i) -> MeasureWindow:
	var w := MeasureWindow.new()
	var full := Rect2i(0, 0, img.get_width(), img.get_height())
	w.rect = box.grow(MARGIN).intersection(full)
	var data: PackedByteArray = img.get_data()
	var iw: int = img.get_width()
	var n: int = w.rect.size.x * w.rect.size.y
	w.lum.resize(n)
	w.rgb.resize(n)
	var raw := PackedByteArray()
	raw.resize(n)
	var i: int = 0
	for y in range(w.rect.position.y, w.rect.end.y):
		for x in range(w.rect.position.x, w.rect.end.x):
			var o: int = (y * iw + x) * 4
			var r: float = float(data[o])
			var g: float = float(data[o + 1])
			var b: float = float(data[o + 2])
			var l: float = 0.2126 * r + 0.7152 * g + 0.0722 * b
			var mx: float = maxf(r, maxf(g, b))
			var mn: float = minf(r, minf(g, b))
			var s: float = (mx - mn) / mx if mx > 0.0 else 0.0
			w.lum[i] = l
			w.rgb[i] = Vector3(r, g, b)
			raw[i] = 1 if (s < 0.30 and l > 115.0 and not (g > r + 6.0 and g > b + 6.0)) else 0
			i += 1
	w.air = _erode(raw, w.rect, full)
	w.blur6 = _gauss(w.lum, w.rect.size.x, w.rect.size.y, 6.0)
	w.blur1 = _gauss(w.lum, w.rect.size.x, w.rect.size.y, 1.0)
	return w


## Mínimo 7 x 7 (separável). Fora da imagem conta como ar (a borda do quadro não erode o ar).
static func _erode(m: PackedByteArray, r: Rect2i, full: Rect2i) -> PackedByteArray:
	var w: int = r.size.x
	var h: int = r.size.y
	var half: int = ERODE / 2
	var tmp := PackedByteArray()
	tmp.resize(w * h)
	for y in h:
		for x in w:
			var v: int = 1
			for k in range(-half, half + 1):
				var xx: int = x + k
				if xx < 0 or xx >= w:
					# Fora da janela: só vale como ar se também está fora da imagem.
					if full.has_point(Vector2i(r.position.x + xx, r.position.y + y)):
						v = 0
						break
					continue
				if m[y * w + xx] == 0:
					v = 0
					break
			tmp[y * w + x] = v
	var out := PackedByteArray()
	out.resize(w * h)
	for y in h:
		for x in w:
			var v: int = 1
			for k in range(-half, half + 1):
				var yy: int = y + k
				if yy < 0 or yy >= h:
					if full.has_point(Vector2i(r.position.x + x, r.position.y + yy)):
						v = 0
						break
					continue
				if tmp[yy * w + x] == 0:
					v = 0
					break
			out[y * w + x] = v
	return out


static func _gauss(src: PackedFloat32Array, w: int, h: int, sigma: float) -> PackedFloat32Array:
	var radius: int = ceili(3.0 * sigma)
	var kernel := PackedFloat32Array()
	var total: float = 0.0
	for k in range(-radius, radius + 1):
		var v: float = exp(-float(k * k) / (2.0 * sigma * sigma))
		kernel.append(v)
		total += v
	for k in kernel.size():
		kernel[k] /= total
	var tmp := PackedFloat32Array()
	tmp.resize(w * h)
	for y in h:
		for x in w:
			var acc: float = 0.0
			for k in range(-radius, radius + 1):
				acc += src[y * w + clampi(x + k, 0, w - 1)] * kernel[k + radius]
			tmp[y * w + x] = acc
	var out := PackedFloat32Array()
	out.resize(w * h)
	for y in h:
		for x in w:
			var acc: float = 0.0
			for k in range(-radius, radius + 1):
				acc += tmp[clampi(y + k, 0, h - 1) * w + x] * kernel[k + radius]
			out[y * w + x] = acc
	return out


static func percentile(values: PackedFloat32Array, p: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted: PackedFloat32Array = values.duplicate()
	sorted.sort()
	var pos: float = p / 100.0 * float(sorted.size() - 1)
	var lo: int = floori(pos)
	var hi: int = mini(lo + 1, sorted.size() - 1)
	return lerpf(sorted[lo], sorted[hi], pos - float(lo))


static func pearson(a: PackedFloat32Array, b: PackedFloat32Array) -> float:
	var n: int = a.size()
	if n < 2:
		return 0.0
	var ma: float = 0.0
	var mb: float = 0.0
	for i in n:
		ma += a[i]
		mb += b[i]
	ma /= float(n)
	mb /= float(n)
	var sab: float = 0.0
	var saa: float = 0.0
	var sbb: float = 0.0
	for i in n:
		sab += (a[i] - ma) * (b[i] - mb)
		saa += (a[i] - ma) * (a[i] - ma)
		sbb += (b[i] - mb) * (b[i] - mb)
	var d: float = sqrt(saa * sbb)
	return sab / d if d > 0.0 else 0.0


static func dist(p: Color, q: Color) -> float:
	return Vector3(p.r - q.r, p.g - q.g, p.b - q.b).length() / sqrt(3.0)


static func to_color(v: Vector3) -> Color:
	return Color(v.x / 255.0, v.y / 255.0, v.z / 255.0)


static func hex(c: Color) -> String:
	return "#" + c.to_html(false).to_upper()


## Medidas de uma janela na caixa (só a imagem): dicionário com ar, percentis, cor, iluminado, gradiente e tons.
static func stats(w: MeasureWindow, box: Rect2i) -> Dictionary:
	var lums := PackedFloat32Array()
	var cols := PackedVector3Array()
	var grads := PackedFloat32Array()
	var lit: int = 0
	var cen := Vector2.ZERO
	var color_sum := Vector3.ZERO
	for y in range(box.position.y, box.end.y):
		for x in range(box.position.x, box.end.x):
			var i: int = w.idx(x, y)
			if w.air[i] == 0:
				continue
			var l: float = w.lum[i]
			lums.append(l)
			cols.append(w.rgb[i])
			color_sum += w.rgb[i]
			if l >= LIT_L:
				lit += 1
				cen += Vector2(x, y)
			var xl: int = clampi(x - 1, w.rect.position.x, w.rect.end.x - 1)
			var xr: int = clampi(x + 1, w.rect.position.x, w.rect.end.x - 1)
			var yu: int = clampi(y - 1, w.rect.position.y, w.rect.end.y - 1)
			var yd: int = clampi(y + 1, w.rect.position.y, w.rect.end.y - 1)
			var gx: float = (w.blur1[w.idx(xr, y)] - w.blur1[w.idx(xl, y)]) * 0.5
			var gy: float = (w.blur1[w.idx(x, yd)] - w.blur1[w.idx(x, yu)]) * 0.5
			grads.append(sqrt(gx * gx + gy * gy))
	var n: int = lums.size()
	var out: Dictionary = {"air": float(n) / float(box.size.x * box.size.y), "n": n}
	if n == 0:
		return out
	out["p10"] = percentile(lums, 10.0)
	out["p50"] = percentile(lums, 50.0)
	out["p90"] = percentile(lums, 90.0)
	out["color"] = to_color(color_sum / float(n))
	out["lit"] = float(lit) / float(n)
	out["centroid"] = cen / float(lit) if lit > 0 else Vector2(-1.0, -1.0)
	var gsum: float = 0.0
	for g: float in grads:
		gsum += g
	out["grad"] = gsum / float(n)
	out["grad95"] = percentile(grads, 95.0)
	var tones: Array[Color] = []
	for p: float in [5.0, 50.0, 95.0]:
		var lo: float = percentile(lums, maxf(p - 3.0, 0.0))
		var hi: float = percentile(lums, minf(p + 3.0, 100.0))
		var acc := Vector3.ZERO
		var k: int = 0
		for j in n:
			if lums[j] >= lo and lums[j] <= hi:
				acc += cols[j]
				k += 1
		tones.append(to_color(acc / float(maxi(k, 1))))
	out["tones"] = tones
	return out


## Medidas que comparam as duas imagens: estrutura, perfil, IoU do iluminado.
static func pair_stats(wc: MeasureWindow, wr: MeasureWindow, box: Rect2i) -> Dictionary:
	var a := PackedFloat32Array()
	var b := PackedFloat32Array()
	var inter: int = 0
	var union: int = 0
	for y in range(box.position.y, box.end.y):
		for x in range(box.position.x, box.end.x):
			var ic: int = wc.idx(x, y)
			var ir: int = wr.idx(x, y)
			var ac: bool = wc.air[ic] == 1
			var ar: bool = wr.air[ir] == 1
			if ac and ar:
				a.append(wc.blur6[ic])
				b.append(wr.blur6[ir])
			var lc: bool = ac and wc.lum[ic] >= LIT_L
			var lr: bool = ar and wr.lum[ir] >= LIT_L
			if lc and lr:
				inter += 1
			if lc or lr:
				union += 1
	var pc := PackedFloat32Array()
	var pr := PackedFloat32Array()
	var y0: int = box.position.y
	while y0 < box.end.y:
		var sc: float = 0.0
		var sr: float = 0.0
		var nc: int = 0
		var nr: int = 0
		for y in range(y0, mini(y0 + BAND, box.end.y)):
			for x in range(box.position.x, box.end.x):
				var ic: int = wc.idx(x, y)
				var ir: int = wr.idx(x, y)
				if wc.air[ic] == 1:
					sc += wc.lum[ic]
					nc += 1
				if wr.air[ir] == 1:
					sr += wr.lum[ir]
					nr += 1
		if nc >= BAND and nr >= BAND:
			pc.append(sc / float(nc))
			pr.append(sr / float(nr))
		y0 += BAND
	var mae: float = 0.0
	for i in pc.size():
		mae += absf(pc[i] - pr[i])
	return {"struct": pearson(a, b) if a.size() > 100 else 0.0, "struct_n": a.size(),
			"prof_r": pearson(pc, pr) if pc.size() >= 4 else 0.0, "prof_mae": mae / float(maxi(pc.size(), 1)), "bands": pc.size(),
			"iou": float(inter) / float(union) if union > 0 else (1.0 if inter == 0 else 0.0)}


static func _ok(v: bool) -> String:
	return "sim" if v else "NAO"


## Imprime a tabela por massa (captura, referência medida, alvo da spec, limite e ok) e o resumo das fases.
static func print_report(cap: Image, ref: Image) -> void:
	var f1_ok: bool = true
	var f2_ok: bool = true
	print("massa | medida | captura | referência (imagem) | alvo da spec | limite | ok")
	for m: Array in MASSES:
		var mass_name: String = m[0]
		var box: Rect2i = m[1]
		var cls: int = m[2]
		var wc: MeasureWindow = analyze(cap, box)
		var wr: MeasureWindow = analyze(ref, box)
		var sc: Dictionary = stats(wc, box)
		var sr: Dictionary = stats(wr, box)
		var ps: Dictionary = pair_stats(wc, wr, box)
		var k: int = mini(cls, 1)
		print("%s | ar erodido | %.0f%% | %.0f%% | - | - | -" % [mass_name, 100.0 * sc["air"], 100.0 * sr["air"]])
		if int(sc["n"]) == 0:
			print("%s | sem ar na captura | - | - | - | - | NAO" % mass_name)
			f1_ok = false
			f2_ok = false
			continue
		if cls == 2:
			# M8: sombra da ilha (Fase 2): cor média, P50 e P90 - P10.
			var d8: float = dist(sc["color"], Color(str(m[6])))
			var spread: float = float(sc["p90"]) - float(sc["p10"])
			print("%s | L P10/P50/P90 | %.0f/%.0f/%.0f | %.0f/%.0f/%.0f | %.0f/%.0f/%.0f | P50 <= 160, P90-P10 <= 30 | %s" % [mass_name,
					sc["p10"], sc["p50"], sc["p90"], sr["p10"], sr["p50"], sr["p90"], m[3], m[4], m[5],
					_ok(float(sc["p50"]) <= 160.0 and spread <= 30.0)])
			print("%s | cor média do ar | %s | %s | %s | <= 8%% | %s (%.1f%%)" % [mass_name, hex(sc["color"]), hex(sr["color"]), m[6],
					_ok(d8 <= 0.08), 100.0 * d8])
			print("%s | iluminado | %.0f%% | %.0f%% | 0%% | - | -" % [mass_name, 100.0 * sc["lit"], 100.0 * sr["lit"]])
			f2_ok = f2_ok and d8 <= 0.08 and float(sc["p50"]) <= 160.0 and spread <= 30.0
			continue
		var cdist: float = -1.0
		var cr: Vector2 = sr["centroid"]
		var cc: Vector2 = sc["centroid"]
		if cr.x >= 0.0 and cc.x >= 0.0:
			cdist = cc.distance_to(cr)
		var struct_ok: bool = float(ps["struct"]) >= LIM_STRUCT[k]
		var prof_ok: bool = int(ps["bands"]) >= 4 and float(ps["prof_r"]) >= LIM_PROF_R[k] and float(ps["prof_mae"]) <= LIM_PROF_MAE[k]
		var iou_ok: bool = float(ps["iou"]) >= LIM_IOU[k]
		var cen_ok: bool = cdist >= 0.0 and cdist <= LIM_CENTROID[k]
		print("%s | estrutura r | %.2f | 1 | - | >= %.2f | %s" % [mass_name, ps["struct"], LIM_STRUCT[k], _ok(struct_ok)])
		print("%s | perfil r / MAE (%d faixas) | %.2f / %.1f | 1 / 0 | - | >= %.2f / <= %.0f | %s" % [mass_name, ps["bands"],
				ps["prof_r"], ps["prof_mae"], LIM_PROF_R[k], LIM_PROF_MAE[k], _ok(prof_ok)])
		print("%s | IoU do iluminado | %.2f | 1 | - | >= %.2f | %s" % [mass_name, ps["iou"], LIM_IOU[k], _ok(iou_ok)])
		print("%s | centróide do iluminado | (%.0f, %.0f) | (%.0f, %.0f) | - | <= %.0f px | %s (%.0f px)" % [mass_name, cc.x, cc.y,
				cr.x, cr.y, LIM_CENTROID[k], _ok(cen_ok), cdist])
		f1_ok = f1_ok and struct_ok and prof_ok and iou_ok and cen_ok
		var l_ok: bool = absf(float(sc["p10"]) - float(m[3])) <= LIM_L[k] and absf(float(sc["p50"]) - float(m[4])) <= LIM_L[k] \
				and absf(float(sc["p90"]) - float(m[5])) <= LIM_L[k]
		print("%s | L P10/P50/P90 | %.0f/%.0f/%.0f | %.0f/%.0f/%.0f | %.0f/%.0f/%.0f | +-%.0f | %s" % [mass_name, sc["p10"], sc["p50"],
				sc["p90"], sr["p10"], sr["p50"], sr["p90"], m[3], m[4], m[5], LIM_L[k], _ok(l_ok)])
		var frac_ok: bool = absf(float(sc["lit"]) - float(m[7])) <= LIM_FRAC[k]
		print("%s | fração iluminada | %.0f%% | %.0f%% | %.0f%% | +-%.0f pontos | %s" % [mass_name, 100.0 * sc["lit"], 100.0 * sr["lit"],
				100.0 * float(m[7]), 100.0 * LIM_FRAC[k], _ok(frac_ok)])
		var dcol: float = dist(sc["color"], Color(str(m[6])))
		var col_ok: bool = dcol <= LIM_COLOR[k]
		print("%s | cor média do ar | %s | %s | %s | <= %.0f%% | %s (%.1f%%)" % [mass_name, hex(sc["color"]), hex(sr["color"]), m[6],
				100.0 * LIM_COLOR[k], _ok(col_ok), 100.0 * dcol])
		var tones_ok: bool = true
		var tone_text: PackedStringArray = []
		var ref_tone_text: PackedStringArray = []
		var tc: Array = sc["tones"]
		var tr: Array = sr["tones"]
		var targets: Array = TONES[mass_name]
		var target_text: PackedStringArray = []
		for t in 3:
			tone_text.append(hex(tc[t]))
			ref_tone_text.append(hex(tr[t]))
			target_text.append(str(targets[t]) if str(targets[t]) != "" else "-")
			if str(targets[t]) != "":
				var dt: float = dist(tc[t], Color(str(targets[t])))
				tone_text[t] += " (%.1f%%)" % (100.0 * dt)
				tones_ok = tones_ok and dt <= LIM_TONE[k]
		print("%s | tons P5/P50/P95 | %s | %s | %s | <= %.0f%% | %s" % [mass_name, " ".join(tone_text), " ".join(ref_tone_text),
				" ".join(target_text), 100.0 * LIM_TONE[k], _ok(tones_ok)])
		var ratio: float = float(sc["grad"]) / maxf(float(sr["grad"]), 0.001)
		var g_ok: bool = ratio >= LIM_GRAD_LO[k] and ratio <= LIM_GRAD_HI[k] and float(sc["grad95"]) <= LIM_GRAD_HI[k] * float(sr["grad95"])
		print("%s | gradiente médio / P95 | %.2f / %.1f | %.2f / %.1f | razão %.2f | %.2f a %.2f, P95 <= %.2f x ref | %s" % [mass_name,
				sc["grad"], sc["grad95"], sr["grad"], sr["grad95"], ratio, LIM_GRAD_LO[k], LIM_GRAD_HI[k], LIM_GRAD_HI[k], _ok(g_ok)])
		f2_ok = f2_ok and l_ok and frac_ok and col_ok and tones_ok and g_ok
	print("RESUMO Fase 1 (estrutura, perfil, IoU e centróide em M1-M7): %s" % ("PASSA" if f1_ok else "NAO PASSA"))
	print("RESUMO Fase 2 (tabela inteira e M8): %s" % ("PASSA" if f1_ok and f2_ok else "NAO PASSA"))


## Comparação da 013: em cima referência | captura; embaixo recortes 2x (referência | captura) de M3, M6, M7 e M5, M4.
static func comparison_image(cap: Image, ref: Image) -> Image:
	var gap: int = 8
	var rows: Array = [["M3", "M6", "M7"], ["M5", "M4"]]
	var boxes: Dictionary = {}
	for m: Array in MASSES:
		boxes[m[0]] = m[1]
	var width: int = cap.get_width() * 2 + gap
	var height: int = cap.get_height() + gap
	for row: Array in rows:
		var hmax: int = 0
		for key: String in row:
			hmax = maxi(hmax, (boxes[key] as Rect2i).size.y * 2)
		height += hmax + gap
	var out := Image.create(width, height, false, Image.FORMAT_RGBA8)
	out.fill(Color(0.09, 0.09, 0.1))
	out.blit_rect(ref, Rect2i(Vector2i.ZERO, ref.get_size()), Vector2i(0, 0))
	out.blit_rect(cap, Rect2i(Vector2i.ZERO, cap.get_size()), Vector2i(cap.get_width() + gap, 0))
	var y: int = cap.get_height() + gap
	for row: Array in rows:
		var x: int = 0
		var hmax: int = 0
		for key: String in row:
			var box: Rect2i = boxes[key]
			for src: Image in [ref, cap]:
				var crop: Image = src.get_region(box)
				crop.resize(box.size.x * 2, box.size.y * 2, Image.INTERPOLATE_LANCZOS)
				out.blit_rect(crop, Rect2i(Vector2i.ZERO, crop.get_size()), Vector2i(x, y))
				x += crop.get_width() + 2
			x += gap * 2
			hmax = maxi(hmax, box.size.y * 2)
		y += hmax + gap
	return out


## Diferença média de L entre duas capturas em cada caixa (determinismo); true se todas <= 0,5.
static func print_determinism(a: Image, b: Image) -> bool:
	var ok: bool = true
	var da: PackedByteArray = a.get_data()
	var db: PackedByteArray = b.get_data()
	var w: int = a.get_width()
	for m: Array in MASSES:
		var box: Rect2i = m[1]
		var acc: float = 0.0
		for y in range(box.position.y, box.end.y):
			for x in range(box.position.x, box.end.x):
				var o: int = (y * w + x) * 4
				var la: float = 0.2126 * da[o] + 0.7152 * da[o + 1] + 0.0722 * da[o + 2]
				var lb: float = 0.2126 * db[o] + 0.7152 * db[o + 1] + 0.0722 * db[o + 2]
				acc += absf(la - lb)
		var mean: float = acc / float(box.size.x * box.size.y)
		ok = ok and mean <= 0.5
		print("%s | diferença média de L | %.3f | <= 0,5 | %s" % [m[0], mean, _ok(mean <= 0.5)])
	return ok


## Vistas giradas (sem referência): ar erodido da metade de cima do quadro. P10 <= 185 e P90 >= 220 (volume com luz e
## sombra), S média de 0,06 a 0,20 e o tom P50 (cor média a +-3 percentis do P50) a <= 10% de #D6C4C5.
static func print_turn(img: Image) -> bool:
	var box := Rect2i(0, 0, img.get_width(), img.get_height() / 2)
	var w: MeasureWindow = analyze(img, box)
	var lums := PackedFloat32Array()
	var cols := PackedVector3Array()
	var s_sum: float = 0.0
	for y in range(box.position.y, box.end.y):
		for x in range(box.position.x, box.end.x):
			var i: int = w.idx(x, y)
			if w.air[i] == 0:
				continue
			var c: Vector3 = w.rgb[i]
			var mx: float = maxf(c.x, maxf(c.y, c.z))
			s_sum += (mx - minf(c.x, minf(c.y, c.z))) / maxf(mx, 1.0)
			lums.append(w.lum[i])
			cols.append(c)
	var n: int = lums.size()
	if n == 0:
		print("giro | sem ar na metade de cima | NAO")
		return false
	var p10: float = percentile(lums, 10.0)
	var p90: float = percentile(lums, 90.0)
	var s_mean: float = s_sum / float(n)
	var lo: float = percentile(lums, 47.0)
	var hi: float = percentile(lums, 53.0)
	var acc := Vector3.ZERO
	var k: int = 0
	for j in n:
		if lums[j] >= lo and lums[j] <= hi:
			acc += cols[j]
			k += 1
	var tone: Color = to_color(acc / float(maxi(k, 1)))
	var d: float = dist(tone, Color("#D6C4C5"))
	var ok_l: bool = p10 <= 185.0 and p90 >= 220.0
	var ok_s: bool = s_mean >= 0.06 and s_mean <= 0.20
	var ok_t: bool = d <= 0.10
	print("giro | ar erodido na metade de cima | %.0f%%" % (100.0 * float(n) / float(box.size.x * box.size.y)))
	print("giro | L P10 / P90 | %.0f / %.0f | P10 <= 185, P90 >= 220 | %s" % [p10, p90, _ok(ok_l)])
	print("giro | S média do ar | %.3f | 0,06 a 0,20 | %s" % [s_mean, _ok(ok_s)])
	print("giro | tom P50 | %s | #D6C4C5 <= 10%% | %s (%.1f%%)" % [hex(tone), _ok(ok_t), 100.0 * d])
	return ok_l and ok_s and ok_t
