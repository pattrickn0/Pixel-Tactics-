# Pixel Chess — Regras do Projeto

Jogo **auto chess multiplayer** (até 8 jogadores, estilo TFT) em **2.5D: mundo 3D low-poly com texturas de pixel art minimalista** (alvo: `docs/reference/Gemini_Generated_Image_6oy5mo6oy5mo6oy5.jpg`), **pixel art de 32 texels por unidade**, feito em **Godot 4.7 + GDScript**.
O mapa é **um só, feito à mão** (fiel à referência), igual em toda partida: nada procedural no mapa nem na arte. Fase atual: **mapa feito à mão** com um kit de peças modulares montado numa cena (spec 011, arte A06).

## Estilo visual: 2.5D com pixel art minimalista (decidido pelo usuário em 2026-10-06)

- **Mundo 3D de verdade** (`Node3D`). **Todo o cenário é modelo 3D low-poly** de um **kit de peças** (`scenes/kit/`, malha gerada por script a partir de tabelas explícitas, sem ruído nem sorteio) montado à mão em `scenes/map.tscn`, com textura pixel art: chão, terraços e muros de pedra, escadas, pedras, **árvores 3D de verdade (copa em lóbulos volumosos, conífera em andares serrilhados; nada de cartão chapado), arbustos, troncos caídos, tocos, capim, flores e cogumelos** (capim, flores e cogumelos em quads cruzados fixos, sem billboard).
- **Sprites 2D em pé** (`Sprite3D`, billboard só no eixo Y, vistos de frente): **só as peças**, no futuro.
- **Câmera orbital:** perspectiva com inclinação fixa, **sempre mirando o centro da arena**, sem pan. **Gira 360°** em torno do centro **só pelo teclado** (A/D); **Espaço** volta ao padrão. **Sem giro pelo mouse** (o mouse fica livre para as peças). **Zoom** com limite mínimo e máximo. Como a câmera gira, os modelos mostram todos os lados e a arte não traz luz lateral pintada. Árvores e monólitos entre a câmera e a arena ficam semitransparentes (dither), para a arena nunca ficar escondida.
- **Luz de dia claro e pós leve:** sol neutro levemente quente, com sombras reais em tudo (inclusive a sombra recortada das copas); sombras suaves esverdeadas; névoa azulada só ao fundo; bloom fraco; desfoque bem sutil só no fundo distante; **sem vinheta**; imagem limpa e nítida. Tudo via `WorldEnvironment`/`CameraAttributes`/`DirectionalLight3D` e shaders próprios, sem addons.
- **Escala única:** 1 tile = **1 unidade 3D** = **32 texels** em toda superfície (UV em unidades do mundo). 1 nível de degrau = 0,5 unidade = 16 texels. Peças usarão `pixel_size = 1.0 / 32.0`. Filtro **Nearest** em toda textura pixel art.
- **Pixel art minimalista:** chão com poucos tons (2 a 4), grandes áreas quase lisas e detalhe esparso; manchas de grama, terra e trilha com bordas orgânicas recortadas em pixel, **desenhadas à mão** (decalques planos com alfa recortado, alinhados ao texel; nunca seguindo o grid de tiles, nunca por ruído); muros de pedra seca com topo de musgo; árvores e props com mais detalhe que o chão. Sem contorno preto. Normal maps só em pedra e madeira, e fracos. Referência única: `docs/reference/Gemini_Generated_Image_6oy5mo6oy5mo6oy5.jpg`.

## Design do jogo (regras fixas)

