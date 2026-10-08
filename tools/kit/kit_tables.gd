class_name KitTables
extends RefCounted
## Tabelas explícitas do kit do mapa (spec 011, fase 2): cada laje, lóbulo, andar e pedra está
## escrito aqui. Sem sorteio e sem ruído: rodar o construtor duas vezes dá os mesmos arquivos.
## Unidades do mundo; "texels" = 1/32 de unidade.

# ---------------------------------------------------------------- capeamento (lajes)
## Cada laje: [largura em texels, profundidade em texels, beiral em texels (1 a 2), subida do topo em texels (1 a 2)].
## A soma das larguras de cada fila é o comprimento da peça em texels. No muro alto a profundidade é de
## 6 a 9 texels: o musgo da crista (32 texels de fundo) fica visível entre as duas fiadas.
const SLABS_WALL_2_INNER: Array = [[14, 7, 1, 1], [11, 6, 2, 2], [19, 9, 1, 1], [10, 7, 2, 1], [10, 8, 1, 2]]
const SLABS_WALL_2_OUTER: Array = [[17, 8, 2, 1], [12, 7, 1, 2], [10, 9, 2, 1], [13, 6, 1, 2], [12, 8, 2, 1]]
const SLABS_WALL_1_INNER: Array = [[12, 7, 1, 1], [10, 6, 2, 2], [10, 8, 1, 1]]
const SLABS_WALL_1_OUTER: Array = [[10, 8, 2, 1], [12, 7, 1, 2], [10, 6, 2, 1]]
## Quina do muro alto: a primeira laje é o bloco de canto (8 x 8, beiral nas duas faces);
## a fila da face -Z segue com 24 texels (duas lajes) e a da face -X também.
const SLABS_CORNER_BLOCK: Array = [8, 8, 2, 2]
const SLABS_CORNER_Z: Array = [[11, 7, 1, 1], [13, 8, 2, 2]]
const SLABS_CORNER_X: Array = [[12, 8, 2, 2], [12, 6, 1, 1]]
## Fiadas de amarração da quina (de baixo para cima): [altura em texels, comprimento do bloco em texels,
## longo?]. Seguem as juntas pintadas em wall_quoin (curtas de 11 a 13 texels, longa de 22); com o muro
## de 1,0 (28 texels de face sob o capeamento) cabem 3 fiadas: linhas 22-32, 12-22 e 4-12 da textura.
const QUOIN_COURSES: Array = [[10, 13, false], [10, 22, true], [8, 11, false]]
## Degrau baixo: lajes de 0,5 de fundo na frente (+Z local).
const SLABS_STEP_2: Array = [[14, 15, 1, 1], [10, 13, 2, 2], [17, 16, 1, 1], [11, 14, 2, 1], [12, 15, 1, 2]]
const SLABS_STEP_1: Array = [[12, 15, 1, 1], [10, 13, 2, 2], [10, 16, 1, 1]]
## Bochechas de escada (0,5 de largura = 16 texels; lance de 2 de fundo = 64 texels, de 1 = 32): uma fiada em cada borda, de 6 a 7 de fundo, e a
## crista de musgo no meio. Fora e dentro com larguras diferentes, para as juntas não se alinharem.
const SLABS_CHEEK_2_OUT: Array = [[14, 7, 2, 1], [10, 6, 1, 2], [18, 7, 2, 1], [12, 6, 1, 2], [10, 7, 2, 1]]
const SLABS_CHEEK_2_IN: Array = [[12, 6, 2, 1], [16, 7, 1, 2], [10, 6, 2, 1], [14, 7, 1, 2], [12, 6, 2, 1]]
const SLABS_CHEEK_1_OUT: Array = [[16, 7, 2, 1], [16, 6, 1, 2]]
const SLABS_CHEEK_1_IN: Array = [[10, 6, 2, 1], [12, 7, 1, 2], [10, 6, 2, 1]]

## Espessura das lajes (texels) e musgo pendente.
const SLAB_THICKNESS: int = 4
const DRAPE_HEIGHT: float = 0.375

