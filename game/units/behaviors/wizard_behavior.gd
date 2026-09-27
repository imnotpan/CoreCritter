class_name WizardBehavior
extends UnitBehavior


func _init() -> void:
	command_name = "METEOR"
	command_cooldown = 90.0
	signature_name = "Arcane Splash"
	mastery_name = "Greater Splash"


func on_attack(unit) -> void:
	unit.perform_base_attack(1.0, 0.6 if unit.star_level >= 5 else (0.35 if unit.star_level >= 3 else 0.0))


func execute_command(army: Army, card: CardData) -> bool:
	army.target.take_damage(StarStats.damage(card.unit_data.damage, army.loadout.get_star_level(card)) * 8)
	army.target.show_command_feedback("METEOR", Color(0.6, 0.7, 1.0))
	return true
