class_name PropagationService
extends RefCounted

const CUTTING_START_GROWTH_RATIO := 5.0 / 8.0

static func prune(
	plant: PlantState,
	slot: StringName,
	item_id: String
) -> CuttingState:
	if plant == null or not plant.alive or not BranchState.VALID_SLOTS.has(slot):
		return null
	var branch := plant.cut_branch(slot)
	if branch == null:
		return null
	var cutting := CuttingState.new()
	cutting.item_id = item_id
	cutting.source_plant_id = plant.instance_id
	cutting.source_branch_id = branch.branch_id
	cutting.genome = GeneticsService.snapshot_branch(branch)
	return cutting

static func plant_cutting(
	cutting: CuttingState,
	pot: PotState,
	plant_id: String
) -> bool:
	if cutting == null or cutting.genome == null or pot == null or not pot.is_empty():
		return false
	var plant := GeneticsService.plant_from_genome(cutting.genome, plant_id)
	if plant == null:
		return false
	plant.growth_ratio = CUTTING_START_GROWTH_RATIO
	plant.growth_cycle_index = 5
	plant.growth_cycle_elapsed = 0.0
	plant.care_stage_index = 5
	pot.plant = plant
	return true

static func plant_seed(seed_state: SeedState, pot: PotState, plant_id: String) -> bool:
	if seed_state == null or seed_state.genome == null or pot == null or not pot.is_empty():
		return false
	var plant := GeneticsService.plant_from_genome(seed_state.genome, plant_id)
	if plant == null:
		return false
	pot.plant = plant
	return true

static func graft_cutting(
	cutting: CuttingState,
	plant: PlantState,
	slot: StringName,
	branch_id: String
) -> bool:
	if cutting == null or cutting.genome == null or not GraftingService.can_graft(plant, slot):
		return false
	var branch := GeneticsService.graft_branch_from_genome(cutting.genome, branch_id, slot)
	return GraftingService.graft(plant, branch, slot)

static func create_fruit(
	plant: PlantState,
	slot: StringName,
	item_id: String
) -> FruitState:
	if plant == null or not plant.alive:
		return null
	var branch := plant.branch_at(slot)
	if branch == null:
		return null
	var fruit := FruitState.new()
	fruit.item_id = item_id
	fruit.source_plant_id = plant.instance_id
	fruit.source_branch_id = branch.branch_id
	fruit.hybrid = branch.grafted
	fruit.genome = GeneticsService.hybrid_snapshot(plant, branch) if branch.grafted else GeneticsService.snapshot_plant(plant)
	return fruit

static func seed_from_fruit(fruit: FruitState, item_id: String) -> SeedState:
	if fruit == null or fruit.genome == null:
		return null
	var seed_state := SeedState.new()
	seed_state.item_id = item_id
	seed_state.source_plant_id = fruit.source_plant_id
	seed_state.genome = fruit.genome.duplicate_snapshot()
	seed_state.ensure_visual_frame()
	return seed_state
