class_name ItemBalanceCatalog
extends RefCounted

const PATH := "res://content/config/item_balance_v5.json"
static var _cache: Dictionary = {}

static func all() -> Dictionary:
	if not _cache.is_empty():
		return _cache
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		push_error("Item balance file not found: %s" % PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Invalid item balance JSON: %s" % PATH)
		return {}
	for raw in parsed.get("items", []):
		if raw is Dictionary:
			var id := String(raw.get("id", ""))
			if not id.is_empty():
				_cache[id] = raw.duplicate(true)
	return _cache

static func get(id: StringName) -> Dictionary:
	return (all().get(String(id), {}) as Dictionary).duplicate(true)

static func food_gain(id: StringName) -> float:
	var value: Variant = get(id).get("food", 0)
	if value is int or value is float:
		return float(value)
	return 0.0

static func grind_yield(id: StringName) -> int:
	return maxi(0, int(get(id).get("grind_yield", 0)))

static func sell_price(id: StringName) -> int:
	return maxi(0, int(get(id).get("sell_price", 0)))

static func drop_chance(id: StringName) -> float:
	return clampf(float(get(id).get("drop_chance_percent", 0.0)) / 100.0, 0.0, 1.0)
