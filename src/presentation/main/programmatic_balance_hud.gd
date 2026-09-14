class_name ProgrammaticBalanceHud
extends Panel

@export var plus_button_path: NodePath

func _ready() -> void:
	call_deferred("_apply_programmatic_style")

func _apply_programmatic_style() -> void:
	CommerceUiStyle.balance_hud(self)
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
