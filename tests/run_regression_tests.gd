extends SceneTree

var _failures: Array[String] = []
var _app: Node

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_app = root.get_node("GameApp")
	await _test_offer_scene_nodes()
	_test_inventory_feeding()
	await _test_inventory_menu_feeding()
	_test_fertilizer_timer_finish()
	_test_existing_growth_repair_and_parallel_cycles()
	_test_restart_booster_completes_restart()
	_test_pruning_requires_mature_branch()
	_test_mixed_fruit_cycle_reopens_all_flowers()
	_test_picked_flower_returns_next_generation()
	if _failures.is_empty():
		print("GrowWeird regression tests passed")
		quit(0)
		return
	for failure in _failures: push_error(failure)
	quit(1)

func _test_offer_scene_nodes() -> void:
	var game_state := _app.get("state") as GameState
	game_state.fertilizer_offer.clear()
	game_state.fertilizer_offer.seconds_until_offer = 10.0
	var controls := (load("res://src/presentation/main/scene_controls.tscn") as PackedScene).instantiate(); controls.size = Vector2(1152.0, 648.0)
	root.add_child(controls)
	await process_frame
	var auxiliary := controls.get_node("FertilizerAuxiliaryUi")
	var panel := controls.get_node("OffersPanel") as Control
	var dim := auxiliary.get_node("Dim") as ColorRect
	var timer := auxiliary.get_node("TimerHud") as Control
	var journal_button := controls.get_node("JournalButton") as Button
	_expect(not panel.visible and not dim.visible and timer.visible, "offer UI: timer state must be visible without modal dim")
	_expect(journal_button.visible, "offer UI: journal button must always exist on the left")
	_expect(journal_button.z_index == 0 and journal_button.z_as_relative, "offer UI: journal button must share the SceneControls action layer")
	_expect(journal_button.position.y > 500.0 and journal_button.position.y + journal_button.size.y <= controls.size.y, "offer UI: journal button must remain visible in the lower-left corner")
	for tab in ["Unknown", "Fertilizers", "Decorations", "Mutagens"]: _expect(auxiliary.has_node("Journal/ContentHud/Tabs/" + tab), "almanac: missing %s tab" % tab)
	var dialogs := controls.get_node("InventoryItemDialogs") as InventoryItemDialogs
	dialogs.show_for(controls.get_node("InventoryHud"), &"fertilizer", "compost_mix", 1, "Compost", 0, 1)
	game_state.fertilizer_offer.offered_ids = [&"humus", &"banana_peel", &"dead_mouse"]
	_app.emit_signal("state_changed")
	await process_frame
	_expect(not panel.visible and not dim.visible and not timer.visible, "offer UI: completed timer must wait for an open menu")
	dialogs.close_all(); await process_frame; await process_frame
	_expect(panel.visible and dim.visible, "offer UI: deferred offer must appear after the current menu closes")
	controls.queue_free()

func _test_inventory_feeding() -> void:
	var state := _state_with_plants(1)
	_app.set("state", state)
	var fertilizer_id := FertilizerAssetCatalog.id_for(0, 0, 0)
	InventoryService.add_fertilizer(state.inventory, fertilizer_id)
	var before := state.pots[0].plant.nutrition
	var result := _app.call("use_inventory_fertilizer", fertilizer_id) as Dictionary
	_expect(bool(result.get("success", false)), "inventory feed: application path returned failure")
	_expect(InventoryService.fertilizer_count(state.inventory, fertilizer_id) == 0, "inventory feed: used item was not removed")
	_expect(state.pots[0].plant.nutrition > before, "inventory feed: nutrition did not increase")

func _test_inventory_menu_feeding() -> void:
	var state := _state_with_plants(1); _app.set("state", state)
	InventoryService.add_fertilizer(state.inventory, RecyclingService.COMPOST_ID)
	var dialogs := (load("res://src/presentation/inventory/inventory_item_dialogs.tscn") as PackedScene).instantiate() as InventoryItemDialogs
	var source := Control.new(); source.size = Vector2(118.0, 118.0); root.add_child(source); root.add_child(dialogs); await process_frame
	dialogs.use_requested.connect(func(kind: StringName, item_id: String) -> void: _app.call("use_inventory_fertilizer", StringName(item_id), kind))
	dialogs.show_for(source, &"fertilizer", String(RecyclingService.COMPOST_ID), 1, "Recycled Fertilizer", 0, 1)
	dialogs.call("_use"); await process_frame
	_expect(InventoryService.fertilizer_count(state.inventory, RecyclingService.COMPOST_ID) == 0 and state.pots[0].plant.nutrition > 0.4, "inventory feed: Use button did not consume and apply fertilizer")
	dialogs.queue_free(); source.queue_free()

func _test_fertilizer_timer_finish() -> void:
	var state := _state_with_plants(1); _app.set("state", state); state.energy = 10
	state.fertilizer_offer.clear(); state.fertilizer_offer.seconds_until_offer = 300.0
	_expect(EnergyService.fertilizer_timer_skip_cost(state.fertilizer_offer) == 5, "offer timer: five minutes must cost five energy")
	_expect(bool(_app.call("finish_fertilizer_timer")) and state.energy == 5 and state.fertilizer_offer.is_active(), "offer timer: Finish did not spend energy and open the selection")

