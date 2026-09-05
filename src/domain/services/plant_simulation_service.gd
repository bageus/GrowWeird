class_name PlantSimulationService
extends RefCounted

static func advance(
	game_state: GameState,
	delta_seconds: float,
	registry: ContentRegistry,
	rules: GameRules,
	policy: SimulationPolicy = null
) -> void:
	if game_state == null or delta_seconds <= 0.0:
		return
	var active_policy := policy if policy != null else SimulationPolicy.realtime()
	for pot in game_state.pots:
		_advance_pot(pot, delta_seconds, registry, rules, active_policy)

static func _advance_pot(
	pot: PotState,
	delta_seconds: float,
	registry: ContentRegistry,
	rules: GameRules,
	policy: SimulationPolicy
) -> void:
	var plant := pot.plant
	if plant == null or not plant.alive:
		return
	var species := registry.get_plant(plant.species_id)
	if species == null:
		push_error("Missing PlantSpeciesDefinition: %s" % String(plant.species_id))
		return

	if policy.advance_environment:
		_consume_growth_needs(pot, plant, species, delta_seconds)
	plant.age_seconds += delta_seconds

	var comfort := ComfortEvaluator.evaluate(pot, species)
	var overall := float(comfort["overall"])
	plant.record_care_sample(overall, delta_seconds)
	if policy.advance_growth:
		GrowthCycleService.advance(plant, delta_seconds, overall)
		if plant.boosted_growth_cycle == plant.growth_cycle_index:
			plant.nutrition = clampf(plant.nutrition, species.nutrition_min, species.nutrition_max)

	if policy.advance_health:
		if overall < rules.critical_comfort_threshold:
			plant.health -= rules.health_decay_per_second * delta_seconds
		elif overall >= rules.recovery_comfort_threshold:
			plant.health += rules.health_recovery_per_second * delta_seconds
		plant.health = clampf(plant.health, 0.0, 1.0)
		if plant.health <= 0.0:
			if policy.allow_death:
				plant.alive = false
			else:
				plant.health = 0.01

	if policy.advance_growth and plant.alive and plant.growth_cycle_index == GrowthCycleService.LAST_CYCLE:
		BranchRegrowthService.advance(plant, delta_seconds, species, overall)

static func _consume_growth_needs(
	pot: PotState,
	plant: PlantState,
	species: PlantSpeciesDefinition,
	delta_seconds: float
) -> void:
	var moisture_stage_before := pot.soil_moisture_stage()
	pot.soil_moisture = clampf(
		pot.soil_moisture - species.moisture_decay_per_second * delta_seconds,
		0.0,
		1.0
	)
	if pot.soil_moisture_stage() != moisture_stage_before:
		pot.reset_spray_streak()
	plant.nutrition = clampf(
		plant.nutrition - species.nutrition_decay_per_second * delta_seconds,
		0.0,
		1.0
	)
