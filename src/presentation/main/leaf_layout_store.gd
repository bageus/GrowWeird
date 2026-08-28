class_name LeafLayoutStore
extends RefCounted

static func load(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not data is Dictionary:
		return {}
	var source: Variant = data.get("points", data)
	if not source is Dictionary:
		return {}
	var result := {}
	for index in LeafPointLayout.TREE_COUNT:
		var values: Variant = source.get(str(index), null)
		if values is Dictionary:
			result[index] = _normalize_tree(values)
	return result

static func save(path: String, points_by_tree: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"points": LeafPointLayout.serializable_points(points_by_tree)}))
	file.close()

static func _normalize_tree(values: Dictionary) -> Dictionary:
	var result := {"left": [], "center": [], "right": []}
	for slot in LeafPointLayout.SLOTS:
		for raw in values.get(String(slot), []):
			result[String(slot)].append(LeafPointLayout.normalize_point(raw))
	return result
