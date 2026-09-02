class_name EconomyActions
extends RefCounted

static func plant_value(
	plant: PlantState,
	registry: ContentRegistry,
	rules: GameRules
) -> int:
	if plant == null:
		return 0
	var species := registry.get_plant(plant.species_id)
	return PlantValuationService.value(plant, species, rules)

static func sell_plant(
	state: GameState,
	pot: PotState,
	registry: ContentRegistry,
	rules: GameRules
) -> int:
	if state == null or pot == null or pot.plant == null:
		return 0
	var amount := plant_value(pot.plant, registry, rules) + maxi(0, rules.pot_base_price)
	if amount <= 0:
		return 0
	EconomyService.credit(state, amount)
	var sold_pot_id := pot.pot_id
	state.pots.erase(pot)
	if state.active_pot_id == sold_pot_id:
		state.active_pot_id = state.pots[0].pot_id if not state.pots.is_empty() else ""
	return amount

static func fruit_value(
	fruit: FruitState,
	registry: ContentRegistry,
	rules: GameRules
) -> int:
	if fruit == null or fruit.genome == null:
		return 0
	var species := registry.get_plant(fruit.genome.species_id)
	return FruitValuationService.value(fruit, species, rules)

static func sell_fruit(
	state: GameState,
	fruit_id: String,
	registry: ContentRegistry,
	rules: GameRules
) -> int:
	if state == null:
		return 0
	var fruit := InventoryService.find_fruit(state.inventory, fruit_id)
	var amount := fruit_value(fruit, registry, rules)
	if amount <= 0:
		return 0
	var removed := InventoryService.take_fruit(state.inventory, fruit_id)
	if removed == null:
		return 0
	EconomyService.credit(state, amount)
	return amount
