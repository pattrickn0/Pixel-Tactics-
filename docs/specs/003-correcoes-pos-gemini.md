# 003 — Correções pós-Gemini

**Status (2026-10-06):** executada e **absorvida**, sem trabalho pendente. O código atual tem a abertura 3×3, as quebras de muro em reta, os monólitos a 6, o yaw em [−180, 180) e os botões sem foco.
- **Continuam valendo:** a câmera e o HUD (C1 a C4; o C5 foi decidido pelo usuário: sem giro pelo mouse), a correção do vão do chanfro (B1/B2), que segue valendo para o barranco natural da floresta, e a regra de UV das laterais (v contínuo a partir do topo, 16 linhas por nível).
- **Ficam obsoletas com a `007`:** A1, A2, A5, A6 e D (terraços em bolha, escadas no sul, boca de trilha, quebras do muro baixo e lajotas).
- **Substituídos pela `006`:** B3 e B4 (runa e sprites de árvore).
- **Atualizados pela `007`:** os testes do item E (os de regras que saíram são retirados).

## Objetivo
O mapa volta a cumprir as regras da spec 001 com as decisões novas do usuário (câmera 360°, ruínas fora da arena, `LEVEL_HEIGHT = 0.5`). Na prática:
- o muro não deixa blocos soltos na boca das trilhas nem tocos isolados;
- os terraços têm forma limpa e escada;
- as laterais de degrau não têm vãos nas quinas arredondadas;
- a runa fica na frente do monólito em qualquer ângulo da câmera;
- a tecla Espaço sempre volta a câmera ao padrão.

Os testes headless voltam a passar.

## Contexto
- Revisão dos commits `d255b03` e `98205b5` (trabalho do Gemini fora do fluxo) e da spec 002 (ver a seção "Revisão" no fim de `002-mapa-menor-e-mais-bonito.md`).
- **Decisões do usuário já registradas (não mexer):** câmera orbital 360° com zoom; ruínas fora da arena; `LEVEL_HEIGHT = 0.5`; o mapa tem 32×32.
- **Specs em paralelo (rascunho):** `004` (luz e pós), `005` (terreno com a A02: faixas A/B nas laterais, normal maps, franja 3D) e `006` (vegetação e monólitos em 3D, regras de geração sem lado privilegiado, dither de oclusão). Esta spec é a base delas. Ela corrige geometria, geração e câmera, e faz só consertos baratos nos sprites atuais, que a `006` vai substituir. Esta spec **não** mexe em PNG nem em `tools/art/`.
- **Decisões pendentes** (o orchestrator confirma com o usuário):
  - **D1.** Arrastar com o **botão esquerdo** também gira a câmera, e isso vai conflitar com arrastar peças. Recomendado: girar só com o botão direito/do meio e com A/D (item C5).
  - **D2.** Lajotas na arena: a decisão registrada diz "ruínas fora da arena", mas a direção de arte nova e a `005` voltam a citar lajotas. O item D1 desta spec funciona com as duas respostas.
- Screenshot do usuário com os problemas: `docs/screenshots/gemini-2026-10-04.png` (seed 977978758).

## Escopo

### A. Geração do mapa (corrige as 3 falhas de `tools/tests/test_map_generation.gd`)
As regras e os testes da spec 001 continuam valendo. **Nenhuma verificação do teste existente pode ser afrouxada.** (Regras que supõem a câmera ao sul, como a faixa sul e os monólitos só no norte, ficam como estão: quem muda é a `006`.)

1. **Terraço com partes finas.** `scripts/map/map_generator.gd:426-439` e `_blob_cells` (`:457-470`). A união de bolhas deixa células elevadas fora de qualquer bloco 3×3 (pontas e tiras de 1–2 células: seed 1 em (11,13); seed 4 em (10,11), (18,11) e (18,12); 46 das seeds 1–100). Isso viola a regra "sem partes com menos de 3 células de largura".
   **Esperado:** manter a forma orgânica e aplicar uma "abertura 3×3" ao candidato antes das checagens de tamanho e de `_region_fits`. Uma célula só fica elevada se algum quadrado 3×3 que a contém estiver inteiro dentro do candidato. Se o candidato sair vazio ou dividido em mais de uma região (vizinhança 4), ele é descartado e a geração tenta outro.
