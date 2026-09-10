class_name TransactionDialogVisual
extends RefCounted

const SIZE := Vector2(500.0, 480.0)
const PANEL_RECT := Rect2(20.0, 10.0, 460.0, 460.0)
const BANNER_RECT := Rect2(5.0, -20.0, 490.0, 80.0)
const TITLE_RECT := Rect2(35.0, -7.0, 395.0, 54.0)
const CLOSE_RECT := Rect2(420.0, 8.0, 60.0, 60.0)
const PREVIEW_RECT := Rect2(135.0, 72.0, 230.0, 148.0)
const DESCRIPTION_RECT := Rect2(50.0, 222.0, 400.0, 58.0)
const QUANTITY_RECT := Rect2(50.0, 282.0, 400.0, 70.0)
const COUNT_RECT := Rect2(120.0, 360.0, 260.0, 55.0)
const ACTION_RECT := Rect2(50.0, 418.0, 400.0, 50.0)

static func configure(nodes: Dictionary, mode: StringName, action_frame: Vector2i) -> void:
	var root := nodes["root"] as Control
	root.custom_minimum_size = SIZE
	root.z_index = 190
	root.z_as_relative = false
	_set_rect(nodes["background"] as Control, PANEL_RECT)
	_set_rect(nodes["banner"] as Control, BANNER_RECT)
	_set_rect(nodes["title"] as Control, TITLE_RECT)
	_set_rect(nodes["close"] as Control, CLOSE_RECT)
	_set_rect(nodes["preview"] as Control, PREVIEW_RECT)
	_set_rect(nodes["description"] as Control, DESCRIPTION_RECT)
	_set_rect(nodes["quantity"] as Control, QUANTITY_RECT)
	_set_rect(nodes["count"] as Control, COUNT_RECT)
	_set_rect(nodes["action"] as Control, ACTION_RECT)

	var background := nodes["background"] as Panel
	background.add_theme_stylebox_override(&"panel", UiAtlas.warm_hud_style(8, 26, Vector4(24.0, 20.0, 24.0, 22.0)))
	(nodes["banner"] as TextureRect).texture = UiAtlas.HUD_BUYSELL_BANNER
	var title := nodes["title"] as Label
	title.text = String(mode).to_upper()
	title.clip_text = true
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_color_override(&"font_outline_color", Color(0.25, 0.08, 0.02, 1.0))
	title.add_theme_constant_override(&"outline_size", 5)
	title.add_theme_font_size_override(&"font_size", 24)

	(nodes["quantity_background"] as TextureRect).texture = UiAtlas.HUD_QUANTITY
	(nodes["count_background"] as TextureRect).texture = UiAtlas.HUD_COUNT
	UiAtlas.configure_close_button(nodes["close"] as Button)
	UiAtlas.configure_button(nodes["action"] as Button, action_frame.x, action_frame.y)
	_configure_quantity_button(nodes["minus"] as Button)
	_configure_quantity_button(nodes["plus"] as Button)
	(nodes["quantity_label"] as Label).mouse_filter = Control.MOUSE_FILTER_IGNORE

static func _configure_quantity_button(button: Button) -> void:
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	button.z_index = 5
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())

static func _set_rect(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size
