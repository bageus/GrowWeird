class_name SaveMigrator
extends RefCounted

const CURRENT_VERSION: int = GameState.SCHEMA_VERSION

static func migrate(source: Dictionary) -> Dictionary:
	var data := source.duplicate(true)
	var version := int(data.get("schema_version", 1))
	if version > CURRENT_VERSION:
		push_error("Save schema %d is newer than supported schema %d" % [version, CURRENT_VERSION])
		return {}

	while version < CURRENT_VERSION:
		match version:
			1:
				data = _migrate_v1_to_v2(data)
			2:
				data = _migrate_v2_to_v3(data)
			3:
				data = _migrate_v3_to_v4(data)
			4:
				data = _migrate_v4_to_v5(data)
			5:
				data = _migrate_v5_to_v6(data)
			6:
				data = _migrate_v6_to_v7(data)
			7:
				data = _migrate_v7_to_v8(data)
			8:
				data = _migrate_v8_to_v9(data)
			_:
				push_error("No save migration registered for schema %d" % version)
				return {}
		version += 1

	data["schema_version"] = CURRENT_VERSION
	return data

static func _migrate_v1_to_v2(source: Dictionary) -> Dictionary:
	var data := source.duplicate(true)
	data["inventory"] = {
		"fertilizers": {},
		"cuttings": [],
		"seeds": [],
		"fruits": [],
	}
	data["fertilizer_offer"] = {
		"offered_ids": [],
		"seconds_until_offer": 0.0,
		"skip_count": 0,
		"rng_state": 0,
	}
	data["schema_version"] = 2
	return data

static func _migrate_v2_to_v3(source: Dictionary) -> Dictionary:
	var data := source.duplicate(true)
	for pot_value in data.get("pots", []):
		if not (pot_value is Dictionary):
			continue
		var plant_value: Variant = pot_value.get("plant")
		if not (plant_value is Dictionary):
			continue
		var branches: Variant = plant_value.get("branches", {})
		if not (branches is Dictionary):
			continue
		for slot in branches:
			var branch_value: Variant = branches[slot]
			if branch_value is Dictionary:
				branch_value["fruit_growth"] = null
	data["schema_version"] = 3
	return data

static func _migrate_v3_to_v4(source: Dictionary) -> Dictionary:
	var data := source.duplicate(true)
	for pot_value in data.get("pots", []):
		if not (pot_value is Dictionary):
			continue
		var plant_value: Variant = pot_value.get("plant")
		if plant_value is Dictionary:
			plant_value["regrowth_progress"] = {}
	data["schema_version"] = 4
	return data

static func _migrate_v4_to_v5(source: Dictionary) -> Dictionary:
	var data := source.duplicate(true)
	# Existing players keep all previously available content and are not forced through onboarding.
	data["progression"] = {
		"progress_by_id": {},
		"completed_ids": [],
		"skip_onboarding": true,
	}
	data["schema_version"] = 5
	return data

static func _migrate_v5_to_v6(source: Dictionary) -> Dictionary:
	var data := source.duplicate(true)
	for pot_value in data.get("pots", []):
		if not (pot_value is Dictionary):
			continue
		var plant_value: Variant = pot_value.get("plant")
		if plant_value is Dictionary:
			plant_value["nutrition"] = 0.5
			plant_value["care_stage_index"] = 0
			plant_value["care_stage_score_sum"] = 0.0
			plant_value["care_stage_sample_seconds"] = 0.0
			plant_value["completed_care_scores"] = []
	data["schema_version"] = 6
	return data

static func _migrate_v6_to_v7(source: Dictionary) -> Dictionary:
	var data := source.duplicate(true)
	for pot_value in data.get("pots", []):
		if not (pot_value is Dictionary): continue
		var plant: Variant = pot_value.get("plant")
		if not (plant is Dictionary): continue
		plant["fruit_cycle_index"] = 0
		plant["regrowth_fruit_cycles"] = {}
		var branches: Dictionary = plant.get("branches", {})
		for branch in branches.values():
			if branch is Dictionary: branch["fruit_cycle_eligible"] = 0
	data["schema_version"] = 7
	return data

static func _migrate_v7_to_v8(source: Dictionary) -> Dictionary:
	var data := source.duplicate(true)
	data["rewarded_ad_claims"] = []
	data["schema_version"] = 8
	return data

static func _migrate_v8_to_v9(source: Dictionary) -> Dictionary:
	var data := source.duplicate(true)
	for pot_value in data.get("pots", []):
		if not (pot_value is Dictionary): continue
		var plant: Variant = pot_value.get("plant")
		if not (plant is Dictionary): continue
		var growth := clampf(float(plant.get("growth_ratio", 0.0)), 0.0, 1.0)
		plant["growth_cycle_index"] = mini(8, floori(growth * 9.0))
		plant["growth_cycle_elapsed"] = 0.0
		plant["boosted_growth_cycle"] = -1
	data["schema_version"] = 9
	return data
