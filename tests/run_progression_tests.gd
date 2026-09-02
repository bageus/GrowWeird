extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	_test_ordered_onboarding_and_rewards()
	_test_events_do_not_bank_before_unlock()
	_test_species_unlocks_use_milestones_and_pots()
	_test_fertilizer_shop_unlocks_and_nonshop_compost()
	_test_catalog_purchases_route_to_pots_and_inventory()
	_test_progression_save_round_trip()
	_test_v4_migration_skips_onboarding()
	if _failures.is_empty():
		print("GrowWeird progression tests passed")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)

func _test_ordered_onboarding_and_rewards() -> void:
	var registry := _registry()
	var state := _state_with_pots(2)
	var goal := ProgressionQuery.current_goal(state, registry)
	_expect(StringName(goal.get("id", "")) == &"water_the_sprout", "progression: first goal should teach watering")
	var start_money := state.money
	var events := ProgressionActions.record_event(state, &"watered", registry)
	_expect(events.size() == 1, "progression: watering should complete first milestone")
	_expect(state.money == start_money + 15, "progression: first reward should credit exactly once")
	ProgressionActions.record_event(state, &"watered", registry)
	_expect(state.money == start_money + 15, "progression: completed milestone must not reward twice")
	goal = ProgressionQuery.current_goal(state, registry)
	_expect(StringName(goal.get("id", "")) == &"tune_environment", "progression: second goal should teach environment")

func _test_events_do_not_bank_before_unlock() -> void:
	var registry := _registry()
	var state := _state_with_pots(2)
	ProgressionActions.record_event(state, &"environment_changed", registry)
	_expect(state.progression.progress_for(&"tune_environment") == 0, "progression: locked milestone must not bank early events")
	ProgressionActions.record_event(state, &"watered", registry)
	_expect(not state.progression.is_completed(&"tune_environment"), "progression: earlier environment event must not auto-complete next milestone")
	ProgressionActions.record_event(state, &"environment_changed", registry)
	_expect(state.progression.is_completed(&"tune_environment"), "progression: available milestone should complete on matching event")

func _test_species_unlocks_use_milestones_and_pots() -> void:
	var registry := _registry()
	var state := _state_with_pots(2)
	var shade := registry.get_plant(&"shade_fern")
	var sun := registry.get_plant(&"sun_creeper")
	_expect(not ShopService.is_species_unlocked(state, shade), "shop progression: shade fern must start milestone-locked")
	state.progression.complete(&"make_seed")
	_expect(ShopService.is_species_unlocked(state, shade), "shop progression: shade fern should unlock after seed milestone with two pots")
	state.progression.complete(&"make_graft")
	_expect(not ShopService.is_species_unlocked(state, sun), "shop progression: sun creeper should still require third pot")
	state.pots.append(_pot("pot-3"))
	_expect(ShopService.is_species_unlocked(state, sun), "shop progression: sun creeper should unlock after graft milestone plus third pot")

func _test_fertilizer_shop_unlocks_and_nonshop_compost() -> void:
	var registry := _registry()
	var state := _state_with_pots(2)
	var radioactive := registry.get_fertilizer(&"radioactive_sample")
	_expect(not ShopService.is_fertilizer_unlocked(state, radioactive), "shop progression: radioactive sample should start locked")
	state.progression.complete(&"find_mutation")
	_expect(ShopService.is_fertilizer_unlocked(state, radioactive), "shop progression: radioactive sample should unlock after visible mutation")
	var catalog := ShopService.fertilizer_catalog(state, registry.all_fertilizers())
	var compost_listed := false
	for item in catalog:
		if StringName(item.get("id", "")) == RecyclingService.COMPOST_ID:
			compost_listed = true
	_expect(not compost_listed, "shop progression: recycled Compost Mix must never be listed as a free shop item")
	_expect(not ShopActions.buy_fertilizer(state, RecyclingService.COMPOST_ID, registry), "shop progression: zero-price Compost Mix must not be purchasable")
	var universal := registry.get_fertilizer(&"universal_fertilizer")
	_expect(universal != null and universal.shop_price > 0, "shop progression: universal fertilizer must be sold in the shop")
	_expect(ShopActions.buy_fertilizer(state, &"universal_fertilizer", registry), "shop progression: universal fertilizer purchase failed")

func _test_progression_save_round_trip() -> void:
	var state := _state_with_pots(2)
	state.progression.complete(&"water_the_sprout")
	state.progression.set_progress(&"tune_environment", 1)
	var restored := SaveMapper.from_dictionary(SaveMapper.to_dictionary(state))
	_expect(restored.schema_version == GameState.SCHEMA_VERSION, "progression save: schema should be current")
	_expect(restored.progression.is_completed(&"water_the_sprout"), "progression save: completed milestone was lost")
	_expect(restored.progression.progress_for(&"tune_environment") == 1, "progression save: partial milestone progress was lost")
	_expect(not restored.progression.skip_onboarding, "progression save: new-game onboarding flag should remain active")

func _test_catalog_purchases_route_to_pots_and_inventory() -> void:
	var registry := _registry()
	var state := _state_with_pots(1)
	state.money = 4
	var pot_item := {"action": &"pot", "source_id": &"new_pot", "price": 1, "unlocked": true}
	var plant_item := {"action": &"potted_plant", "source_id": &"starter_sprout", "price": 1, "unlocked": true}
	var cutting_item := {"action": &"cutting", "source_id": &"shade_fern", "price": 1, "amount": 2, "unlocked": true}
	var decor_item := {"action": &"decoration", "source_id": &"garden_gnome", "price": 1, "unlocked": true}
	_expect(ShopActions.buy_catalog_item(state, pot_item, registry) and state.pots.size() == 2 and state.pots[-1].plant == null, "catalog shop: purchased pot must enter Pots as an empty pot")
	_expect(ShopActions.buy_catalog_item(state, plant_item, registry) and state.pots.size() == 3 and state.pots[-1].plant != null, "catalog shop: ready plant must enter Pots in its own pot")
	_expect(ShopActions.buy_catalog_item(state, cutting_item, registry) and state.inventory.cuttings.size() == 2, "catalog shop: branch lot quantity must enter shared inventory")
	_expect(ShopActions.buy_catalog_item(state, decor_item, registry) and int(state.inventory.misc.get("garden_gnome", 0)) == 1, "catalog shop: non-pot item must enter shared inventory")
	_expect(state.money == 0, "catalog shop: every lot must cost one coin regardless of quantity")

func _test_v4_migration_skips_onboarding() -> void:
	var migrated := SaveMigrator.migrate({"schema_version": 4, "pots": []})
	_expect(int(migrated.get("schema_version", 0)) == GameState.SCHEMA_VERSION, "progression migration: v4 should reach current schema")
	var progression: Dictionary = migrated.get("progression", {})
	_expect(bool(progression.get("skip_onboarding", false)), "progression migration: existing players should bypass onboarding")

func _registry() -> ContentRegistry:
	var registry := ContentRegistry.new()
	registry.load_all()
	return registry

func _state_with_pots(count: int) -> GameState:
	var state := GameState.new()
	state.money = 200
	for index in range(count):
		state.pots.append(_pot("pot-%d" % (index + 1)))
	state.active_pot_id = state.pots[0].pot_id if not state.pots.is_empty() else ""
	return state

func _pot(id: String) -> PotState:
	var pot := PotState.new()
	pot.pot_id = id
	return pot

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