2. **Escadas raras.** `map_generator.gd:451-454` sorteia **uma** região e desiste se ela não servir. `_add_stair` (`:489-507`) exige um trecho reto de `stair_width + 2` células na borda sul, e bolhas redondas quase nunca têm esse trecho. Hoje saem 2 escadas nas seeds 1–20 e 23 nas seeds 1–100, quando `stair_chance = 0.6`.
   **Esperado:** toda região elevada tem, no lado sul, um trecho reto de pelo menos `stair_width + 2` células. Sugestão: bolha ∪ retângulo-base de largura ≥ `stair_width + 2` e profundidade ≥ 3, encostado no sul da bolha, ainda passando pela abertura do item A1. A escada tenta as regiões numa ordem sorteada pelo RNG do passo até achar uma que sirva.
3. **Parâmetros fixos no código.** `map_generator.gd:427-429, 432-435, 461-462` deixam no código o raio 2,5–5,0, a margem +4, a chance 0,7 de segunda bolha, o deslocamento ±3, o fator 0,6–1,1 e o esticamento 0,8–1,25. `:421-422` calcula `min_size` e `max_size`, e `max_size` nunca é usado (warning UNUSED_VARIABLE no editor). `scripts/map/map_gen_config.gd:47-48` (`raised_region_min_size`/`max_size`) não tem mais efeito.
   **Esperado:** esses números viram `@export` em `MapGenConfig` (ex.: `raised_blob_radius_min/max`, `raised_blob_second_chance`, `raised_blob_offset`, `raised_blob_stretch_min/max`, `raised_region_center_margin`). Os campos e variáveis mortos são removidos.
4. **Monólitos perto demais.** `map_gen_config.gd:90` define `monolith_min_spacing = 3.0`. A regra da spec 001, que o teste confere, é de pelo menos 6 unidades. Hoje a seed 13 dá 4,53 e a seed 14 dá 3,87. Nenhuma decisão mudou essa regra.
   **Esperado:** `6.0`. A contagem de 1 a 3 continua.
5. **Bloco de muro solto na boca da trilha.** `map_generator.gd:613-629`, com `_trail_step` em `:640-649`. A trilha para quando o pincel encosta na arena. As células de fora que ficam num "dente" da borda da arena, ao lado da trilha, continuam grama e ganham muro em 2–3 lados. Na tela isso aparece como blocos de muro em cima da terra: seed 977978758 nas células (13,24) e (14,24), seed 1 na célula (6,19), e 69 das seeds 1–100.
   **Esperado:** depois de traçar as trilhas, aplicar uma regra até nada mudar: toda célula de fora da arena, que não é trilha, tem vizinha (vizinhança 4) de trilha e tem 2 ou mais vizinhas (vizinhança 4) da arena vira trilha (`DIRT`, nível base, `ctx.trail = 1`). Com isso, `_build_walls` (`:785-791`) já transforma os segmentos dela em falha. A regra não se espalha pela borda: simulada nas seeds 1–100, preenche no máximo 3 células por mapa.
6. **Muro picotado.** `map_generator.gd:793-821`. No mapa 32×32 o perímetro tem cerca de 80 segmentos. As quebras sorteadas caem nas quinas da "escadinha" e deixam tocos de 1 bloco: no screenshot, o muro aparece em pedaços desconectados.
   **Esperado:** uma quebra sorteada (falha ou trecho baixo, fora as falhas de trilha) só pode cair numa reta: mesmo `outward`, células consecutivas em `along`. Ela precisa ter pelo menos 2 segmentos inteiros (altura = `wall_height`) na mesma reta, antes e depois, e ficar a pelo menos 3 segmentos de uma falha de trilha. `wall_broken_ratio` não muda. Se não houver lugar, saem menos quebras.

