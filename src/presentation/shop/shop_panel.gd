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
const LOT_FRAMES := {
	&"plants": Vector2i(0, 0), &"pots": Vector2i(0, 1), &"seeds": Vector2i(0, 2),
	&"fertilizers": Vector2i(1, 0), &"decorations": Vector2i(1, 1), &"mutagens": Vector2i(1, 2),
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
var _layout_editor: ShopLayoutEditor
var _purchase_quantity := 1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_layout_editor = ShopLayoutEditor.new(self)
	$Window/Content/Header/Title.texture = UiAtlas.shop_title_texture()
	%Awning.texture = UiAtlas.shop_awning_texture()
	($Window as PanelContainer).add_theme_stylebox_override(&"panel", UiAtlas.warm_hud_style(8, 26, Vector4(24.0, 20.0, 24.0, 22.0)))
	category_hud.add_theme_stylebox_override(&"panel", UiAtlas.warm_hud_style(3, 16))
	UiAtlas.configure_close_button(%CloseButton)
	_configure_buy_dialog_art()
	%CloseButton.pressed.connect(_request_close)
	%ConfirmClose.pressed.connect(_hide_confirm)
	buy_button.pressed.connect(_buy_selected)
	quantity_minus.pressed.connect(_change_quantity.bind(-1))
	quantity_plus.pressed.connect(_change_quantity.bind(1))
	_build_tabs()
	_register_static_layout_elements()
	confirm.visible = false

func _input(event: InputEvent) -> void:
	if visible and _layout_editor != null and _layout_editor.handle_input(event):
		get_viewport().set_input_as_handled()

func _apply_shop_layout(control: Control, key: String) -> void:
	if _layout_editor != null:
		_layout_editor.apply_saved(control, key)

func _register_static_layout_elements() -> void:
	_layout_editor.register($Window, "window")
	_layout_editor.register($Window/Content/Header/Title, "title")
	_layout_editor.register(%Awning, "awning")
	_layout_editor.register(%CloseButton, "close")
	_layout_editor.register(%CategoryHud, "category_hud")
	_layout_editor.register(%Confirm, "confirm")
	_layout_editor.register(%ConfirmBackground, "confirm_background")
	_layout_editor.register(%ConfirmBanner, "confirm_banner")
	_layout_editor.register(%ConfirmName, "confirm_name")
	_layout_editor.register(%ConfirmPreview, "confirm_preview")
	_layout_editor.register(%ConfirmDescription, "confirm_description")
	_layout_editor.register(%BuyButton, "confirm_buy")
	_layout_editor.register(%ConfirmClose, "confirm_close")
	_layout_editor.register(%QuantityControl, "confirm_quantity")
	_layout_editor.register(%QuantityBackground, "confirm_quantity_background")
	_layout_editor.register(%QuantityMinus, "confirm_quantity_minus")
	_layout_editor.register(%QuantityLabel, "confirm_quantity_label")
	_layout_editor.register(%QuantityPlus, "confirm_quantity_plus")
	_layout_editor.register(%CountControl, "confirm_count")
	_layout_editor.register(%CountBackground, "confirm_count_background")
	_layout_editor.register(%ConfirmPrice, "confirm_price")

func _configure_buy_dialog_art() -> void:
	(%ConfirmBackground as Panel).add_theme_stylebox_override(&"panel", UiAtlas.warm_hud_style(8, 26, Vector4(24.0, 20.0, 24.0, 22.0)))
	%ConfirmBanner.texture = UiAtlas.HUD_BUYSELL_BANNER
	%QuantityBackground.texture = UiAtlas.HUD_QUANTITY
	%CountBackground.texture = UiAtlas.HUD_COUNT
	UiAtlas.configure_close_button(%ConfirmClose)
	UiAtlas.configure_button(buy_button, 7, 1)
	_configure_quantity_hit(quantity_minus)
	_configure_quantity_hit(quantity_plus)

func _configure_quantity_hit(button: Button) -> void:
	button.text = ""; button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP; button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS; button.z_index = 5
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())

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
		_layout_editor.register(button, "tab_%s" % String(category))

func _show_category(category: StringName) -> void:
	_category = category; _hide_confirm(); _apply_category_hud(COLORS[category])
	for child in grid.get_children(): grid.remove_child(child); child.queue_free()
	for item in _catalogs.get(category, []):
		if int(item.get("stock", 0)) > 0: _add_card(item)

