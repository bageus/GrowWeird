class_name LeafArtPanel
extends RefCounted

const TOP_Y := 68.0
const ROW_STEP := 36.0
const BRANCH_Y := 220.0
const CONTROL_Y := 350.0

static func hit(panel: Rect2, point: Vector2) -> Dictionary:
	for index in 4:
		if button(panel, index).has_point(point):
			return {"id": "top", "index": index}
	for index in LeafPointLayout.SLOTS.size():
		var row := point_row(panel, index)
		if Rect2(row.position, Vector2(24.0, 28.0)).has_point(point):
			return {"id": "branch_add", "index": index}
		if Rect2(row.end - Vector2(24.0, 28.0), Vector2(24.0, 28.0)).has_point(point):
			return {"id": "branch_delete", "index": index}
		if row.has_point(point):
			return {"id": "branch_select", "index": index}
	for index in 4:
		var row := control_row(panel, index)
		if control_button(row, true).has_point(point):
			return {"id": "control", "index": index, "direction": -1}
		if control_button(row, false).has_point(point):
			return {"id": "control", "index": index, "direction": 1}
	if control_row(panel, 4).has_point(point):
		return {"id": "mirror"}
	return {}

static func draw(
	target: CanvasItem,
	panel: Rect2,
	tree_index: int,
	point_slot: StringName,
	points: Dictionary,
	selected: Dictionary,
	message: String,
	message_time: float
) -> void:
	var left := panel.position + Vector2(18.0, 28.0)
	target.draw_rect(panel, Color(0.09, 0.07, 0.055))
	target.draw_string(ThemeDB.fallback_font, left, "LEAF ART LAB", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color(0.55, 0.96, 0.74))
	target.draw_string(ThemeDB.fallback_font, left + Vector2(0.0, 24.0), "Tree %02d · manual placement" % (tree_index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.68, 0.62, 0.52))
	_draw_button(target, button(panel, 0), "Toggle leaf layer")
	_draw_button(target, button(panel, 1), "Copy leaf layout")
	_draw_button(target, button(panel, 2), "Previous tree")
	_draw_button(target, button(panel, 3), "Next tree")
	for index in LeafPointLayout.SLOTS.size():
		var row := point_row(panel, index)
		var slot := LeafPointLayout.SLOTS[index]
		var prefix := "> " if slot == point_slot else "  "
		target.draw_string(ThemeDB.fallback_font, row.position + Vector2(32.0, 19.0), "%s%s: %d" % [prefix, String(slot).capitalize(), (points[String(slot)] as Array).size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.88, 0.82, 0.70))
		_draw_button(target, Rect2(row.position, Vector2(24.0, 28.0)), "+")
		_draw_button(target, Rect2(row.end - Vector2(24.0, 28.0), Vector2(24.0, 28.0)), "−")
	_draw_controls(target, panel, selected)
	if message_time > 0.0:
		target.draw_string(ThemeDB.fallback_font, left + Vector2(0.0, panel.size.y - 58.0), message, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.52, 0.94, 0.72))
	target.draw_string(ThemeDB.fallback_font, left + Vector2(0.0, panel.size.y - 34.0), "Drag dot/handle · wheel size · Q/E rotate · M mirror · Ctrl+D duplicate", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.58, 0.54, 0.48))

static func _draw_controls(target: CanvasItem, panel: Rect2, selected: Dictionary) -> void:
	var labels := ["Asset", "Frame", "Rotation", "Scale", "Mirror"]
	for index in labels.size():
		var row := control_row(panel, index)
		if index < 4:
			_draw_button(target, control_button(row, true), "<")
			_draw_button(target, control_button(row, false), ">")
		var text := labels[index]
		if not selected.is_empty():
			match index:
				0: text += "  %02d" % (int(selected.asset) + 1)
				1: text += "  %02d/%02d" % [int(selected.frame) + 1, LeafPointLayout.frame_count(selected.asset)]
				2: text += "  %.1f°" % rad_to_deg(float(selected.rotation))
				3: text += "  %.2f" % float(selected.size)
				4: text += "  %s" % ("ON" if selected.mirrored else "OFF")
		target.draw_string(ThemeDB.fallback_font, row.position + Vector2(38.0, 19.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.91, 0.85, 0.72))

static func _draw_button(target: CanvasItem, rect: Rect2, text: String) -> void:
	target.draw_rect(rect, Color(0.18, 0.14, 0.10))
	target.draw_rect(rect, Color(0.46, 0.35, 0.21), false, 1.0)
	target.draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, rect.size.y * 0.68), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.91, 0.85, 0.72))

static func button(panel: Rect2, index: int) -> Rect2:
	return Rect2(panel.position + Vector2(18.0, TOP_Y + index * ROW_STEP), Vector2(panel.size.x - 36.0, 28.0))

static func point_row(panel: Rect2, index: int) -> Rect2:
	return Rect2(panel.position + Vector2(18.0, BRANCH_Y + index * ROW_STEP), Vector2(panel.size.x - 36.0, 28.0))

static func control_row(panel: Rect2, index: int) -> Rect2:
	return Rect2(panel.position + Vector2(18.0, CONTROL_Y + index * ROW_STEP), Vector2(panel.size.x - 36.0, 28.0))

static func control_button(row: Rect2, left: bool) -> Rect2:
	return Rect2(row.position if left else row.end - Vector2(30.0, 28.0), Vector2(30.0, 28.0))
