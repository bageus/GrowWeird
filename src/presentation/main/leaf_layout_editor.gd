class_name LeafLayoutEditor
extends Control

signal selection_changed(scale_variance: float, direction_variance: float, has_selection: bool)

const LAYOUT_PATH := "res://content/visual/tree_leaf_layouts.json"
const LEAF_SHEET: Texture2D = preload("res://assets/leaf/leaf_normal_01.png")
const FIRST_TREE_STAGE := 4
const LAST_TREE_STAGE := 13
const BASE_LEAF_SIZE := Vector2(58.0, 58.0)
const HIT_RADIUS := 16.0

var enabled := false
var stage := FIRST_TREE_STAGE
var layouts: Dictionary = {}
var selected_index := -1
var _dragging := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	layouts = _load_layouts()
	queue_redraw()

func set_stage(value: int) -> void:
	var next_stage := clampi(value, FIRST_TREE_STAGE, LAST_TREE_STAGE)
	if next_stage == stage:
		queue_redraw()
		return
	stage = next_stage
	selected_index = -1
	_emit_selection()
	queue_redraw()

func set_editing(value: bool) -> void:
	enabled = value
	mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	if not enabled:
		selected_index = -1
	_emit_selection()
	queue_redraw()

func set_selected_variance(scale_percent: float, direction_percent: float) -> void:
	var points := _stage_points()
	if selected_index < 0 or selected_index >= points.size():
		return
	var point: Dictionary = points[selected_index]
	point["scale_variance"] = clampf(scale_percent, 1.0, 15.0)
	point["direction_variance"] = clampf(direction_percent, 0.5, 7.0)
	points[selected_index] = point
	_store_stage_points(points)
	queue_redraw()

func save_layout() -> bool:
	var directory := DirAccess.open("res://")
	if directory != null:
		directory.make_dir_recursive("content/visual")
	var file := FileAccess.open(LAYOUT_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(layouts, "\t"))
	return true

func _gui_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		_move_selected((event as InputEventMouseMotion).position)
		accept_event()

func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			selected_index = _point_at(event.position)
			if selected_index < 0:
				selected_index = _add_point(event.position)
			_dragging = true
			_emit_selection()
			queue_redraw()
		else:
			_dragging = false
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_remove_point_at(event.position)
	elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var direction := 1.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0
		if event.shift_pressed or Input.is_key_pressed(KEY_SHIFT):
			_rotate_selected(direction * deg_to_rad(5.0))
		else:
			_scale_selected(1.12 if direction > 0.0 else 1.0 / 1.12)

func _draw() -> void:
	var points := _stage_points()
	for index in range(points.size()):
		var point: Dictionary = points[index]
		var point_position := _position_for(point)
		var scale_factor := float(point.get("scale", 1.0)) * _random_scale(index, point)
		var base_angle := float(point.get("angle", 0.0))
		var angle := base_angle + _random_angle(index, point)
		_draw_leaf(point_position, scale_factor, angle)
		if enabled:
			_draw_marker(point_position, float(point.get("scale", 1.0)), base_angle, index == selected_index)

func _draw_leaf(point_position: Vector2, scale_factor: float, angle: float) -> void:
	var source := Rect2(Vector2.ZERO, Vector2(512.0, 512.0))
	var leaf_size := BASE_LEAF_SIZE * scale_factor
	draw_set_transform(point_position, angle, Vector2.ONE)
	draw_texture_rect_region(LEAF_SHEET, Rect2(-leaf_size * 0.5, leaf_size), source)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_marker(point_position: Vector2, scale_factor: float, angle: float, selected: bool) -> void:
	var color := Color("fff06a") if selected else Color("55d9ff")
	var radius := 7.0 * scale_factor
	var direction := Vector2.from_angle(angle)
	draw_circle(point_position, radius, Color(color, 0.42))
	draw_arc(point_position, radius, 0.0, TAU, 18, color, 2.0, true)
	draw_line(point_position, point_position + direction * (24.0 * scale_factor), color, 3.0, true)
	var tip := point_position + direction * (24.0 * scale_factor)
	draw_line(tip, tip - direction.rotated(0.55) * 8.0, color, 3.0, true)
	draw_line(tip, tip - direction.rotated(-0.55) * 8.0, color, 3.0, true)

