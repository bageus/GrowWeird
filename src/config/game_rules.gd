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

@export_group("Tools")
@export_range(0.01, 1.0, 0.01) var watering_can_amount: float = 0.18
@export_range(0.001, 0.5, 0.001) var sprayer_soil_amount: float = 0.035

@export_group("Economy")
@export var starting_money: int = 0
@export var fertilizer_skip_base_price: int = 50

@export_group("Persistence")
@export_range(1.0, 300.0, 1.0) var autosave_interval_seconds: float = 15.0
