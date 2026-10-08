# 011 — Mapa feito à mão (kit modular montado numa cena)

**Substitui:** o layout da `009` (reservas de tábuas no nível 0), a `010` inteira e o `MapGenerator`. Mantém da 009 o retângulo da arena 20 × 18 e a regra "só o anel fica acima".
**Arte:** `A06-arte-mapa-a-mao.md` (roda em paralelo; o developer usa texturas provisórias até a A06 ser aprovada).
**Decisões do usuário (2026-10-07):** nada procedural no mapa nem na arte; mapa fiel à referência `docs/reference/Gemini_Generated_Image_6oy5mo6oy5mo6oy5.jpg`; arena 20 × 18 plana no nível 0 com a mancha de terra desenhada à mão; reservas no terraço do anel (minha ao sul, do inimigo ao norte); sem tábuas; kit de peças em `scenes/kit/` montado à mão em `scenes/map.tscn`; árvores 3D de verdade; muros com pedras irregulares e quinas fechadas; crista em 1,5; 32 texels/unidade, degrau de 0,5, Nearest.
**Decisões tomadas nesta spec, para o usuário confirmar:** ver o fim do arquivo.

## Objetivo
Ao abrir o jogo, o jogador vê o anfiteatro da referência em versão retangular: arena plana de grama com a mancha de terra no meio, um degrau baixo de pedra em volta, o terraço de grama onde ficam as reservas, o muro alto de pedra com musgo, as duas escadas, a trilha de lajes, a plateia (banco, caixote, troncos) atrás do muro norte e a floresta densa em volta. Nada muda entre partidas. O usuário abre `scenes/map.tscn` no editor e ajusta qualquer peça arrastando.

## 1. Análise da referência (e adaptação)

**Perfil do anel na imagem**, de dentro para fora: clareira (arena) → **degrau baixo** de pedra clara (meio nível, às vezes dois degraus no fundo) → **terraço** de grama, largo (troncos e pedras soltos em cima) → **muro alto** de pedra seca com capeamento de musgo → exterior. A imagem é uma encosta: no fundo (norte) o terraço fica **abaixo** do topo do muro, então a câmera vê a **face interna** do muro alto, com 3 a 4 fiadas (cerca de 1,0), e a plateia fica em cima, no nível da mata. Na frente (sul) o terraço fica quase no topo do muro e a câmera vê a **face externa**, alta (cerca de 1,5 a 2,0), que segura o terraço acima do chão de fora.
**Escadas:** três, largas (cerca de 3), de pedra, com bochechas de muro: uma no sudoeste, saindo para fora do muro e subindo do calçamento até o terraço; duas no fundo, descendo do terraço para a arena pelos degraus baixos, a do nordeste ligada à trilha.
**Trilha:** lajes de pedra irregulares, cerca de 3 de largura, chegando pelo sudoeste (canto de baixo à esquerda) e saindo pelo nordeste (canto de cima à direita), com borda orgânica na grama.
**Plateia:** atrás do muro do fundo: banco de tábuas, caixote, pilha de madeira e dois troncos com musgo.
**Floresta:** mata mista densa, coníferas altas em camadas e folhosas de copa redonda e grumosa; folhosas grandes emolduram a frente da tela; a mata do fundo some em névoa azulada.
**Câmera:** cerca de 40° a 45° de inclinação, vinda do sul, anfiteatro ocupando o meio da tela com a face externa do muro sul em primeiro plano.

**Adaptação (retângulo, exterior plano, câmera 360°).** Como o exterior fica todo no nível 0 (regra mantida) e a câmera gira, o perfil fica simétrico e combina as duas leituras da referência: o muro alto mostra a **face interna de 1,0** para quem está do lado de dentro (é ela que aparece do lado oposto à câmera, como o fundo da referência) e a **face externa de 1,5** para quem está fora (é ela que aparece do lado da câmera, como a frente da referência).

