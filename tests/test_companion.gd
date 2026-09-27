extends SceneTree

var failures := 0
var main: Node
var session: GameSession
var collection: CardCollection
var cards: Array[CardData]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	main = load("res://game/main/main.tscn").instantiate()
	main.save_path = ""
	root.add_child(main)
	session = main.game_session
	collection = main.collection
	main.flow.play_requested.emit()
	main.army_builder.start_requested.emit()
	cards = session.run.loadout.get_cards()
	var copies := collection.owned_copies.duplicate()
	var stars := collection.star_levels.duplicate()
	var ids := session.run.loadout.get_card_ids()
	await _test_lifecycle()
	await _test_interactions()
	await _test_commands()
	await _test_boons()
	_check(collection.owned_copies == copies and collection.star_levels == stars, "KO, commands and boons leave permanent cards and stars untouched")
	_check(session.run.loadout.get_card_ids() == ids, "run snapshot remains immutable through all interactions")
	session.exit_run()
	_check(session.army.hp_multiplier == 1.0 and session.army.extra_capacity.is_empty(), "ending run clears all Army boon effects")
	_check(session.commands.loadout == null and not is_instance_valid(session.interaction), "ending run clears command and interaction runtime")
	await process_frame
	_check(session.start_run(session.worlds[0], main.deck), "next run starts normally")
	_check(session.run.chosen_boons.is_empty() and session.run.pending_boons.is_empty(), "next run has no previous boons")
	_check(session.army.hp_multiplier == 1.0 and session.army.spawn_multiplier == 1.0 and session.army.attack_speed_bonus == 0.0, "next run has base modifiers")
	_check(collection.owned_copies == copies and collection.star_levels == stars, "permanent progression survives ending and restarting")
	session.exit_run()
	main.queue_free()
	await process_frame
	if failures == 0:
		print("Companion lifecycle, interactions, commands and boon tests passed.")
	quit(0 if failures == 0 else 1)


func _test_lifecycle() -> void:
	var army := session.army
	var frog := cards[0]
	for index: int in frog.unit_data.max_active_instances:
		army._spawn_unit(frog)
	var unit := army.get_active_units()[0]
	var before := army.count_active(unit.data)
	unit.take_damage(unit.max_hp)
	_check(unit.ko and army.count_active(unit.data) == before - 1, "KO immediately frees active count")
	_check(not army.get_active_units().has(unit), "KO leaves active battlefield immediately")
	_check(army._spawn_unit(frog) == null, "KO vacancy cannot respawn before recovery delay")
	army._process(9.9)
	_check(army.count_active(frog.unit_data) == before - 1, "recovery waits configurable delay")
	army._process(0.2)
	_check(army.count_active(frog.unit_data) == before, "Army replaces recovered KO slot automatically")
	session.core.take_damage(13)
	var hp := session.core.current_hp
	for ally: Unit in army.get_active_units():
		ally.knock_out()
	_check(army.get_active_units().is_empty() and session.run != null, "full wipe keeps run active")
	_check(session.core.current_hp == hp, "full wipe does not reset Core HP")
	_check(main.hud.regroup_label.visible, "wipe displays ARMY DOWN / REGROUPING")
	army._process(10.1)
	_check(not army.get_active_units().is_empty() and not main.hud.regroup_label.visible, "wipe recovers automatically and clears feedback")
	await process_frame
	var ally := army.get_active_units()[0]
	ally.apply_speed_effect(&"test", 0.5, 2.0)
	_check(ally.attack_speed() < 1.0, "temporary slow affects attack speed")
	ally._process(2.1)
	_check(not ally.speed_effects.has(&"test"), "temporary slow expires")
	session.threats._spawn_fly()
	_check(is_instance_valid(session.threats.active_fly), "existing Fly still spawns")
	var fly := session.threats.active_fly
	var attached := fly.attached_unit
	_check(attached.speed_effects.has(&"fly"), "Fly debuffs unit using supported API")
	fly._expire()
	_check(not attached.speed_effects.has(&"fly"), "ignored Fly expires and releases debuff")
	await process_frame


