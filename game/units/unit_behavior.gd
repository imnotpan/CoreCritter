class_name UnitBehavior
extends Resource

@export var signature_name: String = ""
@export var mastery_name: String = ""


func on_attack(unit) -> void:
	unit.perform_base_attack()


func on_tick(_unit, _delta: float, _at_position: bool) -> void:
	pass


func on_army_changed(_unit) -> void:
	pass
