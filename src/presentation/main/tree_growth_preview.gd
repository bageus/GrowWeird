class_name TreeGrowthPreview
extends Control

const LAYOUT_PATH := "user://tree_asset_layout.cfg"
const STAGES := [
	preload("res://assets/tree/tree_01.png"),
	preload("res://assets/tree/tree_02.png"),
	preload("res://assets/tree/tree_03.png"),
	preload("res://assets/tree/tree_04.png"),
]

@onready var tree: TextureRect = $Tree

var stage := 0
var _dragging := false
var _drag_offset := Vector2.ZERO

func _ready() -> void:
	tree.gui_input.connect(_on_tree_gui_input)
	_load_asset_layout()
	set_stage(stage)

func set_stage(value: int) -> void:
	stage = clampi(value, 0, STAGES.size() - 1)
	tree.texture = STAGES[stage]

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
