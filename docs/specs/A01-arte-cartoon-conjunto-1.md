# A01 — Arte cartoon, conjunto 1 (terreno, muro, vegetação e monólitos)

## Objetivo
Produzir o primeiro conjunto de arte do jogo no estilo da imagem da clareira (`docs/reference/Screenshot 2026-10-04 160858.png`): as texturas 32×32 do terreno 3D e os sprites em pé que o mapa da spec `001` usa. Com eles no lugar, o mapa deixa de usar placeholders.

## Escopo
Todos os arquivos abaixo, com **exatamente** estes caminhos, nomes e tamanhos (o código da spec `001` carrega por nome).

### Texturas — `assets/textures/` (32×32, opacas, seamless)
| Arquivo | Ponto de vista | Conteúdo |
|---|---|---|
| `grass_arena_0.png` … `grass_arena_3.png` (4) | de cima | Grama clara da arena. Base `#8DB846`, manchas arredondadas `#6B9B37`, tufos vistos de cima `#B3CF5E` com sombra `#6B9B37`/`#4E7A2A` embaixo-direita. 0–2 limpas; a 3 pode ter 2–3 florzinhas planas de 2×2 (`#F2E27A` ou `#ECEBDF`). A mais limpa e legível do conjunto. |
| `grass_forest_0.png` `grass_forest_1.png` (2) | de cima | Chão da mata: base `#4E7A2A`, manchas `#315740`, tufos `#6B9B37`, sombra pontual `#236460`. Mais escura e fria que a da arena, pouco contraste. |
| `dirt_0.png` `dirt_1.png` (2) | de cima | Terra da trilha: base `#C2A57A`, manchas gastas `#E0CDA0`, sombras `#8A6E4B`/`#6E5538`, pedrinhas de 2–3 px em `#4D6862`/`#6C948B`. |
| `ruin_tile.png` | de cima | Lajotas de ruína (como em volta dos monólitos na clareira): placas de ~12–15 px com quinas gastas, base `#6C948B`, borda de luz `#A9C3B8` em cima-esquerda, sombra `#4D6862` embaixo-direita, rachaduras `#374845`; juntas de 1–2 px com grama `#4E7A2A`/`#6B9B37`. |
| `step_side.png` | de frente | Lateral de degrau em pedra terrosa (como o terraço da clareira): blocos arredondados e gordos, 2–3 por fileira, fileiras de 10–16 px. Face `#634E45`, topo de cada bloco `#B47262` com brilho `#D68775` em cima-esquerda, fendas `#47443B`/`#2B3A2A`. Seamless na horizontal e na vertical. |
| `step_side_grass.png` | de frente | **Igual** a `step_side.png`, com franja de grama por cima: a primeira linha inteira é grama, e a franja cai em "gotas" arredondadas de 3–9 px de comprimento (topo 6–12 px do tile), tons `#8DB846` `#6B9B37` `#4E7A2A`. Abaixo da franja, os pixels são os mesmos de `step_side.png`. |
| `wall_face.png` | de frente | Face do muro da arena: cantaria (blocos retangulares 16×8 e 8×8 em fileiras desencontradas), quinas arredondadas. Faces `#976759`, luz `#B47262`, brilho `#D68775` em cima-esquerda, sombra `#634E45` embaixo-direita, juntas `#47443B`; musgo `#6B9B37`/`#4E7A2A` no topo de 1–2 blocos. Mais claro que `step_side`, para a borda da arena se destacar. Seamless nos dois eixos. |
| `wall_top.png` | de cima | Topo do muro: blocos vistos de cima, base `#B47262`, luz `#D68775`, juntas `#634E45`/`#47443B`, um pouco de musgo `#6B9B37`. Seamless. |
| `rock.png` | sem direção | Superfície das pedras grandes 3D em pedra fria: facetas irregulares, base `#4D6862`, luz `#6C948B`, brilho `#A9C3B8` raro, rachaduras `#374845`/`#232B2B`. Sem luz pintada forte (a malha 3D é iluminada pelo motor). Seamless. |

