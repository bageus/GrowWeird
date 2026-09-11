class_name UiAtlas
extends RefCounted

const BUTTONS: Texture2D = preload("res://assets/ui/buttons.png")
const HUD_BALANCE: Texture2D = preload("res://assets/ui/hud_balance.png")
const ENERGY_COIN_ICONS: Texture2D = preload("res://assets/ui/energycoin_icon.png")
const COIN_ICON: Texture2D = preload("res://assets/ui/coin.svg")
const BALANCE_PLUS_ICON: Texture2D = preload("res://assets/ui/balance_plus.svg")
const RUBLE_ICON: Texture2D = preload("res://assets/ui/ruble.svg")
const DOLLAR_ICON: Texture2D = preload("res://assets/ui/dollar.svg")
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
const HUD_COUNT: Texture2D = preload("res://assets/ui/hud_background_count.png")
const HUD_SHOP_LOTS: Texture2D = preload("res://assets/ui/hud_background_shop.png")
const HUD_COIN_ENERGY_BANNER: Texture2D = preload("res://assets/ui/hud_coinenergy_banner.png")
const CELL := 512.0
const ENERGY_COIN_CELL := 256.0

class CoinFace:
	extends TextureRect
	func _init() -> void:
		texture = preload("res://assets/ui/coin.svg")
		expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mouse_filter = Control.MOUSE_FILTER_IGNORE

