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
	var hooks := branch.trait_level(&"hooks")
	var mineral_nodes := branch.trait_level(&"mineral_nodes")
	var crown_bloom := branch.trait_level(&"crown_bloom")
	var toxic_sacs := branch.trait_level(&"toxic_sacs")
	return {
		"thorns": thorns,
		"thorn_count": mini(14, thorns * 2),
		"thorn_scale": 1.0 + minf(float(thorns) * 0.08, 1.2),
		"hook_count": mini(12, hooks * 2),
		"hook_scale": 1.0 + minf(float(hooks) * 0.10, 1.0),
		"crystal_thorn_count": mini(12, crystal_thorns * 2),
		"crystal_thorn_scale": 1.0 + minf(float(crystal_thorns) * 0.12, 1.3),
		"bloom": bloom,
		"flower_count": mini(16, bloom * 2 + lure * 2 + luminous_bloom * 2 + crown_bloom * 3),
		"flower_scale": 1.0 + minf(float(bloom + lure + luminous_bloom) * 0.05 + float(crown_bloom) * 0.10, 1.2),
		"crown_bloom_strength": minf(float(crown_bloom) * 0.22, 1.0),
		"lure_strength": minf(float(lure) * 0.18, 1.0),
		"flower_glow": minf(float(luminous_bloom) * 0.20, 0.95),
		"glow": glow,
		"glow_strength": minf(float(glow) * 0.12, 0.85),
		"fungus_count": mini(12, fungi * 2 + luminous_fungus * 2),
		"fungus_scale": 1.0 + minf(float(fungi + luminous_fungus) * 0.07, 0.8),
		"fungus_glow": minf(float(luminous_fungus) * 0.20, 0.95),
		"spore_trap_count": mini(8, spore_trap * 2),
		"toxic_sac_count": mini(10, toxic_sacs * 2),
		"toxic_sac_scale": 1.0 + minf(float(toxic_sacs) * 0.08, 0.8),
		"mineral_node_count": mini(10, mineral_nodes * 2),
		"mineral_node_scale": 1.0 + minf(float(mineral_nodes) * 0.10, 0.9),
		"bark_ring_count": mini(10, bark * 2),
		"branch_width_bonus": minf(float(bark) * 1.2 + float(mineral_nodes) * 0.35, 8.0),
		"leaf_scale": 1.0 + minf(float(bloom + lure + crown_bloom) * 0.025, 0.5),
	}
