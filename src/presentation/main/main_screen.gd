extends Control

@onready var money_label: Label = %MoneyLabel
@onready var plant_name_label: Label = %PlantNameLabel
@onready var status_label: Label = %StatusLabel
@onready var event_label: Label = %EventLabel
@onready var window_view: WindowView = %WindowView
@onready var plant_view: PlantView = %PlantView
@onready var progression_panel: ProgressionPanel = %ProgressionPanel
@onready var pot_selector: PotSelector = %PotSelector
@onready var scene_controls: SceneControlsOverlay = %SceneControls
@onready var offer_label: Label = scene_controls.get_node("OffersPanel/OffersLayout/OfferLabel")
@onready var offer_one: Button = scene_controls.get_node("OffersPanel/OffersLayout/OfferOne")
@onready var offer_two: Button = scene_controls.get_node("OffersPanel/OffersLayout/OfferTwo")
@onready var offer_three: Button = scene_controls.get_node("OffersPanel/OffersLayout/OfferThree")
@onready var skip_offer: Button = scene_controls.get_node("OffersPanel/OffersLayout/SkipOffer")
@onready var inventory_slot_one: Button = scene_controls.get_node("InventoryHud/InventoryHudLayout/Slots/InventorySlotOne")
@onready var inventory_slot_two: Button = scene_controls.get_node("InventoryHud/InventoryHudLayout/Slots/InventorySlotTwo")
@onready var inventory_slot_three: Button = scene_controls.get_node("InventoryHud/InventoryHudLayout/Slots/InventorySlotThree")
@onready var inventory_details: PanelContainer = scene_controls.get_node("InventoryDetails")
@onready var inventory_panel: InventoryPanel = scene_controls.get_node("InventoryDetails/InventoryDetailsLayout/InventoryScroll/InventoryPanel")
@onready var shop_container: PanelContainer = scene_controls.get_node("ShopContainer")
@onready var shop_panel: ShopPanel = scene_controls.get_node("ShopContainer/ShopLayout/ShopPanel")
@onready var lighting_button: SceneActionButton = scene_controls.get_node("LightingButton")
@onready var prune_button: SceneActionButton = scene_controls.get_node("PruneButton")
@onready var harvest_button: SceneActionButton = scene_controls.get_node("HarvestButton")
@onready var sell_plant_button: SceneActionButton = scene_controls.get_node("SellPlantButton")
@onready var recycle_plant_button: SceneActionButton = scene_controls.get_node("RecyclePlantButton")
@onready var cancel_button: SceneActionButton = scene_controls.get_node("CancelButton")
@onready var sunny_button: Button = scene_controls.get_node("LightingOptions/Options/SunnyButton")
@onready var ventilation_button: Button = scene_controls.get_node("LightingOptions/Options/VentilationButton")
@onready var blinds_button: Button = scene_controls.get_node("LightingOptions/Options/BlindsButton")
@onready var curtains_button: Button = scene_controls.get_node("LightingOptions/Options/CurtainsButton")

var _interaction_mode: StringName = PlantView.MODE_NONE
var _pending_item_id := ""
var _pending_plant_kind: StringName = &""
var _lighting_submenu_visible := false

func _ready() -> void:
	GameApp.state_changed.connect(_refresh)
	GameApp.mutations_resolved.connect(_on_mutations_resolved)
	GameApp.fertilizer_offer_ready.connect(_on_offer_ready)
	plant_view.branch_selected.connect(_on_branch_selected)
	pot_selector.pot_selected.connect(_handle_pot_click)
	inventory_panel.fertilizer_use_requested.connect(_on_inventory_fertilizer)
	inventory_panel.cutting_plant_requested.connect(_on_cutting_plant_requested)
	inventory_panel.cutting_graft_requested.connect(_on_cutting_graft_requested)
	inventory_panel.seed_plant_requested.connect(_on_seed_plant_requested)
	inventory_panel.fruit_seed_requested.connect(_on_fruit_seed_requested)
	inventory_panel.item_sell_requested.connect(_on_item_sell_requested)
	inventory_panel.item_recycle_requested.connect(_on_item_recycle_requested)
	shop_panel.fertilizer_buy_requested.connect(_on_shop_fertilizer_requested)
	shop_panel.species_seed_buy_requested.connect(_on_shop_seed_requested)
	shop_panel.pot_buy_requested.connect(_on_shop_pot_requested)
	scene_controls.action_requested.connect(_on_scene_action_requested)
	sunny_button.pressed.connect(_on_environment_preset.bind(&"sunny"))
	ventilation_button.pressed.connect(_on_environment_preset.bind(&"ventilation"))
	blinds_button.pressed.connect(_on_environment_preset.bind(&"blinds"))
	curtains_button.pressed.connect(_on_environment_preset.bind(&"curtains"))
	offer_one.pressed.connect(_on_offer_one_pressed)
	offer_two.pressed.connect(_on_offer_two_pressed)
	offer_three.pressed.connect(_on_offer_three_pressed)
	skip_offer.pressed.connect(_on_skip_offer_pressed)
	inventory_slot_one.pressed.connect(_on_inventory_hud_pressed)
	inventory_slot_two.pressed.connect(_on_inventory_hud_pressed)
	inventory_slot_three.pressed.connect(_on_inventory_hud_pressed)
	scene_controls.get_node("InventoryDetails/InventoryDetailsLayout/InventoryHeader/CloseInventoryButton").pressed.connect(_on_close_inventory_pressed)
	scene_controls.get_node("ShopContainer/ShopLayout/ShopHeader/CloseShopButton").pressed.connect(_on_close_shop_pressed)
	_set_interaction_mode(PlantView.MODE_NONE)
	_refresh()

