extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	_test_presentation_resources_load()
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
		"res://src/presentation/main/garden_layout_editor.gd",
		"res://src/presentation/environment/window_view.gd",
		"res://src/presentation/plant/plant_view.gd",
		"res://src/presentation/plant/branch_mutation_renderer.gd",
		"res://src/presentation/plant/soil_view.gd",
		"res://src/presentation/plant/plant_sense_view.gd",
		"res://src/presentation/plant/phenotype_resolver.gd",
		"res://src/presentation/plant/plant_visual_assembler.gd",
		"res://src/presentation/inventory/inventory_panel.gd",
		"res://src/presentation/inventory/genetic_item_preview.gd",
		"res://src/presentation/progression/progression_panel.gd",
		"res://src/presentation/shop/shop_panel.gd",
	]
	for path in paths:
		_expect(load(path) != null, "presentation load failed: %s" % path)

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
