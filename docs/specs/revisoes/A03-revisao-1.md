# A03: revisão 1

**Data:** 2026-10-06
**Spec:** `docs/specs/A03-arte-minimalista.md`
**Alvo:** `docs/reference/Gemini_Generated_Image_6oy5mo6oy5mo6oy5.jpg`
**Veredito:** `AJUSTES`. O chão (grama, terra e mosaico), o muro, o musgo, os props pequenos e as coníferas estão aprovados como estão. Bloqueiam o calçamento, a escada, a luz de todos os cartões de folhagem (`leaf_*`), o topo do muro e duas prévias. O calçamento depende de uma correção da spec, proposta abaixo.

## O que foi conferido

**Validação que eu refiz:**
- `check_a03.gd` deu `A03 CHECK: PASS`, com 68 arquivos lidos e as 3 `rune_*` com md5 intacto;
- os dois comandos do `CLAUDE.md` rodaram sem nenhuma linha de `error`, `warning` ou `parse`;
- `gen_a02.gd` tem a guarda (`ENABLED = false`, mensagem "A02 substituída pela A03");
- os PNG de `assets/sprites/` estão com data de antes desta entrega. A modificação que aparece no `git status` é antiga.

Não rodei o gerador duas vezes, porque eu não escrevo em `assets/`. Para a reprodutibilidade, vale o relatório do artist.

**Medidas que eu fiz** (contagem das cores opacas lidas do PNG):

| Arquivo | Distribuição |
|---|---|
| `stone_path_0` | `#B9B597` 51%, `#989680` 23%, **`#34403C` 19%**, `#D3CCB4` 6%, musgo 1% |
| `stair_riser` | `#989680` 41%, `#7A7A66` 29%, `#34403C` 20%, `#B9B597` 7%, musgo 2% |
| `stair_tread` | `#B9B597` 44%, `#D3CCB4` 32%, `#989680` 11%, `#7A7A66` 11%, musgo e grama 2% |
| `wall_top` | `#789636` 82%, `#B9B597` 8%, `#8FAE48` 7%, `#D3CCB4` 2% |
| `wall_face` | `#989680` 31%, `#B9B597` 28%, `#34403C` cerca de 25%, `#D3CCB4` 7%, musgo 10% |
| `leaf_0` | `#5A9628` 26%, `#76AB2A` 18%, `#437B25` 16%, `#2F6A2A` 13%, **`#9CC230` 12%, `#B5CA33` 12%**, `#1F5530` 4% |
| `leaf_1` | `#9CC230` 16% e `#B5CA33` 8% (24% nos 2 tons mais claros); `#1F5530` e `#2F6A2A` somam 16% |
| `leaf_olive_0` | os 2 mais claros somam 24%, e os 2 mais escuros, 35% |
| `conifer_tier_0` | `#86A83E` 1%, `#5C8C40` 6%, e o resto é escuro. A linha 20 tem 4 dentes, o mínimo |

