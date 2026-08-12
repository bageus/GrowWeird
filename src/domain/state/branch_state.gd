class_name BranchState
extends RefCounted

const VALID_SLOTS: Array[StringName] = [&"left", &"center", &"right"]

var branch_id: String = ""
var slot: StringName = &"center"
var source_species_id: StringName
var ancestry: Array[String] = []
var traits: Dictionary = {}
var grafted: bool = false
var fruit_growth: GrowingFruitState

func add_trait(trait_id: StringName, amount: int = 1) -> void:
	var key := String(trait_id)
	traits[key] = int(traits.get(key, 0)) + amount

func trait_level(trait_id: StringName) -> int:
	return int(traits.get(String(trait_id), 0))

func is_valid_slot() -> bool:
	return VALID_SLOTS.has(slot)
