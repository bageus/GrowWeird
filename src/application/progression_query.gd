class_name ProgressionQuery
extends RefCounted

static func current_goal(state: GameState, registry: ContentRegistry) -> Dictionary:
	if state == null:
		return {}
	var definition := ProgressionService.current_goal(
		state.progression,
		registry.all_progression()
	)
	if definition == null:
		return {}
	return {
		"id": definition.id,
		"title": definition.title,
		"hint": definition.hint,
		"progress": state.progression.progress_for(definition.id),
		"target": maxi(1, definition.target_count),
		"reward_money": definition.reward_money,
	}
