# A07 — Arte da ilha flutuante, do rio e das transições

**Revisão 1 (2026-10-08): referência `ilha-flutuante.webp`. SUBSTITUÍDA pela `A08-arte-pintada-ilha.md`. Não gerar.** No mesmo dia, o usuário decidiu que o cenário deixa de ser pixel art ("Pixel art serão só os personagens") e que a composição segue 1:1 a referência nova. O rio, as trilhas longas e todo o pixel art do cenário saem (ver `012`, revisão 1). A leva 1 desta spec foi interrompida antes de gravar arquivos. O texto abaixo fica só como histórico.

**Usada por:** `012-ilha-flutuante-rio.md`. O developer integra na Fase 2 da 012 e, até lá, usa materiais provisórios.
**Depende de:** `docs/direcao-de-arte.md`, `A06-arte-mapa-a-mao.md` (regras gerais, contornos e checagem, que continuam valendo) e a referência `docs/reference/Gemini_Generated_Image_6oy5mo6oy5mo6oy5.jpg`.
**Pedido do usuário (2026-10-08):** "melhore a integração das texturas de terra, em alguns momentos parece que só jogou uma grama mais clara ou mais escura"; "as estradas não estão interligadas de forma natural, é possível perceber os quadrados de texturas"; rio por fora da arena; ilha flutuante; "se esforce para o lado externo da arena ser algo muito bonito visualmente".
**Substitui** a parte D da `revisoes/011-f3.md` (polimento da A06). As notas 2, 4 e 6 da A06 entraram aqui, e a nota 3 foi cancelada.

## Objetivo
Dar à 012 a arte que falta: terra e grama que se fundem em 2 a 3 tons (e não adesivos chapados), trilhas desenhadas como peça única sobre o traçado, muro redesenhado para a face de 1,0, água e cascata em pixel art limpa, a borda e o fundo da ilha em estratos de terra e rocha com raízes, nuvens volumosas e acentos de cor (copas outonais e floridas, pedra de musgo). Tudo tem de ler bem de longe e como pixel art limpa de perto.

## Regras
- Valem as regras gerais da A06: sem RNG, sem ruído e sem hash de posição. Contornos são listas de vértices escritas à mão (proibidos raios polares, elipse com variação e Voronoi). Alfa binário, com RGB dos pixels transparentes igual ao do vizinho opaco. Sem contorno preto, sem luz lateral, sem gradiente global. Normal map só em pedra e madeira, convenção OpenGL.
- 32 texels por unidade. Exceções de tamanho, como tiras e decalques grandes, ficam na tabela.
- **Transição em 2 a 3 tons (vale para todo decalque de chão desta spec):** a borda de uma mancha nunca vai direto do tom da mancha ao tom do chão. Ela tem (a) um aro ou faixa intermediária de 1 a 3 px, (b) de 4 a 12 "dedos" ou baías que entram de 3 a 16 px pelos dois lados da borda, e (c) de 6 a 20 tufos ou pontos soltos (1 a 4 px) do tom da mancha fora dela e do tom do chão dentro dela, a até 12 px da borda. Proibido: borda lisa com serrilhado uniforme, mancha redonda ou oval e duas manchas com a mesma silhueta.
- Cores novas: só os grupos novos abaixo, além da paleta de `docs/direcao-de-arte.md`. Se faltar alguma, proponha no relatório.

### Grupos de paleta novos (válidos a partir desta spec)
| Grupo | Sombra → Luz | Uso |
|---|---|---|
| Água | `#123E4E` `#1B5866` `#25707A` `#3A8C8C` `#5AA8A0` `#8CCCC0` | rio, lagoa e cascata. `#25707A` é a base, e os 2 tons mais claros ficam só em brilhos e ondinhas |
| Espuma | `#C8E8E0` `#F0FAF6` | espuma na margem, na foz e na cascata |
| Nuvem | `#8FA9BC` `#B4CAD6` `#D3E2E8` `#EAF2F4` `#FAFCFC` | nuvens. `#EAF2F4` é a base, sem branco puro |
| Folhagem outonal | `#4A2A1E` `#6E3A22` `#9A4E26` `#C46E2C` `#DE9A3C` `#F0C25A` | copa outonal (acento) |
| Florada | `#7E3A5A` `#B05A7E` `#D884A2` `#F0B4C6` `#FBE0E8` | flores na casca da copa florida (sobre folhagem verde) |

