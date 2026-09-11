class_name CommerceUiStyle
extends RefCounted

static func curved_title(label: Label, caption: String, arc_height := 5.0) -> void:
	label.text = ""
	for child in label.get_children():
		child.queue_free()
	var count := caption.length()
	var letter_width := minf(42.0, label.size.x / maxf(float(count), 1.0))
	var title_width := letter_width * float(count)
	var start_x := (label.size.x - title_width) * 0.5
	var center := float(count - 1) * 0.5
	for index in range(count):
		var letter := Label.new()
		letter.mouse_filter = Control.MOUSE_FILTER_IGNORE
		letter.text = caption.substr(index, 1)
		var distance := absf(float(index) - center) / maxf(center, 1.0)
		letter.position = Vector2(start_x + index * letter_width, distance * arc_height)
		letter.size = Vector2(letter_width + 1.0, label.size.y - arc_height)
		letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		letter.add_theme_color_override(&"font_color", Color.WHITE)
		letter.add_theme_color_override(&"font_outline_color", Color(0.25, 0.08, 0.02, 1.0))
		letter.add_theme_constant_override(&"outline_size", 5)
		letter.add_theme_font_size_override(&"font_size", 30)
		label.add_child(letter)

static func topup_button(button: Button, caption: String, rewarded := false) -> void:
	_program_button(button, caption, Color(0.15, 0.69, 0.06, 1.0), Color(0.08, 0.39, 0.025, 1.0), 18)
	button.add_theme_color_override(&"font_color", Color(1.0, 0.84, 0.22, 1.0) if rewarded else Color.WHITE)
	for state in [&"normal", &"hover", &"pressed", &"disabled"]:
		var style := button.get_theme_stylebox(state) as StyleBoxFlat
		if style != null:
			style.shadow_size = 0
			style.shadow_offset = Vector2.ZERO
			style.set_corner_radius_all(18)

static func balance_plus(button: Button) -> void:
	_program_button(button, "+", Color(0.12, 0.72, 0.055, 1.0), Color(0.055, 0.31, 0.015, 1.0), 20)
	button.custom_minimum_size = Vector2(34.0, 34.0)
	button.add_theme_constant_override(&"outline_size", 1)

static func transaction_action(button: Button, mode: StringName) -> void:
	var selling := mode == &"sell"
	_program_button(button, String(mode).to_upper(), Color(0.96, 0.49, 0.045, 1.0) if selling else Color(0.24, 0.72, 0.07, 1.0), Color(0.54, 0.20, 0.02, 1.0), 25)

static func shop_category_button(button: Button, caption: String, accent: Color) -> void:
	button.text = caption.to_upper()
	button.icon = null
	button.expand_icon = false
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override(&"font_size", 18)
	button.add_theme_color_override(&"font_color", Color.WHITE)
	button.add_theme_color_override(&"font_outline_color", accent.darkened(0.62))
	button.add_theme_constant_override(&"outline_size", 3)
	button.add_theme_stylebox_override(&"normal", _category_button_style(accent, false))
	button.add_theme_stylebox_override(&"hover", _category_button_style(accent.lightened(0.10), false))
	button.add_theme_stylebox_override(&"pressed", _category_button_style(accent.darkened(0.10), true))
	button.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	button.add_theme_stylebox_override(&"disabled", _category_button_style(accent.darkened(0.30), false))

static func _category_button_style(color: Color, pressed: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = color.darkened(0.34)
	style.border_width_left = 3
	style.border_width_top = 2
	style.border_width_right = 3
	style.border_width_bottom = 5
	style.set_corner_radius_all(22)
	style.shadow_color = color.darkened(0.48)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0.0, 2.0 if pressed else 5.0)
	style.anti_aliasing_size = 1.5
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	return style

static func shop_lot(card: Button, accent: Color) -> void:
	card.focus_mode = Control.FOCUS_NONE
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.add_theme_stylebox_override(&"normal", _panel(accent.lightened(0.72), accent.darkened(0.24), 4, 18))
	card.add_theme_stylebox_override(&"hover", _panel(accent.lightened(0.80), accent, 5, 18))
	card.add_theme_stylebox_override(&"pressed", _panel(accent.lightened(0.62), accent.darkened(0.12), 5, 18))
	card.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())

static func shop_outer_panel() -> StyleBoxFlat:
	return _panel(Color(1.0, 0.86, 0.61, 0.98), Color(0.36, 0.12, 0.025, 1.0), 9, 26)

static func shop_inner_panel() -> StyleBoxFlat:
	return _panel(Color(0.96, 0.82, 0.55, 0.98), Color(0.46, 0.18, 0.035, 1.0), 5, 18)

static func _program_button(button: Button, caption: String, color: Color, border: Color, font_size: int) -> void:
	button.text = caption
	button.icon = null
	button.expand_icon = false
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override(&"font_size", font_size)
	button.add_theme_color_override(&"font_color", Color.WHITE)
	button.add_theme_color_override(&"font_outline_color", border.darkened(0.3))
	button.add_theme_constant_override(&"outline_size", 2)
	button.add_theme_stylebox_override(&"normal", _panel(color, border, 4, 14))
	button.add_theme_stylebox_override(&"hover", _panel(color.lightened(0.10), border, 4, 14))
	button.add_theme_stylebox_override(&"pressed", _panel(color.darkened(0.13), border, 4, 14))
	button.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	button.add_theme_stylebox_override(&"disabled", _panel(Color(0.45, 0.48, 0.39, 1.0), border, 4, 14))

static func _panel(background: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.20, 0.075, 0.01, 0.48)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0.0, 3.0)
	style.anti_aliasing_size = 1.5
	return style
