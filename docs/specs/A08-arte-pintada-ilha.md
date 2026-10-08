# A08 — Arte pintada do cenário (ilha flutuante)

**Usada por:** `012-ilha-flutuante-rio.md` (revisão 1). A leva 1 entra na Fase 2 da 012 e a leva 2 na Fase 3.
**Substitui:** `A07` (pixel art, nunca gerada). As `A03` e `A06` viram histórico.
**Depende de:** `docs/direcao-de-arte.md` (reescrita em 2026-10-08) e da referência principal `docs/reference/ilha-flutuante.webp`.
**Decisões do usuário (2026-10-08):** "Pixel art serão só os personagens"; "esse gráfico exatamente, nessas posições, igual a todo, tudo"; dia claro com toque quente.
**Procedural permitido (decisão do usuário, 2026-10-08):** a arte do cenário pode usar texturas, ruído e gradientes gerados por código com **seed fixa** (mesmo script → mesmo resultado). Isso substitui, só para a arte do cenário, a regra de 2026-10-07 e as regras "sem RNG/sem ruído" da A06/A07. O layout do mapa continua feito à mão.

**Revisão r1 (2026-10-08, `revisoes/A08.md`):** mudaram `wall_top` (menos musgo, crista clara), `arena_ring` (cores medidas) e os critérios de grama e de coníferas. Mudanças marcadas com **(r1)**.

**Revisão r2 (2026-10-08, `revisoes/A08.md` revisão 2, com a arte medida no jogo):** voltam `leaf_clumps_*` (couve-flor no jogo), `conifer_tiers` (pagode), `arena_dirt` (halo claro e borda de adesivo) e `arena_slabs` (pedras chapadas). A leva 1 fecha com eles. Na leva 2, `cloud_puffs` ganha critério de branco e de base lavanda. Mudanças marcadas com **(r2)** e **(f2)**.

**Atualização de 2026-10-08 (revisão `revisoes/012-f1.md`):** a terra da arena, o círculo e as lajes soltas foram medidos de novo na referência, e entrou a variante de muro com musgo para as faces externas. Mudanças marcadas com **(f1)**.

## Objetivo
Dar ao cenário as texturas pintadas que fazem a captura do jogo parecer a referência: grama viçosa, terra alaranjada com o círculo de pedra, pedra bege em blocos com musgo, lajes, folhagem em tufos redondos, coníferas, penhasco marrom com raízes e cipós, cascata, nuvens fofas, chama e madeira. Tudo deve ler bem na câmera padrão (cerca de 20 px de tela por unidade) e não pode desmanchar de perto.

## Como produzir (pipeline do artist)
Continua o fluxo atual: scripts GDScript `extends SceneTree` em `tools/art/`, rodando headless e gravando PNG. Muda a técnica:
1. **Biblioteca `tools/art/paint_lib.gd`:** preenchimento em gradiente; mancha suave (elipse girada com queda suave); **pincelada** (carimbos ao longo de uma curva, com afinamento, cor tirada de uma rampa da paleta e opacidade); máscara de baixa frequência (`FastNoiseLite` com **seed literal**) com distorção de domínio; desfoque separável; carimbo e ruído com volta (toroidais) para ficar seamless; altura → normal (Sobel sobre a altura desfocada, OpenGL); **supersampling** (pinta em 2× e reduz) para borda limpa; e alfa recortado com RGB dilatado para fora (sem halo escuro nos mipmaps).
2. **Ordem de pintura de cada textura:** cor base → manchas grandes de valor (de 1/8 a 1/2 do quadro) → formas (blocos, lajes, tufos) → pinceladas de detalhe só nas formas → luz de cima (topo de cada forma mais claro) → redução 2×.
3. **Paleta medida:** um script lê a `ilha-flutuante.webp` (o Godot abre WebP), amostra as regiões listadas na prévia e grava os valores medidos. As texturas usam rampas construídas a partir desses valores e da paleta-alvo da direção de arte.
4. **Determinismo:** cada gerador tem as seeds escritas como constantes. Rodar duas vezes dá PNG idênticos (md5).

