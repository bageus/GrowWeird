class_name RecyclingService
extends RefCounted

const COMPOST_ID: StringName = &"compost_mix"

static func fruit_yield(rules: GameRules) -> int:
	return maxi(0, rules.fruit_compost_yield)

static func seed_yield(rules: GameRules) -> int:
	return maxi(0, rules.seed_compost_yield)

static func cutting_yield(rules: GameRules) -> int:
	return maxi(0, rules.cutting_compost_yield)

static func dead_plant_yield(plant: PlantState, rules: GameRules) -> int:
	if plant == null or plant.alive:
		return 0
	var growth_bonus := int(floor(clampf(plant.growth_ratio, 0.0, 1.0) * float(rules.dead_plant_compost_growth_bonus)))
	var branch_bonus := plant.existing_branches().size() * rules.dead_plant_compost_per_branch
	return maxi(1, rules.dead_plant_compost_base + growth_bonus + branch_bonus)