func _refresh() -> void:
	var pot := GameApp.active_pot()
	var plant := GameApp.active_plant()
	money_label.text = "$%d" % GameApp.state.money
	progression_panel.set_goal(ProgressionQuery.current_goal(GameApp.state, GameApp.registry))
	inventory_panel.set_inventory(GameApp.state.inventory, _item_prices())
	_refresh_inventory_hud(GameApp.state.inventory)
	pot_selector.set_state(GameApp.state, not String(_pending_plant_kind).is_empty())
	shop_panel.set_shop(GameApp.shop_catalog(), GameApp.species_shop_catalog(), GameApp.next_pot_price(), GameApp.state.money)
	_refresh_offer()
	_refresh_actions(pot, plant)
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
		status_label.text = "Choose a seed or cutting from inventory to plant here."
		return
	plant_name_label.text = plant.custom_name if not plant.custom_name.is_empty() else _pretty_id(String(plant.species_id))
	var lifecycle := PlantStatusQuery.build(plant, species, GameApp.rules)
	status_label.text = "%s · %s" % [_pretty_id(String(lifecycle.get("growth_stage", &"sprout"))), _pretty_id(String(lifecycle.get("condition", &"healthy")))]
	if _has_regrowth(plant): status_label.text += " · New branch forming"
	if not plant.alive: status_label.text += " · Final state"

func _refresh_inventory_hud(inventory: InventoryState) -> void:
	if inventory == null:
		inventory_slot_one.text = "FERT\n0"
		inventory_slot_two.text = "CUT\n0"
		inventory_slot_three.text = "GEN\n0"
		return
	var fertilizer_count := 0
	for count in inventory.fertilizers.values(): fertilizer_count += int(count)
	inventory_slot_one.text = "FERT\n%d" % fertilizer_count
	inventory_slot_two.text = "CUT\n%d" % inventory.cuttings.size()
	inventory_slot_three.text = "GEN\n%d" % (inventory.seeds.size() + inventory.fruits.size())
	inventory_slot_one.tooltip_text = "Fertilizers · click to open inventory"
	inventory_slot_two.tooltip_text = "Cuttings · click to open inventory"
	inventory_slot_three.tooltip_text = "Seeds + fruits · click to open inventory"

func _refresh_actions(pot: PotState, plant: PlantState) -> void:
	var living := plant != null and plant.alive
	lighting_button.disabled = pot == null
	lighting_button.text = "Lighting · %s" % _environment_name(pot) if pot != null else "Lighting"
	prune_button.disabled = not living
	harvest_button.disabled = not living or not _has_ready_fruit(plant)
	sell_plant_button.disabled = plant == null
	sell_plant_button.text = "Sell · $%d" % GameApp.active_plant_sale_value() if plant != null else "Sell plant"
	var compost_yield := GameApp.active_dead_plant_compost_yield()
	recycle_plant_button.visible = plant != null and not plant.alive
	recycle_plant_button.disabled = compost_yield <= 0
	recycle_plant_button.text = "Compost · ×%d" % compost_yield

func _refresh_offer() -> void:
	var ids := GameApp.current_offer_ids()
	var plant := GameApp.active_plant()
	var buttons: Array[Button] = [offer_one, offer_two, offer_three]
	for index in range(buttons.size()):
		var button := buttons[index]
		if index < ids.size():
			button.text = _pretty_id(String(ids[index]))
			button.disabled = plant == null or not plant.alive
		else:
			button.text = "?"
			button.disabled = true
	var price := GameApp.current_offer_skip_price()
	skip_offer.text = "Skip · $%d" % price if price > 0 else "Skip"
	skip_offer.disabled = price <= 0 or GameApp.state.money < price
	offer_label.text = "Fertilizers · %.0fs" % GameApp.state.fertilizer_offer.seconds_until_offer if ids.is_empty() else "Fertilizers · choose one"

