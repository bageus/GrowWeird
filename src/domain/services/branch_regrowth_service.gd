class_name BranchRegrowthService
extends RefCounted

static func advance(
	plant: PlantState,
	delta_seconds: float,
	species: PlantSpeciesDefinition,
	_overall_comfort: float
) -> Array[StringName]:
	var regrown: Array[StringName] = []
	if plant == null or species == null or not plant.alive or delta_seconds <= 0.0:
		return regrown
	if not species.native_regrowth_enabled:
		return regrown
	if not PlantLifecycleService.is_adult(plant, species):
		return regrown
	# During cycle testing, branch recovery must not be blocked by care gauges.
	var rate_factor := 1.0
	for slot in BranchState.VALID_SLOTS:
		if plant.branch_at(slot) != null:
			plant.clear_regrowth_progress(slot)
			continue
		var progress := plant.regrowth_progress_at(slot)
		progress += delta_seconds * rate_factor / maxf(1.0, species.native_regrowth_seconds)
		if progress < 1.0:
			plant.set_regrowth_progress(slot, progress)
			continue
		var branch := _native_branch(plant, slot)
		if plant.attach_branch(branch, slot):
			regrown.append(slot)
	return regrown

static func _native_branch(plant: PlantState, slot: StringName) -> BranchState:
	var branch := BranchState.new()
	var age_stamp := maxi(1, int(round(plant.age_seconds * 1000.0)))
	branch.branch_id = "%s:%s:regrown:%d" % [plant.instance_id, String(slot), age_stamp]
	branch.slot = slot
	branch.source_species_id = plant.species_id
	branch.ancestry = [plant.instance_id]
	branch.grafted = false
	branch.fruit_cycle_eligible = plant.regrowth_fruit_cycle_at(slot)
	return branch
