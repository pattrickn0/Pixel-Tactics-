extends RefCounted
## Paleta exata da A02 (docs/direcao-de-arte.md, seção Paleta). Sem class_name: usar via preload.
## Cada grupo é uma rampa da sombra para a luz. As flores são 4 rampas separadas.
## As cores ficam guardadas como inteiros 0xRRGGBB para gravar e comparar bytes exatos.

const GROUPS: Array = [
	["grass_arena", ["#426E33", "#4E7D3C", "#5C8E46", "#6B9E50", "#7BAC58", "#8EBD64", "#A0CB73", "#B4DA86"]],
	["grass_forest", ["#0B1B0F", "#112616", "#19341F", "#23452A", "#305837", "#406D47", "#548459"]],
	["leaf_litter", ["#3A2A1C", "#5A3F24", "#7C5A2E", "#A07A3C", "#C29A50"]],
	["dirt", ["#7A6643", "#8B7750", "#9D895E", "#AD9A6C", "#BCAB7B", "#CABE8A", "#D6CA9B", "#E2D7AE"]],
	["rock", ["#161B18", "#242C28", "#353F39", "#49544D", "#5F6B63", "#77857C", "#92A197", "#AEBFB3"]],
	["masonry", ["#181D1A", "#262C27", "#363C37", "#484E48", "#5D645D", "#757C74", "#8F968D", "#ACB4AA"]],
	["cold_stone", ["#141A21", "#212B33", "#303F48", "#43565C", "#5A6F72", "#77898A", "#9AABA6", "#C0CCC4"]],
	["moss", ["#162C14", "#20401C", "#2D5726", "#3E7134", "#528C43", "#6CA956"]],
	["lichen", ["#879875", "#ABC096"]],
	["leaves", ["#0A1B0E", "#112715", "#1A371F", "#274A2B", "#375F39", "#4B764A", "#628F5E", "#7CA874", "#99C48E"]],
	["conifer", ["#071513", "#0C1F1D", "#122C2A", "#1A3C38", "#254F4A", "#33645E", "#447C75"]],
	["bark", ["#15100D", "#231B15", "#33261E", "#47352A", "#5E4637", "#775A47", "#937059"]],
	["rune", ["#1F7C86", "#33C2C4", "#7CF2EC", "#D9FFFA"]],
	["flower_yellow", ["#E8B83A", "#F6D865", "#FFF0A6"]],
	["flower_white", ["#CFCBBE", "#EDEAE0", "#F9F6EA"]],
	["flower_lilac", ["#5E3F7D", "#8A5FB0", "#B48DD6"]],
	["flower_pink", ["#B5506A", "#E07F96"]],
]

static var _built: bool = false
static var _rgb: PackedInt32Array = PackedInt32Array()
static var _group_of: PackedStringArray = PackedStringArray()
static var _tone_of: PackedInt32Array = PackedInt32Array()
static var _ramps: Dictionary = {}
static var _lookup: Dictionary = {}


static func _build() -> void:
	if _built:
		return
	_built = true
	for g: Array in GROUPS:
		var gname: String = g[0]
		var hexes: Array = g[1]
		var ramp_idx: PackedInt32Array = PackedInt32Array()
		for t: int in hexes.size():
			var hx: String = hexes[t]
			var v: int = hx.substr(1).hex_to_int()
			if _lookup.has(v):
				push_error("Cor repetida na paleta: %s" % hx)
			_lookup[v] = _rgb.size()
			ramp_idx.append(_rgb.size())
			_rgb.append(v)
			_group_of.append(gname)
			_tone_of.append(t)
		_ramps[gname] = ramp_idx


## Índices globais de uma rampa, da sombra para a luz.
static func ramp(group: String) -> PackedInt32Array:
	_build()
	return _ramps[group]


## Índice global de um tom de uma rampa.
static func c(group: String, tone: int) -> int:
	_build()
	var r: PackedInt32Array = _ramps[group]
	return r[clampi(tone, 0, r.size() - 1)]


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


static func group_of(i: int) -> String:
	_build()
	return _group_of[i]


static func tone_of(i: int) -> int:
	_build()
	return _tone_of[i]


static func ramp_size(group: String) -> int:
	_build()
	return (_ramps[group] as PackedInt32Array).size()


## Índice global a partir de 0xRRGGBB, ou -1 se a cor não está na paleta.
static func find(v: int) -> int:
	_build()
	return int(_lookup.get(v, -1))


## Tom vizinho na mesma rampa (desloca e prende nos extremos).
static func shift(i: int, d: int) -> int:
	_build()
	var r: PackedInt32Array = _ramps[_group_of[i]]
	return r[clampi(_tone_of[i] + d, 0, r.size() - 1)]


## Luminância Y (sRGB 0..1) da cor global i.
static func luma(i: int) -> float:
	_build()
	var v: int = _rgb[i]
	return (0.299 * float((v >> 16) & 255) + 0.587 * float((v >> 8) & 255) + 0.114 * float(v & 255)) / 255.0
