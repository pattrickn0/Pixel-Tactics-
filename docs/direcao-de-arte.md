# Direção de Arte — Pixel Chess (HD-2D híbrido, pixel art cartoon)

Fonte única de estilo. Vale para o `artist` (scripts em `tools/art/`), para o código (placeholders) e para a revisão. O Antigravity está pausado; se for reativado, também segue este arquivo.
Se algo aqui conflitar com uma spec de arte (`docs/specs/ANN-*.md`), vale a spec mais recente. Se conflitar com `CLAUDE.md`, vale o `CLAUDE.md`.

## Visão geral

Estilo **HD-2D**: mundo 3D de verdade, com texturas em pixel art, mais vegetação e (no futuro) peças como **sprites 2D em pé**, câmera fixa inclinada em perspectiva, luz com sombras reais e pós-processamento leve (glow, desfoque de profundidade, névoa).

O desenho é **pixel art cartoon**: contorno escuro colorido, cores saturadas, poucos tons por material, formas arredondadas e simples, clusters grandes de pixel. A imagem da clareira (`Screenshot 2026-10-04 160858.png`) é o alvo de estilo.

### O que nos diferencia (identidade própria)

- **Cartoon, não pintura.** O Octopath é a referência de *técnica* (como o 3D e os sprites se combinam), não de traço: nada do realismo dessaturado, texturas ruidosas e pós-processamento pesado dele. Nosso pós-processamento é mais leve.
- **Contraste clareira × mata.** Arena de grama clara e ensolarada, cercada por mata **escura e azulada**, como na imagem da clareira. A luz "mora" na arena, que é onde o jogador olha.
- **Arena = clareira enorme com ruína baixa.** Muro baixo de **pedra terrosa avermelhada**, às vezes um **terraço com escada**, **monólitos rúnicos** com brilho **ciano** na borda. Não é coliseu nem arquitetura monumental.
- **Copas arredondadas em "bolhas"**, não pinheiros.
- **Não trocar paleta nem estilo por conta própria.** Propostas de mudança vão por escrito no relatório de entrega (seção de autocrítica/limitações), nunca direto na arte.

## Referências

Em `docs/reference/`. Cada imagem tem um papel; não misture os papéis.

| Arquivo | Papel | O que tirar | O que NÃO tirar |
|---|---|---|---|
| `Screenshot 2026-10-04 160858.png` (clareira) | **Estilo artístico** (alvo principal) | Traço cartoon: contorno escuro colorido, 3 tons por material, formas arredondadas, clusters grandes. **Paleta**: grama clara, mata escura azulada ao fundo, pedra terrosa avermelhada do terraço, lajotas e monólitos em pedra fria, runas ciano. **Terraço com escada** e laterais de pedra com grama caindo na quina. **Monólitos rúnicos** como marco. | Personagens e criaturas. Troncos gigantes em primeiro plano e o enquadramento de cena fechada (nossa câmera vê o mapa inteiro, de mais longe). Qualquer outro elemento brilhante além das runas. |
| `ref-floresta-vila.png` | **Composição do mapa** | Floresta **densa** de copas em bolhas sobrepostas, **trilha de terra** atravessando a mata, contraste entre área aberta e mata fechada. As casas mostram o ponto de vista dos sprites em pé: frente + um pouco do topo (leve 3/4 de cima). | Casas e telhados (não há construções nesta fase). A vista de cima das copas (nossas árvores são vistas de frente). A paleta verde-clara das copas (nossa mata é azulada). |
| `ref-ruinas-planicie.png` | **Composição do mapa** | **Muros baixos de ruína** em ângulo reto delimitando áreas, **lajotas** soltas no chão aberto, terraço elevado com escada, pedras grandes soltas, árvores na borda. | Estátuas, lanternas, vasos, o tom cinza-claro neutro das pedras (nossas pedras são terrosas ou frias, ver Paleta). |
| `Screenshot 2026-10-04 153426.png` (Octopath) | **Técnica HD-2D** | Como o HD-2D é montado: chão 3D texturizado, sprites em pé sobre ele, desfoque de profundidade nas bordas da tela, brilho quente. | Paleta escura, coliseu, estandartes, estátuas, pinheiros, personagens, a intensidade dos efeitos. |
| `Screenshot 2026-10-04 153547.png` (Octopath) | **Técnica HD-2D: relevo** | **Relevo em degraus**: terraços com topo de grama, laterais de rocha, franja de grama caindo sobre a quina, névoa leve ao fundo. | Paleta escura/fria, água, pântano, textura realista ruidosa. |

