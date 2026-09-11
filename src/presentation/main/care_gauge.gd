class_name CareGauge
extends Control

const COLORS := [Color("2699ff"), Color("52d83d"), Color("ff9a24")]
const KEYS := ["water", "food", "environment"]

var _data: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func set_gauge(data: Dictionary) -> void:
	_data = data
	visible = not data.is_empty()
	queue_redraw()

func _draw() -> void:
	if _data.is_empty():
		return
	for index in range(KEYS.size()):
		var component: Dictionary = _data.get(KEYS[index], {})
		_draw_vertical_bar(index, COLORS[index], component)

func _draw_vertical_bar(index: int, color: Color, component: Dictionary) -> void:
	var rect := Rect2(6.0 + index * 29.0, 6.0, 24.0, size.y - 12.0)
	var frame := _bar_style(Color("8f471c"), Color("3b1709"), 12, 2, 3, 4)
	frame.shadow_color = Color(0.10, 0.025, 0.005, 0.52)
	frame.shadow_size = 3
	frame.shadow_offset = Vector2(0.0, 2.0)
	draw_style_box(frame, rect)
	var inner := rect.grow(-4.0)
	draw_style_box(_bar_style(Color(0.10, 0.065, 0.055, 0.94), Color(0.035, 0.02, 0.015, 0.78), 9, 2, 2, 2), inner)
	var value := clampf(float(component.get("value", 0.5)), 0.0, 1.0)
	if value <= 0.0:
		return
	var fill := Rect2(inner.position + Vector2(2.0, inner.size.y * (1.0 - value) + 2.0), Vector2(inner.size.x - 4.0, maxf(6.0, (inner.size.y - 4.0) * value)))
	var fill_style := _bar_style(color, color.darkened(0.42), 7, 2, 2, 3)
	draw_style_box(fill_style, fill)
	var shine := Color(1.0, 1.0, 0.88, 0.72)
	var shine_start := fill.position + Vector2(4.0, 6.0)
	draw_circle(shine_start, 2.5, shine)
	draw_line(shine_start + Vector2(0.0, 3.0), shine_start + Vector2(0.0, minf(18.0, fill.size.y * 0.22)), Color(1.0, 1.0, 0.92, 0.34), 2.0, true)
	draw_line(fill.position + Vector2(fill.size.x - 2.0, 6.0), fill.end - Vector2(2.0, 7.0), Color(0.04, 0.02, 0.01, 0.24), 2.0, true)
	draw_line(fill.position + Vector2(5.0, fill.size.y - 2.0), fill.end - Vector2(5.0, 2.0), Color(0.04, 0.02, 0.01, 0.30), 2.0, true)

func _bar_style(background: Color, border: Color, radius: int, side_width: int, top_width: int, bottom_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = side_width
	style.border_width_top = top_width
	style.border_width_right = side_width
	style.border_width_bottom = bottom_width
	style.set_corner_radius_all(radius)
	style.anti_aliasing_size = 1.5
	return style
