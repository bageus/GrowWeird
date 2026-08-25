class_name ProgressionState
extends RefCounted

var progress_by_id: Dictionary = {}
var completed_ids: Array[StringName] = []
var skip_onboarding: bool = false

func progress_for(id: StringName) -> int:
	return maxi(0, int(progress_by_id.get(String(id), 0)))

func set_progress(id: StringName, value: int) -> void:
	var key := String(id)
	if value <= 0:
		progress_by_id.erase(key)
	else:
		progress_by_id[key] = value

func is_completed(id: StringName) -> bool:
	return skip_onboarding or completed_ids.has(id)

func complete(id: StringName) -> void:
	if not completed_ids.has(id):
		completed_ids.append(id)
	progress_by_id.erase(String(id))
