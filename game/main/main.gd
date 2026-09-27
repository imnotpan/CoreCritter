extends Node2D

const OverlayController = preload("res://game/desktop/overlay_controller.gd")

@export var development_cards: Array[CardData] = []

@onready var game_session: GameSession = $GameSession
@onready var status_label: Label = $UI/StatusLabel
@onready var coin_hud: Label = $UI/CoinHUD
@onready var army_builder: ArmyBuilder = $UI/ArmyBuilder
@onready var army_button: Button = $UI/ArmyButton

var collection := CardCollection.new()
var loadout := ArmyLoadout.new()


func _ready() -> void:
	OverlayController.configure(get_window())
	collection.configure(development_cards)
	for card: CardData in development_cards:
		collection.unlock(card)
	loadout.configure(collection, development_cards.slice(0, ArmyLoadout.SLOT_COUNT))
	game_session.set_loadout(loadout)
	army_builder.configure(collection, loadout)
	army_button.pressed.connect(army_builder.open)
	game_session.core_destroyed.connect(_on_core_destroyed)
	game_session.core_restored.connect(_on_core_restored)
	game_session.wallet.coins_changed.connect(coin_hud.show_coins)
	coin_hud.show_coins(game_session.wallet.coins)
	game_session.start()


func _on_core_destroyed() -> void:
	status_label.visible = true


func _on_core_restored() -> void:
	status_label.visible = false
