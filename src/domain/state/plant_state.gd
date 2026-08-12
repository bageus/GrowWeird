class_name PlantState
extends RefCounted

var instance_id: String = ""
var custom_name: String = ""
var species_id: StringName
var age_seconds: float = 0.0
var growth_ratio: float = 0.0
var health: float = 1.0
var alive: bool = true
var mutation_energy: Dictionary = {}
var branches: Dictionary = {}
var rng_state: int = 0

func initialize_native_branches() -> void:
	branches.clear()
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
	return branch

func attach_branch(branch: BranchState, slot: StringName) -> bool:
	if branch == null or not has_free_slot(slot):
		return false
	branch.slot = slot
	branches[String(slot)] = branch
	return true

func existing_branches() -> Array[BranchState]:
	var result: Array[BranchState] = []
	for slot in BranchState.VALID_SLOTS:
		var branch := branch_at(slot)
		if branch != null:
			result.append(branch)
	return result

func add_mutation_energy(axis: StringName, amount: float) -> void:
	var key := String(axis)
	mutation_energy[key] = float(mutation_energy.get(key, 0.0)) + amount