A borda da ilha usa os grupos existentes: Terra escura, Terra, Pedra, Pedra fria (só no fundo, mais fria e distante) e Musgo. As raízes usam Casca e madeira.

## Escopo — arquivos

### 1. Muro para a face de 1,0 (`assets/textures/wall/`, + `_n`)
| Arquivo | Tamanho | Conteúdo |
|---|---|---|
| `wall_high_face.png` (regerar) | **256×32** (8 × 1,0) | Mesmo estilo da A06, mas com 32 linhas que formam o muro completo, inclusive a fiada de base (blocos maiores embaixo). A face interna usa as linhas 0–15, que também leem como muro completo (fiada de cima com musgo). Seamless na horizontal. |
| `wall_quoin.png` (regerar) | **32×32** | Amarração longo/curto encostada na coluna 31, com 3 fiadas: linhas 22–31, 12–21 e 4–11. Avise o developer se mudar, porque `QUOIN_COURSES` usa essas fiadas. Coluna 0 compatível com `wall_high_face`. |
| `wall_cap.png`, `wall_crest.png` (regerar) | 256×16 / 256×32 | Nota 4 da A06: lajes de borda **mais alongadas** (de 14 a 36 px de comprimento e altura no máximo metade do comprimento), menos seixo e menos contraste laje/junta (junta `#989680`/`#7A7A66`, sem `#5C6250` na borda). Visto de cima, o capeamento não pode ler como uma fila regular de dentes. |
| `stair_landing.png` | 96×32 (3 × 1) | Piso de lajes do patamar da passagem (`stair_crest_3`, `stair_landing_3`): lajes de 12 a 30 px, no mesmo estilo do `stair_tread`, sem bocel. Musgo e grama raros nas juntas. Seamless na vertical, para emendar 1 com 1. |

### 2. Transições de chão (alfa binário, vista de cima, `assets/textures/decals/`), todas com a regra de 2 a 3 tons
| Arquivo | Tamanho | Conteúdo |
|---|---|---|
| `decal_arena_dirt.png` (regerar) | 448×352 | A mesma mancha da A06, com a nota 2: de 3 a 5 inclusões de grama pequenas junto à borda, o braço nordeste mais grosso e a borda com transição de 2 a 3 tons (aro `#73A949`, dedos de grama `#5B9C47` entrando e pontos de terra `#A8955F`/`#C0AE71` soltos na grama). Continuam valendo os critérios automáticos da A06 para essa peça. |
| `decal_grass_light_0..2`, `decal_grass_dark_0..1` (regerar) | os mesmos | Manchas alongadas e irregulares (proporção ≥ 1,6 : 1, nenhuma redonda), com menos contraste. A clara vai de `#73A949` ao miolo e passa por `#5B9C47` com tufos `#98B654`. A escura vai de `#4E9343` ao miolo, com dedos e tufos `#5B9C47`. De perto e de longe, ninguém deve ver "um adesivo verde". |
| `decal_forest_soil_0..2` (regerar `_0`, `_1`; novo `_2`) | 128×96, 96×128, 160×96 | Terra de mata **misturada** com a grama: miolo `#5A4632`/`#7A6444` em no máximo 40% dos opacos, folhas e gravetos `#876547`/`#A37C56`, raízes finas, e a borda dissolvendo em grama de fora (`#2C7036`/`#3D853C`) em dedos e tufos. Sem miolo escuro chapado (nota 6 da A06). Não pode ler como buraco. |
| `decal_meadow_0..1` | 192×128, 160×160 | Prado florido: grama de fora `#539342`/`#6A9E4A` com 25 a 50 flores de 1 a 3 px (Flores branca, amarela, rosa e azul, em grupos irregulares, nunca em grade). Borda com transição de 2 a 3 tons na grama de fora. |

