class_name PropagationService
extends RefCounted

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
	pot.plant = plant
	return true

static func plant_seed(seed: SeedState, pot: PotState, plant_id: String) -> bool:
	if seed == null or seed.genome == null or pot == null or not pot.is_empty():
		return false
	var plant := GeneticsService.plant_from_genome(seed.genome, plant_id)
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
	var seed := SeedState.new()
	seed.item_id = item_id
	seed.source_plant_id = fruit.source_plant_id
	seed.genome = fruit.genome.duplicate_snapshot()
	return seed
