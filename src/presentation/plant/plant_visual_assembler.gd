class_name PlantVisualAssembler
extends RefCounted

static func build(
	size: Vector2,
	plant: PlantState,
	species: PlantSpeciesDefinition = null
) -> Dictionary:
	var growth := clampf(plant.growth_ratio if plant != null else 0.0, 0.0, 1.0)
	var vitality := PlantLifecycleService.vitality(plant)
	var center_x := size.x * 0.5
	var base_y := size.y * 0.94
	var stem_scale := species.stem_height_scale if species != null else 1.0
	var span_scale := species.side_span_scale if species != null else 1.0
	var lift_scale := species.side_lift_scale if species != null else 1.0
	var stem_height := lerpf(size.y * 0.12, size.y * 0.72, pow(growth, 0.72)) * stem_scale
	var droop := pow(1.0 - vitality, 1.45)
	var trunk_top := Vector2(center_x, base_y - stem_height + size.y * 0.035 * droop)
	var trunk_base := Vector2(center_x, base_y)
	var side_y := lerpf(base_y - stem_height * 0.34, base_y - stem_height * 0.56, growth)
	var side_span := lerpf(size.x * 0.02, size.x * 0.27, growth) * span_scale
	var side_lift := lerpf(size.y * 0.01, size.y * 0.16, growth) * lift_scale
	var droop_drop := size.y * 0.16 * droop
	var descriptors := {
		"center": _slot(
			plant,
			&"center",
			trunk_base,
			trunk_top,
			plant.branch_at(&"center") if plant != null else null
		),
		"left": _slot(
			plant,
			&"left",
			Vector2(center_x, side_y),
			Vector2(center_x - side_span, side_y - side_lift + droop_drop),
			plant.branch_at(&"left") if plant != null else null
		),
		"right": _slot(
			plant,
			&"right",
			Vector2(center_x, side_y),
			Vector2(center_x + side_span, side_y - side_lift + droop_drop),
			plant.branch_at(&"right") if plant != null else null
		),
	}
	return {
		"growth": growth,
		"vitality": vitality,
		"base": Vector2(center_x, base_y),
		"root_top": Vector2(center_x, base_y - maxf(size.y * 0.09, stem_height * 0.22)),
		"slots": descriptors,
	}

static func _slot(
	plant: PlantState,
	slot: StringName,
	start: Vector2,
	end: Vector2,
	branch: BranchState
) -> Dictionary:
	return {
		"slot": slot,
		"start": start,
		"end": end,
		"branch": branch,
		"regrowth": plant.regrowth_progress_at(slot) if plant != null else 0.0,
		"phenotype": PhenotypeResolver.resolve_branch(branch),
	}
