# A02 — Arte estilo Octopath: texturas do terreno, dos modelos 3D e cartões

**Status (2026-10-06):** **substituída pela A03** (`A03-arte-minimalista.md`). O usuário rejeitou o estilo Octopath. Não executar de novo. O que se aproveita (runas, infraestrutura dos scripts, nomes de arquivo, contrato das faixas) está listado na A03.
**Substituía:** a A01 (estilo cartoon). **Depende de:** nada. **Usada por:** `005` (terreno) e `006` (vegetação e props 3D).

## Objetivo
Refazer toda a arte do jogo no estilo Octopath definido em `docs/direcao-de-arte.md`:
- texturas de material natural com muitos tons, micro-detalhe e normal map;
- texturas dos novos modelos 3D (casca, massa de folhas, pedra do monólito);
- cartões com alfa recortado para copas, coníferas, franja de grama, capim, flores e runas.

Quando o código usar esta arte, o chão e o relevo vão parecer os do `153426`/`153547`, e as árvores 3D vão ganhar copas em tufos com recorte de pixel.

## Escopo

As texturas de terreno mantêm **os mesmos nomes e caminhos da A01** (o jogo passa a usá-las sem mudar código). O resto é novo. As árvores e monólitos deixam de ser sprites: o artist faz as **texturas** e o developer faz a **forma** (malha, UV, normais), seguindo a fronteira descrita em "Como o mundo é montado" da direção de arte.

### 1. Texturas opacas — `assets/textures/` (32×32, alfa 255, com normal map `<nome>_n.png`)

| Arquivo | Vista | Grupos da paleta | Conteúdo | Tons distintos (mín.–máx.) |
|---|---|---|---|---|
| `grass_arena_0` … `_3` (4) | de cima | Grama da arena (+ Flores na `_3`) | Lâminas de 1 px de largura e 2 a 4 px de comprimento em direções variadas, trevos de 3 a 5 px, pontas ao sol raras, cavidades raras, 1 ou 2 falhas pequenas de terra escura. Sombreamento em domo, sem luz lateral. A `_3` tem de 2 a 4 florzinhas de 1 a 2 px. Mais limpa e legível que a da mata. | 6–10 (`_3`: até 12) |
| `grass_forest_0` `_1` (2) | de cima | Grama da mata, Folha seca, Musgo | Chão sombreado da mata: grama curta e escura, folhas caídas de 2 a 3 px (até 12% dos pixels), tufos de musgo. Mais escura, fria e de baixo contraste. | 6–12 |
| `dirt_0` `_1` (2) | de cima | Terra, Rocha natural | Trilha batida: grãos, sulcos rasos e pedrinhas de 2 a 4 px com sombra de contato embaixo (sem lado). | 6–12 |
| `ruin_tile` | de cima | Cantaria, Musgo, Grama da arena, Líquen | Lajotas irregulares de 10 a 16 px, quinas lascadas, rachaduras de 1 px, juntas de 1 a 2 px com grama e musgo, uma mancha de líquen. | 7–14 |
| `step_side` | de frente | Rocha natural, Terra, Musgo | Rocha em estratos horizontais. **2 faixas de 16 linhas** (A = linhas 0 a 15, B = 16 a 31), cada uma terminando numa **junta horizontal escura e irregular** nas 2 últimas linhas (14 e 15; 30 e 31). Fendas verticais curtas, veio de terra, musgo escorrendo de 2 a 6 px. A e B diferentes entre si. | 7–14 |
| `step_side_grass` | de frente | Os de `step_side` + Grama da arena | Faixa do nível de cima de um degrau com grama. Linhas 0 a 3: terra escura com raízes, musgo e pontas de grama. Linhas 4 a 15: rocha com musgo, terminando na junta. **Linhas 16 a 31 idênticas às de `step_side`.** | 8–16 |
| `wall_face` | de frente | Cantaria, Musgo, Líquen | Cantaria gasta: **2 faixas de 16 linhas**, cada uma uma fiada completa de pedras de 8 a 16 px de largura (2 ou 3 alturas na mesma fiada). A **aresta de cima das pedras está nas linhas 0 e 16** (clara, pega luz). Juntas escuras, quinas lascadas, musgo saindo de 1 ou 2 juntas e líquen. | 7–14 |
| `wall_top` | de cima | Cantaria, Musgo, Líquen | Topo do muro visto de cima: pedras de capa de 10 a 16 px com juntas, desgaste, musgo nas juntas e líquen. Sem faixas repetidas. | 7–14 |
| `rock` | sem direção | Rocha natural, Líquen | Superfície das pedras grandes: facetas e lascas irregulares **sem direção** (nada de faixas horizontais), rachaduras finas, líquen em manchas. | 6–12 |
| `bark_0` | de frente | Casca, Musgo | Casca de folhosa: sulcos verticais de 1 a 2 px (ondulados, não retos), placas, musgo em uma ou duas placas. Seamless nos 2 eixos. | 5–10 |
| `bark_1` | de frente | Casca | Casca de conífera: placas escamosas mais escuras e avermelhadas, sulcos curtos. Seamless nos 2 eixos. | 5–9 |
| `leaves_mass` | sem direção | Folhagem de folhosa (tons 1 a 6) | Miolo da copa: folhas de 2 a 5 px sobrepostas, escuro, com poucos pontos de luz. Seamless nos 2 eixos. | 5–8 |
| `monolith_stone` | de frente | Pedra fria, Líquen | Pedra azul-esverdeada de grão fino, rachaduras finas quase verticais, manchas de líquen. Seamless nos 2 eixos. | 6–12 |

