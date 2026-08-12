extends Control

@onready var money_label: Label = %MoneyLabel
@onready var plant_name_label: Label = %PlantNameLabel
@onready var status_label: Label = %StatusLabel
@onready var event_label: Label = %EventLabel
@onready var offer_label: Label = %OfferLabel
@onready var window_view: WindowView = %WindowView
@onready var soil_view: SoilView = %SoilView
@onready var plant_view: PlantView = %PlantView
@onready var plant_sense: PlantSenseView = %PlantSense
@onready var inventory_panel: InventoryPanel = %InventoryPanel
@onready var pot_selector: PotSelector = %PotSelector
@onready var shop_panel: ShopPanel = %ShopPanel
@onready var shop_overlay: PanelContainer = %ShopOverlay
@onready var offer_one: Button = %OfferOne
@onready var offer_two: Button = %OfferTwo
@onready var offer_three: Button = %OfferThree
@onready var skip_offer: Button = %SkipOffer
@onready var prune_button: Button = %PruneButton
@onready var harvest_button: Button = %HarvestButton
@onready var sell_plant_button: Button = %SellPlantButton
@onready var cancel_button: Button = %CancelButton

var _interaction_mode: StringName = PlantView.MODE_NONE
var _pending_item_id: String = ""
var _pending_plant_kind: StringName = &""

func _ready() -> void:
	GameApp.state_changed.connect(_refresh)
	GameApp.mutations_resolved.connect(_on_mutations_resolved)
	GameApp.fertilizer_offer_ready.connect(_on_offer_ready)
	window_view.light_mode_requested.connect(_on_light_mode_requested)
	window_view.window_state_requested.connect(_on_window_state_requested)
	plant_view.branch_selected.connect(_on_branch_selected)
	pot_selector.pot_selected.connect(_handle_pot_click)
	inventory_panel.fertilizer_use_requested.connect(_on_inventory_fertilizer)
	inventory_panel.cutting_plant_requested.connect(_on_cutting_plant_requested)
	inventory_panel.cutting_graft_requested.connect(_on_cutting_graft_requested)
	inventory_panel.seed_plant_requested.connect(_on_seed_plant_requested)
	inventory_panel.fruit_seed_requested.connect(_on_fruit_seed_requested)
	inventory_panel.fruit_sell_requested.connect(_on_fruit_sell_requested)
	shop_panel.fertilizer_buy_requested.connect(_on_shop_fertilizer_requested)
	shop_panel.species_seed_buy_requested.connect(_on_shop_seed_requested)
	shop_panel.pot_buy_requested.connect(_on_shop_pot_requested)
	_set_interaction_mode(PlantView.MODE_NONE)
	_refresh()

func _refresh() -> void:
	var pot := GameApp.active_pot()
	var plant := GameApp.active_plant()
	money_label.text = "$%d" % GameApp.state.money
	inventory_panel.set_inventory(GameApp.state.inventory, _fruit_prices())
	pot_selector.set_state(GameApp.state, not String(_pending_plant_kind).is_empty())
	shop_panel.set_shop(
		GameApp.shop_catalog(),
		GameApp.species_shop_catalog(),
		GameApp.next_pot_price(),
		GameApp.state.money
	)
	_refresh_offer()
	_refresh_actions(plant)
	plant_sense.visible = plant != null

	if pot == null:
		plant_name_label.text = "No pot selected"
		status_label.text = ""
		plant_view.set_species_style(null)
		plant_view.set_plant(null)
		plant_sense.visible = false
		return
	window_view.set_environment(int(pot.light_mode), pot.window_open)
	soil_view.set_moisture(pot.soil_moisture)
	plant_view.set_species_style(GameApp.active_species_definition())
	plant_view.set_plant(plant)
	if plant == null:
		plant_name_label.text = "%s · empty" % pot.pot_id
		status_label.text = "Choose a seed or cutting from inventory to plant here."
		return
	plant_name_label.text = plant.custom_name if not plant.custom_name.is_empty() else _pretty_id(String(plant.species_id))
	plant_sense.set_comfort(GameApp.current_comfort())
	status_label.text = "Growth %.0f%% · Health %.0f%% · Soil %.0f%% · %s" % [
		plant.growth_ratio * 100.0,
		plant.health * 100.0,
		pot.soil_moisture * 100.0,
		"alive" if plant.alive else "not living",
	]

func _refresh_actions(plant: PlantState) -> void:
	var living := plant != null and plant.alive
	prune_button.disabled = not living
	harvest_button.disabled = not _has_ready_fruit(plant)
	sell_plant_button.disabled = plant == null
	sell_plant_button.text = "Sell plant · $%d" % GameApp.active_plant_sale_value() if plant != null else "Sell plant"

func _refresh_offer() -> void:
	var ids := GameApp.current_offer_ids()
	var plant := GameApp.active_plant()
	var can_apply := plant != null and plant.alive
	var buttons: Array[Button] = [offer_one, offer_two, offer_three]
	for index in range(buttons.size()):
		var button := buttons[index]
		if index < ids.size():
			button.text = _pretty_id(String(ids[index]))
			button.disabled = not can_apply
		else:
			button.text = "?"
			button.disabled = true
	var price := GameApp.current_offer_skip_price()
	skip_offer.text = "Skip · $%d" % price if price > 0 else "Skip"
	skip_offer.disabled = price <= 0 or GameApp.state.money < price
	offer_label.text = (
		"Something strange arrives in %.0fs" % GameApp.state.fertilizer_offer.seconds_until_offer
		if ids.is_empty() else "Choose one. Its real effect is not explained."
	)

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

