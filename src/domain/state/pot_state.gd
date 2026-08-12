class_name PotState
extends RefCounted

enum LightMode {
	DARK,
	DIFFUSED,
	BRIGHT,
	DIRECT,
}

const LIGHT_VALUES: Array[float] = [0.05, 0.4, 0.75, 1.0]

var pot_id: String = ""
var soil_moisture: float = 0.5
var light_mode: int = LightMode.DIFFUSED
var window_open: bool = false
var plant: PlantState

func is_empty() -> bool:
	return plant == null

func light_level() -> float:
	return LIGHT_VALUES[clampi(light_mode, 0, LIGHT_VALUES.size() - 1)]
