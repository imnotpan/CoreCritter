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


const BOON_POOL: Array[BoonData] = [
	preload("res://game/boons/frog_business.tres"),
	preload("res://game/boons/chicken_union.tres"),
	preload("res://game/boons/fast_delivery.tres"),
	preload("res://game/boons/health_plan.tres"),
	preload("res://game/boons/overtime.tres"),
]
var pending_boons: Array[BoonData] = []
var chosen_boons: Array[BoonData] = []


func offer_boon() -> void:
	if not pending_boons.is_empty():
		return
	var pool := BOON_POOL.duplicate()
	pool.shuffle()
	pending_boons.assign(pool.slice(0, 3))


func choose_boon(boon: BoonData, army: Army) -> bool:
	if not pending_boons.has(boon):
		return false
	boon.apply(army)
	chosen_boons.append(boon)
	pending_boons.clear()
	return true


func clear_boons() -> void:
	pending_boons.clear()
	chosen_boons.clear()
