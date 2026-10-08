extends SceneTree
## A08: mede a paleta na referência (docs/reference/ilha-flutuante.webp, 906x509) e grava a prévia
## docs/art-preview/a08-paleta-medida.png (regiões marcadas + tabela medida x alvo).
## Também imprime a tabela no console. Rodar da raiz do projeto:
##   "$G" --headless --path . --script tools/art/gen_a08_paleta.gd

const PL = preload("res://tools/art/paint_lib.gd")

# [nome, retângulo na referência 906x509 (x, y, largura, altura), alvo da direção de arte / A08, só terra?]
const REGIONS: Array = [
	["grama arena oeste (012)", Rect2i(283, 234, 57, 49), "#7F8033", false],
	["grama arena frente (012)", Rect2i(297, 318, 128, 36), "#717B22", false],
	["grama ao sol", Rect2i(322, 248, 18, 14), "#A8C447", false],
	["grama na sombra", Rect2i(292, 245, 10, 25), "#3F5F22", false],
	["terra da arena (012)", Rect2i(396, 283, 57, 28), "#AE813F", true],
	["terra iluminada", Rect2i(470, 262, 28, 14), "#B3843D", true],
	["terra batida escura (sul)", Rect2i(402, 304, 18, 9), "#8A5E34", true],
	["borda avermelhada (so)", Rect2i(352, 300, 12, 6), "#6E4228", true],
	["disco do circulo", Rect2i(429, 274, 10, 5), "#7E5634", false],
	["miolo claro", Rect2i(444, 279, 9, 3), "#B8925A", false],
	["crescente oeste", Rect2i(417, 277, 7, 8), "#C8AA78", false],
	["crescente leste", Rect2i(472, 275, 5, 9), "#C8AA78", false],
	["pedra comprida", Rect2i(472, 308, 14, 4), "#B8AE98", false],
	["capeamento muro sul", Rect2i(330, 381, 60, 2), "#E0D2A8", false],
	["face externa muro sul (012)", Rect2i(212, 393, 184, 14), "#2A3C27", false],
	["degraus escada sul", Rect2i(432, 398, 34, 26), "#C2B58C", false],
	["lajes patamar sul", Rect2i(437, 440, 40, 22), "#BBA366", false],
	["mata noroeste (012)", Rect2i(120, 177, 92, 92), "#58572B", false],
	["copa ao sol (leste)", Rect2i(735, 198, 16, 14), "#C8D870", false],
	["coniferas leste (012)", Rect2i(708, 177, 71, 106), "#384F21", false],
	["folhosas nordeste (012)", Rect2i(566, 106, 99, 57), "#616F58", false],
	["penhasco frente (012)", Rect2i(283, 460, 113, 43), "#38302A", false],
	["nuvem esquerda (012)", Rect2i(28, 226, 71, 43), "#D9C7C2", false],
]


func _initialize() -> void:
	var ref: Image = PL.load_ref()
	var k: int = 2
	var big: Image = PL.scaled(ref, float(k), Image.INTERPOLATE_LANCZOS)
	var marks := [Color("#ff2bd6"), Color("#00e5ff"), Color("#fff200")]
	var rows: Array = []
	print("A08 paleta medida (referência %dx%d):" % [ref.get_width(), ref.get_height()])
	for i: int in REGIONS.size():
		var e: Array = REGIONS[i]
		var rc: Rect2i = e[1]
		var st: Dictionary = PL.lum_stats(ref, rc, bool(e[3]))
		var mc: Color = st["color"]
		var tc: Color = PL.hx(str(e[2]))
		var d: float = PL.cdist(mc, tc)
		rows.append([i + 1, str(e[0]), mc, tc, d, float(st["mean"]), float(st["std"])])
		print("  %2d %-30s medido #%s  alvo %s  dist %4.1f%%  L %5.1f  desvio %4.1f" % [i + 1, str(e[0]), mc.to_html(false).to_upper(), str(e[2]), d * 100.0, st["mean"], st["std"]])
		var mk: Color = marks[i % marks.size()]
		var brc := Rect2i(rc.position * k, rc.size * k)
		PL.frame(big, brc, mk, 2)
		PL.text(big, str(i + 1), brc.position.x, maxi(brc.position.y - 14, 0), 2, mk)
	# Tabela
	var tk: int = 3
	var row_h: int = 34
	var tw: int = 900
	var out := Image.create(big.get_width() + tw, maxi(big.get_height(), 60 + rows.size() * row_h), false, Image.FORMAT_RGBA8)
	out.fill(Color("#2b2b30"))
	out.blit_rect(big, Rect2i(Vector2i.ZERO, big.get_size()), Vector2i.ZERO)
	var x0: int = big.get_width() + 16
	var fg := Color("#f0ece4")
	PL.text(out, "A08 PALETA MEDIDA  (MEDIDO | ALVO | DIST | L MEDIA/DESVIO)", x0, 12, tk, fg)
	for j: int in rows.size():
		var rw: Array = rows[j]
		var y: int = 48 + j * row_h
		PL.text(out, "%2d" % rw[0], x0, y + 8, tk, fg)
		out.fill_rect(Rect2i(x0 + 36, y, 56, 28), rw[2])
		out.fill_rect(Rect2i(x0 + 96, y, 56, 28), rw[3])
		var line: String = "#%s %s %4.1f%% %3d/%2d %s" % [(rw[2] as Color).to_html(false).to_upper(), (rw[3] as Color).to_html(false).to_upper(), rw[4] * 100.0, roundi(rw[5]), roundi(rw[6]), rw[1]]
		PL.text(out, line, x0 + 162, y + 8, 2, fg)
	PL.save_png(out, PL.PREVIEW + "a08-paleta-medida.png")
	quit()
