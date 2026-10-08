# A03 — Arte minimalista: chão, terra, pedra com musgo, escadas, árvores e props

**Histórico (2026-10-08):** o cenário deixou de ser pixel art ("Pixel art serão só os personagens"). Esta spec não vale mais para arte nova. O estilo vigente está em `docs/direcao-de-arte.md` e na `A08-arte-pintada-ilha.md`. Os PNG gerados por ela continuam no disco até o OK do usuário.

**Status:** aprovada pelo usuário em 2026-10-06.
**Substitui:** a A02 (estilo Octopath, rejeitado pelo usuário em 2026-10-06). **Depende de:** `docs/direcao-de-arte.md` reescrita (aprovada junto). **Usada por:** `005` (terreno), `006` (vegetação e props 3D).

## Objetivo
Refazer a arte no estilo da referência `docs/reference/Gemini_Generated_Image_6oy5mo6oy5mo6oy5.jpg`:
- **chão leve e minimalista:** grama quase lisa com poucos tons e detalhe esparso; terra de um tom;
- **pedra seca com topo de musgo** para muros, escadas e calçamento;
- **árvores mais detalhadas**: coníferas em camadas serrilhadas e folhosas em aglomerados de folhas;
- props: tronco caído, toco, cogumelos, capim alto, flores.

Quando o código usar esta arte (`005` e `006`), o jogo deve parecer da mesma família da referência, e não o "carpete ruidoso" do screenshot de 2026-10-06.

## O que da A02 se aproveita
- **Sem mudança:** os cartões `rune_0..2` (o grupo Runa não mudou). A checagem só confere que continuam passando.
- **Infraestrutura:** `tools/art/art_lib.gd`, o cálculo de normal map a partir do mapa de altura com wrap, a geração seamless em módulo 32, a estrutura do `check_a02.gd` (vira `check_a03.gd`) e a montagem das prévias.
- **Contratos:** os **nomes de arquivo** iguais aos da A02 sempre que o papel é o mesmo (o código já os carrega); as laterais em faixas de 16 linhas; as regras de cartão (alfa binário, margem, base centralizada).
- **Não se aproveita:** os pixels de todas as outras texturas e cartões (todos são regerados) e a paleta `palette_a02.gd`.
- **Ficam obsoletos** (não apagar; o código da `005` deixa de carregá-los): `ruin_tile.png` e `ruin_tile_n.png` (o calçamento os substitui), e os normal maps de chão e folhagem (`grass_arena_*_n`, `grass_forest_*_n`, `dirt_*_n` e `leaves_mass_n`). A apagar depois, com o OK do usuário.

## Escopo

Toda cor vem da **Paleta** da direção de arte. Todo número de tons vem da tabela "Tons por material" de lá. Os tons abaixo repetem a tabela para facilitar a checagem.

### 1. Chão — `assets/textures/` (32×32, opaco, **sem normal map**)

Regras comuns:
- vista de cima;
- linhas e colunas 0 e 31 só no tom base;
- detalhe em tracinhos ou clusters de 2 a 6 px (componentes conexos em vizinhança 8), sem pixel solto;
- nenhum elemento repetido;
- sem luz lateral.

| Arquivo | Grupo | Base | Detalhe | Tons | Cobertura do base | Pixels de detalhe |
|---|---|---|---|---|---|---|
| `grass_arena_0` `_1` `_2` | Grama da arena | `#5B9C47` | De 5 a 10 tracinhos de 2 a 3 px (em `#73A949` e `#4E9343`), em direções variadas; no máximo 2 pontas `#98B654` | 2–4 | ≥ 75% | 3–12% |
| `grass_arena_3` | Grama da arena + Flores | `#5B9C47` | Como `_0`, mais 1 ou 2 florzinhas de 2 a 4 px (pétala + miolo) | 3–7 | ≥ 75% | 4–14% |
| `grass_arena_light_0` `_1` | Grama da arena | `#73A949` | Tracinhos em `#98B654` e `#5B9C47` | 2–4 | ≥ 75% | 3–12% |
| `grass_arena_dark_0` `_1` | Grama da arena | `#4E9343` | Tracinhos em `#5B9C47` | 2–3 | ≥ 75% | 3–12% |
| `grass_forest_0` `_1` | Grama de fora + Casca | `#3D853C` | Tracinhos em `#2C7036` e `#539342`; até 3% de folhinha caída (`#876547`) | 2–4 | ≥ 70% | 3–15% |
| `dirt_0` `_1` | Terra | `#C0AE71` | De 2 a 5 pedrinhas de 2 a 4 px em `#A8955F` e `#D4C48C` (miolo claro, base escura, sem lado) | 2–3 | ≥ 85% | 2–10% |

