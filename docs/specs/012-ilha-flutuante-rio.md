# 012 — Ilha flutuante, rio e exterior bonito

**Vem depois de:** `011` (fechada na revisão `revisoes/011-f3.md`). Mantém da 011 a arena, o anel, as reservas, o kit, o `MapLayout`/`MapData` e a regra "nada procedural".
**Arte:** `A07-arte-ilha-rio-transicoes.md`, do artist, que roda em paralelo. Até a A07 ser aprovada, o developer usa texturas existentes ou materiais provisórios com cor da paleta.
**Pedido do usuário (2026-10-08), resumido:** (1) câmera um pouco mais inclinada; (2) o vazio da arena é temporário, porque o HUD e as peças vão ocupar o espaço, então a arena **não** deve ser enchida; (3) a escada não pode ser cortada pelo muro, e a trilha precisa se ligar de forma natural, sem quadrados de textura; (4) tirar a plateia e deixar só árvores; (5) integrar melhor as texturas de terra; (7) menos árvores, sem copas encavaladas (o exterior existe para ser bonito); (8) um rio por fora da arena; (9) alguns metros além da mata e do rio, dar para perceber que tudo é uma **ilha flutuante**. Também: "Se esforce para o lado externo da arena ser algo muito bonito visualmente".
**Decididas pelo Lead Project** (o usuário delegou: "confio em você"): ver a seção "Decisões tomadas".

## Objetivo
O jogador vê o mesmo anfiteatro, agora com a câmera mais oblíqua: as faces de pedra aparecem, e a escada atravessa o anel como uma passagem contínua. Em volta, uma mata com respiro (clareiras, grupos, cores variadas) é cortada por um rio que nasce numa lagoa a oeste, passa atrás do muro norte, ganha uma ponte e despenca da borda leste numa cascata. A alguns metros além da mata, o chão acaba numa borda de terra e rocha, a ilha mostra o fundo cônico com raízes penduradas, e lá embaixo há um mar de nuvens com ilhotas flutuando ao longe. Em qualquer giro da câmera, o fundo tem um ponto de interesse e nunca um "fim do mundo" vazio.

## Decisões tomadas (Lead Project, 2026-10-08)
1. **Câmera:** "mais inclinada" quer dizer mais oblíqua, menos de cima, como a referência. `pitch_degrees` passa de 40 para **35**, `fov_degrees` de 32 para **40** e `start_distance` fica em cerca de **35**, ajustado para o enquadramento do critério. Testei 34 / 42 / 34 numa cópia do projeto: a arena, as duas reservas e a face sul cabem inteiras, e as faces de pedra aparecem. FOV acima de 45 deforma as bordas. Continua com inclinação fixa, giro 360° pelo teclado e zoom com limites.
2. **Escada vira passagem:** na largura do lance, a crista do muro deixa de ser muro. Entra uma peça de patamar no nível 1,0 com piso de lajes e as bochechas continuam sem interrupção de fora até dentro. Os `wall_high_1` em cima do lance saem. O patamar do terraço (x −12 a −11) também ganha piso de lajes, para o caminho ler como um só, da trilha até a arena.
3. **Trilha:** o encadeamento de peças de 3 × 3 giradas sai. Cada trilha passa a ser **um decalque único desenhado sobre o traçado** (A07): sudoeste, nordeste antes da ponte e nordeste depois da ponte. O traçado está fixado abaixo e nas mesmas coordenadas na A07.
4. **Plateia removida:** banco, caixote, pilha de lenha e os dois troncos saem do mapa. As cenas do kit continuam em `scenes/kit/`. No lugar ficam só árvores e arbustos.
5. **Mata recomposta à mão**, com menos árvores. A tabela atual, rascunhada por sequência R2, é **substituída**. A nova é composta por zonas, grupos e clareiras escritos à mão. Nenhum gerador de posição, nem como rascunho fora do projeto.
6. **Ilha flutuante:** borda orgânica a cerca de 34 a 42 unidades do centro, com promontórios nos dois mirantes e na cascata. Face de terra e rocha de 3 unidades, fundo cônico irregular até cerca de −24 e raízes penduradas. Abaixo dela, um mar de nuvens em 3D e 3 ilhotas ao longe. Além da ilha só há céu: o `ground_far` sai.
7. **Rio:** decorativo, fora do `MapData`. Leito rebaixado com água a −0,375 e margens de 0,5. Nasce numa lagoa a oeste, corre atrás do muro norte, passa sob uma ponte de madeira na trilha nordeste e cai da borda leste em cascata. A água anima trocando 4 quadros, e a cascata rola em passos inteiros de texel. Tudo depende só de `TIME`, sem sorteio.
8. **Nuvens em 3D** (lóbulos como as copas, a 32 texels por unidade), em vez de um plano de nuvem com textura esticada. Assim a escala única de 32 texels vale também para o céu.
9. **Fonte de verdade da cena:** depois desta spec, `scenes/map.tscn` é a fonte. `place_decor.gd` só reaplica a tabela com `-- --force`.
10. **Fora do `MapData`:** a ilha, o rio, a ponte, os mirantes e as nuvens são só visuais. `MapData`, `get_height_at` e os testes de altura da 011 não mudam. `bounds` continua `Rect2(-24, -24, 48, 48)`.

