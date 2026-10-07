# 007 — Arena fixa, reservas em terraço e relevo justo (anfiteatro retangular)

**Status:** aprovada pelo usuário em 2026-10-06.
**Depende de:** nada (usa a arte atual; a arte nova vem da A03 e o acabamento visual da `005`).
**Substitui:** a geração de arena orgânica, de terraços em bolha e de muro baixo da `001`, `002` e `003` (ver "O que sai").
**Próximas:** `004` (luz de dia claro), `005` (terreno com a A03), `006` (vegetação e props 3D). Todas assumem o layout desta spec.

## Decisões do usuário (2026-10-06)

- **P1:** (B), reserva **2 níveis (1,0)** acima do chão da arena (`bench_level_offset = 2`).
- **P2:** simetria central (rotação de 180°).
- **P3, P4, P5:** aprovados como propostos (arena 20 × 18, mapa 44 × 44, câmera 32/40, escadas, topo do relevo entre 2 e 3 níveis).

## Pontos que estavam em aberto (registro)

**P1. Altura da reserva.** O usuário disse: "os degraus da reserva devem ser ligeiramente maiores que a arena, pois é uma parte importante de haver uma visão límpida". Há duas leituras:

- **(A) Reserva acima do ponto mais alto do relevo da arena.** Com relevo de até 3 níveis, a reserva fica no nível 4 (2,0 unidades acima do chão da arena).
- **(B) Reserva ligeiramente acima do chão da arena.** A reserva fica 2 níveis (1,0 unidade) acima do chão. O topo do relevo da arena pode passar dela.

Medido na câmera padrão desta spec (distância 32, inclinação 34°), o muro da **minha** reserva (perto da câmera) esconde uma faixa da arena logo atrás dele:

| Reserva acima do chão da arena | Faixa de chão escondida | Faixa em que o meio de uma peça (0,6 de altura) fica escondido |
|---|---|---|
| 1 nível (0,5) | 0,5 | 0 |
| **2 níveis (1,0), recomendado** | 1,0 | 0,4 |
| 3 níveis (1,5) | 1,6 | 1,0 |
| 4 níveis (2,0), leitura A | 2,2 | 1,6 (cerca de 17% da profundidade da minha metade) |

A reserva do inimigo (no fundo da tela) fica visível em qualquer das opções, porque o relevo fica longe dela (margem e terraços de 1 nível, ver C). **Recomendação: (B) com 2 níveis**, que deixa a arena quase toda visível. Se o usuário quiser (A), basta mudar `bench_level_offset` para 4, e o limiar de visibilidade do teste (critério V2) cai de 95% para 85%.

**P2. "Assimétrica".** O usuário pediu "2 degraus separados de forma assimétrica para cada lado", e também que nada seja injusto. Proposta: **simetria central** (rotação de 180° em torno do centro da arena). Na prática:

- vista de cima, o mapa parece assimétrico: se o meu morro está à minha esquerda, perto do meio, o do inimigo está à esquerda **dele**, ou seja, à direita da tela, lá no fundo;
- do ponto de vista de cada jogador, a metade dele é idêntica à do outro. Mesma área por nível, mesmas distâncias até a reserva e até o centro.

A alternativa é a **simetria de espelho** (reflexão na linha do meio): o morro do inimigo fica do mesmo lado da tela que o meu, de frente para ele. Também é justa, mas parece "espelhada". A spec usa a simetria central por padrão e deixa o espelho como `@export`, caso o usuário prefira.

**P3. Dimensões.** Arena de **20 × 18** unidades (11% mais larga que alta). Reservas com área útil de **16 × 2**. Mapa de **44 × 44**. A conta está em "Layout fixo". Para caber as duas reservas na tela na câmera padrão, `start_distance` sobe de 28 para 32 e `max_distance` de 32 para 40. A inclinação e o FOV não mudam.

**P4. Escadas, não rampas.** Para subir no relevo da arena: escadas de pedra (2 degraus por nível), como na referência. Rampas ficam fora (pedem textura esticada e não aparecem na referência). Se a peça vai poder subir por elas é mecânica futura.

**P5. Altura do relevo da arena.** O topo do relevo fica entre 2 e 3 níveis acima do chão, sorteado por seed. Isso dá 3 ou 4 alturas diferentes dentro da arena.

