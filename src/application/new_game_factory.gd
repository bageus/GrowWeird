class_name NewGameFactory
extends RefCounted

const STARTER_SPECIES: StringName = &"starter_sprout"
const STARTER_FERTILIZER: StringName = &"compost_mix"

static func create(rules: GameRules) -> GameState:
	var state := GameState.new()
	state.money = rules.starting_money
	var first_pot := PotState.new()
	first_pot.pot_id = "pot-1"
	first_pot.soil_moisture = 0.30
	first_pot.plant = PlantState.new()
	first_pot.plant.instance_id = IdFactory.make("plant")
	first_pot.plant.species_id = STARTER_SPECIES
	first_pot.plant.initialize_native_branches()
	var second_pot := PotState.new()
	second_pot.pot_id = "pot-2"
	second_pot.soil_moisture = 0.30
	state.pots = [first_pot, second_pot]
	state.active_pot_id = first_pot.pot_id
	add_starter_inventory_item(state, first_pot.plant)
	FertilizerOfferService.initialize_rng(state.fertilizer_offer, int(first_pot.plant.instance_id.hash()))
	FertilizerOfferService.schedule_initial(state.fertilizer_offer, rules)
	return state

static func add_starter_inventory_item(state: GameState, plant: PlantState) -> void:
	InventoryService.add_fertilizer(state.inventory, STARTER_FERTILIZER, 1)
	state.inventory.misc["dead_mouse"] = 1
	var branch := plant.branch_at(&"center")
	if branch == null:
		return
	var cutting := CuttingState.new()
	cutting.item_id = IdFactory.make("cutting")
	cutting.source_plant_id = plant.instance_id
	cutting.source_branch_id = branch.branch_id
	cutting.genome = GeneticsService.snapshot_branch(branch)
	InventoryService.add_cutting(state.inventory, cutting)

static func ensure_inventory_bootstrap(state: GameState, plant: PlantState) -> void:
	if not state.inventory.misc.has("dead_mouse"):
		state.inventory.misc["dead_mouse"] = 1
	var has_items := not state.inventory.cuttings.is_empty() or not state.inventory.seeds.is_empty() or not state.inventory.fruits.is_empty() or not state.inventory.fertilizers.is_empty() or not state.inventory.misc.is_empty()
	if not has_items and plant != null:
		add_starter_inventory_item(state, plant)
