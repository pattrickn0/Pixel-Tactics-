# ART-001 — Mockup do mapa com arena

- **Prioridade:** alta
- **Depende de:** nada
- **Tipo:** referência visual (não precisa ser sprite utilizável)

## Objetivo
Definir o visual alvo de um mapa gerado: a **arena** de planície no centro e a **floresta** ao redor, vista de cima. Este mockup vira o "norte" visual para os tiles (ART-002), a vegetação (ART-003) e o gerador de mapa em código.

## O que entregar
1. `art-001_mockup-mapa.png`: uma tela inteira de jogo, proporção 16:9, pensada como **640×360 px em pixel art** (pode gerar maior, desde que a escala seja inteira e cada "pixel" seja um bloco uniforme).
   - Centro: arena de grama clara, aberta, ocupando ~50–60% da largura e ~60–70% da altura, com formato **orgânico** (não um retângulo perfeito).
   - Borda da arena visível e diferente do resto: faixa de terra batida, pedras baixas ou ruína de pedra baixa (escolha uma e use com consistência).
   - Dentro da arena: só detalhes pequenos (tufos, flores, pedrinhas). Nenhum obstáculo grande.
   - Fora da arena: floresta densa de copas arredondadas sobrepostas (como em `docs/reference/ref-floresta-vila.png`), arbustos, algumas pedras, e uma trilha de terra entrando no mapa.
   - Sem personagens, sem UI, sem texto.
2. `art-001_mockup-mapa_variante.png`: o mesmo conceito com outro formato de arena e outra distribuição de floresta, para mostrar que cada partida gera um mapa diferente.

## Estilo
Siga `docs/direcao-de-arte.md` (paleta, luz cima-esquerda, sem anti-aliasing). Grid de 32 px: árvores grandes com ~64–96 px de largura nessa escala.

## Critérios de aceite
- [ ] Arena claramente distinguível do cenário em menos de 1 segundo de olhada.
- [ ] Borda da arena visível ao redor de todo o contorno.
- [ ] Paleta compatível com `docs/direcao-de-arte.md`. Sem gradientes suaves nem blur.
- [ ] Duas variantes com formatos de arena diferentes.
- [ ] `entrega.md` preenchido.
