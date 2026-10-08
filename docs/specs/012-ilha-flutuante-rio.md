# 012 — Ilha flutuante fiel à referência (cenário pintado)

**Revisão 1 (2026-10-08): referência `ilha-flutuante.webp`.** Esta revisão reescreve a spec. A composição livre da versão anterior (lagoa a oeste, rio atrás do muro norte, cascata a leste, árvore anciã, mirantes, trilhas longas, ilha de raio 34 a 42) **sai** e entra a composição medida na referência nova. O cenário deixa de ser pixel art. O que mudou está resumido em "Mudanças desta revisão", no fim.

**Atualização de 2026-10-08, depois da revisão `revisoes/012-f1.md`:** mudaram a Tabela B (terra e círculo, medidos de novo), a Tabela C (mata mais densa e regra de encavalar), a Tabela D (cascata, arco-íris e ilha alta pela medição do developer, e o mar de nuvens em volta) e os critérios correspondentes. As mudanças estão marcadas com **(f1)**.

**Vem depois de:** `011` (fechada em `revisoes/011-f3.md`). Mantém da 011 o kit, o `MapLayout`/`MapData` por marcadores, a arena, o anel, as reservas e a regra "layout feito à mão".
**Arte:** `A08-arte-pintada-ilha.md` (substitui a `A07`). Até a A08 ser aprovada, o developer usa materiais provisórios de cor chapada e gradiente, com a paleta-alvo de `docs/direcao-de-arte.md`.
**Referência principal:** `docs/reference/ilha-flutuante.webp` (906×509).

**Pedidos e decisões do usuário (2026-10-08), literais:**
- Antes desta revisão: "coloque um rio por fora da arena"; "após alguns metros saindo de nossa arena e depois de algumas árvores/rios, seria legal se desse pra identificar que é uma ilha flutuante"; "se esforce para do lado externo da arena ser algo muito bonito visualmente"; "as árvores às vezes estão muito juntas, nem precisa de tantas"; "vamos caprichar de forma mais original agora". Também a câmera um pouco mais inclinada, a escada sem muro cortando, a plateia fora (só árvores) e a arena vazia (o HUD e as peças vão ocupar o espaço).
- Escadas no meio do lado comprido, como na referência: "Sem problemas. é só visual e ficou top".
- Luz e composição: "Sim, tudo bem deixar dia claro com toque quente, mas esse gráfico exatamente, nessas posições, igual a todo, tudo".
- Estilo: "Pixel art serão só os personagens".
- Arte procedural: "sim". Texturas, ruído e gradientes gerados por código com seed fixa são permitidos nos scripts de arte e nos shaders. O layout continua feito à mão (D1, decidida).

## Objetivo
Na câmera padrão (yaw 0), a captura do jogo tem a mesma composição da `ilha-flutuante.webp`, quadro a quadro: o anfiteatro no centro, a ilha compacta em volta, com mata nos lados e borda de penhasco logo abaixo, a cascata larga da ilha alta ao fundo com arco-íris, as ilhotas, as pontes, as rochas flutuantes, as tochas e o mar de nuvens. O cenário é 3D pintado, com dia claro e toque quente. Girando a câmera, cada lado continua bonito e lê como ilha flutuante.

## Decisões tomadas (Lead Project, 2026-10-08)
1. **Câmera padrão medida na referência.** Ajustei uma câmera aos cantos do muro alto e do degrau baixo da imagem (8 pontos, erro médio de 6 px em 906). O resultado foi **pitch 27°, FOV vertical 37°, distância 54** e o ponto de mira **4,3 unidades à frente** do centro da arena (no sentido da vista). As proporções do anel na imagem batem com as nossas (arena 20 × 18, terraço 3, muro 1), então **nada no anel muda de tamanho**. A câmera continua orbitando o centro da arena. O deslocamento de 4,3 é só de enquadramento e gira junto com o yaw.
2. **Escadas.** A referência mostra três coisas, e as três entram: (a) **escada no meio do lado sul**, da crista para fora, entre duas tochas, descendo até um patamar semicircular de lajes na borda da ilha; (b) **portões laterais** no oeste (ao sul do meio) e no leste (ao norte do meio), que são exatamente os lances da 011 (oeste z 3 a 6, leste z −6 a −3) e **ficam**; (c) por simetria de 180° (justiça entre os times), uma **escada igual no meio do lado norte**.
   - **Conflito com as reservas resolvido sem mexer nelas.** A passagem sul/norte fica inteira dentro da espessura do muro e para fora: do terraço (0,5) sobe um degrau para 0,75 (z 12,0 a 12,5), chega à crista 1,0 (z 12,5 a 13,0) e desce para fora em 0,75, 0,5 e 0,25 (z 13,0 a 14,5) até o chão. A reserva (`Rect2(-9.5, 9.5, 19, 2.25)`, até z 11,75) não é tocada, continua inteira, e o norte é a rotação de 180° do sul. Largura do lance: 3 (x −1,5 a 1,5).
