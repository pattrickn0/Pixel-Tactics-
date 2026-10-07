# 006 — Vegetação e props em 3D (coníferas, folhosas, arbustos, troncos, tocos, monólitos, capim, flores e cogumelos)

**Status:** aprovada pelo usuário em 2026-10-06.
**Revisada em 2026-10-06** para a arte A03 e o layout da `007`. Continua valendo da versão anterior:
- árvores e monólitos como modelos 3D low-poly gerados em código pela seed;
- copa = núcleo + cartões;
- quads cruzados para capim e flor;
- `MultiMesh` sem escala;
- dither de oclusão;
- mata de fundo.

O que mudou:
- o alvo virou a referência do Gemini, com coníferas de mais andares e folhosas em aglomerados de várias famílias de cor;
- entraram props novos (tronco caído, toco, cogumelo, capim alto);
- as regras de onde cada coisa pode ficar agora vêm da `007`.

**Depende de:**
- `007` (zonas: arena, reservas, anéis, floresta);
- `005` (materiais com normal map, tangentes e cartões no `ArtLibrary`);
- **A03** (cartões `leaf_*`, `leaf_olive_*`, `leaf_cool_*`, `leaf_flower_0`, `conifer_tier_*`, `grass_tuft_*`, `tall_grass_*`, `flower_*`, `mushroom_*` e `rune_*`; texturas `bark_*`, `wood_end`, `moss`, `leaves_mass` e `monolith_stone`);
- `004` (luz e sombras).

Pode começar com os placeholders da `005` antes da A03 estar aprovada.

## Objetivo
As árvores, arbustos, monólitos, capim e flores deixam de ser sprites e viram **modelos 3D low-poly gerados em código pela seed**, com textura pixel art de 32 texels por unidade. A mata fica como na referência `docs/reference/Gemini_Generated_Image_6oy5mo6oy5mo6oy5.jpg`:
- coníferas altas em camadas serrilhadas;
- folhosas de copa feita de muitos aglomerados de folhas, em verde vivo, oliva e verde-frio;
- troncos caídos com musgo, tocos, cogumelos coloridos, capim alto e flores.

Ao girar a câmera 360°, o jogador vê os lados de verdade. O que fica entre a câmera e a arena recebe dither, e a arena nunca fica escondida.

## Escopo

### A. Dados e geração (sem visual, determinístico pela seed)
1. **Tipos novos** em `MapObject.ObjectKind`: `CONIFER`, `LOG`, `STUMP`, `MUSHROOM` e `TALL_GRASS`.
   - As coníferas formam **manchas** controladas por um ruído com seed: `@export conifer_share` (sugestão de 0,4 a 0,55; a referência é bem conífera) e `conifer_patch_frequency`.
2. **Quantidade de formas por tipo** (`MapObject.VARIANT_COUNTS`):
   - `TREE_BIG` 6 (2 delas em Folhagem oliva), `TREE_SMALL` 4, `CONIFER` 6;
   - `BUSH` 4 (1 florida), `MONOLITH` 3, `LOG` 3, `STUMP` 2;
   - `GRASS_TUFT` 3, `TALL_GRASS` 2, `FLOWER` 4, `MUSHROOM` 4 (são as texturas).
3. **Zonas** (as da `007`, seção D; esta spec só acrescenta os tipos novos):
   - **arena:** só `GRASS_TUFT` e `FLOWER`, baixos (até 0,5), nunca em escada;
   - **área útil das reservas:** nada;
   - **resto do anel 1 e anel 2:** só `BUSH`, `GRASS_TUFT`, `FLOWER`, `MUSHROOM`, `TALL_GRASS` e `LOG`, fora das escadas e das chegadas. Os troncos ficam deitados ao longo do anel, como na referência;
   - **floresta:** todos os tipos. `LOG`, `STUMP` e `MUSHROOM` aparecem mais na borda da mata e perto das trilhas (densidades em `@export`). Os cogumelos ficam em grupos de 2 a 5, perto de árvores e troncos;
   - colado no anel 2 (1 célula), nada alto.
