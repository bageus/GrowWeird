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

func set_display(kind: DisplayKind, slots: Array[StringName] = []) -> void:
	display_kind = kind; active_slots = slots.duplicate()
	mouse_filter = Control.MOUSE_FILTER_PASS
	queue_redraw()

func _should_draw_index(index: int) -> bool:
	return enabled or (index < BranchState.VALID_SLOTS.size() and active_slots.has(BranchState.VALID_SLOTS[index]))

func _gui_input(event: InputEvent) -> void:
	if enabled:
		super._gui_input(event); return
	if not event is InputEventMouse: return
	var index := _point_at((event as InputEventMouse).position)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if index >= 0 and _should_draw_index(index) else Control.CURSOR_ARROW
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and index >= 0 and _should_draw_index(index):
		fruit_selected.emit(BranchState.VALID_SLOTS[index]); accept_event()

func _store_stage_points(points: Array) -> void:
	super(points)
	save_layout()

func save_layout() -> bool:
	var payload := JSON.stringify(layouts, "\t")
	var user_file := FileAccess.open(USER_LAYOUT_PATH, FileAccess.WRITE)
	if user_file != null: user_file.store_string(payload)
	var source_file := FileAccess.open(FLOWER_LAYOUT_PATH, FileAccess.WRITE) if OS.has_feature("editor") else null
	if source_file != null: source_file.store_string(payload)
	return user_file != null or source_file != null

func _load_layouts() -> Dictionary:
	var path := FLOWER_LAYOUT_PATH if OS.has_feature("editor") else USER_LAYOUT_PATH
	if not FileAccess.file_exists(path): path = FLOWER_LAYOUT_PATH
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	return parsed if parsed is Dictionary else {}

func _draw_leaf(point_position: Vector2, scale_factor: float, angle: float) -> void:
	# This control is the renderer used by TreeGrowthPreview in the actual main
	# scene. Keep the layout/interaction system, but replace its legacy circles
	# and procedural petals with the new atlas artwork.
	var seed := "%d:%d:%d" % [stage, int(round(point_position.x)), int(round(point_position.y))]
	var texture: Texture2D
	var base_size := FLOWER_SIZE
	if display_kind == DisplayKind.FLOWER:
		texture = PlantAtlasArt.flower_texture(PlantAtlasArt.stable_index(seed + ":flower", 24))
	else:
		var ripe := display_kind == DisplayKind.RIPE_FRUIT
		texture = PlantAtlasArt.fruit_texture(PlantAtlasArt.stable_index(seed + ":fruit", 4), ripe)
		base_size = FRUIT_SIZE
	var art_size := Vector2.ONE * base_size * scale_factor
	draw_set_transform(point_position, angle if display_kind == DisplayKind.FLOWER else 0.0, Vector2.ONE)
	draw_texture_rect(texture, Rect2(-art_size * 0.5, art_size), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
