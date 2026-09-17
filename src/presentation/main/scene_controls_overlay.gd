class_name SceneControlsOverlay
extends Control
signal action_requested(action_id: StringName)
const FILE_PATH := "user://growweird_scene_buttons.json"
const LAYOUT_VERSION := 9
const DEFAULT_POSITIONS := {
	"water": Vector2(0.05, 0.56), "lighting": Vector2(0.06, 0.14), "prune": Vector2(0.05, 0.47), "sell_plant": Vector2(0.05, 0.64),
	"shop": Vector2(0.84, 0.12), "tasks": Vector2(0.84, 0.22), "wallet": Vector2(0.72, 0.03), "energy": Vector2(0.59, 0.03),
	"pots": Vector2(0.50, 0.80), "fertilizers": Vector2(0.18, 0.82), "inventory": Vector2(0.77, 0.50),
}
var _controls: Dictionary = {}
var _layout: Dictionary = {}
var _balance_hint: Label
var _hint_tween: Tween
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE; _apply_ui_atlases(); _collect_controls(); (get_node("WalletHud/Layers/ShopButton") as Button).pressed.connect(_toggle_wallet_topup); (get_node("EnergyHud/Layers/AddButton") as Button).pressed.connect(_toggle_energy_topup); _layout = _load_layout(); resized.connect(_on_resized); call_deferred("_apply_layout")
func _apply_ui_atlases() -> void:
	if get_node_or_null("WalletHud") == null: return
	UiAtlas.configure_warm_timer_hud(get_node("EnergyHud/Layers/Next") as PanelContainer, get_node("EnergyHud/Layers/Next/Timer") as Label)
	UiAtlas.configure_warm_timer_hud(get_node("OffersPanel/CooldownCenter/CooldownOverlay") as PanelContainer, get_node("OffersPanel/CooldownCenter/CooldownOverlay/CooldownLabel") as Label)
	var offers := get_node("OffersPanel") as PanelContainer; offers.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	for name in ["OfferOne", "OfferTwo", "OfferThree"]: UiAtlas.configure_hud_slot(get_node("OffersPanel/Row/" + name) as Button)
	var pots := get_node("PotSelector") as PanelContainer; pots.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new()); _configure_pot_circle(get_node("PotSelector/Layers/PotCircle") as Panel)
	var pot_hover := get_node("PotSelector/Layers/PotHover") as TextureRect
	(get_node("WaterOptions") as PanelContainer).add_theme_stylebox_override(&"panel", StyleBoxEmpty.new()); (get_node("LightingOptions") as PanelContainer).add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	UiAtlas.configure_button(get_node("WaterButton") as Button, 3, 1); UiAtlas.configure_button(get_node("LightingButton") as Button, 4, 3); UiAtlas.configure_button(get_node("PruneButton") as Button, 3, 2); UiAtlas.configure_button(get_node("SellPlantButton") as Button, 3, 3); UiAtlas.configure_button(get_node("ShopActionButton") as Button, 2, 0); UiAtlas.configure_button(get_node("TasksButton") as Button, 2, 1); UiAtlas.configure_button(get_node("OffersPanel/Row/RefreshOffer") as Button, 2, 3); UiAtlas.configure_button(get_node("OffersPanel/Row/SkipOffer") as Button, 2, 2); CommerceUiStyle.transaction_action(get_node("OffersPanel/Row/AdOffer") as Button, &"ad")
	UiAtlas.configure_button(get_node("WaterOptions/Options/SprayButton") as Button, 3, 0); UiAtlas.configure_button(get_node("WaterOptions/Options/PourButton") as Button, 3, 1); UiAtlas.configure_button(get_node("LightingOptions/Options/CurtainsButton") as Button, 4, 0); UiAtlas.configure_button(get_node("LightingOptions/Options/BlindsButton") as Button, 4, 1); UiAtlas.configure_button(get_node("LightingOptions/Options/OpenWindowButton") as Button, 4, 2); UiAtlas.configure_button(get_node("LightingOptions/Options/NormalLightButton") as Button, 4, 3)
	_configure_pot_arrow(get_node("PotSelector/Layers/PreviousPot") as Button, pot_hover, true); _configure_pot_arrow(get_node("PotSelector/Layers/NextPot") as Button, pot_hover, false)
func _configure_pot_circle(circle: Panel) -> void:
	var outer := StyleBoxFlat.new(); outer.bg_color = Color("ffd489"); outer.border_color = Color("bd641b"); outer.set_border_width_all(3); outer.set_corner_radius_all(52); outer.shadow_color = Color(0.28, 0.09, 0.01, 0.45); outer.shadow_size = 4; outer.shadow_offset = Vector2(0.0, 3.0); circle.add_theme_stylebox_override(&"panel", outer)
