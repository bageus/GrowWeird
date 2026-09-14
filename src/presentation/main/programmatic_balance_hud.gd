class_name ProgrammaticBalanceHud
extends Panel

@export var plus_button_path: NodePath

func _ready() -> void:
	call_deferred("_apply_programmatic_style")

func _apply_programmatic_style() -> void:
	position = Vector2(0.0, 20.0)
	size = Vector2(224.0, 60.0)
	var inset := get_node_or_null("InnerShadow")
	if inset != null:
		inset.queue_free()
	add_theme_stylebox_override(&"panel", CommerceUiStyle.top_hud_style(24))
	var button := get_node_or_null(plus_button_path) as Button
	if button == null:
		return
	button.icon = null
	button.expand_icon = false
	CommerceUiStyle.balance_plus(button)
	button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	button.custom_minimum_size = Vector2(39.0, 39.0)
	button.position = Vector2(182.0, 11.0)
	button.size = Vector2(39.0, 39.0)
