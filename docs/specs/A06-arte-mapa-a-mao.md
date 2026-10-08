# A06 — Arte do mapa feito à mão (peças únicas)

**Substitui:** `A05` (nunca gerada; o que servia dela está aqui) e as texturas de chão, muro, escada e folhagem da `A03`. **Usada por:** `011` (o developer integra na Fase 3; até lá usa provisórias).
**Depende de:** `docs/direcao-de-arte.md` (paleta, regras de textura e cartão) e a referência `docs/reference/Gemini_Generated_Image_6oy5mo6oy5mo6oy5.jpg`.
**Decisões do usuário (2026-10-07):** a arte não é procedural. Cada textura, decalque e cartão é uma peça única e intencional, desenhada por script com formas, posições e cores escritas no código. Escala inalterada (32 texels/unidade, Nearest).
**Exceção de tamanho (vale esta spec, que é a mais recente):** várias peças não são 32×32 (tiras longas, decalques). A densidade continua 32 texels por unidade.
**Revisão 1 (2026-10-07):** faixas do muro, da crista, da grama da arena e regras de contorno e de lajes ajustadas para o resultado poder ficar como a referência. Onde esta spec e `docs/direcao-de-arte.md` divergem em contagem de cores e faixas, vale esta spec.

## Objetivo
Dar ao mapa da 011 a cara da referência: grama lisa, mancha de terra orgânica com aro de grama clara, manchas de grama desenhadas, lajes de trilha irregulares, muro de pedra seca com capeamento de musgo, escadas largas, copas redondas e grumosas, coníferas em camadas. Tudo lido de longe como a imagem, e de perto como pixel art limpa.

## Regras gerais desta spec
- **Sem RNG e sem ruído.** Os geradores não usam `RandomNumberGenerator`, `FastNoiseLite`, `randi`, `randf` nem hash de posição como fonte de variação. Contornos, manchas, pedras, lajes, tufos e folhas vêm de **tabelas literais** no script (listas de pontos, retângulos, posições). Funções de desenho (polígono, bloco, aglomerado) podem existir, mas os parâmetros de cada chamada estão escritos à mão.
- **Contornos (rev. 1):** todo contorno de mancha, ilha, decalque e laje é uma lista de vértices em coordenadas absolutas (x, y) escrita à mão, com espaçamento irregular entre vértices. Proibido: forma por raios polares em volta de um centro, elipse/círculo com variação, a mesma lista de raios ou de vértices reaproveitada em escala, e divisão por ponto mais próximo (Voronoi). Um pós-passe determinístico de limpeza de borda (ex.: `break_edges`) é permitido só para quebrar retas que sobrarem; ele não pode ser a fonte da forma.
- Paleta, tons por material, alfa binário, sem contorno, sem luz lateral, sem gradiente global e normal map só em pedra e madeira: como em `docs/direcao-de-arte.md`.
- Decalques e cartões: alfa 0 ou 255. Pixels transparentes com RGB igual ao do vizinho opaco mais próximo (evita franja escura no mipmap).
- Seamless só onde a tabela pede.
- Normal map `<nome>_n.png` com o mesmo tamanho do albedo, convenção OpenGL, do mapa de altura da arte, com wrap nos eixos seamless.

## Escopo — arquivos

### 1. Chão (opaco, vista de cima, `assets/textures/ground/`)
| Arquivo | Tamanho (un.) | Conteúdo |
|---|---|---|
| `ground_grass_arena.png` | 64×64 (2 × 2) | Grama da arena, do terraço e da crista. Base `#5B9C47` ≥ 75%; 10 a 20 tracinhos de 2 a 4 px (`#73A949`, `#4E9343`) em posições escritas à mão, nenhum par igual; no máximo 1 florzinha. Seamless nos 2 eixos. |
| `ground_grass_forest.png` | 64×64 (2 × 2) | Grama de fora. Base `#3D853C` ≥ 70%; tracinhos `#2C7036`/`#539342`; até 2 folhas caídas (`#876547`). Seamless nos 2 eixos. |

