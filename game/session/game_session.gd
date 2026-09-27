class_name GameSession
extends Node2D

signal core_destroyed
signal core_restored

@onready var army: Army = $Army
@onready var units: Node2D = $Units
@onready var core: CoreTarget = $CoreTarget
@onready var threats: Threats = $Threats
@onready var wallet: Wallet = $Wallet

@export var seconds_per_pack: float = 600.0
@export var core_destroyed_progress_bonus: float = 0.25

var pack_progress := PackProgress.new()
var pack_inventory := PackInventory.new()
var resetting := false


func _ready() -> void:
	pack_progress.seconds_per_pack = seconds_per_pack
	pack_progress.core_destroyed_progress_bonus = core_destroyed_progress_bonus
	pack_progress.packs_earned.connect(pack_inventory.add_pack)
	army.configure(units, core)
	threats.configure(units)
	threats.fly_clicked.connect(_on_fly_clicked)
	core.destroyed.connect(_on_core_destroyed)


func _process(delta: float) -> void:
	pack_progress.advance_time(delta)


func start() -> void:
	army.start()
	threats.start()


func set_loadout(loadout: ArmyLoadout) -> void:
	army.set_loadout(loadout)


func _on_fly_clicked() -> void:
	wallet.add_coins(10)


func _on_core_destroyed() -> void:
	if resetting:
		return
	resetting = true
	army.stop()
	wallet.add_coins(50)
	pack_progress.on_core_destroyed()
	for unit: Node in units.get_children():
		unit.queue_free()
	core_destroyed.emit()
	await get_tree().create_timer(3.0).timeout
	core.reset()
	resetting = false
	core_restored.emit()
	army.start()
