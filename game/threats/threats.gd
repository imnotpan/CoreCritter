class_name Threats
extends Node2D

signal fly_clicked

@export var fly_scene: PackedScene

@onready var spawn_timer: Timer = $SpawnTimer

var units_parent: Node2D
var active_fly: Fly


func _ready() -> void:
	spawn_timer.timeout.connect(_spawn_fly)


func configure(parent: Node2D) -> void:
	units_parent = parent


func start() -> void:
	_schedule_next()


func stop() -> void:
	spawn_timer.stop()
	if is_instance_valid(active_fly):
		active_fly.queue_free()


func _schedule_next() -> void:
	spawn_timer.start(randf_range(55.0, 90.0))


func _spawn_fly() -> void:
	_schedule_next()
	if is_instance_valid(active_fly) and not active_fly.removed:
		return
	var candidates: Array[Unit] = []
	for child: Node in units_parent.get_children():
		if child is Unit and not child.is_queued_for_deletion():
			candidates.append(child as Unit)
	if candidates.is_empty():
		return
	active_fly = fly_scene.instantiate() as Fly
	add_child(active_fly)
	active_fly.attach(candidates.pick_random(), units_parent)
	active_fly.clicked.connect(func() -> void: fly_clicked.emit())