### 3. Trilhas únicas (alfa binário, vista de cima, `assets/textures/decals/`)
Cada trilha é **uma peça única desenhada sobre o traçado**, no lugar das peças de 3 × 3 encadeadas. Canvas = retângulo de mundo × 32. Pixel (px, py) = ((x − x0) × 32, (z − z0) × 32), com a linha 0 no z0 (norte). As linhas centrais são as da spec 012.
| Arquivo | Retângulo de mundo (x0, z0, larg., fundo) | Tamanho | Linha central (x, z) |
|---|---|---|---|
| `decal_trail_sw.png` | (−29, 3, 14, 22) | 448×704 | (−15, 4.5) → (−16, 4.5) → (−18, 5.2) → (−20, 7) → (−21.5, 10) → (−22.5, 13.5) → (−24, 17) → (−26, 20) → (−27.5, 23) |
| `decal_trail_ne_a.png` | (15, −19, 12, 16) | 384×512 | (15, −4.5) → (16, −4.5) → (18, −5.2) → (20, −7) → (21.5, −10) → (22.5, −13.5) → (23.5, −17) → (24, −19) |
| `decal_trail_ne_b.png` | (21, −30, 7, 7) | 224×224 | (24, −23) → (25.5, −26) → (27, −28.5), terminando na borda do mirante |
- Largura de 3,0 (96 px) no pé da escada, por 1 unidade, abrindo um pouco em leque. No resto, entre 2,2 e 2,8 (70 a 90 px), variando aos poucos.
- Lajes como as da A06 (polígonos de 4 a 7 vértices, de 14 a 32 px, achatadas), **seguindo a direção do traçado** (o eixo maior da laje acompanha a tangente da linha). Nas curvas, as lajes giram e se abrem em leque. Não há nenhuma junta contínua reta com mais de 3 lajes.
- Bordas em 2 a 3 tons: lajes soltas e afundadas na grama na borda (pedaços de laje isolados a até 10 px fora), terra `#7A6444`/`#A8955F` entre as lajes da borda e aro de grama clara. A largura e o perfil da borda mudam ao longo do caminho.
- **Encaixes:** `decal_trail_sw` começa sob a escada (x −15 a −16, faixa de 3 de largura, de z 3 a 6). `decal_trail_ne_a` termina em z −19 e `decal_trail_ne_b` começa em z −23 (sob a cabeceira da ponte). O fim do `ne_b` encosta no mirante.

### 4. Água e cascata (`assets/textures/water/`)
| Arquivo | Tamanho | Conteúdo |
|---|---|---|
| `water_0..3.png` | 64×64 cada, opaco | Superfície vista de cima: base `#25707A`, manchas mais fundas `#1B5866` e de 6 a 12 brilhos e ondinhas de 2 a 6 px (`#5AA8A0`, `#8CCCC0`). Os 4 quadros são uma animação em laço: os brilhos se deslocam de 1 a 2 px e piscam, e o fundo fica igual. Seamless nos 2 eixos. Nada de ruído por pixel. |
| `water_foam_edge.png` | 128×8, alfa | Faixa de espuma e água rasa junto à margem: linhas 0–1 opacas (`#3A8C8C`/`#5AA8A0`), pontos de espuma `#C8E8E0`/`#F0FAF6` em 15% a 35% das linhas 2–7. Seamless na horizontal. |
| `river_bank.png` (+`_n`) | 256×16 (8 × 0,5) | Face da margem: terra úmida (Terra escura), pedrinhas (Pedra) e raízes finas, com o topo de grama de fora nas linhas 0–1. Seamless na horizontal. |
| `river_shore.png` | 128×16, alfa | Faixa de margem por cima da grama (vista de cima): linha 15 = beira da água, cascalho e terra úmida, borda para a grama em 2 a 3 tons. Seamless na horizontal. |
| `waterfall.png` | 96×64 (3 × 2), opaco | Lâmina da cascata vista de frente: faixas verticais de 2 a 6 px nos tons de Água, com riscos de Espuma. Seamless nos 2 eixos (o developer rola para baixo em passos de texel). |
| `waterfall_lip.png` | 96×16, alfa | Espuma na quina da foz: linhas 0–3 opacas, gotas e cortinas descendo até a linha 15. |

