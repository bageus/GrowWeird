class_name SceneDraggablePanel
extends PanelContainer

signal position_committed(layout_id: StringName, normalized_position: Vector2)
signal drag_moved(layout_id: StringName)
signal scale_committed(layout_id: StringName, scale_factor: float)

const DRAG_THRESHOLD := 5.0

@export var layout_id: StringName = &""
@export var drag_handle_height := 30.0
@export var allow_scaling := false
@export_range(0.4, 1.0, 0.05) var minimum_scale := 0.6
@export_range(1.0, 3.0, 0.05) var maximum_scale := 1.8

var scale_factor := 1.0

var _tracking := false
var _dragging := false
var _press_local := Vector2.ZERO
var _press_global := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_ARROW

func apply_normalized_position(value: Vector2) -> void:
	var parent_control := get_parent() as Control
	if parent_control == null:
		return
	var available := _available_space(parent_control)
	position = Vector2(
		clampf(value.x, 0.0, 1.0) * available.x,
		clampf(value.y, 0.0, 1.0) * available.y
	)

func normalized_position() -> Vector2:
	var parent_control := get_parent() as Control
	if parent_control == null:
		return Vector2.ZERO
	var available := _available_space(parent_control)
	return Vector2(
		position.x / maxf(available.x, 1.0),
		position.y / maxf(available.y, 1.0)
	)

func apply_scale_factor(value: float) -> void:
	scale_factor = clampf(value, minimum_scale, maximum_scale)
	scale = Vector2.ONE * scale_factor
	var parent_control := get_parent() as Control
	if parent_control != null:
		position = _clamp_position(parent_control, position)

func _input(event: InputEvent) -> void:
	if _handle_scale_input(event):
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if not Input.is_key_pressed(KEY_CTRL):
				return
			if not get_global_rect().has_point(event.position):
				return
			_tracking = true
			_dragging = false
			_press_local = get_local_mouse_position()
			_press_global = get_global_mouse_position()
			mouse_default_cursor_shape = Control.CURSOR_MOVE
			get_viewport().set_input_as_handled()
		else:
			if not _tracking:
				return
			if _dragging:
				position_committed.emit(layout_id, normalized_position())
			_tracking = false
			_dragging = false
			mouse_default_cursor_shape = Control.CURSOR_ARROW
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _tracking:
		_handle_mouse_motion()

func _handle_scale_input(event: InputEvent) -> bool:
	if not allow_scaling or not Input.is_key_pressed(KEY_CTRL):
		return false
	if not (event is InputEventMouseButton) or not event.pressed:
		return false
	if event.button_index != MOUSE_BUTTON_WHEEL_UP and event.button_index != MOUSE_BUTTON_WHEEL_DOWN:
		return false
	if not get_global_rect().has_point(event.position):
		return false
	var factor := 1.1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.1
	apply_scale_factor(scale_factor * factor)
	scale_committed.emit(layout_id, scale_factor)
	get_viewport().set_input_as_handled()
	return true

func _get_drag_region_height() -> float:
	if drag_handle_height <= 0.0:
		return size.y
	return minf(drag_handle_height, size.y)

func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.pressed:
		if drag_handle_height > 0.0 and event.position.y > _get_drag_region_height():
			return
		_tracking = true
		_dragging = false
		_press_local = event.position
		_press_global = get_global_mouse_position()
		mouse_default_cursor_shape = Control.CURSOR_MOVE
		accept_event()
		return
	if not _tracking:
		return
	if _dragging:
		position_committed.emit(layout_id, normalized_position())
	_tracking = false
	_dragging = false
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	accept_event()

func _handle_mouse_motion() -> void:
	var parent_control := get_parent() as Control
	if parent_control == null:
		return
	var delta := get_global_mouse_position() - _press_global
	if not _dragging and delta.length() >= DRAG_THRESHOLD:
		_dragging = true
	if not _dragging:
		return
	var target := parent_control.get_local_mouse_position() - _press_local
	position = _clamp_position(parent_control, target)
	drag_moved.emit(layout_id)
	accept_event()

func _clamp_position(parent_control: Control, value: Vector2) -> Vector2:
	var available := _available_space(parent_control)
	return Vector2(
		clampf(value.x, 0.0, available.x),
		clampf(value.y, 0.0, available.y)
	)

func _available_space(parent_control: Control) -> Vector2:
	return Vector2(
		maxf(parent_control.size.x - size.x * scale_factor, 0.0),
		maxf(parent_control.size.y - size.y * scale_factor, 0.0)
	)