| Faixa | Nível | Altura do topo | Face que sobe dela | Quem vê a face |
|---|---|---|---|---|
| Arena 20 × 18 | 0 | 0,0 | degrau baixo: **0,5** (16 texels) | a arena; a câmera vê a do lado oposto |
| Terraço (reservas nos lados compridos), largura 4 | **1** | 0,5 | muro alto, face interna: **1,0** (32 texels) | o terraço e a arena; a câmera vê a do lado oposto |
| Crista do muro alto, espessura 1 | 3 | 1,5 | — | — |
| Exterior (floresta, trilha, plateia) | 0 | 0,0 | muro alto, face externa: **1,5** (48 texels) | o exterior; a câmera vê a do seu lado |

**Reserva no nível 1 (0,5):** muda a regra antiga "reserva no nível 0" da 009/`CLAUDE.md`. Decisão aberta nº 1.

## 2. Coordenadas e croqui

**Origem do mundo = centro da arena** (antes era (22, 22) num mapa 44 × 44). X para leste, Z para o sul; `Vector2(x, z)`; retângulos semiabertos `[x0, x1) × [z0, z1)`. A região montada à mão vai de −24 a 24 nos dois eixos; além disso, chão e mata de fundo até a névoa.

| Elemento | Retângulo (x, z, largura, fundo) | Topo |
|---|---|---|
| Arena (`MapData.arena_rect`) | `Rect2(-10, -9, 20, 18)` | 0,0 |
| Degrau baixo (capeamento de 0,5 + 0,5 de grama) | `Rect2(-11, -10, 22, 20)` menos a arena | 0,5 |
| Terraço (inclui o degrau baixo) | `Rect2(-14, -13, 28, 26)` menos a arena | 0,5 |
| Muro alto (espessura 1) | `Rect2(-15, -14, 30, 28)` menos `Rect2(-14, -13, 28, 26)` | 1,5 |
| Reserva sul, time 0: `terrace_rect` / `rect` | `Rect2(-10, 9, 20, 4)` / `Rect2(-9.5, 9.5, 19, 2.5)` | 0,5 |
| Reserva norte, time 1: `terrace_rect` / `rect` | `Rect2(-10, -13, 20, 4)` / `Rect2(-9.5, -12, 19, 2.5)` | 0,5 |
| Escada oeste (andável 2, bochechas de 0,5) | `Rect2(-18, 3, 8, 3)`: fora x −18 a −15 (0 → 1,5, 6 degraus), crista x −15 a −14 (patamar), dentro x −14 a −12 (1,5 → 0,5, 4 degraus), patamar x −12 a −11, x −11 a −10 (0,5 → 0, 2 degraus) | escada |
| Escada leste | rotação de 180° da oeste: `Rect2(10, -6, 8, 3)` | escada |
| Plateia (banco, caixote, pilha, 2 troncos) | cerca de `Rect2(-7, -19, 12, 3)`, no chão de fora | 0,0 |
| Trilha de lajes | do pé da escada oeste (x −18) para sudoeste até a borda (−24, ~21); do pé da escada leste (x 18) para nordeste até (24, ~−21) | 0,0 |

Degraus: espelho 0,25 (8 texels), piso 0,5 (16 texels), como hoje. Sem escada atrás das reservas.

Croqui de cima (1 caractere = 1 unidade em x; linhas = z indicado; norte em cima; a câmera padrão olha do sul). `.` exterior, `#` muro alto, `:` terraço, `R` área útil das reservas, `a` arena, `o` mancha de terra (só indicativa: o desenho é da A06), `S` escada, `T` trilha, `P` plateia.

