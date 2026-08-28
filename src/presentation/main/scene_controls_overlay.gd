class_name SceneControlsOverlay
extends Control

signal action_requested(action_id: StringName)

const FILE_PATH := "user://growweird_scene_buttons.json"
const DEFAULT_POSITIONS := {
	"water": Vector2(0.04, 0.58),
	"spray": Vector2(0.04, 0.66),
	"lighting": Vector2(0.78, 0.10),
	"window": Vector2(0.78, 0.18),
	"prune": Vector2(0.78, 0.50),
	"harvest": Vector2(0.78, 0.58),
	"sell_plant": Vector2(0.78, 0.66),
	"recycle_plant": Vector2(0.78, 0.74),
	"cancel": Vector2(0.42, 0.86),
}

var _buttons: Dictionary = {}
var _layout: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_collect_buttons()
	_layout = _load_layout()
	resized.connect(_on_resized)
	call_deferred("_apply_layout")

func set_lighting_options_visible(enabled: bool) -> void:
	var menu := get_node_or_null("LightingOptions") as Control
	if menu == null:
		return
	menu.visible = enabled
	if enabled:
		_place_lighting_options()

func reset_layout() -> void:
	_layout = DEFAULT_POSITIONS.duplicate(true)
	_apply_layout()
	_save_layout()

func _collect_buttons() -> void:
	for child in get_children():
		if not (child is SceneActionButton):
			continue
		var button := child as SceneActionButton
		var key := String(button.action_id)
		_buttons[key] = button
		button.activated.connect(_on_button_activated)
		button.position_committed.connect(_on_button_position_committed)
		button.drag_moved.connect(_on_button_drag_moved)

func _on_button_activated(action_id: StringName) -> void:
	action_requested.emit(action_id)

func _on_button_position_committed(action_id: StringName, normalized_position: Vector2) -> void:
	_layout[String(action_id)] = normalized_position
	_save_layout()
	_place_lighting_options()

func _on_button_drag_moved(_action_id: StringName) -> void:
	_place_lighting_options()

func _on_resized() -> void:
	_apply_layout()

func _apply_layout() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	for key in _buttons:
		var button := _buttons[key] as SceneActionButton
		var point: Vector2 = _layout.get(key, DEFAULT_POSITIONS.get(key, Vector2.ZERO))
		button.apply_normalized_position(point)
	_place_lighting_options()

func _place_lighting_options() -> void:
	var menu := get_node_or_null("LightingOptions") as Control
	var lighting := _buttons.get("lighting") as SceneActionButton
	if menu == null or lighting == null:
		return
	var gap := 8.0
	var target := lighting.position + Vector2(lighting.size.x + gap, 0.0)
	if target.x + menu.size.x > size.x:
		target.x = lighting.position.x - menu.size.x - gap
	if target.y + menu.size.y > size.y:
		target.y = maxf(0.0, size.y - menu.size.y)
	menu.position = Vector2(maxf(0.0, target.x), maxf(0.0, target.y))

func _load_layout() -> Dictionary:
	var result := DEFAULT_POSITIONS.duplicate(true)
	if not FileAccess.file_exists(FILE_PATH):
		return result
	var file := FileAccess.open(FILE_PATH, FileAccess.READ)
	if file == null:
		return result
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return result
	for key in DEFAULT_POSITIONS:
		var value = parsed.get(key)
		if value is Array and value.size() >= 2:
			result[key] = Vector2(
				clampf(float(value[0]), 0.0, 1.0),
				clampf(float(value[1]), 0.0, 1.0)
			)
	return result

func _save_layout() -> void:
	var payload := {}
	for key in DEFAULT_POSITIONS:
		var point: Vector2 = _layout.get(key, DEFAULT_POSITIONS[key])
		payload[key] = [point.x, point.y]
	var file := FileAccess.open(FILE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(payload))
