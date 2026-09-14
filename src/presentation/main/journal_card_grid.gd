class_name JournalCardGrid
extends RefCounted

const CARD_SIZE := Vector2(242.0, 278.0)

static func populate(scroll: ScrollContainer, app: Node, tab: StringName) -> void:
	if scroll == null or app == null:
		return
	var legacy := scroll.get_node_or_null("KnowledgeText") as Control
	if legacy != null:
		legacy.hide()
	var grid := scroll.get_node_or_null("Cards") as GridContainer
	if grid == null:
		grid = GridContainer.new()
		grid.name = "Cards"
		grid.columns = 2
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override(&"h_separation", 10)
		grid.add_theme_constant_override(&"v_separation", 10)
		scroll.add_child(grid)
	for child in grid.get_children():
		child.free()
	var knowledge := app.call("fertilizer_knowledge") as Dictionary
	var entries := _entries(app, knowledge, tab)
	for entry in entries:
		grid.add_child(_card(entry, app))
	if entries.is_empty():
		grid.add_child(_empty_card(app))

static func _entries(app: Node, knowledge: Dictionary, tab: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if tab == &"unknown":
		var definitions: Array = app.registry.all_fertilizers() + app.registry.all_offer_fertilizers()
		for definition in definitions:
			if definition == null:
				continue
			var id := String(definition.id)
			if knowledge.has(id):
				continue
			result.append({"id": id, "name": "UNKNOWN ITEM", "unknown": true})
		return result
	var ids := knowledge.keys()
	ids.sort()
	for raw_id in ids:
		var entry: Dictionary = knowledge[raw_id]
		var care: Dictionary = entry.get("care_effects", {})
		var mutations: Dictionary = entry.get("mutation_effects", {})
		var traits: Array = entry.get("discovered_traits", [])
		if tab == &"fertilizers" and care.is_empty():
			continue
		if tab == &"mutagens" and mutations.is_empty() and traits.is_empty():
			continue
		if tab == &"decorations" and String(entry.get("category", "")) != "decoration":
			continue
		result.append({"id": String(raw_id), "name": _display_name(StringName(raw_id)), "data": entry})
	return result

static func _card(entry: Dictionary, app: Node) -> PanelContainer:
	var data := entry.get("data", {}) as Dictionary
	var claimed := bool(data.get("reward_claimed", false))
	var card := PanelContainer.new()
	card.custom_minimum_size = CARD_SIZE
	card.add_theme_stylebox_override(&"panel", _card_style(claimed))
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 5)
	card.add_child(column)
	var title := Label.new()
	title.text = String(entry.get("name", "UNKNOWN ITEM")).to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 17)
	title.add_theme_color_override(&"font_color", Color("5b2b12"))
	column.add_child(title)
	var image := TextureRect.new()
	image.custom_minimum_size = Vector2(96.0, 96.0)
	image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture = FertilizerOfferArt.texture_for(StringName(entry.get("id", "")))
	image.modulate = Color(1, 1, 1, 0.52) if bool(entry.get("unknown", false)) else Color.WHITE
	column.add_child(image)
	var details := Label.new()
	details.text = "Properties not discovered yet." if bool(entry.get("unknown", false)) else _details(data)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details.add_theme_font_size_override(&"font_size", 13)
	details.add_theme_color_override(&"font_color", Color("5b2b12"))
	column.add_child(details)
	var item_id := StringName(entry.get("id", ""))
	if not bool(entry.get("unknown", false)) and bool(app.call("can_claim_journal_reward", item_id)):
		var claim := Button.new()
		claim.custom_minimum_size = Vector2(0.0, 38.0)
		claim.text = "CLAIM +3 %s" % String(app.call("journal_reward_kind", item_id)).to_upper()
		CommerceUiStyle.transaction_action(claim, &"claim")
		claim.pressed.connect(func() -> void: app.call("claim_journal_reward", item_id))
		column.add_child(claim)
	return card

static func _details(data: Dictionary) -> String:
	var lines: Array[String] = []
	var care: Dictionary = data.get("care_effects", {})
	for key in care:
		var value: Variant = care[key]
		if key == "growth_cycle" or key == &"growth_cycle":
			lines.append("Special: accelerates %s stage" % String(value).replace("_", " "))
		elif value is float or value is int:
			var amount := float(value)
			lines.append("%s: %s%.2f" % [String(key).replace("_", " ").capitalize(), "+" if amount >= 0.0 else "", amount])
	var mutations: Dictionary = data.get("mutation_effects", {})
	for axis in mutations:
		var amount := float(mutations[axis])
		lines.append("Mutation %s: %s%.2f" % [String(axis), "+" if amount >= 0.0 else "", amount])
	var traits: Array = data.get("discovered_traits", [])
	if not traits.is_empty():
		lines.append("Special: %s" % ", ".join(traits))
	lines.append("Used: %d" % int(data.get("uses", 0)))
	if bool(data.get("reward_claimed", false)):
		lines.append("Reward claimed")
	return "\n".join(lines)

static func _display_name(id: StringName) -> String:
	var descriptor := FertilizerAssetCatalog.descriptor_for(id)
	if not descriptor.is_empty():
		return String(descriptor.get("item_id", id)).replace("_", " ").capitalize()
	return String(id).replace("_", " ").capitalize()

static func _empty_card(app: Node) -> PanelContainer:
	return _card({"name": "NO ITEMS", "id": "", "unknown": true}, app)

static func _card_style(claimed: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f4c651") if claimed else Color("e8bd78")
	style.border_color = Color("c47a08") if claimed else Color("a95c1a")
	style.set_border_width_all(3)
	style.set_corner_radius_all(16)
	style.content_margin_left = 10.0
	style.content_margin_top = 8.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 8.0
	style.shadow_size = 2
	style.shadow_offset = Vector2(0.0, 2.0)
	return style
