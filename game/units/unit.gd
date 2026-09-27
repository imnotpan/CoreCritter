class_name Unit
extends Node2D

@onready var body: Polygon2D = $Body
@onready var eyes: Polygon2D = $Eyes
@onready var name_label: Label = $NameLabel
@onready var attack_flash: Polygon2D = $AttackFlash
@onready var explosion: Polygon2D = $Explosion

var data: UnitData
var target: CoreTarget
var attack_clock := 0.0
var current_hp: int
var attack_speed_multiplier := 1.0
var exploding := false


func configure(unit_data: UnitData, core: CoreTarget) -> void:
	data = unit_data
	target = core
	current_hp = data.max_hp
	body.color = data.color
	body.polygon = data.body_polygon
	name_label.text = data.display_name
	_face_core()


func _physics_process(delta: float) -> void:
	if data == null or target == null or target.current_hp <= 0 or exploding:
		return
	_face_core()
	var destination: Vector2 = target.get_attack_position(self)
	if global_position.distance_to(destination) > 0.5:
		global_position = global_position.move_toward(destination, data.move_speed * delta)
		return
	if not target.has_attack_slot(self):
		return
	attack_clock += delta * attack_speed_multiplier
	if attack_clock >= data.attack_interval:
		attack_clock -= data.attack_interval
		_attack()


func set_attack_speed_multiplier(value: float) -> void:
	attack_speed_multiplier = value


func _face_core() -> void:
	var angle := global_position.angle_to_point(target.global_position)
	eyes.rotation = angle
	attack_flash.rotation = angle


func _attack() -> void:
	if data.attack_mode == UnitData.AttackMode.SELF_DESTRUCT:
		_explode()
		return
	attack_flash.visible = true
	attack_flash.modulate.a = 1.0
	create_tween().tween_property(attack_flash, "modulate:a", 0.0, 0.18).finished.connect(
		func() -> void: attack_flash.visible = false
	)
	if data.projectile_scene != null:
		var projectile: Node2D = data.projectile_scene.instantiate() as Node2D
		get_parent().add_child(projectile)
		projectile.global_position = global_position + global_position.direction_to(target.global_position) * 14.0
		projectile.call("configure", target, data.damage, data.color)
	else:
		target.take_damage(data.damage)


func _explode() -> void:
	exploding = true
	target.take_damage(data.damage)
	body.visible = false
	name_label.visible = false
	explosion.visible = true
	explosion.scale = Vector2(0.2, 0.2)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(explosion, "scale", Vector2(2.2, 2.2), 0.28)
	tween.tween_property(explosion, "modulate:a", 0.0, 0.28)
	tween.chain().tween_callback(queue_free)
