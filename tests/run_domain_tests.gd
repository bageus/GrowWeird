extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	_test_pour_moistens_soil_one_stage()
	_test_seed_snapshot_is_immutable()
	_test_grafted_branch_creates_hybrid_genome()
	_test_offer_contains_three_unique_items()
	_test_multi_axis_mutation_consumes_requirements()
	_test_cutting_plant_and_graft_flow()
	_test_fruit_lifecycle_and_harvest()
	_test_plant_sale_frees_pot()
	_test_shop_transactions()
	_test_species_seed_unlock_progression()
	_test_save_round_trip_preserves_new_state()
	if _failures.is_empty():
		print("GrowWeird domain tests passed")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)

func _test_pour_moistens_soil_one_stage() -> void:
	var pot := PotState.new()
	var expected := [0.30, 0.48, 0.68, 0.86, 1.0, 1.0]
	var starting_values := [0.0, 0.20, 0.40, 0.60, 0.80, 1.0]
	for index in range(starting_values.size()):
		pot.soil_moisture = starting_values[index]
		var stage_before := pot.soil_moisture_stage()
		pot.moisten_soil_one_stage()
		_expect(is_equal_approx(pot.soil_moisture, expected[index]), "pour: soil moisture did not advance to the next stage")
		_expect(pot.soil_moisture_stage() == mini(stage_before + 1, 5), "pour: soil visual stage did not advance exactly once")

func _test_seed_snapshot_is_immutable() -> void:
	var plant := _plant("parent")
	plant.branch_at(&"left").add_trait(&"thorns", 2)
	var fruit := PropagationService.create_fruit(plant, &"left", "fruit-1")
	var seed := PropagationService.seed_from_fruit(fruit, "seed-1")
	plant.branch_at(&"left").add_trait(&"thorns", 5)
	_expect(seed != null, "seed snapshot: seed should be created")
	_expect(int(seed.genome.traits.get("thorns", 0)) == 2, "seed snapshot: later parent mutation changed existing seed")

func _test_grafted_branch_creates_hybrid_genome() -> void:
	var host := _plant("host")
	host.branch_at(&"left").add_trait(&"bloom", 1)
	host.cut_branch(&"center")
	var donor_genome := GenomeSnapshot.new()
	donor_genome.species_id = &"donor_species"
	donor_genome.ancestry = ["donor"]
	donor_genome.traits = {"thorns": 3}
	var donor := CuttingState.new()
	donor.item_id = "cutting-1"
	donor.genome = donor_genome
	var grafted := PropagationService.graft_cutting(donor, host, &"center", "graft-1")
	var fruit := PropagationService.create_fruit(host, &"center", "fruit-2")
	_expect(grafted, "hybrid fruit: graft should succeed in free center slot")
	_expect(fruit != null and fruit.hybrid, "hybrid fruit: grafted branch fruit must be hybrid")
	_expect(int(fruit.genome.traits.get("bloom", 0)) == 1, "hybrid fruit: host trait missing")
	_expect(int(fruit.genome.traits.get("thorns", 0)) == 3, "hybrid fruit: donor trait missing")

func _test_offer_contains_three_unique_items() -> void:
	var offer := FertilizerOfferState.new()
	FertilizerOfferService.initialize_rng(offer, 42)
	var rules := GameRules.new()
	rules.fertilizer_offer_count = 3
	var definitions: Array[FertilizerDefinition] = []
	for index in range(4):
		var definition := FertilizerDefinition.new()
		definition.id = StringName("fertilizer_%d" % index)
		definition.offer_weight = 1.0
		definitions.append(definition)
	var generated := FertilizerOfferService.advance(offer, 1.0, definitions, rules)
	var unique := {}
	for fertilizer_id in offer.offered_ids:
		unique[String(fertilizer_id)] = true
	_expect(generated, "fertilizer offer: expected an offer")
	_expect(offer.offered_ids.size() == 3, "fertilizer offer: expected exactly three items")
	_expect(unique.size() == 3, "fertilizer offer: items must be unique")