3. **Rio.** A imagem não mostra rio na ilha principal. A água é a **cascata da ilha alta**, que cai atrás da borda norte, direto nas nuvens. Saem o rio, a lagoa, a ponte de madeira sobre o rio e a cascata leste. (O pedido antigo "rio por fora da arena" fica atendido pela cascata. Se o usuário quiser um riacho discreto, ver D3.)
4. **Ilha compacta, contorno medido.** O contorno é o da Tabela A: de 3,5 a 5,5 unidades além do muro no sul, encostando quase no canto sudoeste, de 5 a 10 no oeste, de 8 a 17 no leste e 7,7 no norte. Saem o raio de 34 a 42, os promontórios dos mirantes e o entalhe da foz.
5. **Sol do oeste-noroeste.** Na imagem, a luz vem do alto à esquerda, por trás. O sol passa a vir do oeste-noroeste, com elevação de 40° a 48° e cor `#FFE9C8` (dia claro, toque quente). Os feixes de luz fortes não entram.
6. **Moldura dos cantos.** Os cipós e as rochas grandes presos nos cantos de cima da imagem são moldura de câmera fixa e, com câmera 360°, taparia a vista em outros ângulos. Viram **duas rochas grandes flutuantes com cipós**, em posição fixa no mundo, que caem nos cantos de cima do quadro em yaw 0.
7. **Bancos atrás do muro norte (ver D2).** A imagem mostra 3 bancos e 2 caixotes ali. A ordem mais nova do usuário é "igual a tudo", então **eles voltam** (peças `bench_wood`/`crate` do kit). Isso contradiz o pedido anterior ("tirar a plateia"), e por isso fica para o usuário confirmar.
8. **Troncos no terraço.** A imagem mostra um tronco caído no terraço oeste e outro no leste, fora das reservas. Eles entram (Tabela B).
9. **Arena.** A mancha de terra alaranjada, o **círculo de pedra quebrado** no meio, de 6 a 10 lajes soltas e pedrinhas, tudo como **decalque plano** (a arena continua plana e sem obstáculo), e tufos baixos e flores espalhados como na imagem.
10. **Ilha alta fora da órbita.** A ilha alta e a cascata ficam a 55 ou mais unidades do centro, maiores e mais baixas que "parecem" na imagem, mas na mesma linha de visada da câmera padrão. Assim a câmera nunca entra nelas nem as tem entre si e a arena. `max_distance` é limitado para a órbita não chegar lá.
11. **Fonte de verdade da cena:** `scenes/map.tscn`. `place_decor.gd` só reaplica a tabela com `-- --force` (como na versão anterior).
12. **Fora do `MapData`:** a ilha, a mata, as pontes, as ilhotas, a cascata e as nuvens são visuais. **Entram** no `MapData` só as passagens sul e norte (marcadores `StairArea`/`HeightArea`), porque mudam a altura do anel. `bounds` continua `Rect2(-24, -24, 48, 48)`.

## Câmera padrão
| Parâmetro | Valor | Antes |
|---|---|---|
| `pitch_degrees` | **27** | 40 (e 35 na versão anterior da 012) |
| `fov_degrees` (vertical) | **37** | 32 |
| `start_distance` | **54** | 43 |
| Ponto de mira | **4,3 unidades à frente** do centro da arena, no sentido da vista (gira com o yaw). Pode ser um `focus_forward_offset` no lugar do `focus_south_ratio` | centro |
| `max_distance` | **≤ 60** | 64 |
| `min_distance` | o developer escolhe (sugestão: 14) | 8 |
| Proporção de captura | 16:9 (1280×720) | — |

A `distance` é medida do ponto de mira até a câmera, ao longo do pitch. Em yaw 0 e distância 54, a câmera fica em **(0; 24,5; 43,8)** e mira (0, 0, −4,3). A órbita gira em torno do centro da arena, com raio horizontal = distance × cos 27° − 4,3 (43,8 no padrão, ≤ 49,2 no máximo). Se o zoom mudar o deslocamento de 4,3, isso fica a critério do developer, desde que o padrão bata com a Tabela E. O giro de 360° só pelo teclado, a volta ao padrão com Espaço e o zoom com limites continuam iguais.

## Croqui de cima (medido na referência)
Coordenadas do mundo: origem no centro da arena, X para leste e Z para o sul. 1 coluna = 1 unidade em X, 1 linha = 2 unidades em Z. A câmera padrão fica ao sul (embaixo do croqui), olhando para o norte.

```
x →    -30       -20       -10       0         10        20        30
       |    +    |    +    |    +    |    +    |    +    |    +    |
  -24                                                       ::TTTT
  -22             MMMMMMMMM                       oooooooT:::TTTTTTT
  -20          MMMMMMMMMMMMM,,,,,,,,,,,,,,,,,,,oooooooooo:::TTTTTTTT
  -18       MMMMMMMMMMMMMMMM,,b,,,,b,,,c,c,,b,,oooooooooo::TTTTTTTTT
  -16      MMMMMMMMMMMMMMMMM,,,,,,,,,,,,,,,,,,,ooooooooo:::TTTTTTTT
  -14      MMMMMMMMMMMMMMMMM,,,,,,,,EEE,,,,,,,,,,,,,,,,:::TTTTTTTTT
  -12      MMMMMMMMMMMM############*EEE*############,,,::TTTTTTTTT
  -10       MMMMMMMMMMM##*-----------------------*##,,:::TTTTTTTTT
   -8        MMMMMMMMMM##--.....................--##,:::,TTTTTTTT
   -6        MMMMMMMMMM##--.....................EEEE:::,,TTTTTTTT
   -4         oooooooo,##l-.....................EEEE::,,,TTTTTTT
   -2          ooooooo,##--.....................--##,*oooooo,,,
    0           oooooo,##--..........O..........--##,ooooooo,,
    2            oooo*,##--.....................-l##,ooooooo
    4   wwwww    ::::::EEEE.....................--##,oooooo
    6  wwwwwww====:::::EEEE.....................--##,ooooo
    8   wwwww =====::::##--.....................--##,ooo
   10               ,,,##*-----------------------*##,oo
   12                 ,############*EEE*############,,===eeee
   14                   """"""""""""EEE"""""""""""""  ==eeeeee
   16                        """"""p:::p""""""""        eeeeee
   18                               :::
z ↓
```
Legenda: `.` arena · `-` terraço (e degrau baixo) · `#` muro alto · `E` escadas e passagens · `*` braseiro · `O` centro do círculo de pedra · `l` tronco caído · `b` banco · `c` caixote · `M` mata mista (coníferas e folhosas) · `T` coníferas · `o` folhosas · `,` grama · `"` grama com flores, arbustos e raízes · `:` lajes (patamar, plataforma e caminho) · `p` pilar de pedra · `=` ponte de corda · `w`/`e` ilhotas oeste/leste.
Fora do croqui (ao norte, além da borda): a ilha alta com a cascata (z de −55 a −70), a ilhota das ruínas (noroeste), a ilhota pequena (nordeste), as rochas flutuantes e as nuvens (Tabela D).