**Comparação com a referência** (`a03-comparacao.png`, `a03-cena.png` e a imagem original):
- **Grama e terra:** muito perto da referência. O verde é o mesmo, a terra tem um tom só, a borda é orgânica e tem ilhas de grama e aro claro. O mosaico 24×14 é um bom alvo para o shader da `005`. **Aprovado.**
- **Muro (`wall_face`):** fiadas finas, aresta de cima clara e musgo escorrendo. Lê como o muro da referência. **Aprovado.**
- **Calçamento:** na referência, as juntas são finas, cinza-esverdeadas e de valor médio, e as lajes são grandes. Nas nossas, a junta é `#34403C`, quase preta ao lado de `#B9B597`, então cada laje parece ter contorno. Isso fere a regra "sem contorno" da direção de arte. O artist seguiu a spec ao pé da letra: o erro está na spec (ver abaixo).
- **Escada:** lê como parede de tijolo vista de frente. O espelho tem 2 a 3 juntas verticais escuras por fiada, todas da altura inteira, alinhadas em grade. O piso tem moldura dupla em cada laje (chanfro mais junta), o que parece azulejo. Na referência, cada degrau é um bloco comprido, com nariz claro em cima, sombra escura embaixo e musgo no nariz.
- **Folhosa:** os `leaf_0..3` têm 24% dos pixels nos 2 tons mais claros (`#9CC230`/`#B5CA33`), e o "terço de cima" de cada bolinho aparece no card inteiro. Por isso a copa da cena parece toda acesa, em amarelo-limão. A folhosa da referência é uma massa escura, com luz só nas calotas de cima. Além disso, a cena usa só a família verde, enquanto o recorte da referência é a folhosa amarelada: a comparação não foi de igual para igual.
- **Conífera:** tem camadas serrilhadas, então passa no critério. Os andares, porém, são arcos simétricos ("chevrons") que se repetem. Na referência, os galhos pendem e são irregulares.
- **Topo do muro:** as 4 a 5 pedrinhas claras e redondas viram uma fileira de bolinhas que se repete a cada 1 unidade ao longo do muro. Ao longo dos muros do anfiteatro, isso vai aparecer em todo lugar.
- **Tronco caído:** na prévia é um retângulo achatado com cortes verticais. Os cortes são as quebras horizontais das placas de `bark_0`, giradas 90°. A leitura de cilindro vai vir da malha da `006` (6 a 8 lados com luz real), então a prévia 2D não decide. `wood_end` serve: os anéis estão bons e o centro está no meio. `bark_0` serve para tronco em pé e para toco. Para o tronco caído, ele é escuro: a base `#6B4C3E` cobre 57%, enquanto o tronco da referência fica perto de `#A37C56`/`#A98359`.
- **Cogumelos, flores, capim, capim alto, franjas, `moss`, `leaves_mass`, `rock`, `monolith_stone`, `step_side*`, `bark_*`, `wood_end`, `conifer_tier_*`:** de acordo com a spec e com a referência. **Aprovados.**
- **`leaf_olive_*`, `leaf_cool_*`, `leaf_flower_0`:** a forma está boa, e a oliva é a mais próxima da referência. Recebem a mesma regra de luz do item 4, para as famílias ficarem coerentes.

## Conflito na spec (calçamento): correção proposta

A spec A03 (tabela 2, linha `stone_path`) e a direção de arte ("Uso por material: Calçamento", e a tabela "Tons por material") pedem juntas em `#34403C`/`#1C2B2B`. Com lajes em `#B9B597`, isso vira contorno escuro, e a referência não tem isso. Por isso proponho trocar o texto (o Orchestrator confirma com o usuário antes de eu aplicar):

- **A03, tabela 2, `stone_path_0` `_1`:**
  - lajes grandes e irregulares de 10 a 18 px, em Pedra de `#989680` a `#D3CCB4`, com base `#B9B597`;
  - juntas de 1 px (2 px só nos cruzamentos) em `#7A7A66`. `#5C6250` só nos cruzamentos, em até 4% dos pixels;
  - musgo (`#5E7C26`, `#789636`) em 2 a 4 trechos de junta;
  - **sem `#34403C` e sem `#1C2B2B`**;
  - juntas (`#7A7A66`, `#5C6250` e Musgo) entre 10% e 20% dos pixels;
  - o resto da linha (seamless e emenda entre variantes) fica igual.
- **A03, critério automático "Juntas e musgo":** "em `stone_path_*`, as juntas (`#7A7A66`, `#5C6250` e Musgo) ficam entre 10% e 20% dos pixels, e `#34403C`/`#1C2B2B` não aparecem".
- **Direção de arte:**
  - "Uso por material: Calçamento" passa a dizer: lajes de `#989680` a `#D3CCB4`, juntas em `#7A7A66` (com `#5C6250` nos cruzamentos) e Musgo;
  - na tabela "Tons por material", a linha do calçamento passa para "juntas entre 10% e 20%".

O muro e o espelho de escada continuam com junta horizontal escura (`#34403C`). Na referência, essa junta é escura de verdade: é a sombra embaixo de cada pedra e de cada nariz de degrau.

