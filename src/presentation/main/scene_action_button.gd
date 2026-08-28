class_name SceneActionButton
extends Button

signal activated(action_id: StringName)
signal position_committed(action_id: StringName, normalized_position: Vector2)
signal drag_moved(action_id: StringName)

const DRAG_THRESHOLD := 6.0

@export var action_id: StringName = &""

var _tracking := false
var _dragging := false
var _press_local := Vector2.ZERO
var _press_global := Vector2.ZERO

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

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

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion and _tracking:
		_handle_mouse_motion()

func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.pressed:
		_tracking = true
		_dragging = false
		_press_local = event.position
		_press_global = get_global_mouse_position()
		accept_event()
		return
	if not _tracking:
		return
	if _dragging:
		position_committed.emit(action_id, normalized_position())
	else:
		activated.emit(action_id)
	_tracking = false
	_dragging = false
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
	drag_moved.emit(action_id)
	accept_event()

func _clamp_position(parent_control: Control, value: Vector2) -> Vector2:
	var available := _available_space(parent_control)
	return Vector2(
		clampf(value.x, 0.0, available.x),
		clampf(value.y, 0.0, available.y)
	)

func _available_space(parent_control: Control) -> Vector2:
	return Vector2(
		maxf(parent_control.size.x - size.x, 0.0),
		maxf(parent_control.size.y - size.y, 0.0)
	)
