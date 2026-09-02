class_name ShopPanel
extends Control

signal item_buy_requested(item: Dictionary)
signal close_requested

const CATEGORIES := [&"plants", &"pots", &"seeds", &"fertilizers", &"decorations", &"mutagens"]
const COLORS := {
	&"plants": Color("62b934"), &"pots": Color("e47b20"), &"seeds": Color("e9b72b"),
	&"fertilizers": Color("2699df"), &"decorations": Color("bd4fa2"), &"mutagens": Color("d73d68"),
}
const SPECIES := [&"starter_sprout", &"shade_fern", &"sun_creeper", &"starter_sprout", &"shade_fern"]
const PLANT_NAMES := ["Starter Plant", "Shade Fern", "Sun Creeper", "Young Starter", "Young Fern"]
const SEED_NAMES := ["Starter Seed", "Shade Fern Seed", "Sun Creeper Seed", "Hardy Seed", "Deep Shade Seed"]
const POT_NAMES := ["Clay Pot", "Ceramic Pot", "Stone Pot", "Wooden Pot", "Golden Pot"]
const DECORATIONS := [&"garden_gnome", &"fairy_lights", &"crystal_cluster", &"wooden_fence", &"water_fountain"]
const MUTAGENS := [&"stable_mutagen", &"spore_mutagen", &"crystal_mutagen", &"floral_mutagen", &"predatory_mutagen"]

@onready var tabs: VBoxContainer = %Tabs
@onready var grid: GridContainer = %ItemGrid
@onready var category_hud: PanelContainer = %CategoryHud
@onready var money_label: Label = %MoneyLabel
@onready var confirm: PanelContainer = %Confirm
@onready var confirm_name: Label = %ConfirmName
@onready var confirm_description: Label = %ConfirmDescription
@onready var confirm_price: Label = %ConfirmPrice
@onready var confirm_preview: TextureRect = %ConfirmPreview
@onready var quantity_slider: HSlider = %QuantitySlider
@onready var quantity_label: Label = %QuantityLabel
@onready var buy_button: Button = %BuyButton

var _catalogs: Dictionary = {}
var _money := 0
var _category: StringName = &"plants"
var _selected: Dictionary = {}
var _stock: Dictionary = {}
var _last_signature := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	%BalanceArt.texture = UiAtlas.HUD_BALANCE
	UiAtlas.configure_balance_plus(%BalancePlus)
	%CloseButton.pressed.connect(_request_close)
	%CancelButton.pressed.connect(_hide_confirm)
	buy_button.pressed.connect(_buy_selected)
	quantity_slider.value_changed.connect(_refresh_purchase_preview)
	_build_tabs()
	confirm.visible = false

func set_shop(fertilizers: Array[Dictionary], _species: Array[Dictionary], _pot_price: int, money: int) -> void:
	var signature := "%s|%d" % [str(fertilizers), money]
	if signature == _last_signature: return
	_last_signature = signature; _money = money; money_label.text = str(money)
	_catalogs = {
		&"plants": _plant_items(), &"pots": _pot_items(), &"seeds": _seed_items(),
		&"fertilizers": _fertilizer_items(fertilizers), &"decorations": _misc_items(DECORATIONS, &"decoration"),
		&"mutagens": _misc_items(MUTAGENS, &"mutagen"),
	}
	_show_category(_category)

func invalidate() -> void: _last_signature = ""

func _build_tabs() -> void:
	for child in tabs.get_children(): child.queue_free()
	for category in CATEGORIES:
		var button := Button.new()
		button.custom_minimum_size = Vector2(190.0, 60.0); button.text = _pretty(String(category))
		button.add_theme_font_size_override(&"font_size", 20); button.pressed.connect(_show_category.bind(category))
		_apply_button_color(button, COLORS[category]); tabs.add_child(button)

func _show_category(category: StringName) -> void:
	_category = category; _hide_confirm(); _apply_category_hud(COLORS[category])
	for child in grid.get_children(): grid.remove_child(child); child.queue_free()
	for item in _catalogs.get(category, []):
		if int(item.get("stock", 0)) > 0: _add_card(item)

