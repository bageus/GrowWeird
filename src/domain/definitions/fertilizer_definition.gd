class_name FertilizerDefinition
extends Resource

@export var id: StringName
@export var display_name_key: String = ""
@export var shop_price: int = 0

# Hidden from the player. Keys are mutation axes, values are accumulated pressure.
@export var mutation_contributions: Dictionary = {}

# Optional immediate care effects. Keep keys canonical and documented before adding new ones.
@export var care_effects: Dictionary = {}
