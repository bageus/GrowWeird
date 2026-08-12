extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	_test_seed_snapshot_is_immutable()
	_test_grafted_branch_creates_hybrid_genome()
	_test_offer_contains_three_unique_items()
	if _failures.is_empty():
		print("GrowWeird domain tests passed")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)

func _test_seed_snapshot_is_immutable() -> void:
	var plant := _plant("parent")
	plant.branch_at(&"left").add_trait(&"thorns", 2)
	var fruit := PropagationService.create_fruit(plant, &"left", "fruit-1")
	var seed := PropagationService.seed_from_fruit(fruit, "seed-1")
	plant.branch_at(&"left").add_trait(&"thorns", 5)
	_expect(seed != null, "seed snapshot: seed should be created")
	_expect(
		int(seed.genome.traits.get("thorns", 0)) == 2,
		"seed snapshot: later parent mutation changed existing seed"
	)

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

	var grafted := PropagationService.graft_cutting(
		donor,
		host,
		&"center",
		"graft-1"
	)
	var fruit := PropagationService.create_fruit(host, &"center", "fruit-2")
	_expect(grafted, "hybrid fruit: graft should succeed in free center slot")
	_expect(fruit != null and fruit.hybrid, "hybrid fruit: grafted branch fruit must be hybrid")
	_expect(
		int(fruit.genome.traits.get("bloom", 0)) == 1,
		"hybrid fruit: host trait missing"
	)
	_expect(
		int(fruit.genome.traits.get("thorns", 0)) == 3,
		"hybrid fruit: donor trait missing"
	)

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

func _plant(id: String) -> PlantState:
	var plant := PlantState.new()
	plant.instance_id = id
	plant.species_id = &"starter_sprout"
	plant.initialize_native_branches()
	return plant

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
