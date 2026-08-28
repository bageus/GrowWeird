extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	_test_presentation_resources_load()
	_test_scene_button_contract()
	_test_scene_hud_contract()
	_test_window_asset_mapping()
	_test_growth_stage_geometry()
	_test_phenotype_descriptor()
	_test_mutation_reveal_detection()
	_test_species_visual_data()
	_test_fruit_visual_state()
	if _failures.is_empty():
		print("GrowWeird presentation tests passed")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)

func _test_presentation_resources_load() -> void:
	var paths := [
		"res://src/presentation/main/main.tscn",
		"res://src/presentation/main/main_screen.gd",
		"res://src/presentation/main/pot_selector.gd",
		"res://src/presentation/main/scene_action_button.gd",
		"res://src/presentation/main/scene_draggable_panel.gd",
		"res://src/presentation/main/scene_controls_overlay.gd",
		"res://src/presentation/environment/window_view.gd",
		"res://src/presentation/plant/plant_view.gd",
		"res://src/presentation/plant/branch_mutation_renderer.gd",
		"res://src/presentation/plant/phenotype_resolver.gd",
		"res://src/presentation/plant/plant_visual_assembler.gd",
		"res://src/presentation/inventory/inventory_panel.gd",
		"res://src/presentation/inventory/genetic_item_preview.gd",
		"res://src/presentation/progression/progression_panel.gd",
		"res://src/presentation/shop/shop_panel.gd",
	]
	for path in paths:
		_expect(load(path) != null, "presentation load failed: %s" % path)

func _test_scene_button_contract() -> void:
	var host := Control.new()
	host.size = Vector2(1000.0, 600.0)
	var button := SceneActionButton.new()
	button.size = Vector2(100.0, 40.0)
	button.action_id = &"water"
	host.add_child(button)
	button.apply_normalized_position(Vector2(0.5, 0.25))
	_expect(button.normalized_position().distance_to(Vector2(0.5, 0.25)) < 0.001, "scene buttons: normalized position must round-trip")
	_expect(SceneControlsOverlay.DEFAULT_POSITIONS.has("lighting"), "scene buttons: lighting control missing")
	_expect(SceneControlsOverlay.DEFAULT_POSITIONS.has("water") and SceneControlsOverlay.DEFAULT_POSITIONS.has("spray"), "scene buttons: care controls missing")
	_expect(SceneControlsOverlay.DEFAULT_POSITIONS.has("shop"), "scene buttons: shop must live on the scene")
	_expect(not SceneControlsOverlay.DEFAULT_POSITIONS.has("window"), "scene buttons: environment must be controlled through lighting presets")
	host.free()

func _test_scene_hud_contract() -> void:
	var host := Control.new()
	host.size = Vector2(1000.0, 600.0)
	var panel := SceneDraggablePanel.new()
	panel.size = Vector2(240.0, 90.0)
	panel.layout_id = &"inventory"
	host.add_child(panel)
	panel.apply_normalized_position(Vector2(0.6, 0.7))
	_expect(panel.normalized_position().distance_to(Vector2(0.6, 0.7)) < 0.001, "scene HUD: draggable panels must use normalized coordinates")
	_expect(SceneControlsOverlay.DEFAULT_POSITIONS.has("fertilizers"), "scene HUD: fertilizer block must be movable on scene")
	_expect(SceneControlsOverlay.DEFAULT_POSITIONS.has("inventory"), "scene HUD: inventory block must be movable on scene")
	var scene_text := FileAccess.get_file_as_string("res://src/presentation/main/main.tscn")
	_expect(scene_text.contains("Save HUD layout"), "scene HUD: explicit save layout button missing")
	_expect(scene_text.contains("InventorySlotOne") and scene_text.contains("InventorySlotThree"), "scene HUD: compact three-slot inventory missing")
	_expect(not scene_text.contains("SoilView") and not scene_text.contains("PlantSense"), "scene HUD: legacy pot/comfort overlays must be removed")
	host.free()

func _test_window_asset_mapping() -> void:
	var view := WindowView.new()
	view.set_environment(PotState.LightMode.DIRECT, false)
	_expect(view.texture == WindowView.SUNNY, "window art: sunny mode must use window_01")
	view.set_environment(PotState.LightMode.DARK, false)
	_expect(view.texture == WindowView.CURTAINS, "window art: curtains mode must use window_02")
	view.set_environment(PotState.LightMode.DIRECT, true)
	_expect(view.texture == WindowView.VENTILATION, "window art: ventilation mode must use window_03")
	view.set_environment(PotState.LightMode.DIFFUSED, false)
	_expect(view.texture == WindowView.BLINDS, "window art: blinds mode must use window_04")
	view.free()

