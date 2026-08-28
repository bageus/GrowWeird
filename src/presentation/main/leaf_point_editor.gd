class_name LeafPointEditor
extends Control

const SLOTS: Array[StringName] = [&"left", &"center", &"right"]
const TREE_COUNT := 12
const PANEL_RATIO := 0.27
const POINT_RADIUS := 8.0
const POINT_STEP := 0.01
const LEAF_SCALE := 0.055
const POINT_FILE_PATH := "user://growweird_leaf_points.json"

var tree_index := 0
var leaf_layer_visible := false
var _points_by_tree: Dictionary = {}
var _leaves: Array[Dictionary] = []
var _point_slot: StringName = &"center"
var _selected_slot: StringName = &""
var _selected_index := -1
var _dragging := false
var _drag_axis := ""
var _seed := 1
var _message := ""
var _message_time := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)
	for index in TREE_COUNT:
		_points_by_tree[index] = LeafPointLayout.default_points(index)
	_load_points()
	_refresh_leaves()
	queue_redraw()

func set_tree(index: int) -> void:
	tree_index = posmod(index, TREE_COUNT)
	_selected_slot = &""
	_selected_index = -1
	_load_points()
	_refresh_leaves()
	queue_redraw()

func set_leaf_layer_visible(enabled: bool) -> void:
	leaf_layer_visible = enabled
	queue_redraw()

func refresh_leaves() -> void:
	_seed += 1
	_refresh_leaves()
	_flash("Leaf variations refreshed")

func leaf_points() -> Dictionary:
	return _points_by_tree.get(tree_index, {})

func leaf_points_code() -> String:
	return LeafPointLayout.points_code(_points_by_tree)

func _process(delta: float) -> void:
	if _message_time > 0.0:
		_message_time = maxf(0.0, _message_time - delta)
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and _dragging:
		_move_point(event.position)
		accept_event()
	elif event is InputEventMouseButton:
		_mouse(event)
	elif event is InputEventKey and event.pressed and not event.echo:
		_key(event)