func _add_card(item: Dictionary) -> void:
	var card := Button.new()
	card.custom_minimum_size = Vector2(174.0, 156.0); card.clip_contents = true
	card.disabled = not bool(item.get("unlocked", false)); card.tooltip_text = String(item.get("description", ""))
	_apply_button_color(card, COLORS[_category].darkened(0.15))
	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10); layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_label := Label.new()
	name_label.text = String(item.get("name", "Item")); name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; name_label.add_theme_font_size_override(&"font_size", 18); layout.add_child(name_label)
	var preview := TextureRect.new(); preview.custom_minimum_size = Vector2(0.0, 76.0); preview.texture = _preview_texture(item)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(preview)
	var spacer := Control.new(); spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL; layout.add_child(spacer)
	layout.add_child(_price_row(int(item.get("price", 1)), bool(item.get("unlocked", false))))
	card.add_child(layout)
	if int(item.get("stock", 1)) > 1: card.add_child(_quantity_badge(int(item["stock"])))
	card.pressed.connect(_open_confirm.bind(item)); grid.add_child(card)

func _price_row(price: int, unlocked: bool) -> Control:
	var row := HBoxContainer.new(); row.alignment = BoxContainer.ALIGNMENT_CENTER; row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var coin := TextureRect.new()
	coin.custom_minimum_size = Vector2(28.0, 28.0); coin.texture = UiAtlas.atlas_region(UiAtlas.BUTTONS, Rect2(72.0, 1625.0, 250.0, 250.0))
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; row.add_child(coin)
	var label := Label.new(); label.text = str(price) if unlocked else "Locked"; label.add_theme_font_size_override(&"font_size", 18); row.add_child(label)
	return row

func _open_confirm(item: Dictionary) -> void:
	_selected = item; confirm_name.text = String(item.get("name", "Item"))
	confirm_description.text = String(item.get("description", "")); confirm_preview.texture = _preview_texture(item)
	quantity_slider.min_value = 1.0; quantity_slider.max_value = float(int(item.get("stock", 1))); quantity_slider.step = 1.0; quantity_slider.value = 1.0
	quantity_slider.editable = int(item.get("stock", 1)) > 1
	_refresh_purchase_preview(1.0)
	_apply_button_color(buy_button, COLORS[_category]); confirm.visible = true

func _buy_selected() -> void:
	if _selected.is_empty(): return
	var quantity := maxi(1, int(round(quantity_slider.value)))
	var item_id := String(_selected.get("id", "")); var purchase := _selected.duplicate(true)
	purchase["amount"] = quantity; purchase["price"] = int(_selected.get("price", 1)) * quantity
	_stock[item_id] = maxi(0, int(_stock.get(item_id, 0)) - quantity)
	_hide_confirm(); _rebuild_catalog_stock(); _show_category(_category); item_buy_requested.emit(purchase)

func _refresh_purchase_preview(value: float) -> void:
	if _selected.is_empty(): return
	var quantity := maxi(1, int(round(value))); var unit_price := int(_selected.get("price", 1))
	quantity_label.text = "Quantity: %d / %d" % [quantity, int(_selected.get("stock", 1))]
	confirm_price.text = str(unit_price * quantity)
	buy_button.disabled = not bool(_selected.get("unlocked", false)) or _money < unit_price * quantity

func _hide_confirm() -> void: _selected = {}; confirm.visible = false
func _request_close() -> void: _hide_confirm(); close_requested.emit()

func _rebuild_catalog_stock() -> void:
	for category in _catalogs:
		for item in _catalogs[category]: item["stock"] = int(_stock.get(String(item.get("id", "")), 0))

func _plant_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	result.append(_item(&"starter_cuttings", SPECIES[0], "Starter Branches", "Plantable branches delivered to inventory.", &"cutting", true, 2, "res://assets/tree/tree_05.png"))
	result.append(_item(&"fern_cutting", SPECIES[1], "Fern Branch", "A plantable branch delivered without a pot.", &"cutting", true, 1, "res://assets/tree/tree_05.png"))
	result.append(_item(&"starter_plant", SPECIES[0], PLANT_NAMES[0], "A first-stage shoot supplied in its own pot.", &"potted_plant", true, 1, "res://assets/tree/tree_01.png"))
	result.append(_item(&"young_ferns", SPECIES[1], PLANT_NAMES[1], "First-stage shoots supplied in their own pots.", &"potted_plant", true, 2, "res://assets/tree/tree_01.png"))
	result.append(_item(&"sun_creeper_plant", SPECIES[2], PLANT_NAMES[2], "A first-stage shoot supplied in its own pot.", &"potted_plant", true, 1, "res://assets/tree/tree_01.png"))
	return result