func _test_multi_axis_mutation_consumes_requirements() -> void:
	var plant := _plant("synergy")
	var fertilizer := FertilizerDefinition.new()
	fertilizer.id = &"synergy_feed"
	fertilizer.mutation_contributions = {"floral": 8.0, "predatory": 8.0}
	var mutation := MutationDefinition.new()
	mutation.id = &"lure_test"
	mutation.axis_requirements = {"floral": 8.0, "predatory": 8.0}
	mutation.trait_id = &"lure_bloom"
	var definitions: Array[MutationDefinition] = [mutation]
	var events := MutationEngine.apply_fertilizer(plant, fertilizer, definitions)
	_expect(events.size() == 1, "mutation synergy: combined requirements should resolve once")
	_expect(float(plant.mutation_energy.get("floral", -1.0)) == 0.0, "mutation synergy: floral energy was not consumed")
	_expect(float(plant.mutation_energy.get("predatory", -1.0)) == 0.0, "mutation synergy: predatory energy was not consumed")
	var found := false
	for branch in plant.existing_branches():
		found = found or branch.trait_level(&"lure_bloom") == 1
	_expect(found, "mutation synergy: result trait was not applied")

func _test_cutting_plant_and_graft_flow() -> void:
	var donor := _plant("donor")
	donor.branch_at(&"left").add_trait(&"thorns", 4)
	var cutting := PropagationService.prune(donor, &"left", "cutting-flow")
	var empty_pot := PotState.new()
	empty_pot.pot_id = "empty"
	var planted := PropagationService.plant_cutting(cutting, empty_pot, "child")
	_expect(planted and empty_pot.plant != null, "cutting flow: cutting should plant in empty pot")
	_expect(empty_pot.plant.branch_at(&"left").trait_level(&"thorns") == 4, "cutting flow: planted cutting lost inherited trait")
	var host := _plant("host-flow")
	_expect(not PropagationService.graft_cutting(cutting, host, &"right", "blocked"), "cutting flow: graft must fail when slot is occupied")
	host.cut_branch(&"right")
	_expect(PropagationService.graft_cutting(cutting, host, &"right", "graft-flow"), "cutting flow: graft should succeed after slot is freed")

func _test_fruit_lifecycle_and_harvest() -> void:
	var registry := ContentRegistry.new()
	registry.load_all()
	var state := GameState.new()
	var pot := PotState.new()
	pot.pot_id = "fruit-pot"
	pot.soil_moisture = 0.5
	pot.plant = _plant("fruit-plant")
	pot.plant.growth_ratio = 1.0
	state.pots = [pot]
	FruitLifecycleService.advance(state, 120.0, registry)
	var branch := pot.plant.branch_at(&"center")
	_expect(branch.fruit_growth != null and branch.fruit_growth.is_ready(), "fruit lifecycle: mature comfortable branch should ripen fruit")
	var harvested := FruitLifecycleService.harvest(pot.plant, &"center", "fruit-harvest")
	_expect(harvested != null, "fruit lifecycle: ripe fruit should harvest")
	_expect(branch.fruit_growth == null, "fruit lifecycle: harvesting must reset branch fruit cycle")

func _test_plant_sale_frees_pot() -> void:
	var registry := ContentRegistry.new()
	registry.load_all()
	var rules := GameRules.new()
	var state := GameState.new()
	var pot := PotState.new()
	pot.pot_id = "sale-pot"
	pot.plant = _plant("valuable")
	pot.plant.growth_ratio = 1.0
	pot.plant.branch_at(&"left").add_trait(&"thorns", 3)
	state.pots = [pot]
	var amount := EconomyActions.sell_plant(state, pot, registry, rules)
	_expect(amount > 0, "plant sale: expected positive value")
	_expect(pot.plant == null, "plant sale: pot must become empty")
	_expect(state.money == amount, "plant sale: money was not credited")

