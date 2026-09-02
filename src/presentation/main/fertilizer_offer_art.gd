class_name FertilizerOfferArt
extends RefCounted

const ATLAS_TEXTURES := [
	preload("res://assets/fertilizers/fertilizers_01.png"),
	preload("res://assets/fertilizers/fertilizers_02.png"),
]

static func texture_for(id: StringName) -> Texture2D:
	var descriptor := FertilizerAssetCatalog.descriptor_for(id)
	if descriptor.is_empty():
		descriptor = _fallback_descriptor(id)
	var texture := AtlasTexture.new()
	texture.atlas = ATLAS_TEXTURES[int(descriptor["atlas_index"])]
	texture.region = Rect2(
		float(int(descriptor["column"]) * FertilizerAssetCatalog.FRAME_SIZE),
		float(int(descriptor["row"]) * FertilizerAssetCatalog.FRAME_SIZE),
		FertilizerAssetCatalog.FRAME_SIZE,
		FertilizerAssetCatalog.FRAME_SIZE
	)
	return texture

static func _fallback_descriptor(id: StringName) -> Dictionary:
	var hash_value := posmod(int(String(id).hash()), 126)
	var atlas_index := 0 if hash_value < 64 else 1
	var local_index := hash_value if atlas_index == 0 else hash_value - 64
	return {
		"atlas_index": atlas_index,
		"row": floori(float(local_index) / 8.0),
		"column": local_index % 8,
	}
