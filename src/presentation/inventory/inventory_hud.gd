class_name InventoryHud
extends SceneDraggablePanel

signal item_selected(kind: StringName, item_id: String, count: int, title: String)

@onready var items: VBoxContainer = $Layout/Scroll/Items

var _signature := ""

func set_inventory(inventory: InventoryState) -> void:
	var signature := _inventory_signature(inventory)
	if signature == _signature:
		return
	_signature = signature
	_rebuild(inventory)

func invalidate() -> void:
	_signature = ""

func _rebuild(inventory: InventoryState) -> void:
	for child in items.get_children():
		items.remove_child(child)
		child.queue_free()
	if inventory == null:
		_add_empty()
		return
	var added := 0
	var fertilizer_ids := inventory.fertilizers.keys()
	fertilizer_ids.sort()
	for raw_id in fertilizer_ids:
		var count := int(inventory.fertilizers[raw_id])
		if count <= 0:
			continue
		var item_id := String(raw_id)
		var title := _pretty_id(item_id)
		_add_item(&"fertilizer", item_id, count, title)
		added += 1
	for cutting in inventory.cuttings:
		if cutting == null:
			continue
		_add_item(&"cutting", cutting.item_id, 1, _genetic_title("Cutting", cutting.genome))
		added += 1
	for seed_state in inventory.seeds:
		if seed_state == null:
			continue
		_add_item(&"seed", seed_state.item_id, 1, _genetic_title("Seed", seed_state.genome))
		added += 1
	for fruit in inventory.fruits:
		if fruit == null:
			continue
		_add_item(&"fruit", fruit.item_id, 1, _genetic_title("Fruit", fruit.genome))
		added += 1
	if added == 0:
		_add_empty()

func _add_item(kind: StringName, item_id: String, count: int, title: String) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(48.0, 48.0)
	button.text = "●"
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	var count_suffix := ""
	if count > 1:
		count_suffix = " ×%d" % count
	button.tooltip_text = "%s%s · click for actions" % [title, count_suffix]
	button.pressed.connect(_emit_selected.bind(kind, item_id, count, title))
	items.add_child(button)

func _add_empty() -> void:
	var label := Label.new()
	label.text = "Inventory empty"
	label.modulate = Color(1.0, 1.0, 1.0, 0.55)
	items.add_child(label)

func _emit_selected(kind: StringName, item_id: String, count: int, title: String) -> void:
	item_selected.emit(kind, item_id, count, title)

func _genetic_title(prefix: String, genome: GenomeSnapshot) -> String:
	if genome == null or String(genome.species_id).is_empty():
		return prefix
	return "%s · %s" % [prefix, _pretty_id(String(genome.species_id))]

func _inventory_signature(inventory: InventoryState) -> String:
	if inventory == null:
		return "null"
	var parts: Array[String] = [str(inventory.fertilizers)]
	for cutting in inventory.cuttings:
		parts.append("c:%s" % cutting.item_id)
	for seed_state in inventory.seeds:
		parts.append("s:%s" % seed_state.item_id)
	for fruit in inventory.fruits:
		parts.append("f:%s" % fruit.item_id)
	return "|".join(parts)

func _pretty_id(value: String) -> String:
	return value.replace("_", " ").capitalize()