### 2. Decalques de chão (alfa binário, vista de cima, `assets/textures/decals/`)
| Arquivo | Tamanho (un.) | Conteúdo |
|---|---|---|
| `decal_arena_dirt.png` | 448×352 (14 × 11) | **A** mancha de terra da arena, peça única. Terra `#C0AE71` dominante, pedrinhas raras `#A8955F`/`#D4C48C`. Contorno decalcado da mancha da referência: 5 a 8 lóbulos de tamanhos bem diferentes e 2 a 4 **baías de grama** entrando de 24 a 80 px pela borda (nada de elipse nem de blob com bordinha serrilhada uniforme); 4 a 10 **ilhas de grama** dentro, de formas e orientações diferentes, pelo menos 2 com 24 px ou mais no maior eixo, nenhuma em formato de cápsula/losango (buracos com grama `#73A949`/`#5B9C47` e tracinhos, ou transparentes); **aro de grama clara** `#73A949` de 1 a 3 px em toda a borda e em volta das ilhas; 3 a 6 "dentes" e ilhotas soltas de terra fora da borda. Borda recortada em pixel, nenhum trecho reto com mais de 6 px. Margem transparente de pelo menos 4 px. |
| `decal_grass_light_0` `_1` `_2` | 160×96, 128×128, 96×64 | Manchas de grama clara (base `#73A949`, tracinhos `#98B654`/`#5B9C47`), formas diferentes entre si, borda recortada. |
| `decal_grass_dark_0` `_1` | 128×96, 96×96 | Manchas de grama escura (base `#4E9343`, tracinhos `#5B9C47`). |
| `decal_forest_soil_0` `_1` | 128×96, 96×128 | Terra de mata sob árvores (Terra escura `#5A4632`/`#7A6444`, raízes e folhas `#876547`), borda em grama de fora `#2C7036` de 1 a 2 px. Como a terra escura no canto de baixo à direita da referência. |
| `decal_trail_0` … `_3` | 96×96 (3 × 3) | Trecho reto de trilha de lajes, de oeste a leste. Lajes irregulares de 14 a 32 px, cada uma um polígono de 4 a 7 vértices escrito à mão (lajes achatadas e alongadas como na trilha da referência, não células de colmeia), tom dominante `#B9B597` (≥ 50% das lajes), `#D3CCB4` em ≤ 20% delas (`#989680` no resto; aresta de cima de cada laje 1 tom mais clara), juntas `#7A7A66` (com `#5C6250` só nos cruzamentos), musgo `#5E7C26`/`#789636` em 2 a 5 juntas. Largura da trilha de 64 a 84 px, laterais irregulares com aro de grama clara de 1 a 2 px. **Encaixe:** colunas 0–1 e 94–95 iguais nas 4 variantes (mesmo perfil de laje e mesmas linhas opacas), para encadear em qualquer ordem. |
| `decal_trail_bend` | 96×96 | Curva de 90° (entra pela esquerda, sai por baixo), com os mesmos perfis de encaixe nas colunas 0–1 e nas linhas 94–95. |