A borda orgânica da terra, o aro de grama clara e as manchas clara e escura **não** são desenhados aqui: o shader da `005` escolhe a textura por texel.

### 2. Pedra — `assets/textures/` (32×32, opaco, **com normal map** `<nome>_n.png`)

| Arquivo | Vista | Conteúdo | Tons |
|---|---|---|---|
| `stone_path_0` `_1` | de cima | Calçamento: lajes grandes e irregulares de 10 a 18 px em Pedra (`#989680` a `#D3CCB4`, base `#B9B597`); juntas de 1 px (2 px só nos cruzamentos) em `#7A7A66`, com `#5C6250` só nos cruzamentos (até 4% dos pixels); musgo (`#5E7C26`, `#789636`) em 2 a 4 trechos de junta. **Sem `#34403C` e sem `#1C2B2B`.** Juntas (`#7A7A66`, `#5C6250` e Musgo) = 10% a 20% dos pixels. Seamless nos 2 eixos; as duas variantes emendam entre si (mesma faixa de 2 px nas bordas). | 4–6 |
| `wall_face` | de frente | Pedra seca: **2 faixas de 16 linhas**, cada uma com **3 fiadas** de pedras de 4 a 5 px de altura e 6 a 14 px de largura, juntas de 1 px escuras, aresta de cima de cada pedra mais clara. Musgo escorrendo de 2 a 4 juntas (5% a 20% dos pixels). A última linha de cada faixa (15 e 31) é junta. Seamless na horizontal; as faixas A e B são diferentes. | 5–7 |
| `wall_top` | de cima | Topo do muro coberto de musgo (≥ 50% Musgo), com pedras claras (`#B9B597`, `#D3CCB4`) aparecendo em 2 a 4 falhas. Seamless nos 2 eixos. | 4–6 |
| `stair_tread` | de cima | Piso de degrau: lajes grandes claras (12 a 20 px), juntas finas, musgo e grama nas juntas. Seamless nos 2 eixos. | 4–6 |
| `stair_riser` | de frente | Espelho de degrau: **4 faixas de 8 linhas**, cada uma uma fiada de pedras de 6 a 7 px de altura, com junta na última linha (7, 15, 23 e 31). Musgo em 1 ou 2 juntas. Seamless na horizontal. | 5–7 |
| `step_side` | de frente | Barranco natural da floresta: terra escura e pedras em **2 faixas de 16 linhas**, junta escura e irregular na última linha de cada faixa, musgo. Mais simples que o muro (pedras maiores, menos juntas). | 4–6 |
| `step_side_grass` | de frente | Faixa de cima de um barranco com grama: linhas 0 a 3 com terra escura e raízes; **linhas 16 a 31 idênticas às de `step_side`**. | 4–7 |
| `rock` | sem direção | Pedra grande: 3 a 5 facetas grandes em Pedra, com 1 a 2 manchas de musgo. Sem faixas horizontais. | 4–6 |
| `monolith_stone` | de frente | Pedra fria de grão grosso (manchas de 4 a 8 px), 1 ou 2 rachaduras quase verticais, musgo na base. Seamless nos 2 eixos. | 4–6 |

### 3. Madeira e folhagem — `assets/textures/` (32×32, opaco)

