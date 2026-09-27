class_name CardCollection
extends RefCounted

signal cards_changed
signal card_unlocked(card: CardData)

var cards: Array[CardData] = []
var owned_copies: Dictionary = {}


func configure(available_cards: Array[CardData]) -> void:
	cards = available_cards.duplicate()
	owned_copies.clear()
	cards_changed.emit()


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
	return get_owned_copies(card) > 0


func get_owned_copies(card: CardData) -> int:
	if card == null or not cards.has(card):
		return 0
	return int(owned_copies.get(card.id, 0))


func add_copy(card: CardData, amount: int = 1) -> void:
	if card == null or not cards.has(card) or amount <= 0:
		return
	var was_locked := not is_unlocked(card)
	owned_copies[card.id] = get_owned_copies(card) + amount
	if was_locked:
		card_unlocked.emit(card)
	cards_changed.emit()
