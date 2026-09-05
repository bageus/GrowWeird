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
	(get_node("WalletHud/Layers/ShopButton") as Button).pressed.connect(_toggle_wallet_topup)
	_layout = _load_layout()
	resized.connect(_on_resized)
	call_deferred("_apply_layout")

func _apply_ui_atlases() -> void:
	if get_node_or_null("WalletHud") == null:
		return
	var wallet := get_node("WalletHud") as PanelContainer
	wallet.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	var balance_art := get_node("WalletHud/Layers/BalanceArt") as TextureRect
	balance_art.texture = UiAtlas.HUD_BALANCE
	UiAtlas.configure_balance_plus(get_node("WalletHud/Layers/ShopButton") as Button, balance_art)
	var offers := get_node("OffersPanel") as PanelContainer
	offers.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	UiAtlas.configure_hud_slot(get_node("OffersPanel/Row/OfferOne") as Button)
	UiAtlas.configure_hud_slot(get_node("OffersPanel/Row/OfferTwo") as Button)
	UiAtlas.configure_hud_slot(get_node("OffersPanel/Row/OfferThree") as Button)
	var pots := get_node("PotSelector") as PanelContainer
	pots.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	var pot_art := get_node("PotSelector/Layers/PotCircle") as TextureRect
	pot_art.texture = UiAtlas.HUD_POT
	var pot_hover := get_node("PotSelector/Layers/PotHover") as TextureRect
	(get_node("WaterOptions") as PanelContainer).add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	(get_node("LightingOptions") as PanelContainer).add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	UiAtlas.configure_button(get_node("WaterButton") as Button, 3, 1)
	UiAtlas.configure_button(get_node("LightingButton") as Button, 4, 3)
	UiAtlas.configure_button(get_node("PruneButton") as Button, 3, 2)
	UiAtlas.configure_button(get_node("SellPlantButton") as Button, 3, 3)
	UiAtlas.configure_button(get_node("ShopActionButton") as Button, 2, 0)
	UiAtlas.configure_button(get_node("TasksButton") as Button, 2, 1)
	UiAtlas.configure_button(get_node("OffersPanel/Row/RefreshOffer") as Button, 2, 3)
	UiAtlas.configure_button(get_node("OffersPanel/Row/SkipOffer") as Button, 2, 2)
	UiAtlas.configure_button(get_node("WaterOptions/Options/SprayButton") as Button, 3, 0)
	UiAtlas.configure_button(get_node("WaterOptions/Options/PourButton") as Button, 3, 1)
	UiAtlas.configure_button(get_node("LightingOptions/Options/CurtainsButton") as Button, 4, 0)
	UiAtlas.configure_button(get_node("LightingOptions/Options/BlindsButton") as Button, 4, 1)
	UiAtlas.configure_button(get_node("LightingOptions/Options/OpenWindowButton") as Button, 4, 2)
	UiAtlas.configure_button(get_node("LightingOptions/Options/NormalLightButton") as Button, 4, 3)
	_configure_pot_arrow(get_node("PotSelector/Layers/PreviousPot") as Button, pot_hover, true)
	_configure_pot_arrow(get_node("PotSelector/Layers/NextPot") as Button, pot_hover, false)

func _configure_pot_arrow(button: Button, hover_art: TextureRect, left: bool) -> void:
	button.text = ""
	button.icon = null
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.mouse_entered.connect(func() -> void:
		hover_art.texture = UiAtlas.HUD_POT_HOVER_LEFT if left else UiAtlas.HUD_POT_HOVER_RIGHT
	)
	button.mouse_exited.connect(func() -> void: hover_art.texture = null)

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

func set_offer_cooldown(seconds: float) -> void:
	var overlay := get_node("OffersPanel/CooldownCenter/CooldownOverlay") as Control
	overlay.visible = seconds > 0.0
	var total := maxi(0, int(ceil(seconds)))
	var minutes := floori(float(total) / 60.0)
	(get_node("OffersPanel/CooldownCenter/CooldownOverlay/CooldownLabel") as Label).text = "Next fertilizers %02d:%02d" % [minutes, total % 60]

func set_shop_visible(enabled: bool) -> void:
	var panel := get_node_or_null("ShopContainer") as Control
	if panel == null:
		return
	panel.visible = enabled
	if enabled:
		set_wallet_topup_visible(false)

func set_wallet_topup_visible(enabled: bool) -> void:
	var panel := get_node_or_null("WalletTopupPanel") as WalletTopupPanel
	if panel == null:
		return
	if enabled: panel.open()
	else: panel.close()

func _toggle_wallet_topup() -> void:
	var panel := get_node_or_null("WalletTopupPanel") as WalletTopupPanel
	if panel != null:
		var opening := not panel.visible
		if opening:
			set_shop_visible(false)
		set_wallet_topup_visible(opening)

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
	panel.scale_committed.connect(_on_panel_scale_committed)

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

func _on_panel_scale_committed(layout_id: StringName, scale_factor: float) -> void:
	_layout["%s_scale" % String(layout_id)] = scale_factor
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
			var panel := control as SceneDraggablePanel
			panel.apply_scale_factor(float(_layout.get("%s_scale" % key, 1.0)))
			panel.apply_normalized_position(point)
		elif control is SceneActionButton:
			(control as SceneActionButton).apply_normalized_position(point)
	_reposition_open_popups()

func _capture_layout() -> void:
	for key in _controls:
		var control := _controls[key] as Control
		if control is SceneDraggablePanel:
			var panel := control as SceneDraggablePanel
			_layout[key] = panel.normalized_position()
			_layout["%s_scale" % key] = panel.scale_factor
		elif control is SceneActionButton:
			_layout[key] = (control as SceneActionButton).normalized_position()

func _reposition_open_popups() -> void:
	var water := get_node_or_null("WaterOptions") as Control
	if water != null and water.visible:
		_place_popup(water, _controls.get("water") as Control, 2.0)
	var lighting := get_node_or_null("LightingOptions") as Control
	if lighting != null and lighting.visible:
		_place_popup(lighting, _controls.get("lighting") as Control, 2.0)
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
		var saved_scale = parsed.get("%s_scale" % key)
		if saved_scale is float or saved_scale is int:
			result["%s_scale" % key] = float(saved_scale)
	return result

func _save_layout() -> bool:
	var payload := {"layout_version": LAYOUT_VERSION}
	for key in DEFAULT_POSITIONS:
		var point: Vector2 = _layout.get(key, DEFAULT_POSITIONS[key])
		payload[key] = [point.x, point.y]
		payload["%s_scale" % key] = float(_layout.get("%s_scale" % key, 1.0))
	var file := FileAccess.open(FILE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload))
	return true
