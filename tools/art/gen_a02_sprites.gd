extends RefCounted
## Gera sprites em pé de vegetação e monólitos da A02 no estilo naturalista
## (HD-2D Octopath, sem contorno preto, baseado em docs/reference/Gemini_Generated_Image_6oy5mo6oy5mo6oy5.jpg).
## Sem class_name: usar via preload.

const P = preload("res://tools/art/palette_a02.gd")
const Canvas = preload("res://tools/art/a02_canvas.gd")

const ORDER: Array[String] = [
	"tree_big_0", "tree_big_1", "tree_big_2",
	"tree_small_0", "tree_small_1",
	"bush_0", "bush_1", "bush_2",
	"grass_tuft_0", "grass_tuft_1", "grass_tuft_2",
	"flower_0", "flower_1", "flower_2",
	"monolith_0", "monolith_0_rune",
	"monolith_1", "monolith_1_rune",
]


static func rng_for(key: String) -> RandomNumberGenerator:
	var r: RandomNumberGenerator = RandomNumberGenerator.new()
	r.seed = key.hash() ^ 0x5D02
	return r


static func build_all() -> Dictionary:
	var out: Dictionary = {}
	# tree_big: 96x128. 0 = conífera/pinheiro alto, 1 = folhosa/carvalho frondoso, 2 = conífera densa
	out["tree_big_0"] = _build_conifer_sprite(96, 128, 4, rng_for("tree_big_0"))
	out["tree_big_1"] = _build_deciduous_sprite(96, 128, 5, rng_for("tree_big_1"))
	out["tree_big_2"] = _build_conifer_sprite(96, 128, 5, rng_for("tree_big_2"))

	# tree_small: 64x96. 0 = pinheiro jovem, 1 = folhosa pequena/bétula
	out["tree_small_0"] = _build_conifer_sprite(64, 96, 3, rng_for("tree_small_0"))
	out["tree_small_1"] = _build_deciduous_sprite(64, 96, 4, rng_for("tree_small_1"))

	# bush: 32x32
	out["bush_0"] = _build_bush_sprite(32, 32, false, rng_for("bush_0"))
	out["bush_1"] = _build_bush_sprite(32, 32, true, rng_for("bush_1"))
	out["bush_2"] = _build_log_sprite(32, 32, rng_for("bush_2"))

	# grass_tuft: 16x16
	out["grass_tuft_0"] = _build_tuft_sprite(0, rng_for("grass_tuft_0"))
	out["grass_tuft_1"] = _build_tuft_sprite(1, rng_for("grass_tuft_1"))
	out["grass_tuft_2"] = _build_tuft_sprite(2, rng_for("grass_tuft_2"))

	# flower: 16x16
	out["flower_0"] = _build_flower_sprite(0, rng_for("flower_0"))
	out["flower_1"] = _build_flower_sprite(1, rng_for("flower_1"))
	out["flower_2"] = _build_mushroom_sprite(rng_for("flower_2"))

	# monolith: 32x96 e 32x64 (+ runas)
	var m0: Array[Image] = _build_monolith_sprite(32, 96, rng_for("monolith_0"))
	out["monolith_0"] = m0[0]
	out["monolith_0_rune"] = m0[1]

	var m1: Array[Image] = _build_monolith_sprite(32, 64, rng_for("monolith_1"))
	out["monolith_1"] = m1[0]
	out["monolith_1_rune"] = m1[1]

	return out


