class_name ResourceActions
extends RefCounted

const CUTTING: StringName = &"cutting"
const SEED: StringName = &"seed"
const FRUIT: StringName = &"fruit"
const FERTILIZER: StringName = &"fertilizer"
const MISC: StringName = &"misc"

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
			var seed_state := InventoryService.find_seed(state.inventory, item_id)
			if seed_state == null or seed_state.genome == null:
				return 0
			return GeneticItemValuationService.seed_value(
				seed_state, registry.get_plant(seed_state.genome.species_id), rules
			)
		FRUIT:
			var fruit := InventoryService.find_fruit(state.inventory, item_id)
			return EconomyActions.fruit_value(fruit, registry, rules)
		FERTILIZER:
			if InventoryService.fertilizer_count(state.inventory, StringName(item_id)) <= 0:
				return 0
			var fertilizer := registry.get_fertilizer(StringName(item_id))
			if fertilizer == null:
				return 0
			return maxi(1, int(round(float(fertilizer.shop_price) * 0.5)))
	return 0

static func sell_item(
	state: GameState,
	kind: StringName,
	item_id: String,
	registry: ContentRegistry,
	rules: GameRules
) -> int:
	return sell_items(state, kind, item_id, 1, registry, rules)

static func sell_items(
	state: GameState,
	kind: StringName,
	item_id: String,
	quantity: int,
	registry: ContentRegistry,
	rules: GameRules
) -> int:
	if state == null or quantity <= 0:
		return 0
	var unit_value := item_value(state, kind, item_id, registry, rules)
	if unit_value <= 0:
		return 0
	if kind == FERTILIZER:
		var taken := InventoryService.take_fertilizer_amount(state.inventory, StringName(item_id), quantity)
		if taken <= 0:
			return 0
		var total := unit_value * taken
		EconomyService.credit(state, total)
		return total
	if kind == FRUIT:
		return EconomyActions.sell_fruit(state, item_id, registry, rules)
	if not _take_item(state, kind, item_id):
		return 0
	EconomyService.credit(state, unit_value)
	return unit_value

static func recycle_item(
	state: GameState,
	kind: StringName,
	item_id: String,
	rules: GameRules
) -> int:
	if state == null:
		return 0
	var amount := recycle_yield(kind, rules)
	if amount <= 0 or not _take_item(state, kind, item_id):
		return 0
	InventoryService.add_fertilizer(state.inventory, RecyclingService.COMPOST_ID, amount)
	return amount

static func recycle_yield(kind: StringName, rules: GameRules) -> int:
	match kind:
		CUTTING:
			return RecyclingService.cutting_yield(rules)
		SEED:
			return RecyclingService.seed_yield(rules)
		FRUIT:
			return RecyclingService.fruit_yield(rules)
		MISC:
			return RecyclingService.misc_yield(rules)
	return 0

static func _take_item(state: GameState, kind: StringName, item_id: String) -> bool:
	match kind:
		CUTTING:
			return InventoryService.take_cutting(state.inventory, item_id) != null
		SEED:
			return InventoryService.take_seed(state.inventory, item_id) != null
		FRUIT:
			return InventoryService.take_fruit(state.inventory, item_id) != null
		MISC:
			return InventoryService.take_misc(state.inventory, item_id) == 1
	return false
