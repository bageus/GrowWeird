extends RefCounted

static func verify() -> Array[String]:
	var failures: Array[String] = []
	var view := FileAccess.get_file_as_string("res://src/presentation/plant/plant_view.gd")
	if not view.contains("PlantAtlasArt.fruit_texture(_plant.fruit_visual_line, mutation_column, ripe)"):
		failures.append("plant atlas hover: fruit must render one mutation atlas cell")
	if not view.contains("PlantAtlasArt.flower_texture(_plant.flower_visual_line, mutation_column)"):
		failures.append("plant atlas hover: flower must render one mutation atlas cell")
	if not view.contains("_visual_candidate_at(event.position)") or not view.contains("_hovered_visual_kind"):
		failures.append("plant atlas hover: fruit and flower hover must work outside action modes")
	return failures
