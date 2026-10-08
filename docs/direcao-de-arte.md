# Direção de Arte: Pixel Chess (pixel art minimalista em 2.5D)

**Status:** aprovada pelo usuário em 2026-10-06. (Reescrita em 2026-10-06; substitui a versão "HD-2D fiel ao Octopath". Atualizada em 2026-10-07 para o mapa feito à mão: specs `011` e `A06`.)

Esta é a fonte única de estilo. Vale para o `artist` (scripts em `tools/art/`), para o código (placeholders, malhas, materiais, shaders, luz e pós-processamento) e para a revisão. O Antigravity/Gemini está pausado e não edita o projeto.
Se algo aqui conflitar com uma spec de arte (`docs/specs/ANN-*.md`), vale a spec mais recente. Se conflitar com `CLAUDE.md`, vale o `CLAUDE.md`.

## Visão geral

O mundo é 3D de verdade (2.5D): **todo o cenário é modelo 3D low-poly** de um **kit de peças** (`scenes/kit/`) montado à mão em `scenes/map.tscn`, com **texturas em pixel art** a 32 texels por unidade (chão, terraços, muros, escadas, pedras, árvores, arbustos, troncos, tocos). **Nada é procedural:** nem o layout, nem a arte. Cada textura, decalque, árvore e prop é uma peça única e intencional, desenhada por script com formas, posições e cores explícitas (sem RNG nem ruído). Capim, flores e cogumelos são quads cruzados fixos. Só as **peças** (no futuro) serão sprites 2D em pé (billboard no eixo Y).

A câmera **orbita 360°** em torno do centro da arena, com inclinação fixa e zoom limitado. Por isso todo modelo precisa funcionar de qualquer lado, e a arte não traz luz lateral pintada.

**Alvo visual único:** `docs/reference/Gemini_Generated_Image_6oy5mo6oy5mo6oy5.jpg` (anfiteatro de pedra numa clareira, de dia). O que faz a imagem funcionar:

1. **Chão minimalista.** A grama é quase lisa: um tom domina (cerca de 75% dos pixels da grama ao sol, medido na imagem), com tracinhos esparsos de 2 a 3 px e uma florzinha de vez em quando. A variação vem de **manchas grandes** de grama mais clara e mais escura, com borda recortada em pixel, e da sombra das árvores. Nada de ruído por pixel, nada de "carpete".
2. **Terra orgânica.** A terra é praticamente **um tom só**, em manchas grandes com borda recortada em pixel, ilhas de grama dentro e um aro de grama clara em volta. A borda nunca segue o grid de tiles.
3. **Pedra com musgo.** Muros de pedra seca em fiadas finas, bege-acinzentado quente, com o **topo coberto de musgo** e musgo escorrendo pelas juntas. Escadas de pedra largas. Calçamento de lajes irregulares.
4. **Contraste de detalhe.** O chão é calmo. O detalhe mora nas **árvores** (coníferas em camadas serrilhadas, folhosas feitas de muitos aglomerados de folhas), nos muros e nos props (troncos caídos, tocos, cogumelos, flores, capim alto).
5. **Luz de dia claro.** Sol neutro, levemente quente; sombras suaves esverdeadas; névoa azulada só ao fundo. Imagem limpa e nítida, sem vinheta e sem desfoque forte.

**Cor viva, não ruído.** A vibração vem de poucos tons bem escolhidos e saturados (verde vivo, bege claro, verde-amarelado nas copas ao sol), não de muitos tons misturados.

### Identidade própria (o que é nosso)

- **A arena é um anfiteatro retangular.** Arena 20 × 18 plana no centro, degrau baixo, terraço em volta (com as reservas nos lados compridos) e muro alto de pedra, descendo para a floresta (ver "Terreno e mapa").
- **Monólitos rúnicos** com runa ciano (único elemento que emite luz): fora do mapa atual (spec 011); as texturas ficam guardadas.
- **Mata mista.** Coníferas altas em camadas e folhosas de copa em aglomerados, com alturas e silhuetas diferentes. Nada de "pirulito" (bola lisa num pau), nada de cone liso, nada de árvores todas iguais.
- **Não trocar paleta nem estilo por conta própria.** Propostas de mudança vão por escrito no relatório de entrega, nunca direto na arte.