## Objetivo
Ao apertar F5 (ou "Gerar mapa"), o jogador vê um **anfiteatro retangular** sempre com o mesmo formato:
- a arena retangular no centro;
- a **minha reserva** num terraço de pedra embaixo da tela e a **reserva do inimigo** em cima, cada uma com escadas descendo para a arena;
- nos lados curtos, muro e anéis de terraço subindo para a floresta, com a trilha entrando pelas escadas.

O que muda a cada seed é o **relevo dentro da arena**: um morro central compartilhado ou dois morros, um em cada metade, sempre **justos entre as duas metades**. Também mudam as manchas de terra, a floresta, as trilhas e a decoração em volta.

## Fixo e procedural

| Fixo (igual em toda seed; vem da `MapGenConfig`) | Procedural (pela seed) |
|---|---|
| Tamanho do mapa, tamanho e posição da arena (centrada) | Relevo dentro da arena: modo (central ou um por metade), formas, número de níveis e escadas internas |
| Nível do chão da arena | Manchas de terra dentro da arena (só visual) |
| Reservas: terraço, área útil, nível, escadas de descida | Relevo da floresta além do anel 2 |
| Anel 1 (lados curtos) e anel 2 (em volta de tudo): níveis e larguras | Trilhas: traçado da escada de entrada até a borda do mapa, e se é de terra ou de pedra |
| Escadas de entrada nos lados curtos (posição e largura) | Vegetação, pedras grandes e monólitos (posições, variantes) |
| Quais faces são muro de pedra (todo o anfiteatro) | Desgaste visual do muro (só visual, spec `005`) |

## Layout fixo (padrão)

Coordenadas em células do mapa (1 célula = 1 unidade). Z cresce para o sul, que fica embaixo da tela na câmera padrão (yaw 0).

```
x:     0      8  10 12                    32 34 36      44
z= 0   +-------------------------------------------------+
       |              floresta (procedural)              |
z= 8   |      +-----------------------------------+      |
       |      |  anel 2 (nível 4)                 |      |
z=10   |      |  +-----------------------------+  |      |
       |      |  |  reserva do inimigo (nível 2)|  |      |   time 1 (norte)
z=13   |      |  |  +-----------------------+  |  |      |
       |      |  |  |                       |  |  |      |
       |      |  |a |  ARENA 20 x 18        |a |  |      |
z=21-22| trilha=E=E1|  chão no nível 0      |E1=E=trilha  |   E = escada de entrada
       |      |  |1 |  relevo justo (1..3)  |1 |  |      |
       |      |  |  |                       |  |  |      |
z=31   |      |  |  +-----------------------+  |  |      |
       |      |  |  minha reserva (nível 2)    |  |      |   time 0 (sul)
z=34   |      |  +-----------------------------+  |      |
       |      |                                   |      |
z=36   |      +-----------------------------------+      |
z=44   +-------------------------------------------------+
```

- **Arena:** `Rect2(12, 13, 20, 18)`, com centro em (22, 22). O chão fica no nível `arena_floor_level = 0`.
- **Anel 1** (nível `bench_level = arena_floor_level + bench_level_offset`, padrão 2):
  - nos lados compridos, é o **terraço da reserva**, com 3 células de profundidade: z ∈ [10, 13) ao norte e z ∈ [31, 34) ao sul, e x ∈ [10, 34);
  - nos lados curtos, tem 2 células: x ∈ [10, 12) e [32, 34), com z ∈ [13, 31).

  Juntos, formam um anel contínuo em volta da arena.
- **Reservas** (`MapData.benches`, uma por time):
  - **time 0, a minha** (sul, embaixo na câmera padrão): área útil `Rect2(14, 31.5, 16, 2)`;
  - **time 1, a do inimigo** (norte): área útil `Rect2(14, 10.5, 16, 2)`.

  A área útil não inclui as escadas, nem a borda de 0,5 junto ao muro e junto ao anel 2.
- **Escadas das reservas:** 2 por reserva, embutidas no terraço (não invadem a arena), com 2 células de largura e 2 de comprimento (2 níveis × 2 degraus):
  - sul: x ∈ [12, 14) e [30, 32), z ∈ [31, 33), subindo para o sul;
  - norte: as mesmas, giradas 180°.