func _add_point(point_position: Vector2) -> int:
	var points := _stage_points()
	points.append({
		"x": clampf(point_position.x / maxf(size.x, 1.0), 0.0, 1.0),
		"y": clampf(point_position.y / maxf(size.y, 1.0), 0.0, 1.0),
		"scale": 1.0,
		"angle": 0.0,
		"scale_variance": 1.0,
		"direction_variance": 0.5,
	})
	_store_stage_points(points)
	return points.size() - 1

func _move_selected(point_position: Vector2) -> void:
	var points := _stage_points()
	if selected_index < 0 or selected_index >= points.size():
		return
	var point: Dictionary = points[selected_index]
	point["x"] = clampf(point_position.x / maxf(size.x, 1.0), 0.0, 1.0)
	point["y"] = clampf(point_position.y / maxf(size.y, 1.0), 0.0, 1.0)
	points[selected_index] = point
	_store_stage_points(points)
	queue_redraw()

func _scale_selected(factor: float) -> void:
	_change_selected("scale", func(value: float) -> float: return clampf(value * factor, 0.25, 3.0))

func _rotate_selected(delta: float) -> void:
	_change_selected("angle", func(value: float) -> float: return fposmod(value + delta, TAU))

func _change_selected(property: String, transform: Callable) -> void:
	var points := _stage_points()
	if selected_index < 0 or selected_index >= points.size():
		return
	var point: Dictionary = points[selected_index]
	point[property] = transform.call(float(point.get(property, 1.0 if property == "scale" else 0.0)))
	points[selected_index] = point
	_store_stage_points(points)
	queue_redraw()

func _remove_point_at(point_position: Vector2) -> void:
	var index := _point_at(point_position)
	if index < 0:
		return
	var points := _stage_points()
	points.remove_at(index)
	selected_index = -1
	_store_stage_points(points)
	_emit_selection()
	queue_redraw()

func _point_at(point_position: Vector2) -> int:
	var points := _stage_points()
	for index in range(points.size() - 1, -1, -1):
		var point: Dictionary = points[index]
		var center := _position_for(point)
		var scale_factor := float(point.get("scale", 1.0))
		if point_position.distance_to(center) <= HIT_RADIUS * scale_factor:
			return index
		var rendered_scale := scale_factor * _random_scale(index, point)
		var rendered_angle := float(point.get("angle", 0.0)) + _random_angle(index, point)
		var leaf_local := (point_position - center).rotated(-rendered_angle)
		var half_size := BASE_LEAF_SIZE * rendered_scale * 0.5
		if absf(leaf_local.x) <= half_size.x and absf(leaf_local.y) <= half_size.y:
			return index
	return -1

func _position_for(point: Dictionary) -> Vector2:
	return Vector2(float(point.get("x", 0.5)) * size.x, float(point.get("y", 0.5)) * size.y)

func _random_scale(index: int, point: Dictionary) -> float:
	var random := RandomNumberGenerator.new()
	random.seed = hash("%d:%d:scale" % [stage, index])
	var variance := float(point.get("scale_variance", 1.0)) / 100.0
	return random.randf_range(1.0 - variance, 1.0 + variance)

func _random_angle(index: int, point: Dictionary) -> float:
	var random := RandomNumberGenerator.new()
	random.seed = hash("%d:%d:direction" % [stage, index])
	var variance := float(point.get("direction_variance", 0.5)) / 100.0
	return random.randf_range(-TAU * variance, TAU * variance)

func _stage_points() -> Array:
	var value: Variant = layouts.get(str(stage + 1), [])
	return value.duplicate(true) if value is Array else []

func _store_stage_points(points: Array) -> void:
	layouts[str(stage + 1)] = points

func _emit_selection() -> void:
	var points := _stage_points()
	if selected_index < 0 or selected_index >= points.size():
		selection_changed.emit(1.0, 0.5, false)
		return
	var point: Dictionary = points[selected_index]
	selection_changed.emit(float(point.get("scale_variance", 1.0)), float(point.get("direction_variance", 0.5)), true)

func _load_layouts() -> Dictionary:
	if not FileAccess.file_exists(LAYOUT_PATH):
		return {}
	var file := FileAccess.open(LAYOUT_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	return parsed if parsed is Dictionary else {}
