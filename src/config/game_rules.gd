class_name GameRules
extends Resource

@export_group("Simulation")
@export_range(0.05, 5.0, 0.05) var simulation_step_seconds: float = 1.0
@export_range(1.0, 5.0, 0.05) var young_growth_multiplier: float = 1.8
@export_range(0.05, 1.0, 0.05) var mature_growth_multiplier: float = 0.35

@export_group("Health")
@export_range(0.0, 1.0, 0.01) var critical_comfort_threshold: float = 0.25
@export_range(0.0, 1.0, 0.01) var recovery_comfort_threshold: float = 0.7
@export_range(0.0, 1.0, 0.0001) var health_decay_per_second: float = 0.002
@export_range(0.0, 1.0, 0.0001) var health_recovery_per_second: float = 0.001
@export_range(0.0, 1.0, 0.01) var stressed_health_threshold: float = 0.7
@export_range(0.0, 1.0, 0.01) var wilted_health_threshold: float = 0.4
@export_range(0.0, 1.0, 0.01) var critical_health_threshold: float = 0.15

@export_group("Tools")
@export_range(0.01, 1.0, 0.01) var watering_can_amount: float = 0.18
@export_range(0.001, 0.5, 0.001) var sprayer_soil_amount: float = 0.035

@export_group("Fertilizer Offers")
@export_range(1.0, 3600.0, 1.0) var initial_offer_delay_seconds: float = 30.0
@export_range(1.0, 3600.0, 1.0) var fertilizer_offer_interval_seconds: float = 120.0
@export_range(1, 6, 1) var fertilizer_offer_count: int = 3

@export_group("Offline Progression")
@export var offline_progression_enabled: bool = true
@export var offline_environment_enabled: bool = true
@export var offline_growth_enabled: bool = true
@export var offline_health_enabled: bool = true
@export var offline_death_enabled: bool = false
@export var offline_fruiting_enabled: bool = true
@export var offline_offers_enabled: bool = true
@export_range(60.0, 604800.0, 60.0) var offline_max_seconds: float = 28800.0
@export_range(1, 2000, 1) var offline_max_steps: int = 480

@export_group("Economy")
@export var starting_money: int = 200
@export var fertilizer_skip_base_price: int = 50
@export var trait_level_sale_value: int = 18
@export var graft_sale_bonus: int = 65
@export var ancestry_sale_value: int = 8
@export_range(0.0, 1.0, 0.01) var nonliving_plant_value_multiplier: float = 0.15
@export var fruit_trait_value: int = 6
@export var hybrid_fruit_bonus: int = 30
@export_range(0.0, 1.0, 0.01) var seed_sale_multiplier: float = 0.45
@export_range(0.0, 1.0, 0.01) var cutting_sale_multiplier: float = 0.35
@export var genetic_item_trait_value: int = 10
@export var genetic_item_ancestry_value: int = 4
@export var pot_base_price: int = 250
@export_range(1.0, 3.0, 0.05) var pot_price_growth: float = 1.55

@export_group("Recycling")
@export_range(0, 20, 1) var fruit_compost_yield: int = 1
@export_range(0, 20, 1) var seed_compost_yield: int = 1
@export_range(0, 20, 1) var cutting_compost_yield: int = 2
@export_range(0, 20, 1) var dead_plant_compost_base: int = 1
@export_range(0, 20, 1) var dead_plant_compost_growth_bonus: int = 2
@export_range(0, 10, 1) var dead_plant_compost_per_branch: int = 1

@export_group("Persistence")
@export_range(1.0, 300.0, 1.0) var autosave_interval_seconds: float = 15.0
@export_range(5.0, 300.0, 5.0) var cloud_save_interval_seconds: float = 45.0
