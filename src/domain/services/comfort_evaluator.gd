class_name ComfortEvaluator
extends RefCounted

static func evaluate(pot: PotState, species: PlantSpeciesDefinition) -> Dictionary:
	var gauge := CareGaugeService.evaluate(pot, species)
	var water: Dictionary = gauge["water"]
	var food: Dictionary = gauge["food"]
	var light: Dictionary = gauge["environment"]
	var air := _air_component(pot.window_open, species.open_window_preference)

	var components := {
		"water": water,
		"light": light,
		"food": food,
	}
	var main_issue := "water"
	var lowest_score := 2.0
	for key in components:
		var component: Dictionary = components[key]
		var score := float(component["score"])
		if score < lowest_score:
			lowest_score = score
			main_issue = key

	return {
		"overall": clampf(lowest_score, 0.0, 1.0),
		"main_issue": main_issue,
		"direction": int(components[main_issue]["direction"]),
		"water": float(water["score"]),
		"light": float(light["score"]),
		"food": float(food["score"]),
		"air": float(air["score"]),
	}

static func _range_component(value: float, minimum: float, maximum: float) -> Dictionary:
	if value < minimum:
		var span := maxf(minimum, 0.001)
		return {"score": clampf(1.0 - ((minimum - value) / span), 0.0, 1.0), "direction": -1}
	if value > maximum:
		var span := maxf(1.0 - maximum, 0.001)
		return {"score": clampf(1.0 - ((value - maximum) / span), 0.0, 1.0), "direction": 1}
	return {"score": 1.0, "direction": 0}

static func _air_component(window_open: bool, preference: int) -> Dictionary:
	if preference == 0:
		return {"score": 1.0, "direction": 0}
	var wants_open := preference > 0
	if window_open == wants_open:
		return {"score": 1.0, "direction": 0}
	return {"score": 0.35, "direction": -1 if wants_open else 1}
