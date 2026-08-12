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
	var bloom_level := int(traits.get("bloom", 0)) + int(traits.get("lure_bloom", 0)) + int(traits.get("luminous_bloom", 0))
	var glow_level := int(traits.get("glow", 0)) + int(traits.get("luminous_bloom", 0)) + int(traits.get("luminous_fungus", 0))
	var fungal_level := int(traits.get("fungi", 0)) + int(traits.get("luminous_fungus", 0)) + int(traits.get("spore_trap", 0))
	var bark_level := int(traits.get("bark_armor", 0))
	var crystal_level := int(traits.get("crystal_thorns", 0))

	if glow_level > 0:
		draw_circle(Vector2(center_x, size.y * 0.48), 17.0, Color(0.45, 0.96, 0.68, 0.18))
	var trunk_width := 4.0 + minf(float(bark_level), 3.0)
	draw_line(base, top, Color(0.36, 0.22, 0.12), trunk_width, true)
	draw_line(Vector2(center_x, size.y * 0.54), Vector2(size.x * 0.24, size.y * 0.40), Color(0.36, 0.22, 0.12), 3.0, true)
	draw_line(Vector2(center_x, size.y * 0.54), Vector2(size.x * 0.76, size.y * 0.40), Color(0.36, 0.22, 0.12), 3.0, true)
	draw_circle(Vector2(size.x * 0.22, size.y * 0.36), 5.0, Color(0.22, 0.58, 0.24))
	draw_circle(Vector2(size.x * 0.78, size.y * 0.36), 5.0, Color(0.22, 0.58, 0.24))

	_draw_thorns(center_x, thorn_level, Color(0.20, 0.13, 0.09))
	_draw_thorns(center_x, crystal_level, Color(0.48, 0.86, 0.92), 1.5)
	if fungal_level > 0:
		var count := mini(4, fungal_level + 1)
		for index in range(count):
			var y := size.y * (0.43 + 0.10 * float(index))
			var x := center_x + (-7.0 if index % 2 == 0 else 7.0)
			draw_circle(Vector2(x, y), 3.2, Color(0.55, 0.31, 0.55))
	if bloom_level > 0:
		var flower_center := top + Vector2(0.0, -2.0)
		for index in range(5):
			var angle := TAU * float(index) / 5.0
			draw_circle(flower_center + Vector2(cos(angle), sin(angle)) * 5.0, 3.5, Color(0.88, 0.39, 0.55))
		draw_circle(flower_center, 2.5, Color(0.96, 0.79, 0.24))

func _draw_thorns(center_x: float, level: int, color: Color, scale: float = 1.0) -> void:
	if level <= 0:
		return
	for index in range(mini(4, level + 1)):
		var y := size.y * (0.38 + 0.11 * float(index))
		var side := -1.0 if index % 2 == 0 else 1.0
		draw_line(
			Vector2(center_x, y),
			Vector2(center_x + side * 9.0 * scale, y - 5.0 * scale),
			color,
			2.0,
			true
		)
