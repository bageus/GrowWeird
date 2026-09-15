class_name ProgressionPanel
extends PanelContainer

const WINDOW_SIZE := Vector2(900.0, 510.0)
const CARD_SIZE := Vector2(210.0, 286.0)
const CONNECTOR_WIDTH := 62.0

var _overlay: Control
var _window: Control
var _content: Control
var _main_tab: Button
var _daily_tab: Button
var _tab: StringName = &"main"
var _suppress_visibility := false
var _refresh_queued := false

func _app() -> Node: return get_node_or_null("/root/GameApp")
func _ready() -> void:
	_build_modal(); call_deferred("_attach_modal")
	var app := _app()
	if app != null: TaskService.ensure_daily(app.state, int(Time.get_unix_time_from_system()))
	visibility_changed.connect(_on_host_visibility_changed); _suppress_visibility = true; hide(); _suppress_visibility = false
func set_goal(_goal: Dictionary) -> void:
	if _overlay != null and _overlay.visible: _queue_refresh()
func invalidate() -> void: _queue_refresh()
func toggle_menu() -> void:
	if _overlay == null: return
	if _overlay.get_parent() == null: _attach_modal()
	if _overlay.get_parent() == null: return
	if _overlay.visible: _close()
	else: _open()
func _on_host_visibility_changed() -> void:
	if _suppress_visibility or not visible or _overlay == null: return
	toggle_menu(); _suppress_visibility = true; hide(); _suppress_visibility = false

func _build_modal() -> void:
	_overlay = Control.new(); _overlay.name = "TasksMenuOverlay"; _overlay.z_as_relative = false; _overlay.z_index = 190; _overlay.mouse_filter = Control.MOUSE_FILTER_STOP; _overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); _overlay.hide()
	var dim := ColorRect.new(); dim.color = Color(0.05, 0.025, 0.015, 0.58); dim.mouse_filter = Control.MOUSE_FILTER_STOP; _overlay.add_child(dim); dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_window = Control.new(); _window.name = "TasksWindow"; _window.set_anchors_preset(Control.PRESET_CENTER); _window.position = -WINDOW_SIZE * 0.5; _window.size = WINDOW_SIZE; _overlay.add_child(_window)
	var background := Panel.new(); background.mouse_filter = Control.MOUSE_FILTER_STOP; background.add_theme_stylebox_override(&"panel", UiAtlas.warm_hud_style(8, 26, Vector4(24.0, 20.0, 24.0, 22.0))); _window.add_child(background); background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var banner := TextureRect.new(); banner.texture = UiAtlas.HUD_BUYSELL_BANNER; banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; banner.stretch_mode = TextureRect.STRETCH_SCALE; banner.position = Vector2(290.0, -27.0); banner.size = Vector2(320.0, 82.0); _window.add_child(banner)
	var title := Label.new(); title.position = Vector2(320.0, -11.0); title.size = Vector2(260.0, 52.0); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; _window.add_child(title); CommerceUiStyle.curved_title(title, "TASKS", 3.0)
	var close := Button.new(); close.position = Vector2(856.0, -18.0); close.size = Vector2(64.0, 64.0); _window.add_child(close); UiAtlas.configure_close_button(close); close.pressed.connect(_close)
	_build_tabs(); _content = Control.new(); _content.position = Vector2(28.0, 106.0); _content.size = Vector2(844.0, 370.0); _window.add_child(_content)
func _attach_modal() -> void:
	if _overlay == null or _overlay.get_parent() != null: return
	var scene := get_tree().current_scene
	if scene == null: call_deferred("_attach_modal"); return
	scene.add_child(_overlay); _overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func _build_tabs() -> void:
	_main_tab = Button.new(); _main_tab.text = "MAIN"; _main_tab.position = Vector2(255.0, 57.0); _main_tab.size = Vector2(190.0, 48.0); _window.add_child(_main_tab)
	_daily_tab = Button.new(); _daily_tab.text = "DAILY"; _daily_tab.position = Vector2(455.0, 57.0); _daily_tab.size = Vector2(190.0, 48.0); _window.add_child(_daily_tab)
	_main_tab.pressed.connect(_select_tab.bind(&"main")); _daily_tab.pressed.connect(_select_tab.bind(&"daily")); _style_tabs()
func _open() -> void:
	var app := _app()
	if app != null: TaskService.ensure_daily(app.state, int(Time.get_unix_time_from_system()))
	_overlay.show(); _refresh(); call_deferred("_center_current_main")
func _close() -> void:
	if _overlay != null: _overlay.hide()
func _select_tab(tab: StringName) -> void:
	_tab = tab; _style_tabs(); _refresh()
	if tab == &"main": call_deferred("_center_current_main")
func _style_tabs() -> void:
	if _main_tab == null: return
	CommerceUiStyle.shop_category_button(_main_tab, "MAIN", Color("d99727") if _tab == &"main" else Color("a85e20")); CommerceUiStyle.shop_category_button(_daily_tab, "DAILY", Color("d99727") if _tab == &"daily" else Color("a85e20"))
