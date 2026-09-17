class_name EnergyTopupPanel
extends Control
signal purchase_requested(product_id: StringName, energy: int, price_rub: int)
const PRODUCTS := [{ "id": &"energy_15", "energy": 15, "rub": 59 }, { "id": &"energy_30", "energy": 30, "rub": 159 }]
const FREE_VIEWS_DEFAULT := 6
var _ad_pending := false
var _free_views_left := FREE_VIEWS_DEFAULT
func _ready() -> void:
	(%Background as Panel).add_theme_stylebox_override(&"panel", UiAtlas.warm_hud_style(8, 26, Vector4(24.0, 20.0, 24.0, 22.0))); %Banner.texture = UiAtlas.HUD_COIN_ENERGY_BANNER; CommerceUiStyle.curved_title($Window/MenuTitle, "ENERGY")
	UiAtlas.configure_topup_card(%Energy5, "5", UiAtlas.energy_coin_icon(3, 3)); UiAtlas.configure_topup_card(%Energy15, "15", UiAtlas.energy_coin_icon(3, 2)); UiAtlas.configure_topup_card(%Energy30, "30", UiAtlas.energy_coin_icon(3, 4)); _polish_amounts([%Energy5, %Energy15, %Energy30]); _add_remaining_label(%Energy5)
	UiAtlas.configure_close_button(%CloseButton); UiAtlas.configure_topup_button(%AdButton, 0, true); UiAtlas.configure_topup_button(%Pack15, 59); UiAtlas.configure_topup_button(%Pack30, 159)
	%CloseButton.pressed.connect(close); %AdButton.pressed.connect(_request_rewarded_ad); %Pack15.pressed.connect(_purchase.bind(0)); %Pack30.pressed.connect(_purchase.bind(1)); _app().state_changed.connect(refresh); refresh()
func _polish_amounts(cards: Array) -> void:
	for card in cards:
		var label := card.get_node_or_null("Title") as Label
		if label != null: label.add_theme_font_size_override(&"font_size", 31); label.add_theme_constant_override(&"outline_size", 5)
func _add_remaining_label(card: Panel) -> void:
	var label := Label.new(); label.name = "Remaining"; label.mouse_filter = Control.MOUSE_FILTER_IGNORE; label.set_anchors_preset(Control.PRESET_TOP_WIDE); label.offset_top = 55.0; label.offset_bottom = 78.0; label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.add_theme_font_override(&"font", UiAtlas.GAME_FONT); label.add_theme_font_size_override(&"font_size", 12); label.add_theme_color_override(&"font_color", Color(0.33, 0.18, 0.1, 1.0)); card.add_child(label)
func open() -> void: visible = true; %StatusLabel.text = ""; refresh()
func close() -> void: visible = false
func refresh() -> void:
	if not is_node_ready() or _app().state == null: return
	%EnergyLabel.text = "Energy %d / %d · next +1: %s" % [_app().state.energy, EnergyService.capacity(_app().state), _timer()]; %AdButton.disabled = _free_views_left <= 0; %AdButton.tooltip_text = "Free reward · +5 energy"
	var remaining := %Energy5.get_node_or_null("Remaining") as Label; if remaining != null: remaining.text = "осталось %d" % _free_views_left
func _purchase(index: int) -> void:
	var product: Dictionary = PRODUCTS[index]; purchase_requested.emit(product["id"], int(product["energy"]), int(product["rub"])); var credited: int = int(_app().buy_energy(int(product["energy"]))); if credited > 0: TaskService.record_daily_event(_app().state, &"energy_bought"); %StatusLabel.text = "+%d energy received." % credited; refresh()
func _request_rewarded_ad() -> void:
	if _free_views_left <= 0: return
	_free_views_left -= 1; %StatusLabel.text = "+%d energy received." % _app().buy_energy(5); refresh()
func _on_ad_closed(was_shown: bool) -> void:
	_ad_pending = false
	if was_shown and _free_views_left > 0 and _app().buy_energy(5) > 0: _free_views_left -= 1; %StatusLabel.text = "+5 energy received."
	else: %StatusLabel.text = "Advertisement was not completed."
	refresh()
func _timer() -> String:
	var seconds := EnergyService.seconds_to_next(_app().state); return "full" if seconds == 0 else "%02d:%02d" % [floori(float(seconds) / 60.0), seconds % 60]
func _app() -> Node: return get_node("/root/GameApp")
func _platform() -> Node: return get_node("/root/PlatformRuntime")
