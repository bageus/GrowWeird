class_name ResourceActions
extends RefCounted

static func cutting_value(
	state: GameState,
	item_id: String,
	registry: ContentRegistry,
	rules: GameRules
) -> int:
	if state == null:
		return 0
	var cutting := InventoryService.find_cutting(state.inventory, item_id)
	if cutting == null or cutting.genome == null:
		return 0
	return GeneticItemValuationService.cutting_value(
		cutting,
		registry.get_plant(cutting.genome.species_id),
		rules
	)

static func seed_value(
	state: GameState,
	item_id: String,
	registry: ContentRegistry,
	rules: GameRules
) -> int:
	if state == null:
		return 0
	var seed := InventoryService.find_seed(state.inventory, item_id)
	if seed == null or seed.genome == null:
		return 0
	return GeneticItemValuationService.seed_value(
		seed,
		registry.get_plant(seed.genome.species_id),
		rules
	)

static func sell_cutting(
	state: GameState,
	item_id: String,
	registry: ContentRegistry,
	rules: GameRules
) -> int:
	var amount := cutting_value(state, item_id, registry, rules)
	if amount <= 0 or InventoryService.take_cutting(state.inventory, item_id) == null:
		return 0
	EconomyService.credit(state, amount)
	return amount

static func sell_seed(
	state: GameState,
	item_id: String,
	registry: ContentRegistry,
	rules: GameRules
) -> int:
	var amount := seed_value(state, item_id, registry, rules)
	if amount <= 0 or InventoryService.take_seed(state.inventory, item_id) == null:
		return 0
	EconomyService.credit(state, amount)
	return amount

static func recycle_cutting(state: GameState, item_id: String, rules: GameRules) -> int:
	if state == null:
		return 0
	var amount := RecyclingService.cutting_yield(rules)
	if amount <= 0 or InventoryService.take_cutting(state.inventory, item_id) == null:
		return 0
	InventoryService.add_fertilizer(state.inventory, RecyclingService.COMPOST_ID, amount)
	return amount

static func recycle_seed(state: GameState, item_id: String, rules: GameRules) -> int:
	if state == null:
		return 0
	var amount := RecyclingService.seed_yield(rules)
	if amount <= 0 or InventoryService.take_seed(state.inventory, item_id) == null:
		return 0
	InventoryService.add_fertilizer(state.inventory, RecyclingService.COMPOST_ID, amount)
	return amount

static func recycle_fruit(state: GameState, item_id: String, rules: GameRules) -> int:
	if state == null:
		return 0
	var amount := RecyclingService.fruit_yield(rules)
	if amount <= 0 or InventoryService.take_fruit(state.inventory, item_id) == null:
		return 0
	InventoryService.add_fertilizer(state.inventory, RecyclingService.COMPOST_ID, amount)
	return amount

static func recycle_dead_plant(state: GameState, pot: PotState, rules: GameRules) -> int:
	if state == null or pot == null or pot.plant == null:
		return 0
	var amount := RecyclingService.dead_plant_yield(pot.plant, rules)
	if amount <= 0:
		return 0
	pot.plant = null
	InventoryService.add_fertilizer(state.inventory, RecyclingService.COMPOST_ID, amount)
	return amount
