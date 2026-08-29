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
	if definition == null or definition.shop_price <= 0:
		return false
	if not ShopService.is_fertilizer_unlocked(state, definition):
		return false
	if not EconomyService.spend(state, definition.shop_price):
		return false
	InventoryService.add_fertilizer(state.inventory, fertilizer_id, 1)
	return true

static func buy_species_seed(
	state: GameState,
	species_id: StringName,
	registry: ContentRegistry
) -> String:
	if state == null:
		return ""
	var definition := registry.get_plant(species_id)
	if definition == null or definition.shop_seed_price <= 0:
		return ""
	if not ShopService.is_species_unlocked(state, definition):
		return ""
	if not EconomyService.spend(state, definition.shop_seed_price):
		return ""
	var seed_state := SeedState.new()
	seed_state.item_id = IdFactory.make("seed")
	seed_state.source_plant_id = "shop"
	seed_state.genome = GeneticsService.fresh_species_snapshot(species_id)
	if seed_state.genome == null:
		EconomyService.credit(state, definition.shop_seed_price)
		return ""
	InventoryService.add_seed(state.inventory, seed_state)
	return seed_state.item_id

static func buy_pot(state: GameState, rules: GameRules) -> String:
	if state == null:
		return ""
	var price := ShopService.next_pot_price(state, rules)
	if not EconomyService.spend(state, price):
		return ""
	var pot := PotState.new()
	pot.pot_id = "pot-%d" % (state.pots.size() + 1)
	pot.soil_moisture = 0.30
	state.pots.append(pot)
	return pot.pot_id
