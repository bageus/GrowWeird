class_name UiAtlas
extends RefCounted

const BUTTONS: Texture2D = preload("res://assets/ui/buttons.png")
const BUTTONS_HOVER: Texture2D = preload("res://assets/ui/buttons_hover.png")
const HUD_BALANCE: Texture2D = preload("res://assets/ui/hud_balance.png")
const HUD_BALANCE_ICON: Texture2D = preload("res://assets/ui/hud_balance_icon.png")
const HUD_BALANCE_NEXT: Texture2D = preload("res://assets/ui/hud_balance_next.png")
const HUD_BACKGROUND: Texture2D = preload("res://assets/ui/hud_background.png")
const HUD_BACKGROUND2: Texture2D = preload("res://assets/ui/hud_background2.png")
const HUD_INVENTORY: Texture2D = preload("res://assets/ui/hud_background_inventory.png")
const HUD_INVENTORY_HOVER_UP: Texture2D = preload("res://assets/ui/hud_background_inventory_hoverup.png")
const HUD_INVENTORY_HOVER_DOWN: Texture2D = preload("res://assets/ui/hud_background_inventory_hoverdown.png")
const HUD_POT: Texture2D = preload("res://assets/ui/hud_background_pot.png")
const HUD_POT_HOVER_LEFT: Texture2D = preload("res://assets/ui/hud_background_pot_hoverleft.png")
const HUD_POT_HOVER_RIGHT: Texture2D = preload("res://assets/ui/hud_background_pot_hoverright.png")
const HUD_BUYSELL: Texture2D = preload("res://assets/ui/hud4.png")
const HUD_BUYSELL_BANNER: Texture2D = preload("res://assets/ui/hud_buysell_banner.png")
const HUD_QUANTITY: Texture2D = preload("res://assets/ui/hud_background_quantity.png")
const HUD_COUNT: Texture2D = preload("res://assets/ui/hud_background_count.png")
const HUD_SHOP_LOTS: Texture2D = preload("res://assets/ui/hud_background_shop.png")
const HUD_COIN_ENERGY_BANNER: Texture2D = preload("res://assets/ui/hud_coinenergy_banner.png")
const COIN_LOTS := {
	10: preload("res://assets/ui/coinlot_card_10.png"),
	100: preload("res://assets/ui/coinlot_card_100.png"),
	300: preload("res://assets/ui/coinlot_card_300.png"),
	1000: preload("res://assets/ui/coinlot_card_1000.png"),
}
const ENERGY_LOTS := {
	5: preload("res://assets/ui/energylot_card_5.png"),
	15: preload("res://assets/ui/energylot_card_15.png"),
	30: preload("res://assets/ui/energylot_card_30.png"),
}
const CELL := 512.0

static func atlas_region(source: Texture2D, region: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = source
	texture.region = region
	return texture

static func button_texture(row: int, column: int, hover := false, mirror_x := false) -> Texture2D:
	var source := BUTTONS_HOVER if hover else BUTTONS
	var texture: Texture2D = atlas_region(source, Rect2(column * CELL, row * CELL + 88.0, CELL, 336.0))
	if not mirror_x:
		return texture
	var image := texture.get_image()
	image.flip_x()
	return ImageTexture.create_from_image(image)

static func configure_button(button: Button, row: int, column: int, mirror_x := false) -> void:
	if button == null:
		return
	button.text = ""
	button.icon = button_texture(row, column, false, mirror_x)
	button.expand_icon = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_color_override(&"icon_disabled_color", Color.WHITE)
	for state in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.mouse_entered.connect(_set_button_hover.bind(button, row, column, mirror_x, true))
	button.mouse_exited.connect(_set_button_hover.bind(button, row, column, mirror_x, false))

static func configure_icon_button(button: Button, row: int, column: int) -> void:
	if button == null:
		return
	button.text = ""
	button.icon = _button_icon_crop(row, column, false)
	button.expand_icon = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_color_override(&"icon_disabled_color", Color.WHITE)
	for state in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.mouse_entered.connect(_set_icon_button_hover.bind(button, row, column, true))
	button.mouse_exited.connect(_set_icon_button_hover.bind(button, row, column, false))

static func configure_close_button(button: Button) -> void:
	if button == null:
		return
	button.text = ""
	button.icon = _close_texture(false)
	button.expand_icon = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.mouse_entered.connect(_set_close_hover.bind(button, true))
	button.mouse_exited.connect(_set_close_hover.bind(button, false))

static func _close_texture(hovered: bool) -> Texture2D:
	var source := BUTTONS_HOVER if hovered else BUTTONS
	return atlas_region(source, Rect2(104.0, 3176.0, 304.0, 304.0))

static func _button_icon_crop(row: int, column: int, hover: bool) -> Texture2D:
	var source := BUTTONS_HOVER if hover else BUTTONS
	return atlas_region(source, Rect2(column * CELL + 24.0, row * CELL + 88.0, 240.0, 336.0))

static func configure_topup_button(button: Button, price := 0, rewarded_ad := false) -> void:
	configure_button(button, 7, 2)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	var amount := Label.new()
	amount.name = "Amount"
	amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
	amount.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	amount.offset_left = 18.0; amount.offset_right = -52.0
	amount.text = "" if rewarded_ad else str(price)
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	amount.add_theme_font_size_override(&"font_size", 24)
	button.add_child(amount)
	var currency := TextureRect.new()
	currency.name = "CurrencyIcon"
	currency.mouse_filter = Control.MOUSE_FILTER_IGNORE
	currency.texture = button_texture(7, 3) if rewarded_ad else button_texture(6, 3)
	currency.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	currency.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var icon_size := 42.0 if rewarded_ad else 25.0
	currency.position = Vector2((button.size.x - icon_size) * 0.5 if rewarded_ad else button.size.x - icon_size - 20.0, (button.size.y - icon_size) * 0.5)
	currency.size = Vector2(icon_size, icon_size)
	button.add_child(currency)

static func configure_balance_plus(button: Button, _balance_art: TextureRect) -> void:
	if button == null: return
	button.text = ""
	button.icon = button_texture(5, 3)
	button.expand_icon = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())

