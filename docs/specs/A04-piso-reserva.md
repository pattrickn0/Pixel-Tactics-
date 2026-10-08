# A04 — Piso da reserva (tábuas de madeira)

**Status:** aprovada pelo usuário em 2026-10-07 (tábuas de madeira mel). Liberada para o `artist` gerar.
**Depende de:** `docs/direcao-de-arte.md` (linhas novas de "Piso da reserva" em **Tons por material**, **Normal maps** e no uso da **Paleta**). **Usada por:** `009` (`Ground.BENCH`).
**Decisão do usuário (2026-10-07):** a reserva tem arte nova, sem reaproveitar `stone_path`.

## Objetivo
Dar às duas reservas (faixas de 20 × 3 unidades coladas aos lados compridos da arena, no mesmo nível dela) um piso próprio: **tábuas de madeira clara**, lido de longe como "banco/deck" e não como arena. Precisa contrastar com a grama da arena (`#5B9C47`) e com o calçamento de pedra (`stone_path`), mas parecer do mesmo jogo da referência `docs/reference/Gemini_Generated_Image_6oy5mo6oy5mo6oy5.jpg`: poucos tons, superfícies quase lisas, sem contorno.

## Escopo

### 1. Texturas — `assets/textures/` (32×32, RGBA8, opacas, vista de cima, **com normal map**)

| Arquivo | Conteúdo | Tons |
|---|---|---|
| `bench_floor_0` `_1` | **4 tábuas por tile**, paralelas ao eixo horizontal (U), cada uma com 8 linhas: 7 de madeira + 1 de fresta (linhas 7, 15, 23 e 31). Tábua em Casca e madeira: tom dominante `#C29A6C`; meio-tom `#A37C56` em 2 a 4 veios longos de 1 px (6 a 14 px de comprimento) por tile; `#D9BC86` em 1 a 3 trechos claros de 3 a 8 px no miolo das tábuas; no máximo 2 nós de 2×2 a 3×2 px (`#876547` com miolo `#6B4C3E`). Fresta em `#4B3339` com trechos `#6B4C3E`. Em cada tile, **1 ou 2 emendas de topo** (fresta vertical de 1 px, 7 px de altura) em tábuas diferentes, desencontradas entre as tábuas e entre `_0` e `_1`. Até 2 tufos de Musgo (`#5E7C26`, `#789636`, 2 a 4 px) só sobre frestas. Seamless nos 2 eixos; as duas variantes emendam entre si (linhas 7/15/23/31 de fresta e colunas 0 e 31 sem emenda de topo em nenhuma delas). | 4–6 |
| `bench_floor_0_n` `_1_n` | Normal map do mapa de altura da própria arte: tábua alta, fresta baixa, chanfro de 1 px na borda de cima e de baixo de cada tábua; veios e nós com relevo mínimo. Convenção OpenGL, wrap. | — |

Regras extras:
- **Contraste:** luminância média do albedo entre 0,50 e 0,62 (a grama da arena `#5B9C47` fica perto de 0,51, então a diferença vem do matiz quente e das frestas; o calçamento é cinza-bege, a tábua é marrom-mel).
- **Sem gradiente** e **sem luz lateral**: cada tábua clareia no miolo e escurece só junto à fresta, igual em cima e embaixo.
- Nenhum elemento marcante (> 4×4 px) repetido no mesmo tile.

**Totais:** 2 texturas + 2 normal maps = **4 PNG**.

### 2. Script, checagem e prévia
- **Gerador:** `tools/art/gen_a04.gd` (`extends SceneTree`), reaproveitando `tools/art/art_lib.gd` (normal map com wrap, gravação) e `tools/art/palette_a03.gd` (cores). Sem `class_name`. RNG com seed fixa por arquivo.
- **Checagem:** `tools/art/check_a04.gd` (`extends SceneTree`): mede os critérios automáticos abaixo, imprime uma linha por arquivo e termina com `A04 CHECK: PASS` ou `A04 CHECK: FAIL (n problemas)`, saindo com código 0 ou 1.
- **Prévia:** `docs/art-preview/a04-piso-reserva.png`:
  - `bench_floor_0` e `_1` a ×4, sozinhas e lado a lado;
  - um trecho de 20 × 3 tiles a ×2 alternando as variantes pela seed, com uma fileira de `grass_arena_0` encostada de um lado (limite reto arena/reserva) e `wall_face` + `wall_top` do outro;
  - o mesmo trecho ao lado de 3 tiles de `stone_path_0`, para mostrar que não se confundem.
