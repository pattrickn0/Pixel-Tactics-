extends SceneTree
## Prévia de peças do kit numa cena de luz simples (ferramenta de desenvolvimento, não entra no jogo).
## Precisa de janela (xvfb-run, sem --headless):
##   xvfb-run -a -s "-screen 0 1280x720x24" "$G" --path . --resolution 1280x720 --script tools/dev/preview_kit.gd -- \
##     --pieces="wall_high_corner@0,0,0;wall_high_2@1.5,0,0" --cam=3,2.5,4 --look=0,0.7,0 --out=/caminho/saida.png
## --pieces = nome@x,y,z,yaw separados por ";" (yaw opcional, em graus). --fov (padrão 40).

const KIT_DIR: String = "res://scenes/kit/"


func _initialize() -> void:
	@warning_ignore("missing_await")
	_run()


func _arg(args: Dictionary, key: String, fallback: String) -> String:
	return str(args.get(key, fallback))


func _vec(text: String) -> Vector3:
	var parts: PackedStringArray = text.split(",")
	return Vector3(float(parts[0]), float(parts[1]), float(parts[2]))


func _run() -> void:
	var args: Dictionary = {}
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--") and arg.contains("="):
			var eq: int = arg.find("=")
			args[arg.substr(2, eq - 2)] = arg.substr(eq + 1)
	var world := Node3D.new()
	root.add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.7, 0.85)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.66, 0.6)
	env.ambient_light_energy = 0.8
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
	sun.shadow_enabled = true
	world.add_child(sun)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(60.0, 60.0)
	floor_mesh.mesh = plane
	floor_mesh.position = Vector3(0.0, -0.001, 0.0)
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.36, 0.6, 0.28)
	floor_mesh.material_override = floor_mat
	world.add_child(floor_mesh)
	for item: String in _arg(args, "pieces", "").split(";", false):
		var parts: PackedStringArray = item.split("@")
		var coords: PackedStringArray = parts[1].split(",")
		var scene := load(KIT_DIR + parts[0] + ".tscn") as PackedScene
		var node := scene.instantiate() as Node3D
		node.position = Vector3(float(coords[0]), float(coords[1]), float(coords[2]))
		if coords.size() > 3:
			node.rotation_degrees = Vector3(0.0, float(coords[3]), 0.0)
		world.add_child(node)
	var cam := Camera3D.new()
	cam.fov = float(_arg(args, "fov", "40"))
	world.add_child(cam)
	cam.look_at_from_position(_vec(_arg(args, "cam", "4,3,5")), _vec(_arg(args, "look", "0,0.5,0")))
	for _i in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_viewport().get_texture().get_image()
	image.save_png(_arg(args, "out", "res://preview.png"))
	print("Prévia salva: ", _arg(args, "out", ""))
	quit(0)