# ---------------------------------------------------------------------------
# Conífera / Pinheiro (camadas de agulhas pontilhadas em trapézios)
# ---------------------------------------------------------------------------
static func _build_conifer_sprite(w: int, h: int, tiers: int, rng: RandomNumberGenerator) -> Image:
	var img: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var cnf: PackedInt32Array = P.ramp("conifer")
	var bk: PackedInt32Array = P.ramp("bark")

	var mid_x: float = float(w) * 0.5
	var trunk_w: float = float(w) * 0.10
	var trunk_top_y: float = float(h) * 0.70

	# Tronco e raízes visíveis na base
	for y: int in range(roundi(trunk_top_y), h - 1):
		var flare: float = pow(float(y - trunk_top_y) / float(h - trunk_top_y), 2.0) * float(w) * 0.12
		var cur_w: float = trunk_w * 0.5 + flare
		for x: int in range(roundi(mid_x - cur_w), roundi(mid_x + cur_w) + 1):
			var dist_center: float = absf(float(x) - mid_x) / maxf(cur_w, 1.0)
			var tone: int = clampi(roundi(4.2 - dist_center * 2.8 + rng.randf_range(-0.4, 0.4)), 0, 4)
			img.set_pixel(x, y, P.color(bk[tone]))

	# Andares cônicos de agulhas com pontas pendentes
	var tier_h: float = float(h) * 0.82 / float(tiers)
	for t: int in tiers:
		var top_y: float = float(h) * 0.04 + float(t) * tier_h * 0.72
		var bot_y: float = top_y + tier_h * 1.35
		var max_r: float = float(w) * (0.18 + float(t) * 0.09)

		for y: int in range(roundi(top_y), roundi(bot_y)):
			if y >= h - 1:
				continue
			var frac_y: float = float(y - top_y) / (bot_y - top_y)
			# Curva ligeiramente côncava nos ramos
			var cur_r: float = max_r * pow(frac_y, 0.85)

			for x: int in range(roundi(mid_x - cur_r), roundi(mid_x + cur_r) + 1):
				if x < 1 or x >= w - 1:
					continue
				var dist_norm: float = absf(float(x) - mid_x) / maxf(cur_r, 1.0)
				# Borda irregular com recorte serrilhado de agulhas
				if frac_y > 0.75:
					var saw: float = absf(sin(float(x) * 1.6 + float(t)))
					if saw > (1.0 - frac_y) * 3.5:
						continue
				elif dist_norm > 0.88 and rng.randf() < (dist_norm - 0.88) * 5.0:
					continue

				# Sombreamento volumétrico naturalista (sol no alto-esquerda, sombra embaixo e atrás)
				var light_vert: float = 1.0 - frac_y # 1 no topo do andar, 0 embaixo
				var light_horiz: float = 1.0 - dist_norm # 1 no centro, 0 nas bordas
				var sun_bias: float = clampf(1.0 - (float(x) - (mid_x - cur_r * 0.35)) / cur_r, 0.0, 1.0)
				var val: float = light_vert * 0.45 + light_horiz * 0.20 + sun_bias * 0.40
				# Andares superiores recebem mais luz solar direta
				if t == 0:
					val += 0.20
				elif t == tiers - 1:
					val -= 0.12

				var tone: int = clampi(roundi(0.8 + val * 5.4 + rng.randf_range(-0.35, 0.35)), 0, 6)
				img.set_pixel(x, y, P.color(cnf[tone]))

	return img


