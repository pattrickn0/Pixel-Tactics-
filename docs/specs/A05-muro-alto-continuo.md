# A05 — Muro alto contínuo (face longa, capeamento, musgo pendente, degrau curto)

> **SUBSTITUÍDA por 011/A06** (2026-10-07): mapa feito à mão com kit modular, reservas no terraço, arte sem variação procedural. Mantida só como histórico.

**Depende de:** `docs/direcao-de-arte.md` e `A03` (paleta e regras gerais). **Usada por:** `010` (o developer integra).
**Decisões do usuário (2026-10-07):** crista do anel no nível 3 = **1,5** (perfil 1-3-3-1, como na `010`): o banco interno e o externo têm face de **0,5 (16 texels)** e o muro entre banco e crista tem face de **1,0 (32 texels)**; escadas com espelho 0,25, célula que sobe 1 nível (0,5) e célula que sobe 2 níveis (1,0); nada de "textura colada em bloco"; musgo do topo contrastando com a grama; tons mais próximos da referência.
**Exceção à direção de arte (vale esta spec, que é a mais recente):** as texturas abaixo **não** são 32×32. São tiras longas para o muro não repetir a cada unidade. A densidade continua 32 texels por unidade.

## Objetivo
Dar ao muro do anel a cara do muro da referência (`docs/reference/Gemini_Generated_Image_6oy5mo6oy5mo6oy5.jpg`, muro da frente): pedra seca bege-acinzentada em blocos irregulares, juntas escuras, musgo nas juntas, capeamento de pedra clara com tufos de musgo no topo e musgo pendurado pela borda. Lido como **muro**, não como cerca nem como bloco repetido.

## Escopo — arquivos em `assets/textures/` (filtro Nearest; normal map OpenGL, wrap)

