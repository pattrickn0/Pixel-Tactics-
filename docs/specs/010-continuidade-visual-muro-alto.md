# 010 — Muro alto e continuidade visual

> **SUBSTITUÍDA por 011/A06** (2026-10-07): mapa feito à mão com kit modular, reservas no terraço, arte sem variação procedural. Mantida só como histórico.

**Depende de:** `009` (aprovada) e `A05-muro-alto-continuo.md` (aprovada antes desta; texturas `wall_face_long`, `wall_cap_long`, `wall_cap_corner`, `moss_drape_0/_1` (128×12), `stair_tread_long`, `stair_tread_short`, `stair_riser_short`).
**Decisões do usuário (2026-10-07):** crista do anel no nível 3 (1,5) e câmera padrão a ~40° (meio-termo escolhido); borda das tábuas reta também no visual; acabar com a sensação de "textura colada em bloco" com texturas melhores e um sistema de conexão (sem render em baixa resolução); câmera padrão enquadra a arena inteira com o muro sul visível. Árvores novas ficam para spec própria.

## Objetivo
O jogador vê a arena cercada por um muro de pedra de verdade (1,5 de altura: um banco de 0,5 junto à arena e um muro de 1,0 até a crista), com pedras alinhadas ao longo de todo o trecho, cantos fechados, capeamento claro com musgo pendurado e sombra no pé. O chão não tem mais escadinha de quadrados: terra, grama clara, manchas, trilha e tábuas se encontram em bordas recortadas no tamanho do texel. Na câmera padrão a arena e as duas reservas aparecem inteiras.

## Escopo

### 1. Perfil do anel: 1-3-3-1 (1 nível = 0,5, inalterado)
- Mesmos retângulos da 009. Níveis: degrau interno **1** (0,5), crista **3** (1,5), degrau externo **1** (0,5). Arena, reservas e exterior seguem no nível 0.
- Faces: piso → degrau interno = **0,5**; degrau interno → crista = **1,0**; crista → degrau externo = **1,0**; degrau externo → exterior = **0,5**. Config: `ring_step_level: int = 1` e `ring_crest_level: int = 3`; nada de números soltos.
- Por que 1-3-3-1: o banco baixo de 0,5 junto ao piso não tapa a borda da reserva sul a ~40° (com 2-3-3-2, a face de 1,0 colada à reserva esconderia a faixa z 33–33,5 do `rect`).
- **Escadas** nas mesmas células da 009, perfil oeste x 8 = 0→1, x 9 = 1→3, x 10 = 3→1, x 11 = 1→0 (leste por rotação de 180°). `MapStair` passa a aceitar subida diferente por célula (ex.: `rise_per_cell: PackedInt32Array`). Espelho sempre 0,25 (2 degraus por nível): célula que sobe 1 nível = 2 degraus com piso 0,5 (`stair_tread_long`); célula que sobe 2 níveis = 4 degraus com piso 0,25 (`stair_tread_short`); espelho com `stair_riser_short` nos dois casos. `get_height_at` acompanha os degraus.
- Laterais (bochechas) das escadas com `wall_face_long` (v contínuo, empilhando até 1,5), sem buraco entre escada e muro.

### 2. Muro contínuo (developer)
- `wall_face_long` em todas as faces do anel e bochechas de escada: **u = distância ao longo do contorno** do anel (perímetro, partindo de um canto fixo; contínuo ao dobrar cada quina convexa), **v = (y_topo_da_face − y)**. Fiadas alinhadas entre células e níveis; nada de UV por célula.
- **Quinas em 90° nas paredes construídas** (sem o chanfro `BEVEL_R` nem faces de `step_side` no anel). Barranco natural fora do anel não muda.
- **Capeamento:** tira de 0,5 de `wall_cap_long` no topo de cada face, u contínuo como a face; `wall_cap_corner` em toda quina convexa e côncava, sem sobreposição nem fresta entre tiras (sem z-fighting).
- **Musgo pendente:** `moss_drape_0/_1` presos na quina de cada face (pendendo para fora sobre a face), u contínuo, variante trocada a cada 4 unidades pelo hash do trecho (determinístico), sem cartão nas quinas sobrepondo outro.
- O piso no alto dos degraus e da crista, atrás do capeamento, continua grama (`FOREST_GRASS`).

### 3. Chão por máscara em resolução de texel (developer)
- Novo shader do chão (`scripts/map/ground.gdshader` + quem monta o `ShaderMaterial`, ex. `GroundMaterialBuilder`) usado em **todo topo horizontal** (arena, reservas, anel, exterior, calçamento). O topo de cada célula é **1 quad** (sem os sub-quads de 0,25 de `_build_arena_floor_cell` nem o desenho radial fixo da clareira).
- Entradas do shader, todas derivadas de `MapData` e da seed (função pura): textura de células 44×44 (tipo de chão, variante, nível) com filtro Nearest; campos de ruído assados de `FastNoiseLite` com `seed` da partida; as texturas de chão existentes.
- O shader quantiza a posição em texel (`floor(xz * 32.0) / 32.0`) antes de avaliar qualquer máscara e escolhe **uma** textura por texel (sem blend de cor). Transições:
  - **terra ↔ grama:** campo das células `DIRT` interpolado + ruído (escala 1 a 3) → terra / aro de `grass_arena_light` de 1 a 3 texels / grama; ilhas e dentes como em `direcao-de-arte.md`. A forma da clareira vem de `MapData` (gerador), não do mesh builder;
  - **manchas de grama da arena:** clara ~20% / base ~65% / escura ~15% por ruído em escala 4 a 10;
  - **trilha de pedra ↔ grama:** mesma técnica, com aro de grama clara;
  - **tábuas ↔ grama:** borda **reta** em z = 13 e z = 31, também no visual (nenhum texel de grama sobre as tábuas nem de tábua sobre a grama). As manchas e o aro de grama clara param na borda.
