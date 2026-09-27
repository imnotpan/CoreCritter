class_name FrogBehavior
extends UnitBehavior


func _init() -> void:
	signature_name = "Ricochet"
	mastery_name = "Triple Burst"


func on_attack(unit) -> void:
	unit.attacks_made += 1
	unit.perform_base_attack(1.0, 0.5 if unit.star_level >= 3 else 0.0)
	if unit.star_level >= 5 and unit.attacks_made % 4 == 0:
		unit.perform_base_attack(0.65)
		unit.perform_base_attack(0.65)
