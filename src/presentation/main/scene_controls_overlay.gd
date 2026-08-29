class_name SceneControlsOverlay
extends Control

signal action_requested(action_id: StringName)

const FILE_PATH := "user://growweird_scene_buttons.json"
const LAYOUT_VERSION := 4
const DEFAULT_POSITIONS := {
	"water": Vector2(0.05, 0.56),
	"lighting": Vector2(0.06, 0.14),
	"prune": Vector2(0.05, 0.47),
	"sell_plant": Vector2(0.05, 0.64),
	"recycle_plant": Vector2(0.05, 0.72),
	"cancel": Vector2(0.42, 0.86),
	"wallet": Vector2(0.72, 0.03),
	"fertilizers": Vector2(0.16, 0.04),
	"inventory": Vector2(0.77, 0.50),
}

var _controls: Dictionary = {}
var _layout: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_collect_controls()
	_layout = _load_layout()
	resized.connect(_on_resized)
	call_deferred("_apply_layout")

func set_water_options_visible(enabled: bool) -> void:
	var menu := get_node_or_null("WaterOptions") as Control
	if menu == null:
		return
	menu.visible = enabled
	if enabled:
		_place_popup(menu, _controls.get("water") as Control)

func set_lighting_options_visible(enabled: bool) -> void:
	var menu := get_node_or_null("LightingOptions") as Control
	if menu == null:
		return
	menu.visible = enabled
	if enabled:
		_place_popup(menu, _controls.get("lighting") as Control)

func set_shop_visible(enabled: bool) -> void:
	var panel := get_node_or_null("ShopContainer") as Control
	if panel == null:
		return
	panel.visible = enabled
	if enabled:
		_place_popup(panel, _controls.get("wallet") as Control)

func save_layout() -> bool:
	_capture_layout()
	return _save_layout()

func reset_layout() -> void:
	_layout = DEFAULT_POSITIONS.duplicate(true)
	_apply_layout()

func _collect_controls() -> void:
	for child in get_children():
		if child is SceneActionButton:
			var button := child as SceneActionButton
			_register_control(String(button.action_id), button)
			button.activated.connect(_on_button_activated)
			button.position_committed.connect(_on_control_position_committed)
			button.drag_moved.connect(_on_control_drag_moved)
		elif child is SceneDraggablePanel:
			_register_panel(child as SceneDraggablePanel)
	var inventory := get_node_or_null("InventoryHud") as SceneDraggablePanel
	if inventory != null and not _controls.has("inventory"):
		_register_panel(inventory)

func _register_panel(panel: SceneDraggablePanel) -> void:
	if panel == null or panel.layout_id.is_empty():
		return
	var key := String(panel.layout_id)
	if _controls.has(key):
		return
	_register_control(key, panel)
	panel.position_committed.connect(_on_control_position_committed)
	panel.drag_moved.connect(_on_control_drag_moved)

func _register_control(key: String, control: Control) -> void:
	if key.is_empty():
		return
	_controls[key] = control

func _on_button_activated(action_id: StringName) -> void:
	action_requested.emit(action_id)

func _on_control_position_committed(layout_id: StringName, normalized_position: Vector2) -> void:
	_layout[String(layout_id)] = normalized_position
	_reposition_open_popups()

func _on_control_drag_moved(_layout_id: StringName) -> void:
	_reposition_open_popups()

func _on_resized() -> void:
	_apply_layout()

func _apply_layout() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	for key in _controls:
		var control := _controls[key] as Control
		if control is SceneDraggablePanel:
			var point: Vector2 = _layout.get(key, DEFAULT_POSITIONS.get(key, Vector2.ZERO))
			(control as SceneDraggablePanel).apply_normalized_position(point)
	_reposition_open_popups()

func _capture_layout() -> void:
	for key in _controls:
		_layout[key] = _controls[key].normalized_position()

func _reposition_open_popups() -> void:
	var water := get_node_or_null("WaterOptions") as Control
	if water != null and water.visible:
		_place_popup(water, _controls.get("water") as Control)
	var lighting := get_node_or_null("LightingOptions") as Control
	if lighting != null and lighting.visible:
		_place_popup(lighting, _controls.get("lighting") as Control)
	var shop := get_node_or_null("ShopContainer") as Control
	if shop != null and shop.visible:
		_place_popup(shop, _controls.get("wallet") as Control)
	var dialogs := get_node_or_null("InventoryItemDialogs") as InventoryItemDialogs
	if dialogs != null:
		dialogs.refresh_position()

func _place_popup(popup: Control, source: Control) -> void:
	if popup == null or source == null:
		return
	var gap := 8.0
	var target := source.position + Vector2(source.size.x + gap, 0.0)
	if target.x + popup.size.x > size.x:
		target.x = source.position.x - popup.size.x - gap
	if target.y + popup.size.y > size.y:
		target.y = maxf(0.0, size.y - popup.size.y)
	popup.position = Vector2(maxf(0.0, target.x), maxf(0.0, target.y))

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
	if int(parsed.get("layout_version", 0)) < LAYOUT_VERSION:
		return result
	for key in DEFAULT_POSITIONS:
		var value = parsed.get(key)
		if value is Array and value.size() >= 2:
			result[key] = Vector2(clampf(float(value[0]), 0.0, 1.0), clampf(float(value[1]), 0.0, 1.0))
	return result

func _save_layout() -> bool:
	var payload := {"layout_version": LAYOUT_VERSION}
	for key in DEFAULT_POSITIONS:
		var point: Vector2 = _layout.get(key, DEFAULT_POSITIONS[key])
		payload[key] = [point.x, point.y]
	var file := FileAccess.open(FILE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload))
	return true