4. **Mata além do mapa** (só cenário): numa faixa de `@export outer_band_width` células (sugestão: 10) em volta do mapa, coníferas e folhosas sobre a saia da `004`.
   - Ficam numa lista separada (`MapData.backdrop_objects`) e não afetam regras.
   - Usam um RNG derivado da seed com fluxo próprio, para não mudar o resto do mapa.

### B. Formas 3D (visual, `scripts/map/props/`)
5. **Biblioteca de formas por mapa.** Para cada (tipo, variante), gera uma `ArrayMesh` com uma superfície por material, usando um RNG com seed `hash([map_seed, kind, variant])`. Mesma seed, mesmas formas. Tudo em código, sem arquivo de modelo e sem addon.
6. **Folhosa** (`TREE_BIG`: altura 4,0 a 6,0, copa 2,8 a 4,0; `TREE_SMALL`: altura 2,4 a 3,5, copa 1,6 a 2,6):
   - **Tronco:**
     - prisma de 6 a 8 lados, afinando de 30% a 50%;
     - 2 ou 3 segmentos com leve curva;
     - de 2 a 4 raízes curtas na base;
     - de 0 a 2 galhos grossos entrando na copa;
     - material `bark_0`.
   - **Copa:**
     - de 3 a 6 **massas** pequenas (elipsoides low-poly deformados) com `leaves_mass`, só como núcleo escuro;
     - de 40 a 90 **cartões** de aglomerado (`leaf_*`, `leaf_olive_*` ou `leaf_cool_*`, uma família por árvore) cobrindo as massas, com centro de 0,1 a 0,35 para fora, virados para fora, giro aleatório e inclinação de até ±30°;
     - mais cartões no topo e nas laterais; de 10% a 20% virados para baixo embaixo.

     A silhueta tem que parecer **aglomerados de folhas**, como na referência, e nunca uma bola lisa sobre um pau.
   - **Normais da copa:** direção do centro da copa até o vértice, misturada com no máximo 30% da normal do plano. A copa acende como um volume só.
7. **Conífera** (altura 4,5 a 7,5):
   - tronco curto visível (0,3 a 0,8) com `bark_1`;
   - de **5 a 9 andares** em tronco de cone de 7 a 9 lados, cada um cobrindo de 30% a 50% do de baixo, com raio decrescendo e ponta final fina;
   - material `conifer_tier_0/1`, com alfa recortado e sem cull. Os dentes da textura formam a borda serrilhada de cada andar;
   - **UV:** u = comprimento de arco na base, arredondado para repetições inteiras (±25%); v de 0 a 1 do alto até a borda de baixo, com a inclinação do andar entre 0,8 e 1,0 unidade;
   - normais misturando a do cone com a direção a partir do eixo.
8. **Arbusto** (altura 0,6 a 1,2, largura 0,8 a 1,6): de 1 a 3 massas pequenas e de 10 a 24 cartões `leaf_cool_*`, sem tronco. A variante florida usa `leaf_flower_0` em parte dos cartões.
9. **Tronco caído** (`LOG`, comprimento 1,5 a 3,0, diâmetro 0,4 a 0,7):
   - cilindro de 6 a 8 lados, deitado e levemente enterrado (0,05 a 0,1);
   - casca `bark_0` nas faces laterais;
   - `wood_end` nas duas pontas (tampa com os anéis);
   - faces de cima (normal com y > 0,6) com `moss`;
   - 0 ou 1 galho curto quebrado.
10. **Toco** (`STUMP`, altura 0,3 a 0,6, diâmetro 0,4 a 0,7): cilindro curto de 6 a 8 lados, com `bark_0` nos lados, `wood_end` no topo (cortado reto ou levemente inclinado) e de 2 a 4 raízes curtas.
11. **Monólito** (altura 1,8 a 3,0, largura 0,6 a 1,0):
    - prisma de 4 a 6 lados afinando de 10% a 25%, com inclinação de até 6°;
    - topo arredondado ou quebrado;
    - normais planas, UV de caixa em unidades do mundo, `monolith_stone` com normal map;
    - 1 ou 2 decalques de runa (`rune_0..2`, 0,5 × 0,5) emissivos, sem sombra.
