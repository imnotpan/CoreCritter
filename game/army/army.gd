class_name Army
extends Node

const SPAWN_POINTS := [
	Vector2(34, 91), Vector2(200, 69), Vector2(366, 91),
	Vector2(366, 232), Vector2(200, 282), Vector2(34, 232),
	Vector2(104, 282), Vector2(296, 69),
]
const SPAWN_VARIATION := 9.0

@export var unit_scene: PackedScene

var units_parent: Node2D
var target: CoreTarget
var loadout: ArmyLoadout
var spawn_timers: Array[Timer] = []
var scheduled_data: Array[UnitData] = []
var spawn_count := 0
var active_counts: Dictionary = {}
var running := false


func configure(parent: Node2D, core: CoreTarget) -> void:
	units_parent = parent
	target = core


func set_loadout(army_loadout: ArmyLoadout) -> void:
	if loadout != null and loadout.changed.is_connected(_on_loadout_changed):
		loadout.changed.disconnect(_on_loadout_changed)
	loadout = army_loadout
	loadout.changed.connect(_on_loadout_changed)
	if running:
		_rebuild_schedules()


func start() -> void:
	running = true
	_rebuild_schedules()


func _rebuild_schedules() -> void:
	_clear_timers()
	if loadout == null:
		return
	var new_data := loadout.get_unit_data()
	for data: UnitData in new_data:
		if not scheduled_data.has(data):
			_spawn_unit(data)
		var timer := Timer.new()
		timer.wait_time = data.spawn_interval
		timer.timeout.connect(_spawn_unit.bind(data))
		add_child(timer)
		spawn_timers.append(timer)
		timer.start()
	scheduled_data = new_data


func stop() -> void:
	running = false
	_clear_timers()
	scheduled_data.clear()


func _clear_timers() -> void:
	for timer: Timer in spawn_timers:
		timer.stop()
		timer.queue_free()
	spawn_timers.clear()


func _on_loadout_changed() -> void:
	if running:
		_rebuild_schedules()


func _spawn_unit(data: UnitData) -> void:
	var active_count: int = active_counts.get(data, 0)
	if active_count >= data.max_active_instances:
		return
	var unit: Unit = unit_scene.instantiate() as Unit
	units_parent.add_child(unit)
	var spawn_position: Vector2 = SPAWN_POINTS[spawn_count % SPAWN_POINTS.size()]
	unit.position = spawn_position + Vector2(
		randf_range(-SPAWN_VARIATION, SPAWN_VARIATION),
		randf_range(-SPAWN_VARIATION, SPAWN_VARIATION)
	)
	spawn_count += 1
	active_counts[data] = active_count + 1
	unit.tree_exiting.connect(_on_unit_exiting.bind(unit, data))
	target.reserve_attack_position(unit, data.attack_profile)
	unit.configure(data, target)


func _on_unit_exiting(unit: Unit, data: UnitData) -> void:
	active_counts[data] = maxi(0, int(active_counts.get(data, 0)) - 1)
	if is_instance_valid(target):
		target.release_attack_position(unit)
