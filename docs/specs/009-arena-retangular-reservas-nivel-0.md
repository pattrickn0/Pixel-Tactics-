# 009 — Arena retangular com reservas no nível 0 e anel de muros

> **SUBSTITUÍDA por 011/A06** (2026-10-07): mapa feito à mão com kit modular, reservas no terraço, arte sem variação procedural. Mantida só como histórico.

**Substitui (em parte):** o layout octogonal de `_build_fixed_layout` (spec 008, feito fora do fluxo). Mantém o resto da 008.
**Decisões do usuário (2026-10-07):** arena, reservas e **todo o exterior** (floresta, trilhas, calçamento) no nível 0 (altura 0,0); **só o anel de muros** que cerca arena + reservas fica acima (níveis 1 e 2), com face de pedra dos dois lados; forma retangular do `CLAUDE.md`; piso da reserva em tábuas de madeira mel (A04, aprovada); **sem escada atrás das reservas** (só as duas dos lados curtos, atravessando o anel). Não existe mais "exterior no nível 2".
**Depende de:** `A04-piso-reserva.md` (aprovada para gerar; texturas `bench_floor_*`).

## Objetivo
O jogador vê uma arena retangular plana de grama no centro, com uma faixa de reserva de tábuas colada a cada lado comprido (a minha embaixo, a do inimigo em cima), tudo no nível 0. Em volta de arena + reservas corre um anel retangular de muro de pedra com musgo e terraço no topo, que sobe da arena e desce de novo para a floresta, também no nível 0. Duas escadas, uma em cada lado curto, atravessam o anel.

## Escopo
- **Layout fixo (sem RNG), mapa 44 × 44, centro (22, 22).** Coordenadas em células (x, z), retângulos semiabertos:
  - Arena: `Rect2(12, 13, 20, 18)` (células x 12–31, z 13–30), nível 0.
  - Reserva sul (time 0, embaixo na câmera padrão): `Rect2(12, 31, 20, 3)` (z 31–33), nível 0.
  - Reserva norte (time 1): `Rect2(12, 10, 20, 3)` (z 10–12), nível 0.
  - **Piso interno** = arena + reservas = `Rect2(12, 10, 20, 24)` (x 12–31, z 10–33), nível 0.
  - **Anel de muros, largura 4** = `Rect2(8, 6, 28, 32)` menos o piso interno, perfil simétrico 1-2-2-1:
    - degrau interno, nível 1 (0,5): `Rect2(11, 9, 22, 26)` menos o piso interno (x = 11 ou 32, z 9–34; z = 9 ou 34, x 11–32);
    - crista, nível 2 (1,0): `Rect2(9, 7, 26, 30)` menos `Rect2(11, 9, 22, 26)` (faixa de 2 células: x 9–10 e 33–34; z 7–8 e 35–36);
    - degrau externo, nível 1 (0,5): `Rect2(8, 6, 28, 32)` menos `Rect2(9, 7, 26, 30)` (x = 8 ou 35; z = 6 ou 37).
  - **Exterior** (fora de `Rect2(8, 6, 28, 32)`): nível 0, sem relevo. O relevo de floresta atual (níveis ≥ 2 fora do anfiteatro) sai.
  - Muro de pedra com topo de musgo em **toda** borda de nível, nos quatro lados: faces viradas para dentro (piso interno → degrau interno → crista) e para fora (exterior → degrau externo → crista).
- **`MapData.benches`:** dois `MapBench` com `level = 0`:
  - sul: `terrace_rect = Rect2(12, 31, 20, 3)`, `rect = Rect2(12.5, 31.0, 19.0, 2.5)`;
  - norte: `terrace_rect = Rect2(12, 10, 20, 3)`, `rect = Rect2(12.5, 10.5, 19.0, 2.5)`.
  - A área útil encosta na arena e tem margem de 0,5 junto ao muro e às pontas. Arena e reserva são disjuntas (`_inside_rect` é semiaberto).
- **Visual da reserva:** novo `Ground.BENCH` (ou nome equivalente) em `MapData.Ground`, com `bench_floor_0`/`_1` + `_n` da A04 (UV em unidades do mundo, tábuas paralelas ao eixo X). Limite arena/reserva é reto em z = 13 e z = 31.
- **Escadas** (só duas, largura 3; o layout é invariante à rotação de 180° em torno de (22, 22), célula (x, z) → (43 − x, 43 − z)):
  - oeste: células x 8–11, z 24–26; sobe do exterior (x 7) até a crista e desce até a arena (x 12): x 8 = 0→1, x 9 = 1→2, x 10 = 2→1, x 11 = 1→0;
  - leste (rotação da oeste): células x 32–35, z 17–19, mesmo perfil espelhado (x 35 = 0→1 vindo de x 36, …, x 32 = 1→0 chegando em x 31);
  - **nenhuma escada atrás das reservas:** o anel ao norte e ao sul é contínuo.
  - Trilhas de pedra (nível 0) chegam ao pé de cada escada pelo lado de fora (oeste em x 7, leste em x 36) e seguem até a borda do mapa. Remover trilhas que levavam a escadas atrás das reservas.
- **Config:** `MapGenConfig` com `arena_floor_level = 0`, `bench_depth = 3`, `ring_inner_step_width = 1`, `ring_crest_width = 2`, `ring_outer_step_width = 1`, `stair_width = 3`. Remover/renomear `bench_level_offset`, `ring1_width`, `ring2_width` se ficarem sem sentido.
- Remover o código octogonal (`dx + dz`, `in_tier1/in_tier2`, coordenadas mágicas de escada) e derivar o layout da config, não de números soltos.
- Manter da 008 o que não conflita: clareira de terra orgânica em (22, 22) dentro da arena (sem invadir as reservas), props, troncos, cogumelos, vegetação, trilhas, `forest_dist`, floresta em volta (agora no nível 0).
- **Testes em `tools/tests/`:** atualizar as verificações que assumiam reserva acima da arena, exterior elevado ou layout octogonal (ex.: `test_arena_layout.gd` ~100–131, `test_map_generation.gd` ~130–170) e acrescentar os critérios abaixo.

