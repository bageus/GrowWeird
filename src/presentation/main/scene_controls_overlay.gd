class_name SceneControlsOverlay
extends Control

signal action_requested(action_id: StringName)

const FILE_PATH := "user://growweird_scene_buttons.json"
const LAYOUT_VERSION := 7
const DEFAULT_POSITIONS := {
	"water": Vector2(0.05, 0.56),
	"lighting": Vector2(0.06, 0.14),
	"prune": Vector2(0.05, 0.47),
	"sell_plant": Vector2(0.05, 0.64),
	"recycle_plant": Vector2(0.05, 0.72),
	"cancel": Vector2(0.45, 0.05),
	"shop": Vector2(0.84, 0.12),
	"tasks": Vector2(0.84, 0.22),
	"wallet": Vector2(0.72, 0.03),
	"pots": Vector2(0.02, 0.82),
	"fertilizers": Vector2(0.18, 0.82),
	"inventory": Vector2(0.77, 0.50),
}

var _controls: Dictionary = {}
var _layout: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_ui_atlases()
	_collect_controls()
	_layout = _load_layout()
	resized.connect(_on_resized)
	call_deferred("_apply_layout")

func _apply_ui_atlases() -> void:
	if get_node_or_null("WalletHud") == null:
		return
	var wallet := get_node("WalletHud") as PanelContainer
	wallet.add_theme_stylebox_override(&"panel", UiAtlas.panel_style(UiAtlas.HUD_BALANCE, Vector4.ZERO))
	UiAtlas.configure_balance_plus(get_node("WalletHud/Layers/ShopButton") as Button)
	var offers := get_node("OffersPanel") as PanelContainer
	offers.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	UiAtlas.configure_hud_slot(get_node("OffersPanel/Row/OfferOne") as Button)
	UiAtlas.configure_hud_slot(get_node("OffersPanel/Row/OfferTwo") as Button)
	UiAtlas.configure_hud_slot(get_node("OffersPanel/Row/OfferThree") as Button)
	var pots := get_node("PotSelector") as PanelContainer
	pots.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	(get_node("PotSelector/Layers/PotCircle") as TextureRect).texture = UiAtlas.background(1)
	(get_node("WaterOptions") as PanelContainer).add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	(get_node("LightingOptions") as PanelContainer).add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	UiAtlas.configure_button(get_node("WaterButton") as Button, 1, 1)
	UiAtlas.configure_button(get_node("LightingButton") as Button, 2, 3)
	UiAtlas.configure_button(get_node("PruneButton") as Button, 1, 2)
	UiAtlas.configure_button(get_node("SellPlantButton") as Button, 1, 3)
	UiAtlas.configure_button(get_node("RecyclePlantButton") as Button, 3, 2)
	UiAtlas.configure_button(get_node("ShopActionButton") as Button, 0, 0)
	UiAtlas.configure_button(get_node("TasksButton") as Button, 0, 1)
	UiAtlas.configure_button(get_node("OffersPanel/Row/RefreshOffer") as Button, 0, 3)
	UiAtlas.configure_button(get_node("OffersPanel/Row/SkipOffer") as Button, 0, 2)
	UiAtlas.configure_button(get_node("WaterOptions/Options/SprayButton") as Button, 1, 0)
	UiAtlas.configure_button(get_node("WaterOptions/Options/PourButton") as Button, 1, 1)
	UiAtlas.configure_button(get_node("LightingOptions/Options/CurtainsButton") as Button, 2, 0)
	UiAtlas.configure_button(get_node("LightingOptions/Options/BlindsButton") as Button, 2, 1)
	UiAtlas.configure_button(get_node("LightingOptions/Options/OpenWindowButton") as Button, 2, 2)
	UiAtlas.configure_button(get_node("LightingOptions/Options/NormalLightButton") as Button, 2, 3)
	UiAtlas.configure_button(get_node("PotSelector/Layers/PreviousPot") as Button, 3, 3, true)
	UiAtlas.configure_button(get_node("PotSelector/Layers/NextPot") as Button, 3, 3)

func set_water_options_visible(enabled: bool) -> void:
	var menu := get_node_or_null("WaterOptions") as Control
	if menu == null:
		return
	menu.visible = enabled
	if enabled:
		_place_popup(menu, _controls.get("water") as Control, 2.0)

func set_lighting_options_visible(enabled: bool) -> void:
	var menu := get_node_or_null("LightingOptions") as Control
	if menu == null:
		return
	menu.visible = enabled
	if enabled:
		_place_popup(menu, _controls.get("lighting") as Control, 2.0)

func set_shop_visible(enabled: bool) -> void:
	var panel := get_node_or_null("ShopContainer") as Control
	if panel == null:
		return
	panel.visible = enabled
	if enabled:
		_place_popup(panel, _controls.get("wallet") as Control)

func save_layout() -> bool:
	_capture_layout()
	var saved := _save_layout()
	if saved:
		_layout = _load_layout()
		_apply_layout()
	return saved

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
		var point: Vector2 = _layout.get(key, DEFAULT_POSITIONS.get(key, Vector2.ZERO))
		if control is SceneDraggablePanel:
			(control as SceneDraggablePanel).apply_normalized_position(point)
		elif control is SceneActionButton:
			(control as SceneActionButton).apply_normalized_position(point)
	_reposition_open_popups()

func _capture_layout() -> void:
	for key in _controls:
		var control := _controls[key] as Control
		if control is SceneDraggablePanel:
			_layout[key] = (control as SceneDraggablePanel).normalized_position()
		elif control is SceneActionButton:
			_layout[key] = (control as SceneActionButton).normalized_position()

func _reposition_open_popups() -> void:
	var water := get_node_or_null("WaterOptions") as Control
	if water != null and water.visible:
		_place_popup(water, _controls.get("water") as Control, 2.0)
	var lighting := get_node_or_null("LightingOptions") as Control
	if lighting != null and lighting.visible:
		_place_popup(lighting, _controls.get("lighting") as Control, 2.0)
	var shop := get_node_or_null("ShopContainer") as Control
	if shop != null and shop.visible:
		_place_popup(shop, _controls.get("wallet") as Control)
	var dialogs := get_node_or_null("InventoryItemDialogs") as InventoryItemDialogs
	if dialogs != null:
		dialogs.refresh_position()

func _place_popup(popup: Control, source: Control, gap := 8.0) -> void:
	if popup == null or source == null:
		return
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
