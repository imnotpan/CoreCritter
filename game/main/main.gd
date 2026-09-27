extends Node2D

const OverlayController = preload("res://game/desktop/overlay_controller.gd")

@export var development_cards: Array[CardData] = []
@export var basic_pack: PackData
@export var save_path := "user://progress.tres"

@onready var game_session: GameSession = $GameSession
@onready var status_label: Label = $UI/StatusLabel
@onready var hud: GameHUD = $UI/HUD
@onready var army_builder: ArmyBuilder = $UI/ArmyBuilder
@onready var pack_opening: PackOpening = $UI/PackOpening
@onready var world_select: WorldSelect = $UI/WorldSelect
@onready var flow: AppFlow = $UI/AppFlow
@onready var debug_pack_button: Button = $UI/DebugPackButton
@onready var debug_destroy_button: Button = $UI/DebugDestroy
@onready var debug_unlock_button: Button = $UI/DebugUnlock
@onready var debug_card_button: Button = $UI/DebugCard
@onready var debug_world_button: Button = $UI/DebugWorld
@onready var debug_inspect_button: Button = $UI/DebugInspect

var collection := CardCollection.new()
var deck := DeckLoadout.new()
var pack_generator := PackGenerator.new()
var selected_world: WorldData


func _ready() -> void:
	OverlayController.configure(get_window())
	collection.configure(development_cards)
	collection.set_wallet(game_session.wallet)
	for card: CardData in development_cards.slice(0, DeckLoadout.SLOT_COUNT):
		collection.add_copy(card)
	deck.configure(collection, development_cards.slice(0, DeckLoadout.SLOT_COUNT))
	selected_world = game_session.world_progression.worlds[0]
	if not save_path.is_empty() and ResourceLoader.exists(save_path):
		var saved := ResourceLoader.load(save_path, "", ResourceLoader.CACHE_MODE_IGNORE) as SaveData
		if saved != null:
			selected_world = saved.restore(collection, deck, game_session)
	army_builder.configure(collection, deck, game_session.wallet, game_session.world_progression)
	army_builder.set_world(selected_world)
	army_builder.world_requested.connect(_open_worlds)
	army_builder.start_requested.connect(_start_run)
	army_builder.back_requested.connect(_back_from_builder)
	army_builder.equip_requested.connect(func(index: int, card: CardData) -> void:
		if game_session.run == null:
			deck.equip(index, card)
	)
	army_builder.upgrade_requested.connect(func(card: CardData) -> void:
		if game_session.run == null and collection.upgrade(card.id):
			army_builder.show_upgrade(card)
	)
	army_builder.debug_copies_requested.connect(func(card: CardData) -> void:
		if OS.is_debug_build() and game_session.run == null:
			collection.add_copy(card, 10)
	)
	army_builder.debug_coins_requested.connect(func() -> void:
		if OS.is_debug_build() and game_session.run == null:
			game_session.wallet.add_coins(1000)
	)
	world_select.world_requested.connect(_select_world)
	flow.play_requested.connect(_show_pre_run)
	flow.collection_requested.connect(func() -> void:
		if game_session.run == null:
			flow.panel.hide()
			army_builder.open(true)
	)
	flow.settings_requested.connect(flow.show_settings)
	flow.continue_requested.connect(_show_pre_run)
	flow.exit_requested.connect(game_session.exit_run)
	hud.configure_interactions(game_session)
	hud.boon_requested.connect(game_session.choose_boon)
	hud.active_cards.command_requested.connect(game_session.request_command)
	hud.packs_button.pressed.connect(_open_packs)
	hud.pause_button.pressed.connect(flow.show_pause)
	pack_opening.open_requested.connect(_open_pack)
	pack_opening.configure_debug_cards(development_cards)
	game_session.pack_progress.progress_changed.connect(hud.show_pack_progress)
	game_session.pack_inventory.count_changed.connect(_show_pack_count)
	game_session.core_destroyed.connect(_on_core_destroyed)
	game_session.core_restored.connect(_on_core_restored)
	game_session.run_finished.connect(_on_run_finished)
	game_session.core.health_changed.connect(hud.show_core_health)
	game_session.world_progression.changed.connect(_show_world_progress)
	game_session.wallet.coins_changed.connect(hud.show_coins)
	hud.show_coins(game_session.wallet.coins)
	hud.show_pack_progress(game_session.pack_progress.progress)
	_show_pack_count(game_session.pack_inventory.get_pack_count())
	_show_world_progress()
	hud.show_core_health(game_session.core.current_hp, game_session.core.max_hp)
	collection.card_unlocked.connect(_on_card_unlocked)
	collection.cards_changed.connect(_save_progress)
	deck.changed.connect(_save_progress)
	game_session.wallet.coins_changed.connect(_save_progress)
	game_session.pack_inventory.count_changed.connect(_save_progress)
	game_session.world_progression.changed.connect(_save_progress)
	_setup_debug()
	hud.visible = false
	flow.show_menu()


