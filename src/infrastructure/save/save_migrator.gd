class_name SaveMigrator
extends RefCounted

const CURRENT_VERSION: int = GameState.SCHEMA_VERSION

static func migrate(source: Dictionary) -> Dictionary:
	var data := source.duplicate(true)
	var version := int(data.get("schema_version", 1))
	if version > CURRENT_VERSION:
		push_error("Save schema %d is newer than supported schema %d" % [version, CURRENT_VERSION])
		return {}

	while version < CURRENT_VERSION:
		match version:
			1:
				data = _migrate_v1_to_v2(data)
			_:
				push_error("No save migration registered for schema %d" % version)
				return {}
		version += 1

	data["schema_version"] = CURRENT_VERSION
	return data

static func _migrate_v1_to_v2(source: Dictionary) -> Dictionary:
	var data := source.duplicate(true)
	data["inventory"] = {
		"fertilizers": {},
		"cuttings": [],
		"seeds": [],
		"fruits": [],
	}
	data["fertilizer_offer"] = {
		"offered_ids": [],
		"seconds_until_offer": 0.0,
		"skip_count": 0,
		"rng_state": 0,
	}
	data["schema_version"] = 2
	return data
