class_name FertilizerAssetCatalog
extends RefCounted

const ATLAS_COUNT := 2
const GRID_SIZE := 8
const FRAME_SIZE := 512
const FOOD_HEALTH := 0.02
const ID_PREFIX := "fertilizer_atlas_"

static func definitions() -> Array[FertilizerDefinition]:
	var result: Array[FertilizerDefinition] = []
	for atlas_index in range(ATLAS_COUNT):
		for row in range(GRID_SIZE):
			for column in range(GRID_SIZE):
				if _is_reserved_grind_result(atlas_index, row, column):
					continue
				var definition := FertilizerDefinition.new()
				definition.id = id_for(atlas_index, row, column)
				definition.display_name_key = "fertilizer.atlas_item"
				definition.offer_weight = 1.0
				definition.care_effects = {"health": FOOD_HEALTH}
				result.append(definition)
	return result

static func id_for(atlas_index: int, row: int, column: int) -> StringName:
	return StringName("%s%d_r%d_c%d" % [ID_PREFIX, atlas_index + 1, row + 1, column + 1])

static func descriptor_for(id: StringName) -> Dictionary:
	var value := String(id)
	if not value.begins_with(ID_PREFIX):
		return {}
	var parts := value.trim_prefix(ID_PREFIX).split("_")
	if parts.size() != 3 or not parts[1].begins_with("r") or not parts[2].begins_with("c"):
		return {}
	var atlas_index := int(parts[0]) - 1
	var row := int(parts[1].trim_prefix("r")) - 1
	var column := int(parts[2].trim_prefix("c")) - 1
	if atlas_index < 0 or atlas_index >= ATLAS_COUNT:
		return {}
	if row < 0 or row >= GRID_SIZE or column < 0 or column >= GRID_SIZE:
		return {}
	if _is_reserved_grind_result(atlas_index, row, column):
		return {}
	return {"atlas_index": atlas_index, "row": row, "column": column}

static func is_offer_id(id: StringName) -> bool:
	return not descriptor_for(id).is_empty()

static func _is_reserved_grind_result(atlas_index: int, row: int, column: int) -> bool:
	return atlas_index == 1 and ((row == 0 and column == 5) or (row == 3 and column == 0))