| Arquivo | Normal map | Conteúdo | Tons |
|---|---|---|---|
| `bark_0` | sim | Casca de folhosa: sulcos verticais ondulados de 1 a 2 px, placas, musgo em 1 ou 2 placas. Seamless nos 2 eixos. | 4–6 |
| `bark_1` | sim | Casca de conífera: placas escamosas escuras (`#1A1426` a `#6B4C3E`). Seamless nos 2 eixos. | 3–5 |
| `wood_end` | sim | Ponta cortada de tronco e topo de toco: 3 a 5 anéis concêntricos (`#A37C56`, `#C29A6C`, `#D9BC86`), casca de 2 px na borda, 1 rachadura radial. O centro dos anéis fica no centro da textura. Não precisa ser seamless. | 4–6 |
| `moss` | não | Musgo para o topo de troncos caídos e tocos: Musgo com tufos de 2 a 4 px. Seamless nos 2 eixos. | 3–4 |
| `leaves_mass` | não | Miolo da copa: aglomerados de folhas de 3 a 6 px em Folhagem verde, tons 1 a 4. Escuro e calmo. Seamless nos 2 eixos. | 3–5 |

### 4. Cartões — `assets/textures/cards/` (alfa binário, sem normal map)

| Arquivo | Tamanho | Conteúdo | Regras de forma | Tons |
|---|---|---|---|---|
| `leaf_0` … `leaf_3` | 32×32 | Aglomerado de folhas em Folhagem verde, como as copas da referência: 3 a 6 "bolinhos" de folhas, cada um com topo claro (`#9CC230`/`#B5CA33` só no terço de cima) e base escura, borda com recorte de pixel (pontas de folha de 1 a 2 px). 0 redondo, 1 largo, 2 pendente, 3 ralo (2 a 4 buracos). | Margem de 1 px; 45% a 80% opaco | 4–7 |
| `leaf_olive_0` `_1` | 32×32 | Como `leaf_0`/`_1`, em Folhagem oliva (folhosa amarelada) | Idem | 4–7 |
| `leaf_cool_0` `_1` | 32×32 | Como `leaf_0`/`_1`, em Folhagem fria (arbustos) | Idem | 4–7 |
| `leaf_flower_0` | 32×32 | Como `leaf_cool_0`, com 3 a 6 flores rosa ou brancas de 2×2 a 3×3 px | Idem | 6–10 |
| `conifer_tier_0` `_1` | 32×32 | Camada de galhos de conífera, como as da referência: linhas 0 a 13 cheias de galhos inclinados para baixo, com a luz (`#5C8C40`/`#86A83E`) só no alto de cada galho; linhas 14 a 31 com **pontas serrilhadas** pendentes de 3 a 16 px, em 4 a 7 dentes por cartão. | Linhas 0 a 13 100% opacas; linha 31 com até 25% opaco; **seamless na horizontal**; colunas 0, 1, 30 e 31 iguais nas duas variantes | 4–7 |
| `moss_fringe_0` `_1` | 32×16 | Musgo caindo pela borda do muro: linhas 0 a 2 cheias de musgo; depois tufos e fios pendentes de 2 a 10 px. | Linhas 0 a 2 100% opacas; linha 15 com até 15% opaco; **seamless na horizontal**; colunas 0, 1, 30 e 31 iguais nas duas variantes | 3–5 |
| `grass_fringe_0` `_1` | 32×16 | Grama caindo pela quina do barranco natural, em Grama de fora. | Como `moss_fringe` | 3–5 |
| `grass_tuft_0` … `_2` | 16×16 | Capim baixo de 4 a 7 lâminas, altura de 6 a 12 px. 0 e 1 em Grama da arena; 2 em Grama de fora. | Linha 0 e colunas 0 e 15 transparentes; última linha com ≥ 2 px opacos e meio a ≤ 2 px do centro | 2–4 |
| `tall_grass_0` `_1` | 16×32 | Capim alto em tufo (como os da referência), de 6 a 10 lâminas de 14 a 30 px, pontas mais claras. Grama de fora. | Idem (linha 0 e colunas 0 e 15 transparentes) | 3–4 |
| `flower_0` … `_3` | 16×16 | Tufo de 1 a 3 flores em hastes, com 1 ou 2 folhas. 0 rosa, 1 branca, 2 amarela, 3 azul. Miolo amarelo. | Idem capim | 3–6 |
| `mushroom_0` … `_3` | 16×16 | 1 a 3 cogumelos de 5 a 10 px de altura: chapéu redondo de 2 a 3 tons (topo claro), pé `#B8AE98`/`#E8E0C8`. 0 rosa, 1 azul, 2 roxo, 3 laranja. Sem contorno. | Idem capim | 3–5 |

