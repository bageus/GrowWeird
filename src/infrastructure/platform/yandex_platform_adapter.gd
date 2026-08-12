class_name YandexPlatformAdapter
extends PlatformAdapter

const BRIDGE_NAME := "GrowWeirdYandexBridge"
const BRIDGE_SOURCE := """
(() => {
  if (window.GrowWeirdYandexBridge) return;
  const saveKey = 'growweird_save_v1';
  const bridge = {
    ysdk: null,
    player: null,
    subscribed: false,
    pauseCallback: null,
    resumeCallback: null,
    loadSdk() {
      if (window.YaGames) return Promise.resolve();
      return new Promise((resolve, reject) => {
        const existing = document.querySelector('script[data-growweird-yandex-sdk]');
        if (existing) {
          existing.addEventListener('load', resolve, { once: true });
          existing.addEventListener('error', reject, { once: true });
          return;
        }
        const script = document.createElement('script');
        script.src = '/sdk.js';
        script.async = true;
        script.dataset.growweirdYandexSdk = '1';
        script.onload = resolve;
        script.onerror = reject;
        document.head.appendChild(script);
      });
    },
    async initialize(done, pauseCallback, resumeCallback) {
      try {
        await this.loadSdk();
        this.ysdk = await window.YaGames.init();
        try { this.player = await this.ysdk.getPlayer(); } catch (_error) { this.player = null; }
        this.pauseCallback = pauseCallback;
        this.resumeCallback = resumeCallback;
        if (!this.subscribed && this.ysdk && this.ysdk.on) {
          this.ysdk.on('game_api_pause', () => this.pauseCallback && this.pauseCallback());
          this.ysdk.on('game_api_resume', () => this.resumeCallback && this.resumeCallback());
          this.subscribed = true;
        }
        done(JSON.stringify({ ok: true, cloud: !!this.player }));
      } catch (error) {
        done(JSON.stringify({ ok: false, cloud: false, error: String(error) }));
      }
    },
    serverNow() {
      if (this.ysdk && this.ysdk.serverTime) return Math.floor(this.ysdk.serverTime() / 1000);
      return Math.floor(Date.now() / 1000);
    },
    async loadCloud(done) {
      if (!this.player) { done(''); return; }
      try {
        const data = await this.player.getData([saveKey]);
        done(typeof data[saveKey] === 'string' ? data[saveKey] : '');
      } catch (_error) { done(''); }
    },
    async saveCloud(payload, done) {
      if (!this.player) { done(false); return; }
      try {
        const data = {}; data[saveKey] = payload;
        await this.player.setData(data, true);
        done(true);
      } catch (_error) { done(false); }
    },
    markReady() {
      if (this.ysdk && this.ysdk.features && this.ysdk.features.LoadingAPI) this.ysdk.features.LoadingAPI.ready();
    },
    setGameplay(active) {
      const api = this.ysdk && this.ysdk.features && this.ysdk.features.GameplayAPI;
      if (!api) return;
      if (active) api.start(); else api.stop();
    },
    showFullscreen(done) {
      if (!this.ysdk || !this.ysdk.adv || !this.ysdk.adv.showFullscreenAdv) { done(false); return; }
      this.setGameplay(false);
      this.ysdk.adv.showFullscreenAdv({ callbacks: {
        onClose: (wasShown) => { this.setGameplay(true); done(!!wasShown); },
        onError: () => {}
      }});
    }
  };
  window.GrowWeirdYandexBridge = bridge;
})();
"""

var _bridge: Variant
var _ready: bool = false
var _cloud: bool = false
var _init_callback: Variant
var _pause_callback: Variant
var _resume_callback: Variant
var _cloud_load_callback: Variant
var _cloud_save_callback: Variant
var _ad_callback: Variant

func initialize() -> void:
	if not OS.has_feature("web"):
		initialized.emit(false)
		return
	JavaScriptBridge.eval(BRIDGE_SOURCE, true)
	_bridge = JavaScriptBridge.get_interface(BRIDGE_NAME)
	if _bridge == null:
		initialized.emit(false)
		return
	_init_callback = JavaScriptBridge.create_callback(_on_initialized)
	_pause_callback = JavaScriptBridge.create_callback(_on_pause)
	_resume_callback = JavaScriptBridge.create_callback(_on_resume)
	_bridge.initialize(_init_callback, _pause_callback, _resume_callback)

func platform_id() -> StringName:
	return &"yandex" if _ready else &"local"

func cloud_available() -> bool:
	return _ready and _cloud

func now_unix() -> int:
	if _ready and _bridge != null:
		return int(_bridge.serverNow())
	return super.now_unix()

func load_cloud_save() -> void:
	if not cloud_available():
		cloud_load_completed.emit("")
		return
	_cloud_load_callback = JavaScriptBridge.create_callback(_on_cloud_loaded)
	_bridge.loadCloud(_cloud_load_callback)

func save_cloud(payload: String) -> void:
	if not cloud_available():
		cloud_save_completed.emit(false)
		return
	_cloud_save_callback = JavaScriptBridge.create_callback(_on_cloud_saved)
	_bridge.saveCloud(payload, _cloud_save_callback)

func mark_game_ready() -> void:
	if _ready and _bridge != null:
		_bridge.markReady()

func set_gameplay_active(active: bool) -> void:
	if _ready and _bridge != null:
		_bridge.setGameplay(active)

func show_fullscreen_ad() -> void:
	if not _ready or _bridge == null:
		ad_closed.emit(false)
		return
	_ad_callback = JavaScriptBridge.create_callback(_on_ad_closed)
	_bridge.showFullscreen(_ad_callback)

func _on_initialized(arguments: Array) -> void:
	var payload := String(arguments[0]) if not arguments.is_empty() else ""
	var parsed: Variant = JSON.parse_string(payload)
	_ready = parsed is Dictionary and bool(parsed.get("ok", false))
	_cloud = _ready and bool(parsed.get("cloud", false))
	initialized.emit(_ready)

func _on_pause(_arguments: Array) -> void:
	pause_requested.emit()

func _on_resume(_arguments: Array) -> void:
	resume_requested.emit()

func _on_cloud_loaded(arguments: Array) -> void:
	var payload := String(arguments[0]) if not arguments.is_empty() else ""
	_cloud_load_callback = null
	cloud_load_completed.emit(payload)

func _on_cloud_saved(arguments: Array) -> void:
	var success := bool(arguments[0]) if not arguments.is_empty() else false
	_cloud_save_callback = null
	cloud_save_completed.emit(success)

func _on_ad_closed(arguments: Array) -> void:
	var was_shown := bool(arguments[0]) if not arguments.is_empty() else false
	_ad_callback = null
	ad_closed.emit(was_shown)
