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
const FRUIT_COLUMNS := 3
const FRUIT_ROWS := 2

static func flower_texture(line: int, mutation_column: int = FLOWER_NORMAL) -> AtlasTexture:
	var row := posmod(line, FLOWER_ROWS)
	var column := clampi(mutation_column, 0, FLOWER_COLUMNS - 1)
	var atlas := AtlasTexture.new()
	atlas.atlas = FLOWERS
	atlas.region = Rect2(Vector2(column, row) * FLOWER_CELL, Vector2.ONE * FLOWER_CELL)
	return atlas

static func flower_line(seed_text: String) -> int:
	return stable_index(seed_text, FLOWER_ROWS)

static func flower_mutation_column(branch: BranchState) -> int:
	if branch == null:
		return FLOWER_NORMAL
	# A flower keeps its plant's row; only this column changes when a visible
	# mutation is acquired. The state already stores traits immediately, so a
	# mutation before flowering is waiting in the branch and a mutation during
	# flowering is reflected on the next redraw.
	if branch.trait_level(&"toxic_sacs") > 0:
		return FLOWER_POISONOUS
	if branch.trait_level(&"lure_bloom") > 0 or branch.trait_level(&"spore_trap") > 0:
		return FLOWER_CARNIVOROUS
	if branch.trait_level(&"thorns") > 0 or branch.trait_level(&"hooks") > 0:
		return FLOWER_THORNY
	if branch.trait_level(&"crystal_thorns") > 0 or branch.trait_level(&"mineral_nodes") > 0:
		return FLOWER_CRYSTAL
	if branch.trait_level(&"bark_armor") > 0:
		return FLOWER_CYBERNETIC
	if branch.trait_level(&"glow") > 0 or branch.trait_level(&"luminous_bloom") > 0 or branch.trait_level(&"luminous_fungus") > 0:
		return FLOWER_COSMIC
	if branch.trait_level(&"crown_bloom") > 0:
		return FLOWER_GOLDEN
	if branch.trait_level(&"fungi") > 0:
		return FLOWER_DRAGON
	return FLOWER_NORMAL

static func fruit_texture(index: int, ripe: bool) -> AtlasTexture:
	var row := posmod(index, FRUIT_ROWS)
	var column := 1 + posmod(index / FRUIT_ROWS, FRUIT_COLUMNS - 1) if ripe else 0
	return _cell(FRUITS, FRUIT_COLUMNS, FRUIT_ROWS, row * FRUIT_COLUMNS + column)

static func stable_index(seed_text: String, count: int) -> int:
	return posmod(seed_text.hash(), count)

static func _cell(texture: Texture2D, columns: int, rows: int, index: int) -> AtlasTexture:
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
