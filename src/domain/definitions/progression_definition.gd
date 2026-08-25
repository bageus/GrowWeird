class_name ProgressionDefinition
extends Resource

@export var id: StringName
@export var order: int = 0
@export var title: String = ""
@export_multiline var hint: String = ""
@export var event_id: StringName
@export_range(1, 1000, 1) var target_count: int = 1
@export var required_ids: Array[StringName] = []
@export var reward_money: int = 0
