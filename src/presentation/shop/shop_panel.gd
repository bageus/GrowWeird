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
const CATEGORY_FRAMES := {
	&"fertilizers": Vector2i(0, 0), &"plants": Vector2i(0, 1),
	&"mutagens": Vector2i(0, 2), &"decorations": Vector2i(0, 3),
	&"seeds": Vector2i(1, 0), &"pots": Vector2i(1, 1),
}

@onready var tabs: Control = %Tabs
@onready var grid: GridContainer = %ItemGrid
@onready var category_hud: PanelContainer = %CategoryHud
@onready var confirm: Control = %Confirm
@onready var confirm_name: Label = %ConfirmName
@onready var confirm_description: Label = %ConfirmDescription
@onready var confirm_price: Label = %ConfirmPrice
@onready var confirm_preview: TextureRect = %ConfirmPreview
@onready var quantity_label: Label = %QuantityLabel
@onready var buy_button: Button = %BuyButton
@onready var quantity_minus: Button = %QuantityMinus
@onready var quantity_plus: Button = %QuantityPlus

var _catalogs: Dictionary = {}
var _money := 0
var _category: StringName = &"plants"
var _selected: Dictionary = {}
var _stock: Dictionary = {}
var _last_signature := ""
var _purchase_quantity := 1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	$Window/Content/Header/Title.texture = UiAtlas.shop_title_texture()
	%Awning.texture = UiAtlas.shop_awning_texture()
	($Window as PanelContainer).add_theme_stylebox_override(&"panel", CommerceUiStyle.shop_outer_panel())
	category_hud.add_theme_stylebox_override(&"panel", CommerceUiStyle.shop_inner_panel())
	UiAtlas.configure_close_button(%CloseButton)
	_configure_buy_dialog_art()
	%CloseButton.pressed.connect(_request_close)
	%ConfirmClose.pressed.connect(_hide_confirm)
	buy_button.pressed.connect(_buy_selected)
	quantity_minus.pressed.connect(_change_quantity.bind(-1))
	quantity_plus.pressed.connect(_change_quantity.bind(1))
	_build_tabs()
	confirm.visible = false

func _configure_buy_dialog_art() -> void:
	TransactionDialogVisual.configure({
		"root": confirm, "background": %ConfirmBackground, "banner": %ConfirmBanner,
		"title": confirm_name, "close": %ConfirmClose, "preview": confirm_preview,
		"description": confirm_description, "quantity": %QuantityControl,
		"quantity_background": %QuantityBackground, "minus": quantity_minus,
		"quantity_label": quantity_label, "plus": quantity_plus, "count": %CountControl,
		"count_background": %CountBackground, "action": buy_button,
	}, &"buy", Vector2i.ZERO)

func set_shop(fertilizers: Array[Dictionary], _species: Array[Dictionary], _pot_price: int, money: int) -> void:
	var signature := "%s|%d" % [str(fertilizers), money]
	if signature == _last_signature: return
	_last_signature = signature; _money = money
	_catalogs = {
		&"plants": _plant_items(), &"pots": _pot_items(), &"seeds": _seed_items(),
		&"fertilizers": _fertilizer_items(fertilizers), &"decorations": _misc_items(DECORATIONS, &"decoration"),
		&"mutagens": _misc_items(MUTAGENS, &"mutagen"),
	}
	_show_category(_category)

func invalidate() -> void: _last_signature = ""

func _build_tabs() -> void:
	for child in tabs.get_children(): child.queue_free()
	for index in range(CATEGORIES.size()):
		var category: StringName = CATEGORIES[index]
		var button := Button.new()
		button.custom_minimum_size = Vector2(190.0, 60.0)
		button.position = Vector2(5.0, float(index * 68))
		button.size = Vector2(190.0, 60.0)
		var frame: Vector2i = CATEGORY_FRAMES[category]
		UiAtlas.configure_button(button, frame.x, frame.y)
		button.pressed.connect(_show_category.bind(category)); tabs.add_child(button)

func _show_category(category: StringName) -> void:
	_category = category; _hide_confirm(); _apply_category_hud(COLORS[category])
	for child in grid.get_children(): grid.remove_child(child); child.queue_free()
	for item in _catalogs.get(category, []):
		if int(item.get("stock", 0)) > 0: _add_card(item)