### 5. Borda e fundo da ilha (`assets/textures/island/`, + `_n` nos de rocha e terra)
| Arquivo | Tamanho | Conteúdo |
|---|---|---|
| `island_cliff.png` | 256×96 (8 × 3) | Face da borda vista de frente, em estratos de cima para baixo: linhas 0–3 com raízes de grama e terra escura; faixa de terra `#7A6444`/`#5A4632` com pedrinhas; 2 ou 3 estratos de pedra (`#7A7A66` a `#B9B597`) de alturas desiguais que ondulam de 1 a 3 px; manchas de musgo; pontas de raiz. As linhas de estrato não são retas nem paralelas o tempo todo. Seamless na horizontal. |
| `island_under.png` | 128×128 | Fundo cônico: rocha em placas (Pedra e Pedra fria), veios de terra, poucas raízes, mais escura e mais fria que a face. Seamless nos 2 eixos. |
| `cards/island_lip.png` | 128×16, alfa | Beiral de capim pendente na quina da borda (como o `moss_drape`, em grama de fora): linhas 0–1 opacas, cortinas de 1 a 12 px e cobertura de 30% a 55%. Seamless na horizontal. |
| `root_bark.png` (+`_n`) | 32×64 | Casca de raiz grossa (Casca e madeira, fibras na vertical, terra grudada). Seamless na vertical. |
| `cards/roots_hang_0..2.png` | 32×96, alfa | Raízes finas penduradas (de 3 a 7 fios, que se ramificam e afinam até 1 px). Formas diferentes entre si. |

### 6. Nuvens (`assets/textures/sky/`)
| Arquivo | Tamanho | Conteúdo |
|---|---|---|
| `cloud_mass.png` | 64×64, opaco | Miolo dos lóbulos: base `#EAF2F4`, aglomerados suaves de `#D3E2E8` e alguns de `#B4CAD6`, sem lado de luz. Seamless nos 2 eixos. ≥ 70% de base. |
| `cloud_shell.png` | 64×64, alfa | Casca: bordas em "couve-flor" recortadas em pixel, cobertura de 45% a 70%, `#FAFCFC` só no terço de cima de cada aglomerado. Seamless nos 2 eixos. |

### 7. Folhagem e props de acento (`assets/textures/foliage/`, `props/`)
| Arquivo | Tamanho | Conteúdo |
|---|---|---|
| `leaf_mass_autumn.png`, `leaf_shell_autumn.png` | 64×64 (opaco / alfa) | Como os `leaf_*` da A06, no grupo Folhagem outonal. |
| `leaf_shell_bloom.png` | 64×64, alfa | Casca verde (Folhagem verde) com 10 a 18 cachos de flor (Florada) de 2 a 4 px. |
| `rock_moss.png` (+`_n`) | 32×32 | Pedra com musgo no topo (Pedra + Musgo, musgo de 30% a 50%, só no terço de cima da textura). |
| `bridge_plank.png` (+`_n`) | 96×32 (3 × 1) | Pranchas da ponte de través: 5 ou 6 tábuas de larguras diferentes, frestas `#4B3339`, cabeças de prego raras e musgo nas pontas. Seamless na vertical. |

**Prévias** (`docs/art-preview/`): `a07-chao.png` (cada decalque ×1 e ×2 sobre a grama certa, e uma maquete de 24 × 24 unidades a ×1 com a trilha sudoeste, a terra de mata, o prado e a margem do rio sobre `ground_grass_forest`); `a07-agua-ilha.png` (os 4 quadros da água lado a lado e em mosaico 3 × 3, cascata em mosaico 2 × 3, elevação de 8 unidades da borda com `island_lip` + `island_cliff` + raízes, e o `island_under` em mosaico); `a07-muro.png` (elevação de 8 unidades da face de 1,0 e da interna de 0,5, a quina e o patamar); `a07-folhagem-nuvem.png` (×4, com a casca sobre o miolo de cada família).

