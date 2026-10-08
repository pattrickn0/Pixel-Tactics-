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
			Vector4(-0.4, 3.35, 1.05, 0.58), Vector4(0.15, 3.4, -0.2, 0.65), Vector4(1.5, 3.5, 0.6, 0.5),
			Vector4(-1.2, 4.7, 0.9, 0.5)],
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

# ---------------------------------------------------------------- coníferas
## Padrões da borda de baixo de cada andar: pontas Vector2(multiplicador do raio, descida em fração da altura do andar).
const CONIFER_PATTERNS: Array = [
	[Vector2(1.0, 0.20), Vector2(0.84, 0.12), Vector2(0.96, 0.24), Vector2(0.78, 0.10), Vector2(1.0, 0.20),
		Vector2(0.86, 0.14), Vector2(0.94, 0.26), Vector2(0.80, 0.10), Vector2(0.98, 0.18)],
	[Vector2(0.94, 0.22), Vector2(1.0, 0.16), Vector2(0.80, 0.10), Vector2(0.98, 0.26), Vector2(0.86, 0.12),
		Vector2(1.0, 0.20), Vector2(0.82, 0.14), Vector2(0.96, 0.24), Vector2(0.88, 0.10), Vector2(1.0, 0.18)],
	[Vector2(1.0, 0.18), Vector2(0.82, 0.12), Vector2(0.94, 0.24), Vector2(0.86, 0.10), Vector2(1.0, 0.22),
		Vector2(0.80, 0.14), Vector2(0.96, 0.20), Vector2(0.84, 0.10), Vector2(1.0, 0.26), Vector2(0.88, 0.14),
		Vector2(0.92, 0.20)],
]
## Cada conífera: altura do tronco, andares [y da base, altura, raio embaixo, raio em cima, giro em graus, padrão].
const CONIFERS: Array = [
	{"trunk": 0.8, "tiers": [[0.7, 1.25, 1.1, 0.5, 0.0, 0], [1.4, 1.15, 0.92, 0.42, 24.0, 1], [2.05, 1.05, 0.74, 0.34, 48.0, 2],
		[2.7, 1.0, 0.55, 0.24, 12.0, 0], [3.3, 1.2, 0.38, 0.0, 36.0, 1]]},
	{"trunk": 0.9, "tiers": [[0.8, 1.2, 1.2, 0.55, 0.0, 1], [1.5, 1.15, 1.02, 0.47, 18.0, 2], [2.15, 1.1, 0.86, 0.4, 40.0, 0],
		[2.8, 1.05, 0.7, 0.32, 8.0, 1], [3.4, 1.0, 0.54, 0.24, 28.0, 2], [3.95, 1.25, 0.38, 0.0, 50.0, 0]]},
	{"trunk": 1.0, "tiers": [[0.9, 1.25, 1.3, 0.6, 0.0, 2], [1.65, 1.2, 1.12, 0.5, 22.0, 0], [2.35, 1.15, 0.96, 0.44, 44.0, 1],
		[3.0, 1.1, 0.8, 0.36, 10.0, 2], [3.65, 1.05, 0.64, 0.28, 32.0, 0], [4.25, 1.0, 0.48, 0.2, 54.0, 1], [4.8, 1.0, 0.3, 0.0, 16.0, 2]]},
	{"trunk": 1.1, "tiers": [[1.0, 1.3, 1.4, 0.65, 0.0, 0], [1.8, 1.25, 1.22, 0.55, 26.0, 1], [2.55, 1.2, 1.06, 0.48, 50.0, 2],
		[3.25, 1.15, 0.9, 0.4, 14.0, 0], [3.9, 1.1, 0.74, 0.32, 38.0, 1], [4.5, 1.05, 0.58, 0.24, 62.0, 2], [5.1, 1.4, 0.4, 0.0, 20.0, 0]]},
	{"trunk": 1.1, "tiers": [[1.0, 1.3, 1.5, 0.7, 0.0, 1], [1.75, 1.25, 1.32, 0.6, 28.0, 2], [2.45, 1.2, 1.15, 0.52, 54.0, 0],
		[3.1, 1.15, 0.98, 0.44, 12.0, 1], [3.7, 1.1, 0.82, 0.36, 40.0, 2], [4.3, 1.05, 0.66, 0.28, 66.0, 0],
		[4.85, 1.0, 0.5, 0.2, 22.0, 1], [5.4, 1.6, 0.34, 0.0, 48.0, 2]]},
	{"trunk": 1.2, "tiers": [[1.1, 1.35, 1.7, 0.8, 0.0, 2], [1.9, 1.3, 1.5, 0.7, 30.0, 0], [2.65, 1.25, 1.3, 0.6, 56.0, 1],
		[3.35, 1.2, 1.12, 0.52, 14.0, 2], [4.0, 1.15, 0.95, 0.44, 42.0, 0], [4.6, 1.1, 0.78, 0.36, 68.0, 1],
		[5.2, 1.05, 0.62, 0.28, 24.0, 2], [5.75, 1.0, 0.46, 0.2, 50.0, 0], [6.3, 1.2, 0.3, 0.0, 6.0, 1]]},
]

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