### Tabela A — contorno da ilha (âncoras, sentido horário a partir da ponta sul)
`(0.0, 18.5)` ponta do patamar sul · `(2.4, 17.6)` · `(4.8, 17.2)` · `(7.2, 16.9)` · `(9.7, 16.3)` · `(12.2, 15.6)` · `(14.6, 14.1)` · `(16.4, 11.8)` cabeceira da ponte leste · `(18.5, 8.8)` · `(20.5, 5.5)` · `(22.5, 2.3)` · `(24.8, -1.2)` · `(26.9, -4.9)` · `(28.3, -9.5)` · `(29.3, -14.3)` · `(30.5, -18.5)` · `(31.0, -22.7)` · `(27.5, -24.6)` · `(23.0, -24.1)` fim do caminho nordeste · `(19.0, -23.6)` · `(15.0, -22.6)` · `(10.0, -21.4)` · `(4.8, -20.7)` · `(0.3, -20.4)` · `(-4.3, -20.7)` · `(-9.0, -21.6)` · `(-13.8, -22.9)` · `(-18.0, -22.6)` · `(-22.0, -20.8)` · `(-25.0, -18.0)` · `(-26.8, -14.5)` · `(-25.5, -9.5)` · `(-23.6, -4.0)` · `(-22.3, -1.2)` · `(-20.9, 1.7)` · `(-19.8, 4.8)` · `(-18.7, 7.8)` cabeceira da ponte oeste · `(-17.0, 10.3)` · `(-15.5, 12.1)` · `(-14.6, 13.7)` · `(-12.4, 14.7)` · `(-9.5, 15.7)` · `(-6.8, 16.5)` · `(-4.4, 17.0)` · `(-2.2, 17.7)`.

O `ISLAND_OUTLINE` final é uma lista literal de 56 a 90 vértices, escrita à mão, que passa a ≤ 0,75 de cada âncora, com arestas ≤ 3 e espaçamento irregular (pequenas baías e saliências entre as âncoras). Valem as proibições: nada de círculo ou elipse com variação, nada de raios polares, nada de lista reaproveitada em escala.

### Tabela B — estruturas e objetos (posições medidas; ± 0,5)
| Item | Posição (x, z) | Notas |
|---|---|---|
| Passagem sul | x −1,5 a 1,5; z 12,0 a 14,5 | decisão 2; peças novas `stair_crest_in_3` (degraus 0,75 e 1,0 dentro do muro) e o lance de fora (0,75 → 0,25) |
| Patamar sul | semicírculo de lajes de x −2,5 a 2,5, z 14,5 a 18,0; pilares de pedra (0,5 × 0,5 × 1,0) em (±1,7; 16,0) | a borda da ilha contorna o patamar (ponta em z 18,5) |
| Passagem norte | rotação de 180° da sul | patamar norte curto (z −14,5 a −16,0), sem pilares, para não encostar nos bancos |
| Portões oeste e leste | os lances da 011 (oeste z 3 a 6, leste z −6 a −3), com a peça de passagem na crista (`stair_crest_3`) e o patamar com lajes no terraço (`stair_landing_3`) | como a versão anterior da 012, item 2 da Fase 1 |
| Plataforma oeste | lajes de x −20 a −15, z 4 a 9,5 | liga o portão oeste à cabeceira da ponte oeste |
| Caminho nordeste | lajes, largura de 2,5 a 3, linha central (15, −4.5) → (17, −8) → (19.4, −14.3) → (21, −19.5) → (23, −24.1) | termina na borda, num pequeno alargamento de lajes |
| Ponte de corda oeste | de (−18.7, 7.8) até a ilhota oeste, em cerca de (−23.5, 7.0), descendo cerca de 1,0 com flecha de 0,4 | largura 1,5 |
| Ponte de corda leste | de (16.4, 11.8) até a ilhota leste, em cerca de (19.5, 13.6), descendo cerca de 1,0 com flecha de 0,3 | largura 1,5 |
| Braseiros (10) | crista, ladeando as escadas: (±1.75, 12.5) e (±1.75, −12.5); cantos do terraço: (−12.2, −10.75), (12.2, −10.75), (−12.2, 10.75), (12.2, 10.75); fora dos portões: (−15.8, 2.0) e (15.8, −2.0) | `OmniLight3D` sem sombra em cada um |
| Bancos e caixotes (D2) | bancos em (−6.7, −18.2), (−2.4, −18.2) e (7.3, −18.2), ao longo de X; caixotes em (1.5, −18.2) e (3.7, −18.2) | peças do kit |
| Troncos caídos | terraço oeste (−12.3, −4.0) e terraço leste (12.2, 1.8), ao longo de Z | fora das reservas |
| Terra da arena | mancha de cerca de 13 a 14,5 × 10 a 11, centro em (0.3, −1.0), alongada em X | decalque; **(f1)** borda escura avermelhada e plantinhas dentro (A08) |
| Círculo de pedra **(f1)** | centro em (0.4, −0.9). Medido de novo: **disco de terra escura** de raio cerca de 1,3 com miolo claro irregular; **dois crescentes claros** (terra batida/pedra lisa) a oeste e a leste, até raio 1,9, abertos ao norte e ao sul; **anel externo quebrado** de 5 a 7 pedras compridas e curvas (1,2 a 1,8 × 0,25 a 0,4) em raio de 3,5 a 4,5, com falhas | decalque plano (A08 `arena_ring` + `arena_slabs`). Não é um anel regular de lajes |

