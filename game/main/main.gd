extends Node2D

const OverlayController = preload("res://game/desktop/overlay_controller.gd")

@export var development_cards: Array[CardData] = []
@export var basic_pack: PackData

@onready var game_session: GameSession = $GameSession
@onready var status_label: Label = $UI/StatusLabel
@onready var coin_hud: Label = $UI/CoinHUD
@onready var army_builder: ArmyBuilder = $UI/ArmyBuilder
@onready var army_button: Button = $UI/ArmyButton
@onready var pack_progress_label: Label = $UI/PackProgress
@onready var pack_count_label: Label = $UI/PackCount
@onready var packs_button: Button = $UI/PacksButton
@onready var debug_pack_button: Button = $UI/DebugPackButton
@onready var pack_opening: PackOpening = $UI/PackOpening

var collection := CardCollection.new()
var loadout := ArmyLoadout.new()
var pack_generator := PackGenerator.new()


func _ready() -> void:
	OverlayController.configure(get_window())
	collection.configure(development_cards)
	collection.set_wallet(game_session.wallet)
	for card: CardData in development_cards.slice(0, ArmyLoadout.SLOT_COUNT):
		collection.add_copy(card)
	loadout.configure(collection, development_cards.slice(0, ArmyLoadout.SLOT_COUNT))
	game_session.set_loadout(loadout)
	army_builder.configure(collection, loadout, game_session.wallet)
	army_button.pressed.connect(army_builder.open)
	packs_button.pressed.connect(_open_packs)
	pack_opening.open_requested.connect(_open_pack)
	game_session.pack_progress.progress_changed.connect(_show_pack_progress)
	game_session.pack_inventory.count_changed.connect(_show_pack_count)
	debug_pack_button.visible = OS.is_debug_build()
	if OS.is_debug_build():
		debug_pack_button.pressed.connect(func() -> void: game_session.pack_inventory.add_pack())
	_show_pack_progress(game_session.pack_progress.progress)
	_show_pack_count(game_session.pack_inventory.get_pack_count())
	game_session.core_destroyed.connect(_on_core_destroyed)
	game_session.core_restored.connect(_on_core_restored)
	game_session.wallet.coins_changed.connect(coin_hud.show_coins)
	coin_hud.show_coins(game_session.wallet.coins)
	game_session.start()


func _on_core_destroyed() -> void:
	status_label.visible = true


func _on_core_restored() -> void:
	status_label.visible = false


func _show_pack_progress(progress: float) -> void:
	pack_progress_label.text = "PACK %d%%" % floori(progress * 100.0)


func _show_pack_count(count: int) -> void:
	pack_count_label.text = "PACKS x%d" % count
	pack_opening.set_pack_count(count)


func _open_packs() -> void:
	army_builder.hide()
	pack_opening.show_inventory(basic_pack.display_name, game_session.pack_inventory.get_pack_count())


func _open_pack() -> void:
	if game_session.pack_inventory.get_pack_count() <= 0:
		return
	var results := pack_generator.generate(basic_pack, development_cards, collection)
	if results.size() != basic_pack.cards_per_pack:
		return
	if not game_session.pack_inventory.consume_pack():
		return
	var new_flags: Array[bool] = []
	for card: CardData in results:
		new_flags.append(not collection.is_unlocked(card))
		collection.add_copy(card)
	pack_opening.show_results(basic_pack.display_name, results, new_flags)
