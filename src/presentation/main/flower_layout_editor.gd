class_name FlowerLayoutEditor
extends LeafLayoutEditor

signal fruit_selected(slot: StringName)

enum DisplayKind { FLOWER, UNRIPE_FRUIT, RIPE_FRUIT }
const FLOWER_LAYOUT_PATH := "res://content/visual/tree_flower_layouts.json"
const USER_LAYOUT_PATH := "user://tree_flower_layouts.json"
const FLOWER_SIZE := 44.0
const FRUIT_SIZE := 48.0
var display_kind: DisplayKind = DisplayKind.FLOWER
var active_slots: Array[StringName] = []
var plant: PlantState
var _hovered_index := -1

func set_display(kind: DisplayKind, slots: Array[StringName] = [], plant_state: PlantState = null) -> void:
	display_kind = kind; active_slots = slots.duplicate(); plant = plant_state
	if plant != null: plant.ensure_visual_lines()
	mouse_filter = Control.MOUSE_FILTER_PASS; queue_redraw()

func _should_draw_index(index: int) -> bool:
	return enabled or (index < BranchState.VALID_SLOTS.size() and active_slots.has(BranchState.VALID_SLOTS[index]))

func _gui_input(event: InputEvent) -> void:
	if enabled: super._gui_input(event); return
	if not event is InputEventMouse: return
	var index := _point_at((event as InputEventMouse).position)
	if index >= 0 and not _should_draw_index(index): index = -1
	if index != _hovered_index: _hovered_index = index; queue_redraw()
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if index >= 0 else Control.CURSOR_ARROW
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and index >= 0:
		fruit_selected.emit(BranchState.VALID_SLOTS[index]); accept_event()

func _store_stage_points(points: Array) -> void: super(points); save_layout()
func save_layout() -> bool:
	var payload := JSON.stringify(layouts, "\t"); var user_file := FileAccess.open(USER_LAYOUT_PATH, FileAccess.WRITE)
	if user_file != null: user_file.store_string(payload)
	var source_file := FileAccess.open(FLOWER_LAYOUT_PATH, FileAccess.WRITE) if OS.has_feature("editor") else null
	if source_file != null: source_file.store_string(payload)
	return user_file != null or source_file != null
func _load_layouts() -> Dictionary:
	var path := FLOWER_LAYOUT_PATH if OS.has_feature("editor") else USER_LAYOUT_PATH
	if not FileAccess.file_exists(path): path = FLOWER_LAYOUT_PATH
	if not FileAccess.file_exists(path): return {}
	var file := FileAccess.open(path, FileAccess.READ); var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	return parsed if parsed is Dictionary else {}

func _draw_leaf(point_position: Vector2, scale_factor: float, angle: float) -> void:
	var index := _draw_index_for_point(point_position)
	var slot := BranchState.VALID_SLOTS[index] if index >= 0 and index < BranchState.VALID_SLOTS.size() else &"center"
	var branch := plant.branch_at(slot) if plant != null else null
	var hovered := index == _hovered_index and _should_draw_index(index)
	var texture: Texture2D; var base_size := FLOWER_SIZE
	if display_kind == DisplayKind.FLOWER:
		var line := plant.flower_visual_line if plant != null else PlantAtlasArt.flower_line("preview")
		texture = PlantAtlasArt.flower_texture(line, PlantAtlasArt.flower_mutation_column(branch))
	else:
		var line := plant.fruit_visual_line if plant != null else PlantAtlasArt.fruit_line("preview")
		texture = PlantAtlasArt.fruit_texture(line, PlantAtlasArt.fruit_mutation_column(branch), display_kind == DisplayKind.RIPE_FRUIT)
		base_size = FRUIT_SIZE
	var hover_scale := 1.16 if hovered else 1.0
	var art_size := Vector2.ONE * base_size * scale_factor * hover_scale
	draw_set_transform(point_position, angle if display_kind == DisplayKind.FLOWER else 0.0, Vector2.ONE)
	if hovered: draw_circle(Vector2.ZERO, art_size.x * 0.56, Color(1.0, 0.92, 0.55, 0.28))
	draw_texture_rect(texture, Rect2(-art_size * 0.5, art_size), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_index_for_point(point_position: Vector2) -> int:
	var points := _stage_points(); var nearest := -1; var nearest_distance := INF
	for index in range(points.size()):
		var distance := point_position.distance_squared_to(_position_for(points[index]))
		if distance < nearest_distance: nearest_distance = distance; nearest = index
	return nearest
