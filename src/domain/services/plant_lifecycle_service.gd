class_name PlantLifecycleService
extends RefCounted

const STAGE_SPROUT: StringName = &"sprout"
const STAGE_JUVENILE: StringName = &"juvenile"
const STAGE_ADULT: StringName = &"adult"

const CONDITION_HEALTHY: StringName = &"healthy"
const CONDITION_STRESSED: StringName = &"stressed"
const CONDITION_WILTED: StringName = &"wilted"
const CONDITION_CRITICAL: StringName = &"critical"
const CONDITION_DEAD: StringName = &"dead"

static func growth_stage(
	plant: PlantState,
	species: PlantSpeciesDefinition
) -> StringName:
	if plant == null or species == null:
		return STAGE_SPROUT
	var growth := clampf(plant.growth_ratio, 0.0, 1.0)
	if growth < species.sprout_stage_end:
		return STAGE_SPROUT
	if growth < species.adult_growth_threshold:
		return STAGE_JUVENILE
	return STAGE_ADULT

static func condition(plant: PlantState, rules: GameRules) -> StringName:
	if plant == null or not plant.alive:
		return CONDITION_DEAD
	var health := clampf(plant.health, 0.0, 1.0)
	if health <= rules.critical_health_threshold:
		return CONDITION_CRITICAL
	if health <= rules.wilted_health_threshold:
		return CONDITION_WILTED
	if health <= rules.stressed_health_threshold:
		return CONDITION_STRESSED
	return CONDITION_HEALTHY

static func is_adult(plant: PlantState, species: PlantSpeciesDefinition) -> bool:
	return growth_stage(plant, species) == STAGE_ADULT

static func vitality(plant: PlantState) -> float:
	if plant == null or not plant.alive:
		return 0.0
	return clampf(plant.health, 0.0, 1.0)