```
  x ->  |.....|..|....|.........|.........|....|..|....|   (| em x = -24 -18 -15 -10 0 10 15 18 23)
z= -24  ................................................
z= -22  ..............................................TT
z= -20  .............................................TTT
z= -18  .................PPPPPPPPPPPP................TTT
z= -16  ............................................TTTT
z= -15  ............................................TTTT
z= -14  .........##############################.....TTT.
z= -13  .........#::::::::::::::::::::::::::::#.....TTT.
z= -12  .........#::::RRRRRRRRRRRRRRRRRRRR::::#.....TTT.
z= -11  .........#::::RRRRRRRRRRRRRRRRRRRR::::#....TTTT.
z= -10  .........#::::RRRRRRRRRRRRRRRRRRRR::::#....TTT..
z=  -9  .........#::::aaaaaaaaaaaaaaaaaaaa::::#....TTT..
z=  -8  .........#::::aaaaaaaaaaaaaaaaaaaa::::#...TTTT..
z=  -7  .........#::::aaaaaaaaaaaaaaaaaaaa::::#...TTT...
z=  -6  .........#::::aaaaaaaaaaaaaaaaaaaaSSSSSSSSTTT...
z=  -5  .........#::::aaaaaaoooooooooaaaaaSSSSSSSSTT....
z=  -4  .........#::::aaaaaoooooooooooaaaaSSSSSSSSTT....
z=  -3  .........#::::aaaaoooooooooooooaaa::::#.........
z=  -2  .........#::::aaaoooooooooooooooaa::::#.........
z=  -1  .........#::::aaaoooooooooooooooaa::::#.........
z=   0  .........#::::aaaoooooooooooooooaa::::#.........
z=   1  .........#::::aaaoooooooooooooooaa::::#.........
z=   2  .........#::::aaaaoooooooooooooaaa::::#.........
z=   3  ....TTSSSSSSSSaaaaaoooooooooooaaaa::::#.........
z=   4  ....TTSSSSSSSSaaaaaaoooooooooaaaaa::::#.........
z=   5  ...TTTSSSSSSSSaaaaaaaaaaaaaaaaaaaa::::#.........
z=   6  ...TTT...#::::aaaaaaaaaaaaaaaaaaaa::::#.........
z=   7  ..TTTT...#::::aaaaaaaaaaaaaaaaaaaa::::#.........
z=   8  ..TTT....#::::aaaaaaaaaaaaaaaaaaaa::::#.........
z=   9  ..TTT....#::::RRRRRRRRRRRRRRRRRRRR::::#.........
z=  10  .TTTT....#::::RRRRRRRRRRRRRRRRRRRR::::#.........
z=  11  .TTT.....#::::RRRRRRRRRRRRRRRRRRRR::::#.........
z=  12  .TTT.....#::::::::::::::::::::::::::::#.........
z=  13  .TTT.....##############################.........
z=  14  TTTT............................................
z=  15  TTTT............................................
z=  16  TTT.............................................
z=  18  TTT.............................................
z=  20  TT..............................................
z=  22  T...............................................
```

Floresta: densa em todo o exterior fora de 2 unidades do muro, das escadas, da trilha e da plateia; mais alta e mais fechada atrás dos cantos e do norte; folhosas grandes emoldurando o sul (como a frente da referência), sem tapar a arena na câmera padrão (o dither cuida das outras rotações). No terraço oeste e leste, um tronco caído cada (como na referência) e algumas pedras; nada sobre as reservas.

## Escopo

