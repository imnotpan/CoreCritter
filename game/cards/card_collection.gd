class_name CardCollection
extends RefCounted

signal cards_changed

var cards: Array[CardData] = []
var unlocked_ids: Dictionary = {}


func configure(available_cards: Array[CardData]) -> void:
	cards = available_cards.duplicate()
	unlocked_ids.clear()
	cards_changed.emit()


func get_owned_cards() -> Array[CardData]:
	var owned: Array[CardData] = []
	for card: CardData in cards:
		if is_unlocked(card):
			owned.append(card)
	return owned


func get_unlocked_cards() -> Array[CardData]:
	return get_owned_cards()


func get_locked_cards() -> Array[CardData]:
	var locked: Array[CardData] = []
	for card: CardData in cards:
		if not is_unlocked(card):
			locked.append(card)
	return locked


func is_unlocked(card: CardData) -> bool:
	return card != null and cards.has(card) and unlocked_ids.has(card.id)


func unlock(card: CardData) -> void:
	if card == null or not cards.has(card) or is_unlocked(card):
		return
	unlocked_ids[card.id] = true
	cards_changed.emit()


func lock(card: CardData) -> void:
	if card == null or not is_unlocked(card):
		return
	unlocked_ids.erase(card.id)
	cards_changed.emit()
