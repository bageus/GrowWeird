extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	_test_growth_stages()
	_test_cared_for_adult_survives_long_term()
	_test_neglected_plant_dies_permanently()
	_test_native_branch_regrows_in_exact_slot()
	_test_regrowth_waits_for_adulthood()
	_test_graft_cancels_native_regrowth()
	_test_regrowth_save_round_trip()
	_test_v3_migrates_to_v4()
	if _failures.is_empty():
		print("GrowWeird lifecycle tests passed")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)

func _test_growth_stages() -> void:
	var registry := _registry()
	var species := registry.get_plant(&"starter_sprout")
	var plant := _plant("stage")
	plant.growth_ratio = species.sprout_stage_end * 0.5
	_expect(PlantLifecycleService.growth_stage(plant, species) == &"sprout", "lifecycle: early growth should be sprout")
	plant.growth_ratio = (species.sprout_stage_end + species.adult_growth_threshold) * 0.5
	_expect(PlantLifecycleService.growth_stage(plant, species) == &"juvenile", "lifecycle: middle growth should be juvenile")
	plant.growth_ratio = species.adult_growth_threshold
	_expect(PlantLifecycleService.growth_stage(plant, species) == &"adult", "lifecycle: threshold plant should be adult")

func _test_cared_for_adult_survives_long_term() -> void:
	var registry := _registry()
	var state := GameState.new()
	var pot := _comfortable_pot("immortal")
	pot.plant.growth_ratio = 1.0
	pot.plant.health = 0.92
	state.pots = [pot]
	var rules := GameRules.new()
	var policy := SimulationPolicy.realtime()
	policy.advance_environment = false
	for _hour in range(48):
		PlantSimulationService.advance(state, 3600.0, registry, rules, policy)
		pot.soil_moisture = 0.5
	_expect(pot.plant.alive, "lifecycle: cared-for adult should remain alive indefinitely")
	_expect(pot.plant.health > 0.9, "lifecycle: comfortable adult should recover instead of aging to death")
	_expect(pot.plant.growth_ratio == 1.0, "lifecycle: adult growth should remain capped")

func _test_neglected_plant_dies_permanently() -> void:
	var registry := _registry()
	var state := GameState.new()
	var pot := PotState.new()
	pot.pot_id = "neglect"
	pot.soil_moisture = 0.0
	pot.light_mode = PotState.LightMode.DARK
	pot.plant = _plant("neglected")
	state.pots = [pot]
	var rules := GameRules.new()
	PlantSimulationService.advance(state, 700.0, registry, rules)
	_expect(not pot.plant.alive, "lifecycle: prolonged critical care should permanently kill plant")
	var health_after_death := pot.plant.health
	PlantSimulationService.advance(state, 700.0, registry, rules)
	_expect(not pot.plant.alive and pot.plant.health == health_after_death, "lifecycle: dead plant must not resume simulation")
	_expect(PlantLifecycleService.condition(pot.plant, rules) == &"dead", "lifecycle: dead condition should be derived explicitly")

func _test_native_branch_regrows_in_exact_slot() -> void:
	var registry := _registry()
	var species := registry.get_plant(&"starter_sprout")
	var plant := _plant("regrow")
	plant.growth_ratio = 1.0
	plant.health = 1.0
	var removed := plant.cut_branch(&"left")
	_expect(removed != null and plant.branch_at(&"left") == null, "regrowth: pruning should free exact left slot")
	var regrown := BranchRegrowthService.advance(plant, species.native_regrowth_seconds, species, 1.0)
	var branch := plant.branch_at(&"left")
	_expect(regrown.has(&"left"), "regrowth: mature healthy plant should restore empty slot")
	_expect(branch != null and branch.slot == &"left", "regrowth: restored branch must occupy exact original slot")
	_expect(branch != null and not branch.grafted, "regrowth: restored branch must be native")
	_expect(branch != null and branch.source_species_id == plant.species_id, "regrowth: native branch must belong to host species")
	_expect(plant.regrowth_progress_at(&"left") == 0.0, "regrowth: completed progress should clear")

func _test_regrowth_waits_for_adulthood() -> void:
	var registry := _registry()
	var species := registry.get_plant(&"starter_sprout")
	var plant := _plant("young-regrow")
	plant.growth_ratio = species.sprout_stage_end
	plant.cut_branch(&"right")
	BranchRegrowthService.advance(plant, species.native_regrowth_seconds * 4.0, species, 1.0)
	_expect(plant.branch_at(&"right") == null, "regrowth: juvenile plant must not regrow native branch yet")
	_expect(plant.regrowth_progress_at(&"right") == 0.0, "regrowth: juvenile wait must not bank progress")

func _test_graft_cancels_native_regrowth() -> void:
	var plant := _plant("graft-race")
	plant.cut_branch(&"center")
	plant.set_regrowth_progress(&"center", 0.73)
	var graft := BranchState.new()
	graft.branch_id = "graft-race:center:donor"
	graft.slot = &"center"
	graft.source_species_id = &"shade_fern"
	graft.grafted = true
	_expect(plant.attach_branch(graft, &"center"), "regrowth: graft should attach to free slot")
	_expect(plant.regrowth_progress_at(&"center") == 0.0, "regrowth: graft must cancel pending native regrowth")

func _test_regrowth_save_round_trip() -> void:
	var state := GameState.new()
	var pot := PotState.new()
	pot.pot_id = "save-regrowth"
	pot.plant = _plant("save-regrowth-plant")
	pot.plant.cut_branch(&"left")
	pot.plant.set_regrowth_progress(&"left", 0.42)
	state.pots = [pot]
	state.active_pot_id = pot.pot_id
	var restored := SaveMapper.from_dictionary(SaveMapper.to_dictionary(state))
	_expect(restored.schema_version == 4, "regrowth save: schema should be v4")
	_expect(restored.pots[0].plant.branch_at(&"left") == null, "regrowth save: empty slot should remain empty")
	_expect(absf(restored.pots[0].plant.regrowth_progress_at(&"left") - 0.42) < 0.001, "regrowth save: partial progress was lost")

func _test_v3_migrates_to_v4() -> void:
	var legacy := {
		"schema_version": 3,
		"pots": [{"plant": {"branches": {"left": null, "center": null, "right": null}}}],
	}
	var migrated := SaveMigrator.migrate(legacy)
	var plant_data: Dictionary = migrated["pots"][0]["plant"]
	_expect(int(migrated.get("schema_version", 0)) == 4, "migration: v3 save should become v4")
	_expect(plant_data.has("regrowth_progress") and plant_data["regrowth_progress"].is_empty(), "migration: v4 must add empty regrowth progress")

func _registry() -> ContentRegistry:
	var registry := ContentRegistry.new()
	registry.load_all()
	return registry

func _plant(id: String) -> PlantState:
	var plant := PlantState.new()
	plant.instance_id = id
	plant.species_id = &"starter_sprout"
	plant.initialize_native_branches()
	return plant

func _comfortable_pot(id: String) -> PotState:
	var pot := PotState.new()
	pot.pot_id = id
	pot.soil_moisture = 0.5
	pot.light_mode = PotState.LightMode.DIFFUSED
	pot.window_open = false
	pot.plant = _plant(id + "-plant")
	return pot

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
