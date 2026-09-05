class_name UiAtlas
extends RefCounted

const BUTTONS: Texture2D = preload("res://assets/ui/buttons.png")
const BUTTONS_HOVER: Texture2D = preload("res://assets/ui/buttons_hover.png")
const HUD_BALANCE: Texture2D = preload("res://assets/ui/hud_balance.png")
const HUD_BALANCE_PLUS_HOVER: Texture2D = preload("res://assets/ui/hud_balance_plus_hover.png")
const HUD_BACKGROUND: Texture2D = preload("res://assets/ui/hud_background.png")
const HUD_BACKGROUND2: Texture2D = preload("res://assets/ui/hud_background2.png")
const HUD_INVENTORY: Texture2D = preload("res://assets/ui/hud_background_inventory.png")
const HUD_INVENTORY_HOVER_UP: Texture2D = preload("res://assets/ui/hud_background_inventory_hoverup.png")
const HUD_INVENTORY_HOVER_DOWN: Texture2D = preload("res://assets/ui/hud_background_inventory_hoverdown.png")
const HUD_POT: Texture2D = preload("res://assets/ui/hud_background_pot.png")
const HUD_POT_HOVER_LEFT: Texture2D = preload("res://assets/ui/hud_background_pot_hoverleft.png")
const HUD_POT_HOVER_RIGHT: Texture2D = preload("res://assets/ui/hud_background_pot_hoverright.png")
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

static func _button_icon_crop(row: int, column: int, hover: bool) -> Texture2D:
	var source := BUTTONS_HOVER if hover else BUTTONS
	return atlas_region(source, Rect2(column * CELL + 24.0, row * CELL + 88.0, 240.0, 336.0))

static func configure_balance_plus(button: Button, balance_art: TextureRect) -> void:
	if button == null or balance_art == null:
		return
	button.text = ""
	button.icon = null
	button.expand_icon = true
	button.tooltip_text = "Open balance and shop"
	balance_art.texture = HUD_BALANCE
	for state in [&"normal", &"hover", &"pressed", &"focus"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.mouse_entered.connect(_set_balance_hover.bind(balance_art, true))
	button.mouse_exited.connect(_set_balance_hover.bind(balance_art, false))

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

static func configure_inventory_arrow(button: TextureButton, points_up: bool) -> void:
	if button == null:
		return
	button.texture_normal = null
	button.texture_hover = null
	button.texture_pressed = null
	button.texture_disabled = null
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

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

static func _set_balance_hover(balance_art: TextureRect, hovered: bool) -> void:
	if not is_instance_valid(balance_art):
		return
	balance_art.texture = HUD_BALANCE_PLUS_HOVER if hovered else HUD_BALANCE

static func _set_slot_hover(button: Button, hovered: bool) -> void:
	if is_instance_valid(button):
		button.self_modulate = Color(1.22, 1.22, 1.12, 1.0) if hovered else Color.WHITE
