# 002 — Mapa menor e mais bonito (Estilo orgânico e denso)

## Objetivo
Reduzir o tamanho do mapa procedual gerado pela metade (para uma área de 32x32), mantendo o formato orgânico da arena, e melhorar substancialmente a aparência visual (densidade da vegetação, formato do relevo e texturas) para que se aproxime mais do estilo definido na direção de arte (mata densa, detalhes orgânicos).

## Escopo
- Alterar o `map_size` padrão em `scripts/map/map_gen_config.gd` de `Vector2i(64, 64)` para `Vector2i(32, 32)`.
- Ajustar proporcionalmente as configurações de tamanho atreladas ao tamanho do mapa (ex: `raised_region_min_size`, `raised_region_max_size`, largura de trilhas, quantidades de decorações `ruin_patch_count`, `monolith_count`) para que caibam bem na nova área de 32x32.
- Aumentar a densidade visual e a sobreposição da floresta fora da arena. Revisar se o `tree_spacing` (atualmente 1.0) está impedindo a mata de parecer densa ("bolhas sobrepostas" como na direção de arte).
- Melhorar a forma com que as texturas do chão (grama da arena vs. mata) e as lajotas são mescladas (blend), usando ruído (`ground_blend_noise_frequency`) para que as transições pareçam mais naturais e orgânicas, menos "quadradas" ou artificiais.
- Garantir que a área ao sul (entre a câmera e a arena) não tenha árvores altas que bloqueiem a visão, ajustando o `south_low_depth` se necessário.
- (Opcional, se precisar) Atualizar o script de placeholders para gerar texturas com as cores exatas da direção de arte, caso a grama atual esteja muito uniforme ou fora da paleta (usar as 4 variantes sugeridas no `docs/direcao-de-arte.md`).

## Fora de escopo
- Refazer totalmente o sistema de mesh (TerrainMeshBuilder/RockMeshBuilder) do zero. Apenas ajustes nos parâmetros e algoritmos de geração de ruído/posicionamento.
- Integrar artes finais (sprites do artista Antigravity) — usaremos e melhoraremos os placeholders atuais em GDScript.
- Adicionar novos tipos de terreno ou biomas que não estejam no documento base.

## Design técnico sugerido
- Edite `scripts/map/map_gen_config.gd` para definir os novos valores padrão (como `map_size = Vector2i(32, 32)`).
- Revise a lógica de `map_generator.gd` no que tange o espaçamento de decorações (Poisson Disk/Grid) se a floresta estiver rala.
- Certifique-se de que a proporção da arena (`arena_fraction_min` e `max`) ainda funcione bem para um mapa menor.
- Valide se o shader/gerador de terreno está aplicando o filtro Nearest corretamente e mesclando os tiles.

## Direção de arte
O mapa deve perder a aparência "vazia e bloco-por-bloco" mostrada nas imagens de debug e ganhar a cara de "mata fechada abraçando uma clareira iluminada" (referência `docs/reference/ref-floresta-vila.png` e clareira). A vegetação de fora deve parecer uma massa contínua, enquanto a arena foca nos tufos e flores espalhadas.

## Critérios de aceite
- [ ] O mapa gerado pela cena tem 32x32 de tamanho.
- [ ] A arena é gerada corretamente no centro, com formato orgânico e com o muro/degrau em volta.
- [ ] A mata ao redor (fora da arena) parece mais fechada e densa que antes (menos buracos), sem bloquear a visão frontal (sul).
- [ ] A proporção de decorações (ruínas, monólitos) continua equilibrada para o novo tamanho (sem o mapa ficar lotado).
- [ ] O projeto passa na validação headless sem erros de parse ou de execução.

## Revisão (Lead Project, 2026-10-04)

**Veredito: AJUSTES.** As correções estão em `docs/specs/003-correcoes-pos-gemini.md`.

A entrega foi feita fora do fluxo, pelo Gemini direto no código (commits `d255b03` e `98205b5`), sem relatório do developer e sem screenshots. Ela também trouxe mudanças fora do escopo desta spec:
- já decididas pelo usuário: câmera 360°, `LEVEL_HEIGHT = 0.5`, ruínas fora da arena;
- sem spec: regiões elevadas em bolha, chanfro nas quinas do relevo e árvores escaladas 1,6×.

| Critério | Status | Evidência |
|---|---|---|
| Mapa 32×32 | OK | `MapGenConfig.map_size = Vector2i(32, 32)`; o mapa gerado tem `size = (32, 32)`. |
| Arena no centro, orgânica, com muro/degrau em volta | PARCIAL | A arena passa nos testes de caixa, conexão, buracos e anel. Mas: (1) blocos de muro soltos na boca das trilhas em 69 das seeds 1–100 (spec 003, A5); (2) terraços com partes de 1–2 células, que violam o bloco 3×3 da spec 001, em 46 das seeds 1–100 (A1); (3) escadas em só 2 das seeds 1–20 (A2). |
| Mata mais fechada, sem bloquear a visão frontal (sul) | OK | Densidade maior (`tree_spacing` 0,6) e faixa sul respeitada em yaw 0 (o teste da faixa sul passa). Com a câmera 360°, a mata dos outros lados tapa a arena: isso não é critério desta spec e é tratado pela 006 (dither de oclusão). |
| Decoração equilibrada (ruínas, monólitos) | FALHA | Ruínas desligadas na config (decisão do usuário, OK). Monólitos: `monolith_min_spacing` caiu para 3,0, quando a regra da spec 001 é 6. O teste falha nas seeds 13 (4,53) e 14 (3,87) (003, A4). |
| Validação headless sem erros | PARCIAL | `--editor --quit` e `--quit-after 300` limpos. `test_main_scene.gd` passa (21). `test_map_generation.gd` falha em 3 de 32, e a definição de pronto exige os testes passando. |
