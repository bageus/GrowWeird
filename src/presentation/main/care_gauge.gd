class_name CareGauge
extends Control

const COLORS := [Color("2699ff"), Color("52d83d"), Color("ff9a24")]
const KEYS := ["water", "food", "environment"]
const ICON_TOP := 30.0

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
		_draw_care_icon(index, COLORS[index])
		_draw_vertical_bar(index, COLORS[index], component)

func _draw_vertical_bar(index: int, color: Color, component: Dictionary) -> void:
	var rect := Rect2(6.0 + index * 29.0, ICON_TOP, 24.0, size.y - ICON_TOP - 6.0)
	var frame := _bar_style(Color("8f471c"), Color("3b1709"), 12, 2, 3, 4)
	frame.shadow_color = Color(0.10, 0.025, 0.005, 0.52)
	frame.shadow_size = 3
	frame.shadow_offset = Vector2(0.0, 2.0)
	draw_style_box(frame, rect)
	var inner := rect.grow(-4.0)
	draw_style_box(_bar_style(Color(0.10, 0.065, 0.055, 0.94), Color(0.035, 0.02, 0.015, 0.78), 9, 2, 2, 2), inner)
	_draw_cell_guides(index, inner)
	var value := clampf(float(component.get("value", 0.5)), 0.0, 1.0)
	if value > 0.0:
		var fill_height := maxf(6.0, (inner.size.y - 4.0) * value)
		var fill := Rect2(inner.position + Vector2(2.0, inner.size.y - fill_height - 2.0), Vector2(inner.size.x - 4.0, fill_height))
		draw_style_box(_bar_style(color, color.darkened(0.42), 7, 2, 2, 3), fill)
		var shine := Color(1.0, 1.0, 0.88, 0.72)
		var shine_start := fill.position + Vector2(4.0, 6.0)
		draw_circle(shine_start, 2.5, shine)
		draw_line(shine_start + Vector2(0.0, 3.0), shine_start + Vector2(0.0, minf(18.0, fill.size.y * 0.22)), Color(1.0, 1.0, 0.92, 0.34), 2.0, true)
		draw_line(fill.position + Vector2(fill.size.x - 2.0, 6.0), fill.end - Vector2(2.0, 7.0), Color(0.04, 0.02, 0.01, 0.24), 2.0, true)
	_draw_target_zone(inner, component, color)

func _draw_target_zone(inner: Rect2, component: Dictionary, color: Color) -> void:
	var minimum := clampf(float(component.get("minimum", 0.0)), 0.0, 1.0)
	var maximum := clampf(float(component.get("maximum", 1.0)), minimum, 1.0)
	var top := inner.end.y - maximum * inner.size.y
	var bottom := inner.end.y - minimum * inner.size.y
	var zone := Rect2(inner.position.x + 2.0, top + 1.0, inner.size.x - 4.0, maxf(4.0, bottom - top - 2.0))
	draw_rect(zone, Color(color, 0.24), true)
	draw_line(Vector2(zone.position.x, zone.position.y), Vector2(zone.end.x, zone.position.y), Color(1.0, 1.0, 0.78, 0.90), 2.0, true)
	draw_line(Vector2(zone.position.x, zone.end.y), Vector2(zone.end.x, zone.end.y), Color(1.0, 1.0, 0.78, 0.90), 2.0, true)

func _draw_cell_guides(index: int, inner: Rect2) -> void:
	if index != 0:
		return
	var previous := 0.0
	for stage_end in PotState.SOIL_MOISTURE_STAGE_MAX:
		for quarter in range(1, PotState.SPRAYS_PER_STAGE + 1):
			var ratio := lerpf(previous, stage_end, float(quarter) / float(PotState.SPRAYS_PER_STAGE))
			var y := inner.end.y - ratio * inner.size.y
			var major := quarter == PotState.SPRAYS_PER_STAGE
			draw_line(
				Vector2(inner.position.x + 2.0, y),
				Vector2(inner.end.x - 2.0, y),
				Color(1.0, 0.91, 0.65, 0.42 if major else 0.18),
				1.5 if major else 1.0,
				true
			)
		previous = stage_end

func _draw_care_icon(index: int, color: Color) -> void:
	var center := Vector2(18.0 + index * 29.0, 15.0)
	match index:
		0:
			var drop := PackedVector2Array([
				center + Vector2(0.0, -9.0), center + Vector2(-7.0, 2.0),
				center + Vector2(-5.0, 7.0), center + Vector2(0.0, 10.0),
				center + Vector2(5.0, 7.0), center + Vector2(7.0, 2.0),
			])
			draw_colored_polygon(drop, color)
			draw_polyline(drop + PackedVector2Array([drop[0]]), color.darkened(0.48), 2.0, true)
		1:
			var leaf := PackedVector2Array([
				center + Vector2(-8.0, 5.0), center + Vector2(-5.0, -5.0),
				center + Vector2(7.0, -9.0), center + Vector2(8.0, 2.0),
				center + Vector2(2.0, 8.0),
			])
			draw_colored_polygon(leaf, color)
			draw_line(center + Vector2(-7.0, 7.0), center + Vector2(6.0, -6.0), color.darkened(0.48), 2.0, true)
		2:
			draw_circle(center, 7.0, color)
			for ray in range(8):
				var direction := Vector2.UP.rotated(TAU * float(ray) / 8.0)
				draw_line(center + direction * 9.0, center + direction * 13.0, color.darkened(0.24), 2.0, true)

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
