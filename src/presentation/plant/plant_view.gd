class_name PlantView
extends Control

signal branch_selected(slot: StringName)

const MODE_NONE: StringName = &""
const MODE_PRUNE: StringName = &"prune"
const MODE_GRAFT: StringName = &"graft"
const MODE_HARVEST: StringName = &"harvest"
const REVEAL_SECONDS := 1.15

var _plant: PlantState
var _species_style: PlantSpeciesDefinition
var _interaction_mode: StringName = MODE_NONE
var _hovered_slot: StringName = &""
var _layout: Dictionary = {}
var _trait_snapshot: Dictionary = {}
var _reveal_slots: Dictionary = {}

func set_plant(plant: PlantState) -> void:
	var same_specimen := _plant != null and plant != null and _plant.instance_id == plant.instance_id
	if same_specimen:
		_detect_trait_increases(plant)
	else:
		_reveal_slots.clear()
		set_process(false)
	_plant = plant
	_trait_snapshot = _snapshot_traits(plant)
	_rebuild()

func set_species_style(definition: PlantSpeciesDefinition) -> void:
	_species_style = definition
	_rebuild()

func set_interaction_mode(mode: StringName) -> void:
	_interaction_mode = mode
	_hovered_slot = &""
	mouse_default_cursor_shape = Control.CURSOR_ARROW if mode == MODE_NONE else Control.CURSOR_POINTING_HAND
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(false)
	_rebuild()

func _process(delta: float) -> void:
	var expired: Array[String] = []
	for key in _reveal_slots:
		var remaining := maxf(0.0, float(_reveal_slots[key]) - delta)
		_reveal_slots[key] = remaining
		if remaining <= 0.0:
			expired.append(String(key))
	for key in expired:
		_reveal_slots.erase(key)
	if _reveal_slots.is_empty():
		set_process(false)
	queue_redraw()

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
	_layout = PlantVisualAssembler.build(size, _plant, _species_style)
	queue_redraw()

func _draw() -> void:
	if _plant == null:
		return
	var vitality := PlantLifecycleService.vitality(_plant)
	var target_wood := _species_style.wood_color if _species_style != null else Color(0.29, 0.18, 0.10)
	var target_leaf := _species_style.leaf_color if _species_style != null else Color(0.22, 0.58, 0.24)
	var dry_wood := Color(0.28, 0.24, 0.19) if _plant.alive else Color(0.20, 0.19, 0.17)
	var dry_leaf := Color(0.48, 0.36, 0.21) if _plant.alive else Color(0.25, 0.23, 0.18)
	var wood_color := dry_wood.lerp(target_wood, vitality)
	var leaf_color := dry_leaf.lerp(target_leaf, vitality)
	var base: Vector2 = _layout.get("base", Vector2.ZERO)
	var root_top: Vector2 = _layout.get("root_top", base)
	draw_line(base, root_top, wood_color, 11.0, true)
	var slots: Dictionary = _layout.get("slots", {})
	for slot_name in BranchState.VALID_SLOTS:
		_draw_slot(slots.get(String(slot_name), {}), wood_color, leaf_color, vitality)