### Sprites em pé — `assets/sprites/` (fundo transparente, vistos de frente com leve 3/4 de cima)
| Arquivo | Canvas | Desenho | Conteúdo |
|---|---|---|---|
| `tree_big_0.png` … `tree_big_2.png` (3) | 96×128 | 64–94 × 96–127 | Árvore de fundo da mata. Copa de 5–9 "bolhas" redondas sobrepostas (raio 10–20 px) ocupando o topo ~70–80% da altura; tronco de 10–16 px de largura visível embaixo, com 2–3 raízes abertas tocando a última linha. Copa: contorno `#0B1228`, sombra `#111A33`, base `#192649`, luz `#224956`, brilho `#236460` e toques de `#458946` só nas bolhas de cima. Tronco: Madeira (`#3B2A1E` `#5C3F2A` `#7E5A3A`), mais escuro logo abaixo da copa, contorno `#2B3A2A`. Variantes: 0 redonda e larga, 1 oval e alta, 2 assimétrica. |
| `tree_small_0.png` `tree_small_1.png` (2) | 64×96 | 48–62 × 64–95 | Mesma família, copa de 3–5 bolhas, tronco de 6–10 px. Mais clara que a grande: sombra `#192649`, base `#224956`, luz `#236460`, brilho `#458946`. |
| `bush_0.png` … `bush_2.png` (3) | 32×32 | 20–30 × 16–30 | Arbusto de 2–4 bolhas, sem tronco, base reta e larga (≥ 16 px) na última linha. Tons como a árvore pequena. A variante 2 tem 3–5 florzinhas lilás de 2×2 (`#B76CC5`, sombra `#8B5396`), como os arbustos ao fundo da clareira. |
| `grass_tuft_0.png` … `grass_tuft_2.png` (3) | 16×16 | 8–14 × 6–14 | Capim: 4–7 folhas pontudas saindo de uma base comum, folhas com ≥ 3 px de largura na base afinando até a ponta. 0 e 1: tons de Grama (`#4E7A2A` `#6B9B37` `#8DB846`, pontas `#B3CF5E`), contorno `#24302A`. 2: tons da Mata (`#192649` `#224956` `#236460`, pontas `#458946`), contorno `#0B1228`. |
| `flower_0.png` … `flower_2.png` (3) | 16×16 | 8–14 × 8–14 | Tufo de 2–3 flores em hastes curtas com 1–2 folhas (`#4E7A2A` `#6B9B37`, contorno `#24302A`). 0 amarela (`#F2E27A`, miolo `#C2A57A`), 1 branca (`#ECEBDF`, miolo `#F2E27A`), 2 lilás (`#B76CC5`/`#8B5396`, miolo `#F2E27A`). |
| `monolith_0.png` | 32×96 | 20–30 × 80–95 | Monólito alto, topo arredondado (como o central da clareira). Pedra fria: face iluminada `#6C948B` com aresta `#A9C3B8` à esquerda, base `#4D6862`, lado direito em sombra `#374845`, rachaduras finas `#232B2B`, musgo `#4E7A2A`/`#6B9B37` perto da base; contorno `#0B1228`. **2 runas** redondas de 6–8 px: aro `#67A7A5`, base `#3AD1CC`, núcleo `#48FDFD`, brilho `#A3F9F7` (1–2 px em cima-esquerda). |
| `monolith_1.png` | 32×64 | 20–30 × 48–63 | Monólito mais baixo com topo **quebrado** em diagonal, mesma pedra, **1 runa**. |
| `monolith_0_rune.png` | 32×96 | — | Máscara da runa: só os pixels da runa de `monolith_0.png` (cores do grupo Runa), nas mesmas posições; todo o resto transparente. O código usa para o brilho (glow). |
| `monolith_1_rune.png` | 32×64 | — | Idem para `monolith_1.png`. |