### B. Terreno e sprites
1. **Vão no chanfro.** `scripts/map/terrain_mesh_builder.gd:98-132` corta as paredes retas em `BEVEL_R` em **todos** os níveis quando a quina é convexa. Já `:135-193` só faz o arco e o preenchimento a partir de `low_lvl = max(vizinho1, vizinho2)`. Se os dois vizinhos mais baixos estão em níveis diferentes, inclusive fora do mapa (`floor_level`), sobra um vão aberto de 0,38 × (diferença de níveis × 0,5). Confirmado por raio: com H = 2, N = 1 e W = 0, não há face em x = cx, z ∈ [cz, cz+0,38], y ∈ [0; 0,5]. São cerca de 20 vãos por mapa na borda do mapa e cerca de 1 dentro, visíveis girando a câmera.
   **Esperado:** abaixo do `low_lvl` da quina, a parede reta do lado mais baixo vai até o canto, sem corte. O corte só vale para níveis ≥ `low_lvl`.
2. **Constante duplicada.** `terrain_mesh_builder.gd:9` define `BEVEL_K = 0.38 * 0.292893`, que repete o literal de `BEVEL_R`. **Esperado:** derivar de `BEVEL_R` (ex.: `BEVEL_R * (1.0 - sqrt(0.5))`).
3. **Runa atrás do monólito.** `scripts/map/map_renderer.gd:15-16, 59-60` desloca a camada da runa +0,02 em Z do **mundo**. Com billboard (`scripts/map/art_library.gd:108`), em yaw 180° a camada emissiva fica atrás do monólito: confirmado, o mesmo monólito brilha em yaw 0 e não brilha em yaw 180. Em 90° e 270° ela briga em profundidade (z-fighting).
   **Esperado:** o deslocamento fica no espaço local do billboard, virado para a câmera. O quad da runa é montado com z = +`RUNE_OFFSET` em `ArtLibrary.sprite_mesh(..., true)` (`art_library.gd:121-136`), e as runas usam exatamente a posição do monólito.
4. **Árvores escaladas.** `art_library.gd:126` (`scale = 1.6` para `tree_*`) viola o `CLAUDE.md` (`pixel_size = 1/32`). A árvore fica com 20 texels por unidade, com pixel maior que o do chão.
   **Esperado:** nenhum sprite escalado. O tamanho final das árvores vem dos modelos 3D da `006`.
5. **Comentário desatualizado.** `map_renderer.gd:47-49` ainda diz que a câmera nunca gira e que quads fixos equivalem ao billboard. **Esperado:** descrever o billboard e a limitação de sombra (ver "Fora de escopo").

### C. Câmera e HUD
1. **Espaço aciona o botão com foco.** Em `scenes/main.tscn:96-99, 111-114, 119-134`, os botões ficam com foco depois do clique, e Espaço/Enter acionam o botão em foco. Confirmado: com "Gerar mapa" clicado, Espaço gera um mapa novo.
   **Esperado:** `focus_mode = FOCUS_NONE` nos 5 botões. Depois de Enter ou de "Usar seed", o `SeedInput` solta o foco (`scripts/ui/hud.gd:51-65`), para A/D/Espaço voltarem para a câmera.
2. **Reset dá várias voltas.** Em `scripts/map/map_camera.gd:108-123, 140`, o yaw acumula sem limite e `reset_to_default()` desfaz todas as voltas. Confirmado: a partir de 725°, a câmera percorre 725°.
   **Esperado:** yaw mantido em [−180°, 180°), com o valor atual e o alvo ajustados juntos, sem salto visível. O reset vai pelo caminho mais curto (≤ 180°).
3. **Comentários errados.** `map_camera.gd:3-5, 20` falam em botão direito/do meio, Q/E e setas, mas o código usa qualquer botão, A/D e R. `scripts/core/main.gd:2-3` não lista o argumento `--yaw`. **Esperado:** comentários de acordo com o código.
4. **HUD.** `hud.gd:33, 35, 37` usam lambdas sem tipo de retorno; **esperado** ligar direto (`pressed.connect(rotate_left_requested.emit)`). `hud.gd:19-21` usa `get_node_or_null("%...")` com checagem de nulo, o que esconde erro de cena; **esperado** `%RotateLeftButton` etc., como nos outros nós.
5. **(Depende de D1.)** `map_camera.gd:135-137` gira com o botão esquerdo também. **Esperado**, se D1 for aprovada: girar só com botão direito/do meio e A/D, deixando o botão esquerdo livre para arrastar peças no futuro. Se não for aprovada, registrar o conflito como limitação no relatório.

