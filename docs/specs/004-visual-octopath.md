# 004 — Atmosfera de dia claro: luz, céu, névoa e pós-processamento leve

**Status:** aprovada pelo usuário em 2026-10-06.
**Reescrita em 2026-10-06:** a versão anterior ("fim de tarde dourado" estilo Octopath, com tilt-shift forte, vinheta e color grading quente) foi rejeitada pelo usuário. O nome do arquivo foi mantido para não quebrar referências.
**Depende de:** `007` (distâncias novas da câmera e layout do anfiteatro). **Não depende da A03:** funciona com a arte atual e pode correr em paralelo com ela.
**Próximas:** `005` (terreno com a A03) e `006` (vegetação e props 3D).

## Objetivo
Ao apertar F5, a cena parece um **dia claro**, como a referência `docs/reference/Gemini_Generated_Image_6oy5mo6oy5mo6oy5.jpg`:
- sol neutro levemente quente, com sombras suaves e esverdeadas;
- imagem limpa e nítida: o anfiteatro e a mata em volta sem desfoque, sem vinheta, com bloom quase imperceptível;
- névoa azulada só ao fundo;
- nenhum vazio azul-marinho em qualquer rotação ou zoom.

## Escopo
1. **Sol** (`DirectionalLight3D`):
   - cor `#FFF3DC`, elevação de 50° a 60°, vindo do **sudoeste** (na câmera padrão, frente-esquerda);
   - **fixo no mundo** por padrão, com `@export var sun_follows_camera: bool = false`. Ligado, o yaw do sol acompanha o da câmera e mantém a direção relativa da vista padrão;
   - sombras ligadas, com 4 splits e distância máxima que cubra o que aparece no zoom máximo, sem acne nem "peter-panning" visíveis.
2. **Sombra suave e esverdeada:**
   - luz ambiente de cor `#7FA898` (ou céu tingido com resultado equivalente), com energia tal que a grama da arena na sombra fique verde médio (alvo na tela perto de `#2E6B45`), nunca azul-petróleo nem quase preta;
   - sombra direcional com borda suave (PCF ou `shadow_blur`), sem perder o recorte das copas;
   - **SSAO leve** (`@export` para ligar e desligar), só para assentar troncos, pedras e o pé dos muros.
3. **Céu claro:** fundo de céu (`ProceduralSkyMaterial` ou shader próprio) com zênite `#78AEDB` e horizonte `#BFD8E0`. O "chão" do céu fica no tom da névoa `#A6C4CE`.
4. **Fundo sem vazio** (só visual, no `MapRenderer`): uma **saia de chão** além da borda do mapa, na altura do chão mais alto da borda do mapa (com o anfiteatro da `007`, a floresta é mais alta que a arena).
   - Usa a textura `grass_forest_*` com UV em unidades do mundo e recebe sombra.
   - É larga o bastante para que, em qualquer yaw e no zoom máximo, o alto da tela mostre chão ou névoa, nunca a cor de fundo.
5. **Névoa azulada só ao fundo:**
   - névoa de profundidade com cor `#A6C4CE`, começando **depois da borda do mapa** (não da arena) e chegando ao máximo de 30 a 50 unidades depois;
   - `fog_sun_scatter` baixo ou zero;
   - nada de névoa volumétrica.
6. **Desfoque sutil, só no fundo distante:**
   - `dof_blur_near_enabled = false`;
   - `dof_blur_far_enabled = true`, com a distância de início ≥ a distância da câmera até o ponto mais longe do anfiteatro ([8, 36)² da `007`) + 4, recalculada como hoje em `MapCamera`;
   - transição longa e `dof_blur_amount` ≤ 0,05.
7. **Bloom fraco:** glow com limiar HDR ≥ 1,0 e intensidade baixa. Só a runa e brilhos muito altos ganham halo. A grama ao sol não brilha.
8. **Tonemap e cor:**
   - tonemap que preserve as cores da paleta (sugestão: `Linear` com exposição calibrada; se estourar, `Filmic`). Relate o motivo da escolha;
   - `adjustment_*` no máximo com contraste de 1,0 a 1,05 e saturação de 1,05 a 1,10;
   - **sem** `adjustment_color_correction`.
9. **Sem vinheta.** Se existir algum nó de vinheta, remova ou desligue.
10. **Desligar tudo para comparar:** o argumento `--fx=off` desliga DOF, bloom, névoa e SSAO e mantém sol, sombras, céu e saia.
11. **Medição:**
    - o modo `--capture` imprime a média de FPS dos últimos 60 quadros, as draw calls e as primitivas do quadro (`Performance`);
    - novo `tools/tests/measure_capture.gd` (`extends SceneTree`, recebe o caminho de um PNG), que imprime:
      - a luminância média, a saturação média (HSV) e a porcentagem de pixels estourados (Y ≥ 0,97) do retângulo central de 40% × 40%;
      - a luminância média de 3 cantos de 8% × 8% (cima-direita, baixo-esquerda e baixo-direita);
      - na faixa de cima (15% da altura), quantos pixels têm a cor de fundo antiga `#1F2E47` e quantas linhas são de uma cor só;
      - **sombras:** dos pixels fora da faixa de cima com Y entre 0,10 e 0,35, o matiz médio (HSV, em graus) e a fração com matiz entre 180° e 260°.
12. **Teste headless** `tools/tests/test_atmosphere.gd`. Ele verifica:
    - que `--fx=off` (ou o método equivalente) desliga os efeitos do item 10;
    - que, com `sun_follows_camera = true`, depois de `set_target_yaw(90, true)` o yaw do sol mudou 90° e, com `false`, não mudou;
    - que não existe vinheta nem `adjustment_color_correction`, e que o DOF de perto está desligado.
