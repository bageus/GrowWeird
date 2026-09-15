extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://src/presentation/progression/progression_panel.gd")
	var ok := true
	ok = _expect(source.contains('call_deferred("_attach_modal")'), "Tasks modal attachment must be deferred from _ready") and ok
	ok = _expect(source.contains("func _attach_modal() -> void:"), "Tasks panel must provide deferred modal attachment") and ok
	ok = _expect(not source.contains("get_tree().current_scene.add_child(_overlay)"), "Tasks modal must not be attached synchronously while scene children are being built") and ok
	quit(0 if ok else 1)

func _expect(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
	return condition
