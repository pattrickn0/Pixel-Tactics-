class_name IslandTables
extends RefCounted
## Tabelas LITERAIS da ilha flutuante e do que fica fora dela (spec 012, Fase 1). Feitas à mão a partir
## das medidas da referência docs/reference/ilha-flutuante.webp (Tabelas A e D da spec): nada aqui é
## sorteado nem calculado em tempo de build além de aritmética sobre estes números.
## Coordenadas do mundo: origem no centro da arena, X para leste, Z para o sul (Vector2(x, z)).

# ---------------------------------------------------------------- ilha principal
## Contorno da ilha (Tabela A): 86 vértices, arestas <= 3, passa a <= 0,75 de cada âncora.
const ISLAND_OUTLINE: PackedVector2Array = [
	Vector2(0.0, 18.5), Vector2(1.47, 18.32), Vector2(2.45, 17.79), Vector2(4.78, 17.05), Vector2(7.25, 17.15), Vector2(8.5, 16.16),
	Vector2(9.67, 16.2), Vector2(11.15, 16.08), Vector2(12.32, 15.87), Vector2(13.4, 14.52), Vector2(14.47, 13.95), Vector2(16.0, 13.12),
	Vector2(16.48, 11.86), Vector2(17.41, 10.01), Vector2(18.5, 8.8), Vector2(19.72, 7.01), Vector2(20.29, 5.37), Vector2(21.15, 3.42),
	Vector2(22.63, 2.38), Vector2(24.04, 0.5), Vector2(24.76, -1.23), Vector2(25.87, -3.33), Vector2(26.9, -4.9), Vector2(28.11, -7.34),
	Vector2(28.49, -9.45), Vector2(28.52, -12.26), Vector2(29.15, -14.34), Vector2(30.18, -16.59), Vector2(30.75, -18.45), Vector2(30.28, -20.91),
	Vector2(30.91, -22.66), Vector2(29.23, -24.12), Vector2(27.55, -24.9), Vector2(25.01, -24.07), Vector2(23.02, -23.9), Vector2(20.72, -24.17),
	Vector2(18.98, -23.7), Vector2(16.86, -22.63), Vector2(15.0, -22.6), Vector2(12.99, -22.3), Vector2(11.98, -21.59), Vector2(10.05, -21.15),
	Vector2(7.89, -21.62), Vector2(6.82, -20.77), Vector2(4.78, -20.85), Vector2(2.27, -20.65), Vector2(0.3, -20.35), Vector2(-2.31, -20.02),
	Vector2(-4.3, -20.7), Vector2(-6.88, -21.5), Vector2(-8.95, -21.79), Vector2(-11.72, -22.21), Vector2(-13.82, -22.75), Vector2(-16.18, -23.18),
	Vector2(-18.06, -22.84), Vector2(-20.1, -21.27), Vector2(-21.95, -20.72), Vector2(-23.83, -19.39), Vector2(-25.24, -18.18), Vector2(-25.56, -15.81),
	Vector2(-26.6, -14.49), Vector2(-26.68, -12.43), Vector2(-25.76, -11.48), Vector2(-25.6, -9.47), Vector2(-25.08, -7.22), Vector2(-23.93, -6.25),
	Vector2(-23.6, -4.0), Vector2(-23.04, -2.36), Vector2(-22.07, -1.31), Vector2(-21.26, 0.3), Vector2(-21.04, 1.76), Vector2(-20.76, 3.6),
	Vector2(-19.75, 4.78), Vector2(-19.0, 6.41), Vector2(-18.7, 7.8), Vector2(-17.85, 9.27), Vector2(-17.16, 10.42), Vector2(-15.38, 12.01),
	Vector2(-14.76, 13.89), Vector2(-12.36, 14.61), Vector2(-10.6, 14.74), Vector2(-9.59, 15.99), Vector2(-8.07, 16.44), Vector2(-6.75, 16.31),
	Vector2(-4.43, 17.1), Vector2(-2.2, 17.7),
]

