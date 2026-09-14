class_name PlantState
extends RefCounted

var instance_id: String = ""
var custom_name: String = ""
var species_id: StringName
var genetic_rarity: StringName = &"common"
var age_seconds: float = 0.0
var growth_ratio: float = 0.0
var growth_cycle_index: int = 0
var growth_cycle_elapsed: float = 0.0
var boosted_growth_cycle: int = -1
var health: float = 1.0
var alive: bool = true
var nutrition: float = 10.0
var care_stage_index: int = 0
var care_stage_score_sum: float = 0.0
var care_stage_sample_seconds: float = 0.0
var completed_care_scores: Array[float] = []
var mutation_energy: Dictionary = {}
var branches: Dictionary = {}
var regrowth_progress: Dictionary = {}
var regrowth_fruit_cycles: Dictionary = {}
var fruit_cycle_index: int = 0
var rng_state: int = 0

func initialize_native_branches() -> void:
	branches.clear()
	regrowth_progress.clear()
	regrowth_fruit_cycles.clear()
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

func restore_native_branch(slot: StringName) -> bool:
	if slot not in [&"left", &"right"] or branch_at(slot) != null:
		return false
	var branch := BranchState.new()
	branch.branch_id = "%s:%s:regrown:%d" % [instance_id, String(slot), fruit_cycle_index]
	branch.slot = slot
	branch.source_species_id = species_id
	branch.ancestry = [instance_id]
	branch.fruit_cycle_eligible = regrowth_fruit_cycle_at(slot)
	return attach_branch(branch, slot)

func has_free_slot(slot: StringName) -> bool:
	return BranchState.VALID_SLOTS.has(slot) and branch_at(slot) == null

func cut_branch(slot: StringName) -> BranchState:
	var branch := branch_at(slot)
	if branch == null:
		return null
	branches[String(slot)] = null
	set_regrowth_progress(slot, 0.0)
	regrowth_fruit_cycles[String(slot)] = fruit_cycle_index + 1
	return branch

func removed_last_active_fruit(removed: BranchState) -> bool:
	if removed == null or removed.fruit_growth == null: return false
	for existing in existing_branches():
		if existing.fruit_growth != null: return false
	return true

func has_active_fruits() -> bool:
	for branch in existing_branches():
		if branch.fruit_growth != null: return true
	return false

func attach_branch(branch: BranchState, slot: StringName) -> bool:
	if branch == null or not has_free_slot(slot):
		return false
	branch.slot = slot
	if has_active_fruits(): branch.fruit_cycle_eligible = maxi(branch.fruit_cycle_eligible, fruit_cycle_index + 1)
	branches[String(slot)] = branch
	clear_regrowth_progress(slot)
	regrowth_fruit_cycles.erase(String(slot))
	return true

func existing_branches() -> Array[BranchState]:
	var result: Array[BranchState] = []
	for slot in BranchState.VALID_SLOTS:
		var branch := branch_at(slot)
		if branch != null:
			result.append(branch)
	return result

func add_mutation_energy(axis: StringName, amount: float) -> void:
	if amount <= 0.0:
		return
	var key := String(axis)
	mutation_energy[key] = maxf(0.0, float(mutation_energy.get(key, 0.0)) + amount)

func mutation_value(axis: StringName) -> float:
	return maxf(0.0, float(mutation_energy.get(String(axis), 0.0)))

func consume_mutation_energy(axis: StringName, amount: float) -> bool:
	if amount <= 0.0:
		return true
	var key := String(axis)
	var available := mutation_value(axis)
	if available < amount:
		return false
	mutation_energy[key] = available - amount
	return true

func set_regrowth_progress(slot: StringName, value: float) -> void:
	regrowth_progress[String(slot)] = clampf(value, 0.0, 1.0)

func regrowth_progress_at(slot: StringName) -> float:
	return clampf(float(regrowth_progress.get(String(slot), 0.0)), 0.0, 1.0)

func clear_regrowth_progress(slot: StringName) -> void:
	regrowth_progress.erase(String(slot))

func regrowth_fruit_cycle_at(slot: StringName) -> int:
	return maxi(0, int(regrowth_fruit_cycles.get(String(slot), 0)))

func advance_fruit_cycle() -> void:
	fruit_cycle_index += 1

func next_random_u64() -> int:
	var state := rng_state
	if state == 0:
		state = hash(instance_id)
	state = int((state * 6364136223846793005 + 1442695040888963407) & 0x7fffffffffffffff)
	rng_state = state
	return state

func random_float() -> float:
	return float(next_random_u64() % 1000000) / 1000000.0
