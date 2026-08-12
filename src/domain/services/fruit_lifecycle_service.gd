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
		_advance_pot(pot, delta_seconds, registry)

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
	return fruit

static func _advance_pot(
	pot: PotState,
	delta_seconds: float,
	registry: ContentRegistry
) -> void:
	var plant := pot.plant
	if plant == null or not plant.alive:
		return
	var species := registry.get_plant(plant.species_id)
	if species == null or plant.growth_ratio < species.fruiting_growth_threshold:
		return
	var comfort := ComfortEvaluator.evaluate(pot, species)
	var growth_factor := clampf(float(comfort.get("overall", 0.0)), 0.0, 1.0)
	if growth_factor <= 0.0:
		return
	for branch in plant.existing_branches():
		if branch.fruit_growth == null:
			branch.fruit_growth = GrowingFruitState.new()
			branch.fruit_growth.hybrid = branch.grafted
		var fruit := branch.fruit_growth
		fruit.hybrid = branch.grafted
		fruit.progress = minf(
			1.0,
			fruit.progress + delta_seconds * growth_factor / maxf(1.0, species.fruit_ripen_seconds)
		)
