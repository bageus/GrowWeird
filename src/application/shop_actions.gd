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
	seed_state.ensure_visual_frame()
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

static func buy_catalog_item(state: GameState, item: Dictionary, registry: ContentRegistry) -> bool:
	if state == null or registry == null or not bool(item.get("unlocked", false)):
		return false
	var price := int(item.get("price", 0))
	if price <= 0 or not EconomyService.spend(state, price):
		return false
	var action := StringName(item.get("action", &""))
	var source_id := StringName(item.get("source_id", item.get("id", &"")))
	var amount := maxi(1, int(item.get("amount", 1)))
	var success := false
	match action:
		&"pot": success = _add_pots(state, amount)
		&"potted_plant": success = _add_potted_plants(state, source_id, registry, amount)
		&"cutting": success = _add_cuttings(state, source_id, registry, amount)
		&"seed": success = _add_seeds(state, source_id, registry, amount, int(item.get("seed_frame", -1)))
		&"fertilizer": success = registry.get_fertilizer(source_id) != null
		&"decoration", &"mutagen": success = not String(source_id).is_empty()
	if success and action == &"fertilizer": InventoryService.add_fertilizer(state.inventory, source_id, amount)
	if success and action in [&"decoration", &"mutagen"]: InventoryService.add_misc(state.inventory, String(source_id), amount)
	if not success: EconomyService.credit(state, price)
	return success

static func _add_pot(state: GameState) -> String:
	var pot := PotState.new()
	pot.pot_id = IdFactory.make("pot")
	pot.soil_moisture = 0.30
	state.pots.append(pot)
	return pot.pot_id

static func _add_pots(state: GameState, amount: int) -> bool:
	for _index in range(amount): _add_pot(state)
	return true

static func _add_potted_plants(state: GameState, species_id: StringName, registry: ContentRegistry, amount: int) -> bool:
	if registry.get_plant(species_id) == null: return false
	for _index in range(amount):
		var plant := GeneticsService.plant_from_genome(GeneticsService.fresh_species_snapshot(species_id), IdFactory.make("plant"))
		if plant == null: return false
		plant.growth_ratio = 0.0
		plant.growth_cycle_index = 1
		var pot := PotState.new(); pot.pot_id = IdFactory.make("pot"); pot.soil_moisture = 0.30; pot.plant = plant
		state.pots.append(pot)
	return true

static func _add_cuttings(state: GameState, species_id: StringName, registry: ContentRegistry, amount: int) -> bool:
	if registry.get_plant(species_id) == null: return false
	for _index in range(amount):
		var cutting := CuttingState.new(); cutting.item_id = IdFactory.make("cutting"); cutting.source_plant_id = "shop"
		cutting.source_branch_id = "shop-branch"; cutting.genome = GeneticsService.fresh_species_snapshot(species_id)
		InventoryService.add_cutting(state.inventory, cutting)
	return true

static func _add_seeds(state: GameState, species_id: StringName, registry: ContentRegistry, amount: int, visual_frame: int) -> bool:
	if registry.get_plant(species_id) == null: return false
	for _index in range(amount):
		var seed_state := SeedState.new(); seed_state.item_id = IdFactory.make("seed"); seed_state.source_plant_id = "shop"
		seed_state.visual_frame = visual_frame; seed_state.ensure_visual_frame()
		seed_state.genome = GeneticsService.fresh_species_snapshot(species_id); InventoryService.add_seed(state.inventory, seed_state)
	return true