## Composição do exterior (a vitrine)
Coordenadas como na 011: origem no centro da arena, X para leste, Z para o sul. A câmera em yaw 0 fica ao sul e olha para o norte, em yaw 90 fica a leste e olha para oeste, em yaw 180 fica ao norte e olha para o sul, e em yaw 270 fica a oeste e olha para leste.

| Quadrante (fundo visto em) | Ponto de interesse | Onde |
|---|---|---|
| **Norte** (yaw 0) | Rio correndo atrás de uma faixa de mata baixa, ponte de madeira na trilha nordeste e, ao longe, a ilhota norte | rio em z ≈ −20 a −23; ponte em (24, −21) |
| **Oeste** (yaw 90) | **Nascente**: lagoa com pedras de musgo e a **árvore anciã** (folhosa grande e única, de copa larga e raízes à mostra) | lagoa com centro em (−27, −9), raio de cerca de 2,5; árvore em cerca de (−30, −4) |
| **Sul** (yaw 180) | **Clareira florida** com 2 ou 3 pedras de musgo, o mirante sudoeste na ponta da ilha e, na borda, raízes e nuvens | clareira em cerca de (−4, 21) a (6, 26); mirante em (−27.5, 23.5) |
| **Leste** (yaw 270) | **Cascata** caindo da borda nas nuvens, com o mirante nordeste ao lado | foz em cerca de (36, −17); mirante em (27, −28.5) |

- **Mata:** de **100 a 140 árvores** na ilha (hoje são 236, mais 96 aglomerados). Coníferas altas em grupos de 3 a 7, principalmente no norte e nos cantos. Folhosas em 3 famílias (verde, oliva, fria), e de 6 a 10 árvores em tom **outonal** ou **florido**, nunca duas dessas lado a lado. Arbustos e árvores pequenas na borda das clareiras. No sul, perto da câmera padrão, folhosas emolduram a borda de baixo sem tapar a arena, como na 011.
- **Clareiras** (sem tronco de árvore): a clareira florida, a lagoa, as duas margens do rio (de 1 a 2 unidades de cada lado), os mirantes, a faixa de 2 unidades junto ao muro (regra da 011) e pelo menos mais 2 clareiras pequenas, de raio entre 2 e 3, com troncos caídos, tocos e cogumelos.
- **Chão da ilha:** `ground_grass_forest`, com os decalques novos da A07 (prado florido, terra de mata e margem). Nada de mancha chapada.
- **Borda:** a grama termina num beiral de capim pendente (A07) sobre a face de estratos. Em 4 a 8 pontos, raízes grossas saem da face e pendem de 2 a 5 unidades. De 4 a 6 rochas pequenas flutuam perto da borda, em posições fixas, de 2 a 8 unidades abaixo do nível 0.
- **Profundidade:** mar de nuvens de −16 a −34, ilhotas a 80–120 unidades e névoa azulada só no que estiver além da borda da ilha.

