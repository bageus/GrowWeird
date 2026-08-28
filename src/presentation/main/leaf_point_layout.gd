class_name LeafPointLayout
extends RefCounted

const SLOTS: Array[StringName] = [&"left", &"center", &"right"]
const TREE_COUNT := 12
const LEAF_FRAME_SIZE := 512
const LEAF_TEXTURES: Array[Texture2D] = [
	preload("res://assets/leaf/leaf_normal_01.png"),
	preload("res://assets/leaf/leaf_normal_02.png"),
	preload("res://assets/leaf/leaf_normal_03.png"),
	preload("res://assets/leaf/leaf_normal_04.png"),
	preload("res://assets/leaf/leaf_normal_05.png"),
	preload("res://assets/leaf/leaf_normal_06.png"),
	preload("res://assets/leaf/leaf_normal_07.png"),
	preload("res://assets/leaf/leaf_normal_08.png"),
	preload("res://assets/leaf/leaf_normal_09.png"),
]
const TREES: Array[Texture2D] = [
	preload("res://assets/tree/tree_01.png"), preload("res://assets/tree/tree_02.png"),
	preload("res://assets/tree/tree_03.png"), preload("res://assets/tree/tree_04.png"),
	preload("res://assets/tree/tree_05.png"), preload("res://assets/tree/tree_06.png"),
	preload("res://assets/tree/tree_07.png"), preload("res://assets/tree/tree_08.png"),
	preload("res://assets/tree/tree_09.png"), preload("res://assets/tree/tree_10.png"),
	preload("res://assets/tree/tree_11.png"), preload("res://assets/tree/tree_12.png"),
]

static func default_points(index: int) -> Dictionary:
	var points := {"left": [], "center": [], "right": []}
	if index < 4:
		points.center = [_point(0.50, 0.50)]
		return points
	points.center = [_point(0.50, 0.53), _point(0.50, 0.40), _point(0.50, 0.28)]
	points.left = [_point(0.40, 0.48, -0.90, 1.0, 0, 0, true), _point(0.32, 0.36, -1.00, 1.0, 0, 1, true)]
	points.right = [_point(0.60, 0.48, 0.90, 1.0, 0, 0), _point(0.68, 0.36, 1.00, 1.0, 0, 1)]
	if index >= 6:
		points.left.append(_point(0.25, 0.28, -1.05, 0.94, 0, 2, true))
		points.right.append(_point(0.75, 0.28, 1.05, 0.94, 0, 2))
	if index == 8:
		points.left.append(_point(0.36, 0.26, -0.90, 0.90, 0, 3, true))
	if index == 9:
		points.right.append(_point(0.64, 0.26, 0.90, 0.90, 0, 3))
	if index == 10:
		points.left.append(_point(0.34, 0.24, -0.98, 0.90, 0, 4, true))
		points.right.append(_point(0.66, 0.24, 0.98, 0.90, 0, 4))
	if index == 11:
		points.left = [_point(0.42, 0.48, -0.82, 1.0, 0, 0, true), _point(0.34, 0.37, -0.94, 0.96, 0, 1, true)]
		points.right = [_point(0.58, 0.48, 0.82, 1.0), _point(0.66, 0.37, 0.94, 0.96, 0, 1)]
	return points

static func point(x: float, y: float, rotation := 0.0, leaf_size := 1.0, asset := 0, frame := 0, mirrored := false) -> Dictionary:
	return _point(x, y, rotation, leaf_size, asset, frame, mirrored)

static func _point(x: float, y: float, rotation := 0.0, leaf_size := 1.0, asset := 0, frame := 0, mirrored := false) -> Dictionary:
	return {
		"position": Vector2(x, y), "rotation": rotation, "size": leaf_size,
		"asset": asset, "frame": frame, "mirrored": mirrored,
	}

static func normalize_point(raw: Variant) -> Dictionary:
	if raw is Vector2:
		return _point(raw.x, raw.y)
	if not raw is Dictionary:
		return _point(0.5, 0.5)
	var position: Variant = raw.get("position", Vector2(float(raw.get("x", 0.5)), float(raw.get("y", 0.5))))
	var legacy_direction := _vector(raw.get("direction", Vector2(float(raw.get("dx", 0.0)), float(raw.get("dy", -0.35)))), Vector2.UP)
	var rotation := float(raw.get("rotation", legacy_direction.angle() + PI * 0.5))
	var mirrored := bool(raw.get("mirrored", legacy_direction.x < 0.0))
	return {
		"position": _vector(position, Vector2(0.5, 0.5)),
		"rotation": rotation,
		"size": clampf(float(raw.get("size", 1.0)), 0.35, 2.0),
		"asset": clampi(int(raw.get("asset", 0)), 0, LEAF_TEXTURES.size() - 1),
		"frame": maxi(0, int(raw.get("frame", 0))),
		"mirrored": mirrored,
	}

static func serializable_points(points_by_tree: Dictionary) -> Dictionary:
	var result := {}
	for index in TREE_COUNT:
		var tree_points: Dictionary = points_by_tree.get(index, default_points(index))
		var encoded_tree := {}
		for slot in SLOTS:
			var encoded: Array[Dictionary] = []
			for raw in tree_points.get(String(slot), []):
				var item := normalize_point(raw)
				encoded.append({
					"position": {"x": item.position.x, "y": item.position.y},
					"rotation": item.rotation, "size": item.size, "asset": item.asset,
					"frame": item.frame, "mirrored": item.mirrored,
				})
			encoded_tree[String(slot)] = encoded
		result[str(index)] = encoded_tree
	return result

static func points_code(points_by_tree: Dictionary) -> String:
	var lines: Array[String] = ["const LEAF_POINTS := {"]
	for index in TREE_COUNT:
		lines.append("\t\"tree_%02d\": {" % (index + 1))
		var tree_points: Dictionary = points_by_tree.get(index, default_points(index))
		for slot in SLOTS:
			var encoded: Array[String] = []
			for raw in tree_points.get(String(slot), []):
				var item := normalize_point(raw)
				encoded.append("{\"position\": Vector2(%.4f, %.4f), \"rotation\": %.4f, \"size\": %.4f, \"asset\": %d, \"frame\": %d, \"mirrored\": %s}" % [item.position.x, item.position.y, item.rotation, item.size, item.asset, item.frame, str(item.mirrored)])
			lines.append("\t\t\"%s\": [%s]," % [String(slot), ", ".join(encoded)])
		lines.append("\t},")
	lines.append("}")
	return "\n".join(lines)

static func frame_count(asset: int) -> int:
	var texture := LEAF_TEXTURES[clampi(asset, 0, LEAF_TEXTURES.size() - 1)]
	return maxi(1, int(texture.get_width() / LEAF_FRAME_SIZE))

static func _vector(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is Dictionary:
		return Vector2(float(value.get("x", fallback.x)), float(value.get("y", fallback.y)))
	return fallback
