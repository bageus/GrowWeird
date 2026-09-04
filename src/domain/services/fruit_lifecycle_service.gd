class_name FruitLifecycleService
extends RefCounted

static func advance(
	game_state: GameState,
	delta_seconds: float,
	registry: ContentRegistry
) -> void:
	if game_state == null or delta_seconds <= 0.0:
		return
	for pot in game_state.pots:
		_advance_pot(game_state, pot, delta_seconds, registry)

static func harvest(
	plant: PlantState,
	slot: StringName,
	item_id: String
) -> FruitState:
	if plant == null or not plant.alive:
		return null
	var branch := plant.branch_at(slot)
	if branch == null or branch.fruit_growth == null or not branch.fruit_growth.is_ready():
		return null
	var fruit := PropagationService.create_fruit(plant, slot, item_id)
	if fruit == null:
		return null
	branch.fruit_growth = null
	branch.fruit_cycle_eligible = plant.fruit_cycle_index + 1
	if not plant.has_active_fruits():
		plant.fruit_cycle_index += 1
		plant.growth_cycle_index = GrowthCycleService.LAST_CYCLE
		plant.growth_cycle_elapsed = 0.0
	return fruit

static func _advance_pot(
	game_state: GameState,
	pot: PotState,
	delta_seconds: float,
	registry: ContentRegistry
) -> void:
	var plant := pot.plant
	if plant == null or not plant.alive:
		return
	var species := registry.get_plant(plant.species_id)
	if species == null or plant.growth_cycle_index < 10:
		return
	if plant.growth_cycle_index == GrowthCycleService.LAST_CYCLE:
		_convert_unharvested_to_seeds(game_state, plant)
		return
	var comfort := ComfortEvaluator.evaluate(pot, species)
	var growth_factor := clampf(float(comfort.get("overall", 0.0)), 0.0, 1.0)
	if growth_factor <= 0.0:
		return
	for branch in plant.existing_branches():
		if branch.fruit_cycle_eligible > plant.fruit_cycle_index:
			continue
		if branch.fruit_growth == null:
			branch.fruit_growth = GrowingFruitState.new()
			branch.fruit_growth.hybrid = branch.grafted
		var fruit := branch.fruit_growth
		fruit.hybrid = branch.grafted
		fruit.progress = 1.0 if plant.growth_cycle_index == 11 else lerpf(0.1, 0.85, GrowthCycleService.progress(plant))

static func _convert_unharvested_to_seeds(game_state: GameState, plant: PlantState) -> void:
	for branch in plant.existing_branches():
		if branch.fruit_growth == null:
			continue
		var fruit := PropagationService.create_fruit(plant, branch.slot, IdFactory.make("fruit"))
		var seed_state := PropagationService.seed_from_fruit(fruit, IdFactory.make("seed"))
		if seed_state != null:
			InventoryService.add_seed(game_state.inventory, seed_state)
		branch.fruit_growth = null
