# A09 — Rampa de cor das nuvens volumétricas (o ruído 3D foi adiado em 2026-10-09)

**Usada por:** `013-nuvens-3d.md` (Fase 2). A Fase 1 da 013 não depende desta arte.
**Depende de:** `docs/direcao-de-arte.md` e da referência `docs/reference/ilha-flutuante.webp`. A análise das nuvens (massas, tons e como medir) está na 013 e em `docs/specs/013-nuvens-analise.png`.
**Decisões do usuário (2026-10-08):** nuvens 3D de verdade, volumétricas, "exatamente essas sombras, exatamente essa iluminação". Procedural com **seed fixa** é permitido na arte.
**Mudança de 2026-10-09 (Lead Project, a partir da decisão do usuário de congelar a forma das nuvens):** esta spec agora é **só a rampa** (`cloud_ramp.png`). As texturas de ruído 3D (`cloud_shape_3d.png` e `cloud_detail_3d.png`) foram **adiadas** para a otimização do release, porque trocar o ruído procedural do shader mudaria a forma que o usuário aprovou (spec 013, N3). O texto delas fica abaixo, riscado, para quando voltarem.

## Objetivo
Dar ao shader volumétrico da 013 ~~(1) o ruído 3D que esculpe as bolotas redondas e a borda macia dos cúmulos e (2)~~ a rampa de cor **medida na referência**, que transforma a luz calculada nas cores de tela da imagem: sombra azul-lavanda, meio malva e crista creme quente. O artist não desenha a silhueta nem a posição de nenhuma nuvem. Isso é forma, do developer.

## Como produzir
- Script `tools/art/gen_clouds_a09.gd` (`extends SceneTree`, API `Image`), rodando headless. As seeds ficam escritas como constantes, e rodar duas vezes dá PNG idênticos (md5).
- ~~O ruído 3D é **periódico nos 3 eixos** (o Worley usa pontos de célula com volta, e o Perlin usa gradientes com volta), para o shader repetir sem emenda.~~ (adiado)
- ~~**Atlas de fatias:** a fatia de índice k fica na coluna k % C e na linha k / C (C = número de colunas da tabela), com a fatia 0 no canto de cima à esquerda. O developer importa como `Texture3D` com essas fatias.~~ (adiado)
- A rampa é cor sRGB de tela. (Os ruídos adiados seriam dados lineares de 0 a 255, sem correção de gama.)

## O que entregar

| Arquivo | Tamanho | Conteúdo |
|---|---|---|
| ~~`assets/textures/scenery/sky/cloud_shape_3d.png`~~ (adiado) | 2048×1024, RGBA8, opaco | Ruído 3D de **128³** em **16 colunas × 8 linhas** de fatias de 128×128. **R:** Perlin-Worley (Perlin fBm de 4 oitavas, frequência base 4 por período, remapeado pelo Worley invertido de frequência 4), o "corpo" das bolotas. **G, B, A:** Worley invertido (1 − distância ao ponto mais próximo, normalizado) nas frequências 4, 8 e 16 por período |
| ~~`assets/textures/scenery/sky/cloud_detail_3d.png`~~ (adiado) | 256×128, RGBA8, opaco | Ruído 3D de **32³** em **8 colunas × 4 linhas** de fatias de 32×32. **R, G, B:** Worley invertido nas frequências 2, 4 e 8 por período. **A** = 255 |
| `assets/textures/scenery/sky/cloud_ramp.png` | 256×4, RGB8 sRGB | **Linha 0 (luz normal):** rampa de 256 tons, da sombra (x = 0) à luz (x = 255), **medida na referência** (ver abaixo). **Linha 1 (sombra da ilha):** rampa medida em M8, esticada nos 256 tons. **Linhas 2 e 3:** cópias das linhas 0 e 1 (para o filtro não misturar as linhas) |

### Como medir a rampa (linha 0)
1. A referência ampliada para 1280×720 com Lanczos.
2. Pixels de **ar erodido** (fórmula de "Como medir" da 013: S < 0,30, L > 115, não verde, filtro de mínimo 7 × 7) dentro das caixas **M1 a M7** da Tabela N1 da 013, todos juntos.
3. Ordene por L e divida em 256 quantis iguais (o tom x cobre de x/256 a (x + 1)/256 da distribuição, sem cortar as pontas, porque a erosão já tira as franjas). A cor de cada quantil é a média RGB dos pixels dele.
4. Suavize ao longo de x com janela de 9 tons (média móvel), mantendo **L monotônico crescente**.
5. A linha 1 sai do mesmo processo só com a caixa M8 (980, 580, 1280, 720).

## Critérios de aceite
- [ ] O PNG da rampa (`cloud_ramp.png`) existe com o tamanho e o formato da tabela (2026-10-09: os 2 de ruído estão adiados). Rodar o script duas vezes dá md5 idênticos.
- ~~**Periodicidade:** em cada canal de cada ruído, a diferença média entre bordas opostas de cada fatia (x = 0 contra x = último, e y idem) e entre a última fatia e a primeira é ≤ 2% da faixa (o mesmo critério das texturas seamless).~~ (adiado)
- ~~**Faixa útil:** em cada canal de ruído, P5 ≤ 0,15 e P95 ≥ 0,85 (em 0 a 1), com média entre 0,40 e 0,65. O canal R de `cloud_shape_3d` lê como **bolotas redondas** numa fatia (manchas claras arredondadas com vales estreitos), e não como névoa de Perlin nem como células de Voronoi com aresta reta.~~ (adiado)
- [ ] **Rampa, linha 0:** os tons em x = 13, 64, 128, 191 e 242 (P5, P25, P50, P75 e P95) ficam a ≤ 3% (distância RGB normalizada) de `#959FB5`, `#B4AFBF`, `#D6C4C5`, `#EDD9CF` e `#FDEED6` (Tabela N2 da 013, linha "Todas"). L cresce em toda a linha. A matiz vai de azul-lavanda (B > R em x ≤ 64) a creme quente (R > B em x ≥ 191). Nenhum tom tem S > 0,22.
- [ ] **Rampa, linha 1:** os tons em x = 13, 128 e 242 a ≤ 3% de `#818597`, `#8D97AD` e `#9FA3B6`.
- [ ] **Prévia `docs/art-preview/a09-nuvens.png`**, com: ~~4 fatias de cada ruído, canal por canal, e um ladrilho 2 × 2~~ (adiado); a rampa ampliada (cada linha com 40 px de altura), com os 5 tons-alvo marcados embaixo e o valor medido ao lado; e o recorte da referência das massas M3 e M6 ao lado da rampa.
- [ ] Relatório com o caminho do script, o md5 do PNG, os valores medidos da rampa (os 5 tons das duas linhas) e o tempo de geração.

## Fora de escopo
- Desenhar nuvens, silhuetas, puffs ou atlas de billboard (saíram com a 013).
- Mexer em `cloud_puffs.png`, `cloud_sea.png` ou `mist_puff.png` (ficam no disco, sem uso, até o usuário decidir).
- Import, shader, layout e calibração da cor no jogo (developer).