**Totais:** 27 texturas opacas, 13 normal maps (`stone_path_*`, `wall_face`, `wall_top`, `stair_tread`, `stair_riser`, `step_side`, `step_side_grass`, `rock`, `monolith_stone`, `bark_*` e `wood_end`) e 28 cartões novos. São **68 PNG** gerados, mais os 3 `rune_*` mantidos.

### 5. Scripts, checagem e prévias
- **Gerador:** `tools/art/gen_a03.gd` (`extends SceneTree`). Pode ser dividido em `gen_a03_textures.gd`, `gen_a03_cards.gd` e `gen_a03_preview.gd`. A paleta fica em `tools/art/palette_a03.gd`, com os hex exatos da direção de arte. Sem `class_name`. RNG com seed fixa por arquivo.
- **A02 vira histórico:**
  - acrescente no início de `gen_a02.gd` uma guarda que aborta com a mensagem "A02 substituída pela A03";
  - `check_a02.gd` não é mais rodado;
  - não mexa nos `rune_*` nem em `assets/sprites/`.
- **Checagem:** `tools/art/check_a03.gd` (`extends SceneTree`):
  - lê os PNG do disco e mede todos os critérios automáticos;
  - imprime uma linha por arquivo com os números (tons, cobertura do base, detalhe, maior e menor cluster, emenda, correlação de luz);
  - no fim, imprime `A03 CHECK: PASS` ou `A03 CHECK: FAIL (n problemas)` e sai com código 0 ou 1.
- **Prévias** em `docs/art-preview/` (largura máxima de cerca de 1600 px):
  - `a03-texturas.png`:
    - cada textura ×4 sozinha e repetida 4×4 a ×2;
    - um **mosaico de chão** de 24 × 14 tiles a ×1, simulando na CPU a técnica do shader da `005`: escolha por texel entre `grass_arena_*`, `_light_*`, `_dark_*` e `dirt_*`, com ruído quantizado no texel, mancha de terra orgânica com ilhas de grama e o aro de grama clara. Serve de alvo para o developer;
    - muro de 2 níveis (`wall_face` A e B) com `wall_top` em cima e `moss_fringe` na borda;
    - escada de 2 níveis (`stair_riser` + `stair_tread`);
    - trecho de calçamento com borda de grama.
  - `a03-cartoes.png`: todos os cartões ×4 sobre cinza neutro e ×2 sobre `grass_arena_0` e `grass_forest_0`.
  - `a03-cena.png`: composição 2D a ×2, sem luz direcional (só a luz pintada de cima). Mostra:
    - chão da arena com terra;
    - muro com musgo e escada;
    - uma conífera de mentira (6 andares de `conifer_tier` em trapézios) e uma folhosa de mentira (tronco `bark_0`, mancha de `leaves_mass` e de 20 a 40 cartões `leaf_*` numa elipse);
    - um arbusto, um tronco caído (casca + `wood_end` na ponta + `moss` em cima), um toco, cogumelos, flores e capim alto.
  - `a03-comparacao.png`: lado a lado, com o mesmo tamanho aparente de pixel, recortes da referência (lida do disco pelo caminho absoluto) e os trechos equivalentes da `a03-cena.png`. O pixel da arte na referência mede cerca de 5 px da imagem, então amplie a nossa arte ×5, ou reduza o recorte da referência na mesma proporção, sempre com Nearest. Trechos:
    - grama com terra;
    - muro com musgo;
    - escada;
    - calçamento;
    - conífera;
    - folhosa;
    - tronco caído;
    - cogumelos.

