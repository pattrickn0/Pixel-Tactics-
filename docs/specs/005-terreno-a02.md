# 005 — Terreno com a arte A03: chão minimalista com bordas de pixel, muros de pedra com musgo, escadas e calçamento

**Status:** aprovada pelo usuário em 2026-10-06.
**Reescrita em 2026-10-06:** a versão anterior (terreno com a A02, normal maps fortes em tudo e variação macro suave) foi substituída. O nome do arquivo foi mantido para não quebrar referências.
**Depende de:**
- `007` (layout do anfiteatro, `built_mask`, escadas em 4 direções, `Ground.STONE_PATH`);
- **A03 aprovada** (texturas, normal maps e cartões `moss_fringe_*`/`grass_fringe_*`);
- `004` (luz final, para ajustar a força dos normal maps).

Dá para começar com placeholders antes da A03, mas os critérios visuais só são conferidos com a arte real.
**Próxima:** `006` (vegetação e props 3D), que reaproveita os materiais e cartões desta spec.

## O que se aproveita da versão anterior
Ficam os normal maps com tangentes, as laterais em faixas A/B, a franja em cartão presa na quina, o carregamento de cartões no `ArtLibrary` e os placeholders.

Muda o seguinte:
- os normal maps só valem para pedra e madeira, e são mais fracos;
- a "variação macro suave" sai e entram **máscaras em resolução de texel com borda de pixel**;
- o muro do anfiteatro é pedra com topo de musgo e pilares;
- a franja de grama vale só no barranco natural da floresta.

## Objetivo
O chão e os muros ficam como na referência `docs/reference/Gemini_Generated_Image_6oy5mo6oy5mo6oy5.jpg`:
- grama da arena quase lisa, com manchas grandes de luz recortadas em pixel;
- terra de um tom com borda orgânica, ilhas de grama e aro de grama clara, sem nenhuma escada de tile;
- muros de pedra seca com topo de musgo, musgo caindo pela borda e pilares nos cantos;
- escadas de pedra e trilhas de calçamento.

Girando a câmera, a luz nas pedras continua coerente com o sol.

## Escopo
1. **Normal maps no `ArtLibrary`:**
   - carrega `<nome>_n.png` só para a lista de materiais de pedra e madeira da A03 (`stone_path_*`, `wall_face`, `wall_top`, `stair_tread`, `stair_riser`, `step_side*`, `rock`, `monolith_stone`, `bark_*` e `wood_end`);
   - os `_n.png` obsoletos da A02 (`grass_*`, `dirt_*`, `leaves_mass`, `ruin_tile`) são **ignorados** mesmo existindo no disco;
   - `normal_scale` numa constante única, entre 0,4 e 0,7.
2. **Tangentes** (`ARRAY_TANGENT`) nas malhas com normal map: muros, escadas, pilares, barrancos, calçamento e pedras grandes.
   - Topos: tangente +X, v para +Z.
   - Faces verticais: tangente no sentido em que u cresce, "para cima" = +Y.
3. **Máscara do chão em resolução de texel:**
   - Uma regra pura em GDScript, `GroundMask` (`scripts/map/ground_mask.gd`, visual mas sem nó), decide qual camada vai em cada texel do topo do terreno, a partir do `MapData` e da seed: `grass_arena` (base, clara ou escura), `dirt`, `stone_path` ou `grass_forest`. O texel é `floor(xz × 32)`.
   - **Terra e calçamento:**
     - o campo é o valor da célula (1 se `DIRT`/`STONE_PATH`, 0 se não), interpolado bilinear entre os centros das células, mais ruído com seed em escala de 1 a 3 unidades (amplitude ajustável);
     - abaixo do limiar entra a terra ou a pedra;
     - numa faixa de 1 a 3 texels logo acima, o **aro de grama clara**;
     - acima disso, grama.
   - **Manchas da grama da arena:** ruído com seed em escala de 4 a 10 unidades, com dois limiares: cerca de 20% clara, 65% base e 15% escura.
   - **Variante por tile:** dentro da mesma camada, a variante (`_0` a `_3`) sai de um hash da célula. A `_3` (florida) fica em no máximo 10% das células.
   - **Fora da arena e dos anéis:** a grama de fora (`grass_forest_*`) também ganha manchas clara e escura usando as próprias variantes, sem textura nova.

   O jogo usa essa regra de uma de duas formas (escolha e relate):
   - (a) **assar** um índice de camada por texel numa textura (Nearest) que o shader do chão lê, sem passar de 300 ms por mapa no tamanho padrão (use `FastNoiseLite.get_image` para gerar o ruído em C++);
   - (b) replicar a regra num `ShaderMaterial`, mostrando no relatório uma captura de cima, lado a lado com o resultado da função GDScript na mesma área.
