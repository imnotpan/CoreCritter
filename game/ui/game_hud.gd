class_name GameHUD
extends Control

const ActiveCardStrip = preload("res://game/ui/active_card_strip.gd")

@onready var active_cards: ActiveCardStrip = $Bottom/Rows/ActiveCardStrip
@onready var packs_button: Button = $Bottom/Rows/Footer/PacksButton
@onready var pause_button: Button = $Bottom/Rows/Footer/PauseButton
@onready var coins_label: Label = $Bottom/Rows/Footer/Coins
@onready var pack_count_label: Label = $Bottom/Rows/Footer/Packs
@onready var pack_progress_label: Label = $Bottom/Rows/Footer/PackProgress
@onready var world_label: Label = $Top/Rows/Identity/WorldProgress
@onready var core_label: Label = $Top/Rows/Identity/CoreName
@onready var boss_label: Label = $Top/Rows/Identity/Boss
@onready var core_health: ProgressBar = $Top/Rows/HealthRow/CoreHealth
@onready var health_percent: Label = $Top/Rows/HealthRow/HealthPercent


func show_coins(coins: int) -> void:
	coins_label.text = "COINS %d" % coins


func show_pack_count(count: int) -> void:
	pack_count_label.text = "PACKS %d" % count


func show_pack_progress(progress: float) -> void:
	pack_progress_label.text = "PACK %d%%" % floori(progress * 100.0)


func show_world_progress(run: RunSession) -> void:
	var world: WorldData = run.world if run != null else null
	if world == null:
		world_label.text = "NO WORLD"
		core_label.text = ""
		boss_label.visible = false
		return
	world_label.text = "%s %d/%d" % [world.display_name.to_upper(), run.current_core_index + 1, world.cores.size()]
	var data := run.get_current_core()
	core_label.text = data.display_name.to_upper() if data != null else "WORLD COMPLETE"
	boss_label.visible = data != null and data.is_boss
	if data == null:
		show_core_health(0.0, 1.0)


func show_core_health(current: float, maximum: float) -> void:
	core_health.max_value = maxf(maximum, 1.0)
	core_health.value = current
	health_percent.text = "%d%%" % roundi(100.0 * current / maxf(maximum, 1.0))
