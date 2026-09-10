class_name EnergyService
extends RefCounted

const PER_POT := 35
const REGEN_SECONDS := 120.0
const WATER_COST := 1
const OFFER_COST := 5

static func capacity(state: GameState) -> int:
	if state == null: return 0
	var planted := 0
	for pot in state.pots:
		if pot != null and not pot.is_empty(): planted += 1
	return planted * PER_POT

static func fill(state: GameState) -> void:
	if state != null: state.energy = capacity(state); state.energy_regen_elapsed = 0.0

static func clamp_to_capacity(state: GameState) -> void:
	if state == null: return
	state.energy = maxi(0, state.energy)
	if state.energy >= capacity(state): state.energy_regen_elapsed = 0.0

static func spend(state: GameState, amount: int) -> bool:
	if state == null or amount < 0 or state.energy < amount: return false
	state.energy -= amount
	return true

static func credit(state: GameState, amount: int) -> int:
	if state == null or amount <= 0: return 0
	var before := state.energy
	state.energy += amount
	return state.energy - before

static func advance(state: GameState, seconds: float) -> bool:
	if state == null or seconds <= 0.0 or state.energy >= capacity(state): return false
	state.energy_regen_elapsed += seconds
	var gained := floori(state.energy_regen_elapsed / REGEN_SECONDS)
	if gained <= 0: return false
	state.energy_regen_elapsed -= float(gained) * REGEN_SECONDS
	state.energy = mini(capacity(state), state.energy + gained)
	if state.energy >= capacity(state): state.energy_regen_elapsed = 0.0
	return true

static func seconds_to_next(state: GameState) -> int:
	if state == null or state.energy >= capacity(state): return 0
	return maxi(1, int(ceil(REGEN_SECONDS - state.energy_regen_elapsed)))

static func cycle_skip_cost(plant: PlantState) -> int:
	if plant == null or not plant.alive: return 0
	var remaining := maxf(0.0, GrowthCycleService.duration(plant.growth_cycle_index) - plant.growth_cycle_elapsed)
	if plant.boosted_growth_cycle == plant.growth_cycle_index: remaining *= 0.5
	return maxi(1, int(ceil(remaining / 60.0)))
