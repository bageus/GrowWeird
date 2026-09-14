class_name FeedGainFeedback
extends RefCounted

static func show(parent: Control, anchor: Control, gain: float) -> void:
	if parent == null or anchor == null or gain <= 0.0001: return
	var label := Label.new()
	label.text = "+%s" % _format_units(gain); label.size = Vector2(130.0, 56.0); label.pivot_offset = label.size * 0.5
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE; label.z_as_relative = false; label.z_index = 900
	label.add_theme_font_size_override(&"font_size", 30); label.add_theme_color_override(&"font_color", Color("55e85b"))
	label.add_theme_color_override(&"font_outline_color", Color("124719")); label.add_theme_constant_override(&"outline_size", 6)
	parent.add_child(label)
	var center := anchor.get_global_rect().get_center(); var start := center + Vector2(145.0, 150.0); var finish := center + Vector2(145.0, -105.0)
	label.global_position = start - label.size * 0.5
	var tween := parent.create_tween().set_parallel(true)
	tween.tween_property(label, "global_position", finish - label.size * 0.5, 1.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2(1.35, 1.35), 0.2).from(Vector2(0.55, 0.55)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.25).set_delay(0.52)
	tween.chain().tween_callback(label.queue_free)

static func _format_units(gain: float) -> String:
	if is_equal_approx(gain, roundf(gain)):
		return "%d" % roundi(gain)
	return "%.1f" % gain
