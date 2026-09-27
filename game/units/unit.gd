class_name Unit
extends Node2D

@onready var body: Polygon2D = $Body
@onready var eyes: Polygon2D = $Eyes
@onready var name_label: Label = $NameLabel
@onready var attack_flash: Polygon2D = $AttackFlash
@onready var explosion: Polygon2D = $Explosion

var data: UnitData
var target: CoreTarget
var army: Army
var star_level := 1
var resolved_damage := 0
var attack_clock := 0.0
signal knocked_out(unit: Unit)

var max_hp: int
var current_hp: int
var ko := false
var temporary := false
var lifetime := -1.0
var disabled := false
var speed_effects: Dictionary = {}
var protection_time := 0.0
var damage_reduction := 0.0
var army_speed_bonus := 0.0
var spore_bonus := 0.0
var spore_time := 0.0
var exploding := false
var ability_clock := 0.0
var attacks_made := 0


func configure(unit_data: UnitData, core: CoreTarget, owning_army: Army, stars: int) -> void:
	data = unit_data
	target = core
	army = owning_army
	star_level = stars
	resolved_damage = StarStats.damage(data.damage, stars)
	max_hp = roundi(data.max_hp * (army.hp_multiplier if army != null else 1.0))
	current_hp = max_hp
	queue_redraw()
	body.color = data.color
	body.polygon = data.body_polygon
	name_label.text = data.display_name
	_face_core()


func _process(delta: float) -> void:
	spore_time = maxf(0.0, spore_time - delta)
	if spore_time <= 0.0:
		spore_bonus = 0.0
	for key: StringName in speed_effects.keys():
		speed_effects[key].time -= delta
		if speed_effects[key].time <= 0.0:
			speed_effects.erase(key)
	protection_time = maxf(0.0, protection_time - delta)
	if protection_time <= 0.0 and damage_reduction > 0.0:
		damage_reduction = 0.0
		queue_redraw()
	if lifetime >= 0.0:
		lifetime -= delta
		if lifetime <= 0.0:
			queue_free()


func _draw() -> void:
	if data == null or ko:
		return
	draw_line(Vector2(-12, 17), Vector2(12, 17), Color(0.15, 0.2, 0.2), 3.0)
	draw_line(Vector2(-12, 17), Vector2(-12 + 24.0 * current_hp / max_hp, 17), Color(0.5, 0.9, 0.6), 3.0)
	if damage_reduction > 0.0:
		draw_arc(Vector2.ZERO, 19.0, 0, TAU, 16, Color(0.5, 0.8, 1.0), 2.0)


func take_damage(amount: float) -> void:
	if ko or exploding or is_queued_for_deletion():
		return
	current_hp = maxi(0, current_hp - ceili(maxf(0.0, amount) * (1.0 - damage_reduction)))
	queue_redraw()
	if current_hp == 0:
		knock_out()


func knock_out() -> void:
	if ko or is_queued_for_deletion():
		return
	ko = true
	visible = false
	knocked_out.emit(self)
	queue_free()


func apply_speed_effect(key: StringName, multiplier: float, duration: float) -> void:
	speed_effects[key] = {"multiplier": multiplier, "time": duration}


func set_attack_speed_multiplier(multiplier: float) -> void:
	if multiplier == 1.0:
		speed_effects.erase(&"fly")
	else:
		apply_speed_effect(&"fly", multiplier, 30.0)


func protect(reduction: float, duration: float) -> void:
	damage_reduction = maxf(damage_reduction, reduction)
	protection_time = maxf(protection_time, duration)
	queue_redraw()


func attack_speed() -> float:
	var speed := 1.0 + army_speed_bonus + spore_bonus + (army.attack_speed_bonus if army != null else 0.0)
	for effect: Dictionary in speed_effects.values():
		speed *= float(effect.multiplier)
	return speed


func _physics_process(delta: float) -> void:
	if disabled or ko:
		return
	if data == null or target == null or target.current_hp <= 0 or exploding:
		return
	_face_core()
	var destination: Vector2 = target.get_attack_position(self)
	var at_position := global_position.distance_to(destination) <= 0.5
	if data.behavior != null:
		data.behavior.on_tick(self, delta, at_position and target.has_attack_slot(self))
	if not at_position:
		global_position = global_position.move_toward(destination, data.move_speed * delta)
		return
	if not target.has_attack_slot(self):
		return
	attack_clock += delta * attack_speed()
	if attack_clock >= data.attack_interval:
		attack_clock -= data.attack_interval
		if data.behavior != null:
			data.behavior.on_attack(self)
		else:
			perform_base_attack()


func apply_spore_bonus(bonus: float, duration: float) -> void:
	spore_bonus = maxf(spore_bonus, bonus)
	spore_time = maxf(spore_time, duration)


func on_army_changed() -> void:
	if data != null and data.behavior != null:
		data.behavior.on_army_changed(self)


func _face_core() -> void:
	var angle := global_position.angle_to_point(target.global_position)
	eyes.rotation = angle
	attack_flash.rotation = angle


func perform_base_attack(damage_multiplier: float = 1.0, secondary_multiplier: float = 0.0) -> void:
	if disabled or ko or exploding or target.current_hp <= 0.0:
		return
	if data.attack_mode == UnitData.AttackMode.SELF_DESTRUCT:
		_explode(damage_multiplier)
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
		projectile.call("configure", target, maxi(1, roundi(resolved_damage * damage_multiplier)), data.color, secondary_multiplier)
	else:
		target.take_damage(maxi(1, roundi(resolved_damage * damage_multiplier)))
		if secondary_multiplier > 0.0:
			target.take_damage(maxi(1, roundi(resolved_damage * secondary_multiplier)))


func _explode(damage_multiplier: float = 1.0) -> void:
	exploding = true
	target.take_damage(maxi(1, roundi(resolved_damage * damage_multiplier)))
	body.visible = false
	name_label.visible = false
	explosion.visible = true
	explosion.scale = Vector2(0.2, 0.2)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(explosion, "scale", Vector2(2.2, 2.2) * (1.35 if star_level >= 3 else 1.0), 0.28)
	tween.tween_property(explosion, "modulate:a", 0.0, 0.28)
	tween.chain().tween_callback(queue_free)
