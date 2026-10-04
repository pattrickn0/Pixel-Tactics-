class_name MapGenConfig
extends Resource
## Todos os parâmetros ajustáveis da geração do mapa.
## No multiplayer, todos os clientes devem usar a mesma config (junto com a seed).

@export_group("Mapa")
@export var map_size: Vector2i = Vector2i(32, 32)

@export_group("Arena")
## Largura e altura da caixa da arena / tamanho do mapa.
@export_range(0.3, 0.9, 0.01) var arena_fraction_min: float = 0.62
@export_range(0.3, 0.9, 0.01) var arena_fraction_max: float = 0.68
## Deformação relativa do raio (forma orgânica).
@export_range(0.0, 0.3, 0.01) var arena_shape_noise: float = 0.08
## Quantos "calombos" a borda tem (raio do círculo amostrado no noise).
@export var arena_shape_noise_scale: float = 1.6
## Expoente da superelipse (2 = elipse, maior = mais quadrada).
@export var arena_shape_exponent_min: float = 2.5
@export var arena_shape_exponent_max: float = 3.4
## Deslocamento máximo do centro da arena, em células.
@export var arena_center_jitter: int = 2
@export var arena_base_level: int = 1
## Anel plano em volta da arena (onde fica o muro), em células.
@export var ring_width: int = 2

@export_group("Relevo")
@export var max_level: int = 3
@export var height_noise_frequency: float = 0.07
## Força do noise do relevo (em níveis).
@export var height_noise_amplitude: float = 2.2
## Quanto o relevo sobe à medida que se afasta da arena.
@export var height_distance_bias: float = 1.2
## Distância (células) a partir do anel em que o viés de altura chega no máximo.
@export var height_distance_falloff: float = 5.0
@export var raised_regions_min: int = 1
@export var raised_regions_max: int = 2
## Fração máxima da arena em cada região elevada.
@export_range(0.0, 0.3, 0.01) var raised_region_max_fraction: float = 0.15
## Fração máxima da arena somando todas as regiões elevadas (o resto fica no nível base).
@export_range(0.0, 0.3, 0.01) var raised_total_max_fraction: float = 0.29
@export var raised_region_min_size: Vector2i = Vector2i(3, 2)
@export var raised_region_max_size: Vector2i = Vector2i(6, 4)
## Células de nível base entre a região elevada e a borda da arena.
@export var raised_region_edge_margin: int = 3
@export_range(0.0, 1.0, 0.05) var stair_chance: float = 0.6
@export var stair_width: int = 2

@export_group("Muro")
@export var wall_height: float = 0.5
@export var wall_thickness: float = 0.5
## Fração do perímetro com trechos quebrados (mais baixos ou com falha).
@export_range(0.0, 0.5, 0.01) var wall_broken_ratio: float = 0.15
## Altura dos trechos baixos, relativa a wall_height.
@export_range(0.1, 0.9, 0.05) var wall_low_height_ratio: float = 0.5
## Dos trechos quebrados, a fração que vira falha (o resto fica mais baixo).
@export_range(0.0, 1.0, 0.05) var wall_gap_share: float = 0.45
## Teto de falhas no perímetro (contando as das trilhas).
@export_range(0.0, 0.25, 0.01) var wall_max_gap_ratio: float = 0.2

@export_group("Trilhas")
@export var trail_count_min: int = 2
@export var trail_count_max: int = 3
@export var trail_width: int = 2
## Quantas células a trilha entra na arena antes de se dissolver.
@export var trail_arena_depth_min: int = 2
@export var trail_arena_depth_max: int = 4
## Curvas da trilha: variação por passo e curvatura máxima (radianos).
@export var trail_wiggle: float = 0.09
@export var trail_max_turn: float = 0.2
## Quanto a trilha é puxada para o centro da arena a cada passo (0..1).
@export_range(0.0, 1.0, 0.01) var trail_pull: float = 0.12
## Sorteio do ponto da arena para onde a trilha vai (em volta do centro).
@export var trail_target_jitter: float = 3.0

@export_group("Chão")
## Mistura irregular entre grama da arena e da mata no anel.
@export var ground_blend_noise_frequency: float = 0.2
@export var ground_blend_noise_strength: float = 1.5
@export var ruin_patch_radius_min: float = 1.5
@export var ruin_patch_radius_max: float = 3.2
## Chance de lajota no centro e na borda de cada mancha.
@export_range(0.0, 1.0, 0.05) var ruin_center_chance: float = 0.7
@export_range(0.0, 1.0, 0.05) var ruin_edge_chance: float = 0.2

@export_group("Decoração")
@export var ruin_patch_count_min: int = 0
@export var ruin_patch_count_max: int = 0
@export var monolith_count_min: int = 1
@export var monolith_count_max: int = 3
@export var monolith_min_spacing: float = 3.0
@export var monolith_max_arena_distance: float = 2.0
## Monólitos só na parte de cima da caixa da arena (nada alto perto da câmera).
@export_range(0.0, 1.0, 0.05) var monolith_north_fraction: float = 0.7
## Distância mínima de um monólito até uma falha do muro.
@export var monolith_gap_clearance: float = 2.5
## Densidades: chance por célula de fora da arena.
@export_range(0.0, 1.0, 0.01) var tree_big_density: float = 0.7
@export_range(0.0, 1.0, 0.01) var tree_small_density: float = 0.3
@export_range(0.0, 1.0, 0.01) var bush_density: float = 0.4
@export_range(0.0, 1.0, 0.01) var grass_tuft_density: float = 0.45
@export_range(0.0, 1.0, 0.01) var flower_density: float = 0.08
@export_range(0.0, 1.0, 0.01) var rock_density: float = 0.025
## Chance por célula de capim/flor dentro da arena.
@export_range(0.0, 0.2, 0.005) var arena_detail_density: float = 0.04
## Na arena, fração de capim (o resto são flores).
@export_range(0.0, 1.0, 0.05) var arena_grass_tuft_share: float = 0.7
## Variação da densidade da mata (bosques mais fechados e mais abertos).
@export var forest_density_noise_frequency: float = 0.09
@export var forest_density_variation: float = 1.0
## Espaçamento mínimo entre bases de árvores.
@export var tree_spacing: float = 0.6
## Espaçamento mínimo entre arbustos (e de arbusto para árvore).
@export var bush_spacing: float = 0.5
## Na faixa sul, só vegetação baixa até esta distância (células) da arena.
@export var south_low_depth: int = 3
