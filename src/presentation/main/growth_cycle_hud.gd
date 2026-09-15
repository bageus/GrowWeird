class_name GrowthCycleHud
extends Control

signal skip_requested

var _panel: Panel
var _stage_icon: TextureRect
var _timer_label: Label
var _skip_button: Button
var _cost_label: Label

func _ready() -> void:
	position = Vector2(position.x, 24.0)
	_build_hud()
	_skip_button.pressed.connect(func() -> void: skip_requested.emit())

func set_cycle(plant: PlantState, _energy: int) -> void:
	visible = plant != null and plant.alive
	if not visible: return
	var duration := GrowthCycleService.duration(plant.growth_cycle_index)
	var boosted := plant.boosted_growth_cycle == plant.growth_cycle_index
	var remaining := maxf(0.0, duration - plant.growth_cycle_elapsed) / (2.0 if boosted else 1.0)
	_stage_icon.texture = Hud5Atlas.stage_icon(plant.growth_cycle_index)
	_timer_label.text = _format(remaining)
	_timer_label.add_theme_color_override(&"font_color", Color("8cff91") if boosted else Color.WHITE)
	var cost := EnergyService.cycle_skip_cost(plant)
	_cost_label.text = "· %d" % cost
	_skip_button.disabled = cost <= 0

func _build_hud() -> void:
	_panel = Panel.new(); _panel.name = "Hud"; _panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); _panel.mouse_filter = Control.MOUSE_FILTER_IGNORE; _panel.add_theme_stylebox_override(&"panel", _hud_style()); add_child(_panel)
	_stage_icon = TextureRect.new(); _stage_icon.name = "StageIcon"; _stage_icon.position = Vector2(18.0, 3.0); _stage_icon.size = Vector2(38.0, 36.0); Hud5Atlas.configure_icon(_stage_icon, Hud5Atlas.restart_icon()); _panel.add_child(_stage_icon)
	_timer_label = Label.new(); _timer_label.name = "TimerLabel"; _timer_label.position = Vector2(60.0, 0.0); _timer_label.size = Vector2(116.0, 42.0); _timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; _timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; _timer_label.add_theme_font_size_override(&"font_size", 18); _timer_label.add_theme_color_override(&"font_outline_color", Color("3b1405")); _timer_label.add_theme_constant_override(&"outline_size", 2); _panel.add_child(_timer_label)
	_skip_button = Button.new(); _skip_button.name = "SkipButton"; _skip_button.position = Vector2(184.0, 3.0); _skip_button.size = Vector2(120.0, 36.0); add_child(_skip_button)
	Hud5Atlas.configure_atlas_button(_skip_button, Hud5Atlas.cycle_finish_icon(), Hud5Atlas.cycle_finish_hover_icon(), Hud5Atlas.cycle_finish_pressed_icon())
	_cost_label = Hud5Atlas.add_cost_overlay(_skip_button)

func _hud_style() -> StyleBoxFlat:
	var style := CommerceUiStyle.top_hud_style(21); style.shadow_size = 0; style.shadow_offset = Vector2.ZERO; return style

func _format(seconds: float) -> String:
	var total := int(ceil(seconds)); return "%02d:%02d" % [floori(float(total) / 60.0), total % 60]