- **Mapa feito à mão (decidido em 2026-10-07).** Um único mapa, fiel à referência, montado à mão com o kit em `scenes/map.tscn`; o usuário ajusta arrastando no editor. Sem seed, sem gerador, sem botão "Gerar mapa". A seed (`int`) fica só para o RNG da partida (combate, loja), no futuro.
- **Arena.** Todo mapa tem uma **arena**: a área de luta, delimitada e visível. O que fica fora dela não é área de luta.
  - **Formato fixo, sem aleatoriedade:** retângulo de **20 × 18** unidades, plano, no nível 0, centrado na origem do mundo (`Rect2(-10, -9, 20, 18)`). A mancha de terra no meio é desenhada à mão.
  - **Reservas (bench estilo TFT):** nos dois lados compridos, fixas. Na câmera padrão, a minha reserva fica embaixo e a do inimigo em cima. Cada reserva fica **no terraço do anel** (decidido pelo usuário em 2026-10-07): a faixa de grama entre o degrau baixo junto da arena e o muro alto, como na referência; **nível 1 (altura 0,5)**, terraço de **3 unidades** de largura (decidido em 2026-10-08). Sem piso de tábuas. Peças na reserva não lutam. A mecânica de reserva (slots, regras) ainda será definida; o mapa só reserva o espaço e expõe os dados (`MapData.benches`).
  - **Anel do anfiteatro (perfil da 011):** arena (0,0) → degrau baixo de 0,5 → terraço (0,5, largura 3, com as reservas nos lados compridos) → muro alto de pedra com musgo, crista em **1,0** (face interna de 0,5, face externa de 1,0; decidido em 2026-10-08) → exterior. **Fora do anel, o chão volta ao nível 0**, o mesmo da arena. Duas escadas, nos lados curtos, atravessam o anel do exterior até a arena; as trilhas chegam nelas.
  - **O mesmo mapa em toda partida**, usado por todos os jogadores em todas as rodadas. Não existe arena por jogador.
  - O mapa expõe a arena e as reservas nos dados (`MapData.arena_rect`, `MapData.benches`), montados a partir de marcadores na cena do mapa (não de um gerador), e funções como `is_inside_arena(pos: Vector2) -> bool`, `clamp_to_arena(pos: Vector2) -> Vector2` e `get_height_at(pos: Vector2) -> float`.
- **Posicionamento livre das peças.** Diferente dos auto chess tradicionais, **não existe grid de posicionamento**: a peça pode ser colocada em **qualquer ponto dentro da arena** (posição contínua `Vector2` no plano do chão, eixos X/Z do 3D; a altura vem do terreno), mas **nunca fora dela**. Arrastar para fora → a peça é limitada à borda (clamp) ou o posicionamento é recusado.
  - As peças têm um raio de colisão e não se sobrepõem.
  - Ainda a definir com o usuário (não implementar sem pedido): regras da divisão da arena por time (o mapa já expõe as duas metades), obstáculos dentro da arena, se o degrau bloqueia movimento ou se a peça sobe pela escada, e as mecânicas de terreno alto (dano extra, cobertura, bloqueio de habilidade).
- **Arena plana (sem alturas no meio):** Dentro da arena, todo o chão de combate fica no nível base (nível 0 / altura 0,0), sem morros ou plataformas elevadas no meio. O relevo (degrau baixo, terraço e muro alto) fica exclusivamente no anel que circunda a arena; o exterior (floresta, trilhas, plateia) também é nível 0.
- **Continuidade visual (decidido em 2026-10-07):** nada de "textura colada em bloco". Grama com UV de mundo (sem emenda entre peças), manchas e bordas por decalques desenhados à mão e alinhados ao texel, muros com textura contínua ao longo do trecho (UV de mundo), pedras de contorno irregular no capeamento e quinas fechadas com amarração. Não usar render 3D em baixa resolução (recusado pelo usuário).

## Multiplayer (estrutura; rede só na fase própria)

- Até **8 jogadores por partida, estilo TFT**. Agora: **um jogador hospeda** (multiplayer nativo do Godot, `ENetMultiplayerPeer` + RPC, sem addons). No futuro distante: servidor dedicado headless rodando o mesmo código.
- **Autoritativo decide tudo.** O host (ou, offline, o "host local") valida e aplica; clientes só enviam **intenções** (ex.: "posicionar peça em X") e mostram o resultado.
- **Lógica separada do visual.** O estado e as regras da partida vivem em classes sem visual (`RefCounted`/`Resource`, em `scripts/match/` e `scripts/map/`). Nós visuais só leem esse estado e reagem a sinais. Nenhuma regra de jogo dentro de um nó visual.
- **Mapa igual para todos sem sincronizar.** Todo cliente carrega a mesma cena `scenes/map.tscn`; o `MapData` é **função pura dessa cena** (sem depender de frame, tempo, ordem de nós ou estado global).
- **Combate roda só no autoritativo**; os clientes recebem estado/eventos. Não usar lockstep (float não é determinístico entre máquinas). Mesmo assim, usar RNG com seed para dar para reproduzir.
- **Offline = host local.** O jogo sem rede passa pelo mesmo caminho de intenção → validação → estado, para a rede entrar depois sem reescrita.
- Não escrever código de rede antes da spec de multiplayer.

