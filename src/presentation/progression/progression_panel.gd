class_name ProgressionPanel
extends PanelContainer

const WINDOW_SIZE := Vector2(900.0, 460.0)
const CARD_SIZE := Vector2(210.0, 286.0)
const CONNECTOR_WIDTH := 62.0
const CONTENT_SIZE := Vector2(844.0, 320.0)
const VIEWPORT_HEIGHT := 300.0
const SCROLL_Y := 306.0

var _overlay: Control
var _window: Control
var _content: Control
var _main_tab: Button
var _daily_tab: Button
var _tab: StringName = &"main"
var _suppress_visibility := false
var _refresh_queued := false
var _main_scroll_value := 0.0
var _daily_scroll_value := 0.0
var _main_active_index := 0

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
	_window = Control.new(); _window.name = "TasksWindow"; _window.set_anchors_preset(Control.PRESET_CENTER); _window.position = -WINDOW_SIZE * 0.5 + Vector2(0.0, 40.0); _window.size = WINDOW_SIZE; _overlay.add_child(_window)
	var background := Panel.new(); background.mouse_filter = Control.MOUSE_FILTER_STOP; background.add_theme_stylebox_override(&"panel", UiAtlas.warm_hud_style(8, 26, Vector4(24.0, 20.0, 24.0, 22.0))); _window.add_child(background); background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var banner := TextureRect.new(); banner.texture = UiAtlas.HUD_BUYSELL_BANNER; banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; banner.stretch_mode = TextureRect.STRETCH_SCALE; banner.position = Vector2(290.0, -27.0); banner.size = Vector2(320.0, 82.0); _window.add_child(banner)
	var title := Label.new(); title.position = Vector2(320.0, -11.0); title.size = Vector2(260.0, 52.0); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; _window.add_child(title); CommerceUiStyle.curved_title(title, "TASKS", 3.0)
	var close := Button.new(); close.position = Vector2(856.0, -18.0); close.size = Vector2(64.0, 64.0); _window.add_child(close); UiAtlas.configure_close_button(close); close.pressed.connect(_close)
	_build_tabs(); _content = Control.new(); _content.position = Vector2(28.0, 106.0); _content.size = CONTENT_SIZE; _window.add_child(_content)
func _attach_modal() -> void:
	if _overlay == null or _overlay.get_parent() != null: return
	var scene := get_tree().current_scene
	if scene == null: call_deferred("_attach_modal"); return
	scene.add_child(_overlay); _overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func _build_tabs() -> void:
	_main_tab = Button.new(); _main_tab.text = "PROGRESS"; _main_tab.position = Vector2(255.0, 57.0); _main_tab.size = Vector2(190.0, 48.0); _window.add_child(_main_tab)
	_daily_tab = Button.new(); _daily_tab.text = "DAILY"; _daily_tab.position = Vector2(455.0, 57.0); _daily_tab.size = Vector2(190.0, 48.0); _window.add_child(_daily_tab)
	_main_tab.pressed.connect(_select_tab.bind(&"main")); _daily_tab.pressed.connect(_select_tab.bind(&"daily")); _style_tabs()
func _open() -> void:
	var app := _app()
	if app != null: TaskService.ensure_daily(app.state, int(Time.get_unix_time_from_system()))
	_overlay.show(); _refresh()
	if _tab == &"main" and _main_scroll_value <= 0.0: call_deferred("_center_current_main")
func _close() -> void:
	if _overlay != null: _overlay.hide()
func _select_tab(tab: StringName) -> void:
	_store_scroll(); _tab = tab; _style_tabs(); _refresh()
	if tab == &"main" and _main_scroll_value <= 0.0: call_deferred("_center_current_main")
func _style_tabs() -> void:
	if _main_tab == null: return
	CommerceUiStyle.shop_category_button(_main_tab, "PROGRESS", Color("d99727") if _tab == &"main" else Color("a85e20")); CommerceUiStyle.shop_category_button(_daily_tab, "DAILY", Color("d99727") if _tab == &"daily" else Color("a85e20"))
func _queue_refresh() -> void:
	if _refresh_queued: return
	_refresh_queued = true; call_deferred("_deferred_refresh")
func _deferred_refresh() -> void:
	_refresh_queued = false
	if _overlay != null and _overlay.visible: _refresh()
