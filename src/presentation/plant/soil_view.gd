class_name SoilView
extends Control

var _moisture: float = 0.5

func set_moisture(value: float) -> void:
	_moisture = clampf(value, 0.0, 1.0)
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	var width := size.x
	var height := size.y
	var pot_top_y := height * 0.22
	var pot_bottom_y := height * 0.93
	var pot_left := width * 0.19
	var pot_right := width * 0.81
	var bottom_left := width * 0.28
	var bottom_right := width * 0.72

	var soil_color := Color(0.78, 0.66, 0.48).lerp(Color(0.17, 0.10, 0.07), _moisture)
	if _moisture < 0.16:
		soil_color = soil_color.lerp(Color(0.88, 0.79, 0.58), 0.55)

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(pot_left, pot_top_y),
			Vector2(pot_right, pot_top_y),
			Vector2(bottom_right, pot_bottom_y),
			Vector2(bottom_left, pot_bottom_y),
		]),
		Color(0.48, 0.24, 0.13)
	)
	draw_line(
		Vector2(pot_left, pot_top_y),
		Vector2(pot_right, pot_top_y),
		Color(0.25, 0.11, 0.07),
		5.0,
		true
	)
	draw_rect(
		Rect2(Vector2(pot_left + 7.0, pot_top_y - 5.0), Vector2(pot_right - pot_left - 14.0, 16.0)),
		soil_color,
		true
	)
	if _moisture > 0.8:
		draw_line(
			Vector2(pot_left + 12.0, pot_top_y + 1.0),
			Vector2(pot_right - 12.0, pot_top_y + 1.0),
			Color(0.47, 0.58, 0.64, 0.55),
			2.0,
			true
		)