### Tabela C — mata por zona (contagens tiradas da imagem; **(f1)** recontadas)
Na referência, a mata do noroeste e a do leste são **maciços contínuos e escuros**: as copas se tocam e se sobrepõem, encostam na face externa do muro e passam da borda da ilha. O respiro vem das áreas abertas fixas (faixa norte, faixa sul, terraço, entorno das lajes e do caminho), não de espaço entre cada árvore.

| Zona | Área (x; z) | Conteúdo |
|---|---|---|
| Noroeste (`M`) | x −27 a −10; z −23 a −5 | **(f1)** 24 a 32 árvores: coníferas altas e escuras no fundo e entremeadas, folhosas redondas na frente e na borda oeste. Massa contínua do muro até a borda, sem gramado aparecendo entre as copas na câmera padrão. É a massa mais alta à esquerda do quadro |
| Oeste perto do portão (`o`) | x −23 a −16; z −5 a 3 | **(f1)** 4 a 6 folhosas e arbustos, deixando livre a plataforma oeste |
| Norte central | x −9 a 10; z −21 a −14,5 | **aberta**: grama, bancos, 1 ou 2 folhosas na ponta oeste, cerca de (−9.2, −16.6). A cascata aparece por cima dessa faixa |
| Nordeste (`o`) | x 10 a 19; z −23 a −15 | **(f1)** 6 a 9 folhosas redondas, em grupo fechado, à esquerda do caminho, e 1 ou 2 coníferas no meio |
| Leste (`T`) | x 20 a 31; z −25 a −4 | **(f1)** 18 a 26 árvores, pelo menos 2/3 coníferas altas e escuras, do caminho até a borda (copas passando da borda), com 3 a 5 folhosas verde-amareladas entremeadas no meio da massa |
| Frente leste (`o`) | x 16 a 22; z −4 a 11 | **(f1)** 6 a 8 folhosas redondas **grandes** (copa de 4,5 a 5,5), cerca de (19.2, −3.3), (19.9, 2.3), (15.1, 5.8) e (16.1, 9.8), mais arbustos entre elas |
| Sul (`"`) **(f1)** | faixa entre o muro e a borda | sem árvores. **18 a 26 arbustos** em grupos (ao pé do muro e na borda, deixando a escada e o patamar livres), **4 a 6 raízes de superfície** grossas serpenteando pela grama até a borda (peça nova `root_surface_a..c`, provisória), flores e tufos densos (MultiMesh), cipós na face externa do muro sul (6 a 10 cartões) |
| Ilhotas oeste e leste | — | uma folhosa grande em cada uma, mais arbustos |

Total na ilha principal: **(f1) de 60 a 82 árvores** (eram 40 a 58). Regras **(f1)**:
- **Encavalar:** a distância entre troncos é ≥ max(1,2; 0,45 × (r_a + r_b)), com r = raio da copa. Copas podem se sobrepor até cerca da metade, como na imagem. (Antes: ≥ 0,8 × (r_a + r_b), que deixava a mata rala.)
- Tronco a ≥ 1,5 da face externa do muro (a copa pode encostar no muro, mas não passa da crista para o terraço), ≥ 0,75 de uma laje ou do caminho e ≥ 1,0 da borda da ilha (copas podem passar da borda).
- O pedido antigo "as árvores às vezes estão muito juntas" era sobre a mata uniforme da 011. Vale a ordem mais nova, "igual a tudo". O respiro fica nas áreas abertas listadas acima.

