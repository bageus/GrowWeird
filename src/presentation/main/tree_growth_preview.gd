class_name TreeGrowthPreview
extends Control

const STAGES := [
	preload("res://assets/tree/tree_01.png"),
	preload("res://assets/tree/tree_02.png"),
	preload("res://assets/tree/tree_03.png"),
	preload("res://assets/tree/tree_04.png"),
]

@onready var tree: TextureRect = $Tree

var stage := 0

func _ready() -> void:
	set_stage(stage)

func set_stage(value: int) -> void:
	stage = clampi(value, 0, STAGES.size() - 1)
	tree.texture = STAGES[stage]