func _mouse(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed:
		if _panel().has_point(event.position):
			_panel_click(event.position)
			accept_event()
			return
		var hit := _point_at(event.position)
		if not hit.is_empty():
			_selected_slot = hit.slot
			_selected_index = hit.index
			_drag_axis = "direction" if event.position.distance_to(_direction_screen(hit.slot, hit.index)) < POINT_RADIUS * 1.8 else "point"
			_dragging = true
			accept_event()
			queue_redraw()
			return
		if _canvas().has_point(event.position):
			_add_point(event.position)
			accept_event()
	else:
		_dragging = false
		_drag_axis = ""

func _key(event: InputEventKey) -> void:
	if _selected_slot.is_empty() or _selected_index < 0:
		return
	var point: Dictionary = LeafPointLayout.normalize_point(_points()[String(_selected_slot)][_selected_index])
	match event.keycode:
		KEY_LEFT: point.position.x -= POINT_STEP
		KEY_RIGHT: point.position.x += POINT_STEP
		KEY_UP: point.position.y -= POINT_STEP
		KEY_DOWN: point.position.y += POINT_STEP
		KEY_DELETE, KEY_BACKSPACE:
			_delete_point()
			return
		KEY_PLUS, KEY_EQUAL: point.size = clampf(point.size + POINT_STEP, 0.35, 2.0)
		KEY_MINUS: point.size = clampf(point.size - POINT_STEP, 0.35, 2.0)
		_: return
	point.position = Vector2(clampf(point.position.x, 0.02, 0.98), clampf(point.position.y, 0.02, 0.98))
	_points()[String(_selected_slot)][_selected_index] = point
	_changed()

func _panel_click(point: Vector2) -> void:
	if _button(0).has_point(point):
		leaf_layer_visible = not leaf_layer_visible
		_flash("Leaf layer %s" % ("ON" if leaf_layer_visible else "OFF"))
		queue_redraw()
		return
	if _button(1).has_point(point):
		DisplayServer.clipboard_set(leaf_points_code())
		_flash("Leaf coordinates copied")
		return
	if _button(2).has_point(point):
		set_tree(tree_index - 1)
		return
	if _button(3).has_point(point):
		set_tree(tree_index + 1)
		return
	if _button(4).has_point(point):
		refresh_leaves()
		return
	for index in SLOTS.size():
		var row := _point_row(index)
		if Rect2(row.position, Vector2(24.0, 28.0)).has_point(point):
			_point_slot = SLOTS[index]
			_flash("New points: %s" % String(_point_slot).capitalize())
			queue_redraw()
			return
		if Rect2(row.end - Vector2(24.0, 28.0), Vector2(24.0, 28.0)).has_point(point):
			_point_slot = SLOTS[index]
			_delete_named_point(_point_slot)
			return

func _add_point(point: Vector2) -> void:
	var local := (point - _canvas().position) / _canvas().size
	var slot := _nearest_slot(local)
	var values: Array = _points()[String(slot)]
	values.append(LeafPointLayout.point(clampf(local.x, 0.02, 0.98), clampf(local.y, 0.02, 0.98)))
	_selected_slot = slot
	_selected_index = values.size() - 1
	_changed("Point added to %s" % slot)

func _add_named_point(slot: StringName) -> void:
	var values: Array = _points()[String(slot)]
	var point := Vector2(0.50, 0.50)
	if not values.is_empty():
		point = LeafPointLayout.normalize_point(values.back()).position + Vector2(0.0, -0.06)
	values.append(LeafPointLayout.point(clampf(point.x, 0.02, 0.98), clampf(point.y, 0.02, 0.98)))
	_selected_slot = slot
	_selected_index = values.size() - 1
	_changed("Point added to %s" % slot)

func _delete_point() -> void:
	if _selected_slot.is_empty() or _selected_index < 0:
		return
	var values: Array = _points()[String(_selected_slot)]
	if _selected_index >= values.size():
		return
	values.remove_at(_selected_index)
	_selected_index = mini(_selected_index, values.size() - 1)
	if _selected_index < 0:
		_selected_slot = &""
	_changed("Point removed")

func _delete_named_point(slot: StringName) -> void:
	var values: Array = _points()[String(slot)]
	if values.is_empty():
		return
	_selected_slot = slot
	_selected_index = values.size() - 1
	_delete_point()

func _move_point(point: Vector2) -> void:
	if _selected_slot.is_empty() or _selected_index < 0:
		return
	var local := (point - _canvas().position) / _canvas().size
	var item := LeafPointLayout.normalize_point(_points()[String(_selected_slot)][_selected_index])
	if _drag_axis == "direction":
		var origin := _point_screen(_selected_slot, _selected_index)
		item.direction = Vector2(clampf((point.x - origin.x) / 28.0, -1.0, 1.0), clampf((point.y - origin.y) / 28.0, -1.0, 1.0))
		_points()[String(_selected_slot)][_selected_index] = item
		_changed()
	else:
		_set_point(Vector2(clampf(local.x, 0.02, 0.98), clampf(local.y, 0.02, 0.98)))

func _set_point(point: Vector2) -> void:
	var item := LeafPointLayout.normalize_point(_points()[String(_selected_slot)][_selected_index])
	item.position = point
	_points()[String(_selected_slot)][_selected_index] = item
	_changed()

func _points() -> Dictionary:
	var points: Variant = _points_by_tree.get(tree_index, LeafPointLayout.default_points(tree_index))
	if not _points_by_tree.has(tree_index):
		_points_by_tree[tree_index] = points
	return points

func _nearest_slot(point: Vector2) -> StringName:
	return &"left" if point.x < 0.46 else &"right" if point.x > 0.54 else &"center"

func _point_screen(slot: StringName, index: int) -> Vector2:
	var item: Dictionary = LeafPointLayout.normalize_point(_points()[String(slot)][index])
	return _canvas().position + item.position * _canvas().size

func _direction_screen(slot: StringName, index: int) -> Vector2:
	var item: Dictionary = LeafPointLayout.normalize_point(_points()[String(slot)][index])
	return _point_screen(slot, index) + item.direction * 28.0

func _point_at(point: Vector2) -> Dictionary:
	for slot in SLOTS:
		var values: Array = _points()[String(slot)]
		for index in values.size():
			var screen := _point_screen(slot, index)
			if screen.distance_to(point) <= POINT_RADIUS * 1.8 or _direction_screen(slot, index).distance_to(point) <= POINT_RADIUS * 1.8:
				return {"slot": slot, "index": index}
	return {}

func _canvas() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(size.x * (1.0 - PANEL_RATIO), size.y))