func _queue_refresh() -> void:
	if _refresh_queued: return
	_refresh_queued = true; call_deferred("_deferred_refresh")
func _deferred_refresh() -> void:
	_refresh_queued = false
	if _overlay != null and _overlay.visible: _refresh()
func _refresh() -> void:
	var app := _app()
	if _content == null or app == null or app.state == null: return
	for child in _content.get_children(): _content.remove_child(child); child.queue_free()
	if _tab == &"daily": _build_daily()
	else: _build_main()

func _build_main() -> void:
	var app := _app()
	if app == null: return
	var scroll := HScrollBar.new(); scroll.name = "MainTaskScroll"; scroll.position = Vector2(0.0, 336.0); scroll.size = Vector2(_content.size.x, 24.0); _content.add_child(scroll)
	var viewport := Control.new(); viewport.name = "MainViewport"; viewport.clip_contents = true; viewport.size = Vector2(_content.size.x, 330.0); _content.add_child(viewport)
	var ribbon := HBoxContainer.new(); ribbon.name = "MainRibbon"; ribbon.position = Vector2(18.0, 15.0); ribbon.add_theme_constant_override(&"separation", 0); viewport.add_child(ribbon)
	var tasks := TaskService.main_tasks(app.state, app.registry)
	for index in range(tasks.size()):
		var task: Dictionary = tasks[index]; ribbon.add_child(_task_card(task, false))
		if index < tasks.size() - 1: ribbon.add_child(_connector(task))
	var total_width := float(tasks.size()) * CARD_SIZE.x + float(maxi(0, tasks.size() - 1)) * CONNECTOR_WIDTH + 36.0; scroll.max_value = maxf(0.0, total_width - viewport.size.x); scroll.page = viewport.size.x; scroll.value_changed.connect(func(value: float) -> void: ribbon.position.x = 18.0 - value)
func _build_daily() -> void:
	var app := _app()
	if app == null: return
	var scroll := ScrollContainer.new(); scroll.name = "DailyTaskScroll"; scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO; scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; _content.add_child(scroll)
	var row := HBoxContainer.new(); row.name = "DailyRibbon"; row.add_theme_constant_override(&"separation", 12); row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN; scroll.add_child(row)
	for task in TaskService.daily_tasks(app.state): row.add_child(_task_card(task, true))

func _task_card(task: Dictionary, daily: bool) -> PanelContainer:
	var card := PanelContainer.new(); card.name = "Task_%s" % String(task.id); card.custom_minimum_size = CARD_SIZE; var active := bool(task.unlocked) and not bool(task.claimed); card.add_theme_stylebox_override(&"panel", _card_style(active, bool(task.claimed)))
	var box := VBoxContainer.new(); box.add_theme_constant_override(&"separation", 8); card.add_child(box)
	var title := Label.new(); title.text = String(task.title).to_upper(); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; title.add_theme_font_size_override(&"font_size", 17); title.add_theme_color_override(&"font_color", Color("5b2b12")); box.add_child(title)
	var requirement := Label.new(); requirement.text = String(task.get("hint", task.title)); requirement.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; requirement.size_flags_vertical = Control.SIZE_EXPAND_FILL; requirement.add_theme_font_size_override(&"font_size", 14); requirement.add_theme_color_override(&"font_color", Color("693718")); box.add_child(requirement)
	var progress := Label.new(); progress.text = "%d / %d" % [int(task.progress), int(task.target)]; progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; progress.add_theme_font_size_override(&"font_size", 15); box.add_child(progress)
	var reward := Label.new(); reward.text = "REWARD  +%d %s" % [int(task.reward), String(task.reward_kind).to_upper()]; reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; reward.add_theme_font_size_override(&"font_size", 15); reward.add_theme_color_override(&"font_color", Color("7b4513")); box.add_child(reward)
	var claim := Button.new(); claim.custom_minimum_size = Vector2(0.0, 42.0); box.add_child(claim); _configure_claim(claim, task, daily)
	if not bool(task.unlocked): var lock := ColorRect.new(); lock.color = Color(0.11, 0.07, 0.045, 0.55); lock.mouse_filter = Control.MOUSE_FILTER_IGNORE; card.add_child(lock); lock.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return card
func _configure_claim(button: Button, task: Dictionary, daily: bool) -> void:
	if bool(task.claimed): button.text = "CLAIMED"; button.disabled = true; _style_disabled_claim(button)
	elif not bool(task.unlocked): button.text = "LOCKED"; button.disabled = true; _style_disabled_claim(button)
	elif not bool(task.completed): button.text = "IN PROGRESS"; button.disabled = true; _style_disabled_claim(button)
	else:
		button.text = "CLAIM"; CommerceUiStyle.transaction_action(button, &"claim"); button.pressed.connect(_claim_task.bind(StringName(task.id), daily, int(task.reward), StringName(task.reward_kind)), CONNECT_DEFERRED)