## Faixas do penhasco em blocos: [y de cima, y de baixo].
const CLIFF_BANDS: Array = [[0.0, -0.8], [-0.8, -1.7], [-1.7, -2.6], [-2.6, -3.5]]
## Recuo (para dentro, em unidades) de cada faixa em cada vértice do contorno: Vector4(faixa 0, 1, 2, 3).
## Corridas de vértices com o mesmo recuo formam os blocos; a diferença entre faixas é o degrau.
const CLIFF_INSETS: Array = [
	Vector4(0.0, 0.35, 1.0, 0.9), Vector4(0.0, 0.35, 1.0, 0.9), Vector4(0.0, 0.35, 1.0, 0.9), Vector4(0.0, 0.7, 0.45, 1.8), Vector4(0.0, 0.7, 0.45, 1.8),
	Vector4(0.0, 0.2, 0.8, 1.1), Vector4(0.0, 0.2, 0.8, 1.1), Vector4(0.0, 0.2, 0.8, 1.1), Vector4(0.0, 0.2, 0.8, 1.1), Vector4(0.0, 0.9, 0.3, 1.2),
	Vector4(0.0, 0.9, 0.3, 1.2), Vector4(0.0, 0.9, 0.3, 1.2), Vector4(0.0, 0.5, 1.1, 0.8), Vector4(0.0, 0.5, 1.1, 0.8), Vector4(0.0, 0.3, 0.55, 1.6),
	Vector4(0.0, 0.3, 0.55, 1.6), Vector4(0.0, 0.3, 0.55, 1.6), Vector4(0.0, 0.3, 0.55, 1.6), Vector4(0.0, 0.3, 0.55, 1.6), Vector4(0.0, 0.8, 0.9, 1.0),
	Vector4(0.0, 0.8, 0.9, 1.0), Vector4(0.0, 0.45, 0.6, 1.4), Vector4(0.0, 0.45, 0.6, 1.4), Vector4(0.0, 0.45, 0.6, 1.4), Vector4(0.0, 0.35, 0.25, 0.9),
	Vector4(0.0, 0.35, 0.25, 0.9), Vector4(0.0, 0.35, 0.25, 0.9), Vector4(0.0, 0.35, 0.25, 0.9), Vector4(0.0, 0.7, 1.0, 1.8), Vector4(0.0, 0.7, 1.0, 1.8),
	Vector4(0.0, 0.2, 0.45, 1.1), Vector4(0.0, 0.2, 0.45, 1.1), Vector4(0.0, 0.2, 0.45, 1.1), Vector4(0.0, 0.9, 0.8, 1.2), Vector4(0.0, 0.9, 0.8, 1.2),
	Vector4(0.0, 0.5, 0.3, 0.8), Vector4(0.0, 0.5, 0.3, 0.8), Vector4(0.0, 0.5, 0.3, 0.8), Vector4(0.0, 0.5, 0.3, 0.8), Vector4(0.0, 0.3, 1.1, 1.6),
	Vector4(0.0, 0.3, 1.1, 1.6), Vector4(0.0, 0.3, 1.1, 1.6), Vector4(0.0, 0.8, 0.55, 1.0), Vector4(0.0, 0.8, 0.55, 1.0), Vector4(0.0, 0.45, 0.9, 1.4),
	Vector4(0.0, 0.45, 0.9, 1.4), Vector4(0.0, 0.45, 0.9, 1.4), Vector4(0.0, 0.45, 0.9, 1.4), Vector4(0.0, 0.45, 0.9, 1.4), Vector4(0.0, 0.35, 0.6, 0.9),
	Vector4(0.0, 0.35, 0.6, 0.9), Vector4(0.0, 0.7, 0.25, 1.8), Vector4(0.0, 0.7, 0.25, 1.8), Vector4(0.0, 0.7, 0.25, 1.8), Vector4(0.0, 0.2, 1.0, 1.1),
	Vector4(0.0, 0.2, 1.0, 1.1), Vector4(0.0, 0.2, 1.0, 1.1), Vector4(0.0, 0.2, 1.0, 1.1), Vector4(0.0, 0.9, 0.45, 1.2), Vector4(0.0, 0.9, 0.45, 1.2),
	Vector4(0.0, 0.5, 0.8, 0.8), Vector4(0.0, 0.5, 0.8, 0.8), Vector4(0.0, 0.5, 0.8, 0.8), Vector4(0.0, 0.3, 0.3, 1.6), Vector4(0.0, 0.3, 0.3, 1.6),
	Vector4(0.0, 0.8, 1.1, 1.0), Vector4(0.0, 0.8, 1.1, 1.0), Vector4(0.0, 0.8, 1.1, 1.0), Vector4(0.0, 0.8, 1.1, 1.0), Vector4(0.0, 0.45, 0.55, 1.4),
	Vector4(0.0, 0.45, 0.55, 1.4), Vector4(0.0, 0.45, 0.55, 1.4), Vector4(0.0, 0.35, 0.9, 0.9), Vector4(0.0, 0.35, 0.9, 0.9), Vector4(0.0, 0.7, 0.6, 1.8),
	Vector4(0.0, 0.7, 0.6, 1.8), Vector4(0.0, 0.7, 0.6, 1.8), Vector4(0.0, 0.7, 0.6, 1.8), Vector4(0.0, 0.7, 0.6, 1.8), Vector4(0.0, 0.2, 0.25, 1.1),
	Vector4(0.0, 0.2, 0.25, 1.1), Vector4(0.0, 0.9, 1.0, 1.2), Vector4(0.0, 0.9, 1.0, 1.2), Vector4(0.0, 0.9, 1.0, 1.2), Vector4(0.0, 0.5, 0.45, 0.8),
	Vector4(0.0, 0.5, 0.45, 0.8),
]

