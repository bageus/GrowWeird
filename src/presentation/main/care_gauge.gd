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
	var rect := Rect2(8.0 + index * 27.0, 8.0, 20.0, size.y - 16.0)
	draw_rect(rect, Color("482715"), true)
	var inner := rect.grow(-3.0); draw_rect(inner, Color(0.18, 0.18, 0.2, 0.85), true)
	var value := clampf(float(component.get("value", 0.5)), 0.0, 1.0)
	var fill := Rect2(inner.position + Vector2(0.0, inner.size.y * (1.0 - value)), Vector2(inner.size.x, inner.size.y * value))
	draw_rect(fill, color, true)
