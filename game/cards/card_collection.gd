class_name CardCollection
extends RefCounted

signal cards_changed
signal card_unlocked(card: CardData)
signal card_upgraded(card: CardData, star_level: int)

var cards: Array[CardData] = []
var owned_copies: Dictionary = {}
var star_levels: Dictionary = {}
var wallet: Wallet
var progression_config: StarProgressionConfig = preload("res://game/cards/star_progression.tres")


func configure(available_cards: Array[CardData]) -> void:
	cards = available_cards.duplicate()
	owned_copies.clear()
	star_levels.clear()
	cards_changed.emit()


func set_wallet(value: Wallet) -> void:
	wallet = value


func get_owned_cards() -> Array[CardData]:
	return get_unlocked_cards()


func get_unlocked_cards() -> Array[CardData]:
	var owned: Array[CardData] = []
	for card: CardData in cards:
		if is_unlocked(card):
			owned.append(card)
	return owned


func get_locked_cards() -> Array[CardData]:
	var locked: Array[CardData] = []
	for card: CardData in cards:
		if not is_unlocked(card):
			locked.append(card)
	return locked


func is_unlocked(card: CardData) -> bool:
	return get_star_level(card) > 0


func get_star_level(card: CardData) -> int:
	if card == null or not cards.has(card):
		return 0
	return int(star_levels.get(card.id, 0))


func get_owned_copies(card: CardData) -> int:
	if card == null or not cards.has(card):
		return 0
	return int(owned_copies.get(card.id, 0))


func add_copy(card: CardData, amount: int = 1) -> void:
	if card == null or not cards.has(card) or amount <= 0:
		return
	var was_locked := not is_unlocked(card)
	if was_locked:
		star_levels[card.id] = 1
		amount -= 1
		card_unlocked.emit(card)
	owned_copies[card.id] = get_owned_copies(card) + amount
	cards_changed.emit()


func get_card(card_id: StringName) -> CardData:
	for card: CardData in cards:
		if card.id == card_id:
			return card
	return null


func get_upgrade_cost(card_id: StringName) -> Vector2i:
	return progression_config.cost_for(get_star_level(get_card(card_id)))


func can_upgrade(card_id: StringName) -> bool:
	var card := get_card(card_id)
	if card == null or not is_unlocked(card) or get_star_level(card) >= 5 or wallet == null:
		return false
	var cost := get_upgrade_cost(card_id)
	return get_owned_copies(card) >= cost.x and wallet.can_spend(cost.y)


func upgrade(card_id: StringName) -> bool:
	if not can_upgrade(card_id):
		return false
	var card := get_card(card_id)
	var cost := get_upgrade_cost(card_id)
	if not wallet.spend(cost.y):
		return false
	owned_copies[card.id] = get_owned_copies(card) - cost.x
	star_levels[card.id] = get_star_level(card) + 1
	card_upgraded.emit(card, get_star_level(card))
	cards_changed.emit()
	return true
