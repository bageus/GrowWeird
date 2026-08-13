class_name InventoryPanel
extends VBoxContainer

signal fertilizer_use_requested(fertilizer_id: StringName)
signal cutting_plant_requested(item_id: String)
signal cutting_graft_requested(item_id: String)
signal seed_plant_requested(item_id: String)
signal fruit_seed_requested(item_id: String)
signal item_sell_requested(kind: StringName, item_id: String)
signal item_recycle_requested(kind: StringName, item_id: String)

var _last_signature: String = ""

func set_inventory(inventory: InventoryState, item_prices: Dictionary = {}) -> void:
	var signature := _signature(inventory, item_prices)
	if signature == _last_signature:
		return
	_last_signature = signature
	_clear_rows()
	_add_header("Inventory")
	if inventory == null:
		_add_muted("No inventory")
		return
	_add_fertilizers(inventory)
	_add_cuttings(inventory, item_prices)
	_add_seeds(inventory, item_prices)
	_add_fruits(inventory, item_prices)

func invalidate() -> void:
	_last_signature = ""

func _clear_rows() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

func _add_fertilizers(inventory: InventoryState) -> void:
	_add_header("Fertilizers")
	if inventory.fertilizers.is_empty():
		_add_muted("Empty")
		return
	var ids := inventory.fertilizers.keys()
	ids.sort()
	for raw_id in ids:
		var id := StringName(raw_id)
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = "%s ×%d" % [_pretty_id(String(id)), int(inventory.fertilizers[raw_id])]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var button := Button.new()
		button.text = "Use"
		button.pressed.connect(_emit_fertilizer.bind(id))
		row.add_child(button)
		add_child(row)

func _add_cuttings(inventory: InventoryState, prices: Dictionary) -> void:
	_add_header("Cuttings (%d)" % inventory.cuttings.size())
	if inventory.cuttings.is_empty():
		_add_muted("No cuttings")
		return
	for cutting in inventory.cuttings:
		if cutting == null:
			continue
		var row := _genetic_row(cutting.genome, _pretty_id(String(cutting.genome.species_id)), cutting.genome.ancestry.size())
		row.add_child(_action_button("Plant", _emit_cutting_plant.bind(cutting.item_id)))
		row.add_child(_action_button("Graft", _emit_cutting_graft.bind(cutting.item_id)))
		row.add_child(_sell_button(&"cutting", cutting.item_id, prices))
		row.add_child(_recycle_button(&"cutting", cutting.item_id))
		add_child(row)

func _add_seeds(inventory: InventoryState, prices: Dictionary) -> void:
	_add_header("Seeds (%d)" % inventory.seeds.size())
	if inventory.seeds.is_empty():
		_add_muted("No seeds")
		return
	for seed in inventory.seeds:
		if seed == null:
			continue
		var row := _genetic_row(seed.genome, _pretty_id(String(seed.genome.species_id)), seed.genome.ancestry.size())
		row.add_child(_action_button("Plant", _emit_seed_plant.bind(seed.item_id)))
		row.add_child(_sell_button(&"seed", seed.item_id, prices))
		row.add_child(_recycle_button(&"seed", seed.item_id))
		add_child(row)

func _add_fruits(inventory: InventoryState, prices: Dictionary) -> void:
	_add_header("Fruits (%d)" % inventory.fruits.size())
	if inventory.fruits.is_empty():
		_add_muted("No fruits")
		return
	for fruit in inventory.fruits:
		if fruit == null:
			continue
		var prefix := "Hybrid " if fruit.hybrid else ""
		var row := _genetic_row(fruit.genome, prefix + _pretty_id(String(fruit.genome.species_id)), fruit.genome.ancestry.size())
		row.add_child(_action_button("Seed", _emit_fruit_seed.bind(fruit.item_id)))
		row.add_child(_sell_button(&"fruit", fruit.item_id, prices))
		row.add_child(_recycle_button(&"fruit", fruit.item_id))
		add_child(row)

func _genetic_row(genome: GenomeSnapshot, title: String, ancestry_count: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	var preview := GeneticItemPreview.new()
	preview.set_genome(genome)
	row.add_child(preview)
	var label := Label.new()
	label.text = "%s · lineage %d" % [title, ancestry_count]
	label.tooltip_text = "Preview shows phenotype only; hidden mutation values stay secret."
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	return row

func _sell_button(kind: StringName, item_id: String, prices: Dictionary) -> Button:
	return _action_button(
		"Sell · $%d" % int(prices.get(item_id, 0)),
		_emit_item_sell.bind(kind, item_id)
	)

func _recycle_button(kind: StringName, item_id: String) -> Button:
	var button := _action_button("Compost", _emit_item_recycle.bind(kind, item_id))
	button.tooltip_text = "Destroy this genetic item and turn it into Compost Mix."
	return button

func _action_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	return button

func _add_header(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	add_child(label)

func _add_muted(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.modulate = Color(1.0, 1.0, 1.0, 0.55)
	add_child(label)

func _signature(inventory: InventoryState, prices: Dictionary) -> String:
	if inventory == null:
		return "null"
	var parts: Array[String] = [str(inventory.fertilizers), str(prices)]
	for cutting in inventory.cuttings:
		parts.append("c:%s" % cutting.item_id)
	for seed in inventory.seeds:
		parts.append("s:%s" % seed.item_id)
	for fruit in inventory.fruits:
		parts.append("f:%s" % fruit.item_id)
	return "|".join(parts)

func _pretty_id(value: String) -> String:
	return value.replace("_", " ").capitalize()

func _emit_fertilizer(id: StringName) -> void:
	fertilizer_use_requested.emit(id)

func _emit_cutting_plant(item_id: String) -> void:
	cutting_plant_requested.emit(item_id)

func _emit_cutting_graft(item_id: String) -> void:
	cutting_graft_requested.emit(item_id)

func _emit_seed_plant(item_id: String) -> void:
	seed_plant_requested.emit(item_id)

func _emit_fruit_seed(item_id: String) -> void:
	fruit_seed_requested.emit(item_id)

func _emit_item_sell(kind: StringName, item_id: String) -> void:
	item_sell_requested.emit(kind, item_id)

func _emit_item_recycle(kind: StringName, item_id: String) -> void:
	item_recycle_requested.emit(kind, item_id)
