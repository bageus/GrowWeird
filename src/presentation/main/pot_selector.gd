class_name PotSelector
extends HBoxContainer

signal pot_selected(pot_id: String)

var _last_signature: String = ""

func set_state(state: GameState, planting_target: bool) -> void:
	var signature := _signature(state, planting_target)
	if signature == _last_signature:
		return
	_last_signature = signature
	for child in get_children():
		remove_child(child)
		child.queue_free()
	if state == null:
		return
	for pot in state.pots:
		var button := Button.new()
		var active := state.active_pot_id == pot.pot_id
		var label := "Empty" if pot.is_empty() else String(pot.plant.species_id).replace("_", " ").capitalize()
		button.text = "%s%s · %s" % ["● " if active else "", pot.pot_id, label]
		if planting_target:
			button.disabled = not pot.is_empty()
			button.modulate = Color(0.72, 1.0, 0.72) if pot.is_empty() else Color(1.0, 1.0, 1.0, 0.45)
		button.pressed.connect(_emit_selected.bind(pot.pot_id))
		add_child(button)

func invalidate() -> void:
	_last_signature = ""

func _signature(state: GameState, planting_target: bool) -> String:
	if state == null:
		return "null"
	var parts: Array[String] = [state.active_pot_id, str(planting_target)]
	for pot in state.pots:
		parts.append("%s:%s" % [pot.pot_id, "empty" if pot.is_empty() else pot.plant.instance_id])
	return "|".join(parts)

func _emit_selected(pot_id: String) -> void:
	pot_selected.emit(pot_id)
