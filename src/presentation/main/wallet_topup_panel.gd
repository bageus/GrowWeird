class_name WalletTopupPanel
extends Control
signal purchase_requested(product_id: StringName, coins: int, price_rub: int)
const PRODUCTS := [{ "id": &"coins_100", "coins": 100, "rub": 59 }, { "id": &"coins_300", "coins": 300, "rub": 159 }, { "id": &"coins_1000", "coins": 1000, "rub": 259 }]
const FREE_VIEWS_DEFAULT := 3
@onready var balance_label: Label = %BalanceLabel
@onready var ad_button: Button = %AdButton
@onready var status_label: Label = %StatusLabel
var _ad_pending := false
var _free_views_left := FREE_VIEWS_DEFAULT
func _ready() -> void:
	(%Background as Panel).add_theme_stylebox_override(&"panel", UiAtlas.warm_hud_style(8, 26, Vector4(24.0, 20.0, 24.0, 22.0))); %Banner.texture = UiAtlas.HUD_COIN_ENERGY_BANNER; CommerceUiStyle.curved_title($Window/MenuTitle, "COINS")
	UiAtlas.configure_topup_card(%Coin10, "10", UiAtlas.energy_coin_icon(2, 1)); UiAtlas.configure_topup_card(%Coin100, "100", UiAtlas.energy_coin_icon(1, 2)); UiAtlas.configure_topup_card(%Coin300, "300", UiAtlas.energy_coin_icon(1, 1)); UiAtlas.configure_topup_card(%Coin1000, "1000", UiAtlas.energy_coin_icon(1, 4)); _polish_amounts([%Coin10, %Coin100, %Coin300, %Coin1000]); _add_remaining_label(%Coin10)
	UiAtlas.configure_close_button(%CloseButton); UiAtlas.configure_topup_button(%AdButton, 0, true); UiAtlas.configure_topup_button(%Product100, 59); UiAtlas.configure_topup_button(%Product300, 159); UiAtlas.configure_topup_button(%Product1000, 259)
	%CloseButton.pressed.connect(close); %Product100.pressed.connect(_request_purchase.bind(0)); %Product300.pressed.connect(_request_purchase.bind(1)); %Product1000.pressed.connect(_request_purchase.bind(2)); ad_button.pressed.connect(_request_rewarded_ad); _app().state_changed.connect(refresh); visibility_changed.connect(refresh); refresh()
func _polish_amounts(cards: Array) -> void:
	for card in cards:
		var label := card.get_node_or_null("Title") as Label
		if label != null: label.add_theme_font_size_override(&"font_size", 31); label.add_theme_constant_override(&"outline_size", 5)
func _add_remaining_label(card: Panel) -> void:
	var label := Label.new(); label.name = "Remaining"; label.mouse_filter = Control.MOUSE_FILTER_IGNORE; label.set_anchors_preset(Control.PRESET_TOP_WIDE); label.offset_top = 55.0; label.offset_bottom = 78.0; label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.add_theme_font_override(&"font", UiAtlas.GAME_FONT); label.add_theme_font_size_override(&"font_size", 12); label.add_theme_color_override(&"font_color", Color(0.33, 0.18, 0.1, 1.0)); card.add_child(label)
func open() -> void: visible = true; status_label.text = ""; refresh()
func close() -> void: visible = false
func refresh() -> void:
	var app := _app(); if not is_node_ready() or app.state == null: return
	balance_label.text = "Balance: %d coins" % app.state.money; ad_button.disabled = _free_views_left <= 0; ad_button.tooltip_text = "Free reward · +10 coins"
	var remaining := %Coin10.get_node_or_null("Remaining") as Label; if remaining != null: remaining.text = "осталось %d" % _free_views_left
func _request_purchase(index: int) -> void:
	var product: Dictionary = PRODUCTS[index]; purchase_requested.emit(product["id"], int(product["coins"]), int(product["rub"])); var credited: int = int(_app().buy_coins(int(product["coins"]))); if credited > 0: TaskService.record_daily_event(_app().state, &"coins_bought"); status_label.text = "+%d coins received." % credited; refresh()
func _request_rewarded_ad() -> void:
	if _free_views_left <= 0: return
	_free_views_left -= 1; status_label.text = "+%d coins received." % _app().buy_coins(10); refresh()
func _on_ad_closed(was_shown: bool) -> void:
	_ad_pending = false
	if was_shown and _free_views_left > 0 and _app().claim_rewarded_ad(_platform().now_unix()): _free_views_left -= 1; status_label.text = "+10 coins received."
	else: status_label.text = "Advertisement was not completed."
	refresh()
func _format_duration(seconds: int) -> String:
	var hours := floori(float(seconds) / 3600.0); var minutes := floori(float(seconds % 3600) / 60.0); return "%02d:%02d" % [hours, minutes]
func _app() -> Node: return get_node("/root/GameApp")
func _platform() -> Node: return get_node("/root/PlatformRuntime")
