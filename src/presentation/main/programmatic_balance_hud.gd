class_name ProgrammaticBalanceHud
extends Panel

@export var plus_button_path: NodePath

func _ready() -> void:
	call_deferred("_apply_programmatic_style")

func _apply_programmatic_style() -> void:
	var inset := get_node_or_null("InnerShadow")
	if inset != null:
		inset.queue_free()
	var hud_style := CommerceUiStyle.top_hud_style(21)
	hud_style.shadow_size = 0
	hud_style.shadow_offset = Vector2.ZERO
	add_theme_stylebox_override(&"panel", hud_style)
	_move_wallet_coin_icon()
	var button := get_node_or_null(plus_button_path) as Button
	if button == null:
		return
	button.icon = null
	button.expand_icon = false
	CommerceUiStyle.balance_plus(button)

func _move_wallet_coin_icon() -> void:
	var layers := get_parent()
	if layers == null or layers.get_parent() == null or layers.get_parent().name != "WalletHud":
		return
	var icon := layers.get_node_or_null("BalanceIcon") as TextureRect
	if icon == null:
		return
	icon.position = Vector2(-8.0, 14.0)
