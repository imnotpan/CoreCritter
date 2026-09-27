class_name SlugBehavior
extends UnitBehavior


func _init() -> void:
	command_name = "SHELL UP"
	command_cooldown = 60.0
	signature_name = "Acid Trail"
	mastery_name = "Potent Acid"


func on_tick(unit, delta: float, at_position: bool) -> void:
	if unit.star_level < 3 or not at_position:
		return
	unit.ability_clock += delta
	if unit.ability_clock < 3.0:
		return
	unit.ability_clock = 0.0
	var zone_count := 0
	for child: Node in unit.get_children():
		if child is AcidZone and not child.is_queued_for_deletion():
			zone_count += 1
	if zone_count >= 2:
		return
	var zone := AcidZone.new()
	zone.target = unit.target
	zone.damage = maxi(1, roundi(unit.resolved_damage * (0.25 if unit.star_level >= 5 else 0.12)))
	zone.tick_interval = 0.55 if unit.star_level >= 5 else 0.8
	unit.add_child(zone)
	zone.global_position = unit.target.global_position + Vector2(randf_range(-18.0, 18.0), randf_range(-18.0, 18.0))


func execute_command(army: Army, card: CardData) -> bool:
	return army.shell_up()