- **Anel 2** (nível `ring2_level = bench_level + 2`, padrão 4): faixa de 2 células em volta do anel 1, x ∈ [8, 36) × z ∈ [8, 36), menos o miolo.
- **Escadas de entrada** (lados curtos, centradas em z ∈ [21, 23), 2 de largura):
  - oeste: x ∈ [10, 12) (anel 1, sobe para oeste) e x ∈ [8, 10) (anel 2);
  - leste: as mesmas, giradas 180°.

  A trilha começa no topo da escada do anel 2.
- **Floresta:** tudo fora de [8, 36)². O relevo é procedural, sempre ≥ `ring2_level`.
- **Todo desnível dentro de [8, 36)²** é muro de pedra (`MapData.built_mask`). Os desníveis da floresta são barranco natural.

Todos esses números são `@export` em `MapGenConfig` (tamanho da arena, profundidade da reserva, largura dos anéis, offsets de nível, largura e posição das escadas). O gerador calcula as posições a partir deles, sem literais espalhados. Com qualquer configuração válida, o layout fixo tem que ser simétrico por rotação de 180° em torno do centro da arena (o teste confere).

**Por que 20 × 18 e 44 × 44.** Com inclinação de 34° e FOV de 32°, na distância 32 a borda de baixo da tela fica cerca de 11,5 unidades à frente do centro (12,4 contando a altura da reserva). Assim, a minha reserva (até z = 34, ou seja, 12 do centro) cabe inteira, e a do inimigo também, com folga. Uma arena maior obrigaria a afastar mais a câmera, e o pixel ficaria menor na tela. O mapa de 44 dá 8 células de floresta em volta do anfiteatro (28 × 28). Além dele entra a mata de fundo da `004`/`006`.

## Escopo

### A. Dados (`scripts/map/`, sem visual)
1. **`MapData`:**
   - `arena_rect` passa a ser o retângulo fixo;
   - `arena_base_level` vira o nível do chão da arena (pode renomear para `arena_floor_level`; atualize os usos);
   - o `arena_mask` continua existindo, derivado do retângulo.
2. **Funções da arena sobre o retângulo:**
   - `is_inside_arena(pos)`: `x0 ≤ x < x1` e `z0 ≤ z < z1`;
   - `clamp_to_arena(pos)`: limita a `[x0 + CLAMP_INSET, x1 − CLAMP_INSET]` em cada eixo;
   - `distance_to_arena(pos)`: distância ao retângulo.

   Nada disso depende mais de células.
3. **Reservas:** nova classe `MapBench` (`RefCounted`), com:
   - `team: int` (0 = sul, 1 = norte);
   - `rect: Rect2` (área útil);
   - `terrace_rect: Rect2`;
   - `level: int`.

   Em `MapData`: `benches: Array[MapBench]`, `get_bench(team) -> MapBench`, `is_inside_bench(pos, team) -> bool` e `clamp_to_bench(pos, team) -> Vector2`. Só dados e consulta, **sem** slots nem regra de reserva.
4. **Metades e simetria:**
   - `arena_side_of(pos) -> int`: 0 se pos está na metade sul da arena (z ≥ centro), 1 na norte, −1 fora da arena;
   - `mirror_point(pos) -> Vector2`: o ponto correspondente na outra metade (`2 × centro − pos` na simetria central; reflexão em z no modo espelho);
   - `relief_mode` (`CENTRAL` ou `PER_SIDE`), para teste e depuração.
5. **Altura consultável:** `get_height_at(pos)` continua sendo a altura do topo do chão em qualquer ponto (terreno e escadas), sem regra de jogo.
   - **Escadas em qualquer direção e de vários níveis:** `MapStair` ganha `levels: int` (1 ou 2) e `up_direction` passa a valer nas 4 direções.
   - **2 degraus por nível:** cada degrau sobe meio nível e tem 0,5 de piso. Uma escada de `levels` níveis ocupa `levels` células na direção da subida.
   - Atualize `MapData.STAIR_STEPS` e o comentário "sobe do lado sul".
6. **`built_mask`** (`PackedByteArray`): 1 nas células do anfiteatro ([8, 36)², arena e anéis). O visual usa a máscara para escolher muro de pedra ou barranco.
7. **`MapData.fingerprint()`** passa a incluir as reservas, `relief_mode`, `built_mask` e os campos novos de `MapStair`.

