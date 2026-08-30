class_name TreeGrowthPreview
extends Control

const LAYOUT_PATH := "user://tree_asset_layout.cfg"
const STAGES := [
	preload("res://assets/tree/tree_01.png"),
	preload("res://assets/tree/tree_02.png"),
	preload("res://assets/tree/tree_03.png"),
	preload("res://assets/tree/tree_04.png"),
	preload("res://assets/tree/tree_05.png"),
	preload("res://assets/tree/tree_06.png"),
	preload("res://assets/tree/tree_07.png"),
	preload("res://assets/tree/tree_08.png"),
	preload("res://assets/tree/tree_09.png"),
	preload("res://assets/tree/tree_10.png"),
	preload("res://assets/tree/tree_11.png"),
	preload("res://assets/tree/tree_12.png"),
]
const LEFT_HOVER := preload("res://assets/tree/tree_left.png")
const RIGHT_HOVER := preload("res://assets/tree/tree_right.png")

@onready var tree: TextureRect = $Tree
@onready var left_hover: TextureRect = $LeftHover
@onready var right_hover: TextureRect = $RightHover

var stage := 0
var _dragging := false
var _drag_offset := Vector2.ZERO
var prune_mode := false

func _ready() -> void:
	tree.gui_input.connect(_on_tree_gui_input)
	_load_asset_layout()
	set_stage(stage)

func set_stage(value: int) -> void:
	stage = clampi(value, 0, STAGES.size() - 1)
	tree.texture = STAGES[stage]
	_update_hover_visibility()

func set_prune_mode(enabled: bool) -> void:
	prune_mode = enabled
	_update_hover_visibility()

func save_asset_layout() -> void:
	var config := ConfigFile.new()
	config.set_value("tree", "position", tree.position)
	config.set_value("tree", "scale", tree.scale)
	config.save(LAYOUT_PATH)

func _load_asset_layout() -> void:
	var config := ConfigFile.new()
	if config.load(LAYOUT_PATH) != OK:
		return
	var saved_position: Variant = config.get_value("tree", "position", tree.position)
	var saved_scale: Variant = config.get_value("tree", "scale", tree.scale)
	if saved_position is Vector2:
		tree.position = saved_position
	if saved_scale is Vector2:
		tree.scale = saved_scale

func _update_hover_visibility() -> void:
	left_hover.visible = prune_mode and stage in [6, 7, 10, 11]
	right_hover.visible = prune_mode and stage in [7, 9, 11]

func _on_tree_gui_input(event: InputEvent) -> void:
	if not Input.is_key_pressed(KEY_CTRL):
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging = true
				_drag_offset = get_global_mouse_position() - tree.global_position
				tree.move_to_front()
			else:
				_dragging = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_scale_tree(1.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_scale_tree(0.9)
	elif event is InputEventMouseMotion and _dragging and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		tree.global_position = get_global_mouse_position() - _drag_offset

func _scale_tree(factor: float) -> void:
	var next_scale := tree.scale * factor
	next_scale.x = clampf(next_scale.x, 0.2, 4.0)
	next_scale.y = clampf(next_scale.y, 0.2, 4.0)
	tree.scale = next_scale