### Fase 1 — dados, cena e limpeza (não depende de arte)
1. **Remover o gerador e a UI de seed:** `MapGenerator`, `MapGenConfig`, `MapTrail`, `MapObject`, `MapRenderer`, `TerrainMeshBuilder`, `SkirtMeshBuilder`, `PropMeshBuilder` e o que só servia a eles (o `arena_relief_generator.gd` já saiu). Peças úteis ao kit (ex.: `mesh_batch.gd`, `rock_mesh_builder.gd`, `art_library.gd`) podem ficar, desde que sem RNG nem ruído. No HUD saem `SeedLabel`, `GenerateButton`, `SeedRow`, `UseSeedButton` e o sinal `map_requested`; ficam os botões de girar e "Padrão". Em `main.gd` sai `--seed`.
2. **`MapData` novo** (`scripts/map/map_data.gd`, `RefCounted`, sem nós): `arena_rect`, `arena_center` (= `Vector2.ZERO`), `benches: Array[MapBench]` (`MapBench.level: int` vira `height: float`), `height_areas: Array[MapHeightArea]` (`rect: Rect2`, `top: float`), `stairs: Array[MapStair]` (`rect`, `up_direction: Vector2i`, `base_height`, `step_rise = 0.25`, `tread_depth = 0.5`, `step_count`), `bounds: Rect2` (área montada, para a câmera). Saem `map_seed`, `heights`, `ground`, máscaras, `relief_*`, `trails`, `objects`.
   - Mantêm a assinatura: `is_inside_arena`, `clamp_to_arena`, `distance_to_arena`, `arena_side_of`, `mirror_point` (só rotação de 180° em torno do centro), `get_bench`, `is_inside_bench`, `clamp_to_bench`, `get_height_at`, `fingerprint()` (sem seed).
   - `get_height_at(pos)`: se `pos` está numa escada, a altura do degrau (`base_height + step_rise × (degrau + 1)`, degrau contado a partir de baixo pela distância andada no sentido de `up_direction` dividida por `tread_depth`); senão o maior `top` das `height_areas` que contêm `pos`; senão 0,0.
3. **Marcadores na cena** (`scripts/map/`, `@tool`, `Node3D`, só dados): `ArenaMarker` (`size: Vector2`), `BenchMarker` (`team: int`, `size`, `usable_margin`), `HeightArea` (`size: Vector2`, `top: float`), `StairArea` (`size`, `step_count`, sobe para −Z local). No editor desenham uma caixa de linhas (gizmo simples) para o usuário ver o que está marcando; no jogo não desenham nada. Cada peça estrutural do kit já traz os seus `HeightArea`/`StairArea` como filhos, então arrastar a peça arrasta o dado.
4. **`MapLayout`** (`scripts/map/map_layout.gd`, raiz de `scenes/map.tscn`): `build_map_data() -> MapData` lê os marcadores pelas transformações globais (rotação só em múltiplos de 90°; posição de peça estrutural em múltiplos de 0,5; fora disso, `push_error` com o nome do nó) e emite `map_ready(map_data)`. É a única ponte cena → dados.
5. **`MatchState`:** recebe o mapa pronto (`set_map(map_data)` → sinal `map_loaded(map_data)`); guarda `match_seed: int` só para o RNG de partida futuro (não usado agora). `main.gd` liga `Map.map_ready → MatchState.set_map` e `map_loaded → câmera`.
6. **`scenes/main.tscn`:** troca `MapRenderer` por uma instância de `scenes/map.tscn` (nó `Map`). Luz, ambiente, `Atmosphere`, câmera e HUD continuam.
7. **Kit em versão bloco** (`scenes/kit/`, lista na seção Kit): todas as cenas já com nome, tamanho, pivô e marcadores definitivos, mas malha simples (caixas e prismas) com texturas existentes da A03 ou placeholder em código. A Fase 2 troca só a malha e o material **dentro** de cada cena, então nada do que foi posicionado no `map.tscn` se perde.
8. **`scenes/map.tscn` montado** com as peças estruturais nas coordenadas da seção 2 (anel, escadas, marcadores) e um primeiro passe de mata, plateia e trilha.
9. **Câmera:** foco no centro da arena (0, 0); `pitch_degrees` padrão **40°**; `start_distance`/`focus_south_ratio` ajustados para, a 1280×720 e yaw 0, aparecerem inteiros: arena, as duas reservas e a face externa do muro sul, fora do painel do HUD. Limites de zoom mantidos (ajuste só se o enquadramento exigir). `focus_on_map` usa `MapData.bounds`.
10. **Testes** (ver Critérios): reescrever `test_map_generation`, `test_arena_layout`, `test_arena_fairness`, `test_terrain_mesh` como `test_map_layout.gd` e `test_kit.gd`; atualizar `test_main_scene` e `test_arena_visibility`.

