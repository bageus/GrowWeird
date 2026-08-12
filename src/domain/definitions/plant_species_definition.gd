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

@export_group("Lifecycle")
@export_range(0.05, 0.6, 0.01) var sprout_stage_end: float = 0.18
@export_range(0.2, 0.95, 0.01) var adult_growth_threshold: float = 0.65
@export var native_regrowth_enabled: bool = true
@export_range(1.0, 3600.0, 1.0) var native_regrowth_seconds: float = 120.0
@export_range(0.0, 1.0, 0.01) var native_regrowth_min_health: float = 0.62
@export_range(0.0, 1.0, 0.01) var native_regrowth_min_comfort: float = 0.62

@export_group("Fruiting")
@export_range(0.0, 1.0, 0.01) var fruiting_growth_threshold: float = 0.72
@export_range(1.0, 3600.0, 1.0) var fruit_ripen_seconds: float = 90.0
@export var fruit_base_value: int = 35

@export_group("Economy")
@export var base_sale_value: int = 100
@export var shop_seed_price: int = 0
@export_range(1, 100, 1) var unlock_pot_count: int = 1

@export_group("Presentation")
@export var wood_color: Color = Color(0.29, 0.18, 0.10)
@export var leaf_color: Color = Color(0.22, 0.58, 0.24)
@export var fruit_color: Color = Color(0.91, 0.42, 0.18)
@export_range(0.5, 1.5, 0.01) var stem_height_scale: float = 1.0
@export_range(0.5, 1.6, 0.01) var side_span_scale: float = 1.0
@export_range(0.2, 1.6, 0.01) var side_lift_scale: float = 1.0
@export_range(0.5, 1.6, 0.01) var leaf_scale: float = 1.0
