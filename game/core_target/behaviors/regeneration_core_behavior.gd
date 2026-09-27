extends CoreBehavior

var elapsed := 0.0


func process_behavior(core: CoreTarget, delta: float) -> void:
	super.process_behavior(core, delta)
	elapsed += delta
	if elapsed >= 10.0:
		elapsed -= 10.0
		core.heal(core.max_hp * 0.03)
