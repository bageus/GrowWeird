class_name InventoryItemArt
extends RefCounted

const FERTILIZERS_02: Texture2D = preload("res://assets/fertilizers/fertilizers_02.png")
const SEEDS: Texture2D = preload("res://assets/tree/seeds.png")
const REGIONS := {
	"fertilizer:universal_fertilizer": Vector2i(0, 5),
	"fertilizer:compost_mix": Vector2i(3, 0),
	"misc:dead_mouse": Vector2i(2, 5),
}

static func texture_for(kind: StringName, item_id: String) -> Texture2D:
	if kind == &"seed":
		var seed_texture := AtlasTexture.new()
		var frame := posmod(item_id.hash(), 8)
		seed_texture.atlas = SEEDS
		seed_texture.region = Rect2((frame % 4) * 512, floori(float(frame) / 4.0) * 512, 512, 512)
		return seed_texture
	if kind == &"fertilizer" and FertilizerAssetCatalog.is_offer_id(StringName(item_id)):
		return FertilizerOfferArt.texture_for(StringName(item_id))
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