13. **Capturas** 1280×720 (com janela, não headless) em `docs/screenshots/`:
    - `004-s42-y0.png`, padrão;
    - `004-s42-y0-fxoff.png`, a mesma vista com `--fx=off`;
    - `004-s42-y135.png`;
    - `004-s42-y225-max.png`;
    - `004-s1337-y300-min.png`;
    - `004-s1-y45-max.png`.

    Use `--seed`, `--yaw`, `--zoom` e `--capture`.

## Fora de escopo
- Arte nova (A03), terreno e máscaras do chão (`005`), árvores e props 3D (`006`).
- Mudar a geração do mapa, os controles da câmera ou o HUD.
- Ciclo de dia e noite, vento, partículas, água, peças.
- TAA ou FXAA (borram o pixel), SDFGI, VoxelGI, lightmaps, addons.

## Design técnico sugerido
- **Onde ficam os valores.** O `Environment` e o `CameraAttributesPractical` ficam como recursos editáveis no inspetor (no `main.tscn` ou em `.tres` em `scenes/`). Um script de cena `scripts/core/atmosphere.gd` (`class_name Atmosphere`, `extends Node`) cuida do comportamento: aplicar `--fx=off`, fazer o sol acompanhar a câmera e ligar ou desligar o SSAO.
- **Sol que acompanha a câmera.** `MapCamera` emite um sinal (ex.: `yaw_changed(yaw_degrees)`) e o `Atmosphere` reage. Nada de caminho de nó frágil.
- **DOF e névoa.** `MapCamera._update_depth_effects` hoje usa a caixa da arena. Passe a usar a caixa do anfiteatro mais a floresta do mapa (exposta pelo `MapData` da `007`). O desfoque e a névoa começam depois dela.
- **Saia de chão.** Fica no visual (`MapRenderer` ou um ajudante `SkirtMeshBuilder`), sem regra de jogo e fora do `MapData`. A `006` põe a mata de fundo nela.
- **Calibrar pela captura:** comece pelos hex da direção de arte e ajuste até a grama da arena ao sol ficar perto de `#5B9C47`/`#73A949` na tela, e a da sombra perto de `#2E6B45`.

## Direção de arte
- Fonte: `docs/direcao-de-arte.md`, seção **Iluminação e pós-processamento** e tabela de cores de ambiente.
- Alvo: a referência do Gemini, com dia claro, cores vivas, sombra verde e névoa azulada só no alto da imagem.
- **Limpo e nítido.** É o oposto do "tilt-shift forte" da versão anterior: o jogador precisa ver as peças e o relevo com clareza em toda a área de jogo.

## Critérios de aceite

**Configuração (código, cena e teste)**
- [ ] O sol tem a cor e a elevação da direção de arte, com sombras ligadas e 4 splits. `sun_follows_camera` existe, é `false` por padrão e o `test_atmosphere.gd` passa.
- [ ] A configuração está assim:
  - fundo de céu;
  - névoa de profundidade começando depois da borda do mapa;
  - glow com limiar ≥ 1,0;
  - SSAO com interruptor;
  - DOF de perto desligado e DOF de longe com força ≤ 0,05;
  - sem vinheta e sem `adjustment_color_correction`.
- [ ] `--fx=off` desliga os efeitos do item 10.

**Medidas nas capturas (`tools/tests/measure_capture.gd`)**
- [ ] Em `004-s42-y0.png`, no retângulo central:
  - luminância média entre 0,40 e 0,65;
  - saturação média ≥ 0,40;
  - no máximo 0,5% de pixels estourados.
- [ ] **Sem vinheta:** a razão (média dos 3 cantos ÷ centro) em `004-s42-y0.png` é pelo menos 0,95 vez a mesma razão em `004-s42-y0-fxoff.png`.
- [ ] **Sombra verde:** em `004-s42-y0.png`, nos pixels de sombra, o matiz médio fica entre 95° e 165°, e no máximo 10% deles têm matiz entre 180° e 260°.
- [ ] **Sem vazio:** em todas as capturas, a faixa de cima não tem nenhum pixel `#1F2E47` nem linha de uma cor só.

**Visuais (revisão do Lead Project)**
- [ ] O anfiteatro e a mata do mapa estão nítidos em todas as capturas. Só o fundo além do mapa tem desfoque leve. Nada perto da câmera fica desfocado.
- [ ] A grama ao sol tem cor viva, perto da paleta. A sombra é verde suave. A runa tem um halo discreto. Nada estoura em branco.
- [ ] Ao fundo aparece chão e mata sumindo numa névoa azulada clara, nunca azul-marinho chapado.
- [ ] Lado a lado com a referência, a luz e a cor parecem da mesma família (dia claro, limpo), mesmo com a arte atual.

**Desempenho**
- [ ] O relatório traz o FPS médio (modo `--capture`) em 1280×720 e 1920×1080, seed 42, yaw 45 e zoom máximo, com tudo ligado e com o SSAO desligado.
- [ ] O padrão final dá **≥ 60 FPS a 1920×1080** nesta máquina. Se não der, desligue por padrão o efeito mais caro e relate.

**Processo**
- [ ] Os dois comandos de validação do `CLAUDE.md` rodam sem erros. Os testes `tools/tests/` existentes e o novo `test_atmosphere.gd` passam.
- [ ] As 6 capturas estão em `docs/screenshots/`. O relatório traz a saída do `measure_capture.gd` de cada uma e descreve qualquer mudança em `project.godot`.
