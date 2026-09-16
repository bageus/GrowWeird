class_name PlantAtlasArt
extends RefCounted

const FLOWERS: Texture2D = preload("res://assets/flower/flowers_01.png")
const FRUITS: Texture2D = preload("res://assets/fruit/fruits_01.png")
const FLOWER_COLUMNS := 6
const FLOWER_ROWS := 4
const FRUIT_COLUMNS := 3
const FRUIT_ROWS := 2

static func flower_texture(index: int) -> AtlasTexture:
	return _cell(FLOWERS, FLOWER_COLUMNS, FLOWER_ROWS, posmod(index, FLOWER_COLUMNS * FLOWER_ROWS))

static func fruit_texture(index: int, ripe: bool) -> AtlasTexture:
	var row := posmod(index, FRUIT_ROWS)
	var column := 1 + posmod(index / FRUIT_ROWS, FRUIT_COLUMNS - 1) if ripe else 0
	return _cell(FRUITS, FRUIT_COLUMNS, FRUIT_ROWS, row * FRUIT_COLUMNS + column)

static func stable_index(seed_text: String, count: int) -> int:
	return posmod(seed_text.hash(), count)

static func _cell(texture: Texture2D, columns: int, rows: int, index: int) -> AtlasTexture:
	var cell_size := Vector2(texture.get_width() / float(columns), texture.get_height() / float(rows))
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(Vector2(index % columns, index / columns) * cell_size, cell_size)
	return atlas
