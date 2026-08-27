class_name GardenLayoutEditor
extends Control

signal layout_changed(layout: Dictionary)
signal window_changed
signal pot_changed(direction: int)
signal soil_changed(direction: int)
signal tree_changed(direction: int)
signal prune_changed
signal prune_undo_pressed

const WINDOWS: Array[Texture2D] = [preload("res://assets/window/window_01.png"), preload("res://assets/window/window_02.png"), preload("res://assets/window/window_03.png"), preload("res://assets/window/window_04.png")]
const POTS: Array[Texture2D] = [preload("res://assets/pot/pot_01.png"), preload("res://assets/pot/pot_02.png"), preload("res://assets/pot/pot_03.png"), preload("res://assets/pot/pot_04.png"), preload("res://assets/pot/pot_05.png")]
const SOILS: Array[Texture2D] = [preload("res://assets/pot/pot_ground/ground_06.png"), preload("res://assets/pot/pot_ground/ground_01.png"), preload("res://assets/pot/pot_ground/ground_05.png"), preload("res://assets/pot/pot_ground/ground_04.png"), preload("res://assets/pot/pot_ground/ground_02.png"), preload("res://assets/pot/pot_ground/ground_03.png")]
const TREES: Array[Texture2D] = [preload("res://assets/tree/tree_01.png"), preload("res://assets/tree/tree_02.png"), preload("res://assets/tree/tree_03.png"), preload("res://assets/tree/tree_04.png"), preload("res://assets/tree/tree_05.png"), preload("res://assets/tree/tree_06.png"), preload("res://assets/tree/tree_07.png"), preload("res://assets/tree/tree_08.png"), preload("res://assets/tree/tree_09.png")]
const STAND: Texture2D = preload("res://assets/pot/window_potground_01.png")
const IDS: Array[StringName] = [&"stand", &"pot", &"soil", &"tree"]
const VARIANTS: Array[StringName] = [&"window", &"pot", &"soil", &"tree"]
const MIN_SCALE := 0.25
const MAX_SCALE := 3.0
const HANDLE := 22.0
const PANEL_RATIO := 0.27
const STEP := 0.025
const FILE_PATH := "user://growweird_layout.json"
const ART_LAYOUT := {"stand": {"position": Vector2(0.5107, 0.4953), "size": Vector2(0.6000, 0.3400), "scale": 3.0000}, "pot": {"position": Vector2(0.4987, 0.7336), "size": Vector2(0.4800, 0.4000), "scale": 0.6500}, "soil": {"position": Vector2(0.4987, 0.7354), "size": Vector2(0.3600, 0.1900), "scale": 1.4250}, "tree": {"position": Vector2(0.4947, 0.4236), "size": Vector2(0.6800, 0.5800), "scale": 0.9250}}

var window_index := 0
var pot_index := 0
var soil_index := 2
var tree_index := 0
var pruned := false
var _items: Dictionary
var _selected: StringName = &""
var _drag_mode: StringName = &""
var _drag_offset := Vector2.ZERO
var _start_distance := 1.0
var _start_scale := 1.0
var _message := ""
var _message_time := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)
	_reset_items()
	_apply_art_layout()
	_load_layout()
	queue_redraw()
func set_preview(next_window: int, next_pot: int, next_soil: int, next_tree: int, next_pruned: bool) -> void:
	window_index = posmod(next_window, WINDOWS.size())
	pot_index = posmod(next_pot, POTS.size())
	soil_index = clampi(next_soil, 0, SOILS.size() - 1)
	tree_index = clampi(next_tree, 0, TREES.size() - 1)
	pruned = next_pruned
	_update_textures()
	queue_redraw()
func set_prune_mode(enabled: bool) -> void:
	pruned = false if enabled else pruned
	queue_redraw()
func layout_data() -> Dictionary:
	var result := {}
	for id in IDS:
		var item: Dictionary = _items[id]
		result[String(id)] = {"position": item.position, "size": item.size, "scale": item.scale}
	return result
func layout_code() -> String:
	var lines: Array[String] = ["const ART_LAYOUT := {"]
	for id in IDS:
		var item: Dictionary = _items[id]
		lines.append("\t\"%s\": {\"position\": Vector2(%.4f, %.4f), \"size\": Vector2(%.4f, %.4f), \"scale\": %.4f}," % [String(id), item.position.x, item.position.y, item.size.x, item.size.y, item.scale])
	lines.append("}")
	return "\n".join(lines)

