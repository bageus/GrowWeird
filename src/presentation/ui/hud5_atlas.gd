class_name Hud5Atlas
extends RefCounted

const TEXTURE: Texture2D = preload("res://assets/ui/hud5.png")
const CELL := 256.0

static func cell(row: int, column: int) -> Texture2D:
	var texture := AtlasTexture.new()
	texture.atlas = TEXTURE
	texture.region = Rect2((column - 1) * CELL, (row - 1) * CELL, CELL, CELL)
	return texture

static func fertilizer_icon() -> Texture2D: return cell(1, 3)
static func restart_icon() -> Texture2D: return cell(1, 1)
static func seed_icon() -> Texture2D: return cell(1, 2)
static func sprout_icon() -> Texture2D: return cell(1, 3)
static func tree_icon() -> Texture2D: return cell(1, 4)
static func flower_icon() -> Texture2D: return cell(1, 5)
static func fruit_icon() -> Texture2D: return cell(1, 6)
static func energy_icon() -> Texture2D: return cell(1, 4)
static func balance_coin_icon() -> Texture2D: return cell(1, 5)
static func coin_icon() -> Texture2D: return cell(1, 6)
static func claim_energy_icon() -> Texture2D: return cell(1, 7)
static func fertilizer_finish_icon() -> Texture2D: return cell(3, 1)
static func fertilizer_finish_pressed_icon() -> Texture2D: return cell(3, 2)
static func cycle_finish_icon() -> Texture2D: return cell(3, 2)
static func cycle_finish_hover_icon() -> Texture2D: return cell(3, 3)
static func cycle_finish_pressed_icon() -> Texture2D: return cell(3, 4)
static func plus_icon() -> Texture2D: return cell(3, 5)

static func stage_icon(cycle: int) -> Texture2D:
	match cycle:
		0: return seed_icon()
		1, 2, 3, 4: return sprout_icon()
		5, 6, 7, 8: return tree_icon()
		9: return flower_icon()
		10, 11: return fruit_icon()
		_: return restart_icon()

static func configure_icon(rect: TextureRect, texture: Texture2D) -> void:
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

static func configure_atlas_button(button: Button, normal: Texture2D, hover: Texture2D = null, pressed: Texture2D = null) -> void:
	button.text = ""
	button.icon = normal
	button.expand_icon = true
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_constant_override(&"icon_max_width", 256)
	for state in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	if hover != null:
		button.mouse_entered.connect(func() -> void: button.icon = hover)
		button.mouse_exited.connect(func() -> void: button.icon = normal)
	if pressed != null:
		button.button_down.connect(func() -> void: button.icon = pressed)
		button.button_up.connect(func() -> void: button.icon = hover if hover != null and button.is_hovered() else normal)

static func add_cost_overlay(button: Button) -> Label:
	var dot := Label.new()
	dot.name = "EnergyDot"
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.position = Vector2(button.size.x * 0.5 - 20.0, 0.0)
	dot.size = Vector2(18.0, button.size.y)
	dot.text = "·"
	dot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dot.add_theme_font_override(&"font", UiAtlas.GAME_FONT)
	dot.add_theme_font_size_override(&"font_size", 22)
	dot.add_theme_color_override(&"font_color", Color("ffd229"))
	dot.add_theme_color_override(&"font_outline_color", Color("5b2b12"))
	dot.add_theme_constant_override(&"outline_size", 2)
	button.add_child(dot)
	var label := Label.new()
	label.name = "Cost"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = Vector2(button.size.x * 0.5 - 2.0, 0.0)
	label.size = Vector2(button.size.x * 0.5 - 8.0, button.size.y)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override(&"font", UiAtlas.GAME_FONT)
	label.add_theme_font_size_override(&"font_size", 17)
	label.add_theme_color_override(&"font_color", Color.WHITE)
	label.add_theme_color_override(&"font_outline_color", Color("5b2b12"))
	label.add_theme_constant_override(&"outline_size", 3)
	button.add_child(label)
	return label