func _draw_slot(descriptor: Dictionary, wood_color: Color, leaf_color: Color, vitality: float) -> void:
	if descriptor.is_empty():
		return
	var slot: StringName = descriptor.get("slot", &"")
	var branch := descriptor.get("branch") as BranchState
	var start: Vector2 = descriptor.get("start", Vector2.ZERO)
	var end: Vector2 = descriptor.get("end", Vector2.ZERO)
	var highlighted := _is_selectable(branch) and slot == _hovered_slot
	if branch == null:
		_draw_regrowth(start, end, float(descriptor.get("regrowth", 0.0)))
		if _interaction_mode == MODE_GRAFT:
			var ghost_color := Color(0.38, 0.74, 0.42, 0.62 if highlighted else 0.30)
			draw_line(start, end, ghost_color, 8.0 if highlighted else 5.0, true)
			draw_circle(end, 10.0, ghost_color)
		return
	var phenotype: Dictionary = descriptor.get("phenotype", {})
	var glow_strength := float(phenotype.get("glow_strength", 0.0)) * vitality
	if glow_strength > 0.0:
		draw_line(start, end, Color(0.45, 0.96, 0.68, glow_strength * 0.32), 24.0, true)
	var branch_color := Color(0.88, 0.74, 0.26) if highlighted else wood_color
	var width := (10.0 if highlighted else 8.0) + float(phenotype.get("branch_width_bonus", 0.0))
	draw_line(start, end, branch_color, width, true)
	_draw_bark(start, end, phenotype)
	_draw_leaves(start, end, leaf_color, phenotype, vitality)
	_draw_thorns(start, end, phenotype)
	BranchMutationRenderer.draw_hooks(self, start, end, phenotype)
	_draw_crystal_thorns(start, end, phenotype)
	BranchMutationRenderer.draw_mineral_nodes(self, start, end, phenotype)
	_draw_fungi(start, end, phenotype, vitality)
	_draw_spore_traps(start, end, phenotype)
	BranchMutationRenderer.draw_toxic_sacs(self, start, end, phenotype, vitality)
	_draw_flowers(end, phenotype, vitality)
	_draw_fruit(branch, end, highlighted, vitality)
	if branch.grafted:
		var graft_point := start.lerp(end, 0.12)
		draw_circle(graft_point, 7.0, Color(0.68, 0.43, 0.26))
		draw_arc(graft_point, 10.0, 0.0, TAU, 18, Color(0.94, 0.83, 0.61), 2.0, true)
	var reveal := float(_reveal_slots.get(String(slot), 0.0)) / REVEAL_SECONDS
	BranchMutationRenderer.draw_reveal(self, start, end, reveal)

func _draw_regrowth(start: Vector2, end: Vector2, progress: float) -> void:
	if progress <= 0.0 or _plant == null or not _plant.alive:
		return
	var t := lerpf(0.04, 0.30, clampf(progress, 0.0, 1.0))
	var bud_end := start.lerp(end, t)
	var color := (_species_style.leaf_color if _species_style != null else Color(0.22, 0.58, 0.24)).lerp(Color(0.72, 0.84, 0.34), 0.35)
	draw_line(start, bud_end, color.darkened(0.28), 4.0, true)
	draw_circle(bud_end, lerpf(3.0, 7.0, progress), color)

func _draw_bark(start: Vector2, end: Vector2, phenotype: Dictionary) -> void:
	var count := int(phenotype.get("bark_ring_count", 0))
	for index in range(count):
		var t := (float(index) + 1.0) / (float(count) + 1.0)
		var center := start.lerp(end, t)
		draw_arc(center, 6.0, -0.8, 0.8, 8, Color(0.18, 0.11, 0.07, 0.85), 2.0, true)

func _draw_fruit(branch: BranchState, end: Vector2, highlighted: bool, vitality: float) -> void:
	if branch.fruit_growth == null:
		return
	var progress := clampf(branch.fruit_growth.progress, 0.0, 1.0)
	var center := end + Vector2(0.0, 18.0)
	if progress < 0.18:
		draw_circle(center, 4.0, Color(0.96, 0.72, 0.82).lerp(Color(0.30, 0.25, 0.20), 1.0 - vitality))
		return
	var radius := lerpf(5.0, 14.0, progress)
	var ripe_color := _species_style.fruit_color if _species_style != null else Color(0.91, 0.42, 0.18)
	var fruit_color := Color(0.35, 0.68, 0.25).lerp(ripe_color, progress)
	if branch.fruit_growth.hybrid:
		fruit_color = fruit_color.lerp(Color(0.64, 0.28, 0.72), 0.42)
	fruit_color = Color(0.29, 0.25, 0.19).lerp(fruit_color, vitality)
	draw_circle(center, radius, fruit_color)
	draw_line(center + Vector2(0.0, -radius), center + Vector2(0.0, -radius - 7.0), Color(0.22, 0.43, 0.16).lerp(Color(0.28, 0.25, 0.19), 1.0 - vitality), 2.0, true)
	if branch.fruit_growth.is_ready() and _plant.alive:
		draw_arc(center, radius + 4.0, 0.0, TAU, 24, Color(1.0, 0.82, 0.28, 1.0 if highlighted else 0.6), 3.0, true)

