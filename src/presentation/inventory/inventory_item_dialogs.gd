class_name InventoryItemDialogs
extends Control

signal use_requested(kind: StringName, item_id: String)
signal sell_requested(kind: StringName, item_id: String, quantity: int)
signal recycle_requested(kind: StringName, item_id: String, quantity: int)
signal closed

@onready var actions: PanelContainer = $ActionMenu
@onready var recycle_action: Button = $ActionMenu/Actions/RecycleAction
@onready var sell_action: Button = $ActionMenu/Actions/SellAction
@onready var use_action: Button = $ActionMenu/Actions/UseAction
@onready var sell_popup: Control = $SellPopup
@onready var sell_title: Label = $SellPopup/SellName
@onready var sell_preview: TextureRect = $SellPopup/SellPreview
@onready var sell_description: Label = $SellPopup/SellDescription
@onready var sell_quantity: Label = $SellPopup/QuantityControl/QuantityLabel
@onready var sell_value: Label = $SellPopup/CountControl/ValueLabel
@onready var sell_minus: Button = $SellPopup/QuantityControl/QuantityMinus
@onready var sell_plus: Button = $SellPopup/QuantityControl/QuantityPlus
@onready var recycle_popup: Control = $RecyclePopup
@onready var recycle_preview: TextureRect = $RecyclePopup/RecyclePreview
@onready var recycle_description: Label = $RecyclePopup/RecycleDescription
@onready var recycle_quantity: Label = $RecyclePopup/QuantityControl/QuantityLabel
@onready var recycle_cost: Label = $RecyclePopup/CountControl/ValueLabel
@onready var recycle_minus: Button = $RecyclePopup/QuantityControl/QuantityMinus
@onready var recycle_plus: Button = $RecyclePopup/QuantityControl/QuantityPlus

var _source: Control
var _kind: StringName = &""
var _item_id := ""
var _title := ""
var _count := 1
var _unit_value := 0
var _sell_amount := 1
var _recycle_yield := 0
var _recycle_amount := 1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	actions.visible = false
	sell_popup.visible = false
	recycle_popup.visible = false
	recycle_action.pressed.connect(_open_recycle)
	sell_action.pressed.connect(_open_sell)
	use_action.pressed.connect(_use)
	$SellPopup/SellClose.pressed.connect(close_all)
	$SellPopup/SellButton.pressed.connect(_confirm_sell)
	sell_minus.pressed.connect(_change_sell_quantity.bind(-1))
	sell_plus.pressed.connect(_change_sell_quantity.bind(1))
	$RecyclePopup/RecycleClose.pressed.connect(close_all)
	$RecyclePopup/RecycleButton.pressed.connect(_confirm_recycle)
	recycle_minus.pressed.connect(_change_recycle_quantity.bind(-1))
	recycle_plus.pressed.connect(_change_recycle_quantity.bind(1))
	UiAtlas.configure_button(use_action, 5, 1)
	UiAtlas.configure_button(sell_action, 3, 3)
	UiAtlas.configure_button(recycle_action, 5, 2)
	_configure_sell_art()
	_configure_recycle_art()
	actions.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())

func _configure_sell_art() -> void:
	TransactionDialogVisual.configure({
		"root": sell_popup, "background": $SellPopup/SellBackground,
		"banner": $SellPopup/SellBanner, "title": sell_title,
		"close": $SellPopup/SellClose, "preview": sell_preview,
		"description": sell_description, "quantity": $SellPopup/QuantityControl,
		"quantity_background": $SellPopup/QuantityControl/QuantityBackground,
		"minus": sell_minus, "quantity_label": sell_quantity, "plus": sell_plus,
		"count": $SellPopup/CountControl,
		"count_background": $SellPopup/CountControl/CountBackground,
		"action": $SellPopup/SellButton,
	}, &"sell", Vector2i(3, 3))