### D. Lajotas (decisão do usuário: ruínas fora da arena)
1. **Gambiarra no desenho.** `terrain_mesh_builder.gd:310-311` desenha `RUIN_TILE` com a textura de grama para esconder as lajotas. Se alguém ligar as lajotas na config, elas aparecem como grama.
   **Esperado:**
   - `RUIN_TILE` usa a textura `ruin_tile`.
   - As lajotas ficam desligadas **só pela config**: `ruin_patch_count_min/max = 0` (`map_gen_config.gd:86-87`, já é o padrão), com um comentário dizendo que estão desligadas por decisão do usuário.
   - Não apagar o código de lajota (`map_generator.gd:703-747`), por causa de D2.
   - Se D2 confirmar "sem lajota nunca", aí sim remover o código, os campos `ruin_*`, o `RUIN_TILE` e o placeholder `ruin_tile` (`scripts/map/placeholder_art.gd:40-41, 172-199`).

### E. Testes
1. `tools/tests/test_map_generation.gd`: manter todas as verificações. Acrescentar:
   - (a) escada em pelo menos 45 das seeds 1–100;
   - (b) boca da trilha (item A5);
   - (c) quebras sorteadas do muro (item A6).
2. Novo `tools/tests/test_terrain_mesh.gd`, com `MapData` montado à mão (sem gerador): caso do item B1 (H = 2, N = 1, W = 0) e o mesmo caso na borda do mapa. Raios horizontais disparados de fora contra o vão (`Geometry3D.ray_intersects_triangle`) acertam a malha a no máximo 0,4 da aresta.
3. `tools/tests/test_main_scene.gd`, acrescentar:
   - (a) A/D mudam o yaw alvo em ±`rotation_step`;
   - (b) Espaço volta a yaw 0 e `start_distance`;
   - (c) depois de yaw 725 + reset, o caminho até o alvo é ≤ 180°;
   - (d) nos yaws 0, 90, 180 e 270, `-basis.z` aponta para o centro da arena (tolerância 0,001) e a distância fica entre os limites;
   - (e) com "Gerar mapa" em foco, Espaço não troca a seed;
   - (f) os vértices do quad da runa têm z local > 0.

## Fora de escopo
- **UV das laterais.** Hoje cada nível mostra as 16 linhas de cima da textura (`v_top = (l + 1) * lh`). É o modelo que a A02 e a `005` adotam (1 nível = 1 faixa de 16 linhas; a `005` acrescenta a faixa B por hash). A "borda flutuando" do platô no screenshot vem da arte A01, que foi desenhada para 32 linhas por nível: com `LEVEL_HEIGHT = 0.5`, só aparecem a franja e a faixa escura. A geometria ali está fechada (conferido). Isso se resolve com a A02 + `005`. **Não mudar o UV nesta spec.**
- **Sombra dos sprites ao girar.** O billboard também é aplicado na passada de sombra, pela câmera principal. Com yaw ≈ 35° e ≈ 215° o quad fica alinhado com o sol, e as sombras de árvores, arbustos e monólitos viram uma linha (confirmado com captura: com yaw 35, a sombra da mata oeste some da arena). A `006` troca esses sprites por modelos 3D. Até lá, é limitação conhecida. Se a `006` não for aprovada, abrir item próprio (quad só de sombra, fixo e virado para o sol).
- **Mata tapando a arena com a câmera girada** (yaw 180°: mais da metade da arena some): a `006` trata com regras sem lado privilegiado e dither de oclusão.
- **Trilhas "em blocos quadrados":** é o esperado pela spec 001 (chão por célula; a mistura suave de texturas está fora de escopo lá). Melhorar isso pede spec própria (shader ou decalque de borda).
- **Altura lógica no chanfro:** `MapData.get_height_at` não sabe do arredondamento das quinas, então numa quina arredondada a altura visual difere da lógica. Fica para a spec de peças.
- Arte (texturas, sprites, paleta, `tools/art/`), `docs/direcao-de-arte.md` e `CLAUDE.md`.
- Mudar as decisões registradas: câmera 360°, `LEVEL_HEIGHT`, ruínas, tamanho 32×32.
- Peças, combate, rede, loja. Novos tipos de terreno ou objeto.

