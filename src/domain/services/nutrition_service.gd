class_name NutritionService
extends RefCounted

const SEED_CAPACITY := 20.0
const SPROUT_CAPACITY := 40.0
const YOUNG_TREE_CAPACITY := 60.0
const CENTER_TREE_CAPACITY := 70.0
const SIDE_BRANCH_CAPACITY := 10.0
const FLOWER_BONUS := 15.0
const FRUIT_BONUS := 25.0
const DECAY_FRACTION_PER_MINUTE := 0.05

static func capacity(plant: PlantState) -> float:
	if plant == null:
		return 0.0
	var cycle := plant.growth_cycle_index
	var result := SEED_CAPACITY
	if cycle >= 1 and cycle <= 4:
		result = SPROUT_CAPACITY
	elif cycle == 5:
		result = YOUNG_TREE_CAPACITY
	elif cycle >= 6:
		result = CENTER_TREE_CAPACITY
		if GrowthCycleService.branch_has_grown(plant, &"left"):
			result += SIDE_BRANCH_CAPACITY
		if GrowthCycleService.branch_has_grown(plant, &"right"):
			result += SIDE_BRANCH_CAPACITY
	if cycle == 9:
		result += FLOWER_BONUS
	elif (cycle == 10 or cycle == 11) and plant.has_active_fruits():
		result += FRUIT_BONUS
	return result

static func ratio(plant: PlantState) -> float:
	var maximum := capacity(plant)
	if plant == null or maximum <= 0.0:
		return 0.0
	return clampf(plant.nutrition / maximum, 0.0, 1.0)

static func clamp_to_capacity(plant: PlantState) -> void:
	if plant == null:
		return
	plant.nutrition = clampf(plant.nutrition, 0.0, capacity(plant))

static func consume(plant: PlantState, seconds: float) -> void:
	if plant == null or seconds <= 0.0:
		return
	clamp_to_capacity(plant)
	var units_per_second := capacity(plant) * DECAY_FRACTION_PER_MINUTE / 60.0
	plant.nutrition = maxf(0.0, plant.nutrition - units_per_second * seconds)

static func add(plant: PlantState, units: float) -> float:
	if plant == null or units <= 0.0:
		return 0.0
	var before := plant.nutrition
	plant.nutrition = minf(capacity(plant), plant.nutrition + units)
	return plant.nutrition - before

static func correct_stage_fertilizer_gain(plant: PlantState) -> float:
	# Store fertilizers always restore half of the CURRENT dynamic capacity.
	return ceilf(capacity(plant) * 0.5)

static func ground_fertilizer_gain(plant: PlantState, extra: float = 0.0) -> float:
	if plant == null:
		return 0.0
	var cycle := plant.growth_cycle_index
	var base := 7.0
	if cycle == 0:
		base = 10.0
	elif cycle >= 1 and cycle <= 4:
		base = 9.0
	elif cycle == 5:
		base = 8.0
	elif cycle >= 6 and cycle <= 8:
		base = 7.0
	elif cycle == 9:
		base = 6.0
	elif cycle == 10 or cycle == 11:
		base = 5.0
	return base + maxf(0.0, extra)

static func item_gain(plant: PlantState, fertilizer: FertilizerDefinition) -> float:
	if plant == null or fertilizer == null:
		return 0.0
	var points := float(fertilizer.care_effects.get("nutrition_points", 0.0))
	# 100 in the balance table means a complete refill (green elixir).
	if points >= 100.0:
		return capacity(plant)
	return clampf(points, 0.0, 5.0)

static func fertilizer_gain(plant: PlantState, fertilizer: FertilizerDefinition, kind: StringName) -> float:
	if plant == null or fertilizer == null:
		return 0.0
	if kind == ResourceActions.MISC:
		return item_gain(plant, fertilizer)
	var target := StringName(fertilizer.care_effects.get("growth_cycle", &""))
	if not String(target).is_empty() and GrowthCycleService.matches_target(plant.growth_cycle_index, target):
		return correct_stage_fertilizer_gain(plant)
	return ground_fertilizer_gain(plant)
