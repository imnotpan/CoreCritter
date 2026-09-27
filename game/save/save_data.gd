class_name SaveData
extends Resource

@export var copies: Dictionary = {}
@export var stars: Dictionary = {}
@export var unlocked_worlds: Dictionary = {}
@export var completed_worlds: Dictionary = {}
@export var deck_ids: Array[StringName] = []
@export var world_id: StringName
@export var coins := 0
@export var packs := 0
@export var pack_progress := 0.0


static func capture(collection: CardCollection, deck: DeckLoadout, session: GameSession, world: WorldData) -> SaveData:
	var data := SaveData.new()
	data.copies = collection.owned_copies.duplicate()
	data.stars = collection.star_levels.duplicate()
	data.unlocked_worlds = session.world_progression.unlocked_worlds.duplicate()
	data.completed_worlds = session.world_progression.completed_worlds.duplicate()
	for card: CardData in deck.get_cards():
		data.deck_ids.append(card.id if card != null else &"")
	data.world_id = world.id
	data.coins = session.wallet.coins
	data.packs = session.pack_inventory.get_pack_count()
	data.pack_progress = session.pack_progress.progress
	return data


func restore(collection: CardCollection, deck: DeckLoadout, session: GameSession) -> WorldData:
	for card: CardData in collection.cards:
		collection.star_levels[card.id] = clampi(int(stars.get(card.id, collection.get_star_level(card))), 0, 5)
		collection.owned_copies[card.id] = maxi(0, int(copies.get(card.id, 0)))
	for world: WorldData in session.worlds:
		if unlocked_worlds.has(world.id):
			session.world_progression.unlocked_worlds[world.id] = true
		if completed_worlds.has(world.id):
			session.world_progression.completed_worlds[world.id] = true
	session.wallet.coins = maxi(0, coins)
	session.pack_inventory.add_pack(maxi(0, packs))
	session.pack_progress.progress = clampf(pack_progress, 0.0, 0.999999)
	var cards: Array[CardData] = []
	for card_id: StringName in deck_ids:
		var card := collection.get_card(card_id)
		cards.append(card)
	deck.configure(collection, cards)
	for world: WorldData in session.worlds:
		if world.id == world_id and session.world_progression.is_unlocked(world):
			return world
	return session.worlds[0]
