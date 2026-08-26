class_name GardenDebugController
extends RefCounted

var garden_art: GardenArtView
var event_label: Label
var panel: VBoxContainer
var buttons: Array[Button] = []

func setup(art: GardenArtView, tools: VBoxContainer, events: Label) -> void:
	garden_art = art
	event_label = events
	panel = VBoxContainer.new()
	panel.name = "GardenPreviewControls"
	panel.add_theme_constant_override("separation", 4)
	tools.add_child(panel)
	tools.move_child(panel, maxi(0, tools.get_child_count() - 2))
	var title := Label.new()
	title.text = "Garden preview"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)
	_add_button("Pot ←", _on_pot_left_pressed)
	_add_button("Pot →", _on_pot_right_pressed)
	_add_button("Water soil", _on_wet_pressed)
	_add_button("Dry soil", _on_dry_pressed)
	_add_button("Prune branches", _on_prune_pressed)
	_add_button("Undo prune", _on_unprune_pressed)
	_add_button("Tree −", _on_tree_down_pressed)
	_add_button("Tree +", _on_tree_up_pressed)
	garden_art.debug_changed.connect(refresh)
	refresh()

func _add_button(text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	panel.add_child(button)
	buttons.append(button)

func refresh() -> void:
	buttons[0].disabled = garden_art.get_pot_index() <= 0
	buttons[1].disabled = garden_art.get_pot_index() >= garden_art.pot_count() - 1
	buttons[2].disabled = garden_art.get_ground_index() >= garden_art.ground_count() - 1
	buttons[3].disabled = garden_art.get_ground_index() <= 0
	buttons[4].disabled = garden_art.is_pruned()
	buttons[5].disabled = not garden_art.is_pruned()
	buttons[6].disabled = garden_art.get_tree_index() <= 0
	buttons[7].disabled = garden_art.get_tree_index() >= garden_art.tree_count() - 1

func _on_pot_left_pressed() -> void:
	garden_art.set_pot_index(garden_art.get_pot_index() - 1)

func _on_pot_right_pressed() -> void:
	garden_art.set_pot_index(garden_art.get_pot_index() + 1)

func _on_wet_pressed() -> void:
	garden_art.set_ground_index(garden_art.get_ground_index() + 1)
	event_label.text = "Garden preview: soil moisture increased."

func _on_dry_pressed() -> void:
	garden_art.set_ground_index(garden_art.get_ground_index() - 1)
	event_label.text = "Garden preview: soil moisture decreased."

func _on_prune_pressed() -> void:
	garden_art.set_prune_mode(true)
	event_label.text = "Prune preview: hover a branch, then click it."

func _on_unprune_pressed() -> void:
	garden_art.set_pruned(false)
	event_label.text = "Prune preview reset."

func _on_tree_down_pressed() -> void:
	garden_art.set_tree_index(garden_art.get_tree_index() - 1)

func _on_tree_up_pressed() -> void:
	garden_art.set_tree_index(garden_art.get_tree_index() + 1)
