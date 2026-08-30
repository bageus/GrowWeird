class_name PotSelector
extends SceneDraggablePanel

signal pot_selected(pot_id: String)

const POT_TEXTURES := [
	preload("res://assets/pot/pot_01.png"),
	preload("res://assets/pot/pot_02.png"),
	preload("res://assets/pot/pot_03.png"),
	preload("res://assets/pot/pot_04.png"),
	preload("res://assets/pot/pot_05.png"),
]

@onready var previous_button: Button = $Row/PreviousPot
@onready var thumbnail: TextureRect = $Row/PotThumbnail
@onready var next_button: Button = $Row/NextPot

var _state: GameState
var _planting_target := false
var _last_signature := ""

func _ready() -> void:
	super()
	previous_button.pressed.connect(_select_offset.bind(-1))
	next_button.pressed.connect(_select_offset.bind(1))

func set_state(state: GameState, planting_target: bool) -> void:
	_state = state
	_planting_target = planting_target
	var signature := _signature(state, planting_target)
	if signature == _last_signature:
		return
	_last_signature = signature
	_refresh_view()

func invalidate() -> void:
	_last_signature = ""

func _refresh_view() -> void:
	var pots := _selectable_pots()
	var active := _active_pot()
	if active == null and not pots.is_empty():
		active = pots[0]
	var has_pot := active != null
	thumbnail.visible = has_pot
	previous_button.disabled = pots.size() <= 1
	next_button.disabled = pots.size() <= 1
	if not has_pot:
		tooltip_text = "No available pots"
		return
	thumbnail.texture = POT_TEXTURES[_pot_index(active.pot_id)]
	var contents := "Empty" if active.is_empty() else String(active.plant.species_id).replace("_", " ").capitalize()
	tooltip_text = "%s · %s" % [active.pot_id, contents]
	thumbnail.tooltip_text = tooltip_text

func _select_offset(offset: int) -> void:
	var pots := _selectable_pots()
	if pots.size() <= 1:
		return
	var current_index := 0
	for index in range(pots.size()):
		if pots[index].pot_id == _state.active_pot_id:
			current_index = index
			break
	var next: PotState = pots[posmod(current_index + offset, pots.size())]
	pot_selected.emit(next.pot_id)

func _selectable_pots() -> Array[PotState]:
	var result: Array[PotState] = []
	if _state == null:
		return result
	for pot in _state.pots:
		result.append(pot)
	return result

func _active_pot() -> PotState:
	if _state == null:
		return null
	for pot in _state.pots:
		if pot.pot_id == _state.active_pot_id:
			return pot
	return null

func _signature(state: GameState, planting_target: bool) -> String:
	if state == null:
		return "null"
	var parts: Array[String] = [state.active_pot_id, str(planting_target)]
	for pot in state.pots:
		parts.append("%s:%s" % [pot.pot_id, "empty" if pot.is_empty() else pot.plant.instance_id])
	return "|".join(parts)

func _pot_index(pot_id: String) -> int:
	var digits := ""
	for character in pot_id:
		if character >= "0" and character <= "9":
			digits += character
	if digits.is_empty():
		return 0
	return posmod(int(digits) - 1, POT_TEXTURES.size())