func _store_scroll() -> void:
	if _content == null: return
	var main := _content.get_node_or_null("MainTaskScroll") as HScrollBar
	if main != null: _main_scroll_value = main.value
	var daily := _content.get_node_or_null("DailyTaskScroll") as HScrollBar
	if daily != null: _daily_scroll_value = daily.value
func _refresh() -> void:
	var app := _app()
	if _content == null or app == null or app.state == null: return
	_store_scroll()
	for child in _content.get_children(): _content.remove_child(child); child.queue_free()
	if _tab == &"daily": _build_daily()
	else: _build_main()
func _build_main() -> void:
	var app := _app()
	if app == null: return
	var scroll := _build_scroll("MainTaskScroll"); var viewport := _build_viewport("MainViewport")
	var ribbon := HBoxContainer.new(); ribbon.name = "MainRibbon"; ribbon.position = Vector2(18.0, 15.0); ribbon.add_theme_constant_override(&"separation", 0); viewport.add_child(ribbon)
	var tasks := TaskService.main_tasks(app.state, app.registry); _main_active_index = 0
	for index in range(tasks.size()):
		var task: Dictionary = tasks[index]
		if bool(task.unlocked) and not bool(task.claimed): _main_active_index = index
		ribbon.add_child(_task_card(task, false))
		if index < tasks.size() - 1: ribbon.add_child(_connector(task))
	var total_width := float(tasks.size()) * CARD_SIZE.x + float(maxi(0, tasks.size() - 1)) * CONNECTOR_WIDTH + 36.0
	_bind_scroll(scroll, ribbon, total_width, _main_scroll_value, true)
func _build_daily() -> void:
	var app := _app()
	if app == null: return
	var scroll := _build_scroll("DailyTaskScroll"); var viewport := _build_viewport("DailyViewport")
	var ribbon := HBoxContainer.new(); ribbon.name = "DailyRibbon"; ribbon.position = Vector2(18.0, 15.0); ribbon.add_theme_constant_override(&"separation", 12); viewport.add_child(ribbon)
	var tasks := TaskService.daily_tasks(app.state)
	for task in tasks: ribbon.add_child(_task_card(task, true))
	var total_width := float(tasks.size()) * CARD_SIZE.x + float(maxi(0, tasks.size() - 1)) * 12.0 + 36.0
	_bind_scroll(scroll, ribbon, total_width, _daily_scroll_value, false)
func _build_scroll(name_value: String) -> HScrollBar:
	var scroll := HScrollBar.new(); scroll.name = name_value; scroll.position = Vector2(0.0, SCROLL_Y); scroll.size = Vector2(_content.size.x, 24.0); _content.add_child(scroll); return scroll
func _build_viewport(name_value: String) -> Control:
	var viewport := Control.new(); viewport.name = name_value; viewport.clip_contents = true; viewport.size = Vector2(_content.size.x, VIEWPORT_HEIGHT); _content.add_child(viewport); return viewport
func _bind_scroll(scroll: HScrollBar, ribbon: Control, total_width: float, saved_value: float, main: bool) -> void:
	scroll.max_value = maxf(_content.size.x, total_width); scroll.page = _content.size.x
	scroll.value_changed.connect(func(value: float) -> void:
		ribbon.position.x = 18.0 - value
		if main: _main_scroll_value = value
		else: _daily_scroll_value = value)
	var last_value := maxf(0.0, scroll.max_value - scroll.page)
	scroll.value = clampf(saved_value, 0.0, last_value); ribbon.position.x = 18.0 - scroll.value
func _task_card(task: Dictionary, daily: bool) -> PanelContainer:
	var card := PanelContainer.new(); card.name = "Task_%s" % String(task.id); card.custom_minimum_size = CARD_SIZE; card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN; card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var active := bool(task.unlocked) and not bool(task.claimed); card.add_theme_stylebox_override(&"panel", _card_style(active, bool(task.claimed)))
	var box := VBoxContainer.new(); box.add_theme_constant_override(&"separation", 8); card.add_child(box)
	var title := Label.new(); title.text = String(task.title).to_upper(); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; title.add_theme_font_size_override(&"font_size", 17); title.add_theme_color_override(&"font_color", Color("5b2b12")); box.add_child(title)
	var requirement := Label.new(); requirement.text = String(task.get("hint", task.title)); requirement.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; requirement.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; requirement.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; requirement.size_flags_vertical = Control.SIZE_EXPAND_FILL; requirement.add_theme_font_size_override(&"font_size", 14); requirement.add_theme_color_override(&"font_color", Color("693718")); box.add_child(requirement)
	var progress := Label.new(); progress.text = "%d / %d" % [int(task.progress), int(task.target)]; progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; progress.add_theme_font_size_override(&"font_size", 15); box.add_child(progress)
	box.add_child(_reward_row(int(task.reward), StringName(task.reward_kind)))
	var claim := Button.new(); claim.custom_minimum_size = Vector2(0.0, 42.0); box.add_child(claim); _configure_claim(claim, task, daily)
	return card