### Fase 2 — kit definitivo (geometria; arte provisória até a A06)
11. **Construtor do kit:** `tools/kit/build_kit.gd` (`extends SceneTree`, headless) grava as malhas em `assets/models/kit/*.res` a partir de **tabelas explícitas** por peça em `tools/kit/` (pontos, larguras, lóbulos, andares). **Sem RNG e sem ruído:** cada pedra, laje, lóbulo e andar está escrito na tabela. Rodar duas vezes dá arquivos idênticos.
12. **Muros:** face com UV de mundo (u ao longo da face, v a partir do topo da face, 32 texels/unidade), então a textura corre contínua de uma peça para a outra. **Capeamento** em lajes individuais com contorno irregular (larguras de 0,3 a 0,8, beiral de 1 a 2 texels sobre a face, topo variando 1 a 2 texels), não uma régua. **Quinas fechadas:** a quina do muro alto tem blocos de amarração alternando longo/curto nas duas faces, sem fresta nem face sobreposta; a quina do degrau baixo fecha o capeamento em L. **Musgo pendente** (`moss_drape_*`) preso no beiral de cada face, contínuo ao longo do trecho, sem cartão sobrepondo outro na quina.
13. **Escadas:** degraus em blocos com piso e espelho de pedra, bochechas de muro de 0,5 com o mesmo capeamento; sem fresta entre escada, muro e terraço em nenhuma rotação.
14. **Chão:** plano no nível 0 (arena, exterior) e topo do terraço e da crista com grama em UV de mundo (`ground_grass_arena` dentro do anel, `ground_grass_forest` fora; a emenda fica embaixo do muro). Por cima, **decalques planos** com alfa recortado (mancha de terra, manchas de grama clara/escura, terra de mata, pedaços de trilha), posicionados à mão, em múltiplos de 1/32 e com rotação em múltiplos de 90° para o texel do decalque cair no texel do chão. Ordem entre decalques sobrepostos por pequeno deslocamento em y ou `render_priority`, sem z-fighting. Sem shader de máscara por ruído.
15. **Árvores 3D de verdade** (cada uma uma peça única, ver Kit): **folhosa** = tronco em prisma afinando com raízes e 2 a 4 galhos + copa de 8 a 20 **lóbulos** 3D arredondados (malhas low-poly fechadas, achatadas e sobrepostas, posições e raios na tabela), cada lóbulo com miolo opaco (`leaf_mass_*`) e uma casca um pouco maior com alfa recortado (`leaf_shell_*`) que dá a silhueta serrilhada em pixel; normais da copa "esféricas" (do centro da copa). **Conífera** = tronco + 5 a 9 andares em tronco de cone com a borda de baixo serrilhada **na geometria** (pontas explícitas) e faixa `conifer_fringe` em volta. Nada de cartão chapado com a silhueta da árvore. Sombra projetada pela copa.
16. **Props:** tronco caído (cilindro de 7 a 8 lados com musgo no topo e pontas com anéis), toco, pedras (low-poly facetadas, formas na tabela), banco de tábuas, caixote, pilha de madeira; capim alto, flores e cogumelos em 3 quads cruzados fixos (rotação escolhida à mão).
17. **Dither de oclusão:** árvores entre a câmera e a arena ficam semitransparentes por dither (regra do `CLAUDE.md`), em toda rotação.

### Fase 3 — arte A06 e acabamento
18. Trocar todas as texturas provisórias pelas da A06 (filtro Nearest, normal map só em pedra e madeira).
19. Passe final de montagem à mão no `map.tscn` comparando com a referência (mancha de terra, manchas de grama, trilha, plateia, troncos nos terraços, floresta e fundo), com as capturas pedidas.

## Kit (`scenes/kit/`)

Pivô de toda peça: centro da pegada, na base (y do chão onde ela se apoia). Peça estrutural: pegada em múltiplos de 0,5, frente = +Z local (para peças de muro, a face que dá para dentro do anel). Medidas em unidades (largura ao longo da frente × fundo × altura).

