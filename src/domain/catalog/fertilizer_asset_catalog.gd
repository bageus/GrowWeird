class_name FertilizerAssetCatalog
extends RefCounted

const FRAME_SIZE := 512
const FOOD_HEALTH := 0.02
const ID_PREFIX := "fertilizer_atlas_"
const MANIFEST_PATHS := [
	"res://assets/fertilizers/fertilizers_01.json",
	"res://assets/fertilizers/fertilizers_02.json",
]
const STAGE_ITEMS := [
	{"id": "seed_booster", "row": 1, "position": 1, "growth_cycle": &"seed", "shop_price": 12},
	{"id": "sprout_booster", "row": 1, "position": 2, "growth_cycle": &"sprout", "shop_price": 20},
	{"id": "flower_booster", "row": 1, "position": 3, "growth_cycle": &"flower", "shop_price": 50},
	{"id": "fruit_booster", "row": 2, "position": 1, "growth_cycle": &"fruit", "shop_price": 60},
	{"id": "restart_booster", "row": 2, "position": 2, "growth_cycle": &"branch", "shop_price": 40},
	{"id": "tree_booster", "row": 2, "position": 3, "growth_cycle": &"tree", "shop_price": 30},
]

static func definitions() -> Array[FertilizerDefinition]:
	var result: Array[FertilizerDefinition] = []
	for atlas_index in range(MANIFEST_PATHS.size() + 1):
		for item in _items_for_atlas(atlas_index):
			if _is_reserved_grind_result(atlas_index, item):
				continue
			var definition := FertilizerDefinition.new()
			definition.id = _offer_id(atlas_index, String(item.get("id", "")))
			definition.display_name_key = "fertilizer.%s" % String(item.get("id", ""))
			definition.offer_weight = 1.0
			definition.care_effects = {"health": FOOD_HEALTH}
			if atlas_index == 2:
				definition.shop_price = int(item.get("shop_price", 0))
				definition.care_effects["growth_cycle"] = item["growth_cycle"]
			else:
				_apply_balance(definition)
			result.append(definition)
	return result

static func _apply_balance(definition: FertilizerDefinition) -> void:
	var balance := ItemBalanceCatalog.get(definition.id)
	if balance.is_empty():
		return
	definition.display_name = String(balance.get("display_name", ""))
	definition.sell_price = int(balance.get("sell_price", 0))
	definition.recycle_yield = int(balance.get("grind_yield", 0))
	definition.drop_chance = clampf(float(balance.get("drop_chance_percent", 0.0)) / 100.0, 0.0, 1.0)
	# Offer generation is weighted, so the configured drop percentage is used as its weight.
	# Zero-drop reward/processed items are therefore excluded from random offers.
	definition.offer_weight = float(balance.get("drop_chance_percent", 0.0))
	definition.rarity = String(balance.get("rarity", ""))
	definition.target = String(balance.get("target", ""))
	definition.effect_description = String(balance.get("effect", ""))
	var food: Variant = balance.get("food", 0)
	if food is int or food is float:
		definition.care_effects["nutrition_points"] = float(food)

static func id_for(atlas_index: int, row: int, column: int) -> StringName:
	for item in _items_for_atlas(atlas_index):
		if int(item.get("row", 0)) == row + 1 and int(item.get("position", 0)) == column + 1:
			return _offer_id(atlas_index, String(item.get("id", "")))
	return &""

static func descriptor_for(id: StringName) -> Dictionary:
	for atlas_index in range(MANIFEST_PATHS.size() + 1):
		for item in _items_for_atlas(atlas_index):
			if _is_reserved_grind_result(atlas_index, item):
				continue
			if _offer_id(atlas_index, String(item.get("id", ""))) == id:
				var balance := ItemBalanceCatalog.get(id)
				return {
					"atlas_index": atlas_index,
					"row": int(item.get("row", 1)) - 1,
					"column": int(item.get("position", 1)) - 1,
					"item_id": StringName(item.get("id", "")),
					"display_name": balance.get("display_name", ""),
				}
	return {}

static func is_offer_id(id: StringName) -> bool:
	return not descriptor_for(id).is_empty()

static func _items_for_atlas(atlas_index: int) -> Array:
	if atlas_index == 2:
		return STAGE_ITEMS
	if atlas_index < 0 or atlas_index >= MANIFEST_PATHS.size():
		return []
	var file := FileAccess.open(MANIFEST_PATHS[atlas_index], FileAccess.READ)
	if file == null:
		push_error("Fertilizer atlas manifest not found: %s" % MANIFEST_PATHS[atlas_index])
		return []
	var data: Variant = JSON.parse_string(file.get_as_text())
	if not data is Dictionary:
		push_error("Invalid fertilizer atlas manifest: %s" % MANIFEST_PATHS[atlas_index])
		return []
	var items: Variant = data.get("items", [])
	return items if items is Array else []

static func _offer_id(atlas_index: int, item_id: String) -> StringName:
	return StringName("%s%d_%s" % [ID_PREFIX, atlas_index + 1, item_id])

static func _is_reserved_grind_result(atlas_index: int, item: Dictionary) -> bool:
	if atlas_index != 1:
		return false
	var row := int(item.get("row", 0))
	var position := int(item.get("position", 0))
	return (row == 1 and position == 6) or (row == 4 and position == 1)
