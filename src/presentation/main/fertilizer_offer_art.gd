class_name FertilizerOfferArt
extends RefCounted

const TEXTURES := [
	preload("res://assets/fertilizers/fertilizers_01.png"),
	preload("res://assets/fertilizers/fertilizers_02.png"),
	preload("res://assets/fertilizers/fertilizers_03.png"),
	preload("res://assets/fertilizers/fertilizers_04.png"),
	preload("res://assets/fertilizers/fertilizers_05.png"),
	preload("res://assets/fertilizers/fertilizers_06.png"),
]

static func texture_for(id: StringName) -> Texture2D:
	return TEXTURES[posmod(int(String(id).hash()), TEXTURES.size())]
