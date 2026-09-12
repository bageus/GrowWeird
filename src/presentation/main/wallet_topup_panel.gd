class_name WalletTopupPanel
extends Control

signal purchase_requested(product_id: StringName, coins: int, price_rub: int)

const PRODUCTS := [
	{ "id": &"coins_100", "coins": 100, "rub": 59 },
	{ "id": &"coins_300", "coins": 300, "rub": 159 },
	{ "id": &"coins_1000", "coins": 1000, "rub": 259 },
]

@onready var balance_label: Label = %BalanceLabel
@onready var ad_button: Button = %AdButton
@onready var status_label: Label = %StatusLabel
var _ad_pending := false

func _ready() -> void:
	(%Background as Panel).add_theme_stylebox_override(&"panel", UiAtlas.warm_hud_style(8, 26, Vector4(24.0, 20.0, 24.0, 22.0)))
	%Banner.texture = UiAtlas.HUD_COIN_ENERGY_BANNER
	CommerceUiStyle.curved_title($Window/MenuTitle, "COINS")
	UiAtlas.configure_topup_card(%Coin10, "10 Coins", UiAtlas.energy_coin_icon(2, 1))
	UiAtlas.configure_topup_card(%Coin100, "100 Coins", UiAtlas.energy_coin_icon(1, 2))
	UiAtlas.configure_topup_card(%Coin300, "300 Coins", UiAtlas.energy_coin_icon(1, 1))
	UiAtlas.configure_topup_card(%Coin1000, "1000 Coins", UiAtlas.energy_coin_icon(1, 4))
	UiAtlas.configure_close_button(%CloseButton)
	UiAtlas.configure_topup_button(%AdButton, 0, true)
	UiAtlas.configure_topup_button(%Product100, 59)
	UiAtlas.configure_topup_button(%Product300, 159)
	UiAtlas.configure_topup_button(%Product1000, 259)
	%CloseButton.pressed.connect(close)
	%Product100.pressed.connect(_request_purchase.bind(0))
	%Product300.pressed.connect(_request_purchase.bind(1))
	%Product1000.pressed.connect(_request_purchase.bind(2))
	ad_button.pressed.connect(_request_rewarded_ad)
	_app().state_changed.connect(refresh)
	visibility_changed.connect(refresh)
	refresh()

func open() -> void:
	visible = true
	status_label.text = ""
	refresh()

func close() -> void:
	visible = false

func refresh() -> void:
	var app := _app()
	if not is_node_ready() or app.state == null:
		return
	balance_label.text = "Balance: %d coins" % app.state.money
	ad_button.disabled = false
	ad_button.tooltip_text = "Temporary local reward · +10 coins"

func _request_purchase(index: int) -> void:
	var product: Dictionary = PRODUCTS[index]
	purchase_requested.emit(product["id"], int(product["coins"]), int(product["rub"]))
	var credited := _app().buy_coins(int(product["coins"]))
	status_label.text = "+%d coins received." % credited
	refresh()

func _request_rewarded_ad() -> void:
	status_label.text = "+%d coins received." % _app().buy_coins(10)
	refresh()

func _on_ad_closed(was_shown: bool) -> void:
	_ad_pending = false
	if was_shown and _app().claim_rewarded_ad(_platform().now_unix()):
		status_label.text = "+10 coins received."
	else:
		status_label.text = "Advertisement was not completed."
	refresh()

func _format_duration(seconds: int) -> String:
	var hours := floori(float(seconds) / 3600.0)
	var minutes := floori(float(seconds % 3600) / 60.0)
	return "%02d:%02d" % [hours, minutes]

func _app() -> Node: return get_node("/root/GameApp")
func _platform() -> Node: return get_node("/root/PlatformRuntime")