func _add_card(item: Dictionary) -> void:
	var card := Button.new()
	card.custom_minimum_size = Vector2(174.0, 156.0); card.clip_contents = true
	card.disabled = not bool(item.get("unlocked", false)); card.tooltip_text = String(item.get("description", ""))
	_configure_lot_button(card)
	var key := "lot_%s_%s" % [String(_category), String(item.get("id", ""))]
	var background := TextureRect.new(); background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.offset_left = 1.0; background.offset_top = 1.0; background.offset_right = -1.0; background.offset_bottom = -1.0
	var lot_frame: Vector2i = LOT_FRAMES[_category]; background.texture = UiAtlas.shop_lot_texture(lot_frame.x, lot_frame.y)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE; card.add_child(background)
	var name_label := Label.new()
	name_label.position = Vector2(10.0, 7.0); name_label.size = Vector2(154.0, 28.0)
	name_label.text = String(item.get("name", "Item")); name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; name_label.add_theme_font_size_override(&"font_size", 16); card.add_child(name_label)
	var preview := TextureRect.new(); preview.position = Vector2(25.0, 35.0); preview.size = Vector2(124.0, 78.0); preview.texture = _preview_texture(item)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(preview)
	var coin := TextureRect.new(); coin.position = Vector2(57.0, 119.0); coin.size = Vector2(28.0, 28.0); coin.texture = UiAtlas.coin_texture()
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; coin.mouse_filter = Control.MOUSE_FILTER_IGNORE; card.add_child(coin)
	var price := Label.new(); price.position = Vector2(87.0, 118.0); price.size = Vector2(55.0, 30.0)
	price.text = str(int(item.get("price", 1))) if bool(item.get("unlocked", false)) else "Locked"; price.add_theme_font_size_override(&"font_size", 18); card.add_child(price)
	var badge: Label = null
	if int(item.get("stock", 1)) > 1: badge = _quantity_badge(int(item["stock"])); card.add_child(badge)
	card.pressed.connect(_open_confirm.bind(item)); grid.add_child(card)
	_layout_editor.register(background, "%s_background" % key); _layout_editor.register(card, key)
	_layout_editor.register(name_label, "%s_name" % key); _layout_editor.register(preview, "%s_preview" % key)
	_layout_editor.register(coin, "%s_coin" % key); _layout_editor.register(price, "%s_price" % key)
	if badge != null: _layout_editor.register(badge, "%s_quantity" % key)

func _configure_lot_button(card: Button) -> void:
	card.focus_mode = Control.FOCUS_NONE; card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		card.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	card.mouse_entered.connect(_set_lot_hover.bind(card, true))
	card.mouse_exited.connect(_set_lot_hover.bind(card, false))

func _set_lot_hover(card: Button, hovered: bool) -> void:
	if is_instance_valid(card): card.self_modulate = Color(1.22, 1.22, 1.12, 1.0) if hovered else Color.WHITE

func _open_confirm(item: Dictionary) -> void:
	_selected = item; confirm_name.text = String(item.get("name", "Item"))
	confirm_description.text = String(item.get("description", "")); confirm_preview.texture = _preview_texture(item)
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
	quantity_minus.disabled = stock <= 1 or _purchase_quantity <= 1
	quantity_plus.disabled = stock <= 1 or _purchase_quantity >= stock
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

func _quantity_badge(amount: int) -> Label:
	var badge := Label.new(); badge.text = "×%d" % amount; badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.set_anchors_preset(Control.PRESET_TOP_RIGHT); badge.position = Vector2(-45.0, 6.0); badge.size = Vector2(38.0, 28.0)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; badge.add_theme_font_size_override(&"font_size", 18)
	badge.add_theme_color_override(&"font_color", Color("fff1a8")); badge.add_theme_constant_override(&"outline_size", 5)
	return badge

func _apply_category_hud(color: Color) -> void:
	var style := StyleBoxFlat.new(); style.bg_color = color.darkened(0.72); style.bg_color.a = 0.96
	style.border_width_left = 7; style.border_width_top = 7; style.border_width_right = 7; style.border_width_bottom = 7
	style.border_color = color.lightened(0.28); style.shadow_color = Color(0.08, 0.04, 0.01, 0.55); style.shadow_size = 5; style.shadow_offset = Vector2(0, 3)
	style.corner_radius_top_left = 20; style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20; style.corner_radius_bottom_right = 20
	style.content_margin_left = 16; style.content_margin_top = 16; style.content_margin_right = 16; style.content_margin_bottom = 16
	category_hud.add_theme_stylebox_override(&"panel", style)

func _pretty(value: String) -> String: return value.replace("_", " ").capitalize()
