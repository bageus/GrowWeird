class_name CareGaugeService
extends RefCounted

const GROWTH_STAGE_COUNT := 8

static func evaluate_or_preview(pot: PotState, species: PlantSpeciesDefinition) -> Dictionary:
	if pot == null:
		return {}
	if pot.plant != null and species != null:
		return evaluate(pot, species)
	return {
		"overall": 1.0,
		"water": component(pot.soil_moisture, 0.35, 0.7),
		"food": component(0.5, 0.3, 0.75),
		"environment": component(pot.light_level(), 0.35, 0.75),
		"stage_index": 0,
		"stage_progress": 0.0,
		"stage_quality": 1.0,
	}

static func evaluate(pot: PotState, species: PlantSpeciesDefinition) -> Dictionary:
	if pot == null or pot.plant == null or species == null:
		return {}
	var plant := pot.plant
	var water := component(pot.soil_moisture, species.moisture_min, species.moisture_max)
	var food := component(plant.nutrition, species.nutrition_min, species.nutrition_max)
	var environment := component(pot.light_level(), species.light_min, species.light_max)
	var air := air_component(pot.window_open, species.open_window_preference)
	environment["score"] = minf(float(environment["score"]), float(air["score"]))
	if int(air["direction"]) != 0 and int(environment["direction"]) == 0:
		environment["direction"] = air["direction"]
	var overall := minf(float(water["score"]), minf(float(food["score"]), float(environment["score"])))
	return {
		"overall": overall,
		"water": water,
		"food": food,
		"environment": environment,
		"stage_index": plant.growth_cycle_index,
		"stage_progress": GrowthCycleService.progress(plant),
		"stage_quality": plant.current_care_score(),
	}

static func component(value: float, minimum: float, maximum: float) -> Dictionary:
	var direction := 0
	var score := 1.0
	if value < minimum:
		direction = -1
		score = clampf(1.0 - (minimum - value) / maxf(minimum, 0.001), 0.0, 1.0)
	elif value > maximum:
		direction = 1
		score = clampf(1.0 - (value - maximum) / maxf(1.0 - maximum, 0.001), 0.0, 1.0)
	return {"value": clampf(value, 0.0, 1.0), "minimum": minimum, "maximum": maximum, "score": score, "direction": direction}

static func air_component(window_open: bool, preference: int) -> Dictionary:
	if preference == 0 or window_open == (preference > 0):
		return {"score": 1.0, "direction": 0}
	return {"score": 0.35, "direction": -1 if preference > 0 else 1}

static func stage_index(growth_ratio: float) -> int:
	return mini(int(floor(clampf(growth_ratio, 0.0, 1.0) * GROWTH_STAGE_COUNT)), GROWTH_STAGE_COUNT - 1)

static func stage_progress(growth_ratio: float) -> float:
	if growth_ratio >= 1.0:
		return 1.0
	return fmod(clampf(growth_ratio, 0.0, 1.0) * GROWTH_STAGE_COUNT, 1.0)
