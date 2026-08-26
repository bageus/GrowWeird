class_name GardenPreview
extends Control

signal window_changed
signal pot_changed(direction: int)
signal soil_changed(direction: int)
signal tree_changed(direction: int)
signal prune_changed
signal prune_undo_pressed

const WINDOW_NAMES := ["Direct light · closed", "No light · closed", "Direct light · open", "Diffused light · closed"]
const SOIL_NAMES := ["Very dry", "Dry", "Medium", "Moist", "Very moist", "Saturated"]
const WINDOWS: Array[Texture2D] = [preload("res://assets/window/window_01.png"), preload("res://assets/window/window_02.png"), preload("res://assets/window/window_03.png"), preload("res://assets/window/window_04.png")]
const POTS: Array[Texture2D] = [preload("res://assets/pot/pot_01.png"), preload("res://assets/pot/pot_02.png"), preload("res://assets/pot/pot_03.png"), preload("res://assets/pot/pot_04.png"), preload("res://assets/pot/pot_05.png")]
const SOILS: Array[Texture2D] = [preload("res://assets/pot/pot_ground/ground_06.png"), preload("res://assets/pot/pot_ground/ground_01.png"), preload("res://assets/pot/pot_ground/ground_05.png"), preload("res://assets/pot/pot_ground/ground_04.png"), preload("res://assets/pot/pot_ground/ground_02.png"), preload("res://assets/pot/pot_ground/ground_03.png")]
const TREES: Array[Texture2D] = [preload("res://assets/tree/tree_01.png"), preload("res://assets/tree/tree_02.png"), preload("res://assets/tree/tree_03.png"), preload("res://assets/tree/tree_04.png"), preload("res://assets/tree/tree_05.png"), preload("res://assets/tree/tree_06.png"), preload("res://assets/tree/tree_07.png"), preload("res://assets/tree/tree_08.png"), preload("res://assets/tree/tree_09.png")]
const STAND: Texture2D = preload("res://assets/pot/window_potground_01.png")

var _window := 0
var _pot := 0
var _soil := 2
var _tree := 0
var _pruned := false
var _prune_mode := false
var _hovered_side := ""
var _pulse := 0.0

func set_preview(window_index: int, pot_index: int, soil_index: int, tree_index: int, pruned: bool) -> void:
	_window = posmod(window_index, WINDOWS.size())
	_pot = posmod(pot_index, POTS.size())
	_soil = clampi(soil_index, 0, SOILS.size() - 1)
	_tree = clampi(tree_index, 0, TREES.size() - 2)
	_pruned = pruned
	queue_redraw()

func set_prune_mode(enabled: bool) -> void:
	_prune_mode = enabled
	_hovered_side = ""
	mouse_default_cursor_shape = Control.CURSOR_CROSS if enabled else Control.CURSOR_ARROW
	set_process(enabled)
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	set_process(false)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not _prune_mode or _pruned:
		return
	if event is InputEventMouseMotion:
		var next := _branch_at(event.position)
		if next != _hovered_side:
			_hovered_side = next
			queue_redraw()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not _branch_at(event.position).is_empty():
		_pruned = true
		_prune_mode = false
		_hovered_side = ""
		set_process(false)
		mouse_default_cursor_shape = Control.CURSOR_ARROW
		prune_changed.emit()
		queue_redraw()
		accept_event()

func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()

func _draw() -> void:
	var canvas := Rect2(Vector2.ZERO, size)
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var window_rect := Rect2(Vector2.ZERO, Vector2(size.x, size.y * 0.68))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.06, 0.05, 1.0))
	draw_texture_rect(WINDOWS[_window], _cover(WINDOWS[_window], window_rect), false)
	var stand := Rect2(Vector2(size.x * 0.20, size.y * 0.64), Vector2(size.x * 0.60, size.y * 0.34))
	draw_texture_rect(STAND, _fit(STAND, stand), false)
	var pot := Rect2(Vector2(size.x * 0.26, size.y * 0.50), Vector2(size.x * 0.48, size.y * 0.40))
	draw_texture_rect(POTS[_pot], _fit(POTS[_pot], pot), false)
	var soil := Rect2(Vector2(size.x * 0.32, size.y * 0.57), Vector2(size.x * 0.36, size.y * 0.19))
	draw_texture_rect(SOILS[_soil], _fit(SOILS[_soil], soil), false)
	var tree := TREES[8] if _pruned else TREES[_tree]
	var tree_box := Rect2(Vector2(size.x * 0.16, size.y * 0.08), Vector2(size.x * 0.68, size.y * 0.58))
	draw_texture_rect(tree, _fit(tree, tree_box), false)
	if _prune_mode and not _pruned:
		_draw_hint(canvas, -1.0)
		_draw_hint(canvas, 1.0)

func _draw_hint(canvas: Rect2, side: float) -> void:
	var center := canvas.position + Vector2(canvas.size.x * (0.35 if side < 0.0 else 0.65), canvas.size.y * 0.34)
	var radius := 24.0 + sin(_pulse * 8.0) * 5.0 if _hovered_side == ("left" if side < 0.0 else "right") else 20.0
	draw_circle(center, radius, Color(1.0, 0.78, 0.22, 0.14))
	draw_arc(center, radius, 0.0, TAU, 24, Color(1.0, 0.82, 0.30, 0.82), 3.0, true)

func _branch_at(point: Vector2) -> String:
	if _tree < 5:
		return ""
	var canvas := Rect2(Vector2.ZERO, size)
	if Rect2(canvas.position + Vector2(canvas.size.x * 0.20, canvas.size.y * 0.18), Vector2(canvas.size.x * 0.30, canvas.size.y * 0.34)).has_point(point):
		return "left"
	if Rect2(canvas.position + Vector2(canvas.size.x * 0.50, canvas.size.y * 0.18), Vector2(canvas.size.x * 0.30, canvas.size.y * 0.34)).has_point(point):
		return "right"
	return ""

func _cover(texture: Texture2D, bounds: Rect2) -> Rect2:
	var scale := maxf(bounds.size.x / texture.get_width(), bounds.size.y / texture.get_height())
	var draw_size := Vector2(texture.get_width(), texture.get_height()) * scale
	return Rect2(bounds.position + (bounds.size - draw_size) * 0.5, draw_size)

func _fit(texture: Texture2D, bounds: Rect2) -> Rect2:
	var scale := minf(bounds.size.x / texture.get_width(), bounds.size.y / texture.get_height())
	var draw_size := Vector2(texture.get_width(), texture.get_height()) * scale
	return Rect2(bounds.position + (bounds.size - draw_size) * 0.5, draw_size)
