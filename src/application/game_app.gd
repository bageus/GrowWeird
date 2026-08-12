extends Node

signal state_changed
signal mutations_resolved(events: Array[Dictionary])

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
	var steps := _clock.consume(delta, rules.simulation_step_seconds)
	for _step in range(steps):
		PlantSimulationService.advance(state, rules.simulation_step_seconds, registry, rules)
	if steps > 0:
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

func apply_fertilizer(fertilizer_id: StringName) -> Array[Dictionary]:
	var plant := active_plant()
	var fertilizer := registry.get_fertilizer(fertilizer_id)
	if plant == null or fertilizer == null or not plant.alive:
		return []
	_apply_care_effects(plant, fertilizer)
	var events := MutationEngine.apply_fertilizer(plant, fertilizer, registry.all_mutations())
	mutations_resolved.emit(events)
	state_changed.emit()
	return events

func current_comfort() -> Dictionary:
	var pot := active_pot()
	if pot == null or pot.plant == null:
		return {}
	var species := registry.get_plant(pot.plant.species_id)
	return ComfortEvaluator.evaluate(pot, species) if species != null else {}

func save_now() -> bool:
	return state != null and SaveRepository.save(state)

func _apply_care_effects(plant: PlantState, fertilizer: FertilizerDefinition) -> void:
	if fertilizer.care_effects.has("health"):
		plant.health = clampf(
			plant.health + float(fertilizer.care_effects["health"]),
			0.0,
			1.0
		)

func _create_new_game() -> GameState:
	var new_state := GameState.new()
	new_state.money = rules.starting_money

	var first_pot := PotState.new()
	first_pot.pot_id = "pot-1"
	first_pot.plant = PlantState.new()
	first_pot.plant.instance_id = _make_id("plant")
	first_pot.plant.species_id = STARTER_SPECIES
	first_pot.plant.initialize_native_branches()

	var second_pot := PotState.new()
	second_pot.pot_id = "pot-2"

	new_state.pots = [first_pot, second_pot]
	new_state.active_pot_id = first_pot.pot_id
	return new_state

func _make_id(prefix: String) -> String:
	return "%s-%d-%d" % [prefix, Time.get_ticks_usec(), randi()]