func _add_card(item: Dictionary) -> void:
	var card := Button.new()
	card.custom_minimum_size = Vector2(158.0, 156.0); card.clip_contents = true
	card.disabled = not bool(item.get("unlocked", false)); card.tooltip_text = String(item.get("description", ""))
	_configure_lot_button(card)
	var name_label := Label.new()
	name_label.position = Vector2(10.0, 7.0); name_label.size = Vector2(144.0, 28.0)
	name_label.text = String(item.get("name", "Item")); name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; name_label.add_theme_font_size_override(&"font_size", 16)
	name_label.add_theme_color_override(&"font_color", Color(0.24, 0.105, 0.035, 1.0)); card.add_child(name_label)
	var preview := TextureRect.new(); preview.position = Vector2(20.0, 35.0); preview.size = Vector2(118.0, 78.0); preview.texture = _preview_texture(item)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(preview)
	var unlocked := bool(item.get("unlocked", false))
	var price_hud := Panel.new(); price_hud.position = Vector2(37.0, 116.0); price_hud.size = Vector2(84.0, 34.0)
	price_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE; price_hud.add_theme_stylebox_override(&"panel", _lot_price_style(COLORS[_category])); card.add_child(price_hud)
	var coin := UiAtlas.CoinFace.new(); coin.position = Vector2(6.0, 5.0); coin.size = Vector2(24.0, 24.0); coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin.visible = unlocked; price_hud.add_child(coin)
	var price := Label.new(); price.position = Vector2(31.0 if unlocked else 5.0, 2.0); price.size = Vector2(48.0 if unlocked else 74.0, 30.0)
	price.text = str(int(item.get("price", 1))) if unlocked else "Locked"; price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; price.add_theme_font_size_override(&"font_size", 17); price_hud.add_child(price)
	var badge: Control = null
	if int(item.get("stock", 1)) > 1: badge = _quantity_badge(int(item["stock"])); card.add_child(badge)
	card.pressed.connect(_open_confirm.bind(item)); grid.add_child(card)

func _configure_lot_button(card: Button) -> void:
	CommerceUiStyle.shop_lot(card, COLORS[_category])
func _open_confirm(item: Dictionary) -> void:
	_selected = item
	confirm_description.text = "%s\n%s" % [String(item.get("name", "Item")), String(item.get("description", ""))]
	TransactionDialogVisual.fit_description(confirm_description)
	confirm_preview.texture = _preview_texture(item)
	_purchase_quantity = 1
	_refresh_purchase_preview()
	confirm.visible = true

func _buy_selected() -> void:
	if _selected.is_empty(): return
	var quantity := _purchase_quantity
	var item_id := String(_selected.get("id", "")); var purchase := _selected.duplicate(true)
	purchase["amount"] = quantity; purchase["price"] = int(_selected.get("price", 1)) * quantity
	_stock[item_id] = maxi(0, int(_stock.get(item_id, 0)) - quantity)
	_hide_confirm(); _rebuild_catalog_stock(); _show_category(_category); item_buy_requested.emit(purchase)

func _change_quantity(delta: int) -> void:
	if _selected.is_empty(): return
	_purchase_quantity = clampi(_purchase_quantity + delta, 1, int(_selected.get("stock", 1)))
	_refresh_purchase_preview()

func _refresh_purchase_preview() -> void:
	if _selected.is_empty(): return
	var stock := int(_selected.get("stock", 1)); var unit_price := int(_selected.get("price", 1))
	quantity_label.text = "%d / %d" % [_purchase_quantity, stock]
	var can_change_quantity := stock > 1
	quantity_minus.visible = can_change_quantity
	quantity_plus.visible = can_change_quantity
	quantity_minus.disabled = not can_change_quantity or _purchase_quantity <= 1
	quantity_plus.disabled = not can_change_quantity or _purchase_quantity >= stock
	confirm_price.text = str(unit_price * _purchase_quantity)
	buy_button.disabled = not bool(_selected.get("unlocked", false)) or _money < unit_price * _purchase_quantity

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
	for index in range(5):
		var item := _item(StringName("seed_%d" % index), SPECIES[index], SEED_NAMES[index], "A seed that can be planted in a free pot.", &"seed", true, 4)
		item["seed_frame"] = randi_range(0, 7)
		result.append(item)
	return result