## AJUSTES (bloqueiam)

1. **`stone_path_0.png`, `stone_path_1.png`** (`tools/art/gen_a03_textures.gd:816`, `_stone_paths`): as juntas em `#34403C` parecem contorno preto. **Esperado:** aplicar a correção acima, depois que ela entrar na spec. As lajes ficam maiores (10 a 18 px), a junta é `#7A7A66` com 1 px, e `#5C6250` aparece só nos cruzamentos. No `check_a03.gd:448-454`, a contagem de juntas do `stone_path` passa a usar essas cores, com a faixa de 10% a 20%, e passa a reprovar se aparecer `#34403C` ou `#1C2B2B`. Na prévia ×4, nenhuma laje pode ter borda mais escura que `#7A7A66`.
2. **`stair_riser.png`** (`gen_a03_textures.gd:699-725`): o espelho parece tijolo em grade, porque a linha 707 usa larguras de 9 a 17 px e a junta vertical é `#34403C` da altura inteira. **Esperado:**
   - pedras de 14 a 32 px de largura, ou seja, de 1 a 2 juntas verticais por faixa, deslocadas pelo menos 6 px entre faixas vizinhas;
   - junta vertical em `#5C6250` ou `#7A7A66`, nunca em `#34403C`;
   - a linha de cima de cada faixa (0, 8, 16 e 24) é o nariz, em `#B9B597`/`#D3CCB4` em pelo menos 70% da largura;
   - as linhas 7, 15, 23 e 31 continuam escuras (com 60% ou mais, como hoje);
   - musgo de 3 a 8 px em cima do nariz, em 1 ou 2 faixas.
   Na prévia, cada faixa deve ler como um bloco comprido, e não como tijolos.
3. **`stair_tread.png`** (`gen_a03_textures.gd:728-790` e `:88`):
   - O `best_roll` vertical tira as juntas horizontais das linhas 15 e 31. É a "junta deslocada" que o artist relatou. O piso tem 0,5 de profundidade (16 texels, spec `007`), então a junta precisa cair na última linha de cada faixa de 16, como nas laterais. **Esperado:** sem roll vertical. As juntas horizontais ficam nas linhas 15 e 31, e a linha 0 (e a 16) é o nariz claro (`#D3CCB4`).
   - Cada laje tem moldura dupla (o chanfro de 1 px numa cor e a junta `#7A7A66` em outra, linhas 778-790), e isso lê como azulejo. **Esperado:** sem moldura interna. Só a junta de 1 px `#7A7A66`, e as lajes ficam entre 16 e 20 px (o topo da faixa da spec).
   - Musgo e grama nas juntas somam hoje 2%. **Esperado:** de 2 a 4 tufos de 2 a 4 px, em 4% a 8% dos pixels, como pede a spec ("musgo e grama nas juntas").
4. **`cards/leaf_0..3.png`** (`tools/art/gen_a03_cards.gd:162-180`): as faixas de tom por `v` deixam 24% do card nos 2 tons mais claros, e a copa fica "toda acesa", em amarelo-limão. **Esperado** (vale também para `leaf_olive_*`, `leaf_cool_*` e `leaf_flower_0`, para ficarem coerentes):
   - os 2 tons mais claros da família somam no máximo 12% dos pixels opacos, e o mais claro (`#B5CA33`, `#A6B04A`, `#7CC070`) no máximo 4%;
   - a luz forma uma calota de 1 a 3 linhas só no topo de cada bolinho, e o tom mais claro só aparece nos bolinhos cuja parte de cima está na metade de cima do card;
   - os 3 tons mais escuros somam 30% ou mais;
   - dentro do bolinho, marcas de folha de 2 a 3 px num tom abaixo, para quebrar a calota;
   - as pontas de folha também nos lados e na base da silhueta, além do topo.
   Acrescente essas contagens ao `check_a03.gd`, para que a regra seja verificável.
