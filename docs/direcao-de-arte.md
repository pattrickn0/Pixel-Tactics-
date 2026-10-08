# Direção de Arte: Pixel Chess (cenário 3D pintado, personagens em pixel art)

**Status:** reescrita em 2026-10-08 por decisão do usuário: "Pixel art serão só os personagens" e, sobre a referência nova, "esse gráfico exatamente, nessas posições, igual a tudo", com "dia claro com toque quente". **Substitui** a versão "pixel art minimalista em 2.5D" de 2026-10-06/07 (specs `A03`, `A06` e `A07` viram histórico). Specs vigentes: `012` e `013` (developer), `A08` e `A09` (artist).
**Atualização (2026-10-08, fechamento da `012` e da `A08`):** os valores de luz, pós, folhagem, cascata e nuvens passam a ser os da entrega aprovada (`revisoes/012-f2.md` revisão 2 e `revisoes/012-f3.md`), mais as medidas de controle em "Luz e pós-processamento".
**Atualização (2026-10-08, spec `013`):** as nuvens passam a ser **volumétricas** (raymarch próprio), por decisão do usuário ("vamos de volumétrica"). Os billboards de puff e o plano do mar de nuvens saem. A análise, as cores medidas e os critérios ficam na `013` e na `A09`.

Esta é a fonte única de estilo. Vale para o `artist` (scripts em `tools/art/`), para o código (malhas, materiais, shaders, luz e pós-processamento) e para a revisão. Se algo aqui conflitar com uma spec de arte (`docs/specs/ANN-*.md`), vale a spec mais recente. Se conflitar com `CLAUDE.md`, vale o `CLAUDE.md`.

## Visão geral

Dois estilos com fronteira clara:

| | Cenário (tudo que não é personagem) | Personagens (peças, no futuro) |
|---|---|---|
| Estilo | **3D estilizado com aparência pintada**: formas redondas e volumosas, cores suaves e saturadas, gradientes, textura pintada à mão (pinceladas largas), sem contorno | **Pixel art** |
| Forma | Modelos 3D low/mid-poly do kit (`scenes/kit/`), montados à mão em `scenes/map.tscn` | `Sprite3D` em pé, billboard só no eixo Y |
| Escala da textura | **64 px por unidade** no chão, na pedra e na madeira (ver "Escala e medidas") | **32 px por unidade** (`pixel_size = 1/32`, `WorldScale.PIXEL_SIZE`) |
| Filtro | **Linear com mipmaps e anisotrópico** | **Nearest**, só nos personagens |

O contraste é intencional: o cenário é macio e pintado, e o personagem é nítido em pixel, o que ajuda a lê-lo em cima do cenário.

O mundo é 3D de verdade. A câmera **orbita 360°** em torno do centro da arena, com inclinação fixa e zoom limitado, então todo modelo funciona de qualquer lado e nenhuma textura traz luz lateral pintada. **Na câmera padrão (yaw 0), o quadro reproduz a composição da referência**. As posições estão na spec `012`.

## Referências

Ficam em `docs/reference/`.

| Arquivo | Papel | O que tirar | O que NÃO tirar |
|---|---|---|---|
| `ilha-flutuante.webp` | **Referência principal** (desde 2026-10-08): composição 1:1 na câmera padrão, estilo, paleta, luz e atmosfera | Tudo o que aparece e **na mesma posição**: ilha compacta em volta do anfiteatro, faixa de mata (mista a noroeste, coníferas a leste e folhosas na frente leste), faixa norte aberta com bancos, borda de penhasco em blocos de terra e rocha marrom com raízes e cipós, ilha alta ao fundo com cascata larga e arco-íris, ilhota com ruínas de colunas (fundo à esquerda), ilhota pequena com coluna (fundo à direita), ilhotas laterais ligadas por pontes de corda, rochas flutuantes, mar de nuvens em volta e embaixo, tochas/braseiros, escada no meio do lado sul com patamar de lajes, portões laterais, círculo de pedra na terra da arena, lajes soltas, flores, troncos no terraço, vaga-lumes dourados. A aparência pintada: volumes redondos, gradientes, pinceladas, folhagem em tufos | A **tarde dourada** forte e os feixes de luz fortes (usamos dia claro com toque quente, ver "Luz"). A **moldura de cipós e rochas presa nos cantos da imagem** (é coisa de câmera fixa; vira rochas flutuantes no mundo, ver `012`). Desfoque forte nas bordas. Os erros de render da imagem gerada (muros que não fecham, escalas que mudam). O enquadramento é o da câmera padrão, mas as outras direções da órbita também precisam ser bonitas |
| `Gemini_Generated_Image_6oy5mo6oy5mo6oy5.jpg` | **Histórico.** Valeu de 2026-10-06 a 2026-10-08 para a pixel art | A forma do anfiteatro (degrau baixo, terraço, muro alto com musgo), que já está no mapa | Estilo, paleta e pixel art do cenário |

