extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var frog: CardData = load("res://game/cards/frog.tres")
	var slug: CardData = load("res://game/cards/slug.tres")
	var cards: Array[CardData] = [frog, slug]
	var collection := CardCollection.new()
	collection.configure(cards)
	var wallet := Wallet.new()
	root.add_child(wallet)
	collection.set_wallet(wallet)
	_check(not collection.can_upgrade(frog.id) and collection.get_star_level(frog) == 0, "locked card cannot upgrade")
	_check(not collection.upgrade(frog.id), "locked upgrade fails")
	collection.add_copy(frog)
	_check(collection.get_star_level(frog) == 1 and collection.get_owned_copies(frog) == 0, "first copy unlocks at one star")
	wallet.add_coins(1000)
	collection.add_copy(frog)
	var before_coins := wallet.coins
	_check(not collection.upgrade(frog.id), "insufficient copies fails")
	_check(wallet.coins == before_coins and collection.get_owned_copies(frog) == 1, "copy failure is atomic")
	collection.add_copy(frog)
	wallet.spend(975)
	_check(not collection.upgrade(frog.id), "insufficient coins fails")
	_check(wallet.coins == 25 and collection.get_owned_copies(frog) == 2 and collection.get_star_level(frog) == 1, "coin failure is atomic")
	wallet.add_coins(100)
	_check(collection.upgrade(frog.id), "upgrade succeeds")
	_check(collection.get_star_level(frog) == 2 and collection.get_owned_copies(frog) == 0 and wallet.coins == 75, "upgrade consumes exactly two copies and fifty coins")
	_check(StarStats.damage(100, 1) == 100 and StarStats.damage(100, 2) == 115 and StarStats.damage(100, 4) == 135, "two and four star damage scaling")
	_check(StarStats.damage(2, 2) > StarStats.damage(2, 1) and StarStats.damage(2, 4) > StarStats.damage(2, 2), "low damage units improve at both stat stars")
	var pack: PackData = load("res://game/packs/basic_pack.tres")
	var generator := PackGenerator.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	pack.guarantee_new_card_if_available = false
	var only_frog: Array[CardData] = [frog]
	var results := generator.generate(pack, only_frog, collection, rng)
	for card: CardData in results:
		collection.add_copy(card)
	_check(collection.get_owned_copies(frog) == pack.cards_per_pack, "pack copies remain spendable")
	wallet.add_coins(1000)
	_check(collection.upgrade(frog.id) and collection.get_star_level(frog) == 3, "three star upgrade happens once")
	_test_ricochet(frog)
	collection.add_copy(frog, 13)
	_check(collection.upgrade(frog.id) and collection.upgrade(frog.id), "four and five star upgrades succeed")
	var max_copies := collection.get_owned_copies(frog)
	var max_coins := wallet.coins
	_check(not collection.upgrade(frog.id) and not collection.can_upgrade(frog.id), "five star cannot upgrade")
	_check(collection.get_star_level(frog) == 5 and collection.get_owned_copies(frog) == max_copies and wallet.coins == max_coins, "max star failure is atomic")
	if failures == 0:
		print("Progression tests passed.")
	quit(0 if failures == 0 else 1)


func _test_ricochet(frog: CardData) -> void:
	var core: CoreTarget = load("res://game/core_target/core_target.tscn").instantiate()
	root.add_child(core)
	core.position = Vector2(200, 160)
	var unit: Unit = load("res://game/units/unit.tscn").instantiate()
	root.add_child(unit)
	unit.configure(frog.unit_data, core, null, 2)
	frog.unit_data.behavior.on_attack(unit)
	var plain: Projectile = _last_projectile()
	_check(plain != null and plain.secondary_multiplier == 0.0, "two star attack has no ricochet")
	plain.queue_free()
	unit.star_level = 3
	frog.unit_data.behavior.on_attack(unit)
	var ricochet: Projectile = _last_projectile()
	_check(ricochet != null and is_equal_approx(ricochet.secondary_multiplier, 0.5), "three star ricochet activates")
	unit.queue_free()
	core.queue_free()


func _last_projectile() -> Projectile:
	for index: int in range(root.get_child_count() - 1, -1, -1):
		if root.get_child(index) is Projectile and not root.get_child(index).is_queued_for_deletion():
			return root.get_child(index) as Projectile
	return null


func _check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error("Progression test failed: " + description)
