class_name PersistenceCoordinator
extends RefCounted

signal reconciled(state: GameState, offline_result: Dictionary)

var _registry: ContentRegistry
var _rules: GameRules
var _platform: Node
var _candidate: GameState
var _ready: bool = false
var _local_elapsed: float = 0.0
var _cloud_elapsed: float = 0.0
var _cloud_save_in_flight: bool = false

func start(
	candidate: GameState,
	registry: ContentRegistry,
	rules: GameRules,
	platform: Node
) -> void:
	_candidate = candidate
	_registry = registry
	_rules = rules
	_platform = platform
	_platform.initialized.connect(_on_platform_initialized)
	_platform.cloud_load_completed.connect(_on_cloud_loaded)
	_platform.cloud_save_completed.connect(_on_cloud_saved)
	_platform.initialize()

func process(delta: float, state: GameState) -> void:
	if not _ready or state == null or delta <= 0.0:
		return
	_local_elapsed += delta
	_cloud_elapsed += delta
	if _local_elapsed >= _rules.autosave_interval_seconds:
		_local_elapsed = 0.0
		_save_local(state)
	if _cloud_elapsed >= _rules.cloud_save_interval_seconds:
		_cloud_elapsed = 0.0
		_save_cloud(state)

func save_now(state: GameState, include_cloud: bool = true) -> bool:
	if state == null:
		return false
	_stamp(state)
	var saved := SaveRepository.save(state)
	if include_cloud:
		_save_cloud(state, false)
	return saved

func is_ready() -> bool:
	return _ready

func _on_platform_initialized(_platform_id: StringName, cloud_available: bool) -> void:
	if cloud_available:
		_platform.load_cloud_save()
	else:
		_finalize(_candidate)

func _on_cloud_loaded(payload: String) -> void:
	var cloud := SaveRepository.from_json(payload)
	var chosen := _candidate
	if cloud != null and (chosen == null or cloud.last_saved_unix > chosen.last_saved_unix):
		chosen = cloud
	_finalize(chosen)

func _finalize(chosen: GameState) -> void:
	if _ready or chosen == null:
		return
	var now := _platform.now_unix()
	var elapsed := 0.0
	if chosen.last_saved_unix > 0 and now > chosen.last_saved_unix:
		elapsed = float(now - chosen.last_saved_unix)
	var offline_result := OfflineProgressionService.advance(chosen, elapsed, _registry, _rules)
	chosen.last_saved_unix = now
	_ready = true
	SaveRepository.save(chosen)
	_save_cloud(chosen, false)
	_platform.mark_game_ready()
	_platform.set_gameplay_active(true)
	reconciled.emit(chosen, offline_result)

func _save_local(state: GameState) -> void:
	_stamp(state)
	SaveRepository.save(state)

func _save_cloud(state: GameState, stamp_first: bool = true) -> void:
	if not _ready or not _platform.cloud_available() or _cloud_save_in_flight:
		return
	if stamp_first:
		_stamp(state)
	_cloud_save_in_flight = true
	_platform.save_cloud(SaveRepository.to_json(state))

func _stamp(state: GameState) -> void:
	state.last_saved_unix = _platform.now_unix()

func _on_cloud_saved(_success: bool) -> void:
	_cloud_save_in_flight = false
