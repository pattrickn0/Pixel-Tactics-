class_name WorldScale
extends RefCounted
## Escala única do mundo: 1 tile = 1 unidade 3D = 32 texels.
## Único lugar dessas constantes.

const TEXELS_PER_UNIT: int = 32
const PIXEL_SIZE: float = 1.0 / TEXELS_PER_UNIT
## Altura de 1 nível de degrau (corte pela metade: 0.5).
const LEVEL_HEIGHT: float = 0.5
