class_name InventoryItemDialogs
extends Control

signal use_requested(kind: StringName, item_id: String)
signal sell_requested(kind: StringName, item_id: String, quantity: int)
signal recycle_requested(kind: StringName, item_id: String, quantity: int)

@onready var actions: PanelContainer = $ActionMenu
@onready var recycle_action: Button = $ActionMenu/Actions/RecycleAction
@onready var sell_action: Button = $ActionMenu/Actions/SellAction
@onready var use_action: Button = $ActionMenu/Actions/UseAction
@onready var sell_popup: PanelContainer = $SellPopup
@onready var sell_title: Label = $SellPopup/Layout/Header/Title
@onready var sell_slider: HSlider = $SellPopup/Layout/QuantitySlider
@onready var sell_quantity: Label = $SellPopup/Layout/QuantityLabel
@onready var sell_value: Label = $SellPopup/Layout/ValueLabel
@onready var recycle_popup: PanelContainer = $RecyclePopup
@onready var recycle_title: Label = $RecyclePopup/Layout/Header/Title
@onready var recycle_slider: HSlider = $RecyclePopup/Layout/QuantitySlider
@onready var recycle_quantity: Label = $RecyclePopup/Layout/QuantityLabel
@onready var recycle_output: Label = $RecyclePopup/Layout/OutputLabel

var _source: Control
var _kind: StringName = &""
var _item_id := ""
var _title := ""
var _count := 1
var _unit_value := 0
var _recycle_yield := 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	actions.visible = false
	sell_popup.visible = false
	recycle_popup.visible = false
	recycle_action.pressed.connect(_open_recycle)
	sell_action.pressed.connect(_open_sell)
	use_action.pressed.connect(_use)
	$SellPopup/Layout/Header/Close.pressed.connect(close_all)
	$SellPopup/Layout/Confirm.pressed.connect(_confirm_sell)
	$RecyclePopup/Layout/Header/Close.pressed.connect(close_all)
	$RecyclePopup/Layout/Confirm.pressed.connect(_confirm_recycle)
	sell_slider.value_changed.connect(_refresh_sell_preview)
	recycle_slider.value_changed.connect(_refresh_recycle_preview)

func show_for(
	source: Control,
	kind: StringName,
	item_id: String,
	count: int,
	title: String,
	unit_value: int,
	recycle_yield: int
) -> void:
	_source = source
	_kind = kind
	_item_id = item_id
	_count = maxi(1, count)
	_title = title
	_unit_value = maxi(0, unit_value)
	_recycle_yield = maxi(0, recycle_yield)
	recycle_action.visible = kind != &"fertilizer" and _recycle_yield > 0
	actions.visible = true
	sell_popup.visible = false
	recycle_popup.visible = false
	_place_left(actions)

func close_all() -> void:
	actions.visible = false
	sell_popup.visible = false
	recycle_popup.visible = false

func refresh_position() -> void:
	if actions.visible:
		_place_left(actions)
	if sell_popup.visible:
		_place_left(sell_popup)
	if recycle_popup.visible:
		_place_left(recycle_popup)

func _open_sell() -> void:
	actions.visible = false
	sell_popup.visible = true
	recycle_popup.visible = false
	sell_title.text = "Sell · %s" % _title
	_setup_slider(sell_slider)
	_refresh_sell_preview(sell_slider.value)
	_place_left(sell_popup)

func _open_recycle() -> void:
	if _kind == &"fertilizer" or _recycle_yield <= 0:
		return
	actions.visible = false
	sell_popup.visible = false
	recycle_popup.visible = true
	recycle_title.text = "Grind · %s" % _title
	_setup_slider(recycle_slider)
	_refresh_recycle_preview(recycle_slider.value)
	_place_left(recycle_popup)

func _setup_slider(slider: HSlider) -> void:
	slider.min_value = 1.0
	slider.max_value = float(_count)
	slider.step = 1.0
	slider.value = 1.0
	slider.editable = _count > 1

func _refresh_sell_preview(value: float) -> void:
	var quantity := maxi(1, int(round(value)))
	sell_quantity.text = "Quantity: %d / %d" % [quantity, _count]
	sell_value.text = "Value: $%d" % (_unit_value * quantity)

func _refresh_recycle_preview(value: float) -> void:
	var quantity := maxi(1, int(round(value)))
	recycle_quantity.text = "Quantity: %d / %d" % [quantity, _count]
	recycle_output.text = "Output: Compost Mix ×%d" % (_recycle_yield * quantity)

func _confirm_sell() -> void:
	var quantity := maxi(1, int(round(sell_slider.value)))
	sell_requested.emit(_kind, _item_id, quantity)
	close_all()

func _confirm_recycle() -> void:
	var quantity := maxi(1, int(round(recycle_slider.value)))
	recycle_requested.emit(_kind, _item_id, quantity)
	close_all()

func _use() -> void:
	use_requested.emit(_kind, _item_id)
	close_all()

func _place_left(panel: Control) -> void:
	if _source == null:
		return
	var gap := 8.0
	var target := _source.position + Vector2(-panel.size.x - gap, 30.0)
	if target.x < 0.0:
		target.x = _source.position.x + _source.size.x + gap
	if target.x + panel.size.x > size.x:
		target.x = maxf(0.0, size.x - panel.size.x)
	if target.y + panel.size.y > size.y:
		target.y = maxf(0.0, size.y - panel.size.y)
	panel.position = Vector2(maxf(0.0, target.x), maxf(0.0, target.y))
