class_name PackGenerator
extends RefCounted


func generate(pack: PackData, available_cards: Array[CardData], collection: CardCollection, rng: RandomNumberGenerator = null) -> Array[CardData]:
	var results: Array[CardData] = []
	if pack == null or collection == null or available_cards.is_empty():
		return results
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var valid_cards: Array[CardData] = []
	for card: CardData in available_cards:
		if card != null and collection.cards.has(card):
			valid_cards.append(card)
	if valid_cards.is_empty():
		return results
	if pack.guarantee_new_card_if_available:
		var locked: Array[CardData] = []
		for card: CardData in valid_cards:
			if not collection.is_unlocked(card):
				locked.append(card)
		if not locked.is_empty():
			results.append(_pick_weighted(pack, locked, rng))
	while results.size() < pack.cards_per_pack:
		results.append(_pick_weighted(pack, valid_cards, rng))
	return results


func _pick_weighted(pack: PackData, cards: Array[CardData], rng: RandomNumberGenerator) -> CardData:
	var total := 0.0
	var available_rarities: Array[CardData.Rarity] = []
	for card: CardData in cards:
		if not available_rarities.has(card.rarity):
			available_rarities.append(card.rarity)
	for rarity: CardData.Rarity in available_rarities:
		total += _rarity_weight(pack, rarity)
	if total <= 0.0:
		return cards[rng.randi_range(0, cards.size() - 1)]
	var roll := rng.randf() * total
	var chosen_rarity: CardData.Rarity = available_rarities.back()
	for rarity: CardData.Rarity in available_rarities:
		roll -= _rarity_weight(pack, rarity)
		if roll < 0.0:
			chosen_rarity = rarity
			break
	var matching: Array[CardData] = []
	for card: CardData in cards:
		if card.rarity == chosen_rarity:
			matching.append(card)
	return matching[rng.randi_range(0, matching.size() - 1)]


func _rarity_weight(pack: PackData, rarity: CardData.Rarity) -> float:
	match rarity:
		CardData.Rarity.UNCOMMON:
			return pack.uncommon_weight
		CardData.Rarity.RARE:
			return pack.rare_weight
	return pack.common_weight