func _show_pre_run() -> void:
	hud.visible = false
	status_label.visible = false
	pack_opening.hide()
	world_select.hide()
	flow.show_pre_run()
	army_builder.set_world(selected_world)
	army_builder.open()


func _back_from_builder() -> void:
	army_builder.hide()
	world_select.hide()
	flow.show_menu()


func _open_worlds() -> void:
	if game_session.run == null:
		world_select.show_worlds(game_session.world_progression)


func _select_world(world: WorldData) -> void:
	if game_session.run != null or not game_session.world_progression.is_unlocked(world):
		return
	selected_world = world
	army_builder.set_world(world)
	world_select.hide()
	_save_progress()


func _start_run() -> void:
	if flow.state != AppFlow.State.PRE_RUN or not game_session.start_run(selected_world, deck):
		return
	army_builder.hide()
	world_select.hide()
	hud.active_cards.configure(game_session.run.loadout, game_session.army, game_session.commands)
	hud.visible = true
	flow.show_active_run()
	_show_world_progress()
	hud.show_core_health(game_session.core.current_hp, game_session.core.max_hp)


func _on_core_destroyed(_data: CoreData) -> void:
	status_label.text = "CORE DESTROYED"
	status_label.visible = true


func _on_core_restored(_data: CoreData) -> void:
	status_label.visible = false
	_show_world_progress()


func _on_run_finished(finished: RunSession) -> void:
	hud.visible = false
	status_label.visible = false
	pack_opening.hide()
	flow.show_results(finished)
	_save_progress()


func _show_world_progress() -> void:
	hud.show_world_progress(game_session.run)


func _show_pack_count(count: int) -> void:
	hud.show_pack_count(count)
	pack_opening.set_pack_count(count)


func _open_packs() -> void:
	if flow.state == AppFlow.State.ACTIVE_RUN:
		pack_opening.show_inventory(basic_pack.display_name, game_session.pack_inventory.get_pack_count())


func _open_pack() -> void:
	if game_session.run == null or game_session.pack_inventory.get_pack_count() <= 0:
		return
	var results := pack_generator.generate(basic_pack, development_cards, collection)
	if results.size() != basic_pack.cards_per_pack or not game_session.pack_inventory.consume_pack():
		return
	var new_flags: Array[bool] = []
	var copies_before: Array[int] = []
	var copies_after: Array[int] = []
	var stars: Array[int] = []
	for card: CardData in results:
		new_flags.append(not collection.is_unlocked(card))
		copies_before.append(collection.get_owned_copies(card))
		collection.add_copy(card)
		copies_after.append(collection.get_owned_copies(card))
		stars.append(collection.get_star_level(card))
	pack_opening.show_results(basic_pack.display_name, results, new_flags, copies_before, copies_after, stars, true)


func _on_card_unlocked(card: CardData) -> void:
	if game_session.run != null:
		game_session.run.record_unlock(card)


func _setup_debug() -> void:
	if not OS.is_debug_build():
		return
	var runtime := RunDebugTools.new()
	runtime.session = game_session
	game_session.add_child(runtime)
	hud.debug_requested.connect(runtime.execute)
	debug_pack_button.pressed.connect(func() -> void: game_session.pack_inventory.add_pack())
	debug_destroy_button.pressed.connect(game_session.debug_destroy_core)
	debug_unlock_button.pressed.connect(game_session.debug_unlock_next_world)
	debug_card_button.pressed.connect(_debug_unlock_card)
	debug_world_button.pressed.connect(game_session.debug_complete_world)
	debug_inspect_button.pressed.connect(_debug_inspect)
	flow.play_requested.connect(_show_debug_buttons)
	flow.continue_requested.connect(_show_debug_buttons)


func _show_debug_buttons() -> void:
	for button: Button in [debug_pack_button, debug_destroy_button, debug_unlock_button, debug_card_button, debug_world_button, debug_inspect_button]:
		button.show()


func _debug_unlock_card() -> void:
	if game_session.run == null:
		return
	for card: CardData in collection.get_locked_cards():
		collection.add_copy(card)
		var cards: Array[CardData] = [card]
		var flags: Array[bool] = [true]
		var copies: Array[int] = [0]
		var stars: Array[int] = [collection.get_star_level(card)]
		pack_opening.show_results("DEBUG COLLECTION REWARD", cards, flags, copies, copies, stars, true)
		pack_opening.show()
		print("DEBUG unlocked: ", card.display_name, " — available next run")
		return


func _debug_inspect() -> void:
	print("DeckLoadout: ", deck.get_cards().map(func(card: CardData) -> String: return card.display_name))
	if game_session.run != null:
		print("RunLoadout: ", game_session.run.loadout.get_card_ids())
		for card: CardData in game_session.run.loadout.get_cards():
			print(card.display_name, " stars: ", game_session.run.loadout.get_star_level(card))


func _save_progress(_value: Variant = null) -> void:
	if save_path.is_empty():
		return
	var data := SaveData.capture(collection, deck, game_session, selected_world)
	var error := ResourceSaver.save(data, save_path)
	if error != OK:
		push_warning("Could not save progression: %s" % error_string(error))