Na referência nova, o anfiteatro tem as mesmas proporções do nosso (arena 20 × 18, terraço 3 e muro). A spec `012` mediu isso com um ajuste de câmera, que deu erro médio de 6 px em 906. Por isso nada no anel muda de tamanho.

## Como o mundo é montado

**Fronteira de trabalho.** O `artist` faz os **pixels**: texturas pintadas (albedo, normal map suave e, quando a spec pedir, rugosidade), atlas de cartões de folha, ruído 3D e rampa de cor das nuvens (`A09`), decalques com borda suave, flipbook de chama e o gradiente do arco-íris. O `developer` faz a **forma** e a **luz**: malhas do kit (por tabelas explícitas), UV, cor de vértice, materiais e shaders (folhagem, chão, pedra, penhasco, água, céu, nuvens), luz, pós-processamento e a montagem à mão do mapa. O artist nunca desenha a silhueta inteira de uma árvore, e o developer nunca edita PNG.

**De onde vem o "pintado"** (o modo realista de chegar à referência no nosso fluxo):
1. **Forma:** volumes redondos e chanfrados. A copa é um aglomerado de lóbulos com cartões de folha. A pedra é bloco com chanfro. A borda da ilha é um contorno irregular. Nada de cubo seco nem cone liso.
2. **Shader:** gradiente de cor por altura e por exposição ao sol (base mais escura e fria, topo mais claro e quente), luz "embrulhada" (wrap) e normais esféricas na folhagem, luz de borda quente contra o sol, musgo pela normal (topo das pedras) e AO por cor de vértice nos pés de muro e nos troncos.
3. **Textura:** pinceladas largas pintadas por script, com variação de valor em manchas grandes e detalhe só onde importa (juntas da pedra, folhas na borda dos tufos). Ruído fino por pixel não pinta nada.
4. **Atmosfera:** névoa de profundidade lavanda-azulada, névoa de altura embaixo da ilha (o fundo some nas nuvens), bloom leve e desfoque sutil só no fundo distante.

**Procedural na arte (decisão do usuário, 2026-10-08):** a arte do cenário **pode** usar texturas, ruído e gradientes gerados por código **com seed fixa** (mesmo script → mesmo resultado), nos scripts de `tools/art/` e nos shaders. Isso substitui, só para a arte do cenário, a regra "nada procedural na arte" de 2026-10-07. O **layout do mapa continua feito à mão**: posições de peças, decalques e árvores ficam na cena ou em tabelas literais, sem gerador.