4. **Shader do chão:** Nearest com mipmaps, sem normal map, recebe sombra e escolhe **uma** textura por texel (nunca mistura cores). Sai a variação macro suave.
5. **Muros do anfiteatro** (faces de desnível com `built_mask`):
   - textura `wall_face` com faixas A/B, v contínuo a partir do topo da face (1 nível = 16 linhas), cantos retos;
   - **topo do muro:** nas células de cima, uma faixa de 0,5 de largura junto à borda usa `wall_top`, **no mesmo nível do chão** (sem parapeito). Nos cantos, a faixa vira em L;
   - **musgo caindo:** um cartão `moss_fringe_0`/`_1` (32×16 = 1 × 0,5) em toda borda de cima de muro, preso 0,03 a 0,06 para dentro, pendendo para fora com 10° a 25° de inclinação, com u contínuo em unidades do mundo e variante por hash do trecho. Alfa recortado, sem cull, projetando sombra;
   - **pilares:** caixas de 0,75 × 0,75, com o topo 0,25 acima do nível de cima, em `wall_face` + `wall_top`. Ficam nos cantos externos dos anéis e das reservas e nas duas laterais de cada escada do anfiteatro. Nada de pilar no meio da arena;
   - no relevo de dentro da arena (`007`, terraços de 1 nível), o mesmo muro com topo de musgo e musgo caindo, **sem pilares**.
6. **Escadas** (todas, nas 4 direções): piso `stair_tread`, espelho `stair_riser` (uma faixa de 8 linhas por degrau, alternando por degrau) e laterais da escada embutida em `wall_face`.
7. **Barranco natural** (faces fora do `built_mask`): `step_side`/`step_side_grass` como hoje, com o chanfro atual e a franja `grass_fringe_0`/`_1` na quina de cima (mesma regra do musgo caindo).
8. **Calçamento:** `Ground.STONE_PATH` usa `stone_path_0`/`_1` pela máscara do item 3.
9. **Placeholders e paleta:**
   - `scripts/core/palette.gd` passa a ter a paleta da A03;
   - `PlaceholderArt` gera placeholders para todos os nomes da A03 (texturas, normal maps planos e cartões), nos tamanhos da A03 e com a paleta nova. Os placeholders seguem a regra minimalista (tom base liso e poucos tracinhos).
10. **Capturas** 1280×720 em `docs/screenshots/`:
    - `005-s42-y0.png`;
    - `005-s42-y180.png`;
    - `005-s42-y0-min.png` (de perto, com terra, muro com musgo e escada);
    - `005-s1337-y90.png`;
    - `005-s42-y0-min-nonormal.png` (como `-min`, com `normal_scale = 0`).

## Fora de escopo
- Árvores, coníferas, arbustos, troncos, tocos, cogumelos, monólitos, capim e flores 3D, dither e mata de fundo (spec `006`).
- Luz e pós (spec `004`). Aqui só se ajusta a força dos normal maps.
- Mudar a geração (`007`), criar tipos de chão novos ou editar PNG.

