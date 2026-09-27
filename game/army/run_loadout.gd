class_name RunLoadout
extends RefCounted

var _sealed := false
var _cards: Array[CardData] = []:
	set(value):
		if not _sealed:
			_cards = value
var _stars: Array[int] = []:
	set(value):
		if not _sealed:
			_stars = value


static func from_deck(deck: DeckLoadout) -> RunLoadout:
	if deck == null or not deck.is_valid():
		return null
	var snapshot := RunLoadout.new()
	for card: CardData in deck.get_cards():
		snapshot._cards.append(card)
		snapshot._stars.append(deck.collection.get_star_level(card))
	snapshot._cards.make_read_only()
	snapshot._stars.make_read_only()
	snapshot._sealed = true
	return snapshot


func get_cards() -> Array[CardData]:
	return _cards.duplicate()


func get_card(index: int) -> CardData:
	return _cards[index] if index >= 0 and index < _cards.size() else null


func get_star_level(card: CardData) -> int:
	var index := _cards.find(card)
	return _stars[index] if index >= 0 else 0


func get_card_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for card: CardData in _cards:
		ids.append(card.id)
	return ids
