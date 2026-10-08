extends SceneTree
## Monta a imagem de comparação: duas imagens lado a lado, na mesma altura (por padrão a captura --a à
## esquerda e a referência --b à direita; com --ref-first a referência vai à esquerda, ampliada para o
## tamanho da captura). Com --blend=arquivo.png grava também as duas misturadas a 50% no tamanho da captura.
##   "$G" --headless --path . --script tools/dev/compare_images.gd -- --a=captura.png --b=referencia.webp --out=saida.png [--ref-first] [--blend=mistura.png]
## Caixas de cor (spec 012, Fase 2): com --boxes, imprime a cor média de cada caixa da captura --a
## (1280x720, sem HUD), a cor da referência ampliada (--b) e a distância RGB normalizada até o alvo da
## spec, mais o desvio-padrão da luminância dos pixels de terra da arena. --out é opcional com --boxes.
##   "$G" --headless --path . --script tools/dev/compare_images.gd -- --a=captura.png --b=docs/reference/ilha-flutuante.webp --boxes

## Caixas da spec 012 (x0, y0, x1, y1 em 1280x720), alvo e limite (fração). Fase 3 = só informativas.
const BOXES: Array = [
	["terra da arena", Rect2i(560, 400, 80, 40), "#B3843D", 0.08],
	["grama da arena oeste", Rect2i(400, 330, 80, 70), "#7F8033", 0.08],
	["grama da arena frente", Rect2i(420, 450, 180, 50), "#717B22", 0.08],
	["mata noroeste", Rect2i(170, 250, 130, 130), "#58572B", 0.08],
	["coniferas leste", Rect2i(1000, 250, 100, 150), "#384F21", 0.08],
	["folhosas nordeste", Rect2i(800, 150, 140, 80), "#616F58", 0.08],
	["face externa do muro sul", Rect2i(300, 555, 260, 20), "#2A3C27", 0.08],
	["penhasco da frente", Rect2i(400, 650, 160, 60), "#38302A", 0.08],
	["cascata (lamina do meio)", Rect2i(620, 80, 70, 100), "#BCCEDC", 0.15],
	["faixa sul", Rect2i(250, 590, 170, 40), "#2C3F1E", 0.12],
	["(F3) ceu alto direita", Rect2i(870, 0, 90, 30), "#B4BAD9", 0.08],
	["(F3) ceu alto esquerda", Rect2i(130, 0, 100, 30), "#E2D1C1", 0.08],
	["(F3) nuvem esquerda", Rect2i(40, 320, 100, 60), "#D9C7C2", 0.08],
	["(F3) nuvem embaixo esquerda", Rect2i(30, 560, 120, 140), "#938B8C", 0.08],
	["(F3) nuvem direita", Rect2i(1190, 330, 80, 90), "#B9B3BA", 0.08],
]
## Caixa da variação da terra (pixels de terra: vermelho > verde e vermelho > azul) e o mínimo de desvio.
const DIRT_BOX: Rect2i = Rect2i(480, 330, 320, 140)
const DIRT_MIN_STD: float = 22.0


