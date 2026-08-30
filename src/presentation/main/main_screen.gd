extends Control
@onready var plant_name_label: Label = %PlantNameLabel
@onready var status_label: Label = %StatusLabel
@onready var event_label: Label = %EventLabel
@onready var window_view: WindowView = %WindowView
@onready var plant_view: PlantView = %PlantView
@onready var pot_visual: PotVisual = %PotVisual
@onready var tree_growth_preview: TreeGrowthPreview = %TreeGrowthPreview
@onready var progression_panel: ProgressionPanel = %ProgressionPanel
@onready var scene_controls: SceneControlsOverlay = %SceneControls
@onready var pot_selector: PotSelector = scene_controls.get_node("PotSelector")
@onready var money_label: Label = scene_controls.get_node("WalletHud/Layers/MoneyLabel")
@onready var shop_button: Button = scene_controls.get_node("WalletHud/Layers/ShopButton")
@onready var offer_one: Button = scene_controls.get_node("OffersPanel/Row/OfferOne")
@onready var offer_two: Button = scene_controls.get_node("OffersPanel/Row/OfferTwo")
@onready var offer_three: Button = scene_controls.get_node("OffersPanel/Row/OfferThree")
@onready var refresh_offer: Button = scene_controls.get_node("OffersPanel/Row/RefreshOffer")
@onready var skip_offer: Button = scene_controls.get_node("OffersPanel/Row/SkipOffer")
@onready var inventory_hud: InventoryHud = scene_controls.get_node("InventoryHud")
@onready var inventory_dialogs: InventoryItemDialogs = scene_controls.get_node("InventoryItemDialogs")
@onready var shop_container: PanelContainer = scene_controls.get_node("ShopContainer")
@onready var shop_panel: ShopPanel = scene_controls.get_node("ShopContainer/ShopLayout/ShopPanel")
@onready var lighting_button: SceneActionButton = scene_controls.get_node("LightingButton")
@onready var prune_button: SceneActionButton = scene_controls.get_node("PruneButton")
@onready var sell_plant_button: SceneActionButton = scene_controls.get_node("SellPlantButton")
@onready var recycle_plant_button: SceneActionButton = scene_controls.get_node("RecyclePlantButton")
@onready var cancel_button: SceneActionButton = scene_controls.get_node("CancelButton")
@onready var spray_button: Button = scene_controls.get_node("WaterOptions/Options/SprayButton")
@onready var pour_button: Button = scene_controls.get_node("WaterOptions/Options/PourButton")
@onready var curtains_button: Button = scene_controls.get_node("LightingOptions/Options/CurtainsButton")
@onready var open_window_button: Button = scene_controls.get_node("LightingOptions/Options/OpenWindowButton")
@onready var blinds_button: Button = scene_controls.get_node("LightingOptions/Options/BlindsButton")
@onready var normal_light_button: Button = scene_controls.get_node("LightingOptions/Options/NormalLightButton")
var _interaction_mode: StringName = PlantView.MODE_NONE
var _pending_item_id := ""
var _pending_plant_kind: StringName = &""
var _water_submenu_visible := false
var _lighting_submenu_visible := false
var _prune_cursor: Texture2D = null
func _ready() -> void:
	GameApp.state_changed.connect(_refresh)
	GameApp.mutations_resolved.connect(_on_mutations_resolved)
	GameApp.fertilizer_offer_ready.connect(_on_offer_ready)
	plant_view.branch_selected.connect(_on_branch_selected)
	tree_growth_preview.tree_branch_pruned.connect(_on_tree_branch_pruned)
	pot_selector.pot_selected.connect(_handle_pot_click)
	scene_controls.action_requested.connect(_on_scene_action_requested)
	inventory_hud.item_selected.connect(_on_inventory_item_selected)
	inventory_dialogs.use_requested.connect(_on_inventory_use_requested)
	inventory_dialogs.sell_requested.connect(_on_inventory_sell_requested)
	inventory_dialogs.recycle_requested.connect(_on_inventory_recycle_requested)
	inventory_dialogs.closed.connect(_set_cancel_visibility)
	shop_panel.fertilizer_buy_requested.connect(_on_shop_fertilizer_requested)
	shop_panel.species_seed_buy_requested.connect(_on_shop_seed_requested)
	shop_panel.pot_buy_requested.connect(_on_shop_pot_requested)
	shop_button.pressed.connect(_on_shop_pressed)
	spray_button.pressed.connect(_on_spray_pressed)
	pour_button.pressed.connect(_on_pour_pressed)
	curtains_button.pressed.connect(_on_environment_preset.bind(&"curtains"))
	open_window_button.pressed.connect(_on_environment_preset.bind(&"open_window"))
	blinds_button.pressed.connect(_on_environment_preset.bind(&"blinds"))
	normal_light_button.pressed.connect(_on_environment_preset.bind(&"normal_light"))
	offer_one.pressed.connect(_on_offer_one_pressed)
	offer_two.pressed.connect(_on_offer_two_pressed)
	offer_three.pressed.connect(_on_offer_three_pressed)
	refresh_offer.pressed.connect(_on_refresh_offer_pressed)
	skip_offer.pressed.connect(_on_skip_offer_pressed)
	for stage in range(14):
		var button := get_node("Shell/Layout/LeftSidebar/LeftScroll/LeftLayout/TreeGrowthControls/Layout/Stage%dButton" % (stage + 1)) as Button
		button.pressed.connect(_on_tree_stage_selected.bind(stage))
	scene_controls.get_node("ShopContainer/ShopLayout/ShopHeader/CloseShopButton").pressed.connect(_on_close_shop_pressed)
	_set_interaction_mode(PlantView.MODE_NONE)
	_refresh()