func _configure_pot_arrow(button: Button, hover_art: TextureRect, left: bool) -> void:
	hover_art.texture = null; button.text = "‹" if left else "›"; button.icon = null; button.focus_mode = Control.FOCUS_NONE; button.mouse_filter = Control.MOUSE_FILTER_STOP; button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND; button.move_to_front(); button.add_theme_font_size_override(&"font_size", 34); button.add_theme_color_override(&"font_color", Color.WHITE); button.add_theme_color_override(&"font_outline_color", Color("7b2f09")); button.add_theme_constant_override(&"outline_size", 2)
	for state in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		var style := StyleBoxFlat.new(); style.bg_color = Color("ed8b25"); style.border_color = Color(0.32, 0.10, 0.015, 0.50); style.set_border_width_all(1); style.set_corner_radius_all(20); button.add_theme_stylebox_override(state, style)
func set_prune_cancel(enabled: bool) -> void: _set_context_cancel_state(_controls.get("prune") as Button, enabled)
func set_water_options_visible(enabled: bool) -> void:
	var menu := get_node_or_null("WaterOptions") as Control; if menu == null: return
	menu.visible = enabled; _set_context_cancel_state(_controls.get("water") as Button, enabled); if enabled: _place_popup(menu, _controls.get("water") as Control, 2.0)
func set_lighting_options_visible(enabled: bool) -> void:
	var menu := get_node_or_null("LightingOptions") as Control; if menu == null: return
	menu.visible = enabled; _set_context_cancel_state(_controls.get("lighting") as Button, enabled); if enabled: _place_popup(menu, _controls.get("lighting") as Control, 2.0)
func _set_context_cancel_state(button: Button, active: bool) -> void:
	if button == null: return
	button.self_modulate = Color.WHITE; var face := button.get_node_or_null("ContextCancelButton") as Panel
	if not active: if face != null: face.free(); return
	if face != null: return
	face = Panel.new(); face.name = "ContextCancelButton"; face.mouse_filter = Control.MOUSE_FILTER_IGNORE; button.add_child(face); face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); face.offset_left = 4.0; face.offset_top = 13.0; face.offset_right = -36.0; face.offset_bottom = -17.0
	var style := StyleBoxFlat.new(); style.bg_color = Color("df4a2f"); style.border_color = Color("8d210f"); style.set_border_width_all(3); style.set_corner_radius_all(22); face.add_theme_stylebox_override(&"panel", style)
	var caption := Label.new(); caption.name = "ContextCancelCaption"; caption.text = "CANCEL"; caption.mouse_filter = Control.MOUSE_FILTER_IGNORE; face.add_child(caption); caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
func should_cancel_context_click(point: Vector2, dialogs: InventoryItemDialogs) -> bool:
	var water := get_node("WaterOptions") as Control; var lighting := get_node("LightingOptions") as Control
	if water.visible and not water.get_global_rect().has_point(point): return true
	if lighting.visible and not lighting.get_global_rect().has_point(point): return true
	return dialogs.needs_scene_cancel() and not dialogs.cancelable_menu_contains_global_point(point)
func set_offer_cooldown(seconds: float) -> void:
	var overlay := get_node("OffersPanel/CooldownCenter/CooldownOverlay") as Control; overlay.visible = seconds > 0.0; var total := maxi(0, int(ceil(seconds))); (get_node("OffersPanel/CooldownCenter/CooldownOverlay/CooldownLabel") as Label).text = "Next fertilizers %02d:%02d" % [floori(float(total) / 60.0), total % 60]
func set_energy(state: GameState) -> void:
	var capacity := EnergyService.capacity(state); var seconds := EnergyService.seconds_to_next(state); (get_node("EnergyHud/Layers/Value") as Label).text = "%d / %d" % [state.energy, capacity]; var next := get_node("EnergyHud/Layers/Next") as Control; next.visible = state.energy < capacity; (get_node("EnergyHud/Layers/Next/Timer") as Label).text = "%02d:%02d" % [floori(float(seconds) / 60.0), seconds % 60]
func set_offer_energy_actions(has_offer: bool, _energy: int) -> void:
	for button_name in ["RefreshOffer", "SkipOffer"]:
		var button := get_node("OffersPanel/Row/" + button_name) as Button; button.text = ""; button.tooltip_text = "%s · %d energy" % [button_name.trim_suffix("Offer"), EnergyService.OFFER_COST]; button.disabled = not has_offer
func set_shop_visible(enabled: bool) -> void:
	var panel := get_node_or_null("ShopContainer") as Control; if panel != null: panel.visible = enabled
