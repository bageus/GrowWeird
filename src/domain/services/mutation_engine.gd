class_name MutationEngine
extends RefCounted

static func apply_fertilizer(
	plant: PlantState,
	fertilizer: FertilizerDefinition,
	mutations: Array[MutationDefinition]
) -> Array[Dictionary]:
	if plant == null or fertilizer == null or not plant.alive:
		return []

	for axis in fertilizer.mutation_contributions:
		plant.add_mutation_energy(StringName(axis), float(fertilizer.mutation_contributions[axis]))

	var rng := _rng_for(plant)
	var events: Array[Dictionary] = []
	while true:
		var eligible := _eligible_mutations(plant, mutations)
		if eligible.is_empty():
			break
		var definition: MutationDefinition = eligible[rng.randi_range(0, eligible.size() - 1)]
		var event := _apply_definition(plant, definition, rng)
		if event.is_empty():
			break
		events.append(event)

	plant.rng_state = rng.state
	return events

static func _eligible_mutations(
	plant: PlantState,
	mutations: Array[MutationDefinition]
) -> Array[MutationDefinition]:
	var result: Array[MutationDefinition] = []
	for definition in mutations:
		if definition == null or definition.target_scope != &"branch":
			continue
		if not _has_candidate_branch(plant, definition):
			continue
		var requirements := definition.requirements()
		if requirements.is_empty():
			continue
		var meets_all := true
		for axis in requirements:
			var energy := float(plant.mutation_energy.get(String(axis), 0.0))
			if energy < float(requirements[axis]):
				meets_all = false
				break
		if meets_all:
			result.append(definition)
	return result

static func _has_candidate_branch(plant: PlantState, definition: MutationDefinition) -> bool:
	for branch in plant.existing_branches():
		if definition.repeatable or branch.trait_level(definition.trait_id) <= 0:
			return true
	return false

static func _apply_definition(
	plant: PlantState,
	definition: MutationDefinition,
	rng: RandomNumberGenerator
) -> Dictionary:
	var candidates: Array[BranchState] = []
	for branch in plant.existing_branches():
		if definition.repeatable or branch.trait_level(definition.trait_id) <= 0:
			candidates.append(branch)
	if candidates.is_empty():
		return {}

	var branch := candidates[rng.randi_range(0, candidates.size() - 1)]
	for axis in definition.requirements():
		var key := String(axis)
		plant.mutation_energy[key] = maxf(
			0.0,
			float(plant.mutation_energy.get(key, 0.0)) - float(definition.requirements()[axis])
		)
	branch.add_trait(definition.trait_id, definition.level_increment)
	return {
		"mutation_id": String(definition.id),
		"trait_id": String(definition.trait_id),
		"branch_id": branch.branch_id,
		"level": branch.trait_level(definition.trait_id),
	}

static func _rng_for(plant: PlantState) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	if plant.rng_state == 0:
		rng.seed = int(plant.instance_id.hash())
	else:
		rng.state = plant.rng_state
	return rng
