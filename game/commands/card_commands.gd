class_name CardCommands
extends RefCounted

var loadout: RunLoadout
var army: Army
var remaining: Dictionary = {}


func configure(snapshot: RunLoadout, player_army: Army) -> void:
	loadout = snapshot
	army = player_army
	remaining.clear()


func advance(delta: float) -> void:
	for card: CardData in remaining.keys():
		remaining[card] = maxf(0.0, float(remaining[card]) - delta)


func activate(card: CardData) -> bool:
	if loadout == null or not loadout.get_cards().has(card) or not army.running or army.target.current_hp <= 0.0:
		return false
	if float(remaining.get(card, 0.0)) > 0.0 or card.unit_data.behavior == null:
		return false
	var behavior := card.unit_data.behavior
	if not behavior.execute_command(army, card):
		return false
	remaining[card] = behavior.command_cooldown
	return true


func get_state(card: CardData) -> Dictionary:
	if card == null or loadout == null or not loadout.get_cards().has(card) or card.unit_data.behavior == null:
		return {"name": "", "status": "UNAVAILABLE", "progress": 0.0}
	var behavior := card.unit_data.behavior
	var time := float(remaining.get(card, 0.0))
	return {"name": behavior.command_name, "status": "%ds" % ceili(time) if time > 0.0 else "READY",
		"progress": 1.0 - time / behavior.command_cooldown}


func clear() -> void:
	loadout = null
	army = null
	remaining.clear()