func _claim_task(task_id: StringName, daily: bool, reward_amount: int, reward_kind: StringName) -> void:
	var app := _app()
	if app == null: return
	var result := TaskService.claim_daily(app.state, task_id) if daily else TaskService.claim_main(app.state, app.registry, task_id)
	if result.is_empty(): return
	_show_claim_reward(reward_amount, reward_kind)
	if daily: app.state_changed.emit(); call_deferred("_refresh")
	else: _animate_connector(task_id)
func _show_claim_reward(amount: int, reward_kind: StringName) -> void:
	if _window == null: return
	var popup := HBoxContainer.new(); popup.name = "ClaimReward"; popup.z_index = 30; popup.mouse_filter = Control.MOUSE_FILTER_IGNORE; popup.position = Vector2(WINDOW_SIZE.x * 0.5 - 70.0, WINDOW_SIZE.y * 0.5 - 12.0); popup.size = Vector2(140.0, 48.0); popup.add_theme_constant_override(&"separation", 5); _window.add_child(popup)
	var label := Label.new(); label.text = "+%d" % amount; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; label.add_theme_font_override(&"font", UiAtlas.GAME_FONT); label.add_theme_font_size_override(&"font_size", 28); label.add_theme_color_override(&"font_color", Color.WHITE); label.add_theme_color_override(&"font_outline_color", Color("6a3214")); label.add_theme_constant_override(&"outline_size", 5); popup.add_child(label)
	var icon := TextureRect.new(); icon.custom_minimum_size = Vector2(42.0, 42.0); Hud5Atlas.configure_icon(icon, Hud5Atlas.claim_energy_icon() if reward_kind == &"energy" else Hud5Atlas.coin_icon()); popup.add_child(icon)
	var tween := popup.create_tween().set_parallel(true); tween.tween_property(popup, "position:y", popup.position.y - 75.0, 1.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT); tween.tween_property(popup, "modulate:a", 0.0, 1.15).set_delay(0.25); tween.chain().tween_callback(popup.queue_free)
func _animate_connector(task_id: StringName) -> void:
	var connector := _content.get_node_or_null("MainViewport/MainRibbon/Connector_%s" % String(task_id)) as Control
	if connector == null: _finish_main_claim(); return
	var fill := connector.get_node_or_null("Fill") as Panel
	if fill == null: _finish_main_claim(); return
	fill.size = Vector2(0.0, 5.0); var tween := fill.create_tween(); tween.tween_property(fill, "size", Vector2(CONNECTOR_WIDTH, 5.0), 0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT); tween.tween_callback(_finish_main_claim)
func _finish_main_claim() -> void:
	var app := _app()
	if app != null: app.state_changed.emit()
	_refresh(); call_deferred("_center_current_main")
func _connector(task: Dictionary) -> Control:
	var connector := Control.new(); connector.name = "Connector_%s" % String(task.id); connector.custom_minimum_size = Vector2(CONNECTOR_WIDTH, CARD_SIZE.y)
	var track := Panel.new(); track.position = Vector2(0.0, 139.0); track.size = Vector2(CONNECTOR_WIDTH, 5.0); track.add_theme_stylebox_override(&"panel", _line_style(Color("7d5b36"))); connector.add_child(track)
	var fill := Panel.new(); fill.name = "Fill"; fill.position = Vector2(0.0, 139.0); fill.size = Vector2(CONNECTOR_WIDTH if bool(task.claimed) else 0.0, 5.0); fill.add_theme_stylebox_override(&"panel", _line_style(Color("ffc52c"))); connector.add_child(fill); return connector
func _center_current_main() -> void:
	if _tab != &"main" or _content == null: return
	var app := _app()
	if app == null: return
	var scroll := _content.get_node_or_null("MainTaskScroll") as HScrollBar
	if scroll == null: return
	var tasks := TaskService.main_tasks(app.state, app.registry); var active_index := 0
	for index in range(tasks.size()):
		if bool(tasks[index].unlocked) and not bool(tasks[index].claimed): active_index = index; break
	var center_x := float(active_index) * (CARD_SIZE.x + CONNECTOR_WIDTH) + CARD_SIZE.x * 0.5; scroll.value = clampf(center_x - _content.size.x * 0.5 + 18.0, 0.0, scroll.max_value)
func _card_style(active: bool, claimed: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = Color("d9a968") if claimed else Color("f0c982"); style.border_color = Color("8d5b2b") if claimed else (Color("f6b817") if active else Color("a76525")); style.set_border_width_all(4 if active else 3); style.set_corner_radius_all(18); style.content_margin_left = 13.0; style.content_margin_top = 14.0; style.content_margin_right = 13.0; style.content_margin_bottom = 12.0
	if active: style.shadow_color = Color(1.0, 0.72, 0.12, 0.35); style.shadow_size = 8
	return style
func _style_disabled_claim(button: Button) -> void:
	var style := StyleBoxFlat.new(); style.bg_color = Color("8c8276"); style.border_color = Color("62594f"); style.set_border_width_all(3); style.set_corner_radius_all(18)
	for state in [&"normal", &"hover", &"pressed", &"disabled"]: button.add_theme_stylebox_override(state, style)
	button.add_theme_color_override(&"font_disabled_color", Color("ded8cf"))
func _line_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = color; style.set_corner_radius_all(3); return style
