# Pixel Chess — Regras do Projeto

Jogo **auto chess multiplayer** (até 8 jogadores, estilo TFT) em **2.5D estilo HD-2D** (como Octopath Traveler, com identidade própria), **pixel art cartoon 32×32**, feito em **Godot 4.7 + GDScript**.
Cada partida gera um mapa procedural novo a partir de uma **seed**. Fase atual: **geração de mapa (planície/floresta, com relevo e degraus)** com um botão "Gerar mapa".

## Estilo visual: HD-2D híbrido (decidido pelo usuário)

- **Mundo 3D de verdade** (`Node3D`), com texturas em pixel art. O que tem volume é **modelo 3D** gerado em código ou simples: chão, **relevo e degraus**, rampas, borda da arena, pedras grandes, construções.
- **Sprites 2D em pé** (`Sprite3D`, billboard), desenhados em pixel art **vistos de frente**: árvores, arbustos, capim, flores e, no futuro, as peças.
- **Câmera fixa:** ângulo inclinado fixo, perspectiva. **Só zoom** (com limite mínimo e máximo), **sempre mirando o centro da arena**, sem arrastar a câmera (pan). **Nunca gira.** Por isso os sprites em pé nunca são vistos de lado.
- **Efeitos do estilo:** luz direcional com sombras reais (sprites também projetam sombra), bloom/glow, desfoque de profundidade (tilt-shift), névoa leve. Tudo via `WorldEnvironment`/`CameraAttributes`, sem addons.
- **Escala única:** 1 tile = **1 unidade 3D** = **32 texels**. Sprites usam `pixel_size = 1.0 / 32.0` para manter a mesma densidade de pixel do chão. Filtro **Nearest** em tudo.
- **Pixel art cartoon:** contorno escuro colorido, cores saturadas, formas simples e arredondadas, poucos tons por material. Pós-processamento mais leve que no Octopath. Referência de estilo: a imagem da clareira em `docs/reference/`; referência de composição do mapa: `ref-floresta-vila.png` e `ref-ruinas-planicie.png`.

## Design do jogo (regras fixas)

- **Mapa por seed.** Cada partida tem uma seed (`int`). Mesma seed → mesmo mapa, sempre. A seed aparece na tela e pode ser reutilizada para reproduzir um mapa.
- **Arena.** Todo mapa gerado define uma **arena**: a área de luta, delimitada e visível no mapa. O que fica fora dela é cenário (floresta, decoração) e não é jogável.
  - Padrão atual: arena = clareira aberta de planície **muito grande** no centro (cerca de 60–70% da largura e da altura do mapa), com floresta e decoração ao redor como moldura.
  - **Um único mapa por partida**, gerado pela seed da partida e usado por todos os jogadores em todas as rodadas. Não existe arena por jogador.
  - O gerador expõe o formato da arena nos dados do mapa (ex.: `MapData.arena`) e funções como `is_inside_arena(pos: Vector2) -> bool` e `clamp_to_arena(pos: Vector2) -> Vector2`.
- **Posicionamento livre das peças.** Diferente dos auto chess tradicionais, **não existe grid de posicionamento**: a peça pode ser colocada em **qualquer ponto dentro da arena** (posição contínua `Vector2` no plano do chão, eixos X/Z do 3D; a altura vem do terreno), mas **nunca fora dela**. Arrastar para fora → a peça é limitada à borda (clamp) ou o posicionamento é recusado.
  - As peças têm um raio de colisão e não se sobrepõem.
  - Ainda a definir com o usuário (não implementar sem pedido): divisão da arena por time/lado, obstáculos dentro da arena, e se degrau alto bloqueia movimento ou se a peça sobe por rampa.
- **Tudo é procedural, a cada partida:** relevo, degraus e escadas, formato da arena, muro, trilhas, vegetação e decoração são gerados a partir da seed da partida. Nenhum mapa é feito à mão nem fixo.
- **Relevo e degraus:** o terreno tem níveis de altura em degraus (incluindo dentro da arena). O grid de **tiles** (células de 1 unidade, textura 32×32) serve para gerar e desenhar o terreno e as alturas. Ele não limita onde as peças ficam.

## Multiplayer (estrutura; rede só na fase própria)

