class_name AlmanacItemCatalog
extends RefCounted

const DECORATIONS := [&"garden_gnome", &"fairy_lights", &"crystal_cluster", &"wooden_fence", &"water_fountain"]
const MUTAGENS := [&"stable_mutagen", &"spore_mutagen", &"crystal_mutagen", &"floral_mutagen", &"predatory_mutagen"]
const MUTATION_AXES := [&"stability", &"fungal", &"structural", &"floral", &"predatory"]

static func category_for(kind: StringName, item_id: String, registry: ContentRegistry) -> StringName:
	var id := StringName(item_id)
	if DECORATIONS.has(id): return &"decoration"
	if MUTAGENS.has(id): return &"mutagen"
	var fertilizer := registry.get_fertilizer(id) if registry != null else null
	if fertilizer != null:
		return &"mutagen" if not fertilizer.mutation_contributions.is_empty() else &"fertilizer"
	return &"unknown" if kind == ResourceActions.MISC else kind

static func decoration_effect(item_id: StringName) -> Dictionary:
	match item_id:
		&"garden_gnome": return {"sale_bonus": 0.10}
		&"fairy_lights": return {"energy_bonus": 0.10}
		&"crystal_cluster": return {"energy_bonus": 0.20}
		&"wooden_fence": return {"sale_bonus": 0.15}
		&"water_fountain": return {"moisture_saving": 0.20}
	return {}

static func mutagen_effect(item_id: StringName) -> Dictionary:
	var index := MUTAGENS.find(item_id)
	return {String(MUTATION_AXES[index]): 8.0} if index >= 0 else {}