# ---------------------------------------------------------------- decalques (tamanho em unidades)
const DECAL_SIZES: Dictionary = {
	"decal_arena_dirt": Vector2(14.0, 11.0),
	"decal_grass_light_0": Vector2(5.0, 3.0), "decal_grass_light_1": Vector2(4.0, 4.0), "decal_grass_light_2": Vector2(3.0, 2.0),
	"decal_grass_dark_0": Vector2(4.0, 3.0), "decal_grass_dark_1": Vector2(3.0, 3.0),
	"decal_forest_soil_0": Vector2(4.0, 3.0), "decal_forest_soil_1": Vector2(3.0, 4.0),
	"decal_trail_0": Vector2(3.0, 3.0), "decal_trail_1": Vector2(3.0, 3.0), "decal_trail_2": Vector2(3.0, 3.0),
	"decal_trail_3": Vector2(3.0, 3.0), "decal_trail_bend": Vector2(3.0, 3.0),
}

# ---------------------------------------------------------------- folhosas
## Cada árvore: tronco [altura, raio da base, raio do topo], lados do tronco, família da folha,
## centro da copa, lóbulos Vector4(x, y, z, raio) e galhos [y no tronco, ponta, raio], raízes [ângulo, comprimento].
const BROAD: Array = [
	{ # a
		"trunk": [1.5, 0.20, 0.14], "sides": 7, "family": "green", "crown": Vector3(0.0, 2.6, 0.0),
		"lobes": [Vector4(0.0, 2.7, 0.0, 0.85), Vector4(0.75, 2.35, 0.3, 0.7), Vector4(-0.7, 2.3, 0.4, 0.72),
			Vector4(0.2, 2.2, -0.8, 0.68), Vector4(-0.55, 2.5, -0.7, 0.62), Vector4(0.95, 2.6, -0.5, 0.52),
			Vector4(0.35, 3.35, 0.15, 0.62), Vector4(-0.4, 3.25, -0.1, 0.6), Vector4(0.0, 3.0, 0.75, 0.58),
			Vector4(-1.0, 2.7, -0.1, 0.5)],
		"branches": [[1.2, Vector3(0.5, 2.1, 0.2), 0.06], [1.3, Vector3(-0.45, 2.2, 0.1), 0.055], [1.4, Vector3(0.0, 2.5, -0.4), 0.05]],
		"roots": [[20.0, 0.35], [140.0, 0.3], [255.0, 0.33]],
	},
	{ # b
		"trunk": [1.8, 0.22, 0.15], "sides": 7, "family": "olive", "crown": Vector3(0.0, 3.0, 0.0),
		"lobes": [Vector4(0.0, 3.1, 0.0, 0.9), Vector4(0.85, 2.7, 0.35, 0.72), Vector4(-0.8, 2.8, 0.3, 0.75),
			Vector4(0.3, 2.6, -0.9, 0.7), Vector4(-0.65, 2.85, -0.8, 0.64), Vector4(1.05, 3.0, -0.45, 0.55),
			Vector4(0.45, 3.8, 0.2, 0.66), Vector4(-0.5, 3.75, -0.05, 0.64), Vector4(-0.05, 3.45, 0.85, 0.6),
			Vector4(-1.15, 3.1, -0.25, 0.52), Vector4(0.1, 4.05, -0.3, 0.5), Vector4(0.8, 2.45, -0.55, 0.5)],
		"branches": [[1.5, Vector3(0.6, 2.4, 0.3), 0.065], [1.55, Vector3(-0.6, 2.5, 0.2), 0.06],
			[1.7, Vector3(0.1, 2.8, -0.6), 0.055], [1.6, Vector3(0.0, 2.3, 0.5), 0.05]],
		"roots": [[35.0, 0.38], [150.0, 0.32], [270.0, 0.36]],
	},
	{ # c
		"trunk": [2.0, 0.23, 0.15], "sides": 7, "family": "green", "crown": Vector3(0.0, 3.3, 0.0),
		"lobes": [Vector4(0.0, 3.4, 0.0, 0.95), Vector4(0.95, 3.0, 0.3, 0.76), Vector4(-0.9, 3.05, 0.45, 0.74),
			Vector4(0.4, 2.9, -0.95, 0.72), Vector4(-0.7, 3.2, -0.85, 0.66), Vector4(1.15, 3.3, -0.5, 0.58),
			Vector4(0.55, 4.15, 0.25, 0.7), Vector4(-0.55, 4.1, -0.1, 0.66), Vector4(0.0, 3.8, 0.9, 0.62),
			Vector4(-1.25, 3.4, -0.2, 0.54), Vector4(0.15, 4.45, -0.2, 0.52), Vector4(0.9, 2.75, -0.6, 0.52),
			Vector4(-0.3, 2.75, 0.9, 0.5)],
		"branches": [[1.6, Vector3(0.7, 2.7, 0.2), 0.07], [1.7, Vector3(-0.7, 2.8, 0.3), 0.065], [1.85, Vector3(0.0, 3.0, -0.7), 0.06]],
		"roots": [[10.0, 0.4], [130.0, 0.34], [245.0, 0.38]],
	},
	{ # d
		"trunk": [2.1, 0.25, 0.17], "sides": 8, "family": "olive", "crown": Vector3(0.0, 3.65, 0.0),
		"lobes": [Vector4(0.0, 3.75, 0.0, 1.05), Vector4(1.05, 3.3, 0.35, 0.82), Vector4(-1.0, 3.4, 0.4, 0.8),
			Vector4(0.45, 3.2, -1.05, 0.78), Vector4(-0.8, 3.55, -0.95, 0.72), Vector4(1.3, 3.7, -0.55, 0.62),
			Vector4(0.6, 4.6, 0.3, 0.76), Vector4(-0.6, 4.5, -0.1, 0.72), Vector4(0.0, 4.15, 1.0, 0.68),
			Vector4(-1.4, 3.8, -0.25, 0.6), Vector4(0.2, 4.95, -0.25, 0.58), Vector4(1.0, 3.05, -0.7, 0.58),
			Vector4(-0.35, 3.0, 1.0, 0.55), Vector4(0.1, 3.0, -0.2, 0.6)],
		"branches": [[1.7, Vector3(0.8, 3.0, 0.3), 0.075], [1.8, Vector3(-0.8, 3.1, 0.3), 0.07],
			[1.95, Vector3(0.2, 3.3, -0.8), 0.065], [1.9, Vector3(-0.3, 2.9, 0.7), 0.06]],
		"roots": [[25.0, 0.42], [145.0, 0.36], [265.0, 0.4]],
	},
	{ # e
		"trunk": [2.4, 0.26, 0.17], "sides": 8, "family": "cool", "crown": Vector3(0.0, 4.0, 0.0),
		"lobes": [Vector4(0.0, 4.1, 0.0, 1.1), Vector4(1.1, 3.65, 0.4, 0.85), Vector4(-1.05, 3.75, 0.45, 0.84),
			Vector4(0.5, 3.55, -1.1, 0.8), Vector4(-0.85, 3.9, -1.0, 0.74), Vector4(1.4, 4.05, -0.6, 0.64),
			Vector4(0.65, 5.0, 0.35, 0.8), Vector4(-0.65, 4.9, -0.1, 0.76), Vector4(0.0, 4.5, 1.05, 0.7),
			Vector4(-1.5, 4.15, -0.3, 0.62), Vector4(0.25, 5.35, -0.3, 0.62), Vector4(1.05, 3.4, -0.75, 0.6),
			Vector4(-0.4, 3.35, 1.05, 0.58), Vector4(0.15, 3.4, -0.2, 0.65)],
		"branches": [[2.0, Vector3(0.9, 3.3, 0.3), 0.08], [2.1, Vector3(-0.9, 3.4, 0.3), 0.075],
			[2.2, Vector3(0.3, 3.6, -0.9), 0.07], [2.15, Vector3(-0.4, 3.2, 0.8), 0.065]],
		"roots": [[15.0, 0.44], [135.0, 0.38], [250.0, 0.42]],
	},
	{ # small a
		"trunk": [0.9, 0.13, 0.10], "sides": 6, "family": "green", "crown": Vector3(0.0, 1.6, 0.0),
		"lobes": [Vector4(0.0, 1.65, 0.0, 0.55), Vector4(0.5, 1.4, 0.2, 0.42), Vector4(-0.45, 1.45, 0.2, 0.44),
			Vector4(0.15, 1.35, -0.5, 0.4), Vector4(-0.3, 1.6, -0.4, 0.38), Vector4(0.3, 2.05, 0.1, 0.38),
			Vector4(-0.25, 2.0, -0.05, 0.36), Vector4(0.55, 1.75, -0.3, 0.32)],
		"branches": [[0.7, Vector3(0.3, 1.3, 0.1), 0.04], [0.75, Vector3(-0.3, 1.35, 0.1), 0.04]],
		"roots": [[30.0, 0.22], [160.0, 0.2], [280.0, 0.22]],
	},
	{ # small b
		"trunk": [1.1, 0.15, 0.10], "sides": 6, "family": "olive", "crown": Vector3(0.0, 1.95, 0.0),
		"lobes": [Vector4(0.0, 2.0, 0.0, 0.62), Vector4(0.6, 1.7, 0.2, 0.48), Vector4(-0.55, 1.75, 0.25, 0.5),
			Vector4(0.2, 1.65, -0.6, 0.46), Vector4(-0.4, 1.9, -0.5, 0.42), Vector4(0.35, 2.5, 0.15, 0.42),
			Vector4(-0.3, 2.45, -0.1, 0.4), Vector4(0.7, 2.1, -0.35, 0.36), Vector4(-0.05, 2.2, 0.55, 0.38)],
		"branches": [[0.85, Vector3(0.35, 1.55, 0.1), 0.045], [0.9, Vector3(-0.35, 1.6, 0.1), 0.045]],
		"roots": [[20.0, 0.26], [150.0, 0.22], [265.0, 0.25]],
	},
	{ # small c
		"trunk": [1.3, 0.17, 0.11], "sides": 7, "family": "green", "crown": Vector3(0.0, 2.3, 0.0),
		"lobes": [Vector4(0.0, 2.35, 0.0, 0.7), Vector4(0.7, 2.0, 0.25, 0.54), Vector4(-0.65, 2.05, 0.3, 0.56),
			Vector4(0.25, 1.95, -0.7, 0.5), Vector4(-0.5, 2.2, -0.6, 0.46), Vector4(0.4, 2.95, 0.2, 0.48),
			Vector4(-0.35, 2.9, -0.1, 0.46), Vector4(0.8, 2.45, -0.4, 0.4), Vector4(-0.05, 2.6, 0.65, 0.44),
			Vector4(-0.85, 2.5, -0.1, 0.38)],
		"branches": [[1.0, Vector3(0.45, 1.85, 0.15), 0.05], [1.05, Vector3(-0.45, 1.9, 0.15), 0.05], [1.15, Vector3(0.0, 2.1, -0.4), 0.045]],
		"roots": [[28.0, 0.3], [155.0, 0.26], [275.0, 0.28]],
	},
]