# ---------------------------------------------------------------------------
# Folhosa / Carvalho (copa com tufos/nuvens volumétricas e galhos visíveis)
# ---------------------------------------------------------------------------
static func _build_deciduous_sprite(w: int, h: int, _clumps: int, rng: RandomNumberGenerator) -> Image:
	var img: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var lv: PackedInt32Array = P.ramp("leaves")
	var bk: PackedInt32Array = P.ramp("bark")

	var mid_x: float = float(w) * 0.5
	var trunk_w: float = float(w) * 0.11
	var crown_y: float = float(h) * 0.40

	# Tronco curvado e raízes
	var trunk_top_y: float = float(h) * 0.50
	for y: int in range(roundi(trunk_top_y), h - 1):
		var frac_down: float = float(y - trunk_top_y) / float(h - trunk_top_y)
		var flare: float = pow(frac_down, 2.5) * float(w) * 0.14
		var cur_w: float = trunk_w * (0.45 + 0.55 * frac_down) + flare
		var cur_mid_x: float = mid_x + sin(frac_down * 1.6) * float(w) * 0.025
		for x: int in range(roundi(cur_mid_x - cur_w), roundi(cur_mid_x + cur_w) + 1):
			var dist_c: float = absf(float(x) - cur_mid_x) / maxf(cur_w, 1.0)
			var tone: int = clampi(roundi(4.5 - dist_c * 2.8 + rng.randf_range(-0.4, 0.4)), 0, 5)
			img.set_pixel(x, y, P.color(bk[tone]))

	# Galhos estruturais que entram na copa
	var branches: Array = [
		[Vector2(mid_x, trunk_top_y + 4.0), Vector2(mid_x - float(w) * 0.22, crown_y + float(h) * 0.08), 2.5],
		[Vector2(mid_x, trunk_top_y + 2.0), Vector2(mid_x + float(w) * 0.20, crown_y + float(h) * 0.10), 2.2],
		[Vector2(mid_x, trunk_top_y), Vector2(mid_x - float(w) * 0.05, crown_y - float(h) * 0.05), 2.0],
	]
	for b: Array in branches:
		var p0: Vector2 = b[0]
		var p1: Vector2 = b[1]
		var bw: float = b[2]
		var steps: int = roundi(p0.distance_to(p1) * 2.0)
		for s: int in steps + 1:
			var t: float = float(s) / float(steps)
			var pt: Vector2 = p0.lerp(p1, t)
			var w_cur: float = bw * (1.0 - t * 0.5)
			for dy: int in range(roundi(-w_cur), roundi(w_cur) + 1):
				for dx: int in range(roundi(-w_cur), roundi(w_cur) + 1):
					var px: int = roundi(pt.x + dx)
					var py: int = roundi(pt.y + dy)
					if px >= 1 and px < w - 1 and py >= 1 and py < h - 1:
						var tone: int = clampi(roundi(2.5 + rng.randf_range(-0.4, 0.4)), 0, 4)
						img.set_pixel(px, py, P.color(bk[tone]))

	# Nuvens de folhagem (pillows/clumps) organizadas em camadas
	# Cada tufo: [cx_norm, cy_norm, rx, ry, sun_boost, layer_order]
	var clumps: Array = [
		# Fundo / sombra profunda
		[-0.12, 0.08, float(w) * 0.26, float(h) * 0.16, -0.15, 0],
		[0.14, 0.10, float(w) * 0.25, float(h) * 0.16, -0.18, 0],
		# Miolo
		[0.0, -0.02, float(w) * 0.32, float(h) * 0.22, 0.05, 1],
		# Laterais médias
		[-0.24, -0.05, float(w) * 0.25, float(h) * 0.19, 0.15, 2],
		[0.22, -0.04, float(w) * 0.24, float(h) * 0.18, -0.05, 2],
		[-0.28, 0.12, float(w) * 0.22, float(h) * 0.16, -0.10, 2],
		[0.26, 0.14, float(w) * 0.21, float(h) * 0.15, -0.22, 2],
		# Cúpula e tufo do sol (topo-esquerda)
		[-0.15, -0.22, float(w) * 0.24, float(h) * 0.18, 0.32, 3],
		[0.12, -0.20, float(w) * 0.22, float(h) * 0.17, 0.12, 3],
		[0.0, -0.32, float(w) * 0.20, float(h) * 0.15, 0.25, 4],
	]

	# Renderiza os tufos com sombreamento esférico local + oclusão entre tufos
	for clump: Array in clumps:
		var cx: float = mid_x + clump[0] * float(w)
		var cy: float = crown_y + clump[1] * float(h)
		var rx: float = clump[2]
		var ry: float = clump[3]
		var sun_boost: float = clump[4]

		var min_x: int = clampi(roundi(cx - rx * 1.15), 1, w - 2)
		var max_x: int = clampi(roundi(cx + rx * 1.15), 1, w - 2)
		var min_y: int = clampi(roundi(cy - ry * 1.15), 1, h - 2)
		var max_y: int = clampi(roundi(cy + ry * 1.15), 1, h - 2)

		for y: int in range(min_y, max_y + 1):
			var dy: float = (float(y) - cy) / ry
			for x: int in range(min_x, max_x + 1):
				var dx: float = (float(x) - cx) / rx
				var d2: float = dx * dx + dy * dy
				if d2 > 1.0:
					continue

				# Borda recortada de folhas individuais
				if d2 > 0.82:
					var angle: float = atan2(dy, dx)
					var leaf_leaf_jitter: float = sin(angle * 7.0 + float(y) * 0.5) * 0.10
					if d2 + leaf_leaf_jitter > 0.96 and rng.randf() > 0.35:
						continue

				# Iluminação local do tufo esférico: sol a (-0.6, -0.8)
				var norm_z: float = sqrt(maxf(1.0 - d2, 0.0))
				var local_sun: float = -dx * 0.45 - dy * 0.65 + norm_z * 0.35
				var total_light: float = local_sun + sun_boost

				# Sombra na base do tufo (crevice sob o travesseiro de folhas)
				if dy > 0.65:
					total_light -= (dy - 0.65) * 0.9

				var tone: int = clampi(roundi(3.2 + total_light * 3.2 + rng.randf_range(-0.35, 0.35)), 1, 7)

				# Se já existia um pixel de folha, só sobrepõe se for mais iluminado ou camada superior
				var prev_col: Color = img.get_pixel(x, y)
				if prev_col.a > 0.1 and total_light < -0.2:
					continue

				img.set_pixel(x, y, P.color(lv[tone]))

	return img