| Cena | Tamanho | Conteúdo / marcadores |
|---|---|---|
| `step_low_2`, `step_low_1` | 2 × 1 × 0,5 / 1 × 1 × 0,5 | degrau baixo: face de 0,5 na frente, capeamento de 0,5 + grama 0,5 em cima; `HeightArea` top 0,5 |
| `step_low_corner` | 1 × 1 × 0,5 | canto do degrau baixo (capeamento em L, fecha as duas faces); `HeightArea` 0,5 |
| `terrace_fill_4x3`, `_2x3`, `_1x3`, `_3x3` | conforme o nome × 0,5 | bloco de terraço, topo de grama; `HeightArea` 0,5 |
| `wall_high_2`, `wall_high_1` | 2 × 1 × 1,5 / 1 × 1 × 1,5 | muro alto: face interna (+Z) de 1,0 acima do terraço, face externa (−Z) de 1,5, crista de 1 com capeamento; `HeightArea` 1,5 |
| `wall_high_corner` | 1 × 1 × 1,5 | quina do muro alto com amarração; `HeightArea` 1,5 |
| `stair_outer_3` | 3 × 3 × 1,5 | 0 → 1,5, 6 degraus, andável 2 + bochechas de 0,5; `StairArea` + `HeightArea` nas bochechas (1,5) |
| `stair_inner_3` | 3 × 2 × 1,5 | 0,5 → 1,5, 4 degraus, mesmas bochechas; `StairArea` |
| `stair_low_3` | 3 × 1 × 0,5 | 0 → 0,5, 2 degraus; `StairArea` |
| `ground_inner`, `ground_outer`, `ground_far` | planos | chão do nível 0 dentro do anel, fora até ±24, e fundo até a névoa |
| `decal_arena_dirt`, `decal_grass_light_0..2`, `decal_grass_dark_0..1`, `decal_forest_soil_0..1`, `decal_trail_0..3`, `decal_trail_bend` | tamanho do PNG ÷ 32 | decalques planos (A06) |
| `tree_broad_a` … `tree_broad_e` | alt. 4,0 a 6,0 | 5 folhosas grandes únicas (verdes e oliva) |
| `tree_small_a` … `tree_small_c` | alt. 2,4 a 3,5 | 3 folhosas pequenas únicas |
| `conifer_a` … `conifer_f` | alt. 4,5 a 7,5 | 6 coníferas únicas |
| `bush_a` … `bush_d` | alt. 0,6 a 1,2 | 4 arbustos (lóbulos `leaf_*_cool`; um florido) |
| `log_a` … `log_c`, `stump_a`, `stump_b` | ver direção de arte | troncos caídos com musgo, tocos |
| `rock_a` … `rock_d` | 0,6 a 1,5 | pedras |
| `bench_wood`, `crate`, `crate_stack`, `wood_pile` | banco 2 × 0,6 × 0,5; caixote 0,75³ | plateia |
| `mushrooms_a..d`, `flowers_a..d`, `tall_grass_a..c` | pequenos | grupos de 2 a 6 quads cruzados (cartões da A03) |
| `forest_backdrop_a..c` | ~8 × 8 | aglomerados fixos de 8 a 15 árvores do kit para o fundo (sem sorteio) |

Árvores e props não têm marcador de altura (não são chão). Ficam no grupo `map_obstacle` para os testes e para as regras futuras.

## Fora de escopo
- Mecânica de reserva (slots), peças, combate, loja, rede.
- Regras de terreno (se o degrau bloqueia, se a peça sobe escada, terreno alto).
- Monólitos rúnicos: não entram neste mapa (texturas ficam guardadas).
- Gerar ou editar PNG (é a A06). Apagar PNG antigos (só depois da A06 aprovada e com OK do usuário).
- Render em baixa resolução, TAA/FXAA, trocar Nearest, mudar luz/pós (além do dither).
- Qualquer variação aleatória (rotação, escala ou posição sorteada) de árvore, prop ou decalque.