func _refresh() -> void:
	var pot := GameApp.active_pot()
	var plant := GameApp.active_plant()
	money_label.text = "%d" % GameApp.state.money
	progression_panel.set_goal(ProgressionQuery.current_goal(GameApp.state, GameApp.registry))
	inventory_hud.set_inventory(GameApp.state.inventory)
	pot_selector.set_state(GameApp.state, not String(_pending_plant_kind).is_empty())
	shop_panel.set_shop(GameApp.shop_catalog(), GameApp.species_shop_catalog(), GameApp.next_pot_price(), GameApp.state.money)
	_refresh_offer()
	_refresh_actions(pot, plant)
	if pot != null:
		pot_visual.set_pot_state(pot)
	tree_growth_preview.set_plant(plant)
	scene_controls.set_water_options_visible(_water_submenu_visible)
	scene_controls.set_lighting_options_visible(_lighting_submenu_visible)
	if pot == null:
		plant_name_label.text = "No pot selected"
		status_label.text = "Choose or buy a pot to start growing."
		plant_view.set_species_style(null)
		plant_view.set_plant(null)
		return
	window_view.set_environment(int(pot.light_mode), pot.window_open)
	var species := GameApp.active_species_definition()
	plant_view.set_species_style(species)
	plant_view.set_plant(plant)
	if plant == null:
		plant_name_label.text = "%s · empty" % pot.pot_id
		status_label.text = "Choose a seed or cutting to use in this pot."
		return
	plant_name_label.text = plant.custom_name if not plant.custom_name.is_empty() else _pretty_id(String(plant.species_id))
	var lifecycle := PlantStatusQuery.build(plant, species, GameApp.rules)
	status_label.text = "%s · %s" % [_pretty_id(String(lifecycle.get("growth_stage", &"sprout"))), _pretty_id(String(lifecycle.get("condition", &"healthy")))]
	if _has_regrowth(plant): status_label.text += " · New branch forming"
	if not plant.alive: status_label.text += " · Final state"
func _refresh_actions(pot: PotState, plant: PlantState) -> void:
	lighting_button.disabled = pot == null
	lighting_button.text = ""
	lighting_button.tooltip_text = "Lighting"
	prune_button.disabled = pot == null
	sell_plant_button.disabled = plant == null
	sell_plant_button.text = ""
	sell_plant_button.tooltip_text = "Sell · %d" % GameApp.active_plant_sale_value() if plant != null else "Sell plant"
	var compost_yield := GameApp.active_dead_plant_compost_yield()
	recycle_plant_button.visible = plant != null and not plant.alive
	recycle_plant_button.disabled = compost_yield <= 0
	recycle_plant_button.text = ""
	recycle_plant_button.tooltip_text = "Grind · ×%d" % compost_yield
