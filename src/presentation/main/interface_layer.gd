extends Control

@onready var coins_label: Label = $CoinsLabel
@onready var lighting_options: Control = $LightingOptions

func _ready() -> void:
	coins_label.text = "Баланс · 0"

func set_coins(value: int) -> void:
	coins_label.text = "Баланс · %d" % value

func set_lighting_options_visible(value: bool) -> void:
	lighting_options.visible = value
