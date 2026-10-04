# 001 — Mapa HD-2D por seed

## Objetivo
Ao apertar F5, o jogador vê um mapa 3D estilo HD-2D cartoon: uma clareira enorme no centro (a arena), cercada por muro baixo de ruína, às vezes com um terraço e escada, monólitos rúnicos na borda, e uma floresta densa e azulada em volta, com relevo em degraus e trilhas de terra. A roda do mouse aproxima e afasta (a câmera nunca gira). O botão "Gerar mapa" troca o mapa, a seed fica visível e pode ser digitada para reproduzir exatamente o mesmo mapa.

## Escopo
1. **Cena principal 3D** `scenes/main.tscn` como `run/main_scene`: `Node3D` raiz com `WorldEnvironment`, `DirectionalLight3D` (sombras), câmera do mapa, renderizador do mapa e HUD.
2. **Dados do mapa** (`MapData`): classe de dados puros, sem nós nem visual.
3. **Gerador** (`MapGenerator` + `MapGenConfig`): `generate(map_seed: int) -> MapData`, **função pura da seed** (e da config).
4. **Estado mínimo da partida** (`MatchState`): guarda a seed e o `MapData` atuais, recebe a intenção "quero o mapa da seed N", gera e emite `map_generated(map_data)`.
5. **Visual 3D** (`MapRenderer` e ajudantes): malha do terreno (topos + laterais de degrau), escada, muro da arena, pedras 3D, sprites em pé (vegetação e monólitos com runa brilhando). Reage só ao sinal `map_generated`.
6. **Arte:** usa os PNG de `assets/` (lista exata abaixo) quando existirem; senão, **placeholders gerados em código** com a paleta, mesmos tamanhos.
7. **Câmera** com ângulo fixo, perspectiva, **só zoom** pela roda do mouse, entre limites `@export`. Nunca gira.
8. **Ambiente HD-2D leve:** glow leve (quase só nas runas), DOF sutil com a arena sempre nítida, névoa leve e fria, fundo escuro azulado.
9. **HUD:** botão "Gerar mapa" (seed nova aleatória), seed atual visível, campo para digitar uma seed + botão "Usar seed" (Enter também funciona).
10. **Testes headless** em `tools/tests/`: determinismo e regras do gerador; regeneração sem vazar nós.
11. **Captura de tela para revisão:** argumentos de linha de comando `--seed`, `--zoom` e `--capture` (ver Design técnico), e 4 screenshots entregues em `docs/screenshots/`.
12. **Import da arte:** PNG de `assets/` importados sem compressão com perda (ver Design técnico).

## Fora de escopo
- Peças, arrastar/posicionar, colisão entre peças, combate, loja, economia, rodadas, times.
- **Qualquer código de rede** (ENet, RPC, lobby, sincronização). Só a estrutura: geração pura, estado sem visual, visual por sinal.
- Pan, rotação, inclinação variável ou câmera que segue algo. Zoom "mirando no cursor" (o zoom mira sempre o centro da arena).
- Regras de movimento em degraus/escada (a escada é só visual), obstáculos dentro da arena, divisão da arena por lado.
- Água, rios, construções, dia/noite, vento/animação de vegetação, partículas, som.
- Shader de mistura suave entre texturas de chão (a transição desta spec é por célula, com borda irregular).
- Desenhar a arte final (é do `artist`, spec `A01`). O developer **não edita** PNG de `assets/`; pode criar/editar os `.import` deles.
- Chunks, LOD, oclusão. (MultiMesh é permitido se ajudar no desempenho, ver Visual.)

## Design técnico sugerido

### Convenções
- **Eixos:** X = leste (direita da tela), Z = sul (perto da câmera, parte de baixo da tela), Y = altura. Norte = −Z.
- **Células:** a célula `(cx, cz)` ocupa no mundo `X ∈ [cx, cx+1)`, `Z ∈ [cz, cz+1)`. O mapa começa na origem.
- **Posições contínuas:** `Vector2(x, z)` em unidades do mundo. Altura do topo = `level * LEVEL_HEIGHT`.
- `scripts/core/world_scale.gd` (`class_name WorldScale`): `TEXELS_PER_UNIT = 32`, `PIXEL_SIZE = 1.0 / TEXELS_PER_UNIT`, `LEVEL_HEIGHT = 1.0`. Único lugar dessas constantes.
- Use **`map_seed`** como nome de parâmetro/variável: `seed` sombreia a função global `seed()` e gera warning.
- Scripts de `tools/` **não** declaram `class_name` (não poluir o namespace do jogo).

