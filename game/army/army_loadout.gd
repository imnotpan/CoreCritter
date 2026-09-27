class_name ArmyLoadout
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
		if slots.size() >= SLOT_COUNT or not collection.is_unlocked(card) or slots.has(card) or card.unit_data == null:
			continue
		slots.append(card)
	assert(slots.size() == SLOT_COUNT, "ArmyLoadout needs three distinct unlocked cards with UnitData.")
	changed.emit()


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
	if not collection.is_unlocked(card) or card.unit_data == null:
		return false
	var previous_index := slots.find(card)
	if previous_index == slot_index:
		return true
	if previous_index >= 0:
		slots[previous_index] = slots[slot_index]
	slots[slot_index] = card
	changed.emit()
	return true


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
