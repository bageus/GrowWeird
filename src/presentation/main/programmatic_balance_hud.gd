class_name ProgrammaticBalanceHud
extends PanelContainer

@export var energy := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	_build_hud(); call_deferred("_apply_programmatic_style")

func _build_hud() -> void:
	if get_node_or_null("Layers") != null: return
	var layers := Control.new(); layers.name = "Layers"; layers.mouse_filter = Control.MOUSE_FILTER_PASS; add_child(layers); layers.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var body := Panel.new(); body.name = "BalanceArt"; body.position = Vector2(36.0, 24.0); body.size = Vector2(188.0, 42.0); body.mouse_filter = Control.MOUSE_FILTER_IGNORE; layers.add_child(body)
	var icon := TextureRect.new(); icon.name = "BalanceIcon"; icon.position = Vector2(40.0, 25.0); icon.size = Vector2(37.4, 37.4); Hud5Atlas.configure_icon(icon, Hud5Atlas.energy_icon() if energy else Hud5Atlas.balance_coin_icon()); layers.add_child(icon)
	var value := Label.new(); value.name = "Value" if energy else "MoneyLabel"; value.position = Vector2(76.0, 24.0); value.size = Vector2(108.0, 42.0); value.text = "0 / 0" if energy else "0"; value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; value.add_theme_font_size_override(&"font_size", 22 if energy else 25); value.add_theme_color_override(&"font_color", Color.WHITE); value.add_theme_color_override(&"font_outline_color", Color(0.12, 0.04, 0.16, 1.0)); value.add_theme_constant_override(&"outline_size", 5); value.mouse_filter = Control.MOUSE_FILTER_IGNORE; layers.add_child(value)
	var plus := Button.new(); plus.name = "AddButton" if energy else "ShopButton"; plus.position = Vector2(188.0, 28.0); plus.size = Vector2(34.0, 34.0); plus.focus_mode = Control.FOCUS_NONE; layers.add_child(plus)
	if energy:
		var next := PanelContainer.new(); next.name = "Next"; next.position = Vector2(48.0, 66.0); next.size = Vector2(170.0, 24.0); next.mouse_filter = Control.MOUSE_FILTER_IGNORE; layers.add_child(next)
		var timer := Label.new(); timer.name = "Timer"; timer.text = "Next energy in 02:00"; timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; timer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; timer.add_theme_color_override(&"font_color", Color(0.28, 0.12, 0.04, 1.0)); timer.add_theme_font_size_override(&"font_size", 14); next.add_child(timer)

func _apply_programmatic_style() -> void:
	var body := get_node_or_null("Layers/BalanceArt") as Panel
	if body != null:
		var style := CommerceUiStyle.top_hud_style(21); style.shadow_size = 0; style.shadow_offset = Vector2.ZERO; body.add_theme_stylebox_override(&"panel", style)
		var inset := body.get_node_or_null("InnerShadow"); if inset != null: inset.queue_free()
	var plus := get_node_or_null("Layers/%s" % ("AddButton" if energy else "ShopButton")) as Button
	if plus != null: Hud5Atlas.configure_atlas_button(plus, Hud5Atlas.plus_icon())
	if energy:
		var next := get_node_or_null("Layers/Next") as PanelContainer; var timer := get_node_or_null("Layers/Next/Timer") as Label
		if next != null and timer != null: UiAtlas.configure_warm_timer_hud(next, timer)
