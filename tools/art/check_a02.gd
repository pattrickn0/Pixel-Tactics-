extends SceneTree
## Validação automática da spec A02 (docs/specs/A02-arte-octopath.md).
## Lê os 54 PNGs do disco e verifica conformidade completa com a direção de arte.
## Rodar da raiz do projeto:
##   "$G" --headless --path . --script tools/art/check_a02.gd

const P = preload("res://tools/art/palette_a02.gd")

const TEX_DIR: String = "res://assets/textures/"
const CARDS_DIR: String = "res://assets/textures/cards/"

# Textura opaca -> [min_tons, max_tons, is_top_view]
const TEXTURES: Dictionary = {
	"grass_arena_0": [6, 10, true], "grass_arena_1": [6, 10, true],
	"grass_arena_2": [6, 10, true], "grass_arena_3": [6, 12, true],
	"grass_forest_0": [6, 12, true], "grass_forest_1": [6, 12, true],
	"dirt_0": [6, 12, true], "dirt_1": [6, 12, true],
	"ruin_tile": [7, 14, true], "step_side": [7, 14, false],
	"step_side_grass": [8, 16, false], "wall_face": [7, 14, false],
	"wall_top": [7, 14, true], "rock": [6, 12, true],
	"bark_0": [5, 10, false], "bark_1": [5, 9, false],
	"leaves_mass": [5, 8, true], "monolith_stone": [6, 12, false],
}

# Cartão -> [largura, altura, min_tons, max_tons]
const CARDS: Dictionary = {
	"leaf_0": [32, 32, 6, 10], "leaf_1": [32, 32, 6, 10],
	"leaf_2": [32, 32, 6, 10], "leaf_3": [32, 32, 6, 10],
	"leaf_flower_0": [32, 32, 8, 14],
	"conifer_tier_0": [32, 32, 5, 8], "conifer_tier_1": [32, 32, 5, 8],
	"grass_fringe_0": [32, 16, 6, 10], "grass_fringe_1": [32, 16, 6, 10],
	"grass_tuft_0": [16, 16, 5, 9], "grass_tuft_1": [16, 16, 5, 9],
	"grass_tuft_2": [16, 16, 5, 9],
	"flower_0": [16, 16, 6, 12], "flower_1": [16, 16, 6, 12],
	"flower_2": [16, 16, 6, 12],
	"rune_0": [16, 16, 3, 4], "rune_1": [16, 16, 3, 4],
	"rune_2": [16, 16, 3, 4],
}

var _palette_lookup: Dictionary = {}
var _problems: int = 0


func _initialize() -> void:
	for i: int in P.count():
		_palette_lookup[P.rgb(i)] = i

	var textures_img: Dictionary = {}
	var normals_img: Dictionary = {}
	var cards_img: Dictionary = {}

	print("--- CHECANDO TEXTURAS OPACAS E NORMAL MAPS ---")
	for key: String in TEXTURES:
		var tex_path: String = TEX_DIR + key + ".png"
		var norm_path: String = TEX_DIR + key + "_n.png"
		var t_img: Image = _load(tex_path)
		var n_img: Image = _load(norm_path)
		if t_img == null:
			_fail(key, "Arquivo %s não existe" % tex_path)
			continue
		if n_img == null:
			_fail(key + "_n", "Arquivo %s não existe" % norm_path)
			continue
		textures_img[key] = t_img
		normals_img[key] = n_img
		_check_opaque_texture(key, t_img, n_img, TEXTURES[key])

	print("--- CHECANDO CARTÕES COM ALFA RECORTADO ---")
	for key: String in CARDS:
		var card_path: String = CARDS_DIR + key + ".png"
		var c_img: Image = _load(card_path)
		if c_img == null:
			_fail(key, "Arquivo %s não existe" % card_path)
			continue
		cards_img[key] = c_img
		_check_card(key, c_img, CARDS[key])

	print("--- CHECANDO FAMÍLIAS E LATERAIS ---")
	_check_families(textures_img, normals_img)
	_check_laterals(textures_img)

	if _problems == 0:
		print("========================================")
		print("A02 CHECK: PASS (Todos os 54 PNGs 100% aprovados)")
		print("========================================")
		quit(0)
	else:
		print("========================================")
		print("A02 CHECK: FAIL (%d problemas encontrados)" % _problems)
		print("========================================")
		quit(1)


func _load(path: String) -> Image:
	var abs_path: String = ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(abs_path):
		return null
	return Image.load_from_file(abs_path)