São **18 texturas e 18 normal maps** (`grass_arena_0_n.png` … `monolith_stone_n.png`).

### 2. Cartões com alfa — `assets/textures/cards/` (alfa binário)

| Arquivo | Tamanho | Conteúdo | Regras de forma | Tons (mín.–máx.) |
|---|---|---|---|---|
| `leaf_0` … `leaf_3` (4) | 32×32 | Tufo de folhas visto de frente: de 6 a 14 folhas de 2 a 5 px apontando para fora e para baixo. 0 redondo, 1 largo e achatado, 2 pendente, 3 ralo (com 2 a 4 buracos). Topo de cada folha mais claro, miolo e base escuros. | Margem de 1 px livre; 50% a 80% dos pixels opacos; borda com recorte de pixel (pontas) | 6–10 |
| `leaf_flower_0` | 32×32 | Como `leaf_0`, com 4 a 8 flores lilás ou brancas de 2×2 a 3×3 px. | Idem | 8–14 |
| `conifer_tier_0` `_1` (2) | 32×32 | Faixa de agulhas de um andar de conífera. Linhas 0 a 15: agulhas densas em traços curtos inclinados para baixo, luz só no alto de cada camada. Linhas 16 a 31: pontas pendentes de 3 a 14 px de comprimento, recortadas. | Linhas 0 a 15 100% opacas; linha 31 com até 25% opaco; **seamless na horizontal**; colunas 0 e 1 e 30 e 31 iguais nas duas variantes | 5–8 |
| `grass_fringe_0` `_1` (2) | 32×16 | Grama e musgo caindo pela quina do degrau (como no `153547`): linhas 0 a 3 cheias de grama densa; depois lâminas e tufos pendentes de 3 a 12 px de comprimento. | Linhas 0 a 3 100% opacas; linha 15 com até 20% opaco; **seamless na horizontal**; colunas 0, 1, 30 e 31 iguais nas duas variantes | 6–10 |
| `grass_tuft_0` … `_2` (3) | 16×16 | Capim de 5 a 9 lâminas finas saindo de uma base comum, altura de 8 a 15 px, pontas ao sol. 0 e 1: Grama da arena. 2: Grama da mata. | Linha 0 e colunas 0 e 15 transparentes; última linha com pelo menos 2 pixels opacos, com o meio a no máximo 2 px do centro | 5–9 |
| `flower_0` … `_2` (3) | 16×16 | Tufo de 2 ou 3 flores em hastes, com 1 a 3 folhas (Grama da arena). 0 amarela, 1 branca, 2 lilás. Miolo amarelo. | Idem capim | 6–12 |
| `rune_0` … `_2` (3) | 16×16 | Glifo de runa para decalque emissivo na face do monólito: traço de 1 a 2 px, forma de 8 a 13 px. Aro `#1F7C86`/`#33C2C4`, núcleo `#7CF2EC`, brilho `#D9FFFA` em 1 a 3 px. Três glifos diferentes. | Só cores do grupo Runa; margem de 1 px; de 20 a 70 pixels opacos | 3–4 |

São **18 cartões**, sem normal map (o volume vem das normais da malha). Ao todo, a A02 tem **54 PNG**.

