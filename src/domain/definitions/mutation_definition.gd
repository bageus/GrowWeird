class_name MutationDefinition
extends Resource

@export var id: StringName

# Legacy single-axis fields remain as a compatibility fallback for existing content.
@export var trigger_axis: StringName
@export_range(0.01, 1000.0, 0.01) var threshold: float = 10.0

@export_group("Requirements")
@export var axis_requirements: Dictionary = {}

@export_group("Result")
@export var trait_id: StringName
@export_range(1, 100, 1) var level_increment: int = 1
@export var target_scope: StringName = &"branch"
@export var repeatable: bool = true

func requirements() -> Dictionary:
	if not axis_requirements.is_empty():
		var result := {}
		for axis in axis_requirements:
			result[String(axis)] = maxf(0.01, float(axis_requirements[axis]))
		return result
	if String(trigger_axis).is_empty():
		return {}
	return {String(trigger_axis): threshold}
