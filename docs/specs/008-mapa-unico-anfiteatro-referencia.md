# 008 — Mapa Único Canônico: Anfiteatro Florestal Fiel 1:1 à Referência

**Status:** Em implementação (diretriz do usuário em 2026-10-07).
**Substitui:** Geração procedural aleatória da arena e relevos elevados no meio da arena.
**Alvo visual:** `docs/reference/Gemini_Generated_Image_6oy5mo6oy5mo6oy5.jpg`.

## 1. Visão Geral e Decisões de Arquitetura

O usuário definiu:
1. **Fim do mapa procedural aleatório:** o jogo passa a ter um **mapa único canônico**, esculpido à mão / com layout fixo definitivo, reproduzindo 1:1 o anfiteatro da imagem de referência.
2. **Arena plana (sem relevos no meio):** toda a área interna de combate possui altura única (`height = 0`), eliminando os morros, degraus e plataformas centrais que dificultavam o combate e destoavam da clareira plana da referência.
3. **Fidelidade artística 1:1 com a imagem de referência:**
   - Anfiteatro em formato octogonal / arredondado com dois anéis de terraços de pedra em torno da clareira central.
   - Clareira de terra central orgânica com bordas recortadas em pixel, pequenas ilhas de grama internas e aro de grama clara.
   - Muros de pedra seca com topo de musgo e musgo caindo pelas juntas.
   - Três conjuntos de escadarias integrados nas paredes:
     - Entrada principal no sudoeste (inferior-esquerda) com calçamento de lajes irregulares.
     - Saída no nordeste (superior-direita) conectando à trilha da floresta.
     - Escada no terraço superior-esquerdo.
   - Props fiéis à referência:
     - Troncos caídos cobertos de musgo deitados sobre os terraços e rente aos muros.
     - Bancos e caixotes de madeira no terraço superior de fundo.
     - Cogumelos coloridos (azuis e rosas) agrupados nas bases dos muros e árvores.
     - Arbustos e flores silvestres coloridas espalhadas.
   - Floresta densa circundante: coníferas em camadas e folhosas em copas volumosas, com primeiro plano emoldurando a tela e fundo suave com névoa azulada.

## 2. Estrutura do Layout Canônico

- **Dimensões do mapa:** Grade 44 × 44 células (1 unidade 3D por célula).
- **Centro da arena:** `Vector2(22.0, 22.0)`.
- **Níveis de Altura:**
  - `Level 0` (Y = 0.0): Chão da arena de combate. Totalmente plano.
  - `Level 1` (Y = 0.5): Primeiro anel de arquibancada / terraço do anfiteatro (largura ~2 a 3 células).
  - `Level 2` (Y = 1.0): Segundo terraço / solo da floresta envolvente.
  - `Level 3+`: Elevação suave natural da floresta ao fundo.

## 3. Escadas e Acessos
- Escada Sudoeste: largura 3 unidades, descendo do calçamento exterior (nível 2) para o terraço (nível 1) e depois para o chão da arena (nível 0).
- Escada Nordeste: largura 3 unidades, subindo do chão da arena para o terraço e para a trilha da floresta.
- Escada Noroeste: conectando o terraço inferior ao superior.

## 4. Texturização do Terreno
- Grama da arena: `#5B9C47` dominante, com variações suaves.
- Clareira de terra central: Forma orgânica centrada em (22, 22), raio aproximado de 5 a 6 unidades, cor base `#C0AE71`, com ilhotas de grama e aro `#73A949`.
- Calçamento: Lajes irregulares em `stone_path` conectando as escadas aos limites do mapa.
- Muros: `wall_face` nas paredes verticais, `wall_top` com musgo espesso na borda superior, cartões `moss_fringe` suspensos nas quinas.