### 3. Scripts, checagem e prévias
- **Gerador:** `tools/art/gen_a02.gd` (`extends SceneTree`), que pode ser dividido em `gen_a02_textures.gd`, `gen_a02_cards.gd` e `gen_a02_preview.gd`. A paleta nova fica em `tools/art/palette_a02.gd`, com os hex exatos da direção de arte. Pode reaproveitar `art_lib.gd` sem quebrar os scripts da A01. Sem `class_name`.
- **A01 vira histórico:**
  - acrescente no início de `gen_a01.gd` uma guarda que **aborta com mensagem** ("A01 substituída pela A02"), para ninguém sobrescrever a arte nova por engano;
  - `check_a01.gd` fica como está e não é mais rodado (a paleta mudou);
  - não apague nem mexa nos sprites antigos de `assets/sprites/`: o jogo ainda os usa até a spec `006`.
- **Checagem:** `tools/art/check_a02.gd` (`extends SceneTree`) substitui a `check_a01.gd`.
  - Ela verifica todos os critérios automáticos abaixo lendo os PNG do disco (`Image.load_from_file(ProjectSettings.globalize_path(...))`).
  - Imprime uma linha por arquivo, com os números medidos (tons, órfãos, saltos, emenda, correlação de luz), e no fim `A02 CHECK: PASS` ou `A02 CHECK: FAIL (n problemas)`.
  - Sai com código 0 ou 1.
- **Prévias** em `docs/art-preview/` (largura máxima de cerca de 1600 px; quebre em linhas):
  - `a02-texturas.png`:
    - cada textura opaca ×4 sozinha e repetida 4×4 a ×2;
    - mosaico 8×8 a ×2 das 4 `grass_arena_*` sorteadas;
    - mosaico de `grass_forest_*` com uma trilha de `dirt_*`;
    - **penhasco de 3 níveis** a ×4, com 3 tiles de largura e 16 linhas por nível, na ordem que o jogo usa (v contínuo, spec `003`): `step_side_grass` linhas 0 a 15, depois `step_side` linhas 16 a 31, depois `step_side` linhas 0 a 15, com a `grass_fringe` sobreposta na quina de cima;
    - muro com as faixas A e B de `wall_face` e o `wall_top` em cima.
  - `a02-luz.png`: cada textura opaca iluminada por CPU com o próprio normal map (Lambert, luz a 45° de elevação vindo de N, L, S e O, mais luz ambiente fraca) em 4 cópias lado a lado, mais o normal map visto como cor. Serve para julgar o relevo e para conferir que nenhuma das 4 direções parece "errada".
  - `a02-cartoes.png`: todos os cartões ×4 sobre cinza neutro e, numa segunda faixa, ×2 sobre `grass_arena_0` e `grass_forest_0` repetidas.
  - `a02-cena.png`: composição 2D simples a ×2, iluminada por CPU com os normal maps (sol quente `#FFE1B0` vindo de cima-esquerda da imagem, ambiente frio `#5A7099`). Ela mostra:
    - chão da arena com capim e flores;
    - penhasco com franja;
    - trecho de muro;
    - uma "árvore de mentira" (faixa de `bark_0` + mancha de `leaves_mass` + 15 a 25 `leaf_*` sobrepostos numa elipse);
    - uma conífera de mentira (andares de `conifer_tier` em trapézios);
    - um monólito com runa.

    Não é tela do jogo: serve só para julgar a harmonia.
  - `a02-comparacao.png`: lado a lado, na mesma altura e com ampliação Nearest:
    - um recorte de `docs/reference/Screenshot 2026-10-04 153426.png` (grama e pedra);
    - um de `153547.png` (terraço com grama caindo e conífera);
    - os trechos equivalentes da `a02-cena.png`.

    As referências podem ser lidas do disco pelo caminho absoluto.

## Fora de escopo
- Malhas 3D, UV, normais da malha, distribuição de árvores, shaders, luz e pós-processamento (specs `004`, `005` e `006`, do developer).
- Sprites de árvore, arbusto e monólito (deixam de existir), peças, UI, fontes, água e construções.
- Animação (vento), sombra desenhada, glow ou halo pintado, gradiente global.
- Variação macro de tom do chão (é do shader, spec `005`) e texturas de transição (o código faz).
- Editar `scripts/`, `scenes/`, `project.godot`, `docs/specs/` ou arquivos `.import`. Se o import precisar de ajuste (ex.: marcar `_n.png` como normal map), relate para o developer.
- Apagar arquivos de `assets/sprites/`.
- Cores fora da paleta. Se faltar cor, escreva a proposta no relatório e não pinte.

