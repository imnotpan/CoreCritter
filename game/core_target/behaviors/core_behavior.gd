class_name CoreBehavior
extends RefCounted


func on_spawn(_core: CoreTarget) -> void:
	pass


var interaction_clock := 0.0
var first_attack := true


func process_behavior(core: CoreTarget, delta: float) -> void:
	if core.data.interaction == CoreData.Interaction.NONE:
		return
	interaction_clock += delta
	var delay := core.data.first_interaction_delay if first_attack else core.data.interaction_interval
	if interaction_clock >= delay:
		interaction_clock = 0.0
		first_attack = false
		core.interaction_requested.emit(core.data.interaction)


func on_health_changed(_core: CoreTarget) -> void:
	pass
