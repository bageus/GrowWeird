class_name PotState
extends RefCounted

enum LightMode {
	DARK,
	DIFFUSED,
	BRIGHT,
	DIRECT,
}

const LIGHT_VALUES: Array[float] = [0.05, 0.4, 0.75, 1.0]
const SOIL_MOISTURE_STAGE_MAX: Array[float] = [0.08, 0.30, 0.48, 0.68, 0.86, 1.0]

var pot_id: String = ""
var soil_moisture: float = 0.30
var light_mode: int = LightMode.DIFFUSED
var window_open: bool = false
var plant: PlantState

func is_empty() -> bool:
	return plant == null

func light_level() -> float:
	return LIGHT_VALUES[clampi(light_mode, 0, LIGHT_VALUES.size() - 1)]

func soil_moisture_stage() -> int:
	return soil_moisture_stage_for(soil_moisture)

static func soil_moisture_stage_for(value: float) -> int:
	var moisture := clampf(value, 0.0, 1.0)
	for index in range(SOIL_MOISTURE_STAGE_MAX.size()):
		if moisture <= SOIL_MOISTURE_STAGE_MAX[index]:
			return index
	return SOIL_MOISTURE_STAGE_MAX.size() - 1

func moisten_soil_one_stage() -> void:
	var next_stage := mini(soil_moisture_stage() + 1, SOIL_MOISTURE_STAGE_MAX.size() - 1)
	soil_moisture = SOIL_MOISTURE_STAGE_MAX[next_stage]