func set_wallet_topup_visible(enabled: bool) -> void:
	var panel := get_node_or_null("WalletTopupPanel") as WalletTopupPanel; if panel != null: if enabled: panel.open(); else: panel.close()
func _toggle_wallet_topup() -> void: var panel := get_node_or_null("WalletTopupPanel") as WalletTopupPanel; if panel != null: set_wallet_topup_visible(not panel.visible)
func set_energy_topup_visible(enabled: bool) -> void:
	var panel := get_node_or_null("EnergyTopupPanel") as EnergyTopupPanel; if panel != null: if enabled: panel.open(); else: panel.close()
func _toggle_energy_topup() -> void: var panel := get_node_or_null("EnergyTopupPanel") as EnergyTopupPanel; if panel != null: set_energy_topup_visible(not panel.visible)
func save_layout() -> bool: _capture_layout(); var saved := _save_layout(); if saved: _layout = _load_layout(); _apply_layout(); return saved
func reset_layout() -> void: _layout = DEFAULT_POSITIONS.duplicate(true); _apply_layout()
func _collect_controls() -> void:
	for child in get_children():
		if child is SceneActionButton: var button := child as SceneActionButton; _register_control(String(button.action_id), button); button.activated.connect(_on_button_activated); button.position_committed.connect(_on_control_position_committed); button.drag_moved.connect(_on_control_drag_moved)
		elif child is SceneDraggablePanel: _register_panel(child as SceneDraggablePanel)
	var inventory := get_node_or_null("InventoryHud") as SceneDraggablePanel; if inventory != null and not _controls.has("inventory"): _register_panel(inventory)
func _register_panel(panel: SceneDraggablePanel) -> void:
	if panel == null or panel.layout_id.is_empty(): return
	var key := String(panel.layout_id); if _controls.has(key): return
	_register_control(key, panel); panel.position_committed.connect(_on_control_position_committed); panel.drag_moved.connect(_on_control_drag_moved); panel.scale_committed.connect(_on_panel_scale_committed)
func _register_control(key: String, control: Control) -> void: if not key.is_empty(): _controls[key] = control
func _on_button_activated(action_id: StringName) -> void: action_requested.emit(action_id)
func _on_control_position_committed(layout_id: StringName, normalized_position: Vector2) -> void: _layout[String(layout_id)] = normalized_position; _reposition_open_popups()
func _on_control_drag_moved(_layout_id: StringName) -> void: _reposition_open_popups()
func _on_panel_scale_committed(layout_id: StringName, scale_factor: float) -> void: _layout["%s_scale" % String(layout_id)] = scale_factor; _reposition_open_popups()
func _on_resized() -> void: _apply_layout()
func _apply_layout() -> void:
	if size.x <= 1.0 or size.y <= 1.0: return
	for key in _controls:
		var control := _controls[key] as Control; var normalized: Vector2 = _layout.get(key, DEFAULT_POSITIONS.get(key, Vector2.ZERO)); control.position = Vector2(normalized.x * size.x, normalized.y * size.y)
		if control is SceneDraggablePanel: (control as SceneDraggablePanel).apply_scale_factor(float(_layout.get("%s_scale" % key, 1.0)))
	_reposition_open_popups()
func _capture_layout() -> void:
	for key in _controls: var control := _controls[key] as Control; _layout[key] = Vector2(control.position.x / maxf(size.x, 1.0), control.position.y / maxf(size.y, 1.0))
func _save_layout() -> bool:
	var file := FileAccess.open(FILE_PATH, FileAccess.WRITE); if file == null: return false
	file.store_string(JSON.stringify({"version": LAYOUT_VERSION, "positions": _layout})); return true
func _load_layout() -> Dictionary:
	if not FileAccess.file_exists(FILE_PATH): return DEFAULT_POSITIONS.duplicate(true)
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(FILE_PATH)); if not parsed is Dictionary: return DEFAULT_POSITIONS.duplicate(true)
	var result := DEFAULT_POSITIONS.duplicate(true); for key in parsed.get("positions", {}): result[String(key)] = parsed["positions"][key]; return result
func _place_popup(menu: Control, anchor: Control, gap: float) -> void: menu.position = anchor.position + Vector2(anchor.size.x + gap, 0.0)
func _reposition_open_popups() -> void:
	if (get_node("WaterOptions") as Control).visible: _place_popup(get_node("WaterOptions") as Control, _controls.get("water") as Control, 2.0)
	if (get_node("LightingOptions") as Control).visible: _place_popup(get_node("LightingOptions") as Control, _controls.get("lighting") as Control, 2.0)
