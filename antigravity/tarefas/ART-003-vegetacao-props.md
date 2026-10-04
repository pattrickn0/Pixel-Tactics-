# ART-003 — Vegetação e props

- **Prioridade:** média
- **Depende de:** ART-001 (referência de estilo)
- **Tipo:** sprite utilizável (fundo transparente, alinhado ao grid de 32 px)

## Objetivo
Objetos que o gerador espalha pela floresta e pela borda da arena.

## O que entregar
Todos com **fundo transparente**, cada objeto centralizado numa célula múltipla de 32 px. A **sombra no chão** vai num arquivo separado, para o código poder desenhar sombra e objeto em camadas diferentes.

1. `art-003_arvore-grande_a.png` … `_c.png`: 3 árvores grandes, célula de **96×96**. Copa arredondada em "bolhas", 3–4 tons, tronco visível embaixo.
2. `art-003_arvore-pequena_a.png` … `_b.png`: 2 árvores pequenas, célula de **64×64**.
3. `art-003_arbusto_a.png` … `_c.png`: 3 arbustos, célula de **32×32**.
4. `art-003_pedra_a.png` … `_c.png`: 2 pedras pequenas (célula 32×32) + 1 pedra grande (célula 64×32).
5. `art-003_borda-arena.png`: sheet com as peças da borda da arena, no estilo escolhido no ART-001 (ex.: pedras baixas ou blocos de ruína). Pelo menos 4 peças de 32×32 que funcionem lado a lado.
6. `art-003_sombras.png`: sombras correspondentes às árvores grandes e pequenas (forma elíptica, cor escura da paleta), mesmas dimensões de célula.

## Estilo
`docs/direcao-de-arte.md` e `docs/reference/ref-floresta-vila.png` para as copas. Luz cima-esquerda, contorno escuro colorido (nunca preto puro).

## Critérios de aceite
- [ ] Dimensões de célula exatamente as pedidas.
- [ ] Fundo transparente (ou `#FF00FF` registrado em Limitações).
- [ ] Árvores lado a lado parecem da mesma família, mas com silhuetas diferentes.
- [ ] Sombras em arquivo separado.
- [ ] `entrega.md` preenchido.
