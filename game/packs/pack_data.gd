class_name PackData
extends Resource

@export var id: StringName
@export var display_name: String
@export_range(1, 20, 1) var cards_per_pack: int = 3
@export_range(0.0, 1000.0) var common_weight: float = 70.0
@export_range(0.0, 1000.0) var uncommon_weight: float = 25.0
@export_range(0.0, 1000.0) var rare_weight: float = 5.0
@export var guarantee_new_card_if_available: bool = true