### Arquivos sugeridos
| Arquivo | Responsabilidade |
|---|---|
| `scripts/core/world_scale.gd` | Constantes de escala |
| `scripts/core/palette.gd` | Cores de `docs/direcao-de-arte.md` como constantes (para placeholders) |
| `scripts/map/map_data.gd` | `class_name MapData extends RefCounted`: dados + consultas (arena, altura) |
| `scripts/map/map_object.gd` | `class_name MapObject extends RefCounted`: `kind`, `position: Vector2`, `variant: int` |
| `scripts/map/map_gen_config.gd` | `class_name MapGenConfig extends Resource`: todos os parâmetros `@export` |
| `scripts/map/map_generator.gd` | `class_name MapGenerator extends RefCounted`: `generate(map_seed: int) -> MapData` |
| `scripts/match/match_state.gd` | `class_name MatchState extends RefCounted`: `signal map_generated(map_data: MapData)`, `request_map(map_seed: int)` |
| `scripts/map/map_renderer.gd` | `class_name MapRenderer extends Node3D`: limpa e monta o visual a partir de um `MapData` |
| `scripts/map/terrain_mesh_builder.gd` | Monta a `ArrayMesh` do terreno (topos, laterais, escadas) a partir do `MapData` |
| `scripts/map/art_library.gd` | Carrega texturas/sprites de `assets/` ou pede o placeholder |
| `scripts/map/placeholder_art.gd` | Gera `ImageTexture` placeholder por nome, com a paleta e os mesmos tamanhos da A01 |
| `scripts/map/map_camera.gd` | `class_name MapCamera extends Camera3D`: ângulo fixo, zoom, DOF |
| `scripts/ui/hud.gd` | HUD; emite `map_requested(map_seed: int)` |
| `scripts/core/main.gd` | Liga tudo: cria o `MatchState`, conecta sinais, lê argumentos de linha de comando |
| `scenes/main.tscn` | Cena principal |
| `tools/tests/test_map_generation.gd` | Testes puros do gerador (`extends SceneTree`) |
| `tools/tests/test_main_scene.gd` | Testes da cena (regenerar sem vazar nós, câmera não gira, seed inválida) |

Nomes e divisão são sugestão; a separação **dados / geração / estado / visual** é obrigatória.

### Fluxo (pronto para multiplayer, sem rede)
`HUD.map_requested(map_seed)` → `MatchState.request_map(map_seed)` (valida e aplica: o "host local") → `MapGenerator.generate(map_seed)` → `MatchState` guarda e emite `map_generated(map_data)` → `MapRenderer`, `MapCamera` e `HUD` reagem.
- O HUD **nunca** chama o gerador nem o renderer direto.
- O gerador **não** lê arquivos, assets, tempo, `OS`, cena nem RNG global. Só `map_seed` + `MapGenConfig`.
- O `MapData` **não depende da arte existente**: a quantidade de variantes de cada objeto vem de constantes/config (os números da A01). O renderer faz `variant % variantes_disponíveis` se faltar arte.
- `MatchState` não conhece nós. `main.gd` faz as conexões em código.

### MapData
Campos (tipos estáticos; arrays planos indexados por `cz * size.x + cx`):
- `map_seed: int`, `size: Vector2i`
- `heights: PackedInt32Array` (nível inteiro por célula)
- `ground: PackedByteArray` (enum `Ground { ARENA_GRASS, FOREST_GRASS, DIRT, RUIN_TILE }`)
- `arena_mask: PackedByteArray` (1 = célula da arena), `arena_base_level: int`, `arena_center: Vector2`, `arena_rect: Rect2` (caixa da arena, em unidades)
- `wall_segments`: lista tipada de segmentos do muro (início, fim, altura; altura 0 = falha), gerados pelo gerador
- `stairs`: lista tipada de escadas (células de baixo, direção; nesta spec sempre subindo para o norte, voltadas para a câmera)
- `objects: Array[MapObject]`, com `kind` em enum `ObjectKind { TREE_BIG, TREE_SMALL, BUSH, GRASS_TUFT, FLOWER, ROCK, MONOLITH }`

