extends SceneTree

func _init() -> void:
	var atlas := FileAccess.get_file_as_string("res://src/presentation/ui/hud5_atlas.gd")
	var growth := FileAccess.get_file_as_string("res://src/presentation/main/growth_cycle_hud.gd")
	var fertilizer := FileAccess.get_file_as_string("res://src/presentation/main/fertilizer_offer_panel.gd")
	var journal := FileAccess.get_file_as_string("res://src/presentation/main/journal_card_grid.gd")
	var tasks := FileAccess.get_file_as_string("res://src/presentation/progression/progression_panel.gd")
	var ok := true
	ok = _expect(atlas.contains("const CELL := 256.0"), "hud5 must use 256x256 cells") and ok
	ok = _expect(atlas.contains("CELL * columns, CELL"), "hud5 must support multi-cell horizontal assets") and ok
	ok = _expect(atlas.contains("fertilizer_finish_icon() -> Texture2D: return region(3, 1, 2)"), "fertilizer finish must use the full 512x256 two-cell asset") and ok
	ok = _expect(atlas.contains("cycle_finish_icon() -> Texture2D: return region(3, 3, 2)"), "growth finish must use its full two-cell atlas asset") and ok
	ok = _expect(atlas.contains("seed_icon() -> Texture2D: return cell(2, 2)"), "growth stage assets must come from row 2") and ok
	ok = _expect(atlas.contains("static func plus_icon() -> Texture2D: return cell(3, 5)"), "plus icon must be row 3 col 5") and ok
	ok = _expect(atlas.contains("Color(\"ffd229\")"), "finish button energy dot must be yellow") and ok
	ok = _expect(growth.contains("const HUD_BODY_WIDTH := 153.0"), "growth HUD body must be half of the old 306px width") and ok
	ok = _expect(fertilizer.contains("const TIMER_HUD_BODY_WIDTH := 153.0"), "fertilizer HUD body must be half of the old 306px width") and ok
	ok = _expect(growth.contains("Vector2(49.0, 47.0)"), "growth left icon must be enlarged by about 30 percent") and ok
	ok = _expect(fertilizer.contains("Vector2(49.0, 47.0)"), "fertilizer left icon must be enlarged by about 30 percent") and ok
	ok = _expect(growth.contains("_cost_label.text = str(cost)"), "growth cost must be white number inside atlas button") and ok
	ok = _expect(fertilizer.contains("_timer_cost.text = str(finish_cost)"), "fertilizer cost must be white number inside atlas button") and ok
	ok = _expect(journal.contains("Hud5Atlas.claim_energy_icon() if reward_kind == &\"energy\" else Hud5Atlas.coin_icon()"), "journal claims must use hud5 reward icons") and ok
	ok = _expect(tasks.contains("Hud5Atlas.claim_energy_icon() if reward_kind == &\"energy\" else Hud5Atlas.coin_icon()"), "task claims must use hud5 reward icons") and ok
	quit(0 if ok else 1)

func _expect(condition: bool, message: String) -> bool:
	if not condition: push_error(message)
	return condition
