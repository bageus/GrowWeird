class_name FertilizerOfferPanel
extends SceneDraggablePanel

var _dim: ColorRect
var _timer: PanelContainer
var _timer_label: Label
var _journal_button: Button
var _journal: PanelContainer
var _ad_pending := false

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
	UiAtlas.configure_warm_timer_hud(_timer, _timer_label)
	_journal_button = auxiliary.get_node("JournalButton") as Button
	CommerceUiStyle.transaction_action(_journal_button, &"journal")
	_journal_button.pressed.connect(_toggle_journal)
	_journal = auxiliary.get_node("Journal") as PanelContainer
	_journal.add_theme_stylebox_override(&"panel", UiAtlas.warm_hud_style(6, 24, Vector4(24.0, 22.0, 24.0, 22.0)))

func _sync() -> void:
	var host := get_parent() as Control
	var app := get_node_or_null("/root/GameApp")
	if host == null or app == null or app.state == null:
		return
	var active: bool = app.state.fertilizer_offer.is_active()
	visible = active
	_dim.visible = active or _journal.visible
	_timer.visible = not active
	if active:
		z_index = 210
		position = (host.size - size) * 0.5
	var seconds := maxi(0, int(ceil(app.state.fertilizer_offer.seconds_until_offer)))
	_timer_label.text = "FERTILIZERS %02d:%02d" % [floori(float(seconds) / 60.0), seconds % 60]
	_refresh_journal(app)

func _refresh_journal(app: Node) -> void:
	var label := _journal.get_node_or_null("KnowledgeText") as Label
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
	_dim.visible = visible or _journal.visible

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
		app.call("refresh_fertilizer_offer_rewarded") if was_shown else _sync()
