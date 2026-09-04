class_name LeafLayoutControls
extends VBoxContainer

@export var editor_node_name: StringName = &"LeafLayout"
@export var item_label := "Leaf"
@onready var toggle: Button = $Toggle
@onready var scale_variance: HSlider = $ScaleVariance
@onready var direction_variance: HSlider = $DirectionVariance
@onready var scale_value: Label = $ScaleValue
@onready var direction_value: Label = $DirectionValue
@onready var save_button: Button = $Save
var editor: LeafLayoutEditor
var _syncing := false

func _ready() -> void:
	add_to_group(&"placement_layout_controls")
	editor = get_tree().current_scene.find_child(String(editor_node_name), true, false) as LeafLayoutEditor
	if editor == null:
		push_error("%s layout editor was not found in the current scene" % item_label)
		set_process(false)
		return
	toggle.toggled.connect(_on_toggled)
	scale_variance.value_changed.connect(_on_variance_changed)
	direction_variance.value_changed.connect(_on_variance_changed)
	save_button.pressed.connect(_on_save_pressed)
	editor.selection_changed.connect(_on_selection_changed)
	_set_parameter_enabled(false)
	_update_labels()

func _on_toggled(enabled: bool) -> void:
	if enabled:
		for peer in get_tree().get_nodes_in_group(&"placement_layout_controls"):
			if peer != self:
				peer.deactivate_from_peer()
	toggle.text = "%s points: %s" % [item_label, "ON" if enabled else "OFF"]
	editor.set_editing(enabled)

func deactivate_from_peer() -> void:
	if not toggle.button_pressed:
		return
	toggle.set_pressed_no_signal(false)
	toggle.text = "%s points: OFF" % item_label
	editor.set_editing(false)

func _on_variance_changed(_value: float) -> void:
	_update_labels()
	if not _syncing:
		editor.set_selected_variance(scale_variance.value, direction_variance.value)

func _on_selection_changed(scale_percent: float, direction_percent: float, has_selection: bool) -> void:
	_syncing = true
	scale_variance.value = scale_percent
	direction_variance.value = direction_percent
	_syncing = false
	_set_parameter_enabled(has_selection)
	_update_labels()

func _on_save_pressed() -> void:
	save_button.text = "Saved" if editor.save_layout() else "Save failed"

func _set_parameter_enabled(enabled: bool) -> void:
	scale_variance.editable = enabled
	direction_variance.editable = enabled

func _update_labels() -> void:
	scale_value.text = "Random scale: %.0f%%" % scale_variance.value
	direction_value.text = "Direction error: %.1f%%" % direction_variance.value
