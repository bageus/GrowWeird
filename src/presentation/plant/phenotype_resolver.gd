class_name PhenotypeResolver
extends RefCounted

static func resolve_branch(branch: BranchState) -> Dictionary:
	if branch == null:
		return {}
	var thorns := branch.trait_level(&"thorns")
	var bloom := branch.trait_level(&"bloom")
	var glow := branch.trait_level(&"glow")
	return {
		"thorns": thorns,
		"thorn_count": mini(14, thorns * 2),
		"thorn_scale": 1.0 + minf(float(thorns) * 0.08, 1.2),
		"bloom": bloom,
		"flower_count": mini(9, bloom * 2),
		"flower_scale": 1.0 + minf(float(bloom) * 0.06, 0.8),
		"glow": glow,
		"glow_strength": minf(float(glow) * 0.12, 0.85),
		"leaf_scale": 1.0 + minf(float(bloom) * 0.025, 0.35),
	}
