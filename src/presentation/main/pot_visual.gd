class_name PotVisual
extends Control

const POT_TEXTURES := [
	preload("res://assets/pot/pot_01.png"),
	preload("res://assets/pot/pot_02.png"),
	preload("res://assets/pot/pot_03.png"),
	preload("res://assets/pot/pot_04.png"),
	preload("res://assets/pot/pot_05.png"),
]
const GROUND_TEXTURES := {
	"very_dry": preload("res://assets/pot/pot_ground/ground_06.png"),
	"dry": preload("res://assets/pot/pot_ground/ground_01.png"),
	"drying": preload("res://assets/pot/pot_ground/ground_05.png"),
	"moist": preload("res://assets/pot/pot_ground/ground_04.png"),
	"wet": preload("res://assets/pot/pot_ground/ground_02.png"),
	"very_wet": preload("res://assets/pot/pot_ground/ground_03.png"),
}

@onready var ground: TextureRect = $Ground
@onready var pot: TextureRect = $Pot

func set_pot_state(state: PotState) -> void:
	if state == null:
		return
	pot.texture = POT_TEXTURES[_pot_index(state.pot_id)]
	ground.texture = GROUND_TEXTURES[_soil_key(state.soil_moisture)]

func _pot_index(pot_id: String) -> int:
	var digits := ""
	for character in pot_id:
		if character >= "0" and character <= "9":
			digits += character
	if digits.is_empty():
		return 0
	return posmod(int(digits) - 1, POT_TEXTURES.size())

func _soil_key(moisture: float) -> String:
	var value := clampf(moisture, 0.0, 1.0)
	if value <= 0.08: return "very_dry"
	if value <= 0.30: return "dry"
	if value <= 0.48: return "drying"
	if value <= 0.68: return "moist"
	if value <= 0.86: return "wet"
	return "very_wet"
