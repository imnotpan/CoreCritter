class_name CardData
extends Resource

enum Rarity { COMMON, UNCOMMON, RARE }

@export var id: StringName
@export var display_name: String
@export var unit_data: UnitData
@export var rarity: Rarity = Rarity.COMMON
@export_multiline var description: String
@export var icon: Texture2D


func rarity_name() -> String:
	return Rarity.keys()[rarity].capitalize()