### Scripts e prévias
- Gerador: `tools/art/gen_a01.gd` (`extends SceneTree`), pode dividir em `gen_a01_textures.gd` e `gen_a01_sprites.gd` e usar ajudantes por `preload`. Paleta em `tools/art/palette.gd` com os hex exatos de `docs/direcao-de-arte.md`.
- Checagem: `tools/art/check_a01.gd` (`extends SceneTree`): verifica todos os critérios automáticos abaixo nos PNG de `assets/`, imprime uma linha por arquivo e no fim `A01 CHECK: PASS` ou `A01 CHECK: FAIL (n problemas)`, e sai com código 0/1. Leia os PNG do disco (`Image.load_from_file(ProjectSettings.globalize_path(...))`), sem depender do import.
- Prévias em `docs/art-preview/` (largura máxima ~1600 px; quebre em linhas):
  - `a01-texturas.png`: cada textura ×4 sozinha e repetida 4×4 a ×2; um mosaico 8×8 a ×2 misturando as 4 `grass_arena_*` ao acaso; uma coluna de 3 tiles de largura com `step_side_grass` em cima de 2 `step_side` (degrau de 3 níveis).
  - `a01-sprites.png`: todos os sprites ×4 sobre fundo cinza neutro e, numa segunda faixa, ×2 sobre `grass_arena_0` repetida (para ver o contraste com o chão).
  - `a01-cena.png`: composição 2D simples, a ×2, para comparar com a clareira: mata de `grass_forest` com árvores grandes e pequenas sobrepostas ao fundo, um degrau (`step_side_grass` + `step_side`) e um trecho de `wall_face`/`wall_top`, grama da arena na frente com capim e flores, dois monólitos na lateral. Não é tela do jogo; serve só para julgar a harmonia do conjunto.

## Fora de escopo
- Personagens/peças, UI, fontes, água, construções, estátuas, vasos.
- Animação (frames), normal maps, sombras desenhadas, halo ou glow pintado.
- Texturas de transição (feitas no código), textura própria de escada (o código reaproveita `dirt_*` e `wall_face`), lateral de terra.
- Mudar `project.godot`, criar/editar `.import` (se o import precisar de ajuste, reporte para o developer), mexer em `scripts/`, `scenes/` ou `docs/specs/`.
- Novas cores fora da paleta. Se faltar cor, escreva a proposta no relatório; não pinte.

## Design técnico sugerido
- Um RNG com seed fixa por arquivo (ex.: hash do nome), para mexer num item sem mudar os outros.
- **Texturas seamless:** desenhe com coordenadas em módulo 32. Para as famílias com variantes (`grass_arena_*`, `grass_forest_*`, `dirt_*`), gere **uma vez** a faixa de 3 px junto às 4 bordas e use os **mesmos pixels** nela em todas as variantes da família; varie só o miolo (26×26). Assim qualquer variante encaixa ao lado de qualquer outra. Faça o miolo continuar a faixa sem costura visível.
- `step_side_grass` = cópia de `step_side` + franja pintada por cima.
- **Sprites:** monte por formas (círculos/elipses para bolhas, retângulos arredondados para tronco e pedra), pinte os 3 tons por forma (luz em cima-esquerda, sombra embaixo-direita) e só no fim aplique o contorno de 1 px em volta da silhueta inteira. Limpe pixels órfãos e degraus irregulares nas curvas.
- Máscara da runa: gere a partir do próprio sprite (copiar os pixels com cor do grupo Runa).
- Scripts sem `class_name` (não poluir o namespace do jogo).
- Comandos:
  ```bash
  G="/c/Users/pattr/Downloads/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe"
  "$G" --headless --path . --script tools/art/gen_a01.gd
  "$G" --headless --path . --script tools/art/check_a01.gd
  ```

## Direção de arte
- Fonte única: `docs/direcao-de-arte.md` (paleta, regras cartoon, regras de sprite e textura, escala). Alvo de estilo: a imagem da clareira. Releia as seções **Forma (regras cartoon)**, **Paleta** e **Uso por material** antes de começar.
- Cartoon: contorno 1 px escuro colorido nos sprites, **3 tons por material** (+1 brilho pontual), formas arredondadas e simples, clusters de 2×2 px ou mais. Nada de ruído pixel a pixel.
- Profundidade pela cor: árvores grandes mais escuras e azuladas (fundo), árvores pequenas e arbustos um pouco mais claros e verdes, grama da arena clara e quente. O único brilho do conjunto é a runa ciano.
- Texturas sem contorno na borda do tile e sem gradiente global; luz cima-esquerda só no nível do detalhe.

