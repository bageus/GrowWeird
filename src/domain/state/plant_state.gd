class_name PlantState
extends RefCounted

var instance_id: String = ""
var custom_name: String = ""
var species_id: StringName
var age_seconds: float = 0.0
var growth_ratio: float = 0.0
var health: float = 1.0
var alive: bool = true
var nutrition: float = 0.5
var care_stage_index: int = 0
var care_stage_score_sum: float = 0.0
var care_stage_sample_seconds: float = 0.0
var completed_care_scores: Array[float] = []
var mutation_energy: Dictionary = {}
var branches: Dictionary = {}
var regrowth_progress: Dictionary = {}
var rng_state: int = 0

func initialize_native_branches() -> void:
	branches.clear()
	regrowth_progress.clear()
	for slot in BranchState.VALID_SLOTS:
		var branch := BranchState.new()
		branch.branch_id = "%s:%s" % [instance_id, String(slot)]
		branch.slot = slot
		branch.source_species_id = species_id
		branch.ancestry = [instance_id]
		branches[String(slot)] = branch

func branch_at(slot: StringName) -> BranchState:
	var value: Variant = branches.get(String(slot))
	return value as BranchState

func has_free_slot(slot: StringName) -> bool:
	return BranchState.VALID_SLOTS.has(slot) and branch_at(slot) == null

func cut_branch(slot: StringName) -> BranchState:
	var branch := branch_at(slot)
	if branch == null:
		return null
	branches[String(slot)] = null
	set_regrowth_progress(slot, 0.0)
	return branch

func attach_branch(branch: BranchState, slot: StringName) -> bool:
	if branch == null or not has_free_slot(slot):
		return false
	branch.slot = slot
	branches[String(slot)] = branch
	clear_regrowth_progress(slot)
	return true

func existing_branches() -> Array[BranchState]:
	var result: Array[BranchState] = []
	for slot in BranchState.VALID_SLOTS:
		var branch := branch_at(slot)
		if branch != null:
			result.append(branch)
	return result

func regrowth_progress_at(slot: StringName) -> float:
	if not BranchState.VALID_SLOTS.has(slot):
		return 0.0
	return clampf(float(regrowth_progress.get(String(slot), 0.0)), 0.0, 1.0)

func set_regrowth_progress(slot: StringName, progress: float) -> void:
	if not BranchState.VALID_SLOTS.has(slot):
		return
	regrowth_progress[String(slot)] = clampf(progress, 0.0, 1.0)

func clear_regrowth_progress(slot: StringName) -> void:
	regrowth_progress.erase(String(slot))

func add_mutation_energy(axis: StringName, amount: float) -> void:
	var key := String(axis)
	mutation_energy[key] = float(mutation_energy.get(key, 0.0)) + amount

func record_care_sample(score: float, delta_seconds: float) -> void:
	care_stage_score_sum += clampf(score, 0.0, 1.0) * maxf(delta_seconds, 0.0)
	care_stage_sample_seconds += maxf(delta_seconds, 0.0)

func finish_care_stage(next_stage: int) -> void:
	if care_stage_sample_seconds > 0.0:
		completed_care_scores.append(care_stage_score_sum / care_stage_sample_seconds)
	care_stage_index = next_stage
	care_stage_score_sum = 0.0
	care_stage_sample_seconds = 0.0

func current_care_score() -> float:
	if care_stage_sample_seconds <= 0.0:
		return 1.0
	return clampf(care_stage_score_sum / care_stage_sample_seconds, 0.0, 1.0)
