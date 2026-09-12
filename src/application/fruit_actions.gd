class_name FruitActions
extends RefCounted

static func pick_flower(state: GameState, plant: PlantState, slot: StringName) -> bool:
	if state == null or plant == null or plant.growth_cycle_index != 9: return false
	var branch := plant.branch_at(slot)
	if branch == null or branch.fruit_cycle_eligible > plant.fruit_cycle_index: return false
	branch.fruit_cycle_eligible = plant.fruit_cycle_index + 1
	InventoryService.add_misc(state.inventory, "picked_flower")
	return true

static func harvest(
	state: GameState,
	plant: PlantState,
	slot: StringName
) -> String:
	if state == null or plant == null:
		return ""
	var item_id := IdFactory.make("fruit")
	var fruit := FruitLifecycleService.harvest(plant, slot, item_id)
	if fruit == null:
		return ""
	InventoryService.add_fruit(state.inventory, fruit)
	return item_id
