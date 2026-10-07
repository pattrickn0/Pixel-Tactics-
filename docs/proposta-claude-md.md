# Proposta de alteração do `CLAUDE.md` (2026-10-06)

**Status:** aplicada no `CLAUDE.md` em 2026-10-06.

O Lead Project não edita o `CLAUDE.md`. Este arquivo traz o texto pronto para o usuário (ou a sessão principal, com o OK dele) colar.

Só mudam os trechos que conflitam com a nova direção:
- a linha de abertura;
- "Estilo visual";
- os itens "Arena", "Tudo é procedural" e "Relevo e degraus" de "Design do jogo";
- o resumo de "Direção de arte".

O resto não muda.

---

## 1. Linha 3 (abertura)

**Trocar:**
> Jogo **auto chess multiplayer** (até 8 jogadores, estilo TFT) em **2.5D estilo HD-2D fiel ao Octopath Traveler** (com identidade própria), **pixel art de 32 texels por unidade**, feito em **Godot 4.7 + GDScript**.

**Por:**
> Jogo **auto chess multiplayer** (até 8 jogadores, estilo TFT) em **2.5D: mundo 3D low-poly com texturas de pixel art minimalista** (alvo: `docs/reference/Gemini_Generated_Image_6oy5mo6oy5mo6oy5.jpg`), **pixel art de 32 texels por unidade**, feito em **Godot 4.7 + GDScript**.

## 2. Seção "Estilo visual" (inteira)

**Trocar a seção `## Estilo visual: HD-2D estilo Octopath (decidido pelo usuário)` inteira por:**

```markdown
## Estilo visual: 2.5D com pixel art minimalista (decidido pelo usuário em 2026-10-06)

- **Mundo 3D de verdade** (`Node3D`). **Todo o cenário é modelo 3D low-poly** gerado em código, com textura pixel art: chão, terraços e muros de pedra, escadas, pedras, **árvores, arbustos, troncos caídos, tocos, monólitos, capim, flores e cogumelos** (capim, flores e cogumelos em quads cruzados fixos, sem billboard).
- **Sprites 2D em pé** (`Sprite3D`, billboard só no eixo Y, vistos de frente): **só as peças**, no futuro.
- **Câmera orbital:** perspectiva com inclinação fixa, **sempre mirando o centro da arena**, sem pan. **Gira 360°** em torno do centro **só pelo teclado** (A/D); **Espaço** volta ao padrão. **Sem giro pelo mouse** (o mouse fica livre para as peças). **Zoom** com limite mínimo e máximo. Como a câmera gira, os modelos mostram todos os lados e a arte não traz luz lateral pintada. Árvores e monólitos entre a câmera e a arena ficam semitransparentes (dither), para a arena nunca ficar escondida.
- **Luz de dia claro e pós leve:** sol neutro levemente quente, com sombras reais em tudo (inclusive a sombra recortada das copas); sombras suaves esverdeadas; névoa azulada só ao fundo; bloom fraco; desfoque bem sutil só no fundo distante; **sem vinheta**; imagem limpa e nítida. Tudo via `WorldEnvironment`/`CameraAttributes`/`DirectionalLight3D` e shaders próprios, sem addons.
- **Escala única:** 1 tile = **1 unidade 3D** = **32 texels** em toda superfície (UV em unidades do mundo). 1 nível de degrau = 0,5 unidade = 16 texels. Peças usarão `pixel_size = 1.0 / 32.0`. Filtro **Nearest** em toda textura pixel art.
- **Pixel art minimalista:** chão com poucos tons (2 a 4), grandes áreas quase lisas e detalhe esparso; manchas de luz e bordas de terra recortadas em pixel, feitas por máscara no código (nunca seguindo o grid de tiles); muros de pedra seca com topo de musgo; árvores e props com mais detalhe que o chão. Sem contorno preto. Normal maps só em pedra e madeira, e fracos. Referência única: `docs/reference/Gemini_Generated_Image_6oy5mo6oy5mo6oy5.jpg`.
```

## 3. "Design do jogo": item "Arena"

**Trocar o item `- **Arena.** ...` e o subitem "Padrão atual: arena = clareira aberta..." por:**

