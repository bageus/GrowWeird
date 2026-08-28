extends Node

signal state_changed
signal mutations_resolved(events: Array[Dictionary])
signal fertilizer_offer_ready(ids: Array[StringName])
signal offline_progress_applied(result: Dictionary)

const DEFAULT_RULES: GameRules = preload("res://content/config/default_game_rules.tres")

var state: GameState
var registry := ContentRegistry.new()
var rules: GameRules = DEFAULT_RULES
var _clock := GameClock.new()
var _persistence := PersistenceCoordinator.new()
var _platform_paused: bool = false

func _ready() -> void:
	registry.load_all()
	state = SaveRepository.load_state()
	if state == null:
		state = _create_new_game()
	else:
		NewGameFactory.ensure_inventory_bootstrap(state, active_plant())
	_persistence.reconciled.connect(_on_persistence_reconciled)
	PlatformRuntime.pause_requested.connect(_on_platform_pause_requested)
	PlatformRuntime.resume_requested.connect(_on_platform_resume_requested)
	_persistence.start(state, registry, rules, PlatformRuntime)
	state_changed.emit()

func _process(delta: float) -> void:
	if state == null:
		return
	_persistence.process(delta, state)
	if not _persistence.is_ready() or _platform_paused:
		return
	var changed := false
	var steps := _clock.consume(delta, rules.simulation_step_seconds)
	for _step in range(steps):
		PlantSimulationService.advance(state, rules.simulation_step_seconds, registry, rules)
		FruitLifecycleService.advance(state, rules.simulation_step_seconds, registry)
		changed = true
	if _has_living_plant() and FertilizerOfferService.advance(state.fertilizer_offer, delta, registry.all_fertilizers(), rules):
		fertilizer_offer_ready.emit(state.fertilizer_offer.offered_ids.duplicate())
		changed = true
	if changed:
		state_changed.emit()

func _exit_tree() -> void:
	if state != null and _persistence.is_ready():
		_persistence.save_now(state, false)

func active_pot() -> PotState:
	return state.active_pot() if state != null else null

func active_plant() -> PlantState:
	var pot := active_pot()
	return pot.plant if pot != null else null

func active_species_definition() -> PlantSpeciesDefinition:
	var plant := active_plant()
	return registry.get_plant(plant.species_id) if plant != null else null

func switch_pot(pot_id: String) -> bool:
	if state == null or state.find_pot(pot_id) == null:
		return false
	state.active_pot_id = pot_id
	state_changed.emit()
	return true

func set_light_mode(mode: int) -> bool:
	var pot := active_pot()
	if pot == null or mode < 0 or mode >= PotState.LightMode.size():
		return false
	pot.light_mode = mode
	_progress(&"environment_changed")
	state_changed.emit()
	return true

func set_window_open(value: bool) -> bool:
	var pot := active_pot()
	if pot == null:
		return false
	pot.window_open = value
	_progress(&"environment_changed")
	state_changed.emit()
	return true

func water_active(use_sprayer: bool = false) -> bool:
	var pot := active_pot()
	if pot == null or pot.plant == null or not pot.plant.alive:
		return false
	var amount := rules.sprayer_soil_amount if use_sprayer else rules.watering_can_amount
	pot.soil_moisture = clampf(pot.soil_moisture + amount, 0.0, 1.0)
	_progress(&"watered")
	state_changed.emit()
	return true

func rename_active_plant(new_name: String) -> bool:
	var plant := active_plant()
	if plant == null:
		return false
	plant.custom_name = new_name.strip_edges().left(48)
	state_changed.emit()
	return true

func choose_fertilizer_offer(fertilizer_id: StringName) -> Array[Dictionary]:
	var result := FertilizerActions.choose_offer(state, active_plant(), fertilizer_id, registry, rules)
	if not bool(result.get("success", false)):
		return []
	var events := _events_from_result(result)
	_progress(&"fertilizer_used")
	if not events.is_empty():
		_progress(&"mutation_resolved")
	_emit_mutation_events(events)
	state_changed.emit()
	return events