### B. Layout fixo (gerador)
8. `MapGenerator` monta o layout da seção anterior a partir da config, antes de qualquer passo aleatório: alturas do anel 1, do anel 2 e das reservas, escadas fixas, `built_mask` e reservas.
9. O RNG de cada passo procedural continua sendo um sub-RNG da seed. O layout fixo não consome RNG.

### C. Relevo justo dentro da arena (procedural)
10. **Gerar uma metade e girar.** O gerador cria o relevo **só na minha metade** (sul) e copia para a outra por rotação de 180° em torno do centro: a célula (i, j) da arena vai para (W−1−i, D−1−j). As escadas internas vão junto, com `up_direction` invertida. Com `@export var relief_symmetry` = `MIRROR`, usa reflexão em z.
11. **Modo por seed:**
    - **`CENTRAL`** (chance `relief_central_chance`, padrão 0,5): **um** morro que cruza a linha do meio. A forma gerada na minha metade encosta na linha do meio cobrindo as 2 colunas centrais. Junto com a cópia girada, vira um único morro conexo.
    - **`PER_SIDE`**: um morro em cada metade, com `relief_midline_gap` (padrão 1) linha de chão entre o morro e a linha do meio. Os dois morros ficam separados.
12. **Níveis:** o topo do relevo fica entre `relief_peak_min` (2) e `relief_peak_max` (3) níveis acima do chão, sorteado por seed.
    - Os níveis são regiões encaixadas (nível ≥ 1 ⊇ nível ≥ 2 ⊇ nível ≥ 3).
    - **Células vizinhas (vizinhança 4) dentro da arena diferem no máximo 1 nível**, ou seja, o relevo é em terraços e não em penhasco. Isso deixa as peças visíveis atrás do relevo.
    - Se a forma não comporta o pico sorteado com as regras abaixo, use um pico menor (mínimo 1) e registre isso no teste de variedade.
13. **Forma limpa** (o muro de pedra fica reto, sem o zigue-zague de tile do screenshot):
    - cada região de nível é **união de 1 a 3 retângulos**;
    - passa na abertura 3×3 (reaproveite `MapGenerator.open_3x3`): nenhuma parte com menos de 3 células de largura;
    - todo trecho reto do contorno tem pelo menos 2 células (nada de dente de 1 célula).
14. **Margens:**
    - o nível 1 fica a pelo menos `relief_long_margin` (1) célula das bordas compridas e a `relief_short_margin` (2) das curtas;
    - a área elevada total (nível ≥ 1) fica entre `relief_area_min` (0,12) e `relief_area_max` (0,40) da arena.
15. **O chão conecta as reservas:** as células no nível do chão formam **uma** região conexa (vizinhança 4) que toca as duas bordas compridas, e as faixas de margem ficam inteiras no chão. A célula de chegada de cada escada de entrada e de cada escada da reserva fica no chão.
16. **Escadas internas:** cada região conexa de nível k (k ≥ 1) tem pelo menos uma escada vinda do nível k − 1:
    - 2 de largura, 1 célula de comprimento;
    - num trecho reto do contorno com pelo menos 4 células, ocupando células do nível de baixo, sem tapar a chegada de outra escada;
    - sorteada pelo RNG do passo.

    Todo ponto do relevo fica alcançável a partir do chão só passando por escadas (vale como dado: a regra de movimento é futura).
17. **Terra na arena** (só visual, sem regra): de 15% a 35% das células da arena viram `DIRT`, numa mancha central gasta e mais 0 a 2 manchas menores. A terra é gerada na metade e girada, como o relevo. O contorno orgânico é do shader (spec `005`).

### D. Em volta do anfiteatro (procedural)
18. **Relevo da floresta:** além do anel 2, ruído com seed, sempre ≥ `ring2_level` e subindo no máximo `forest_relief_max` (2) níveis. Regiões com a abertura 3×3 e sem penhascos de mais de 1 nível a menos de 2 células do anel 2. Reaproveite `_remove_spikes` e companhia.
19. **Trilhas:**
    - uma por escada de entrada (2 trilhas), do topo da escada do anel 2 até a borda do mapa, com o traçado sinuoso atual (`trail_wiggle`, `trail_max_turn`);
    - cada trilha é de terra (`DIRT`) ou de pedra (novo `Ground.STONE_PATH`), com `trail_stone_chance` (padrão 0,4);
    - `trail_branch_max` (padrão 1) ramal opcional saindo de uma trilha.

    A trilha acompanha o relevo da floresta (escada natural onde subir; pode reaproveitar `MapStair` com `levels = 1`).
