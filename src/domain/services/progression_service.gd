class_name ProgressionService
extends RefCounted

static func record_event(
	progression: ProgressionState,
	event_id: StringName,
	definitions: Array[ProgressionDefinition]
) -> Array[ProgressionDefinition]:
	var completed: Array[ProgressionDefinition] = []
	if progression == null or progression.skip_onboarding:
		return completed
	for definition in _ordered(definitions):
		if definition == null or progression.is_completed(definition.id):
			continue
		if not _requirements_met(progression, definition):
			continue
		if definition.event_id != event_id:
			continue
		var next := progression.progress_for(definition.id) + 1
		if next >= maxi(1, definition.target_count):
			progression.complete(definition.id)
			completed.append(definition)
		else:
			progression.set_progress(definition.id, next)
	return completed

static func current_goal(
	progression: ProgressionState,
	definitions: Array[ProgressionDefinition]
) -> ProgressionDefinition:
	if progression == null or progression.skip_onboarding:
		return null
	for definition in _ordered(definitions):
		if definition == null or progression.is_completed(definition.id):
			continue
		if _requirements_met(progression, definition):
			return definition
	return null

static func is_completed(progression: ProgressionState, id: StringName) -> bool:
	return progression != null and (String(id).is_empty() or progression.is_completed(id))

static func _requirements_met(progression: ProgressionState, definition: ProgressionDefinition) -> bool:
	for required_id in definition.required_ids:
		if not progression.is_completed(required_id):
			return false
	return true

static func _ordered(definitions: Array[ProgressionDefinition]) -> Array[ProgressionDefinition]:
	var result := definitions.duplicate()
	result.sort_custom(func(a: ProgressionDefinition, b: ProgressionDefinition) -> bool:
		if a.order == b.order:
			return String(a.id) < String(b.id)
		return a.order < b.order
	)
	return result
