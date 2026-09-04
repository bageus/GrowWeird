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
		"rewarded_ad_claims": state.rewarded_ad_claims.duplicate(),
		"pots": pots,
		"inventory": SaveItemMapper.inventory_to_dictionary(state.inventory),
		"fertilizer_offer": _offer_to_dictionary(state.fertilizer_offer),
		"progression": _progression_to_dictionary(state.progression),
	}

static func from_dictionary(data: Dictionary) -> GameState:
	var state := GameState.new()
	state.schema_version = int(data.get("schema_version", GameState.SCHEMA_VERSION))
	state.money = int(data.get("money", 0))
	state.active_pot_id = String(data.get("active_pot_id", ""))
	state.last_saved_unix = int(data.get("last_saved_unix", 0))
	for claim_time in data.get("rewarded_ad_claims", []):
		state.rewarded_ad_claims.append(maxi(0, int(claim_time)))
	state.inventory = SaveItemMapper.inventory_from_dictionary(data.get("inventory", {}))
	state.fertilizer_offer = _offer_from_dictionary(data.get("fertilizer_offer", {}))
	state.progression = _progression_from_dictionary(data.get("progression", {}))
	for value in data.get("pots", []):
		if value is Dictionary:
			state.pots.append(_pot_from_dictionary(value))
	return state

static func _pot_to_dictionary(pot: PotState) -> Dictionary:
	var plant_data: Variant = null
	if pot.plant != null:
		plant_data = _plant_to_dictionary(pot.plant)
	return {
		"pot_id": pot.pot_id,
		"soil_moisture": pot.soil_moisture,
		"consecutive_sprays": pot.consecutive_sprays,
		"light_mode": pot.light_mode,
		"window_open": pot.window_open,
		"plant": plant_data,
	}

static func _pot_from_dictionary(data: Dictionary) -> PotState:
	var pot := PotState.new()
	pot.pot_id = String(data.get("pot_id", ""))
	pot.soil_moisture = clampf(float(data.get("soil_moisture", 0.5)), 0.0, 1.0)
	pot.consecutive_sprays = clampi(int(data.get("consecutive_sprays", 0)), 0, PotState.SPRAYS_PER_STAGE - 1)
	pot.light_mode = clampi(int(data.get("light_mode", PotState.LightMode.DIFFUSED)), 0, PotState.LightMode.size() - 1)
	pot.window_open = bool(data.get("window_open", false))
	var plant_data: Variant = data.get("plant")
	if plant_data is Dictionary:
		pot.plant = _plant_from_dictionary(plant_data)
	return pot

static func _plant_to_dictionary(plant: PlantState) -> Dictionary:
	var branches := {}
	for slot in BranchState.VALID_SLOTS:
		var branch := plant.branch_at(slot)
		if branch == null:
			branches[String(slot)] = null
		else:
			branches[String(slot)] = _branch_to_dictionary(branch)
	return {
		"instance_id": plant.instance_id,
		"custom_name": plant.custom_name,
		"species_id": String(plant.species_id),
		"age_seconds": plant.age_seconds,
		"growth_ratio": plant.growth_ratio,
		"growth_cycle_index": plant.growth_cycle_index,
		"growth_cycle_elapsed": plant.growth_cycle_elapsed,
		"boosted_growth_cycle": plant.boosted_growth_cycle,
		"health": plant.health,
		"alive": plant.alive,
		"nutrition": plant.nutrition,
		"care_stage_index": plant.care_stage_index,
		"care_stage_score_sum": plant.care_stage_score_sum,
		"care_stage_sample_seconds": plant.care_stage_sample_seconds,
		"completed_care_scores": plant.completed_care_scores.duplicate(),
		"mutation_energy": _plain_dictionary(plant.mutation_energy),
		"branches": branches,
		"regrowth_progress": _plain_dictionary(plant.regrowth_progress),
		"regrowth_fruit_cycles": _plain_dictionary(plant.regrowth_fruit_cycles),
		"fruit_cycle_index": plant.fruit_cycle_index,
		"rng_state": plant.rng_state,
	}

