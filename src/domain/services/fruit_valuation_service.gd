class_name FruitValuationService
extends RefCounted

static func value(
	fruit: FruitState,
	species: PlantSpeciesDefinition,
	rules: GameRules
) -> int:
	if fruit == null or fruit.genome == null or species == null:
		return 0
	var trait_levels := 0
	for trait_id in fruit.genome.traits:
		trait_levels += maxi(0, int(fruit.genome.traits[trait_id]))
	var result := species.fruit_base_value + trait_levels * rules.fruit_trait_value
	if fruit.hybrid:
		result += rules.hybrid_fruit_bonus
	return maxi(1, result)