- **Sombra de contato:** no chão, faixa de 2 a 4 texels junto ao pé de toda face de muro mais alta, com a cor multiplicada por `contact_shadow_strength` (`@export`, padrão 0,7), borda quantizada no texel. SSAO continua como está.

### 4. Câmera padrão
- Ajustar `start_distance`, `pitch_degrees` e/ou `focus_south_ratio` (e `max_distance` se preciso) para que, a 1280×720 e yaw 0, **a arena e as duas reservas apareçam inteiras e sem oclusão pelo muro**, com o muro sul inteiro na tela e fora do retângulo do HUD. `pitch_degrees` padrão = **40°** (decisão do usuário; ±1° se precisar para o enquadramento).

### 5. Testes
- Atualizar `tools/tests/` (níveis 1-3-3-1, altura máxima 1,5, escadas 0→1→3→1→0) e acrescentar os critérios abaixo.

## Fora de escopo
- Árvores novas, pilares de canto, props novos, mudar vegetação.
- Gerar ou editar PNG (é a A05). Texturas de chão ficam as da A03/A04.
- Render em baixa resolução, mudar Nearest, TAA/FXAA.
- Regras de jogo sobre altura, escadas ou bloqueio; mecânica de reserva; rede.
- Apagar texturas antigas ou `arena_relief_generator.gd` (só com OK do usuário).

## Direção de arte
`docs/direcao-de-arte.md` (seções "Transições e manchas", "Pixel e filtro", "Iluminação") e a referência `docs/reference/Gemini_Generated_Image_6oy5mo6oy5mo6oy5.jpg`: muro da frente da referência (pedra seca clara, capeamento, musgo caindo), bordas de terra recortadas em pixel, chão calmo. 32 texels por unidade em toda superfície, Nearest, sem contorno.

## Critérios de aceite
- [ ] Níveis por célula: degrau interno 1, crista 3, degrau externo 1, resto 0 (fora das escadas), seeds 1–20; `get_height_at` máximo do mapa = 1,5; arena, reservas e exterior a ≥ 0,5 do anel = 0,0.
- [ ] Escadas nas mesmas células da 009, perfil 0→1→3→1→0 (2, 4, 4 e 2 degraus por célula); `get_height_at` muda só em saltos de 0,25 ao longo de cada escada; invariante à rotação de 180°.
- [ ] `pitch_degrees` padrão entre 39° e 41°.
- [ ] Na captura padrão, a borda arena/reserva é uma linha reta de pixels (nenhum texel de grama sobre tábua em z ∈ [31; 31,25) nem em z ∈ [12,75; 13)).
- [ ] Malha: em cada face do anel, a coordenada u nas duas pontas de cada quad é igual à do quad vizinho (diferença < 0,001), inclusive dobrando as quinas convexas; v = 0 no topo de cada face.
- [ ] Nenhuma face com textura `step_side*` nem vértice de chanfro no anel; quinas do anel em 90°.
- [ ] Toda quina (convexa e côncava) do capeamento tem um `wall_cap_corner`; nenhuma sobreposição de quads de capeamento no mesmo plano.
- [ ] Topo de cada célula do mapa = 1 quad (contagem de vértices do chão = 4 × células de topo, ou equivalente indexado); `grep -n "sub_size\|21.4, 21.0" scripts/map/` vazio.
- [ ] O shader do chão quantiza em 1/32 (`grep "32.0" scripts/map/ground.gdshader` mostra a quantização) e não usa `mix` entre cores de texturas diferentes.
- [ ] Mesma seed → mesmas texturas de máscara (bytes idênticos em duas gerações); seeds diferentes → máscaras diferentes. `fingerprint()` determinístico.
- [ ] Captura de perto (zoom mínimo, yaw 0, borda da clareira): borda terra/grama sem degraus alinhados a 0,25 nem a 1,0, aro de grama clara visível; anexar `docs/screenshots/010-perto.png`.
- [ ] Captura padrão `docs/screenshots/010-default.png` (1280×720, yaw 0): arena e as duas reservas inteiras, muro sul inteiro, nada da arena/reserva sob o HUD; capeamento claro destacado da grama; sombra no pé do muro.
- [ ] Teste headless de visibilidade (estender `test_arena_visibility.gd`): na distância e pitch padrão, para yaw 0, 90, 180 e 270, todo ponto de uma grade de 0,5 em `arena_rect` (recuada 0,25 das bordas) e nos `rect` das reservas (incluindo a linha z = 33,5 da reserva sul) tem linha de visão até a câmera sem cruzar o terreno (`get_height_at` ao longo do raio); para yaw 45, 135, 225 e 315, ≥ 97%.
- [ ] Capturas extras em yaw 45 e 180 (`010-y45.png`, `010-y180.png`) sem buracos/frestas de luz nas quinas, escadas e bochechas.
- [ ] Os dois comandos de validação do `CLAUDE.md` sem `ERROR`/`SCRIPT ERROR` nem warnings do nosso código; todos os `tools/tests/test_*.gd` saem com código 0.
