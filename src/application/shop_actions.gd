class_name ShopActions
extends RefCounted

static func buy_fertilizer(
	state: GameState,
	fertilizer_id: StringName,
	registry: ContentRegistry
) -> bool:
	if state == null:
		return false
	var definition := registry.get_fertilizer(fertilizer_id)
	if definition == null or definition.shop_price < 0:
		return false
	if not EconomyService.spend(state, definition.shop_price):
		return false
	InventoryService.add_fertilizer(state.inventory, fertilizer_id, 1)
	return true

static func buy_pot(state: GameState, rules: GameRules) -> String:
	if state == null:
		return ""
	var price := ShopService.next_pot_price(state, rules)
	if not EconomyService.spend(state, price):
		return ""
	var pot := PotState.new()
	pot.pot_id = "pot-%d" % (state.pots.size() + 1)
	state.pots.append(pot)
	return pot.pot_id