Pastas novas, separadas das texturas pixel art antigas: `assets/textures/scenery/{ground,decals,stone,foliage,island,water,sky,fx,props}/`. A densidade é de **64 px por unidade**, salvo quando a tabela diz outra coisa. Os mipmaps e o filtro linear ficam com o developer (import e material).

## Leva 1: chão, arena, pedra e folhagem (maior impacto na semelhança)

| Arquivo | Tamanho | Conteúdo |
|---|---|---|
| `ground/grass_a.png` | 512×512 (8 × 8), opaco, seamless 2 eixos | Grama viçosa ao sol: base `#7FA22C`, manchas de `#5E8424` e `#A8C447`, pinceladas curtas e curvas em várias direções, sem grão |
| `ground/grass_b.png` | 512×512, idem | Variação mais verde-amarelada, com trevos e algumas florzinhas planas (rosa, branca, amarela, azul) |
| `ground/blend_mask.png` | 256×256 (cobre 32 × 32 no shader), opaco, seamless | R: mistura a ↔ b. G: áreas mais secas ou com mais flores. Manchas grandes e orgânicas |
| `decals/arena_dirt.png` **(f1)** | 1024×768 (16 × 12), alfa suave | Mancha de terra **marrom-alaranjada**, não laranja chapado. Na referência, a média da terra iluminada é `#AE813F` (a Fase 1 do jogo deu `#C1873F`, clara e uniforme demais). Rampa: terra batida escura `#74502C`/`#8A5E34` em manchas grandes (20% a 30% da área, mais no sul e no oeste da mancha), tom médio `#A87A3C`/`#B3843D`, luz `#C89A55`/`#D6AA66` em manchas, e uma **borda escura avermelhada** (`#6E4228` a `#7E5A2C`) de 0,2 a 0,5 de largura, esfiapada para dentro da grama. Dentro: 8 a 14 plantinhas verdes pintadas (tufos de 0,3 a 0,6), seixos e grãos claros esparsos. Forma de retângulo arredondado alongado em X, com braços curtos. O opaco ocupa cerca de 13 a 14,5 × 10 a 11. Desvio-padrão da luminância nos pixels opacos ≥ 24. **(r2)** Sem halo claro em volta do anel; terra escura (L ≤ 95) em 25% a 35% dos opacos; clara (L ≥ 159) em ≤ 10%; na coroa de raio 1,3 a 3,0 do centro do círculo, L médio ≤ L médio da mancha + 3; borda de 0,1 a 0,6 cortada por 10 a 20 entradas de grama; 20 a 30 plantinhas (verde em 2% a 5% dos opacos); cor média a ≤ 5% da versão r1 |
| `decals/arena_ring.png` **(f1)** | 384×384 (6 × 6), alfa suave | Centro do círculo, como na referência (não é anel regular de lajes). **(r1, valores medidos na referência):** um **anel grosso de terra mais escura** (`#8A5A36` a `#9A6440`, de 0,35 a 0,5 de largura) até raio cerca de 1,3, em volta de um **miolo claro irregular e grande** (`#D8A862` a `#E2AE64`, raio de 0,6 a 0,8, mancha torta e fora do centro); e **dois crescentes claros** (`#DBAF5C` a `#E5B96F`), a oeste e a leste, até raio 1,9, abertos ao norte e ao sul, com **pouco contraste** contra a terra em volta. A média do disco (raio 1,3) fica a ≤ 10% de `#B27541`. Borda suave. Nada emissivo |
| `decals/arena_slabs.png` **(f1)** | 1024×512, alfa | Atlas 4 × 2 de células 256×256 (4 × 4 unidades): **5 pedras compridas e curvas** chatas (de 1,2 a 1,8 × 0,25 a 0,4), cinza-bege (`#7E786A` → `#B8AE98`, topo mais claro, meio enterradas, com terra escura na volta), que formam o anel externo quebrado em raio de 3,5 a 4,5; **1 laje gasta** (0,6 a 0,9); **2 grupos de pedrinhas**. Borda suave, nada de retângulo de borda dura. **(r2)** Volume pintado só com luz de cima: topo claro (`#C8BEA6` a `#D8CCB0`, ≥ 20% da pedra), sombra de contato quente (`#4A3A28` a `#5C4630`, 0,03 a 0,08) em toda a volta e terra cobrindo parte da pedra |
| `stone/wall_blocks.png` (+`_n`) | 512×128 (8 × 2), seamless 2 eixos | Pedra cortada bege (`#C2B58C`, chanfro `#E0D2A8`, sombra `#8E8466`, juntas `#5C5646`), blocos de tamanhos variados em fiadas irregulares e musgo em algumas juntas. Lê como "muro completo" em qualquer faixa de 0,5 ou 1,0 de altura |
| `stone/wall_blocks_mossy.png` (+`_n`) **(f1)** | 512×128 (8 × 2), seamless 2 eixos | Mesma pedra e mesmas fiadas da `wall_blocks`, para as **faces externas** do muro alto: 35% a 50% coberta de musgo e folhagem escura (`#2C4520` a `#56702A`) escorrendo do topo e saindo das juntas, mais denso em cima. Na referência, a face externa sul lê como verde-escura (média `#2A3C27`, na sombra) |
| `stone/wall_top.png` (+`_n`) **(r1)** | 512×128 (8 × 2), seamless horizontal | Topo de muro e de degrau: lajes de cobertura bege-claras (`#E0D2A8`/`#D2C59C`) aparecendo, com musgo amarelo-esverdeado claro (`#A8B050` a `#C8C470`) **nas bordas e nas juntas, cobrindo de 25% a 40%**. Na referência, a crista lê como uma linha clara amarelada que emoldura a arena (medida `#D2C46D`). A cor média fica a ≤ 12% de `#D2C46D`. (Antes era musgo ≥ 50%, e o resultado lia como faixa verde.) |
| `stone/slabs.png` (+`_n`) | 512×512, seamless 2 eixos | Lajes grandes irregulares (`#BBA366`/`#D6BB8D`), grama e musgo nas juntas. Serve para o patamar sul, a plataforma oeste, o caminho nordeste e o piso das escadas |
| `foliage/leaf_clumps_warm.png`, `_mid.png`, `_cool.png` | 1024×1024 cada, alfa recortado | Atlas 4 × 4 de tufos de folha redondos (16 diferentes por arquivo). Topo do tufo mais claro (`#C8D870` no warm), miolo escuro (`#33522A`), borda feita de folhinhas recortadas e sem contorno. As três famílias: verde-amarelada, verde-média e verde-fria. **(r2)** Cada célula é uma massa de folhas irregular e lobada (não uma bola), preenchendo de 45% a 65% da célula, com folhas em grupos de 6 a 14 px; escuros (L < 0,55 × mediana) em ≤ 8% dos opacos, ≥ 60% deles no terço de baixo; diferença de L médio entre o terço de cima e o de baixo ≤ 25 (a luz da copa vem do shader); sem aro claro contínuo |
| `foliage/conifer_tiers.png` | 1024×512, alfa | Atlas de 6 cartões de andar de conífera (galhos serrilhados para baixo, ponta de cima mais clara `#8EB048`, miolo `#1A3016`). **(r2)** Andar assimétrico (IoU com o espelho horizontal ≤ 0,85), saia de 4 a 8 cachos caídos de tamanhos diferentes (maior ≥ 1,6 × o menor), espaçamento irregular, nenhum trecho reto na saia maior que 12% da largura da célula, faixa de sombra irregular seguindo os cachos, rampa clara ≥ 15%; pontas finas e um pouco tortas |
| `foliage/bark.png` (+`_n`) | 256×512, seamless vertical | Casca marrom (`#4A3426` a `#A88058`), fibras verticais, musgo na base |
| `foliage/grass_tufts.png` | 512×256, alfa | Atlas de 8 tufos (4 baixos para a arena, de ≤ 0,15, e 4 altos para fora) |
| `foliage/flowers.png` | 256×256, alfa | Atlas de 12 grupinhos de flor nas cores da paleta |

