class_name PlantView
extends Control

signal branch_selected(slot: StringName)

const MODE_NONE: StringName = &""
const MODE_PRUNE: StringName = &"prune"
const MODE_GRAFT: StringName = &"graft"

var _plant: PlantState
var _interaction_mode: StringName = MODE_NONE
var _hovered_slot: StringName = &""
var _layout: Dictionary = {}

func set_plant(plant: PlantState) -> void:
	_plant = plant
	_rebuild()

func set_interaction_mode(mode: StringName) -> void:
	_interaction_mode = mode
	_hovered_slot = &""
	mouse_default_cursor_shape = Control.CURSOR_ARROW if mode == MODE_NONE else Control.CURSOR_POINTING_HAND
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rebuild()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_rebuild()

func _gui_input(event: InputEvent) -> void:
	if _interaction_mode == MODE_NONE:
		return
	if event is InputEventMouseMotion:
		var next_slot := _candidate_at(event.position)
		if next_slot != _hovered_slot:
			_hovered_slot = next_slot
			queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var slot := _candidate_at(event.position)
		if not String(slot).is_empty():
			branch_selected.emit(slot)
			accept_event()

func _rebuild() -> void:
	_layout = PlantVisualAssembler.build(size, _plant)
	queue_redraw()

func _draw() -> void:
	if _plant == null:
		return
	var health := clampf(_plant.health, 0.0, 1.0)
	var wood_color := Color(0.37, 0.22, 0.12).lerp(Color(0.29, 0.18, 0.10), health)
	var leaf_color := Color(0.46, 0.36, 0.23).lerp(Color(0.22, 0.58, 0.24), health)
	var base: Vector2 = _layout.get("base", Vector2.ZERO)
	var root_top: Vector2 = _layout.get("root_top", base)
	draw_line(base, root_top, wood_color, 11.0, true)

	var slots: Dictionary = _layout.get("slots", {})
	for slot_name in BranchState.VALID_SLOTS:
		var descriptor: Dictionary = slots.get(String(slot_name), {})
		_draw_slot(descriptor, wood_color, leaf_color)

func _draw_slot(descriptor: Dictionary, wood_color: Color, leaf_color: Color) -> void:
	if descriptor.is_empty():
		return
	var slot: StringName = descriptor.get("slot", &"")
	var branch := descriptor.get("branch") as BranchState
	var start: Vector2 = descriptor.get("start", Vector2.ZERO)
	var end: Vector2 = descriptor.get("end", Vector2.ZERO)
	var selectable := _is_selectable(branch)
	var highlighted := selectable and slot == _hovered_slot

	if branch == null:
		if _interaction_mode == MODE_GRAFT:
			var ghost_color := Color(0.38, 0.74, 0.42, 0.62 if highlighted else 0.30)
			draw_line(start, end, ghost_color, 8.0 if highlighted else 5.0, true)
			draw_circle(end, 10.0, ghost_color)
		return

	var phenotype: Dictionary = descriptor.get("phenotype", {})
	var glow_strength := float(phenotype.get("glow_strength", 0.0))
	if glow_strength > 0.0:
		draw_line(start, end, Color(0.45, 0.96, 0.68, glow_strength * 0.32), 24.0, true)

	var branch_color := Color(0.88, 0.74, 0.26) if highlighted else wood_color
	draw_line(start, end, branch_color, 10.0 if highlighted else 8.0, true)
	_draw_leaves(start, end, leaf_color, phenotype)
	_draw_thorns(start, end, phenotype)
	_draw_flowers(end, phenotype)

	if branch.grafted:
		var graft_point := start.lerp(end, 0.12)
		draw_circle(graft_point, 7.0, Color(0.68, 0.43, 0.26))
		draw_arc(graft_point, 10.0, 0.0, TAU, 18, Color(0.94, 0.83, 0.61), 2.0, true)

func _draw_leaves(start: Vector2, end: Vector2, color: Color, phenotype: Dictionary) -> void:
	var leaf_scale := float(phenotype.get("leaf_scale", 1.0))
	var vector := end - start
	var length := maxf(vector.length(), 1.0)
	var normal := Vector2(-vector.y, vector.x) / length
	var count := clampi(int(length / 42.0), 2, 6)
	for index in range(count):
		var t := 0.34 + (float(index) / maxf(1.0, float(count - 1))) * 0.60
		var anchor := start.lerp(end, t)
		var side := -1.0 if index % 2 == 0 else 1.0
		var leaf_center := anchor + normal * side * 15.0 * leaf_scale
		var forward := vector.normalized() * 11.0 * leaf_scale
		var across := normal * 7.0 * leaf_scale
		draw_colored_polygon(
			PackedVector2Array([
				leaf_center + forward,
				leaf_center + across,
				leaf_center - forward,
				leaf_center - across,
			]),
			color
		)

func _draw_thorns(start: Vector2, end: Vector2, phenotype: Dictionary) -> void:
	var count := int(phenotype.get("thorn_count", 0))
	if count <= 0:
		return
	var vector := end - start
	var length := maxf(vector.length(), 1.0)
	var normal := Vector2(-vector.y, vector.x) / length
	var scale := float(phenotype.get("thorn_scale", 1.0))
	for index in range(count):
		var t := (float(index) + 1.0) / (float(count) + 1.0)
		var anchor := start.lerp(end, t)
		var side := -1.0 if index % 2 == 0 else 1.0
		draw_line(anchor, anchor + normal * side * 10.0 * scale, Color(0.23, 0.16, 0.11), 2.5, true)

func _draw_flowers(end: Vector2, phenotype: Dictionary) -> void:
	var count := int(phenotype.get("flower_count", 0))
	if count <= 0:
		return
	var scale := float(phenotype.get("flower_scale", 1.0))
	for index in range(count):
		var angle := TAU * float(index) / float(count)
		var center := end + Vector2(cos(angle), sin(angle)) * 18.0 * scale
		draw_circle(center, 7.0 * scale, Color(0.88, 0.39, 0.55))
		draw_circle(center, 2.5 * scale, Color(0.96, 0.79, 0.24))

func _is_selectable(branch: BranchState) -> bool:
	if _interaction_mode == MODE_PRUNE:
		return branch != null
	if _interaction_mode == MODE_GRAFT:
		return branch == null
	return false

func _candidate_at(point: Vector2) -> StringName:
	var slots: Dictionary = _layout.get("slots", {})
	var closest: StringName = &""
	var closest_distance := 28.0
	for slot_name in BranchState.VALID_SLOTS:
		var descriptor: Dictionary = slots.get(String(slot_name), {})
		if descriptor.is_empty():
			continue
		var branch := descriptor.get("branch") as BranchState
		if not _is_selectable(branch):
			continue
		var start: Vector2 = descriptor.get("start", Vector2.ZERO)
		var end: Vector2 = descriptor.get("end", Vector2.ZERO)
		var distance := _distance_to_segment(point, start, end)
		if distance < closest_distance:
			closest_distance = distance
			closest = slot_name
	return closest

func _distance_to_segment(point: Vector2, start: Vector2, end: Vector2) -> float:
	var segment := end - start
	var length_squared := segment.length_squared()
	if length_squared <= 0.001:
		return point.distance_to(start)
	var t := clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(start + segment * t)
