class_name GeneticsService
extends RefCounted

static func snapshot_branch(branch: BranchState) -> GenomeSnapshot:
	if branch == null:
		return null
	var genome := GenomeSnapshot.new()
	genome.species_id = branch.source_species_id
	genome.ancestry = branch.ancestry.duplicate()
	genome.traits = branch.traits.duplicate(true)
	genome.branch_traits[String(branch.slot)] = branch.traits.duplicate(true)
	return genome

static func snapshot_plant(plant: PlantState) -> GenomeSnapshot:
	if plant == null:
		return null
	var genome := GenomeSnapshot.new()
	genome.species_id = plant.species_id
	_append_unique(genome.ancestry, plant.instance_id)
	for slot in BranchState.VALID_SLOTS:
		var branch := plant.branch_at(slot)
		if branch == null:
			continue
		genome.branch_traits[String(slot)] = branch.traits.duplicate(true)
		_merge_traits(genome.traits, branch.traits)
		for ancestor in branch.ancestry:
			_append_unique(genome.ancestry, ancestor)
	return genome

static func hybrid_snapshot(plant: PlantState, bearing_branch: BranchState) -> GenomeSnapshot:
	var host := snapshot_plant(plant)
	var donor := snapshot_branch(bearing_branch)
	return combine(host, donor)

static func combine(first: GenomeSnapshot, second: GenomeSnapshot) -> GenomeSnapshot:
	if first == null:
		return second.duplicate_snapshot() if second != null else null
	var result := first.duplicate_snapshot()
	if second == null:
		return result
	_merge_traits(result.traits, second.traits)
	for slot in second.branch_traits:
		var key := String(slot)
		var target: Dictionary = result.branch_traits.get(key, {}).duplicate(true)
		_merge_traits(target, second.branch_traits[slot])
		result.branch_traits[key] = target
	for ancestor in second.ancestry:
		_append_unique(result.ancestry, ancestor)
	return result

static func plant_from_genome(genome: GenomeSnapshot, instance_id: String) -> PlantState:
	if genome == null or genome.is_empty():
		return null
	var plant := PlantState.new()
	plant.instance_id = instance_id
	plant.species_id = genome.species_id
	plant.initialize_native_branches()
	for branch in plant.existing_branches():
		branch.traits = genome.traits.duplicate(true)
		branch.ancestry = genome.ancestry.duplicate()
		_append_unique(branch.ancestry, instance_id)
	return plant

static func graft_branch_from_genome(
	genome: GenomeSnapshot,
	branch_id: String,
	slot: StringName
) -> BranchState:
	if genome == null or genome.is_empty() or not BranchState.VALID_SLOTS.has(slot):
		return null
	var branch := BranchState.new()
	branch.branch_id = branch_id
	branch.slot = slot
	branch.source_species_id = genome.species_id
	branch.ancestry = genome.ancestry.duplicate()
	branch.traits = genome.traits.duplicate(true)
	branch.grafted = true
	return branch

static func _merge_traits(target: Dictionary, source: Dictionary) -> void:
	for trait_id in source:
		var key := String(trait_id)
		target[key] = maxi(int(target.get(key, 0)), int(source[trait_id]))

static func _append_unique(values: Array[String], value: String) -> void:
	if not value.is_empty() and not values.has(value):
		values.append(value)