func _set_interaction_mode(mode: StringName) -> void:
	_interaction_mode = mode
	plant_view.set_interaction_mode(mode)
	plant_view.mouse_filter = Control.MOUSE_FILTER_IGNORE if mode == PlantView.MODE_NONE else Control.MOUSE_FILTER_STOP
	prune_button.button_pressed = mode == PlantView.MODE_PRUNE
	harvest_button.button_pressed = mode == PlantView.MODE_HARVEST
	cancel_button.visible = mode != PlantView.MODE_NONE or not String(_pending_plant_kind).is_empty()

func _cancel_action() -> void:
	_pending_item_id = ""
	_pending_plant_kind = &""
	_set_interaction_mode(PlantView.MODE_NONE)
	pot_selector.invalidate()

func _on_scene_action_requested(action_id: StringName) -> void:
	match action_id:
		&"water": _on_water_pressed()
		&"spray": _on_spray_pressed()
		&"lighting": _on_light_pressed()
		&"prune": _on_prune_pressed()
		&"harvest": _on_harvest_pressed()
		&"sell_plant": _on_sell_plant_pressed()
		&"recycle_plant": _on_recycle_plant_pressed()
		&"cancel": _on_cancel_pressed()
		&"shop": _on_shop_pressed()

func _on_water_pressed() -> void: GameApp.water_active(false)
func _on_spray_pressed() -> void: GameApp.water_active(true)
func _on_light_pressed() -> void:
	_lighting_submenu_visible = not _lighting_submenu_visible
	scene_controls.set_lighting_options_visible(_lighting_submenu_visible)

func _on_environment_preset(preset: StringName) -> void:
	if GameApp.active_pot() == null: return
	var light_mode := PotState.LightMode.DIRECT
	var window_open := false
	match preset:
		&"ventilation": window_open = true
		&"blinds": light_mode = PotState.LightMode.DIFFUSED
		&"curtains": light_mode = PotState.LightMode.DARK
	GameApp.set_light_mode(light_mode)
	GameApp.set_window_open(window_open)
	_lighting_submenu_visible = false
	scene_controls.set_lighting_options_visible(false)
	event_label.text = "Environment: %s." % _pretty_id(String(preset))

func _on_prune_pressed() -> void:
	if GameApp.active_plant() == null:
		event_label.text = "There is nothing to prune."
		return
	_begin_branch_mode(PlantView.MODE_PRUNE, "Prune mode: click any existing branch.")
func _on_harvest_pressed() -> void:
	if not _has_ready_fruit(GameApp.active_plant()):
		event_label.text = "No ripe fruit yet."
		return
	_begin_branch_mode(PlantView.MODE_HARVEST, "Harvest mode: click a branch with ripe fruit.")
func _begin_branch_mode(mode: StringName, message: String) -> void:
	_pending_item_id = ""
	_pending_plant_kind = &""
	_set_interaction_mode(mode)
	event_label.text = message
func _on_cancel_pressed() -> void:
	_cancel_action()
	event_label.text = "Action cancelled."

func _on_branch_selected(slot: StringName) -> void:
	if _interaction_mode == PlantView.MODE_PRUNE:
		var cutting_id := GameApp.prune_active_branch(slot)
		event_label.text = "Cutting created from %s." % String(slot) if not cutting_id.is_empty() else "That branch cannot be cut."
	elif _interaction_mode == PlantView.MODE_GRAFT:
		var success := GameApp.graft_cutting(_pending_item_id, slot)
		event_label.text = "Graft attached to %s." % String(slot) if success else "Graft failed."
	elif _interaction_mode == PlantView.MODE_HARVEST:
		var fruit_id := GameApp.harvest_active_fruit(slot)
		event_label.text = "Fruit harvested." if not fruit_id.is_empty() else "That fruit is not ready."
	_cancel_action()

func _on_cutting_graft_requested(item_id: String) -> void:
	var plant := GameApp.active_plant()
	if plant == null or not plant.alive:
		event_label.text = "Select a pot with a living plant first."
		return
	_pending_item_id = item_id
	_pending_plant_kind = &""
	_set_interaction_mode(PlantView.MODE_GRAFT)
	event_label.text = "Graft mode: choose one glowing empty branch slot."
func _on_cutting_plant_requested(item_id: String) -> void: _begin_plant_target(&"cutting", item_id)
func _on_seed_plant_requested(item_id: String) -> void: _begin_plant_target(&"seed", item_id)
func _begin_plant_target(kind: StringName, item_id: String) -> void:
	_pending_item_id = item_id
	_pending_plant_kind = kind
	_set_interaction_mode(PlantView.MODE_NONE)
	pot_selector.invalidate()
	event_label.text = "Choose an empty pot."

