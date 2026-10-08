class_name Hud
extends CanvasLayer
## HUD do mapa. Só emite os pedidos de giro da câmera; nunca chama a câmera diretamente.
## Os botões não pegam foco (focus_mode = none na cena): Espaço/Enter não acionam botão,
## e A/D/Espaço ficam para a câmera.

signal rotate_left_requested()
signal rotate_right_requested()
signal reset_rotation_requested()

@onready var _rotate_left_button: Button = %RotateLeftButton
@onready var _rotate_right_button: Button = %RotateRightButton
@onready var _reset_rotate_button: Button = %ResetRotateButton


func _ready() -> void:
	_rotate_left_button.pressed.connect(rotate_left_requested.emit)
	_rotate_right_button.pressed.connect(rotate_right_requested.emit)
	_reset_rotate_button.pressed.connect(reset_rotation_requested.emit)
