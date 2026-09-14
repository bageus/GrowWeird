class_name TaskService
extends RefCounted

const DAILY_TASKS := [
	{"id": "daily_login", "title": "Log in", "event": &"login", "reward_kind": &"coins", "reward": 5},
	{"id": "daily_sell", "title": "Sell an item", "event": &"item_sold", "reward_kind": &"coins", "reward": 3},
	{"id": "daily_shop", "title": "Buy in the shop", "event": &"shop_purchase", "reward_kind": &"coins", "reward": 3},
	{"id": "daily_water", "title": "Water a plant", "event": &"watered", "reward_kind": &"energy", "reward": 3},
	{"id": "daily_feed", "title": "Use fertilizer", "event": &"fertilizer_used", "reward_kind": &"energy", "reward": 3},
	{"id": "daily_buy_coins", "title": "Buy coins", "event": &"coins_bought", "reward_kind": &"coins", "reward": 300},
	{"id": "daily_buy_energy", "title": "Buy energy", "event": &"energy_bought", "reward_kind": &"energy", "reward": 100},
]

static func ensure_daily(state: GameState, unix_time: int) -> void:
	if state == null:
		return
	var day := int(floor(float(maxi(0, unix_time)) / 86400.0))
	var stored_day := int(state.progression.progress_by_id.get("__tasks_daily_day", -1))
	if stored_day != day:
		for key in state.progression.progress_by_id.keys():
			if String(key).begins_with("__daily_"):
				state.progression.progress_by_id.erase(key)
		state.progression.progress_by_id["__tasks_daily_day"] = day
	record_daily_event(state, &"login")

static func record_daily_event(state: GameState, event_id: StringName) -> void:
	if state == null:
		return
	for task in DAILY_TASKS:
		if StringName(task.event) != event_id:
			continue
		state.progression.progress_by_id[_daily_progress_key(String(task.id))] = 1

static func main_tasks(state: GameState, registry: ContentRegistry) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if state == null or registry == null:
		return result
	var definitions := registry.all_progression()
	definitions.sort_custom(func(a: ProgressionDefinition, b: ProgressionDefinition) -> bool: return a.order < b.order)
	for definition in definitions:
		var key := String(definition.id)
		var claimed := _flag(state, "__task_claim_%s" % key)
		var completed := state.progression.is_completed(definition.id)
		result.append({
			"id": key,
			"title": definition.title,
			"hint": definition.hint,
			"progress": definition.target_count if completed else state.progression.progress_for(definition.id),
			"target": maxi(1, definition.target_count),
			"reward_kind": &"coins",
			"reward": definition.reward_money,
			"completed": completed,
			"claimed": claimed,
			"unlocked": _main_unlocked(state, definitions, definition),
		})
	return result

static func daily_tasks(state: GameState) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if state == null:
		return result
	for definition in DAILY_TASKS:
		var task: Dictionary = definition.duplicate(true)
		var key := String(task.id)
		task["progress"] = int(state.progression.progress_by_id.get(_daily_progress_key(key), 0))
		task["target"] = 1
		task["completed"] = int(task.progress) >= 1
		task["claimed"] = _flag(state, _daily_claim_key(key))
		task["unlocked"] = true
		result.append(task)
	return result

static func has_main_claim_block(state: GameState, registry: ContentRegistry) -> bool:
	for task in main_tasks(state, registry):
		if bool(task.completed) and not bool(task.claimed):
			return true
	return false

static func claim_main(state: GameState, registry: ContentRegistry, task_id: StringName) -> Dictionary:
	for task in main_tasks(state, registry):
		if StringName(task.id) != task_id:
			continue
		if not bool(task.unlocked) or not bool(task.completed) or bool(task.claimed):
			return {}
		state.progression.progress_by_id["__task_claim_%s" % String(task_id)] = 1
		_apply_reward(state, StringName(task.reward_kind), int(task.reward))
		return task
	return {}

static func claim_daily(state: GameState, task_id: StringName) -> Dictionary:
	for task in daily_tasks(state):
		if StringName(task.id) != task_id:
			continue
		if not bool(task.completed) or bool(task.claimed):
			return {}
		state.progression.progress_by_id[_daily_claim_key(String(task_id))] = 1
		_apply_reward(state, StringName(task.reward_kind), int(task.reward))
		return task
	return {}

static func _main_unlocked(state: GameState, definitions: Array[ProgressionDefinition], definition: ProgressionDefinition) -> bool:
	for candidate in definitions:
		if candidate.order >= definition.order:
			continue
		if not _flag(state, "__task_claim_%s" % String(candidate.id)):
			return false
	return true

static func _flag(state: GameState, key: String) -> bool:
	return int(state.progression.progress_by_id.get(key, 0)) > 0

static func _daily_progress_key(id: String) -> String:
	return "__daily_progress_%s" % id

static func _daily_claim_key(id: String) -> String:
	return "__daily_claim_%s" % id

static func _apply_reward(state: GameState, kind: StringName, amount: int) -> void:
	if amount <= 0:
		return
	if kind == &"energy":
		EnergyService.credit(state, amount)
	else:
		EconomyService.credit(state, amount)