## Fundo cônico: anéis literais [y, pontos (x, z)] abaixo do penhasco, e o ápice irregular.
const UNDER_RINGS: Array = [
	[-5.0, [
		Vector2(0.1, 16.45), Vector2(3.88, 16.41), Vector2(6.99, 13.86), Vector2(11.88, 15.57), Vector2(12.92, 10.79), Vector2(16.45, 9.15),
		Vector2(17.51, 5.39), Vector2(21.15, 2.69), Vector2(20.83, -0.69), Vector2(24.34, -4.0), Vector2(25.5, -7.39), Vector2(27.25, -11.73),
		Vector2(25.78, -14.11), Vector2(29.85, -19.89), Vector2(24.71, -20.03), Vector2(24.2, -22.9), Vector2(18.99, -21.26), Vector2(16.99, -22.23),
		Vector2(11.55, -19.23), Vector2(8.83, -19.68), Vector2(5.16, -18.94), Vector2(1.39, -19.67), Vector2(-2.22, -17.54), Vector2(-6.66, -21.11),
		Vector2(-8.93, -18.64), Vector2(-14.1, -21.65), Vector2(-16.51, -19.52), Vector2(-21.89, -19.47), Vector2(-21.32, -14.79), Vector2(-24.38, -12.33),
		Vector2(-22.92, -8.65), Vector2(-22.71, -5.58), Vector2(-19.13, -1.85), Vector2(-20.58, 1.94), Vector2(-15.81, 4.43), Vector2(-16.45, 8.88),
		Vector2(-13.05, 10.99), Vector2(-11.22, 14.04), Vector2(-6.71, 13.59), Vector2(-3.62, 15.63),
	]],
	[-7.0, [
		Vector2(1.32, 14.38), Vector2(5.19, 11.81), Vector2(10.18, 12.84), Vector2(11.67, 8.09), Vector2(15.43, 5.67), Vector2(16.43, 1.59),
		Vector2(20.54, -1.78), Vector2(20.13, -5.33), Vector2(22.33, -9.91), Vector2(23.39, -13.77), Vector2(24.92, -18.79), Vector2(18.9, -18.12),
		Vector2(16.92, -20.25), Vector2(10.7, -16.39), Vector2(7.74, -17.23), Vector2(3.37, -15.86), Vector2(-0.95, -16.75), Vector2(-4.58, -15.91),
		Vector2(-9.37, -17.8), Vector2(-13.38, -17.86), Vector2(-18.15, -16.62), Vector2(-18.22, -11.92), Vector2(-21.12, -9.29), Vector2(-16.38, -4.62),
		Vector2(-16.98, -0.95), Vector2(-14.45, 2.82), Vector2(-14.16, 7.45), Vector2(-10.02, 9.42), Vector2(-7.12, 11.97), Vector2(-2.82, 12.6),
	]],
	[-9.5, [
		Vector2(0.83, 9.64), Vector2(5.22, 10.42), Vector2(7.92, 7.08), Vector2(11.59, 5.1), Vector2(12.84, 1.07), Vector2(16.64, -2.23),
		Vector2(16.43, -5.77), Vector2(18.56, -10.27), Vector2(18.86, -14.16), Vector2(16.34, -16.06), Vector2(10.82, -14.15), Vector2(7.93, -14.75),
		Vector2(3.16, -12.4), Vector2(-0.93, -13.26), Vector2(-4.76, -13.51), Vector2(-9.8, -15.56), Vector2(-12.08, -12.46), Vector2(-15.56, -10.07),
		Vector2(-14.85, -6.02), Vector2(-14.28, -2.22), Vector2(-11.21, 1.42), Vector2(-10.95, 6.0), Vector2(-6.39, 7.16), Vector2(-3.4, 9.58),
	]],
	[-12.0, [
		Vector2(2.02, 7.39), Vector2(5.49, 5.25), Vector2(8.84, 3.13), Vector2(10.49, -0.48), Vector2(13.6, -4.19), Vector2(12.91, -7.68),
		Vector2(13.69, -11.91), Vector2(9.46, -11.7), Vector2(5.83, -11.07), Vector2(1.56, -9.8), Vector2(-2.74, -11.34), Vector2(-5.91, -10.56),
		Vector2(-10.56, -9.79), Vector2(-10.4, -5.76), Vector2(-10.23, -2.08), Vector2(-7.31, 1.39), Vector2(-5.92, 5.18), Vector2(-2.0, 6.2),
	]],
	[-14.5, [
		Vector2(1.28, 3.52), Vector2(5.3, 2.92), Vector2(7.26, -0.7), Vector2(9.83, -4.59), Vector2(9.22, -8.01), Vector2(5.89, -8.33),
		Vector2(1.75, -7.62), Vector2(-2.59, -8.36), Vector2(-5.94, -7.05), Vector2(-7.54, -3.74), Vector2(-4.68, -0.03), Vector2(-2.74, 3.21),
	]],
	[-17.0, [
		Vector2(1.9, 1.38), Vector2(4.24, -0.93), Vector2(6.11, -4.22), Vector2(3.96, -5.49), Vector2(0.71, -5.16), Vector2(-2.72, -5.24),
		Vector2(-3.41, -2.3), Vector2(-1.38, 0.62),
	]],
	[-19.0, [
		Vector2(1.04, -0.63), Vector2(2.81, -2.0), Vector2(2.25, -3.45), Vector2(0.03, -3.46), Vector2(-0.58, -1.89),
	]],
]
const UNDER_APEX: Vector3 = Vector3(1.6, -20.6, -1.3)
## Esporões pendurados no fundo: [centro (x, y, z), raio, ponta (x, y, z)].
const UNDER_SPURS: Array = [
	[Vector3(-13.0, -7.5, 5.0), 2.0, Vector3(-13.6, -14.5, 5.6)],
	[Vector3(12.5, -8.0, 7.0), 1.7, Vector3(13.2, -13.8, 7.8)],
	[Vector3(-3.0, -10.0, -12.0), 2.2, Vector3(-3.4, -17.0, -12.6)],
]