| Elemento | Geometria e shader (developer) | Arte (artist) |
|---|---|---|
| Chão de grama (exterior, terraço e arena) | Planos com UV de mundo. Mistura de 2 ou 3 grama pintadas por máscara de baixa frequência em espaço de mundo. AO por cor de vértice perto de muros | `ground_grass_*` 512×512 seamless (8 × 8 unidades) e máscara de mistura |
| Tufos de grama e flores | `MultiMeshInstance3D` de tufos (3 quads cruzados, normal para cima, sem sombra). Na arena, só tufos baixos (≤ 0,15) | Atlas de tufos e de flores com alfa |
| Terra da arena, círculo de pedra e lajes soltas | Decalques planos (`Decal` ou quad com alfa misturado), sem relevo: a arena continua plana | Decalques pintados com borda suave |
| Muro alto, degrau baixo, crista e capeamento | Blocos com chanfro de 0,04 a 0,08. Musgo pela normal no topo. Cipós e tufos pendentes em cartões | Pedra pintada (bege quente) + `_n` suave, musgo e cartões de cipó |
| Escada, patamar e lajes do caminho | Degraus em blocos chanfrados e lajes irregulares | Lajes pintadas + `_n` |
| Folhosa | Tronco em prisma afinando, com raízes. Copa = 6 a 14 lóbulos, cada um com **4 a 6 cartões grandes** sobrepostos (meia largura de 0,9 a 1,2 × o raio do lóbulo), normal do elipsoide da copa inteira, alpha scissor e alpha-to-coverage. O escuro de dentro e de baixo vem do shader (AO por profundidade na copa, base mais fria): uma luz só por copa (revisão 012-f2) | Casca + atlas de tufos de folha (2 ou 3 famílias de verde) |
| Conífera | Tronco + **7 a 9 andares de 7 a 9 cartões**, com raio, ângulo e alcance variados por tabela (raios fora de uma reta), ponta fina, normal suave por vértice (sem faceta), escuro entre os andares pelo shader, gradiente por altura | Casca + atlas de galhos de conífera |
| Arbusto | Lóbulos pequenos de cartões, sem tronco | O mesmo atlas da folhosa |
| Penhasco e fundo da ilha | Face irregular em blocos (malha com degraus e reentrâncias) + fundo cônico. Triplanar, mais escuro e frio para baixo, e somindo na névoa de altura | Terra e rocha marrom pintadas + `_n` suave; cartões de raiz e de cipó |
| Cascata e névoa | Lâminas em 2 camadas com shader de rolagem (riscos), faixa de espuma no lábio, puffs de névoa na base | Riscos de água, espuma e puff de névoa |
| Arco-íris | Fita em arco com shader aditivo fraco, apagando nas pontas | Gradiente de 6 faixas |
| Nuvens (spec `013`) | **Volumes com raymarch próprio** (`cloud_volume.gdshader`): lóbulos em tabela literal por massa, um nó por massa em `Sky/Clouds`, sombra própria por marcha até o sol, fase HG dupla, ambiente por altura, luz → rampa medida, sombra da ilha por máscara de pegada, perspectiva aérea própria (sem a névoa da cena) e mar de nuvens volumétrico embaixo. **Sem billboard** | Ruído 3D (forma e detalhe) e rampa de cor de tela medida na referência (`A09`) |
| Céu | Shader de céu próprio, **inclusive abaixo do horizonte** (a câmera olha para baixo e o "céu" de baixo aparece entre as nuvens) | — |
| Braseiro | Pedestal de pedra + bacia de ferro + chama em cartões cruzados com flipbook, `OmniLight3D` sem sombra | Pedra e ferro pintados, flipbook de chama |
| Ponte de corda | Tábuas, postes e cordas pendentes (catenária em tabela) | Tábuas e corda pintadas |
| Ruínas | Colunas com tambores e lintel, algumas quebradas | Pedra clara de ruína + `_n` |
| Vaga-lumes | `MultiMesh` de pontos emissivos com posições em tabela (38, em volta das matas e da cascata) | — |
| **Personagens** (futuro) | `Sprite3D` billboard Y, `pixel_size = 1/32`, Nearest | Pixel art (regras na spec dos personagens) |

## Escala e medidas

- **Mundo:** 1 tile = 1 unidade 3D. 1 nível de degrau = 0,5 unidade (`WorldScale.LEVEL_HEIGHT`). As medidas do anel, da arena e das reservas são as do `CLAUDE.md` e da `011`/`012`.
- **Densidade de textura do cenário:** **64 px por unidade** no chão, na pedra, na madeira e no penhasco, com UV em unidades do mundo (sem esticar). Cartões de folha e puffs têm resolução própria, definida na `A08`. Texturas seamless de 512×512 (8 × 8 unidades), com quebra de repetição no shader (mistura por máscara de baixa frequência e rotação ou deslocamento por região).
- **Personagens:** 32 px por unidade, `pixel_size = 1/32`. `TEXELS_PER_UNIT = 32` continua sendo a constante dos personagens. A densidade do cenário vira uma constante própria (por exemplo, `SCENERY_TEXELS_PER_UNIT = 64`), definida num lugar só.

| Item | Medida |
|---|---|
| Muro alto | crista em 1,0; face interna 0,5, externa 1,0; espessura 1 |
| Degrau baixo | face de 0,5, capeamento de 0,5 |
| Degrau de escada | espelho de 0,25, piso de 0,5 |
| Conífera | altura de 6 a 9; base (com o alcance dos galhos) de 2,0 a 3,2; altura ≥ 2,4 × base (revisão 012-f2) |
| Folhosa grande | altura de 4,5 a 7; copa de 3,5 a 5,5 de largura (copas redondas e cheias, como na referência) |
| Folhosa pequena | altura de 2,5 a 4; copa de 2 a 3 |
| Arbusto | altura de 0,6 a 1,4; largura de 1 a 2 |
| Tufo de grama | 0,2 a 0,5 de altura fora da arena; ≤ 0,15 na arena |
| Tronco caído | comprimento de 2 a 3,5; diâmetro de 0,5 a 0,8 |
| Braseiro | pedestal de 0,4 × 0,4 × 0,7 + bacia de 0,5 de diâmetro; chama de 0,4 × 0,6 |
| Personagem (futuro) | cerca de 1 de largura × 1 a 1,5 de altura (32 × 32 a 48 px) |