func _handle_pot_click(pot_id: String) -> void:
	if String(_pending_plant_kind).is_empty():
		GameApp.switch_pot(pot_id)
		return
	var success := GameApp.plant_cutting(_pending_item_id, pot_id) if _pending_plant_kind == &"cutting" else GameApp.plant_seed(_pending_item_id, pot_id)
	if success:
		GameApp.switch_pot(pot_id)
		event_label.text = "Planted in %s." % pot_id
	else: event_label.text = "Cannot plant there."
	_cancel_action()

func _on_inventory_hud_pressed() -> void: scene_controls.set_inventory_details_visible(not inventory_details.visible)
func _on_close_inventory_pressed() -> void: scene_controls.set_inventory_details_visible(false)
func _on_inventory_fertilizer(fertilizer_id: StringName) -> void:
	if GameApp.use_inventory_fertilizer(fertilizer_id).is_empty(): event_label.text = "Fertilizer used. No visible mutation yet."
func _on_fruit_seed_requested(item_id: String) -> void:
	var seed_id := GameApp.create_seed_from_fruit(item_id)
	event_label.text = "Seed created." if not seed_id.is_empty() else "Could not create seed."
func _on_item_sell_requested(kind: StringName, item_id: String) -> void:
	var amount := GameApp.sell_inventory_item(kind, item_id)
	event_label.text = "%s sold for $%d." % [_pretty_id(String(kind)), amount] if amount > 0 else "Could not sell item."
func _on_item_recycle_requested(kind: StringName, item_id: String) -> void:
	var amount := GameApp.recycle_inventory_item(kind, item_id)
	event_label.text = "%s composted into ×%d Compost Mix." % [_pretty_id(String(kind)), amount] if amount > 0 else "Could not compost item."
func _on_sell_plant_pressed() -> void:
	var amount := GameApp.sell_active_plant()
	event_label.text = "Plant sold for $%d. Pot is free." % amount if amount > 0 else "Could not sell plant."
	_cancel_action()
func _on_recycle_plant_pressed() -> void:
	var amount := GameApp.recycle_active_dead_plant()
	event_label.text = "Remains composted into ×%d Compost Mix. Pot is free." % amount if amount > 0 else "Only dead plants can be composted."
	_cancel_action()
func _on_shop_pressed() -> void:
	scene_controls.set_shop_visible(not shop_container.visible)
	shop_panel.invalidate()
	_refresh()
func _on_close_shop_pressed() -> void: scene_controls.set_shop_visible(false)
func _on_save_layout_pressed() -> void:
	event_label.text = "HUD layout saved." if scene_controls.save_layout() else "Could not save HUD layout."
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
	if index >= ids.size(): return
	if GameApp.choose_fertilizer_offer(ids[index]).is_empty(): event_label.text = "Fertilizer absorbed. Nothing obvious happened yet."
func _on_skip_offer_pressed() -> void:
	event_label.text = "Offer skipped." if GameApp.skip_fertilizer_offer() else "Not enough money to skip."
func _on_mutations_resolved(events: Array[Dictionary]) -> void:
	if events.is_empty(): return
	var texts: Array[String] = []
	for event in events: texts.append("%s changed: %s" % [event["branch_id"], _pretty_id(String(event["trait_id"]))])
	event_label.text = " · ".join(texts)
func _on_offer_ready(_ids: Array[StringName]) -> void: event_label.text = "Three new fertilizers appeared."

func _item_prices() -> Dictionary:
	var result := {}
	for cutting in GameApp.state.inventory.cuttings: result[cutting.item_id] = GameApp.inventory_item_sale_value(&"cutting", cutting.item_id)
	for seed in GameApp.state.inventory.seeds: result[seed.item_id] = GameApp.inventory_item_sale_value(&"seed", seed.item_id)
	for fruit in GameApp.state.inventory.fruits: result[fruit.item_id] = GameApp.inventory_item_sale_value(&"fruit", fruit.item_id)
	return result
func _has_ready_fruit(plant: PlantState) -> bool:
	if plant == null or not plant.alive: return false
	for branch in plant.existing_branches():
		if branch.fruit_growth != null and branch.fruit_growth.is_ready(): return true
	return false
func _has_regrowth(plant: PlantState) -> bool:
	if plant == null or not plant.alive: return false
	for slot in BranchState.VALID_SLOTS:
		if plant.branch_at(slot) == null and plant.regrowth_progress_at(slot) > 0.0: return true
	return false
func _environment_name(pot: PotState) -> String:
	if pot.window_open: return "Ventilation"
	if pot.light_mode == PotState.LightMode.DARK: return "Curtains"
	if pot.light_mode == PotState.LightMode.DIFFUSED: return "Blinds"
	return "Sunny"
func _pretty_id(value: String) -> String: return value.replace("_", " ").capitalize()
