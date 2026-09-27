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
@export var respawn_delay := 10.0

var recovery_slots: Array[Dictionary] = []
var hp_multiplier := 1.0
var spawn_multiplier := 1.0
var attack_speed_bonus := 0.0
var extra_capacity: Dictionary = {}
var ricochet_bonus := 0.0
var shell_time := 0.0
var party_time := 0.0

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
		timer.wait_time = data.spawn_interval * spawn_multiplier
		timer.timeout.connect(_spawn_unit.bind(card))
		add_child(timer)
		spawn_timers.append(timer)
		timer.start()
	scheduled_cards = new_cards
	spawn_state_changed.emit()


func stop() -> void:
	running = false
	recovery_slots.clear()
	_clear_timers()
	scheduled_cards.clear()
	spawn_state_changed.emit()


func _clear_timers() -> void:
	for timer: Timer in spawn_timers:
		timer.stop()
		timer.queue_free()
	spawn_timers.clear()


func _spawn_unit(card: CardData, temporary_count: bool = false) -> Unit:
	if not running or target.current_hp <= 0.0:
		return null
	var data := card.unit_data
	var active_count: int = active_counts.get(data, 0)
	var blocked := 0
	for slot: Dictionary in recovery_slots:
		if slot.card == card:
			blocked += 1
	if not temporary_count and active_count + blocked >= capacity(card):
		return null
	var unit: Unit = unit_scene.instantiate() as Unit
	units_parent.add_child(unit)
	var spawn_position: Vector2 = SPAWN_POINTS[spawn_count % SPAWN_POINTS.size()]
	unit.position = spawn_position + Vector2(
		randf_range(-SPAWN_VARIATION, SPAWN_VARIATION),
		randf_range(-SPAWN_VARIATION, SPAWN_VARIATION)
	)
	spawn_count += 1
	unit.temporary = temporary_count
	if not temporary_count:
		active_counts[data] = active_count + 1
	active_units.append(unit)
	unit.knocked_out.connect(_on_ko.bind(card))
	unit.tree_exiting.connect(_on_unit_exiting.bind(unit, data))
	target.reserve_attack_position(unit, data.attack_profile)
	unit.configure(data, target, self, loadout.get_star_level(card))
	if shell_time > 0.0:
		unit.protect(0.4, shell_time)
	if party_time > 0.0:
		unit.apply_speed_effect(&"party", 1.25, party_time)
	_refresh_composition()
	spawn_state_changed.emit()
	return unit


func _on_unit_exiting(unit: Unit, data: UnitData) -> void:
	if not active_units.has(unit):
		return
	if not unit.temporary:
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
	if count_active(data) >= capacity(card):
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


func _process(delta: float) -> void:
	shell_time = maxf(0.0, shell_time - delta)
	party_time = maxf(0.0, party_time - delta)
	if not running:
		return
	for slot: Dictionary in recovery_slots.duplicate():
		slot.time -= delta
		if slot.time <= 0.0:
			recovery_slots.erase(slot)
			_spawn_unit(slot.card)


func _on_ko(unit: Unit, card: CardData) -> void:
	if running and not unit.temporary:
		recovery_slots.append({"card": card, "time": respawn_delay})
	_on_unit_exiting(unit, unit.data)


func capacity(card: CardData) -> int:
	return card.unit_data.max_active_instances + int(extra_capacity.get(card.id, 0))


func spawn_temporary(card: CardData, count: int, duration: float = 12.0) -> bool:
	for index: int in count:
		var unit := _spawn_unit(card, true)
		if unit == null:
			return false
		unit.lifetime = duration
	return true


func shell_up() -> bool:
	shell_time = 5.0
	for unit: Unit in active_units:
		unit.protect(0.4, shell_time)
	return true


func spore_party() -> bool:
	party_time = 6.0
	for unit: Unit in active_units:
		unit.apply_speed_effect(&"party", 1.25, party_time)
	return true


func reset_run_effects() -> void:
	recovery_slots.clear()
	hp_multiplier = 1.0
	spawn_multiplier = 1.0
	attack_speed_bonus = 0.0
	extra_capacity.clear()
	ricochet_bonus = 0.0
	shell_time = 0.0
	party_time = 0.0


func refresh_run_effects() -> void:
	for unit: Unit in active_units:
		var next_hp := roundi(unit.data.max_hp * hp_multiplier)
		unit.current_hp += next_hp - unit.max_hp
		unit.max_hp = next_hp
		unit.queue_redraw()
	for index: int in spawn_timers.size():
		spawn_timers[index].wait_time = scheduled_cards[index].unit_data.spawn_interval * spawn_multiplier


func clear_units() -> void:
	for unit: Unit in get_active_units():
		_on_unit_exiting(unit, unit.data)
		unit.queue_free()
