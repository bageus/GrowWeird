extends Node

signal state_changed
signal mutations_resolved(events: Array[Dictionary])
signal fertilizer_offer_ready(ids: Array[StringName])

const DEFAULT_RULES: GameRules = preload("res://content/config/default_game_rules.tres")
const STARTER_SPECIES: StringName = &"starter_sprout"

var state: GameState
var registry := ContentRegistry.new()
var rules: GameRules = DEFAULT_RULES

var _clock := GameClock.new()
var _autosave_elapsed: float = 0.0

func _ready() -> void:
	registry.load_all()
	state = SaveRepository.load_state()
	if state == null:
		state = _create_new_game()
	state_changed.emit()

func _process(delta: float) -> void:
	var changed := false
	var steps := _clock.consume(delta, rules.simulation_step_seconds)
	for _step in range(steps):
		PlantSimulationService.advance(state, rules.simulation_step_seconds, registry, rules)
		changed = true

	if _has_living_plant() and FertilizerOfferService.advance(
		state.fertilizer_offer,
		delta,
		registry.all_fertilizers(),
		rules
	):
		fertilizer_offer_ready.emit(state.fertilizer_offer.offered_ids.duplicate())
		changed = true

	if changed:
		state_changed.emit()

	_autosave_elapsed += delta
	if _autosave_elapsed >= rules.autosave_interval_seconds:
		_autosave_elapsed = 0.0
		SaveRepository.save(state)

func _exit_tree() -> void:
	if state != null:
		SaveRepository.save(state)

func active_pot() -> PotState:
	return state.active_pot() if state != null else null

func active_plant() -> PlantState:
	var pot := active_pot()
	return pot.plant if pot != null else null

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
	state_changed.emit()
	return true

func set_window_open(value: bool) -> bool:
	var pot := active_pot()
	if pot == null:
		return false
	pot.window_open = value
	state_changed.emit()
	return true

func water_active(use_sprayer: bool = false) -> bool:
	var pot := active_pot()
	if pot == null or pot.plant == null or not pot.plant.alive:
		return false
	var amount := rules.sprayer_soil_amount if use_sprayer else rules.watering_can_amount
	pot.soil_moisture = clampf(pot.soil_moisture + amount, 0.0, 1.0)
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
	var result := FertilizerActions.choose_offer(
		state,
		active_plant(),
		fertilizer_id,
		registry,
		rules
	)
	if not bool(result.get("success", false)):
		return []
	var events := _events_from_result(result)
	_emit_mutation_events(events)
	state_changed.emit()
	return events

func skip_fertilizer_offer() -> bool:
	if not FertilizerActions.skip_offer(state, rules):
		return false
	state_changed.emit()
	return true

func use_inventory_fertilizer(fertilizer_id: StringName) -> Array[Dictionary]:
	var result := FertilizerActions.use_inventory(state, active_plant(), fertilizer_id, registry)
	if not bool(result.get("success", false)):
		return []
	var events := _events_from_result(result)
	_emit_mutation_events(events)
	state_changed.emit()
	return events

func prune_active_branch(slot: StringName) -> String:
	var item_id := PropagationActions.prune(state, active_plant(), slot)
	if not item_id.is_empty():
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
	state_changed.emit()
	return true

func create_seed_from_fruit(fruit_id: String) -> String:
	var item_id := PropagationActions.create_seed_from_fruit(state, fruit_id)
	if not item_id.is_empty():
		state_changed.emit()
	return item_id

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

func save_now() -> bool:
	return state != null and SaveRepository.save(state)

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

func _has_living_plant() -> bool:
	if state == null:
		return false
	for pot in state.pots:
		if pot.plant != null and pot.plant.alive:
			return true
	return false

func _create_new_game() -> GameState:
	var new_state := GameState.new()
	new_state.money = rules.starting_money

	var first_pot := PotState.new()
	first_pot.pot_id = "pot-1"
	first_pot.plant = PlantState.new()
	first_pot.plant.instance_id = IdFactory.make("plant")
	first_pot.plant.species_id = STARTER_SPECIES
	first_pot.plant.initialize_native_branches()

	var second_pot := PotState.new()
	second_pot.pot_id = "pot-2"

	new_state.pots = [first_pot, second_pot]
	new_state.active_pot_id = first_pot.pot_id
	FertilizerOfferService.initialize_rng(
		new_state.fertilizer_offer,
		int(first_pot.plant.instance_id.hash())
	)
	FertilizerOfferService.schedule_initial(new_state.fertilizer_offer, rules)
	return new_state