Consultas:
- `is_inside_arena(pos: Vector2) -> bool`: verdadeiro se a célula que contém `pos` é da arena (fora do mapa = falso).
- `clamp_to_arena(pos: Vector2) -> Vector2`: se `pos` está dentro, devolve `pos` igual; se não, o ponto **mais próximo** da união das células da arena, puxado ~0,001 para dentro (o resultado sempre passa em `is_inside_arena`).
- `get_height_at(pos: Vector2) -> float`: altura do topo do chão naquele ponto (na escada pode ser a altura do degrau).
- `fingerprint() -> String`: hash (ex.: SHA-256 com `HashingContext`) de **todos** os campos, incluindo muro, escadas e objetos, em ordem fixa. Usado nos testes.

### MapGenConfig (`@export`, valores padrão sugeridos)
- `map_size = Vector2i(64, 64)`
- Arena: `arena_fraction_min = 0.62`, `arena_fraction_max = 0.68` (largura e altura da caixa da arena / tamanho do mapa), `arena_shape_noise = 0.08`, `arena_center_jitter = 2` (células), `arena_base_level = 1`, `ring_width = 2`
- Relevo: `max_level = 3`, `height_noise_frequency`, `raised_regions_min = 1`, `raised_regions_max = 2`, `raised_region_max_fraction = 0.15`, `stair_chance = 0.6`, `stair_width = 2`
- Muro: `wall_height = 0.5`, `wall_thickness = 0.5`, `wall_broken_ratio = 0.15`
- Trilhas: `trail_count_min = 2`, `trail_count_max = 3`, `trail_width = 2`
- Decoração: `ruin_patch_count_min/max`, `monolith_count_min = 3`, `monolith_count_max = 5`, densidades de árvore grande/pequena, arbusto, capim, flor, pedra, e `arena_detail_density = 0.04`
- Os nomes podem mudar; o que importa é tudo ajustável sem mexer no código. Uma instância padrão é usada se nenhuma for passada. (No multiplayer, todos os clientes usarão a mesma config; fora de escopo agora.)

### MapGenerator (ordem fixa de passos, tudo com RNG/noise semeados)
1. `RandomNumberGenerator` com `seed = map_seed`. Cada `FastNoiseLite` recebe uma sub-seed tirada desse RNG (ex.: `rng.randi()`), sempre na mesma ordem.
2. **Arena:** forma orgânica (ex.: superelipse com raio deformado por noise) centrada no meio do mapa (± jitter), com caixa entre `arena_fraction_min` e `max` do mapa nos dois eixos. Uma única região conectada, sem buracos.
3. **Relevo:** fora da arena, níveis de 0 a `max_level` por noise, recortados, sem "espinhos" de 1 célula. Arena no `arena_base_level`. Anel de `ring_width` células em volta da arena no `arena_base_level` (o muro fica em chão plano). **Faixa sul** (células ao sul da arena, na largura da arena): nunca acima do `arena_base_level`, para não tampar a arena.
4. **Degraus na arena:** 1–2 regiões elevadas em +1 nível, largas (sem partes com menos de 3 células de largura), a pelo menos 3 células da borda da arena, cada uma com no máximo `raised_region_max_fraction` da arena; no total, pelo menos 70% da arena fica no nível base. Com chance `stair_chance`, uma região ganha **escada** de `stair_width` células no lado sul (voltada para a câmera), ocupando as células de baixo.
5. **Trilhas:** de `trail_count_min` a `max`, cada uma começa numa borda do mapa e vai até a arena com curvas (passeio aleatório puxado para o centro), largura `trail_width`, chão `DIRT`, e **corta o relevo** (células da trilha no nível base). Pelo menos uma vem da borda sul. A trilha pode entrar 2–4 células na arena e se dissolver com borda irregular.
6. **Chão:** arena = `ARENA_GRASS` com 2–4 manchas soltas de `RUIN_TILE` (lajotas espaçadas, como em `ref-ruinas-planicie.png`, nunca um bloco maciço); fora = `FOREST_GRASS`; no anel, mistura irregular por noise entre grama da arena e da mata.
7. **Muro:** segmentos ao longo de toda a borda da arena, do lado de fora (a face interna coincide com a borda; o muro não come área da arena). Trechos quebrados (`wall_broken_ratio`: mais baixos ou com falha). **Falha obrigatória** onde cada trilha chega.
8. **Monólitos:** de `monolith_count_min` a `max`, no anel fora da arena (até 2 unidades da borda), nunca na faixa sul, nunca em trilha ou falha, a pelo menos 6 unidades um do outro.
9. **Pedras 3D:** fora da arena e do anel, fora das trilhas.
10. **Vegetação:** posições contínuas com jitter e espaçamento mínimo. Fora da arena: mata densa (árvores grandes, pequenas, arbustos, capim, flores); árvores não ficam em trilha. **Na faixa sul só vegetação baixa** (sem árvore grande nem monólito). **Dentro da arena só `GRASS_TUFT` e `FLOWER`**, em densidade baixa, nunca na escada.