static func balance_background() -> Texture2D:
	return atlas_region(HUD_BALANCE, Rect2(48.0, 132.0, 936.0, 252.0))

static func balance_icon(energy := false) -> Texture2D:
	return atlas_region(HUD_BALANCE_ICON, Rect2(572.0, 66.0, 392.0, 362.0) if energy else Rect2(70.0, 86.0, 344.0, 340.0))

static func balance_next_texture() -> Texture2D:
	return atlas_region(HUD_BALANCE_NEXT, Rect2(196.0, 188.0, 632.0, 136.0))

static func configure_hud_slot(button: Button) -> void:
	if button == null:
		return
	var style := panel_style(background(0), Vector4(10.0, 10.0, 10.0, 10.0))
	for state in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		button.add_theme_stylebox_override(state, style)
	button.add_theme_color_override(&"icon_disabled_color", Color.WHITE)
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.mouse_entered.connect(_set_slot_hover.bind(button, true))
	button.mouse_exited.connect(_set_slot_hover.bind(button, false))

static func configure_inventory_arrow(button: TextureButton, _points_up: bool) -> void:
	if button == null:
		return
	button.texture_normal = null
	button.texture_hover = null
	button.texture_pressed = null
	button.texture_disabled = null
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

static func configure_shop_slot(button: Button) -> void:
	if button == null:
		return
	var style := panel_style(background2(1), Vector4(14.0, 14.0, 14.0, 14.0))
	for state in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		button.add_theme_stylebox_override(state, style)
	button.add_theme_color_override(&"icon_disabled_color", Color.WHITE)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.mouse_entered.connect(_set_slot_hover.bind(button, true))
	button.mouse_exited.connect(_set_slot_hover.bind(button, false))

static func coin_texture() -> Texture2D:
	return atlas_region(BUTTONS, Rect2(112.0, 2672.0, 288.0, 288.0))

static func branch_texture() -> Texture2D:
	return atlas_region(BUTTONS, Rect2(0.0, 7.0 * CELL, CELL, CELL))

static func shop_title_texture() -> Texture2D:
	return button_texture(6, 1)

static func shop_awning_texture() -> Texture2D:
	return button_texture(6, 2)

static func buy_close_texture(hover := false) -> Texture2D:
	return button_texture(6, 0, hover)

static func buy_button_texture(hover := false) -> Texture2D:
	return button_texture(7, 1, hover)

static func shop_lot_texture(row: int, column: int) -> Texture2D:
	return atlas_region(HUD_SHOP_LOTS, Rect2(column * CELL, row * CELL, CELL, CELL))

static func panel_style(texture: Texture2D, margins := Vector4(12.0, 12.0, 12.0, 12.0)) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.content_margin_left = margins.x
	style.content_margin_top = margins.y
	style.content_margin_right = margins.z
	style.content_margin_bottom = margins.w
	return style

static func background(index: int) -> Texture2D:
	return atlas_region(HUD_BACKGROUND, Rect2(index * CELL, 0.0, CELL, CELL))

static func background2(index: int) -> Texture2D:
	return atlas_region(HUD_BACKGROUND2, Rect2(index * CELL, 0.0, CELL, CELL))

static func prune_cursor() -> Texture2D:
	var image := background(1).get_image()
	image.resize(72, 72, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(image)

static func _set_button_hover(button: Button, row: int, column: int, mirror_x: bool, hovered: bool) -> void:
	if is_instance_valid(button):
		button.icon = button_texture(row, column, hovered, mirror_x)
		button.self_modulate = Color(1.12, 1.12, 1.12, 1.0) if hovered else Color.WHITE

static func _set_icon_button_hover(button: Button, row: int, column: int, hovered: bool) -> void:
	if is_instance_valid(button):
		button.icon = _button_icon_crop(row, column, hovered)
		button.self_modulate = Color(1.12, 1.12, 1.12, 1.0) if hovered else Color.WHITE

static func _set_close_hover(button: Button, hovered: bool) -> void:
	if is_instance_valid(button):
		button.icon = _close_texture(hovered)

static func _set_slot_hover(button: Button, hovered: bool) -> void:
	if is_instance_valid(button):
		button.self_modulate = Color(1.22, 1.22, 1.12, 1.0) if hovered else Color.WHITE