### Traçados fixos (os mesmos da A07)
| Elemento | Linha central (x, z), em ordem | Largura |
|---|---|---|
| Trilha sudoeste | (−16, 4.5) → (−18, 5.2) → (−20, 7) → (−21.5, 10) → (−22.5, 13.5) → (−24, 17) → (−26, 20) → (−27.5, 23) | 3,0 no pé da escada, de 2,2 a 2,8 no resto |
| Trilha nordeste A | (16, −4.5) → (18, −5.2) → (20, −7) → (21.5, −10) → (22.5, −13.5) → (23.5, −17) → (24, −18.5) | idem |
| Ponte | de (24, −18.5) a (24, −23.5), largura 3, sobre o rio | — |
| Trilha nordeste B | (24, −23.5) → (25.5, −26) → (27, −28.5) | 2,2 a 2,8 |
| Rio (linha central) | lagoa (−27, −9) → (−26, −14) → (−22, −19) → (−14, −21.5) → (−4, −21) → (6, −22) → (14, −21) → (20, −21.5) → (24, −21) → (29, −19) → (33, −17.5) → foz e cascata em cerca de (36, −17) | 2,4 a 3,4 (variando à mão) |

A borda da ilha é desenhada à mão em volta disso. Ela fica a ≥ 2 unidades além do fim de cada trilha e mirante e a ≥ 4 de qualquer árvore na mata densa, e tem um entalhe na foz do rio.

## Escopo

### Fase 1: forma, composição e câmera (não depende da A07)
1. **Câmera** (`scripts/map/map_camera.gd`): os valores da decisão 1. Ajuste `start_distance` e `focus_south_ratio` para o enquadramento do critério. Os limites de zoom continuam `@export`, e `max_distance` não pode mostrar o fim do mar de nuvens. **Só para captura**, `main.gd` aceita `--overview` (câmera afastada fora dos limites: pitch 30, distância de cerca de 130, yaw 35, mirando a ilha inteira) e `--distance=N`. Essas opções não existem no jogo normal.
2. **Passagem da escada** (kit, pelas tabelas em `tools/kit/`): peça nova `stair_crest_3` (3 × 1 × 1,0). Piso de lajes no nível 1,0 nos 2 de largura andável, bochechas de 0,5 com o mesmo capeamento e a mesma face das bochechas de `stair_outer_3`/`stair_inner_3`, contínuas com elas e sem fresta. Tem `HeightArea` 1,0. Peça nova `stair_landing_3` (3 × 1 × 0,5), patamar no nível 0,5 com piso de lajes, para o lugar do `terrace_fill_1x3` em x −12 a −11. No `map.tscn`, os `wall_high_1` de z 3 a 6 (e os do leste) saem e entram essas duas peças. As pontas do muro alto que encostam na escada ficam fechadas pela bochecha, sem face aberta nem fresta.
3. **Plateia:** sai o grupo `Audience` do `map.tscn` e da tabela. No lugar, árvores e arbustos.
4. **`place_decor.gd`:** sem `-- --force`, recusa e explica, como `gen_initial_map.gd`. Com `--force`, avisa quantos nós de cada grupo vai trocar. O cabeçalho da tabela passa a dizer que a cena é a fonte de verdade.
5. **Ilha** (dados em `tools/kit/island_tables.gd`, malhas por `build_kit.gd`, sem RNG nem ruído):
   - `ISLAND_OUTLINE`: lista literal de 48 a 90 vértices (x, z), espaçados de forma irregular, com promontórios nos mirantes e o entalhe da foz. Nenhuma aresta com mais de 4 unidades. Proibido: círculo ou elipse com variação, raios polares a partir de um centro e a mesma lista reaproveitada em escala (mesma regra de contorno da A06).
   - Peça `island_top`: o polígono da ilha menos o polígono do rio (a lagoa é a ponta fechada do rio, e a foz chega à borda, então o resultado é um polígono sem furo). Triangulado com `Geometry2D`, com UV de mundo e grama de fora.
   - Peça `island_cliff`: face vertical ao longo do contorno, de 0 a −3, com u corrido pelo perímetro (32 texels por unidade). Beiral de capim pendente (cartão alfa, A07) preso no topo.
   - Peça `island_under`: fundo cônico em 6 a 9 anéis, cada um uma lista literal de deslocamentos para dentro e de altura, até um ápice irregular em cerca de −24, com 2 ou 3 esporões secundários. Projeção pelo eixo da normal geométrica (`uv_mode` 1).
   - Peças `root_hang_a..c`: raízes grossas em prisma afinando, de 4 a 6 lados, que saem da face. 4 a 8 instâncias.
   - Peças `floating_rock_a..c`: 4 a 6 instâncias, em posição fixa. Opcional: subir e descer no shader, em passos de 1/32, com período de 6 a 10 s.
