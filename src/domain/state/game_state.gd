class_name GameState
extends RefCounted

const SCHEMA_VERSION: int = 8

var schema_version: int = SCHEMA_VERSION
var money: int = 0
var active_pot_id: String = ""
var pots: Array[PotState] = []
var inventory := InventoryState.new()
var fertilizer_offer := FertilizerOfferState.new()
var progression := ProgressionState.new()
var last_saved_unix: int = 0
var rewarded_ad_claims: Array[int] = []

func find_pot(pot_id: String) -> PotState:
	for pot in pots:
		if pot.pot_id == pot_id:
			return pot
	return null

func active_pot() -> PotState:
	return find_pot(active_pot_id)