# ---------------------------------------------------------------- raízes e cipós (peças pequenas)
## Raízes pendentes: cadeias Vector4(x, y, z, raio) a partir da borda (pivô no topo da borda, +Z para fora).
const ROOTS: Array = [
	[[Vector4(0.0, -0.2, -0.35, 0.17), Vector4(0.1, -0.75, 0.12, 0.15), Vector4(0.32, -1.45, 0.38, 0.13),
		Vector4(0.22, -2.25, 0.52, 0.11), Vector4(-0.08, -3.0, 0.58, 0.09), Vector4(-0.3, -3.8, 0.5, 0.07), Vector4(-0.18, -4.6, 0.44, 0.05)],
		[Vector4(0.3, -1.45, 0.38, 0.08), Vector4(0.75, -1.9, 0.6, 0.065), Vector4(0.95, -2.6, 0.66, 0.05), Vector4(0.85, -3.2, 0.6, 0.035)]],
	[[Vector4(0.0, -0.15, -0.3, 0.2), Vector4(-0.15, -0.6, 0.2, 0.18), Vector4(-0.45, -1.1, 0.55, 0.15), Vector4(-0.6, -1.9, 0.72, 0.12),
		Vector4(-0.4, -2.7, 0.78, 0.1), Vector4(0.05, -3.3, 0.7, 0.08), Vector4(0.4, -3.9, 0.62, 0.06), Vector4(0.42, -4.7, 0.6, 0.045),
		Vector4(0.2, -5.5, 0.58, 0.03)],
		[Vector4(-0.55, -1.6, 0.68, 0.08), Vector4(-1.0, -2.1, 0.75, 0.06), Vector4(-1.25, -2.9, 0.7, 0.045)]],
	[[Vector4(0.0, -0.25, -0.3, 0.14), Vector4(0.2, -0.7, 0.15, 0.12), Vector4(0.15, -1.3, 0.42, 0.1), Vector4(-0.1, -1.9, 0.5, 0.08),
		Vector4(-0.05, -2.6, 0.46, 0.06), Vector4(0.15, -3.1, 0.4, 0.04)]],
]
## Cipós pendentes: pontos Vector3 (pivô no topo); cada ponto leva 2 cartões de folha cruzados.
const VINES: Array = [
	[Vector3(0.0, 0.0, 0.1), Vector3(0.05, -0.45, 0.22), Vector3(0.0, -0.9, 0.3), Vector3(-0.08, -1.35, 0.32), Vector3(-0.05, -1.8, 0.3),
		Vector3(0.05, -2.25, 0.27), Vector3(0.1, -2.7, 0.25), Vector3(0.05, -3.15, 0.24)],
	[Vector3(0.0, 0.0, 0.1), Vector3(-0.06, -0.5, 0.2), Vector3(-0.1, -1.0, 0.28), Vector3(-0.02, -1.5, 0.3), Vector3(0.1, -2.0, 0.28)],
]