6. **Rio** (`tools/kit/river_tables.gd`): a linha central da tabela acima, com meia-largura por ponto e polígono da lagoa, tudo literal. Malhas: `river_water` (superfície a −0,375, UV de mundo, 4 quadros trocados a 4 ou 5 por segundo), `river_bank` (faces de 0 a −0,5 nas duas margens e em volta da lagoa), faixas `river_foam` (cartão em faixa dentro da água, junto à margem) e `river_shore` (faixa de margem por cima da grama, A07). Peça `waterfall`: lâmina vertical da foz até cerca de −20, que some numa nuvem. A textura rola para baixo em passos inteiros de texel (`floor`) e há espuma (`waterfall_lip`) na quina. A lagoa leva 4 a 7 pedras de musgo.
7. **Ponte** `bridge_wood` (3 × 5, pranchas e corrimão de postes e travessas, em tabela, levemente arqueada até 0,25). Tábuas `bench_floor_0` e casca `bark_0` até a A07 trazer `bridge_plank`. Fica no grupo `map_obstacle` só nos corrimões.
8. **Mirantes** `lookout_a`: plataforma de lajes de cerca de 3 × 3 no nível 0, com mureta de pedra de 0,5 (capeamento igual ao do degrau baixo) no lado da borda. Dois, no fim de cada trilha.
9. **Céu e nuvens** (`scenes/main.tscn` e `atmosphere.gd`): sai o `ground_far`. O `ProceduralSkyMaterial` fica com o fundo (`ground_bottom_color`/`ground_horizon_color`) igual ao horizonte `#BFD8E0`, sem chão escuro. A névoa de profundidade começa depois da borda da ilha, ajustada para as ilhotas lerem azuladas mas com silhueta. O desfoque de fundo vale só além da borda. Nuvens: 5 peças `cloud_a..e` (de 6 a 14 lóbulos achatados cada, com miolo e casca como as copas, de 6 a 16 unidades de largura) e de 25 a 40 instâncias fixas entre −16 e −34, no raio de 30 a 110, uma delas sob a cascata. Não projetam sombra. Opcional: o grupo inteiro gira devagar em volta do eixo Y (menos de 1° por segundo).
10. **Ilhotas** `islet_a..c`: 3, com raio de 4 a 8, topo de grama, fundo cônico, de 2 a 5 árvores do kit e pedras. Uma tem uma cascatinha. Posições: norte em cerca de (8, 6, −100), sudoeste em cerca de (−90, −4, 55) e leste em cerca de (95, 10, 30). Não projetam sombra.
11. **Mata e decoração** (tabela reescrita à mão, aplicada uma vez com `--force`, e daí em diante ajustada na cena): a composição da seção anterior. Peças novas de árvore: `tree_ancient` (altura de 8 a 9, de 18 a 28 lóbulos, raízes à mostra; é a única exceção ao limite de 20 lóbulos da 011), `tree_broad_autumn_a`, `tree_broad_autumn_b` e `tree_small_bloom_a` (mesma geometria nova, materiais da A07; até a A07, com a folhagem verde). Os `forest_backdrop_*` saem da ilha. Se servirem, podem ser usados nas ilhotas.
12. **Desempenho:** em modo de captura, `main.gd` imprime `draw calls` e `primitives` do quadro (`RenderingServer.get_rendering_info`). Use `MultiMeshInstance3D` ou junte malhas por material onde fizer sentido (cartões pequenos, pedras, nuvens). A distância de sombra do sol cobre a ilha, não o céu.
13. **Testes:** `test_map_layout` e `test_arena_visibility` continuam passando, a visibilidade já no pitch novo. Novo `tools/tests/test_island.gd` com os critérios automáticos abaixo.
14. Capturas da Fase 1 com materiais provisórios: `docs/screenshots/012-f1-default.png`, `012-f1-y90`, `012-f1-y180`, `012-f1-y270` e `012-f1-ilha.png` (`--overview`).

