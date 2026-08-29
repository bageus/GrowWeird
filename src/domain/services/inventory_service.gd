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
	return take_fertilizer_amount(inventory, fertilizer_id, 1) == 1

static func take_fertilizer_amount(inventory: InventoryState, fertilizer_id: StringName, amount: int) -> int:
	if inventory == null or amount <= 0:
		return 0
	var key := String(fertilizer_id)
	var count := int(inventory.fertilizers.get(key, 0))
	var taken := mini(count, amount)
	if taken <= 0:
		return 0
	var remaining := count - taken
	if remaining <= 0:
		inventory.fertilizers.erase(key)
	else:
		inventory.fertilizers[key] = remaining
	return taken

static func add_cutting(inventory: InventoryState, cutting: CuttingState) -> void:
	if inventory != null and cutting != null:
		inventory.cuttings.append(cutting)

static func find_cutting(inventory: InventoryState, item_id: String) -> CuttingState:
	if inventory == null:
		return null
	var index := _find_item_index(inventory.cuttings, item_id)
	return inventory.cuttings[index] if index >= 0 else null

static func take_cutting(inventory: InventoryState, item_id: String) -> CuttingState:
	if inventory == null:
		return null
	var index := _find_item_index(inventory.cuttings, item_id)
	return inventory.cuttings.pop_at(index) if index >= 0 else null

static func add_seed(inventory: InventoryState, seed_state: SeedState) -> void:
	if inventory != null and seed_state != null:
		inventory.seeds.append(seed_state)

static func find_seed(inventory: InventoryState, item_id: String) -> SeedState:
	if inventory == null:
		return null
	var index := _find_item_index(inventory.seeds, item_id)
	return inventory.seeds[index] if index >= 0 else null

static func take_seed(inventory: InventoryState, item_id: String) -> SeedState:
	if inventory == null:
		return null
	var index := _find_item_index(inventory.seeds, item_id)
	return inventory.seeds.pop_at(index) if index >= 0 else null

static func add_fruit(inventory: InventoryState, fruit: FruitState) -> void:
	if inventory != null and fruit != null:
		inventory.fruits.append(fruit)

static func find_fruit(inventory: InventoryState, item_id: String) -> FruitState:
	if inventory == null:
		return null
	var index := _find_item_index(inventory.fruits, item_id)
	return inventory.fruits[index] if index >= 0 else null

static func take_fruit(inventory: InventoryState, item_id: String) -> FruitState:
	if inventory == null:
		return null
	var index := _find_item_index(inventory.fruits, item_id)
	return inventory.fruits.pop_at(index) if index >= 0 else null

static func _find_item_index(items: Array, item_id: String) -> int:
	for index in range(items.size()):
		if items[index] != null and String(items[index].item_id) == item_id:
			return index
	return -1
