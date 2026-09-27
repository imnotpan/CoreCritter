class_name Projectile
extends Node2D

const SPEED := 220.0

var target: CoreTarget
var damage: int
var secondary_multiplier := 0.0
@onready var body: Polygon2D = $Body


func configure(core: CoreTarget, attack_damage: int, tint: Color, extra_hit_multiplier: float = 0.0) -> void:
	target = core
	damage = attack_damage
	secondary_multiplier = extra_hit_multiplier
	body.color = tint


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target) or target.current_hp <= 0:
		queue_free()
		return
	global_position = global_position.move_toward(target.global_position, SPEED * delta)
	if global_position.distance_to(target.global_position) < 12.0:
		target.take_damage(damage)
		if secondary_multiplier > 0.0 and target.current_hp > 0:
			var extra_damage := maxi(1, roundi(damage * secondary_multiplier))
			var hit_target := target
			get_tree().create_timer(0.13).timeout.connect(func() -> void:
				if is_instance_valid(hit_target) and hit_target.current_hp > 0:
					hit_target.take_damage(extra_damage)
			)
		queue_free()
