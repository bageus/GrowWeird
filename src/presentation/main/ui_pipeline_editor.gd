class_name UIPipelineEditor
extends Control

signal layout_changed(id: StringName, position: Vector2)
signal saved

const FILE_PATH := "user://growweird_ui_pipeline.json"

var _targets: Dictionary = {}
var _positions: Dictionary = {}
var _defaults: Dictionary = {}
var _selected: StringName = &""
var _dragging: StringName = &""
var _drag_offset := Vector2.ZERO
var _message := "Перетащите кнопки и сохраните координаты"

func configure(targets: Dictionary, defaults: Dictionary) -> void:
	_targets = targets
	_defaults = defaults.duplicate(true)
	_positions = defaults.duplicate(true)
	_load_layout()
	_apply_positions()
	queue_redraw()

func set_active(active: bool) -> void:
	visible = active
	mouse_filter = Control.MOUSE_FILTER_STOP if active else Control.MOUSE_FILTER_IGNORE
	if active:
		_message = "Перетащите кнопки и сохраните координаты"
		_apply_positions()
	queue_redraw()

func save_layout() -> void:
	var data := {}
	for id in _positions:
		var position: Vector2 = _positions[id]
		data[String(id)] = {"x": position.x, "y": position.y}
	var file := FileAccess.open(FILE_PATH, FileAccess.WRITE)
	if file == null:
		_message = "Не удалось сохранить координаты"
		queue_redraw()
		return
	file.store_string(JSON.stringify(data))
	file.close()
	_message = "Координаты сохранены"
	saved.emit()
	queue_redraw()

func reset_layout() -> void:
	_positions = _defaults.duplicate(true)
	_apply_positions()
	_message = "Положение кнопок сброшено"
	queue_redraw()

func coordinates() -> Dictionary:
	return _positions.duplicate(true)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_input(true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_positions()
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _save_rect().has_point(event.position):
				save_layout()
				accept_event()
				return
			if _reset_rect().has_point(event.position):
				reset_layout()
				accept_event()
				return
			var id := _target_at(event.position)
			if id != &"":
				_selected = id
				_dragging = id
				_drag_offset = event.position - _target_center(id)
				accept_event()
				queue_redraw()
		else:
			_dragging = &""
			accept_event()
	elif event is InputEventMouseMotion and _dragging != &"":
		var center: Vector2 = event.position - _drag_offset
		var normalized := Vector2(
			clampf(center.x / maxf(size.x, 1.0), 0.03, 0.97),
			clampf(center.y / maxf(size.y, 1.0), 0.05, 0.95)
		)
		_positions[_dragging] = normalized
		_apply_one(_dragging)
		layout_changed.emit(_dragging, normalized)
		accept_event()
		queue_redraw()

func _target_at(point: Vector2) -> StringName:
	var ids: Array = _targets.keys()
	ids.reverse()
	for raw_id in ids:
		var id := StringName(raw_id)
		if _target_rect(id).grow(5.0).has_point(point):
			return id
	return &""

func _target_center(id: StringName) -> Vector2:
	return Vector2(_positions.get(String(id), Vector2(0.5, 0.5))) * size

func _target_rect(id: StringName) -> Rect2:
	var target := _targets.get(String(id)) as Control
	if target == null:
		return Rect2()
	var top_left: Vector2 = target.global_position - global_position
	return Rect2(top_left, target.size)

func _apply_positions() -> void:
	for raw_id in _targets:
		_apply_one(StringName(raw_id))

func _apply_one(id: StringName) -> void:
	var target := _targets.get(String(id)) as Control
	if target == null or not _positions.has(String(id)):
		return
	target.global_position = global_position + _target_center(id) - target.size * 0.5

func _draw() -> void:
	if not visible or size.x <= 1.0:
		return
	for raw_id in _targets:
		var id := StringName(raw_id)
		var rect := _target_rect(id)
		var color := Color(1.0, 0.78, 0.20, 0.95) if id == _selected else Color(0.30, 0.90, 0.72, 0.78)
		draw_rect(rect, color, false, 2.0)
		draw_circle(_target_center(id), 4.0, color)
	draw_rect(Rect2(12.0, 12.0, 360.0, 38.0), Color(0.05, 0.04, 0.03, 0.88), true)
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 37.0), _message, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.87, 0.54))

func _save_rect() -> Rect2:
	return Rect2(12.0, size.y - 54.0, 190.0, 36.0)

func _reset_rect() -> Rect2:
	return Rect2(210.0, size.y - 54.0, 130.0, 36.0)

func _draw_action_button(rect: Rect2, text: String) -> void:
	draw_rect(rect, Color(0.12, 0.28, 0.23, 0.96), true)
	draw_rect(rect, Color(0.30, 0.90, 0.72, 0.90), false, 2.0)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(10.0, 24.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.88, 1.0, 0.92))

func _load_layout() -> void:
	if not FileAccess.file_exists(FILE_PATH):
		return
	var file := FileAccess.open(FILE_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file else null
	if file:
		file.close()
	if not parsed is Dictionary:
		return
	for raw_id in parsed:
		var id := StringName(raw_id)
		if not _positions.has(String(id)) or not parsed[raw_id] is Dictionary:
			continue
		var value: Dictionary = parsed[raw_id]
		_positions[id] = Vector2(
			clampf(float(value.get("x", _positions[id].x)), 0.03, 0.97),
			clampf(float(value.get("y", _positions[id].y)), 0.05, 0.95)
		)
