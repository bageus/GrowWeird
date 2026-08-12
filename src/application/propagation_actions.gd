class_name PropagationActions
extends RefCounted

static func prune(state: GameState, plant: PlantState, slot: StringName) -> String:
	if state == null:
		return ""
	var cutting := PropagationService.prune(plant, slot, IdFactory.make("cutting"))
	if cutting == null:
		return ""
	InventoryService.add_cutting(state.inventory, cutting)
	return cutting.item_id

static func plant_cutting(state: GameState, cutting_id: String, pot_id: String) -> bool:
	if state == null:
		return false
	var cutting := InventoryService.find_cutting(state.inventory, cutting_id)
	var pot := state.find_pot(pot_id)
	if cutting == null or pot == null:
		return false
	if not PropagationService.plant_cutting(cutting, pot, IdFactory.make("plant")):
		return false
	InventoryService.take_cutting(state.inventory, cutting_id)
	return true

static func plant_seed(state: GameState, seed_id: String, pot_id: String) -> bool:
	if state == null:
		return false
	var seed := InventoryService.find_seed(state.inventory, seed_id)
	var pot := state.find_pot(pot_id)
	if seed == null or pot == null:
		return false
	if not PropagationService.plant_seed(seed, pot, IdFactory.make("plant")):
		return false
	InventoryService.take_seed(state.inventory, seed_id)
	return true

static func graft_cutting(
	state: GameState,
	plant: PlantState,
	cutting_id: String,
	slot: StringName
) -> bool:
	if state == null:
		return false
	var cutting := InventoryService.find_cutting(state.inventory, cutting_id)
	if cutting == null:
		return false
	if not PropagationService.graft_cutting(cutting, plant, slot, IdFactory.make("branch")):
		return false
	InventoryService.take_cutting(state.inventory, cutting_id)
	return true

static func create_seed_from_fruit(state: GameState, fruit_id: String) -> String:
	if state == null:
		return ""
	var fruit := InventoryService.find_fruit(state.inventory, fruit_id)
	if fruit == null:
		return ""
	var seed := PropagationService.seed_from_fruit(fruit, IdFactory.make("seed"))
	if seed == null:
		return ""
	InventoryService.take_fruit(state.inventory, fruit_id)
	InventoryService.add_seed(state.inventory, seed)
	return seed.item_id