func _pot_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in range(5): result.append(_item(StringName("pot_%d" % index), &"new_pot", POT_NAMES[index], "Adds an empty independent growing place.", &"pot", true, 1, "res://assets/pot/pot_%02d.png" % (index + 1)))
	return result

func _seed_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in range(5): result.append(_item(StringName("seed_%d" % index), SPECIES[index], SEED_NAMES[index], "A seed that can be planted in a free pot.", &"seed", true, 4))
	return result

func _fertilizer_items(catalog: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in range(5):
		var source: Dictionary = catalog[index % catalog.size()] if not catalog.is_empty() else {}
		var source_id := StringName(source.get("id", &""))
		result.append(_item(StringName("fertilizer_%d" % index), source_id, _pretty(String(source_id)) if not String(source_id).is_empty() else "Unavailable", "Universal plant food with hidden effects.", &"fertilizer", not source.is_empty(), 3))
	return result

func _misc_items(ids: Array, action: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id in ids:
		var item_id := StringName(id)
		result.append(_item(item_id, item_id, _pretty(String(item_id)), "A %s item stored in the shared inventory." % _pretty(String(action)), action))
	return result

func _item(id: StringName, source_id: StringName, name: String, description: String, action: StringName, unlocked: bool = true, stock: int = 1, preview_path: String = "") -> Dictionary:
	var key := String(id)
	if not _stock.has(key): _stock[key] = maxi(0, stock)
	return {"id": id, "source_id": source_id, "name": name, "price": 1, "stock": int(_stock[key]), "preview_path": preview_path, "unlocked": unlocked, "description": description, "action": action}

func _preview_texture(item: Dictionary) -> Texture2D:
	var path := String(item.get("preview_path", ""))
	if not path.is_empty() and ResourceLoader.exists(path): return load(path) as Texture2D
	return UiAtlas.background(CATEGORIES.find(_category) % 2)

func _quantity_badge(amount: int) -> Label:
	var badge := Label.new(); badge.text = "×%d" % amount; badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.set_anchors_preset(Control.PRESET_TOP_RIGHT); badge.position = Vector2(-45.0, 6.0); badge.size = Vector2(38.0, 28.0)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; badge.add_theme_font_size_override(&"font_size", 18)
	badge.add_theme_color_override(&"font_color", Color("fff1a8")); badge.add_theme_constant_override(&"outline_size", 5)
	return badge

func _apply_category_hud(color: Color) -> void:
	var style := StyleBoxFlat.new(); style.bg_color = color.darkened(0.72); style.bg_color.a = 0.96
	style.border_width_left = 4; style.border_width_top = 4; style.border_width_right = 4; style.border_width_bottom = 4
	style.border_color = color.lightened(0.2); style.corner_radius_top_left = 18; style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18; style.corner_radius_bottom_right = 18
	style.content_margin_left = 16; style.content_margin_top = 16; style.content_margin_right = 16; style.content_margin_bottom = 16
	category_hud.add_theme_stylebox_override(&"panel", style)

func _apply_button_color(button: Button, color: Color) -> void:
	for state in [&"normal", &"hover", &"pressed", &"disabled"]:
		var style := StyleBoxFlat.new(); style.bg_color = color.lightened(0.12) if state == &"hover" else color
		style.bg_color.a = 0.55 if state == &"disabled" else 0.94
		style.border_width_left = 3; style.border_width_top = 3; style.border_width_right = 3; style.border_width_bottom = 3
		style.border_color = color.lightened(0.35); style.corner_radius_top_left = 14; style.corner_radius_top_right = 14
		style.corner_radius_bottom_left = 14; style.corner_radius_bottom_right = 14; button.add_theme_stylebox_override(state, style)

func _pretty(value: String) -> String: return value.replace("_", " ").capitalize()
