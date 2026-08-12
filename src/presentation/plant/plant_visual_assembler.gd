class_name PlantVisualAssembler
extends RefCounted

static func build(size: Vector2, plant: PlantState) -> Dictionary:
	var growth := clampf(plant.growth_ratio if plant != null else 0.0, 0.0, 1.0)
	var center_x := size.x * 0.5
	var base_y := size.y * 0.94
	var stem_height := lerpf(size.y * 0.12, size.y * 0.72, pow(growth, 0.72))
	var trunk_top := Vector2(center_x, base_y - stem_height)
	var trunk_base := Vector2(center_x, base_y)
	var side_y := lerpf(base_y - stem_height * 0.34, base_y - stem_height * 0.56, growth)
	var side_span := lerpf(size.x * 0.08, size.x * 0.27, growth)
	var side_lift := lerpf(size.y * 0.03, size.y * 0.16, growth)
	var descriptors := {
		"center": _slot(
			&"center",
			trunk_base,
			trunk_top,
			plant.branch_at(&"center") if plant != null else null
		),
		"left": _slot(
			&"left",
			Vector2(center_x, side_y),
			Vector2(center_x - side_span, side_y - side_lift),
			plant.branch_at(&"left") if plant != null else null
		),
		"right": _slot(
			&"right",
			Vector2(center_x, side_y),
			Vector2(center_x + side_span, side_y - side_lift),
			plant.branch_at(&"right") if plant != null else null
		),
	}
	return {
		"growth": growth,
		"base": Vector2(center_x, base_y),
		"root_top": Vector2(center_x, base_y - maxf(size.y * 0.09, stem_height * 0.22)),
		"slots": descriptors,
	}

static func _slot(
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
		"phenotype": PhenotypeResolver.resolve_branch(branch),
	}
