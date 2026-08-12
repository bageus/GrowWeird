class_name SaveMapper
extends RefCounted

static func to_dictionary(state: GameState) -> Dictionary:
	var pots: Array[Dictionary] = []
	for pot in state.pots:
		pots.append(_pot_to_dictionary(pot))
	return {
		"schema_version": state.schema_version,
		"money": state.money,
		"active_pot_id": state.active_pot_id,
		"last_saved_unix": state.last_saved_unix,
		"pots": pots,
	}

static func from_dictionary(data: Dictionary) -> GameState:
	var state := GameState.new()
	state.schema_version = int(data.get("schema_version", GameState.SCHEMA_VERSION))
	state.money = int(data.get("money", 0))
	state.active_pot_id = String(data.get("active_pot_id", ""))
	state.last_saved_unix = int(data.get("last_saved_unix", 0))
	for value in data.get("pots", []):
		if value is Dictionary:
			state.pots.append(_pot_from_dictionary(value))
	return state

static func _pot_to_dictionary(pot: PotState) -> Dictionary:
	return {
		"pot_id": pot.pot_id,
		"soil_moisture": pot.soil_moisture,
		"light_mode": int(pot.light_mode),
		"window_open": pot.window_open,
		"plant": null if pot.plant == null else _plant_to_dictionary(pot.plant),
	}

static func _pot_from_dictionary(data: Dictionary) -> PotState:
	var pot := PotState.new()
	pot.pot_id = String(data.get("pot_id", ""))
	pot.soil_moisture = float(data.get("soil_moisture", 0.5))
	pot.light_mode = int(data.get("light_mode", PotState.LightMode.DIFFUSED)) as PotState.LightMode
	pot.window_open = bool(data.get("window_open", false))
	var plant_data: Variant = data.get("plant")
	if plant_data is Dictionary:
		pot.plant = _plant_from_dictionary(plant_data)
	return pot

static func _plant_to_dictionary(plant: PlantState) -> Dictionary:
	var branches := {}
	for slot in BranchState.VALID_SLOTS:
		var branch := plant.branch_at(slot)
		branches[String(slot)] = null if branch == null else _branch_to_dictionary(branch)
	return {
		"instance_id": plant.instance_id,
		"custom_name": plant.custom_name,
		"species_id": String(plant.species_id),
		"age_seconds": plant.age_seconds,
		"growth_ratio": plant.growth_ratio,
		"health": plant.health,
		"alive": plant.alive,
		"mutation_energy": _plain_dictionary(plant.mutation_energy),
		"branches": branches,
		"rng_state": plant.rng_state,
	}

static func _plant_from_dictionary(data: Dictionary) -> PlantState:
	var plant := PlantState.new()
	plant.instance_id = String(data.get("instance_id", ""))
	plant.custom_name = String(data.get("custom_name", ""))
	plant.species_id = StringName(data.get("species_id", ""))
	plant.age_seconds = float(data.get("age_seconds", 0.0))
	plant.growth_ratio = float(data.get("growth_ratio", 0.0))
	plant.health = float(data.get("health", 1.0))
	plant.alive = bool(data.get("alive", true))
	plant.mutation_energy = _plain_dictionary(data.get("mutation_energy", {}))
	plant.rng_state = int(data.get("rng_state", 0))
	var branch_data: Dictionary = data.get("branches", {})
	for slot in BranchState.VALID_SLOTS:
		var value: Variant = branch_data.get(String(slot))
		plant.branches[String(slot)] = _branch_from_dictionary(value) if value is Dictionary else null
	return plant

static func _branch_to_dictionary(branch: BranchState) -> Dictionary:
	return {
		"branch_id": branch.branch_id,
		"slot": String(branch.slot),
		"source_species_id": String(branch.source_species_id),
		"ancestry": branch.ancestry.duplicate(),
		"traits": _plain_dictionary(branch.traits),
		"grafted": branch.grafted,
	}

static func _branch_from_dictionary(data: Dictionary) -> BranchState:
	var branch := BranchState.new()
	branch.branch_id = String(data.get("branch_id", ""))
	branch.slot = StringName(data.get("slot", "center"))
	branch.source_species_id = StringName(data.get("source_species_id", ""))
	for ancestor in data.get("ancestry", []):
		branch.ancestry.append(String(ancestor))
	branch.traits = _plain_dictionary(data.get("traits", {}))
	branch.grafted = bool(data.get("grafted", false))
	return branch

static func _plain_dictionary(source: Dictionary) -> Dictionary:
	var result := {}
	for key in source:
		result[String(key)] = source[key]
	return result
