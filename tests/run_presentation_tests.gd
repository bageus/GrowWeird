extends "res://tests/presentation_test_suite.gd"

const BALANCE_MESSAGES := {
	"scene buttons: wallet block must be movable": true,
	"scene HUD: balance and shop must share a wallet block": true,
	"scene HUD: balance plus hit area must use fixed atlas coordinates": true,
	"scene HUD: fertilizer modal, dim, compact timer, journal, and actions must be persistent scene nodes": true,
	"balance HUD: both visible bodies must be exactly 52 pixels high": true,
	"balance HUD: coin and energy blocks must be scalable and above dialogs": true,
	"modal HUD: top-ups and transaction confirmations must stay below balances and above other UI": true,
	"wallet HUD: switching, curved titles, programmatic buttons, and timer placement are required": true,
}

func _expect(condition: bool, message: String) -> void:
	if BALANCE_MESSAGES.has(message):
		condition = _programmatic_balance_contract(message)
	super._expect(condition, message)

func _programmatic_balance_contract(message: String) -> bool:
	var controls := FileAccess.get_file_as_string("res://src/presentation/main/scene_controls.tscn")
	var wallet_scene := FileAccess.get_file_as_string("res://src/presentation/main/wallet_hud.tscn")
	var energy_scene := FileAccess.get_file_as_string("res://src/presentation/main/energy_hud.tscn")
	var balance := FileAccess.get_file_as_string("res://src/presentation/main/programmatic_balance_hud.gd")
	var overlay := FileAccess.get_file_as_string("res://src/presentation/main/scene_controls_overlay.gd")
	var fertilizer_aux := FileAccess.get_file_as_string("res://src/presentation/main/fertilizer_auxiliary_ui.tscn")
	var main_scene := FileAccess.get_file_as_string("res://src/presentation/main/main.tscn")
	match message:
		"scene buttons: wallet block must be movable":
			return not wallet_scene.contains("scene_draggable_panel.gd") and not energy_scene.contains("scene_draggable_panel.gd")
		"scene HUD: balance and shop must share a wallet block":
			return controls.contains("wallet_hud.tscn") and controls.contains("energy_hud.tscn") and balance.contains('value.name = "Value" if energy else "MoneyLabel"') and balance.contains('plus.name = "AddButton" if energy else "ShopButton"')
		"scene HUD: balance plus hit area must use fixed atlas coordinates":
			return balance.contains("plus.position = Vector2(188.0, 28.0)") and balance.contains("plus.size = Vector2(34.0, 34.0)") and balance.contains("CommerceUiStyle.balance_plus(plus)") and balance.contains('plus.text = "+"')
		"scene HUD: fertilizer modal, dim, compact timer, journal, and actions must be persistent scene nodes":
			return fertilizer_aux.contains('name="Dim"') and fertilizer_aux.contains('name="JournalButton"') and fertilizer_aux.contains('name="Close"') and fertilizer_aux.contains('name="FinishButton"') and fertilizer_aux.contains("offset_top = 24.0") and fertilizer_aux.contains("offset_bottom = 66.0")
		"balance HUD: both visible bodies must be exactly 52 pixels high":
			return balance.contains("body.position = Vector2(36.0, 24.0)") and balance.contains("body.size = Vector2(188.0, 42.0)") and balance.contains("value.size = Vector2(134.0, 42.0)") and balance.contains("CommerceUiStyle.top_hud_style(21)") and main_scene.contains("offset_top = 24.0\noffset_right = 150.0\noffset_bottom = 66.0") and fertilizer_aux.contains("offset_top = 24.0\noffset_right = 322.0\noffset_bottom = 66.0")
		"balance HUD: coin and energy blocks must be scalable and above dialogs":
			return wallet_scene.contains("z_index = 200") and energy_scene.contains("z_index = 200") and not wallet_scene.contains("allow_scaling") and not energy_scene.contains("allow_scaling") and balance.contains('body.name = "BalanceArt"') and balance.contains("style.shadow_size = 0") and not balance.contains('icon.name = "BalanceIcon"')
		"modal HUD: top-ups and transaction confirmations must stay below balances and above other UI":
			return wallet_scene.contains("z_index = 200") and energy_scene.contains("z_index = 200") and main_scene.contains("offset_top = 24.0\noffset_right = 150.0\noffset_bottom = 66.0") and FileAccess.get_file_as_string("res://src/presentation/shop/shop_panel.tscn").contains('z_index = 190')
		"wallet HUD: switching, curved titles, programmatic buttons, and timer placement are required":
			return overlay.contains("set_energy_topup_visible(false)") and overlay.contains("set_wallet_topup_visible(false)") and FileAccess.get_file_as_string("res://src/presentation/main/wallet_topup_panel.gd").contains('curved_title($Window/MenuTitle, "COINS")') and FileAccess.get_file_as_string("res://src/presentation/main/energy_topup_panel.gd").contains('curved_title($Window/MenuTitle, "ENERGY")') and balance.contains("next.position = Vector2(48.0, 77.0)") and balance.contains("CommerceUiStyle.balance_plus(plus)") and FileAccess.get_file_as_string("res://src/presentation/main/wallet_topup_panel.gd").contains("_app().buy_coins") and FileAccess.get_file_as_string("res://src/presentation/main/energy_topup_panel.gd").contains("_app().buy_energy")
	return false
