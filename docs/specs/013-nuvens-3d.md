# 013 — Nuvens volumétricas fiéis à referência

**Vem depois de:** `012` (fechada em `revisoes/012-f3.md`). Esta spec substitui, **só para as nuvens**, a Tabela D da 012 (linhas "Mar de nuvens" e "Anel de nuvens do horizonte"), o item 16 da Fase 3 ("puffs billboard") e a linha "Nuvens" da tabela de `docs/direcao-de-arte.md`.
**Arte:** `A09-nuvens-volumetricas.md` (rampa de cor medida; o ruído 3D foi adiado em 2026-10-09, ver N3).
**Referência:** `docs/reference/ilha-flutuante.webp` (906×509; todas as medidas abaixo são da imagem ampliada para 1280×720 com Lanczos, como na 012).
**Prévia da análise:** `docs/specs/013-nuvens-analise.png` (massas, faixas de luz, rampas medidas e recortes). Ela fica junto da spec, e não em `docs/art-preview/`, porque essa pasta é do `artist`.

**Pedido e decisões do usuário (2026-10-08), literais ou resumidos fielmente:**
- "As nuvens eram 3D e agora viraram nuvens 2D, você botou uns PNG 2D. Eu gostaria que fossem realmente nuvens 3D, nesse estilo artístico, essa coisa bonita que está na referência. Mesmo sem o bloom/sun flare e os efeitos de pós-processamento que a referência obviamente tem (isso não mexemos agora), eu quero olhar para as nuvens e falar: é isso aqui, exatamente essas sombras, exatamente essa iluminação, exatamente esse gráfico. Bater 1:1 com a referência."
- O trabalho vai **por etapas**, cada uma fechada antes da próxima. Esta etapa é **só das nuvens**. Depois dela, o usuário testa.
- "Pode utilizar nuvens volumétricas se quiser." Depois: "Meu pc é parrudo, relaxa, vamos de volumétrica, otimização só no release oficial que estamos bem longe." Então a técnica é **volumétrica**, a qualidade visual vem primeiro e o **desempenho não é critério de aceite** nesta etapa (só é registrado).
- O custo de uso não é problema ("é um projeto de longuíssimo prazo").

**Decisões do usuário (2026-10-09), que mudam a régua desta spec:**
- **Forma congelada.** "Já está ficando bom a forma que ele está fazendo... os ajustes já foram o suficiente." E: "reaproveitar os modelos de nuvem prontos para preencher os outros ângulos da câmera, sem mais ajuste de forma." A partir daqui, **os lóbulos, os proxies, a base, a maciez da borda e o ruído das massas não mudam mais**. Os critérios de forma (estrutura, perfil, IoU, centróide e gradiente) viram **medida informativa**. Para preencher outros ângulos, só cópias das massas prontas (`CloudTables.INSTANCES`) e posicionamento.
- **Câmera do jogo:** o zoom inicial passa a ser **48,6** (10% mais perto), e o giro fica limitado a **±45°** (um passo para cada lado). As medidas contra a referência continuam na distância **54** (`MapCamera.REFERENCE_DISTANCE`), que a captura usa por padrão. Os ângulos que valem fora da vista padrão passam a ser **y−45 e y+45**, nas distâncias 48,6 e 54. O `CLAUDE.md` já foi atualizado.
- **Laterais:** "na lateral tem alguns pontos que estão mal preenchidos." Na revisão `revisoes/013-f1.md`, eles foram localizados nos cantos sudeste (vista y−45) e sudoeste (vista y+45), embaixo da borda da ilha.

## Objetivo
Na câmera padrão, cada massa de nuvem da referência aparece no mesmo lugar, com a mesma silhueta, a mesma luz (crista creme quente contra o sol, face rosada, vale e base lavanda-azulados) e a mesma maciez. São **volumes 3D de verdade** (raymarch), sem billboard, que continuam lendo como volume de qualquer ângulo da órbita. Embaixo da ilha fica um mar de nuvens também volumétrico, escurecido pela sombra da ilha.

## Análise das nuvens da referência

### Como medir (vale para a análise e para os critérios)
- Imagem em sRGB de 0 a 255. **L** = 0,2126 R + 0,7152 G + 0,0722 B. **S** = (máx − mín) / máx.
- **Ar** (nuvem, céu ou água clara) = S < 0,30 **e** L > 115 **e não** (G > R + 6 **e** G > B + 6). **Ar erodido** = ar após um filtro de mínimo 7 × 7 (tira a franja de folhas, cipós e rochas). **Céu** = ar com (B − R) > 24 e L < 215. Nuvem = ar menos céu. Toda medida "do ar" usa o ar erodido.
- **Iluminado** = ar erodido com L ≥ 215.
- **Tons:** a cor média dos pixels de ar cujo L está a ±3 percentis de P5, P25, P50, P75 e P95.

