class_name GeneticItemPreview
extends Control

var _genome: GenomeSnapshot

func set_genome(genome: GenomeSnapshot) -> void:
	_genome = genome
	queue_redraw()

func _ready() -> void:
	custom_minimum_size = Vector2(42.0, 42.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	var center_x := size.x * 0.5
	var base := Vector2(center_x, size.y * 0.86)
	var top := Vector2(center_x, size.y * 0.22)
	var traits := _genome.traits if _genome != null else {}
	var thorn_level := int(traits.get("thorns", 0))
	var bloom_level := int(traits.get("bloom", 0))
	var glow_level := int(traits.get("glow", 0))

	if glow_level > 0:
		draw_circle(Vector2(center_x, size.y * 0.48), 17.0, Color(0.45, 0.96, 0.68, 0.18))
	draw_line(base, top, Color(0.36, 0.22, 0.12), 4.0, true)
	draw_line(Vector2(center_x, size.y * 0.54), Vector2(size.x * 0.24, size.y * 0.40), Color(0.36, 0.22, 0.12), 3.0, true)
	draw_line(Vector2(center_x, size.y * 0.54), Vector2(size.x * 0.76, size.y * 0.40), Color(0.36, 0.22, 0.12), 3.0, true)
	draw_circle(Vector2(size.x * 0.22, size.y * 0.36), 5.0, Color(0.22, 0.58, 0.24))
	draw_circle(Vector2(size.x * 0.78, size.y * 0.36), 5.0, Color(0.22, 0.58, 0.24))

	if thorn_level > 0:
		for index in range(mini(4, thorn_level + 1)):
			var y := size.y * (0.38 + 0.11 * float(index))
			var side := -1.0 if index % 2 == 0 else 1.0
			draw_line(
				Vector2(center_x, y),
				Vector2(center_x + side * 9.0, y - 5.0),
				Color(0.20, 0.13, 0.09),
				2.0,
				true
			)

	if bloom_level > 0:
		var flower_center := top + Vector2(0.0, -2.0)
		for index in range(5):
			var angle := TAU * float(index) / 5.0
			draw_circle(flower_center + Vector2(cos(angle), sin(angle)) * 5.0, 3.5, Color(0.88, 0.39, 0.55))
		draw_circle(flower_center, 2.5, Color(0.96, 0.79, 0.24))
