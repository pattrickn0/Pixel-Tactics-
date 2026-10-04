class_name Hud
extends CanvasLayer
## HUD do mapa. Só emite a intenção map_requested e mostra o estado recebido.
## Nunca chama o gerador nem o renderer.

signal map_requested(map_seed: int)
signal rotate_left_requested()
signal rotate_right_requested()
signal reset_rotation_requested()

const MAX_RANDOM_SEED: int = 999_999_999
const INVALID_SEED_TEXT: String = "Seed inválida"

@onready var _seed_label: Label = %SeedLabel
@onready var _generate_button: Button = %GenerateButton
@onready var _seed_input: LineEdit = %SeedInput
@onready var _use_seed_button: Button = %UseSeedButton
@onready var _status_label: Label = %StatusLabel
@onready var _rotate_left_button: Button = get_node_or_null("%RotateLeftButton")
@onready var _rotate_right_button: Button = get_node_or_null("%RotateRightButton")
@onready var _reset_rotate_button: Button = get_node_or_null("%ResetRotateButton")

# RNG próprio do HUD: só escolhe a seed, não gera o mapa (por isso randomize é permitido aqui).
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_generate_button.pressed.connect(request_random_map)
	_use_seed_button.pressed.connect(_on_use_seed)
	_seed_input.text_submitted.connect(_on_seed_submitted)
	if _rotate_left_button != null:
		_rotate_left_button.pressed.connect(func(): rotate_left_requested.emit())
	if _rotate_right_button != null:
		_rotate_right_button.pressed.connect(func(): rotate_right_requested.emit())
	if _reset_rotate_button != null:
		_reset_rotate_button.pressed.connect(func(): reset_rotation_requested.emit())
	_status_label.text = ""


func request_random_map() -> void:
	_status_label.text = ""
	map_requested.emit(_rng.randi_range(0, MAX_RANDOM_SEED))


## Reage a map_generated: mostra a seed atual.
func show_map_info(map_data: MapData) -> void:
	_seed_label.text = "Seed: %d" % map_data.map_seed


func _on_use_seed() -> void:
	_submit_seed_text(_seed_input.text)


func _on_seed_submitted(text: String) -> void:
	_submit_seed_text(text)


func _submit_seed_text(text: String) -> void:
	var clean: String = text.strip_edges()
	if not is_valid_seed_text(clean):
		_status_label.text = INVALID_SEED_TEXT
		return
	_status_label.text = ""
	map_requested.emit(clean.to_int())


## Inteiro de 64 bits (aceita negativo); fora do int64 é inválido.
static func is_valid_seed_text(text: String) -> bool:
	if not text.is_valid_int():
		return false
	var digits: String = text.trim_prefix("-").trim_prefix("+").lstrip("0")
	if digits.length() < 19:
		return true
	if digits.length() > 19:
		return false
	return digits <= "9223372036854775807"