func skip_fertilizer_offer() -> bool:
	if not FertilizerActions.skip_offer(state, rules):
		return false
	state_changed.emit()
	return true

func refresh_fertilizer_offer() -> bool:
	if state == null or not _has_living_plant():
		return false
	if not FertilizerOfferService.refresh_offer(state.fertilizer_offer, registry.all_fertilizers(), rules):
		return false
	state_changed.emit()
	return true

func use_inventory_fertilizer(fertilizer_id: StringName) -> Array[Dictionary]:
	var result := FertilizerActions.use_inventory(state, active_plant(), fertilizer_id, registry)
	if not bool(result.get("success", false)):
		return []
	var events := _events_from_result(result)
	_progress(&"fertilizer_used")
	if not events.is_empty():
		_progress(&"mutation_resolved")
	_emit_mutation_events(events)
	state_changed.emit()
	return events

func prune_active_branch(slot: StringName) -> String:
	var item_id := PropagationActions.prune(state, active_plant(), slot)
	if not item_id.is_empty():
		_progress(&"branch_pruned")
		state_changed.emit()
	return item_id

func plant_cutting(cutting_id: String, pot_id: String) -> bool:
	if not PropagationActions.plant_cutting(state, cutting_id, pot_id):
		return false
	state_changed.emit()
	return true

func plant_seed(seed_id: String, pot_id: String) -> bool:
	if not PropagationActions.plant_seed(state, seed_id, pot_id):
		return false
	state_changed.emit()
	return true

func graft_cutting(cutting_id: String, slot: StringName) -> bool:
	if not PropagationActions.graft_cutting(state, active_plant(), cutting_id, slot):
		return false
	_progress(&"branch_grafted")
	state_changed.emit()
	return true

func harvest_active_fruit(slot: StringName) -> String:
	var item_id := FruitActions.harvest(state, active_plant(), slot)
	if not item_id.is_empty():
		_progress(&"fruit_harvested")
		state_changed.emit()
	return item_id

func create_seed_from_fruit(fruit_id: String) -> String:
	var item_id := PropagationActions.create_seed_from_fruit(state, fruit_id)
	if not item_id.is_empty():
		_progress(&"seed_created")
		state_changed.emit()
	return item_id

func active_plant_sale_value() -> int:
	return EconomyActions.plant_value(active_plant(), registry, rules)

func sell_active_plant() -> int:
	var amount := EconomyActions.sell_plant(state, active_pot(), registry, rules)
	if amount > 0:
		state_changed.emit()
	return amount

func fruit_sale_value(fruit_id: String) -> int:
	var fruit := InventoryService.find_fruit(state.inventory, fruit_id) if state != null else null
	return EconomyActions.fruit_value(fruit, registry, rules)

func sell_fruit(fruit_id: String) -> int:
	var amount := EconomyActions.sell_fruit(state, fruit_id, registry, rules)
	if amount > 0:
		_progress(&"resource_processed")
		state_changed.emit()
	return amount

func inventory_item_sale_value(kind: StringName, item_id: String) -> int:
	return ResourceActions.item_value(state, kind, item_id, registry, rules)

func sell_inventory_item(kind: StringName, item_id: String) -> int:
	return sell_inventory_items(kind, item_id, 1)

func sell_inventory_items(kind: StringName, item_id: String, quantity: int) -> int:
	var amount := ResourceActions.sell_items(state, kind, item_id, quantity, registry, rules)
	if amount > 0:
		_progress(&"resource_processed")
		state_changed.emit()
	return amount

func inventory_item_recycle_yield(kind: StringName) -> int:
	return ResourceActions.recycle_yield(kind, rules)

func recycle_inventory_item(kind: StringName, item_id: String) -> int:
	var amount := ResourceActions.recycle_item(state, kind, item_id, rules)
	if amount > 0:
		_progress(&"resource_processed")
		state_changed.emit()
	return amount