## Escala de cada folhosa (a, b, c, d, e, pequenas a, b, c) para as medidas da direção de arte de 2026-10-08
## (folhosa grande de 4,5 a 7 de altura, copa de 3,5 a 5,5; pequena de 2,5 a 4).
const BROAD_SCALE: Array = [1.25, 1.2, 1.2, 1.18, 1.15, 1.15, 1.15, 1.12]

# ---------------------------------------------------------------- coníferas
## Cada conífera (revisão 012-f2: alta, estreita e irregular): altura do tronco e andares
## [y da base, altura, alcance dos cartões, giro em graus, número de cartões (7 a 9), desvio x, desvio z].
## Os alcances saem de uma reta (variação de ±15%, não monotônica) e cada andar fica um pouco torto (desvio).
## O último andar é a ponta (célula 6 ou 7 do atlas). Altura de 6 a 9 e base (2 x o maior alcance) de 2,0 a 3,2.
const CONIFERS: Array = [
	{"trunk": 3.5, "tiers": [
		[0.90, 1.40, 0.92, 0.0, 7, 0.00, 0.00], [1.57, 1.33, 0.73, 23.0, 8, 0.06, -0.04], [2.25, 1.26, 0.75, 51.0, 9, -0.05, 0.07],
		[2.92, 1.19, 0.56, 14.0, 7, 0.08, 0.03], [3.60, 1.12, 0.52, 38.0, 8, -0.07, -0.05], [4.27, 1.05, 0.33, 67.0, 9, 0.04, 0.08],
		[4.95, 1.35, 0.36, 9.0, 7, -0.06, 0.02],
	]},
	{"trunk": 3.7, "tiers": [
		[0.90, 1.40, 0.90, 23.0, 8, 0.00, 0.00], [1.66, 1.33, 0.95, 51.0, 9, 0.08, 0.03], [2.42, 1.26, 0.71, 14.0, 7, -0.07, -0.05],
		[3.17, 1.19, 0.69, 38.0, 8, 0.04, 0.08], [3.93, 1.12, 0.46, 67.0, 9, -0.06, 0.02], [4.69, 1.05, 0.43, 9.0, 7, 0.05, -0.07],
		[5.45, 1.35, 0.36, 44.0, 7, 0.00, 0.05],
	]},
	{"trunk": 4.0, "tiers": [
		[0.90, 1.40, 1.12, 51.0, 9, 0.00, 0.00], [1.61, 1.34, 0.88, 14.0, 7, 0.04, 0.08], [2.31, 1.28, 0.89, 38.0, 8, -0.06, 0.02],
		[3.02, 1.22, 0.64, 67.0, 9, 0.05, -0.07], [3.73, 1.17, 0.66, 9.0, 7, 0.00, 0.05], [4.44, 1.11, 0.50, 44.0, 8, 0.00, 0.00],
		[5.14, 1.05, 0.42, 29.0, 9, 0.06, -0.04], [5.85, 1.35, 0.36, 0.0, 7, -0.05, 0.07],
	]},
	{"trunk": 4.2, "tiers": [
		[0.90, 1.40, 1.04, 14.0, 7, 0.00, 0.00], [1.66, 1.34, 1.07, 38.0, 8, 0.05, -0.07], [2.43, 1.28, 0.78, 67.0, 9, 0.00, 0.05],
		[3.19, 1.22, 0.82, 9.0, 7, 0.00, 0.00], [3.96, 1.17, 0.64, 44.0, 8, 0.06, -0.04], [4.72, 1.11, 0.56, 29.0, 9, -0.05, 0.07],
		[5.49, 1.05, 0.40, 0.0, 7, 0.08, 0.03], [6.25, 1.35, 0.36, 23.0, 7, -0.07, -0.05],
	]},
	{"trunk": 4.5, "tiers": [
		[0.90, 1.40, 1.27, 38.0, 8, 0.00, 0.00], [1.64, 1.35, 0.95, 67.0, 9, 0.00, 0.00], [2.39, 1.30, 1.03, 9.0, 7, 0.06, -0.04],
		[3.13, 1.25, 0.84, 44.0, 8, -0.05, 0.07], [3.87, 1.20, 0.78, 29.0, 9, 0.08, 0.03], [4.62, 1.15, 0.61, 0.0, 7, -0.07, -0.05],
		[5.36, 1.10, 0.61, 23.0, 8, 0.04, 0.08], [6.11, 1.05, 0.43, 51.0, 9, -0.06, 0.02], [6.85, 1.35, 0.36, 14.0, 7, 0.05, -0.07],
	]},
	{"trunk": 4.8, "tiers": [
		[0.90, 1.40, 1.11, 67.0, 9, 0.00, 0.00], [1.71, 1.35, 1.21, 9.0, 7, -0.05, 0.07], [2.51, 1.30, 1.00, 44.0, 8, 0.08, 0.03],
		[3.32, 1.25, 0.94, 29.0, 9, -0.07, -0.05], [4.12, 1.20, 0.75, 0.0, 7, 0.04, 0.08], [4.93, 1.15, 0.77, 23.0, 8, -0.06, 0.02],
		[5.74, 1.10, 0.57, 51.0, 9, 0.05, -0.07], [6.54, 1.05, 0.53, 14.0, 7, 0.00, 0.05], [7.35, 1.35, 0.36, 38.0, 7, 0.00, 0.00],
	]},
]
## Variação de cada cartão do andar (sem sorteio): Vector2(desvio do ângulo em graus, multiplicador do alcance).
## O cartão i do andar t da conífera v usa a linha (3 i + 5 t + 7 v) % 13.
const CONIFER_CARD_VAR: Array[Vector2] = [
	Vector2(0.0, 1.0), Vector2(9.0, 0.86), Vector2(-7.0, 1.12), Vector2(4.0, 0.93), Vector2(-11.0, 1.05), Vector2(12.0, 0.82),
	Vector2(-3.0, 1.16), Vector2(7.0, 0.97), Vector2(-9.0, 0.88), Vector2(2.0, 1.09), Vector2(-5.0, 0.9), Vector2(10.0, 1.02),
	Vector2(-12.0, 0.95),
]

