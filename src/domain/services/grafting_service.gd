class_name GraftingService
extends RefCounted

static func can_graft(plant: PlantState, slot: StringName) -> bool:
	return plant != null and plant.alive and plant.has_free_slot(slot)

static func graft(plant: PlantState, branch: BranchState, slot: StringName) -> bool:
	if branch == null or not can_graft(plant, slot):
		return false
	branch.grafted = true
	return plant.attach_branch(branch, slot)
