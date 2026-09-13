class_name FertilizerOfferPanel
extends SceneDraggablePanel

var _dim: ColorRect
var _timer: PanelContainer
var _timer_label: Label
var _journal_button: Button
var _journal: Control
var _ad_pending := false
var _last_blocked := false

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
	var auxiliary := get_parent().get_node("FertilizerAuxiliaryUi")
	_dim = auxiliary.get_node("Dim") as ColorRect
	_timer = auxiliary.get_node("TimerHud") as PanelContainer
	_timer_label = auxiliary.get_node("TimerHud/Label") as Label
	_configure_timer_hud()
	_journal_button = auxiliary.get_node("JournalButton") as Button
	CommerceUiStyle.transaction_action(_journal_button, &"journal")
	_journal_button.pressed.connect(_toggle_journal)
	_journal = auxiliary.get_node("Journal") as Control
	(_journal.get_node("Background") as Panel).add_theme_stylebox_override(&"panel", UiAtlas.warm_hud_style(8, 26, Vector4(24.0, 20.0, 24.0, 22.0)))
	(_journal.get_node("Banner") as TextureRect).texture = UiAtlas.HUD_BUYSELL_BANNER
	CommerceUiStyle.curved_title(_journal.get_node("Title") as Label, "JOURNAL")
	var content_hud := _journal.get_node("ContentHud") as Panel
	content_hud.add_theme_stylebox_override(&"panel", UiAtlas.warm_hud_style(2, 14, Vector4(18.0, 16.0, 18.0, 16.0)))
	var close_button := _journal.get_node("Close") as Button
	UiAtlas.configure_close_button(close_button)
	close_button.pressed.connect(_close_journal)

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
	_refresh_journal(app)

func _refresh_journal(app: Node) -> void:
	var label := _journal.get_node_or_null("ContentHud/Scroll/KnowledgeText") as Label
	if label == null:
		return
	var knowledge := app.call("fertilizer_knowledge") as Dictionary
	var lines: Array[String] = ["MUTATION JOURNAL", ""]
	if knowledge.is_empty():
		lines.append("Use fertilizers to reveal their care and mutation properties.")
	else:
		var ids := knowledge.keys(); ids.sort()
		for raw_id in ids:
			var entry: Dictionary = knowledge[raw_id]
			var details: Array[String] = ["used ×%d" % int(entry.get("uses", 0))]
			var care: Dictionary = entry.get("care_effects", {})
			for key in care:
				var amount := float(care[key])
				details.append("%s %s%.2f" % [String(key).replace("_", " "), "+" if amount >= 0.0 else "", amount])
			var traits: Array = entry.get("discovered_traits", [])
			if not traits.is_empty(): details.append("mutations: %s" % ", ".join(traits))
			lines.append("%s — %s" % [String(raw_id).replace("_", " ").capitalize(), "; ".join(details)])
	label.text = "\n".join(lines)

func _toggle_journal() -> void:
	_journal.visible = not _journal.visible
	_sync()

func _close_journal() -> void:
	_journal.visible = false
	_sync()

func _other_menu_open() -> bool:
	if _journal != null and _journal.visible: return true
	var host := get_parent()
	for path in ["ShopContainer", "WalletTopupPanel", "EnergyTopupPanel", "WaterOptions", "LightingOptions"]:
		var menu := host.get_node_or_null(path) as Control
		if menu != null and menu.visible: return true
	var dialogs := host.get_node_or_null("InventoryItemDialogs") as InventoryItemDialogs
	return dialogs != null and dialogs.is_open()

func _configure_timer_hud() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("74320f"); style.border_color = Color("ffad25"); style.set_border_width_all(4); style.set_corner_radius_all(19)
	style.shadow_color = Color(0.20, 0.06, 0.01, 0.55); style.shadow_size = 5; style.shadow_offset = Vector2(0.0, 3.0)
	_timer.add_theme_stylebox_override(&"panel", style)
	_timer_label.add_theme_font_size_override(&"font_size", 15); _timer_label.add_theme_color_override(&"font_color", Color("ffe7a1")); _timer_label.add_theme_color_override(&"font_outline_color", Color("3b1405")); _timer_label.add_theme_constant_override(&"outline_size", 2)

func _request_rewarded_refresh() -> void:
	_ad_pending = true
	get_node("Row/AdOffer").disabled = true
	get_node("/root/GameApp").call("show_fullscreen_ad")

func _on_ad_closed(was_shown: bool) -> void:
	if not _ad_pending: return
	_ad_pending = false
	get_node("Row/AdOffer").disabled = false
	var app := get_node_or_null("/root/GameApp")
	if app != null and app.state.fertilizer_offer.is_active():
		if was_shown:
			app.call("refresh_fertilizer_offer_rewarded")
		else:
			_sync()
