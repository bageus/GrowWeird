class_name PlantValuationService
extends RefCounted

static func value(
	plant: PlantState,
	species: PlantSpeciesDefinition,
	rules: GameRules
) -> int:
	if plant == null or species == null:
		return 0
	var base := float(species.base_sale_value) * lerpf(0.35, 1.5, clampf(plant.growth_ratio, 0.0, 1.0))
	var trait_levels := 0
	var grafts := 0
	var ancestry: Dictionary = {}
	for branch in plant.existing_branches():
		for trait_id in branch.traits:
			trait_levels += maxi(0, int(branch.traits[trait_id]))
		if branch.grafted:
			grafts += 1
		for ancestor in branch.ancestry:
			ancestry[String(ancestor)] = true
	var extras := (
		trait_levels * rules.trait_level_sale_value
		+ grafts * rules.graft_sale_bonus
		+ maxi(0, ancestry.size() - 1) * rules.ancestry_sale_value
	)
	var health_factor := lerpf(0.4, 1.0, clampf(plant.health, 0.0, 1.0))
	if not plant.alive:
		health_factor *= rules.nonliving_plant_value_multiplier
	return maxi(1, int(round((base + float(extras)) * health_factor)))