func _on_water_pressed() -> void:
	GameApp.water_active(false)

func _on_spray_pressed() -> void:
	GameApp.water_active(true)

func _on_prune_pressed() -> void:
	if GameApp.active_plant() == null:
		event_label.text = "There is nothing to prune."
		return
	_begin_branch_mode(PlantView.MODE_PRUNE, "Prune mode: click any existing branch.")

func _on_harvest_pressed() -> void:
	if not _has_ready_fruit(GameApp.active_plant()):
		event_label.text = "No ripe fruit yet."
		return
	_begin_branch_mode(PlantView.MODE_HARVEST, "Harvest mode: click a branch with a ripe fruit.")

func _begin_branch_mode(mode: StringName, message: String) -> void:
	_pending_item_id = ""
	_pending_plant_kind = &""
	_set_interaction_mode(mode)
	event_label.text = message

func _on_cancel_pressed() -> void:
	_cancel_action()
	event_label.text = "Action cancelled."

func _on_light_mode_requested(mode: int) -> void:
	GameApp.set_light_mode(mode)

func _on_window_state_requested(open: bool) -> void:
	GameApp.set_window_open(open)

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

func _on_cutting_plant_requested(item_id: String) -> void:
	_begin_plant_target(&"cutting", item_id)

func _on_seed_plant_requested(item_id: String) -> void:
	_begin_plant_target(&"seed", item_id)

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
	else:
		event_label.text = "Cannot plant there."
	_cancel_action()

func _on_inventory_fertilizer(fertilizer_id: StringName) -> void:
	var events := GameApp.use_inventory_fertilizer(fertilizer_id)
	if events.is_empty():
		event_label.text = "Fertilizer used. No visible mutation yet."

func _on_fruit_seed_requested(item_id: String) -> void:
	var seed_id := GameApp.create_seed_from_fruit(item_id)
	event_label.text = "Seed created." if not seed_id.is_empty() else "Could not create seed."

func _on_fruit_sell_requested(item_id: String) -> void:
	var amount := GameApp.sell_fruit(item_id)
	event_label.text = "Fruit sold for $%d." % amount if amount > 0 else "Could not sell fruit."

func _on_sell_plant_pressed() -> void:
	var amount := GameApp.sell_active_plant()
	event_label.text = "Plant sold for $%d. Pot is free." % amount if amount > 0 else "Could not sell plant."
	_cancel_action()

func _on_shop_pressed() -> void:
	shop_overlay.visible = not shop_overlay.visible
	shop_panel.invalidate()
	_refresh()

func _on_close_shop_pressed() -> void:
	shop_overlay.visible = false

func _on_shop_fertilizer_requested(id: StringName) -> void:
	var success := GameApp.buy_shop_fertilizer(id)
	event_label.text = "%s added to inventory." % _pretty_id(String(id)) if success else "Not enough money."

func _on_shop_seed_requested(species_id: StringName) -> void:
	var seed_id := GameApp.buy_shop_seed(species_id)
	event_label.text = "%s seed added to inventory." % _pretty_id(String(species_id)) if not seed_id.is_empty() else "Seed is locked or unaffordable."

func _on_shop_pot_requested() -> void:
	var pot_id := GameApp.buy_new_pot()
	event_label.text = "%s purchased." % pot_id if not pot_id.is_empty() else "Not enough money for a new pot."
	pot_selector.invalidate()

func _on_offer_one_pressed() -> void:
	_choose_offer(0)

func _on_offer_two_pressed() -> void:
	_choose_offer(1)

func _on_offer_three_pressed() -> void:
	_choose_offer(2)

func _choose_offer(index: int) -> void:
	var ids := GameApp.current_offer_ids()
	if index >= ids.size():
		return
	var events := GameApp.choose_fertilizer_offer(ids[index])
	if events.is_empty():
		event_label.text = "Fertilizer absorbed. Nothing obvious happened yet."

func _on_skip_offer_pressed() -> void:
	event_label.text = "Offer skipped." if GameApp.skip_fertilizer_offer() else "Not enough money to skip."

func _on_mutations_resolved(events: Array[Dictionary]) -> void:
	if events.is_empty():
		return
	var texts: Array[String] = []
	for event in events:
		texts.append("%s changed: %s" % [event["branch_id"], _pretty_id(String(event["trait_id"]))])
	event_label.text = " · ".join(texts)

func _on_offer_ready(_ids: Array[StringName]) -> void:
	event_label.text = "Three new fertilizers appeared."

func _fruit_prices() -> Dictionary:
	var result := {}
	for fruit in GameApp.state.inventory.fruits:
		result[fruit.item_id] = GameApp.fruit_sale_value(fruit.item_id)
	return result

func _has_ready_fruit(plant: PlantState) -> bool:
	if plant == null:
		return false
	for branch in plant.existing_branches():
		if branch.fruit_growth != null and branch.fruit_growth.is_ready():
			return true
	return false

func _pretty_id(value: String) -> String:
	return value.replace("_", " ").capitalize()
