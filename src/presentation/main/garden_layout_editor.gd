class_name GardenLayoutEditor
extends Control

signal state_changed

const WINDOW_TEXTURES: Array[Texture2D] = [
	preload("res://assets/window/window_01.png"),
	preload("res://assets/window/window_02.png"),
	preload("res://assets/window/window_03.png"),
	preload("res://assets/window/window_04.png"),
]
const POT_TEXTURES: Array[Texture2D] = [
	preload("res://assets/pot/pot_01.png"),
	preload("res://assets/pot/pot_02.png"),
	preload("res://assets/pot/pot_03.png"),
	preload("res://assets/pot/pot_04.png"),
	preload("res://assets/pot/pot_05.png"),
]
const SOIL_TEXTURES: Array[Texture2D] = [
	preload("res://assets/pot/pot_ground/ground_06.png"),
	preload("res://assets/pot/pot_ground/ground_01.png"),
	preload("res://assets/pot/pot_ground/ground_05.png"),
	preload("res://assets/pot/pot_ground/ground_04.png"),
	preload("res://assets/pot/pot_ground/ground_02.png"),
	preload("res://assets/pot/pot_ground/ground_03.png"),
]
const TREE_TEXTURES: Array[Texture2D] = [
	preload("res://assets/tree/tree_01.png"),
	preload("res://assets/tree/tree_02.png"),
	preload("res://assets/tree/tree_03.png"),
	preload("res://assets/tree/tree_04.png"),
	preload("res://assets/tree/tree_05.png"),
	preload("res://assets/tree/tree_06.png"),
	preload("res://assets/tree/tree_07.png"),
	preload("res://assets/tree/tree_08.png"),
	preload("res://assets/tree/tree_09.png"),
]
const STAND_TEXTURE: Texture2D = preload("res://assets/pot/window_potground_01.png")
const MIN_SCALE := 0.35
const MAX_SCALE := 2.4
const HANDLE_SIZE := 18.0

var window_index := 0
var pot_index := 0
var soil_index := 2
var tree_index := 0
var pruned := false
var _selected := ""
var _dragging := false
var _drag_offset := Vector2.ZERO
var _hovered_branch := ""
var _pulse := 0.0
var _items := {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)
	_items = {
		"stand": {"position": Vector2(0.50, 0.77), "size": Vector2(0.60, 0.34), "scale": 1.0, "texture": STAND_TEXTURE},
		"pot": {"position": Vector2(0.50, 0.69), "size": Vector2(0.48, 0.40), "scale": 1.0, "texture": POT_TEXTURES[pot_index]},
		"soil": {"position": Vector2(0.50, 0.665), "size": Vector2(0.36, 0.19), "scale": 1.0, "texture": SOIL_TEXTURES[soil_index]},
		"tree": {"position": Vector2(0.50, 0.37), "size": Vector2(0.68, 0.58), "scale": 1.0, "texture": TREE_TEXTURES[tree_index]},
	}
	queue_redraw()

func set_preview(next_window: int, next_pot: int, next_soil: int, next_tree: int, next_pruned: bool) -> void:
	window_index = posmod(next_window, WINDOW_TEXTURES.size())
	pot_index = posmod(next_pot, POT_TEXTURES.size())
	soil_index = clampi(next_soil, 0, SOIL_TEXTURES.size() - 1)
	tree_index = clampi(next_tree, 0, TREE_TEXTURES.size() - 2)
	pruned = next_pruned
	if _items.is_empty():
		return
	_items["pot"].texture = POT_TEXTURES[pot_index]
	_items["soil"].texture = SOIL_TEXTURES[soil_index]
	_items["tree"].texture = TREE_TEXTURES[8] if pruned else TREE_TEXTURES[tree_index]
	queue_redraw()

func _process(delta: float) -> void:
	_pulse += delta
	if _selected == "" and _hovered_branch != "":
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var point := event.position
		if _dragging and _selected != "":
			_items[_selected].position = (point - _drag_offset) / size
			state_changed.emit()
			queue_redraw()
			accept_event()
			return
		var branch := _branch_at(point)
		if branch != _hovered_branch:
			_hovered_branch = branch
			queue_redraw()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var handle := _size_handle_at(event.position)
			if handle != "":
				_selected = handle
				_scale_selected(0.1)
				return
			var target := _item_at(event.position)
			if target != "":
				_selected = target
				_drag_offset = event.position - Vector2(_items[target].position) * size
				_dragging = true
					queue_redraw()
				accept_event()
				return
			if _prune_mode() and not _branch_at(event.position).is_empty():
				pruned = true
				_hovered_branch = ""
				state_changed.emit()
				queue_redraw()
				accept_event()
		else:
			_dragging = false
			accept_event()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_dragging = false