func _reset_items() -> void:
	_items = {
		"stand": {"position": Vector2(0.50, 0.77), "size": Vector2(0.60, 0.34), "scale": 1.0, "label": "Stand", "texture": STAND},
		"pot": {"position": Vector2(0.50, 0.69), "size": Vector2(0.48, 0.40), "scale": 1.0, "label": "Pot", "texture": POTS[pot_index]},
		"soil": {"position": Vector2(0.50, 0.665), "size": Vector2(0.36, 0.19), "scale": 1.0, "label": "Soil", "texture": SOILS[soil_index]},
		"tree": {"position": Vector2(0.50, 0.37), "size": Vector2(0.68, 0.58), "scale": 1.0, "label": "Tree", "texture": TREES[tree_index]},
	}
func _apply_art_layout() -> void:
	for id in IDS:
		var item: Dictionary = _items[id]
		var configured: Dictionary = ART_LAYOUT[String(id)]
		item.position = configured.position
		item.size = configured.size
		item.scale = configured.scale
func _update_textures() -> void:
	if _items.is_empty():
		return
	_items["pot"].texture = POTS[pot_index]
	_items["soil"].texture = SOILS[soil_index]
	_items["tree"].texture = TREES[tree_index]
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_motion(event.position)
	elif event is InputEventMouseButton:
		_mouse(event)
	elif event is InputEventKey and event.pressed and not event.echo:
		_key(event)
func _motion(point: Vector2) -> void:
	if _drag_mode == &"move" and _items.has(_selected):
		var p: Vector2 = (point - _drag_offset) / _canvas().size
		_items[_selected].position = Vector2(clampf(p.x, -0.2, 1.2), clampf(p.y, -0.2, 1.2))
		_changed()
	elif _drag_mode == &"scale" and _items.has(_selected):
		var center: Vector2 = _item_rect(_selected).get_center()
		_items[_selected].scale = clampf(_start_scale * maxf(8.0, point.distance_to(center)) / _start_distance, MIN_SCALE, MAX_SCALE)
		_changed()
func _mouse(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _panel_click(event.position):
			accept_event()
			return
		var handle := _handle_at(event.position)
		if handle != &"":
			_selected = handle
			_drag_mode = &"scale"
			_start_distance = maxf(8.0, event.position.distance_to(_item_rect(handle).get_center()))
			_start_scale = _items[handle].scale
			accept_event()
			return
		var target := _item_at(event.position)
		if target != &"":
			_selected = target
			_drag_mode = &"move"
			_drag_offset = event.position - _item_rect(target).get_center()
			accept_event()
			queue_redraw()
			return
		_selected = &""
		_drag_mode = &""
		queue_redraw()
	elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_drag_mode = &""
	elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		_scale_at(event.position, STEP)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		_scale_at(event.position, -STEP)
func _key(event: InputEventKey) -> void:
	if _selected == &"" or not _items.has(_selected):
		return
	var item: Dictionary = _items[_selected]
	var p: Vector2 = item.position
	match event.keycode:
		KEY_LEFT: p.x -= STEP
		KEY_RIGHT: p.x += STEP
		KEY_UP: p.y -= STEP
		KEY_DOWN: p.y += STEP
		KEY_PLUS, KEY_EQUAL: item.scale = clampf(item.scale + STEP, MIN_SCALE, MAX_SCALE)
		KEY_MINUS: item.scale = clampf(item.scale - STEP, MIN_SCALE, MAX_SCALE)
		_: return
	item.position = Vector2(clampf(p.x, -0.2, 1.2), clampf(p.y, -0.2, 1.2))
	_changed()
func _panel_click(point: Vector2) -> bool:
	var panel := _panel()
	if not panel.has_point(point):
		return false
	if _button(0).has_point(point):
		DisplayServer.clipboard_set(layout_code())
		_flash("Coordinates copied")
		return true
	if _button(1).has_point(point):
		_save_layout()
		return true
	if _button(2).has_point(point):
		_reset_items()
		_selected = &""
		_changed()
		_flash("Layout reset")
		return true
	if _button(3).has_point(point):
		_apply_art_layout()
		_selected = &""
		_changed()
		_flash("Draft coordinates applied")
		return true
	for i in VARIANTS.size():
		var y := 214.0 + i * 40.0
		if Rect2(panel.position + Vector2(18.0, y), Vector2(24.0, 28.0)).has_point(point):
			_variant(VARIANTS[i], -1)
			return true
		if Rect2(panel.position + Vector2(panel.size.x - 42.0, y), Vector2(24.0, 28.0)).has_point(point):
			_variant(VARIANTS[i], 1)
			return true
	return true
func _variant(id: StringName, direction: int) -> void:
	match id:
		&"window":
			window_index = posmod(window_index + direction, WINDOWS.size())
			window_changed.emit()
		&"pot":
			pot_index = posmod(pot_index + direction, POTS.size())
			pot_changed.emit(direction)
		&"soil":
			soil_index = clampi(soil_index + direction, 0, SOILS.size() - 1)
			soil_changed.emit(direction)
		&"tree":
			tree_index = posmod(tree_index + direction, TREES.size())
			tree_changed.emit(direction)
	_update_textures()
	queue_redraw()
func _scale_at(point: Vector2, amount: float) -> void:
	var target := _item_at(point)
	if target == &"":
		return
	_selected = target
	_items[target].scale = clampf(_items[target].scale + amount, MIN_SCALE, MAX_SCALE)
	_changed()
func _item_at(point: Vector2) -> StringName:
	for id in [&"tree", &"soil", &"pot", &"stand"]:
		if _item_rect(id).has_point(point):
			return id
	return &""
func _handle_at(point: Vector2) -> StringName:
	if _selected == &"" or not _items.has(_selected):
		return &""
	var rect := _item_rect(_selected)
	if Rect2(rect.end - Vector2(HANDLE, HANDLE), Vector2(HANDLE, HANDLE)).has_point(point) or Rect2(rect.position, Vector2(HANDLE, HANDLE)).has_point(point):
		return _selected
	return &""
func _canvas() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(size.x * (1.0 - PANEL_RATIO), size.y))
func _panel() -> Rect2:
	var canvas := _canvas()
	return Rect2(Vector2(canvas.end.x, 0.0), Vector2(size.x - canvas.size.x, size.y))