func _draw_leaves(start: Vector2, end: Vector2, color: Color, phenotype: Dictionary, vitality: float) -> void:
	var species_scale := _species_style.leaf_scale if _species_style != null else 1.0
	var leaf_scale := float(phenotype.get("leaf_scale", 1.0)) * species_scale * lerpf(0.58, 1.0, vitality)
	var vector := end - start
	var length := maxf(vector.length(), 1.0)
	var normal := Vector2(-vector.y, vector.x) / length
	var base_count := clampi(int(length / 42.0), 0, 6)
	var count := clampi(int(round(float(base_count) * lerpf(0.18, 1.0, vitality))), 0, 6)
	if count <= 0:
		return
	for index in range(count):
		var t := 0.55 if count == 1 else 0.34 + (float(index) / float(count - 1)) * 0.60
		var anchor := start.lerp(end, t)
		var side := -1.0 if index % 2 == 0 else 1.0
		var leaf_center := anchor + normal * side * 15.0 * leaf_scale
		var forward := vector.normalized() * 11.0 * leaf_scale
		var across := normal * 7.0 * leaf_scale
		draw_colored_polygon(PackedVector2Array([leaf_center + forward, leaf_center + across, leaf_center - forward, leaf_center - across]), color)

func _draw_thorns(start: Vector2, end: Vector2, phenotype: Dictionary) -> void:
	var count := int(phenotype.get("thorn_count", 0))
	if count <= 0:
		return
	var vector := end - start
	var normal := Vector2(-vector.y, vector.x) / maxf(vector.length(), 1.0)
	var scale := float(phenotype.get("thorn_scale", 1.0))
	for index in range(count):
		var t := (float(index) + 1.0) / (float(count) + 1.0)
		var anchor := start.lerp(end, t)
		var side := -1.0 if index % 2 == 0 else 1.0
		draw_line(anchor, anchor + normal * side * 10.0 * scale, Color(0.23, 0.16, 0.11), 2.5, true)

func _draw_crystal_thorns(start: Vector2, end: Vector2, phenotype: Dictionary) -> void:
	var count := int(phenotype.get("crystal_thorn_count", 0))
	if count <= 0:
		return
	var vector := end - start
	var normal := Vector2(-vector.y, vector.x) / maxf(vector.length(), 1.0)
	var scale := float(phenotype.get("crystal_thorn_scale", 1.0))
	for index in range(count):
		var t := (float(index) + 1.0) / (float(count) + 1.0)
		var anchor := start.lerp(end, t)
		var side := -1.0 if index % 2 == 0 else 1.0
		var tip := anchor + normal * side * 13.0 * scale
		draw_line(anchor, tip, Color(0.48, 0.86, 0.92), 4.0, true)
		draw_circle(tip, 2.2, Color(0.82, 0.98, 1.0))

func _draw_fungi(start: Vector2, end: Vector2, phenotype: Dictionary, vitality: float) -> void:
	var count := int(phenotype.get("fungus_count", 0))
	if count <= 0:
		return
	var vector := end - start
	var normal := Vector2(-vector.y, vector.x) / maxf(vector.length(), 1.0)
	var scale := float(phenotype.get("fungus_scale", 1.0))
	var glow := float(phenotype.get("fungus_glow", 0.0)) * vitality
	for index in range(count):
		var t := (float(index) + 1.0) / (float(count) + 1.0)
		var side := -1.0 if index % 2 == 0 else 1.0
		var anchor := start.lerp(end, t) + normal * side * 7.0
		if glow > 0.0:
			draw_circle(anchor, 9.0 * scale, Color(0.42, 0.94, 0.82, glow * 0.22))
		draw_line(anchor, anchor + normal * side * 5.0 * scale, Color(0.72, 0.67, 0.52), 2.0, true)
		draw_circle(anchor + normal * side * 6.0 * scale, 4.5 * scale, Color(0.57, 0.31, 0.55).lerp(Color(0.38, 0.90, 0.76), glow))

