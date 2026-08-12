class_name SaveItemMapper
extends RefCounted

static func inventory_to_dictionary(inventory: InventoryState) -> Dictionary:
	var cuttings: Array[Dictionary] = []
	var seeds: Array[Dictionary] = []
	var fruits: Array[Dictionary] = []
	for item in inventory.cuttings:
		cuttings.append(_cutting_to_dictionary(item))
	for item in inventory.seeds:
		seeds.append(_seed_to_dictionary(item))
	for item in inventory.fruits:
		fruits.append(_fruit_to_dictionary(item))
	return {
		"fertilizers": inventory.fertilizers.duplicate(true),
		"cuttings": cuttings,
		"seeds": seeds,
		"fruits": fruits,
	}

static func inventory_from_dictionary(source: Variant) -> InventoryState:
	var inventory := InventoryState.new()
	if not (source is Dictionary):
		return inventory
	var data: Dictionary = source
	var fertilizers: Variant = data.get("fertilizers", {})
	if fertilizers is Dictionary:
		for key in fertilizers:
			var count := maxi(0, int(fertilizers[key]))
			if count > 0:
				inventory.fertilizers[String(key)] = count
	for value in data.get("cuttings", []):
		if value is Dictionary:
			inventory.cuttings.append(_cutting_from_dictionary(value))
	for value in data.get("seeds", []):
		if value is Dictionary:
			inventory.seeds.append(_seed_from_dictionary(value))
	for value in data.get("fruits", []):
		if value is Dictionary:
			inventory.fruits.append(_fruit_from_dictionary(value))
	return inventory

static func genome_to_dictionary(genome: GenomeSnapshot) -> Dictionary:
	if genome == null:
		return {}
	return {
		"species_id": String(genome.species_id),
		"ancestry": genome.ancestry.duplicate(),
		"traits": genome.traits.duplicate(true),
		"branch_traits": genome.branch_traits.duplicate(true),
	}

static func genome_from_dictionary(source: Variant) -> GenomeSnapshot:
	if not (source is Dictionary):
		return null
	var data: Dictionary = source
	var genome := GenomeSnapshot.new()
	genome.species_id = StringName(data.get("species_id", ""))
	for ancestor in data.get("ancestry", []):
		genome.ancestry.append(String(ancestor))
	genome.traits = _dictionary_copy(data.get("traits", {}))
	genome.branch_traits = _dictionary_copy(data.get("branch_traits", {}))
	return genome

static func _cutting_to_dictionary(item: CuttingState) -> Dictionary:
	return {
		"item_id": item.item_id,
		"source_plant_id": item.source_plant_id,
		"source_branch_id": item.source_branch_id,
		"genome": genome_to_dictionary(item.genome),
	}

static func _cutting_from_dictionary(data: Dictionary) -> CuttingState:
	var item := CuttingState.new()
	item.item_id = String(data.get("item_id", ""))
	item.source_plant_id = String(data.get("source_plant_id", ""))
	item.source_branch_id = String(data.get("source_branch_id", ""))
	item.genome = genome_from_dictionary(data.get("genome", {}))
	return item

static func _seed_to_dictionary(item: SeedState) -> Dictionary:
	return {
		"item_id": item.item_id,
		"source_plant_id": item.source_plant_id,
		"genome": genome_to_dictionary(item.genome),
	}

static func _seed_from_dictionary(data: Dictionary) -> SeedState:
	var item := SeedState.new()
	item.item_id = String(data.get("item_id", ""))
	item.source_plant_id = String(data.get("source_plant_id", ""))
	item.genome = genome_from_dictionary(data.get("genome", {}))
	return item

static func _fruit_to_dictionary(item: FruitState) -> Dictionary:
	return {
		"item_id": item.item_id,
		"source_plant_id": item.source_plant_id,
		"source_branch_id": item.source_branch_id,
		"hybrid": item.hybrid,
		"genome": genome_to_dictionary(item.genome),
	}

static func _fruit_from_dictionary(data: Dictionary) -> FruitState:
	var item := FruitState.new()
	item.item_id = String(data.get("item_id", ""))
	item.source_plant_id = String(data.get("source_plant_id", ""))
	item.source_branch_id = String(data.get("source_branch_id", ""))
	item.hybrid = bool(data.get("hybrid", false))
	item.genome = genome_from_dictionary(data.get("genome", {}))
	return item

static func _dictionary_copy(source: Variant) -> Dictionary:
	return source.duplicate(true) if source is Dictionary else {}
