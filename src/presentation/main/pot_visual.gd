class_name PotVisual
extends Control

const LAYOUT_PATH := "user://pot_asset_layout.cfg"
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

@onready var stand: TextureRect = $Stand
@onready var ground: TextureRect = $Ground
@onready var pot: TextureRect = $Pot

var _drag_target: Control
var _drag_offset := Vector2.ZERO

func _ready() -> void:
	for node in _assets():
		node.gui_input.connect(_on_asset_gui_input.bind(node))
	_load_asset_layout()

func set_pot_state(state: PotState) -> void:
	if state == null:
		return
	pot.texture = POT_TEXTURES[_pot_index(state.pot_id)]
	ground.texture = GROUND_TEXTURES[_soil_key(state.soil_moisture)]
	ground.queue_redraw()

func save_asset_layout() -> void:
	var config := ConfigFile.new()
	for node in _assets():
		config.set_value("assets", node.name + "_position", node.position)
		config.set_value("assets", node.name + "_scale", node.scale)
	config.save(LAYOUT_PATH)

func _load_asset_layout() -> void:
	var config := ConfigFile.new()
	if config.load(LAYOUT_PATH) != OK:
		return
	for node in _assets():
		var saved_position: Variant = config.get_value("assets", node.name + "_position", node.position)
		var saved_scale: Variant = config.get_value("assets", node.name + "_scale", node.scale)
		if saved_position is Vector2:
			node.position = saved_position
		if saved_scale is Vector2:
			node.scale = saved_scale

func _assets() -> Array[Control]:
	return [stand, ground, pot]

func _on_asset_gui_input(event: InputEvent, target: Control) -> void:
	if not Input.is_key_pressed(KEY_CTRL):
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_drag_target = target
				_drag_offset = target.get_global_mouse_position() - target.global_position
				target.move_to_front()
			elif _drag_target == target:
				_drag_target = null
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_scale_asset(target, 1.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_scale_asset(target, 0.9)
	elif event is InputEventMouseMotion and _drag_target == target and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		target.global_position = target.get_global_mouse_position() - _drag_offset

func _scale_asset(target: Control, factor: float) -> void:
	var next_scale := target.scale * factor
	next_scale.x = clampf(next_scale.x, 0.2, 4.0)
	next_scale.y = clampf(next_scale.y, 0.2, 4.0)
	target.scale = next_scale

func _pot_index(pot_id: String) -> int:
	var digits := ""
	for character in pot_id:
		if character >= "0" and character <= "9":
			digits += character
	if digits.is_empty():
		return 0
	return posmod(int(digits) - 1, POT_TEXTURES.size())

func _soil_key(moisture: float) -> String:
	return ["very_dry", "dry", "drying", "moist", "wet", "very_wet"][PotState.soil_moisture_stage_for(moisture)]