## Fora de escopo
- Malhas, UV, normais da malha, shaders (inclusive as máscaras de chão), distribuição pela seed, luz e pós (specs `004`, `005` e `006`).
- Textura de transição de terra e grama (é máscara do shader).
- Sprites de peças, UI, fontes, água, construções, bancos e caixotes da referência.
- Animação, sombra desenhada, glow pintado, gradiente global, contorno.
- Editar `scripts/`, `scenes/`, `project.godot`, `docs/specs/` ou arquivos `.import`. Se o import precisar de ajuste (ex.: marcar `_n.png` como normal map), relate ao developer.
- Apagar arquivos (os obsoletos ficam até o OK do usuário).
- Cores fora da paleta. Se faltar cor, escreva a proposta no relatório e não pinte.

## Design técnico sugerido
- **Chão:** comece pela textura toda no tom base. Depois sorteie os tracinhos (segmentos de 2 a 3 px em 8 direções, com 1 ou 2 tons) em posições com distância mínima de 5 px entre si, longe da borda de 1 px. O resultado deve parecer "quase liso".
- **Pedra:** desenhe albedo e altura juntos (pedra alta, junta baixa, chanfro de 1 px). O normal map sai da altura, com força baixa (a direção de arte pede relevo de pedra a pedra, sem micro-relevo).
- **Folhagem:** monte cada aglomerado com "bolinhos" (círculos ou gotas de 5 a 10 px). Pinte em 3 faixas: topo claro, meio e base escura. Recorte a borda com pontas de folha de 1 a 2 px. Nada de ruído por pixel dentro do aglomerado.
- **Conífera:** desenhe os galhos como cunhas inclinadas para baixo, empilhadas, com dentes de comprimentos variados. A luz fica só na aresta de cima de cada cunha.
- **Comandos:**
  ```bash
  G="/c/Users/pattr/Downloads/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe"
  "$G" --headless --path . --script tools/art/gen_a03.gd
  "$G" --headless --path . --script tools/art/check_a03.gd
  ```

## Direção de arte
- Fonte única: `docs/direcao-de-arte.md`. Releia **Visão geral**, **Regras das texturas opacas**, **Tons por material**, **Normal maps**, **Laterais em faixas**, **Regras dos cartões**, **Transições e manchas** e **Paleta** antes de começar.
- **Alvo:** a referência do Gemini.
- **Menos é mais no chão.** Se a dúvida for "ponho mais um tracinho?", a resposta é não. As árvores, os muros e os props carregam o detalhe.

## Critérios de aceite

**Automáticos (`tools/art/check_a03.gd` sai com `A03 CHECK: PASS`).** Luminância Y = 0,299R + 0,587G + 0,114B, com os canais em 0 a 1.
- [ ] Existem os 68 PNG listados, nos caminhos e com as dimensões das tabelas, em RGBA8. Os 3 `rune_*` estão intactos (mesmo md5 de antes).
- [ ] **Paleta:** todo pixel opaco de toda textura e todo cartão é exatamente uma cor da Paleta da direção de arte (os normal maps ficam de fora). Cada arquivo usa só os grupos indicados na tabela dele.
- [ ] **Alfa:** texturas e normal maps com todos os pixels a 255; cartões só com 0 ou 255.
- [ ] **Tons:** o número de cores opacas distintas de cada arquivo está na faixa da tabela.
- [ ] **Chão minimalista** (`grass_*` e `dirt_*`):
  - a cobertura do tom base e a fração de pixels de detalhe estão nas faixas da tabela;
  - as linhas e colunas 0 e 31 são 100% tom base;
  - todo componente conexo (vizinhança 8) de pixels fora do base tem de 2 a 6 px (flores: até 9). Nenhum pixel solto.
- [ ] **Juntas e musgo:**
  - em `stone_path_*`, as juntas (`#7A7A66`, `#5C6250` e Musgo) ficam entre 10% e 20% dos pixels, e `#34403C`/`#1C2B2B` não aparecem;
  - em `wall_face`, o musgo fica entre 5% e 20%; as linhas 15 e 31 têm ≥ 60% de pixels nos 2 tons mais escuros de Pedra ou Musgo; e cada faixa tem, além da última, pelo menos 2 linhas internas com ≥ 40% de pixels nesses tons (3 fiadas);
  - em `stair_riser`, as linhas 7, 15, 23 e 31 têm ≥ 60% nesses tons;
  - em `wall_top`, o musgo fica em ≥ 50%;
  - em `step_side_grass`, as linhas 16 a 31 são idênticas às de `step_side`.
