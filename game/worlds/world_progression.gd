class_name WorldProgression
extends RefCounted

signal changed
signal world_completed(world: WorldData, first_clear: bool)
signal world_unlocked(world: WorldData)

var worlds: Array[WorldData] = []
var unlocked_worlds: Dictionary = {}
var completed_worlds: Dictionary = {}


func configure(content: Array[WorldData]) -> void:
	worlds = content.duplicate()
	unlocked_worlds.clear()
	completed_worlds.clear()
	if not worlds.is_empty():
		unlocked_worlds[worlds[0].id] = true


func is_unlocked(world: WorldData) -> bool:
	return world != null and unlocked_worlds.has(world.id)


func is_completed(world: WorldData) -> bool:
	return world != null and completed_worlds.has(world.id)


func complete_world(world: WorldData) -> bool:
	if not worlds.has(world) or not is_unlocked(world):
		return false
	var first_clear := not is_completed(world)
	completed_worlds[world.id] = true
	unlock_next_world(world)
	world_completed.emit(world, first_clear)
	changed.emit()
	return first_clear


func unlock_next_world(world: WorldData) -> void:
	var next_index := worlds.find(world) + 1
	if next_index > 0 and next_index < worlds.size() and not is_unlocked(worlds[next_index]):
		unlocked_worlds[worlds[next_index].id] = true
		world_unlocked.emit(worlds[next_index])
		changed.emit()
