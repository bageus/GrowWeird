class_name PlantSimulationService
extends RefCounted

static func advance(
	game_state: GameState,
	delta_seconds: float,
	registry: ContentRegistry,
	rules: GameRules
) -> void:
	if delta_seconds <= 0.0:
		return
	for pot in game_state.pots:
		_advance_pot(pot, delta_seconds, registry, rules)

static func _advance_pot(
	pot: PotState,
	delta_seconds: float,
	registry: ContentRegistry,
	rules: GameRules
) -> void:
	var plant := pot.plant
	if plant == null or not plant.alive:
		return

	var species := registry.get_plant(plant.species_id)
	if species == null:
		push_error("Missing PlantSpeciesDefinition: %s" % String(plant.species_id))
		return

	pot.soil_moisture = clampf(
		pot.soil_moisture - species.moisture_decay_per_second * delta_seconds,
		0.0,
		1.0
	)
	plant.age_seconds += delta_seconds

	var comfort := ComfortEvaluator.evaluate(pot, species)
	var overall := float(comfort["overall"])
	var size_multiplier := lerpf(
		rules.young_growth_multiplier,
		rules.mature_growth_multiplier,
		clampf(plant.growth_ratio, 0.0, 1.0)
	)
	plant.growth_ratio = minf(
		1.0,
		plant.growth_ratio + species.base_growth_per_second * size_multiplier * overall * delta_seconds
	)

	if overall < rules.critical_comfort_threshold:
		plant.health -= rules.health_decay_per_second * delta_seconds
	elif overall >= rules.recovery_comfort_threshold:
		plant.health += rules.health_recovery_per_second * delta_seconds

	plant.health = clampf(plant.health, 0.0, 1.0)
	if plant.health <= 0.0:
		plant.alive = false