### Tabela D — fora da ilha
| Item | Posição | Notas |
|---|---|---|
| Ilha alta **(f1)** | corpo de x −13 a 23, z −55 a −70, topo em y de **6,5 a 7,5** | lábio da água em **y ≈ 6,3** (na tela, v ≈ 0,05). Blocos de rocha entre as lâminas: bloco esquerdo de x −6,8 a −3,3 descendo até y ≈ −4 (tela v ≈ 0,21); **esporão central de x 5,8 a 11,5**, que desce até y ≈ −10 (v ≈ 0,29); bloco direito depois de x 14,1 descendo até y ≈ 0 (v ≈ 0,15). Mata baixa e o rio no topo. O fundo cônico fica **atrás das lâminas e da névoa**: na câmera padrão, abaixo do lábio só aparecem água, esses blocos, névoa e nuvem (ver critério da cascata) |
| Cascata (3 lâminas) **(f1)** | medida pelo developer e conferida: esquerda x −9,0 a −6,8; **meio x −3,3 a 5,6, visível inteira** (nada na frente dela); direita x 11,5 a 14,1; do lábio (y ≈ 6,3) até y ≈ −13, em z ≈ −56,45 | névoa de puffs na base (y −10 a −15, e subindo até y ≈ −4 entre as lâminas), que se funde ao mar de nuvens |
| Arco-íris **(f1)** | fita em arco no plano z ≈ −55,2, do pé em (−0.5, −12.5), topo em (8.6, −1.8), descendo até (15.5, −5.5) (a tabela `RAINBOW_ARC` do developer) | visível só da metade sul da órbita (yaw de 270° a 90° passando por 0°) |
| Ilhota das ruínas | centro em (−34, 0, −58), raio de cerca de 9 | 4 a 6 colunas (duas com lintel formando um pórtico, as outras quebradas), tambores caídos, 3 a 5 coníferas e folhosas pequenas |
| Ilhota pequena nordeste | centro em (43, −3, −78), raio de cerca de 3,5 | uma coluna e verde no topo |
| Ilhota oeste (`w`) | centro em (−27, −1.2, 6), raio de cerca de 3,5 | ponte oeste; folhosa grande |
| Ilhota leste (`e`) | centro em (21.5, −1.5, 14.5), raio de cerca de 3 | ponte leste; folhosa grande |
| Rochas grandes com cipós (decisão 6) | (−41, 10, −30) e (43, 8, −30) | caem nos cantos de cima do quadro em yaw 0 |
| Rochas flutuantes | 8 a 12, de 0,5 a 2,5 de tamanho, por exemplo (45, 8, −40), (46, −8, −40), (−39, 4, −40), (−52, −10, −40) e uma pequena com grama perto da ilhota leste | opcional: sobe e desce devagar, determinístico por `TIME` |
| Mar de nuvens | aglomerados de y −6 a −30 em volta e embaixo da ilha, mais denso nos lados esquerdo e direito do quadro e embaixo da borda sul | não projeta sombra |
| Anel de nuvens do horizonte **(f1)** | 10 a 16 aglomerados largos em volta da ilha inteira, com raio horizontal de 35 a 60 e topo em y de −2 a −6 | aparecem logo acima da borda distante nas vistas giradas (y90, y180, y270), para a borda ler como "fim da ilha" e não como fim de um morro. Valem a regra da órbita e a visibilidade da arena |

Regra da órbita: todo vértice fora da ilha principal com raio horizontal r ≤ 60 fica com r ≥ 55, **ou** abaixo de y = 0,51 × r − 4 (0,51 = tan 27°). Assim a câmera nunca entra nem fica atrás dessas peças.

### Tabela E — âncoras de composição (para `test_composition.gd`)
A posição esperada na tela é a da referência, normalizada (0 a 1, a partir do canto de cima à esquerda).
| Âncora | Mundo (x, y, z) | Tela esperada (u, v) |
|---|---|---|
| Crista NW | (−13.5, 1.0, −12.5) | (0.304, 0.387) |
| Crista NE | (13.5, 1.0, −12.5) | (0.681, 0.387) |
| Crista SW | (−13.5, 1.0, 12.5) | (0.189, 0.768) |
| Crista SE | (13.5, 1.0, 12.5) | (0.781, 0.745) |
| Degrau NW | (−10.25, 0.5, −9.25) | (0.353, 0.432) |
| Degrau NE | (10.25, 0.5, −9.25) | (0.642, 0.432) |
| Degrau SW | (−10.25, 0.5, 9.25) | (0.296, 0.701) |
| Degrau SE | (10.25, 0.5, 9.25) | (0.698, 0.701) |
| Tocha sul esquerda | (−1.75, 1.4, 12.5) | (0.456, 0.756) |
| Tocha sul direita | (1.75, 1.4, 12.5) | (0.533, 0.756) |
| Ponta do patamar sul | (0, 0, 18.5) | (0.497, 0.953) |
| Cabeceira oeste | (−18.7, 0, 7.8) | (0.130, 0.688) |
| Cabeceira leste | (16.4, 0, 11.8) | (0.838, 0.770) |
| Fim do caminho nordeste | (23.0, 0, −24.1) | (0.762, 0.314) |
| Centro do círculo | (0.4, 0, −0.9) | (0.499, 0.544) |

## Escopo

### Fase 1: câmera, passagens e composição (materiais provisórios; não depende da A08)
1. **Câmera** (`scripts/map/map_camera.gd`): os valores da tabela "Câmera padrão". `--overview` e `--distance=N` continuam só para captura. Nenhuma regra de jogo depende disso.
2. **Passagens sul e norte** (decisão 2): as peças `stair_crest_in_3` e o lance de fora (pode reusar o `stair_outer_3`, se a altura e o passo baterem), os marcadores `StairArea`/`HeightArea` no `map.tscn` e os `wall_high_*` que cruzavam a passagem, que saem. Pontas de muro fechadas, sem fresta.
3. **Portões oeste e leste:** `stair_crest_3` e `stair_landing_3`, como na versão anterior (a crista não corta mais o lance).
4. **Ilha principal** (`tools/kit/island_tables.gd`, malhas por `build_kit.gd`): `ISLAND_OUTLINE` (Tabela A); `island_top` (o polígono menos o anel, triangulado com `Geometry2D`, UV de mundo); `island_cliff` (face em **blocos**: o contorno ganha degraus e reentrâncias de 0,3 a 1,0 na vertical e na horizontal, em tabela, de 0 a −3,5); `island_under` (fundo cônico em 6 a 9 anéis literais, ápice irregular em cerca de −20, com 2 ou 3 esporões); `root_hang_a..c` (6 a 10 instâncias, concentradas no sul e no oeste, como na imagem); cipós pendentes (cartões, 8 a 14).
5. **Estruturas e objetos da Tabela B:** patamar sul com pilares, patamar norte, plataforma oeste, caminho nordeste, pontes de corda (`bridge_rope_w`, `bridge_rope_e`: tábuas, 2 postes em cada ponta, cordas de corrimão e pendentes em catenária **em tabela** com 9 a 13 pontos), braseiros (`brazier_a`: pedestal, bacia e chama provisória emissiva, mais `OmniLight3D` sem sombra, alcance ≤ 4), bancos, caixotes e troncos.
6. **Mata** (Tabela C), reescrita à mão em `map_decor_table.gd` e aplicada uma vez com `--force`. A plateia antiga e os `forest_backdrop_*` saem. As peças de árvore ganham a forma "pintada" (lóbulos redondos de cartões e coníferas em andares de cartões), com material provisório de gradiente por altura.
7. **Fora da ilha** (Tabela D): ilha alta (`island_high`), 3 lâminas de cascata com rolagem provisória, névoa, arco-íris provisório, ilhotas (`islet_ruins`, `islet_ne`, `islet_w`, `islet_e`), colunas (`ruin_column_a..c`, `ruin_lintel`), rochas e mar de nuvens provisório (aglomerados de esferas achatadas brancas com gradiente lavanda, até a A08).
8. **Céu provisório:** shader de céu próprio, já com o gradiente da paleta-alvo e **o céu abaixo do horizonte claro**. Sol na direção da decisão 5.
9. **Desempenho:** a impressão de `draw calls` e `primitives` do modo de captura continua. Use `MultiMeshInstance3D` para tufos, flores, pedrinhas, rochas pequenas e vaga-lumes, e junte malhas por material onde fizer sentido (um material por árvore, com atlas).
10. **Testes:** `test_map_layout` atualizado (ver critérios); `test_arena_visibility` com a câmera nova e com as peças novas como oclusores; `test_island.gd` reescrito; novo `test_composition.gd` (Tabela E).
11. **Capturas da Fase 1:** `docs/screenshots/012-f1-default.png`, `012-f1-y90`, `012-f1-y180` e `012-f1-y270`, e `012-f1-comparacao.png` (a referência à esquerda, ampliada para 1280×720, e a captura padrão à direita) e `012-f1-sobreposicao.png` (as duas misturadas a 50%).

