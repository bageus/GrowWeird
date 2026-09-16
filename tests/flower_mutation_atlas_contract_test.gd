extends SceneTree

func _init() -> void:
	var atlas := FileAccess.get_file_as_string("res://src/presentation/plant/plant_atlas_art.gd")
	var view := FileAccess.get_file_as_string("res://src/presentation/plant/plant_view.gd")
	var ok := atlas.contains("FLOWER_COLUMNS := 9") \
		and atlas.contains("FLOWER_ROWS := 16") \
		and atlas.contains("FLOWER_CELL := 256.0") \
		and atlas.contains("FLOWER_POISONOUS := 0") \
		and atlas.contains("FLOWER_NORMAL := 1") \
		and atlas.contains("FLOWER_DRAGON := 8") \
		and view.contains("flower_line(_plant.instance_id)") \
		and view.contains("flower_mutation_column(branch)")
	if not ok:
		push_error("flower mutation atlas contract is incomplete")
		quit(1)
		return
	print("Flower mutation atlas contract passed")
	quit(0)
