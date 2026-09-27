extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = load("res://game/main/main.tscn").instantiate()
	main.save_path = ""
	root.add_child(main)
	var session: GameSession = main.game_session
	var deck: DeckLoadout = main.deck
	var collection: CardCollection = main.collection
	var frog := collection.get_card(&"frog")
	var slug := collection.get_card(&"slug")
	var wizard := collection.get_card(&"wizard")
	var office := session.worlds[0]
	_check(main.flow.state == AppFlow.State.MAIN_MENU and session.run == null, "boot opens main menu without combat")
	_check(not session.army.running and session.units.get_child_count() == 0, "menu has no spawning")
	main.flow.collection_requested.emit()
	_check(main.army_builder.visible and main.army_builder.collection_only, "menu collection opens outside combat")
	main.army_builder.back_requested.emit()
	main.flow.play_requested.emit()
	_check(main.flow.state == AppFlow.State.PRE_RUN and main.army_builder.visible, "Play opens dedicated pre-run")
	_check(not deck.equip(1, wizard), "locked card cannot be equipped")
	_check(not session.start_run(session.worlds[1], deck), "locked world cannot start")
	main.army_builder.set_world(session.worlds[1])
	_check(main.army_builder.get_node("Panel/StartButton").disabled, "locked world disables Start")
	main.army_builder.set_world(office)
	var invalid := DeckLoadout.new()
	invalid.configure(collection, [frog])
	_check(not session.start_run(office, invalid), "incomplete deck cannot start")
	invalid.slots = [frog, frog, slug]
	_check(not session.start_run(office, invalid), "duplicate deck cannot start")
	var snapshot := RunLoadout.from_deck(deck)
	_check(snapshot != null and snapshot.get_card_ids() == [&"frog", &"slug", &"chicken"], "snapshot contains three selected IDs")
	_check(snapshot._cards.is_read_only() and snapshot._stars.is_read_only(), "snapshot backing arrays are sealed")
	snapshot._cards = []
	snapshot._stars = []
	_check(snapshot.get_cards().size() == 3 and snapshot.get_star_level(frog) == 1, "sealed snapshot rejects backing array replacement")
	var exposed := snapshot.get_cards()
	exposed.clear()
	_check(snapshot.get_cards().size() == 3, "editing returned array cannot mutate snapshot")
	main.army_builder.start_requested.emit()
	_check(session.run != null and main.flow.state == AppFlow.State.ACTIVE_RUN, "Start enters active run")
	_check(session.army.loadout == session.run.loadout, "army consumes run snapshot")
	_check(session.army.spawn_timers.size() == 3 and session.army.get_active_units().size() == 3, "exactly selected creatures spawn")
	_check(not main.hud.has_node("Bottom/Rows/Footer/ArmyButton") and not main.hud.has_node("Bottom/Rows/Footer/WorldButton"), "active HUD has no deck/world editing controls")
	var active := session.run.loadout
	session.run.world = session.worlds[1]
	session.run.loadout = snapshot
	_check(session.run.world == office and session.run.loadout == active, "active run rejects world and loadout replacement")
	_check(not session.complete_run(), "run cannot complete before final core")
	main._select_world(session.worlds[1])
	_check(session.run.world == office and main.selected_world == office, "world selection ignored during combat")
	collection.add_copy(wizard)
	_check(session.run.new_cards.has(wizard), "run records permanent unlock for results")
	_check(not active.get_cards().has(wizard) and session.army.spawn_timers.size() == 3, "unlock cannot add card or timer to current army")
	_check(session.army.get_spawn_state(wizard).status == "UNAVAILABLE", "new Wizard has no current spawn schedule")
	_check(deck.equip(1, wizard), "editable future deck accepts unlocked Wizard")
	_check(active.get_cards().has(slug) and not active.get_cards().has(wizard), "editing future deck does not change current run")
	collection.add_copy(frog, 2)
	session.wallet.add_coins(50)
	_check(collection.upgrade(frog.id), "permanent star can advance")
	_check(active.get_star_level(frog) == 1 and collection.get_star_level(frog) == 2, "run retains captured star level")
	session.pack_progress.add_progress(1.0)
	session.pack_inventory.consume_pack()
	_check(session.run.packs_earned == 1, "pack rewards counted independently of opening packs")
	_check(not session.start_run(office, deck), "cannot replace active run or world")
	var reveal: CardView = load("res://game/ui/card_view.tscn").instantiate()
	root.add_child(reveal)
	reveal.configure(wizard, true, 0, 0, 1, true)
	_check(reveal.name_label.text == "WIZARD" and reveal.result_badge.text == "NEW!" and reveal.copies_label.text == "AVAILABLE NEXT RUN", "pack reveal clearly labels future availability")
	reveal.queue_free()
	for index: int in office.cores.size():
		session.debug_destroy_core()
		await create_timer(2.6).timeout
	_check(session.run == null and main.flow.state == AppFlow.State.RUN_RESULTS, "final boss opens results")
	_check(not session.army.running and session.army.spawn_timers.is_empty(), "completion stops spawning")
	_check(session.world_progression.is_completed(office), "world completion persists")
	var results_text := ""
	for child: Node in main.flow.content.get_children():
		if child is Label:
			results_text += child.text
	_check(results_text.contains("Wizard") and results_text.contains("Cores destroyed: 4"), "results include Wizard and core count")
	main.flow.continue_requested.emit()
	_check(main.flow.state == AppFlow.State.PRE_RUN and collection.is_unlocked(wizard), "continue prepares next run with unlock retained")
	main.army_builder.start_requested.emit()
	_check(session.run.loadout.get_cards().has(wizard) and not session.run.loadout.get_cards().has(slug), "next run uses manually edited deck")
	_check(session.run.loadout.get_star_level(frog) == 2, "next run uses new progression")
	var spawned: Array[UnitData] = []
	for unit: Unit in session.army.get_active_units():
		spawned.append(unit.data)
	_check(spawned.has(wizard.unit_data) and not spawned.has(slug.unit_data), "Wizard spawns next run and Slug does not")
	var mushroom := collection.get_card(&"mushroom")
	collection.add_copy(mushroom)
	_check(not session.run.loadout.get_cards().has(mushroom), "second run unlock also stays isolated")
	session.debug_destroy_core()
	session.exit_run()
	_check(collection.is_unlocked(mushroom) and collection.is_unlocked(wizard), "early exit keeps collection rewards")
	await create_timer(2.6).timeout
	_check(session.run == null and not session.army.running, "early exit cancels pending core transition")
	var data := SaveData.capture(collection, deck, session, office)
	var save_path := "/private/tmp/corecritters-run-test.tres"
	_check(ResourceSaver.save(data, save_path) == OK, "progression can save")
	main.queue_free()
	await process_frame
	var relaunched = load("res://game/main/main.tscn").instantiate()
	relaunched.save_path = save_path
	root.add_child(relaunched)
	_check(relaunched.collection.is_unlocked(relaunched.collection.get_card(&"wizard")), "unlock survives relaunch")
	_check(relaunched.deck.get_cards().has(relaunched.collection.get_card(&"wizard")), "next-run deck survives relaunch")
	_check(relaunched.collection.get_star_level(relaunched.collection.get_card(&"frog")) == 2, "stars survive relaunch")
	_check(relaunched.game_session.run == null and relaunched.flow.state == AppFlow.State.MAIN_MENU, "relaunch starts menu without resuming combat")
	relaunched.queue_free()
	await process_frame
	DirAccess.remove_absolute(save_path)
	if failures == 0:
		print("Run flow and isolation tests passed.")
	quit(0 if failures == 0 else 1)


func _check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error("Run test failed: " + description)
