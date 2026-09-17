extends SceneTree

func _init() -> void:
	var source := FileAccess.get_file_as_string("res://src/presentation/plant/plant_view.gd")
	var failures: Array[String] = []
	if not source.contains("PlantAtlasArt.fruit_texture(_plant.fruit_visual_line, mutation_column, ripe)"):
		failures.append("fruit renderer must request one atlas cell with line, mutation column and ripe state")
	if not source.contains("PlantAtlasArt.flower_texture(_plant.flower_visual_line, mutation_column)"):
		failures.append("flower renderer must request one atlas cell with persistent line and mutation column")
	if source.contains("PlantAtlasArt.fruit_texture(PlantAtlasArt.stable_index(seed, 4), ripe)"):
		failures.append("legacy fruit call must not pass ripe as mutation column")
	if not source.contains("_visual_candidate_at(event.position)"):
		failures.append("normal mouse motion must hit-test flower and fruit visuals")
	if source.contains("if _interaction_mode == MODE_NONE: return"):
		failures.append("normal mode must not disable flower and fruit hover")
	if not source.contains("_hovered_visual_kind") or not source.contains("draw_arc(center"):
		failures.append("flower and fruit hover must have visible feedback")
	if failures.is_empty():
		print("plant atlas cell/hover contract: PASS")
		quit(0)
		return
	for failure in failures: push_error(failure)
	quit(1)