## Como o mundo é montado

| Elemento | Como é feito | Arte necessária | Ponto de vista da arte |
|---|---|---|---|
| Chão (topo dos blocos) | 3D | Textura 32×32, seamless nos 4 lados, opaca | **De cima**, ortogonal, sem perspectiva |
| Lateral de degrau / terraço | 3D | Textura 32×32, seamless na horizontal e na vertical (empilha níveis) + variante com franja de grama no topo | **De frente**, ortogonal |
| Escada do terraço | 3D (degraus em código) | Reaproveita texturas (piso de terra, espelho de muro) | — |
| Borda da arena (muro baixo de ruína) | 3D (caixa baixa) | Textura de face (de frente) + textura de topo (de cima), 32×32 | Face de frente; topo de cima |
| Lajotas de ruína | 3D (tipo de chão) | Textura 32×32 de topo, seamless | De cima |
| Pedra grande | 3D (forma simples, low poly) | Textura de superfície de pedra 32×32 seamless | Superfície sem direção (sem luz pintada forte) |
| Árvores, arbustos, capim, flores | `Sprite3D` em pé (billboard só no eixo Y) | PNG com fundo transparente | **De frente, com leve 3/4 de cima** |
| Monólito rúnico | `Sprite3D` em pé | PNG transparente + máscara da runa (para o brilho do motor) | De frente, leve 3/4 de cima |
| Peças (futuro) | `Sprite3D` em pé | PNG com fundo transparente | De frente, leve 3/4 de cima |

- A câmera **nunca gira**. Sprites só precisam de **uma** vista (a frontal). Não desenhar lados, costas nem rotações.
- Câmera sugerida (referência para mockup e código): inclinação de **35° a 45°** para baixo, campo de visão baixo (**~30° a 40°**) para a perspectiva ficar suave. A borda de baixo da tela é o lado mais perto da câmera (sul).

### Ponto de vista em detalhe

- **Textura de topo:** vista exatamente de cima. Nada "em pé" desenhado nela (sem lâminas altas de capim vistas de lado, sem troncos, sem sombra projetada). O que tem altura vira sprite.
- **Textura lateral:** vista de frente. Pedra terrosa em blocos arredondados, com fendas escuras entre eles. Variante com **franja de grama** na parte de cima (a grama do topo "caindo" sobre a quina, em gotas arredondadas, como no terraço da clareira).
- **Sprite em pé:** vista frontal com leve 3/4 de cima. Vê-se a frente do objeto e um pouco do seu topo. A base é reta e é o ponto que toca o chão.

## Escala e medidas

**1 tile = 1 unidade 3D = 32 texels.** Sprites usam `pixel_size = 1/32`, então **32 px de sprite = 1 unidade**, a mesma densidade de pixel do chão.