### O que define o visual (resumo)
1. **Fileiras e torres de cúmulos, sem céu limpo entre elas.** As nuvens não são bolinhas soltas. Nos lados do quadro, são **fileiras** de cúmulos uma atrás da outra (vistas de cima a 27°). Ao fundo, são **massas grandes** (torres e bancos) de 20 a 45 unidades. O céu azul só aparece em frestas pequenas (de 5% a 9% das caixas da direita).
2. **Luz de contraluz lateral.** O sol vem do oés-noroeste, da esquerda e um pouco de trás. A face que a câmera vê fica quase toda em **meia-sombra rosada e lavanda**. Só a **crista** de cada fileira ou lóbulo acende, creme quente, e mais forte do lado esquerdo. Na média, só de 9% a 31% do ar fica iluminado (L ≥ 215) nas massas laterais e no fundo à direita. A exceção é perto do sol (M1 e M2, de 51% a 72%).
3. **Perfil de cada fileira:** a crista sobe de golpe (de L ~165 para ~240 em 5 a 10 px, cerca de 0,4 a 0,7 unidade) e depois desce **devagar**, em gradiente quase linear, até o vale (de ~240 para ~165 em 40 a 60 px, cerca de 3 a 4,5 unidades). No vale, a fileira da frente corta de novo. Não há sombra projetada dura de um lóbulo no outro. O escuro entre os lóbulos é **oclusão macia** (o vale).
4. **Rampa de cor com troca de matiz:** sombra azul-lavanda fria → meio rosado (malva) → luz creme quente. Saturação baixa (S de 0,10 a 0,16). Não existe cinza neutro nem branco puro: o máximo é `#FEF4D6`.
5. **Translucidez:** as bordas finas viradas para o sol (cristas, bordas de cima) ficam mais claras e quentes que o miolo, como "forro de prata". O miolo grosso nunca chega a branco.
6. **Borda macia, sem contorno:** a silhueta é feita de bolotas redondas de tamanhos variados (as grandes têm de 60 a 170 px, e as bolinhas da borda, de 15 a 40 px). A borda é macia (gradiente médio de L entre 1,4 e 2,7 por px, medido pela ferramenta; corrigido em 2026-10-09) e nunca recortada.
7. **Pouca perspectiva aérea nas nuvens:** as massas a ~145 unidades (M6) têm quase o mesmo contraste das que estão a ~70 (M3): P10/P90 de 162/227 contra 167/236. A névoa de profundidade da cena (de 70 a 100) **não** pode lavar as nuvens.
8. **Base e fundo somem em lavanda-azul,** sem base reta e sem plano visível. O mar de baixo, à direita (M8), está **na sombra da ilha** (sol de 34° do oés-noroeste: a sombra cai para leste-sudeste, embaixo e à direita do quadro) e fica azul-acinzentado uniforme, com L ~150 e pouco contraste. Embaixo à esquerda (M4), fora da sombra, o mar fica claro, com crista creme.

### Tabela N1 — massas na câmera padrão (referência)
Caixas em px de 1280×720 (x0, y0, x1, y1). As massas e as cristas estão desenhadas na prévia. **2026-10-09:** a coluna do gradiente passou a ter os valores que `compare_images.gd --clouds` mede na própria referência (antes de 1,53 a 2,86; o resto da tabela bateu na autoverificação).

| Massa | Caixa | O que é | Ar | L P10/P50/P90 | Cor média | Iluminado | Centróide do iluminado | Gradiente médio / P95 |
|---|---|---|---|---|---|---|---|---|
| **M1** noroeste | 100, 40, 380, 220 | banco atrás e embaixo da ilhota das ruínas, perto do sol | 39% | 200/230/242 | `#EDDBC9` | 72% | (205, 103) | 2,11 / 6,9 |
| **M2** esquerda da cascata | 380, 40, 535, 260 | massa atrás da lâmina esquerda; a base vira a névoa da cascata | 51% | 198/215/239 | `#E5D6D2` | 51% | (459, 93) | 2,18 / 7,4 |
| **M3** oeste | 0, 220, 180, 520 | 4 fileiras à esquerda da ilha (cristas na tela em y ≈ 195, 330, 400 e 470) | 69% | 167/192/236 | `#D2C2C2` | 26% | (82, 379) | 1,69 / 5,7 |
| **M4** sudoeste baixo | 40, 540, 300, 720 | mar, embaixo da ponte e da ilhota oeste | 46% | 160/182/219 | `#C0B8BE` | 14% | (144, 617) | 1,40 / 4,6 |
| **M5** direita da cascata | 800, 40, 1000, 260 | massa larga e macia atrás da ilha alta, até a ilhota nordeste | 42% | 171/195/231 | `#CDC3CC` | 29% | (916, 110) | 2,58 / 8,9 |
| **M6** nordeste alto | 1000, 0, 1280, 230 | torre de cúmulo atrás da ilhota NE e dos cipós | 50% | 162/198/227 | `#CCC0C6` | 28% | (1102, 122) | 2,73 / 9,3 |
| **M7** leste | 1140, 230, 1280, 520 | 3 fileiras à direita da ilha (cristas em y ≈ 235, 355 e 405) | 47% | 160/179/214 | `#BAB5BE` | 9% | (1249, 324) | 1,77 / 5,4 |
| **M8** sudeste baixo | 980, 580, 1280, 720 | mar na sombra da ilha, embaixo da ponte leste | 7% | 139/150/156 | `#8C96AD` | 0% | — | 1,10 / 2,7 (não medido pela ferramenta) |

**Para comparação, a 012 entregue (billboards):** a estrutura (r, ver critérios) fica de −0,23 a 0,35, o IoU do iluminado de 0,00 a 0,17 e os centróides a 40–167 px. M3, M4 e M7 têm de 53% a 65% de iluminado (a referência tem de 9% a 26%), e M8 fica `#E1D7DB` (claro, fora da sombra). Os tons médios da 012 são brancos e chapados (P50 de M3 em `#E4D6DA`, com L 218 contra 192).