# ---------------------------------------------------------------- fora da ilha (Tabela D)
## Massas de rocha (ilha alta, ilhotas, rochas): topo literal (x, z locais), faixas [y0, y1, recuo],
## "jog" = recuo extra por vértice (ciclo), anéis literais do fundo e ápice. y relativo a top_y.
const HIGH_ISLAND: Dictionary = {
	"top": [
		Vector2(-12.6, -56.9), Vector2(-10.6, -56.2), Vector2(-9.0, -56.8), Vector2(-6.8, -56.8), Vector2(-5.0, -56.3), Vector2(-3.3, -56.8),
		Vector2(0.0, -56.9), Vector2(3.0, -56.8), Vector2(5.6, -56.8), Vector2(7.6, -56.4), Vector2(9.8, -56.3), Vector2(11.5, -56.8),
		Vector2(13.0, -56.9), Vector2(14.1, -56.8), Vector2(16.4, -56.0), Vector2(18.7, -56.5), Vector2(20.6, -57.6), Vector2(22.4, -60.4),
		Vector2(23.1, -63.8), Vector2(21.9, -67.2), Vector2(19.2, -69.8), Vector2(15.0, -71.2), Vector2(10.0, -71.9), Vector2(5.2, -72.5),
		Vector2(0.3, -71.8), Vector2(-4.6, -71.0), Vector2(-8.8, -69.4), Vector2(-12.0, -66.6), Vector2(-13.6, -63.0), Vector2(-13.9, -59.4),
	],
	"top_y": 0.0,
	"bands": [[0.0, -1.0, 0.0], [-1.0, -2.6, 0.5], [-2.6, -4.2, 1.1], [-4.2, -6.0, 1.8]],
	"jog": [0.0, 0.35, -0.2, 0.5, 0.1, -0.3, 0.25, 0.6, -0.1],
	"rings": [
		[-7.4, [
			Vector2(-9.28, -58.32), Vector2(-7.13, -57.83), Vector2(-2.95, -58.26), Vector2(-0.85, -57.71), Vector2(2.76, -58.72), Vector2(5.78, -57.87),
			Vector2(8.53, -58.11), Vector2(12.34, -57.81), Vector2(13.9, -58.2), Vector2(17.77, -58.87), Vector2(18.83, -61.66), Vector2(20.05, -64.67),
			Vector2(16.78, -67.06), Vector2(16.27, -69.47), Vector2(11.57, -69.37), Vector2(9.46, -70.58), Vector2(6.09, -70.38), Vector2(3.08, -71.06),
			Vector2(0.39, -69.66), Vector2(-3.1, -69.76), Vector2(-5.75, -68.51), Vector2(-8.99, -66.84), Vector2(-8.87, -64.08), Vector2(-11.68, -60.83),
		]],
		[-10.5, [
			Vector2(-6.11, -58.73), Vector2(-1.64, -59.75), Vector2(0.81, -59.36), Vector2(4.11, -59.71), Vector2(7.51, -58.86), Vector2(9.91, -59.82),
			Vector2(13.64, -59.36), Vector2(15.41, -61.79), Vector2(16.31, -64.9), Vector2(13.11, -67.13), Vector2(11.46, -68.92), Vector2(7.37, -68.51),
			Vector2(4.55, -69.5), Vector2(1.5, -68.59), Vector2(-2.15, -68.54), Vector2(-3.91, -66.65), Vector2(-6.75, -64.45), Vector2(-7.08, -61.39),
		]],
		[-13.5, [
			Vector2(-1.29, -60.82), Vector2(1.23, -60.45), Vector2(4.42, -60.92), Vector2(7.51, -60.58), Vector2(10.34, -60.46), Vector2(13.06, -62.27),
			Vector2(11.8, -65.2), Vector2(10.56, -67.31), Vector2(6.78, -67.31), Vector2(4.04, -68.03), Vector2(1.17, -67.25), Vector2(-2.28, -66.71),
			Vector2(-3.21, -64.28), Vector2(-4.24, -61.35),
		]],
		[-16.5, [
			Vector2(-0.84, -61.7), Vector2(1.96, -61.84), Vector2(4.76, -61.64), Vector2(7.2, -61.85), Vector2(10.08, -62.87), Vector2(8.49, -65.32),
			Vector2(6.45, -66.41), Vector2(3.62, -66.34), Vector2(0.67, -66.06), Vector2(-0.71, -64.16),
		]],
		[-19.5, [
			Vector2(2.41, -62.91), Vector2(4.42, -62.7), Vector2(6.23, -62.93), Vector2(6.89, -64.65), Vector2(4.79, -65.23), Vector2(2.65, -65.23),
			Vector2(1.4, -63.9),
		]],
	],
	"apex": Vector3(4.0, -22.0, -64.0),
}
const HIGH_SPUR: Dictionary = {
	"top": [
		Vector2(-2.9, -0.2), Vector2(-2.2, -1.4), Vector2(-0.6, -1.9), Vector2(1.2, -1.6), Vector2(2.7, -0.8), Vector2(2.9, 0.6),
		Vector2(1.6, 1.5), Vector2(-0.4, 1.6), Vector2(-2.2, 1.1),
	],
	"top_y": 0.0,
	"bands": [[0.0, -2.5, 0.0], [-2.5, -6.0, 0.35], [-6.0, -9.5, 0.7], [-9.5, -12.5, 1.1]],
	"jog": [0.0, 0.2, -0.15, 0.3, 0.05],
	"rings": [
		[-14.0, [
			Vector2(-1.22, -0.08), Vector2(-0.67, -0.73), Vector2(0.23, -0.67), Vector2(1.17, -0.41), Vector2(0.95, 0.35), Vector2(0.23, 0.69),
			Vector2(-0.63, 0.51),
		]],
	],
	"apex": Vector3(0.3, -16.5, -0.4),
}
const HIGH_BLOCK: Dictionary = {
	"top": [
		Vector2(-1.8, -0.4), Vector2(-1.2, -1.3), Vector2(0.3, -1.6), Vector2(1.6, -1.0), Vector2(1.9, 0.3), Vector2(1.1, 1.2),
		Vector2(-0.5, 1.3), Vector2(-1.6, 0.7),
	],
	"top_y": 0.0,
	"bands": [[0.0, -2.0, 0.0], [-2.0, -4.8, 0.3], [-4.8, -7.5, 0.65]],
	"jog": [0.0, 0.15, -0.1, 0.25],
	"rings": [
		[-9.5, [
			Vector2(-0.81, -0.18), Vector2(-0.26, -0.69), Vector2(0.48, -0.52), Vector2(0.93, 0.1), Vector2(0.27, 0.51), Vector2(-0.49, 0.48),
		]],
	],
	"apex": Vector3(0.1, -11.5, -0.2),
}
const ISLET_RUINS: Dictionary = {
	"top": [
		Vector2(-8.6, -1.2), Vector2(-7.4, -4.6), Vector2(-4.8, -7.4), Vector2(-1.2, -8.8), Vector2(2.6, -8.4), Vector2(5.9, -6.7),
		Vector2(8.2, -3.6), Vector2(8.9, 0.2), Vector2(8.0, 3.9), Vector2(5.6, 6.6), Vector2(2.2, 8.2), Vector2(-1.6, 8.6),
		Vector2(-5.0, 7.3), Vector2(-7.6, 4.6), Vector2(-8.9, 1.9),
	],
	"top_y": 0.0,
	"bands": [[0.0, -0.9, 0.0], [-0.9, -2.2, 0.5], [-2.2, -3.6, 1.2]],
	"jog": [0.0, 0.3, -0.2, 0.45, 0.1, -0.25],
	"rings": [
		[-5.0, [
			Vector2(-5.68, -0.79), Vector2(-4.75, -3.76), Vector2(-1.97, -4.98), Vector2(0.91, -6.2), Vector2(3.33, -4.2), Vector2(5.71, -2.32),
			Vector2(5.49, 0.73), Vector2(4.87, 3.72), Vector2(1.92, 4.76), Vector2(-0.91, 5.83), Vector2(-3.61, 4.49), Vector2(-5.83, 2.28),
		]],
		[-7.0, [
			Vector2(-3.63, -1.54), Vector2(-1.51, -2.99), Vector2(0.88, -3.73), Vector2(2.81, -2.12), Vector2(4.02, 0.17), Vector2(2.48, 2.25),
			Vector2(0.42, 3.6), Vector2(-2.06, 3.08), Vector2(-3.86, 1.15),
		]],
		[-8.8, [
			Vector2(-1.0, -1.33), Vector2(0.73, -1.73), Vector2(1.61, -0.22), Vector2(1.09, 1.39), Vector2(-0.68, 1.58), Vector2(-1.89, 0.25),
		]],
	],
	"apex": Vector3(0.6, -10.5, 0.3),
}
const ISLET_NE: Dictionary = {
	"top": [
		Vector2(-3.4, -0.6), Vector2(-2.4, -2.6), Vector2(-0.3, -3.5), Vector2(2.0, -2.8), Vector2(3.5, -0.9), Vector2(3.1, 1.6),
		Vector2(1.2, 3.3), Vector2(-1.3, 3.4), Vector2(-3.1, 1.8),
	],
	"top_y": 0.0,
	"bands": [[0.0, -0.8, 0.0], [-0.8, -1.9, 0.4]],
	"jog": [0.0, 0.25, -0.15, 0.3],
	"rings": [
		[-3.4, [
			Vector2(-2.04, -0.36), Vector2(-1.03, -1.89), Vector2(0.75, -1.7), Vector2(2.3, -0.61), Vector2(1.48, 1.09), Vector2(0.06, 2.11),
			Vector2(-1.49, 1.3),
		]],
		[-5.0, [
			Vector2(-0.88, -0.67), Vector2(0.3, -0.85), Vector2(1.05, 0.02), Vector2(0.28, 0.95), Vector2(-0.93, 0.65),
		]],
	],
	"apex": Vector3(0.2, -6.6, -0.1),
}
const ISLET_W: Dictionary = {
	"top": [
		Vector2(-3.5, -0.4), Vector2(-2.7, -2.4), Vector2(-0.7, -3.4), Vector2(1.6, -3.0), Vector2(3.3, -1.3), Vector2(3.6, 0.9),
		Vector2(2.5, 2.8), Vector2(0.2, 3.6), Vector2(-2.0, 3.0), Vector2(-3.3, 1.5),
	],
	"top_y": 0.0,
	"bands": [[0.0, -0.8, 0.0], [-0.8, -1.9, 0.45], [-1.9, -2.9, 0.9]],
	"jog": [0.0, 0.3, -0.2, 0.35, 0.1],
	"rings": [
		[-4.2, [
			Vector2(-2.17, -0.25), Vector2(-1.43, -1.77), Vector2(0.25, -1.87), Vector2(1.85, -1.28), Vector2(2.03, 0.36), Vector2(1.44, 1.89),
			Vector2(-0.25, 2.04), Vector2(-1.83, 1.44),
		]],
		[-5.8, [
			Vector2(-1.05, -0.59), Vector2(-0.01, -0.97), Vector2(1.02, -0.53), Vector2(0.94, 0.57), Vector2(0.02, 1.23), Vector2(-0.9, 0.54),
		]],
	],
	"apex": Vector3(0.3, -7.6, 0.2),
}
const ISLET_E: Dictionary = {
	"top": [
		Vector2(-3.0, -0.6), Vector2(-2.2, -2.3), Vector2(-0.4, -3.0), Vector2(1.7, -2.4), Vector2(3.0, -0.7), Vector2(2.8, 1.3),
		Vector2(1.3, 2.8), Vector2(-0.8, 3.0), Vector2(-2.6, 1.7),
	],
	"top_y": 0.0,
	"bands": [[0.0, -0.8, 0.0], [-0.8, -1.8, 0.4], [-1.8, -2.8, 0.8]],
	"jog": [0.0, 0.25, -0.2, 0.35, 0.15],
	"rings": [
		[-4.0, [
			Vector2(-1.8, -0.36), Vector2(-1.12, -1.59), Vector2(0.27, -1.55), Vector2(1.56, -1.0), Vector2(1.58, 0.34), Vector2(1.01, 1.57),
			Vector2(-0.36, 1.72), Vector2(-1.67, 1.11),
		]],
		[-5.4, [
			Vector2(-0.79, -0.62), Vector2(0.25, -0.72), Vector2(0.92, 0.04), Vector2(0.23, 0.82), Vector2(-0.83, 0.56),
		]],
	],
	"apex": Vector3(-0.2, -7.0, 0.1),
}
const ROCK_FLOAT_A: Dictionary = {
	"top": [
		Vector2(-0.5, -0.15), Vector2(-0.25, -0.48), Vector2(0.2, -0.5), Vector2(0.5, -0.18), Vector2(0.45, 0.3), Vector2(0.05, 0.52),
		Vector2(-0.42, 0.35),
	],
	"top_y": 0.0,
	"bands": [[0.0, -0.35, 0.0]],
	"jog": [0.0, 0.06, -0.04],
	"rings": [
		[-0.7, [
			Vector2(-0.3, -0.09), Vector2(-0.08, -0.31), Vector2(0.2, -0.19), Vector2(0.31, 0.09), Vector2(0.06, 0.27), Vector2(-0.24, 0.23),
		]],
	],
	"apex": Vector3(0.05, -1.3, 0.0),
}
const ROCK_FLOAT_B: Dictionary = {
	"top": [
		Vector2(-0.48, 0.05), Vector2(-0.3, -0.45), Vector2(0.15, -0.52), Vector2(0.5, -0.25), Vector2(0.52, 0.2), Vector2(0.2, 0.5),
		Vector2(-0.3, 0.45),
	],
	"top_y": 0.0,
	"bands": [[0.0, -0.25, 0.0], [-0.25, -0.55, 0.12]],
	"jog": [0.0, 0.05, -0.05, 0.08],
	"rings": [
		[-0.85, [
			Vector2(-0.24, 0.03), Vector2(-0.1, -0.25), Vector2(0.19, -0.15), Vector2(0.26, 0.14), Vector2(-0.04, 0.22),
		]],
	],
	"apex": Vector3(-0.1, -1.6, 0.05),
}
const ROCK_FLOAT_C: Dictionary = {
	"top": [
		Vector2(-0.5, -0.3), Vector2(0.0, -0.55), Vector2(0.48, -0.3), Vector2(0.5, 0.25), Vector2(0.0, 0.55), Vector2(-0.5, 0.28),
	],
	"top_y": 0.0,
	"bands": [[0.0, -0.5, 0.0]],
	"jog": [0.0, 0.08, -0.05],
	"rings": [
		[-0.8, [
			Vector2(-0.28, -0.17), Vector2(0.06, -0.29), Vector2(0.25, -0.02), Vector2(0.11, 0.27), Vector2(-0.21, 0.16),
		]],
	],
	"apex": Vector3(0.08, -1.1, -0.06),
}
const ROCK_BIG: Dictionary = {
	"top": [
		Vector2(-3.6, -0.8), Vector2(-2.4, -3.0), Vector2(0.2, -3.8), Vector2(2.8, -2.9), Vector2(3.9, -0.4), Vector2(3.2, 2.4),
		Vector2(0.9, 3.7), Vector2(-1.9, 3.4), Vector2(-3.5, 1.6),
	],
	"top_y": 0.0,
	"bands": [[0.0, -1.2, 0.0], [-1.2, -2.8, 0.6], [-2.8, -4.2, 1.0]],
	"jog": [0.0, 0.4, -0.3, 0.6, 0.2],
	"rings": [
		[-5.8, [
			Vector2(-2.23, -0.5), Vector2(-1.29, -2.08), Vector2(0.52, -2.07), Vector2(2.18, -1.37), Vector2(2.06, 0.45), Vector2(1.34, 1.99),
			Vector2(-0.45, 2.1), Vector2(-2.09, 1.36),
		]],
		[-7.4, [
			Vector2(-1.02, -0.74), Vector2(0.12, -1.1), Vector2(1.14, -0.53), Vector2(1.0, 0.68), Vector2(-0.08, 1.24), Vector2(-1.02, 0.5),
		]],
	],
	"apex": Vector3(0.4, -9.5, -0.2),
}
## Lâminas da cascata (medidas na referência): [x da esquerda, x da direita]; caem do lábio em
## y WATERFALL_TOP (z WATERFALL_LIP) até WATERFALL_BOTTOM, na frente da face (z WATERFALL_Z).
const WATERFALL_SHEETS: Array = [[-9.0, -6.8], [-3.3, 5.6], [11.5, 14.1]]
const WATERFALL_TOP: float = 8.0
const WATERFALL_LIP: float = -56.9
const WATERFALL_Z: float = -56.45
const WATERFALL_BOTTOM: float = -13.0
## Rio no topo da ilha alta (até o lábio): [x0, x1, z de trás].
const RIVER: Array = [-9.5, 14.5, -66.0]
## Arco-íris no plano z RAINBOW_Z: pontos (x, y) do arco e largura da fita.
const RAINBOW_Z: float = -55.2
const RAINBOW_ARC: PackedVector2Array = [
	Vector2(-0.50, -12.50), Vector2(-0.67, -10.49), Vector2(-0.39, -8.49), Vector2(0.33, -6.61), Vector2(1.46, -4.94),
	Vector2(2.93, -3.56), Vector2(4.68, -2.55), Vector2(6.60, -1.95), Vector2(8.62, -1.80), Vector2(10.61, -2.11),
	Vector2(12.48, -2.86), Vector2(14.14, -4.01), Vector2(15.50, -5.50),
]
const RAINBOW_WIDTH: float = 1.5