### Fase 2: arte A07 e acabamento (depois da A07 aprovada)
15. Ligar todas as texturas da A07 (Nearest, normal map só em pedra e madeira).
16. **Trilhas:** os decalques únicos `decal_trail_sw`, `decal_trail_ne_a` e `decal_trail_ne_b`, cada um no centro do seu retângulo de mundo (A07). Os `decal_trail_0..3`/`_bend` saem da cena.
17. **Transições:** trocar os decalques de terra e grama pelos redesenhados, com as manchas novas em posições compostas à mão. Na arena, só o necessário (a arena continua calma, decisão 2 do usuário). Os decalques de margem, prado e terra de mata entram fora do anel.
18. Muro com `wall_high_face`/`wall_quoin` de 32 linhas e capeamento/crista novos.
19. Folhagem outonal e florida e pedra de musgo nos lugares da composição.
20. Capturas finais: `docs/screenshots/012-default.png`, `012-y90.png`, `012-y180.png`, `012-y270.png`, `012-escada.png` (escada oeste de perto: yaw 90 e `--distance` que mostre o lance inteiro) e `012-ilha.png` (`--overview`).

## Fora de escopo
- Encher a arena ou o terraço de decoração (a pedido do usuário, o vazio é para o HUD e para as peças).
- Mudar o tamanho da arena, das reservas, do anel ou das alturas. O rio e a ilha entrarem em regra de jogo.
- Física da água, reflexo em tempo real, partículas com sorteio e som.
- Peças, combate, loja e rede.
- Apagar PNG antigos sem OK do usuário.

## Design técnico sugerido
- **Tabelas em `tools/kit/`** (`island_tables.gd`, `river_tables.gd` e o catálogo novo em `kit_tables.gd`), malhas por `build_kit.gd` e cenas em `scenes/kit/`. O `map.tscn` instancia as peças. A ilha, o rio, as nuvens e as ilhotas ficam em grupos próprios (`Island`, `River`, `Sky`). Nada disso entra no `MapLayout.build_map_data()`.
- **Shaders:** a água e a cascata podem ser um shader próprio (`assets/materials/water.gdshader`) ou um `uv_mode` novo no `kit_surface`. O quadro vem de `floor(TIME * fps)`, o rolamento de `floor(TIME * texels_por_s) / 32`, e não há distorção por seno. Nuvens: `kit_surface` com `alpha_cut` e sem dither.
- **Dither:** continua só para árvores (e monólitos). Nuvens, ponte e ilhotas não têm dither.
- **Parâmetros `@export`:** quadros por segundo da água, velocidade da cascata, giro das nuvens, força da névoa.

## Direção de arte
`docs/direcao-de-arte.md`, a referência `docs/reference/Gemini_Generated_Image_6oy5mo6oy5mo6oy5.jpg` para a mata, a pedra e o chão, e a `A07` para a água, a borda, as nuvens e as cores novas. O exterior é a vitrine: em cada giro, um primeiro plano de folhagem, um meio com o ponto de interesse e um fundo de borda, nuvens e ilhota. Variação de cor intencional e com moderação. Nenhuma emenda nem grade visível.

## Critérios de aceite