static func _plant_from_dictionary(data: Dictionary) -> PlantState:
	var plant := PlantState.new()
	plant.instance_id = String(data.get("instance_id", ""))
	plant.custom_name = String(data.get("custom_name", ""))
	plant.species_id = StringName(data.get("species_id", ""))
	plant.age_seconds = maxf(0.0, float(data.get("age_seconds", 0.0)))
	plant.growth_ratio = clampf(float(data.get("growth_ratio", 0.0)), 0.0, 1.0)
	plant.growth_cycle_index = clampi(int(data.get("growth_cycle_index", 0)), 0, GrowthCycleService.LAST_CYCLE)
	plant.growth_cycle_elapsed = maxf(0.0, float(data.get("growth_cycle_elapsed", 0.0)))
	plant.boosted_growth_cycle = int(data.get("boosted_growth_cycle", -1))
	plant.health = clampf(float(data.get("health", 1.0)), 0.0, 1.0)
	plant.alive = bool(data.get("alive", true)) and plant.health > 0.0
	plant.nutrition = clampf(float(data.get("nutrition", 0.5)), 0.0, 1.0)
	plant.care_stage_index = maxi(0, int(data.get("care_stage_index", 0)))
	plant.care_stage_score_sum = maxf(0.0, float(data.get("care_stage_score_sum", 0.0)))
	plant.care_stage_sample_seconds = maxf(0.0, float(data.get("care_stage_sample_seconds", 0.0)))
	for score in data.get("completed_care_scores", []):
		plant.completed_care_scores.append(clampf(float(score), 0.0, 1.0))
	plant.mutation_energy = _plain_dictionary(data.get("mutation_energy", {}))
	plant.regrowth_progress = _plain_dictionary(data.get("regrowth_progress", {}))
	plant.regrowth_fruit_cycles = _plain_dictionary(data.get("regrowth_fruit_cycles", {}))
	plant.fruit_cycle_index = maxi(0, int(data.get("fruit_cycle_index", 0)))
	plant.rng_state = int(data.get("rng_state", 0))
	var branch_data: Variant = data.get("branches", {})
	for slot in BranchState.VALID_SLOTS:
		var value: Variant = null
		if branch_data is Dictionary:
			value = branch_data.get(String(slot))
		if value is Dictionary:
			plant.branches[String(slot)] = _branch_from_dictionary(value)
		else:
			plant.branches[String(slot)] = null
		if plant.branch_at(slot) != null:
			plant.clear_regrowth_progress(slot)
			plant.regrowth_fruit_cycles.erase(String(slot))
		else:
			plant.set_regrowth_progress(slot, plant.regrowth_progress_at(slot))
	return plant

static func _branch_to_dictionary(branch: BranchState) -> Dictionary:
	return {
		"branch_id": branch.branch_id,
		"slot": String(branch.slot),
		"source_species_id": String(branch.source_species_id),
		"ancestry": branch.ancestry.duplicate(),
		"traits": _plain_dictionary(branch.traits),
		"grafted": branch.grafted,
		"fruit_growth": _fruit_growth_to_dictionary(branch.fruit_growth),
		"fruit_cycle_eligible": branch.fruit_cycle_eligible,
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
	branch.fruit_growth = _fruit_growth_from_dictionary(data.get("fruit_growth"))
	branch.fruit_cycle_eligible = maxi(0, int(data.get("fruit_cycle_eligible", 0)))
	return branch

static func _fruit_growth_to_dictionary(fruit: GrowingFruitState) -> Variant:
	if fruit == null:
		return null
	return {"progress": fruit.progress, "hybrid": fruit.hybrid}

static func _fruit_growth_from_dictionary(source: Variant) -> GrowingFruitState:
	if not (source is Dictionary):
		return null
	var fruit := GrowingFruitState.new()
	fruit.progress = clampf(float(source.get("progress", 0.0)), 0.0, 1.0)
	fruit.hybrid = bool(source.get("hybrid", false))
	return fruit

static func _offer_to_dictionary(offer: FertilizerOfferState) -> Dictionary:
	var offered: Array[String] = []
	for fertilizer_id in offer.offered_ids:
		offered.append(String(fertilizer_id))
	return {
		"offered_ids": offered,
		"seconds_until_offer": offer.seconds_until_offer,
		"skip_count": offer.skip_count,
		"rng_state": offer.rng_state,
	}

static func _offer_from_dictionary(source: Variant) -> FertilizerOfferState:
	var offer := FertilizerOfferState.new()
	if not (source is Dictionary):
		return offer
	var data: Dictionary = source
	for fertilizer_id in data.get("offered_ids", []):
		offer.offered_ids.append(StringName(fertilizer_id))
	offer.seconds_until_offer = maxf(0.0, float(data.get("seconds_until_offer", 0.0)))
	offer.skip_count = maxi(0, int(data.get("skip_count", 0)))
	offer.rng_state = int(data.get("rng_state", 0))
	return offer

static func _progression_to_dictionary(progression: ProgressionState) -> Dictionary:
	var completed: Array[String] = []
	for id in progression.completed_ids:
		completed.append(String(id))
	return {
		"progress_by_id": _plain_dictionary(progression.progress_by_id),
		"completed_ids": completed,
		"skip_onboarding": progression.skip_onboarding,
	}

static func _progression_from_dictionary(source: Variant) -> ProgressionState:
	var progression := ProgressionState.new()
	if not (source is Dictionary):
		return progression
	progression.progress_by_id = _plain_dictionary(source.get("progress_by_id", {}))
	for id in source.get("completed_ids", []):
		var milestone := StringName(id)
		if not progression.completed_ids.has(milestone):
			progression.completed_ids.append(milestone)
	progression.skip_onboarding = bool(source.get("skip_onboarding", false))
	return progression

static func _plain_dictionary(source: Variant) -> Dictionary:
	var result := {}
	if not (source is Dictionary):
		return result
	for key in source:
		result[String(key)] = source[key]
	return result
