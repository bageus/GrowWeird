class_name FruitActions
extends RefCounted

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
