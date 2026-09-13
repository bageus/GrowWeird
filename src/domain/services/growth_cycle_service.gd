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

static func repair_state(state: GameState) -> void:
	if state == null: return
	for pot in state.pots:
		var plant := pot.plant as PlantState
		if plant == null: continue
		plant.growth_cycle_index = clampi(plant.growth_cycle_index, 0, LAST_CYCLE)
		if not is_finite(plant.growth_cycle_elapsed) or plant.growth_cycle_elapsed < 0.0:
			plant.growth_cycle_elapsed = 0.0
		if plant.branches.is_empty(): plant.initialize_native_branches()
		if plant.growth_ratio >= 0.999 and plant.growth_cycle_index < 8:
			plant.growth_cycle_index = 8
		elif plant.growth_ratio > 0.0 and plant.growth_cycle_index == 0:
			plant.growth_cycle_index = clampi(floori(plant.growth_ratio * 8.0), 1, 7)
		_sync_legacy_growth(plant)

static func advance(plant: PlantState, delta_seconds: float, _care_factor: float) -> bool:
	if plant == null or not plant.alive or delta_seconds <= 0.0:
		return false
	var speed := 2.0 if plant.boosted_growth_cycle == plant.growth_cycle_index else 1.0
	plant.growth_cycle_elapsed += delta_seconds * speed
	var changed := false
	while plant.growth_cycle_elapsed >= duration(plant.growth_cycle_index):
		plant.growth_cycle_elapsed -= duration(plant.growth_cycle_index)
		plant.finish_care_stage(plant.growth_cycle_index + 1)
		if plant.growth_cycle_index >= LAST_CYCLE:
			_restore_next_side_branch(plant)
			plant.growth_cycle_index = LAST_CYCLE if _has_missing_side_branch(plant) else 9
			if plant.growth_cycle_index == 9:
				plant.fruit_cycle_index += 1
		else:
			plant.growth_cycle_index += 1
		plant.boosted_growth_cycle = -1
		changed = true
	_sync_legacy_growth(plant)
	return changed

static func _restore_next_side_branch(plant: PlantState) -> void:
	for slot: StringName in [&"left", &"right"]:
		if plant.branch_at(slot) == null:
			plant.restore_native_branch(slot)
			return

static func _has_missing_side_branch(plant: PlantState) -> bool:
	return plant.branch_at(&"left") == null or plant.branch_at(&"right") == null

static func recovery_complete(plant: PlantState) -> bool:
	if plant == null:
		return false
	for slot in BranchState.VALID_SLOTS:
		if plant.branch_at(slot) == null:
			return false
	return true

static func branch_has_grown(plant: PlantState, slot: StringName) -> bool:
	if plant == null or plant.branch_at(slot) == null:
		return false
	match slot:
		&"left": return plant.growth_cycle_index >= 7
		&"right": return plant.growth_cycle_index >= 8
	return false

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
	if plant.growth_cycle_index >= 8:
		plant.growth_ratio = 1.0
	else:
		plant.growth_ratio = clampf((float(plant.growth_cycle_index) + progress(plant)) / 8.0, 0.0, 1.0)
