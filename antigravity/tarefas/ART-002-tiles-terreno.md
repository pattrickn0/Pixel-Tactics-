# ART-002 — Tiles de terreno (32×32)

- **Prioridade:** alta
- **Depende de:** ART-001 (use o mockup como referência de cor e estilo. Se ainda não foi revisado, pode começar mesmo assim)
- **Tipo:** sprite utilizável (grid exato de 32 px)

## Objetivo
Tiles de chão que o gerador procedural vai combinar para montar o mapa.

## O que entregar
Um tile = **32×32 px**, seamless (encaixa com ele mesmo e com as variantes do mesmo tipo, sem emenda visível).

1. `art-002_grama-arena_a.png` … `_d.png`: 4 variantes de grama **clara** (arena). Pouco ruído, legível.
2. `art-002_grama-mata_a.png` … `_c.png`: 3 variantes de grama **escura** (chão sob a floresta).
3. `art-002_terra_a.png` … `_b.png`: 2 variantes de terra batida/trilha.
4. `art-002_decals.png`: sheet de detalhes soltos com fundo transparente, para espalhar por cima da grama: 4 tufos de grama, 3 flores (amarela, branca, rosa), 3 pedrinhas. Cada detalhe ocupa uma célula de **16×16** do sheet.
5. (opcional, bônus) `art-002_transicao-grama-terra.png`: sheet de transição grama-clara↔terra no formato de autotile **3×3 + 4 cantos internos** (grid de 32 px).

## Estilo
`docs/direcao-de-arte.md`: paleta da grama e da terra, luz cima-esquerda, sem anti-aliasing.

## Critérios de aceite
- [ ] Cada tile tem exatamente 32×32 px (ou o sheet é múltiplo exato de 32 / 16 para decals).
- [ ] Repetindo um tile 4×4 não aparece emenda nem padrão gritante.
- [ ] Grama da arena visivelmente mais clara que a grama da mata.
- [ ] Decals com fundo transparente.
- [ ] `entrega.md` preenchido, dizendo quais arquivos estão no grid exato e quais são só referência.
