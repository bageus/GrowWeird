class_name PlantSenseView
extends Control

var _comfort: Dictionary = {}

func set_comfort(value: Dictionary) -> void:
	_comfort = value.duplicate(true)
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	var center := Vector2(size.x * 0.5, size.y * 0.73)
	var radius := minf(size.x * 0.36, size.y * 0.58)
	var segment := PI / 5.0
	var colors := [
		Color(0.82, 0.24, 0.20),
		Color(0.92, 0.55, 0.18),
		Color(0.33, 0.72, 0.34),
		Color(0.92, 0.55, 0.18),
		Color(0.82, 0.24, 0.20),
	]
	for index in range(5):
		var start_angle := PI + segment * float(index)
		var end_angle := start_angle + segment - 0.025
		draw_arc(center, radius, start_angle, end_angle, 18, colors[index], 8.0, true)

	var direction := int(_comfort.get("direction", 0))
	var overall := float(_comfort.get("overall", 1.0))
	var spread := lerpf(0.18, 0.78, 1.0 - overall)
	var needle_angle := PI * 1.5 + float(direction) * spread
	var needle_end := center + Vector2(cos(needle_angle), sin(needle_angle)) * (radius - 9.0)
	draw_line(center, needle_end, Color(0.16, 0.14, 0.12), 4.0, true)
	draw_circle(center, 6.0, Color(0.16, 0.14, 0.12))

	var main_issue := String(_comfort.get("main_issue", "ok"))
	var caption := _issue_caption(main_issue, direction)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(size.x * 0.5 - 72.0, size.y * 0.94),
		caption,
		HORIZONTAL_ALIGNMENT_CENTER,
		144.0,
		14,
		Color(0.16, 0.14, 0.12)
	)
	_draw_status_dots()

func _draw_status_dots() -> void:
	var items := [
		["W", float(_comfort.get("water", 1.0))],
		["L", float(_comfort.get("light", 1.0))],
		["A", float(_comfort.get("air", 1.0))],
	]
	var start_x := size.x * 0.5 - 48.0
	for index in range(items.size()):
		var item: Array = items[index]
		var score := float(item[1])
		var position := Vector2(start_x + float(index) * 48.0, size.y * 0.18)
		var color := Color(0.33, 0.72, 0.34)
		if score < 0.4:
			color = Color(0.82, 0.24, 0.20)
		elif score < 0.75:
			color = Color(0.92, 0.55, 0.18)
		draw_circle(position, 12.0, color)
		draw_string(
			ThemeDB.fallback_font,
			position + Vector2(-5.0, 5.0),
			String(item[0]),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			12,
			Color.WHITE
		)

func _issue_caption(issue: String, direction: int) -> String:
	if float(_comfort.get("overall", 1.0)) >= 0.98:
		return "Comfortable"
	var prefix := "Too little " if direction < 0 else "Too much "
	match issue:
		"water":
			return prefix + "water"
		"light":
			return prefix + "light"
		"air":
			return "Needs open window" if direction < 0 else "Dislikes draft"
	return "Needs attention"
