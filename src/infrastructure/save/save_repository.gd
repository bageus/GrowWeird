class_name SaveRepository
extends RefCounted

const SAVE_PATH := "user://growweird_save.json"

static func save(state: GameState) -> bool:
	if state == null:
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Unable to open save file for writing: %s" % FileAccess.get_open_error())
		return false
	file.store_string(to_json(state))
	file.close()
	return true

static func load_state() -> GameState:
	if not FileAccess.file_exists(SAVE_PATH):
		return null
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Unable to open save file for reading: %s" % FileAccess.get_open_error())
		return null
	var raw := file.get_as_text()
	file.close()
	return from_json(raw)

static func to_json(state: GameState) -> String:
	return JSON.stringify(SaveMapper.to_dictionary(state)) if state != null else ""

static func from_json(raw: String) -> GameState:
	if raw.is_empty():
		return null
	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		push_error("Save payload is not a valid JSON object")
		return null
	var migrated := SaveMigrator.migrate(parsed)
	if migrated.is_empty():
		return null
	return SaveMapper.from_dictionary(migrated)