## Design técnico sugerido
- **Dados ← cena:** só `MapLayout.build_map_data()` lê a cena; `MapData` não conhece nós. Um servidor headless futuro instancia `map.tscn` e chama o mesmo método.
- **Simetria justa:** o anel, as escadas e as reservas são invariantes à rotação de 180° em torno de (0, 0). Decoração (árvores, plateia, decalques) não precisa ser simétrica.
- **Materiais:** um `ShaderMaterial` de "UV de mundo por face" para muros, capeamento e chão (32 texels/unidade, `texture_filter_nearest`, `normal_scale` 0,4 a 0,7 em pedra/madeira); decalques e cartões com `alpha_scissor`. Folhagem com o dither de oclusão (uniforms do ponto da câmera e do centro da arena).
- **Arquivos:** malhas em `assets/models/kit/`, materiais em `assets/materials/` (`.tres`), scripts do kit em `scripts/map/kit/` se precisar de `@tool` de editor.
- `@export` onde fizer sentido (ex.: `MapLayout.strict_snap`, parâmetros de câmera, força do dither).

## Direção de arte
`docs/direcao-de-arte.md` e a referência `docs/reference/Gemini_Generated_Image_6oy5mo6oy5mo6oy5.jpg`: grama quase lisa com manchas grandes desenhadas, terra de um tom com borda recortada em pixel e aro de grama clara, muro de pedra seca bege-acinzentado com capeamento de musgo e musgo escorrendo, escadas largas, lajes irregulares, copas redondas e grumosas (nada de pirulito, nada de cartão chapado), coníferas em camadas serrilhadas. 32 texels por unidade em toda superfície, Nearest, sem contorno.

## Critérios de aceite

**Fase 1**
- [ ] `grep -rnE "MapGenerator|MapGenConfig|SeedInput|GenerateButton|UseSeedButton|map_requested" scripts scenes` não retorna nada; `scripts/map/map_generator.gd` e `map_gen_config.gd` não existem.
- [ ] `grep -rnE "RandomNumberGenerator|FastNoiseLite|randi\(|randf\(|randomize" scripts/map tools/kit` não retorna nada.
- [ ] `main.tscn` instancia `scenes/map.tscn`; F5 abre o mapa sem botão "Gerar mapa" nem seed na tela; A/D giram, Espaço volta ao padrão, roda faz zoom.
- [ ] `MapData` vindo de `map.tscn`: `arena_rect == Rect2(-10, -9, 20, 18)`, `arena_center == Vector2.ZERO`; reservas time 0 `rect == Rect2(-9.5, 9.5, 19, 2.5)` e time 1 `rect == Rect2(-9.5, -12, 19, 2.5)`, ambas com `height == 0.5`.
- [ ] `get_height_at`: 0,0 em 1000 pontos da arena; 0,5 em 1000 pontos de cada `bench.rect`; 1,5 no meio da crista fora das escadas (ex.: (0, 13.5), (−14.5, 0)); 0,0 no exterior a ≥ 0,5 do muro e das escadas; máximo do mapa = 1,5.
- [ ] Escadas: exatamente 2 lances completos (oeste e leste), cada um com `get_height_at` mudando só em saltos de 0,25 ao andar pelo eixo do lance: 0 → 1,5 por fora, 1,5 → 0,5 por dentro, 0,5 → 0 até a arena; nenhuma célula de escada dentro de `bench.terrace_rect`.
- [ ] Justiça: `get_height_at(p) == get_height_at(-p)` numa grade de passo 0,25 (pontos deslocados 0,125) em `Rect2(-19, -15, 38, 30)`; a reserva do time 1 é a rotação de 180° da do time 0.
- [ ] Carregar `map.tscn` duas vezes dá `fingerprint()` idêntico.
- [ ] Peças estruturais com posição em múltiplos de 0,5 e rotação em múltiplos de 90°; `build_map_data()` emite erro para quem foge disso (testado com uma peça fora da grade numa cena de teste).
- [ ] Nenhum nó do grupo `map_obstacle` com pegada (AABB no plano) cruzando `arena_rect` ou um `bench.rect`.
- [ ] Captura padrão `docs/screenshots/011-f1-default.png` (1280×720, yaw 0, `pitch_degrees` 40): arena, as duas reservas e a face externa do muro sul inteiras, nada disso sob o HUD.
- [ ] Teste de visibilidade: na distância e pitch padrão, para yaw 0, 90, 180 e 270, todo ponto de uma grade de 0,5 em `arena_rect` (recuada 0,25) e nos `bench.rect` tem linha de visão até a câmera sem cruzar o terreno (`get_height_at` ao longo do raio); yaw 45, 135, 225 e 315: ≥ 97%.