**Automáticos (`test_island.gd`, `test_map_layout.gd`, `test_arena_visibility.gd`)**
- [ ] `test_map_layout` passa sem mudar nenhum valor esperado da 011 (arena, reservas, crista 1,0, lances, justiça, fingerprint).
- [ ] Visibilidade com o pitch e a distância padrão novos: 100% em yaw 0/90/180/270 e ≥ 97% em 45/135/225/315.
- [ ] `get_height_at` em (−13.5, 4.5) e (13.5, −4.5) = 1,0, e ao andar pelo eixo de cada escada a altura muda só em saltos de 0,25. Nenhum nó `wall_high_*` tem pegada que cruze `Rect2(-14, 3, 1, 3)` ou `Rect2(13, -6, 1, 3)`.
- [ ] O `map.tscn` não tem nenhuma instância de `bench_wood`, `crate`, `crate_stack` ou `wood_pile`.
- [ ] `ISLAND_OUTLINE`: de 48 a 90 vértices, polígono simples (sem autointerseção), nenhuma aresta > 4,0. Contém `Rect2(-28, -28, 56, 56)` exceto o entalhe da foz. Os pontos finais das 3 trilhas e os mirantes ficam a ≥ 2 da borda.
- [ ] Rio: todo ponto do polígono do rio e da lagoa fora de `Rect2(-20, -19, 40, 38)` (≥ 6 do muro). A foz encosta na borda. A largura varia em pelo menos 4 valores diferentes.
- [ ] Árvores na ilha (folhosas, coníferas, pequenas, anciã, outonais e floridas): entre 100 e 140. Outonais + floridas: de 6 a 10. Para todo par, distância horizontal entre os centros ≥ 0,8 × (r_a + r_b), em que r é a meia-largura do AABB da copa no plano. Todo tronco a ≥ 2 do muro, ≥ 1 da água, ≥ 0,75 da borda de uma trilha e ≥ 1,5 da borda da ilha.
- [ ] Clareiras: nenhum tronco dentro dos círculos listados no teste (clareira florida, lagoa, mirantes e as 2 clareiras pequenas, com centros e raios escritos no teste conforme a cena).
- [ ] `grep -rnE "RandomNumberGenerator|FastNoiseLite|randi\(|randf\(|randomize" scripts tools/kit` não retorna nada. Os shaders de água e cascata só usam `TIME` dentro de `floor(...)`.
- [ ] `build_kit.gd` rodado duas vezes dá `.res` idênticos (md5), incluindo as peças novas.
- [ ] `place_decor.gd` sem `--force` sai com código ≠ 0 e não altera o `map.tscn` (md5 igual).
- [ ] Desempenho, com a impressão do modo de captura a 1280×720: **≤ 500 draw calls** na câmera padrão e ≤ 700 no `--overview`. Registre no relatório o antes (cerca de 1000) e o depois.

**Por captura (Lead Project)**
- [ ] `012-default`: a arena, as duas reservas e a face externa sul inteiras, fora do HUD. As faces internas de pedra do muro norte e do degrau aparecem como faixas de pedra, não como linha. Há pelo menos um trecho de água do rio ou a ponte visível no terço de cima.
- [ ] `012-y90`: a lagoa com pedras de musgo e a árvore anciã. `012-y180`: a clareira florida e o mirante sudoeste. `012-y270`: a cascata caindo da borda até as nuvens.
- [ ] Nas 4 capturas de giro: o fundo é mata → borda da ilha → nuvens/céu, sem gramado indo até o horizonte e sem chão vazio. Pelo menos uma ilhota aparece em 2 das 4. A água e as nuvens não mostram grade nem repetição evidente.
- [ ] `012-escada`: o lance oeste lê como um caminho contínuo da trilha até a arena (lajes no patamar da crista e no do terraço, bochechas contínuas), sem muro atravessado e sem fresta.
- [ ] Trilhas (Fase 2): sem quadrado, emenda ou repetição visível. A ligação com o pé da escada e com a ponte é contínua.
- [ ] `012-ilha`: o contorno é orgânico (sem reta longa) e o fundo é cônico, com esporões, raízes e a cascata contínua do rio até as nuvens. A ilha lê como flutuante.
- [ ] Mata: grupos e clareiras evidentes, nenhuma copa encavalada em outra. As outonais e floridas aparecem como acentos, nunca como maioria num trecho.

**Sempre**
- [ ] Os dois comandos de validação do `CLAUDE.md` sem `ERROR`/`SCRIPT ERROR` nem warnings do nosso código. Todos os `tools/tests/test_*.gd` com código 0.
- [ ] Relatório com os arquivos criados, alterados e removidos, como testar (F5, giro, `--overview`), os números de desempenho e as limitações.

## Decisões do usuário (só se ele quiser mudar)
- Nenhuma bloqueia. Ele pode querer outro lado para a cascata (hoje é a leste) ou uma ponte de pedra no lugar da de madeira. Essas mudanças só trocam tabelas.