## Referência

Em `docs/reference/`. Há **uma** referência.

| Arquivo | O que tirar | O que NÃO tirar |
|---|---|---|
| `Gemini_Generated_Image_6oy5mo6oy5mo6oy5.jpg` | Grama lisa com tracinhos esparsos e manchas grandes de luz; terra de um tom com borda orgânica recortada; muro de pedra seca com topo de musgo, pilares nos cantos e escadas largas; calçamento de lajes; coníferas em camadas serrilhadas; folhosas em aglomerados de folhas; troncos caídos com musgo, tocos, cogumelos coloridos, flores, capim alto; névoa azulada ao fundo; cores vivas e limpas. | A arena octogonal (a nossa é retangular, ver `CLAUDE.md`); o terreno em encosta (o nosso exterior é plano); luz pintada vinda de um lado (a câmera gira); contorno escuro nos troncos e cogumelos; o enquadramento fixo. A plateia (banco, caixote, troncos) **entra**, atrás do muro norte. |

As referências antigas do Octopath (`153426`, `153547`, `160858`) foram removidas pelo usuário e **não** são mais alvo.

## Como o mundo é montado

**Fronteira de trabalho.** O `artist` faz os **pixels**: texturas opacas, normal maps (só pedra e madeira) e cartões com alfa recortado. O `artist` também desenha os **decalques de chão** (mancha de terra, manchas de grama, terra de mata, trilha). O `developer` faz a **forma**: malhas do kit (por tabelas explícitas), UV, normais, materiais, shaders, luz, pós-processamento e a montagem à mão do mapa (posição de cada peça e decalque). O artist nunca desenha a silhueta inteira de uma árvore. O developer nunca edita PNG.

| Elemento | Geometria (developer) | Arte (artist) | Ponto de vista da arte |
|---|---|---|---|
| Chão (nível 0, terraço, crista) | Planos com UV de mundo | Grama opaca 64×64 seamless, sem normal map | De cima |
| Decalques de chão (terra, manchas, trilha) | Quads planos com alfa recortado, posicionados à mão em múltiplos de 1/32, rotação de 90° em 90° | Peças únicas com alfa binário e borda recortada em pixel | De cima |
| Muro alto e degrau baixo | Faces verticais com UV de mundo (textura contínua entre peças) | Tiras longas de pedra seca (`wall_high_face` 1,5, `wall_low_face` 0,5) + normal map | De frente |
| Capeamento e crista | Lajes individuais de contorno irregular, com beiral | Tiras de lajes com musgo + normal map | De cima |
| Musgo caindo pela borda | Cartão alfa preso no beiral, pendendo sobre a face | Cartão 128×12, seamless na horizontal | De frente |
| Quina do muro alto | Blocos de amarração alternando longo e curto, fechada | `wall_quoin` + `wall_crest_corner` | De frente / de cima |
| Escada | Degraus em blocos (espelho 0,25, piso 0,5), bochechas de muro | Piso e espelho com a largura do lance + normal map | Piso de cima; espelho de frente |
| Pedra grande | Malha low-poly facetada | Textura sem direção + normal map | Sem direção |
| Folhosa | Tronco em prisma afinando, com raízes e galhos; copa = **8 a 20 lóbulos 3D** arredondados (miolo opaco + casca um pouco maior com alfa recortado). **Nada de cartão chapado** com a silhueta da árvore | Casca, `leaf_mass_*` (opaca) e `leaf_shell_*` (alfa), seamless | Sem direção |
| Conífera | Tronco curto + **5 a 9 andares** em tronco de cone, com a borda de baixo serrilhada **na geometria** | Casca + `conifer_needles` + `conifer_fringe` (alfa) | De frente |
| Arbusto | Lóbulos pequenos, sem tronco | `leaf_mass_cool` + `leaf_shell_cool` (variante florida) | Sem direção |
| Tronco caído e toco | Cilindro low-poly (6 a 8 lados), com as pontas cortadas | Casca, madeira cortada (anéis) e musgo no topo | Casca de frente; anéis de frente para a ponta |
| Capim alto, capim, flores, cogumelos | **3 quads cruzados fixos** (sem billboard) | Cartões com alfa | De frente (de lado) |
| Monólito rúnico (fora do mapa atual) | Prisma de 4 a 6 lados afinando | Pedra opaca + normal map; runa emissiva | De frente |
| Banco, caixote, pilha de lenha (plateia) | Caixas e cilindros low-poly | Tábuas (`bench_floor_0`), `crate_*`, `wood_pile_end` | De frente / de cima |
| Peças (futuro) | `Sprite3D` billboard Y | Sprite com alfa, regras na spec das peças | De frente, com leve 3/4 de cima |

