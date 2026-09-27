class_name WorldSelect
extends Control

signal world_requested(world: WorldData)

@onready var world_list: VBoxContainer = $Panel/WorldList


func show_worlds(progression: WorldProgression) -> void:
	for child: Node in world_list.get_children():
		child.queue_free()
	for world: WorldData in progression.worlds:
		var button := Button.new()
		button.custom_minimum_size = Vector2(350, 48)
		var state := "LOCKED"
		if progression.is_completed(world):
			state = "COMPLETED"
		elif progression.is_unlocked(world):
			state = "UNLOCKED"
		button.text = "%s  —  %s" % [world.display_name.to_upper(), state]
		button.disabled = not progression.is_unlocked(world)
		button.pressed.connect(_request_world.bind(world))
		world_list.add_child(button)
	show()


func _request_world(world: WorldData) -> void:
	world_requested.emit(world)