### Tabela N2 — tons medidos (P5 · P25 · P50 · P75 · P95)
| Massa | P5 | P25 | P50 | P75 | P95 |
|---|---|---|---|---|---|
| **Todas (M1–M7)** | `#959FB5` (L158) | `#B4AFBF` (177) | `#D6C4C5` (200) | `#EDD9CF` (220) | `#FDEED6` (239) |
| M1 | `#B4998C` (158)\* | `#E7D1C8` (213) | `#F6E3D1` (230) | `#FDECCD` (238) | `#FEF4D6` (244) |
| M2 | `#CDBFC8` (195) | `#D8C9CE` (204) | `#E5D4D1` (215) | `#F5E4D8` (231) | `#FEF1E0` (242) |
| M3 | `#A9A1B1` (164) | `#B9AEBA` (177) | `#D1BCBE` (192) | `#EBD5C9` (216) | `#FEEFD7` (240) |
| M4 | `#929DB4` (156) | `#A4A5B8` (166) | `#BFB3BD` (182) | `#DCC8C3` (204) | `#F1DDCA` (224) |
| M5 | `#9B9AA8` (155) | `#BCB3C4` (182) | `#CCBFCD` (195) | `#E7D6D5` (218) | `#F7E8E3` (235) |
| M6 | `#8F98AF` (152) | `#AEACC6` (174) | `#D5C2C6` (198) | `#EAD5CE` (217) | `#F7E4D7` (231) |
| M7 | `#8F9FB7` (157) | `#9EA6BB` (166) | `#B7B1BE` (179) | `#D6C2C0` (198) | `#EED8CB` (220) |
| M8 (sombra da ilha) | `#818597` (133) | `#8492AA` (145) | `#8D97AD` (150) | `#909AB3` (153) | `#9FA3B6` (164) |

\* O P5 de M1 tem mistura com a borda da ilhota. Não vale como alvo.

### Tabela N3 — forma de cada massa (o que construir)
"Px/u" é quantos pixels uma unidade ocupa naquela profundidade. A âncora no mundo é a posição sugerida para a massa cair no lugar certo (± 5 unidades). **O que vale é a tela.** As alturas são do topo das cristas.

| Massa | Forma (contada nos recortes) | Luz e sombra | Âncora no mundo (x, y, z) e extensão | Px/u |
|---|---|---|---|---|
| M1 | Banco baixo e largo: de 5 a 7 lóbulos grandes (raio de 4 a 7) e de 8 a 12 bolotas na crista (raio de 1,5 a 3). Contraste baixo | Quase todo creme; lavanda-rosado só embaixo da ilhota e nos vãos. É a mais quente (está do lado do sol) | centro (−48, −8, −85); x de −63 a −33, y de −21 a +3, z de −75 a −100 | 8,3 |
| M2 | De 3 a 4 lóbulos grandes empilhados (raio de 5 a 8), com a crista na tela em y ≈ 90–110. **M2b:** a névoa na base da cascata (tela x 560–800, y 190–265) entra como volume baixo e largo **na frente** do pé das lâminas | Crista creme à esquerda; o miolo é rosado claro; a base funde com a água e fica branca | M2: (−19, −9, −75); x de −28 a −10, y de −22 a +3. M2b: (4, −11, −54); x de −8 a 16, y de −16 a −6, z de −52 a −58 | 8,9 / 10,3 |
| M3 | **4 fileiras** paralelas, alongadas em X, que continuam pelo menos 15 unidades além da borda esquerda do quadro. De 3 a 5 lóbulos visíveis por fileira (raio de 2 a 5) e bolotas de 15 a 40 px na crista | Crista creme, face descendo para malva e vale lavanda (L ~160–175). A fileira R2 (tela y ≈ 330) e a R3 (≈ 400) têm as cristas mais claras | R1: x de −52 a −37 (até −70), z ≈ −40, topo −3. R2: x de −42 a −31, z ≈ −20, topo −6. R3: x de −42 a −30, z ≈ −16, topo −9. R4: x de −40 a −28, z ≈ −8, topo −11 | 12–17 |
| M4 | Uma massa: 2 lóbulos grandes (raio de 5 a 7) e de 4 a 6 bolotas. Crista 1 na tela em x 60–180, y ≈ 575, e crista 2 em x 210–300, y ≈ 640 | Crista creme no alto à esquerda, embaixo azul-lavanda (`#929DB4`), sem base reta | x de −33 a −19, z de −5 a +2, topo de −14 a −16 (embaixo da ilhota e da ponte oeste) | 18 |
| M5 | Massa larga e macia: de 4 a 6 lóbulos grandes (raio de 5 a 9), poucas bolotas, contorno pouco recortado | Iluminado no alto à esquerda (centróide em (916, 110)). Embaixo, some em lavanda atrás das árvores | (29, −11, −82); x de 14 a 45, y de −25 a +1, z de −72 a −95 | 8,4 |
| M6 | **Torre**: de 3 a 4 lóbulos de corpo (raio de 8 a 12) e de 8 a 10 bolotas na silhueta de cima e da esquerda (raio de 2,5 a 4,5). Tem uma **fresta de céu azul** na tela em x 1150–1200, y 160–210 | Bolotas de cima e da esquerda em creme e branco quente. Corpo malva com sombra azul-lavanda embaixo à direita | (67, −12, −100); x de 46 a 90, y de −28 a +3, z de −85 a −125 (atrás da ilhota NE, que está em (43, −3, −78)) | 7,4 |
| M7 | **3 fileiras** (cristas na tela em y ≈ 235, 355 e 405), que continuam além da borda direita. Entre R1 e R2, um **vão escuro** azul-acinzentado (L de 126 a 155, tela y 305–335) | Pouca luz: só as cristas acendem (9% do ar) | R1: x de 37 a 47 (até 65), z ≈ −30, topo −3. R2: x de 35 a 42 (até 60), z ≈ −19, topo −7. R3: x de 37 a 44 (até 60), z ≈ −12, topo −12 | 13–16 |
| M8 | Camada baixa do mar, poucos lóbulos legíveis | **Na sombra da ilha:** azul-acinzentado uniforme | x de 21 a 39, z de −8 a −3, topo de −18 a −22 | 16,5 |
| Mar | Camada contínua embaixo de tudo, com o topo ondulado em cúmulos (de y −24 a −16) e a base em −40, raio de até ~180 | Mesma luz das outras; mais funda é mais fria. A sombra da ilha escurece a parte de leste-sudeste | centrada na arena | — |