## Nuvens: aglomerados de puffs Vector4(x, y, z, raio) (achatados em y por CLOUD_FLATTEN).
const CLOUD_FLATTEN: float = 0.62
const CLOUDS: Array = [
	[Vector4(-4.0, 0.0, 0.0, 2.2), Vector4(-1.5, 0.4, 0.5, 2.6), Vector4(1.5, 0.2, -0.3, 2.4), Vector4(4.0, 0.0, 0.2, 2.0),
		Vector4(0.0, 1.2, 0.0, 1.8), Vector4(-2.6, 1.0, -0.6, 1.5), Vector4(2.6, 1.1, 0.4, 1.6), Vector4(0.5, -0.2, 1.6, 1.8),
		Vector4(-0.8, -0.1, -1.6, 1.7)],
	[Vector4(0.0, 0.0, 0.0, 2.4), Vector4(1.8, 0.5, 0.4, 1.9), Vector4(-1.9, 0.4, -0.3, 2.0), Vector4(0.3, 1.8, 0.1, 1.9),
		Vector4(-0.9, 2.9, 0.0, 1.4), Vector4(1.0, 2.6, -0.3, 1.3), Vector4(0.0, 3.8, 0.2, 1.1), Vector4(2.8, -0.2, 0.1, 1.4),
		Vector4(-2.9, -0.3, 0.2, 1.3)],
	[Vector4(-6.0, 0.0, 0.3, 1.8), Vector4(-3.6, 0.3, -0.2, 2.2), Vector4(-1.0, 0.5, 0.2, 2.5), Vector4(1.8, 0.3, -0.1, 2.3),
		Vector4(4.4, 0.1, 0.3, 2.0), Vector4(6.6, -0.1, 0.0, 1.6), Vector4(-2.2, 1.6, 0.0, 1.5), Vector4(0.8, 1.8, 0.2, 1.7),
		Vector4(3.4, 1.4, -0.2, 1.4)],
	[Vector4(0.0, 0.0, 0.0, 1.5), Vector4(1.3, 0.3, 0.3, 1.2), Vector4(-1.2, 0.2, -0.2, 1.3), Vector4(0.2, 1.0, 0.0, 1.1),
		Vector4(-0.4, -0.2, 1.0, 1.0)],
	[Vector4(-5.0, 0.0, -2.0, 2.6), Vector4(-1.5, 0.2, -2.4, 3.0), Vector4(2.5, 0.0, -1.8, 2.8), Vector4(5.5, -0.2, -1.0, 2.2),
		Vector4(-4.0, -0.1, 1.6, 2.4), Vector4(-0.5, 0.3, 1.2, 3.0), Vector4(3.5, 0.1, 1.8, 2.6), Vector4(0.8, 1.1, -0.3, 2.0),
		Vector4(-2.4, 0.9, 0.2, 1.8)],
]