| Item | Tamanho |
|---|---|
| Textura de terreno (topo, lateral, muro, lajota, pedra) | **32×32 px** exato |
| Altura de 1 nível de degrau | **1 unidade = 32 texels** (a lateral de um nível é exatamente uma textura 32×32) |
| Muro baixo da arena (sugestão) | altura **0,5 unidade** (16 texels), espessura 0,5. Por isso as texturas de muro são seamless nos dois eixos: o código recorta a altura que quiser |
| Escada (sugestão) | vence 1 nível em 4 degraus de 0,25 unidade |
| Árvore grande (sprite) | desenho de **64–96 de largura × 96–128 de altura** |
| Árvore pequena (sprite) | desenho de **48–64 × 64–96** |
| Monólito rúnico (sprite) | desenho de **~24–32 de largura × 64–96 de altura** |
| Arbusto (sprite) | **32×32** |
| Capim / flor (sprite) | **16×16** |
| Peça, futuro (sprite) | ~**32 de largura × 32–48 de altura** |

Por que 1 nível = 32 texels: a lateral usa a mesma textura 32×32 do resto, sem textura "meia altura", e um degrau fica da altura de uma peça (32–48 px), o que deixa o relevo legível sem esconder as peças.

### Regras dos sprites em pé

- **Fundo transparente**, alfa **binário** (cada pixel é 0% ou 100% opaco). Nada de semitransparência.
- O canvas (tamanho do PNG) é múltiplo de 16 px. A **base do objeto toca a última linha de pixels** do canvas e fica **centralizada na horizontal**. O código usa o centro da borda de baixo como ponto de apoio no chão.
- A silhueta não encosta na primeira linha nem nas colunas laterais do canvas (1 px de folga), para o contorno não ser cortado.
- **Sem sombra desenhada no chão.** O motor projeta a sombra do sprite. Sombra **própria** (o lado escuro do próprio objeto) é desenhada normalmente.
- **Contorno cartoon** de 1 px em toda a silhueta (ver Forma).
- Não escalar sprites no código para variar o tamanho (muda a densidade de pixel). Variação vem de **variantes desenhadas**.

### Regras das texturas

- Exatamente 32×32, **opacas** (sem alfa), **seamless** (repetidas 4×4 não mostram emenda nem padrão gritante).
- **Sem contorno nas bordas do tile** (senão aparece uma grade no chão). Contorno interno de blocos (pedras, lajotas) é permitido e desejado.
- **Sem iluminação global pintada:** nada de gradiente de um lado ao outro, vinheta ou canto escurecido. O motor ilumina os blocos. A luz cima-esquerda aparece só **no nível do detalhe** (cada pedra, tufo ou bloco tem seu highlight em cima-esquerda e sombra embaixo-direita).
- Grama do topo: tufos e manchas arredondadas em clusters (como a grama da clareira), poucos tons, pouco "chiado". A grama da arena é a mais limpa e legível de todas.

## Iluminação

- **Luz direcional** (`DirectionalLight3D`) vinda de **cima-esquerda em relação à câmera**, com **sombras reais**. Sprites também projetam sombra.
- Os sprites em pé estão virados para a câmera, então **nunca podem ficar "de costas" para a luz** (escuros, só com luz ambiente). Eles devem parecer tão iluminados quanto o chão em volta. O jeito de garantir isso é decisão do código (direção do sol, normal do sprite), não da arte.
- **Sol levemente quente** na luz direcional; **luz ambiente fria/azulada e fraca**, para as sombras puxarem para o azul da mata (como na clareira).
- **Na arte:** highlight em cima-esquerda, sombra própria embaixo-direita, com **3 tons por material** (ver Forma).
- **Efeitos aplicados pelo motor** (não pintar na arte), todos leves: glow/bloom (quase só nas runas), desfoque de profundidade estilo tilt-shift (perto e longe desfocados, **arena sempre nítida**), névoa leve e fria na distância. Mais suave que no Octopath: o cartoon precisa continuar nítido.
- **Runas:** são o único elemento "brilhante" do mapa. A arte só pinta a runa em ciano (grupo Runa); o brilho em volta vem do glow do motor, a partir de uma máscara da runa entregue junto com o sprite.
- **Proibido na arte de jogo (texturas e sprites):** sombra no chão, blur, glow ou halo pintado, névoa, desfoque, vinheta, gradiente suave, anti-aliasing.

## Pixel e filtro