func _test_shop_transactions() -> void:
	var registry := ContentRegistry.new()
	registry.load_all()
	var state := GameState.new()
	state.money = 1000
	state.pots = [PotState.new(), PotState.new()]
	var rules := GameRules.new()
	var bought_fertilizer := ShopActions.buy_fertilizer(state, &"humus", registry)
	_expect(bought_fertilizer, "shop: fertilizer purchase should succeed")
	_expect(InventoryService.fertilizer_count(state.inventory, &"humus") == 1, "shop: fertilizer not added")
	var pot_id := ShopActions.buy_pot(state, rules)
	_expect(not pot_id.is_empty() and state.pots.size() == 3, "shop: new pot should be added")

func _test_species_seed_unlock_progression() -> void:
	var registry := ContentRegistry.new()
	registry.load_all()
	var state := GameState.new()
	state.money = 1000
	state.pots = [PotState.new(), PotState.new()]
	_expect(not ShopService.is_species_unlocked(state, registry.get_plant(&"shade_fern")), "species shop: shade fern should stay locked before lineage milestone")
	state.progression.complete(&"make_seed")
	_expect(ShopService.is_species_unlocked(state, registry.get_plant(&"shade_fern")), "species shop: shade fern should unlock after seed milestone with two pots")
	_expect(not ShopService.is_species_unlocked(state, registry.get_plant(&"sun_creeper")), "species shop: sun creeper should stay locked before graft milestone and third pot")
	var shade_seed_id := ShopActions.buy_species_seed(state, &"shade_fern", registry)
	var shade_seed := InventoryService.find_seed(state.inventory, shade_seed_id)
	_expect(shade_seed != null and shade_seed.genome.species_id == &"shade_fern", "species shop: purchased seed genome is wrong")
	_expect(ShopActions.buy_species_seed(state, &"sun_creeper", registry).is_empty(), "species shop: locked seed purchase should fail")
	state.progression.complete(&"make_graft")
	state.pots.append(PotState.new())
	var sun_seed_id := ShopActions.buy_species_seed(state, &"sun_creeper", registry)
	_expect(not sun_seed_id.is_empty(), "species shop: sun creeper should unlock after graft milestone plus third pot")

func _test_save_round_trip_preserves_new_state() -> void:
	var state := GameState.new()
	state.money = 123
	var pot := PotState.new()
	pot.pot_id = "pot-save"
	pot.plant = _plant("save-plant")
	var growing := GrowingFruitState.new()
	growing.progress = 0.61
	growing.hybrid = true
	pot.plant.branch_at(&"left").fruit_growth = growing
	state.pots = [pot]
	state.active_pot_id = pot.pot_id
	state.fertilizer_offer.offered_ids = [&"humus", &"dead_mouse", &"banana_peel"]
	state.fertilizer_offer.seconds_until_offer = 12.5
	var cutting := CuttingState.new()
	cutting.item_id = "cutting-save"
	cutting.source_plant_id = pot.plant.instance_id
	cutting.source_branch_id = pot.plant.branch_at(&"left").branch_id
	cutting.genome = GeneticsService.snapshot_branch(pot.plant.branch_at(&"left"))
	InventoryService.add_cutting(state.inventory, cutting)
	InventoryService.add_fertilizer(state.inventory, &"humus", 2)
	var restored := SaveMapper.from_dictionary(SaveMapper.to_dictionary(state))
	_expect(restored.money == 123, "save round trip: money changed")
	_expect(restored.fertilizer_offer.offered_ids.size() == 3, "save round trip: offer lost")
	_expect(InventoryService.fertilizer_count(restored.inventory, &"humus") == 2, "save round trip: fertilizer stack lost")
	_expect(restored.inventory.cuttings.size() == 1, "save round trip: cutting lost")
	var restored_fruit := restored.pots[0].plant.branch_at(&"left").fruit_growth
	_expect(restored_fruit != null and absf(restored_fruit.progress - 0.61) < 0.001, "save round trip: growing fruit progress lost")
	_expect(restored_fruit.hybrid, "save round trip: growing fruit hybrid marker lost")

func _plant(id: String) -> PlantState:
	var plant := PlantState.new()
	plant.instance_id = id
	plant.species_id = &"starter_sprout"
	plant.initialize_native_branches()
	return plant

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