## Critérios de aceite

**Automáticos (`tools/art/check_a01.gd` sai com `A01 CHECK: PASS`)**
- [ ] Todos os 14 PNG de `assets/textures/` e os 18 de `assets/sprites/` (16 sprites + 2 máscaras) listados acima existem, com as dimensões exatas da tabela, em RGBA8.
- [ ] Paleta: todo pixel opaco de todo arquivo é **exatamente** uma cor da tabela Paleta de `docs/direcao-de-arte.md`.
- [ ] Texturas: todos os pixels com alfa 255.
- [ ] Sprites e máscaras: alfa só 0 ou 255.
- [ ] Sprites (exceto máscaras): primeira linha, primeira coluna e última coluna 100% transparentes; última linha com pelo menos 2 pixels opacos, e o meio do trecho opaco da última linha a no máximo 2 px do centro do canvas; caixa do desenho dentro da faixa "Desenho" da tabela.
- [ ] Contorno: nos sprites (exceto máscaras), pelo menos 90% dos pixels opacos vizinhos (vizinhança 4) de um pixel transparente ou da borda do canvas são de uma cor de contorno: `#0B1228` `#1A2420` `#24302A` `#2B3A2A` ou o tom mais escuro de um grupo (`#4E7A2A` `#315740` `#111A33` `#6E5538` `#47443B` `#232B2B` `#3B2A1E` `#8B5396`). Para os sprites de 16×16, pelo menos 75%.
- [ ] Poucos tons (cartoon), cores opacas distintas por arquivo no máximo: `grass_arena_*` 6, `grass_forest_*` 5, `dirt_*` 7, `ruin_tile` 8, `step_side` 7, `step_side_grass` 10, `wall_face` 8, `wall_top` 8, `rock` 6, `tree_big_*` 12, `tree_small_*` 12, `bush_*` 9, `grass_tuft_*` 5, `flower_*` 7, `monolith_*` 12.
- [ ] Pixels órfãos (nenhum dos 8 vizinhos com a mesma cor; nas texturas, vizinhos com wrap em 32) no máximo 3% dos pixels opacos de cada arquivo (exceto máscaras).
- [ ] Sem gradiente global nas texturas: a luminância média da metade esquerda e da direita difere no máximo 0,06 (escala 0–1), e a de cima e de baixo também (exceto `step_side_grass` no eixo vertical).
- [ ] Famílias com variantes (`grass_arena_*`, `grass_forest_*`, `dirt_*`): pixels idênticos entre as variantes na faixa de 3 px das 4 bordas, e miolos diferentes entre si.
- [ ] `step_side_grass.png`: as 16 linhas de baixo são idênticas às de `step_side.png`; a primeira linha só tem tons de Grama.
- [ ] Máscaras `monolith_N_rune.png`: cada pixel opaco tem a mesma cor do pixel na mesma posição de `monolith_N.png` e é do grupo Runa; todo pixel do grupo Runa em `monolith_N.png` é opaco na máscara; `monolith_0` tem 2 regiões de runa separadas e `monolith_1` tem 1.

**Visuais (revisão pelo Lead Project nas prévias)**
- [ ] Texturas repetidas 4×4 e o mosaico de variantes sem emenda visível nem padrão gritante; o degrau de 3 níveis empilha sem costura e a franja de grama cai em gotas arredondadas.
- [ ] Silhuetas legíveis e arredondadas, sem "jaggies" e sem ruído; copas em bolhas, não pinheiros.
- [ ] `a01-cena.png` parece da mesma família da clareira de referência: mata escura azulada, grama clara, pedra terrosa avermelhada, runa ciano como único brilho.
- [ ] Nenhuma sombra no chão, halo, gradiente suave ou anti-aliasing.

**Processo**
- [ ] Rodar `gen_a01.gd` duas vezes gera arquivos idênticos (ex.: `md5sum assets/textures/*.png assets/sprites/*.png` igual antes e depois).
- [ ] Os dois comandos de validação do `CLAUDE.md` rodam sem `ERROR` depois que os PNG existem (o import não falha).
- [ ] Relatório de entrega no formato do `artist`, com autocrítica comparando com a clareira.

