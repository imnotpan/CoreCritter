class_name AcidZone
extends Node2D

var target: CoreTarget
var damage := 1
var lifetime := 4.0
var tick_interval := 0.8
var tick_clock := 0.0


func _ready() -> void:
	var visual := Polygon2D.new()
	visual.color = Color(0.55, 0.95, 0.25, 0.45)
	visual.polygon = PackedVector2Array([Vector2(-11, -5), Vector2(9, -8), Vector2(13, 4), Vector2(-8, 8)])
	add_child(visual)


func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0 or not is_instance_valid(target):
		queue_free()
		return
	tick_clock += delta
	if tick_clock >= tick_interval:
		tick_clock -= tick_interval
		target.take_damage(damage)