func _refresh_offer() -> void:
	var ids := GameApp.current_offer_ids()
	var plant := GameApp.active_plant()
	var buttons: Array[Button] = [offer_one, offer_two, offer_three]
	for index in range(buttons.size()):
		var button := buttons[index]
		if index < ids.size():
			button.text = _pretty_id(String(ids[index]))
			button.icon = FertilizerOfferArt.texture_for(ids[index])
			button.expand_icon = true
			button.disabled = plant == null or not plant.alive
		else:
			button.text = ""
			button.icon = null
			button.disabled = true
	var price := GameApp.current_offer_skip_price()
	refresh_offer.text = ""
	refresh_offer.tooltip_text = "Refresh · %d" % price if price > 0 else "Refresh"
	refresh_offer.disabled = ids.is_empty() or price <= 0 or GameApp.state.money < price
	skip_offer.text = ""
	skip_offer.tooltip_text = "Skip · %d" % price if price > 0 else "Skip"
	skip_offer.disabled = ids.is_empty() or price <= 0 or GameApp.state.money < price
func _set_interaction_mode(mode: StringName) -> void:
	_interaction_mode = mode
	plant_view.set_interaction_mode(mode)
	tree_growth_preview.set_prune_mode(mode == PlantView.MODE_PRUNE)
	plant_view.mouse_filter = Control.MOUSE_FILTER_IGNORE if mode == PlantView.MODE_NONE or mode == PlantView.MODE_PRUNE else Control.MOUSE_FILTER_STOP
	prune_button.button_pressed = mode == PlantView.MODE_PRUNE
	cancel_button.visible = mode != PlantView.MODE_NONE or not String(_pending_plant_kind).is_empty() or _water_submenu_visible or _lighting_submenu_visible or shop_container.visible
	if mode == PlantView.MODE_PRUNE:
		if _prune_cursor == null:
			_prune_cursor = load("res://assets/ui/prune_cursor.svg") as Texture2D
		if _prune_cursor != null:
			Input.set_custom_mouse_cursor(_prune_cursor)
	else:
		Input.set_custom_mouse_cursor(null)
func _cancel_action() -> void:
	_pending_item_id = ""
	_pending_plant_kind = &""
	_set_interaction_mode(PlantView.MODE_NONE)
	pot_selector.invalidate()
func _on_scene_action_requested(action_id: StringName) -> void:
	match action_id:
		&"water": _on_water_pressed()
		&"lighting": _on_light_pressed()
		&"prune": _on_prune_pressed()
		&"sell_plant": _on_sell_plant_pressed()
		&"recycle_plant": _on_recycle_plant_pressed()
		&"cancel": _on_cancel_pressed()
		&"shop": _on_shop_pressed()
		&"tasks": progression_panel.visible = not progression_panel.visible
func _on_water_pressed() -> void:
	_water_submenu_visible = not _water_submenu_visible
	_lighting_submenu_visible = false
	_set_cancel_visibility()
	scene_controls.set_water_options_visible(_water_submenu_visible)
	scene_controls.set_lighting_options_visible(false)
func _on_spray_pressed() -> void:
	_water_submenu_visible = false
	scene_controls.set_water_options_visible(false)
	_set_cancel_visibility()
	event_label.text = "Sprayed plant." if GameApp.water_active(true) else "Nothing to water."
func _on_pour_pressed() -> void:
	_water_submenu_visible = false
	scene_controls.set_water_options_visible(false)
	_set_cancel_visibility()
	event_label.text = "Water poured." if GameApp.water_active(false) else "Nothing to water."
	_refresh()
func _on_light_pressed() -> void:
	_lighting_submenu_visible = not _lighting_submenu_visible
	_water_submenu_visible = false
	_set_cancel_visibility()
	scene_controls.set_lighting_options_visible(_lighting_submenu_visible)
	scene_controls.set_water_options_visible(false)
