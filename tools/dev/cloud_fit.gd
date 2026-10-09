extends SceneTree
## Ajuste das nuvens (spec 013, ferramenta opcional): projeta os lóbulos da tabela CloudTables com a câmera padrão
## (posição (0; 24,52; 43,81), mira (0, 0, -4,3), FOV vertical 37°, 1280x720) e imprime, por lóbulo, o centro na
## tela, o raio em px e o topo. Com --out, grava a referência com os contornos dos lóbulos por cima (uma cor por
## massa), para acertar a silhueta antes da captura.
##   "$G" --headless --path . --script tools/dev/cloud_fit.gd -- [--mass=M6] [--out=fit.png]

const REF_PATH: String = "res://docs/reference/ilha-flutuante.webp"
const CAM_POS: Vector3 = Vector3(0.0, 24.52, 43.81)
const CAM_TARGET: Vector3 = Vector3(0.0, 0.0, -4.3)
const FOV_DEG: float = 37.0
const SIZE: Vector2i = Vector2i(1280, 720)
const COLORS: Array[Color] = [Color.RED, Color.YELLOW, Color.CYAN, Color.MAGENTA, Color.ORANGE, Color.LIME, Color.DODGER_BLUE,
		Color.WHITE]


func _initialize() -> void:
	var args: Dictionary = {}
	for a: String in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	var view := Transform3D.IDENTITY.looking_at(CAM_TARGET - CAM_POS, Vector3.UP)
	view.origin = CAM_POS
	var inv: Transform3D = view.affine_inverse()
	var focal: float = float(SIZE.y) * 0.5 / tan(deg_to_rad(FOV_DEG * 0.5))
	var img: Image = null
	if args.has("out"):
		img = Image.load_from_file(ProjectSettings.globalize_path(REF_PATH))
		img.convert(Image.FORMAT_RGBA8)
		img.resize(SIZE.x, SIZE.y, Image.INTERPOLATE_LANCZOS)
	var k: int = 0
	for mass: Dictionary in CloudTables.MASSES:
		var mass_name: String = str(mass["name"])
		if args.has("mass") and not mass_name.begins_with(str(args["mass"])):
			continue
		var pos: Vector3 = mass["pos"]
		var color: Color = COLORS[k % COLORS.size()]
		k += 1
		print("%s (cor %s)" % [mass_name, color.to_html(false)])
		var i: int = 0
		for l: Array in mass.get("lobes", []):
			var ax := Vector3(float(l[4]), float(l[5]), float(l[6]))
			var r: float = float(l[3])
			var c: Vector3 = pos + Vector3(float(l[0]), float(l[1]), float(l[2]))
			var v: Vector3 = inv * c
			var depth: float = -v.z
			if depth <= 0.1:
				i += 1
				continue
			var sx: float = SIZE.x * 0.5 + v.x / depth * focal
			var sy: float = SIZE.y * 0.5 - v.y / depth * focal
			var rx: float = r * ax.x / depth * focal
			var ry: float = r * ax.y / depth * focal
			print("  %2d centro (%4.0f, %4.0f) raio %3.0f x %3.0f px, topo y %4.0f, prof %.0f" % [i, sx, sy, rx, ry, sy - ry, depth])
			if img != null:
				_ellipse(img, Vector2(sx, sy), Vector2(rx, ry), color)
			i += 1
	if img != null:
		img.save_png(str(args["out"]))
	quit(0)


static func _ellipse(img: Image, c: Vector2, r: Vector2, color: Color) -> void:
	var steps: int = maxi(24, int((r.x + r.y) * 2.0))
	for s in steps:
		var a: float = TAU * float(s) / float(steps)
		var p := Vector2i(int(c.x + cos(a) * r.x), int(c.y + sin(a) * r.y))
		if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height():
			img.set_pixelv(p, color)
