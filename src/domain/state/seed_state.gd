class_name SeedState
extends RefCounted

var item_id: String = ""
var source_plant_id: String = ""
var genome: GenomeSnapshot
var visual_frame: int = -1

func ensure_visual_frame() -> void:
	if visual_frame < 0 or visual_frame > 7:
		visual_frame = posmod(item_id.hash(), 8)
