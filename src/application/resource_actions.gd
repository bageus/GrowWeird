class_name ResourceActions
extends RefCounted

const CUTTING: StringName = &"cutting"
const SEED: StringName = &"seed"
const FRUIT: StringName = &"fruit"

static func item_value(
	state: GameState,
	kind: StringName,
	item_id: String,
	registry: ContentRegistry,
	rules: GameRules
) -> int:
	if state == null:
		return 0
	match kind:
		CUTTING:
			var cutting := InventoryService.find_cutting(state.inventory, item_id)
			if cutting == null or cutting.genome == null:
				return 0
			return GeneticItemValuationService.cutting_value(
				cutting, registry.get_plant(cutting.genome.species_id), rules
			)
		SEED:
			var seed := InventoryService.find_seed(state.inventory, item_id)
			if seed == null or seed.genome == null:
				return 0
			return GeneticItemValuationService.seed_value(
				seed, registry.get_plant(seed.genome.species_id), rules
			)
		FRUIT:
			var fruit := InventoryService.find_fruit(state.inventory, item_id)
			return EconomyActions.fruit_value(fruit, registry, rules)
	return 0

static func sell_item(
	state: GameState,
	kind: StringName,
	item_id: String,
	registry: ContentRegistry,
	rules: GameRules
) -> int:
	if kind == FRUIT:
		return EconomyActions.sell_fruit(state, item_id, registry, rules)
	var amount := item_value(state, kind, item_id, registry, rules)
	if amount <= 0 or not _take_item(state, kind, item_id):
		return 0
	EconomyService.credit(state, amount)
	return amount

static func recycle_item(
	state: GameState,
	kind: StringName,
	item_id: String,
	rules: GameRules
) -> int:
	if state == null:
		return 0
	var amount := _recycle_yield(kind, rules)
	if amount <= 0 or not _take_item(state, kind, item_id):
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

static func _take_item(state: GameState, kind: StringName, item_id: String) -> bool:
	match kind:
		CUTTING:
			return InventoryService.take_cutting(state.inventory, item_id) != null
		SEED:
			return InventoryService.take_seed(state.inventory, item_id) != null
		FRUIT:
			return InventoryService.take_fruit(state.inventory, item_id) != null
	return false

static func _recycle_yield(kind: StringName, rules: GameRules) -> int:
	match kind:
		CUTTING:
			return RecyclingService.cutting_yield(rules)
		SEED:
			return RecyclingService.seed_yield(rules)
		FRUIT:
			return RecyclingService.fruit_yield(rules)
	return 0