func active_dead_plant_compost_yield() -> int:
	return RecyclingService.dead_plant_yield(active_plant(), rules)

func recycle_active_dead_plant() -> int:
	var amount := ResourceActions.recycle_dead_plant(state, active_pot(), rules)
	if amount > 0:
		state_changed.emit()
	return amount

func shop_catalog() -> Array[Dictionary]:
	return ShopService.fertilizer_catalog(state, registry.all_fertilizers())

func species_shop_catalog() -> Array[Dictionary]:
	return ShopService.species_catalog(state, registry.all_plants())

func next_pot_price() -> int:
	return ShopService.next_pot_price(state, rules)

func buy_shop_fertilizer(fertilizer_id: StringName) -> bool:
	if not ShopActions.buy_fertilizer(state, fertilizer_id, registry):
		return false
	state_changed.emit()
	return true

func buy_shop_seed(species_id: StringName) -> String:
	var seed_id := ShopActions.buy_species_seed(state, species_id, registry)
	if not seed_id.is_empty():
		state_changed.emit()
	return seed_id

func buy_new_pot() -> String:
	var pot_id := ShopActions.buy_pot(state, rules)
	if not pot_id.is_empty():
		state_changed.emit()
	return pot_id

func current_comfort() -> Dictionary:
	var pot := active_pot()
	if pot == null or pot.plant == null:
		return {}
	var species := registry.get_plant(pot.plant.species_id)
	return ComfortEvaluator.evaluate(pot, species) if species != null else {}

func current_offer_ids() -> Array[StringName]:
	return state.fertilizer_offer.offered_ids.duplicate() if state != null else []

func current_offer_skip_price() -> int:
	return FertilizerOfferService.skip_price(state.fertilizer_offer, rules) if state != null else 0

func platform_id() -> StringName:
	return PlatformRuntime.platform_id()

func cloud_save_available() -> bool:
	return PlatformRuntime.cloud_available()

func set_gameplay_active(active: bool) -> void:
	PlatformRuntime.set_gameplay_active(active)

func show_fullscreen_ad() -> void:
	PlatformRuntime.show_fullscreen_ad()

func save_now() -> bool:
	return state != null and _persistence.save_now(state)

func _on_persistence_reconciled(next_state: GameState, offline_result: Dictionary) -> void:
	state = next_state
	_clock.reset()
	_emit_offline_result(offline_result)
	state_changed.emit()

func _on_platform_pause_requested() -> void:
	if _platform_paused:
		return
	_platform_paused = true
	_clock.reset()
	if _persistence.is_ready():
		_persistence.save_now(state)

func _on_platform_resume_requested() -> void:
	if not _platform_paused:
		return
	_platform_paused = false
	_clock.reset()
	var result := _persistence.catch_up(state)
	_emit_offline_result(result)
	state_changed.emit()

func _emit_offline_result(result: Dictionary) -> void:
	if result.is_empty() or float(result.get("applied_seconds", 0.0)) <= 0.0:
		return
	offline_progress_applied.emit(result)
	if bool(result.get("offer_created", false)):
		fertilizer_offer_ready.emit(state.fertilizer_offer.offered_ids.duplicate())

func _events_from_result(result: Dictionary) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var raw: Variant = result.get("events", [])
	if raw is Array:
		for value in raw:
			if value is Dictionary:
				events.append(value)
	return events

func _emit_mutation_events(events: Array[Dictionary]) -> void:
	if not events.is_empty():
		mutations_resolved.emit(events)

func _progress(event_id: StringName) -> void:
	ProgressionActions.record_event(state, event_id, registry)

func _has_living_plant() -> bool:
	if state == null:
		return false
	for pot in state.pots:
		if pot.plant != null and pot.plant.alive:
			return true
	return false

func _create_new_game() -> GameState:
	return NewGameFactory.create(rules)
