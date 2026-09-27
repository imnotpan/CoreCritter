class_name WizardBehavior
extends UnitBehavior


func _init() -> void:
	signature_name = "Arcane Splash"
	mastery_name = "Greater Splash"


func on_attack(unit) -> void:
	unit.perform_base_attack(1.0, 0.6 if unit.star_level >= 5 else (0.35 if unit.star_level >= 3 else 0.0))
