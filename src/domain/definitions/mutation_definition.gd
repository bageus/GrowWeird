class_name MutationDefinition
extends Resource

@export var id: StringName
@export var trigger_axis: StringName
@export_range(0.01, 1000.0, 0.01) var threshold: float = 10.0
@export var trait_id: StringName
@export_range(1, 100, 1) var level_increment: int = 1
@export var target_scope: StringName = &"branch"
@export var repeatable: bool = true
