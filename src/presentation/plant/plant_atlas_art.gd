class_name PlantAtlasArt
extends RefCounted

const FLOWERS: Texture2D = preload("res://assets/flower/flowers_01.png")
const FRUITS: Texture2D = preload("res://assets/fruit/fruits_01.png")
const FLOWER_COLUMNS := 9
const FLOWER_ROWS := 16
const FLOWER_CELL := 256.0
const FLOWER_POISONOUS := 0
const FLOWER_NORMAL := 1
const FLOWER_CARNIVOROUS := 2
const FLOWER_THORNY := 3
const FLOWER_CRYSTAL := 4
const FLOWER_CYBERNETIC := 5
const FLOWER_COSMIC := 6
const FLOWER_GOLDEN := 7
const FLOWER_DRAGON := 8
const FRUIT_COLUMNS := 16
const FRUIT_ROWS := 8
const FRUIT_CELL := 256.0
const FRUIT_UNRIPE := 0
const FRUIT_NORMAL := 1
const FRUIT_THORNY := 2
const FRUIT_CARNIVOROUS := 3
const FRUIT_POISONOUS := 4
const FRUIT_CYBERNETIC := 5
const FRUIT_ENERGETIC := 8
const FRUIT_LUNAR := 10
const FRUIT_GOLDEN := 11
const FRUIT_MAGIC := 12
const FRUIT_DRAGON := 13
const FRUIT_CRYSTAL := 14
const FRUIT_COSMIC := 15

static func flower_texture(line: int, mutation_column: int = FLOWER_NORMAL) -> AtlasTexture:
	var row := posmod(line, FLOWER_ROWS); var column := clampi(mutation_column, 0, FLOWER_COLUMNS - 1); return _atlas_cell(FLOWERS, column, row, FLOWER_CELL)
static func flower_line(seed_text: String) -> int: return stable_index(seed_text, FLOWER_ROWS)
# A flowering cycle is one phenotype visually: branch-local mutations must not mix flower assets on one plant.
static func flower_mutation_column(_branch: BranchState) -> int: return FLOWER_NORMAL
static func fruit_line(seed_text: String) -> int: return stable_index(seed_text, FRUIT_ROWS)
static func fruit_texture(line: int, mutation_column: int = FRUIT_NORMAL, ripe: bool = true) -> AtlasTexture:
	var row := posmod(line, FRUIT_ROWS); var column := clampi(mutation_column, 0, FRUIT_COLUMNS - 1) if ripe else FRUIT_UNRIPE; return _atlas_cell(FRUITS, column, row, FRUIT_CELL)
# Fruit from the same fruiting cycle uses the same plant line and phenotype across all branches.
static func fruit_mutation_column(_branch: BranchState) -> int: return FRUIT_NORMAL
static func stable_index(seed_text: String, count: int) -> int: return posmod(seed_text.hash(), count)
static func _atlas_cell(texture: Texture2D, column: int, row: int, cell_size: float) -> AtlasTexture:
	var atlas := AtlasTexture.new(); atlas.atlas = texture; atlas.region = Rect2(Vector2(column, row) * cell_size, Vector2.ONE * cell_size); return atlas
