class_name EnergyActions
extends RefCounted

static func skip_growth_cycle(state: GameState, plant: PlantState) -> bool:
	var cost := EnergyService.cycle_skip_cost(plant)
	if state == null or plant == null or cost <= 0:
		return false
	if plant.growth_cycle_index == GrowthCycleService.LAST_CYCLE and not GrowthCycleService.recovery_complete(plant):
		return false
	if not EnergyService.spend(state, cost):
		return false
	plant.growth_cycle_elapsed = GrowthCycleService.duration(plant.growth_cycle_index)
	GrowthCycleService.advance(plant, 0.001, 1.0)
	return true
