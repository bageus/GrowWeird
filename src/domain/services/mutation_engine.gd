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
		var energy := float(plant.mutation_energy.get(String(definition.trigger_axis), 0.0))
		if energy >= definition.threshold:
			result.append(definition)
	return result

static func _apply_definition(
	plant: PlantState,
	definition: MutationDefinition,
	rng: RandomNumberGenerator
) -> Dictionary:
	var branches := plant.existing_branches()
	if definition.target_scope != &"branch" or branches.is_empty():
		return {}

	var branch := branches[rng.randi_range(0, branches.size() - 1)]
	if not definition.repeatable and branch.trait_level(definition.trait_id) > 0:
		return {}

	var axis_key := String(definition.trigger_axis)
	plant.mutation_energy[axis_key] = maxf(
		0.0,
		float(plant.mutation_energy.get(axis_key, 0.0)) - definition.threshold
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