| Arquivo | Tamanho (= unidades) | Vista | Conteúdo |
|---|---|---|---|
| `wall_face_long.png` + `_n` | 256×32 (8 × 1,0) | de frente | Face do muro, usada com v = 0 no topo da face: a face de 1,0 usa as linhas 0–31 e a face de 0,5 dos bancos usa só as linhas 0–15, então **a metade de cima (linhas 0–15) sozinha também tem que ler como muro completo** (pelo menos 2 fiadas inteiras, musgo e juntas na mesma proporção do todo). Pedra seca: blocos de 8 a 28 px de largura e 5 a 10 px de altura, em 3 a 4 fiadas de alturas desiguais; juntas horizontais desencontradas (nenhuma linha com ≥ 90% de junta), verticais desencontradas entre fiadas. Blocos em `#989680` `#B9B597` `#D3CCB4` (aresta de cima de cada bloco 1 tom mais clara, base 1 tom mais escura `#7A7A66`), juntas `#34403C` com `#1C2B2B` só nos cruzamentos. Musgo (`#496819` `#5E7C26` `#789636`) escorrendo de juntas e em 3 a 6 placas. **Seamless nos 2 eixos**: as bochechas de escada vão até 1,5 (48 texels) e empilham a textura em v; o corte na linha 16 (base da face de 0,5) não precisa coincidir com junta. Sem escurecer a base (a sombra de contato é do código). |
| `wall_cap_long.png` + `_n` | 128×16 (4 × 0,5) | de cima | Capeamento: uma fila de lajes claras ao longo do muro, larguras de 10 a 24 px, juntas de 1 px. Linha 0 = borda sobre a face; linha 15 = lado da grama. Lajes em `#B9B597` `#D3CCB4` com `#989680` nas bordas; musgo (`#5E7C26` `#789636` `#8FAE48` `#B0C860`) em 5 a 9 tufos irregulares que cobrem **30% a 50%** da tira, mais denso perto da linha 15. Seamless na horizontal. |
| `wall_cap_corner.png` + `_n` | 16×16 (0,5 × 0,5) | de cima | Laje de canto que fecha a junção de duas tiras de capeamento (quina convexa e côncava). Mesmos tons de `wall_cap_long`; musgo 20% a 45%. Simétrica sob rotação de 90° (o código gira livremente). Bordas compatíveis com as pontas de `wall_cap_long` (lajes, não junta, nas colunas/linhas 0 e 15). |
| `cards/moss_drape_0.png` `_1` | 128×12 (4 × 0,375) | de frente, alfa | Musgo pendurado pela borda do capeamento sobre a face. Mesmo cartão nas faces de 1,0 e de 0,5: com 12 texels de altura, no banco de 0,5 sobram sempre ≥ 4 texels de pedra limpa no pé (o musgo nunca chega ao chão); no muro de 1,0 ele cobre só o terço de cima, como na referência. Linhas 0–1 100% opacas; abaixo, cortinas e fios de 1 a 10 px de comprimento, larguras de 2 a 12 px, irregulares (nenhum comprimento repetido em sequência), a maioria curta (≤ 6 px). Cobertura opaca total 25% a 45%; linha 11 com ≤ 5% opaco. Topo de cada tufo mais claro. **Seamless na horizontal**; colunas 0–1 e 126–127 iguais nas duas variantes. |
| `stair_tread_long.png` + `_n` | 32×32 (1 × 1) | de cima | Piso de degrau de **0,5 de fundo (16 texels)**, para a célula que sobe 1 nível (2 degraus): 2 faixas de 16 linhas, cada faixa = 1 piso. Linha 0 de cada faixa = bocel claro (`#D3CCB4`), linhas 1–14 laje (`#B9B597` `#989680`, 1 ou 2 juntas verticais desencontradas por faixa), linha 15 = junta escura (`#5C6250`). Musgo raro nas juntas. Seamless na horizontal; faixas empilham sem costura. |
| `stair_tread_short.png` + `_n` | 32×32 (1 × 1) | de cima | Piso de degrau de **0,25 de fundo (8 texels)**, para a célula que sobe 2 níveis (4 degraus): 4 faixas de 8 linhas, cada faixa = 1 piso. Linha 0 de cada faixa = bocel claro (`#D3CCB4`), linhas 1–6 laje (`#B9B597` `#989680`, 1 junta vertical desencontrada por faixa), linha 7 = junta escura (`#5C6250`). Musgo raro nas juntas. Seamless na horizontal; faixas empilham sem costura. |
| `stair_riser_short.png` + `_n` | 32×32 | de frente | Espelho de **0,25 = 8 texels** (o mesmo nos dois tipos de célula de escada) em 4 faixas de 8 linhas, mesmos tons e tipo de bloco de `wall_face_long` (blocos de 8 a 20 px), para a escada parecer do mesmo muro. Seamless na horizontal. |

**Totais:** 7 texturas opacas + 6 normal maps + 2 cartões = **15 PNG**. Não sobrescrever nada da A03/A04 (os antigos `wall_face`, `wall_top`, `moss_fringe_*`, `stair_*` ficam até a limpeza, com OK do usuário).

### Script, checagem e prévia
- Gerador `tools/art/gen_a05.gd` (`extends SceneTree`, reaproveita `art_lib.gd` e `palette_a03.gd`, RNG com seed fixa por arquivo).
- Checagem `tools/art/check_a05.gd`: uma linha por arquivo e `A05 CHECK: PASS` / `FAIL (n problemas)`, código de saída 0/1.
- Prévia `docs/art-preview/a05-muro-alto.png`:
  - cada PNG a ×4 (as tiras longas a ×2);
  - **maquete do muro** a ×2, em elevação achatada, de cima para baixo: capeamento da crista (0,5) → face do muro de 1,0 com `moss_drape` → topo do banco (0,5 de `grass_forest_0` + 0,5 de capeamento) → face do banco de 0,5 com `moss_drape` → 0,5 de `grass_arena_0`; trecho reto de 12 unidades, tudo com u contínuo;
  - uma **quina convexa** e uma **côncava** vistas de cima (duas tiras + `wall_cap_corner`);
  - um lance de escada 0→1→3 ao lado do muro: célula de 1 nível (2 degraus, `stair_tread_long`) + célula de 2 níveis (4 degraus, `stair_tread_short`), espelhos de 0,25, com a bochecha de `wall_face_long` empilhada até 1,5;
  - a maquete ao lado de um recorte da referência (muro da frente) na mesma escala aproximada.

