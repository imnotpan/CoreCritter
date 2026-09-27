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


@onready var boon_button: Button = $Bottom/Rows/Footer/BoonButton
@onready var boon_choices: PanelContainer = $BoonChoices
var regroup_label: Label
var session: GameSession

signal boon_requested(boon: BoonData)
signal debug_requested(action: StringName)


func configure_interactions(game: GameSession) -> void:
	session = game
	boon_button.pressed.connect(func() -> void: boon_choices.visible = not boon_choices.visible)
	regroup_label = Label.new()
	regroup_label.position = Vector2(8, 42)
	regroup_label.text = "REGROUPING…"
	regroup_label.add_theme_font_size_override("font_size", 10)
	regroup_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(regroup_label)
	game.boon_changed.connect(_refresh_boons)
	game.army.spawn_state_changed.connect(_refresh_regroup)
	_refresh_boons()
	_refresh_regroup()
	if OS.is_debug_build():
		_add_run_debug()


func _refresh_regroup() -> void:
	regroup_label.visible = session.run != null and session.army.running and session.army.get_active_units().is_empty()


func _refresh_boons() -> void:
	boon_choices.hide()
	for child: Node in boon_choices.get_children():
		boon_choices.remove_child(child)
		child.queue_free()
	var options: Array[BoonData] = []
	if session.run != null:
		options.assign(session.run.pending_boons)
	boon_button.visible = not options.is_empty()
	var column := VBoxContainer.new()
	boon_choices.add_child(column)
	for boon: BoonData in options:
		var button := Button.new()
		button.text = boon.display_name
		button.tooltip_text = boon.description
		button.add_theme_font_size_override("font_size", 10)
		button.pressed.connect(func() -> void: boon_requested.emit(boon))
		column.add_child(button)
		var description := Label.new()
		description.text = boon.description
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.add_theme_font_size_override("font_size", 9)
		description.add_theme_color_override("font_color", Color("9da9ad"))
		description.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(description)
	var later := Button.new()
	later.text = "LATER"
	later.pressed.connect(boon_choices.hide)
	column.add_child(later)


func _add_run_debug() -> void:
	var menu: MenuButton = $Bottom/Rows/Footer/DebugMenu
	menu.show()
	menu.get_popup().max_size = Vector2i(240, 220)
	var actions: Array[StringName] = [
		&"unlock_card", &"finish_run", &"inspect_decks", &"unlock_next", &"add_pack", &"kill_core",
		&"damage_unit", &"ko_unit", &"ko_all", &"core_ability", &"threat", &"reset_commands",
		&"frog", &"slug", &"chicken", &"wizard", &"bomb_baby", &"mushroom", &"grant_boon",
		&"frog_business", &"chicken_union", &"fast_delivery", &"health_plan", &"overtime",
	]
	for action: StringName in actions:
		menu.get_popup().add_item(String(action).replace("_", " ").to_upper())
	menu.get_popup().id_pressed.connect(func(index: int) -> void: debug_requested.emit(actions[index]))


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_node_ready():
		boon_choices.hide()
		var menu: MenuButton = $Bottom/Rows/Footer/DebugMenu
		menu.get_popup().hide()