## Leva 2: ilha, água, céu, efeitos e props

| Arquivo | Tamanho | Conteúdo |
|---|---|---|
| `island/cliff.png` (+`_n`) | 512×512, seamless 2 eixos | Face do penhasco: blocos grandes de terra e rocha marrom (`#4A3628` a `#9A7656`), fissuras, raízes finas, pouco musgo. Sem luz lateral |
| `island/under.png` (+`_n`) | 512×512, seamless 2 eixos | Fundo: rocha mais escura e fria (`#3E3640` a `#6E5038`), em placas grandes |
| `island/roots_hang.png` | 512×1024, alfa | Atlas de 4 raízes grossas pendentes, que se ramificam e afinam |
| `island/vines_hang.png` | 512×1024, alfa | Atlas de 4 cipós com folhas (para o penhasco, a ilha alta e as rochas grandes) |
| `water/fall_streaks.png` | 256×512, opaco, seamless 2 eixos | Lâmina da cascata: riscos verticais `#7FA2BE` → `#EAF6FC`, mais claros no meio |
| `water/fall_foam.png` | 512×128, alfa suave, seamless horizontal | Espuma da quina e cortinas de gota |
| `fx/mist_puff.png` | 256×256, alfa suave | Puff de névoa branca-lavanda |
| `sky/cloud_puffs.png` | 1024×1024, alfa suave | Atlas 2 × 2 de cúmulos pintados, com o topo claro `#FFF6EC`, a base `#C8C0D4` e as bordas em couve-flor. **(f2)** Branco de verdade no topo (≥ 15% dos opacos com L ≥ 235) e base lavanda escura (`#9C9CB8` a `#8C8498`): a nuvem de baixo à esquerda da referência mede `#938B8C` |
| `sky/cloud_sea.png` | 1024×1024, opaco, seamless 2 eixos | Mar de nuvens visto de cima, para os planos de baixo |
| `fx/fire_flipbook.png` | 512×192, alfa | 4 quadros de 128×192 de chama (`#B8501C` → `#FFF2C0`) |
| `fx/rainbow.png` | 256×32, alfa suave | 6 faixas suaves (vermelho, laranja, amarelo, verde, azul, violeta), dessaturadas, apagando nas bordas |
| `props/wood_planks.png` (+`_n`) | 256×256, seamless vertical | Tábuas (pontes, bancos, caixotes) |
| `props/wood_end.png` (+`_n`) | 256×256 | Anéis de madeira para as pontas de tronco e de toco |
| `props/rope.png` | 64×256, seamless vertical | Corda trançada clara |
| `props/iron.png` (+`_n`) | 128×128, seamless | Ferro escuro da bacia do braseiro |
| `props/ruin_stone.png` (+`_n`) | 512×512, seamless 2 eixos | Pedra clara de ruína (`#8E7660` a `#E0CCAA`) com musgo no topo, para as colunas e o lintel |

