class_name WindowView
extends Control

signal light_mode_requested(mode: int)
signal window_state_requested(open: bool)

var _light_mode: int = PotState.LightMode.DIFFUSED
var _window_open: bool = false

func set_environment(light_mode: int, window_open: bool) -> void:
	_light_mode = clampi(light_mode, 0, PotState.LightMode.size() - 1)
	_window_open = window_open
	queue_redraw()

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var handle_rect := Rect2(size.x * 0.70, size.y * 0.42, size.x * 0.12, size.y * 0.16)
		if handle_rect.has_point(event.position):
			window_state_requested.emit(not _window_open)
		else:
			light_mode_requested.emit((_light_mode + 1) % PotState.LightMode.size())
		accept_event()

func _draw() -> void:
	var brightness: float = float([0.12, 0.42, 0.72, 1.0][_light_mode])
	var sky := Color(0.28, 0.34, 0.40).lerp(Color(0.67, 0.87, 1.0), brightness)
	var frame := Color(0.48, 0.39, 0.30)
	var inset := Rect2(size.x * 0.12, size.y * 0.08, size.x * 0.76, size.y * 0.82)
	var glass := inset.grow(-12.0)

	draw_rect(Rect2(Vector2.ZERO, size), Color(0.80, 0.75, 0.66), true)
	if _light_mode == PotState.LightMode.DIRECT:
		for index in range(3):
			var offset := float(index) * 42.0
			draw_colored_polygon(
				PackedVector2Array([
					Vector2(size.x * 0.22 + offset, 0.0),
					Vector2(size.x * 0.38 + offset, 0.0),
					Vector2(size.x * 0.62 + offset, size.y),
					Vector2(size.x * 0.46 + offset, size.y),
				]),
				Color(1.0, 0.90, 0.54, 0.11)
			)

	draw_rect(inset, frame, true)
	draw_rect(glass, sky, true)
	var middle_x := glass.position.x + glass.size.x * 0.5
	draw_line(Vector2(middle_x, glass.position.y), Vector2(middle_x, glass.end.y), frame, 8.0, true)

	if _window_open:
		var open_rect := Rect2(glass.position + Vector2(glass.size.x * 0.50, 4.0), Vector2(glass.size.x * 0.45, glass.size.y - 8.0))
		draw_rect(open_rect, Color(0.20, 0.25, 0.28, 0.35), true)
		draw_line(open_rect.position, open_rect.end, Color(0.92, 0.90, 0.83), 5.0, true)

	_draw_blinds(glass)
	var handle_center := Vector2(size.x * 0.76, size.y * 0.50)
	draw_circle(handle_center, 9.0, Color(0.19, 0.17, 0.15))
	draw_line(handle_center, handle_center + Vector2(0.0, 24.0), Color(0.19, 0.17, 0.15), 5.0, true)

func _draw_blinds(glass: Rect2) -> void:
	var opacity := 0.0
	match _light_mode:
		PotState.LightMode.DARK:
			opacity = 0.92
		PotState.LightMode.DIFFUSED:
			opacity = 0.48
		PotState.LightMode.BRIGHT:
			opacity = 0.12
		PotState.LightMode.DIRECT:
			opacity = 0.0
	if opacity <= 0.0:
		return
	var strip_height := 18.0
	var y := glass.position.y
	while y < glass.end.y:
		draw_rect(
			Rect2(Vector2(glass.position.x, y), Vector2(glass.size.x, strip_height - 3.0)),
			Color(0.91, 0.89, 0.82, opacity),
			true
		)
		y += strip_height