12. **Capim, capim alto, flor e cogumelo:**
    - **3 quads cruzados a 60°**, fixos no mundo (sem billboard), com a base no chão: 0,5 × 0,5 (`grass_tuft_*`, `flower_*` e `mushroom_*`) ou 0,5 × 1,0 (`tall_grass_*`);
    - normal para cima, alfa recortado, **sem sombra projetada**.
13. **Instâncias:**
    - cada forma é desenhada com `MultiMeshInstance3D`, com posição e yaw sorteado por `hash(position)`, **sem escala**;
    - árvores, arbustos, troncos, tocos, monólitos e pedras projetam sombra; capim, flor e cogumelo não;
    - as copas recebem sombra. Se aparecer acne, ajuste o bias e relate.
14. **Saem os sprites** de árvore, arbusto, capim, flor e monólito do `MapRenderer`, junto com a camada de runa em billboard e a mata de fundo em sprite (`_add_backdrop_forest`).
    - O caminho de sprite em pé (`ArtLibrary.sprite_mesh`) fica para as peças.
    - Os PNG antigos de `assets/sprites/` **não** são apagados (decisão do usuário, depois).

### C. Oclusão com câmera 360° (dither)
15. Árvores, coníferas e monólitos entre a câmera e o anfiteatro ganham **dither de transparência**:
    - **quem:** objetos do lado da câmera (em relação ao centro da arena), a até `@export occlusion_depth` (sugestão: 7) unidades da borda do anel 2, e perto da linha câmera → arena;
    - **como:** descartam de 0% a 75% dos pixels num padrão Bayer 4×4 em pixels de tela (alfa binário). A porcentagem cresce suavemente quanto mais o objeto tampa a arena e as reservas;
    - a **sombra continua inteira**;
    - arbustos, troncos, tocos, capim, flores e cogumelos nunca recebem dither.
16. A porcentagem de cada instância vem de uma **função pura testável**, `OcclusionFade.amount(instance_pos, camera_pos, arena_center, structure_half_size) -> float`. Ela é recalculada quando a câmera gira ou muda o zoom e entra no shader (ex.: `INSTANCE_CUSTOM`).

### D. Capturas
17. 1280×720 em `docs/screenshots/`:
    - `006-s42-y0.png`, `006-s42-y90.png`, `006-s42-y180.png` e `006-s42-y270.png` (zoom padrão);
    - `006-s42-y45-max.png`;
    - `006-s1337-y30-min.png` (de perto: conífera, folhosa, tronco caído e cogumelos);
    - `006-s1-y200-max.png`.

## Fora de escopo
- Vento e animação de folhas, LOD além do necessário para o desempenho, partículas.
- Peças, colisão, interação, árvores destrutíveis.
- Mudar ambiente e pós (`004`), terreno e muros (`005`) ou layout e zonas (`007`), além de ajustes mínimos para integrar.
- Apagar arquivos de `assets/sprites/`, editar PNG ou criar arte nova (se faltar textura, use placeholder e relate).
- Obstáculos dentro da arena e regras de movimento.

## Design técnico sugerido
- **Organização:**
  - `scripts/map/props/prop_shape_library.gd`: cache de formas por mapa;
  - um construtor por tipo: `broadleaf_builder.gd`, `conifer_builder.gd`, `bush_builder.gd`, `log_builder.gd`, `stump_builder.gd`, `monolith_builder.gd` e `tuft_builder.gd`;
  - `occlusion_fade.gd`: função pura;
  - os parâmetros de forma num `Resource` visual próprio (ex.: `PropStyle`) com `@export`, separado do `MapGenConfig`.
- **Reaproveitamento:** `MeshBatch` (com as tangentes da `005`) e o padrão do `RockMeshBuilder` (RNG por objeto, normais para fora).
- **Massas da copa:** icosfera de subdivisão 1, deformada por ruído e escalada nos eixos, com UV de caixa em unidades do objeto.
- **Dither e sombra:** duas `MultiMeshInstance3D` por forma alta:
  - uma só de sombra (`SHADOW_CASTING_SETTING_SHADOWS_ONLY`), sem dither;
  - outra visível, sem sombra, com dither.
- **Material das formas altas:** `ShaderMaterial` próprio (Nearest com mipmaps, alfa recortado, normal map onde houver, fade da instância).
- **Determinismo visual:** nada de `randf()` global. Yaw e forma vêm de `hash(position)` e de `hash([map_seed, kind, variant])`.