### Visual (`MapRenderer`)
- Ao receber `map_generated`, **apaga tudo do mapa anterior** (sem vazar nós) e monta o novo, sem recarregar a cena.
- **Terreno:** `MeshInstance3D` com `ArrayMesh` gerada em código. Topo de cada célula na sua altura, UV de 1 textura por unidade, variante de textura escolhida por hash determinístico de `(cx, cz)`. Laterais onde o vizinho é mais baixo: 1 quad por nível (a lateral de 1 nível = 1 textura 32×32 inteira); o quad mais alto usa `step_side_grass` quando o topo é grama, os de baixo `step_side`. Bordas do mapa fecham com laterais até 1 nível abaixo do mínimo. Uma superfície (material) por textura é suficiente.
- **Escada:** 4 degraus de 0,25: piso com `dirt_*`, espelho com `wall_face`, laterais com `step_side`.
- **Muro:** caixas por segmento, faces com `wall_face`, topo com `wall_top`, UV em unidades do mundo (0,5 de altura mostra meia textura). Projeta sombra.
- **Pedras 3D:** malha low poly simples gerada em código (forma por variante), textura `rock`, projetam sombra.
- **Sprites em pé** (árvores, arbustos, capim, flores, monólitos): `Sprite3D` com `pixel_size = WorldScale.PIXEL_SIZE`, billboard **só no eixo Y**, alpha scissor (`alpha_cut` discard), filtro Nearest, projetando sombra, **âncora no centro da borda de baixo** (a base toca o chão em `get_height_at`). Como a câmera nunca gira, quads fixos virados para a câmera (ou `MultiMeshInstance3D` por textura, se o número de `Sprite3D` pesar) são equivalentes e aceitos.
- **Sprites não podem ficar escuros** por estarem de costas para a luz: devem parecer tão iluminados quanto o chão em volta (ex.: sol vindo da esquerda e um pouco da frente, ou normal do sprite apontando para cima via material). Decisão do developer, registrada no relatório.
- **Runa:** o monólito ganha uma camada com `monolith_N_rune.png` (unshaded/emissiva) que passa do limiar do glow; a pedra em volta não brilha. Se a máscara não existir, o placeholder gera uma.
- **Texturas:** `texture_filter` Nearest (com mipmaps) em todos os materiais e sprites, `texture_repeat` ligado no terreno.

### Arte esperada (mesmos nomes da `A01`)
O `artist` está produzindo estes arquivos em paralelo. Carregue-os se existirem (`ResourceLoader.exists`); senão use o placeholder de mesmo nome e mesmo tamanho. Arte parcial (só alguns arquivos) deve funcionar.

