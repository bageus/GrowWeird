extends Control

@onready var status_label: Label = %StatusLabel
@onready var event_label: Label = %EventLabel
@onready var inventory_label: Label = %InventoryLabel
@onready var offer_label: Label = %OfferLabel
@onready var window_button: Button = %WindowButton
@onready var light_button: Button = %LightButton
@onready var offer_one: Button = %OfferOne
@onready var offer_two: Button = %OfferTwo
@onready var offer_three: Button = %OfferThree
@onready var skip_offer: Button = %SkipOffer

func _ready() -> void:
	GameApp.state_changed.connect(_refresh)
	GameApp.mutations_resolved.connect(_on_mutations_resolved)
	GameApp.fertilizer_offer_ready.connect(_on_offer_ready)
	_refresh()

func _refresh() -> void:
	_refresh_status()
	_refresh_offer()
	_refresh_inventory()

func _refresh_status() -> void:
	var pot := GameApp.active_pot()
	var plant := GameApp.active_plant()
	if pot == null:
		status_label.text = "No active pot"
		return
	window_button.text = "Window: %s" % ("open" if pot.window_open else "closed")
	light_button.text = "Light: %s" % _light_name(int(pot.light_mode))
	if plant == null:
		status_label.text = "%s is empty" % pot.pot_id
		return

	var comfort := GameApp.current_comfort()
	status_label.text = (
		"%s | %s\nGrowth %.1f%%  Health %.1f%%  Soil %.1f%%  Comfort %.1f%%\nMain issue: %s (%d)\nBranches: %s"
		% [
			pot.pot_id,
			plant.custom_name if not plant.custom_name.is_empty() else String(plant.species_id),
			plant.growth_ratio * 100.0,
			plant.health * 100.0,
			pot.soil_moisture * 100.0,
			float(comfort.get("overall", 0.0)) * 100.0,
			String(comfort.get("main_issue", "none")),
			int(comfort.get("direction", 0)),
			_branch_summary(plant),
		]
	)

func _refresh_offer() -> void:
	var ids := GameApp.current_offer_ids()
	var buttons: Array[Button] = [offer_one, offer_two, offer_three]
	for index in range(buttons.size()):
		var button := buttons[index]
		if index < ids.size():
			button.text = String(ids[index])
			button.disabled = false
		else:
			button.text = "—"
			button.disabled = true
	var price := GameApp.current_offer_skip_price()
	skip_offer.text = "Skip (%d)" % price if price > 0 else "Skip"
	skip_offer.disabled = price <= 0 or GameApp.state.money < price
	if ids.is_empty():
		offer_label.text = "Next fertilizer offer in %.1fs | Money: %d" % [
			GameApp.state.fertilizer_offer.seconds_until_offer,
			GameApp.state.money,
		]
	else:
		offer_label.text = "Choose one fertilizer for the active plant | Money: %d" % GameApp.state.money

func _refresh_inventory() -> void:
	var inventory := GameApp.state.inventory
	inventory_label.text = "Inventory | Fertilizers %s | Cuttings %d | Seeds %d | Fruits %d" % [
		str(inventory.fertilizers),
		inventory.cuttings.size(),
		inventory.seeds.size(),
		inventory.fruits.size(),
	]

func _branch_summary(plant: PlantState) -> String:
	var parts: Array[String] = []
	for slot in BranchState.VALID_SLOTS:
		var branch := plant.branch_at(slot)
		if branch == null:
			parts.append("%s=empty" % String(slot))
		else:
			var graft := " graft" if branch.grafted else ""
			parts.append("%s%s %s" % [String(slot), graft, str(branch.traits)])
	return "; ".join(parts)

func _light_name(mode: int) -> String:
	match mode:
		PotState.LightMode.DARK:
			return "dark"
		PotState.LightMode.DIFFUSED:
			return "diffused"
		PotState.LightMode.BRIGHT:
			return "bright"
		PotState.LightMode.DIRECT:
			return "direct"
	return "unknown"

func _on_water_pressed() -> void:
	GameApp.water_active(false)

func _on_spray_pressed() -> void:
	GameApp.water_active(true)

func _on_window_pressed() -> void:
	var pot := GameApp.active_pot()
	if pot != null:
		GameApp.set_window_open(not pot.window_open)

func _on_light_pressed() -> void:
	var pot := GameApp.active_pot()
	if pot != null:
		GameApp.set_light_mode((int(pot.light_mode) + 1) % PotState.LightMode.size())

func _on_offer_one_pressed() -> void:
	_choose_offer(0)

func _on_offer_two_pressed() -> void:
	_choose_offer(1)

func _on_offer_three_pressed() -> void:
	_choose_offer(2)

func _choose_offer(index: int) -> void:
	var ids := GameApp.current_offer_ids()
	if index < ids.size():
		GameApp.choose_fertilizer_offer(ids[index])

func _on_skip_offer_pressed() -> void:
	if not GameApp.skip_fertilizer_offer():
		event_label.text = "Unable to skip fertilizer offer"

func _on_prune_left_pressed() -> void:
	_prune(&"left")

func _on_prune_center_pressed() -> void:
	_prune(&"center")

func _on_prune_right_pressed() -> void:
	_prune(&"right")

func _prune(slot: StringName) -> void:
	var item_id := GameApp.prune_active_branch(slot)
	event_label.text = "Created cutting %s" % item_id if not item_id.is_empty() else "Cannot prune %s" % slot

func _on_plant_cutting_pressed() -> void:
	var inventory := GameApp.state.inventory
	if inventory.cuttings.is_empty():
		event_label.text = "No cutting in inventory"
		return
	var cutting := inventory.cuttings[0]
	var success := GameApp.plant_cutting(cutting.item_id, "pot-2")
	event_label.text = "Cutting planted in pot-2" if success else "Cannot plant cutting in pot-2"

func _on_graft_cutting_pressed() -> void:
	var inventory := GameApp.state.inventory
	var plant := GameApp.active_plant()
	if inventory.cuttings.is_empty() or plant == null:
		event_label.text = "Need a cutting and active plant"
		return
	for slot in BranchState.VALID_SLOTS:
		if plant.has_free_slot(slot):
			var success := GameApp.graft_cutting(inventory.cuttings[0].item_id, slot)
			event_label.text = "Grafted into %s" % slot if success else "Graft failed"
			return
	event_label.text = "No free branch slot"

func _on_pot_one_pressed() -> void:
	GameApp.switch_pot("pot-1")

func _on_pot_two_pressed() -> void:
	GameApp.switch_pot("pot-2")

func _on_mutations_resolved(events: Array[Dictionary]) -> void:
	if events.is_empty():
		return
	var texts: Array[String] = []
	for event in events:
		texts.append("%s → %s Lv.%d" % [event["branch_id"], event["trait_id"], event["level"]])
	event_label.text = "\n".join(texts)

func _on_offer_ready(_ids: Array[StringName]) -> void:
	event_label.text = "New fertilizer offer is ready"
