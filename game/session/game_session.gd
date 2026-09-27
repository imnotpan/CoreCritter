class_name GameSession
extends Node2D

signal core_destroyed(data: CoreData)
signal core_restored(data: CoreData)
signal run_finished(run: RunSession)

@onready var army: Army = $Army
@onready var units: Node2D = $Units
@onready var core: CoreTarget = $CoreTarget
@onready var threats: Threats = $Threats
@onready var wallet: Wallet = $Wallet

@export var seconds_per_pack: float = 600.0
@export var worlds: Array[WorldData] = []

var pack_progress := PackProgress.new()
var pack_inventory := PackInventory.new()
var world_progression := WorldProgression.new()
var transitioning := false
var transition_version := 0
var run: RunSession


func _ready() -> void:
	pack_progress.seconds_per_pack = seconds_per_pack
	pack_progress.packs_earned.connect(_earn_packs)
	world_progression.configure(worlds)
	world_progression.world_completed.connect(_on_world_completed)
	army.configure(units, core)
	threats.configure(units)
	threats.fly_clicked.connect(_on_fly_clicked)
	core.destroyed.connect(_on_core_destroyed)


func _process(delta: float) -> void:
	if run != null:
		pack_progress.advance_time(delta)


func start_run(world: WorldData, deck: DeckLoadout) -> bool:
	if run != null or not world_progression.is_unlocked(world) or not world_progression.worlds.has(world):
		return false
	var snapshot := RunLoadout.from_deck(deck)
	if snapshot == null or world.cores.is_empty():
		return false
	run = RunSession.new()
	run.world = world
	run.loadout = snapshot
	core.configure(run.get_current_core())
	army.set_loadout(snapshot)
	army.start()
	threats.start()
	core_restored.emit(core.data)
	return true


func _on_fly_clicked() -> void:
	if run == null:
		return
	wallet.add_coins(10)
	run.coins_earned += 10


func exit_run() -> void:
	if run == null:
		return
	transition_version += 1
	transitioning = false
	army.stop()
	threats.stop()
	_clear_units()
	var finished := run
	run = null
	run_finished.emit(finished)


func complete_run() -> bool:
	if run == null or run.get_current_core() != null:
		return false
	run.completed = true
	world_progression.complete_world(run.world)
	exit_run()
	return true


func _clear_units() -> void:
	for unit: Node in units.get_children():
		unit.queue_free()


func _on_world_completed(_world: WorldData, first_clear: bool) -> void:
	if first_clear:
		_earn_packs(1)


func _on_core_destroyed(data: CoreData) -> void:
	if run == null or transitioning or run.get_current_core() != data:
		return
	transitioning = true
	army.stop()
	wallet.add_coins(data.coin_reward)
	run.coins_earned += data.coin_reward
	run.cores_destroyed += 1
	pack_progress.add_progress(data.pack_progress_reward)
	_clear_units()
	core_destroyed.emit(data)
	var version := transition_version
	await get_tree().create_timer(2.5).timeout
	if version != transition_version:
		return
	run.advance()
	transitioning = false
	var next_core := run.get_current_core()
	if next_core != null:
		core.configure(next_core)
		core_restored.emit(next_core)
		army.start()
	else:
		complete_run()


func debug_destroy_core() -> void:
	if OS.is_debug_build() and not transitioning and core.current_hp > 0.0:
		core.take_damage(ceili(core.current_hp * 2.0))


func debug_unlock_next_world() -> void:
	if OS.is_debug_build():
		world_progression.unlock_next_world(run.world if run != null else worlds[0])


func _earn_packs(amount: int = 1) -> void:
	pack_inventory.add_pack(amount)
	if run != null:
		run.packs_earned += amount


func debug_complete_world() -> void:
	if not OS.is_debug_build():
		return
	var original := run
	while run != null and run == original:
		debug_destroy_core()
		await get_tree().create_timer(2.6).timeout