5. **`wall_top.png`** (`gen_a03_textures.gd:937`, `_wall_top`): as 4 a 5 pedrinhas claras e redondas viram bolinhas em fileira a cada 32 px. **Esperado:**
   - de 2 a 3 falhas de pedra, cada uma com forma irregular e alongada (de 3×2 a 6×3 px), não redonda, e com `#989680` na borda de baixo;
   - o musgo varia em tufos, com `#8FAE48` em clusters de 2 a 5 px com `#5E7C26` embaixo, e não em pontos isolados;
   - nenhum elemento claro maior que 2×2 px aparece mais de 3 vezes.
   Na prévia do muro repetida em 4 tiles, não pode surgir fileira de bolinhas.
6. **Prévias** (`tools/art/gen_a03_preview.gd`). Estas imagens são o alvo que o developer vai copiar na `006`.
   - `_fake_broadleaf`, linhas 382-413:
     - a copa usa `leaf_0..3` e `leaf_olive_*` misturados;
     - os cartões da metade de baixo da elipse ficam mais espaçados, para o `leaves_mass` aparecer em 30% ou mais da metade de baixo.
   - `a03-comparacao.png`:
     - compare a folhosa amarelada da referência com uma copa só de `leaf_olive_*`;
     - acrescente um recorte de folhosa verde da frente da referência (canto inferior direito), comparado com a copa de `leaf_*`.
   - `_stair_demo` (linha 213) e a escada da cena: mostre o degrau como na vista do jogo. O piso é desenhado com 4 a 6 linhas visíveis (o topo da faixa, achatado) em cima de cada faixa de 8 linhas do espelho, para ler como degrau, e não como parede.

## Pode refinar depois de ver no motor (005/006), sem bloquear

- **Conífera (`conifer_tier_*`):** ganharia se os arcos simétricos virassem galhos pendentes assimétricos, com 5 a 7 dentes na linha 20 (hoje são 4, o mínimo) e a luz em riscos ao longo de cada galho, em vez de uma calota em arco. Vale reavaliar com a luz real e o empilhamento da `006`.
- **Tronco caído:** reavaliar no screenshot de perto da `006`.
  - Se ficar escuro ou "em tábuas", o caminho é uma textura nova `bark_log`: mais clara (base `#876547`/`#A37C56`), com veios longos e contínuos na direção do tronco e sem quebras transversais. Ela entraria por spec nova, não por esta.
  - Para o developer: no tronco caído, os sulcos de `bark_0` correm ao longo do eixo do tronco.
- **`bark_0`:** as quebras horizontais escuras entre placas podiam ser mais curtas, de 2 a 3 px, sem cruzar de sulco a sulco.
- **`wall_face`:** a junta `#34403C` está em cerca de 25%, no limite da faixa de 12% a 25% da direção. Pode baixar 2 ou 3 pontos se no motor o muro parecer escuro.
- **`grass_fringe_*`:** o contraste com `grass_forest` é baixo. Talvez some no motor, e isso é aceitável.

## Notas para o developer (005/006)

- **Normal maps:** no `.import`, marque todos os `*_n.png` como normal map (`compress/normal_map = 1`). Use filtro Nearest com mipmaps em todo material.
- **Obsoletos** (não carregar; apagar só com o OK do usuário): `ruin_tile.png`, `ruin_tile_n.png`, `grass_arena_*_n.png`, `grass_forest_*_n.png`, `dirt_*_n.png` e `leaves_mass_n.png`.
- **Já pode integrar**, porque não muda neste ciclo:
  - chão: `grass_*`, `dirt_*`;
  - pedra e madeira: `wall_face`, `step_side*`, `rock`, `monolith_stone`, `bark_*`, `wood_end`, `moss`, `leaves_mass`;
  - cartões: `conifer_tier_*`, `moss_fringe_*`, `grass_fringe_*`, `grass_tuft_*`, `tall_grass_*`, `flower_*`, `mushroom_*`.
  - Os itens 1 a 5 trocam só pixels: os nomes e as dimensões ficam iguais.