func _draw_spore_traps(start: Vector2, end: Vector2, phenotype: Dictionary) -> void:
	var count := int(phenotype.get("spore_trap_count", 0))
	if count <= 0:
		return
	var vector := end - start
	var normal := Vector2(-vector.y, vector.x) / maxf(vector.length(), 1.0)
	for index in range(count):
		var t := 0.25 + (float(index) / maxf(float(count), 1.0)) * 0.65
		var side := -1.0 if index % 2 == 0 else 1.0
		var center := start.lerp(end, t) + normal * side * 13.0
		draw_circle(center, 7.0, Color(0.43, 0.16, 0.39))
		draw_circle(center, 3.0, Color(0.76, 0.70, 0.35))
		draw_line(center, center + normal * side * 8.0, Color(0.34, 0.12, 0.28), 2.0, true)

func _draw_flowers(end: Vector2, phenotype: Dictionary, vitality: float) -> void:
	var count := int(phenotype.get("flower_count", 0))
	if count <= 0:
		return
	var scale := float(phenotype.get("flower_scale", 1.0)) * lerpf(0.65, 1.0, vitality)
	var lure := float(phenotype.get("lure_strength", 0.0))
	var crown := float(phenotype.get("crown_bloom_strength", 0.0))
	var flower_glow := float(phenotype.get("flower_glow", 0.0)) * vitality
	for index in range(count):
		var angle := TAU * float(index) / float(count)
		var center := end + Vector2(cos(angle), sin(angle)) * lerpf(18.0, 25.0, crown) * scale
		if flower_glow > 0.0:
			draw_circle(center, 13.0 * scale, Color(0.60, 0.94, 0.74, flower_glow * 0.24))
		var petal := Color(0.88, 0.39, 0.55).lerp(Color(0.68, 0.12, 0.34), lure)
		petal = petal.lerp(Color(0.96, 0.62, 0.20), crown * 0.55)
		petal = Color(0.37, 0.28, 0.22).lerp(petal, vitality)
		draw_circle(center, 7.0 * scale, petal)
		var center_color := Color(0.96, 0.79, 0.24).lerp(Color(0.18, 0.06, 0.08), lure)
		draw_circle(center, 2.5 * scale, center_color)

func _detect_trait_increases(plant: PlantState) -> void:
	for slot in BranchState.VALID_SLOTS:
		var branch := plant.branch_at(slot)
		if branch == null:
			continue
		var previous: Dictionary = _trait_snapshot.get(String(slot), {})
		for trait_id in branch.traits:
			if int(branch.traits[trait_id]) > int(previous.get(String(trait_id), 0)):
				_reveal_slots[String(slot)] = REVEAL_SECONDS
				set_process(true)
				break

func _snapshot_traits(plant: PlantState) -> Dictionary:
	var result := {}
	if plant == null:
		return result
	for slot in BranchState.VALID_SLOTS:
		var branch := plant.branch_at(slot)
		result[String(slot)] = branch.traits.duplicate(true) if branch != null else {}
	return result

func _is_selectable(branch: BranchState) -> bool:
	if _plant == null or not _plant.alive:
		return false
	if _interaction_mode == MODE_PRUNE:
		return branch != null
	if _interaction_mode == MODE_GRAFT:
		return branch == null
	if _interaction_mode == MODE_HARVEST:
		return branch != null and branch.fruit_growth != null and branch.fruit_growth.is_ready()
	return false

func _candidate_at(point: Vector2) -> StringName:
	var slots: Dictionary = _layout.get("slots", {})
	var closest: StringName = &""
	var closest_distance := 34.0 if _interaction_mode == MODE_HARVEST else 28.0
	for slot_name in BranchState.VALID_SLOTS:
		var descriptor: Dictionary = slots.get(String(slot_name), {})
		if descriptor.is_empty():
			continue
		var branch := descriptor.get("branch") as BranchState
		if not _is_selectable(branch):
			continue
		var start: Vector2 = descriptor.get("start", Vector2.ZERO)
		var end: Vector2 = descriptor.get("end", Vector2.ZERO)
		var distance := _distance_to_segment(point, start, end + Vector2(0.0, 18.0))
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
