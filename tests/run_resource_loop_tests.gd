extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	_test_cutting_sale()
	_test_seed_sale()
	_test_item_recycling()
	_test_compost_uses_normal_fertilizer_path()
	_test_dynamic_nutrition_capacity()
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

	InventoryService.add_fertilizer(state.inventory, &"test_fertilizer", 1)
	var fertilizer_yield := ResourceActions.recycle_item(state, &"fertilizer", "test_fertilizer", rules)
	_expect(fertilizer_yield == 1 and InventoryService.fertilizer_count(state.inventory, &"test_fertilizer") == 0, "resource: fertilizer inventory items must be grindable")
	var total := seed_yield + cutting_yield + fruit_yield + misc_yield + fertilizer_yield
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
	plant.nutrition = 10.0
	state.inventory.misc["dead_mouse"] = 1
	var nutrition_before := plant.nutrition
	result = FertilizerActions.use_inventory(state, plant, &"dead_mouse", registry, &"misc")
	_expect(bool(result.get("success", false)) and not state.inventory.misc.has("dead_mouse"), "resource: used misc fertilizer should leave inventory")
	_expect(is_equal_approx(plant.nutrition - nutrition_before, 2.0), "resource: ordinary item should feed two units by default")
	state.fertilizer_knowledge["dead_mouse"] = {"uses": 1, "care_effects": {"nutrition_points": 2}}
	var restored := SaveMapper.from_dictionary(SaveMapper.to_dictionary(state))
	_expect(restored.fertilizer_knowledge.has("dead_mouse"), "resource: discovered fertilizer knowledge must survive save and load")

func _test_dynamic_nutrition_capacity() -> void:
	var plant := _plant("nutrition-capacity")
	plant.growth_cycle_index = 0; _expect(NutritionService.capacity(plant) == 20.0, "nutrition: seed capacity must be 20")
	plant.growth_cycle_index = 1; _expect(NutritionService.capacity(plant) == 40.0, "nutrition: sprout capacity must be 40")
	plant.growth_cycle_index = 5; _expect(NutritionService.capacity(plant) == 60.0, "nutrition: young tree capacity must be 60")
	plant.growth_cycle_index = 6; _expect(NutritionService.capacity(plant) == 70.0, "nutrition: center tree capacity must be 70")
	plant.growth_cycle_index = 7; _expect(NutritionService.capacity(plant) == 80.0, "nutrition: first side branch must raise capacity to 80")
	plant.growth_cycle_index = 8; _expect(NutritionService.capacity(plant) == 90.0, "nutrition: second side branch must raise capacity to 90")
	plant.growth_cycle_index = 9; _expect(NutritionService.capacity(plant) == 105.0, "nutrition: flowering must add 15")
	plant.growth_cycle_index = 10
	plant.branch_at(&"center").fruit_growth = GrowingFruitState.new()
	_expect(NutritionService.capacity(plant) == 115.0, "nutrition: fruit phase must add 25")
	plant.branch_at(&"center").fruit_growth = null
	_expect(NutritionService.capacity(plant) == 90.0, "nutrition: harvested fruit phase must remove 25")
	for pair in [[0, 10.0], [1, 9.0], [5, 8.0], [7, 7.0], [9, 6.0], [10, 5.0]]:
		plant.growth_cycle_index = int(pair[0])
		_expect(NutritionService.ground_fertilizer_gain(plant) == float(pair[1]), "nutrition: compost gain mismatch for cycle %d" % int(pair[0]))
	var fertilizer := FertilizerDefinition.new()
	fertilizer.care_effects = {"growth_cycle": &"sprout"}
	plant.growth_cycle_index = 1
	_expect(NutritionService.fertilizer_gain(plant, fertilizer, &"fertilizer") == 20.0, "nutrition: matching fertilizer must restore half capacity")
	plant.growth_cycle_index = 8
	_expect(NutritionService.fertilizer_gain(plant, fertilizer, &"fertilizer") == 7.0, "nutrition: mismatched fertilizer must act like compost")

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
