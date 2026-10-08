extends SceneTree
## Monta a imagem de comparação: captura à esquerda e referência à direita, na mesma altura.
##   "$G" --headless --path . --script tools/dev/compare_images.gd -- --a=captura.png --b=referencia.jpg --out=saida.png


func _initialize() -> void:
	var args: Dictionary = {}
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--") and arg.contains("="):
			var eq: int = arg.find("=")
			args[arg.substr(2, eq - 2)] = arg.substr(eq + 1)
	var a := Image.load_from_file(str(args["a"]))
	var b := Image.load_from_file(str(args["b"]))
	if a == null or b == null:
		push_error("Não abriu as imagens")
		quit(1)
		return
	var height: int = a.get_height()
	var b_width: int = roundi(float(b.get_width()) * float(height) / float(b.get_height()))
	b.resize(b_width, height, Image.INTERPOLATE_LANCZOS)
	a.convert(Image.FORMAT_RGBA8)
	b.convert(Image.FORMAT_RGBA8)
	var out := Image.create(a.get_width() + b_width + 8, height, false, Image.FORMAT_RGBA8)
	out.fill(Color.WHITE)
	out.blit_rect(a, Rect2i(0, 0, a.get_width(), height), Vector2i(0, 0))
	out.blit_rect(b, Rect2i(0, 0, b_width, height), Vector2i(a.get_width() + 8, 0))
	var err: Error = out.save_png(str(args["out"]))
	quit(0 if err == OK else 1)
