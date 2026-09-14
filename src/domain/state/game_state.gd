class_name GameState
extends RefCounted

const SCHEMA_VERSION: int = 13

var schema_version: int = SCHEMA_VERSION
var money: int = 0
var energy: int = 0
var energy_regen_elapsed: float = 0.0
var active_pot_id: String = ""
var pots: Array[PotState] = []
var inventory := InventoryState.new()
var fertilizer_offer := FertilizerOfferState.new()
var fertilizer_knowledge: Dictionary = {}
var progression := ProgressionState.new()
var task_claimed: Dictionary = {}
var daily_task_progress: Dictionary = {}
var daily_task_claimed: Dictionary = {}
var daily_task_day: int = -1
var last_saved_unix: int = 0
var rewarded_ad_claims: Array[int] = []

func find_pot(pot_id: String) -> PotState:
	for pot in pots:
		if pot.pot_id == pot_id:
			return pot
	return null

func active_pot() -> PotState:
	return find_pot(active_pot_id)
