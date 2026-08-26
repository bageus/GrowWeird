class_name GardenArtView
extends Control

signal debug_changed

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
const STAND_TEXTURE: Texture2D = preload("res://assets/pot/window_potground_01.png")
const GROUND_TEXTURES: Array[Texture2D] = [
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
const WINDOW_NAMES := ["Direct light · open curtains", "No light · closed curtains", "Direct light · open window", "Diffused light · open curtains"]

var _window_mode := 0
var _pot_index := 0
var _ground_index := 2
var _tree_index := 0
var _pruned := false
var _prune_mode := false
var _hovered_branch := ""
var _pulse := 0.0
var _tree_rect := Rect2()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(false)
	queue_redraw()

func cycle_window_mode() -> void:
	set_window_mode(_window_mode + 1)

func window_mode_name() -> String:
	return WINDOW_NAMES[_window_mode]

func window_mode_count() -> int:
	return WINDOW_TEXTURES.size()

func pot_count() -> int:
	return POT_TEXTURES.size()

func ground_count() -> int:
	return GROUND_TEXTURES.size()

func tree_count() -> int:
	return TREE_TEXTURES.size()

func get_window_mode() -> int:
	return _window_mode

func get_pot_index() -> int:
	return _pot_index

func get_ground_index() -> int:
	return _ground_index

func get_tree_index() -> int:
	return _tree_index

func is_pruned() -> bool:
	return _pruned

func set_window_mode(mode: int) -> void:
	_window_mode = posmod(mode, WINDOW_TEXTURES.size())
	queue_redraw()
	debug_changed.emit()

func set_pot_index(index: int) -> void:
	_pot_index = posmod(index, POT_TEXTURES.size())
	queue_redraw()
	debug_changed.emit()

func set_ground_index(index: int) -> void:
	_ground_index = clampi(index, 0, GROUND_TEXTURES.size() - 1)
	queue_redraw()
	debug_changed.emit()

func set_tree_index(index: int) -> void:
	_tree_index = clampi(index, 0, TREE_TEXTURES.size() - 1)
	if _tree_index < 5:
		_prune_mode = false
		_hovered_branch = ""
		set_process(false)
	queue_redraw()
	debug_changed.emit()

func set_pruned(value: bool) -> void:
	_pruned = value
	_prune_mode = false
	_hovered_branch = ""
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	set_process(false)
	queue_redraw()
	debug_changed.emit()

func set_prune_mode(value: bool) -> void:
	_prune_mode = value and not _pruned and _tree_index >= 5
	_hovered_branch = ""
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _prune_mode else Control.CURSOR_ARROW
	set_process(_prune_mode)
	queue_redraw()

func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not _prune_mode or _pruned:
		return
	if event is InputEventMouseMotion:
		var next_branch := _branch_at(event.position)
		if next_branch != _hovered_branch:
			_hovered_branch = next_branch
			queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not _branch_at(event.position).is_empty():
			_pruned = true
			_prune_mode = false
			_hovered_branch = ""
			mouse_default_cursor_shape = Control.CURSOR_ARROW
			set_process(false)
			queue_redraw()
			debug_changed.emit()
			accept_event()

func _draw() -> void:
	_draw_cover(WINDOW_TEXTURES[_window_mode])
	var stand_width := size.x * 0.76
	var stand_height := stand_width * STAND_TEXTURE.get_height() / STAND_TEXTURE.get_width()
	var stand_rect := Rect2((size.x - stand_width) * 0.5, size.y - stand_height - 10.0, stand_width, stand_height)
	draw_texture_rect(STAND_TEXTURE, stand_rect, false)
	var pot_texture := POT_TEXTURES[_pot_index]
	var pot_width := size.x * 0.43
	var pot_height := pot_width * pot_texture.get_height() / pot_texture.get_width()
	var pot_rect := Rect2((size.x - pot_width) * 0.5, stand_rect.position.y - pot_height * 0.72, pot_width, pot_height)
	draw_texture_rect(pot_texture, pot_rect, false)
	var ground_texture := GROUND_TEXTURES[_ground_index]
	var ground_width := pot_width * 0.92
	var ground_height := ground_width * ground_texture.get_height() / ground_texture.get_width()
	var ground_rect := Rect2((size.x - ground_width) * 0.5, pot_rect.position.y + pot_height * 0.08, ground_width, ground_height)
	draw_texture_rect(ground_texture, ground_rect, false)
	var tree_index := 8 if _pruned else _tree_index
	var tree_texture := TREE_TEXTURES[tree_index]
	var tree_height := size.y * 0.64
	var tree_width := tree_height * tree_texture.get_width() / tree_texture.get_height()
	_tree_rect = Rect2((size.x - tree_width) * 0.5, ground_rect.position.y - tree_height * 0.82, tree_width, tree_height)
	draw_texture_rect(tree_texture, _tree_rect, false)
	if _prune_mode and not _pruned and _tree_index >= 5:
		_draw_branch_hint(_tree_rect, 0.27, "left")
		_draw_branch_hint(_tree_rect, 0.73, "right")

func _draw_cover(texture: Texture2D) -> void:
	var scale := maxf(size.x / texture.get_width(), size.y / texture.get_height())
	var draw_size := Vector2(texture.get_width(), texture.get_height()) * scale
	var rect := Rect2((size - draw_size) * 0.5, draw_size)
	draw_texture_rect(texture, rect, false)

func _draw_branch_hint(rect: Rect2, x_ratio: float, branch: String) -> void:
	var center := rect.position + Vector2(rect.size.x * x_ratio, rect.size.y * 0.43)
	var active := _hovered_branch == branch
	var alpha := (0.32 if not active else 0.72) + sin(_pulse * 7.0) * 0.16
	draw_circle(center, 22.0 if not active else 29.0, Color(1.0, 0.70, 0.24, alpha))
	draw_arc(center, 31.0 if not active else 38.0, 0.0, TAU, 24, Color(1.0, 0.90, 0.52, alpha), 3.0, true)

func _branch_at(point: Vector2) -> String:
	if not _tree_rect.has_point(point):
		return ""
	var left := Rect2(_tree_rect.position + Vector2(_tree_rect.size.x * 0.12, _tree_rect.size.y * 0.22), Vector2(_tree_rect.size.x * 0.32, _tree_rect.size.y * 0.32))
	var right := Rect2(_tree_rect.position + Vector2(_tree_rect.size.x * 0.56, _tree_rect.size.y * 0.17), Vector2(_tree_rect.size.x * 0.32, _tree_rect.size.y * 0.36))
	if left.has_point(point):
		return "left"
	if right.has_point(point):
		return "right"
	return ""
