class_name Projectile
extends Node2D

const SPEED := 220.0

var target: CoreTarget
var damage: int
@onready var body: Polygon2D = $Body


func configure(core: CoreTarget, attack_damage: int, tint: Color) -> void:
	target = core
	damage = attack_damage
	body.color = tint


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target) or target.current_hp <= 0:
		queue_free()
		return
	global_position = global_position.move_toward(target.global_position, SPEED * delta)
	if global_position.distance_to(target.global_position) < 12.0:
		target.take_damage(damage)
		queue_free()
