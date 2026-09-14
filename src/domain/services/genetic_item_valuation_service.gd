class_name GeneticItemValuationService
extends RefCounted

const SEED := &"seed"
const SPROUT := &"sprout"
const CUTTING := &"cutting"

const BASE_PRICES := {
	SEED: 20,
	SPROUT: 60,
	CUTTING: 110,
}

const RARITY_MULTIPLIERS := {
	&"common": 1.0,
	&"uncommon": 1.5,
	&"rare": 2.0,
	&"epic": 3.0,
	&"legendary": 4.5,
	&"golden": 6.0,
	&"lunar": 7.5,
	&"unique": 9.0,
}

const RARITY_ORDER := [
	&"common",
	&"uncommon",
	&"rare",
	&"epic",
	&"legendary",
	&"golden",
	&"lunar",
	&"unique",
]

static func price(item_type: StringName, rarity: StringName = &"common") -> int:
	var base := int(BASE_PRICES.get(item_type, 0))
	if base <= 0:
		return 0
	var multiplier := float(RARITY_MULTIPLIERS.get(rarity, RARITY_MULTIPLIERS[&"common"]))
	return maxi(1, int(round(float(base) * multiplier)))

static func seed_price(rarity: StringName = &"common") -> int:
	return price(SEED, rarity)

static func sprout_price(rarity: StringName = &"common") -> int:
	return price(SPROUT, rarity)

static func cutting_price(rarity: StringName = &"common") -> int:
	return price(CUTTING, rarity)

static func higher_rarity(first: StringName, second: StringName) -> StringName:
	var first_index := RARITY_ORDER.find(first)
	var second_index := RARITY_ORDER.find(second)
	if first_index < 0:
		first_index = 0
	if second_index < 0:
		second_index = 0
	return RARITY_ORDER[maxi(first_index, second_index)]

static func seed_value(
	seed_state: SeedState,
	_species: PlantSpeciesDefinition,
	rules: GameRules
) -> int:
	if seed_state == null or seed_state.genome == null:
		return 0
	var full_price := seed_price(seed_state.genome.rarity)
	return maxi(1, int(round(float(full_price) * rules.seed_sale_multiplier)))

static func cutting_value(
	cutting: CuttingState,
	_species: PlantSpeciesDefinition,
	rules: GameRules
) -> int:
	if cutting == null or cutting.genome == null:
		return 0
	var full_price := cutting_price(cutting.genome.rarity)
	return maxi(1, int(round(float(full_price) * rules.cutting_sale_multiplier)))
