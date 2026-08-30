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
	preload("res://assets/tree/tree_13.png"),
	preload("res://assets/tree/tree_14.png"),
]

@onready var tree: TextureRect = $Tree
@onready var left_hover: TextureRect = $LeftHover
@onready var right_hover: TextureRect = $RightHover

var stage := 0
var _dragging := false
var _drag_offset := Vector2.ZERO
var prune_mode := false
var persisted_stage := -1
signal tree_branch_pruned(side: StringName)

func _ready() -> void:
	tree.gui_input.connect(_on_tree_gui_input)
	_load_asset_layout()
	set_stage(stage)

func set_stage(value: int) -> void:
	stage = clampi(value, 0, STAGES.size() - 1)
	tree.texture = STAGES[stage]
	_update_hover_visibility()

func prune_left() -> void:
	match stage:
		7: set_stage(10) # tree_08 -> tree_11: right was cut, left remains
		6: set_stage(12) # tree_07 -> tree_13: left cut, right not grown
		10: set_stage(8) # tree_11 -> tree_09: both side branches cut
	persisted_stage = _normalized_stage(stage)

func prune_right() -> void:
	match stage:
		7: set_stage(10) # tree_08 -> tree_11: right cut, left remains
		9: set_stage(8) # tree_10 -> tree_09: both side branches cut
		11: set_stage(12) # tree_12 -> tree_13: right cut
	persisted_stage = _normalized_stage(stage)

func restore_persisted_stage() -> void:
	set_stage(persisted_stage if persisted_stage >= 0 else _normalized_stage(stage))

func _normalized_stage(value: int) -> int:
	match value:
		8: return 5 # tree_09 -> tree_06 after reload
		9: return 6 # tree_10 -> tree_07 after reload
		10: return 6 # tree_11 -> tree_07 after reload
		11: return 5 # tree_12 -> tree_06 after reload
		12: return 5 # tree_13 -> tree_06 after reload
		13: return 5 # tree_14 -> tree_06 after reload
	return value

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
	left_hover.visible = prune_mode and stage in [6, 7, 10]
	right_hover.visible = prune_mode and stage in [7, 9, 11]

func _on_tree_gui_input(event: InputEvent) -> void:
	if prune_mode and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var side := _branch_side_at(tree.get_local_mouse_position())
		if side == &"left" and stage in [6, 7, 10]:
			prune_left(); tree_branch_pruned.emit(side); return
		if side == &"right" and stage in [7, 9, 11]:
			prune_right(); tree_branch_pruned.emit(side); return
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

func _branch_side_at(point: Vector2) -> StringName:
	var width := tree.size.x
	if width <= 0.0:
		return &""
	if point.x < width * 0.45:
		return &"left"
	if point.x > width * 0.55:
		return &"right"
	return &""

func _scale_tree(factor: float) -> void:
	var next_scale := tree.scale * factor
	next_scale.x = clampf(next_scale.x, 0.2, 4.0)
	next_scale.y = clampf(next_scale.y, 0.2, 4.0)
	tree.scale = next_scale