`assets/textures/` (32×32, opacas):
`grass_arena_0.png` … `grass_arena_3.png` · `grass_forest_0.png` `grass_forest_1.png` · `dirt_0.png` `dirt_1.png` · `ruin_tile.png` · `step_side.png` · `step_side_grass.png` · `wall_face.png` · `wall_top.png` · `rock.png`

`assets/sprites/` (fundo transparente, base na última linha, centralizada):
| Arquivo | Canvas | Variantes (`MapObject.variant`) |
|---|---|---|
| `tree_big_0.png` … `tree_big_2.png` | 96×128 | 3 |
| `tree_small_0.png` `tree_small_1.png` | 64×96 | 2 |
| `bush_0.png` … `bush_2.png` | 32×32 | 3 |
| `grass_tuft_0.png` … `grass_tuft_2.png` | 16×16 | 3 (0 e 1 = tons de grama clara, para arena e anel; 2 = tons da mata, para a floresta) |
| `flower_0.png` … `flower_2.png` | 16×16 | 3 (amarela, branca, lilás) |
| `monolith_0.png` + `monolith_0_rune.png` | 32×96 | variante 0 (alto) |
| `monolith_1.png` + `monolith_1_rune.png` | 32×64 | variante 1 (baixo, quebrado) |

Placeholders: mesmas dimensões e âncora; seguem a paleta (`scripts/core/palette.gd`), sem cor chapada: texturas com manchas/tufos, sprites com forma (copa em bolhas + tronco, contorno colorido), RNG com seed fixa.

### Import da arte
O import padrão do Godot pode comprimir com perda (VRAM) texturas usadas em 3D, o que estraga pixel art. Garanta, para tudo em `assets/textures/` e `assets/sprites/`: `compress/mode` = Lossless, `detect_3d/compress_to` = desativado, `mipmaps/generate` = ligado. Sugestão: `[importer_defaults]` no `project.godot` (mudança a descrever no relatório), para valer também para os PNG que o `artist` ainda vai criar.

### Câmera (`MapCamera`)
- `@export`: `pitch_degrees` (≈40), `fov_degrees` (≈35), `min_distance`, `max_distance`, `start_distance`, `zoom_step`.
- Alvo = centro da arena na altura do nível base; posição = alvo + direção fixa × distância. Ao chegar um mapa novo, reposiciona no centro da arena nova (mantém a distância).
- Roda do mouse muda **só a distância**, limitada entre `min` e `max`. Suavização é opcional. Nenhum código altera a rotação depois de montada. `max_distance` padrão mostra a arena inteira com a floresta como moldura.
- DOF (`CameraAttributesPractical`): desfoque perto e longe sutil, recalculado ao dar zoom para que **toda a arena fique dentro da faixa nítida**.

### Ambiente
- `DirectionalLight3D`: cima-esquerda em relação à câmera, cor levemente quente, sombras ligadas e cobrindo a arena inteira no zoom máximo; sombras de borda bem definida (cartoon).
- `WorldEnvironment`: fundo cor `#111A33` (a borda do mapa some na mata), luz ambiente fria e fraca, glow leve com limiar alto (só as runas brilham de verdade), névoa leve e fria que começa depois da arena (ex.: modo de profundidade), tonemap que **não desature** a paleta (a grama da arena ao sol deve ficar perto de `#8DB846`).

### HUD
`CanvasLayer` com: rótulo "Seed: N", botão "Gerar mapa", `LineEdit` ("Digite uma seed") + botão "Usar seed" (Enter também). Seed nova aleatória entre 0 e 999 999 999, vinda de um RNG próprio do HUD (`randomize()` é permitido **aqui**, porque só escolhe a seed; não gera o mapa). Texto que não é inteiro (`String.is_valid_int()` falso, depois de `strip_edges`) mostra "Seed inválida" e não troca o mapa. Seeds negativas e grandes (int64) são aceitas.

