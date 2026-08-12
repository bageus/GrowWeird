class_name FertilizerActions
extends RefCounted

static func choose_offer(
	state: GameState,
	plant: PlantState,
	fertilizer_id: StringName,
	registry: ContentRegistry,
	rules: GameRules
) -> Dictionary:
	var fertilizer := registry.get_fertilizer(fertilizer_id)
	if state == null or plant == null or not plant.alive or fertilizer == null:
		return _failure()
	if not FertilizerOfferService.can_choose(state.fertilizer_offer, fertilizer_id):
		return _failure()
	var events := FertilizerUseService.apply(plant, fertilizer, registry.all_mutations())
	if not FertilizerOfferService.resolve_choice(state.fertilizer_offer, fertilizer_id, rules):
		return _failure()
	return {"success": true, "events": events}

static func skip_offer(state: GameState, rules: GameRules) -> bool:
	if state == null:
		return false
	var price := FertilizerOfferService.skip_price(state.fertilizer_offer, rules)
	if price <= 0 or not EconomyService.spend(state, price):
		return false
	if FertilizerOfferService.resolve_skip(state.fertilizer_offer, rules):
		return true
	EconomyService.credit(state, price)
	return false

static func use_inventory(
	state: GameState,
	plant: PlantState,
	fertilizer_id: StringName,
	registry: ContentRegistry
) -> Dictionary:
	var fertilizer := registry.get_fertilizer(fertilizer_id)
	if state == null or plant == null or not plant.alive or fertilizer == null:
		return _failure()
	if InventoryService.fertilizer_count(state.inventory, fertilizer_id) <= 0:
		return _failure()
	if not InventoryService.take_fertilizer(state.inventory, fertilizer_id):
		return _failure()
	var events := FertilizerUseService.apply(plant, fertilizer, registry.all_mutations())
	return {"success": true, "events": events}

static func _failure() -> Dictionary:
	return {"success": false, "events": []}
