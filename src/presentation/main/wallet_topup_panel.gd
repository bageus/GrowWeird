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
	%CloseButton.pressed.connect(close)
	%Product100.pressed.connect(_request_purchase.bind(0))
	%Product300.pressed.connect(_request_purchase.bind(1))
	%Product1000.pressed.connect(_request_purchase.bind(2))
	ad_button.pressed.connect(_request_rewarded_ad)
	GameApp.state_changed.connect(refresh)
	visibility_changed.connect(refresh)
	refresh()

func open() -> void:
	visible = true
	status_label.text = ""
	refresh()

func close() -> void:
	visible = false

func refresh() -> void:
	if not is_node_ready() or GameApp.state == null:
		return
	var now_unix := PlatformRuntime.now_unix()
	var remaining := RewardedAdService.remaining_claims(GameApp.state, now_unix)
	balance_label.text = "Balance: %d coins" % GameApp.state.money
	ad_button.disabled = _ad_pending or remaining <= 0
	if remaining > 0:
		ad_button.text = "Watch ad  ·  +10 coins  ·  %d/4 left" % remaining
	else:
		ad_button.text = "Next ad in %s" % _format_duration(RewardedAdService.seconds_until_next(GameApp.state, now_unix))

func _request_purchase(index: int) -> void:
	var product: Dictionary = PRODUCTS[index]
	purchase_requested.emit(product["id"], int(product["coins"]), int(product["rub"]))
	status_label.text = "Waiting for payment provider confirmation."

func _request_rewarded_ad() -> void:
	if _ad_pending or RewardedAdService.remaining_claims(GameApp.state, PlatformRuntime.now_unix()) <= 0:
		return
	_ad_pending = true
	status_label.text = "Opening advertisement..."
	PlatformRuntime.ad_closed.connect(_on_ad_closed, CONNECT_ONE_SHOT)
	GameApp.show_fullscreen_ad()
	refresh()

func _on_ad_closed(was_shown: bool) -> void:
	_ad_pending = false
	if was_shown and GameApp.claim_rewarded_ad(PlatformRuntime.now_unix()):
		status_label.text = "+10 coins received."
	else:
		status_label.text = "Advertisement was not completed."
	refresh()

func _format_duration(seconds: int) -> String:
	var hours := floori(float(seconds) / 3600.0)
	var minutes := floori(float(seconds % 3600) / 60.0)
	return "%02d:%02d" % [hours, minutes]
