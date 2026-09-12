class_name TransactionDialogVisual
extends RefCounted

const SIZE := Vector2(466.0, 480.0)
const PANEL_RECT := Rect2(20.0, 10.0, 426.0, 460.0)
const BANNER_RECT := Rect2(5.0, -20.0, 456.0, 80.0)
const TITLE_RECT := Rect2(53.0, -7.0, 360.0, 54.0)
const CLOSE_RECT := Rect2(418.0, -10.0, 60.0, 60.0)
const PREVIEW_RECT := Rect2(118.0, 62.0, 230.0, 140.0)
const DESCRIPTION_RECT := Rect2(33.0, 205.0, 400.0, 73.0)
const QUANTITY_RECT := Rect2(33.0, 282.0, 400.0, 70.0)
const COUNT_RECT := Rect2(103.0, 350.0, 260.0, 55.0)
const ACTION_RECT := Rect2(93.0, 408.0, 280.0, 54.0)

static func configure(nodes: Dictionary, mode: StringName, _action_frame: Vector2i) -> void:
	var root := nodes["root"] as Control
	root.custom_minimum_size = SIZE
	root.z_index = 190
	root.z_as_relative = false
	_configure_modal_dim(root)
	_set_rect(nodes["background"] as Control, PANEL_RECT)
	_set_rect(nodes["banner"] as Control, BANNER_RECT)
	_set_rect(nodes["title"] as Control, TITLE_RECT)
	_set_rect(nodes["close"] as Control, CLOSE_RECT)
	_set_rect(nodes["preview"] as Control, PREVIEW_RECT)
	_set_rect(nodes["description"] as Control, DESCRIPTION_RECT)
	_configure_description_hud(root, nodes["description"] as Label)
	_set_rect(nodes["quantity"] as Control, QUANTITY_RECT)
	_set_rect(nodes["minus"] as Control, Rect2(14.0, 14.0, 42.0, 42.0))
	_set_rect(nodes["quantity_label"] as Control, Rect2(70.0, 4.0, 260.0, 62.0))
	_set_rect(nodes["plus"] as Control, Rect2(344.0, 14.0, 42.0, 42.0))
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

	(nodes["quantity_background"] as TextureRect).texture = null
	(nodes["count_background"] as TextureRect).texture = null
	UiAtlas.configure_transaction_total(nodes["count"] as Control)
	UiAtlas.configure_close_button(nodes["close"] as Button)
	CommerceUiStyle.transaction_action(nodes["action"] as Button, mode)
	_configure_quantity_button(nodes["minus"] as Button, "−")
	_configure_quantity_button(nodes["plus"] as Button, "+")
	var quantity_label := nodes["quantity_label"] as Label
	quantity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_emphasize_label(quantity_label)

static func fit_description(label: Label) -> void:
	var length := label.text.length()
	var font_size := 20
	if length > 82:
		font_size = 16
	elif length > 58:
		font_size = 18
	label.add_theme_font_size_override(&"font_size", font_size)

static func _configure_description_hud(root: Control, label: Label) -> void:
	var hud := root.get_node_or_null("DescriptionHud") as Panel
	if hud == null:
		hud = Panel.new()
		hud.name = "DescriptionHud"
		hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(hud)
		root.move_child(hud, label.get_index())
	# The visible description border has an 8 px gap after the main HUD's 8 px inner border.
	_set_rect(hud, Rect2(36.0, 201.0, 394.0, 81.0))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.82, 0.56, 0.42)
	style.border_color = Color(0.68, 0.34, 0.075, 0.66)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(0.28, 0.10, 0.02, 0.16)
	style.shadow_size = 2
	hud.add_theme_stylebox_override(&"panel", style)
	label.clip_text = true
	fit_description(label)

static func _configure_modal_dim(root: Control) -> void:
	var parent := root.get_parent()
	var dim := parent.get_node_or_null("%sModalDim" % root.name) as ColorRect
	if dim == null:
		dim = ColorRect.new()
		dim.name = "%sModalDim" % root.name
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dim.color = Color(0.015, 0.01, 0.02, 0.72)
		dim.mouse_filter = Control.MOUSE_FILTER_STOP
		dim.z_index = 189
		dim.z_as_relative = false
		parent.add_child(dim)
		parent.move_child(dim, root.get_index())
		root.visibility_changed.connect(func() -> void: dim.visible = root.visible)
	dim.visible = root.visible

static func _configure_quantity_button(button: Button, caption: String) -> void:
	button.text = caption
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	button.z_index = 5
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override(&"font_size", 28)
	var bold_font := SystemFont.new()
	bold_font.font_names = PackedStringArray(["Arial", "Noto Sans"])
	bold_font.font_weight = 800
	button.add_theme_font_override(&"font", bold_font)
	button.add_theme_color_override(&"font_color", Color.WHITE)
	button.add_theme_color_override(&"font_outline_color", Color(0.08, 0.22, 0.015, 1.0))
	button.add_theme_constant_override(&"outline_size", 2)
	button.add_theme_stylebox_override(&"normal", _quantity_button_style(Color(0.20, 0.72, 0.08, 1.0)))
	button.add_theme_stylebox_override(&"hover", _quantity_button_style(Color(0.30, 0.86, 0.10, 1.0)))
	button.add_theme_stylebox_override(&"pressed", _quantity_button_style(Color(0.13, 0.52, 0.045, 1.0)))
	button.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	button.add_theme_stylebox_override(&"disabled", _quantity_button_style(Color(0.38, 0.46, 0.32, 1.0)))

static func _quantity_button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.09, 0.29, 0.012, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(11)
	style.shadow_color = Color(0.08, 0.14, 0.01, 0.58)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0.0, 4.0)
	style.anti_aliasing_size = 1.5
	return style

static func _emphasize_label(label: Label) -> void:
	var bold_font := SystemFont.new()
	bold_font.font_names = PackedStringArray(["Arial", "Noto Sans"])
	bold_font.font_weight = 700
	label.add_theme_font_override(&"font", bold_font)
	label.add_theme_color_override(&"font_color", Color(0.24, 0.105, 0.035, 1.0))

static func _set_rect(control: Control, rect: Rect2) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.position = rect.position
	control.size = rect.size