func _test_growth_stage_geometry() -> void:
	var plant := _plant()
	plant.growth_ratio = 0.05
	var young := PlantVisualAssembler.build(Vector2(600.0, 400.0), plant)
	plant.growth_ratio = 0.8
	var mature := PlantVisualAssembler.build(Vector2(600.0, 400.0), plant)
	for slot in BranchState.VALID_SLOTS:
		var young_length := _slot_length(young, slot)
		var mature_length := _slot_length(mature, slot)
		_expect(mature_length > young_length, "growth view: %s branch should visibly expand with growth" % String(slot))

func _test_phenotype_descriptor() -> void:
	var branch := BranchState.new()
	branch.add_trait(&"thorns", 2)
	branch.add_trait(&"bloom", 3)
	branch.add_trait(&"glow", 1)
	branch.add_trait(&"fungi", 2)
	branch.add_trait(&"bark_armor", 1)
	branch.add_trait(&"lure_bloom", 1)
	branch.add_trait(&"crystal_thorns", 1)
	branch.add_trait(&"luminous_fungus", 1)
	branch.add_trait(&"hooks", 2)
	branch.add_trait(&"mineral_nodes", 1)
	branch.add_trait(&"crown_bloom", 1)
	branch.add_trait(&"toxic_sacs", 1)
	var phenotype := PhenotypeResolver.resolve_branch(branch)
	_expect(int(phenotype["thorn_count"]) > 0, "phenotype: thorns must be visible")
	_expect(int(phenotype["hook_count"]) > 0, "phenotype: hooks must be visible")
	_expect(int(phenotype["flower_count"]) > 0, "phenotype: bloom/lure must be visible")
	_expect(float(phenotype["crown_bloom_strength"]) > 0.0, "phenotype: crown bloom must affect flowers")
	_expect(float(phenotype["glow_strength"]) > 0.0, "phenotype: glow must be visible")
	_expect(int(phenotype["fungus_count"]) > 0, "phenotype: fungi must be visible")
	_expect(float(phenotype["branch_width_bonus"]) > 0.0, "phenotype: bark/mineral growth must affect silhouette")
	_expect(int(phenotype["mineral_node_count"]) > 0, "phenotype: mineral nodes must be visible")
	_expect(int(phenotype["toxic_sac_count"]) > 0, "phenotype: toxic sacs must be visible")
	_expect(int(phenotype["crystal_thorn_count"]) > 0, "phenotype: crystal thorns must be visible")
	_expect(float(phenotype["fungus_glow"]) > 0.0, "phenotype: luminous fungus must glow")

func _test_mutation_reveal_detection() -> void:
	var plant := _plant()
	var view := PlantView.new()
	view.set_process(false)
	view.set_plant(plant)
	_expect(not view.is_processing(), "mutation reveal: initial specimen should not animate as a mutation")
	plant.branch_at(&"left").add_trait(&"hooks", 1)
	view.set_plant(plant)
	_expect(view.is_processing(), "mutation reveal: increased branch trait should start reveal animation")
	view.free()

func _test_species_visual_data() -> void:
	var starter := load("res://content/plants/starter_sprout.tres") as PlantSpeciesDefinition
	var shade := load("res://content/plants/shade_fern.tres") as PlantSpeciesDefinition
	var sun := load("res://content/plants/sun_creeper.tres") as PlantSpeciesDefinition
	if starter == null or shade == null or sun == null:
		_expect(false, "species presentation: species resources failed to load")
		return
	_expect(shade.leaf_color != starter.leaf_color, "species presentation: shade fern should have distinct palette")
	_expect(sun.fruit_color != starter.fruit_color, "species presentation: sun creeper should have distinct fruit palette")

func _test_fruit_visual_state() -> void:
	var fruit := GrowingFruitState.new()
	fruit.progress = 0.99
	_expect(not fruit.is_ready(), "fruit presentation: unripe fruit marked ready")
	fruit.progress = 1.0
	fruit.hybrid = true
	_expect(fruit.is_ready() and fruit.hybrid, "fruit presentation: ripe hybrid state unavailable")
	_expect(PlantView.MODE_HARVEST == &"harvest", "fruit presentation: harvest interaction mode missing")

func _slot_length(layout: Dictionary, slot: StringName) -> float:
	var slots: Dictionary = layout["slots"]
	var descriptor: Dictionary = slots[String(slot)]
	var start: Vector2 = descriptor["start"]
	var end: Vector2 = descriptor["end"]
	return start.distance_to(end)

func _plant() -> PlantState:
	var plant := PlantState.new()
	plant.instance_id = "presentation-test"
	plant.species_id = &"starter_sprout"
	plant.initialize_native_branches()
	return plant

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
