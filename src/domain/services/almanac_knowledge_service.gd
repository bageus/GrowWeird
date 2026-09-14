class_name AlmanacKnowledgeService
extends RefCounted

const COMPLETION_REWARD := 3

static func record_use(state: GameState, item_id: String, category: StringName, care: Dictionary, mutations: Dictionary, traits: Array[String], decoration: Dictionary = {}) -> int:
	if state == null: return 0
	var entry := _entry(state, item_id); entry["category"] = String(category); entry["uses"] = int(entry.get("uses", 0)) + 1
	entry["use_known"] = true; entry["care_effects"] = care.duplicate(true); entry["mutation_effects"] = mutations.duplicate(true); entry["decoration_effects"] = decoration.duplicate(true)
	var known_traits: Array[String] = []
	for value in entry.get("discovered_traits", []):
		if not known_traits.has(String(value)): known_traits.append(String(value))
	for value in traits:
		if not known_traits.has(value): known_traits.append(value)
	entry["discovered_traits"] = known_traits
	return _finish(state, item_id, entry)

static func record_recycle(state: GameState, item_id: String, category: StringName, output: int) -> int:
	if state == null or output <= 0: return 0
	var entry := _entry(state, item_id); entry["recycle_known"] = true; entry["recycle_output"] = output
	entry["recycle_category_hint"] = String(category)
	return _finish(state, item_id, entry)

static func _entry(state: GameState, item_id: String) -> Dictionary:
	return (state.fertilizer_knowledge.get(item_id, {}) as Dictionary).duplicate(true)

static func _finish(state: GameState, item_id: String, entry: Dictionary) -> int:
	var fully_known := bool(entry.get("use_known", false)) and bool(entry.get("recycle_known", false))
	entry["fully_known"] = fully_known
	var reward := 0
	if fully_known and not bool(entry.get("reward_claimed", false)):
		entry["reward_claimed"] = true; reward = EnergyService.credit(state, COMPLETION_REWARD)
	state.fertilizer_knowledge[item_id] = entry
	return reward
