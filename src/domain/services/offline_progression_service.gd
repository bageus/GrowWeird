class_name OfflineProgressionService
extends RefCounted

static func advance(
	state: GameState,
	elapsed_seconds: float,
	registry: ContentRegistry,
	rules: GameRules
) -> Dictionary:
	var requested := maxf(0.0, elapsed_seconds)
	if state == null or registry == null or not rules.offline_progression_enabled or requested <= 0.0:
		return _result(requested, 0.0, 0, false, 0, false)

	var applied := minf(requested, rules.offline_max_seconds)
	var steps := mini(
		rules.offline_max_steps,
		maxi(1, int(ceil(applied / maxf(rules.simulation_step_seconds, 1.0))))
	)
	var step_seconds := applied / float(steps)
	var policy := SimulationPolicy.offline(rules)
	var living_before := _living_count(state)
	var offer_created := false

	for _index in range(steps):
		PlantSimulationService.advance(state, step_seconds, registry, rules, policy)
		if rules.offline_fruiting_enabled:
			FruitLifecycleService.advance(state, step_seconds, registry)
		if rules.offline_offers_enabled and _living_count(state) > 0:
			offer_created = FertilizerOfferService.advance(
				state.fertilizer_offer,
				step_seconds,
				registry.all_fertilizers(),
				rules
			) or offer_created

	var deaths := maxi(0, living_before - _living_count(state))
	return _result(requested, applied, steps, requested > applied, deaths, offer_created)

static func _living_count(state: GameState) -> int:
	var count := 0
	for pot in state.pots:
		if pot.plant != null and pot.plant.alive:
			count += 1
	return count

static func _result(
	requested: float,
	applied: float,
	steps: int,
	capped: bool,
	deaths: int,
	offer_created: bool
) -> Dictionary:
	return {
		"requested_seconds": requested,
		"applied_seconds": applied,
		"steps": steps,
		"capped": capped,
		"deaths": deaths,
		"offer_created": offer_created,
	}
