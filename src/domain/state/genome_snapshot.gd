class_name GenomeSnapshot
extends RefCounted

var species_id: StringName
var ancestry: Array[String] = []
var traits: Dictionary = {}
var branch_traits: Dictionary = {}

func duplicate_snapshot() -> GenomeSnapshot:
	var copy := GenomeSnapshot.new()
	copy.species_id = species_id
	copy.ancestry = ancestry.duplicate()
	copy.traits = traits.duplicate(true)
	copy.branch_traits = branch_traits.duplicate(true)
	return copy

func is_empty() -> bool:
	return String(species_id).is_empty()
