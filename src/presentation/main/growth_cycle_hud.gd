class_name GrowthCycleHud
extends Control

signal skip_requested

var _panel: Panel
var _stage_label: Label
var _timer_label: Label
var _skip_button: Button

func _ready() -> void:
	_build_hud()
	_skip_button.pressed.connect(func() -> void: skip_requested.emit())

func set_cycle(plant: PlantState, energy: int) -> void:
	visible = plant != null and plant.alive
	if not visible:
		return
	var duration := GrowthCycleService.duration(plant.growth_cycle_index)
	var boosted := plant.boosted_growth_cycle == plant.growth_cycle_index
	var remaining := maxf(0.0, duration - plant.growth_cycle_elapsed) / (2.0 if boosted else 1.0)
	_stage_label.text = _stage_name(plant.growth_cycle_index)
	_timer_label.text = _format(remaining)
	_timer_label.add_theme_color_override(&"font_color", Color("8cff91") if boosted else Color.WHITE)
	var cost := EnergyService.cycle_skip_cost(plant)
	_skip_button.text = "FINISH · %d" % cost
	_skip_button.disabled = cost <= 0 or (plant.growth_cycle_index == GrowthCycleService.LAST_CYCLE and not GrowthCycleService.recovery_complete(plant))

func _build_hud() -> void:
	_panel = Panel.new()
	_panel.name = "Hud"
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_theme_stylebox_override(&"panel", _hud_style())
	add_child(_panel)

	_stage_label = Label.new()
	_stage_label.name = "StageLabel"
	_stage_label.position = Vector2(22.0, 0.0)
	_stage_label.size = Vector2(88.0, 42.0)
	_stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stage_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_stage_label.add_theme_font_size_override(&"font_size", 15)
	_stage_label.add_theme_color_override(&"font_color", Color("ffe7a1"))
	_stage_label.add_theme_color_override(&"font_outline_color", Color("3b1405"))
	_stage_label.add_theme_constant_override(&"outline_size", 2)
	_panel.add_child(_stage_label)

	_timer_label = Label.new()
	_timer_label.name = "TimerLabel"
	_timer_label.position = Vector2(110.0, 0.0)
	_timer_label.size = Vector2(74.0, 42.0)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_timer_label.add_theme_font_size_override(&"font_size", 18)
	_timer_label.add_theme_color_override(&"font_outline_color", Color("3b1405"))
	_timer_label.add_theme_constant_override(&"outline_size", 2)
	_panel.add_child(_timer_label)

	_skip_button = Button.new()
	_skip_button.name = "SkipButton"
	_skip_button.position = Vector2(184.0, 1.0)
	_skip_button.size = Vector2(110.0, 38.0)
	_skip_button.focus_mode = Control.FOCUS_NONE
	_skip_button.add_theme_font_size_override(&"font_size", 16)
	_skip_button.add_theme_color_override(&"font_color", Color.WHITE)
	_skip_button.add_theme_color_override(&"font_outline_color", Color("31105c"))
	_skip_button.add_theme_constant_override(&"outline_size", 2)
	_skip_button.add_theme_stylebox_override(&"normal", _button_style(Color("7d25e8")))
	_skip_button.add_theme_stylebox_override(&"hover", _button_style(Color("963cf2")))
	_skip_button.add_theme_stylebox_override(&"pressed", _button_style(Color("6418c2")))
	_skip_button.add_theme_stylebox_override(&"disabled", _button_style(Color("766b7e")))
	_skip_button.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	add_child(_skip_button)

func _hud_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("74320f")
	style.border_color = Color("ffad25")
	style.set_border_width_all(4)
	style.set_corner_radius_all(21)
	style.shadow_color = Color(0.20, 0.06, 0.01, 0.55)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0.0, 3.0)
	style.anti_aliasing_size = 1.5
	return style

func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("451086")
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0.10, 0.02, 0.18, 0.55)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0.0, 2.0)
	style.anti_aliasing_size = 1.5
	return style

func _stage_name(cycle: int) -> String:
	match cycle:
		0: return "SEED"
		1, 2, 3, 4: return "SPROUT"
		5, 6, 7, 8: return "BRANCH"
		9: return "FLOWER"
		10, 11: return "FRUIT"
		_: return "RESTART"

func _format(seconds: float) -> String:
	var total := int(ceil(seconds))
	return "%02d:%02d" % [floori(float(total) / 60.0), total % 60]
