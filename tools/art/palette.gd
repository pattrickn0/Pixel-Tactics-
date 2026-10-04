extends RefCounted
## Paleta exata de docs/direcao-de-arte.md (sem class_name: usar via preload).

# Grama (planície/arena)
const GRASS_0: Color = Color("#4E7A2A")
const GRASS_1: Color = Color("#6B9B37")
const GRASS_2: Color = Color("#8DB846")
const GRASS_3: Color = Color("#B3CF5E")

# Grama da mata (chão fora da arena) — usa também GRASS_0/GRASS_1
const FGRASS_0: Color = Color("#315740")

# Mata / copas (escura azulada)
const CANOPY_0: Color = Color("#111A33")
const CANOPY_1: Color = Color("#192649")
const CANOPY_2: Color = Color("#224956")
const CANOPY_3: Color = Color("#236460")
const CANOPY_4: Color = Color("#458946")

# Terra / trilha
const DIRT_0: Color = Color("#6E5538")
const DIRT_1: Color = Color("#8A6E4B")
const DIRT_2: Color = Color("#C2A57A")
const DIRT_3: Color = Color("#E0CDA0")

# Pedra terrosa (muro, laterais de degrau)
const ESTONE_0: Color = Color("#47443B")
const ESTONE_1: Color = Color("#634E45")
const ESTONE_2: Color = Color("#976759")
const ESTONE_3: Color = Color("#B47262")
const ESTONE_4: Color = Color("#D68775")

# Pedra fria (monólito, lajota, pedra grande)
const CSTONE_0: Color = Color("#232B2B")
const CSTONE_1: Color = Color("#374845")
const CSTONE_2: Color = Color("#4D6862")
const CSTONE_3: Color = Color("#6C948B")
const CSTONE_4: Color = Color("#A9C3B8")

# Runa (brilho pontual)
const RUNE_RING: Color = Color("#67A7A5")
const RUNE_BASE: Color = Color("#3AD1CC")
const RUNE_CORE: Color = Color("#48FDFD")
const RUNE_SHINE: Color = Color("#A3F9F7")

# Madeira / tronco
const WOOD_0: Color = Color("#3B2A1E")
const WOOD_1: Color = Color("#5C3F2A")
const WOOD_2: Color = Color("#7E5A3A")

# Água (uso futuro)
const WATER_0: Color = Color("#2B4F6E")
const WATER_1: Color = Color("#3E7499")
const WATER_2: Color = Color("#6FA8C9")

# Flores
const FLOWER_YELLOW: Color = Color("#F2E27A")
const FLOWER_WHITE: Color = Color("#ECEBDF")
const FLOWER_PINK: Color = Color("#E39BB0")
const FLOWER_LILAC_0: Color = Color("#8B5396")
const FLOWER_LILAC_1: Color = Color("#B76CC5")

# Contorno
const OUTLINE_FOREST: Color = Color("#0B1228")
const OUTLINE_PLANT_DARK: Color = Color("#1A2420")
const OUTLINE_PLANT: Color = Color("#24302A")
const OUTLINE_STONE: Color = Color("#2B3A2A")

const ALL: Array[Color] = [
	GRASS_0, GRASS_1, GRASS_2, GRASS_3,
	FGRASS_0,
	CANOPY_0, CANOPY_1, CANOPY_2, CANOPY_3, CANOPY_4,
	DIRT_0, DIRT_1, DIRT_2, DIRT_3,
	ESTONE_0, ESTONE_1, ESTONE_2, ESTONE_3, ESTONE_4,
	CSTONE_0, CSTONE_1, CSTONE_2, CSTONE_3, CSTONE_4,
	RUNE_RING, RUNE_BASE, RUNE_CORE, RUNE_SHINE,
	WOOD_0, WOOD_1, WOOD_2,
	WATER_0, WATER_1, WATER_2,
	FLOWER_YELLOW, FLOWER_WHITE, FLOWER_PINK, FLOWER_LILAC_0, FLOWER_LILAC_1,
	OUTLINE_FOREST, OUTLINE_PLANT_DARK, OUTLINE_PLANT, OUTLINE_STONE,
]

const RUNE: Array[Color] = [RUNE_RING, RUNE_BASE, RUNE_CORE, RUNE_SHINE]

# Cores aceitas como contorno pelo verificador (contorno + tom mais escuro de cada grupo)
const OUTLINE_LIKE: Array[Color] = [
	OUTLINE_FOREST, OUTLINE_PLANT_DARK, OUTLINE_PLANT, OUTLINE_STONE,
	GRASS_0, FGRASS_0, CANOPY_0, DIRT_0, ESTONE_0, CSTONE_0, WOOD_0, FLOWER_LILAC_0,
]
