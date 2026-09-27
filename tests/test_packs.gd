extends SceneTree

var failures := 0


func _initialize() -> void:
	var frog: CardData = load("res://game/cards/frog.tres")
	var slug: CardData = load("res://game/cards/slug.tres")
	var wizard: CardData = load("res://game/cards/wizard.tres")
	var cards: Array[CardData] = [frog, slug, wizard]
	var pack: PackData = load("res://game/packs/basic_pack.tres")
	var collection := CardCollection.new()
	collection.configure(cards)
	collection.add_copy(frog)
	collection.add_copy(slug)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var generator := PackGenerator.new()
	for iteration: int in range(100):
		var results := generator.generate(pack, cards, collection, rng)
		_check(results.size() == pack.cards_per_pack, "configured card count")
		_check(results.all(func(card: CardData) -> bool: return cards.has(card)), "only available cards")
		_check(results.has(wizard), "new card guaranteed")
	collection.add_copy(wizard)
	pack.guarantee_new_card_if_available = false
	pack.common_weight = 0.0
	pack.uncommon_weight = 1.0
	pack.rare_weight = 0.0
	for iteration: int in range(100):
		var results := generator.generate(pack, cards, collection, rng)
		_check(results.size() == pack.cards_per_pack, "full collection still generates")
		_check(results.all(func(card: CardData) -> bool: return cards.has(card)), "full collection valid cards")
		_check(results.all(func(card: CardData) -> bool: return card.rarity == CardData.Rarity.UNCOMMON), "rarity weights select available rarity")
	var unlocks := [0]
	collection.card_unlocked.connect(func(_card: CardData) -> void: unlocks[0] += 1)
	collection.add_copy(frog, 2)
	_check(collection.get_owned_copies(frog) == 2, "duplicate copies accumulate")
	_check(unlocks[0] == 0, "duplicates do not unlock again")
	var earned := [0]
	var progress := PackProgress.new()
	progress.packs_earned.connect(func(amount: int) -> void: earned[0] += amount)
	progress.add_progress(2.25)
	_check(earned[0] == 2 and is_equal_approx(progress.progress, 0.25), "progress overflow awards two packs")
	progress.on_core_destroyed()
	_check(is_equal_approx(progress.progress, 0.5), "core bonus adds progress")
	var inventory := PackInventory.new()
	inventory.add_pack(earned[0])
	_check(inventory.get_pack_count() == 2 and inventory.consume_pack(), "inventory consumes one")
	_check(inventory.get_pack_count() == 1, "inventory preserves remaining pack")
	if failures == 0:
		print("Pack tests passed.")
	quit(0 if failures == 0 else 1)


func _check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error("Pack test failed: " + description)