func _test_interactions() -> void:
	for kind: CoreData.Interaction in [CoreData.Interaction.PAPER_JAM, CoreData.Interaction.COFFEE_SPILL, CoreData.Interaction.FIREWALL_NODES, CoreData.Interaction.GRAB]:
		session._begin_interaction(kind)
		var event := session.interaction
		_check(is_instance_valid(event) and not event.resolved, "Core attack starts with visible warning")
		var victim := event.victim
		var hp := victim.current_hp
		event.advance(1.0)
		_check(not event.resolved and victim.current_hp == hp, "warning delays harmful effect")
		event.advance(0.6)
		match kind:
			CoreData.Interaction.PAPER_JAM:
				_check(victim.current_hp < hp and victim.speed_effects.has(&"paper"), "paper damages and slows unit")
			CoreData.Interaction.COFFEE_SPILL:
				victim.global_position = event.zone_center
				event.advance(1.1)
				_check(victim.current_hp < hp, "coffee zone damages units inside")
			CoreData.Interaction.FIREWALL_NODES:
				var core_hp := session.core.current_hp
				session.core.take_damage(10)
				_check(is_equal_approx(core_hp - session.core.current_hp, 7.0), "firewall nodes reduce incoming damage by 30 percent")
			CoreData.Interaction.GRAB:
				_check(victim.disabled, "grab disables and displays victim near Core")
		event.advance(16.0)
		_check(event.ended and session.interaction == null and session.core.firewall_nodes == 0, "ignored Core interaction expires automatically")
		if kind == CoreData.Interaction.GRAB:
			_check(victim.ko and not session.army.get_active_units().has(victim), "ignored grab KO uses normal recovery")
		await process_frame
		session.army._process(10.1)
		session._begin_interaction(kind)
		event = session.interaction
		event.advance(1.6)
		victim = event.victim
		for index: int in 3:
			if not event.ended:
				event.markers[0].pressed.emit()
		_check(event.ended, "optional clicks remove interaction early")
		if kind == CoreData.Interaction.GRAB:
			_check(not victim.disabled and not victim.ko, "clicking restraint frees victim without KO")
		await process_frame
	# Existing behavior scheduler actually requests attacks without clicks.
	session.core.behavior.process_behavior(session.core, 11.0)
	_check(is_instance_valid(session.interaction), "CoreBehavior autonomously emits a telegraphed attack")
	session._clear_interaction()
	await process_frame