Câmera padrão para conferir a projeção (a mesma da 012): posição (0; 24,52; 43,81), mira (0, 0, −4,3), FOV vertical 37°, 16:9. Px/u = 360 / (tan 18,5° × profundidade) ≈ 1076 / profundidade.

## Decisões tomadas (Lead Project, 2026-10-08)
1. **Técnica: raymarch próprio em shader** (`spatial`), em volumes-proxy, e não `FogVolume` nem malha.
   - **Por que não `FogVolume`/névoa volumétrica do Godot:** ela é calculada numa grade de "froxels" (64 fatias em profundidade por padrão). As nuvens ficam de 45 a 200 unidades da câmera, e a crista precisa de borda de ~0,5 unidade. A grade daria fatias de várias unidades e borrões. Ela também não faz sombra própria do volume e mexe na névoa da cena inteira.
   - **Por que não malha** (aglomerado de esferas com shader): não tem translucidez nem sombra própria de verdade (precisa fingir as duas), a borda macia vira franja de alfa com erro de ordenação, e o usuário pediu volume.
   - **O raymarch dá o que a referência mostra:** densidade de lóbulos com borda macia, sombra própria por marcha até o sol (o vale e o miolo escuros, e a crista acesa), translucidez nas bordas finas e base que some.
2. **Luz "física na forma, pintada na cor".** O shader calcula a luz de cada amostra com transmitância até o sol (Beer), fase Henyey-Greenstein dupla (forro de prata contra o sol), termo "powder" e ambiente por altura. Isso vira um **escalar de luz** que passa por uma **rampa de cor medida na referência** (A09, `cloud_ramp.png`). Assim, a forma e a sombra vêm da física, e as cores (azul → malva → creme) batem por construção.
3. **Direção do sol:** continua só no nó `Sun`. Um script lê o `Sun` (direção, cor e energia) e publica isso em uniforms globais de shader (`RenderingServer.global_shader_parameter_*`) a cada quadro. Nenhum shader tem o vetor escrito. Se o developer preferir declarar o global em `project.godot`, descreve a mudança no relatório.
4. **Névoa:** as nuvens usam `fog_disabled` e a perspectiva aérea própria delas: no máximo 15% em direção a `#DCD6E6` a 200 unidades (análise, item 7). A névoa da cena (profundidade de 70 a 100, altura abaixo de −3) continua igual para o resto.
5. **Sombra da ilha nas nuvens:** o shader não lê o shadow map. Uma **máscara de pegada** vista de cima (PNG gerado pelo developer a partir do `ISLAND_OUTLINE` e das ilhotas e da ilha alta, sem desenho à mão) é amostrada ao projetar a amostra na direção do sol até o plano da ilha. Isso escurece M8 e o mar a leste-sudeste. É forma, então é do developer.
6. **Saem os billboards:** os aglomerados `cloud_a..e`, a névoa `mist_a` (billboard de `mist_puff`) e o plano `cloud_sea`. Os PNG `sky/cloud_puffs.png`, `sky/cloud_sea.png` e `fx/mist_puff.png` ficam sem uso, mas **não são apagados** sem OK do usuário. A cascata, o arco-íris e os vaga-lumes não mudam.
7. **Editável no editor:** cada massa (e cada fileira) é um nó próprio em `scenes/map.tscn`, em `Sky/Clouds`. Arrastar o nó move o volume (o shader trabalha no espaço local do nó). A forma (lóbulos) fica em tabela literal.
8. **Captura reproduzível:** as nuvens podem andar devagar no jogo (deriva do ruído ≤ 0,2 unidade/s, forma e posição fixas), mas **na captura o tempo das nuvens fica em 0**. Duas capturas iguais dão a mesma imagem.
9. **Desempenho:** não é critério (decisão do usuário). A otimização fica para o release. O custo vai no relatório só como informação.

## Escopo