**Capim e flores: o plano e o que fica em pé.**
- O **detalhe plano** fica dentro da textura do chão e é esparso: tracinhos de 2 a 3 px e, raramente, uma florzinha de 2 a 4 px.
- O que **fica em pé** vira geometria: 3 quads cruzados a 60°, fixos no mundo, em grupos do kit com rotação escolhida à mão. A normal desses quads aponta para cima (mesma luz do chão em volta) e eles não projetam sombra.

### Ponto de vista e UV

- **Textura de topo:** vista exatamente de cima, com `u = X` (leste) e `v = Z` (sul). O topo da textura é o norte. Nada "em pé" desenhado nela.
- **Textura lateral** (muro, barranco, espelho de degrau, casca, pedra do monólito): vista de frente. O topo da textura é "para cima" no mundo.
- **Cartões:** vistos de frente. O topo do cartão é "para cima" (nos cartões de copa, "para fora e para cima").
- **Densidade:** 32 texels por unidade em toda superfície. O UV é em unidades do mundo: nada de esticar textura. Tolerâncias: até ±25% na volta do tronco e dos andares da conífera (para fechar a costura com repetições inteiras); compressão de até 50% no topo de cada andar de conífera. Modelos não são escalados em instância.

## Escala e medidas

**1 tile = 1 unidade 3D = 32 texels.** Peças futuras usam `pixel_size = 1/32`.

| Item | Medida |
|---|---|
| Textura opaca | **32×32 px** por padrão; tiras longas, grama 64×64 e decalques quando a spec pedir (sempre 32 texels/unidade). Normal map `<nome>_n.png` do mesmo tamanho, só em pedra e madeira |
| Altura de 1 nível | **0,5 unidade = 16 texels** (`WorldScale.LEVEL_HEIGHT`). A lateral de 1 nível mostra **uma faixa de 16 linhas** |
| Degrau de escada | 2 degraus por nível: espelho de 0,25 (8 texels), piso de 0,5 (16 texels) |
| Degrau baixo | face de 0,5 (16 texels), capeamento de 0,5 |
| Muro alto | crista em 1,5; face interna 1,0 (32 texels), externa 1,5 (48 texels); espessura 1 |
| Conífera | altura 4,5 a 7,5; andar de baixo com 1,8 a 3,0 de diâmetro; 5 a 9 andares |
| Folhosa grande | altura 4,0 a 6,0; copa 2,8 a 4,0 de largura; tronco 0,35 a 0,6 de diâmetro |
| Folhosa pequena | altura 2,4 a 3,5; copa 1,6 a 2,6 |
| Arbusto | altura 0,6 a 1,2; largura 0,8 a 1,6 |
| Tronco caído | comprimento 1,5 a 3,0; diâmetro 0,4 a 0,7 |
| Toco | altura 0,3 a 0,6; diâmetro 0,4 a 0,7 |
| Capim e flor | cartão 16×16 = 0,5 × 0,5 |
| Capim alto | cartão 16×32 = 0,5 × 1,0 (só fora da arena) |
| Cogumelo | cartão 16×16 = 0,5 × 0,5 (desenho de 5 a 10 texels de altura) |
| Cartão de folhagem | 32×32 = 1 × 1 |
| Musgo caindo | 32×16 = 1 × 0,5 |
| Monólito | altura 1,8 a 3,0; largura 0,6 a 1,0; runa 16×16 = 0,5 × 0,5 |
| Pedra grande | 0,6 a 1,5 de largura |
| Peça (futuro) | cerca de 1 de largura × 1 a 1,5 de altura (32 × 32 a 48 px) |

