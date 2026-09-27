class_name MushroomBehavior
extends UnitBehavior


func _init() -> void:
	signature_name = "Spore Boost"
	mastery_name = "Super Spores"


func on_tick(unit, delta: float, _at_position: bool) -> void:
	if unit.star_level < 3:
		return
	unit.ability_clock += delta
	if unit.ability_clock < 3.0:
		return
	unit.ability_clock = 0.0
	var bonus := 0.25 if unit.star_level >= 5 else 0.15
	var duration := 6.0 if unit.star_level >= 5 else 4.0
	for ally: Unit in unit.army.get_active_units():
		if ally != unit and ally.global_position.distance_to(unit.global_position) <= 95.0:
			ally.apply_spore_bonus(bonus, duration)
