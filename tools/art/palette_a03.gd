extends RefCounted
## Paleta exata da A03 (docs/direcao-de-arte.md, seção Paleta). Sem class_name: usar via preload.
## Cada rampa vai da sombra para a luz. Flores e Cogumelos são uma família com várias rampas.
## As cores ficam como inteiros 0xRRGGBB para gravar e comparar bytes exatos.

# [id da rampa, família da direção de arte, hexes]
const GROUPS: Array = [
	["grass_arena", "grass_arena", ["#4E9343", "#5B9C47", "#73A949", "#98B654"]],
	["grass_forest", "grass_forest", ["#2C7036", "#3D853C", "#539342", "#6A9E4A"]],
	["dirt", "dirt", ["#8E7B4C", "#A8955F", "#C0AE71", "#D4C48C"]],
	["dark_earth", "dark_earth", ["#3E3226", "#5A4632", "#7A6444"]],
	["stone", "stone", ["#1C2B2B", "#34403C", "#5C6250", "#7A7A66", "#989680", "#B9B597", "#D3CCB4"]],
	["moss", "moss", ["#2E4A1E", "#496819", "#5E7C26", "#789636", "#8FAE48", "#B0C860"]],
	["leaf_green", "leaf_green", ["#123B32", "#1F5530", "#2F6A2A", "#437B25", "#5A9628", "#76AB2A", "#9CC230", "#B5CA33"]],
	["leaf_olive", "leaf_olive", ["#1B3429", "#2B4328", "#3B5328", "#546A29", "#6E8432", "#869736", "#A6B04A"]],
	["leaf_cool", "leaf_cool", ["#163F3E", "#1C4948", "#245747", "#2F6A48", "#3F8650", "#58A758", "#7CC070"]],
	["conifer", "conifer", ["#08262A", "#0E3330", "#16402F", "#1F4D34", "#2C5E38", "#40743C", "#5C8C40", "#86A83E"]],
	["bark", "bark", ["#1A1426", "#2C212D", "#4B3339", "#6B4C3E", "#876547", "#A37C56", "#C29A6C", "#D9BC86"]],
	["cold_stone", "cold_stone", ["#1E2C34", "#33454C", "#4E6266", "#6E8482", "#93A6A0", "#BCCAC2"]],
	["rune", "rune", ["#1F7C86", "#33C2C4", "#7CF2EC", "#D9FFFA"]],
	["flower_pink", "flowers", ["#C4506E", "#E8829C", "#F8B8C8"]],
	["flower_white", "flowers", ["#D8D4C4", "#F4F0E4", "#FFFDF6"]],
	["flower_yellow", "flowers", ["#D8A830", "#F2D04A", "#FFF08A"]],
	["flower_blue", "flowers", ["#4C7CD0", "#7FB0F0"]],
	["mush_pink", "mushrooms", ["#8E3A86", "#C957B7", "#E88AD6"]],
	["mush_blue", "mushrooms", ["#2A7FA8", "#68D8E5", "#B8F2F6"]],
	["mush_purple", "mushrooms", ["#3E2E78", "#6A4FB0", "#9C84E0"]],
	["mush_orange", "mushrooms", ["#A8502A", "#E07A3A", "#F4A868"]],
	["mush_stem", "mushrooms", ["#B8AE98", "#E8E0C8"]],
]

static var _built: bool = false
static var _rgb: PackedInt32Array = PackedInt32Array()
static var _ramp_of: PackedStringArray = PackedStringArray()
static var _family_of: PackedStringArray = PackedStringArray()
static var _tone_of: PackedInt32Array = PackedInt32Array()
static var _ramps: Dictionary = {}
static var _lookup: Dictionary = {}


static func _build() -> void:
	if _built:
		return
	_built = true
	for g: Array in GROUPS:
		var rname: String = g[0]
		var fam: String = g[1]
		var hexes: Array = g[2]
		var idx: PackedInt32Array = PackedInt32Array()
		for t: int in hexes.size():
			var hx: String = hexes[t]
			var v: int = hx.substr(1).hex_to_int()
			if _lookup.has(v):
				push_error("Cor repetida na paleta: %s" % hx)
			_lookup[v] = _rgb.size()
			idx.append(_rgb.size())
			_rgb.append(v)
			_ramp_of.append(rname)
			_family_of.append(fam)
			_tone_of.append(t)
		_ramps[rname] = idx


## Índice global de um tom de uma rampa (prende nos extremos).
static func c(ramp_name: String, tone: int) -> int:
	_build()
	var r: PackedInt32Array = _ramps[ramp_name]
	return r[clampi(tone, 0, r.size() - 1)]


## Índice global a partir do hex "#RRGGBB" (erro se não estiver na paleta).
static func hx(s: String) -> int:
	_build()
	var v: int = s.substr(1).hex_to_int()
	if not _lookup.has(v):
		push_error("Cor fora da paleta: %s" % s)
		return -1
	return _lookup[v]


static func count() -> int:
	_build()
	return _rgb.size()


static func rgb(i: int) -> int:
	_build()
	return _rgb[i]


static func color(i: int) -> Color:
	_build()
	var v: int = _rgb[i]
	return Color8((v >> 16) & 255, (v >> 8) & 255, v & 255, 255)


static func ramp_of(i: int) -> String:
	_build()
	return _ramp_of[i]


static func family_of(i: int) -> String:
	_build()
	return _family_of[i]


static func tone_of(i: int) -> int:
	_build()
	return _tone_of[i]


## Índice global a partir de 0xRRGGBB, ou -1 se a cor não está na paleta.
static func find(v: int) -> int:
	_build()
	return int(_lookup.get(v, -1))


## Tom vizinho na mesma rampa.
static func shift(i: int, d: int) -> int:
	_build()
	var r: PackedInt32Array = _ramps[_ramp_of[i]]
	return r[clampi(_tone_of[i] + d, 0, r.size() - 1)]


## Luminância Y (0..1) da cor global i.
static func luma(i: int) -> float:
	_build()
	var v: int = _rgb[i]
	return (0.299 * float((v >> 16) & 255) + 0.587 * float((v >> 8) & 255) + 0.114 * float(v & 255)) / 255.0


## Os n índices mais escuros (por luminância) de uma família.
static func darkest_of_family(fam: String, n: int) -> Array[int]:
	_build()
	var ids: Array[int] = []
	for i: int in _rgb.size():
		if _family_of[i] == fam:
			ids.append(i)
	ids.sort_custom(func(a: int, b: int) -> bool: return luma(a) < luma(b))
	return ids.slice(0, n)