## Regras das texturas pintadas

- **Pinceladas, não ruído.** Valor e cor variam em **manchas grandes** (de 1/8 a 1/2 da textura) com pinceladas visíveis e direcionais (grama: traços curtos e curvos; pedra: planos chapados com borda de luz; terra: manchas e seixos). Proibido: ruído por pixel tipo foto, "grão" uniforme e padrão de repetição evidente.
- **Gradientes suaves.** Topo de pedra e de tufo mais claro, base e juntas mais escuras. A luz vem só de cima: nada de lado iluminado pintado, porque a câmera gira.
- **Saturação controlada.** Verdes vivos ao sol, mais frios e escuros na sombra. Terra quente e alaranjada. Pedra bege quente. Nenhum tom fora da paleta-alvo por mais de 12% (distância RGB normalizada) na cor média de cada textura.
- **Seamless** nos eixos indicados pela spec, no albedo e no `_n`.
- **Normal maps suaves:** calculados de um mapa de altura **desfocado** (relevo de bloco a bloco e de tufo a tufo, sem micro-relevo). Convenção OpenGL. O código usa `normal_scale` entre 0,3 e 0,8. Grama e terra não têm normal map. Pedra, madeira e penhasco têm.
- **Alfa:** cartões de folha, tufo e cipó usam alfa recortado (o motor usa alpha scissor + alpha-to-coverage com MSAA). Decalques de chão, puffs de nuvem e névoa usam alfa suave.
- **Sem contorno** no cenário, nem preto nem colorido.
- **Proibido nas texturas:** sombra projetada pintada, luz lateral, vinheta, glow pintado, texto e marcas d'água.

## Folhagem (o que mais pesa na semelhança)

- Copas **redondas, cheias e com tufos** visíveis na silhueta (a borda é feita de tufos, não lisa). Topo ao sol verde-amarelado claro e base verde-escura fria. Entre os tufos há fresta e sombra própria. A copa inteira tem **uma luz só** (topo claro, miolo e base escuros): os tufos não são bolas separadas, cada uma com luz própria, o que lê como couve-flor (revisão 012-f2).
- Coníferas altas, estreitas e escuras, com camadas marcadas e as pontas de cima mais claras. A silhueta é irregular (andares de tamanhos e ângulos variados, cachos caídos), nunca um pagode de andares iguais. Na referência, elas formam a massa do leste e o fundo do noroeste.
- Três famílias de folhosa (verde-amarelada, verde-média e verde-fria) e nenhuma árvore igual a outra (peça única por instância, ou variação por escala e giro em até 15%).
- Sem vento forte. É permitido um balanço lento (amplitude ≤ 0,03, período de 3 a 6 s, determinístico por `TIME`).

## Pedra, terra e chão

- **Muros:** pedra cortada bege quente, blocos de tamanhos variados, chanfro claro, juntas escuras e quentes, **musgo e grama no topo** e cipós escorrendo em alguns trechos (como na referência).
- **Lajes** (patamar sul, caminho leste, plataforma oeste e cabeceiras): lajes grandes e irregulares, bege-claras, com grama nas juntas.
- **Arena:** grama viva com tufos baixos e florzinhas espalhadas. Uma **mancha de terra marrom-alaranjada** grande no centro, com manchas escuras de terra batida, borda escura avermelhada irregular e suave, e plantinhas dentro. No meio, o **círculo** da referência: disco de terra escura com miolo claro, dois crescentes claros e um anel externo quebrado de pedras compridas e chatas. Pedrinhas soltas. Tudo plano, sem obstáculo.
- **Penhasco:** blocos grandes de terra e rocha marrom (mais quente em cima e mais fria e escura embaixo), raízes grossas saindo da face e cipós pendurados. O fundo afunila e some nas nuvens.

## Água, nuvens e céu