20. **Monólitos:** de 2 a 4, em células da floresta a 1 a 4 células do anel 2, ou no próprio anel 2:
    - fora das escadas e da faixa de 1,5 em volta delas e das trilhas;
    - a pelo menos `monolith_min_spacing` (6) um do outro;
    - em qualquer lado.
21. **Zonas da decoração** (usa os tipos de objeto atuais; os tipos novos são da `006`):
    - **arena:** só capim e flor (`arena_detail_density`), nunca nas escadas;
    - **área útil das reservas:** nada;
    - **resto do anel 1 e anel 2:** só vegetação baixa (arbusto, capim, flor), fora das escadas e das chegadas;
    - **floresta:** árvores, arbustos, pedras e o resto. Nada alto colado no anel 2 (1 célula).

### E. Visual mínimo (para ver e testar; o acabamento é da `005`)
22. `TerrainMeshBuilder` desenha:
    - escadas nas 4 direções e de 1 ou 2 níveis (2 degraus por nível);
    - faces de desnível de células com `built_mask` usando a textura `wall_face` (cantos retos, **sem chanfro**);
    - faces fora dela com `step_side`/`step_side_grass` (o chanfro atual continua).

    `Ground.STONE_PATH` usa a textura `ruin_tile` até a A03 chegar.
23. **O muro baixo some.** Remova a geração de `WallSegment` e o `WallMeshBuilder` do mapa, ou deixe o builder sem uso e apague a chamada (a borda da arena agora é o muro de arrimo das reservas e do anel 1).
24. **Câmera:**
    - `start_distance` = 32 e `max_distance` = 40 (ajuste fino permitido, desde que o critério V1 passe);
    - `sharp_margin` cobre as reservas e o anel 1 (≥ 5);
    - o alvo continua sendo o centro da arena, no nível do chão;
    - inclinação, FOV, controles e o reset por Espaço não mudam.

### F. Testes (`tools/tests/`)
25. Reescreva `test_map_generation.gd`:
    - tire os testes de regras que deixaram de existir (forma orgânica, faixa sul, muro baixo e quebras, boca de trilha, lajotas, bolhas);
    - mantenha determinismo, RNG global, clamp e monólitos;
    - acrescente os critérios abaixo.

    Pode dividir em `test_arena_layout.gd` e `test_arena_fairness.gd`.
26. Novo `tools/tests/test_arena_visibility.gd`, com uma função pura de linha de visão sobre o `MapData`. Ela marcha o raio de 0,05 em 0,05 contra `get_height_at` (ou algo equivalente), da posição da câmera calculada a partir dos `@export` padrão de `MapCamera` (yaw, `start_distance`, inclinação, alvo). Confere os critérios V1 a V3.
27. `test_main_scene.gd`: os testes de câmera continuam passando com as distâncias novas.

## O que sai (substituído por esta spec)
- `arena_fraction_*`, `arena_shape_*`, `arena_center_jitter`, `ring_width`, `_build_arena` por máscara orgânica e limpeza da máscara.
- Os terraços em bolha (`raised_*`, `_raised_candidate`, `_add_blob`). O `open_3x3` fica.
- O muro baixo e as quebras (`wall_*`, `WallSegment`, `_build_walls`, `_break_fits`).
- A boca de trilha (`_fill_trail_mouths`), porque a trilha agora chega numa escada.
- As lajotas (`ruin_*`, `Ground.RUIN_TILE`), que viram `Ground.STONE_PATH` nas trilhas de pedra.
- As regras que supõem a câmera ao sul: `south_low_depth`, `_near_south_strip`, `_visible_step_distance`, `monolith_north_fraction`.

