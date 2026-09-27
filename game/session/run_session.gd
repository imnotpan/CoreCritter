class_name RunSession
extends RefCounted

var world: WorldData:
	set(value):
		if world == null:
			world = value
var loadout: RunLoadout:
	set(value):
		if loadout == null:
			loadout = value
var cores_destroyed := 0
var coins_earned := 0
var packs_earned := 0
var new_cards: Array[CardData] = []
var completed := false
var current_core_index := 0


func get_current_core() -> CoreData:
	if current_core_index >= world.cores.size():
		return null
	return world.cores[current_core_index]


func advance() -> void:
	current_core_index += 1


func record_unlock(card: CardData) -> void:
	if not new_cards.has(card):
		new_cards.append(card)