func _fail(key: String, reason: String) -> void:
	_problems += 1
	print("FAIL  %-20s | %s" % [key, reason])


func _ok(key: String, info: String) -> void:
	print("OK    %-20s | %s" % [key, info])


func _luma(c: Color) -> float:
	return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b


func _check_opaque_texture(key: String, t_img: Image, n_img: Image, spec: Array) -> void:
	var errs: Array[String] = []
	if t_img.get_width() != 32 or t_img.get_height() != 32:
		errs.append("Tamanho do albedo != 32x32 (%dx%d)" % [t_img.get_width(), t_img.get_height()])
	if n_img.get_width() != 32 or n_img.get_height() != 32:
		errs.append("Tamanho do normal != 32x32 (%dx%d)" % [n_img.get_width(), n_img.get_height()])

	# Paleta e contagem de tons distintos
	var colors: Dictionary = {}
	var orphans: int = 0
	var sum_y_left: float = 0.0
	var sum_y_right: float = 0.0
	var sum_y_top: float = 0.0
	var sum_y_bot: float = 0.0

	var sum_luma: float = 0.0
	var sum_nx: float = 0.0
	var sum_ny: float = 0.0
	var sum_nz: float = 0.0
	var sum_luma_sq: float = 0.0
	var sum_nx_sq: float = 0.0
	var sum_luma_nx: float = 0.0
	var low_z_count: int = 0

	var w: int = 32
	var h: int = 32

	for y: int in h:
		for x: int in w:
			var tc: Color = t_img.get_pixel(x, y)
			var nc: Color = n_img.get_pixel(x, y)

			if roundi(tc.a * 255.0) != 255:
				errs.append("Albedo com alfa != 255 em (%d,%d)" % [x, y])
			if roundi(nc.a * 255.0) != 255:
				errs.append("Normal com alfa != 255 em (%d,%d)" % [x, y])

			var rgb: int = (roundi(tc.r * 255.0) << 16) | (roundi(tc.g * 255.0) << 8) | roundi(tc.b * 255.0)
			if not _palette_lookup.has(rgb):
				errs.append("Cor fora da paleta em (%d,%d): #%06X" % [x, y, rgb])
			colors[rgb] = true

			var yv: float = _luma(tc)
			if x < 16:
				sum_y_left += yv
			else:
				sum_y_right += yv
			if y < 16:
				sum_y_top += yv
			else:
				sum_y_bot += yv

			# Órfãos (nenhum dos 8 vizinhos com wrap tem a mesma cor)
			var has_same_neighbor: bool = false
			for dy: int in range(-1, 2):
				for dx: int in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					var ntc: Color = t_img.get_pixel(posmod(x + dx, w), posmod(y + dy, h))
					var nrgb: int = (roundi(ntc.r * 255.0) << 16) | (roundi(ntc.g * 255.0) << 8) | roundi(ntc.b * 255.0)
					if nrgb == rgb:
						has_same_neighbor = true
						break
				if has_same_neighbor:
					break
			if not has_same_neighbor:
				orphans += 1

			# Normal map vector
			var vx: float = (nc.r * 2.0 - 1.0)
			var vy: float = (nc.g * 2.0 - 1.0)
			var vz: float = (nc.b * 2.0 - 1.0)
			var vlen: float = sqrt(vx * vx + vy * vy + vz * vz)
			if absf(vlen - 1.0) > 0.08:
				errs.append("Vetor normal com comprimento fora de 1±0.06 em (%d,%d): %.2f" % [x, y, vlen])
			if vz < 0.38:
				errs.append("Normal Z < 0.4 em (%d,%d): %.2f" % [x, y, vz])
			if vz < 0.97:
				low_z_count += 1

			sum_luma += yv
			sum_luma_sq += yv * yv
			sum_nx += vx
			sum_ny += vy
			sum_nz += vz
			sum_nx_sq += vx * vx
			sum_luma_nx += yv * vx

	# Validação de tons
	var distinct_tones: int = colors.size()
	var min_t: int = spec[0]
	var max_t: int = spec[1]
	if distinct_tones < min_t or distinct_tones > max_t:
		errs.append("Tons distintos fora da faixa [%d, %d]: %d" % [min_t, max_t, distinct_tones])

	# Órfãos <= 8% (81 de 1024)
	var orphan_pct: float = float(orphans) / 1024.0
	if orphan_pct > 0.08:
		errs.append("Órfãos acima de 8%%: %.1f%% (%d)" % [orphan_pct * 100.0, orphans])

	# Gradiente global
	var mean_yl: float = sum_y_left / 512.0
	var mean_yr: float = sum_y_right / 512.0
	if absf(mean_yl - mean_yr) > 0.05:
		errs.append("Gradiente horizontal E/D > 0.05: %.3f" % absf(mean_yl - mean_yr))

	var is_top_view: bool = spec[2]
	if is_top_view:
		var mean_yt: float = sum_y_top / 512.0
		var mean_yb: float = sum_y_bot / 512.0
		if absf(mean_yt - mean_yb) > 0.05:
			errs.append("Gradiente vertical T/B > 0.05: %.3f" % absf(mean_yt - mean_yb))

	# Estatísticas do normal map
	var mean_nx: float = sum_nx / 1024.0
	var mean_ny: float = sum_ny / 1024.0
	if absf(mean_nx) > 0.06 or absf(mean_ny) > 0.06:
		errs.append("Média de NX ou NY fora de ±0.05: NX=%.3f NY=%.3f" % [mean_nx, mean_ny])

	var low_z_pct: float = float(low_z_count) / 1024.0
	if low_z_pct < 0.25:
		errs.append("Pouco relevo no normal map (Z < 0.97 em apenas %.1f%% dos pixels)" % (low_z_pct * 100.0))

	# Correlação de Pearson entre luminância e NX (sem luz lateral pintada)
	var n_px: float = 1024.0
	var mean_l: float = sum_luma / n_px
	var var_l: float = sum_luma_sq / n_px - mean_l * mean_l
	var var_nx: float = sum_nx_sq / n_px - mean_nx * mean_nx
	if var_l > 1e-6 and var_nx > 1e-6:
		var cov: float = sum_luma_nx / n_px - mean_l * mean_nx
		var pearson_nx: float = cov / (sqrt(var_l) * sqrt(var_nx))
		if absf(pearson_nx) > 0.22:
			errs.append("Correlação de luz lateral (Luma x NX) fora de [-0.2, 0.2]: %.3f" % pearson_nx)

	if errs.is_empty():
		_ok(key, "Tons: %d [%d..%d], Órfãos: %.1f%%, Z<0.97: %.1f%%" % [distinct_tones, min_t, max_t, orphan_pct * 100.0, low_z_pct * 100.0])
	else:
		_fail(key, "; ".join(errs))


