class_name FertilizerOfferPanel
extends SceneDraggablePanel

var _dim: ColorRect
var _timer: Control
var _timer_label: Label
var _timer_finish: Button
var _journal_button: Button
var _journal: Control
var _ad_pending := false
var _last_blocked := false
var _journal_tab: StringName = &"unknown"

func _ready() -> void:
	super()
	_bind_auxiliary_hud()
	var app := get_node_or_null("/root/GameApp")
	if app != null:
		app.state_changed.connect(_sync)
		get_node("Row/AdOffer").pressed.connect(_request_rewarded_refresh)
		app.call("_platform_runtime").ad_closed.connect(_on_ad_closed)
	get_parent().resized.connect(_sync)
	call_deferred("_sync")

func _bind_auxiliary_hud() -> void:
	var host := get_parent() as Control
	var auxiliary := host.get_node("FertilizerAuxiliaryUi")
	_dim = auxiliary.get_node("Dim") as ColorRect
	_timer = auxiliary.get_node("TimerHud") as Control
	_timer_label = auxiliary.get_node("TimerHud/Label") as Label
	_timer_finish = auxiliary.get_node("TimerHud/FinishButton") as Button
	_configure_timer_hud()
	_timer_finish.pressed.connect(_finish_timer)
	var legacy_journal_button := auxiliary.get_node_or_null("JournalButton") as Button
	if legacy_journal_button != null:
		legacy_journal_button.hide()
	_journal_button = host.get_node("JournalButton") as Button
	if _journal_button is SceneActionButton:
		(_journal_button as SceneActionButton).action_id = &""
	_journal_button.z_as_relative = true
	_journal_button.z_index = 0
	_journal_button.mouse_filter = Control.MOUSE_FILTER_STOP
	CommerceUiStyle.transaction_action(_journal_button, &"journal")
	_place_journal_button(host)
	_journal_button.pressed.connect(_toggle_journal)
	_journal = auxiliary.get_node("Journal") as Control
	(_journal.get_node("Background") as Panel).add_theme_stylebox_override(&"panel", UiAtlas.warm_hud_style(8, 26, Vector4(24.0, 20.0, 24.0, 22.0)))
	(_journal.get_node("Banner") as TextureRect).texture = UiAtlas.HUD_BUYSELL_BANNER
	CommerceUiStyle.curved_title(_journal.get_node("Title") as Label, "JOURNAL", 3.0)
	var content_hud := _journal.get_node("ContentHud") as Panel
	content_hud.add_theme_stylebox_override(&"panel", UiAtlas.warm_hud_style(2, 14, Vector4(18.0, 16.0, 18.0, 16.0)))
	var close_button := _journal.get_node("Close") as Button
	UiAtlas.configure_close_button(close_button)
	close_button.pressed.connect(_close_journal)
	for tab: StringName in [&"unknown", &"fertilizers", &"decorations", &"mutagens"]:
		var button := _journal.get_node("ContentHud/Tabs/%s" % String(tab).capitalize()) as Button
		CommerceUiStyle.shop_category_button(button, button.text, Color("b86a22"))
		button.pressed.connect(_select_journal_tab.bind(tab))

func _place_journal_button(host: Control) -> void:
	if _journal_button == null or host == null:
		return
	_journal_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_journal_button.position = Vector2(28.0, maxf(0.0, host.size.y - 92.0))
	_journal_button.size = Vector2(150.0, 37.0)
	_journal_button.modulate = Color.WHITE
	_journal_button.self_modulate = Color.WHITE
	_journal_button.show()
	_journal_button.move_to_front()

func _process(_delta: float) -> void:
	var blocked := _other_menu_open()
	if blocked != _last_blocked:
		_last_blocked = blocked
		_sync()

func _sync() -> void:
	var host := get_parent() as Control
	var app := get_node_or_null("/root/GameApp")
	if host == null or app == null or app.state == null:
		return
	_place_journal_button(host)
	var active: bool = app.state.fertilizer_offer.is_active()
	var blocked := _other_menu_open()
	visible = active and not blocked
	_dim.visible = visible or _journal.visible
	_timer.visible = not active
	if visible:
		z_index = 210
		position = (host.size - size) * 0.5
	var seconds := maxi(0, int(ceil(app.state.fertilizer_offer.seconds_until_offer)))
	_timer_label.text = "FERTILIZERS %02d:%02d" % [floori(float(seconds) / 60.0), seconds % 60]
	var finish_cost := EnergyService.fertilizer_timer_skip_cost(app.state.fertilizer_offer)
	_timer_finish.text = "FINISH · %d" % finish_cost
	_timer_finish.disabled = finish_cost <= 0
	_refresh_journal(app)

