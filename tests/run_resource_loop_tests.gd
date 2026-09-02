extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	_test_cutting_sale()
	_test_seed_sale()
	_test_item_recycling()
	_test_compost_uses_normal_fertilizer_path()
	if _failures.is_empty():
		print("GrowWeird resource loop tests passed")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)

func _test_cutting_sale() -> void:
	var registry := _registry()
	var rules := GameRules.new()
	var state := GameState.new()
	var plant := _plant("cutting-sale")
	plant.branch_at(&"left").add_trait(&"thorns", 2)
	var cutting := PropagationService.prune(plant, &"left", "cutting-sale-item")
	InventoryService.add_cutting(state.inventory, cutting)
	var expected := ResourceActions.item_value(state, &"cutting", cutting.item_id, registry, rules)
	var amount := ResourceActions.sell_item(state, &"cutting", cutting.item_id, registry, rules)
	_expect(expected > 0 and amount == expected, "resource: cutting sale should use its valuation")
	_expect(state.money == amount, "resource: cutting sale should credit money")
	_expect(InventoryService.find_cutting(state.inventory, cutting.item_id) == null, "resource: sold cutting should be consumed")

func _test_seed_sale() -> void:
	var registry := _registry()
	var rules := GameRules.new()
	var state := GameState.new()
	var seed_state := SeedState.new()
	seed_state.item_id = "seed-sale-item"
	seed_state.genome = GeneticsService.fresh_species_snapshot(&"shade_fern")
	seed_state.genome.traits["fungi"] = 3
	seed_state.genome.ancestry = ["parent-a", "parent-b"]
	InventoryService.add_seed(state.inventory, seed_state)
	var expected := ResourceActions.item_value(state, &"seed", seed_state.item_id, registry, rules)
	var amount := ResourceActions.sell_item(state, &"seed", seed_state.item_id, registry, rules)
	_expect(expected > 0 and amount == expected, "resource: seed sale should use genome value")
	_expect(state.money == amount, "resource: seed sale should credit money")
	_expect(InventoryService.find_seed(state.inventory, seed_state.item_id) == null, "resource: sold seed should be consumed")

func _test_item_recycling() -> void:
	var rules := GameRules.new()
	var state := GameState.new()
	var seed_state := SeedState.new()
	seed_state.item_id = "seed-compost"
	seed_state.genome = GeneticsService.fresh_species_snapshot(&"starter_sprout")
	InventoryService.add_seed(state.inventory, seed_state)
	var seed_yield := ResourceActions.recycle_item(state, &"seed", seed_state.item_id, rules)
	_expect(seed_yield == rules.seed_compost_yield, "resource: seed compost yield mismatch")
	_expect(InventoryService.find_seed(state.inventory, seed_state.item_id) == null, "resource: composted seed should be destroyed")

	var plant := _plant("cutting-compost")
	var cutting := PropagationService.prune(plant, &"right", "cutting-compost-item")
	InventoryService.add_cutting(state.inventory, cutting)
	var cutting_yield := ResourceActions.recycle_item(state, &"cutting", cutting.item_id, rules)
	_expect(cutting_yield == rules.cutting_compost_yield, "resource: cutting compost yield mismatch")
	_expect(InventoryService.find_cutting(state.inventory, cutting.item_id) == null, "resource: composted cutting should be destroyed")

	var fruit := FruitState.new()
	fruit.item_id = "fruit-compost"
	fruit.genome = GeneticsService.fresh_species_snapshot(&"starter_sprout")
	InventoryService.add_fruit(state.inventory, fruit)
	var fruit_yield := ResourceActions.recycle_item(state, &"fruit", fruit.item_id, rules)
	_expect(fruit_yield == rules.fruit_compost_yield, "resource: fruit compost yield mismatch")
	_expect(InventoryService.find_fruit(state.inventory, fruit.item_id) == null, "resource: composted fruit should be destroyed")
	state.inventory.misc["dead_mouse"] = 1
	var misc_yield := ResourceActions.recycle_item(state, &"misc", "dead_mouse", rules)
	_expect(misc_yield == rules.misc_compost_yield, "resource: misc compost yield mismatch")
	_expect(not state.inventory.misc.has("dead_mouse"), "resource: ground misc item should be destroyed")

	var total := seed_yield + cutting_yield + fruit_yield + misc_yield
	_expect(InventoryService.fertilizer_count(state.inventory, RecyclingService.COMPOST_ID) == total, "resource: compost stack should equal recycled material")

func _test_compost_uses_normal_fertilizer_path() -> void:
	var registry := _registry()
	var state := GameState.new()
	var plant := _plant("compost-use")
	plant.health = 0.5
	InventoryService.add_fertilizer(state.inventory, RecyclingService.COMPOST_ID, 1)
	var result := FertilizerActions.use_inventory(state, plant, RecyclingService.COMPOST_ID, registry)
	_expect(bool(result.get("success", false)), "resource: compost should use normal fertilizer action")
	_expect(InventoryService.fertilizer_count(state.inventory, RecyclingService.COMPOST_ID) == 0, "resource: used compost should leave inventory")
	_expect(plant.health > 0.5, "resource: compost care effect should be applied through fertilizer service")
	state.inventory.misc["dead_mouse"] = 1
	var nutrition_before := plant.nutrition
	result = FertilizerActions.use_inventory(state, plant, &"dead_mouse", registry, &"misc")
	_expect(bool(result.get("success", false)) and not state.inventory.misc.has("dead_mouse"), "resource: used misc fertilizer should leave inventory")
	_expect(plant.nutrition > nutrition_before, "resource: used misc fertilizer should feed the plant")

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

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
