class_name PlantSpeciesDefinition
extends Resource

@export var id: StringName
@export var display_name_key: String = ""

@export_group("Care")
@export_range(0.0, 1.0, 0.01) var moisture_min: float = 0.35
@export_range(0.0, 1.0, 0.01) var moisture_max: float = 0.7
@export_range(0.0, 1.0, 0.01) var light_min: float = 0.35
@export_range(0.0, 1.0, 0.01) var light_max: float = 0.75
@export_range(-1, 1, 1) var open_window_preference: int = 0
@export_range(0.0, 0.01, 0.00001) var moisture_decay_per_second: float = 0.0005

@export_group("Growth")
@export_range(0.00001, 0.1, 0.00001) var base_growth_per_second: float = 0.002

@export_group("Fruiting")
@export_range(0.0, 1.0, 0.01) var fruiting_growth_threshold: float = 0.72
@export_range(1.0, 3600.0, 1.0) var fruit_ripen_seconds: float = 90.0
@export var fruit_base_value: int = 35

@export_group("Economy")
@export var base_sale_value: int = 100
