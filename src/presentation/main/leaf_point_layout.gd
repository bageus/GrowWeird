class_name LeafPointLayout
extends RefCounted

const SLOTS: Array[StringName] = [&"left", &"center", &"right"]
const TREE_COUNT := 12
const LEAF_TEXTURE: Texture2D = preload("res://assets/leaf/leaf_normal_01.png")
const TREES: Array[Texture2D] = [preload("res://assets/tree/tree_01.png"), preload("res://assets/tree/tree_02.png"), preload("res://assets/tree/tree_03.png"), preload("res://assets/tree/tree_04.png"), preload("res://assets/tree/tree_05.png"), preload("res://assets/tree/tree_06.png"), preload("res://assets/tree/tree_07.png"), preload("res://assets/tree/tree_08.png"), preload("res://assets/tree/tree_09.png"), preload("res://assets/tree/tree_10.png"), preload("res://assets/tree/tree_11.png"), preload("res://assets/tree/tree_12.png")]

static func default_points(index: int) -> Dictionary:
	var points := {"left": [], "center": [], "right": []}
	if index < 4:
		points.center = [_point(0.50, 0.50)]
		return points
	points.center = [_point(0.50, 0.53), _point(0.50, 0.40), _point(0.50, 0.28)]
	points.left = [_point(0.40, 0.48, -0.45), _point(0.32, 0.36, -0.55)]
	points.right = [_point(0.60, 0.48, 0.45), _point(0.68, 0.36, 0.55)]
	if index >= 6:
		points.left.append(_point(0.25, 0.28, -0.65))
		points.right.append(_point(0.75, 0.28, 0.65))
	if index == 8:
		points.left.append(_point(0.36, 0.26, -0.55))
	if index == 9:
		points.right.append(_point(0.64, 0.26, 0.55))
	if index == 10:
		points.left.append(_point(0.34, 0.24, -0.60))
		points.right.append(_point(0.66, 0.24, 0.60))
	if index == 11:
		points.left = [_point(0.42, 0.48, -0.40), _point(0.34, 0.37, -0.50)]
		points.right = [_point(0.58, 0.48, 0.40), _point(0.66, 0.37, 0.50)]
	return points

static func _point(x: float, y: float, direction_x := 0.0, direction_y := -0.35, leaf_size := 1.0) -> Dictionary:
	return {"position": Vector2(x, y), "size": leaf_size, "direction": Vector2(direction_x, direction_y)}

static func point(x: float, y: float, direction_x := 0.0, direction_y := -0.35, leaf_size := 1.0) -> Dictionary:
	return _point(x, y, direction_x, direction_y, leaf_size)

static func normalize_point(raw: Variant) -> Dictionary:
	if raw is Dictionary:
		var position: Variant = raw.get("position", Vector2(float(raw.get("x", 0.5)), float(raw.get("y", 0.5))))
		var direction: Variant = raw.get("direction", Vector2(float(raw.get("dx", 0.0)), float(raw.get("dy", -0.35))))
		return {"position": _vector(position, Vector2(0.5, 0.5)), "size": clampf(float(raw.get("size", 1.0)), 0.35, 2.0), "direction": _vector(direction, Vector2(0.0, -0.35))}
	if raw is Vector2:
		return _point(raw.x, raw.y)
	return _point(0.5, 0.5)

static func _vector(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is Dictionary:
		return Vector2(float(value.get("x", fallback.x)), float(value.get("y", fallback.y)))
	return fallback

static func points_code(points_by_tree: Dictionary) -> String:
	var lines: Array[String] = ["const LEAF_POINTS := {"]
	for index in TREE_COUNT:
		lines.append("\t\"tree_%02d\": {" % (index + 1))
		var points: Dictionary = points_by_tree.get(index, default_points(index))
		for slot in SLOTS:
			var encoded: Array[String] = []
			for raw in points.get(String(slot), []):
				var point: Dictionary = normalize_point(raw)
				encoded.append("{\"position\": Vector2(%.4f, %.4f), \"size\": %.4f, \"direction\": Vector2(%.4f, %.4f)}" % [point.position.x, point.position.y, point.size, point.direction.x, point.direction.y])
			lines.append("\t\t\"%s\": [%s]," % [String(slot), ", ".join(encoded)])
		lines.append("\t},")
	lines.append("}")
	return "\n".join(lines)
