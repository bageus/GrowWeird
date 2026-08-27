class_name LeafPointLayout
extends RefCounted

const SLOTS: Array[StringName] = [&"left", &"center", &"right"]
const TREE_COUNT := 12
const LEAF_TEXTURE: Texture2D = preload("res://assets/leaf/leaf_normal_01.png")
const TREES: Array[Texture2D] = [preload("res://assets/tree/tree_01.png"), preload("res://assets/tree/tree_02.png"), preload("res://assets/tree/tree_03.png"), preload("res://assets/tree/tree_04.png"), preload("res://assets/tree/tree_05.png"), preload("res://assets/tree/tree_06.png"), preload("res://assets/tree/tree_07.png"), preload("res://assets/tree/tree_08.png"), preload("res://assets/tree/tree_09.png"), preload("res://assets/tree/tree_10.png"), preload("res://assets/tree/tree_11.png"), preload("res://assets/tree/tree_12.png")]

static func default_points(index: int) -> Dictionary:
	var points := {"left": [], "center": [], "right": []}
	if index < 4:
		points.center = [Vector2(0.50, 0.50)]
		return points
	points.center = [Vector2(0.50, 0.53), Vector2(0.50, 0.40), Vector2(0.50, 0.28)]
	points.left = [Vector2(0.40, 0.48), Vector2(0.32, 0.36)]
	points.right = [Vector2(0.60, 0.48), Vector2(0.68, 0.36)]
	if index >= 6:
		points.left.append(Vector2(0.25, 0.28))
		points.right.append(Vector2(0.75, 0.28))
	if index == 8:
		points.left.append(Vector2(0.36, 0.26))
	if index == 9:
		points.right.append(Vector2(0.64, 0.26))
	if index == 10:
		points.left.append(Vector2(0.34, 0.24))
		points.right.append(Vector2(0.66, 0.24))
	if index == 11:
		points.left = [Vector2(0.42, 0.48), Vector2(0.34, 0.37)]
		points.right = [Vector2(0.58, 0.48), Vector2(0.66, 0.37)]
	return points

static func points_code(points_by_tree: Dictionary) -> String:
	var lines: Array[String] = ["const LEAF_POINTS := {"]
	for index in TREE_COUNT:
		lines.append("\t\"tree_%02d\": {" % (index + 1))
		var points: Dictionary = points_by_tree.get(index, default_points(index))
		for slot in SLOTS:
			var encoded: Array[String] = []
			for point in points.get(String(slot), []):
				encoded.append("Vector2(%.4f, %.4f)" % [point.x, point.y])
			lines.append("\t\t\"%s\": [%s]," % [String(slot), ", ".join(encoded)])
		lines.append("\t},")
	lines.append("}")
	return "\n".join(lines)
