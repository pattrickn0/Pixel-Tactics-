# A08 — Arte pintada do cenário (ilha flutuante)

**Usada por:** `012-ilha-flutuante-rio.md` (revisão 1). A leva 1 entra na Fase 2 da 012 e a leva 2 na Fase 3.
**Substitui:** `A07` (pixel art, nunca gerada). As `A03` e `A06` viram histórico.
**Depende de:** `docs/direcao-de-arte.md` (reescrita em 2026-10-08) e da referência principal `docs/reference/ilha-flutuante.webp`.
**Decisões do usuário (2026-10-08):** "Pixel art serão só os personagens"; "esse gráfico exatamente, nessas posições, igual a todo, tudo"; dia claro com toque quente.
**Procedural permitido (decisão do usuário, 2026-10-08):** a arte do cenário pode usar texturas, ruído e gradientes gerados por código com **seed fixa** (mesmo script → mesmo resultado). Isso substitui, só para a arte do cenário, a regra de 2026-10-07 e as regras "sem RNG/sem ruído" da A06/A07. O layout do mapa continua feito à mão.

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
| `decals/arena_dirt.png` | 1024×768 (16 × 12), alfa suave | Mancha de terra alaranjada (`#C89046`, luz `#DDB06A`, borda mais escura `#A26A36`/`#7E5A2C`) com borda irregular e esfiapada na grama, braços como os da referência, ilhas de grama e seixos. O opaco ocupa cerca de 14,5 × 11 |
| `decals/arena_ring.png` | 384×384 (6 × 6), alfa suave | Círculo de pedra quebrado, como na referência: sulco de terra mais escura, de 10 a 14 pedras chatas faceando o chão, com falhas, e disco interno mais claro. Nada emissivo |
| `decals/arena_slabs.png` | 512×512, alfa | Atlas 4 × 2: 6 lajes soltas (de 0,4 a 1,0) e 2 grupos de pedrinhas |
| `stone/wall_blocks.png` (+`_n`) | 512×128 (8 × 2), seamless 2 eixos | Pedra cortada bege (`#C2B58C`, chanfro `#E0D2A8`, sombra `#8E8466`, juntas `#5C5646`), blocos de tamanhos variados em fiadas irregulares e musgo em algumas juntas. Lê como "muro completo" em qualquer faixa de 0,5 ou 1,0 de altura |
| `stone/wall_top.png` (+`_n`) | 512×128 (8 × 2), seamless horizontal | Topo de muro e de degrau: lajes de cobertura cobertas de musgo e grama (musgo ≥ 50%), com pedra aparecendo nas bordas |
| `stone/slabs.png` (+`_n`) | 512×512, seamless 2 eixos | Lajes grandes irregulares (`#BBA366`/`#D6BB8D`), grama e musgo nas juntas. Serve para o patamar sul, a plataforma oeste, o caminho nordeste e o piso das escadas |
| `foliage/leaf_clumps_warm.png`, `_mid.png`, `_cool.png` | 1024×1024 cada, alfa recortado | Atlas 4 × 4 de tufos de folha redondos (16 diferentes por arquivo). Topo do tufo mais claro (`#C8D870` no warm), miolo escuro (`#33522A`), borda feita de folhinhas recortadas e sem contorno. As três famílias: verde-amarelada, verde-média e verde-fria |
| `foliage/conifer_tiers.png` | 1024×512, alfa | Atlas de 6 cartões de andar de conífera (galhos serrilhados para baixo, ponta de cima mais clara `#8EB048`, miolo `#1A3016`) |
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
| `sky/cloud_puffs.png` | 1024×1024, alfa suave | Atlas 2 × 2 de cúmulos pintados, com o topo claro `#FFF6EC`, a base `#C8C0D4` e as bordas em couve-flor |
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
- `a08-chao.png`: `grass_a` e `grass_b` misturadas pela máscara em mosaico 3 × 3; maquete de cima da arena (20 × 18) com a terra, o círculo e as lajes; e um recorte da referência (a terra da arena) ao lado, na mesma escala aproximada.
- `a08-pedra.png`: elevação de 8 unidades do muro (face de 1,0 com o topo) e da face de 0,5; o mosaico das lajes; um recorte da referência (muro sul) ao lado.
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
- [ ] Determinismo: rodar os geradores duas vezes dá md5 iguais. Toda seed é uma constante literal e não há `randomize()`.

**Visuais (Lead Project, pelas prévias, contra os recortes da referência)**
- [ ] A grama lê como a grama viçosa da referência (pinceladas e manchas), não como carpete nem como ruído.
- [ ] A terra é alaranjada, com borda esfiapada e suave, e o círculo de pedra lê como o da imagem.
- [ ] O muro lê como blocos bege com chanfro claro e musgo no topo.
- [ ] A montagem da copa lê como uma copa redonda e fofa da referência. As coníferas leem como as do leste da imagem.
- [ ] (Leva 2) O penhasco lê como blocos de terra e rocha marrom, a cascata como água branca-azulada caindo e as nuvens como cúmulos fofos.

**Processo**
- [ ] Os dois comandos de validação do `CLAUDE.md` sem `ERROR` depois que os PNG existem.
- [ ] Relatório do artist com a lista final, a paleta medida, a autocrítica contra a referência e os avisos ao developer (escala de UV, quais texturas são seamless em quais eixos, atlas e layout).