### Linha de comando (revisão)
`main.gd` lê `OS.get_cmdline_user_args()`:
- `--seed=N`: mapa inicial com essa seed (sem o argumento, seed aleatória).
- `--zoom=min|max|default`: distância inicial da câmera.
- `--capture=caminho.png`: espera ~60 frames, salva a imagem do viewport nesse caminho e fecha.

Exemplo (sem `--headless`, precisa de janela):
```bash
"$G" --path . --resolution 1280x720 -- --seed=42 --zoom=default --capture=docs/screenshots/001-seed-42.png
```

### Testes
Rodar depois do comando de validação 1 (para o cache de classes existir). Cada teste imprime `PASS`/`FAIL: motivo` por verificação e sai com `quit(0)` se tudo passou, `quit(1)` se não.
```bash
"$G" --headless --path . --script tools/tests/test_map_generation.gd
"$G" --headless --path . --script tools/tests/test_main_scene.gd
```

## Direção de arte
Seguir `docs/direcao-de-arte.md` (fonte única: paleta, escala, regras cartoon, iluminação) e as referências em `docs/reference/`:
- **Estilo:** `Screenshot 2026-10-04 160858.png` (clareira): grama clara e ensolarada na arena, mata escura azulada em volta, muro e laterais em pedra terrosa avermelhada com grama caindo na quina, terraço com escada, monólitos com runa ciano.
- **Composição:** `ref-floresta-vila.png` (mata densa, trilha de terra atravessando) e `ref-ruinas-planicie.png` (muros baixos, lajotas soltas no chão aberto, terraço com escada).
- **Técnica:** `Screenshot 2026-10-04 153426.png` e `153547.png` (Octopath): chão 3D texturizado, sprites em pé, relevo em degraus, DOF e névoa. Efeitos **mais leves** que lá; o cartoon tem que continuar nítido.
- Arena limpa e legível: só capim e flores baixos, manchas de lajota, poucos degraus largos. Nada alto entre a câmera e a arena.

## Critérios de aceite

**Estrutura e código**
- [ ] `run/main_scene` = `res://scenes/main.tscn`; a cena é 3D (`Node3D`) com `Camera3D` em perspectiva, `DirectionalLight3D` com sombras e `WorldEnvironment` com glow, DOF (via `CameraAttributesPractical`) e névoa ligados.
- [ ] `MapData`, `MapGenerator`, `MapGenConfig` e `MatchState` não estendem `Node` e não referenciam nós, cenas, `load()` de assets, `Time`, `OS` nem `randi()`/`randf()`/`randomize()` globais.
- [ ] `MapGenerator.generate(map_seed: int) -> MapData` existe; o HUD só emite intenção, e o `MapRenderer` só monta o visual ao receber `map_generated(map_data)`.
- [ ] `TEXELS_PER_UNIT = 32` definido num único arquivo; sprites usam `pixel_size = 1/32`.
- [ ] Tipagem estática em todo o código novo; nenhum `.cs`; nenhum addon; nenhum `get_node("../..")`.
- [ ] Todos os parâmetros de geração estão em `MapGenConfig` com `@export`; câmera com `@export` para pitch, fov e limites de zoom.