- **Cascata:** larga, branco-azulada, com riscos verticais rolando, espuma na quina e névoa branca na base que se funde ao mar de nuvens. Há um **arco-íris** fraco na frente da névoa, visto da metade sul da órbita.
- **Nuvens (spec `013`):** cúmulos volumétricos em **fileiras** nos lados da ilha e **torres e bancos** ao fundo, sem céu limpo entre eles. É contraluz lateral: só a crista acende em creme quente (`#FDEED6`), a face fica malva (`#D6C4C5`) e o vale e a base, azul-lavanda (`#959FB5`). A borda é macia, de bolotas redondas, sem contorno, sem branco puro e sem cinza neutro. As nuvens distantes quase não perdem contraste. O mar embaixo da ilha fica azul-acinzentado (`#8C96AD`) na sombra da ilha (leste-sudeste) e claro fora dela.
- **Céu:** claro, azul-lavanda no alto, rosado-claro perto do horizonte e mais quente do lado do sol. **Abaixo do horizonte** continua claro (lavanda-azulado), sem "chão" escuro.

## Luz e pós-processamento (motor)

Momento do dia: **dia claro com toque quente** (decisão do usuário, 2026-10-08). Não é tarde dourada.

- **Sol:** `DirectionalLight3D` `#FFE9C8`, energia 1,65, elevação de **34°** (`rotation_degrees = (-34, -112.5, 0)`; a faixa aceita é de 32° a 36°, revisão 012-f2, para as faixas de sombra da referência), **vindo do oeste-noroeste** (na câmera padrão, de trás e da esquerda, como na referência). A direção do sol fica só no nó `Sun`: nenhum shader copia o vetor. Sombras reais em tudo. Tufos, flores, nuvens e vaga-lumes não projetam sombra.
- **Ambiente:** cor lavanda-azulada clara (`#B8C4DC`, energia 0,2), forte o bastante para a sombra ficar verde-escura e nunca preta. SSAO leve (raio 1, intensidade 1).
- **Pontos de luz quente:** braseiros com `OmniLight3D` `#FFB066`, alcance ≤ 4, **sem sombra**, energia baixa (de dia, eles só aquecem o entorno).
- **Bloom:** leve (glow nos níveis 2 e 3, intensidade 0,3, limiar HDR 1,0), só em chama, vaga-lume, espuma da cascata e brilho do sol nas nuvens. A grama ao sol não brilha.
- **Feixes de luz:** fora (revisão 012-f2: leram como faixas cinza sobre o céu; a 012 fechou sem eles). Só voltam com uma spec nova.
- **Sem véu:** nada de emissão ou névoa clareando a ilha. A sombra fica verde-escura e o branco das nuvens e da espuma chega a branco quente. O ar só aparece além da borda (névoa de profundidade e de altura).
- **Névoa:** de profundidade lavanda (`#DCD6E6`), de 70 a 100 unidades da câmera (depois da borda da ilha), e de altura abaixo do nível −3, densidade 0,03 (o fundo da ilha e as ilhotas "afundam" nas nuvens).
- **Desfoque:** só no fundo distante (a partir de 90, transição de 60, quantidade 0,02). O anfiteatro e a mata ficam nítidos, e a ilha alta e as ilhotas também devem ler nítidas, suavizadas só pela névoa.
- **Tonemap:** Filmic, exposição 1,25, **branco 3** (com branco 6, nuvem, céu e espuma ficavam cinza ~210; revisão 012-f2). Ajuste de cor com saturação 1,05 (faixa de 1,05 a 1,12) e contraste 1,0 (faixa de 1,0 a 1,05). **Sem vinheta.**
- **Antisserrilhado:** MSAA 4× (com alpha-to-coverage na folhagem). Sem TAA nem FXAA, porque borram o pixel dos personagens.
- **Emissão:** chamas, vaga-lumes e (no futuro) efeitos das peças.

### Medidas de controle (captura padrão 1280×720 sem HUD, `tools/dev/compare_images.gd --boxes`)

Valem para qualquer mudança de luz, pós ou material que mexa no quadro inteiro (spec 012, critérios **(f2)**). Entre parênteses, a referência e o valor da 012 entregue.

- Quadro: saturação média ≥ 0,36 (0,397; 0,408), P95 de L ≥ 226 (232; 229), pixels com L < 50 ≥ 13% (17,2%; 13,3%) e leitosos (S < 0,18 e L > 150) ≤ 30% (24,9%; 27,6%).
- Ilha (170, 180, 1110, 700): L médio ≤ 110 (102; 110) e pixels com L < 50 ≥ 16% (19,4%; 17,6%).
- Granulação da folhagem ≤ 0,95 nas caixas de mata (de 0,74 a 0,84 na referência).
- Caixas de cor da 012 a ≤ 8% (cascata ≤ 8% e faixa sul ≤ 12%).