func _configure_recycle_art() -> void:
	TransactionDialogVisual.configure({
		"root": recycle_popup, "background": $RecyclePopup/RecycleBackground,
		"banner": $RecyclePopup/RecycleBanner, "title": $RecyclePopup/RecycleName,
		"close": $RecyclePopup/RecycleClose, "preview": recycle_preview,
		"description": recycle_description, "quantity": $RecyclePopup/QuantityControl,
		"quantity_background": $RecyclePopup/QuantityControl/QuantityBackground,
		"minus": recycle_minus, "quantity_label": recycle_quantity, "plus": recycle_plus,
		"count": $RecyclePopup/CountControl,
		"count_background": $RecyclePopup/CountControl/CountBackground,
		"action": $RecyclePopup/RecycleButton,
	}, &"grind", Vector2i(5, 2))

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
	recycle_action.visible = _recycle_yield > 0
	actions.visible = true
	sell_popup.visible = false
	recycle_popup.visible = false
	_place_left(actions)

func close_all() -> void:
	actions.visible = false
	sell_popup.visible = false
	recycle_popup.visible = false
	closed.emit()

func is_open() -> bool:
	return actions.visible or sell_popup.visible or recycle_popup.visible

func needs_scene_cancel() -> bool:
	return actions.visible or recycle_popup.visible

func cancelable_menu_contains_global_point(point: Vector2) -> bool:
	for panel in [actions, recycle_popup]:
		if panel.visible and panel.get_global_rect().has_point(point):
			return true
	return false

func refresh_position() -> void:
	if actions.visible:
		_place_left(actions)
	if recycle_popup.visible:
		recycle_popup.position = (size - recycle_popup.size) * 0.5

func _open_sell() -> void:
	actions.visible = false
	sell_popup.visible = true
	recycle_popup.visible = false
	sell_preview.texture = InventoryItemArt.texture_for(_kind, _item_id)
	CommerceUiStyle.curved_title(sell_title, "SELL · %s" % String(_kind).to_upper())
	sell_description.text = _item_description(_kind)
	TransactionDialogVisual.fit_description(sell_description)
	_sell_amount = 1
	_refresh_sell_preview()

func _item_description(kind: StringName) -> String:
	match kind:
		&"seed": return "A seed stored in the inventory, ready for planting."
		&"cutting": return "A branch cutting stored in the inventory."
		&"fruit": return "A harvested fruit stored in the inventory."
		&"fertilizer": return "Fertilizer stored in the inventory."
		_: return "An item stored in the inventory."

func _open_recycle() -> void:
	actions.visible = false; sell_popup.visible = false; recycle_popup.visible = true
	recycle_preview.texture = InventoryItemArt.texture_for(_kind, _item_id); _recycle_amount = 1; _refresh_recycle_preview()

func _change_recycle_quantity(delta: int) -> void:
	_recycle_amount = clampi(_recycle_amount + delta, 1, _count); _refresh_recycle_preview()

func _change_sell_quantity(delta: int) -> void:
	_sell_amount = clampi(_sell_amount + delta, 1, _count)
	_refresh_sell_preview()

func _refresh_sell_preview() -> void:
	sell_quantity.text = "%d / %d" % [_sell_amount, _count]
	sell_value.text = str(_unit_value * _sell_amount)
	var can_change_quantity := _count > 1
	sell_minus.visible = can_change_quantity
	sell_plus.visible = can_change_quantity
	sell_minus.disabled = not can_change_quantity or _sell_amount <= 1
	sell_plus.disabled = not can_change_quantity or _sell_amount >= _count

func _refresh_recycle_preview() -> void:
	recycle_quantity.text = "%d / %d" % [_recycle_amount, _count]
	recycle_description.text = "Grind %s.\nOutput: Recycled Fertilizer ×%d" % [_title, _recycle_yield * _recycle_amount]; TransactionDialogVisual.fit_description(recycle_description)
	recycle_cost.text = "%d ENERGY" % (ResourceActions.RECYCLE_ENERGY_COST * _recycle_amount)
	var can_change := _count > 1; recycle_minus.visible = can_change; recycle_plus.visible = can_change; recycle_minus.disabled = not can_change or _recycle_amount <= 1; recycle_plus.disabled = not can_change or _recycle_amount >= _count

func _confirm_sell() -> void:
	sell_requested.emit(_kind, _item_id, _sell_amount)
	close_all()

func _confirm_recycle() -> void:
	recycle_requested.emit(_kind, _item_id, _recycle_amount)
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
