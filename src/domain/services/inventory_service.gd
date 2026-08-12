class_name InventoryService
extends RefCounted

static func add_fertilizer(inventory: InventoryState, fertilizer_id: StringName, amount: int = 1) -> void:
	if inventory == null or amount <= 0:
		return
	var key := String(fertilizer_id)
	inventory.fertilizers[key] = int(inventory.fertilizers.get(key, 0)) + amount

static func fertilizer_count(inventory: InventoryState, fertilizer_id: StringName) -> int:
	return int(inventory.fertilizers.get(String(fertilizer_id), 0)) if inventory != null else 0

static func take_fertilizer(inventory: InventoryState, fertilizer_id: StringName) -> bool:
	if inventory == null:
		return false
	var key := String(fertilizer_id)
	var count := int(inventory.fertilizers.get(key, 0))
	if count <= 0:
		return false
	if count == 1:
		inventory.fertilizers.erase(key)
	else:
		inventory.fertilizers[key] = count - 1
	return true

static func add_cutting(inventory: InventoryState, cutting: CuttingState) -> void:
	if inventory != null and cutting != null:
		inventory.cuttings.append(cutting)

static func find_cutting(inventory: InventoryState, item_id: String) -> CuttingState:
	var index := _find_item_index(inventory.cuttings if inventory != null else [], item_id)
	return inventory.cuttings[index] as CuttingState if index >= 0 else null

static func take_cutting(inventory: InventoryState, item_id: String) -> CuttingState:
	var index := _find_item_index(inventory.cuttings if inventory != null else [], item_id)
	return inventory.cuttings.pop_at(index) as CuttingState if index >= 0 else null

static func add_seed(inventory: InventoryState, seed: SeedState) -> void:
	if inventory != null and seed != null:
		inventory.seeds.append(seed)

static func find_seed(inventory: InventoryState, item_id: String) -> SeedState:
	var index := _find_item_index(inventory.seeds if inventory != null else [], item_id)
	return inventory.seeds[index] as SeedState if index >= 0 else null

static func take_seed(inventory: InventoryState, item_id: String) -> SeedState:
	var index := _find_item_index(inventory.seeds if inventory != null else [], item_id)
	return inventory.seeds.pop_at(index) as SeedState if index >= 0 else null

static func add_fruit(inventory: InventoryState, fruit: FruitState) -> void:
	if inventory != null and fruit != null:
		inventory.fruits.append(fruit)

static func find_fruit(inventory: InventoryState, item_id: String) -> FruitState:
	var index := _find_item_index(inventory.fruits if inventory != null else [], item_id)
	return inventory.fruits[index] as FruitState if index >= 0 else null

static func take_fruit(inventory: InventoryState, item_id: String) -> FruitState:
	var index := _find_item_index(inventory.fruits if inventory != null else [], item_id)
	return inventory.fruits.pop_at(index) as FruitState if index >= 0 else null

static func _find_item_index(items: Array, item_id: String) -> int:
	for index in range(items.size()):
		if items[index] != null and String(items[index].item_id) == item_id:
			return index
	return -1
