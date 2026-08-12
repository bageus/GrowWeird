class_name FertilizerOfferState
extends RefCounted

var offered_ids: Array[StringName] = []
var seconds_until_offer: float = 0.0
var skip_count: int = 0
var rng_state: int = 0

func is_active() -> bool:
	return not offered_ids.is_empty()

func clear() -> void:
	offered_ids.clear()