func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var canvas := Rect2(Vector2.ZERO, size)
	draw_rect(canvas, Color(0.08, 0.06, 0.05, 1.0))
	draw_texture_rect(WINDOW_TEXTURES[window_index], _cover(WINDOW_TEXTURES[window_index], canvas), false)
	for id in ["stand", "pot", "soil", "tree"]:
		var rect := _item_rect(id)
		draw_texture_rect(_items[id].texture, _fit(_items[id].texture, rect), false)
	if _selected != "":
		var selected_rect := _item_rect(_selected)
		draw_rect(selected_rect, Color(1.0, 0.83, 0.34, 0.8), false, 2.0)
		var handle := Rect2(selected_rect.end - Vector2(HANDLE_SIZE, HANDLE_SIZE), Vector2(HANDLE_SIZE, HANDLE_SIZE))
		draw_rect(handle, Color(1.0, 0.83, 0.34, 0.95))
		draw_string(ThemeDB.fallback_font, handle.position + Vector2(5, 14), "+", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.15, 0.10, 0.04))
		var minus := Rect2(selected_rect.position - Vector2(HANDLE_SIZE, 0), Vector2(HANDLE_SIZE, HANDLE_SIZE))
		draw_rect(minus, Color(1.0, 0.83, 0.34, 0.95))
		draw_string(ThemeDB.fallback_font, minus.position + Vector2(5, 14), "−", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.15, 0.10, 0.04))
	if _prune_mode() and not pruned:
		_draw_branch_hint(canvas, -1.0)
		_draw_branch_hint(canvas, 1.0)

func _prune_mode() -> bool:
	return _selected == "prune"

func set_prune_mode(enabled: bool) -> void:
	_selected = "prune" if enabled else ""
	_hovered_branch = ""
	set_process(enabled)
	queue_redraw()

func _scale_selected(amount: float) -> void:
	if _selected == "" or not _items.has(_selected):
		return
	_items[_selected].scale = clampf(_items[_selected].scale + amount, MIN_SCALE, MAX_SCALE)
	state_changed.emit()
	queue_redraw()

func _item_rect(id: String) -> Rect2:
	var item: Dictionary = _items[id]
	var center: Vector2 = Vector2(item.position) * size
	var bounds: Vector2 = Vector2(item.size) * size * float(item.scale)
	return Rect2(center - bounds * 0.5, bounds)

func _item_at(point: Vector2) -> String:
	for id in ["tree", "soil", "pot", "stand"]:
		if _item_rect(id).has_point(point):
			return id
	return ""

func _size_handle_at(point: Vector2) -> String:
	for id in ["tree", "soil", "pot", "stand"]:
		var rect := _item_rect(id)
		if Rect2(rect.end - Vector2(HANDLE_SIZE, HANDLE_SIZE), Vector2(HANDLE_SIZE, HANDLE_SIZE)).has_point(point):
			return id
		if Rect2(rect.position - Vector2(HANDLE_SIZE, 0), Vector2(HANDLE_SIZE, HANDLE_SIZE)).has_point(point):
			return id
	return ""

func _branch_at(point: Vector2) -> String:
	var rect := _item_rect("tree")
	if Rect2(rect.position + Vector2(rect.size.x * 0.05, rect.size.y * 0.18), Vector2(rect.size.x * 0.42, rect.size.y * 0.42)).has_point(point):
		return "left"
	if Rect2(rect.position + Vector2(rect.size.x * 0.53, rect.size.y * 0.18), Vector2(rect.size.x * 0.42, rect.size.y * 0.42)).has_point(point):
		return "right"
	return ""

func _draw_branch_hint(canvas: Rect2, side: float) -> void:
	var center := Vector2(canvas.size.x * (0.35 if side < 0.0 else 0.65), canvas.size.y * 0.34)
	var radius := 24.0 + sin(_pulse * 8.0) * 5.0 if _hovered_branch == ("left" if side < 0.0 else "right") else 20.0
	draw_circle(center, radius, Color(1.0, 0.78, 0.22, 0.14))
	draw_arc(center, radius, 0.0, TAU, 24, Color(1.0, 0.82, 0.30, 0.82), 3.0, true)

func _cover(texture: Texture2D, bounds: Rect2) -> Rect2:
	var scale := maxf(bounds.size.x / texture.get_width(), bounds.size.y / texture.get_height())
	var draw_size := Vector2(texture.get_width(), texture.get_height()) * scale
	return Rect2(bounds.position + (bounds.size - draw_size) * 0.5, draw_size)

func _fit(texture: Texture2D, bounds: Rect2) -> Rect2:
	var scale := minf(bounds.size.x / texture.get_width(), bounds.size.y / texture.get_height())
	var draw_size := Vector2(texture.get_width(), texture.get_height()) * scale
	return Rect2(bounds.position + (bounds.size - draw_size) * 0.5, draw_size)
