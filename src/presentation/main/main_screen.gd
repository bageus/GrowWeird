extends Control

@onready var status_label: Label = %StatusLabel
@onready var event_label: Label = %EventLabel
@onready var window_button: Button = %WindowButton
@onready var light_button: Button = %LightButton

func _ready() -> void:
	GameApp.state_changed.connect(_refresh)
	GameApp.mutations_resolved.connect(_on_mutations_resolved)
	_refresh()

func _refresh() -> void:
	var pot := GameApp.active_pot()
	var plant := GameApp.active_plant()
	if pot == null:
		status_label.text = "No active pot"
		return
	if plant == null:
		status_label.text = "%s is empty" % pot.pot_id
		return

	var comfort := GameApp.current_comfort()
	status_label.text = (
		"%s\nGrowth: %.1f%%  Health: %.1f%%\nSoil: %.1f%%  Comfort: %.1f%%\nMain issue: %s (%d)\nTraits: %s"
		% [
			plant.custom_name if not plant.custom_name.is_empty() else String(plant.species_id),
			plant.growth_ratio * 100.0,
			plant.health * 100.0,
			pot.soil_moisture * 100.0,
			float(comfort.get("overall", 0.0)) * 100.0,
			String(comfort.get("main_issue", "none")),
			int(comfort.get("direction", 0)),
			_trait_summary(plant),
		]
	)
	window_button.text = "Window: %s" % ("open" if pot.window_open else "closed")
	light_button.text = "Light: %s" % _light_name(int(pot.light_mode))

func _trait_summary(plant: PlantState) -> String:
	var parts: Array[String] = []
	for branch in plant.existing_branches():
		if not branch.traits.is_empty():
			parts.append("%s=%s" % [String(branch.slot), str(branch.traits)])
	return "none" if parts.is_empty() else "; ".join(parts)

func _light_name(mode: int) -> String:
	match mode:
		PotState.LightMode.DARK:
			return "dark"
		PotState.LightMode.DIFFUSED:
			return "diffused"
		PotState.LightMode.BRIGHT:
			return "bright"
		PotState.LightMode.DIRECT:
			return "direct"
	return "unknown"

func _on_water_pressed() -> void:
	GameApp.water_active(false)

func _on_spray_pressed() -> void:
	GameApp.water_active(true)

func _on_window_pressed() -> void:
	var pot := GameApp.active_pot()
	if pot != null:
		GameApp.set_window_open(not pot.window_open)

func _on_light_pressed() -> void:
	var pot := GameApp.active_pot()
	if pot != null:
		GameApp.set_light_mode((int(pot.light_mode) + 1) % PotState.LightMode.size())

func _on_humus_pressed() -> void:
	GameApp.apply_fertilizer(&"humus")

func _on_mouse_pressed() -> void:
	GameApp.apply_fertilizer(&"dead_mouse")

func _on_banana_pressed() -> void:
	GameApp.apply_fertilizer(&"banana_peel")

func _on_radiation_pressed() -> void:
	GameApp.apply_fertilizer(&"radioactive_sample")

func _on_pot_one_pressed() -> void:
	GameApp.switch_pot("pot-1")

func _on_pot_two_pressed() -> void:
	GameApp.switch_pot("pot-2")

func _on_mutations_resolved(events: Array[Dictionary]) -> void:
	if events.is_empty():
		event_label.text = "No mutation resolved"
		return
	var texts: Array[String] = []
	for event in events:
		texts.append("%s → %s Lv.%d" % [event["branch_id"], event["trait_id"], event["level"]])
	event_label.text = "\n".join(texts)
