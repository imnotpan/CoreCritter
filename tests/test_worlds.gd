extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var office: WorldData = load("res://game/worlds/office.tres")
	var backyard: WorldData = load("res://game/worlds/backyard.tres")
	var progression := WorldProgression.new()
	progression.configure([office, backyard])
	_check(progression.is_unlocked(office), "first world unlocked")
	_check(not progression.is_unlocked(backyard), "second world locked")
	_check(progression.complete_world(office), "first clear recorded")
	_check(progression.is_unlocked(backyard), "next world unlocks")
	_check(not progression.complete_world(office), "replay is not first clear")
	_test_arbitrary_world_ids()
	_test_core_behaviors(office)
	await _test_session_rewards(office)
	if failures == 0:
		print("World tests passed.")
	quit(0 if failures == 0 else 1)


func _test_arbitrary_world_ids() -> void:
	var first := WorldData.new()
	first.id = &"unrelated_first"
	first.cores = [CoreData.new()]
	var second := WorldData.new()
	second.id = &"unrelated_second"
	second.cores = [CoreData.new()]
	var progression := WorldProgression.new()
	progression.configure([first, second])
	_check(progression.complete_world(first) and progression.is_unlocked(second), "world order does not depend on IDs")


func _test_core_behaviors(office: WorldData) -> void:
	var core: CoreTarget = load("res://game/core_target/core_target.tscn").instantiate()
	root.add_child(core)
	core.configure(office.cores[1])
	core.take_damage(200)
	var regeneration_hp := core.current_hp
	core.behavior.process_behavior(core, 10.0)
	_check(core.current_hp > regeneration_hp, "coffee core regenerates")
	core.heal(100000.0)
	_check(core.current_hp <= core.max_hp, "regeneration cannot exceed max HP")
	core.configure(office.cores[2])
	core.behavior.process_behavior(core, 12.0)
	_check(core.shield_remaining > 0.0, "server activates shield")
	core.take_damage(100)
	_check(is_equal_approx(core.current_hp, core.max_hp - 50.0), "shield halves incoming damage")
	core.configure(office.cores[3])
	core.take_damage(2100)
	_check(core.shield_remaining > 0.0, "boss shields at 60 percent")
	core.queue_free()


func _test_session_rewards(office: WorldData) -> void:
	var session: GameSession = load("res://game/session/game_session.tscn").instantiate()
	root.add_child(session)
	var collection := CardCollection.new()
	var cards: Array[CardData] = [load("res://game/cards/frog.tres"), load("res://game/cards/slug.tres"), load("res://game/cards/chicken.tres")]
	collection.configure(cards)
	for card: CardData in cards:
		collection.add_copy(card)
	var deck := DeckLoadout.new()
	deck.configure(collection, cards)
	_check(session.run == null and not session.army.running, "session boots idle")
	_check(session.start_run(office, deck), "valid deck starts Office")
	var printer := office.cores[0]
	session.core.take_damage(ceili(printer.max_hp * 2))
	_check(session.wallet.coins == printer.coin_reward, "CoreData coins forwarded to wallet")
	_check(is_equal_approx(session.pack_progress.progress, printer.pack_progress_reward), "CoreData pack progress forwarded")
	await create_timer(2.6).timeout
	for index: int in range(1, office.cores.size()):
		session.debug_destroy_core()
		await create_timer(2.6).timeout
	_check(session.run == null and not session.army.running, "final boss ends run")
	_check(session.world_progression.is_unlocked(session.worlds[1]), "boss clear unlocks next world")
	_check(session.pack_inventory.get_pack_count() >= 1, "world clear earns packs")
	session.queue_free()


func _check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error("World test failed: " + description)
