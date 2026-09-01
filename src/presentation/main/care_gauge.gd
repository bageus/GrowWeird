class_name CareGauge
extends Control

const START_ANGLE := deg_to_rad(210.0)
const END_ANGLE := deg_to_rad(330.0)
const ARC_WIDTH := 7.0
const ARC_GAP := 12.0
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
	var center := Vector2(size.x * 0.5, size.y - 8.0)
	var progress := float(_data.get("stage_progress", 0.0))
	for index in range(KEYS.size()):
		var component: Dictionary = _data.get(KEYS[index], {})
		_draw_gauge_arc(center, 54.0 + ARC_GAP * index, COLORS[index], component, progress)
	_draw_pointer(center, progress)

func _draw_gauge_arc(center: Vector2, radius: float, color: Color, component: Dictionary, progress: float) -> void:
	draw_arc(center, radius, START_ANGLE, END_ANGLE, 48, Color("482715"), ARC_WIDTH + 4.0, true)
	draw_arc(center, radius, START_ANGLE, END_ANGLE, 48, color.darkened(0.15), ARC_WIDTH, true)
	var minimum := clampf(float(component.get("minimum", 0.35)), 0.0, 1.0)
	var maximum := clampf(float(component.get("maximum", 0.7)), minimum, 1.0)
	var value := clampf(float(component.get("value", 0.5)), 0.0, 1.0)
	var good_start_ratio := clampf(progress + minimum - value, 0.0, 1.0)
	var good_end_ratio := clampf(progress + maximum - value, 0.0, 1.0)
	var good_start := lerpf(START_ANGLE, END_ANGLE, good_start_ratio)
	var good_end := lerpf(START_ANGLE, END_ANGLE, good_end_ratio)
	draw_arc(center, radius, START_ANGLE, good_start, 20, Color(0.45, 0.45, 0.48, 0.62), ARC_WIDTH, true)
	draw_arc(center, radius, good_end, END_ANGLE, 20, Color(1.0, 0.08, 0.04, 0.5), ARC_WIDTH, true)
	var active := int(component.get("direction", 0))
	if active == 0:
		draw_arc(center, radius, good_start, good_end, 24, color.lightened(0.28), ARC_WIDTH + 2.0, true)
	elif active < 0:
		draw_arc(center, radius, START_ANGLE, good_start, 20, Color(0.82, 0.84, 0.9, 0.78), ARC_WIDTH + 2.0, true)
	else:
		draw_arc(center, radius, good_end, END_ANGLE, 20, Color(1.0, 0.12, 0.05, 0.78), ARC_WIDTH + 2.0, true)
	_draw_boundary(center, radius, good_start)
	_draw_boundary(center, radius, good_end)

func _draw_boundary(center: Vector2, radius: float, angle: float) -> void:
	var normal := Vector2.from_angle(angle)
	for offset in [-4.0, 1.0]:
		var from: Vector2 = center + normal * (radius + float(offset))
		draw_line(from, from + normal * 3.0, Color("fff0c2"), 1.5, true)

func _draw_pointer(center: Vector2, progress: float) -> void:
	var angle := lerpf(START_ANGLE, END_ANGLE, clampf(progress, 0.0, 1.0))
	var direction := Vector2.from_angle(angle)
	var side := direction.orthogonal()
	var tip := center + direction * 84.0
	var polygon := PackedVector2Array([center + side * 4.0, tip, center - side * 4.0])
	draw_colored_polygon(polygon, Color("ffd45c"))
	draw_polyline(PackedVector2Array([polygon[0], polygon[1], polygon[2], polygon[0]]), Color("4a2817"), 2.0, true)
	draw_circle(center, 7.0, Color("4a2817"))
	draw_circle(center, 4.5, Color("ffd45c"))
