class_name RunDebugTools
extends Node

var session: GameSession


func execute(action: StringName) -> void:
	if not OS.is_debug_build() or session.run == null:
		return
	var army := session.army
	var units := army.get_active_units()
	match action:
		&"damage_unit":
			if not units.is_empty():
				units[0].take_damage(5)
		&"ko_unit":
			if not units.is_empty():
				units[0].knock_out()
		&"ko_all":
			for unit: Unit in units:
				unit.knock_out()
		&"core_ability":
			session._begin_interaction(session.core.data.interaction)
		&"threat":
			session.threats._spawn_fly()
		&"reset_commands":
			session.commands.remaining.clear()
		&"grant_boon":
			session.run.offer_boon()
			session.boon_changed.emit()
		_:
			for card: CardData in session.run.loadout.get_cards():
				if card.id == action:
					session.request_command(card)
					return
			for boon: BoonData in RunSession.BOON_POOL:
				if boon.id == action:
					session.run.pending_boons.assign([boon])
					session.choose_boon(boon)
					return
