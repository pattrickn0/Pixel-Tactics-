class_name MapGenConfig
extends Resource
## Todos os parâmetros ajustáveis da geração do mapa.
## No multiplayer, todos os clientes devem usar a mesma config (junto com a seed).
## O layout fixo (arena, reservas, anéis, escadas) sai só daqui, sem RNG; o resto vem da seed.

@export_group("Layout fixo")
@export var map_size: Vector2i = Vector2i(44, 44)
## Arena retangular centrada no mapa (largura em x, profundidade em z). Use valores pares.
@export var arena_size: Vector2i = Vector2i(20, 18)
@export var arena_floor_level: int = 0
## Quantos níveis a reserva (e o anel 1) fica acima do chão da arena.
@export var bench_level_offset: int = 2
## Profundidade (células) do terraço da reserva, nos lados compridos.
@export var bench_depth: int = 3
## Borda (unidades) do terraço que não entra na área útil, junto ao muro e ao anel 2.
@export var bench_edge_inset: float = 0.5
## Largura (células) do anel 1 nos lados curtos.
@export var ring1_width: int = 2
## Largura (células) do anel 2, em volta de tudo.
@export var ring2_width: int = 2
## Quantos níveis o anel 2 fica acima da reserva.
@export var ring2_level_offset: int = 2
## Largura (células) de todas as escadas.
@export var stair_width: int = 2
## Distância (células) da escada da reserva até o canto da arena, ao longo do lado comprido.
@export var bench_stair_inset: int = 0
## Deslocamento (células) das escadas de entrada a partir do meio do lado curto.
@export var entrance_stair_offset: int = 0

@export_group("Relevo da arena")
## Como a metade do inimigo copia a minha (rotação de 180° ou reflexão em z).
@export var relief_symmetry: MapData.ReliefSymmetry = MapData.ReliefSymmetry.ROTATION
## Chance do modo CENTRAL (um morro que cruza o meio); senão, um morro por metade.
@export_range(0.0, 1.0, 0.05) var relief_central_chance: float = 0.5
## No modo PER_SIDE, linhas de chão entre o morro e a linha do meio.
@export var relief_midline_gap: int = 1
## Topo do relevo, em níveis acima do chão (sorteado entre os dois).
@export var relief_peak_min: int = 2
@export var relief_peak_max: int = 3
## Chance de sortear o pico máximo (senão, um dos menores). O PER_SIDE, com as margens
## padrão, só comporta 2 níveis; aí o pico cai para 2.
@export_range(0.0, 1.0, 0.05) var relief_peak_high_chance: float = 0.7
## Distância mínima (células) do nível 1 até as bordas compridas e curtas da arena.
@export var relief_long_margin: int = 1
@export var relief_short_margin: int = 2
## Área elevada (nível >= 1), em fração da arena.
@export_range(0.0, 1.0, 0.01) var relief_area_min: float = 0.12
@export_range(0.0, 1.0, 0.01) var relief_area_max: float = 0.40
## Retângulos por nível em cada metade (o nível 1 usa até relief_rects_max).
@export var relief_rects_max: int = 3
## Lado dos retângulos do relevo, em células.
@export var relief_rect_min: int = 3
@export var relief_rect_max: int = 12
## Trecho reto mínimo do contorno para pôr uma escada interna.
@export var relief_stair_run_min: int = 4
## Tentativas de forma antes de usar a forma reserva.
@export var relief_max_attempts: int = 240
## Fração da arena coberta de terra (só visual): sorteada entre os dois.
@export_range(0.0, 1.0, 0.01) var arena_dirt_min: float = 0.18
@export_range(0.0, 1.0, 0.01) var arena_dirt_max: float = 0.32
## Manchas extras de terra, além da mancha central.
@export var arena_dirt_patches_max: int = 2

@export_group("Floresta")
@export var forest_noise_frequency: float = 0.09
## Força do noise do relevo (em níveis).
@export var forest_noise_amplitude: float = 1.6
## Quanto o relevo sobe à medida que se afasta do anfiteatro.
@export var forest_distance_bias: float = 1.0
## Distância (células) a partir da qual o viés de altura chega no máximo.
@export var forest_distance_falloff: float = 5.0
## Quantos níveis a floresta sobe, no máximo, acima do anel 2.
@export var forest_relief_max: int = 2

@export_group("Trilhas")
@export var trail_width: int = 2
## Curvas da trilha: variação por passo e curvatura máxima (radianos).
@export var trail_wiggle: float = 0.09
@export var trail_max_turn: float = 0.2
## Quanto a trilha é puxada para o ponto sorteado na borda (0..1).
@export_range(0.0, 1.0, 0.01) var trail_pull: float = 0.12
## Sorteio do ponto da borda para onde a trilha vai (em volta da escada).
@export var trail_target_jitter: float = 8.0
## Chance de a trilha ser de pedra (senão, de terra).
@export_range(0.0, 1.0, 0.05) var trail_stone_chance: float = 0.4
## Ramais (no máximo) saindo das trilhas.
@export var trail_branch_max: int = 1

@export_group("Chão")
## Mistura irregular entre grama da arena e da mata no anel 2.
@export var ground_blend_noise_frequency: float = 0.2
@export var ground_blend_noise_strength: float = 1.5

@export_group("Decoração")
@export var monolith_count_min: int = 2
@export var monolith_count_max: int = 4
@export var monolith_min_spacing: float = 6.0
## Monólitos ficam no anel 2 ou na floresta a até esta distância (células) dele.
@export var monolith_max_ring_distance: int = 4
## Folga mínima de um monólito até escadas e trilhas.
@export var monolith_clearance: float = 1.5
## Densidades: chance por célula da floresta.
@export_range(0.0, 1.0, 0.01) var tree_big_density: float = 0.7
@export_range(0.0, 1.0, 0.01) var tree_small_density: float = 0.3
@export_range(0.0, 1.0, 0.01) var bush_density: float = 0.4
@export_range(0.0, 1.0, 0.01) var grass_tuft_density: float = 0.45
@export_range(0.0, 1.0, 0.01) var flower_density: float = 0.08
@export_range(0.0, 1.0, 0.01) var rock_density: float = 0.025
## Chance por célula de capim/flor dentro da arena.
@export_range(0.0, 0.2, 0.005) var arena_detail_density: float = 0.04
## Chance por célula de capim/flor nos anéis e no terraço das reservas (fora da área útil).
@export_range(0.0, 1.0, 0.01) var ring_detail_density: float = 0.12
## Na arena, fração de capim (o resto são flores).
@export_range(0.0, 1.0, 0.05) var arena_grass_tuft_share: float = 0.7
## Variação da densidade da mata (bosques mais fechados e mais abertos).
@export var forest_density_noise_frequency: float = 0.09
@export var forest_density_variation: float = 1.0
## Espaçamento mínimo entre bases de árvores.
@export var tree_spacing: float = 0.6
## Espaçamento mínimo entre arbustos (e de arbusto para árvore).
@export var bush_spacing: float = 0.5