- [ ] **Dithering:** nas texturas de pedra e casca, no máximo 5% dos pixels fazem parte de xadrez 2×2 de dois tons. No chão, nenhum.
- [ ] **Sem gradiente global:** a luminância média da metade esquerda e da direita difere no máximo 0,04. Nas texturas de topo, isso vale também de cima para baixo.
- [ ] **Emenda (seamless):** em cada eixo seamless, a diferença média de Y entre a última e a primeira coluna (ou linha) é no máximo 1,3 vez a diferença média entre colunas (ou linhas) vizinhas do interior. Vale para albedo e normal map. Nos cartões seamless na horizontal, transparente conta como Y = 0.
- [ ] **Sem luz lateral pintada:** nas texturas com normal map, a correlação de Pearson entre a luminância do albedo e o componente X do normal fica em [−0,2; 0,2]. Nas de topo e em `rock`, vale também para o componente Y.
- [ ] **Normal maps fracos e válidos:**
  - todo pixel decodifica para um vetor de comprimento 1 ± 0,06, com Z ≥ 0,6;
  - a média de X e a de Y ficam em ±0,05;
  - a média de Z é ≥ 0,9 (relevo suave);
  - pelo menos 15% dos pixels têm Z < 0,98 (há relevo nas juntas).
- [ ] **Cartões: forma.** As regras da coluna "Regras de forma" são medidas: margens, cobertura de 45% a 80% nos `leaf_*`, linhas cheias e ralas em `conifer_tier_*`, `moss_fringe_*` e `grass_fringe_*`, colunas iguais entre variantes e base centralizada em capim, capim alto, flor e cogumelo. Em `conifer_tier_*`, a linha 20 tem entre 4 e 7 trechos opacos separados (os dentes).
- [ ] **Cartões: sem contorno.**
  - Nos pixels opacos com vizinho transparente logo acima, a luminância média é ≥ a média de todos os pixels opacos do cartão.
  - No máximo 30% dos pixels de borda (vizinho transparente na vizinhança 4) estão nos 2 tons mais escuros do grupo.

**Visuais (revisão do Lead Project pelas prévias)**
- [ ] **Chão leve.** O mosaico de chão de `a03-texturas.png` parece a arena da referência: verde vivo quase liso, manchas grandes de luz com borda de pixel, terra de um tom com borda orgânica, ilhas de grama e aro claro. Sem grade, sem repetição visível, sem "carpete".
- [ ] **Pedra.** O muro parece pedra seca em fiadas finas com topo de musgo e musgo escorrendo, como na referência. A escada e o calçamento são legíveis.
- [ ] **Árvores.** A conífera de mentira tem camadas serrilhadas. A folhosa parece feita de aglomerados de folhas com recorte de pixel, com topo claro e base escura. Nunca "bola lisa".
- [ ] **Props.** Tronco caído, toco e cogumelos são legíveis a ×2 e coloridos como na referência, sem contorno preto.
- [ ] **Comparação.** Em `a03-comparacao.png`, cada trecho nosso parece do mesmo jogo que o recorte da referência: mesma quantidade de tons no chão, mesmo verde, mesmo bege de terra e de pedra.
- [ ] Nenhuma sombra no chão, halo, gradiente suave nem anti-aliasing.

**Processo**
- [ ] Rodar `gen_a03.gd` duas vezes gera arquivos idênticos (md5 de todos os PNG igual).
- [ ] `gen_a02.gd` aborta com a mensagem de substituição. Nenhum arquivo de `assets/sprites/` muda.
- [ ] Os dois comandos de validação do `CLAUDE.md` rodam sem `ERROR` depois que os PNG existem.
- [ ] O relatório do `artist` traz autocrítica comparando com a referência, a lista dos arquivos obsoletos e qualquer proposta de cor (sem pintá-la).