## Fora de escopo
- **Mecânicas futuras:** dano extra por terreno alto, cobertura, bloqueio de habilidade, linha de visão de jogo, movimento entre níveis (degrau bloqueia ou escada permite). O mapa só expõe altura e escadas como dado.
- **Mecânica de reserva:** slots, quantas peças cabem, arrastar entre reserva e arena, venda.
- **Peças, combate, loja, economia, rede.** Também a câmera padrão por time: no multiplayer, o time 1 vai começar em yaw 180 para ver a própria reserva embaixo. Isso fica para a spec de multiplayer; aqui só os dados (`team`) permitem isso.
- **Acabamento visual:** textura nova, topo de musgo, pilares, musgo caindo, máscara orgânica da terra, calçamento (spec `005` e A03); árvores 3D, troncos, cogumelos, dither (spec `006`); luz e pós (spec `004`).
- Obstáculos dentro da arena (pedras, árvores): continuam proibidos.
- Mudar `LEVEL_HEIGHT`, `TEXELS_PER_UNIT`, a inclinação ou o FOV da câmera.

## Design técnico sugerido
- **Ordem dos passos:** layout fixo → relevo da arena (metade + giro) → terra da arena (metade + giro) → relevo da floresta → trilhas → chão → monólitos → pedras → vegetação. Um sub-RNG por passo, na ordem fixa, como hoje.
- **Relevo como função pura:** `ArenaReliefGenerator` (novo script, `RefCounted`) recebe `(rng, W, D, config)` e devolve a grade de níveis da arena inteira (W × D) mais as escadas internas. Um teste pode chamá-lo sem o mapa todo.
  - Gerar a metade sul como lista de retângulos por nível, validar margens, abertura 3×3, trechos ≥ 2 e área, e tentar de novo (com limite de tentativas) se falhar.
  - Depois, girar.
  - Com W e D pares, cada célula tem par único na outra metade e nenhuma célula é o próprio par.
- **Simetria das escadas:** gire a escada inteira (as células e `up_direction`). Assim, `get_height_at(p) == get_height_at(mirror_point(p))` vale também em cima dos degraus.
- **Config:** agrupe os `@export` novos em grupos "Layout fixo", "Relevo da arena", "Floresta" e "Trilhas". Apague os campos mortos (o teste de campos da config confere isso).
- **Sem regra de jogo em nó visual:** `MapBench` e as funções de metade ficam em `scripts/map/`, puras.

## Direção de arte
- Fonte: `docs/direcao-de-arte.md` (reescrita), seção "Terreno e mapa". Alvo: `docs/reference/Gemini_Generated_Image_6oy5mo6oy5mo6oy5.jpg`, com o anfiteatro de pedra, os terraços, as escadas embutidas no terraço e a arena aberta no meio.
- Nesta spec só a **forma** importa: muros retos, cantos retos, terraços largos, nenhum dente de 1 célula. Com a arte atual vai parecer "cinza", e isso é esperado até a A03 e a `005`.

## Critérios de aceite

**Layout fixo**
- [ ] Em 20 seeds, `arena_rect`, as reservas (`rect`, `terrace_rect`, `level`), as escadas fixas, as alturas dos anéis e o `built_mask` são idênticos.
- [ ] `arena_rect.size` = (20, 18), centrado no mapa, e `size` = (44, 44) (ou os valores aprovados no P3).
- [ ] As reservas ficam fora da arena e não se sobrepõem às escadas. A do time 0 tem z maior que a arena (sul) e a do time 1 tem z menor (norte). As duas ficam no mesmo nível, `bench_level`, acima de `arena_floor_level`.
- [ ] O layout fixo é simétrico por rotação de 180°: para toda célula c de [8, 36)², a altura e o `built_mask` de c são iguais aos de `mirror(c)`.

**Funções da arena e das reservas**
- [ ] `is_inside_arena` é verdadeiro exatamente no retângulo (teste com pontos dentro, nas 4 bordas, nos cantos e fora).
- [ ] `clamp_to_arena` devolve o próprio ponto quando ele está dentro. Em 1000 pontos aleatórios de fora, o resultado está dentro e é o ponto mais próximo do retângulo (tolerância de `CLAMP_INSET`).
- [ ] O mesmo vale para `is_inside_bench` e `clamp_to_bench` nos dois times.
- [ ] `arena_side_of` dá 0 na metade sul, 1 na norte e −1 fora.