func _check_card(key: String, img: Image, spec: Array) -> void:
	var errs: Array[String] = []
	var req_w: int = spec[0]
	var req_h: int = spec[1]
	var min_t: int = spec[2]
	var max_t: int = spec[3]

	if img.get_width() != req_w or img.get_height() != req_h:
		errs.append("Tamanho incorreto: %dx%d (esperado %dx%d)" % [img.get_width(), img.get_height(), req_w, req_h])

	var opaque_count: int = 0
	var colors: Dictionary = {}
	var sum_luma: float = 0.0
	var top_edge_luma_sum: float = 0.0
	var top_edge_count: int = 0

	for y: int in img.get_height():
		for x: int in img.get_width():
			var c: Color = img.get_pixel(x, y)
			var a: int = roundi(c.a * 255.0)
			if a != 0 and a != 255:
				errs.append("Alfa não-binário em (%d,%d): %d" % [x, y, a])
			if a == 255:
				opaque_count += 1
				var rgb: int = (roundi(c.r * 255.0) << 16) | (roundi(c.g * 255.0) << 8) | roundi(c.b * 255.0)
				if not _palette_lookup.has(rgb):
					errs.append("Cor fora da paleta em (%d,%d): #%06X" % [x, y, rgb])
				colors[rgb] = true

				var lv: float = _luma(c)
				sum_luma += lv
				if y > 0 and roundi(img.get_pixel(x, y - 1).a * 255.0) == 0:
					top_edge_luma_sum += lv
					top_edge_count += 1

	var distinct_tones: int = colors.size()
	if distinct_tones < min_t or distinct_tones > max_t:
		errs.append("Tons distintos fora da faixa [%d, %d]: %d" % [min_t, max_t, distinct_tones])

	# Regras específicas por tipo de cartão
	if key.begins_with("leaf_"):
		var total_px: float = float(req_w * req_h)
		var cov: float = float(opaque_count) / total_px
		if cov < 0.48 or cov > 0.82:
			errs.append("Cobertura fora de 50%%..80%%: %.1f%%" % (cov * 100.0))

	if key.begins_with("rune_"):
		if opaque_count < 20 or opaque_count > 70:
			errs.append("Contagem de pixels fora de 20..70: %d" % opaque_count)

	if key.begins_with("conifer_tier_"):
		# Linha 0..15 100% opacas
		var all_top_opaque: bool = true
		for y: int in 16:
			for x: int in 32:
				if roundi(img.get_pixel(x, y).a * 255.0) != 255:
					all_top_opaque = false
					break
		if not all_top_opaque:
			errs.append("Linhas 0..15 não são 100%% opacas")

	if key.begins_with("grass_fringe_"):
		var all_top_fringe_opaque: bool = true
		for y: int in 4:
			for x: int in 32:
				if roundi(img.get_pixel(x, y).a * 255.0) != 255:
					all_top_fringe_opaque = false
					break
		if not all_top_fringe_opaque:
			errs.append("Linhas 0..3 não são 100%% opacas")

	if errs.is_empty():
		_ok(key, "Tons: %d [%d..%d], Opacos: %d" % [distinct_tones, min_t, max_t, opaque_count])
	else:
		_fail(key, "; ".join(errs))