## Pontes de corda: catenária em tabela (distância ao longo, altura), da cabeceira (0, 0) até a ilhota.
const BRIDGE_W: PackedVector2Array = [
	Vector2(0.0, 0.0), Vector2(0.49, -0.26), Vector2(0.97, -0.5), Vector2(1.46, -0.7), Vector2(1.95, -0.86), Vector2(2.43, -1.0),
	Vector2(2.92, -1.1), Vector2(3.41, -1.18), Vector2(3.89, -1.22), Vector2(4.38, -1.22), Vector2(4.87, -1.2),
]
const BRIDGE_E: PackedVector2Array = [
	Vector2(0.0, 0.0), Vector2(0.45, -0.32), Vector2(0.9, -0.6), Vector2(1.34, -0.84), Vector2(1.79, -1.05), Vector2(2.24, -1.22),
	Vector2(2.69, -1.35), Vector2(3.14, -1.44), Vector2(3.58, -1.5),
]
const BRIDGE_WIDTH: float = 1.5

# ---------------------------------------------------------------- lajes (Tabela B)
## Ciclos fixos de medidas das lajes (comprimento, largura, folga do canto): dão lajes irregulares sem sorteio.
const SLAB_LENGTHS: Array = [0.9, 0.7, 1.1, 0.8, 0.6, 1.0, 0.75, 0.95, 0.65]
const SLAB_WIDTHS: Array = [0.8, 1.05, 0.65, 0.9, 1.15, 0.7]
const SLAB_JITTER: Array = [0.04, -0.03, 0.06, -0.05, 0.02, -0.06, 0.05, -0.02]
## Caminho nordeste: linha central (x, z) e largura.
const PATH_NE: PackedVector2Array = [Vector2(16.2, -4.5), Vector2(17.0, -8.0), Vector2(19.4, -14.3), Vector2(21.0, -19.5), Vector2(23.0, -24.1)]
const PATH_NE_WIDTH: float = 2.75
## Lajes soltas na arena (centro x, z, meio comprimento, meia largura, giro em graus).
const ARENA_SLABS: Array = [
	[-4.6, -2.8, 0.45, 0.3, 20.0], [-3.4, 1.9, 0.5, 0.28, -15.0], [3.9, -3.9, 0.4, 0.26, 35.0], [5.3, 0.6, 0.48, 0.3, -30.0],
	[-1.6, -5.0, 0.35, 0.22, 60.0], [2.6, 2.7, 0.42, 0.25, 10.0], [-5.6, 0.3, 0.3, 0.2, -50.0], [1.2, -4.6, 0.3, 0.2, 75.0],
]
