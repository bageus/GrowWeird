class_name FertilizerUseService
extends RefCounted

static func apply(
	plant: PlantState,
	fertilizer: FertilizerDefinition,
	mutations: Array[MutationDefinition]
) -> Array[Dictionary]:
	if plant == null or fertilizer == null or not plant.alive:
		return []
	_apply_care_effects(plant, fertilizer)
	return MutationEngine.apply_fertilizer(plant, fertilizer, mutations)

static func _apply_care_effects(plant: PlantState, fertilizer: FertilizerDefinition) -> void:
	var nutrition_gain := float(fertilizer.care_effects.get("nutrition", 0.18))
	plant.nutrition = clampf(plant.nutrition + nutrition_gain, 0.0, 1.0)
	if fertilizer.care_effects.has("health"):
		plant.health = clampf(
			plant.health + float(fertilizer.care_effects["health"]),
			0.0,
			1.0
		)
