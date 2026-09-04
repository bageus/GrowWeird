class_name FlowerLayoutEditor
extends LeafLayoutEditor

const FLOWER_LAYOUT_PATH := "res://content/visual/tree_flower_layouts.json"

func save_layout() -> bool:
	var directory := DirAccess.open("res://")
	if directory != null:
		directory.make_dir_recursive("content/visual")
	var file := FileAccess.open(FLOWER_LAYOUT_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(layouts, "\t"))
	return true

func _load_layouts() -> Dictionary:
	if not FileAccess.file_exists(FLOWER_LAYOUT_PATH):
		return {}
	var file := FileAccess.open(FLOWER_LAYOUT_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	return parsed if parsed is Dictionary else {}

func _draw_leaf(point_position: Vector2, scale_factor: float, angle: float) -> void:
	var petal_color := Color("ff75bd")
	var petal_radius := 10.0 * scale_factor
	var petal_distance := 12.0 * scale_factor
	draw_set_transform(point_position, angle, Vector2.ONE)
	for petal in range(5):
		var petal_position := Vector2.from_angle(float(petal) * TAU / 5.0) * petal_distance
		var current_radius := petal_radius * (1.2 if petal == 0 else 1.0)
		draw_circle(petal_position, current_radius, petal_color)
		draw_arc(petal_position, current_radius, 0.0, TAU, 16, Color("a92d73"), 1.5, true)
	draw_circle(Vector2.ZERO, 8.0 * scale_factor, Color("ffd85a"))
	draw_arc(Vector2.ZERO, 8.0 * scale_factor, 0.0, TAU, 16, Color("9b5d20"), 1.5, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
