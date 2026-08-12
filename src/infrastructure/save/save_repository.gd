class_name SaveRepository
extends RefCounted

const SAVE_PATH := "user://growweird_save.json"

static func save(state: GameState) -> bool:
	state.last_saved_unix = int(Time.get_unix_time_from_system())
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Unable to open save file for writing: %s" % FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(SaveMapper.to_dictionary(state)))
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
	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		push_error("Save file is not a valid JSON object")
		return null
	var migrated := SaveMigrator.migrate(parsed)
	if migrated.is_empty():
		return null
	return SaveMapper.from_dictionary(migrated)