### 3. Muro e escada (opaco + `_n`, `assets/textures/wall/`)
Pedra seca como o muro da frente da referência: blocos de 6 a 24 px de largura e 4 a 10 px de altura, fiadas de alturas desiguais que ondulam ±1 px, alguns blocos ocupando 2 fiadas, cantos lascados (1 a 2 px comidos pela junta) em pelo menos metade dos blocos; juntas `#34403C` de 1 a 2 px (`#1C2B2B` só nos cruzamentos e nas juntas mais fundas), blocos `#7A7A66` `#989680` `#B9B597` (`#D3CCB4` só na aresta de cima de blocos claros), aresta de cima 1 tom mais clara; musgo em 3 tons (`#496819` `#5E7C26` `#789636`, `#8FAE48` opcional nas pontas de luz) em manchas de 4 a 14 px no topo e escorrendo de juntas. Nada de bloco retangular perfeito com retângulo interno claro. Nenhum bloco repetido (mesma forma e tons). Sem escurecer a base (a sombra é do motor).
| Arquivo | Tamanho (un.) | Conteúdo |
|---|---|---|
| `wall_high_face.png` | 256×48 (8 × 1,5) | Face do muro alto. A face externa usa as 48 linhas; a interna (1,0) usa as linhas 0–31, então **as linhas 0–31 sozinhas também leem como muro completo**. Musgo 8% a 20%, mais no terço de cima. Seamless na horizontal. |
| `wall_low_face.png` | 256×16 (8 × 0,5) | Face do degrau baixo: 2 fiadas, blocos mais compridos e baixos (meio-fio). Seamless na horizontal. |
| `wall_crest.png` | 256×32 (8 × 1) | Topo do muro alto visto de cima: lajes de capeamento claras (`#B9B597` `#D3CCB4`, bordas `#989680`) de 10 a 30 px, com contorno irregular, nas linhas 0–9 e 22–31 (as duas bordas), algumas invadidas pelo musgo e com falhas; miolo com musgo (`#5E7C26` `#789636` `#8FAE48` `#B0C860`) em manchas, nunca em listra de tracinhos repetidos. Musgo 40% a 65% no total. **Coluna 0 = junta vertical** nas duas faixas de laje. **Linha 0 = lado externo** (floresta). Seamless na horizontal. |
| `wall_cap.png` | 256×16 (8 × 0,5) | Capeamento do degrau baixo: uma fila de lajes de 10 a 24 px; linha 0 = beirada sobre a face; musgo 20% a 40%, mais perto da linha 15. Seamless na horizontal. |
| `wall_quoin.png` | 32×48 (1 × 1,5) | Face de 1 unidade junto à quina do muro alto: blocos de amarração alternando longo (20 a 28 px) e curto (10 a 14 px) encostados na coluna 31, para casar com a outra face girada. Coluna 0 compatível com `wall_high_face`. |
| `wall_crest_corner.png` | 32×32 | Topo da quina do muro alto: lajes em L nas bordas externas **linha 0 e coluna 31**, laje do canto interno nas linhas 22–31 × colunas 0–9, musgo no miolo. Junta de 1 px (`#989680`) na coluna 0 (linhas 0–9 e 22–31) e na linha 31 (colunas 0–9 e 22–31): é onde a crista encosta, então qualquer laje cortada da crista lê como laje inteira. |
| `wall_cap_corner.png` | 16×16 | Laje de canto do capeamento do degrau baixo. Linha 0 e coluna 15 = beiradas sobre as faces; junta de 1 px na coluna 0 e na linha 15 onde o capeamento encosta. |
| `stair_tread_0` `_1` | 96×16 (3 × 0,5) | Piso de degrau (largura toda do lance). Linha 0 = bocel `#D3CCB4`; linhas 1–14 lajes `#B9B597`/`#989680` com 2 ou 3 juntas verticais tortas (não retas de cima a baixo), lascas e trincas desenhadas uma a uma (nenhuma marca repetida entre lajes); linha 15 = junta `#5C6250`. Musgo e grama da arena raros nas juntas. As duas variantes com juntas em lugares diferentes (o developer alterna). |
| `stair_riser_0` `_1` | 96×8 (3 × 0,25) | Espelho: uma fiada de blocos no mesmo estilo do muro. |
| `cards/moss_drape_0` `_1` | 128×12 (4 × 0,375), alfa | Musgo pendurado pelo beiral (regras da A05: linhas 0–1 opacas; cortinas de 1 a 10 px, a maioria ≤ 6; cobertura 25% a 45%; linha 11 ≤ 5%; seamless na horizontal; colunas 0–1 e 126–127 iguais nas duas). |

### 4. Árvores (`assets/textures/foliage/`)
A copa é **geometria 3D** do developer (lóbulos e andares). A arte cobre as superfícies; nenhum PNG desenha a silhueta de uma árvore inteira.
| Arquivo | Tamanho | Conteúdo |
|---|---|---|
| `leaf_mass_green` `_olive` `_cool` | 64×64, opaco | Miolo dos lóbulos: folhas em aglomerados de 3 a 6 px, 3 a 5 tons da família (verde, oliva, fria), sem lado de luz (o volume vem das normais da copa). Seamless nos 2 eixos. |
| `leaf_shell_green` `_olive` `_cool` | 64×64, alfa | Casca externa do lóbulo: aglomerados de folhas soltos com recorte de pixel nas pontas; cobertura 45% a 70%; os 2 tons mais claros só no terço de cima de cada aglomerado. Seamless nos 2 eixos. `leaf_shell_cool` tem uma variante `leaf_shell_cool_flower` com 6 a 10 flores (rosa ou branca) para o arbusto florido. |
| `conifer_needles` | 64×32, opaco | Lateral de um andar de conífera: agulhas em faixas inclinadas para baixo, família Conífera; `#5C8C40`/`#86A83E` só nas pontas de cima. Seamless na horizontal. |
| `conifer_fringe` | 128×16, alfa | Faixa da borda de baixo de cada andar: pontas de galho serrilhadas de 3 a 12 px; linhas 0–2 opacas; seamless na horizontal. |