## Equipe de agentes

O trabalho é feito por quatro papéis do Claude, mais um colaborador externo (pausado). As definições ficam em `.claude/agents/`.

| Papel | Arquivo | Responsabilidade | Edita código? |
|---|---|---|---|
| **Lead Orchestrator** | `lead-orchestrator.md` | Recebe o pedido do usuário, divide em tarefas, delega, integra e reporta | Não |
| **Lead Project** | `lead-project.md` | Escreve specs e tarefas de arte, define critérios de aceite, revisa entregas | Não (só `docs/` e `antigravity/tarefas|revisoes/`) |
| **Developer** | `developer.md` | Implementa a spec, integra artes aprovadas, valida no Godot | Sim |
| **Artist** | `artist.md` | Produz a arte do jogo (texturas, normal maps e cartões) com scripts geradores em GDScript | Só `tools/art/`, `assets/textures/`, `assets/sprites/`, `docs/art-preview/` |
| **Artista externo (Antigravity / Gemini)**: **pausado, não edita o projeto** | `antigravity/INSTRUCOES.md` | Gerava artes de referência. Hoje toda a arte do jogo é do `artist` | Nada no projeto. Se o usuário reativar: só `antigravity/entregas/` e `antigravity/ferramentas/` |

**Sessão principal = Lead Orchestrator.** Se você é a sessão principal (não foi invocado como subagente), siga `.claude/agents/lead-orchestrator.md`. Subagentes não criam outros subagentes.

### Fluxo padrão (código)

1. **Orchestrator** entende o pedido. Se faltar uma decisão que só o usuário pode tomar, pergunta.
2. **Lead Project** escreve a spec em `docs/specs/NNN-nome.md` (objetivo, escopo, fora de escopo, critérios de aceite).
3. **Developer** implementa a spec e roda a validação.
4. **Lead Project** revisa a entrega contra os critérios de aceite → `APROVADO` ou `AJUSTES` (lista objetiva).
5. Se `AJUSTES`, volta ao passo 3 (máx. 2 ciclos; depois o Orchestrator decide ou pergunta ao usuário).
6. **Orchestrator** reporta ao usuário: o que foi feito, como testar, pendências.

Tarefas triviais (renomear, ajustar uma cor, corrigir typo) podem pular a spec: o Orchestrator delega direto ao Developer.

### Fluxo de arte (agente `artist`)

1. **Lead Project** escreve a spec de arte em `docs/specs/ANN-nome.md` (o que gerar, nomes, tamanhos, critérios).
2. **Artist** escreve/atualiza um script gerador em `tools/art/` (`extends SceneTree`, API `Image`; formas, posições e cores escritas no código, **sem RNG nem ruído**: cada textura é uma peça única), roda no Godot headless, grava os PNG em `assets/` e uma **prévia ampliada ×4** em `docs/art-preview/`.
3. **Lead Project** revisa pela prévia e pelos PNG → `APROVADO` ou `AJUSTES`.
4. **Developer** usa os PNG aprovados no jogo.

Gerar de novo: `"$G" --headless --path . --script tools/art/<script>.gd`. A arte é reproduzível: mesmo script → mesmos PNG.

### Fluxo de arte externo (Antigravity, **pausado**: cota de imagens do Gemini esgotada)

O Gemini não edita nada fora de `antigravity/` (código, cenas, `assets/`, `tools/`, `docs/`). Decisão do usuário em 2026-10-05.

