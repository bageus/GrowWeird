class_name EnergyTopupPanel
extends Control

signal purchase_requested(product_id: StringName, energy: int, price_rub: int)

const PRODUCTS := [
	{ "id": &"energy_15", "energy": 15, "rub": 59 },
	{ "id": &"energy_30", "energy": 30, "rub": 159 },
]
var _ad_pending := false

func _ready() -> void:
	(%Background as Panel).add_theme_stylebox_override(&"panel", UiAtlas.warm_hud_style(8, 26, Vector4(24.0, 20.0, 24.0, 22.0)))
	%Banner.texture = UiAtlas.HUD_COIN_ENERGY_BANNER
	UiAtlas.configure_topup_card(%Energy5, "5 Energy")
	UiAtlas.configure_topup_card(%Energy15, "15 Energy")
	UiAtlas.configure_topup_card(%Energy30, "30 Energy")
	UiAtlas.configure_close_button(%CloseButton)
	UiAtlas.configure_topup_button(%AdButton, 0, true)
	UiAtlas.configure_topup_button(%Pack15, 59)
	UiAtlas.configure_topup_button(%Pack30, 159)
	%CloseButton.pressed.connect(close)
	%AdButton.pressed.connect(_request_rewarded_ad)
	%Pack15.pressed.connect(_purchase.bind(0))
	%Pack30.pressed.connect(_purchase.bind(1))
	_app().state_changed.connect(refresh)

func open() -> void: visible = true; %StatusLabel.text = ""; refresh()
func close() -> void: visible = false
func refresh() -> void:
	if not is_node_ready() or _app().state == null: return
	%EnergyLabel.text = "Energy %d / %d · next +1: %s" % [_app().state.energy, EnergyService.capacity(_app().state), _timer()]
	%AdButton.disabled = _ad_pending or _app().state.energy >= EnergyService.capacity(_app().state)
	%AdButton.tooltip_text = "Watch ad · +5 energy"

func _purchase(index: int) -> void:
	var product: Dictionary = PRODUCTS[index]
	purchase_requested.emit(product["id"], int(product["energy"]), int(product["rub"]))
	%StatusLabel.text = "Waiting for payment provider confirmation."

func _request_rewarded_ad() -> void:
	if _ad_pending or %AdButton.disabled: return
	_ad_pending = true
	%StatusLabel.text = "Opening advertisement..."
	_platform().ad_closed.connect(_on_ad_closed, CONNECT_ONE_SHOT)
	_app().show_fullscreen_ad()
	refresh()

func _on_ad_closed(was_shown: bool) -> void:
	_ad_pending = false
	if was_shown and _app().buy_energy(5) > 0: %StatusLabel.text = "+5 energy received."
	else: %StatusLabel.text = "Advertisement was not completed."
	refresh()

func _timer() -> String:
	var seconds := EnergyService.seconds_to_next(_app().state)
	return "full" if seconds == 0 else "%02d:%02d" % [floori(float(seconds) / 60.0), seconds % 60]

func _app() -> Node: return get_node("/root/GameApp")
func _platform() -> Node: return get_node("/root/PlatformRuntime")
