class_name FruitActions
extends RefCounted

const PICKED_FLOWER_PREFIX := "picked_flower:"

static func pick_flower(state: GameState, plant: PlantState, slot: StringName) -> bool:
	if state == null or plant == null or plant.growth_cycle_index != 9: return false
	var branch := plant.branch_at(slot)
	if branch == null or branch.fruit_cycle_eligible > plant.fruit_cycle_index: return false
	plant.ensure_visual_lines()
	var mutation_frame := PlantAtlasArt.flower_mutation_column(branch)
	var item_id := "%s%d:%d" % [PICKED_FLOWER_PREFIX, plant.flower_visual_line, mutation_frame]
	branch.fruit_cycle_eligible = plant.fruit_cycle_index + 1
	InventoryService.add_misc(state.inventory, item_id)
	return true

static func picked_flower_frame(item_id: String) -> Vector2i:
	if not item_id.begins_with(PICKED_FLOWER_PREFIX): return Vector2i(-1, -1)
	var parts := item_id.trim_prefix(PICKED_FLOWER_PREFIX).split(":")
	if parts.size() != 2: return Vector2i(-1, -1)
	return Vector2i(int(parts[0]), int(parts[1]))

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
	NutritionService.clamp_to_capacity(plant)
	InventoryService.add_fruit(state.inventory, fruit)
	return item_id
