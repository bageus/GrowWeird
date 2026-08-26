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

var _window_mode := 0
var _pot_index := 0
var _ground_index := 2
var _tree_index := 0
var _pruned := false
var _prune_mode := false
var _hovered_branch := ""
var _pulse := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func cycle_window_mode() -> void:
	_window_mode = (_window_mode + 1) % WINDOW_TEXTURES.size()
	queue_redraw()
	debug_changed.emit()

func set_window_mode(mode: int) -> void:
	_window_mode = posmod(mode, WINDOW_TEXTURES.size())
	queue_redraw()

func set_pot_index(index: int) -> void:
	_pot_index = posmod(index, POT_TEXTURES.size())
	queue_redraw()

func set_ground_index(index: int) -> void:
	_ground_index = clampi(index, 0, GROUND_TEXTURES.size() - 1)
	queue_redraw()

func set_tree_index(index: int) -> void:
	_tree_index = clampi(index, 0, TREE_TEXTURES.size() - 1)
	queue_redraw()

func set_pruned(value: bool) -> void:
	_pruned = value
	queue_redraw()

func set_prune_mode(value: bool) -> void:
	_prune_mode = value
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if value else Control.CURSOR_ARROW
	queue_redraw()

func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not _prune_mode or _pruned:
		return
	if event is InputEventMouseMotion:
		_hovered_branch = _branch_at(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not _branch_at(event.position).is_empty():
			_pruned = true
			_prune_mode = false
			mouse_default_cursor_shape = Control.CURSOR_ARROW
			queue_redraw()
			debug_changed.emit()
			accept_event()

func _draw() -> void:
	draw_texture_rect(WINDOW_TEXTURES[_window_mode], Rect2(Vector2.ZERO, size), false)
	var pot_width := size.x * 0.55
	var pot_texture := POT_TEXTURES[_pot_index]
	var pot_height := pot_width * pot_texture.get_height() / pot_texture.get_width()
	var pot_rect := Rect2((size.x - pot_width) * 0.5, size.y - pot_height * 0.66, pot_width, pot_height)
	var ground_texture := GROUND_TEXTURES[_ground_index]
	var ground_width := pot_width * 1.12
	var ground_height := ground_width * ground_texture.get_height() / ground_texture.get_width()
	draw_texture_rect(ground_texture, Rect2((size.x - ground_width) * 0.5, pot_rect.position.y + pot_height * 0.18, ground_width, ground_height), false)
	draw_texture_rect(pot_texture, pot_rect, false)
	var tree_index := 8 if _pruned else _tree_index
	var tree_texture := TREE_TEXTURES[tree_index]
	var tree_height := size.y * 0.66
	var tree_width := tree_height * tree_texture.get_width() / tree_texture.get_height()
	var tree_rect := Rect2((size.x - tree_width) * 0.5, pot_rect.position.y - tree_height * 0.72, tree_width, tree_height)
	draw_texture_rect(tree_texture, tree_rect, false)
	if _prune_mode and not _pruned:
		_draw_branch_hint(tree_rect, 0.27, "left")
		_draw_branch_hint(tree_rect, 0.73, "right")

func _draw_branch_hint(rect: Rect2, x_ratio: float, branch: String) -> void:
	var center := rect.position + Vector2(rect.size.x * x_ratio, rect.size.y * 0.43)
	var active := _hovered_branch == branch
	var alpha := (0.32 if not active else 0.72) + sin(_pulse * 7.0) * 0.16
	draw_circle(center, 22.0 if not active else 29.0, Color(1.0, 0.70, 0.24, alpha))
	draw_arc(center, 31.0 if not active else 38.0, 0.0, TAU, 24, Color(1.0, 0.90, 0.52, alpha), 3.0, true)

func _branch_at(point: Vector2) -> String:
	var left := Rect2(size.x * 0.27, size.y * 0.22, size.x * 0.22, size.y * 0.28)
	var right := Rect2(size.x * 0.51, size.y * 0.17, size.x * 0.22, size.y * 0.30)
	if left.has_point(point):
		return "left"
	if right.has_point(point):
		return "right"
	return ""