- Até **8 jogadores por partida, estilo TFT**. Agora: **um jogador hospeda** (multiplayer nativo do Godot, `ENetMultiplayerPeer` + RPC, sem addons). No futuro distante: servidor dedicado headless rodando o mesmo código.
- **Autoritativo decide tudo.** O host (ou, offline, o "host local") valida e aplica; clientes só enviam **intenções** (ex.: "posicionar peça em X") e mostram o resultado.
- **Lógica separada do visual.** O estado e as regras da partida vivem em classes sem visual (`RefCounted`/`Resource`, em `scripts/match/` e `scripts/map/`). Nós visuais só leem esse estado e reagem a sinais. Nenhuma regra de jogo dentro de um nó visual.
- **Mapa sincronizado só pela seed.** Cada cliente gera o mesmo mapa localmente, então a geração do mapa é **função pura da seed** (sem depender de frame, tempo, ordem de nós ou estado global).
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
| **Artist** | `artist.md` | Produz a arte do jogo (texturas e sprites) com scripts geradores em GDScript | Só `tools/art/`, `assets/textures/`, `assets/sprites/`, `docs/art-preview/` |
| **Artista externo (Antigravity / Gemini)** — **pausado** | `antigravity/INSTRUCOES.md` | Gerava artes de referência e sprites candidatos | Só `antigravity/entregas/` e `antigravity/ferramentas/` |

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
2. **Artist** escreve/atualiza um script gerador em `tools/art/` (`extends SceneTree`, API `Image`, RNG com seed), roda no Godot headless, grava os PNG em `assets/` e uma **prévia ampliada ×4** em `docs/art-preview/`.
3. **Lead Project** revisa pela prévia e pelos PNG → `APROVADO` ou `AJUSTES`.
4. **Developer** usa os PNG aprovados no jogo.

Gerar de novo: `"$G" --headless --path . --script tools/art/<script>.gd`. A arte é reproduzível: mesmo script → mesmos PNG.

### Fluxo de arte externo (Antigravity, **pausado**: cota de imagens do Gemini esgotada)

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
  scenes/          # .tscn (main.tscn é a cena principal)
  scripts/
    map/           # geração de mapa (dados, gerador, renderização, arena)
    match/         # estado e regras da partida, sem visual (autoritativo)
    net/           # rede (futuro, só com a spec de multiplayer)
    ui/            # HUD, botões
    core/          # autoloads, utilidades, RNG
  tools/
    art/           # scripts geradores de arte (rodam headless, gravam em assets/)
  assets/
    textures/      # texturas 32×32 do terreno 3D (topo, lateral de degrau, borda)
    sprites/       # sprites em pé (árvores, arbustos, capim, flores...)
    models/        # modelos 3D simples, se houver (pedras, borda)
    fonts/
  docs/            # NÃO importado pelo Godot (.gdignore)
    direcao-de-arte.md   # fonte única de estilo, paleta e medidas
    specs/         # specs do Lead Project (NNN-nome.md; arte: ANN-nome.md)
    art-preview/   # prévias ampliadas da arte gerada, para revisão
    reference/     # imagens de referência do usuário
  antigravity/     # NÃO importado pelo Godot (.gdignore). Troca de arquivos com o artista
```

## Convenções de código (GDScript)

- **Tipagem estática sempre**: `var size: int = 32`, `func generate(seed: int) -> MapData:`.
- Nomes: `snake_case` para arquivos, funções e variáveis; `PascalCase` para `class_name` e nós; `UPPER_SNAKE` para constantes.
- Um script = uma responsabilidade. Separar **dados** (ex.: `MapData`), **geração** (ex.: `MapGenerator`) e **visual** (ex.: `MapRenderer`).
- Geração **determinística por seed**: usar `RandomNumberGenerator` com seed explícita e `FastNoiseLite` com `seed` setada. Nunca usar `randi()`/`randf()` globais na geração.
- `TEXELS_PER_UNIT = 32` (1 tile = 1 unidade 3D = 32 texels) definido em um único lugar e reutilizado.
- Posições de peças em coordenadas contínuas (`Vector2` no plano X/Z, em unidades do mundo 3D), nunca em índice de tile.
- Câmera: ângulo fixo; só a distância (zoom) muda, entre limites `@export`. Nenhum código gira a câmera.
- Parâmetros ajustáveis como `@export` (tamanho do mapa, tamanho da arena, densidade de árvores, frequência do noise...).
- Comunicação entre sistemas por **sinais** (ex.: `map_generated(map_data)`), não por caminhos de nó frágeis (`get_node("../../X")`).
- Comentários em **português**, curtos, só onde o "porquê" não é óbvio. Identificadores em **inglês**.
- Não editar `project.godot` à mão sem necessidade. Quando for preciso (ex.: `run/main_scene`, autoloads, filtro de textura padrão), descrever a mudança no relatório.

## Direção de arte

A fonte única é **`docs/direcao-de-arte.md`** (estilo, paleta em hex, medidas, iluminação). Ela vale tanto para os placeholders em código quanto para o artista. Resumo:
- HD-2D híbrido: terreno/relevo 3D com textura pixel art 32×32; vegetação e peças como sprites em pé vistos de frente. Filtro **Nearest**.
- Luz direcional vinda de cima-esquerda (em relação à câmera), com sombras reais. Árvores maiores que um tile e sobrepostas.
- Placeholders gerados em código seguem a paleta. Nada de cor chapada: texturas com ruído/detalhe e sprites com forma.

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