### Fase 1: volumes, forma e layout (não depende da A09)
1. **Shader `assets/materials/cloud_volume.gdshader`** (decisões 1 a 5): proxy desenhado por dentro (`cull_front`, funciona com a câmera dentro), `unshaded`, `blend_mix`, `depth_draw_never`, `fog_disabled` e sem sombra. A marcha para na profundidade da cena (`hint_depth_texture`), o que deixa as nuvens abraçarem o penhasco e as ilhotas sem corte duro. Densidade = união suave dos lóbulos da massa (elipsoides) erodida por ruído 3D. Na Fase 1, o ruído é **procedural no shader** (hash com constantes fixas) e a rampa vem como 5 uniforms com os tons de "Todas" da Tabela N2. Deslocamento por pixel com ruído de gradiente intercalado (fórmula fixa) contra faixas de passo.
2. **Tabela literal `tools/kit/cloud_tables.gd`** (`CloudTables`): para cada massa, a lista de lóbulos em espaço local (centro, raios do elipsoide), mais a altura da base, a maciez da borda, a escala e a força do ruído e o tamanho do proxy. Sem sorteio. A tabela pode ser **ajustada com uma ferramenta de medição** (projetar os lóbulos e sobrepor na referência, por exemplo `tools/dev/cloud_fit.gd`), mas o que fica no repositório são números literais.
3. **Montagem:** um nó por massa em `Sky/Clouds` no `map.tscn` (M1, M2, M2b, M3-R1..R4, M4, M5, M6, M7-R1..R3, M8 e o Mar), com o material de cada massa gerado a partir da tabela (por `build_kit.gd` ou por um `tools/kit/build_clouds.gd` novo, sempre com saída idêntica entre execuções). `place_decor.gd` com `--force` continua o único jeito de reaplicar a tabela.
4. **Anel para os outros ângulos** (mudado em 2026-10-09): **cópias das massas prontas** (`CloudTables.INSTANCES`: massa de origem, posição, yaw e escala), sem forma nova, para que os ângulos que o jogador alcança, **y−45 e y+45**, tenham a mesma linguagem da vista padrão nas distâncias 48,6 e 54: fileiras dos dois lados da ilha (r de 30 a 60, topo de −3 a −12), mar de cúmulos embaixo da borda (como M4 e M8, topo de −14 a −22) e torres e bancos ao fundo (r de 80 a 130, topo ≤ +6). Nenhuma nuvem passa de y +6. Nenhuma cópia pode mudar as medidas da vista padrão (critérios). As 24 cópias de y90, y180 e y270 que já existem ficam, mas esses ângulos são só informativos.
5. **Sombra da ilha** (decisão 5) e **perspectiva aérea própria** (decisão 4).
6. **Uniforms globais do sol** (decisão 3) e **`cloud_time`** (decisão 8).
7. **Captura:** `--capture-frames=N` (só captura: quantos quadros esperar, porque o raymarch por software do container é lento) e `--cam-from=x,y,z --cam-to=x,y,z` (só captura, para a `013-perto`). Nenhuma regra de jogo muda.
8. **Medida:** `tools/dev/compare_images.gd --clouds` implementa as medidas de "Como medir" e dos critérios, para as massas da Tabela N1. Ele imprime uma tabela por massa e grava, com `--out`, a `013-comparacao` (ver Capturas).
9. **Teste novo `tools/tests/test_clouds.gd`** (critérios automáticos).
10. **Capturas da Fase 1** (lista mudada em 2026-10-09; nomes e argumentos na seção "Capturas"): `013-f1-default.png`, `013-f1-comparacao.png`, `013-f1-jogo.png`, `013-f1-y-45.png`, `013-f1-y+45.png`, `013-f1-jogo-y-45.png` e `013-f1-jogo-y+45.png`. As `013-f1-y90/y180/y270` já entregues ficam como informativas.

### Fase 2: rampa da A09 e calibração de cor, tom e luz (mudada em 2026-10-09)
**A forma está congelada.** Na Fase 2, não mudam os `lobes`, o `proxy`, a `base`, a maciez da borda (`edge_softness`, `base_softness`), o ruído (escala, força, erosão e a função de ruído do shader) nem a posição das massas da vista padrão. Muda só o que é **cor, tom e luz**: a rampa, a energia, a fase, o powder, o ambiente, a exposição e a gama por massa (`params`), a densidade de extinção usada na luz, a perspectiva aérea e a força da sombra da ilha. As cópias de `INSTANCES` também podem ser acrescentadas ou movidas. Se algum critério de cor só passar mudando a forma, o developer para e reporta (não muda a forma).
11. Troca da rampa de uniforms por `cloud_ramp.png` da A09 (linha 0: luz normal; linha 1: sombra da ilha). **O ruído procedural da Fase 1 fica.** As texturas de ruído 3D que estavam na A09 (`cloud_shape_3d.png` e `cloud_detail_3d.png`) foram adiadas para a otimização do release, porque trocar o ruído mudaria a forma congelada. Quando voltarem, vão ter que reproduzir a mesma forma.
12. Calibração (energia, fase, powder, ambiente, exposição e gama por massa, densidade de extinção, perspectiva aérea e sombra da ilha, tudo `@export` ou uniform) até passar os critérios de cor e tom. A rampa da A09 é **cor de tela** (depois do tonemap Filmic, exposição 1,25, branco 3). O shader compensa o tonemap com uma inversa aproximada documentada, ou por calibração, e o que vale é a medida na captura.
13. **Capturas finais** (nomes e argumentos na seção "Capturas"): `013-default.png`, `013-comparacao.png`, `013-jogo.png`, `013-y-45.png`, `013-y+45.png`, `013-jogo-y-45.png`, `013-jogo-y+45.png`, `013-perto.png` e `013-overview.png`.

### Capturas (2026-10-09)
Toda captura usa `--fixed-fps 60 --resolution 1280x720` (sem eles, a captura não é determinística) e `--hud=off`. Sem argumento de enquadramento, a captura fica na distância da referência, 54 (`MapCamera.REFERENCE_DISTANCE`). Com `--zoom=default`, fica no zoom inicial do jogo, 48,6. `G` é o executável do `CLAUDE.md`. Rode sem `--headless` (o raymarch precisa de GPU).

```bash
C="--fixed-fps 60 --resolution 1280x720"
"$G" --path . $C -- --hud=off --capture=docs/screenshots/013-default.png                       # medida (54)
"$G" --path . $C -- --hud=off --yaw=-45 --capture=docs/screenshots/013-y-45.png                # 54
"$G" --path . $C -- --hud=off --yaw=45 --capture=docs/screenshots/013-y+45.png                 # 54
"$G" --path . $C -- --hud=off --zoom=default --capture=docs/screenshots/013-jogo.png           # jogo (48,6)
"$G" --path . $C -- --hud=off --zoom=default --yaw=-45 --capture=docs/screenshots/013-jogo-y-45.png
"$G" --path . $C -- --hud=off --zoom=default --yaw=45 --capture=docs/screenshots/013-jogo-y+45.png
"$G" --path . $C -- --hud=off --overview --capture=docs/screenshots/013-overview.png
```
Na Fase 1, os mesmos comandos com o prefixo `013-f1-`. A `013-perto.png` usa `--cam-from`/`--cam-to` (o developer registra os argumentos). As `013-y90/y180/y270` são opcionais e informativas (`--yaw=90/180/270`).

