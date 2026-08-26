class_name ProgressionPanel
extends PanelContainer

var _signature: String = ""

func set_goal(goal: Dictionary) -> void:
	var signature := str(goal)
	if signature == _signature:
		return
	_signature = signature
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 3)
	add_child(layout)
	var title := Label.new()
	if goal.is_empty():
		title.text = "Experiment freely"
		title.add_theme_font_size_override("font_size", 17)
		layout.add_child(title)
		var done := Label.new()
		done.text = "Core onboarding complete. Grow, mutate, breed and build stranger lineages."
		done.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		done.modulate = Color(1.0, 1.0, 1.0, 0.68)
		layout.add_child(done)
		return
	title.text = "Next: %s" % String(goal.get("title", "Experiment"))
	title.add_theme_font_size_override("font_size", 17)
	layout.add_child(title)
	var hint := Label.new()
	hint.text = String(goal.get("hint", ""))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(1.0, 1.0, 1.0, 0.72)
	layout.add_child(hint)
	var progress := int(goal.get("progress", 0))
	var target := maxi(1, int(goal.get("target", 1)))
	var reward := int(goal.get("reward_money", 0))
	var footer := Label.new()
	footer.text = "%d/%d%s" % [progress, target, " · reward $%d" % reward if reward > 0 else ""]
	footer.modulate = Color(1.0, 1.0, 1.0, 0.56)
	layout.add_child(footer)

func invalidate() -> void:
	_signature = ""
