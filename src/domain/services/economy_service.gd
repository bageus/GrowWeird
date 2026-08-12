class_name EconomyService
extends RefCounted

static func can_afford(state: GameState, amount: int) -> bool:
	return state != null and amount >= 0 and state.money >= amount

static func spend(state: GameState, amount: int) -> bool:
	if not can_afford(state, amount):
		return false
	state.money -= amount
	return true

static func credit(state: GameState, amount: int) -> void:
	if state != null and amount > 0:
		state.money += amount