Mantido para quando o usuário reativar. O artista é um modelo Gemini rodando no Antigravity, **em paralelo** e **sem comunicação direta**. Toda troca acontece por arquivos em `antigravity/`. **Cada arquivo tem um único dono:**

| Caminho | Dono | Conteúdo |
|---|---|---|
| `antigravity/INSTRUCOES.md` | Claude | Regras do artista (o "prompt" fixo dele) |
| `antigravity/tarefas/ART-NNN-nome.md` | Claude (Lead Project) | Pedido de arte |
| `antigravity/revisoes/ART-NNN.md` | Claude (Lead Project) | `APROVADO` ou `AJUSTES` sobre a última versão entregue |
| `antigravity/entregas/ART-NNN/vN/` | Artista | Imagens + `entrega.md` |
| `antigravity/ferramentas/` | Artista | Scripts auxiliares dele (ex.: pós-processamento) |

Regras:
- O Claude **nunca** escreve em `entregas/` ou `ferramentas/`. O artista **nunca** escreve fora deles.
- Uma tarefa está pendente para o artista quando não existe entrega, ou quando a revisão mais recente diz `AJUSTES` para a última versão. Revisão `APROVADO` ou `CANCELADA` (tarefa substituída por outra) encerra a tarefa.
- O Orchestrator, ao começar um trabalho, confere se há entregas novas sem revisão e pede ao Lead Project para revisá-las.
- Arte aprovada **não** é usada direto de `entregas/`: o Developer copia e adapta para `assets/` (grid 32×32 exato, paleta, fundo transparente, import com filtro Nearest).
- Enquanto não houver arte aprovada, o código continua usando placeholders gerados em código, seguindo a direção de arte.

## Stack e ambiente

- Godot **4.7.2** (build Mono, mas o projeto usa **somente GDScript**: não criar `.cs`/`.csproj`).
- Renderer: Forward Plus (necessário para sombras, glow e DOF). Stretch: `canvas_items` / `expand`.
- Cena principal em **3D** (`Node3D` + `Camera3D` + `DirectionalLight3D` + `WorldEnvironment`). HUD em `CanvasLayer`/`Control`.
- Executável (console, para validação headless):
  `C:/Users/pattr/Downloads/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe`

### Comandos de validação (rodar via Bash, a partir da raiz do projeto)

```bash
G="/c/Users/pattr/Downloads/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe"
# 1. Importa o projeto e reporta erros de parse/carregamento de scripts e cenas
"$G" --headless --path . --editor --quit 2>&1 | grep -iE "error|warning|parse"
# 2. Roda a cena principal por ~300 frames e encerra (pega erros de runtime)
"$G" --headless --path . --quit-after 300 2>&1 | grep -iE "error|warning|script"
```

Saída sem `ERROR`/`SCRIPT ERROR` = passou. Warnings do nosso código devem ser lidos e corrigidos.

## Estrutura de pastas

```
res://
  scenes/          # .tscn (main.tscn é a cena principal; map.tscn = o mapa montado à mão)
    kit/           # peças modulares do mapa (muros, quinas, escadas, terraço, árvores, props, decalques)
  scripts/
    map/           # dados do mapa (MapData), marcadores da cena, MapLayout (cena → dados), materiais do kit
    match/         # estado e regras da partida, sem visual (autoritativo)
    net/           # rede (futuro, só com a spec de multiplayer)
    ui/            # HUD, botões
    core/          # autoloads, utilidades, RNG
  tools/
    art/           # scripts geradores de arte (rodam headless, gravam em assets/)
    kit/           # construtor das malhas do kit (headless, tabelas explícitas, grava em assets/models/kit/)
  assets/
    textures/      # texturas do terreno e do kit (32 texels/unidade; + normal maps *_n.png); cards/ = cartões com alfa; decals/ = decalques de chão
    sprites/       # sprites em pé das peças (futuro); hoje ainda os sprites cartoon antigos, até a spec 006
    models/kit/    # malhas do kit (.res) gravadas por tools/kit/
    materials/     # materiais do kit (.tres)
    fonts/
  docs/            # NÃO importado pelo Godot (.gdignore)
    direcao-de-arte.md   # fonte única de estilo, paleta e medidas
    specs/         # specs do Lead Project (NNN-nome.md; arte: ANN-nome.md)
    art-preview/   # prévias ampliadas da arte gerada, para revisão
    reference/     # imagens de referência do usuário
  antigravity/     # NÃO importado pelo Godot (.gdignore). Troca de arquivos com o artista
```

