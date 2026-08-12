extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	_test_bounded_offline_progression()
	_test_offline_death_policy()
	_test_save_json_round_trip()
	_test_platform_resources_load()
	if _failures.is_empty():
		print("GrowWeird offline/platform tests passed")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)

func _test_bounded_offline_progression() -> void:
	var registry := ContentRegistry.new()
	registry.load_all()
	var rules := GameRules.new()
	rules.offline_max_seconds = 120.0
	rules.offline_max_steps = 4
	rules.offline_death_enabled = false
	rules.health_decay_per_second = 0.1
	var state := _stressed_state(0.02)
	state.fertilizer_offer.seconds_until_offer = 10.0
	var result := OfflineProgressionService.advance(state, 1000.0, registry, rules)
	_expect(bool(result["capped"]), "offline: long absence should be capped")
	_expect(absf(float(result["applied_seconds"]) - 120.0) < 0.001, "offline: cap was not respected")
	_expect(int(result["steps"]) <= 4, "offline: bounded step count was exceeded")
	_expect(state.pots[0].plant.alive, "offline: death-disabled policy killed the plant")
	_expect(state.pots[0].plant.health > 0.0, "offline: death-disabled policy left zero health")
	_expect(state.fertilizer_offer.is_active(), "offline: fertilizer timer should advance while a plant lives")

func _test_offline_death_policy() -> void:
	var registry := ContentRegistry.new()
	registry.load_all()
	var rules := GameRules.new()
	rules.offline_max_seconds = 60.0
	rules.offline_max_steps = 1
	rules.offline_death_enabled = true
	rules.health_decay_per_second = 0.1
	var state := _stressed_state(0.01)
	OfflineProgressionService.advance(state, 60.0, registry, rules)
	_expect(not state.pots[0].plant.alive, "offline: death-enabled policy should allow permanent death")

func _test_save_json_round_trip() -> void:
	var state := _stressed_state(0.8)
	state.money = 321
	state.last_saved_unix = 123456789
	var restored := SaveRepository.from_json(SaveRepository.to_json(state))
	_expect(restored != null, "platform save: serialized state should restore")
	_expect(restored.money == 321, "platform save: money changed in JSON round trip")
	_expect(restored.last_saved_unix == 123456789, "platform save: timestamp changed in JSON round trip")

func _test_platform_resources_load() -> void:
	var paths := [
		"res://src/infrastructure/platform/platform_adapter.gd",
		"res://src/infrastructure/platform/local_platform_adapter.gd",
		"res://src/infrastructure/platform/yandex_platform_adapter.gd",
		"res://src/infrastructure/platform/platform_runtime.gd",
		"res://src/application/persistence_coordinator.gd",
	]
	for path in paths:
		_expect(load(path) != null, "platform load failed: %s" % path)
	var local := LocalPlatformAdapter.new()
	_expect(local.platform_id() == &"local", "platform: local adapter id is wrong")
	_expect(local.now_unix() > 0, "platform: local clock should return unix time")

func _stressed_state(health: float) -> GameState:
	var state := GameState.new()
	var pot := PotState.new()
	pot.pot_id = "offline-pot"
	pot.soil_moisture = 0.0
	pot.light_mode = PotState.LightMode.DARK
	pot.plant = PlantState.new()
	pot.plant.instance_id = "offline-plant"
	pot.plant.species_id = &"starter_sprout"
	pot.plant.health = health
	pot.plant.initialize_native_branches()
	state.pots = [pot]
	state.active_pot_id = pot.pot_id
	return state

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