## Fora de escopo
- Malha, UV, cantos, sombra de contato, máscaras do chão, câmera (é a `010`).
- Texturas de chão (grama, terra, calçamento, tábuas), árvores, props, pilares.
- Editar `scripts/`, `scenes/`, `project.godot`, `docs/specs/`, `.import`. Cores fora da Paleta (propor no relatório).

## Direção de arte
`docs/direcao-de-arte.md` (Regras das texturas opacas, Normal maps, Laterais, Cartões, Paleta) com a exceção de tamanho acima. Sem contorno, sem gradiente global, sem luz lateral (topo de cada bloco mais claro), dithering ≤ 5%, sem anti-aliasing. Alvo: o muro da frente da referência, com blocos maiores e mais claros que o `wall_face` atual e menos musgo na face.

## Critérios de aceite

**Automáticos (`check_a05.gd` → `A05 CHECK: PASS`).** Y = 0,299R + 0,587G + 0,114B.
- [ ] Os 15 PNG existem com as dimensões da tabela; opacos com alfa 255; cartões com alfa binário (0/255).
- [ ] Todo pixel é cor da Paleta, só dos grupos Pedra e Musgo; `#1C2B2B` ≤ 2% em cada textura.
- [ ] `wall_face_long`: 5 a 8 cores; juntas (`#34403C` + `#1C2B2B`) entre 10% e 22%; musgo entre 5% e 15%; nenhuma linha com ≥ 90% de pixels de junta; luminância média entre 0,55 e 0,68. As mesmas faixas (juntas, musgo, luminância) valem também só para as linhas 0–15.
- [ ] `wall_cap_long`: musgo entre 30% e 50%; pedra clara (`#B9B597` + `#D3CCB4`) ≥ 30%; luminância média ≥ 0,08 acima da de `grass_arena_0` e ≥ 0,15 acima da de `grass_forest_0` (contraste com o chão).
- [ ] `wall_cap_corner`: igual a si mesma girada 90° em ≥ 85% dos pixels; musgo entre 20% e 45%.
- [ ] `moss_drape_*`: 128×12; linhas 0–1 100% opacas; cobertura entre 25% e 45%; linha 11 ≤ 5%; colunas 0–1 e 126–127 iguais nas duas variantes.
- [ ] `stair_tread_long`: linhas 0 e 16 com ≥ 80% de `#D3CCB4`; linhas 15 e 31 com ≥ 80% de `#5C6250`.
- [ ] `stair_tread_short`: linhas 0, 8, 16, 24 com ≥ 80% de `#D3CCB4`; linhas 7, 15, 23, 31 com ≥ 80% de `#5C6250`.
- [ ] Seamless (regra da A03: diferença de Y na borda ≤ 1,3 × a média entre vizinhas do interior) nos eixos indicados, albedo e normal map.
- [ ] Nenhum bloco com a mesma forma e tons repetido dentro de `wall_face_long` (comparação de janelas 12×8 alinhadas a blocos: nenhuma idêntica).
- [ ] Normal maps: comprimento 1 ± 0,06; Z ≥ 0,6; médias de X e Y em ±0,05; média de Z ≥ 0,9.

**Visuais (Lead Project, pela prévia)**
- [ ] A maquete lê como muro de pedra seca em dois patamares (banco baixo de 0,5 + muro de 1,0, crista a 1,5), sem grade de 1 unidade visível; a face de 0,5 não parece um pedaço cortado; o musgo do banco não chega ao chão; o capeamento se destaca da grama.
- [ ] Na escada da prévia, a bochecha empilhada não mostra costura em v e os dois tipos de piso parecem da mesma pedra.
- [ ] Ao lado do recorte da referência: tom de pedra, tamanho de bloco e quantidade de musgo parecidos.

**Processo**
- [ ] Rodar `gen_a05.gd` duas vezes gera PNG idênticos (md5); nenhum PNG da A03/A04 muda.
- [ ] Os dois comandos de validação do `CLAUDE.md` sem `ERROR` depois que os PNG existem.
- [ ] Relatório do `artist` com autocrítica contra a referência.
