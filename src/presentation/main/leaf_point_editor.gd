class_name LeafPointEditor
extends Control

const SLOTS: Array[StringName] = [&"left", &"center", &"right"]
const TREE_COUNT := 12
const PANEL_RATIO := 0.27
const POINT_RADIUS := 8.0
const POINT_STEP := 0.005
const LEAF_SCALE := 0.055
const LEAF_PIVOT_Y := 0.94
const ROTATION_STEP := 0.08
const SIZE_STEP := 0.05
const POINT_FILE_PATH := "user://growweird_leaf_points.json"

var tree_index := 0
var leaf_layer_visible := false
var _points_by_tree: Dictionary = {}
var _point_slot: StringName = &"center"
var _selected_slot: StringName = &""
var _selected_index := -1
var _dragging := false
var _drag_axis := ""
var _message := ""
var _message_time := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)
	_ensure_defaults()
	_load_points()
	queue_redraw()

func set_tree(index: int) -> void:
	tree_index = posmod(index, TREE_COUNT)
	_selected_slot = &""
	_selected_index = -1
	queue_redraw()

func set_leaf_layer_visible(enabled: bool) -> void:
	leaf_layer_visible = enabled
	queue_redraw()

func refresh_leaves() -> void:
	_flash("Manual leaf layout: no random refresh")
	queue_redraw()

func leaf_points() -> Dictionary:
	return _points()

func leaf_points_code() -> String:
	_ensure_defaults()
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
	if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		if _has_selection():
			_adjust_size(SIZE_STEP if event.button_index == MOUSE_BUTTON_WHEEL_UP else -SIZE_STEP)
			accept_event()
		return
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
			_point_slot = hit.slot
			_drag_axis = "rotation" if event.position.distance_to(_rotation_screen(hit.slot, hit.index)) < POINT_RADIUS * 1.8 else "point"
			_dragging = true
			accept_event()
			queue_redraw()
			return
		if _tree_rect().has_point(event.position):
			_add_point(event.position, _point_slot)
			accept_event()
	else:
		_dragging = false
		_drag_axis = ""

func _key(event: InputEventKey) -> void:
	if not _has_selection():
		return
	var item := _selected_point()
	var move_step := POINT_STEP * (5.0 if event.shift_pressed else 1.0)
	if event.ctrl_pressed and event.keycode == KEY_D:
		_duplicate_selected()
		return
	match event.keycode:
		KEY_LEFT: item.position.x -= move_step
		KEY_RIGHT: item.position.x += move_step
		KEY_UP: item.position.y -= move_step
		KEY_DOWN: item.position.y += move_step
		KEY_DELETE, KEY_BACKSPACE:
			_delete_point()
			return
		KEY_PLUS, KEY_EQUAL: item.size = clampf(item.size + SIZE_STEP, 0.35, 2.0)
		KEY_MINUS: item.size = clampf(item.size - SIZE_STEP, 0.35, 2.0)
		KEY_Q: item.rotation -= ROTATION_STEP
		KEY_E: item.rotation += ROTATION_STEP
		KEY_M: item.mirrored = not bool(item.mirrored)
		_: return
	item.position = Vector2(clampf(item.position.x, 0.0, 1.0), clampf(item.position.y, 0.0, 1.0))
	_commit_selected(item)

func _panel_click(point: Vector2) -> void:
	if _button(0).has_point(point):
		leaf_layer_visible = not leaf_layer_visible
		_flash("Leaf layer %s" % ("ON" if leaf_layer_visible else "OFF"))
		queue_redraw()
		return
	if _button(1).has_point(point):
		DisplayServer.clipboard_set(leaf_points_code())
		_flash("Leaf layout copied")
		return
	if _button(2).has_point(point):
		set_tree(tree_index - 1)
		return
	if _button(3).has_point(point):
		set_tree(tree_index + 1)
		return
	for index in SLOTS.size():
		var row := _point_row(index)
		if Rect2(row.position, Vector2(24.0, 28.0)).has_point(point):
			_add_named_point(SLOTS[index])
			return
		if Rect2(row.end - Vector2(24.0, 28.0), Vector2(24.0, 28.0)).has_point(point):
			_delete_named_point(SLOTS[index])
			return
		if row.has_point(point):
			_point_slot = SLOTS[index]
			_flash("New leaves: %s branch" % String(_point_slot).capitalize())
			queue_redraw()
			return
	if not _has_selection():
		return
	for index in 4:
		var row := _control_row(index)
		if _control_button(row, true).has_point(point):
			_adjust_control(index, -1)
			return
		if _control_button(row, false).has_point(point):
			_adjust_control(index, 1)
			return
	if _control_row(4).has_point(point):
		_toggle_mirror()