## Design técnico sugerido
- **RNG** com seed fixa por arquivo (ex.: hash do nome), para mexer num item sem mudar os outros.
- **Desenhe albedo e altura juntos.** Cada forma (lâmina, pedrinha, pedra, folha, estrato) escreve a cor no albedo e a sua altura num mapa de altura em float do mesmo tamanho. O normal map sai do mapa de altura, nunca da luminância do albedo.
- **Normal map (convenção OpenGL do Godot).** Com `h` em pixels de altura, diferenças centrais **com wrap** (módulo 32) e `s` = força por material:
  - `n = normalize(Vector3(-s * dh/dx, +s * dh/dlinha, 1.0))`, onde `dh/dlinha` é a derivada no sentido em que a linha da imagem aumenta (para baixo);
  - cor = `(n * 0.5 + 0.5) * 255`, com alfa 255;
  - assim, a encosta de cima de um calombo aponta para o topo da textura (verde > 128).
  - Nos cartões não há normal map.
- **Seamless:** desenhe com coordenadas em módulo 32 (o que sai pela direita entra pela esquerda). Nas famílias com variantes (`grass_arena_*`, `grass_forest_*`, `dirt_*`):
  - gere **uma vez** a faixa de 3 px junto às 4 bordas e use os **mesmos pixels** (albedo e altura) nela em todas as variantes da família;
  - varie só o miolo (26×26);
  - a faixa é **neutra**: só tons do meio da rampa, sem elemento marcante.
- **Laterais em faixas:** desenhe cada faixa de 16 linhas como um estrato completo, com a junta embaixo. `step_side_grass` = cópia de `step_side` com a faixa A redesenhada por cima.
- **Cartões:** monte o tufo por folhas (pequenas elipses ou gotas de 2 a 5 px). Pinte cada folha com 2 ou 3 tons (claro em cima, escuro embaixo). Ao recortar, limpe pixels soltos de alfa e mantenha as pontas.
- **Luz pintada** só de cima, nunca de lado (ver direção de arte). Nas texturas de topo, sombreamento em domo.
- **Comandos:**
  ```bash
  G="/c/Users/pattr/Downloads/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe"
  "$G" --headless --path . --script tools/art/gen_a02.gd
  "$G" --headless --path . --script tools/art/check_a02.gd
  ```

## Direção de arte
- Fonte única: `docs/direcao-de-arte.md`. Releia **Visão geral**, **Regras das texturas opacas**, **Laterais em faixas**, **Regras dos cartões**, **Paleta** e **Uso por material** antes de começar.
- **Alvo:** `153426` e `153547` (estilo). A clareira `160858` só dá os elementos (monólito, runa, lajota), não o traço.
- **Mais tons e detalhe fino, sem chiado.** A diferença para a A01 está em ter de 6 a 10 tons com desvio de matiz, detalhe de 1 a 3 px com forma, dithering só entre tons vizinhos e nenhum contorno.
- **A vibração vem do motor** (sol quente, bloom, grading). A textura entrega material natural e bem-desenhado. A grama da arena é a mais clara e quente do conjunto. A mata e a conífera são mais escuras e frias.

## Critérios de aceite

**Automáticos (`tools/art/check_a02.gd` sai com `A02 CHECK: PASS`).** Luminância Y = 0,299R + 0,587G + 0,114B, com os canais sRGB em 0 a 1.
- [ ] Existem os 54 PNG listados, nos caminhos e com as dimensões das tabelas, em RGBA8.
- [ ] **Paleta:** todo pixel opaco de toda textura e todo cartão é **exatamente** uma cor da tabela Paleta da direção de arte. Os normal maps ficam de fora.
- [ ] **Alfa:**
  - texturas e normal maps com todos os pixels a 255;
  - cartões só com 0 ou 255.
- [ ] **Tons:** o número de cores opacas distintas de cada arquivo está na faixa "mín.–máx." da tabela.
- [ ] **Ruído controlado** (exceto `rune_*`):
  - até 8% de pixels órfãos (nenhum dos 8 vizinhos com a mesma cor; nas texturas, vizinhos com wrap);
  - no máximo 10% dos pares de vizinhos (vizinhança 4) da **mesma rampa** saltam mais de 3 posições de tom.
- [ ] **Sem gradiente global:** a luminância média da metade esquerda e da direita difere no máximo 0,05.
  - Vale também de cima para baixo nas texturas de topo, `rock`, `bark_*`, `leaves_mass` e `monolith_stone`.