func _test_existing_growth_repair_and_parallel_cycles() -> void:
	var state := _state_with_plants(2)
	for pot in state.pots:
		pot.plant.growth_ratio = 1.0
		pot.plant.growth_cycle_index = 0
		pot.plant.alive = false; pot.plant.health = 0.0
	GrowthCycleService.repair_state(state)
	_expect(state.pots[0].plant.alive and state.pots[0].plant.health > 0.0 and state.pots[0].plant.growth_cycle_index == 8 and state.pots[1].plant.growth_cycle_index == 8, "growth repair: existing adult cycles were not restored")
	PlantSimulationService.advance(state, GrowthCycleService.duration(8), _registry(), _app.get("rules") as GameRules)
	_expect(state.pots[0].plant.growth_cycle_index == 9 and state.pots[1].plant.growth_cycle_index == 9, "growth cycle: inactive plants did not advance with the selected plant")

func _test_pruning_requires_mature_branch() -> void:
	var state := _state_with_plants(1)
	state.energy = 20
	var plant := state.pots[0].plant as PlantState
	plant.growth_cycle_index = 6
	_expect(PropagationActions.prune(state, plant, &"left").is_empty(), "pruning: an immature left branch was cut")
	plant.growth_cycle_index = 7
	_expect(not PropagationActions.prune(state, plant, &"left").is_empty(), "pruning: a grown left branch could not be cut")
	_expect(PropagationActions.prune(state, plant, &"right").is_empty(), "pruning: an immature right branch was cut")
	plant.growth_cycle_index = 8
	_expect(not PropagationActions.prune(state, plant, &"right").is_empty(), "pruning: a grown right branch could not be cut")

func _test_restart_booster_completes_restart() -> void:
	var plant := _state_with_plants(1).pots[0].plant
	plant.growth_cycle_index = GrowthCycleService.LAST_CYCLE
	plant.boosted_growth_cycle = GrowthCycleService.LAST_CYCLE
	GrowthCycleService.advance(plant, GrowthCycleService.duration(GrowthCycleService.LAST_CYCLE) * 0.5, 1.0)
	_expect(plant.growth_cycle_index == 9, "growth cycle: boosted Restart did not complete at double speed")

func _test_mixed_fruit_cycle_reopens_all_flowers() -> void:
	var state := _state_with_plants(1)
	var plant := state.pots[0].plant
	plant.growth_ratio = 1.0
	plant.growth_cycle_index = 11
	FruitLifecycleService.advance(state, 1.0, _registry())
	_expect(FruitLifecycleService.harvest(plant, &"left", "mixed-left") != null, "fruit cycle: first fruit was not harvested")
	plant.growth_cycle_index = GrowthCycleService.LAST_CYCLE
	FruitLifecycleService.advance(state, 1.0, _registry())
	GrowthCycleService.advance(plant, GrowthCycleService.duration(GrowthCycleService.LAST_CYCLE), 1.0)
	_expect(plant.growth_cycle_index == 9, "fruit cycle: restart did not return to flowering")
	for branch in plant.existing_branches():
		_expect(branch.fruit_cycle_eligible <= plant.fruit_cycle_index, "fruit cycle: a mixed harvested/seeded slot did not flower again")

func _test_picked_flower_returns_next_generation() -> void:
	var state := _state_with_plants(1)
	var plant := state.pots[0].plant
	plant.growth_ratio = 1.0; plant.growth_cycle_index = 9
	_expect(FruitActions.pick_flower(state, plant, &"left"), "flower cycle: flower was not collectible")
	for cycle in [9, 10, 11, 12]:
		plant.growth_cycle_index = cycle; plant.growth_cycle_elapsed = 0.0
		FruitLifecycleService.advance(state, 1.0, _registry())
		GrowthCycleService.advance(plant, GrowthCycleService.duration(cycle), 1.0)
	_expect(plant.growth_cycle_index == 9 and plant.branch_at(&"left").fruit_cycle_eligible <= plant.fruit_cycle_index, "flower cycle: collected flower did not return in the next generation")

func _state_with_plants(count: int) -> GameState:
	var state := GameState.new()
	for index in range(count):
		var pot := PotState.new(); pot.pot_id = "regression-%d" % index; pot.soil_moisture = 0.5
		var plant := PlantState.new(); plant.instance_id = "plant-%d" % index; plant.species_id = &"starter_sprout"; plant.nutrition = 0.4; plant.initialize_native_branches()
		pot.plant = plant; state.pots.append(pot)
	state.active_pot_id = state.pots[0].pot_id
	EnergyService.fill(state)
	return state

func _registry() -> ContentRegistry:
	return _app.get("registry") as ContentRegistry

func _expect(condition: bool, message: String) -> void:
	if not condition: _failures.append(message)
