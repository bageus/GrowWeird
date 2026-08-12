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
