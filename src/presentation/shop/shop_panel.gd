class_name ShopPanel
extends Control

signal fertilizer_buy_requested(fertilizer_id: StringName)
signal species_seed_buy_requested(species_id: StringName)
signal pot_buy_requested
signal close_requested

const CATEGORIES := [&"plants", &"pots", &"seeds", &"fertilizers", &"decorations", &"mutagens"]
const COLORS := {
	&"plants": Color("62b934"), &"pots": Color("e47b20"),
	&"seeds": Color("e9b72b"), &"fertilizers": Color("2699df"),
	&"decorations": Color("bd4fa2"), &"mutagens": Color("d73d68"),
}

@onready var tabs: VBoxContainer = %Tabs
@onready var grid: GridContainer = %ItemGrid
@onready var category_title: Label = %CategoryTitle
@onready var hover_description: Label = %HoverDescription
@onready var money_label: Label = %MoneyLabel
@onready var confirm: PanelContainer = %Confirm
@onready var confirm_name: Label = %ConfirmName
@onready var confirm_description: Label = %ConfirmDescription
@onready var confirm_price: Label = %ConfirmPrice
@onready var buy_button: Button = %BuyButton

var _catalogs: Dictionary = {}
var _money := 0
var _category: StringName = &"plants"
var _selected: Dictionary = {}
var _last_signature := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	%CloseButton.pressed.connect(_request_close)
	%CancelButton.pressed.connect(_hide_confirm)
	buy_button.pressed.connect(_buy_selected)
	_build_tabs()
	confirm.visible = false

func set_shop(fertilizers: Array[Dictionary], species: Array[Dictionary], pot_price: int, money: int) -> void:
	var signature := "%s|%s|%d|%d" % [str(fertilizers), str(species), pot_price, money]
	if signature == _last_signature: return
	_last_signature = signature
	_money = money
	money_label.text = str(money)
	_catalogs = {
		&"plants": [_placeholder(&"starter_plant", "Starter Plant", "Ready plants will appear here when their assets are connected.")],
		&"pots": [_item(&"new_pot", "New Pot", pot_price, true, "Adds another independent growing place.", &"pot")],
		&"seeds": _species_items(species),
		&"fertilizers": _fertilizer_items(fertilizers),
		&"decorations": [_placeholder(&"garden_decor", "Garden Decoration", "Decorative inventory will be connected with its assets.")],
		&"mutagens": [_placeholder(&"stable_mutagen", "Stable Mutagen", "Guaranteed mutation items will be connected with their assets.")],
	}
	_show_category(_category)

func invalidate() -> void:
	_last_signature = ""

func _build_tabs() -> void:
	for child in tabs.get_children(): child.queue_free()
	for category in CATEGORIES:
		var button := Button.new()
		button.custom_minimum_size = Vector2(190.0, 60.0)
		button.text = _pretty(String(category))
		button.add_theme_font_size_override(&"font_size", 20)
		button.pressed.connect(_show_category.bind(category))
		_apply_button_color(button, COLORS[category])
		tabs.add_child(button)

func _show_category(category: StringName) -> void:
	_category = category
	category_title.text = _pretty(String(category))
	category_title.add_theme_color_override(&"font_color", COLORS[category].lightened(0.25))
	hover_description.text = "Hover an item to see its description."
	_hide_confirm()
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	for item in _catalogs.get(category, []): _add_card(item)

func _add_card(item: Dictionary) -> void:
	var card := Button.new()
	card.custom_minimum_size = Vector2(190.0, 156.0)
	card.clip_contents = true
	card.disabled = not bool(item.get("unlocked", false))
	card.tooltip_text = String(item.get("description", ""))
	_apply_button_color(card, COLORS[_category].darkened(0.15))
	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_label := Label.new()
	name_label.text = String(item.get("name", "Item"))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override(&"font_size", 18)
	layout.add_child(name_label)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(spacer)
	layout.add_child(_price_row(int(item.get("price", 0)), bool(item.get("unlocked", false))))
	card.add_child(layout)
	card.mouse_entered.connect(_show_description.bind(item))
	card.pressed.connect(_open_confirm.bind(item))
	grid.add_child(card)

func _price_row(price: int, unlocked: bool) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var coin := TextureRect.new()
	coin.custom_minimum_size = Vector2(28.0, 28.0)
	coin.texture = UiAtlas.atlas_region(UiAtlas.BUTTONS, Rect2(72.0, 1625.0, 250.0, 250.0))
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(coin)
	var label := Label.new()
	label.text = str(price) if unlocked else "Locked"
	label.add_theme_font_size_override(&"font_size", 18)
	row.add_child(label)
	return row

func _open_confirm(item: Dictionary) -> void:
	_selected = item
	confirm_name.text = String(item.get("name", "Item"))
	confirm_description.text = String(item.get("description", ""))
	confirm_price.text = str(int(item.get("price", 0)))
	buy_button.disabled = not bool(item.get("unlocked", false)) or _money < int(item.get("price", 0))
	_apply_button_color(buy_button, COLORS[_category])
	confirm.visible = true

func _buy_selected() -> void:
	if _selected.is_empty(): return
	match StringName(_selected.get("action", &"")):
		&"pot": pot_buy_requested.emit()
		&"seed": species_seed_buy_requested.emit(StringName(_selected["id"]))
		&"fertilizer": fertilizer_buy_requested.emit(StringName(_selected["id"]))
	_hide_confirm()

func _hide_confirm() -> void:
	_selected = {}
	confirm.visible = false

func _show_description(item: Dictionary) -> void:
	hover_description.text = String(item.get("description", ""))

func _request_close() -> void:
	_hide_confirm()
	close_requested.emit()

func _species_items(catalog: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for source in catalog:
		var id := StringName(source["id"])
		result.append(_item(id, _pretty(String(id)), int(source["price"]), bool(source["unlocked"]), "A seed for growing %s." % _pretty(String(id)), &"seed"))
	return result

func _fertilizer_items(catalog: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for source in catalog:
		result.append(_item(source["id"], _pretty(String(source["id"])), int(source["price"]), bool(source["unlocked"]), "Universal plant food. Hidden mutation effects remain secret.", &"fertilizer"))
	return result

func _item(id: StringName, name: String, price: int, unlocked: bool, description: String, action: StringName) -> Dictionary:
	return {"id": id, "name": name, "price": price, "unlocked": unlocked, "description": description, "action": action}

func _placeholder(id: StringName, name: String, description: String) -> Dictionary:
	return _item(id, name, 0, false, description, &"")

func _apply_button_color(button: Button, color: Color) -> void:
	for state in [&"normal", &"hover", &"pressed", &"disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = color.lightened(0.12) if state == &"hover" else color
		style.bg_color.a = 0.55 if state == &"disabled" else 0.94
		style.border_width_left = 3; style.border_width_top = 3
		style.border_width_right = 3; style.border_width_bottom = 3
		style.border_color = color.lightened(0.35)
		style.corner_radius_top_left = 14; style.corner_radius_top_right = 14
		style.corner_radius_bottom_left = 14; style.corner_radius_bottom_right = 14
		button.add_theme_stylebox_override(state, style)

func _pretty(value: String) -> String:
	return value.replace("_", " ").capitalize()
