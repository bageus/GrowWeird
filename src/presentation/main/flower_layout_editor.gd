class_name FlowerLayoutEditor
extends LeafLayoutEditor

signal fruit_selected(slot: StringName)

enum DisplayKind { FLOWER, UNRIPE_FRUIT, RIPE_FRUIT }
const FLOWER_LAYOUT_PATH := "res://content/visual/tree_flower_layouts.json"
var display_kind: DisplayKind = DisplayKind.FLOWER
var active_slots: Array[StringName] = []

func set_display(kind: DisplayKind, slots: Array[StringName] = []) -> void:
	display_kind = kind; active_slots = slots.duplicate()
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func _should_draw_index(index: int) -> bool:
	return index < BranchState.VALID_SLOTS.size() and active_slots.has(BranchState.VALID_SLOTS[index])

func _gui_input(event: InputEvent) -> void:
	if enabled:
		super._gui_input(event); return
	if not event is InputEventMouse: return
	var index := _point_at((event as InputEventMouse).position)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if index >= 0 and _should_draw_index(index) else Control.CURSOR_ARROW
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and index >= 0 and _should_draw_index(index):
		fruit_selected.emit(BranchState.VALID_SLOTS[index]); accept_event()

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
	if display_kind != DisplayKind.FLOWER:
		var fruit_color := Color("e53935") if display_kind == DisplayKind.RIPE_FRUIT else Color("66c92f")
		var radius := 14.0 * scale_factor
		draw_circle(point_position, radius, fruit_color); draw_arc(point_position, radius, 0.0, TAU, 20, fruit_color.darkened(0.45), 2.0, true)
		draw_circle(point_position + Vector2(-4.0, -5.0) * scale_factor, 3.5 * scale_factor, Color(1.0, 1.0, 1.0, 0.55)); return
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
