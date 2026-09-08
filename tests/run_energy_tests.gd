extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_expect(EnergyService.capacity(GameState.new()) == 0, "energy capacity without pots must be zero")
	var state := GameState.new(); state.pots = [PotState.new(), PotState.new()]
	EnergyService.fill(state)
	_expect(EnergyService.capacity(state) == 70 and state.energy == 70, "energy capacity must be 35 per pot")
	_expect(EnergyService.spend(state, 5) and state.energy == 65, "energy spending failed")
	EnergyService.advance(state, 119.0); _expect(state.energy == 65, "energy restored too early")
	EnergyService.advance(state, 1.0); _expect(state.energy == 66, "energy must restore every 120 seconds")
	var restored := SaveMapper.from_dictionary(SaveMapper.to_dictionary(state))
	_expect(restored.energy == 66 and is_zero_approx(restored.energy_regen_elapsed), "energy save round trip failed")
	state.pots.pop_back(); EnergyService.clamp_to_capacity(state)
	_expect(state.energy == 66, "owned energy must survive a lower pot capacity")
	EnergyService.credit(state, 20); _expect(state.energy == 86, "purchased energy may exceed capacity")
	var migrated := SaveMigrator.migrate({"schema_version": 9, "pots": [{}, {}]})
	_expect(int(migrated.get("energy", -1)) == 70, "existing saves must start with full energy")
	var plant := PlantState.new(); plant.growth_cycle_index = 9; plant.growth_cycle_elapsed = 0.0
	_expect(EnergyService.cycle_skip_cost(plant) == 9, "flower cycle cost must follow remaining minutes")
	plant.boosted_growth_cycle = 9
	_expect(EnergyService.cycle_skip_cost(plant) == 5, "matching fertilizer must halve effective skip time")
	if failures.is_empty(): print("Energy tests passed")
	else:
		for failure in failures: push_error(failure)
	quit(failures.size())

func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