**Geração (verificado por `tools/tests/test_map_generation.gd`)**
- [ ] Determinismo: para as seeds `0, 1, 7, 42, 1337, 999999999, 2147483647, -12345`, duas instâncias novas de `MapGenerator` geram `fingerprint()` iguais; e numa mesma instância, gerar A, depois B, depois A dá o mesmo `fingerprint()` da primeira A.
- [ ] Seeds diferentes: os 8 `fingerprint()` acima são todos diferentes entre si.
- [ ] Gerar não consome o RNG global (depois de `seed(1)`, o `randi()` seguinte é o mesmo com ou sem uma chamada a `generate()` no meio).
- [ ] Arena (seeds 1 a 20): caixa da arena entre 58% e 72% do mapa na largura **e** na altura; uma única região conectada (vizinhança 4) e sem buracos.
- [ ] `is_inside_arena`/`clamp_to_arena` (1000 pontos aleatórios com seed fixa, incluindo pontos fora do mapa): `is_inside_arena(clamp_to_arena(p))` sempre verdadeiro; ponto de dentro volta igual; para ponto de fora, a distância até o resultado é a menor distância até a união das células da arena (força bruta no teste), com tolerância de 0,01.
- [ ] Relevo da arena: toda célula da arena tem altura base ou base+1; pelo menos 70% no nível base; toda célula elevada pertence a algum bloco 3×3 inteiro elevado; células do anel (vizinhas da arena, vizinhança 8) estão no nível base.
- [ ] Escadas: em pelo menos 6 das seeds 1 a 20 há escada; toda célula de escada é da arena, está no nível base, e a célula ao norte dela está no nível base+1.
- [ ] Faixa sul: nenhuma célula ao sul da arena (mesma coluna, abaixo da célula de arena mais ao sul daquela coluna) acima do nível base.
- [ ] Objetos: dentro da arena só `GRASS_TUFT` e `FLOWER`; nenhum objeto em célula de escada; nenhum `TREE_BIG` nem `MONOLITH` na faixa sul; todo `MONOLITH` fora da arena, a no máximo 2 unidades dela e a pelo menos 6 de outro monólito; todos os `variant` dentro das contagens da tabela de arte; todas as posições dentro do mapa.
- [ ] Trilhas: pelo menos `trail_count_min` caminhos de `DIRT` (vizinhança 4) ligando uma célula da borda do mapa a uma célula vizinha da arena, e pelo menos um começa na borda sul; onde cada trilha chega na arena existe falha no muro (segmento de altura 0 ou ausente).
- [ ] Muro: pelo menos 75% do perímetro da arena tem muro com altura > 0; nenhum segmento fica sobre célula da arena.
- [ ] O teste imprime o tempo médio de `generate()` com a config padrão (meta: < 500 ms na máquina do usuário).

**Cena (verificado por `tools/tests/test_main_scene.gd`)**
- [ ] Pedir a mesma seed 5 vezes seguidas: a contagem de nós (`Performance.OBJECT_NODE_COUNT`, medida após alguns frames) depois da 5ª é igual à depois da 1ª; `OBJECT_ORPHAN_NODE_COUNT` = 0 no fim.
- [ ] Depois de eventos de roda do mouse (para os dois lados, além dos limites), a distância fica entre `min_distance` e `max_distance` e o `basis` da câmera é igual ao de antes.
- [ ] Mandar "abc" como seed pelo HUD não muda a seed nem o mapa; mandar "42" troca para a seed 42 e o rótulo mostra 42.

**Visual (verificado pelos screenshots, ver Entregáveis)**
- [ ] A arena (grama clara, com muro baixo de pedra terrosa em volta, com falhas) ocupa a maior parte da tela no zoom padrão; a floresta escura azulada aparece como moldura.
- [ ] Relevo em degraus visível fora da arena (laterais de pedra com franja de grama) e pelo menos um degrau na arena; trilhas de terra entrando pelas falhas do muro.
- [ ] Monólitos na borda da arena com a runa ciano brilhando (glow só na runa); nada alto na parte de baixo da tela.
- [ ] Sprites e malhas projetam sombra; sprites não estão escuros em relação ao chão; nenhum sprite visto de lado.
- [ ] Pixels nítidos (Nearest), sem borrão de compressão; a arena inteira nítida (DOF só nas bordas da tela).
- [ ] Funciona com a arte de `assets/` ausente (placeholders) e presente (se a A01 já tiver sido entregue).

**Entregáveis e validação**
- [ ] `docs/screenshots/001-seed-1.png`, `001-seed-42.png`, `001-seed-1337.png` (zoom padrão) e `001-seed-42-max.png` (zoom máximo de afastamento), 1280×720, gerados com `--capture`.
- [ ] Os dois comandos de validação do `CLAUDE.md` e os dois testes acima rodam sem `ERROR`/`SCRIPT ERROR` e sem warnings do nosso código; os testes saem com código 0.
- [ ] Relatório com arquivos, como testar (F5 → roda do mouse; "Gerar mapa"; digitar seed), decisões (direção do sol / normal dos sprites, Sprite3D vs MultiMesh, mudanças no `project.godot`) e limitações.