## Paleta-alvo (medida na `ilha-flutuante.webp`)

Valores de referência para as texturas e os materiais, da sombra para a luz. O `artist` confirma por medição na imagem (script em `tools/art/`) e registra os valores medidos na prévia da `A08`. Diferenças de até 12% são aceitas, e diferenças maiores vão por escrito no relatório.

| Grupo | Sombra → Luz |
|---|---|
| Grama | `#2C4520` `#3F5F22` `#5E8424` `#7FA22C` `#A8C447` |
| Terra da arena | `#6E4228` (borda) `#74502C` `#8A5E34` `#AE813F` (média medida) `#C89A55` `#D6AA66` (revisão 012-f1: a anterior, centrada em `#C89046`, saía laranja e clara demais) |
| Pedra do muro | `#5C5646` `#8E8466` `#C2B58C` `#E0D2A8` |
| Lajes | `#8E7C56` `#BBA366` `#D6BB8D` |
| Musgo | `#56702A` `#87A23A` `#B8C85A` |
| Folhosa | `#33522A` `#5E8A30` `#8DB040` `#C8D870` |
| Conífera | `#1A3016` `#2C4A1E` `#4E7A2E` `#8EB048` |
| Tronco e madeira | `#4A3426` `#7A5638` `#A88058` |
| Penhasco | `#3E3640` (fundo frio) `#4A3628` `#6E5038` `#9A7656` |
| Ruínas | `#8E7660` `#BDA083` `#E0CCAA` |
| Água | `#5A7E9C` `#7FA2BE` `#B6D0E3` `#EAF6FC` |
| Nuvem (medida na `013`, P5 → P95) | `#959FB5` `#B4AFBF` `#D6C4C5` `#EDD9CF` `#FDEED6`; na sombra da ilha: `#818597` `#8D97AD` `#9FA3B6` |
| Céu | zênite `#8FB0D8`, meio `#C9D3EA`, horizonte e abaixo `#EAD9DC`, perto do sol `#FFF0D8` |
| Névoa | `#DCD6E6` |
| Fogo | `#B8501C` `#E39041` `#FFDA81` `#FFF2C0` |
| Flores | rosa `#F08CA8`, branca `#F6F2E8`, amarela `#F4D04A`, azul `#7FA8F0`, lilás `#B898E0` |

## Personagens (pixel art)

- `Sprite3D` em pé, billboard só no eixo Y, `pixel_size = 1/32`, filtro **Nearest**, alfa binário e sem ruído por pixel.
- A paleta e as regras de desenho vêm na spec dos personagens. O que já vale: a leitura contra o cenário pintado (silhueta clara e valor contrastante) e nada de luz lateral pintada.

## O que NÃO fazer

- Pixel art, Nearest ou dithering no cenário (só nos personagens). O pontilhado de oclusão (árvore entre a câmera e a arena) continua permitido, porque é efeito de shader e não de arte.
- Realismo fotográfico, texturas escaneadas e ruído por pixel.
- Contorno preto, vinheta, tarde dourada forte, desfoque perto da câmera.
- Mudar a composição da câmera padrão sem atualizar a `012` (ela é 1:1 com a referência).
- Assets ou addons de terceiros sem aprovação do usuário.

## Terreno e mapa

O layout é feito à mão (`011`) e a composição exterior é a da `012` (croqui e coordenadas tiradas da referência). Resumo:

- **Arena 20 × 18 plana** no nível 0: grama, terra alaranjada com círculo de pedra e lajes soltas.
- **Anel:** degrau baixo (0,5), terraço de 3 (reservas nos lados compridos), muro alto com crista em 1,0, e exterior no nível 0.
- **Passagens:** escada no **meio do lado sul e do lado norte**, da crista para fora, com patamar de lajes (decisão do usuário, 2026-10-08), e os **portões oeste e leste** (lances da `011`), que atravessam o anel. O oeste leva à plataforma e à ponte de corda. O leste leva ao caminho de lajes que sobe para o nordeste.
- **Exterior:** ilha compacta (de 3,5 a 6 unidades além do muro no sul, de 5 a 10 no oeste e de 8 a 17 no leste), mata como na referência, faixa norte aberta com bancos, borda de penhasco, ilha alta com cascata ao norte, ilhotas, rochas e nuvens.
- **Legibilidade com câmera 360°:** a arena e as reservas sempre visíveis. Árvores, rochas e braseiros entre a câmera e a arena (ou as reservas) ficam pontilhados.
