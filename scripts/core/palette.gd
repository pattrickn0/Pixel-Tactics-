class_name Palette
extends RefCounted
## Cores de docs/direcao-de-arte.md (fonte única), usadas pelos placeholders.
## Em cada grupo: sombra -> luz.

# Grama (planície/arena)
const GRASS_0 := Color("#4E7A2A")
const GRASS_1 := Color("#6B9B37")
const GRASS_2 := Color("#8DB846")
const GRASS_3 := Color("#B3CF5E")

# Grama da mata (chão fora da arena)
const FOREST_GRASS_0 := Color("#315740")
const FOREST_GRASS_1 := Color("#4E7A2A")
const FOREST_GRASS_2 := Color("#6B9B37")
const FOREST_GRASS_SPOT := Color("#236460")

# Mata / copas (escura azulada)
const WOODS_0 := Color("#111A33")
const WOODS_1 := Color("#192649")
const WOODS_2 := Color("#224956")
const WOODS_3 := Color("#236460")
const WOODS_4 := Color("#458946")

# Terra / trilha
const DIRT_0 := Color("#6E5538")
const DIRT_1 := Color("#8A6E4B")
const DIRT_2 := Color("#C2A57A")
const DIRT_3 := Color("#E0CDA0")

# Pedra terrosa (muro, laterais de degrau)
const EARTH_STONE_0 := Color("#47443B")
const EARTH_STONE_1 := Color("#634E45")
const EARTH_STONE_2 := Color("#976759")
const EARTH_STONE_3 := Color("#B47262")
const EARTH_STONE_4 := Color("#D68775")

# Pedra fria (monólito, lajota, pedra grande)
const COLD_STONE_0 := Color("#232B2B")
const COLD_STONE_1 := Color("#374845")
const COLD_STONE_2 := Color("#4D6862")
const COLD_STONE_3 := Color("#6C948B")
const COLD_STONE_4 := Color("#A9C3B8")

# Runa (brilho pontual): aro, base, núcleo, brilho
const RUNE_0 := Color("#67A7A5")
const RUNE_1 := Color("#3AD1CC")
const RUNE_2 := Color("#48FDFD")
const RUNE_3 := Color("#A3F9F7")

# Madeira / tronco
const WOOD_0 := Color("#3B2A1E")
const WOOD_1 := Color("#5C3F2A")
const WOOD_2 := Color("#7E5A3A")

# Flores
const FLOWER_YELLOW := Color("#F2E27A")
const FLOWER_WHITE := Color("#ECEBDF")
const FLOWER_PINK := Color("#E39BB0")
const FLOWER_LILAC_0 := Color("#8B5396")
const FLOWER_LILAC_1 := Color("#B76CC5")

# Contornos
const OUTLINE_WOODS := Color("#0B1228")
const OUTLINE_GRASS_0 := Color("#1A2420")
const OUTLINE_GRASS_1 := Color("#24302A")
const OUTLINE_STONE := Color("#2B3A2A")

# Ambiente (fundo da cena = sombra mais escura da mata)
const BACKGROUND := Color("#111A33")


## Verdadeiro se a cor é do grupo Runa (usado para extrair a máscara da runa).
static func is_rune_color(c: Color) -> bool:
	for rune: Color in [RUNE_0, RUNE_1, RUNE_2, RUNE_3]:
		if c.a > 0.5 and absf(c.r - rune.r) < 0.02 and absf(c.g - rune.g) < 0.02 and absf(c.b - rune.b) < 0.02:
			return true
	return false