func _initialize() -> void:
	var args: Dictionary = {}
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--"):
			var eq: int = arg.find("=")
			if eq < 0:
				args[arg.substr(2)] = ""
			else:
				args[arg.substr(2, eq - 2)] = arg.substr(eq + 1)
	var a := Image.load_from_file(str(args["a"]))
	var b := Image.load_from_file(str(args["b"]))
	if a == null or b == null or a.is_empty() or b.is_empty():
		push_error("Não abriu as imagens")
		quit(1)
		return
	a.convert(Image.FORMAT_RGBA8)
	b.convert(Image.FORMAT_RGBA8)
	if args.has("boxes"):
		var ref := b.duplicate() as Image
		ref.resize(a.get_width(), a.get_height(), Image.INTERPOLATE_LANCZOS)
		_print_boxes(a, ref)
		if not args.has("out"):
			quit(0)
			return
	var ref_first: bool = args.has("ref-first")
	var height: int = a.get_height()
	var b_width: int = roundi(float(b.get_width()) * float(height) / float(b.get_height()))
	if ref_first:
		# A referência ocupa o mesmo quadro da captura (a 906x509 é 16:9, como a captura 1280x720).
		b_width = a.get_width()
	b.resize(b_width, height, Image.INTERPOLATE_LANCZOS)
	var out := Image.create(a.get_width() + b_width + 8, height, false, Image.FORMAT_RGBA8)
	out.fill(Color.WHITE)
	var left: Image = b if ref_first else a
	var right: Image = a if ref_first else b
	out.blit_rect(left, Rect2i(0, 0, left.get_width(), height), Vector2i(0, 0))
	out.blit_rect(right, Rect2i(0, 0, right.get_width(), height), Vector2i(left.get_width() + 8, 0))
	var err: Error = out.save_png(str(args["out"]))
	if args.has("blend") and err == OK:
		var ref := b.duplicate() as Image
		ref.resize(a.get_width(), a.get_height(), Image.INTERPOLATE_LANCZOS)
		var mix := Image.create(a.get_width(), a.get_height(), false, Image.FORMAT_RGBA8)
		for y in a.get_height():
			for x in a.get_width():
				mix.set_pixel(x, y, a.get_pixel(x, y).lerp(ref.get_pixel(x, y), 0.5))
		err = mix.save_png(str(args["blend"]))
	quit(0 if err == OK else 1)


static func _mean(img: Image, r: Rect2i) -> Color:
	var sum := Vector3.ZERO
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var c: Color = img.get_pixel(x, y)
			sum += Vector3(c.r, c.g, c.b)
	sum /= float(r.size.x * r.size.y)
	return Color(sum.x, sum.y, sum.z)


## Distância RGB normalizada (0 a 1): euclidiana / (raiz de 3).
static func _dist(p: Color, q: Color) -> float:
	return Vector3(p.r - q.r, p.g - q.g, p.b - q.b).length() / sqrt(3.0)


## Desvio-padrão da luminância (0 a 255) dos pixels de terra da caixa; devolve [desvio, fração de terra].
static func _dirt_std(img: Image, r: Rect2i) -> Vector2:
	var values: PackedFloat32Array = PackedFloat32Array()
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var c: Color = img.get_pixel(x, y)
			if c.r > c.g and c.r > c.b:
				values.append(255.0 * (0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b))
	if values.is_empty():
		return Vector2.ZERO
	var mean: float = 0.0
	for v: float in values:
		mean += v
	mean /= float(values.size())
	var acc: float = 0.0
	for v: float in values:
		acc += (v - mean) * (v - mean)
	return Vector2(sqrt(acc / float(values.size())), float(values.size()) / float(r.size.x * r.size.y))


func _print_boxes(cap: Image, ref: Image) -> void:
	print("caixa | captura | referência | alvo | distância | limite | ok")
	for box: Array in BOXES:
		var r: Rect2i = box[1]
		var target := Color(str(box[2]))
		var mc: Color = _mean(cap, r)
		var mr: Color = _mean(ref, r)
		var d: float = _dist(mc, target)
		print("%s | #%s | #%s | %s | %.1f%% | %.0f%% | %s" % [box[0], mc.to_html(false).to_upper(), mr.to_html(false).to_upper(),
				box[2], 100.0 * d, 100.0 * float(box[3]), "sim" if d <= float(box[3]) else "NAO"])
	var sc: Vector2 = _dirt_std(cap, DIRT_BOX)
	var sr: Vector2 = _dirt_std(ref, DIRT_BOX)
	print("desvio de luminância da terra (480,330,800,470): captura %.1f (%.0f%% de terra), referência %.1f (%.0f%%), mínimo %.0f -> %s" % [
			sc.x, 100.0 * sc.y, sr.x, 100.0 * sr.y, DIRT_MIN_STD, "sim" if sc.x >= DIRT_MIN_STD else "NAO"])
