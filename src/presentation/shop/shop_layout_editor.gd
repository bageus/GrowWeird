class_name ShopLayoutEditor
extends RefCounted

const CONFIG_PATH := "user://growweird_shop_layout.cfg"
const MIN_SCALE := 0.5
const MAX_SCALE := 2.0

var _host: Control
var _targets: Array[Control] = []
var _keys: Dictionary = {}
var _config := ConfigFile.new()
var _active: Control
var _start_mouse := Vector2.ZERO
var _start_position := Vector2.ZERO

func _init(host: Control) -> void:
	_host = host
	_config.load(CONFIG_PATH)

func register(control: Control, key: String) -> void:
	if control == null or key.is_empty():
		return
	_targets = _targets.filter(func(item: Control) -> bool: return is_instance_valid(item))
	if not _targets.has(control):
		_targets.append(control)
	_keys[control] = key
	control.pivot_offset = control.size * 0.5
	_host.call_deferred("_apply_shop_layout", control, key)

func apply_saved(control: Control, key: String) -> void:
	if not is_instance_valid(control):
		return
	if _config.has_section_key(key, "position"):
		control.position = _config.get_value(key, "position", control.position)
	var factor := clampf(float(_config.get_value(key, "scale", 1.0)), MIN_SCALE, MAX_SCALE)
	control.scale = Vector2.ONE * factor
	control.pivot_offset = control.size * 0.5

func handle_input(event: InputEvent) -> bool:
	if not Input.is_key_pressed(KEY_CTRL):
		if event is InputEventMouseButton and not event.pressed:
			_finish_drag()
		return false
	if event is InputEventMouseButton:
		return _handle_button(event)
	if event is InputEventMouseMotion and _active != null:
		_move_active(event.position)
		return true
	return false

func _handle_button(event: InputEventMouseButton) -> bool:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_active = _target_at(event.position)
			if _active == null:
				return false
			_start_mouse = event.position
			_start_position = _active.position
			return true
		var handled := _active != null
		_finish_drag()
		return handled
	if not event.pressed or (event.button_index != MOUSE_BUTTON_WHEEL_UP and event.button_index != MOUSE_BUTTON_WHEEL_DOWN):
		return false
	var target := _target_at(event.position)
	if target == null:
		return false
	var current := target.scale.x
	var step := 1.1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.1
	var factor := clampf(current * step, MIN_SCALE, MAX_SCALE)
	target.scale = Vector2.ONE * factor
	target.pivot_offset = target.size * 0.5
	_save(target)
	return true

func _move_active(mouse_position: Vector2) -> void:
	var parent := _active.get_parent() as Control
	if parent == null:
		return
	var inverse := parent.get_global_transform_with_canvas().affine_inverse()
	var local_start := inverse * _start_mouse
	var local_now := inverse * mouse_position
	_active.position = _start_position + local_now - local_start

func _target_at(mouse_position: Vector2) -> Control:
	for index in range(_targets.size() - 1, -1, -1):
		var target := _targets[index]
		if not is_instance_valid(target) or not target.is_visible_in_tree():
			continue
		var local := target.get_global_transform_with_canvas().affine_inverse() * mouse_position
		if Rect2(Vector2.ZERO, target.size).has_point(local):
			return target
	return null

func _finish_drag() -> void:
	if _active != null and is_instance_valid(_active):
		_save(_active)
	_active = null

func _save(control: Control) -> void:
	var key := String(_keys.get(control, ""))
	if key.is_empty():
		return
	_config.set_value(key, "position", control.position)
	_config.set_value(key, "scale", control.scale.x)
	_config.save(CONFIG_PATH)
