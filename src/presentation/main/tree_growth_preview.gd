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
@onready var left_hover: TextureRect = $Tree/LeftHover
@onready var right_hover: TextureRect = $Tree/RightHover
@onready var leaf_layout: LeafLayoutEditor = $Tree/LeafLayout
@onready var flower_layout: FlowerLayoutEditor = $Tree/FlowerLayout

var stage := 0
var _plant: PlantState
var _testing_stage := -1
var _dragging := false
var _drag_offset := Vector2.ZERO
var prune_mode := false
var _hovered_branch: StringName = &""
signal tree_branch_pruned(side: StringName)

func _ready() -> void:
	tree.gui_input.connect(_on_tree_gui_input)
	_load_asset_layout()
	_set_stage(stage)

func set_plant(plant: PlantState) -> void:
	_plant = plant
	if _testing_stage >= 0:
		visible = true
		_set_stage(_testing_stage)
		return
	var next_stage := stage_for(plant)
	visible = plant != null and next_stage >= 0
	if next_stage >= 0:
		_set_stage(next_stage)

static func stage_for(plant: PlantState) -> int:
	if plant == null:
		return -1
	var has_left := plant.branch_at(&"left") != null
	var has_right := plant.branch_at(&"right") != null
	if not has_left and not has_right: return 13
	if not has_left: return 11
	if not has_right: return 12
	var growth_stage := plant.growth_cycle_index
	if growth_stage == 0:
		return -1
	if growth_stage <= 11:
		return growth_stage - 1
	return 7

func _set_stage(value: int) -> void:
	stage = clampi(value, 0, STAGES.size() - 1)
	tree.texture = STAGES[stage]
	leaf_layout.visible = stage >= LeafLayoutEditor.FIRST_TREE_STAGE
	if leaf_layout.visible:
		leaf_layout.set_stage(stage)
	flower_layout.visible = _testing_stage >= 0 or (_plant != null and _plant.growth_cycle_index == 9)
	if flower_layout.visible:
		flower_layout.set_stage(stage)
	_update_hover_visibility()

func preview_stage_for_testing(value: int) -> void:
	_testing_stage = clampi(value, 0, STAGES.size() - 1)
	visible = true
	_set_stage(_testing_stage)

func clear_testing_preview() -> void:
	_testing_stage = -1
	set_plant(_plant)

func has_prunable_branch() -> bool:
	if _testing_stage >= 0:
		return stage in [6, 7, 11, 12]
	return _plant != null and (_plant.branch_at(&"left") != null or _plant.branch_at(&"right") != null)

func set_prune_mode(enabled: bool) -> void:
	prune_mode = enabled
	_hovered_branch = &""
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
	left_hover.visible = prune_mode and _hovered_branch == &"left" and stage in [6, 7, 12]
	right_hover.visible = prune_mode and _hovered_branch == &"right" and stage in [7, 11]
	left_hover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_hover.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _set_hovered_branch(side: StringName) -> void:
	if side != _hovered_branch:
		_hovered_branch = side
		_update_hover_visibility()

func _on_tree_gui_input(event: InputEvent) -> void:
	if prune_mode and event is InputEventMouseMotion:
		_set_hovered_branch(_branch_side_at(tree.get_local_mouse_position()))
		return
	if prune_mode and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var side := _branch_side_at(tree.get_local_mouse_position())
		if side == &"left" and stage in [6, 7, 12]:
			tree_branch_pruned.emit(side); return
		if side == &"right" and stage in [7, 11]:
			tree_branch_pruned.emit(side); return
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
	var normalized := Vector2(
		clampf(point.x / maxf(tree.size.x, 1.0), 0.0, 1.0),
		clampf(point.y / maxf(tree.size.y, 1.0), 0.0, 1.0)
	)
	var left_image := left_hover.texture.get_image() if left_hover.texture != null else null
	var right_image := right_hover.texture.get_image() if right_hover.texture != null else null
	if left_image != null:
		var left_px := Vector2i(int(normalized.x * float(left_image.get_width() - 1)), int(normalized.y * float(left_image.get_height() - 1)))
		if left_image.get_pixelv(left_px).a > 0.08 and stage in [6, 7, 12]:
			return &"left"
	if right_image != null:
		var right_px := Vector2i(int(normalized.x * float(right_image.get_width() - 1)), int(normalized.y * float(right_image.get_height() - 1)))
		if right_image.get_pixelv(right_px).a > 0.08 and stage in [7, 11]:
			return &"right"
	return &""

func _scale_tree(factor: float) -> void:
	var next_scale := tree.scale * factor
	next_scale.x = clampf(next_scale.x, 0.2, 4.0)
	next_scale.y = clampf(next_scale.y, 0.2, 4.0)
	tree.scale = next_scale