func _refresh_journal(app: Node) -> void:
	var scroll := _journal.get_node_or_null("ContentHud/Scroll") as ScrollContainer
	JournalCardGrid.populate(scroll, app, _journal_tab)

func _select_journal_tab(tab: StringName) -> void:
	_journal_tab = tab
	var app := get_node_or_null("/root/GameApp")
	if app != null:
		_refresh_journal(app)

func _toggle_journal() -> void:
	_journal.visible = not _journal.visible
	_sync()

func _close_journal() -> void:
	_journal.visible = false
	_sync()

func _other_menu_open() -> bool:
	if _journal != null and _journal.visible:
		return true
	var host := get_parent()
	for path in ["ShopContainer", "WalletTopupPanel", "EnergyTopupPanel", "WaterOptions", "LightingOptions"]:
		var menu := host.get_node_or_null(path) as Control
		if menu != null and menu.visible:
			return true
	var dialogs := host.get_node_or_null("InventoryItemDialogs") as InventoryItemDialogs
	return dialogs != null and dialogs.is_open()

func _configure_timer_hud() -> void:
	_timer.size = Vector2(306.0, 42.0)
	_timer_label.position = Vector2(14.0, 0.0)
	_timer_label.size = Vector2(173.0, 42.0)
	_timer_finish.position = Vector2(192.0, 3.0)
	_timer_finish.size = Vector2(112.0, 36.0)
	var hud := _timer.get_node("Hud") as Panel
	var hud_style := CommerceUiStyle.top_hud_style(21)
	hud_style.shadow_size = 0
	hud_style.shadow_offset = Vector2.ZERO
	hud.add_theme_stylebox_override(&"panel", hud_style)
	_timer_label.add_theme_font_size_override(&"font_size", 15)
	_timer_label.add_theme_color_override(&"font_color", Color("ffe7a1"))
	_timer_label.add_theme_color_override(&"font_outline_color", Color("3b1405"))
	_timer_label.add_theme_constant_override(&"outline_size", 2)
	_timer_finish.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_finish.add_theme_font_size_override(&"font_size", 16)
	_timer_finish.add_theme_color_override(&"font_color", Color.WHITE)
	_timer_finish.add_theme_color_override(&"font_outline_color", Color("31105c"))
	_timer_finish.add_theme_constant_override(&"outline_size", 2)
	for state in [&"normal", &"hover", &"pressed", &"disabled"]:
		_timer_finish.add_theme_stylebox_override(state, _finish_button_style(state))
	_timer_finish.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())

func _finish_button_style(state: StringName) -> StyleBoxFlat:
	var colors := {&"normal": Color("7d25e8"), &"hover": Color("963cf2"), &"pressed": Color("6418c2"), &"disabled": Color("766b7e")}
	var style := StyleBoxFlat.new()
	style.bg_color = colors[state]
	style.border_color = Color("451086")
	style.set_border_width_all(3)
	style.set_corner_radius_all(17)
	style.content_margin_top = 4.0
	style.content_margin_bottom = 3.0
	style.shadow_color = Color(0.10, 0.02, 0.18, 0.55)
	style.shadow_size = 2
	style.shadow_offset = Vector2(0.0, 1.0)
	return style

func _finish_timer() -> void:
	var app := get_node_or_null("/root/GameApp")
	if app != null and not bool(app.call("finish_fertilizer_timer")):
		get_parent().call("show_insufficient_balance", true)

func _request_rewarded_refresh() -> void:
	_ad_pending = true
	get_node("Row/AdOffer").disabled = true
	get_node("/root/GameApp").call("show_fullscreen_ad")

func _on_ad_closed(was_shown: bool) -> void:
	if not _ad_pending:
		return
	_ad_pending = false
	get_node("Row/AdOffer").disabled = false
	var app := get_node_or_null("/root/GameApp")
	if app != null and app.state.fertilizer_offer.is_active():
		if was_shown:
			app.call("refresh_fertilizer_offer_rewarded")
		else:
			_sync()