**Fase 2**
- [ ] `tools/kit/build_kit.gd` roda headless, grava as malhas e, rodado duas vezes, gera `.res` idênticos (md5).
- [ ] Toda cena de `scenes/kit/` abre sem erro no editor e na validação headless; cada uma tem malha visível e os marcadores da tabela do Kit.
- [ ] Muro: em duas peças `wall_high_2` vizinhas, a textura continua sem salto na emenda (UV de mundo; conferido por teste que amostra u nas duas bordas, diferença < 0,001); capeamento com lajes de larguras diferentes (≥ 4 larguras distintas por `wall_high_2`) e beiral sobre a face; nenhuma fresta de luz nas quinas em yaw 45 e 135 (captura).
- [ ] Árvores: cada folhosa com 8 a 20 lóbulos 3D (malhas fechadas) e casca alfa; cada conífera com 5 a 9 andares e borda serrilhada na geometria; nenhuma árvore feita de quad com a silhueta inteira. Sombra das copas visível no chão.
- [ ] Decalques em múltiplos de 1/32 com rotação em múltiplos de 90°; sem z-fighting na captura de perto.
- [ ] Dither: com yaw 180 e zoom padrão, árvore entre a câmera e a arena aparece pontilhada e a arena fica visível (captura `011-f2-y180.png`).

**Fase 3**
- [ ] Nenhuma textura provisória (A03 descartada pela A06) referenciada em `scenes/` ou `assets/materials/`; todas as texturas com filtro Nearest.
- [ ] Capturas `docs/screenshots/011-default.png`, `011-perto.png` (zoom mínimo, borda da mancha de terra), `011-y45.png`, `011-y180.png`, e `011-comparacao.png` (captura padrão ao lado da referência). Na comparação, o Lead Project confere: mancha de terra orgânica com aro claro, muro de pedra com capeamento e musgo, árvores redondas e em camadas, trilha de lajes, plateia, sem grade de 1 unidade visível no chão.

**Sempre**
- [ ] Os dois comandos de validação do `CLAUDE.md` sem `ERROR`/`SCRIPT ERROR` nem warnings do nosso código; todos os `tools/tests/test_*.gd` saem com código 0.
- [ ] Relatório do developer com arquivos criados/alterados/removidos, como testar (F5 e como mover uma peça no editor), limitações.

## Decisões em aberto (para o usuário)
1. **Reserva no terraço, nível 1 (0,5)**, e não mais no nível 0. Recomendado: sim (é o que a referência mostra).
2. **Perfil simétrico** (degrau 0,5 → terraço 0,5 → muro alto com face interna 1,0 e externa 1,5; exterior todo no 0) em vez de encosta como na imagem (norte alto). Recomendado: simétrico (justo para os dois times e compatível com a câmera 360°).
3. **Plateia no chão de fora, atrás do muro norte**, e não em cima do muro. Recomendado: no chão de fora (aparece na câmera padrão por cima da crista).
4. **Só duas escadas** (oeste e leste, atravessando o anel inteiro), sem as escadinhas da arena para o terraço atrás das reservas que a referência tem. Recomendado: só duas.
5. **Origem no centro da arena** (as coordenadas mudam de (22, 22) para (0, 0)). Recomendado: sim (facilita montar e espelhar no editor).
