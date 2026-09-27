extends SceneTree

var failures := 0
var ko_count := 0
var attack_count := 0
var watched: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: GameSession = load("res://game/session/game_session.tscn").instantiate()
	root.add_child(session)
	var cards: Array[CardData] = [load("res://game/cards/frog.tres"), load("res://game/cards/slug.tres"), load("res://game/cards/chicken.tres")]
	var collection := CardCollection.new()
	collection.configure(cards)
	for card: CardData in cards:
		collection.add_copy(card)
	var deck := DeckLoadout.new()
	deck.configure(collection, cards)
	session.army.spawn_state_changed.connect(func() -> void:
		for unit: Unit in session.army.get_active_units():
			var id := unit.get_instance_id()
			if not watched.has(id):
				watched[id] = true
				unit.knocked_out.connect(func(_unit: Unit) -> void: ko_count += 1)
	)
	session.core.interaction_requested.connect(func(_kind: CoreData.Interaction) -> void: attack_count += 1)
	_check(session.start_run(session.worlds[0], deck), "Frog / Slug / Chicken starts unattended run")
	var natural_run := session.run
	var pending_seen := false
	var next_core_with_pending := false
	for frame: int in 60 * 300:
		await process_frame
		if session.run == null:
			break
		pending_seen = pending_seen or not session.run.pending_boons.is_empty()
		next_core_with_pending = next_core_with_pending or (session.run.current_core_index > 0 and not session.run.pending_boons.is_empty() and session.army.running)
	_check(session.run == null and natural_run.completed, "full Office run completes with zero commands, threat clicks or boon choices")
	_check(pending_seen and next_core_with_pending, "ignored boon choice never interrupts progression")
	_check(attack_count > 0, "Core attacks occur during unattended play")
	# A durable target lets real spawning, timers and physics run for twenty minutes.
	var soak_world := WorldData.new()
	soak_world.id = &"passive_soak"
	soak_world.display_name = "PASSIVE SOAK"
	var soak_core: CoreData = session.worlds[0].cores[0].duplicate()
	soak_core.max_hp = 750000.0
	soak_world.cores = [soak_core]
	session.world_progression.configure([soak_world])
	_check(session.start_run(soak_world, deck), "long unattended segment starts")
	var copies := collection.owned_copies.duplicate()
	var stars := collection.star_levels.duplicate()
	var previous_hp := session.core.current_hp
	var hp_at_five_minutes := previous_hp
	var reset_seen := false
	for frame: int in 60 * 1200:
		await process_frame
		if session.run == null:
			break
		reset_seen = reset_seen or session.core.current_hp > previous_hp
		previous_hp = session.core.current_hp
		if frame == 60 * 300:
			hp_at_five_minutes = previous_hp
	_check(session.run != null and session.army.running, "twenty unattended minutes have no Game Over")
	_check(not reset_seen and session.core.current_hp < hp_at_five_minutes and hp_at_five_minutes < soak_core.max_hp, "Core progress persists and advances at five and twenty minutes")
	_check(ko_count > 0 and not session.army.get_active_units().is_empty(), "natural offensive attacks KO units and Army recovers")
	_check(collection.owned_copies == copies and collection.star_levels == stars, "unattended combat leaves permanent progression untouched")
	print("Passive soak: %d KOs, %d telegraphed attacks, Core HP %.0f." % [ko_count, attack_count, session.core.current_hp])
	session.exit_run()
	session.queue_free()
	await process_frame
	if failures == 0:
		print("Five-minute run and twenty-minute unattended soak passed.")
	quit(0 if failures == 0 else 1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("Passive test failed: " + message)