## Escala de cada conífera (as tabelas já estão na medida final).
const CONIFER_SCALE: Array = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0]

# ---------------------------------------------------------------- arbustos
## Lóbulos Vector4(x, y, z, raio) por arbusto; o último (d) é o florido.
const BUSHES: Array = [
	[Vector4(0.0, 0.3, 0.0, 0.4), Vector4(0.35, 0.25, 0.1, 0.3), Vector4(-0.3, 0.25, -0.1, 0.32)],
	[Vector4(0.0, 0.4, 0.0, 0.45), Vector4(0.4, 0.3, 0.15, 0.35), Vector4(-0.35, 0.3, -0.1, 0.36), Vector4(0.05, 0.3, 0.4, 0.3)],
	[Vector4(0.0, 0.5, 0.0, 0.5), Vector4(0.45, 0.35, 0.2, 0.38), Vector4(-0.4, 0.38, -0.1, 0.4), Vector4(0.1, 0.35, -0.42, 0.34),
		Vector4(0.0, 0.8, 0.05, 0.32)],
	[Vector4(0.0, 0.6, 0.0, 0.55), Vector4(0.5, 0.42, 0.2, 0.4), Vector4(-0.45, 0.45, -0.1, 0.42), Vector4(0.1, 0.4, -0.46, 0.36),
		Vector4(-0.1, 0.95, 0.1, 0.34)],
]