func _fertilizer_items(catalog: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var stage_catalog: Array[Dictionary] = []
	for source in catalog:
		if String(source.get("id", "")).begins_with("fertilizer_atlas_3_"):
			stage_catalog.append(source)
	for index in range(stage_catalog.size()):
		var source: Dictionary = stage_catalog[index]
		var source_id := StringName(source.get("id", &""))
		result.append(_item(StringName("fertilizer_%d" % index), source_id, _pretty(String(source_id).trim_prefix("fertilizer_atlas_3_")), "Doubles growth and holds nutrition in the favorable zone during its matching stage.", &"fertilizer", true, 3))
	return result

func _misc_items(ids: Array, action: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id in ids:
		var item_id := StringName(id)
		result.append(_item(item_id, item_id, _pretty(String(item_id)), "A %s item stored in the shared inventory." % _pretty(String(action)), action))
	return result

func _item(id: StringName, source_id: StringName, display_name: String, description: String, action: StringName, unlocked: bool = true, stock: int = 1, preview_path: String = "") -> Dictionary:
	var key := String(id)
	if not _stock.has(key): _stock[key] = maxi(0, stock)
	return {"id": id, "source_id": source_id, "name": display_name, "price": 1, "stock": int(_stock[key]), "preview_path": preview_path, "unlocked": unlocked, "description": description, "action": action}

func _preview_texture(item: Dictionary) -> Texture2D:
	if StringName(item.get("action", &"")) == &"cutting":
		return _cutting_texture(String(item.get("id", "")))
	if StringName(item.get("action", &"")) == &"fertilizer":
		return FertilizerOfferArt.texture_for(StringName(item.get("source_id", &"")))
	if item.has("seed_frame"):
		var texture := AtlasTexture.new()
		var frame := int(item["seed_frame"]) % 8
		texture.atlas = preload("res://assets/tree/seeds.png")
		texture.region = Rect2((frame % 4) * 512, floori(float(frame) / 4.0) * 512, 512, 512)
		return texture
	var path := String(item.get("preview_path", ""))
	if not path.is_empty() and ResourceLoader.exists(path): return load(path) as Texture2D
	return UiAtlas.background(CATEGORIES.find(_category) % 2)

func _cutting_texture(_item_id: String) -> Texture2D:
	return UiAtlas.branch_texture()

func _quantity_badge(amount: int) -> Control:
	var badge := Panel.new()
	badge.name = "QuantityBadge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	badge.position = Vector2(-36.0, 6.0)
	badge.size = Vector2(30.0, 30.0)
	var style := StyleBoxFlat.new()
	style.bg_color = COLORS[_category].darkened(0.38)
	style.border_color = COLORS[_category].lightened(0.20)
	style.set_border_width_all(2)
	style.set_corner_radius_all(15)
	badge.add_theme_stylebox_override(&"panel", style)
	var label := Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.text = str(amount)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override(&"font_size", 13 if amount >= 10 else 15)
	label.add_theme_color_override(&"font_color", Color.WHITE)
	label.add_theme_color_override(&"font_outline_color", Color(0.20, 0.07, 0.015, 1.0))
	label.add_theme_constant_override(&"outline_size", 2)
	badge.add_child(label)
	return badge

func _apply_category_hud(color: Color) -> void:
	var style := StyleBoxFlat.new(); style.bg_color = color.darkened(0.72); style.bg_color.a = 0.96
	style.border_width_left = 7; style.border_width_top = 7; style.border_width_right = 7; style.border_width_bottom = 7
	style.border_color = color.lightened(0.28); style.shadow_color = Color(0.08, 0.04, 0.01, 0.55); style.shadow_size = 5; style.shadow_offset = Vector2(0, 3)
	style.corner_radius_top_left = 20; style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20; style.corner_radius_bottom_right = 20
	style.content_margin_left = 16; style.content_margin_top = 16; style.content_margin_right = 16; style.content_margin_bottom = 16
	category_hud.add_theme_stylebox_override(&"panel", style)

func _lot_price_style(accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = accent.darkened(0.48); style.bg_color.a = 0.92
	style.border_color = accent.darkened(0.66); style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	return style

func _pretty(value: String) -> String: return value.replace("_", " ").capitalize()