func _item_rect(id: StringName) -> Rect2:
	var item: Dictionary = _items[id]
	var canvas := _canvas()
	var center: Vector2 = canvas.position + Vector2(item.position) * canvas.size
	var bounds: Vector2 = Vector2(item.size) * canvas.size * float(item.scale)
	return Rect2(center - bounds * 0.5, bounds)
func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0 or _items.is_empty():
		return
	var canvas := _canvas()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.045, 0.035))
	draw_texture_rect(WINDOWS[window_index], _cover(WINDOWS[window_index], canvas), false)
	for id in IDS:
		draw_texture_rect(_items[id].texture, _fit(_items[id].texture, _item_rect(id)), false)
	if _selected != &"":
		var rect := _item_rect(_selected)
		draw_rect(rect, Color(1.0, 0.82, 0.26, 0.9), false, 3.0)
		_draw_handle(Rect2(rect.end - Vector2(HANDLE, HANDLE), Vector2(HANDLE, HANDLE)), "+")
		_draw_handle(Rect2(rect.position, Vector2(HANDLE, HANDLE)), "−")
	_draw_panel(_panel())
func _draw_handle(rect: Rect2, text: String) -> void:
	draw_rect(rect, Color(1.0, 0.82, 0.26))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(6.0, 16.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.12, 0.08, 0.03))