## Revisão v1: APROVADO
**Data:** 2026-10-04

**O que foi conferido**
- `check_a01.gd`: `A01 CHECK: PASS`, exit 0. O verificador foi lido e cobre todos os critérios automáticos (paleta com os 43 hex exatos, alfa, bordas, base centralizada, caixa do desenho, contorno 90%/75%, cores máximas, órfãos, luminância, faixa de 3 px das famílias, `step_side_grass`, máscaras e regiões de runa).
- Determinismo: `gen_a01.gd` rodado 2 vezes. O md5 dos 32 PNG e das 3 prévias ficou igual ao da entrega nas duas rodadas. Os scripts não usam `class_name` nem RNG global.
- Import: `--editor --quit` sem `ERROR`, e os 32 PNG estão importados em `.godot/imported`.
- Contagens extras: `grass_arena_3` tem 3 flores de 2×2. A franja de `step_side_grass` desce de 4 a 11 px. Tronco das árvores grandes com 16 px e das pequenas com 10 px. Base de `bush_*` com 18 a 22 px. `bush_2` tem 5 flores lilás. `grass_tuft_2` tem pontas `#458946`.
- Visual: `a01-cena.png` é da mesma família da clareira (mata escura azulada, grama clara e quente, pedra terrosa avermelhada, pedra fria nos monólitos e lajotas, runa ciano como único brilho). O mosaico 8×8 de `grass_arena_*` não tem emenda nem padrão gritante. O degrau de 3 níveis empilha sem costura e a franja cai em gotas. Não há sombra no chão, halo, gradiente nem anti-aliasing.

**Observações não bloqueantes** (para uma próxima spec de arte, A02. Os nomes de arquivo continuam os mesmos, então o developer já pode integrar tudo)
1. `tree_big_*`, `tree_small_*`: as bolhas são lisas, com contorno de círculo perfeito, e todas repetem o mesmo arco de destaque em "C". Em mata densa, isso vai parecer "carimbado". Esperado: bordas com pequenos recortes de folhagem (3 a 5 px) e destaque variando de bolha para bolha, como as copas de `ref-floresta-vila.png` e o fundo da clareira.
2. `tree_big_0..2`: o tronco é idêntico nas 3 variantes, não fica mais escuro logo abaixo da copa e as raízes quase não abrem (largura 16 → 20 px na base). Esperado: tronco variando um pouco entre as variantes, faixa `#3B2A1E` sob a copa e 2 ou 3 raízes visíveis.
3. `rock.png`: a pedra saiu estratificada, em faixas horizontais, e não "facetada" como pede a spec. Aceito nesta fase porque é coerente com a pedra fria e a pedra grande fica fora da arena. Se as faixas ficarem estranhas na malha 3D (topo listrado), refazer com facetas irregulares sem direção.
4. `wall_face.png`: o musgo cai sempre no mesmo ponto a cada 32 px, e no muro de 16 texels de altura isso vira uma marca regular em toda a borda da arena. `step_side.png` repete o mesmo arranjo de blocos. `grass_forest_*`: a mancha `#315740` na quina (dentro da faixa compartilhada) forma uma grade a cada 32 px. Esperado: `wall_face_1` e `step_side_1` como variantes, e uma faixa compartilhada mais neutra em `grass_forest_*`.
5. `wall_top.png`: está correto pela paleta, mas quase chapado. Iluminado pelo sol quente, pode virar uma faixa salmão uniforme. Esperado: um pouco mais de contraste por bloco (sombra `#976759` embaixo-direita, rachaduras). Avaliar no jogo antes de mexer.
6. `bush_0`, `bush_1`: as divisões internas entre bolhas são retas e deixam o arbusto com cara de pedra lapidada quando ampliado. Esperado: divisões curvas, como nas copas.
7. `flower_*` e as flores de `grass_arena_3`: em 16×16 e 2×2, viram pontos de cor à distância. É limitação do tamanho e não defeito. Reavaliar com a câmera real.