# ---------------------------------------------------------------- fundo de mata
## Fundo de mata: por aglomerado, itens [tipo (b = folhosa, c = conífera), variante, x, z, giro em graus, escala].
const BACKDROPS: Array = [
	[["c", 3, -3.0, -2.5, 0.0, 1.0], ["b", 2, -0.5, -3.0, 40.0, 1.0], ["c", 4, 2.5, -2.0, 90.0, 0.95], ["b", 5, -2.0, 0.5, 130.0, 0.9],
		["c", 2, 1.0, 0.5, 20.0, 1.0], ["b", 1, 3.0, 2.5, 200.0, 0.9], ["c", 1, -3.0, 3.0, 60.0, 0.95], ["b", 6, 0.0, 3.5, 310.0, 1.0]],
	[["b", 0, -3.5, -3.0, 10.0, 1.0], ["c", 5, -1.0, -2.5, 0.0, 0.95], ["b", 7, 2.0, -3.2, 75.0, 1.0], ["c", 3, 3.5, -0.5, 150.0, 1.0],
		["c", 2, -2.5, 0.0, 30.0, 1.0], ["b", 3, 0.5, 0.8, 250.0, 0.9], ["b", 5, -3.0, 3.2, 100.0, 1.0], ["c", 4, 2.0, 3.0, 45.0, 0.95],
		["c", 5, 0.0, -0.2, 180.0, 1.0]],
	[["c", 4, -3.0, -3.0, 0.0, 1.0], ["c", 5, 0.0, -3.5, 120.0, 1.0], ["b", 4, 3.0, -3.0, 20.0, 0.95], ["b", 6, -3.5, 0.0, 215.0, 1.0],
		["c", 2, -1.0, -0.5, 60.0, 1.0], ["b", 1, 1.5, 0.0, 300.0, 0.95], ["c", 3, 3.5, 1.5, 15.0, 1.0], ["c", 1, -2.0, 3.0, 90.0, 0.95],
		["b", 7, 1.0, 3.2, 170.0, 1.0], ["c", 5, 3.5, 3.8, 240.0, 1.0]],
	# d: só coníferas altas (mata do fundo, some na névoa).
	[["c", 3, -3.2, -3.0, 0.0, 1.0], ["c", 5, -0.6, -3.4, 40.0, 1.0], ["c", 2, 2.8, -2.8, 80.0, 0.95], ["c", 4, -2.2, -0.2, 20.0, 1.0],
		["c", 1, 0.8, 0.0, 60.0, 1.0], ["c", 5, 3.4, 0.4, 100.0, 1.0], ["c", 3, -3.4, 2.6, 10.0, 0.95], ["c", 0, -0.8, 2.9, 30.0, 1.0],
		["c", 4, 2.4, 3.3, 70.0, 1.0]],
	# e: coníferas com folhosas pequenas no meio.
	[["c", 5, -3.0, -3.2, 15.0, 1.0], ["c", 3, 0.2, -3.0, 55.0, 1.0], ["b", 6, 3.0, -2.6, 95.0, 1.0], ["c", 4, -2.6, 0.2, 135.0, 1.0],
		["b", 5, 0.4, 0.4, 25.0, 1.0], ["c", 2, 3.2, 1.0, 65.0, 1.0], ["c", 4, -3.0, 3.2, 105.0, 0.95], ["c", 5, 0.0, 3.3, 145.0, 1.0],
		["b", 7, 3.0, 3.4, 35.0, 0.95]],
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
	out.append(_e("ground_inner", "ground", Vector3(20, 0, 18), {"material": "ground_grass_arena"}))
	out.append(_e("ground_outer", "ground", Vector3(48, 0, 48), {"material": "ground_grass_forest"}))
	out.append(_e("ground_far", "ground", Vector3(240, 0, 240), {"material": "ground_grass_forest"}))
	for decal_name: String in DECAL_SIZES.keys():
		var dsize: Vector2 = DECAL_SIZES[decal_name]
		out.append(_e(decal_name, "decal", Vector3(dsize.x, 0, dsize.y), {"material": decal_name}))
	var broad_names: PackedStringArray = ["tree_broad_a", "tree_broad_b", "tree_broad_c", "tree_broad_d", "tree_broad_e",
			"tree_small_a", "tree_small_b", "tree_small_c"]
	var broad_sizes: Array[Vector3] = [Vector3(3.2, 4.0, 3.2), Vector3(3.6, 4.6, 3.6), Vector3(3.8, 5.0, 3.8), Vector3(4.2, 5.5, 4.2),
			Vector3(4.4, 6.0, 4.4), Vector3(2.0, 2.4, 2.0), Vector3(2.4, 2.9, 2.4), Vector3(2.8, 3.5, 2.8)]
	for i in broad_names.size():
		out.append(_e(broad_names[i], "broad", broad_sizes[i], {"variant": i, "obstacle": true}))
	var conifer_sizes: Array[Vector3] = [Vector3(2.2, 4.5, 2.2), Vector3(2.4, 5.2, 2.4), Vector3(2.6, 5.8, 2.6),
			Vector3(2.8, 6.5, 2.8), Vector3(3.0, 7.0, 3.0), Vector3(3.4, 7.5, 3.4)]
	for i in conifer_sizes.size():
		out.append(_e("conifer_%s" % "abcdef"[i], "conifer", conifer_sizes[i], {"variant": i, "obstacle": true}))
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
	for i in BACKDROPS.size():
		out.append(_e("forest_backdrop_%s" % "abcde"[i], "backdrop", Vector3(8, 7.5, 8), {"variant": i, "obstacle": true}))
	return out


static func _e(entry_name: String, build: String, size: Vector3, extra: Dictionary = {}) -> Dictionary:
	var entry: Dictionary = extra.duplicate()
	entry["name"] = entry_name
	entry["build"] = build
	entry["size"] = size
	return entry
