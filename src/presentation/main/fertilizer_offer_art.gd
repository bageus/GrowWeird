class_name FertilizerOfferArt
extends RefCounted

const ATLAS_TEXTURES := [
	preload("res://assets/fertilizers/fertilizers_01.png"),
	preload("res://assets/fertilizers/fertilizers_02.png"),
]
const LEGACY_TEXTURES := [
	preload("res://assets/fertilizers/fertilizers_03.png"),
	preload("res://assets/fertilizers/fertilizers_04.png"),
	preload("res://assets/fertilizers/fertilizers_05.png"),
	preload("res://assets/fertilizers/fertilizers_06.png"),
]

static func texture_for(id: StringName) -> Texture2D:
	var descriptor := FertilizerAssetCatalog.descriptor_for(id)
	if descriptor.is_empty():
		return LEGACY_TEXTURES[posmod(int(String(id).hash()), LEGACY_TEXTURES.size())]
	var texture := AtlasTexture.new()
	texture.atlas = ATLAS_TEXTURES[int(descriptor["atlas_index"])]
	texture.region = Rect2(
		float(int(descriptor["column"]) * FertilizerAssetCatalog.FRAME_SIZE),
		float(int(descriptor["row"]) * FertilizerAssetCatalog.FRAME_SIZE),
		FertilizerAssetCatalog.FRAME_SIZE,
		FertilizerAssetCatalog.FRAME_SIZE
	)
	return texture