## Prévias (`docs/art-preview/`)
- `a08-paleta-medida.png`: as regiões amostradas da referência, marcadas, e a tabela de valores medidos ao lado da paleta-alvo.
- `a08-chao.png`: `grass_a` e `grass_b` misturadas pela máscara em mosaico 3 × 3; maquete de cima da arena (20 × 18) com a terra, o círculo e as lajes; e um recorte da referência (a terra da arena) ao lado, na mesma escala aproximada. **(f1)** Mais uma maquete da terra **vista a 27°** (achatada em Z por sin 27° ≈ 0,45), ao lado do recorte da referência na mesma escala, com a média e o desvio-padrão da luminância das duas escritos na prévia.
- `a08-pedra.png`: elevação de 8 unidades do muro (face de 1,0 com o topo) e da face de 0,5, com `wall_blocks` e com `wall_blocks_mossy`; o mosaico das lajes; um recorte da referência (muro sul) ao lado.
- `a08-folhagem.png`: os três atlas sobre cinza médio e uma **montagem 2D de uma copa** (de 25 a 40 tufos sobrepostos de trás para frente) ao lado de um recorte de copa da referência.
- Leva 2: `a08-ilha-agua.png`, `a08-ceu-fx.png` e `a08-props.png`, cada uma com o recorte equivalente da referência ao lado.

## Fora de escopo
- Malhas, UV, shaders, luz, posições e montagem: são da `012`.
- Personagens (pixel art, spec própria).
- Editar `scripts/`, `scenes/`, `project.godot` ou `docs/specs/`. Apagar os PNG antigos.

