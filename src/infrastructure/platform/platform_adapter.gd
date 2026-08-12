class_name PlatformAdapter
extends RefCounted

signal initialized(success: bool)
signal cloud_load_completed(payload: String)
signal cloud_save_completed(success: bool)
signal pause_requested
signal resume_requested
signal ad_closed(was_shown: bool)

func initialize() -> void:
	initialized.emit(true)

func platform_id() -> StringName:
	return &"local"

func cloud_available() -> bool:
	return false

func now_unix() -> int:
	return int(Time.get_unix_time_from_system())

func load_cloud_save() -> void:
	cloud_load_completed.emit("")

func save_cloud(_payload: String) -> void:
	cloud_save_completed.emit(false)

func mark_game_ready() -> void:
	pass

func set_gameplay_active(_active: bool) -> void:
	pass

func show_fullscreen_ad() -> void:
	ad_closed.emit(false)
