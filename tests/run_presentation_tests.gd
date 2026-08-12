extends SceneTree

var _failures: Array[String] = []

func _init() -> void:
	_test_presentation_resources_load()
	_test_growth_stage_geometry()
	_test_phenotype_descriptor()
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
		"res://src/presentation/environment/window_view.gd",
		"res://src/presentation/plant/plant_view.gd",
		"res://src/presentation/plant/soil_view.gd",
		"res://src/presentation/plant/plant_sense_view.gd",
		"res://src/presentation/plant/phenotype_resolver.gd",
		"res://src/presentation/plant/plant_visual_assembler.gd",
		"res://src/presentation/inventory/inventory_panel.gd",
		"res://src/presentation/inventory/genetic_item_preview.gd",
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
		_expect(
			mature_length > young_length,
			"growth view: %s branch should visibly expand with growth" % String(slot)
		)

func _test_phenotype_descriptor() -> void:
	var branch := BranchState.new()
	branch.add_trait(&"thorns", 2)
	branch.add_trait(&"bloom", 3)
	branch.add_trait(&"glow", 1)
	var phenotype := PhenotypeResolver.resolve_branch(branch)
	_expect(int(phenotype["thorn_count"]) > 0, "phenotype: thorns must be visible")
	_expect(int(phenotype["flower_count"]) > 0, "phenotype: bloom must be visible")
	_expect(float(phenotype["glow_strength"]) > 0.0, "phenotype: glow must be visible")

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