**Relevo justo** (seeds 1 a 100)
- [ ] **Simetria:** para 500 pontos aleatórios p da arena por seed (longe 0,01 das bordas de degrau), `get_height_at(p) == get_height_at(mirror_point(p))`.
- [ ] **Área por nível:** para cada nível, o número de células na metade sul é igual ao da metade norte.
- [ ] **Terraços:** células vizinhas (vizinhança 4) da arena diferem no máximo 1 nível. O nível mais alto fica entre 1 e `relief_peak_max` acima do chão.
- [ ] **Forma:** cada região de nível ≥ 1 passa na abertura 3×3, e todo trecho reto do contorno tem pelo menos 2 células.
- [ ] **Margens e área:** nenhuma célula elevada fica a menos de `relief_long_margin` das bordas compridas nem a menos de `relief_short_margin` das curtas. A área elevada fica entre 12% e 40%.
- [ ] **Conexão:** as células do chão formam uma região conexa que toca as duas bordas compridas. Toda chegada de escada (de reserva e de entrada) fica no chão.
- [ ] **Escadas internas:** toda região conexa de nível k ≥ 1 tem escada vinda de k − 1, e uma busca que só sobe e desce por escadas alcança toda célula elevada a partir do chão.
- [ ] **Modos:** `CENTRAL` e `PER_SIDE` aparecem cada um em pelo menos 30 das 100 seeds. Em `CENTRAL`, as células de nível ≥ 1 formam uma região conexa que cruza a linha do meio. Em `PER_SIDE`, formam duas regiões, uma em cada metade.
- [ ] **Variedade:** pelo menos 25 seeds têm pico de 3 níveis e pelo menos 60 grades de altura da arena são diferentes entre si.
- [ ] Com `relief_symmetry = MIRROR`, os critérios de simetria e de área passam com reflexão em z.

**Em volta**
- [ ] As 2 trilhas começam no topo das escadas de entrada e chegam na borda do mapa. Cada uma é toda `DIRT` ou toda `STONE_PATH`. Em 100 seeds, os dois tipos aparecem.
- [ ] Monólitos: de 2 a 4, fora da arena, das reservas e das escadas, a pelo menos 6 um do outro, e em pelo menos 3 dos 4 lados somando 20 seeds.
- [ ] Zonas: nenhum objeto na área útil das reservas nem nas escadas; na arena, só capim e flor; nos anéis, só vegetação baixa; o relevo da floresta é sempre ≥ `ring2_level`.
- [ ] O código e a config não têm mais os campos e funções de "O que sai" (o teste de campos da config confere).

**Visibilidade** (`test_arena_visibility.gd`, câmera padrão, seeds 1 a 50)
- [ ] **V1:** em yaw 0 e em yaw 180, os 4 cantos da área útil das **duas** reservas, a 0,6 de altura, ficam dentro do frustum da câmera.
- [ ] **V2:** em yaw 0, 90, 180 e 270, pelo menos 95% dos pontos de uma grade de 0,25 na arena, a 0,6 acima do chão, têm linha de visão livre até a câmera.
- [ ] **V3:** em yaw 0 e 180, 100% dos pontos de uma grade de 0,25 na área útil das duas reservas, a 0,6 acima do chão, têm linha de visão livre.

**Determinismo e regressão**
- [ ] A mesma seed gera o mesmo `fingerprint()` em duas gerações e em duas execuções do Godot. Nenhum `randi()`/`randf()` global na geração.
- [ ] Regenerar o mapa 10 vezes não deixa nós sobrando (teste existente).
- [ ] Os dois comandos de validação do `CLAUDE.md` e todos os testes de `tools/tests/` rodam sem `ERROR`/`SCRIPT ERROR` e sem warnings do nosso código.

**Entregáveis**
- [ ] Capturas 1280×720 em `docs/screenshots/`:
  - `007-s42-y0.png` e `007-s42-y180.png`;
  - uma seed `CENTRAL` e uma `PER_SIDE` em yaw 0 (`007-sN-y0-central.png` e `007-sM-y0-perside.png`);
  - `007-s42-y90-max.png` e `007-s42-y0-min.png`.
- [ ] Relatório do developer com:
  - arquivos criados, alterados e removidos;
  - os `@export` novos com os valores padrão;
  - a saída dos testes de visibilidade (porcentagens por yaw);
  - como testar (F5, "Gerar mapa", A/D, Espaço);
  - limitações conhecidas.
