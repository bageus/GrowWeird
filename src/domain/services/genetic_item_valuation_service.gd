class_name GeneticItemValuationService
extends RefCounted

static func seed_value(
	seed_state: SeedState,
	species: PlantSpeciesDefinition,
	rules: GameRules
) -> int:
	if seed_state == null or seed_state.genome == null or species == null:
		return 0
	var base := int(round(float(species.shop_seed_price) * rules.seed_sale_multiplier))
	return maxi(1, base + _genome_bonus(seed_state.genome, rules))

static func cutting_value(
	cutting: CuttingState,
	species: PlantSpeciesDefinition,
	rules: GameRules
) -> int:
	if cutting == null or cutting.genome == null or species == null:
		return 0
	var base := int(round(float(species.base_sale_value) * rules.cutting_sale_multiplier))
	return maxi(1, base + _genome_bonus(cutting.genome, rules))

static func _genome_bonus(genome: GenomeSnapshot, rules: GameRules) -> int:
	var trait_depth := 0
	for value in genome.traits.values():
		trait_depth += maxi(0, int(value))
	var ancestry_count := genome.ancestry.size()
	return (
		trait_depth * rules.genetic_item_trait_value
		+ ancestry_count * rules.genetic_item_ancestry_value
	)
