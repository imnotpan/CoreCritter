class_name ChickenBehavior
extends UnitBehavior


func _init() -> void:
	command_name = "STAMPEDE"
	command_cooldown = 60.0
	signature_name = "Frenzy"
	mastery_name = "Swarm Frenzy"


func on_army_changed(unit) -> void:
	var enabled := false
	var mastered := false
	for ally in unit.army.get_active_units():
		if ally.data == unit.data and ally.star_level >= 3:
			enabled = true
			mastered = mastered or ally.star_level >= 5
	if not enabled:
		unit.army_speed_bonus = 0.0
		return
	var count: int = unit.army.count_active(unit.data)
	var bonus_per := 0.07 if mastered else 0.05
	var cap := 0.4 if mastered else 0.25
	unit.army_speed_bonus = minf(cap, count * bonus_per)


func execute_command(army: Army, card: CardData) -> bool:
	return army.spawn_temporary(card, 4)
