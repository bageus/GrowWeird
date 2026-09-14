class_name FertilizerDefinition
extends Resource

@export var id: StringName
@export var display_name_key: String = ""
@export var display_name: String = ""
@export var shop_price: int = 0
@export var sell_price: int = 0
@export var recycle_yield: int = 0
@export_range(0.0, 1.0, 0.0001) var drop_chance: float = 0.0
@export var rarity: String = ""
@export var target: String = ""
@export_multiline var effect_description: String = ""
@export var unlock_milestone_id: StringName
@export_range(0.0, 100.0, 0.1) var offer_weight: float = 1.0

# Hidden from the player. Keys are mutation axes, values are accumulated pressure.
@export var mutation_contributions: Dictionary = {}

# Optional immediate care effects. Keep keys canonical and documented before adding new ones.
@export var care_effects: Dictionary = {}
