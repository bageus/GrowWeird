extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	_test_growth_stages()
	_test_cared_for_adult_survives_long_term()
	_test_neglected_plant_dies_permanently()
	_test_native_branch_regrows_in_exact_slot()
	_test_inactive_pot_branch_regrows_without_refresh()
	_test_regrowth_waits_for_adulthood()
	_test_graft_cancels_native_regrowth()
	_test_regrowth_save_round_trip()
	_test_v3_migrates_through_current_schema()
	_test_species_silhouettes_are_distinct()
	_test_low_vitality_droops_geometry()
	_test_regrowth_is_exposed_to_presentation()
	_test_pruned_branch_skips_current_fruit_cycle()
	_test_fruit_cycle_restarts_after_last_harvest()
	_test_cycle_duration_is_independent_of_care()
	_test_flowering_waits_for_branch_recovery()
	_test_seed_visual_frame_round_trip()
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
	_expect(branch != null and branch.traits.is_empty(), "regrowth: native regrowth must not recreate removed branch-local traits")
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

func _test_inactive_pot_branch_regrows_without_refresh() -> void:
	var registry := _registry(); var species := registry.get_plant(&"starter_sprout"); var state := GameState.new()
	var active := _comfortable_pot("active"); var inactive := _comfortable_pot("inactive")
	active.plant.growth_ratio = 1.0; inactive.plant.growth_ratio = 1.0; inactive.plant.cut_branch(&"right")
	inactive.plant.growth_cycle_index = GrowthCycleService.LAST_CYCLE
	state.pots = [active, inactive]; state.active_pot_id = active.pot_id
	var policy := SimulationPolicy.realtime(); policy.advance_environment = false; policy.advance_health = false
	PlantSimulationService.advance(state, species.native_regrowth_seconds, registry, GameRules.new(), policy)
	_expect(inactive.plant.branch_at(&"right") != null, "regrowth: inactive pot must finish branch growth without switching or manual refresh")

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
	pot.plant.regrowth_fruit_cycles["left"] = 4
	pot.plant.fruit_cycle_index = 3
	pot.plant.branch_at(&"center").fruit_cycle_eligible = 4
	state.pots = [pot]
	state.active_pot_id = pot.pot_id
	var restored := SaveMapper.from_dictionary(SaveMapper.to_dictionary(state))
	_expect(restored.schema_version == GameState.SCHEMA_VERSION, "regrowth save: schema should stay current")
	_expect(restored.pots[0].plant.branch_at(&"left") == null, "regrowth save: empty slot should remain empty")
	_expect(absf(restored.pots[0].plant.regrowth_progress_at(&"left") - 0.42) < 0.001, "regrowth save: partial progress was lost")
	_expect(restored.pots[0].plant.fruit_cycle_index == 3 and restored.pots[0].plant.branch_at(&"center").fruit_cycle_eligible == 4, "fruit cycle: save round trip lost cycle eligibility")
	_expect(int(restored.pots[0].plant.regrowth_fruit_cycles.get("left", 0)) == 4, "fruit cycle: pending regrowth cycle was not persisted")

func _test_v3_migrates_through_current_schema() -> void:
	var legacy := {
		"schema_version": 3,
		"pots": [{"plant": {"branches": {"left": null, "center": null, "right": null}}}],
	}
	var migrated := SaveMigrator.migrate(legacy)
	var plant_data: Dictionary = migrated["pots"][0]["plant"]
	_expect(int(migrated.get("schema_version", 0)) == GameState.SCHEMA_VERSION, "migration: v3 save should reach current schema")
	_expect(plant_data.has("regrowth_progress") and plant_data["regrowth_progress"].is_empty(), "migration: v4 step must add empty regrowth progress")

func _test_species_silhouettes_are_distinct() -> void:
	var registry := _registry()
	var plant := _plant("silhouette")
	plant.growth_ratio = 0.85
	var size := Vector2(620.0, 500.0)
	var starter := PlantVisualAssembler.build(size, plant, registry.get_plant(&"starter_sprout"))
	var fern := PlantVisualAssembler.build(size, plant, registry.get_plant(&"shade_fern"))
	var sun := PlantVisualAssembler.build(size, plant, registry.get_plant(&"sun_creeper"))
	var starter_center: Dictionary = starter["slots"]["center"]
	var fern_center: Dictionary = fern["slots"]["center"]
	var starter_left: Dictionary = starter["slots"]["left"]
	var fern_left: Dictionary = fern["slots"]["left"]
	var sun_left: Dictionary = sun["slots"]["left"]
	_expect((fern_center["end"] as Vector2).y > (starter_center["end"] as Vector2).y, "silhouette: shade fern should be visibly shorter")
	_expect((fern_left["end"] as Vector2).x < (starter_left["end"] as Vector2).x, "silhouette: shade fern should spread wider than starter")
	_expect((sun_left["end"] as Vector2).x < (starter_left["end"] as Vector2).x, "silhouette: sun creeper should spread wider than starter")

func _test_low_vitality_droops_geometry() -> void:
	var registry := _registry()
	var species := registry.get_plant(&"starter_sprout")
	var plant := _plant("droop")
	plant.growth_ratio = 0.9
	plant.health = 1.0
	var healthy := PlantVisualAssembler.build(Vector2(620.0, 500.0), plant, species)
	plant.health = 0.2
	var wilted := PlantVisualAssembler.build(Vector2(620.0, 500.0), plant, species)
	var healthy_left: Dictionary = healthy["slots"]["left"]
	var wilted_left: Dictionary = wilted["slots"]["left"]
	var healthy_center: Dictionary = healthy["slots"]["center"]
	var wilted_center: Dictionary = wilted["slots"]["center"]
	_expect((wilted_left["end"] as Vector2).y > (healthy_left["end"] as Vector2).y, "lifecycle visual: wilted side branches should droop")
	_expect((wilted_center["end"] as Vector2).y > (healthy_center["end"] as Vector2).y, "lifecycle visual: wilted center stem should sag")

