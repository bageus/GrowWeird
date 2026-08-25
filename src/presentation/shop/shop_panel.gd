class_name ShopPanel
extends VBoxContainer

signal fertilizer_buy_requested(fertilizer_id: StringName)
signal species_seed_buy_requested(species_id: StringName)
signal pot_buy_requested

var _last_signature: String = ""

func set_shop(
	fertilizer_catalog: Array[Dictionary],
	species_catalog: Array[Dictionary],
	pot_price: int,
	money: int
) -> void:
	var signature := "%s|%s|%d|%d" % [str(fertilizer_catalog), str(species_catalog), pot_price, money]
	if signature == _last_signature:
		return
	_last_signature = signature
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_add_header("Shop")
	_add_muted("Known materials are sold by name; their hidden mutation effects stay secret.")
	_add_header("Seeds")
	for item in species_catalog:
		_add_seed_row(item, money)
	_add_header("Fertilizers")
	for item in fertilizer_catalog:
		_add_fertilizer_row(item, money)
	_add_header("Expansion")
	var pot_button := Button.new()
	pot_button.text = "New pot · $%d" % pot_price
	pot_button.disabled = money < pot_price
	pot_button.pressed.connect(_emit_pot)
	add_child(pot_button)

func invalidate() -> void:
	_last_signature = ""

func _add_seed_row(item: Dictionary, money: int) -> void:
	var id := StringName(item.get("id", ""))
	var price := int(item.get("price", 0))
	var unlocked := bool(item.get("unlocked", false))
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = String(id).replace("_", " ").capitalize()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var button := Button.new()
	button.text = _seed_button_text(item, price)
	button.disabled = not unlocked or money < price
	button.pressed.connect(_emit_species_seed.bind(id))
	row.add_child(button)
	add_child(row)

func _add_fertilizer_row(item: Dictionary, money: int) -> void:
	var id := StringName(item.get("id", ""))
	var price := int(item.get("price", 0))
	var unlocked := bool(item.get("unlocked", false))
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = String(id).replace("_", " ").capitalize()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var button := Button.new()
	button.text = "$%d" % price if unlocked else "Keep experimenting"
	button.disabled = not unlocked or money < price
	button.pressed.connect(_emit_fertilizer.bind(id))
	row.add_child(button)
	add_child(row)

func _seed_button_text(item: Dictionary, price: int) -> String:
	if bool(item.get("unlocked", false)):
		return "$%d" % price
	if String(item.get("lock_reason", "")) == "pots":
		return "Need %d pots" % int(item.get("requires_pots", 1))
	return "Keep experimenting"

func _add_header(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	add_child(label)

func _add_muted(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.modulate = Color(1.0, 1.0, 1.0, 0.58)
	add_child(label)

func _emit_fertilizer(id: StringName) -> void:
	fertilizer_buy_requested.emit(id)

func _emit_species_seed(id: StringName) -> void:
	species_seed_buy_requested.emit(id)

func _emit_pot() -> void:
	pot_buy_requested.emit()
