class_name InventoryItemArt
extends RefCounted

const FERTILIZERS_02: Texture2D = preload("res://assets/fertilizers/fertilizers_02.png")
const REGIONS := {
	"fertilizer:universal_fertilizer": Vector2i(0, 5),
	"fertilizer:compost_mix": Vector2i(3, 0),
	"misc:dead_mouse": Vector2i(2, 5),
}

static func texture_for(kind: StringName, item_id: String) -> Texture2D:
	var cell: Variant = REGIONS.get("%s:%s" % [kind, item_id])
	if not cell is Vector2i:
		return null
	var position: Vector2i = cell
	var texture := AtlasTexture.new()
	texture.atlas = FERTILIZERS_02
	texture.region = Rect2(
		position.y * FertilizerAssetCatalog.FRAME_SIZE,
		position.x * FertilizerAssetCatalog.FRAME_SIZE,
		FertilizerAssetCatalog.FRAME_SIZE,
		FertilizerAssetCatalog.FRAME_SIZE
	)
	return texture
