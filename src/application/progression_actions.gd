class_name ProgressionActions
extends RefCounted

static func record_event(
	state: GameState,
	event_id: StringName,
	registry: ContentRegistry
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if state == null:
		return result
	TaskService.record_daily_event(state, event_id)
	if TaskService.has_main_claim_block(state, registry):
		return result
	var completed := ProgressionService.record_event(
		state.progression,
		event_id,
		registry.all_progression()
	)
	for definition in completed:
		result.append({
			"id": definition.id,
			"title": definition.title,
			"reward_money": definition.reward_money,
		})
	return result