- [ ] **Emenda (seamless):** em cada eixo seamless, a diferença média de Y entre a última e a primeira coluna (ou linha) é no máximo 1,3 vez a diferença média entre colunas (ou linhas) vizinhas do interior.
  - Nos cartões seamless na horizontal, conta transparente como Y = 0.
  - Vale para o albedo e para o normal map.
- [ ] **Sem luz lateral pintada:** a correlação de Pearson entre a luminância do albedo e o componente X do normal map fica em [−0,2; 0,2] em toda textura opaca.
  - Nas texturas de topo, em `rock` e em `leaves_mass`, o mesmo vale para o componente Y.
- [ ] **Normal maps válidos:**
  - todo pixel decodifica para um vetor de comprimento 1 ± 0,06, com Z ≥ 0,4;
  - a média de X e a média de Y ficam em ±0,05;
  - pelo menos 25% dos pixels têm Z < 0,97 (há relevo).
- [ ] **Famílias** (`grass_arena_*`, `grass_forest_*`, `dirt_*`):
  - a faixa de 3 px das 4 bordas é idêntica entre as variantes (albedo e normal map);
  - pelo menos 30% dos pixels do miolo diferem entre quaisquer duas variantes;
  - na faixa, a fração de pixels nos 2 tons mais escuros e nos 2 mais claros da rampa principal não passa da fração do miolo + 0,02.
- [ ] **Laterais:**
  - em `step_side`, nas linhas 14 e 15 e nas linhas 30 e 31, pelo menos 60% das colunas têm um pixel nos 3 tons mais escuros da Rocha natural;
  - em `step_side_grass`, as linhas 16 a 31 são idênticas às de `step_side`, e pelo menos 50% dos pixels das linhas 0 a 3 são de Terra, Musgo ou Grama da arena;
  - em `wall_face`, pelo menos 60% dos pixels das linhas 0 e 16 estão nos 4 tons mais claros da Cantaria.
- [ ] **Cartões: forma.** As regras da coluna "Regras de forma" são medidas:
  - margens;
  - cobertura de 50% a 80% em `leaf_*`;
  - linhas cheias e linhas ralas em `conifer_tier_*` e `grass_fringe_*`;
  - colunas iguais entre variantes;
  - base centralizada em capim e flor;
  - de 20 a 70 pixels nas runas.
- [ ] **Cartões: sem contorno.**
  - Nos pixels opacos com vizinho transparente logo acima, a luminância média é maior ou igual à média de todos os pixels opacos do cartão.
  - No máximo 30% dos pixels de borda (com vizinho transparente na vizinhança 4) estão nos 2 tons mais escuros do seu grupo.

**Visuais (revisão do Lead Project pelas prévias)**
- [ ] **Repetição e emendas.**
  - As texturas repetidas 4×4 e os mosaicos não mostram emenda, grade nem elemento repetido gritante.
  - O penhasco de 3 níveis empilha sem costura, parece rocha natural em camadas e a franja cai de forma orgânica.
- [ ] **Relevo e luz.** Em `a02-luz.png`, o relevo do normal map corresponde ao desenho (pedras, lâminas e rachaduras saltam). Nas 4 direções de luz, nenhuma textura parece "iluminada do lado errado".
- [ ] **Cartões.** Os de folhagem parecem tufos de folha com recorte de pixel, não bolhas. As coníferas parecem camadas de agulhas. Capim e flores são legíveis.
- [ ] **Comparação com o Octopath.** Em `a02-comparacao.png`, os trechos da A02 parecem do mesmo jogo que os recortes do Octopath:
  - densidade de detalhe parecida na mesma escala;
  - materiais naturais;
  - grama oliva a amarela ao sol e sombras frias;
  - sem contorno e sem cor chapada.

  **Não** pode parecer o cartoon da A01.
- [ ] Nenhuma sombra no chão, halo, gradiente suave nem anti-aliasing.

**Processo**
- [ ] Rodar `gen_a02.gd` duas vezes gera arquivos idênticos (ex.: `md5sum` de todos os PNG de `assets/textures/` e `assets/textures/cards/` igual antes e depois).
- [ ] `gen_a01.gd` aborta com a mensagem de substituição. Nenhum arquivo de `assets/sprites/` muda.
- [ ] Os dois comandos de validação do `CLAUDE.md` rodam sem `ERROR` depois que os PNG existem (o import não falha).
- [ ] O relatório de entrega segue o formato do `artist`, com autocrítica comparando com o `153426` e o `153547`.