## Fora de escopo
- Tudo o que não é nuvem: árvores fora de lugar, contorno da ilha principal, pontes, ângulo dos objetos, cascata, arco-íris, ilhotas, rochas, cipós e vaga-lumes (ficam para as próximas etapas que o usuário vai pedir).
- Bloom, sun flare, feixes de luz, DOF e qualquer pós-processamento da referência (decisão do usuário). A maciez das nuvens vem do próprio volume, e não de desfoque.
- Mudar a luz da cena (sol, ambiente, tonemap e névoa da cena), a câmera e o enquadramento. (A câmera do jogo mudou em 2026-10-09, para zoom inicial 48,6 e giro de ±45°, por pedido do usuário e fora desta spec. O enquadramento de medida continua o mesmo.)
- **Mudar a forma das massas** (lóbulos, proxies, base, maciez e ruído): congelada pelo usuário em 2026-10-09. Para cobrir ângulos novos, só cópias e posicionamento.
- Otimização (meia resolução, reprojeção temporal, LOD): fica para o release.
- Apagar PNG antigos de nuvem sem OK do usuário.
- `FogVolume`/névoa volumétrica do Godot e addons.

## Design técnico sugerido
- **Dados × visual:** as nuvens são só visuais, ficam fora do `MapData`, e nenhuma regra de jogo depende delas.
- **`cloud_volume.gdshader`** (um material por massa, com o mesmo shader; o número de draw calls não importa nesta etapa):
  - Uniforms por massa: `lobes[]` (`vec4` centro + raio) e `lobe_axes[]` (`vec3`, escala do elipsoide), `lobe_count`, `base_height` e `base_softness` (a base some), `edge_softness` (~0,5 unidade, Tabela N1, coluna do gradiente), `noise_scale`, `erosion` (mais na base e nas bordas, menos na crista), `density`.
  - Globais: `sun_direction`, `sun_color`, `sun_energy`, `cloud_time`, `island_shadow_mask` e o retângulo dela no mundo.
  - Marcha: passos primários (`@export`, sugestão de 128, máx. 192), saída antecipada com transmitância < 0,01, de 6 a 8 passos de luz em distância crescente, Beer + powder, HG duplo (g ≈ 0,6 para a frente e ≈ −0,2 para trás, misturados), ambiente `mix(ambiente_base, ambiente_topo, altura na massa)`, escalar de luz → rampa, perspectiva aérea própria e sombra da ilha (linha 1 da rampa ou multiplicador calibrado em M8).
  - Ordem com outros transparentes: as massas atrás da cascata (M2, M5 e M6) desenham **antes** das lâminas, e a M2b (névoa da base) desenha **depois**. Use `render_priority`.
- **Proxy:** caixa ou elipsoide que envolve os lóbulos com a folga do ruído. Regra da órbita da 012 para os vértices do proxy (r ≥ 55 ou y ≤ 0,51 r − 4), o que garante a câmera fora dos volumes no jogo.
- **Plano de corte da câmera:** o `far` precisa cobrir as massas do fundo (até ~260 unidades).
- **`@export`/uniforms ajustáveis no editor:** passos, maciez, densidade, erosão, energia, fase, powder, ambiente, perspectiva aérea, força da sombra da ilha e deriva.
- **Ferramenta de ajuste** (opcional, `tools/dev/`): projeta os lóbulos da tabela com a câmera padrão e desenha sobre a referência, para acertar a silhueta antes de rodar a captura lenta.

## Direção de arte
`docs/direcao-de-arte.md` (linha "Nuvens", atualizada para esta spec) e a referência. O alvo é o da análise: fileiras e torres de cúmulos, crista creme quente acesa contra o sol, face malva, vale e base azul-lavanda, borda macia de bolotas redondas, sem contorno, sem branco puro e sem cinza neutro. O mar embaixo fica claro fora da sombra da ilha e azul-acinzentado dentro dela. Nada de bolinha de algodão empilhada, base reta ou nuvem "no céu" acima da ilha. As cores-alvo são as da Tabela N2. A paleta antiga de nuvem (`#9C9CB8` `#C8C0D4` `#ECE6EE` `#FFF6EC`) dá lugar a ela.

## Critérios de aceite

### Automáticos (`tools/tests/test_clouds.gd` e greps)
- [ ] **Sem billboard:** todo nó com malha em `Sky/Clouds` usa o `cloud_volume.gdshader`. Nenhum material da cena usa `cloud_puff.gdshader`, `billboard_mode` ou `mist_puff`, e o `map.tscn` não tem `cloud_a..e`, `mist_a` nem `cloud_sea`. `grep -rn "cloud_puffs.png\|cloud_puff.gdshader\|mist_puff" scenes/ scripts/ tools/kit/` não retorna nada (a não ser o próprio arquivo antigo do shader e do material, se ficarem no disco).
- [ ] O shader de nuvem não tem direção de sol escrita (só lê o uniform global), e o global é atualizado a partir do nó `Sun` (o teste gira o `Sun` e confere o uniform).
- [ ] Tabela: cada massa da Tabela N3 existe com o número de lóbulos dela (dentro da faixa). Nenhum vértice de proxy fere a regra da órbita, e nenhuma nuvem passa de y +6. Isso vale também para as cópias de `INSTANCES`. **2026-10-09:** os 4 desvios da forma congelada listados em `FROZEN_SHAPE` (`test_clouds.gd`) só são informados. A lista não pode crescer, porque a forma não muda mais.
- [ ] Layout feito à mão: `grep -rnE "RandomNumberGenerator|FastNoiseLite|randi\(|randf\(|randomize" scripts/map scripts/match tools/kit` continua vazio. Gerar os materiais e as malhas das nuvens duas vezes dá arquivos idênticos (md5).
- [ ] **Determinismo da captura:** duas capturas padrão seguidas, com os argumentos da seção "Capturas" (`--fixed-fps 60 --resolution 1280x720`), têm diferença média de L ≤ 0,5 em cada caixa M1–M8. Na Fase 1, o md5 saiu idêntico.
- [ ] Todos os `tools/tests/test_*.gd` com código 0 (`test_composition`, `test_arena_visibility` com as nuvens novas, `test_atmosphere` e os outros).
- [ ] Os dois comandos de validação do `CLAUDE.md` sem `ERROR`/`SCRIPT ERROR` e sem warnings do nosso código.

