class_name ShopService
extends RefCounted

static func next_pot_price(state: GameState, rules: GameRules) -> int:
	if state == null:
		return rules.pot_base_price
	var purchased_count := maxi(0, state.pots.size() - 2)
	return maxi(
		1,
		int(round(float(rules.pot_base_price) * pow(rules.pot_price_growth, purchased_count)))
	)

static func is_species_unlocked(state: GameState, definition: PlantSpeciesDefinition) -> bool:
	if state == null or definition == null:
		return false
	return state.pots.size() >= maxi(1, definition.unlock_pot_count)

static func species_catalog(
	state: GameState,
	definitions: Array[PlantSpeciesDefinition]
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for definition in definitions:
		if definition == null or definition.shop_seed_price <= 0:
			continue
		result.append({
			"id": definition.id,
			"price": definition.shop_seed_price,
			"unlocked": is_species_unlocked(state, definition),
			"requires_pots": maxi(1, definition.unlock_pot_count),
		})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["id"]) < String(b["id"]))
	return result