### Fase 2: estilo pintado (depois da A08, leva 1)
12. **Shaders do cenário** (sem addons): chão (mistura de 2 ou 3 gramas por máscara de mundo, AO por cor de vértice), pedra (musgo pela normal, chanfro claro), folhagem (normais esféricas, wrap, gradiente por altura, luz de borda quente, alpha scissor + alpha-to-coverage, balanço leve), penhasco (triplanar, escurece e esfria para baixo). O `kit_surface.gdshader` em pixel art fica só para referência, ou sai.
13. **Texturas:** filtro linear com mipmaps e anisotrópico em todas as do cenário. Densidade de 64 px por unidade (constante própria, separada da `TEXELS_PER_UNIT` dos personagens).
14. **Luz e pós** conforme a direção de arte: sol `#FFE9C8` do oeste-noroeste, ambiente do céu, SSAO leve, bloom leve, névoa de profundidade lavanda depois da borda e névoa de altura abaixo de −3, desfoque só no fundo e **fraco** (**(f1)**: na Fase 1, a ilhota das ruínas e a ilha alta saem borradas demais; na referência, elas são nítidas e só a névoa as suaviza), Filmic ou AgX, MSAA 4×, sem TAA/FXAA e sem vinheta. `test_atmosphere` é atualizado para esses valores.
15. **Arena:** decalques de terra, círculo de pedra, lajes soltas e pedrinhas (A08), e tufos baixos e flores espalhados. **(f1)** O círculo segue a Tabela B nova (disco escuro, crescentes claros e anel externo de pedras compridas). As lajes soltas atuais (cartões cinza retangulares de borda dura) saem.

### Fase 3: água, penhasco, nuvens e efeitos (depois da A08, leva 2) e comparação final
16. Cascata (riscos rolando, espuma, névoa), arco-íris, penhasco e fundo com a arte nova, raízes e cipós, nuvens (puffs billboard pintados com alfa suave, ordenados por aglomerado, mais o mar de nuvens embaixo), chama em flipbook e vaga-lumes (28 a 48, em tabela, em volta das matas noroeste e leste e da cascata).
17. Capturas finais: `docs/screenshots/012-default.png`, `012-y90.png`, `012-y180.png`, `012-y270.png`, `012-escada-sul.png` (yaw 0, `--distance` que mostre a escada e o patamar de perto), **`012-comparacao.png`** e `012-sobreposicao.png`.

## Fora de escopo
- Mudar o tamanho da arena, das reservas, do anel ou das alturas (fora as passagens da decisão 2).
- Encher a arena de objetos com volume. Na arena só entram decalques planos e tufos baixos.
- Rio na ilha principal (decisão 3), física da água, reflexo em tempo real e som.
- Personagens, combate, loja e rede.
- Apagar PNG antigos (A03, A06 e pixel art) sem OK do usuário.
- Gerador de posição para qualquer coisa do mapa. Ruído e gradiente com seed fixa são permitidos nos shaders e na arte (D1), nunca no layout.

## Design técnico sugerido
- **Tabelas em `tools/kit/`** (`island_tables.gd`, `kit_tables.gd` e `map_decor_table.gd`), malhas por `build_kit.gd` e cenas em `scenes/kit/`. Grupos no `map.tscn`: `Island`, `Structures` (passagens, patamares, pontes e braseiros), `Forest`, `Props`, `Sky` (ilha alta, cascata, ilhotas, rochas e nuvens) e `Fx` (vaga-lumes e névoa).
- **Shaders em `assets/materials/`:** `scenery_ground`, `scenery_stone`, `scenery_foliage`, `scenery_cliff`, `water_fall`, `cloud_puff`, `sky_day` e `rainbow`. Animações só por `TIME` (rolagem, flipbook, balanço), sem sorteio.
- **Dither de oclusão:** continua para árvores e passa a valer também para rochas e ilhotas que fiquem entre a câmera e a arena (não deve acontecer, pela regra da órbita, mas é a rede de segurança).
- **Parâmetros `@export`:** velocidade da cascata, quadros por segundo da chama, intensidade do arco-íris, força das névoas e balanço da folhagem.
- **`main.gd` em modo de captura:** `--yaw=N`, `--distance=N`, `--overview` e a impressão de desempenho, como antes.