# ---------------------------------------------------------------- pedras
## Anéis de 6 pontos (multiplicadores de raio): base, meio, alto; e o ápice (x, altura relativa, z).
const ROCKS: Array = [
	{"rings": [[1.0, 0.9, 1.0, 0.85, 1.0, 0.95], [1.0, 0.8, 0.95, 1.0, 0.85, 0.9], [0.9, 1.0, 0.8, 0.95, 1.0, 0.85]], "apex": Vector3(0.1, 1.0, -0.05)},
	{"rings": [[0.95, 1.0, 0.85, 0.9, 1.0, 0.8], [0.9, 1.0, 1.0, 0.8, 0.95, 1.0], [1.0, 0.85, 0.9, 1.0, 0.8, 0.95]], "apex": Vector3(-0.15, 1.0, 0.1)},
	{"rings": [[1.0, 1.0, 0.8, 0.9, 0.95, 0.85], [0.85, 1.0, 0.95, 1.0, 0.8, 0.95], [0.95, 0.8, 1.0, 0.9, 1.0, 0.85]], "apex": Vector3(0.05, 1.0, 0.15)},
	{"rings": [[0.9, 0.95, 1.0, 0.85, 0.9, 1.0], [1.0, 0.85, 0.9, 1.0, 0.95, 0.8], [0.8, 1.0, 0.9, 0.85, 1.0, 0.95]], "apex": Vector3(-0.1, 1.0, -0.1)},
]

