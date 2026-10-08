class_name WorldScale
extends RefCounted
## Escala única do mundo: 1 tile = 1 unidade 3D.
## Único lugar dessas constantes.

## Personagens (pixel art): 32 texels por unidade, pixel_size = 1/32.
const TEXELS_PER_UNIT: int = 32
const PIXEL_SIZE: float = 1.0 / TEXELS_PER_UNIT
## Cenário pintado (spec 012, Fase 2): 64 px por unidade no chão, na pedra e na casca (UV de mundo).
const SCENERY_TEXELS_PER_UNIT: int = 64
## Altura de 1 nível de degrau (corte pela metade: 0.5).
const LEVEL_HEIGHT: float = 0.5