## Regras das texturas opacas

- **Tamanho da spec, opacas e seamless.** As de topo repetem sem emenda nos dois eixos. As laterais são seamless na horizontal e seguem a regra de faixas.
- **Poucos tons, por material.** Cada textura usa só os tons da tabela "Tons por material". Detalhe em **clusters de 2 a 6 px com forma** (tracinho, pedrinha, junta, folha). Nada de pixel solto de outra cor, nada de dithering no chão. Dithering (xadrez) só é permitido em pedra e casca, entre dois tons vizinhos, em no máximo 5% dos pixels.
- **Tom base dominante no chão.** Nas texturas de chão, um tom (o "base") cobre a maior parte da textura. O detalhe é esparso e espalhado.
- **Bordas neutras no chão.** Nas texturas de chão (grama, terra), as linhas e colunas 0 e 31 são só o tom base. Assim as variantes se misturam em qualquer ordem e nenhuma emenda aparece.
- **Sem padrão de repetição visível.** Nenhum elemento marcante (maior que 4×4 px) aparece mais de uma vez por textura. As manchas grandes são decalques desenhados à mão, não a textura que repete.
- **Luz pintada só de cima, nunca de lado.** A câmera gira. Nas texturas de topo, o centro de cada pedra ou tufo é mais claro e a borda é mais escura, sem lado preferido. Nas laterais, o topo de cada pedra é mais claro e a base e as juntas são mais escuras.
- **Sem iluminação global:** nada de gradiente de um lado ao outro, vinheta ou canto escurecido.
- **Sem contorno**, nem preto nem colorido. Juntas entre pedras são detalhe do material (tom escuro da rampa da pedra), não contorno.

### Tons por material

| Textura | Tons distintos | Regra de cobertura |
|---|---|---|
| Grama da arena (base, clara, escura) | 2 a 4 (+ até 3 de flor na variante florida) | tom base ≥ 75%; pixels de detalhe entre 3% e 12% |
| Grama de fora (anéis e floresta) | 2 a 4 | tom base ≥ 70%; detalhe entre 3% e 15% |
| Terra | 2 a 3 | tom base ≥ 85% |
| Calçamento | 4 a 6 | juntas entre 10% e 20% |
| Muro (face), espelho de escada | 5 a 7 | juntas entre 12% e 25%; musgo entre 5% e 20% |
| Topo do muro | 4 a 6 | musgo ≥ 50% |
| Piso de escada | 4 a 6 | — |
| Tábuas (banco da plateia, A04) | 4 a 6 | tom de tábua dominante ≥ 45%; frestas entre 8% e 16% |
| Barranco natural | 4 a 6 | — |
| Pedra grande, pedra do monólito | 4 a 6 | — |
| Casca, madeira cortada, musgo | 3 a 6 | — |
| Massa de folhas | 3 a 5 | — |
| Cartões de folhagem e de conífera | 4 a 7 | — |
| Capim, capim alto, cogumelo | 2 a 4 | — |
| Flor | 3 a 6 | — |

As árvores podem ter mais tons e detalhe que o chão: é esse contraste que deixa o chão "leve".

### Normal maps

- **Só em pedra e madeira:** muros, capeamento, crista, quinas, degraus e espelhos de escada, pedras, monólito, casca, madeira cortada, tábuas e caixote (lista exata na spec de arte vigente, hoje a `A06`). **Grama e terra não têm normal map** (o chão fica liso e calmo, como na referência).
- **Mais fracos que antes.** O relevo do normal map é de pedra a pedra, sem micro-relevo por pixel. O código usa `normal_scale` entre 0,4 e 0,7.
- Formato: `<nome>_n.png`, 32×32, RGB8 com alfa 255, **convenção OpenGL** (vermelho = +X para a direita, verde = +Y para o topo da textura). Calculado do **mapa de altura da própria arte** (pedra alta, junta baixa, chanfro de 1 px na quina), com wrap para ficar seamless.

### Laterais (faces de muro e escada)

