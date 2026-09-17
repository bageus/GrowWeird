extends Control

func _ready() -> void:
	call_deferred("_nudge_label")

func _nudge_label() -> void:
	var label := get_node_or_null("Label") as Label
	if label != null:
		label.position.x -= 10.0
