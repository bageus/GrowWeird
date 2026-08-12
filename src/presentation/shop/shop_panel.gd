class_name ShopPanel
extends VBoxContainer

signal fertilizer_buy_requested(fertilizer_id: StringName)
signal pot_buy_requested

var _last_signature: String = ""

func set_shop(catalog: Array[Dictionary], pot_price: int, money: int) -> void:
	var signature := "%s|%d|%d" % [str(catalog), pot_price, money]
	if signature == _last_signature:
		return
	_last_signature = signature
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_add_header("Shop")
	_add_muted("Buy known materials. Their hidden effects stay hidden.")
	for item in catalog:
		_add_fertilizer_row(StringName(item.get("id", "")), int(item.get("price", 0)), money)
	_add_header("Expansion")
	var pot_button := Button.new()
	pot_button.text = "New pot · $%d" % pot_price
	pot_button.disabled = money < pot_price
	pot_button.pressed.connect(func() -> void: pot_buy_requested.emit())
	add_child(pot_button)

func invalidate() -> void:
	_last_signature = ""

func _add_fertilizer_row(id: StringName, price: int, money: int) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = String(id).replace("_", " ").capitalize()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var button := Button.new()
	button.text = "$%d" % price
	button.disabled = money < price
	button.pressed.connect(_emit_fertilizer.bind(id))
	row.add_child(button)
	add_child(row)

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