- v começa no topo da face e desce: a face de 1,0 usa as 32 primeiras linhas da textura de 1,5, então o pedaço de cima também tem que ler como muro completo.
- u corre ao longo do muro em coordenadas do mundo: as tiras são seamless na horizontal e o muro não mostra emenda entre peças.
- Topo de cada bloco mais claro, base e juntas mais escuras; sem escurecer o pé da face (a sombra é do motor).

## Regras dos cartões (alfa recortado)

- Alfa **binário** (0 ou 255). Silhueta com recorte de pixel (pontas de folha, galhos, lâminas), **sem contorno**.
- Margem de 1 px livre em volta, exceto nos cartões seamless na horizontal (`moss_fringe_*`, `grass_fringe_*`, `conifer_tier_*`).
- Luz pintada só de cima: o topo de cada aglomerado é mais claro, a base e o miolo mais escuros. A borda de cima nunca é escura.
- O volume da copa vem do motor (normais "esféricas" da copa). O cartão pinta só o aglomerado.
- Capim, flor e cogumelo: a base toca a última linha e fica centralizada.
- Sem sombra no chão desenhada: o motor projeta a sombra.

## Transições e manchas (desenhadas à mão)

O chão da referência tem bordas recortadas em pixel. Isso agora é **decalque**: uma imagem com alfa binário, desenhada pelo `artist` como peça única (contorno, ilhas, aro de grama clara, tudo escrito no script), e posicionada à mão pelo `developer` na cena do mapa.

- **Alinhamento ao texel:** decalque em múltiplos de 1/32 e rotação de 90° em 90°, para o pixel do decalque cair no pixel do chão.
- **Terra:** uma mancha grande de um tom, contorno com lóbulos e reentrâncias, ilhas de grama dentro, aro de grama clara de 1 a 3 texels, dentes e ilhotas soltas. Nenhum trecho reto de borda com mais de 6 texels.
- **Manchas de grama:** decalques de grama clara e escura com formas diferentes entre si.
- **Trilha:** trechos de lajes que encaixam pelas pontas, com borda irregular e aro de grama clara.
- **Grama da arena ↔ grama de fora:** o limite fica embaixo do muro, então não precisa de transição.
- Proibido: máscara por ruído, blend suave entre texturas, borda seguindo o grid.

## Iluminação e pós-processamento (motor)

Momento do dia: **dia claro**, fim de manhã.

- **Sol:** `DirectionalLight3D` neutro levemente quente (`#FFF3DC`), elevação de 50° a 60°, vindo do sudoeste (na câmera padrão, frente-esquerda). Fixo no mundo por padrão.
- **Sombras reais em tudo:** terreno, muros, árvores, troncos, monólitos e pedras. As copas projetam sombra recortada pelos cartões. Capim, flores e cogumelos não projetam sombra.
- **Sombra suave e esverdeada.** A luz ambiente é verde-azulada clara (`#7FA898`), forte o bastante para a grama na sombra ficar verde médio (alvo na tela: perto de `#2E6B45`), nunca azul-petróleo nem quase preta. SSAO leve, só para assentar troncos, pedras e o pé dos muros.
- **Bloom fraco:** só um halo discreto na runa e nas luzes mais altas. A grama ao sol não "brilha".
- **Desfoque bem sutil, só no fundo distante:** nada perto da câmera é desfocado. O anfiteatro inteiro e a mata em volta dele ficam nítidos; só o que está além da borda do mapa ganha um desfoque leve.
- **Névoa azulada só ao fundo:** névoa de profundidade com cor `#A6C4CE`, começando depois da borda do mapa. A floresta do fundo puxa para azul-esverdeado claro, como no alto da referência.
- **Sem vinheta.** **Sem color grading forte:** no máximo saturação 1,05 a 1,10 e contraste 1,0 a 1,05. O tonemap deve preservar as cores da paleta (a grama ao sol na tela fica perto de `#5B9C47`/`#73A949`).
- **Fundo nunca vazio:** o chão e a mata continuam além do mapa e somem na névoa. Céu claro.
- **Emissão:** só as runas (e, no futuro, efeitos das peças).
- **Proibido na arte** (texturas e cartões): glow pintado, blur, névoa, vinheta, gradiente global, sombra projetada, semitransparência e anti-aliasing.

Cores de ambiente (referência para o código; não entram nas texturas):