func _adjust_control(index: int, direction: int) -> void:
	match index:
		0: _adjust_asset(direction)
		1: _adjust_frame(direction)
		2: _adjust_rotation(float(direction) * ROTATION_STEP)
		3: _adjust_size(float(direction) * SIZE_STEP)

func _add_point(screen: Vector2, slot: StringName) -> void:
	var local := _screen_to_tree(screen)
	var values: Array = _points()[String(slot)]
	values.append(LeafPointLayout.point(local.x, local.y))
	_selected_slot = slot
	_selected_index = values.size() - 1
	_point_slot = slot
	_changed("Leaf added to %s" % String(slot))

func _add_named_point(slot: StringName) -> void:
	var values: Array = _points()[String(slot)]
	var item := LeafPointLayout.point(0.50, 0.50)
	if not values.is_empty():
		item = LeafPointLayout.normalize_point(values.back()).duplicate(true)
		item.position = Vector2(clampf(item.position.x + 0.02, 0.0, 1.0), clampf(item.position.y - 0.02, 0.0, 1.0))
	values.append(item)
	_selected_slot = slot
	_selected_index = values.size() - 1
	_point_slot = slot
	_changed("Leaf added to %s" % String(slot))

func _duplicate_selected() -> void:
	var values: Array = _points()[String(_selected_slot)]
	var item := _selected_point().duplicate(true)
	item.position = Vector2(clampf(item.position.x + 0.02, 0.0, 1.0), clampf(item.position.y - 0.02, 0.0, 1.0))
	values.append(item)
	_selected_index = values.size() - 1
	_changed("Leaf duplicated")

func _delete_point() -> void:
	if not _has_selection():
		return
	var values: Array = _points()[String(_selected_slot)]
	values.remove_at(_selected_index)
	_selected_index = mini(_selected_index, values.size() - 1)
	if _selected_index < 0:
		_selected_slot = &""
	_changed("Leaf removed")

func _delete_named_point(slot: StringName) -> void:
	var values: Array = _points()[String(slot)]
	if values.is_empty():
		return
	_selected_slot = slot
	_selected_index = values.size() - 1
	_delete_point()

func _move_point(screen: Vector2) -> void:
	if not _has_selection():
		return
	var item := _selected_point()
	if _drag_axis == "rotation":
		var delta := screen - _point_screen(_selected_slot, _selected_index)
		if delta.length() > 2.0:
			item.rotation = delta.angle() + PI * 0.5
	else:
		item.position = _screen_to_tree(screen)
	_commit_selected(item)

func _adjust_asset(direction: int) -> void:
	var item := _selected_point()
	item.asset = posmod(int(item.asset) + direction, LeafPointLayout.LEAF_TEXTURES.size())
	item.frame = mini(int(item.frame), LeafPointLayout.frame_count(item.asset) - 1)
	_commit_selected(item, "Leaf asset %02d" % (int(item.asset) + 1))

func _adjust_frame(direction: int) -> void:
	var item := _selected_point()
	item.frame = posmod(int(item.frame) + direction, LeafPointLayout.frame_count(item.asset))
	_commit_selected(item, "Frame %02d" % (int(item.frame) + 1))

func _adjust_rotation(amount: float) -> void:
	var item := _selected_point()
	item.rotation = float(item.rotation) + amount
	_commit_selected(item)

func _adjust_size(amount: float) -> void:
	var item := _selected_point()
	item.size = clampf(float(item.size) + amount, 0.35, 2.0)
	_commit_selected(item)

func _toggle_mirror() -> void:
	var item := _selected_point()
	item.mirrored = not bool(item.mirrored)
	_commit_selected(item, "Mirror %s" % ("ON" if item.mirrored else "OFF"))

func _selected_point() -> Dictionary:
	return LeafPointLayout.normalize_point(_points()[String(_selected_slot)][_selected_index])