# ---------------------------------------------------------------------------
# Arbusto (32x32)
# ---------------------------------------------------------------------------
static func _build_bush_sprite(w: int, h: int, with_flowers: bool, rng: RandomNumberGenerator) -> Image:
	var img: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var lv: PackedInt32Array = P.ramp("leaves")
	var fl: PackedInt32Array = P.ramp("flower_white")
	var y_fl: PackedInt32Array = P.ramp("flower_yellow")

	var mid_x: float = float(w) * 0.5
	var base_y: float = float(h) * 0.62
	var puffs: Array = [
		[Vector2(mid_x - 5.0, base_y + 2.0), 9.0, 7.0, 0.08],
		[Vector2(mid_x + 5.0, base_y + 1.0), 9.0, 7.0, -0.12],
		[Vector2(mid_x - 1.0, base_y - 4.0), 8.5, 7.5, 0.28],
	]
	for puff: Array in puffs:
		var c: Vector2 = puff[0]
		var rx: float = puff[1]
		var ry: float = puff[2]
		var sun_boost: float = puff[3]
		for y: int in range(maxi(roundi(c.y - ry), 1), mini(roundi(c.y + ry), h - 1)):
			var dy: float = (float(y) - c.y) / ry
			for x: int in range(maxi(roundi(c.x - rx), 1), mini(roundi(c.x + rx), w - 1)):
				var dx: float = (float(x) - c.x) / rx
				var d2: float = dx * dx + dy * dy
				if d2 > 1.0:
					continue
				if d2 > 0.85 and rng.randf() > 0.4:
					continue
				var norm_z: float = sqrt(maxf(1.0 - d2, 0.0))
				var local_sun: float = -dx * 0.45 - dy * 0.65 + norm_z * 0.35 + sun_boost
				var tone: int = clampi(roundi(4.2 + local_sun * 4.2 + rng.randf_range(-0.35, 0.35)), 1, 8)
				img.set_pixel(x, y, P.color(lv[tone]))

	if with_flowers:
		for pos: Vector2i in [Vector2i(10, 14), Vector2i(18, 12), Vector2i(22, 18), Vector2i(14, 20)]:
			img.set_pixel(pos.x, pos.y, P.color(fl[1]))
			img.set_pixel(pos.x + 1, pos.y, P.color(fl[1]))
			img.set_pixel(pos.x, pos.y + 1, P.color(y_fl[1]))

	return img


# ---------------------------------------------------------------------------
# Capim Tufo Sprite (16x16)
# ---------------------------------------------------------------------------
static func _build_tuft_sprite(variant: int, rng: RandomNumberGenerator) -> Image:
	var img: Image = Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	var ramp: PackedInt32Array = P.ramp("grass_forest" if variant == 2 else "grass_arena")

	var base_x: int = 7
	img.set_pixel(base_x, 15, P.color(ramp[1]))
	img.set_pixel(base_x + 1, 15, P.color(ramp[1]))

	for b: int in 7:
		var target_x: int = clampi(roundi(base_x + rng.randf_range(-5.0, 5.0)), 2, 13)
		var height: int = rng.randi_range(9, 14)
		var target_y: int = 15 - height
		var pts: Array[Vector2i] = Canvas.line_pts(base_x + (b % 2), 14, target_x, target_y)
		for p: Vector2i in pts:
			if p.y == 0 or p.x == 0 or p.x == 15:
				continue
			var vert: float = float(15 - p.y) / float(height)
			var tone: int = clampi(roundi(1.8 + vert * 4.4), 1, ramp.size() - 1)
			img.set_pixel(p.x, p.y, P.color(ramp[tone]))

	return img


