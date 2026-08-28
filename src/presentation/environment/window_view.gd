class_name WindowView
extends TextureRect

const WINDOWS: Array[Texture2D] = [
	preload("res://assets/window/window_01.png"),
	preload("res://assets/window/window_02.png"),
	preload("res://assets/window/window_03.png"),
	preload("res://assets/window/window_04.png"),
]

var _light_mode: int = PotState.LightMode.DIFFUSED
var _window_open := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_texture()

func set_environment(light_mode: int, window_open: bool) -> void:
	_light_mode = clampi(light_mode, 0, WINDOWS.size() - 1)
	_window_open = window_open
	_update_texture()

func _update_texture() -> void:
	texture = WINDOWS[_light_mode]
	tooltip_text = "%s · window %s" % [
		_mode_name(_light_mode),
		"open" if _window_open else "closed",
	]

func _mode_name(mode: int) -> String:
	match mode:
		PotState.LightMode.DARK:
			return "Dark"
		PotState.LightMode.DIFFUSED:
			return "Diffused"
		PotState.LightMode.BRIGHT:
			return "Bright"
		PotState.LightMode.DIRECT:
			return "Direct"
		_:
			return "Diffused"