### 5. Props (opaco + `_n` em madeira e pedra, `assets/textures/props/`)
| Arquivo | Tamanho | Conteúdo |
|---|---|---|
| `log_bark.png` | 64×32 (2 × 1) | Casca de tronco caído deitado (fibras na horizontal), Casca e madeira; faixa de musgo nas linhas 0–7 (topo do tronco) cobrindo 50% a 80% dessas linhas. Seamless na horizontal. |
| `crate_side.png` | 24×24 (0,75) | Lateral do caixote: 3 tábuas verticais, travessas em X ou em Z, Casca e madeira claras; sem contorno. |
| `crate_top.png` | 24×24 | Tampa do caixote. |
| `wood_pile_end.png` | 32×32 | Pilha de lenha vista da ponta: 5 a 7 anéis de tamanhos diferentes. |

### 6. Reaproveitados como estão (não regerar)
`bark_0`, `bark_1` (troncos de folhosa e de conífera), `wood_end` (pontas de tronco e toco), `rock` (pedras), `bench_floor_0` + `_n` da A04 (assento e encosto do banco da plateia), cartões `flower_0..3`, `mushroom_0..3`, `grass_tuft_0..2`, `tall_grass_0..1` (já são peças fixas aprovadas). `monolith_stone` e `rune_*` ficam guardados (fora deste mapa).

### 7. Viram lixo (não usar; apagar só depois da A06 aprovada e com OK do usuário)
`grass_arena_0..3` (+`_n`), `grass_arena_light_*`, `grass_arena_dark_*`, `grass_forest_0..1` (+`_n`), `dirt_0..1` (+`_n`), `stone_path_0..1` (+`_n`), `wall_face`, `wall_top`, `step_side`, `step_side_grass`, `stair_tread`, `stair_riser` (todos +`_n`), `bench_floor_1` (+`_n`), `leaves_mass` (+`_n`), `moss`, `ruin_tile` (+`_n`); cartões `leaf_0..3`, `leaf_olive_*`, `leaf_cool_*`, `leaf_flower_0`, `conifer_tier_*`, `moss_fringe_*`, `grass_fringe_*`. Da A05: nada foi gerado; a spec fica só como histórico.

**Totais novos:** chão 2; decalques 13; muro e escada 11 opacos + 11 `_n` + 2 cartões; folhagem 9 (incl. `leaf_shell_cool_flower`); props 4 + 3 `_n` (`log_bark`, `crate_side`, `crate_top`). Conferir a contagem final no relatório.

## Script, checagem e prévia
- Geradores em `tools/art/gen_a06_*.gd` (`extends SceneTree`; podem reaproveitar `art_lib.gd` e `palette_a03.gd`, sem `class_name`). Uma função por peça, com as tabelas da peça logo acima dela.
- Checagem `tools/art/check_a06.gd`: uma linha por arquivo e `A06 CHECK: PASS` ou `FAIL (n problemas)`, código de saída 0/1.
- Prévias em `docs/art-preview/`:
  - `a06-chao.png`: texturas ×4; decalques ×1 e ×2; **maquete da arena** a ×1 (32 px/unidade): 20 × 18 de `ground_grass_arena` com `decal_arena_dirt` e 3 a 5 manchas posicionadas como a mancha da referência, e a mesma maquete ao lado de um recorte da clareira da referência; um trecho de trilha de 12 unidades encadeando as 4 variantes e a curva sobre `ground_grass_forest`.
  - `a06-muro.png`: cada textura ×4 (tiras ×2); **elevação** de 12 unidades de muro alto (face externa 1,5 com `moss_drape`, crista vista de cima acima dela) e do degrau baixo (face 0,5 + capeamento), quina com `wall_quoin` dos dois lados e `wall_crest_corner`, e um lance de escada (degraus 0,25/0,5) com as duas variantes; ao lado de um recorte do muro da frente da referência.
  - `a06-folhagem-props.png`: tudo ×4, mais cada `leaf_shell` sobre o `leaf_mass` da mesma família (como a casca fica sobre o miolo).
- Comandos:
  ```bash
  G="/c/Users/pattr/Downloads/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe"
  for f in tools/art/gen_a06_*.gd; do "$G" --headless --path . --script "$f"; done
  "$G" --headless --path . --script tools/art/check_a06.gd
  ```

## Fora de escopo
- Malhas, UV, posição das peças, shaders, dither, câmera (é a 011).
- Monólitos, runas, peças do jogo, UI.
- Editar `scripts/`, `scenes/`, `project.godot`, `docs/specs/`, arquivos `.import`. Apagar PNG antigos.
- Cores fora da Paleta (propor no relatório, não pintar).