func _panel() -> Rect2:
	var canvas := _canvas()
	return Rect2(Vector2(canvas.end.x, 0.0), Vector2(size.x - canvas.size.x, size.y))

func _point_row(index: int) -> Rect2:
	var panel := _panel()
	return Rect2(panel.position + Vector2(18.0, 224.0 + index * 36.0), Vector2(panel.size.x - 36.0, 28.0))

func _refresh_leaves() -> void:
	_leaves.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed * 7919 + tree_index
	for slot in SLOTS:
		for raw in _points().get(String(slot), []):
			var item: Dictionary = LeafPointLayout.normalize_point(raw)
			_leaves.append({"position": item.position, "frame": rng.randi_range(0, 5), "angle": item.direction.angle() + rng.randf_range(-0.20, 0.20), "mirrored": item.direction.x < 0.0, "scale": item.size * rng.randf_range(0.92, 1.08)})

func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var canvas := _canvas()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.035, 0.03))
	var tree := LeafPointLayout.TREES[tree_index]
	draw_texture_rect(tree, _fit(tree, Rect2(canvas.position + Vector2(canvas.size.x * 0.08, canvas.size.y * 0.04), canvas.size * 0.84)), false)
	if leaf_layer_visible:
		for leaf in _leaves:
			_draw_leaf(canvas.position + leaf.position * canvas.size, leaf)
	for slot in SLOTS:
		for index in _points()[String(slot)].size():
			var point := _point_screen(slot, index)
			var direction := _direction_screen(slot, index)
			var selected: bool = slot == _selected_slot and index == _selected_index
			var color := Color(0.25, 0.94, 0.72) if selected else Color(0.98, 0.76, 0.26)
			draw_circle(point, POINT_RADIUS + 3.0 if selected else POINT_RADIUS, color)
			draw_circle(point, 3.0, Color(0.09, 0.07, 0.04))
			draw_line(point, direction, color, 2.0, true)
			draw_circle(direction, 4.0, color)
	_draw_panel(_panel())

