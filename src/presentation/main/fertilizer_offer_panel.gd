class_name FertilizerOfferPanel
extends SceneDraggablePanel

var _dim: ColorRect
var _timer: PanelContainer
var _timer_label: Label
var _journal_button: Button
var _journal: PanelContainer

func _ready() -> void:
	super()
	_build_auxiliary_hud()
	var app := get_node_or_null("/root/GameApp")
	if app != null:
		app.state_changed.connect(_sync)
	get_parent().resized.connect(_sync)
	call_deferred("_sync")

func _build_auxiliary_hud() -> void:
	var host := get_parent() as Control
	_dim = ColorRect.new()
	_dim.name = "FertilizerOfferDim"
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0.02, 0.015, 0.025, 0.68)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.z_index = 208
	host.add_child(_dim)
	host.move_child(_dim, get_index())
	_timer = PanelContainer.new()
	_timer.name = "FertilizerTimerHud"
	_timer.size = Vector2(224.0, 52.0)
	_timer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_timer.z_index = 20
	host.add_child(_timer)
	_timer_label = Label.new()
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_timer.add_child(_timer_label)
	UiAtlas.configure_warm_timer_hud(_timer, _timer_label)
	_journal_button = Button.new()
	_journal_button.name = "MutationJournalButton"
	_journal_button.text = "JOURNAL"
	_journal_button.size = Vector2(150.0, 52.0)
	_journal_button.z_index = 20
	CommerceUiStyle.transaction_action(_journal_button, &"journal")
	host.add_child(_journal_button)
	_journal_button.pressed.connect(_toggle_journal)
	_build_journal(host)

func _build_journal(host: Control) -> void:
	_journal = PanelContainer.new()
	_journal.name = "MutationJournal"
	_journal.size = Vector2(430.0, 330.0)
	_journal.z_index = 211
	_journal.visible = false
	_journal.add_theme_stylebox_override(&"panel", UiAtlas.warm_hud_style(6, 24, Vector4(24.0, 22.0, 24.0, 22.0)))
	host.add_child(_journal)
	var text := Label.new()
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	text.text = "MUTATION JOURNAL\n\nApply fertilizers and observe the plant to build knowledge about mutation effects. Known characteristics and discovered combinations will be recorded here."
	_journal.add_child(text)

func _sync() -> void:
	var host := get_parent() as Control
	var app := get_node_or_null("/root/GameApp")
	if host == null or app == null or app.state == null:
		return
	var active: bool = app.state.fertilizer_offer.is_active()
	visible = active
	_dim.visible = active
	_timer.visible = not active
	if active:
		z_index = 210
		position = (host.size - size) * 0.5
	var seconds := maxi(0, int(ceil(app.state.fertilizer_offer.seconds_until_offer)))
	_timer_label.text = "FERTILIZERS %02d:%02d" % [floori(float(seconds) / 60.0), seconds % 60]
	_timer.position = Vector2(16.0, maxf(16.0, (host.size.y - 52.0) * 0.5))
	_journal_button.position = _timer.position + Vector2(37.0, 62.0)
	_journal.position = (host.size - _journal.size) * 0.5

func _toggle_journal() -> void:
	_journal.visible = not _journal.visible
	_dim.visible = visible or _journal.visible