# ---------------------------------------------------------------------------
# Flor Sprite (16x16)
# ---------------------------------------------------------------------------
static func _build_flower_sprite(variant: int, rng: RandomNumberGenerator) -> Image:
	var img: Image = Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	var gr: PackedInt32Array = P.ramp("grass_arena")
	var fl_group: String = ["flower_yellow", "flower_white", "flower_lilac"][variant]
	var fl_ramp: PackedInt32Array = P.ramp(fl_group)
	var y_ramp: PackedInt32Array = P.ramp("flower_yellow")

	var base_x: int = 7
	img.set_pixel(base_x, 15, P.color(gr[1]))
	img.set_pixel(base_x + 1, 15, P.color(gr[1]))

	var heads: Array[Vector2i] = [Vector2i(4, 4), Vector2i(10, 3)]
	for idx: int in heads.size():
		var hpos: Vector2i = heads[idx]
		var pts: Array[Vector2i] = Canvas.line_pts(base_x, 14, hpos.x + 1, hpos.y + 2)
		for p: Vector2i in pts:
			if p.y == 0 or p.x == 0 or p.x == 15:
				continue
			img.set_pixel(p.x, p.y, P.color(gr[3]))

		# Folha
		img.set_pixel(hpos.x + 1, hpos.y + 4, P.color(gr[4]))

		# Flor
		img.set_pixel(hpos.x, hpos.y, P.color(fl_ramp[2]))
		img.set_pixel(hpos.x + 1, hpos.y, P.color(fl_ramp[1]))
		img.set_pixel(hpos.x, hpos.y + 1, P.color(fl_ramp[0]))
		img.set_pixel(hpos.x + 1, hpos.y + 1, P.color(y_ramp[1]))

	return img


# ---------------------------------------------------------------------------
# Monólito e Runa (32x96 ou 32x64)
# ---------------------------------------------------------------------------
static func _build_monolith_sprite(w: int, h: int, rng: RandomNumberGenerator) -> Array[Image]:
	var stone_img: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var rune_img: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var cs: PackedInt32Array = P.ramp("cold_stone")
	var lich: PackedInt32Array = P.ramp("lichen")
	var rn: PackedInt32Array = P.ramp("rune")

	var mid_x: float = float(w) * 0.5
	var top_y: float = float(h) * 0.1
	var bot_y: float = float(h) - 1.0
	var top_w: float = float(w) * 0.28
	var bot_w: float = float(w) * 0.38

	# Corpo do monólito
	for y: int in range(roundi(top_y), roundi(bot_y)):
		var frac_y: float = float(y - top_y) / (bot_y - top_y)
		var cur_w: float = lerpf(top_w, bot_w, frac_y)
		for x: int in range(roundi(mid_x - cur_w), roundi(mid_x + cur_w) + 1):
			var dist_norm: float = (float(x) - (mid_x - cur_w)) / (cur_w * 2.0)
			# Chanfro e luz de borda
			var tone: int = 4
			if dist_norm < 0.2:
				tone = 5 # Face voltada para a luz
			elif dist_norm > 0.8:
				tone = 2 # Face sombreada
			else:
				tone = 3 if rng.randf() < 0.4 else 4
			stone_img.set_pixel(x, y, P.color(cs[tone]))

	# Mancha de líquen
	for dy: int in 4:
		for dx: int in 4:
			if rng.randf() < 0.7:
				stone_img.set_pixel(roundi(mid_x - 4.0) + dx, roundi(bot_y - 12.0) + dy, P.color(lich[1]))

	# Runa central entalhada emissiva
	var rune_center_y: int = roundi(float(h) * 0.4)
	var rx: int = roundi(mid_x)
	var ry: int = rune_center_y

	# Desenha glifo rúnico
	var rune_pts: Array[Vector2i] = [
		Vector2i(0, -6), Vector2i(0, 6),
		Vector2i(-3, -3), Vector2i(3, -3),
		Vector2i(-4, 2), Vector2i(4, 2),
		Vector2i(0, -3), Vector2i(0, 3),
	]
	for p: Vector2i in rune_pts:
		rune_img.set_pixel(rx + p.x, ry + p.y, P.color(rn[1]))
		# Entalhe no monólito
		stone_img.set_pixel(rx + p.x, ry + p.y, P.color(cs[1]))

	# Núcleo emissivo brilhante
	rune_img.set_pixel(rx, ry - 3, P.color(rn[2]))
	rune_img.set_pixel(rx, ry, P.color(rn[3]))
	rune_img.set_pixel(rx, ry + 2, P.color(rn[2]))

	return [stone_img, rune_img]