func _draw_leaf(center: Vector2, leaf: Dictionary) -> void:
	var source := Rect2(float(leaf.frame) * 512.0, 0.0, 512.0, 512.0)
	var leaf_size := Vector2(512.0, 512.0) * LEAF_SCALE * float(leaf.scale)
	draw_set_transform(center, float(leaf.angle), Vector2.ONE)
	draw_texture_rect_region(LeafPointLayout.LEAF_TEXTURE, Rect2(-leaf_size * 0.5, leaf_size), source, Color.WHITE, bool(leaf.mirrored))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_panel(panel: Rect2) -> void:
	var left := panel.position + Vector2(18.0, 28.0)
	draw_rect(panel, Color(0.09, 0.07, 0.055))
	draw_string(ThemeDB.fallback_font, left, "LEAF POINT LAB", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color(0.55, 0.96, 0.74))
	draw_string(ThemeDB.fallback_font, left + Vector2(0.0, 24.0), "Tree %02d · %s" % [tree_index + 1, "leaf layer ON" if leaf_layer_visible else "leaf layer OFF"], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.68, 0.62, 0.52))
	_draw_button(_button(0), "Toggle leaf layer")
	_draw_button(_button(1), "Copy leaf coordinates")
	_draw_button(_button(2), "Previous tree")
	_draw_button(_button(3), "Next tree")
	_draw_button(_button(4), "Refresh leaves")
	for index in SLOTS.size():
		var row := _point_row(index)
		draw_string(ThemeDB.fallback_font, row.position + Vector2(32.0, 19.0), "%s points: %d" % [String(SLOTS[index]).capitalize(), (_points()[String(SLOTS[index])] as Array).size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.88, 0.82, 0.70))
		_draw_button(Rect2(row.position, Vector2(24.0, 28.0)), "+")
		_draw_button(Rect2(row.end - Vector2(24.0, 28.0), Vector2(24.0, 28.0)), "−")
	var selected_text := "none"
	if not _selected_slot.is_empty() and _selected_index >= 0:
		var point: Dictionary = LeafPointLayout.normalize_point(_points()[String(_selected_slot)][_selected_index])
		selected_text = "%s[%d]  x %.4f  y %.4f  size %.2f  dir %.2f,%.2f" % [_selected_slot, _selected_index, point.position.x, point.position.y, point.size, point.direction.x, point.direction.y]
	draw_string(ThemeDB.fallback_font, left + Vector2(0.0, 370.0), "SELECTED POINT", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.60, 0.55, 0.47))
	draw_string(ThemeDB.fallback_font, left + Vector2(0.0, 390.0), selected_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.84, 0.48))
	draw_string(ThemeDB.fallback_font, left + Vector2(0.0, panel.size.y - 38.0), "Click: add · drag dot/arrow · +/- size · Delete: remove", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.58, 0.54, 0.48))
	if _message_time > 0.0:
		draw_string(ThemeDB.fallback_font, left + Vector2(0.0, panel.size.y - 60.0), _message, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.52, 0.94, 0.72))

func _draw_button(rect: Rect2, text: String) -> void:
	draw_rect(rect, Color(0.18, 0.14, 0.10))
	draw_rect(rect, Color(0.46, 0.35, 0.21), false, 1.0)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, rect.size.y * 0.68), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.91, 0.85, 0.72))

func _button(index: int) -> Rect2:
	var panel := _panel()
	return Rect2(panel.position + Vector2(18.0, 68.0 + index * 36.0), Vector2(panel.size.x - 36.0, 28.0))

func _fit(texture: Texture2D, bounds: Rect2) -> Rect2:
	var scale := minf(bounds.size.x / texture.get_width(), bounds.size.y / texture.get_height())
	var draw_size := Vector2(texture.get_width(), texture.get_height()) * scale
	return Rect2(bounds.position + (bounds.size - draw_size) * 0.5, draw_size)

func _changed(message := "") -> void:
	_save_points()
	_refresh_leaves()
	if not message.is_empty():
		_flash(message)
	queue_redraw()

func _flash(text: String) -> void:
	_message = text
	_message_time = 2.5
	queue_redraw()
func _load_points() -> void:
	var file := FileAccess.open(POINT_FILE_PATH, FileAccess.READ) if FileAccess.file_exists(POINT_FILE_PATH) else null
	if file == null:
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if data is Dictionary and data.get("points") is Dictionary:
		for index in TREE_COUNT:
			var values: Variant = data.points.get(str(index), null)
			if values is Dictionary:
				_points_by_tree[index] = _normalize_points(values)
func _normalize_points(values: Dictionary) -> Dictionary:
	for slot in SLOTS:
		var normalized: Array = []
		for raw in values.get(String(slot), []):
			normalized.append(LeafPointLayout.normalize_point(raw))
		values[String(slot)] = normalized
	return values
func _save_points() -> void:
	var file := FileAccess.open(POINT_FILE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(_points_by_tree))
	file.close()