```markdown
- **Arena.** Todo mapa tem uma **arena**: a área de luta, delimitada e visível. O que fica fora dela não é área de luta.
  - **Formato fixo, sem aleatoriedade:** retângulo no centro do mapa, cerca de 10% mais largo que alto (padrão 20 × 18 unidades). Mesmo formato e tamanho em toda seed.
  - **Reservas (bench estilo TFT):** nos dois lados compridos, fixas. Na câmera padrão, a minha reserva fica embaixo e a do inimigo em cima. Cada reserva é um terraço plano acima do chão da arena, com muro de pedra e musgo e escadas descendo para a arena. Peças na reserva não lutam. A mecânica de reserva (slots, regras) ainda será definida; o mapa só reserva o espaço e expõe os dados (`MapData.benches`).
  - **Lados curtos:** muro de pedra com musgo e anéis de terraço subindo para a floresta, fechando um anfiteatro retangular. As trilhas entram pelas escadas.
  - **Um único mapa por partida**, gerado pela seed da partida e usado por todos os jogadores em todas as rodadas. Não existe arena por jogador.
  - O mapa expõe a arena e as reservas nos dados (`MapData.arena_rect`, `MapData.benches`) e funções como `is_inside_arena(pos: Vector2) -> bool`, `clamp_to_arena(pos: Vector2) -> Vector2` e `get_height_at(pos: Vector2) -> float`.
```

E, no item "Posicionamento livre das peças", **trocar o subitem**
> Ainda a definir com o usuário (não implementar sem pedido): divisão da arena por time/lado, obstáculos dentro da arena, e se degrau alto bloqueia movimento ou se a peça sobe por rampa.

**por:**
> Ainda a definir com o usuário (não implementar sem pedido): regras da divisão da arena por time (o mapa já expõe as duas metades), obstáculos dentro da arena, se o degrau bloqueia movimento ou se a peça sobe pela escada, e as mecânicas de terreno alto (dano extra, cobertura, bloqueio de habilidade).

## 4. "Design do jogo": item "Tudo é procedural"

**Trocar:**
> - **Tudo é procedural, a cada partida:** relevo, degraus e escadas, formato da arena, muro, trilhas, vegetação e decoração são gerados a partir da seed da partida. Nenhum mapa é feito à mão nem fixo.

**Por:**
> - **Fixo e procedural.** São fixos (iguais em toda seed): o formato e o tamanho da arena, as reservas, os anéis e muros do anfiteatro e as escadas de entrada. São procedurais pela seed: o relevo dentro da arena, as manchas de terra, o relevo da floresta, as trilhas, a vegetação e a decoração em volta. Nenhum mapa é feito à mão.

## 5. "Design do jogo": item "Relevo e degraus"

**Trocar:**
> - **Relevo e degraus:** o terreno tem níveis de altura em degraus (incluindo dentro da arena). O grid de **tiles** (células de 1 unidade, textura 32×32) serve para gerar e desenhar o terreno e as alturas. Ele não limita onde as peças ficam.

**Por:**
> - **Relevo e degraus:** o terreno tem níveis de altura em degraus de 0,5 unidade. O grid de **tiles** (células de 1 unidade, textura 32×32) serve para gerar e desenhar o terreno e as alturas. Ele não limita onde as peças ficam.
>   - **Arena verticalizada e justa:** dentro da arena, o relevo é procedural, em terraços de pedra com 2 a 3 níveis acima do chão e escadas para subir. Tem **um morro central** compartilhado ou **um morro em cada metade**. As duas metades (a minha, perto da minha reserva, e a do inimigo) são **equivalentes por construção**: o gerador cria uma metade e copia para a outra por rotação de 180° em torno do centro. Mesma área por nível, mesma altura em pontos correspondentes, e o chão liga as duas reservas.
>   - O mapa só expõe a altura (`get_height_at`) e as escadas como dados. Dano por terreno alto, cobertura e bloqueio de habilidade são mecânicas futuras.

## 6. Seção "Direção de arte" (resumo no fim)

**Trocar os 3 itens do resumo por:**

```markdown
- 2.5D: cenário todo em modelos 3D low-poly com textura pixel art de 32 texels por unidade (o `artist` faz texturas, normal maps de pedra e madeira e cartões; o `developer` faz forma, UV, materiais e as máscaras do chão); só as peças são sprites em pé. Filtro **Nearest**.
- Pixel art minimalista no chão (poucos tons, detalhe esparso, bordas orgânicas recortadas em pixel feitas por máscara no código); detalhe maior nas árvores, nos muros e nos props. Dia claro, sombras suaves esverdeadas, névoa azulada ao fundo, pós leve.
- Placeholders gerados em código seguem a paleta. Nada de ruído por pixel nem de cor chapada sem forma.
```