## Fora de escopo
- **Continuidade visual** (transição de chão por máscara no shader, muro com textura contínua, cantos que se emendam): spec **010**. Aqui o muro pode usar o material atual.
- **Árvores novas:** spec própria, depois da 010. Aqui ficam as árvores atuais.
- Mecânica de reserva (slots, regras), peças, combate, rede.
- Gerar arte (é a A04; o developer só integra `bench_floor_*` quando existirem).
- Câmera, luz, pós ou shaders (exceto o mínimo para `Ground.BENCH`).
- Obstáculos ou relevo dentro da arena ou das reservas.

## Design técnico sugerido
- `MapGenerator._new_context`: `ctx.inner` = arena crescida de `bench_depth` em z; `ctx.ring_in = inner.grow(ring_inner_step_width)`, `ctx.ring_crest = ring_in.grow(ring_crest_width)`, `ctx.ring_out = ring_crest.grow(ring_outer_step_width)`.
- `_build_fixed_layout`: nível 0 em tudo; 1 em `ring_in − inner` e `ring_out − ring_crest`; 2 em `ring_crest − ring_in`. Cria os `MapBench` a partir de `ctx.arena` e `bench_depth`, e as escadas com `_make_stair` (sobe + desce) simétricas por `_rotate_cell`.
- `TerrainMeshBuilder`: as faces de muro já saem de toda diferença de nível entre vizinhas; garantir que isso vale para descidas para fora (face externa).
- `MapData`, `MapBench`, `get_height_at`, `is_inside_arena`, `clamp_to_arena`, `is_inside_bench`, `clamp_to_bench` não mudam de assinatura.
- `ArtLibrary`: só o necessário para `Ground.BENCH` usar `bench_floor_0`/`_1` (variante por célula com a seed) e `_n`, filtro Nearest.

## Direção de arte
`docs/direcao-de-arte.md` e `docs/reference/Gemini_Generated_Image_6oy5mo6oy5mo6oy5.jpg`: grama da arena lisa com a clareira de terra; reserva em tábuas de madeira mel (`bench_floor_*`, A04; 32 texels/unidade, Nearest); anel de pedra seca com topo de musgo, face de pedra visível por dentro e por fora; floresta e trilhas no nível 0 em volta. Sem contorno preto.

## Critérios de aceite
- [ ] `MapData.arena_rect == Rect2(12, 13, 20, 18)` e `arena_center == Vector2(22, 22)` para seeds 1–20.
- [ ] `arena_mask` tem exatamente 360 células, todas dentro de `arena_rect`.
- [ ] `MapData.benches` tem 2 itens: time 0 com `rect == Rect2(12.5, 31, 19, 2.5)` e time 1 com `rect == Rect2(12.5, 10.5, 19, 2.5)`, ambos com `level == 0`; o do time 1 é a rotação de 180° do time 0.
- [ ] `get_height_at(p) == 0.0` para 1000 pontos aleatórios em `arena_rect`, 1000 em cada `bench.terrace_rect` e 1000 no exterior a ≥ 0,5 de `Rect2(8, 6, 28, 32)` (seeds 1–20).
- [ ] `get_height_at(p) > 0.0` só em pontos dentro de `Rect2(8, 6, 28, 32)` e fora do piso interno (anel e escadas); nenhum ponto do mapa passa de 1,0.
- [ ] Níveis por célula exatamente como no Escopo (degrau interno 1, crista 2, degrau externo 1, resto 0), exceto células de escada.
- [ ] Muro com face dos dois lados: em cada um dos 4 lados do anel, fora das escadas, há borda de nível 0→1 virada para o piso interno e borda 0→1 virada para o exterior, e as faces correspondentes existem na malha (normais apontando para dentro e para fora).
- [ ] Células com `Ground.BENCH` = exatamente as dos dois `terrace_rect`; nenhuma dentro da arena; material com `bench_floor_*` (não `stone_path_*`).
- [ ] Exatamente 2 escadas, nas células do Escopo, cada uma subindo do exterior (nível 0) à crista (nível 2) e descendo à arena (nível 0); nenhuma célula de escada com x em [12, 32) e z < 10 ou z ≥ 34; layout fixo (níveis, escadas, máscaras) invariante à rotação de 180°.
- [ ] Uma trilha encosta no pé externo de cada escada (células (7, 24–26) e (36, 17–19) são trilha).
- [ ] `grep -nE "dx \+ dz|octog|in_tier" scripts/map/` não retorna nada.
- [ ] `is_inside_arena`, `clamp_to_arena`, `is_inside_bench`, `clamp_to_bench` passam nos testes com os novos retângulos; arena e reservas são disjuntas.
- [ ] Mesma seed gera `fingerprint()` idêntico em duas gerações.
- [ ] Os dois comandos de validação do `CLAUDE.md` rodam sem `ERROR`/`SCRIPT ERROR` nem warnings do nosso código.
- [ ] Todos os `tools/tests/test_*.gd` saem com código 0.
- [ ] Captura (F5 ou `measure_capture.gd`) na câmera padrão mostra arena de grama, reservas de tábuas embaixo e em cima, anel de muro com face interna e externa visível, floresta no nível 0 em volta, escadas só nos lados curtos; anexar no relatório.
