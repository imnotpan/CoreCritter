class_name DeckLoadout
extends RefCounted

signal changed

const SLOT_COUNT := 3

var collection: CardCollection
var slots: Array[CardData] = []


func configure(card_collection: CardCollection, initial_cards: Array[CardData]) -> void:
	if collection != null and collection.cards_changed.is_connected(_on_collection_changed):
		collection.cards_changed.disconnect(_on_collection_changed)
	collection = card_collection
	collection.cards_changed.connect(_on_collection_changed)
	slots.clear()
	for card: CardData in initial_cards:
		if slots.size() >= SLOT_COUNT or card == null or not collection.is_unlocked(card) or _index_for_id(card.id) >= 0 or card.unit_data == null:
			continue
		slots.append(card)
	changed.emit()


func is_valid() -> bool:
	if collection == null or slots.size() != SLOT_COUNT:
		return false
	var ids: Array[StringName] = []
	for card: CardData in slots:
		if card == null or card.unit_data == null or not collection.is_unlocked(card) or ids.has(card.id):
			return false
		ids.append(card.id)
	return true


func get_cards() -> Array[CardData]:
	return slots.duplicate()


func get_unit_data() -> Array[UnitData]:
	var units: Array[UnitData] = []
	for card: CardData in slots:
		if card != null:
			units.append(card.unit_data)
	return units


func equip(slot_index: int, card: CardData) -> bool:
	if slot_index < 0 or slot_index >= slots.size():
		return false
	if card == null or not collection.is_unlocked(card) or card.unit_data == null:
		return false
	var previous_index := _index_for_id(card.id)
	if previous_index == slot_index:
		return true
	if previous_index >= 0:
		slots[previous_index] = slots[slot_index]
	slots[slot_index] = card
	changed.emit()
	return true


func _index_for_id(card_id: StringName) -> int:
	for index: int in slots.size():
		if slots[index] != null and slots[index].id == card_id:
			return index
	return -1


func _on_collection_changed() -> void:
	var updated := false
	for index: int in range(slots.size()):
		if slots[index] == null or collection.is_unlocked(slots[index]):
			continue
		var replacement: CardData
		for card: CardData in collection.get_unlocked_cards():
			if card.unit_data != null and not slots.has(card):
				replacement = card
				break
		slots[index] = replacement
		updated = true
	if updated:
		changed.emit()
