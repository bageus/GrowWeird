class_name WindowView
extends TextureRect

const SUNNY: Texture2D = preload("res://assets/window/window_01.png")
const CURTAINS: Texture2D = preload("res://assets/window/window_02.png")
const VENTILATION: Texture2D = preload("res://assets/window/window_03.png")
const BLINDS: Texture2D = preload("res://assets/window/window_04.png")

var _light_mode: int = PotState.LightMode.DIFFUSED
var _window_open := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_texture()

func set_environment(light_mode: int, window_open: bool) -> void:
	_light_mode = clampi(light_mode, 0, PotState.LightMode.size() - 1)
	_window_open = window_open
	_update_texture()

func _update_texture() -> void:
	if _window_open:
		texture = VENTILATION
	elif _light_mode == PotState.LightMode.DARK:
		texture = CURTAINS
	elif _light_mode == PotState.LightMode.DIFFUSED:
		texture = BLINDS
	else:
		texture = SUNNY
