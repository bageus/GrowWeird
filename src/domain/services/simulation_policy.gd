class_name SimulationPolicy
extends RefCounted

var advance_environment: bool = true
var advance_growth: bool = true
var advance_health: bool = true
var allow_death: bool = true

static func realtime() -> SimulationPolicy:
	return SimulationPolicy.new()

static func offline(rules: GameRules) -> SimulationPolicy:
	var policy := SimulationPolicy.new()
	policy.advance_environment = rules.offline_environment_enabled
	policy.advance_growth = rules.offline_growth_enabled
	policy.advance_health = rules.offline_health_enabled
	policy.allow_death = rules.offline_death_enabled
	return policy
