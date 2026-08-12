class_name ContentRegistry
extends RefCounted

const PLANT_DIR := "res://content/plants"
const FERTILIZER_DIR := "res://content/fertilizers"
const MUTATION_DIR := "res://content/mutations"

var _plants: Dictionary = {}
var _fertilizers: Dictionary = {}
var _mutations: Dictionary = {}

func load_all() -> void:
	_plants.clear()
	_fertilizers.clear()
	_mutations.clear()
	_load_directory(PLANT_DIR, _plants)
	_load_directory(FERTILIZER_DIR, _fertilizers)
	_load_directory(MUTATION_DIR, _mutations)

func get_plant(id: StringName) -> PlantSpeciesDefinition:
	return _plants.get(String(id)) as PlantSpeciesDefinition

func get_fertilizer(id: StringName) -> FertilizerDefinition:
	return _fertilizers.get(String(id)) as FertilizerDefinition

func all_fertilizers() -> Array[FertilizerDefinition]:
	var result: Array[FertilizerDefinition] = []
	for value in _fertilizers.values():
		var definition := value as FertilizerDefinition
		if definition != null:
			result.append(definition)
	return result

func all_mutations() -> Array[MutationDefinition]:
	var result: Array[MutationDefinition] = []
	for value in _mutations.values():
		var definition := value as MutationDefinition
		if definition != null:
			result.append(definition)
	return result

func _load_directory(path: String, target: Dictionary) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		push_error("Content directory not found: %s" % path)
		return

	for file_name in directory.get_files():
		if not file_name.ends_with(".tres") and not file_name.ends_with(".res"):
			continue
		var resource := ResourceLoader.load(path.path_join(file_name))
		if resource == null:
			push_error("Unable to load content resource: %s" % file_name)
			continue
		var id: Variant = resource.get("id")
		if id == null or String(id).is_empty():
			push_error("Content resource has no id: %s" % file_name)
			continue
		var key := String(id)
		if target.has(key):
			push_error("Duplicate content id '%s' in %s" % [key, path])
			continue
		target[key] = resource