func _on_environment_preset(preset: StringName) -> void:
	if GameApp.active_pot() == null:
		return
	var light_mode := PotState.LightMode.DIRECT
	var window_open := false
	match preset:
		&"curtains": light_mode = PotState.LightMode.DARK
		&"open_window": window_open = true
		&"blinds": light_mode = PotState.LightMode.DIFFUSED
		&"normal_light": light_mode = PotState.LightMode.DIRECT
	GameApp.set_light_mode(light_mode)
	GameApp.set_window_open(window_open)
	_lighting_submenu_visible = false
	_set_cancel_visibility()
	scene_controls.set_lighting_options_visible(false)
	event_label.text = "Environment: %s." % _pretty_id(String(preset))
func _on_prune_pressed() -> void:
	if GameApp.active_plant() == null and not tree_growth_preview.has_prunable_branch():
		event_label.text = "There is nothing to prune."
		return
	_pending_item_id = ""
	_pending_plant_kind = &""
	_set_interaction_mode(PlantView.MODE_PRUNE)
	event_label.text = "Prune mode: click an existing branch."
func _on_cancel_pressed() -> void:
	inventory_dialogs.close_all(); _cancel_action()
	_water_submenu_visible = false
	_lighting_submenu_visible = false
	scene_controls.set_water_options_visible(false)
	scene_controls.set_lighting_options_visible(false)
	scene_controls.set_shop_visible(false)
	_set_cancel_visibility()
	event_label.text = "Action cancelled."
func _on_tree_branch_pruned(side: StringName) -> void:
	var cutting_id := GameApp.prune_active_branch(side)
	event_label.text = "Plant branch added to inventory." if not cutting_id.is_empty() else "That branch cannot be cut."
func _on_branch_selected(slot: StringName) -> void:
	if _interaction_mode == PlantView.MODE_PRUNE:
		var cutting_id := GameApp.prune_active_branch(slot)
		event_label.text = "Cutting created." if not cutting_id.is_empty() else "That branch cannot be cut."
	elif _interaction_mode == PlantView.MODE_GRAFT:
		var success := GameApp.graft_cutting(_pending_item_id, slot)
		event_label.text = "Cutting used on plant." if success else "Graft failed."
	_cancel_action()
func _on_inventory_item_selected(kind: StringName, item_id: String, count: int, title: String) -> void:
	var price := GameApp.inventory_item_sale_value(kind, item_id)
	var recycle_yield := GameApp.inventory_item_recycle_yield(kind)
	inventory_dialogs.show_for(inventory_hud, kind, item_id, count, title, price, recycle_yield); _set_cancel_visibility()
func _on_inventory_use_requested(kind: StringName, item_id: String) -> void:
	match kind:
		&"fertilizer":
			if GameApp.active_plant() == null or not GameApp.active_plant().alive:
				event_label.text = "Select a living plant first."
				return
			GameApp.use_inventory_fertilizer(StringName(item_id))
			event_label.text = "Fertilizer used on current plant."
		&"cutting":
			_on_cutting_graft_requested(item_id)
		&"seed":
			var pot := GameApp.active_pot()
			if pot == null or not pot.is_empty():
				event_label.text = "The current pot must be empty to use this seed."
				return
			event_label.text = "Seed planted." if GameApp.plant_seed(item_id, pot.pot_id) else "Could not use seed."
		&"fruit":
			var seed_id := GameApp.create_seed_from_fruit(item_id)
			event_label.text = "Fruit converted into a seed." if not seed_id.is_empty() else "Could not use fruit."
func _on_cutting_graft_requested(item_id: String) -> void:
	var plant := GameApp.active_plant()
	if plant == null or not plant.alive:
		event_label.text = "Select a living plant first."
		return
	_pending_item_id = item_id
	_pending_plant_kind = &""
	_set_interaction_mode(PlantView.MODE_GRAFT)
	event_label.text = "Use cutting: choose an empty branch slot."
func _on_inventory_sell_requested(kind: StringName, item_id: String, quantity: int) -> void:
	var amount := GameApp.sell_inventory_items(kind, item_id, quantity)
	event_label.text = "Sold for $%d." % amount if amount > 0 else "Could not sell item."
func _on_inventory_recycle_requested(kind: StringName, item_id: String, quantity: int) -> void:
	var total := 0
	for _index in range(maxi(1, quantity)):
		var amount := GameApp.recycle_inventory_item(kind, item_id)
		if amount <= 0:
			break
		total += amount
	event_label.text = "Ground into Compost Mix ×%d." % total if total > 0 else "Could not grind item."