### Medida das massas (`compare_images.gd --clouds`, captura padrão 1280×720 sem HUD, contra a referência ampliada)
**Autoverificação da ferramenta:** com `--a` = a própria referência, r = 1 e IoU = 1, e os valores da referência impressos batem com a Tabela N1 dentro de ±3 em L e de ±1,5 ponto percentual nas frações. Se o Lanczos do Godot der diferença maior, o developer registra os valores dele no relatório e o Lead Project atualiza a tabela.

Definições: **estrutura** = correlação de Pearson entre o L desfocado (gaussiano σ = 6 px, sobre a imagem inteira) da captura e o da referência, nos pixels da caixa que são ar erodido nas duas. **Perfil** = média de L do ar erodido em faixas de 20 px de altura a partir do topo da caixa (faixa válida se as duas imagens têm ≥ 20 px de ar nela; mínimo de 4 faixas válidas), com Pearson r e erro médio absoluto (MAE). **IoU do iluminado** e **centróide do iluminado** na caixa. **Gradiente** = média e P95 do módulo do gradiente (diferenças centrais) de L desfocado com σ = 1, no ar erodido. **Cor** = distância RGB normalizada (como na 012).

**2026-10-09 (forma congelada pelo usuário):** as linhas marcadas "(informativo)" medem forma (estrutura, perfil, IoU, centróide e gradiente). Elas continuam impressas pelo `--clouds` e vão no relatório, mas **não bloqueiam** nenhuma fase e não justificam mudar lóbulos.

| Critério | Massas principais **M2, M3, M5, M6** | Secundárias **M1, M4, M7** |
|---|---|---|
| Estrutura r (informativo) | ≥ 0,60 | ≥ 0,50 |
| Perfil: r / MAE (informativo) | ≥ 0,75 / ≤ 10 | ≥ 0,60 / ≤ 14 |
| IoU do iluminado (informativo) | ≥ 0,45 | ≥ 0,35 |
| Centróide do iluminado (informativo) | ≤ 25 px | ≤ 35 px |
| L P10, P50 e P90 | cada um a ±10 da Tabela N1 | ±14 |
| Fração iluminada | ±10 pontos | ±12 pontos |
| Cor média do ar | ≤ 4% | ≤ 5% |
| Tons P5, P50 e P95 (Tabela N2) | cada um ≤ 6% | ≤ 8% |
| Gradiente médio (captura ÷ referência) e P95 (informativo) | de 0,75 a 1,30, e P95 ≤ 1,30 × ref | de 0,70 a 1,40, e P95 ≤ 1,40 × ref |

- [x] ~~**Fase 1:** estrutura, perfil, IoU e centróide da tabela (forma e lugar), com a rampa provisória.~~ Informativo desde 2026-10-09 (forma congelada). Valores da Fase 1 em `revisoes/013-f1.md`.
- [ ] **Fase 2:** as linhas da tabela que **não** são informativas: L P10/P50/P90, fração iluminada, cor média do ar e tons, calibradas só por cor, tom e luz (ver "Fase 2").
- [ ] **M8 (sombra da ilha), Fase 2:** cor média do ar ≤ 8% de `#8C96AD`, P50 ≤ 160 e P90 − P10 ≤ 30.
- [ ] **Caixas de nuvem da 012** (agora obrigatórias): nuvem à esquerda (40, 320, 140, 380) `#D9C7C2`, nuvem embaixo à esquerda (30, 560, 150, 700) `#938B8C` e nuvem à direita (1190, 330, 1270, 420) `#B9B3BA`, cada uma ≤ 8%.
- [ ] **Sem regressão no quadro** (medidas de controle da direção de arte): saturação média ≥ 0,36, P95 de L ≥ 226, L < 50 ≥ 13%, leitosos ≤ 30%, e a caixa da ilha com L médio ≤ 110 e L < 50 ≥ 16%. As outras caixas de cor da 012 continuam passando, e `test_composition` também. **Fase 2** para os leitosos (2026-10-09): a 012 aprovada mede 0,276 neste Windows e a Fase 1 mede 0,313. A subida vem das nuvens (o tom delas é "leitoso" por definição) e se resolve com cor, principalmente M8 escuro na sombra da ilha. As outras medidas do quadro valem desde a Fase 1.

### Ângulos jogáveis (y−45 e y+45, sem referência direta; mudado em 2026-10-09)
Valem nas 4 capturas `y-45`, `y+45` (distância 54), `jogo-y-45` e `jogo-y+45` (48,6), e os itens de preenchimento valem também em `default` e `jogo` (yaw 0). Medida pelo `compare_images.gd --turn`.

**Bloco chapado:** bloco de 80 × 80 px da grade fixa (cantos em múltiplos de 80) com ≥ 98% de ar (definição de "Como medir", sem erosão) e desvio-padrão de L < 4. Na referência ampliada e na vista padrão da Fase 1, não há nenhum de y ≥ 240 para baixo. Nas vistas ±45 da Fase 1, há de 1 a 5 (os buracos da revisão `013-f1`).

