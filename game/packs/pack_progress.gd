class_name PackProgress
extends RefCounted

signal progress_changed(progress: float)
signal packs_earned(amount: int)

var seconds_per_pack: float = 600.0
var core_destroyed_progress_bonus: float = 0.25
var progress: float = 0.0


func advance_time(delta: float) -> void:
	if delta > 0.0 and seconds_per_pack > 0.0:
		add_progress(delta / seconds_per_pack)


func on_core_destroyed() -> void:
	add_progress(core_destroyed_progress_bonus)


func add_progress(amount: float) -> void:
	if amount <= 0.0:
		return
	progress += amount
	var earned := floori(progress)
	if earned > 0:
		progress -= float(earned)
		packs_earned.emit(earned)
	progress_changed.emit(progress)
