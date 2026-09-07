class_name GrowthCycleHud
extends Control

signal skip_requested

func _ready() -> void: %SkipButton.pressed.connect(func() -> void: skip_requested.emit())

func set_cycle(plant: PlantState, energy: int) -> void:
	visible = plant != null and plant.alive
	if not visible: return
	var duration := GrowthCycleService.duration(plant.growth_cycle_index)
	var boosted := plant.boosted_growth_cycle == plant.growth_cycle_index
	%Progress.value = GrowthCycleService.progress(plant) * 100.0
	queue_redraw()
	%TimerLabel.text = _format(maxf(0.0, duration - plant.growth_cycle_elapsed) / (2.0 if boosted else 1.0))
	%TimerLabel.add_theme_color_override(&"font_color", Color("58e86a") if boosted else Color("4ca8ff"))
	var cost := EnergyService.cycle_skip_cost(plant)
	%SkipButton.text = "Finish · %d⚡" % cost
	%SkipButton.disabled = cost <= 0 or energy < cost or (plant.growth_cycle_index == GrowthCycleService.LAST_CYCLE and not GrowthCycleService.recovery_complete(plant))

func _format(seconds: float) -> String:
	var total := int(ceil(seconds)); return "%02d:%02d" % [floori(float(total) / 60.0), total % 60]

func _draw() -> void:
	var ratio := float(%Progress.value) / 100.0
	var x := lerpf(8.0, size.x - 8.0, ratio)
	draw_colored_polygon(PackedVector2Array([Vector2(x - 7.0, 0.0), Vector2(x + 7.0, 0.0), Vector2(x, 12.0)]), Color("ffd45c"))