## Design técnico sugerido
- As mudanças de geração (A1, A2, A5, A6) mudam os mapas de cada seed. Isso é aceito: nenhum fingerprint é guardado. Continua tudo com o RNG de cada passo e com a ordem fixa dos passos.
- A1/A2: a abertura 3×3 é uma função pura sobre um conjunto de células (`_open_3x3(cells) -> Array[Vector2i]`), fácil de testar. Use `Dictionary` como conjunto, em vez de `Array.has` em laço.
- A6: indexar os segmentos por (célula, direção), como já faz `index_by_key`, e andar na reta com `along` para checar os vizinhos.
- B1: calcular o `low_lvl` de cada quina antes das paredes retas e passar o corte por nível (`BEVEL_R` se `l >= low_lvl`, senão 0).
- C2: `wrapf(valor, -180.0, 180.0)`. Ao ajustar, some ou subtraia 360 nos dois valores (atual e alvo) juntos, para não haver salto.

## Direção de arte
Sem arte nova. Nada aqui pode contrariar o contrato das laterais em faixas de 16 linhas (A02, `005`, `docs/direcao-de-arte.md`).

## Critérios de aceite

**Geração**
- [ ] `test_map_generation.gd` passa inteiro (todas as verificações da spec 001, nenhuma afrouxada), incluindo "toda célula elevada pertence a um bloco 3×3", "escadas em pelo menos 6 das seeds 1–20" e "monólitos a pelo menos 6 um do outro".
- [ ] Escada em pelo menos 45 das seeds 1–100.
- [ ] Boca da trilha: nenhuma célula de fora da arena que não seja `DIRT` tem, ao mesmo tempo, uma vizinha (vizinhança 4) `DIRT` de fora da arena e 2 ou mais vizinhas (vizinhança 4) da arena. As células (13,24) e (14,24) da seed 977978758 e a célula (6,19) da seed 1 são `DIRT`.
- [ ] Toda quebra sorteada do muro (falha ou trecho baixo que não é de trilha) tem pelo menos 2 segmentos inteiros na mesma reta, antes e depois, e fica a pelo menos 3 segmentos de uma falha de trilha.
- [ ] `MapGenConfig` tem `@export` para todos os números das bolhas; `raised_region_min_size`/`max_size` não existem mais; nenhuma variável local sem uso em `map_generator.gd`.
- [ ] Com a config padrão, nenhuma célula é `RUIN_TILE` (seeds 1–20). Com `ruin_patch_count_min = ruin_patch_count_max = 3`, as células `RUIN_TILE` são desenhadas com a textura `ruin_tile`. (Se D2 decidir pela remoção: nada de lajota no código.)

**Terreno e sprites**
- [ ] `test_terrain_mesh.gd` passa: os vãos do item B1, dentro e na borda do mapa, são fechados.
- [ ] O UV das laterais continua igual ao de hoje (16 linhas por nível, a partir do topo).
- [ ] Nenhum sprite é escalado (densidade de 32 texels por unidade em todos).
- [ ] Runa na frente do monólito em yaw 0, 90, 180 e 270 (vértices do quad da runa com z local > 0). Nas capturas, a runa brilha nos 3 yaws.

**Câmera e HUD**
- [ ] `test_main_scene.gd` passa com os testes novos do item E3.
- [ ] Depois de clicar em qualquer botão do HUD, Espaço só reseta a câmera (não gera mapa nem gira).
- [ ] O reset nunca percorre mais de 180°.
- [ ] Comentários de `map_camera.gd`, `map_renderer.gd` e `main.gd` de acordo com o código.

**Entregáveis e validação**
- [ ] Os dois comandos de validação do `CLAUDE.md` e os três testes rodam sem `ERROR`/`SCRIPT ERROR` e sem warnings do nosso código; os testes saem com código 0.
- [ ] Capturas 1280×720 com `--capture`:
  - `docs/screenshots/003-seed-977978758-yaw0.png`, `003-seed-977978758-yaw90.png` e `003-seed-977978758-yaw180.png` (zoom padrão);
  - `003-seed-1.png`.
- [ ] Relatório do developer: arquivos alterados, como testar (F5; A/D; arrastar; Espaço; "Gerar mapa"), decisões aplicadas (D1/D2) e limitações conhecidas (sombra dos sprites ao girar, mata tapando a arena, platô com a arte A01).