func _commit_selected(item: Dictionary, message := "") -> void:
	_points()[String(_selected_slot)][_selected_index] = item
	_changed(message)

func _has_selection() -> bool:
	return not _selected_slot.is_empty() and _selected_index >= 0 and _selected_index < (_points()[String(_selected_slot)] as Array).size()

func _ensure_defaults() -> void:
	for index in TREE_COUNT:
		if not _points_by_tree.has(index):
			_points_by_tree[index] = LeafPointLayout.default_points(index)

func _points() -> Dictionary:
	_ensure_defaults()
	return _points_by_tree[tree_index]

func _point_screen(slot: StringName, index: int) -> Vector2:
	var item := LeafPointLayout.normalize_point(_points()[String(slot)][index])
	var tree_rect := _tree_rect()
	return tree_rect.position + item.position * tree_rect.size

func _rotation_screen(slot: StringName, index: int) -> Vector2:
	var item := LeafPointLayout.normalize_point(_points()[String(slot)][index])
	return _point_screen(slot, index) + Vector2.UP.rotated(float(item.rotation)) * 32.0

func _screen_to_tree(screen: Vector2) -> Vector2:
	var rect := _tree_rect()
	return Vector2(clampf((screen.x - rect.position.x) / rect.size.x, 0.0, 1.0), clampf((screen.y - rect.position.y) / rect.size.y, 0.0, 1.0))

func _point_at(point: Vector2) -> Dictionary:
	for slot in SLOTS:
		for index in (_points()[String(slot)] as Array).size():
			if _point_screen(slot, index).distance_to(point) <= POINT_RADIUS * 1.8 or _rotation_screen(slot, index).distance_to(point) <= POINT_RADIUS * 1.8:
				return {"slot": slot, "index": index}
	return {}

func _canvas() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(size.x * (1.0 - PANEL_RATIO), size.y))

func _tree_rect() -> Rect2:
	var canvas := _canvas()
	var bounds := Rect2(canvas.position + Vector2(canvas.size.x * 0.08, canvas.size.y * 0.04), canvas.size * 0.84)
	return _fit(LeafPointLayout.TREES[tree_index], bounds)

func _panel() -> Rect2:
	var canvas := _canvas()
	return Rect2(Vector2(canvas.end.x, 0.0), Vector2(size.x - canvas.size.x, size.y))

func _point_row(index: int) -> Rect2:
	var panel := _panel()
	return Rect2(panel.position + Vector2(18.0, 220.0 + index * 36.0), Vector2(panel.size.x - 36.0, 28.0))

func _control_row(index: int) -> Rect2:
	var panel := _panel()
	return Rect2(panel.position + Vector2(18.0, 350.0 + index * 36.0), Vector2(panel.size.x - 36.0, 28.0))

func _control_button(row: Rect2, left: bool) -> Rect2:
	return Rect2(row.position if left else row.end - Vector2(30.0, 28.0), Vector2(30.0, 28.0))

func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.035, 0.03))
	var tree := LeafPointLayout.TREES[tree_index]
	draw_texture_rect(tree, _tree_rect(), false)
	if leaf_layer_visible:
		for slot in SLOTS:
			for index in (_points()[String(slot)] as Array).size():
				_draw_leaf(_point_screen(slot, index), LeafPointLayout.normalize_point(_points()[String(slot)][index]))
	for slot in SLOTS:
		for index in (_points()[String(slot)] as Array).size():
			_draw_point(slot, index)
	_draw_panel(_panel())

