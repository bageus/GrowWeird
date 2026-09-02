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
	if state == null or fertilizer == null:
		return _failure()
	if not FertilizerOfferService.can_choose(state.fertilizer_offer, fertilizer_id):
		return _failure()
	var events: Array[Dictionary] = []
	if plant != null and plant.alive:
		events = FertilizerUseService.apply(plant, fertilizer, registry.all_mutations())
	if not FertilizerOfferService.resolve_choice(state.fertilizer_offer, fertilizer_id, rules):
		return _failure()
	return {"success": true, "events": events}

static func skip_offer(
	state: GameState,
	rules: GameRules,
	fertilizers: Array[FertilizerDefinition]
) -> bool:
	if state == null:
		return false
	var price := FertilizerOfferService.skip_price(state.fertilizer_offer, rules)
	if price <= 0 or not EconomyService.spend(state, price):
		return false
	var resolved := FertilizerOfferService.resolve_skip(state.fertilizer_offer, rules) if state.fertilizer_offer.is_active() else FertilizerOfferService.refresh_offer(state.fertilizer_offer, fertilizers, rules)
	if resolved:
		return true
	EconomyService.credit(state, price)
	return false

static func use_inventory(
	state: GameState,
	plant: PlantState,
	fertilizer_id: StringName,
	registry: ContentRegistry,
	kind: StringName = ResourceActions.FERTILIZER
) -> Dictionary:
	var fertilizer := registry.get_fertilizer(fertilizer_id)
	if state == null or plant == null or not plant.alive or fertilizer == null:
		return _failure()
	var consumed := InventoryService.take_misc(state.inventory, String(fertilizer_id)) == 1 if kind == ResourceActions.MISC else InventoryService.take_fertilizer(state.inventory, fertilizer_id)
	if not consumed:
		return _failure()
	var events := FertilizerUseService.apply(plant, fertilizer, registry.all_mutations())
	return {"success": true, "events": events}

static func _failure() -> Dictionary:
	return {"success": false, "events": []}