# ---------------------------------------------------------------- catálogo
## Entrada: name, build (nome do construtor), size (largura, altura, fundo) e opcionais variant,
## material, structural, obstacle, areas (HeightArea: [x, y, z, largura, fundo, topo]), stair ([y, largura, fundo, degraus]).
static func catalog() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	out.append(_e("step_low_2", "step_low", Vector3(2, 0.5, 1), {"structural": true, "areas": [[0, 0, 0, 2, 1, 0.5]]}))
	out.append(_e("step_low_1", "step_low", Vector3(1, 0.5, 1), {"structural": true, "areas": [[0, 0, 0, 1, 1, 0.5]]}))
	out.append(_e("step_low_corner", "step_low_corner", Vector3(1, 0.5, 1), {"structural": true, "areas": [[0, 0, 0, 1, 1, 0.5]]}))
	for fill: Vector2i in [Vector2i(4, 3), Vector2i(2, 3), Vector2i(1, 3), Vector2i(3, 3), Vector2i(4, 2), Vector2i(3, 2)]:
		out.append(_e("terrace_fill_%dx%d" % [fill.x, fill.y], "terrace", Vector3(fill.x, 0.5, fill.y),
				{"structural": true, "areas": [[0, 0, 0, fill.x, fill.y, 0.5]]}))
	out.append(_e("wall_high_2", "wall", Vector3(2, 1.0, 1), {"structural": true, "areas": [[0, 0, 0, 2, 1, 1.0]]}))
	out.append(_e("wall_high_1", "wall", Vector3(1, 1.0, 1), {"structural": true, "areas": [[0, 0, 0, 1, 1, 1.0]]}))
	out.append(_e("wall_high_corner", "wall_corner", Vector3(1, 1.0, 1), {"structural": true, "areas": [[0, 0, 0, 1, 1, 1.0]]}))
	out.append(_e("stair_outer_3", "stair_outer", Vector3(3, 1.0, 2), {"structural": true,
			"stair": [0.0, 2.0, 2.0, 4], "areas": [[-1.25, 0, 0, 0.5, 2, 1.0], [1.25, 0, 0, 0.5, 2, 1.0]]}))
	out.append(_e("stair_inner_3", "stair_inner", Vector3(3, 1.0, 1), {"structural": true,
			"stair": [0.5, 2.0, 1.0, 2], "areas": [[-1.25, 0, 0, 0.5, 1, 1.0], [1.25, 0, 0, 0.5, 1, 1.0]]}))
	out.append(_e("stair_low_3", "stair_low", Vector3(3, 0.5, 1), {"structural": true, "stair": [0.0, 3.0, 1.0, 2]}))
	# Passagens sul/norte (spec 012, decisão 2) e piso dos portões oeste/leste (item 3).
	out.append(_e("stair_crest_in_3", "stair_crest_in", Vector3(4, 1.0, 1), {"structural": true,
			"stair": [0.5, 3.0, 1.0, 2], "areas": [[-1.75, 0, 0, 0.5, 1, 1.0], [1.75, 0, 0, 0.5, 1, 1.0]]}))
	out.append(_e("stair_pass_out_3", "stair_pass_out", Vector3(3, 0.75, 2), {"structural": true, "stair": [0.0, 3.0, 1.5, 3, -0.25]}))
	out.append(_e("stair_crest_3", "stair_crest", Vector3(3, 1.0, 1), {"structural": true, "areas": [[0, 0, 0, 3, 1, 1.0]]}))
	out.append(_e("stair_landing_3", "stair_landing", Vector3(1, 0.5, 3), {"structural": true, "areas": [[0, 0, 0, 1, 3, 0.5]]}))
	out.append(_e("ground_inner", "ground", Vector3(20, 0, 18), {"material": "grass_painted_inner", "ao_inside": true}))
	out.append(_e("ground_outer", "ground", Vector3(48, 0, 48), {"material": "grass_painted"}))
	for decal_name: String in DECAL_SIZES.keys():
		var dsize: Vector2 = DECAL_SIZES[decal_name]
		out.append(_e(decal_name, "decal", Vector3(dsize.x, 0, dsize.y), {"material": decal_name}))
	# Árvores pintadas (spec 012): a largura da peça é a da copa (2 x raio) e a altura é a do topo.
	var broad_names: PackedStringArray = ["tree_broad_a", "tree_broad_b", "tree_broad_c", "tree_broad_d", "tree_broad_e",
			"tree_small_a", "tree_small_b", "tree_small_c"]
	for i in broad_names.size():
		var rb: float = snappedf(SceneryPieces.broad_crown_radius(i), 0.01)
		out.append(_e(broad_names[i], "broad", Vector3(2.0 * rb, snappedf(SceneryPieces.broad_height(i), 0.01), 2.0 * rb),
				{"variant": i, "obstacle": true}))
	for i in CONIFERS.size():
		var rc: float = snappedf(SceneryPieces.conifer_radius(i), 0.01)
		out.append(_e("conifer_%s" % "abcdef"[i], "conifer", Vector3(2.0 * rc, snappedf(SceneryPieces.conifer_height(i), 0.01), 2.0 * rc),
				{"variant": i, "obstacle": true}))
	var bush_h: Array[float] = [0.6, 0.8, 1.0, 1.2]
	for i in bush_h.size():
		out.append(_e("bush_%s" % "abcd"[i], "bush", Vector3(1.0 + 0.1 * i, bush_h[i], 1.0 + 0.1 * i), {"variant": i, "obstacle": true}))
	var logs: Array[Vector3] = [Vector3(2.4, 0.65, 0.7), Vector3(1.8, 0.55, 0.6), Vector3(3.0, 0.7, 0.7)]
	for i in logs.size():
		out.append(_e("log_%s" % "abc"[i], "log", logs[i], {"variant": i, "obstacle": true}))
	out.append(_e("stump_a", "stump", Vector3(0.7, 0.45, 0.7), {"variant": 0, "obstacle": true}))
	out.append(_e("stump_b", "stump", Vector3(0.6, 0.35, 0.6), {"variant": 1, "obstacle": true}))
	var rocks: Array[Vector3] = [Vector3(0.9, 0.6, 0.8), Vector3(1.2, 0.9, 1.0), Vector3(1.5, 1.1, 1.3), Vector3(0.7, 0.5, 0.7)]
	for i in rocks.size():
		out.append(_e("rock_%s" % "abcd"[i], "rock", rocks[i], {"variant": i, "obstacle": true}))
	out.append(_e("bench_wood", "bench", Vector3(2.0, 0.5, 0.6), {"obstacle": true}))
	out.append(_e("crate", "crate", Vector3(0.75, 0.75, 0.75), {"obstacle": true}))
	out.append(_e("crate_stack", "crate_stack", Vector3(1.0, 0.75, 1.0), {"obstacle": true}))
	out.append(_e("wood_pile", "wood_pile", Vector3(1.0, 0.9, 1.0), {"obstacle": true}))
	var cross_angles: Array[float] = [0.0, 20.0, 40.0, 10.0]
	for i in 4:
		out.append(_e("mushrooms_%s" % "abcd"[i], "cross", Vector3(0.5, 0.4, 0.5),
				{"material": "card_mushroom_%d" % i, "variant": int(cross_angles[i])}))
		out.append(_e("flowers_%s" % "abcd"[i], "cross", Vector3(0.5, 0.5, 0.5),
				{"material": "card_flower_%d" % i, "variant": int(cross_angles[(i + 1) % 4])}))
	var grass_cards: PackedStringArray = ["card_tall_grass_0", "card_tall_grass_1", "card_grass_tuft_2"]
	var grass_sizes: Array[Vector3] = [Vector3(0.8, 0.9, 0.8), Vector3(0.8, 0.9, 0.8), Vector3(0.8, 0.7, 0.8)]
	for i in grass_cards.size():
		out.append(_e("tall_grass_%s" % "abc"[i], "cross", grass_sizes[i], {"material": grass_cards[i], "variant": 15 * i}))
	out.append_array(SceneryPieces.catalog())
	return out


static func _e(entry_name: String, build: String, size: Vector3, extra: Dictionary = {}) -> Dictionary:
	var entry: Dictionary = extra.duplicate()
	entry["name"] = entry_name
	entry["build"] = build
	entry["size"] = size
	return entry