## Critérios de aceite

**Automáticos (`tools/art/check_a08.gd` → `A08 CHECK: PASS`)**
- [ ] Todos os PNG da leva existem nas dimensões da tabela. Os opacos têm alfa 255.
- [ ] Seamless nos eixos indicados (albedo e `_n`): a diferença média entre a borda e a borda oposta é ≤ 1,5 × a diferença média entre duas colunas (ou linhas) vizinhas do interior.
- [ ] **Sem ruído por pixel:** a média de |L − média 3×3 de L| na luminância (0 a 255) fica ≤ 5 na grama, ≤ 8 em pedra, lajes e penhasco, e ≤ 10 nos pixels opacos dos cartões de folha.
- [ ] **Com variação grande:** o desvio-padrão da luminância depois de um desfoque de 1/8 da largura é ≥ 4 em grama, terra, pedra e penhasco (não é cor chapada).
- [ ] **Cor:** a cor média de cada textura fica a ≤ 12% (distância RGB normalizada) do tom base do grupo dela na paleta-alvo ou na paleta medida. Nenhum pixel preto puro nem branco puro.
- [ ] Cartões com alfa recortado: o RGB dos pixels transparentes a até 4 px de um opaco fica a ≤ 10% do opaco mais próximo (sem halo).
- [ ] Normal maps em convenção OpenGL, com Z médio ≥ 0,85 (suaves).
- [ ] **(r1)** Grama na escala da câmera: `grass_a` e `grass_b` reduzidas a 1/3 (cerca de 21 px por unidade) têm desvio-padrão da luminância ≥ 22 e média de \|L − desfoque gaussiano σ 4 px\| ≥ 10 (a grama da arena na referência dá 24 e 12). A luminância média fica de 105 a 125.
- [ ] **(r2)** As contas da tabela para `leaf_clumps_*`, `conifer_tiers` e `arena_dirt` (frações de escuro, claro e verde, coroa do anel, preenchimento, IoU do espelho) entram no `check_a08`. Na prévia, uma copa montada com 5 lóbulos de 5 cartões grandes, reduzida para cerca de 20 px por unidade, tem granulação (média \|L − G2\| ÷ média \|G2 − G10\|, σ em px) ≤ 0,95 (a referência dá de 0,74 a 0,84).
- [ ] **(r1)** `wall_top`: musgo de 25% a 40% e cor média a ≤ 12% de `#D2C46D`. `arena_ring`: média do disco a ≤ 10% de `#B27541`.
- [ ] Determinismo: rodar os geradores duas vezes dá md5 iguais. Toda seed é uma constante literal e não há `randomize()`.

**Visuais (Lead Project, pelas prévias, contra os recortes da referência)**
- [ ] A grama lê como a grama viçosa da referência (pinceladas e manchas), não como carpete nem como ruído.
- [ ] **(f1)** A terra é marrom-alaranjada com manchas escuras de terra batida, borda escura avermelhada esfiapada e plantinhas, e na maquete a 27° lê como o recorte da referência. O centro lê como o da imagem: disco escuro com miolo claro, dois crescentes claros e o anel externo quebrado de pedras compridas.
- [ ] O muro lê como blocos bege com chanfro claro e musgo no topo.
- [ ] A montagem da copa lê como uma copa redonda e fofa da referência. As coníferas leem como as do leste da imagem. **(r1)** Na montagem, cada andar de conífera lê como uma prateleira separada: topo claro, saia de cachos arredondados caindo e faixa de sombra embaixo. Agulhas de pincel fino espetadas para fora não servem.
- [ ] (Leva 2) O penhasco lê como blocos de terra e rocha marrom, a cascata como água branca-azulada caindo e as nuvens como cúmulos fofos.

**Processo**
- [ ] Os dois comandos de validação do `CLAUDE.md` sem `ERROR` depois que os PNG existem.
- [ ] Relatório do artist com a lista final, a paleta medida, a autocrítica contra a referência e os avisos ao developer (escala de UV, quais texturas são seamless em quais eixos, atlas e layout).
