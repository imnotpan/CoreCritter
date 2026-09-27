extends CoreBehavior

var shield_triggered := false
var regen_triggered := false
var elapsed := 0.0


func process_behavior(core: CoreTarget, delta: float) -> void:
	if not shield_triggered:
		return
	elapsed += delta
	if elapsed >= 10.0:
		elapsed -= 10.0
		core.activate_shield(3.0)


func on_health_changed(core: CoreTarget) -> void:
	if not shield_triggered and core.current_hp <= core.max_hp * 0.6:
		shield_triggered = true
		core.activate_shield(3.0)
	if not regen_triggered and core.current_hp <= core.max_hp * 0.3:
		regen_triggered = true
		core.heal(core.max_hp * 0.05)