| Uso | Hex |
|---|---|
| Sol | `#FFF3DC` |
| Luz ambiente (sombra) | `#7FA898` |
| Céu no zênite | `#78AEDB` |
| Céu no horizonte | `#BFD8E0` |
| Névoa | `#A6C4CE` |
| Alvo da grama na sombra (na tela) | `#2E6B45` |

## Pixel e filtro

- Filtro **Nearest** (com mipmaps) em toda textura pixel art. Cada pixel da arte é 1 texel.
- Em perspectiva, o tamanho do pixel na tela varia com a distância. O que precisa ser igual é a **densidade**: 32 texels por unidade.
- Sem TAA nem FXAA, porque borram o pixel.
- Os decalques do chão ficam alinhados ao texel: borda de pixel, nunca gradiente.

## Paleta (hex)

Extraída da referência (amostragem de regiões da imagem com um script Godot headless em 2026-10-06) e arredondada. Use **somente** estas cores nas texturas e cartões. Não crie famílias novas: se faltar cor, proponha no relatório e não pinte. Em cada grupo, a ordem é da sombra para a luz.

| Grupo | Sombra → Luz | Origem na referência |
|---|---|---|
| Grama da arena | `#4E9343` `#5B9C47` `#73A949` `#98B654` | `#5B9C47` cobre 75% da grama ao sol; `#73A949` nas manchas claras e no aro da terra |
| Grama de fora (anéis e floresta) | `#2C7036` `#3D853C` `#539342` `#6A9E4A` | `#3D853C` cobre a grama dos anéis e da mata |
| Terra | `#8E7B4C` `#A8955F` `#C0AE71` `#D4C48C` | `#C0AE71` cobre 95% da terra |
| Terra escura (barranco) | `#3E3226` `#5A4632` `#7A6444` | — |
| Pedra (muro, escada, calçamento, pedra grande) | `#1C2B2B` `#34403C` `#5C6250` `#7A7A66` `#989680` `#B9B597` `#D3CCB4` | juntas `#252B2A`; pedra `#878576` a `#D3CCB4` |
| Musgo | `#2E4A1E` `#496819` `#5E7C26` `#789636` `#8FAE48` `#B0C860` | topo do muro `#87A946`, juntas `#445827` |
| Folhagem verde (folhosa) | `#123B32` `#1F5530` `#2F6A2A` `#437B25` `#5A9628` `#76AB2A` `#9CC230` `#B5CA33` | copas da frente: `#76AB2A`, luz `#B5CA33` |
| Folhagem oliva (folhosa amarelada) | `#1B3429` `#2B4328` `#3B5328` `#546A29` `#6E8432` `#869736` `#A6B04A` | folhosa amarelada do fundo |
| Folhagem fria (arbusto, folhosa azulada) | `#163F3E` `#1C4948` `#245747` `#2F6A48` `#3F8650` `#58A758` `#7CC070` | arbustos |
| Conífera | `#08262A` `#0E3330` `#16402F` `#1F4D34` `#2C5E38` `#40743C` `#5C8C40` `#86A83E` | miolo `#08262A`; pontas ao sol verde-amareladas |
| Casca e madeira | `#1A1426` `#2C212D` `#4B3339` `#6B4C3E` `#876547` `#A37C56` `#C29A6C` `#D9BC86` | tronco caído `#A98359`, sombra `#4B3339` |
| Pedra fria (monólito) | `#1E2C34` `#33454C` `#4E6266` `#6E8482` `#93A6A0` `#BCCAC2` | — |
| Runa (emissiva) | `#1F7C86` `#33C2C4` `#7CF2EC` `#D9FFFA` | — |
| Flores | rosa `#C4506E` `#E8829C` `#F8B8C8` · branca `#D8D4C4` `#F4F0E4` `#FFFDF6` · amarela `#D8A830` `#F2D04A` `#FFF08A` · azul `#4C7CD0` `#7FB0F0` | flores da referência |
| Cogumelos | rosa `#8E3A86` `#C957B7` `#E88AD6` · azul `#2A7FA8` `#68D8E5` `#B8F2F6` · roxo `#3E2E78` `#6A4FB0` `#9C84E0` · laranja `#A8502A` `#E07A3A` `#F4A868` · pé `#B8AE98` `#E8E0C8` | cogumelos rosa `#C957B7` e azul `#68D8E5` |