## Convenções de código (GDScript)

- **Tipagem estática sempre**: `var size: int = 32`, `func build_map_data() -> MapData:`.
- Nomes: `snake_case` para arquivos, funções e variáveis; `PascalCase` para `class_name` e nós; `UPPER_SNAKE` para constantes.
- Um script = uma responsabilidade. Separar **dados** (ex.: `MapData`), **montagem** (ex.: `MapLayout`, que lê a cena e monta os dados) e **visual** (as peças do kit).
- **Nada procedural no mapa nem na arte:** sem `RandomNumberGenerator`, `FastNoiseLite` ou sorteio em `scripts/map/`, `tools/kit/` e nos geradores de arte a partir da A06 (os antigos ficam como histórico); formas e posições vêm de tabelas explícitas ou da cena. **RNG só na partida** (combate, loja, no futuro): `RandomNumberGenerator` com a seed da partida, nunca `randi()`/`randf()` globais.
- `TEXELS_PER_UNIT = 32` (1 tile = 1 unidade 3D = 32 texels) definido em um único lugar e reutilizado.
- Posições de peças em coordenadas contínuas (`Vector2` no plano X/Z, em unidades do mundo 3D), nunca em índice de tile.
- Câmera: inclinação fixa; mudam só o yaw (giro de 360° em torno do centro da arena, pelo teclado) e a distância (zoom, entre limites `@export`). Sem pan e sem giro pelo mouse. Nenhuma regra de jogo depende do ângulo da câmera.
- Parâmetros ajustáveis como `@export` (câmera, zoom, força do dither, normal_scale...).
- Comunicação entre sistemas por **sinais** (ex.: `map_ready(map_data)`), não por caminhos de nó frágeis (`get_node("../../X")`).
- Comentários em **português**, curtos, só onde o "porquê" não é óbvio. Identificadores em **inglês**.
- Não editar `project.godot` à mão sem necessidade. Quando for preciso (ex.: `run/main_scene`, autoloads, filtro de textura padrão), descrever a mudança no relatório.

## Direção de arte

A fonte única é **`docs/direcao-de-arte.md`** (estilo, paleta em hex, medidas, iluminação, fronteira entre arte e código). Ela vale tanto para os placeholders em código quanto para o artista. Resumo:
- 2.5D: cenário todo em modelos 3D low-poly com textura pixel art de 32 texels por unidade (o `artist` faz texturas, normal maps de pedra e madeira e cartões; o `developer` faz forma, UV, materiais e monta o mapa com o kit); só as peças são sprites em pé. Filtro **Nearest**.
- Pixel art minimalista no chão (poucos tons, detalhe esparso, bordas orgânicas recortadas em pixel, desenhadas à mão como decalques); detalhe maior nas árvores, nos muros e nos props. Dia claro, sombras suaves esverdeadas, névoa azulada ao fundo, pós leve.
- Placeholders gerados em código seguem a paleta. Nada de ruído por pixel nem de cor chapada sem forma.

## Definição de pronto

Uma tarefa só está pronta quando:
1. Os critérios de aceite da spec são atendidos.
2. Os dois comandos de validação rodam sem erros do nosso código.
3. O Developer entregou relatório com: arquivos criados/alterados, como testar no editor (F5), limitações conhecidas.
4. O Lead Project aprovou (exceto tarefas triviais).

## O que não fazer

- Não implementar funcionalidades fora da fase atual (unidades, combate, loja, economia) sem pedido do usuário.
- Não adicionar plugins/addons ou assets de terceiros sem aprovação do usuário.
- Não apagar arquivos do usuário nem mexer em `.godot/`.
- Não escrever em `antigravity/entregas/` ou `antigravity/ferramentas/`.
- Não fazer commits/push sem o usuário pedir.
