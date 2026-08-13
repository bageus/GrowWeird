class_name BranchMutationRenderer
extends RefCounted

static func draw_hooks(canvas: CanvasItem, start: Vector2, end: Vector2, phenotype: Dictionary) -> void:
	var count := int(phenotype.get("hook_count", 0))
	if count <= 0:
		return
	var vector := end - start
	var normal := Vector2(-vector.y, vector.x) / maxf(vector.length(), 1.0)
	var scale := float(phenotype.get("hook_scale", 1.0))
	for index in range(count):
		var t := (float(index) + 1.0) / (float(count) + 1.0)
		var side := -1.0 if index % 2 == 0 else 1.0
		var root := start.lerp(end, t)
		var tip := root + normal * side * 11.0 * scale
		canvas.draw_line(root, tip, Color(0.20, 0.12, 0.09), 3.0, true)
		canvas.draw_arc(tip, 4.5 * scale, 0.1 if side > 0.0 else PI, PI * 1.25 if side > 0.0 else PI * 2.25, 7, Color(0.26, 0.11, 0.10), 2.5, true)

static func draw_mineral_nodes(canvas: CanvasItem, start: Vector2, end: Vector2, phenotype: Dictionary) -> void:
	var count := int(phenotype.get("mineral_node_count", 0))
	if count <= 0:
		return
	var scale := float(phenotype.get("mineral_node_scale", 1.0))
	for index in range(count):
		var t := (float(index) + 1.0) / (float(count) + 1.0)
		var center := start.lerp(end, t)
		var radius := 3.5 * scale
		canvas.draw_circle(center, radius + 2.0, Color(0.18, 0.15, 0.13, 0.65))
		canvas.draw_colored_polygon(PackedVector2Array([
			center + Vector2(0.0, -radius), center + Vector2(radius, 0.0),
			center + Vector2(0.0, radius), center + Vector2(-radius, 0.0),
		]), Color(0.66, 0.70, 0.72))

static func draw_toxic_sacs(canvas: CanvasItem, start: Vector2, end: Vector2, phenotype: Dictionary, vitality: float) -> void:
	var count := int(phenotype.get("toxic_sac_count", 0))
	if count <= 0:
		return
	var vector := end - start
	var normal := Vector2(-vector.y, vector.x) / maxf(vector.length(), 1.0)
	var scale := float(phenotype.get("toxic_sac_scale", 1.0))
	for index in range(count):
		var t := 0.28 + (float(index) / maxf(float(count), 1.0)) * 0.62
		var side := -1.0 if index % 2 == 0 else 1.0
		var center := start.lerp(end, t) + normal * side * 12.0 * scale
		var color := Color(0.72, 0.78, 0.12).lerp(Color(0.36, 0.22, 0.18), 1.0 - vitality)
		canvas.draw_circle(center, 7.0 * scale, Color(color.r, color.g, color.b, 0.22))
		canvas.draw_circle(center, 4.2 * scale, color)
		canvas.draw_circle(center + Vector2(-1.2, -1.2), 1.2 * scale, Color(0.93, 1.0, 0.54, vitality))

static func draw_reveal(canvas: CanvasItem, start: Vector2, end: Vector2, strength: float) -> void:
	if strength <= 0.0:
		return
	var eased := clampf(strength, 0.0, 1.0)
	var center := start.lerp(end, 0.72)
	var radius := lerpf(34.0, 12.0, eased)
	canvas.draw_line(start, end, Color(0.96, 0.88, 0.38, eased * 0.30), 20.0 * eased, true)
	canvas.draw_arc(center, radius, 0.0, TAU, 28, Color(1.0, 0.92, 0.44, eased * 0.88), 2.5 + 3.0 * eased, true)