## Design técnico sugerido
- **Dados para o shader:** uma `Image` do tamanho do mapa (1 texel por célula) com o tipo de chão e as flags (arena, `built_mask`), mais as imagens de ruído geradas com `FastNoiseLite.get_image` com a seed do mapa. Para o campo da terra, amostre a imagem por célula com filtro linear, ou faça a interpolação à mão no shader.
- **Faixa de `wall_top`:** pode ser uma camada a mais da máscara (texels a menos de 0,5 de uma borda de cima de muro) ou uma tira de geometria 0,002 acima do chão. Prefira a máscara (sem z-fighting) e relate a escolha.
- **Cartões de borda:** reaproveite o caminho já usado na franja. Uma superfície por variante.
- **Força do normal map:** comece com 0,5 e ajuste pelas capturas. O relevo das pedras tem que aparecer, sem chiado.

## Direção de arte
- Fonte: `docs/direcao-de-arte.md`, seções **Transições e manchas**, **Normal maps**, **Laterais em faixas** e **Terreno e mapa**.
- Alvo: a referência do Gemini (grama da arena, terra, muro do anfiteatro, escadas e calçamento).
- O alvo intermediário é o mosaico de chão da prévia `docs/art-preview/a03-texturas.png`: o chão do jogo tem que parecer com ele.

## Critérios de aceite

**Funcionais (testes headless em `tools/tests/`)**
- [ ] **`GroundMask` é determinística:** a mesma seed e a mesma posição dão a mesma camada, e seeds diferentes dão manchas diferentes.
- [ ] **Borda orgânica:**
  - nas seeds 1 a 10, dos texels de borda da terra (terra com vizinho de outra camada), no máximo 25% ficam exatamente numa aresta de célula;
  - nenhum trecho reto de borda tem mais de 6 texels seguidos;
  - todo texel de terra que encosta em grama da arena tem um aro de grama clara de 1 a 3 texels.
- [ ] **Ilhas:** em pelo menos 7 das seeds 1 a 10, existe uma ilha de grama (componente de grama cercado de terra) dentro das manchas de terra da arena.
- [ ] **Manchas da grama:** na grama da arena das seeds 1 a 10, a camada clara cobre de 12% a 28%, a escura de 8% a 22%, e a base o resto.
- [ ] **Normal maps:** os materiais de pedra e madeira têm `normal_texture`; os de grama, terra e folhagem não, mesmo com os `_n.png` antigos no disco. Sem os `_n.png`, o jogo roda sem erro.
- [ ] Toda superfície com normal map tem `ARRAY_TANGENT` perpendicular à normal (|produto escalar| < 0,01).
- [ ] O número de cartões de musgo caindo é igual ao número de trechos de borda de cima de muro, e o de franja de grama, ao de trechos de barranco com grama.
- [ ] Os pilares ficam só nos cantos e nas laterais das escadas do anfiteatro, nenhum dentro da arena. A mesma seed gera malhas idênticas (mesmo hash dos arrays).
- [ ] Se a máscara for assada (opção a), ela leva no máximo 300 ms por mapa no tamanho padrão.
- [ ] Os placeholders cobrem todos os nomes da A03. O `--placeholder-art` roda sem erro.

**Visuais (revisão nas capturas)**
- [ ] A grama da arena parece a da referência: quase lisa, com manchas grandes recortadas em pixel. Sem grade, sem carpete e sem repetição visível de longe.
- [ ] A terra tem borda orgânica recortada em pixel, ilhas de grama e aro claro. Nenhuma escada de tile.
- [ ] Os muros parecem pedra seca com topo de musgo e musgo caindo, com pilares nos cantos. Não aparece zigue-zague de tile.
- [ ] **Orientação da luz:** em `005-s42-y0-min.png` e `005-s42-y180.png`, o lado das pedras voltado para o sol é o mais claro.
- [ ] Comparando `-min` com `-min-nonormal`, o relevo das pedras aparece mais com o normal map, sem chiado.
- [ ] Os cartões de borda não somem nem piscam com a distância.

**Processo**
- [ ] Os dois comandos de validação do `CLAUDE.md` rodam sem erros, e todos os testes de `tools/tests/` passam.
- [ ] As 5 capturas estão em `docs/screenshots/`. O relatório traz a escolha (a) ou (b) da máscara e o FPS médio em 1920×1080, seed 42, yaw 45 e zoom máximo (≥ 60).
