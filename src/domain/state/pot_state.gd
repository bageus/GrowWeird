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
const SPRAYS_PER_STAGE := 4

var pot_id: String = ""
var soil_moisture: float = 0.30
var consecutive_sprays: int = 0
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
	consecutive_sprays = 0

func spray_soil(_amount: float) -> bool:
	var displayed_stage := soil_moisture_stage()
	var base_stage := displayed_stage if consecutive_sprays == 0 else maxi(0, displayed_stage - 1)
	var next_stage := mini(base_stage + 1, SOIL_MOISTURE_STAGE_MAX.size() - 1)
	if next_stage == base_stage:
		consecutive_sprays = 0
		return false
	var stage_start := 0.0 if base_stage == 0 else SOIL_MOISTURE_STAGE_MAX[base_stage]
	var stage_end := SOIL_MOISTURE_STAGE_MAX[next_stage]
	consecutive_sprays = mini(consecutive_sprays + 1, SPRAYS_PER_STAGE)
	soil_moisture = lerpf(stage_start, stage_end, float(consecutive_sprays) / float(SPRAYS_PER_STAGE))
	if consecutive_sprays < SPRAYS_PER_STAGE:
		return false
	consecutive_sprays = 0
	return true

func reset_spray_streak() -> void:
	consecutive_sprays = 0
