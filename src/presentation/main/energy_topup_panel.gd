class_name EnergyTopupPanel
extends Control

signal purchase_requested(product_id: StringName, energy: int, price_rub: int)

const PRODUCTS := [[35, 59], [105, 159], [350, 259]]

func _ready() -> void:
	UiAtlas.configure_close_button(%CloseButton)
	%CloseButton.pressed.connect(close)
	%Pack35.pressed.connect(_purchase.bind(0))
	%Pack105.pressed.connect(_purchase.bind(1))
	%Pack350.pressed.connect(_purchase.bind(2))
	GameApp.state_changed.connect(refresh)

func open() -> void: visible = true; refresh()
func close() -> void: visible = false
func refresh() -> void:
	if not is_node_ready() or GameApp.state == null: return
	%EnergyLabel.text = "Energy %d / %d\nNext +1: %s" % [GameApp.state.energy, EnergyService.capacity(GameApp.state), _timer()]

func _purchase(index: int) -> void:
	var product: Array = PRODUCTS[index]
	purchase_requested.emit(StringName("energy_%d" % int(product[0])), int(product[0]), int(product[1]))
	%StatusLabel.text = "Waiting for payment provider confirmation."

func _timer() -> String:
	var seconds := EnergyService.seconds_to_next(GameApp.state)
	return "full" if seconds == 0 else "%02d:%02d" % [floori(float(seconds) / 60.0), seconds % 60]
