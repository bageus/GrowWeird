class_name SaveMigrator
extends RefCounted

const CURRENT_VERSION: int = GameState.SCHEMA_VERSION

static func migrate(source: Dictionary) -> Dictionary:
	var data := source.duplicate(true)
	var version := int(data.get("schema_version", 1))
	if version > CURRENT_VERSION:
		push_error("Save schema %d is newer than supported schema %d" % [version, CURRENT_VERSION])
		return {}

	# Future migrations are applied sequentially here:
	# while version < CURRENT_VERSION:
	#     data = _migrate_vN_to_vN_plus_1(data)
	#     version += 1

	data["schema_version"] = CURRENT_VERSION
	return data
