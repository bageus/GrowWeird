class_name InventoryHud
extends SceneDraggablePanel

signal item_selected(kind: StringName, item_id: String, count: int, title: String)

@onready var items: VBoxContainer = $Layers/FrameContent/Scroll/Items
@onready var scroll: ScrollContainer = $Layers/FrameContent/Scroll
@onready var scroll_up: TextureButton = $Layers/FrameContent/ScrollUp
@onready var scroll_down: TextureButton = $Layers/FrameContent/ScrollDown

const SCROLL_STEP := 100

var _signature := ""

func _ready() -> void:
	super()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	$Layers/Background.texture = UiAtlas.HUD_INVENTORY
	UiAtlas.configure_inventory_arrow(scroll_up, true)
	UiAtlas.configure_inventory_arrow(scroll_down, false)
	scroll_up.pressed.connect(_scroll_inventory.bind(-1))
	scroll_down.pressed.connect(_scroll_inventory.bind(1))
	scroll.get_v_scroll_bar().value_changed.connect(_on_scroll_changed)
	call_deferred("_update_scroll_buttons")

func set_inventory(inventory: InventoryState) -> void:
	var signature := _inventory_signature(inventory)
	if signature == _signature:
		return
	_signature = signature
	_rebuild(inventory)

func invalidate() -> void:
	_signature = ""

func _rebuild(inventory: InventoryState) -> void:
	for child in items.get_children():
		items.remove_child(child)
		child.queue_free()
	if inventory == null:
		_add_empty()
		call_deferred("_update_scroll_buttons")
		return
	var added := 0
	var fertilizer_ids := inventory.fertilizers.keys()
	fertilizer_ids.sort()
	for raw_id in fertilizer_ids:
		var count := int(inventory.fertilizers[raw_id])
		if count <= 0:
			continue
		var item_id := String(raw_id)
		var title := "Recycled Fertilizer" if item_id == String(RecyclingService.COMPOST_ID) else _pretty_id(item_id)
		_add_item(&"fertilizer", item_id, count, title)
		added += 1
	for cutting in inventory.cuttings:
		if cutting == null:
			continue
		_add_item(&"cutting", cutting.item_id, 1, _genetic_title("Branch", cutting.genome))
		added += 1
	for seed_state in inventory.seeds:
		if seed_state == null:
			continue
		_add_item(&"seed", seed_state.item_id, 1, _genetic_title("Seed", seed_state.genome))
		added += 1
	for fruit in inventory.fruits:
		if fruit == null:
			continue
		_add_item(&"fruit", fruit.item_id, 1, _genetic_title("Fruit", fruit.genome))
		added += 1
	var misc_ids := inventory.misc.keys()
	misc_ids.sort()
	for raw_id in misc_ids:
		var count := int(inventory.misc[raw_id])
		if count > 0:
			_add_item(&"misc", String(raw_id), count, _pretty_id(String(raw_id)))
			added += 1
	if added == 0:
		_add_empty()
	else:
		while added < 3:
			_add_empty_slot()
			added += 1
	call_deferred("_update_scroll_buttons")

func _scroll_inventory(direction: int) -> void:
	scroll.scroll_vertical += direction * SCROLL_STEP
	call_deferred("_update_scroll_buttons")

func _on_scroll_changed(_value: float) -> void:
	_update_scroll_buttons()

func _update_scroll_buttons() -> void:
	var bar := scroll.get_v_scroll_bar()
	scroll_up.disabled = scroll.scroll_vertical <= 0
	scroll_down.disabled = scroll.scroll_vertical >= int(maxf(0.0, bar.max_value - bar.page))

func _add_item(kind: StringName, item_id: String, count: int, title: String) -> void:
	var button := Button.new()
	_configure_fixed_slot(button)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.text = title + (" ×%d" % count if count > 1 else "")
	var texture := InventoryItemArt.texture_for(kind, item_id)
	if texture != null:
		button.icon = texture
		button.expand_icon = true
		button.text = ""
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_stylebox_override(&"normal", UiAtlas.panel_style(UiAtlas.background2(1), Vector4(14.0, 14.0, 14.0, 14.0)))
	button.add_theme_stylebox_override(&"hover", UiAtlas.panel_style(UiAtlas.background2(1), Vector4(14.0, 14.0, 14.0, 14.0)))
	button.add_theme_stylebox_override(&"pressed", UiAtlas.panel_style(UiAtlas.background2(1), Vector4(14.0, 14.0, 14.0, 14.0)))
	var count_suffix := ""
	if count > 1:
		count_suffix = " ×%d" % count
	button.tooltip_text = "%s%s · click for actions" % [title, count_suffix]
	button.mouse_entered.connect(_set_item_hover.bind(button, true))
	button.mouse_exited.connect(_set_item_hover.bind(button, false))
	button.pressed.connect(_emit_selected.bind(kind, item_id, count, title))
	items.add_child(button)

func _set_item_hover(button: Button, hovered: bool) -> void:
	if is_instance_valid(button):
		button.self_modulate = Color(1.18, 1.18, 1.08, 1.0) if hovered else Color.WHITE

func _add_empty() -> void:
	for index in range(3):
		_add_empty_slot("Inventory empty" if index == 0 else "")

func _add_empty_slot(label := "") -> void:
	var slot := Button.new()
	_configure_fixed_slot(slot)
	slot.text = label
	slot.disabled = true
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_theme_stylebox_override(&"disabled", UiAtlas.panel_style(UiAtlas.background2(1), Vector4(14.0, 14.0, 14.0, 14.0)))
	items.add_child(slot)

func _configure_fixed_slot(button: Button) -> void:
	button.custom_minimum_size = Vector2(124.0, 124.0)
	button.size = Vector2(124.0, 124.0)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.clip_contents = true
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

func _emit_selected(kind: StringName, item_id: String, count: int, title: String) -> void:
	item_selected.emit(kind, item_id, count, title)

func _genetic_title(prefix: String, genome: GenomeSnapshot) -> String:
	if genome == null or String(genome.species_id).is_empty():
		return prefix
	return "%s · %s" % [prefix, _pretty_id(String(genome.species_id))]

func _inventory_signature(inventory: InventoryState) -> String:
	if inventory == null:
		return "null"
	var parts: Array[String] = [str(inventory.fertilizers), str(inventory.misc)]
	for cutting in inventory.cuttings:
		parts.append("c:%s" % cutting.item_id)
	for seed_state in inventory.seeds:
		parts.append("s:%s" % seed_state.item_id)
	for fruit in inventory.fruits:
		parts.append("f:%s" % fruit.item_id)
	return "|".join(parts)

func _pretty_id(value: String) -> String:
	return value.replace("_", " ").capitalize()