# ---------------------------------------------------------------------------
# Tronco Caído com Musgo (32x32)
# ---------------------------------------------------------------------------
static func _build_log_sprite(w: int, h: int, rng: RandomNumberGenerator) -> Image:
	var img: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var bk: PackedInt32Array = P.ramp("bark")
	var moss: PackedInt32Array = P.ramp("moss")

	var log_x0: int = 3
	var log_x1: int = 28
	var log_y0: int = 18
	var log_h: int = 10

	# Corpo do tronco horizontal
	for y: int in range(log_y0, log_y0 + log_h):
		var frac_y: float = float(y - log_y0) / float(log_h)
		for x: int in range(log_x0, log_x1 + 1):
			var tone: int = clampi(roundi(3.5 - frac_y * 2.2 + rng.randf_range(-0.4, 0.4)), 0, 4)
			img.set_pixel(x, y, P.color(bk[tone]))

	# Corte circular na ponta esquerda mostrando anéis de madeira
	var cut_cx: int = log_x0 + 2
	var cut_cy: int = log_y0 + 5
	for dy: int in range(-4, 5):
		for dx: int in range(-2, 3):
			if dx * dx * 2 + dy * dy <= 16:
				var r: float = sqrt(dx * dx * 2 + dy * dy)
				var ring_tone: int = 5 if fmod(r, 2.0) < 1.0 else 4
				img.set_pixel(cut_cx + dx, cut_cy + dy, P.color(bk[ring_tone]))

	# Tapete espesso de musgo verde no topo do tronco
	for x: int in range(log_x0 + 4, log_x1):
		var moss_depth: int = rng.randi_range(2, 4)
		for dy: int in moss_depth:
			var m_tone: int = clampi(roundi(5 - dy + rng.randf_range(-0.3, 0.3)), 1, 5)
			img.set_pixel(x, log_y0 - 1 + dy, P.color(moss[m_tone]))

	return img


# ---------------------------------------------------------------------------
# Cogumelos Mágicos Brilhantes (16x16)
# ---------------------------------------------------------------------------
static func _build_mushroom_sprite(rng: RandomNumberGenerator) -> Image:
	var img: Image = Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	var gr: PackedInt32Array = P.ramp("grass_arena")
	var stem: PackedInt32Array = P.ramp("flower_white")
	var cyan: PackedInt32Array = P.ramp("rune")
	var lilac: PackedInt32Array = P.ramp("flower_lilac")

	# Base de musgo
	img.set_pixel(7, 15, P.color(gr[1]))
	img.set_pixel(8, 15, P.color(gr[1]))
	img.set_pixel(6, 15, P.color(gr[2]))

	# Cogumelo grande (ciano brilhante)
	for y: int in range(8, 15):
		img.set_pixel(6, y, P.color(stem[1]))
		img.set_pixel(7, y, P.color(stem[0]))
	var cap_pts: Array = [
		Vector2i(5, 7), Vector2i(6, 7), Vector2i(7, 7), Vector2i(8, 7),
		Vector2i(4, 8), Vector2i(5, 8), Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8), Vector2i(9, 8),
		Vector2i(6, 6), Vector2i(7, 6)
	]
	for p: Vector2i in cap_pts:
		img.set_pixel(p.x, p.y, P.color(cyan[2]))
	img.set_pixel(6, 6, P.color(cyan[3]))
	img.set_pixel(5, 7, P.color(cyan[1]))
	img.set_pixel(8, 8, P.color(cyan[0]))

	# Cogumelo pequeno (lilás)
	for y: int in range(11, 15):
		img.set_pixel(11, y, P.color(stem[1]))
	for dx: int in range(-2, 3):
		img.set_pixel(11 + dx, 10, P.color(lilac[2]))
	img.set_pixel(11, 9, P.color(lilac[1]))
	img.set_pixel(10, 10, P.color(lilac[0]))

	return img