- **Comandos:**
  ```bash
  G="/c/Users/pattr/Downloads/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe"
  "$G" --headless --path . --script tools/art/gen_a04.gd
  "$G" --headless --path . --script tools/art/check_a04.gd
  ```

## Fora de escopo
- Malha, UV, material, escolha de variante por célula, borda entre arena e reserva (é da `009`, no código).
- Slots, marcações de posição, bancos, caixotes ou qualquer prop na reserva.
- Mudar texturas da A03 ou os `rune_*`. Editar `scripts/`, `scenes/`, `project.godot`, `docs/specs/` ou `.import` (se o import precisar de ajuste, relate ao developer).
- Cores fora da Paleta. Se faltar cor, proponha no relatório e não pinte.

## Direção de arte
- Fonte única: `docs/direcao-de-arte.md` (**Regras das texturas opacas**, **Tons por material**, **Normal maps**, **Paleta**, linha "Piso da reserva").
- Filtro **Nearest**; 32 texels por unidade; sem contorno, sem dithering no miolo das tábuas, sem anti-aliasing.
- Alvo: madeira quente e calma, do mesmo bege-mel do tronco caído e dos bancos da referência, com menos detalhe que a casca das árvores. Na dúvida, menos veio.

## Critérios de aceite

**Automáticos (`check_a04.gd` sai com `A04 CHECK: PASS`).** Luminância Y = 0,299R + 0,587G + 0,114B, canais em 0 a 1.
- [ ] Existem os 4 PNG, 32×32, RGBA8, alfa 255 em todos os pixels.
- [ ] Todo pixel de `bench_floor_0`/`_1` é uma cor da Paleta, só dos grupos Casca e madeira e Musgo; `#1A1426` e `#2C212D` não aparecem.
- [ ] 4 a 6 cores distintas por textura; `#C29A6C` ≥ 45% dos pixels; frestas (`#4B3339` + `#6B4C3E` + Musgo) entre 8% e 16%.
- [ ] Linhas 7, 15, 23 e 31 com ≥ 85% de pixels de fresta; cada tile tem 1 ou 2 emendas de topo (colunas internas com ≥ 6 px de fresta dentro de uma tábua), e nenhuma nas colunas 0 e 31.
- [ ] Luminância média de cada textura entre 0,50 e 0,62; metade esquerda × direita e de cima × de baixo diferem no máximo 0,04.
- [ ] Emenda seamless nos 2 eixos (mesma regra da A03: diferença de Y na borda ≤ 1,3 × a média entre vizinhas do interior), para albedo e normal map; `_0` ao lado de `_1` também.
- [ ] Dithering (xadrez 2×2 de dois tons) em no máximo 5% dos pixels.
- [ ] Normal maps: comprimento 1 ± 0,06, Z ≥ 0,6; médias de X e Y em ±0,05; média de Z ≥ 0,9; ≥ 15% dos pixels com Z < 0,98; correlação de Pearson entre Y do albedo e os componentes X e Y do normal em [−0,2; 0,2].

**Visuais (Lead Project, pela prévia)**
- [ ] A reserva lê como deck de tábuas, claramente diferente da grama e do calçamento, sem grade visível nem repetição marcante no trecho de 20 × 3.
- [ ] Combina com a referência: madeira mel quente, poucos tons, sem contorno, sem ruído por pixel.

**Processo**
- [ ] Rodar `gen_a04.gd` duas vezes gera PNG idênticos (md5).
- [ ] Nenhum PNG da A03 nem de `assets/sprites/` muda.
- [ ] Os dois comandos de validação do `CLAUDE.md` rodam sem `ERROR` depois que os PNG existem.
- [ ] Relatório do `artist` com autocrítica contra a referência.
