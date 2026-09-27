class_name Army
extends Node

signal spawn_state_changed

const SPAWN_POINTS := [
	Vector2(34, 91), Vector2(200, 69), Vector2(366, 91),
	Vector2(366, 232), Vector2(200, 282), Vector2(34, 232),
	Vector2(104, 282), Vector2(296, 69),
]
const SPAWN_VARIATION := 9.0

@export var unit_scene: PackedScene

var units_parent: Node2D
var target: CoreTarget
var loadout: RunLoadout
var spawn_timers: Array[Timer] = []
var scheduled_cards: Array[CardData] = []
var spawn_count := 0
var active_counts: Dictionary = {}
var active_units: Array[Unit] = []
var running := false


func configure(parent: Node2D, core: CoreTarget) -> void:
	units_parent = parent
	target = core


func set_loadout(run_loadout: RunLoadout) -> void:
	if running:
		return
	loadout = run_loadout


func start() -> void:
	running = true
	_rebuild_schedules()


func _rebuild_schedules() -> void:
	_clear_timers()
	if loadout == null:
		return
	var new_cards := loadout.get_cards()
	for card: CardData in new_cards:
		var data := card.unit_data
		if not scheduled_cards.has(card):
			_spawn_unit(card)
		var timer := Timer.new()
		timer.wait_time = data.spawn_interval
		timer.timeout.connect(_spawn_unit.bind(card))
		add_child(timer)
		spawn_timers.append(timer)
		timer.start()
	scheduled_cards = new_cards
	spawn_state_changed.emit()


func stop() -> void:
	running = false
	_clear_timers()
	scheduled_cards.clear()
	spawn_state_changed.emit()


func _clear_timers() -> void:
	for timer: Timer in spawn_timers:
		timer.stop()
		timer.queue_free()
	spawn_timers.clear()


func _spawn_unit(card: CardData) -> void:
	var data := card.unit_data
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
	active_units.append(unit)
	unit.tree_exiting.connect(_on_unit_exiting.bind(unit, data))
	target.reserve_attack_position(unit, data.attack_profile)
	unit.configure(data, target, self, loadout.get_star_level(card))
	_refresh_composition()
	spawn_state_changed.emit()


func _on_unit_exiting(unit: Unit, data: UnitData) -> void:
	active_counts[data] = maxi(0, int(active_counts.get(data, 0)) - 1)
	active_units.erase(unit)
	_refresh_composition()
	spawn_state_changed.emit()
	if is_instance_valid(target):
		target.release_attack_position(unit)


func count_active(data: UnitData) -> int:
	return int(active_counts.get(data, 0))


func get_spawn_state(card: CardData) -> Dictionary:
	if card == null or card.unit_data == null or loadout == null or not loadout.get_cards().has(card):
		return {"status": "UNAVAILABLE", "progress": 0.0}
	if not running:
		return {"status": "PAUSED", "progress": 0.0}
	var data := card.unit_data
	if count_active(data) >= data.max_active_instances:
		return {"status": "MAX ACTIVE", "progress": 1.0}
	var index := scheduled_cards.find(card)
	if index < 0 or index >= spawn_timers.size():
		return {"status": "READY", "progress": 1.0}
	var timer := spawn_timers[index]
	return {"status": "COOLDOWN", "progress": clampf(1.0 - timer.time_left / timer.wait_time, 0.0, 1.0)}


func get_active_units() -> Array[Unit]:
	return active_units.duplicate()


func _refresh_composition() -> void:
	for unit: Unit in active_units:
		unit.on_army_changed()