func _handle_pot_click(pot_id: String) -> void:
	GameApp.switch_pot(pot_id)
func _on_sell_plant_pressed() -> void:
	var amount := GameApp.sell_active_plant()
	event_label.text = "Plant sold for $%d." % amount if amount > 0 else "Could not sell plant."
	_cancel_action()
func _on_recycle_plant_pressed() -> void:
	var amount := GameApp.recycle_active_dead_plant()
	event_label.text = "Remains ground into Compost Mix ×%d." % amount if amount > 0 else "Only dead plants can be composted."
	_cancel_action()
func _on_shop_pressed() -> void:
	scene_controls.set_shop_visible(not shop_container.visible)
	_set_cancel_visibility()
	shop_panel.invalidate()
	_refresh()
func _on_close_shop_pressed() -> void:
	scene_controls.set_shop_visible(false)
	_set_cancel_visibility()
func _set_cancel_visibility() -> void:
	cancel_button.visible = _interaction_mode != PlantView.MODE_NONE or not String(_pending_plant_kind).is_empty() or _water_submenu_visible or _lighting_submenu_visible or shop_container.visible or inventory_dialogs.is_open()
func _on_save_layout_pressed() -> void:
	event_label.text = "HUD layout saved." if scene_controls.save_layout() else "Could not save HUD layout."
func _on_save_assets_layout_pressed() -> void:
	pot_visual.save_asset_layout()
	tree_growth_preview.save_asset_layout()
	event_label.text = "Pot, soil, stand and tree asset layout saved."
func _on_reset_layout_pressed() -> void:
	scene_controls.reset_layout()
	event_label.text = "HUD layout reset. Press Save HUD layout to keep it."
func _on_shop_fertilizer_requested(id: StringName) -> void:
	var success := GameApp.buy_shop_fertilizer(id)
	event_label.text = "%s added to inventory." % _pretty_id(String(id)) if success else "Item is locked or unaffordable."
func _on_shop_seed_requested(species_id: StringName) -> void:
	var seed_id := GameApp.buy_shop_seed(species_id)
	event_label.text = "%s seed added to inventory." % _pretty_id(String(species_id)) if not seed_id.is_empty() else "Seed is locked or unaffordable."
func _on_shop_pot_requested() -> void:
	var pot_id := GameApp.buy_new_pot()
	event_label.text = "%s purchased." % pot_id if not pot_id.is_empty() else "Not enough money for a new pot."
	pot_selector.invalidate()
func _on_offer_one_pressed() -> void: _choose_offer(0)
func _on_offer_two_pressed() -> void: _choose_offer(1)
func _on_offer_three_pressed() -> void: _choose_offer(2)
func _choose_offer(index: int) -> void:
	var ids := GameApp.current_offer_ids()
	if index >= ids.size():
		return
	GameApp.choose_fertilizer_offer(ids[index])
func _on_refresh_offer_pressed() -> void:
	event_label.text = "Fertilizers refreshed." if GameApp.refresh_fertilizer_offer() else "Cannot refresh fertilizers."
func _on_skip_offer_pressed() -> void:
	event_label.text = "Fertilizers skipped." if GameApp.skip_fertilizer_offer() else "Cannot skip fertilizers."
func _on_mutations_resolved(events: Array[Dictionary]) -> void:
	if events.is_empty():
		return
	var texts: Array[String] = []
	for event in events:
		texts.append("%s changed: %s" % [event["branch_id"], _pretty_id(String(event["trait_id"]))])
	event_label.text = " · ".join(texts)
func _on_offer_ready(_ids: Array[StringName]) -> void:
	event_label.text = "Three new fertilizers appeared."
func _has_regrowth(plant: PlantState) -> bool:
	if plant == null or not plant.alive:
		return false
	for slot in BranchState.VALID_SLOTS:
		if plant.branch_at(slot) == null and plant.regrowth_progress_at(slot) > 0.0:
			return true
	return false
func _pretty_id(value: String) -> String: return value.replace("_", " ").capitalize()
func _on_tree_stage_selected(stage: int) -> void: tree_growth_preview.preview_stage_for_testing(stage); event_label.text = "Tree asset preview: stage %d. Game state unchanged." % (stage + 1)