func _draw_panel(panel: Rect2) -> void:
	var left := panel.position + Vector2(18.0, 28.0)
	draw_rect(panel, Color(0.09, 0.07, 0.055))
	draw_line(panel.position, Vector2(panel.position.x, panel.end.y), Color(0.42, 0.30, 0.16), 2.0)
	draw_string(ThemeDB.fallback_font, left, "ART LAYOUT LAB", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1.0, 0.84, 0.48))
	draw_string(ThemeDB.fallback_font, left + Vector2(0.0, 25.0), "Background is locked", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.62, 0.56, 0.46))
	_draw_button(_button(0), "Copy coordinates")
	_draw_button(_button(1), "Save layout")
	_draw_button(_button(2), "Reset layout")
	_draw_button(_button(3), "Apply draft coordinates")
	for i in VARIANTS.size():
		var id := VARIANTS[i]
		var row := Rect2(panel.position + Vector2(18.0, 214.0 + i * 40.0), Vector2(panel.size.x - 36.0, 28.0))
		draw_string(ThemeDB.fallback_font, row.position + Vector2(32.0, 19.0), _variant_label(id), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.88, 0.82, 0.70))
		_draw_button(Rect2(row.position, Vector2(24.0, 28.0)), "−")
		_draw_button(Rect2(row.end - Vector2(24.0, 28.0), Vector2(24.0, 28.0)), "+")
	var y := 392.0
	draw_string(ThemeDB.fallback_font, left + Vector2(0.0, y - 28.0), "COORDINATES · normalized", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.62, 0.56, 0.46))
	for id in IDS:
		var item: Dictionary = _items[id]
		var color := Color(1.0, 0.84, 0.48) if id == _selected else Color(0.78, 0.73, 0.64)
		draw_string(ThemeDB.fallback_font, left + Vector2(0.0, y), "%s  x %.3f  y %.3f" % [item.label, item.position.x, item.position.y], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)
		draw_string(ThemeDB.fallback_font, left + Vector2(0.0, y + 15.0), "w %.3f  h %.3f  scale %.2f" % [item.size.x, item.size.y, item.scale], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.58, 0.54, 0.48))
		y += 42.0
	draw_string(ThemeDB.fallback_font, left + Vector2(0.0, panel.size.y - 28.0), "Drag · corners/wheel resize · arrows fine tune", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.58, 0.54, 0.48))
	if _message_time > 0.0:
		draw_string(ThemeDB.fallback_font, left + Vector2(0.0, panel.size.y - 52.0), _message, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.52, 0.94, 0.72))
func _process(delta: float) -> void:
	if _message_time > 0.0:
		_message_time = maxf(0.0, _message_time - delta)
		queue_redraw()
func _draw_button(rect: Rect2, text: String) -> void:
	draw_rect(rect, Color(0.18, 0.14, 0.10))
	draw_rect(rect, Color(0.46, 0.35, 0.21), false, 1.0)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, rect.size.y * 0.68), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.91, 0.85, 0.72))
func _button(index: int) -> Rect2:
	var panel := _panel()
	return Rect2(panel.position + Vector2(18.0, 68.0 + index * 36.0), Vector2(panel.size.x - 36.0, 28.0))
func _variant_label(id: StringName) -> String:
	match id:
		&"window": return "Background %d/4" % (window_index + 1)
		&"pot": return "Pot asset %d/5" % (pot_index + 1)
		&"soil": return "Soil asset %d/6" % (soil_index + 1)
		&"tree": return "Tree asset %d/9" % (tree_index + 1)
	return String(id)
func _changed() -> void:
	layout_changed.emit(layout_data())
	queue_redraw()
func _flash(text: String) -> void:
	_message = text
	_message_time = 2.5
	queue_redraw()
func _save_layout() -> void:
	var file := FileAccess.open(FILE_PATH, FileAccess.WRITE)
	if file == null:
		_flash("Could not save layout")
		return
	var data := {}
	for id in IDS:
		var item: Dictionary = _items[id]
		data[String(id)] = {"x": item.position.x, "y": item.position.y, "width": item.size.x, "height": item.size.y, "scale": item.scale}
	file.store_string(JSON.stringify(data))
	file.close()
	_flash("Layout saved")
func _load_layout() -> void:
	if not FileAccess.file_exists(FILE_PATH):
		return
	var file := FileAccess.open(FILE_PATH, FileAccess.READ)
	var data: Variant = JSON.parse_string(file.get_as_text()) if file else null
	if file:
		file.close()
	if not data is Dictionary:
		return
	for id in IDS:
		var value: Variant = data.get(String(id))
		if not value is Dictionary:
			continue
		var item: Dictionary = _items[id]
		item.position = Vector2(float(value.get("x", item.position.x)), float(value.get("y", item.position.y)))
		item.size = Vector2(float(value.get("width", item.size.x)), float(value.get("height", item.size.y)))
		item.scale = clampf(float(value.get("scale", item.scale)), MIN_SCALE, MAX_SCALE)
func _cover(texture: Texture2D, bounds: Rect2) -> Rect2:
	var scale := maxf(bounds.size.x / texture.get_width(), bounds.size.y / texture.get_height())
	var draw_size := Vector2(texture.get_width(), texture.get_height()) * scale
	return Rect2(bounds.position + (bounds.size - draw_size) * 0.5, draw_size)
func _fit(texture: Texture2D, bounds: Rect2) -> Rect2:
	var scale := minf(bounds.size.x / texture.get_width(), bounds.size.y / texture.get_height())
	var draw_size := Vector2(texture.get_width(), texture.get_height()) * scale
	return Rect2(bounds.position + (bounds.size - draw_size) * 0.5, draw_size)