func _test_commands() -> void:
	var frog := cards[0]
	main.hud.active_cards.slots[0].command.pressed.emit()
	_check(session.commands.get_state(frog).status != "READY", "Frog VOLLEY activates through HUD command request")
	_check(not session.request_command(frog), "cooldown prevents command spam")
	_check(session.commands.get_state(frog).status != "READY", "HUD exposes cooldown state")
	session.commands.advance(46.0)
	_check(session.request_command(frog), "command works again after cooldown")
	for unit: Unit in session.army.get_active_units():
		if unit.data == frog.unit_data:
			unit.knock_out()
	session.commands.remaining.clear()
	_check(not session.request_command(frog) and session.commands.get_state(frog).status == "READY", "no active Frogs preserves READY")
	session.army._process(10.1)
	_check(session.request_command(cards[1]), "Slug SHELL UP activates")
	var ally := session.army.get_active_units()[0]
	var hp := ally.current_hp
	ally.take_damage(10)
	_check(hp - ally.current_hp == 6, "SHELL UP reduces damage by 40 percent")
	ally._process(5.1)
	_check(ally.damage_reduction == 0.0, "SHELL UP expires")
	var chicken_count := session.army.count_active(cards[2].unit_data)
	_check(session.request_command(cards[2]), "Chicken STAMPEDE activates")
	var temporary_count := 0
	for unit: Unit in session.army.get_active_units():
		if unit.temporary:
			temporary_count += 1
			unit._process(13.0)
	_check(temporary_count == 4 and session.army.count_active(cards[2].unit_data) == chicken_count, "Stampede creates four temporary units without changing capacity")
	await process_frame
	_check(not session.army.get_active_units().any(func(unit: Unit) -> bool: return unit.temporary), "temporary chickens clean themselves up")
	# Test other commands using a new sealed loadout, without altering the current one.
	var other_cards: Array[CardData] = []
	for id: StringName in [&"wizard", &"bomb_baby", &"mushroom"]:
		var card := collection.get_card(id)
		other_cards.append(card)
	var sandbox_collection := CardCollection.new()
	sandbox_collection.configure(other_cards)
	for card: CardData in other_cards:
		sandbox_collection.add_copy(card)
	var deck := DeckLoadout.new()
	deck.configure(sandbox_collection, other_cards)
	var snapshot := RunLoadout.from_deck(deck)
	var army := session.army
	var original := army.loadout
	army.loadout = snapshot
	var commands := CardCommands.new()
	commands.configure(snapshot, army)
	var hp_before := session.core.current_hp
	_check(commands.activate(other_cards[0]) and session.core.current_hp < hp_before, "Wizard METEOR deals direct damage")
	_check(commands.activate(other_cards[1]), "Bomb Baby PANIC BUTTON spawns temporary unit")
	var bomb: Unit
	for unit: Unit in army.get_active_units():
		if unit.data == other_cards[1].unit_data:
			bomb = unit
	_check(bomb != null and bomb.temporary, "Panic Bomb is temporary")
	bomb.perform_base_attack()
	_check(bomb.exploding, "Panic Bomb uses normal explosion lifecycle")
	_check(commands.activate(other_cards[2]), "Mushroom SPORE PARTY activates")
	ally = army.get_active_units()[0]
	_check(ally.speed_effects.has(&"party"), "Spore Party increases allied speed")
	army.spore_party()
	_check(ally.speed_effects[&"party"].multiplier == 1.25, "Spore Party cannot stack infinitely")
	ally._process(6.1)
	_check(not ally.speed_effects.has(&"party"), "Spore Party expires")
	army.loadout = original
	await create_timer(0.4).timeout
	_check(not is_instance_valid(bomb), "Panic Bomb cleans up after explosion")


func _test_boons() -> void:
	var run := session.run
	run.offer_boon()
	var choices := run.pending_boons.duplicate()
	run.offer_boon()
	_check(run.pending_boons == choices and choices.size() == 3, "pending boons stay bounded to one choice of three")
	for boon: BoonData in RunSession.BOON_POOL:
		run.pending_boons.assign([boon])
		_check(session.choose_boon(boon), "boon can be selected through session")
	_check(session.army.hp_multiplier == 1.2 and session.army.spawn_multiplier == 0.85, "health and spawn boons apply to Army runtime")
	_check(session.army.capacity(cards[2]) == cards[2].unit_data.max_active_instances + 2, "Chicken Union expands run-only capacity")
	var unit := session.army.get_active_units()[0]
	_check(unit.max_hp == roundi(unit.data.max_hp * 1.2), "Health Plan updates living units")
	var base_hp := cards[0].unit_data.max_hp
	_check(base_hp == 30 and cards[2].unit_data.max_active_instances == 5, "boons do not mutate UnitData assets")
	session.debug_destroy_core()
	_check(run.pending_boons.size() == 3, "non-final Core awards boon")
	await create_timer(2.6).timeout
	_check(session.run == run and session.army.running and run.current_core_index == 1, "next Core continues while boon stays pending")
	_check(run.pending_boons.size() == 3, "pending choice remains available after transition")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("Companion test failed: " + message)
