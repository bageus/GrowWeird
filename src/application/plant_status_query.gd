class_name PlantStatusQuery
extends RefCounted

static func build(
	plant: PlantState,
	species: PlantSpeciesDefinition,
	rules: GameRules
) -> Dictionary:
	if plant == null or species == null or rules == null:
		return {}
	return {
		"growth_stage": PlantLifecycleService.growth_stage(plant, species),
		"condition": PlantLifecycleService.condition(plant, rules),
		"alive": plant.alive,
	}
