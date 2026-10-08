extends SceneTree
## Monta a imagem de comparação: duas imagens lado a lado, na mesma altura (por padrão a captura --a à
## esquerda e a referência --b à direita; com --ref-first a referência vai à esquerda, ampliada para o
## tamanho da captura). Com --blend=arquivo.png grava também as duas misturadas a 50% no tamanho da captura.
##   "$G" --headless --path . --script tools/dev/compare_images.gd -- --a=captura.png --b=referencia.webp --out=saida.png [--ref-first] [--blend=mistura.png]


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