- Filtro **Nearest** em tudo. Sem anti-aliasing, sem gradiente suave. Cada pixel da arte é exatamente 1 texel.
- Em perspectiva, o **tamanho do pixel na tela varia** com a distância (perto = pixel maior, longe = menor). Isso é próprio do estilo HD-2D e não é defeito. A regra antiga de "zoom inteiro (×1/×2/×3)" **não se aplica**.
- O que precisa ser igual é a **densidade**: 32 texels por unidade em texturas e sprites.
- (Para o developer) Se houver cintilação nas texturas distantes, use Nearest com mipmaps.

## Forma (regras cartoon)

- **Contorno:** 1 px, escuro e **colorido**, em toda a silhueta dos sprites. Nunca preto `#000000`. Use o tom de Contorno do material (tabela abaixo) ou o tom mais escuro do próprio grupo (contorno seletivo).
- **3 tons por material:** sombra, base e luz. Um 4º tom de brilho é permitido em pontos pequenos (topo das bolhas da copa, quina de pedra). Mais que isso vira pintura, não cartoon.
- **Clusters grandes:** pinte em manchas de 2×2 px ou mais. Pixel isolado só como brilho intencional. Nada de ruído pixel a pixel.
- **Formas arredondadas e simples**, curvas sem "jaggies" (degraus irregulares no contorno).
- **Copas de árvore:** "bolhas" arredondadas sobrepostas, silhueta irregular, tronco visível embaixo. Leve 3/4: as bolhas de cima mostram mais luz (topo da copa), com toques do verde de luz da mata.
- **Pedra terrosa (muro, laterais):** blocos arredondados e gordos, fendas escuras entre eles, topo de cada bloco mais claro e avermelhado, grama caindo por cima.
- **Pedra fria (monólitos, lajotas, pedras grandes):** formas simples com quinas gastas e rachaduras em linha fina escura; monólito alto com topo arredondado ou quebrado.

## Paleta (hex)

Use somente estas cores. Pequenas variações de tom são aceitas (ajuste fino de até ~8 por canal), mas **não** crie famílias de cor novas nem troque a paleta. Grama e Terra são os grupos originais; Mata, Pedra terrosa, Pedra fria, Runa e a flor lilás foram tiradas da imagem da clareira.

| Grupo | Sombra → Luz |
|---|---|
| Grama (planície/arena) | `#4E7A2A` `#6B9B37` `#8DB846` `#B3CF5E` |
| Grama da mata (chão fora da arena) | `#315740` `#4E7A2A` `#6B9B37` (+ `#236460` em sombras pontuais) |
| Mata / copas (escura azulada) | `#111A33` `#192649` `#224956` `#236460` `#458946` |
| Terra / trilha | `#6E5538` `#8A6E4B` `#C2A57A` `#E0CDA0` |
| Pedra terrosa (muro, laterais de degrau) | `#47443B` `#634E45` `#976759` `#B47262` `#D68775` |
| Pedra fria (monólito, lajota, pedra grande) | `#232B2B` `#374845` `#4D6862` `#6C948B` `#A9C3B8` |
| Runa (brilho pontual) | `#67A7A5` `#3AD1CC` `#48FDFD` `#A3F9F7` |
| Madeira / tronco | `#3B2A1E` `#5C3F2A` `#7E5A3A` |
| Água (uso futuro) | `#2B4F6E` `#3E7499` `#6FA8C9` |
| Flores | amarela `#F2E27A`, branca `#ECEBDF`, rosa `#E39BB0`, lilás `#8B5396` `#B76CC5` |
| Contorno | `#0B1228` (mata, monólito) · `#1A2420` `#24302A` (vegetação clara, grama) · `#2B3A2A` (pedra terrosa, madeira) |