func _test_regrowth_is_exposed_to_presentation() -> void:
	var registry := _registry()
	var plant := _plant("bud")
	plant.growth_ratio = 1.0
	plant.cut_branch(&"right")
	plant.set_regrowth_progress(&"right", 0.55)
	var layout := PlantVisualAssembler.build(Vector2(620.0, 500.0), plant, registry.get_plant(&"starter_sprout"))
	var right: Dictionary = layout["slots"]["right"]
	_expect(right["branch"] == null, "regrowth visual: regrowing slot must remain mechanically empty until complete")
	_expect(absf(float(right["regrowth"]) - 0.55) < 0.001, "regrowth visual: presentation descriptor lost bud progress")

func _test_pruned_branch_skips_current_fruit_cycle() -> void:
	var registry := _registry(); var species := registry.get_plant(&"starter_sprout")
	var state := GameState.new(); var pot := _comfortable_pot("cycle-prune"); pot.plant.growth_ratio = 1.0; pot.plant.growth_cycle_index = 10; state.pots = [pot]
	FruitLifecycleService.advance(state, 1.0, registry)
	var first_progress := pot.plant.branch_at(&"center").fruit_growth.progress
	_expect(is_equal_approx(first_progress, pot.plant.branch_at(&"right").fruit_growth.progress), "fruit cycle: all branches must flower simultaneously")
	pot.plant.cut_branch(&"left")
	_expect(TreeGrowthPreview.stage_for(pot.plant) == 11, "regrowth asset: pruned plant must use the no-stump asset after refresh")
	BranchRegrowthService.advance(pot.plant, species.native_regrowth_seconds, species, 1.0)
	var regrown := pot.plant.branch_at(&"left")
	_expect(regrown != null and regrown.fruit_growth == null, "fruit cycle: branch must regrow without its removed flower or fruit")
	FruitLifecycleService.advance(state, species.fruit_ripen_seconds, registry)
	_expect(regrown.fruit_growth == null, "fruit cycle: regrown branch must skip flowering and fruit in the current cycle")

func _test_fruit_cycle_restarts_after_last_harvest() -> void:
	var registry := _registry(); var state := GameState.new(); var pot := _comfortable_pot("cycle-harvest")
	pot.plant.growth_ratio = 1.0; pot.plant.growth_cycle_index = 11; state.pots = [pot]; FruitLifecycleService.advance(state, 1.0, registry)
	_expect(FruitLifecycleService.harvest(pot.plant, &"left", "fruit-left") != null, "fruit cycle: first ready fruit should harvest")
	_expect(pot.plant.fruit_cycle_index == 0 and pot.plant.branch_at(&"left").fruit_growth == null, "fruit cycle: first harvested branch must wait while other fruit remains")
	_expect(FruitLifecycleService.harvest(pot.plant, &"center", "fruit-center") != null, "fruit cycle: center fruit should harvest")
	_expect(FruitLifecycleService.harvest(pot.plant, &"right", "fruit-right") != null, "fruit cycle: last fruit should harvest")
	_expect(pot.plant.fruit_cycle_index == 1, "fruit cycle: last harvested fruit must restart the shared cycle")
	FruitLifecycleService.advance(state, 1.0, registry)
	_expect(pot.plant.growth_cycle_index == GrowthCycleService.LAST_CYCLE, "fruit cycle: harvesting the last fruit must start branch recovery")
	for branch in pot.plant.existing_branches(): _expect(branch.fruit_growth == null, "fruit cycle: recovery must not immediately create new fruit")

func _test_cycle_duration_is_independent_of_care() -> void:
	var plant := _plant("fixed-duration")
	GrowthCycleService.advance(plant, 29.0, 0.0)
	_expect(plant.growth_cycle_index == 0, "growth cycle: seed stage must last its full fixed duration")
	GrowthCycleService.advance(plant, 1.0, 0.0)
	_expect(plant.growth_cycle_index == 1, "growth cycle: poor care must not stretch the configured stage duration")

func _test_flowering_waits_for_branch_recovery() -> void:
	var plant := _plant("strict-recovery")
	plant.growth_cycle_index = GrowthCycleService.LAST_CYCLE
	plant.cut_branch(&"left")
	GrowthCycleService.advance(plant, GrowthCycleService.duration(GrowthCycleService.LAST_CYCLE), 1.0)
	_expect(plant.growth_cycle_index == GrowthCycleService.LAST_CYCLE, "growth cycle: flowering started before every branch regrew")
	plant.initialize_native_branches()
	GrowthCycleService.advance(plant, 1.0, 1.0)
	_expect(plant.growth_cycle_index == 9, "growth cycle: flowering must start after recovery finishes")

func _test_seed_visual_frame_round_trip() -> void:
	var state := GameState.new()
	var seed_state := SeedState.new(); seed_state.item_id = "visual-seed"; seed_state.visual_frame = 7
	state.inventory.seeds.append(seed_state)
	var restored := SaveMapper.from_dictionary(SaveMapper.to_dictionary(state))
	_expect(restored.inventory.seeds[0].visual_frame == 7, "seed art: saved random atlas frame was not restored")

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
