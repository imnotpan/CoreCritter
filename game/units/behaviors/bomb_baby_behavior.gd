class_name BombBabyBehavior
extends UnitBehavior


func _init() -> void:
	signature_name = "Bigger Boom"
	mastery_name = "Massive Boom"


func on_attack(unit) -> void:
	unit.perform_base_attack(2.0 if unit.star_level >= 5 else (1.5 if unit.star_level >= 3 else 1.0))