## Fora de escopo
- Malhas, UV, animação (shader), posições e montagem: é da 012.
- Mudar a paleta existente. Gerar peças de jogo, UI ou monólitos.
- Editar `scripts/`, `scenes/`, `project.godot`, `docs/specs/`. Apagar PNG antigos (os `decal_trail_0..3`/`_bend` ficam no disco até o OK do usuário).

## Critérios de aceite

**Automáticos (`tools/art/check_a07.gd` → `A07 CHECK: PASS`)**
- [ ] Todos os PNG da tabela existem nas dimensões indicadas. Opacos com alfa 255. Decalques e cartões com alfa binário.
- [ ] Todo pixel pertence à paleta existente ou aos grupos novos, e só aos grupos indicados para o arquivo.
- [ ] `grep -nE "RandomNumberGenerator|FastNoiseLite|randi|randf|seed" tools/art/gen_a07_*.gd` não retorna nada. Rodar os geradores duas vezes dá PNG idênticos (md5).
- [ ] Seamless (regra da A03) nos eixos indicados, no albedo e no `_n`. Nos `water_0..3`, também entre quadros: ≥ 85% dos pixels iguais entre quadros vizinhos (o fundo fica parado).
- [ ] Decalques de transição: em cada um, ≥ 3 cores distintas a até 4 px da borda do alfa. Nenhum trecho reto de borda com mais de 6 px. Nenhuma máscara igual a outra, nem girada. Proporção do AABB opaco das manchas de grama ≥ 1,6.
- [ ] `decal_forest_soil_*`: tons de Terra escura em ≤ 40% dos opacos.
- [ ] Trilhas: todo pixel da linha central (amostrada a cada 4 px) a até 10 px de um pixel de laje. Nenhum pixel opaco a mais de 52 px da linha central (fora as lajes soltas a até 62 px). Juntas entre 10% e 20% dos opacos.
- [ ] `wall_high_face` 256×32: as faixas da A06 valem para as 32 linhas e para as linhas 0–15 sozinhas. `wall_cap`/`wall_crest`: ≥ 60% das lajes de borda com comprimento ≥ 2 × altura.
- [ ] Nuvem: `cloud_mass` com `#EAF2F4` ≥ 70%. `cloud_shell` com cobertura entre 45% e 70%.
- [ ] Normal maps com as faixas da A06.

**Visuais (Lead Project, pelas prévias)**
- [ ] Na maquete do chão, nenhuma mancha lê como adesivo: as bordas se fundem em 2 a 3 tons. A terra de mata não parece buraco. O prado lê como flores na grama, não como confete em grade.
- [ ] A trilha sudoeste lê como um caminho de lajes contínuo que acompanha a curva, sem quadrado, emenda ou repetição.
- [ ] A água em mosaico não mostra grade. Os 4 quadros em sequência dão brilho, não piscada do conjunto. A cascata lê como queda d'água em pixel art.
- [ ] A borda da ilha lê como camadas de terra e pedra com capim pendente e raízes, e pede para "olhar para baixo".
- [ ] As nuvens leem como volumes fofos de pixel art, não como ruído branco.
- [ ] A face do muro de 1,0 não parece cortada, e o capeamento visto de cima não lê como dentes.

**Processo**
- [ ] Os dois comandos de validação do `CLAUDE.md` sem `ERROR` depois que os PNG existem.
- [ ] Relatório do artist com a lista final, a autocrítica contra a referência e os avisos ao developer (por exemplo, a mudança das fiadas do `wall_quoin`).

**Ordem sugerida de entrega** (pode ser em 2 levas, cada uma revisada): (1) seções 1, 2 e 3 (muro, transições e trilhas: corrigem o que o usuário já viu); (2) seções 4 a 7 (água, ilha, nuvens e acentos).
