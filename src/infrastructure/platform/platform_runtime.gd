extends Node

signal initialized(platform_id: StringName, cloud_available: bool)
signal cloud_load_completed(payload: String)
signal cloud_save_completed(success: bool)
signal pause_requested
signal resume_requested
signal ad_closed(was_shown: bool)

var _adapter: PlatformAdapter
var _initializing: bool = false
var _initialized: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func initialize() -> void:
	if _initialized:
		initialized.emit(platform_id(), cloud_available())
		return
	if _initializing:
		return
	_initializing = true
	_set_adapter(YandexPlatformAdapter.new() if OS.has_feature("web") else LocalPlatformAdapter.new())
	_adapter.initialize()

func is_initialized() -> bool:
	return _initialized

func platform_id() -> StringName:
	return _adapter.platform_id() if _adapter != null else &"local"

func cloud_available() -> bool:
	return _adapter != null and _adapter.cloud_available()

func now_unix() -> int:
	return _adapter.now_unix() if _adapter != null else int(Time.get_unix_time_from_system())

func load_cloud_save() -> void:
	if _adapter == null:
		cloud_load_completed.emit("")
		return
	_adapter.load_cloud_save()

func save_cloud(payload: String) -> void:
	if _adapter == null:
		cloud_save_completed.emit(false)
		return
	_adapter.save_cloud(payload)

func mark_game_ready() -> void:
	if _adapter != null:
		_adapter.mark_game_ready()

func set_gameplay_active(active: bool) -> void:
	if _adapter != null:
		_adapter.set_gameplay_active(active)

func show_fullscreen_ad() -> void:
	if _adapter == null:
		ad_closed.emit(false)
		return
	_adapter.show_fullscreen_ad()

func _set_adapter(adapter: PlatformAdapter) -> void:
	_adapter = adapter
	_adapter.initialized.connect(_on_adapter_initialized)
	_adapter.cloud_load_completed.connect(func(payload: String) -> void: cloud_load_completed.emit(payload))
	_adapter.cloud_save_completed.connect(func(success: bool) -> void: cloud_save_completed.emit(success))
	_adapter.pause_requested.connect(func() -> void: pause_requested.emit())
	_adapter.resume_requested.connect(func() -> void: resume_requested.emit())
	_adapter.ad_closed.connect(func(was_shown: bool) -> void: ad_closed.emit(was_shown))

func _on_adapter_initialized(success: bool) -> void:
	if not success and _adapter is YandexPlatformAdapter:
		_set_adapter(LocalPlatformAdapter.new())
		_adapter.initialize()
		return
	_initializing = false
	_initialized = true
	initialized.emit(platform_id(), cloud_available())