- [ ] **Fase 1, preenchimento:** nenhum bloco chapado com y ≥ 240 em nenhuma das 6 capturas. A lateral e a parte de baixo do quadro leem como a vista padrão: fileiras dos lados, mar de cúmulos com cristas embaixo da borda (como M4 e M8) e torres e bancos ao fundo, sem nuvem acima de y +6 e sem faixas de passo nem anéis no mar. Tudo com **cópias** das massas prontas.
- [ ] **Fase 1:** a vista padrão não muda com as cópias novas: `--same` entre antes e depois ≤ 0,5 em cada caixa M1–M8, nas distâncias 54 e 48,6.
- [ ] **Fase 2, tom:** no ar erodido da metade de cima do quadro, P10 ≤ 185 e P90 ≥ 220 (volume com luz e sombra, não chapado), S média do ar entre 0,06 e 0,20, e a rampa medida com os mesmos tons da Tabela N2 (P50 a ≤ 10% de `#D6C4C5`, com folga porque a luz muda com o ângulo). Na Fase 1, é informativo (y+45 deu P10 187 e 189).
- [ ] Visibilidade da arena: igual à 012 (nenhum volume entre a câmera e a arena), com yaw −45, 0 e +45 nas distâncias 48,6, 54 e máxima, além dos yaws que o teste já cobre.
- **Informativo:** y90, y180 e y270 (não alcançáveis no jogo). Se o developer capturar, roda o `--turn` e registra, mas não bloqueia.

### Por captura (Lead Project)
- [ ] **`013-comparacao.png`**: em cima, a referência e a captura lado a lado. Embaixo, recortes 2× **lado a lado (referência | captura)** de M3, M6, M5, M4 e M7. Olhando os recortes, as massas leem como "a mesma nuvem" na luz e na cor: crista creme, face malva, vale e base lavanda-azulados, sem branco chapado nem cinza neutro. A forma (fileiras e torres) foi aprovada pelo usuário em 2026-10-09 e não é julgada de novo.
- [ ] **`013-perto.png`** (`--cam-from`/`--cam-to` perto das fileiras de M3, com uma massa ocupando ≥ 25% do quadro; o developer registra os argumentos): volume legível, sem faixas de passo, sem caixas do proxy visíveis, sem corte duro onde a nuvem encontra o penhasco, e sem ruído granulado.
- [ ] **`013-overview.png`**: o anel e o mar em volta da ilha inteira, sem buraco de "céu de baixo" na frente da ilha.
- [ ] Nenhum halo nem erro de ordem com a cascata (as lâminas na frente de M2, M5 e M6, e a névoa M2b na frente do pé das lâminas), o arco-íris e os vaga-lumes.

### Sempre
- [ ] Relatório com: arquivos criados, alterados e removidos; como testar (F5, girar com A/D, zoom, Espaço); a tabela do `--clouds` (todas as massas e todos os critérios, com a referência ao lado); **custo, só como informação**: draw calls, primitivas, passos usados, número de volumes e, se der para medir, o tempo de GPU por quadro (`viewport_get_measured_render_time_gpu`). O FPS do container (Vulkan por software) não vale como medida. Também o tempo de cada captura no container e as limitações.

## Ordem de trabalho
1. **Artist (A09)** e **developer (Fase 1)** começam juntos. A Fase 1 não espera a arte: usa ruído procedural e rampa em uniforms.
2. O Lead Project revisa a A09 (prévia e PNG) e a Fase 1 (forma e lugar, pelos critérios da Fase 1 e pelas capturas `013-f1-*`). **2026-10-09:** a Fase 1 voltou com `AJUSTES` só de preenchimento das laterais com cópias (`revisoes/013-f1.md`), e a A09 ficou reduzida à rampa.
3. **Developer (Fase 2):** integra a rampa da A09 aprovada e calibra cor, tom e luz, sem mudar a forma. Capturas finais.
4. O Lead Project revisa a Fase 2 → o Orchestrator entrega ao usuário para ele testar. Só depois vem a próxima etapa do mapa.

## Decisões que ficam com o usuário (com recomendação)
- **N1. Movimento das nuvens no jogo.** A referência é uma imagem parada. **Recomendação: deriva muito lenta do ruído** (as bolotas "respiram"; a massa não sai do lugar), desligável por `@export`, e parada na captura. Alternativa: nuvens totalmente paradas.
- **N2. Brilho do sol perto de M1.** Parte do creme forte em volta das ruínas é bloom e névoa do sol da referência, que o usuário deixou para depois. **Recomendação: M1 é massa secundária** (tolerância maior) até a etapa de pós.
- **N3. Texturas de ruído 3D da A09 (2026-10-09, decisão do Lead Project, para o usuário confirmar).** Elas foram adiadas para a otimização do release, porque trocar o ruído procedural muda a forma que o usuário congelou. Se o usuário quiser o ruído da A09 já, a forma vai mudar no detalhe (bolotas e erosão) e precisa de nova aprovação visual.

## Registro de mudanças
- **2026-10-09** (decisões do usuário e revisão `013-f1`): forma congelada (os critérios de forma viraram informativos, e a Fase 2 ficou só com cor, tom e luz); ângulos jogáveis y−45 e y+45 nas distâncias 48,6 e 54 no lugar de y90, y180 e y270 (que viraram informativos); critério de "bloco chapado" para as laterais; capturas novas (`jogo`, `y-45`, `y+45`, `jogo-y±45`) com `--fixed-fps 60 --resolution 1280x720`; coluna do gradiente da Tabela N1 com os valores da ferramenta; leitosos passam para a Fase 2; a A09 ficou só com a rampa (ruído 3D adiado, N3).
