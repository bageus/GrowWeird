class_name Hud5Atlas
extends RefCounted

const TEXTURE: Texture2D = preload("res://assets/ui/hud5.png")
const CELL := 256.0
const FINISH_SEGMENT_SIZE := Vector2(36.0, 36.0)

static func region(row: int, column: int, columns := 1) -> Texture2D:
	var texture := AtlasTexture.new(); texture.atlas = TEXTURE; texture.region = Rect2((column - 1) * CELL, (row - 1) * CELL, CELL * columns, CELL); return texture
static func cell(row: int, column: int) -> Texture2D: return region(row, column, 1)
static func fertilizer_icon() -> Texture2D: return cell(1, 3)
static func restart_icon() -> Texture2D: return cell(2, 1)
static func seed_icon() -> Texture2D: return cell(2, 2)
static func sprout_icon() -> Texture2D: return cell(2, 3)
static func tree_icon() -> Texture2D: return cell(2, 4)
static func flower_icon() -> Texture2D: return cell(2, 5)
static func fruit_icon() -> Texture2D: return cell(2, 6)
static func energy_icon() -> Texture2D: return cell(1, 4)
static func balance_coin_icon() -> Texture2D: return cell(1, 5)
static func coin_icon() -> Texture2D: return cell(1, 6)
static func claim_energy_icon() -> Texture2D: return cell(1, 7)
static func fertilizer_finish_left() -> Texture2D: return cell(3, 1)
static func finish_cost_segment() -> Texture2D: return cell(3, 2)
static func cycle_finish_left() -> Texture2D: return cell(3, 3)
static func plus_icon() -> Texture2D: return cell(3, 5)

static func stage_icon(cycle: int) -> Texture2D:
	match cycle:
		0: return seed_icon()
		1, 2, 3, 4: return sprout_icon()
		5, 6, 7, 8: return tree_icon()
		9: return flower_icon()
		10, 11: return fruit_icon()
		_: return restart_icon()

static func configure_icon(rect: TextureRect, texture: Texture2D) -> void:
	rect.texture = texture; rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

static func configure_atlas_button(button: Button, texture: Texture2D) -> void:
	button.text = ""; button.icon = null; button.focus_mode = Control.FOCUS_NONE
	var box := StyleBoxTexture.new(); box.texture = texture
	for state in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]: button.add_theme_stylebox_override(state, box)

static func configure_finish_button(button: Button, left_texture: Texture2D) -> Label:
	button.text = ""; button.icon = null; button.focus_mode = Control.FOCUS_NONE
	for state in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]: button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var left := TextureRect.new(); left.name = "LeftSegment"; left.position = Vector2.ZERO; left.size = FINISH_SEGMENT_SIZE; configure_icon(left, left_texture); button.add_child(left)
	var cost_segment := TextureRect.new(); cost_segment.name = "CostSegment"; cost_segment.position = Vector2(FINISH_SEGMENT_SIZE.x, 0.0); cost_segment.size = FINISH_SEGMENT_SIZE; configure_icon(cost_segment, finish_cost_segment()); button.add_child(cost_segment)
	var dot := Label.new(); dot.name = "EnergyDot"; dot.mouse_filter = Control.MOUSE_FILTER_IGNORE; dot.position = Vector2(FINISH_SEGMENT_SIZE.x - 15.0, 0.0); dot.size = FINISH_SEGMENT_SIZE; dot.text = "·"; dot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; dot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; dot.add_theme_font_override(&"font", UiAtlas.GAME_FONT); dot.add_theme_font_size_override(&"font_size", 22); dot.add_theme_color_override(&"font_color", Color("ffd229")); button.add_child(dot)
	var label := Label.new(); label.name = "Cost"; label.mouse_filter = Control.MOUSE_FILTER_IGNORE; label.position = Vector2(FINISH_SEGMENT_SIZE.x + 9.0, 0.0); label.size = Vector2(22.0, FINISH_SEGMENT_SIZE.y); label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; label.add_theme_font_override(&"font", UiAtlas.GAME_FONT); label.add_theme_font_size_override(&"font_size", 17); label.add_theme_color_override(&"font_color", Color.WHITE); label.add_theme_color_override(&"font_outline_color", Color("5b2b12")); label.add_theme_constant_override(&"outline_size", 3); button.add_child(label); return label
