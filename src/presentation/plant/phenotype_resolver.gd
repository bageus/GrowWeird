class_name PhenotypeResolver
extends RefCounted

static func resolve_branch(branch: BranchState) -> Dictionary:
	if branch == null:
		return {}
	var thorns := branch.trait_level(&"thorns")
	var bloom := branch.trait_level(&"bloom")
	var glow := branch.trait_level(&"glow")
	var fungi := branch.trait_level(&"fungi")
	var bark := branch.trait_level(&"bark_armor")
	var lure := branch.trait_level(&"lure_bloom")
	var luminous_bloom := branch.trait_level(&"luminous_bloom")
	var spore_trap := branch.trait_level(&"spore_trap")
	var crystal_thorns := branch.trait_level(&"crystal_thorns")
	var luminous_fungus := branch.trait_level(&"luminous_fungus")
	return {
		"thorns": thorns,
		"thorn_count": mini(14, thorns * 2),
		"thorn_scale": 1.0 + minf(float(thorns) * 0.08, 1.2),
		"crystal_thorn_count": mini(12, crystal_thorns * 2),
		"crystal_thorn_scale": 1.0 + minf(float(crystal_thorns) * 0.12, 1.3),
		"bloom": bloom,
		"flower_count": mini(12, bloom * 2 + lure * 2 + luminous_bloom * 2),
		"flower_scale": 1.0 + minf(float(bloom + lure + luminous_bloom) * 0.05, 0.9),
		"lure_strength": minf(float(lure) * 0.18, 1.0),
		"flower_glow": minf(float(luminous_bloom) * 0.20, 0.95),
		"glow": glow,
		"glow_strength": minf(float(glow) * 0.12, 0.85),
		"fungus_count": mini(12, fungi * 2 + luminous_fungus * 2),
		"fungus_scale": 1.0 + minf(float(fungi + luminous_fungus) * 0.07, 0.8),
		"fungus_glow": minf(float(luminous_fungus) * 0.20, 0.95),
		"spore_trap_count": mini(8, spore_trap * 2),
		"bark_ring_count": mini(10, bark * 2),
		"branch_width_bonus": minf(float(bark) * 1.2, 7.0),
		"leaf_scale": 1.0 + minf(float(bloom + lure) * 0.025, 0.4),
	}
