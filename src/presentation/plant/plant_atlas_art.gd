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
	# The source sheets contain square art cells. Deriving width and height
	# independently can include padding/gutters in a region and makes the old
	# simple red fruit marker visible instead of the intended atlas artwork.
	var cell_side := minf(texture.get_width() / float(columns), texture.get_height() / float(rows))
	var cell_size := Vector2(cell_side, cell_side)
	var sheet_size := Vector2(texture.get_width(), texture.get_height())
	var grid_size := Vector2(cell_side * columns, cell_side * rows)
	var grid_origin := (sheet_size - grid_size) * 0.5
	var cell := Vector2(index % columns, index / columns)
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(grid_origin + cell * cell_size, cell_size)
	return atlas