func _draw_leaf(center: Vector2, item: Dictionary) -> void:
	var texture := LeafPointLayout.LEAF_TEXTURES[int(item.asset)]
	var frame := clampi(int(item.frame), 0, LeafPointLayout.frame_count(item.asset) - 1)
	var source := Rect2(float(frame * LeafPointLayout.LEAF_FRAME_SIZE), 0.0, LeafPointLayout.LEAF_FRAME_SIZE, LeafPointLayout.LEAF_FRAME_SIZE)
	var leaf_size := Vector2.ONE * float(LeafPointLayout.LEAF_FRAME_SIZE) * LEAF_SCALE * float(item.size)
	var target := Rect2(Vector2(-leaf_size.x * 0.5, -leaf_size.y * LEAF_PIVOT_Y), leaf_size)
	var draw_scale := Vector2(-1.0, 1.0) if bool(item.mirrored) else Vector2.ONE
	draw_set_transform(center, float(item.rotation), draw_scale)
	draw_texture_rect_region(texture, target, source)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_point(slot: StringName, index: int) -> void:
	var point := _point_screen(slot, index)
	var rotation := _rotation_screen(slot, index)
	var selected := slot == _selected_slot and index == _selected_index
	var branch_selected := slot == _point_slot
	var color := Color(0.25, 0.94, 0.72) if selected else Color(0.98, 0.76, 0.26) if branch_selected else Color(0.72, 0.62, 0.40)
	draw_circle(point, POINT_RADIUS + 3.0 if selected else POINT_RADIUS, color)
	draw_circle(point, 3.0, Color(0.09, 0.07, 0.04))
	draw_line(point, rotation, color, 2.0, true)
	draw_circle(rotation, 4.0, color)

func _draw_panel(panel: Rect2) -> void:
	var left := panel.position + Vector2(18.0, 28.0)
	draw_rect(panel, Color(0.09, 0.07, 0.055))
	draw_string(ThemeDB.fallback_font, left, "LEAF ART LAB", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color(0.55, 0.96, 0.74))
	draw_string(ThemeDB.fallback_font, left + Vector2(0.0, 24.0), "Tree %02d · manual placement" % (tree_index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.68, 0.62, 0.52))
	_draw_button(_button(0), "Toggle leaf layer")
	_draw_button(_button(1), "Copy leaf layout")
	_draw_button(_button(2), "Previous tree")
	_draw_button(_button(3), "Next tree")
	for index in SLOTS.size():
		var row := _point_row(index)
		var slot := SLOTS[index]
		var prefix := "> " if slot == _point_slot else "  "
		draw_string(ThemeDB.fallback_font, row.position + Vector2(32.0, 19.0), "%s%s: %d" % [prefix, String(slot).capitalize(), (_points()[String(slot)] as Array).size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.88, 0.82, 0.70))
		_draw_button(Rect2(row.position, Vector2(24.0, 28.0)), "+")
		_draw_button(Rect2(row.end - Vector2(24.0, 28.0), Vector2(24.0, 28.0)), "−")
	_draw_selected_controls()
	if _message_time > 0.0:
		draw_string(ThemeDB.fallback_font, left + Vector2(0.0, panel.size.y - 58.0), _message, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.52, 0.94, 0.72))
	draw_string(ThemeDB.fallback_font, left + Vector2(0.0, panel.size.y - 34.0), "Drag dot/handle · wheel size · Q/E rotate · M mirror · Ctrl+D duplicate", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.58, 0.54, 0.48))

func _draw_selected_controls() -> void:
	var labels := ["Asset", "Frame", "Rotation", "Scale", "Mirror"]
	for index in labels.size():
		var row := _control_row(index)
		if index < 4:
			_draw_button(_control_button(row, true), "<")
			_draw_button(_control_button(row, false), ">")
		var text := labels[index]
		if _has_selection():
			var item := _selected_point()
			match index:
				0: text += "  %02d" % (int(item.asset) + 1)
				1: text += "  %02d/%02d" % [int(item.frame) + 1, LeafPointLayout.frame_count(item.asset)]
				2: text += "  %.1f°" % rad_to_deg(float(item.rotation))
				3: text += "  %.2f" % float(item.size)
				4: text += "  %s" % ("ON" if item.mirrored else "OFF")
		draw_string(ThemeDB.fallback_font, row.position + Vector2(38.0, 19.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.91, 0.85, 0.72))

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
	if not data is Dictionary:
		return
	var source: Variant = data.get("points", data)
	if not source is Dictionary:
		return
	for index in TREE_COUNT:
		var values: Variant = source.get(str(index), null)
		if values is Dictionary:
			_points_by_tree[index] = _normalize_points(values)

func _normalize_points(values: Dictionary) -> Dictionary:
	var result := {"left": [], "center": [], "right": []}
	for slot in SLOTS:
		for raw in values.get(String(slot), []):
			result[String(slot)].append(LeafPointLayout.normalize_point(raw))
	return result

func _save_points() -> void:
	var file := FileAccess.open(POINT_FILE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"points": LeafPointLayout.serializable_points(_points_by_tree)}))
	file.close()