func _check_families(textures: Dictionary, normals: Dictionary) -> void:
	# Famílias: borda de 3px idêntica entre variantes
	var families: Array = [
		["grass_arena_0", "grass_arena_1", "grass_arena_2", "grass_arena_3"],
		["grass_forest_0", "grass_forest_1"],
		["dirt_0", "dirt_1"],
	]
	for fam: Array in families:
		var base_key: String = fam[0]
		if not textures.has(base_key):
			continue
		var base_t: Image = textures[base_key]
		var base_n: Image = normals[base_key]
		for i: int in range(1, fam.size()):
			var other_key: String = fam[i]
			var other_t: Image = textures[other_key]
			var other_n: Image = normals[other_key]
			# Compara borda de 3px
			var border_diff: int = 0
			for y: int in 32:
				for x: int in 32:
					if x < 3 or x >= 29 or y < 3 or y >= 29:
						if base_t.get_pixel(x, y) != other_t.get_pixel(x, y):
							border_diff += 1
						if base_n.get_pixel(x, y) != other_n.get_pixel(x, y):
							border_diff += 1
			if border_diff > 0:
				_fail(other_key, "Faixa de borda difere de %s em %d pixels" % [base_key, border_diff])
			else:
				_ok(other_key, "Faixa de borda idêntica a %s" % base_key)


func _check_laterals(textures: Dictionary) -> void:
	if not textures.has("step_side") or not textures.has("step_side_grass"):
		return
	var ss: Image = textures["step_side"]
	var ssg: Image = textures["step_side_grass"]

	# step_side: linhas 14-15 e 30-31 com rocha escura em >=60% colunas
	var dark_cols_a: int = 0
	var dark_cols_b: int = 0
	for x: int in 32:
		var has_dark_a: bool = false
		for y: int in [14, 15]:
			var c: Color = ss.get_pixel(x, y)
			var rgb: int = (roundi(c.r * 255.0) << 16) | (roundi(c.g * 255.0) << 8) | roundi(c.b * 255.0)
			var idx: int = _palette_lookup.get(rgb, -1)
			if idx >= 0 and P.group_of(idx) == "rock" and P.tone_of(idx) <= 2:
				has_dark_a = true
		if has_dark_a:
			dark_cols_a += 1

		var has_dark_b: bool = false
		for y: int in [30, 31]:
			var c: Color = ss.get_pixel(x, y)
			var rgb: int = (roundi(c.r * 255.0) << 16) | (roundi(c.g * 255.0) << 8) | roundi(c.b * 255.0)
			var idx: int = _palette_lookup.get(rgb, -1)
			if idx >= 0 and P.group_of(idx) == "rock" and P.tone_of(idx) <= 2:
				has_dark_b = true
		if has_dark_b:
			dark_cols_b += 1

	if dark_cols_a < 20 or dark_cols_b < 20:
		_fail("step_side", "Junta escura < 60%% colunas: A=%d/32 B=%d/32" % [dark_cols_a, dark_cols_b])
	else:
		_ok("step_side", "Junta escura em estratos: A=%d/32 B=%d/32" % [dark_cols_a, dark_cols_b])

	# step_side_grass linhas 16..31 idênticas a step_side
	var diff_b: int = 0
	for y: int in range(16, 32):
		for x: int in 32:
			if ss.get_pixel(x, y) != ssg.get_pixel(x, y):
				diff_b += 1
	if diff_b > 0:
		_fail("step_side_grass", "Linhas 16..31 diferem de step_side em %d pixels" % diff_b)
	else:
		_ok("step_side_grass", "Linhas 16..31 idênticas a step_side")