## Direção de arte
`docs/direcao-de-arte.md` (reescrita em 2026-10-08) e `docs/reference/ilha-flutuante.webp`. Na câmera padrão, cada massa fica no lugar dela: mata alta à esquerda, coníferas à direita, faixa norte aberta com a cascata por cima, arco-íris à direita da cascata, ilhota das ruínas no alto à esquerda, ilhota pequena no alto à direita, pontes saindo pelas laterais de baixo, penhasco marrom com raízes embaixo e nuvens nos cantos. O resto da órbita segue a mesma linguagem.

## Critérios de aceite

**Automáticos**
- [ ] `test_composition.gd`: com a câmera padrão (yaw 0, 1280×720), cada âncora da Tabela E projeta a ≤ 0,025 (em u e em v) da posição esperada.
- [ ] `test_map_layout`: arena, reservas, `terrace_rect` e justiça por rotação de 180° iguais aos da 011. A crista em 1,0 passa a ser conferida em (±5, ±12.5) e (±13.5, 0). Alturas novas: (0, 12.25) = 0,75; (0, 12.75) = 1,0; (0, 13.25) = 0,75; (0, 13.75) = 0,5; (0, 14.25) = 0,25; (0, 14.75) = 0; e o simétrico no norte. A reserva em (0, 11.5) continua 0,5. O fingerprint é atualizado e registrado no relatório.
- [ ] `get_height_at` em (−13.5, 4.5) e (13.5, −4.5) = 1,0, e ao andar pelo eixo de cada escada (as 4) a altura muda só em saltos de 0,25. Nenhum `wall_high_*` tem pegada que cruze `Rect2(-14, 3, 1, 3)`, `Rect2(13, -6, 1, 3)`, `Rect2(-1.5, 12, 3, 1)` ou `Rect2(-1.5, -13, 3, 1)`.
- [ ] `ISLAND_OUTLINE`: de 56 a 90 vértices, polígono simples, arestas ≤ 3, a ≤ 0,75 de cada âncora da Tabela A. O muro externo inteiro (`Rect2(-14, -13, 28, 26)`) fica dentro, a ≥ 0,75 da borda.
- [ ] Mata **(f1)**: de 60 a 82 árvores na ilha principal, com as contagens por zona da Tabela C. Nenhum par de troncos a menos de max(1,2; 0,45 × (r_a + r_b)). As distâncias de tronco da Tabela C são respeitadas. Faixa sul: de 18 a 26 arbustos e de 4 a 6 `root_surface_*`, nenhum sobre a escada ou o patamar. A faixa norte central (x −8 a 10, z −21 a −14,5) não tem tronco de árvore.
- [ ] Regra da órbita (Tabela D) válida para todos os vértices de `Sky`. `max_distance` × cos 27° − 4,3 ≤ 50.
- [ ] Visibilidade da arena com a câmera nova: 100% em yaw 0/90/180/270 e ≥ 97% em 45/135/225/315, na distância padrão e na máxima.
- [ ] 10 braseiros e 10 `OmniLight3D`, todos com `shadow_enabled = false` e alcance ≤ 4.
- [ ] O `map.tscn` não tem rio, lagoa, ponte sobre rio nem cascata leste (nenhuma instância de `river_*`, `bridge_wood` ou `waterfall` fora de `Sky`).
- [ ] `grep -rnE "RandomNumberGenerator|FastNoiseLite|randi\(|randf\(|randomize" scripts/map scripts/match tools/kit` não retorna nada (o layout continua feito à mão). Ruído com seed fixa só aparece em `tools/art/`, em recursos de textura (`NoiseTexture2D` com seed fixa) ou em shaders.
- [ ] `build_kit.gd` rodado duas vezes dá `.res` idênticos (md5). `place_decor.gd` sem `--force` sai com código ≠ 0 e não altera o `map.tscn`.
- [ ] Desempenho na impressão do modo de captura a 1280×720: **≤ 500 draw calls** na câmera padrão (a câmera padrão já mostra a ilha quase inteira) e ≤ 650 em `--overview`. Registre os números no relatório.