## Direção de arte
- Fonte: `docs/direcao-de-arte.md`, seções **Como o mundo é montado**, **Escala e medidas**, **Regras dos cartões**, **Paleta** e **Terreno e mapa**.
- Alvo: as coníferas, folhosas, arbustos, troncos e cogumelos da referência do Gemini.
- **Nada de "pirulito" nem cone liso.** As árvores carregam o detalhe da cena, e o chão fica calmo.
- A densidade de texel é a mesma em tudo: de perto, o pixel da casca, da folha e do chão tem o mesmo tamanho aparente na mesma distância.

## Critérios de aceite

**Funcionais (testes headless em `tools/tests/`)**
- [ ] **Determinismo:** a mesma seed gera a mesma lista de objetos (incluindo os tipos novos e `backdrop_objects`) e as mesmas malhas de forma (mesmo hash dos arrays de vértices). Seeds diferentes geram formas diferentes.
- [ ] **Zonas:**
  - na arena, só `GRASS_TUFT` e `FLOWER`; na área útil das reservas e nas escadas, nada;
  - nos anéis, só os tipos baixos do item 3;
  - monólitos fora do anfiteatro ou no anel 2, a pelo menos 6 um do outro;
  - os objetos de `backdrop_objects` ficam todos fora do mapa.
- [ ] **Coníferas em manchas:** em 20 seeds, a fração de coníferas entre as árvores grandes fica entre 0,35 e 0,65, e mais da metade delas tem outra conífera a até 2 unidades.
- [ ] **Props:** em 20 seeds, cada mapa tem pelo menos 3 `LOG`, 3 `STUMP` e 3 grupos de `MUSHROOM`.
- [ ] **Dither (`OcclusionFade`):**
  - uma árvore entre a câmera e a arena, a 2 unidades do anel 2, tem fade > 0,4;
  - a mesma árvore do lado oposto, ou a mais de `occlusion_depth`, tem fade 0;
  - a resposta é contínua ao girar a câmera em passos de 5°.
- [ ] Regenerar o mapa 10 vezes não deixa nós nem instâncias sobrando.
- [ ] Não sobra uso de `Sprite3D` ou quad billboard para vegetação, monólitos e mata de fundo.

**Visuais (revisão nas capturas)**
- [ ] **Copas:**
  - aglomerados de folhas com recorte de pixel, lado do sol claro e lado oposto e barriga escuros, sombra recortada no chão;
  - nenhuma bola lisa nem árvore repetida "em carimbo": pelo menos 6 formas distintas de folhosa reconhecíveis em `006-s42-y0.png`, nas três famílias de cor.
- [ ] **Coníferas:** altas, com camadas serrilhadas, em manchas. A silhueta é diferente da das folhosas.
- [ ] **Props:** troncos caídos com musgo e anéis nas pontas, tocos, cogumelos coloridos e capim alto aparecem na borda da mata e nos anéis, como na referência.
- [ ] **Rotação:** nas 4 capturas de yaw, as árvores mostram lados diferentes de verdade. Cartões vistos de perfil não dominam a silhueta.
- [ ] **Arena e reservas legíveis em todas as rotações:** do lado da câmera, o que tampa recebe dither; do lado oposto, as árvores ficam sólidas.
- [ ] Além da borda do mapa, a mata continua e some na névoa azulada.
- [ ] De perto (`006-s1337-y30-min.png`), casca, folhas, troncos e chão têm a mesma densidade de pixel.
- [ ] **Comparação:** lado a lado com a referência do Gemini, a mata parece da mesma família.

**Desempenho**
- [ ] Com seed 42, yaw 45, zoom máximo e tudo ligado, o FPS médio fica **≥ 60 a 1920×1080** nesta máquina (modo `--capture`).
- [ ] O relatório traz draw calls e primitivas do quadro.

**Processo**
- [ ] Os dois comandos de validação do `CLAUDE.md` rodam sem erros, e todos os testes de `tools/tests/` passam.
- [ ] As 7 capturas estão em `docs/screenshots/`. O relatório lista os parâmetros `@export` novos e os valores padrão escolhidos.