Uso por material:
- **Grama da arena:** grupo Grama inteiro; base `#8DB846`, manchas `#6B9B37`, tufos de luz `#B3CF5E`, sombra pontual `#4E7A2A`.
- **Grama da mata:** mais escura e mais fria que a da arena, para a arena se destacar.
- **Copas e arbustos:** árvores pequenas e arbustos com sombra `#192649`, base `#224956`, luz `#236460`, brilho `#458946` só no topo das bolhas de cima. Árvores grandes (fundo da mata) um tom mais escuras: sombra `#111A33`, base `#192649`, luz `#224956`, brilho `#236460` e toques de `#458946`. Contorno `#0B1228`.
- **Capim:** tons de Grama com contorno `#24302A` (fica junto da grama clara) ou tons da Mata com contorno `#0B1228` (na mata).
- **Lateral de degrau:** grupo Pedra terrosa, com fendas em `#47443B`/`#2B3A2A`. Topo dos blocos `#B47262`/`#D68775`.
- **Franja de grama da lateral:** `#4E7A2A` `#6B9B37` `#8DB846` (combina com o topo da arena).
- **Muro da arena:** grupo Pedra terrosa, com blocos mais regulares (cantaria) e tons um pouco mais claros que a lateral (`#976759` `#B47262` `#D68775` nas faces), para a borda se destacar; musgo `#6B9B37`.
- **Lajota e pedra grande:** grupo Pedra fria; juntas entre lajotas com grama `#4E7A2A`/`#6B9B37`.
- **Monólito:** grupo Pedra fria, contorno `#0B1228`, runas no grupo Runa (aro `#67A7A5`, base `#3AD1CC`, núcleo `#48FDFD`, brilho `#A3F9F7`).
- **Trilha:** grupo Terra, pedrinhas de Pedra fria (`#4D6862` `#6C948B`).
- **Tronco:** grupo Madeira, contorno `#2B3A2A`.

## Terreno e mapa

- **Um mapa por partida**, compartilhado por todos os jogadores.
- **Arena (área de luta):** clareira de grama clara (paleta Grama) **muito grande**, no centro, ocupando **~60–70% da largura e da altura do mapa**. A floresta é **moldura**. Formato orgânico, não um retângulo perfeito. Pouco poluída e legível, porque as peças ficam sobre ela: dentro dela só capim e flores baixos e manchas de lajota.
- **Borda da arena:** sempre visível em todo o contorno: **muro baixo de ruína de pedra terrosa 3D** (baixo o bastante para não esconder as peças), com **trechos quebrados** (mais baixos ou com falhas) e musgo. As trilhas entram na arena pelas falhas do muro.
- **Terraço com escada:** a arena pode ter um ou dois **terraços elevados 1 nível**, largos, com lateral de pedra terrosa, franja de grama na quina e uma **escada** voltada para a câmera (como na clareira).
- **Monólitos rúnicos:** decoração **na borda** da arena (junto ao muro, do lado de fora), **nunca dentro da área de luta**, e nunca na borda sul (entre a câmera e a arena), para não tampar peças.
- **Relevo em degraus:** níveis de altura inteiros, degraus de 1 nível. Dentro da arena, poucos e largos. Fora dela, mais alto e recortado, com laterais de pedra terrosa e franja de grama no topo.
- **Fora da arena:** mata **densa** e escura azulada de sprites sobrepostos: árvores, arbustos, capim, flores, pedras grandes 3D. **Trilhas de terra** cortam a mata e chegam à arena (composição de `ref-floresta-vila.png`).
- **Legibilidade:** entre a câmera e a arena (parte de baixo da tela) só vegetação baixa (capim, flor, arbusto, árvore pequena) e relevo não mais alto que a arena. Árvores grandes e monólitos ficam nas laterais e no fundo.
- **Transições** (grama clara ↔ grama da mata, grama ↔ terra) com bordas irregulares, nunca em linha reta. São feitas no código a partir das texturas base.
- Grama da arena com **4 variantes de textura** e detalhes (capim, flores) espalhados como sprites, para não parecer repetitivo.
