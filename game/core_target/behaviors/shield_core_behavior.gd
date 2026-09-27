extends CoreBehavior

var elapsed := 0.0


func process_behavior(core: CoreTarget, delta: float) -> void:
	elapsed += delta
	if elapsed >= 12.0:
		elapsed -= 12.0
		core.activate_shield(3.0)
