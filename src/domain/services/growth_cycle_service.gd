class_name GrowthCycleService
extends RefCounted

const LAST_CYCLE := 12
const DURATIONS := [30.0, 60.0, 120.0, 180.0, 240.0, 300.0, 360.0, 420.0, 480.0, 540.0, 600.0, 600.0, 600.0]

static func duration(cycle: int) -> float:
	return DURATIONS[clampi(cycle, 0, LAST_CYCLE)]

static func progress(plant: PlantState) -> float:
	if plant == null:
		return 0.0
	return clampf(plant.growth_cycle_elapsed / duration(plant.growth_cycle_index), 0.0, 1.0)

static func advance(plant: PlantState, delta_seconds: float, care_factor: float) -> bool:
	if plant == null or not plant.alive or delta_seconds <= 0.0:
		return false
	var speed := 2.0 if plant.boosted_growth_cycle == plant.growth_cycle_index else 1.0
	plant.growth_cycle_elapsed += delta_seconds * speed * clampf(care_factor, 0.1, 1.0)
	var changed := false
	while plant.growth_cycle_elapsed >= duration(plant.growth_cycle_index):
		plant.growth_cycle_elapsed -= duration(plant.growth_cycle_index)
		plant.finish_care_stage(plant.growth_cycle_index + 1)
		plant.growth_cycle_index = 9 if plant.growth_cycle_index >= LAST_CYCLE else plant.growth_cycle_index + 1
		plant.boosted_growth_cycle = -1
		changed = true
	_sync_legacy_growth(plant)
	return changed

static func activate_stage_fertilizer(plant: PlantState, target: StringName) -> bool:
	if plant == null or not matches_target(plant.growth_cycle_index, target):
		return false
	plant.boosted_growth_cycle = plant.growth_cycle_index
	plant.nutrition = clampf(plant.nutrition, 0.45, 0.65)
	return true

static func matches_target(cycle: int, target: StringName) -> bool:
	match target:
		&"seed": return cycle == 0
		&"sprout": return cycle >= 1 and cycle <= 4
		&"tree": return cycle >= 5 and cycle <= 8
		&"flower": return cycle == 9
		&"fruit": return cycle == 10 or cycle == 11
		&"restart": return cycle == 12
	return false

static func _sync_legacy_growth(plant: PlantState) -> void:
	plant.growth_ratio = clampf((float(mini(plant.growth_cycle_index, 8)) + progress(plant)) / 9.0, 0.0, 1.0)