**Por captura (Lead Project)**
- [ ] `012-comparacao` e `012-sobreposicao`: na sobreposição, o anel, a borda da ilha, as massas de mata, a cascata, as ilhotas, as pontes e as tochas caem no mesmo lugar da referência (diferença visível ≤ cerca de 3% do quadro). Lado a lado, as duas imagens leem como "o mesmo lugar".
- [ ] Cores **(f1, Fase 2)**: na captura padrão sem HUD (`--hud=off`), a cor média de cada caixa abaixo fica a ≤ 8% (distância RGB normalizada) do valor medido na referência ampliada para 1280×720. Caixas em pixels (x0, y0, x1, y1): terra da arena (560, 400, 640, 440) `#B3843D`; grama da arena oeste (400, 330, 480, 400) `#7F8033`; grama da arena frente (420, 450, 600, 500) `#717B22`; mata noroeste (170, 250, 300, 380) `#58572B`; coníferas leste (1000, 250, 1100, 400) `#384F21`; folhosas nordeste (800, 150, 940, 230) `#616F58`; face externa do muro sul (300, 555, 560, 575) `#2A3C27`; penhasco da frente (400, 650, 560, 710) `#38302A`. Na Fase 3, entram também: céu alto à direita (870, 0, 960, 30) `#B4BAD9`; céu alto à esquerda (130, 0, 230, 30) `#E2D1C1`; nuvem à esquerda (40, 320, 140, 380) `#D9C7C2`; nuvem embaixo à esquerda (30, 560, 150, 700) `#938B8C`; nuvem à direita (1190, 330, 1270, 420) `#B9B3BA`. O developer acrescenta essa conta ao `tools/dev/compare_images.gd` e registra a tabela no relatório.
- [ ] Variação **(f1, Fase 2)**: a terra e a grama da arena não são chapadas. Na caixa da terra (480, 330, 800, 470), o desvio-padrão da luminância dos pixels de terra fica ≥ 22 (a referência dá 28; a Fase 1 deu 16).
- [ ] Estilo (Fase 2 e 3): cenário pintado, sem pixel aparente nem Nearest, com copas redondas e fofas, pedra bege com musgo no topo, terra alaranjada, penhasco marrom em blocos e nuvens fofas lavanda e brancas. Dia claro com toque quente, sem tarde dourada e sem vinheta.
- [ ] Nas 4 capturas de giro: o fundo é mata → borda → nuvens/céu, e a ilha lê como flutuante em todas. **(f1)** Em y90, y180 e y270, nuvens do anel do horizonte aparecem logo acima da borda distante em pelo menos metade da largura dela. Em `012-y180`, a ilha alta não aparece entre a câmera e a arena.
- [ ] `012-escada-sul`: a escada sai da crista entre as duas tochas e desce até o patamar com os pilares, sem muro atravessado e sem fresta.
- [ ] Mata **(f1)**: as massas do noroeste e do leste leem como maciços contínuos e escuros, como na referência (sem gramado entre as copas na câmera padrão), e o respiro fica nas áreas abertas (faixa norte, faixa sul, terraço e entorno das lajes).
- [ ] Cascata **(f1)**: na captura padrão sem HUD, a cor média da caixa u 0,484–0,539 × v 0,111–0,25 (a lâmina do meio) fica a ≤ 15% de `#BCCEDC` (≤ 8% na Fase 3) (distância RGB normalizada), e abaixo do lábio da ilha alta só aparecem água, os blocos da Tabela D, névoa e nuvem (o fundo cônico não aparece como massa marrom entre as lâminas).
- [ ] Faixa sul **(f1)**: entre o muro sul e a borda, a captura mostra arbustos, raízes e flores como na referência. A cor média da caixa u 0,195–0,328 × v 0,82–0,875 fica a ≤ 12% de `#2C3F1E`.

**Sempre**
- [ ] Os dois comandos de validação do `CLAUDE.md` sem `ERROR`/`SCRIPT ERROR` nem warnings do nosso código. Todos os `tools/tests/test_*.gd` com código 0.
- [ ] Relatório com os arquivos criados, alterados e removidos, como testar (F5, giro, zoom), os números de desempenho e as limitações.

## Decisões que ficam com o usuário (com recomendação)
- **D1. Ruído procedural na arte: DECIDIDA pelo usuário (2026-10-08), sim.** Texturas, ruído e gradientes gerados por código com seed fixa são permitidos nos scripts de arte e nos shaders. O layout continua feito à mão.
- **D2. Bancos atrás do muro norte.** A imagem tem 3 bancos e 2 caixotes ali, e antes o usuário pediu para tirar a plateia. **Recomendação: manter, porque a ordem mais nova é "igual a tudo" e eles quase não aparecem atrás do muro.**
- **D3. Rio.** A imagem não tem rio na ilha principal. **Recomendação: ficar só com a cascata.** Alternativa: um riacho estreito saindo da faixa norte para a borda nordeste, fora do quadro padrão, que não contradiz a imagem.
- **D4. Arte de terceiros (CC0).** Se a pintura por script não chegar perto da referência na primeira prévia da A08, a alternativa é usar pacotes CC0 estilizados, o que pede aprovação. **Recomendação: não por enquanto; decidir depois da prévia da A08, leva 1.**

## Mudanças desta revisão (para quem leu a versão anterior)
- Saíram: o rio, a lagoa, a ponte de madeira, a cascata leste, a árvore anciã, os mirantes, as trilhas longas sudoeste/nordeste (e os decalques `decal_trail_sw/ne_a/ne_b` da A07), a ilha de raio 34 a 42, as ilhotas a 80–120 e a pixel art no cenário.
- Entraram: a câmera medida (27° / 37° / 54 / +4,3), a passagem sul e a norte, o patamar sul, a plataforma oeste, o caminho nordeste, as pontes de corda, as ilhotas laterais, a ilha alta com a cascata e o arco-íris, a ilhota das ruínas, as rochas com cipós, os 10 braseiros, os bancos e os troncos (D2), o círculo de pedra e o teste de composição.
- **(f1, 2026-10-08)** Mata de 60 a 82 árvores com copas que se sobrepõem (regra de troncos 0,45 × (r_a + r_b)); faixa sul com 18 a 26 arbustos, raízes de superfície e cipós no muro; cascata, arco-íris e ilha alta pela medição do developer, com o lábio em y ≈ 6,3 e o fundo cônico escondido; anel de nuvens do horizonte para as vistas giradas; círculo de pedra medido de novo; critérios de cor por caixa (Fase 2 e 3).
- Ficaram: o kit, os marcadores do `MapData`, as passagens de crista dos portões laterais, `place_decor` com `--force`, o `map.tscn` como fonte de verdade e o limite de 500 draw calls.