## Direção de arte
`docs/direcao-de-arte.md` inteira, com a exceção de tamanho acima. Alvo de cada grupo na referência: clareira central (terra e manchas), muro da frente (pedra, capeamento, musgo), escada do sudoeste, trilha do sudoeste, copas da frente (folhosas) e coníferas do fundo à esquerda, plateia do fundo (tronco, caixote).

## Critérios de aceite

**Automáticos (`check_a06.gd` → `A06 CHECK: PASS`).** Y = 0,299R + 0,587G + 0,114B.
- [ ] Todos os PNG da seção Escopo existem com as dimensões da tabela; opacos com alfa 255; decalques e cartões com alfa binário.
- [ ] Todo pixel é cor da Paleta e só dos grupos indicados para o material.
- [ ] `grep -nE "RandomNumberGenerator|FastNoiseLite|randi|randf|seed" tools/art/gen_a06_*.gd` não retorna nada.
- [ ] Rodar os geradores duas vezes dá PNG idênticos (md5); nenhum PNG da seção 6 muda.
- [ ] Seamless (regra da A03: diferença de Y na emenda ≤ 1,3 × a média entre vizinhas do interior) nos eixos indicados, no albedo e no normal map.
- [ ] Chão: `ground_grass_arena` base `#5B9C47` ≥ 75% e detalhe entre 1% e 6%; `ground_grass_forest` base `#3D853C` ≥ 70%; nenhum elemento > 4×4 px repetido dentro da textura.
- [ ] `decal_arena_dirt`: opacos entre 45% e 75% da imagem; entre os opacos, terra (`#A8955F` `#C0AE71` `#D4C48C` `#8E7B4C`) ≥ 70% e `#C0AE71` ≥ 85% da terra; todo pixel de terra vizinho (4-vizinhança) de grama ou transparente é `#73A949` do aro dentro de 3 px; ≥ 4 componentes de grama dentro do contorno externo; nenhum trecho reto de borda (linha ou coluna) com mais de 6 px.
- [ ] Decalques de mancha: borda sem trecho reto > 6 px; nenhuma forma igual a outra (comparação das máscaras de alfa, inclusive giradas 90°/180°/270°).
- [ ] `decal_trail_*`: colunas 0–1 e 94–95 idênticas nas 4 variantes e na entrada da curva; juntas entre 10% e 20% dos opacos; `#B9B597` é o tom de pedra mais frequente.
- [ ] `decal_arena_dirt`: maior ilha com ≥ 24 px no maior eixo; nenhuma máscara de ilha igual a outra em escala ou rotação.
- [ ] `wall_high_face`: 5 a 10 cores; juntas entre 14% e 26%; musgo entre 8% e 20%, com 3 tons de Musgo; luminância média entre 0,45 e 0,58; as mesmas faixas valem para as linhas 0–31 sozinhas; nenhuma linha com ≥ 90% de junta; nenhuma janela 12×8 alinhada a bloco repetida.
- [ ] `wall_crest` e `wall_cap`: musgo nas faixas da tabela; nenhuma janela 12×8 repetida; pedra clara (`#B9B597` + `#D3CCB4`) ≥ 25%; luminância média ≥ 0,08 acima da de `ground_grass_arena`.
- [ ] `stair_tread_*`: linha 0 com ≥ 80% de `#D3CCB4`, linha 15 com ≥ 80% de `#5C6250`.
- [ ] `leaf_shell_*`: cobertura entre 45% e 70%; `moss_drape_*` e `conifer_fringe` nas regras da tabela.
- [ ] Normal maps: comprimento 1 ± 0,06; Z ≥ 0,6; médias de X e Y em ±0,05; média de Z ≥ 0,9.

**Visuais (Lead Project, pelas prévias)**
- [ ] A maquete da arena lê como a clareira da referência: mancha grande de um tom, borda orgânica, ilhas e aro claro; grama calma sem grade de 1 ou 2 unidades visível.
- [ ] A elevação do muro lê como pedra seca de verdade, com capeamento claro destacado da grama, quina fechada com amarração e musgo só no terço de cima; face interna (linhas 0–31) não parece cortada.
- [ ] A trilha encadeada não mostra emenda nem repetição evidente.
- [ ] Folhagem: miolo + casca lembram as copas grumosas da referência, sem ruído por pixel.

**Processo**
- [ ] Os dois comandos de validação do `CLAUDE.md` sem `ERROR` depois que os PNG existem.
- [ ] Relatório do `artist` com a lista final de arquivos e autocrítica contra a referência.
