class_name FertilizerUseService
extends RefCounted

static func apply(
	plant: PlantState,
	fertilizer: FertilizerDefinition,
	mutations: Array[MutationDefinition],
	kind: StringName = ResourceActions.FERTILIZER
) -> Array[Dictionary]:
	if plant == null or fertilizer == null or not plant.alive:
		return []
	_apply_care_effects(plant, fertilizer, kind)
	return MutationEngine.apply_fertilizer(plant, fertilizer, mutations)

static func _apply_care_effects(plant: PlantState, fertilizer: FertilizerDefinition, kind: StringName) -> void:
	var target := StringName(fertilizer.care_effects.get("growth_cycle", &""))
	if not String(target).is_empty() and GrowthCycleService.matches_target(plant.growth_cycle_index, target):
		GrowthCycleService.activate_stage_fertilizer(plant, target)
	NutritionService.add(plant, NutritionService.fertilizer_gain(plant, fertilizer, kind))
	if fertilizer.care_effects.has("health"):
		plant.health = clampf(
			plant.health + float(fertilizer.care_effects["health"]),
			0.0,
			1.0
		)