static func atlas_region(source: Texture2D, region: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = source
	texture.region = region
	return texture

static func button_texture(row: int, column: int, _hover := false, mirror_x := false) -> Texture2D:
	var texture: Texture2D = atlas_region(BUTTONS, Rect2(column * CELL, row * CELL + 88.0, CELL, 336.0))
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

static func _close_texture(_hovered: bool) -> Texture2D:
	return atlas_region(BUTTONS, Rect2(104.0, 3176.0, 304.0, 304.0))

static func _button_icon_crop(row: int, column: int, _hover: bool) -> Texture2D:
	return atlas_region(BUTTONS, Rect2(column * CELL + 24.0, row * CELL + 88.0, 240.0, 336.0))

static func energy_coin_icon(row: int, column: int) -> Texture2D:
	return atlas_region(ENERGY_COIN_ICONS, Rect2(
		(column - 1) * ENERGY_COIN_CELL,
		(row - 1) * ENERGY_COIN_CELL,
		ENERGY_COIN_CELL,
		ENERGY_COIN_CELL
	))

static func configure_topup_card(panel: Panel, title: String, icon_texture: Texture2D) -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override(&"panel", warm_hud_style(4, 22, Vector4(12.0, 12.0, 12.0, 12.0)))
	var label := Label.new()
	label.name = "Title"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	label.offset_left = 12.0
	label.offset_top = 18.0
	label.offset_right = -12.0
	label.offset_bottom = 58.0
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var bold_font := SystemFont.new()
	bold_font.font_names = PackedStringArray(["Arial", "Noto Sans"])
	bold_font.font_weight = 700
	label.add_theme_font_override(&"font", bold_font)
	label.add_theme_color_override(&"font_color", Color(0.33, 0.18, 0.1, 1.0))
	label.add_theme_color_override(&"font_outline_color", Color(1.0, 0.94, 0.78, 1.0))
	label.add_theme_constant_override(&"outline_size", 4)
	label.add_theme_font_size_override(&"font_size", 22)
	panel.add_child(label)
	var icon := TextureRect.new()
	icon.name = "ItemIcon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = icon_texture
	icon.set_anchors_preset(Control.PRESET_CENTER)
	icon.offset_left = -82.0
	icon.offset_top = -92.0
	icon.offset_right = 82.0
	icon.offset_bottom = 72.0
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	panel.add_child(icon)

static func configure_transaction_total(container: Control) -> void:
	if container == null:
		return
	var labels := container.find_children("*", "Label", true, false)
	if labels.is_empty():
		return
	var value_label := labels[0] as Label
	var bold_font := SystemFont.new()
	bold_font.font_names = PackedStringArray(["Arial", "Noto Sans"])
	bold_font.font_weight = 700
	value_label.add_theme_font_override(&"font", bold_font)
	value_label.add_theme_color_override(&"font_color", Color(0.24, 0.105, 0.035, 1.0))
	value_label.set_anchors_preset(Control.PRESET_CENTER)
	value_label.offset_left = -50.0
	value_label.offset_top = -24.0
	value_label.offset_right = 2.0
	value_label.offset_bottom = 24.0
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var icon := CoinFace.new()
	icon.name = "TotalCoinIcon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_preset(Control.PRESET_CENTER)
	icon.offset_left = 6.0
	icon.offset_top = -13.0
	icon.offset_right = 32.0
	icon.offset_bottom = 13.0
	container.add_child(icon)

static func configure_topup_button(button: Button, price := 0, rewarded_ad := false, currency: StringName = &"rub") -> void:
	if button == null:
		return
	CommerceUiStyle.topup_button(button, "FREE" if rewarded_ad else "", rewarded_ad)
	button.icon = null
	var old_content := button.get_node_or_null("PriceContent")
	if old_content != null:
		old_content.free()
	if not rewarded_ad:
		var center := CenterContainer.new()
		center.name = "PriceContent"
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(center)
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override(&"separation", 5)
		center.add_child(row)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(28.0, 28.0)
		icon.texture = DOLLAR_ICON if currency == &"usd" else RUBLE_ICON
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
		var price_label := Label.new()
		price_label.text = str(price)
		price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		price_label.add_theme_font_size_override(&"font_size", 18)
		price_label.add_theme_color_override(&"font_color", Color.WHITE)
		price_label.add_theme_color_override(&"font_outline_color", Color(0.12, 0.28, 0.04, 0.88))
		price_label.add_theme_constant_override(&"outline_size", 2)
		price_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(price_label)
	button.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	button.offset_left = -88.0
	button.offset_top = -92.0
	button.offset_right = 88.0
	button.offset_bottom = -28.0
	button.clip_contents = true

static func configure_balance_hud(panel: Panel) -> void:
	CommerceUiStyle.balance_hud(panel)
static func configure_balance_plus(button: Button, _balance_art: Control) -> void:
	if button != null:
		CommerceUiStyle.balance_plus(button)
		button.text = ""
		button.icon = BALANCE_PLUS_ICON
		button.expand_icon = true
		button.add_theme_constant_override(&"icon_max_width", 39)
		for state in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
			button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		button.set_anchors_preset(Control.PRESET_TOP_LEFT)
		button.custom_minimum_size = Vector2(39.0, 39.0)
		button.position = Vector2(182.0, 31.0)
		button.size = Vector2(39.0, 39.0)
static func balance_background() -> Texture2D:
	return atlas_region(HUD_BALANCE, Rect2(48.0, 132.0, 936.0, 252.0))

static func balance_icon(energy := false) -> Texture2D:
	return energy_coin_icon(2, 4) if energy else energy_coin_icon(2, 3)

static func balance_next_texture() -> Texture2D:
	return atlas_region(HUD_BALANCE_NEXT, Rect2(196.0, 188.0, 632.0, 136.0))

static func warm_hud_style(border_width := 3, radius := 16, margins := Vector4(14.0, 10.0, 14.0, 10.0)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.88, 0.62, 0.97)
	style.border_color = Color(0.76, 0.38, 0.07, 1.0)
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.34, 0.14, 0.025, 0.48)
	style.shadow_size = maxi(2, border_width - 1)
	style.shadow_offset = Vector2(0.0, 3.0)
	style.anti_aliasing_size = 1.5
	style.content_margin_left = margins.x
	style.content_margin_top = margins.y
	style.content_margin_right = margins.z
	style.content_margin_bottom = margins.w
	return style

static func configure_warm_timer_hud(panel: PanelContainer, label: Label) -> void:
	if panel == null or label == null:
		return
	panel.add_theme_stylebox_override(&"panel", warm_hud_style(2, 10, Vector4(10.0, 2.0, 10.0, 2.0)))
	label.add_theme_color_override(&"font_color", Color(0.28, 0.12, 0.04, 1.0))
	label.add_theme_font_size_override(&"font_size", 14)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

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