func _reward_row(amount: int, kind: StringName) -> HBoxContainer:
	var row := HBoxContainer.new(); row.alignment = BoxContainer.ALIGNMENT_CENTER; row.add_theme_constant_override(&"separation", 4)
	var label := Label.new(); label.text = "+%d" % amount; label.add_theme_font_size_override(&"font_size", 15); label.add_theme_color_override(&"font_color", Color("7b4513")); row.add_child(label)
	var icon := TextureRect.new(); icon.custom_minimum_size = Vector2(24.0, 24.0); Hud5Atlas.configure_icon(icon, Hud5Atlas.claim_energy_icon() if kind == &"energy" else Hud5Atlas.coin_icon()); row.add_child(icon); return row
func _configure_claim(button: Button, task: Dictionary, daily: bool) -> void:
	if bool(task.claimed): button.text = "CLAIMED"; button.disabled = true; _style_disabled_claim(button)
	elif not bool(task.unlocked): button.text = "LOCKED"; button.disabled = true; _style_disabled_claim(button)
	elif not bool(task.completed): button.text = "IN PROGRESS"; button.disabled = true; _style_disabled_claim(button)
	else: button.text = "CLAIM"; CommerceUiStyle.transaction_action(button, &"claim"); button.pressed.connect(_claim_task.bind(StringName(task.id), daily, int(task.reward), StringName(task.reward_kind), button), CONNECT_DEFERRED)
func _claim_task(task_id: StringName, daily: bool, reward_amount: int, reward_kind: StringName, source_button: Button) -> void:
	var app := _app()
	if app == null: return
	var result := TaskService.claim_daily(app.state, task_id) if daily else TaskService.claim_main(app.state, app.registry, task_id)
	if result.is_empty(): return
	_show_claim_reward(reward_amount, reward_kind, source_button)
	if daily: app.state_changed.emit(); call_deferred("_refresh")
	else: _animate_connector(task_id)
func _show_claim_reward(amount: int, reward_kind: StringName, source_button: Control) -> void:
	if _window == null or source_button == null: return
	var popup := HBoxContainer.new(); popup.name = "ClaimReward"; popup.z_index = 30; popup.mouse_filter = Control.MOUSE_FILTER_IGNORE; popup.size = Vector2(140.0, 48.0); popup.add_theme_constant_override(&"separation", 5)
	var center := source_button.get_global_rect().get_center() - _window.global_position; popup.position = Vector2(center.x - 70.0, center.y - 24.0); _window.add_child(popup)
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
	_refresh()
func _connector(task: Dictionary) -> Control:
	var connector := Control.new(); connector.name = "Connector_%s" % String(task.id); connector.custom_minimum_size = Vector2(CONNECTOR_WIDTH, CARD_SIZE.y)
	var track := Panel.new(); track.position = Vector2(0.0, 139.0); track.size = Vector2(CONNECTOR_WIDTH, 5.0); track.add_theme_stylebox_override(&"panel", _line_style(Color("7d5b36"))); connector.add_child(track)
	var fill := Panel.new(); fill.name = "Fill"; fill.position = Vector2(0.0, 139.0); fill.size = Vector2(CONNECTOR_WIDTH if bool(task.claimed) else 0.0, 5.0); fill.add_theme_stylebox_override(&"panel", _line_style(Color("ffc52c"))); connector.add_child(fill); return connector
func _center_current_main() -> void:
	if _tab != &"main" or _content == null or _main_scroll_value > 0.0: return
	var scroll := _content.get_node_or_null("MainTaskScroll") as HScrollBar
	if scroll == null: return
	var center_x := float(_main_active_index) * (CARD_SIZE.x + CONNECTOR_WIDTH) + CARD_SIZE.x * 0.5; scroll.value = clampf(center_x - _content.size.x * 0.5 + 18.0, 0.0, maxf(0.0, scroll.max_value - scroll.page))
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