Uso por material:

- **Grama da arena:** base `#5B9C47`; tracinhos em `#73A949` e `#4E9343`; `#98B654` só em pontas raras. A variante clara usa base `#73A949` (tracinhos `#98B654` e `#5B9C47`); a escura usa base `#4E9343` (tracinhos `#5B9C47`). Todas usam só o grupo Grama da arena (mais Flores na variante florida).
- **Grama de fora:** base `#3D853C`; detalhe em `#2C7036`, `#539342`; folhas caídas raras em Casca e madeira (`#876547`, até 3%).
- **Terra:** base `#C0AE71`; pedrinhas raras em `#A8955F` e `#D4C48C`; `#8E7B4C` só em pedrinhas maiores (até 3%).
- **Calçamento:** lajes em Pedra (`#989680` a `#D3CCB4`), juntas em `#7A7A66` (com `#5C6250` só nos cruzamentos) e Musgo (`#5E7C26`, `#789636`). Sem `#34403C`/`#1C2B2B`.
- **Muro, quina e espelho de escada:** Pedra, mais Musgo nas juntas e escorrendo.
- **Topo do muro:** Musgo dominante, com pedra (`#B9B597`, `#D3CCB4`) aparecendo nas bordas e em falhas.
- **Piso de escada:** Pedra clara, com Musgo e Grama da arena nas juntas.
- **Tábuas (banco da plateia, A04):** tábuas de madeira clara em Casca e madeira (`#876547` a `#D9BC86`), frestas em `#4B3339`/`#6B4C3E`, Musgo raro (`#5E7C26`, `#789636`) só em frestas. Sem `#1A1426`/`#2C212D`.
- **Barranco natural:** Terra escura e Pedra, com Musgo.
- **Pedra grande:** Pedra, mais Musgo.
- **Casca:** Casca e madeira, tons 1 a 6; a folhosa tem Musgo em placas. **Madeira cortada:** anéis em `#A37C56` `#C29A6C` `#D9BC86`.
- **Massa de folhas:** Folhagem verde, tons 1 a 4 (o miolo escuro da copa).
- **Cartões de folhagem:** Folhagem verde, oliva ou fria (uma família por cartão). Os 2 tons mais claros só no terço de cima de cada aglomerado.
- **Conífera:** Conífera. `#5C8C40`/`#86A83E` só na ponta de cima de cada camada de galhos.
- **Capim e capim alto:** Grama da arena (dentro) ou Grama de fora (fora). **Flores e cogumelos:** grupos Flores e Cogumelos, com haste e folhas em Grama da arena.
- **Monólito:** Pedra fria, mais Musgo. A runa usa só o grupo Runa.

## Terreno e mapa

O layout é o da spec `011` (feito à mão, sem seed). Resumo visual:

- **Mapa único feito à mão**, fiel à referência `Gemini_Generated_Image_6oy5mo6oy5mo6oy5.jpg`, montado com o kit em `scenes/map.tscn`. Nada de geração procedural.
- **Arena 20 × 18 plana** no nível 0, grama da arena com a mancha de terra desenhada à mão.
- **Anel:** degrau baixo de pedra (0,5) → terraço de grama (0,5, largura 4; as reservas ficam nele, nos lados compridos) → muro alto de pedra seca com capeamento de musgo (crista em 1,5; face interna 1,0, externa 1,5) → exterior no nível 0.
- **Duas escadas** largas nos lados curtos (oeste e leste) atravessam o anel; a trilha de lajes chega a elas pelo sudoeste e sai pelo nordeste.
- **Plateia** (banco, caixote, pilha de lenha, troncos com musgo) no chão de fora, atrás do muro norte.
- **Fora do anfiteatro:** floresta mista densa (coníferas e folhosas, cada modelo uma peça única), troncos caídos, tocos, cogumelos, arbustos, flores e névoa azulada ao fundo.
- **Legibilidade com câmera 360°:** arena e reservas sempre visíveis; árvores entre a câmera e a arena ficam pontilhadas (dither).
