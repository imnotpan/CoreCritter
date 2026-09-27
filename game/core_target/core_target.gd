class_name CoreTarget
extends Node2D

signal destroyed(data: CoreData)
signal health_changed(current: float, maximum: float)

const MELEE_RADIUS := 57.0
const MELEE_SLOT_COUNT := 16
const MID_RADIUS := 80.0
const MID_SLOT_COUNT := 12
const RANGED_RADIUS := 105.0
const RANGED_SLOT_COUNT := 10
const WAITING_GAP := 23.0

@onready var hp_fill: ColorRect = $HPBack/HPFill
@onready var hp_label: Label = $HPLabel
@onready var body: Polygon2D = $Body
@onready var damage_label: Label = $DamageLabel
@onready var name_label: Label = $NameLabel
@onready var center: Polygon2D = $Center

var data: CoreData
var max_hp: float = 100.0
var current_hp: float = 100.0
var behavior: CoreBehavior
var shield_remaining := 0.0
var hit_tween: Tween
var damage_tween: Tween
var reserved_positions: Dictionary = {}
var waiting_positions: Dictionary = {}
var waiting_profiles: Dictionary = {}
var reserved_profiles: Dictionary = {}


func _ready() -> void:
	reset()


func _process(delta: float) -> void:
	if current_hp <= 0.0:
		return
	if shield_remaining > 0.0:
		shield_remaining = maxf(0.0, shield_remaining - delta)
		if shield_remaining == 0.0:
			_update_shield_visual()
	if behavior != null:
		behavior.process_behavior(self, delta)


func configure(core_data: CoreData) -> void:
	if hit_tween and hit_tween.is_running():
		hit_tween.kill()
	if damage_tween and damage_tween.is_running():
		damage_tween.kill()
	data = core_data
	max_hp = maxf(1.0, data.max_hp)
	behavior = data.behavior_script.new() as CoreBehavior if data.behavior_script != null else null
	shield_remaining = 0.0
	body.color = data.placeholder_color
	center.color = data.placeholder_color.lightened(0.35)
	name_label.text = data.display_name.to_upper()
	name_label.visible = false
	damage_label.visible = false
	_update_shield_visual()
	reset()
	if behavior != null:
		behavior.on_spawn(self)


func take_damage(amount: int) -> void:
	if current_hp <= 0.0:
		return
	var effective := float(amount) * (0.5 if shield_remaining > 0.0 else 1.0)
	current_hp = maxf(0.0, current_hp - effective)
	_update_display()
	_show_hit(ceili(effective))
	if current_hp <= 0.0:
		destroyed.emit(data)
	elif behavior != null:
		behavior.on_health_changed(self)


func heal(amount: float) -> void:
	if current_hp <= 0.0 or amount <= 0.0:
		return
	var healed := minf(amount, max_hp - current_hp)
	if healed <= 0.0:
		return
	current_hp += healed
	_update_display()
	_show_feedback("+%d HP" % ceili(healed), Color(0.45, 1.0, 0.55))


func activate_shield(duration: float) -> void:
	shield_remaining = maxf(shield_remaining, duration)
	_update_shield_visual()
	_show_feedback("SHIELD", Color(0.55, 0.85, 1.0))


func _update_shield_visual() -> void:
	center.modulate = Color(0.4, 0.8, 1.0) if shield_remaining > 0.0 else Color.WHITE


func reset() -> void:
	current_hp = max_hp
	scale = Vector2.ONE * (data.visual_scale if data != null else 1.0)
	body.modulate = Color.WHITE
	_update_display()


func reserve_attack_position(unit: Node2D, profile: UnitData.AttackProfile) -> void:
	var radius := _radius_for(profile)
	var slot_count := _slots_for(profile)
	var best_offset := Vector2.ZERO
	var best_distance := INF
	for index in slot_count:
		var offset := _ring_offset(index, slot_count, radius)
		if reserved_positions.values().has(offset):
			continue
		var distance := unit.global_position.distance_squared_to(global_position + offset)
		if distance < best_distance:
			best_distance = distance
			best_offset = offset
	if best_distance < INF:
		reserved_positions[unit] = best_offset
		reserved_profiles[unit] = profile
		return
	var waiting_index := 0
	while true:
		var ring_index := floori(float(waiting_index) / float(slot_count))
		var offset := _ring_offset(waiting_index % slot_count, slot_count,
			radius + WAITING_GAP * float(ring_index + 1))
		if not waiting_positions.values().has(offset):
			waiting_positions[unit] = offset
			waiting_profiles[unit] = profile
			return
		waiting_index += 1


func _ring_offset(index: int, count: int, radius: float) -> Vector2:
	var angle := -PI / 2.0 + TAU * float(index) / float(count)
	return Vector2.RIGHT.rotated(angle) * radius


func _radius_for(profile: UnitData.AttackProfile) -> float:
	match profile:
		UnitData.AttackProfile.MID:
			return MID_RADIUS
		UnitData.AttackProfile.RANGED:
			return RANGED_RADIUS
	return MELEE_RADIUS


func _slots_for(profile: UnitData.AttackProfile) -> int:
	match profile:
		UnitData.AttackProfile.MID:
			return MID_SLOT_COUNT
		UnitData.AttackProfile.RANGED:
			return RANGED_SLOT_COUNT
	return MELEE_SLOT_COUNT


func release_attack_position(unit: Node2D) -> void:
	if waiting_positions.has(unit):
		waiting_positions.erase(unit)
		waiting_profiles.erase(unit)
		return
	if not reserved_positions.has(unit):
		return
	var freed_offset: Vector2 = reserved_positions[unit]
	var profile: UnitData.AttackProfile = reserved_profiles[unit]
	reserved_positions.erase(unit)
	reserved_profiles.erase(unit)
	for waiting_unit: Node2D in waiting_profiles.keys():
		if waiting_profiles[waiting_unit] == profile:
			waiting_profiles.erase(waiting_unit)
			waiting_positions.erase(waiting_unit)
			reserved_positions[waiting_unit] = freed_offset
			reserved_profiles[waiting_unit] = profile
			return


func get_attack_position(unit: Node2D) -> Vector2:
	if reserved_positions.has(unit):
		return global_position + Vector2(reserved_positions[unit])
	return global_position + Vector2(waiting_positions.get(unit, Vector2.ZERO))


func has_attack_slot(unit: Node2D) -> bool:
	return reserved_positions.has(unit)


func _update_display() -> void:
	hp_fill.size.x = 64.0 * float(current_hp) / float(max_hp)
	hp_label.text = "%d / %d" % [ceili(current_hp), ceili(max_hp)]
	health_changed.emit(current_hp, max_hp)


func _show_hit(amount: int) -> void:
	if hit_tween and hit_tween.is_running():
		hit_tween.kill()
	scale = Vector2(1.08, 0.93) * (data.visual_scale if data != null else 1.0)
	body.modulate = Color(1.0, 0.6, 0.6)
	hit_tween = create_tween().set_parallel(true)
	hit_tween.tween_property(self, "scale", Vector2.ONE * (data.visual_scale if data != null else 1.0), 0.16)
	hit_tween.tween_property(body, "modulate", Color.WHITE, 0.16)
	if damage_tween and damage_tween.is_running():
		damage_tween.kill()
	_show_feedback("-%d" % amount, Color(1.0, 0.86, 0.46))


func _show_feedback(message: String, color: Color) -> void:
	if damage_tween and damage_tween.is_running():
		damage_tween.kill()
	damage_label.text = message
	damage_label.modulate = color
	damage_label.visible = true
	damage_label.position = Vector2(-20, -90)
	damage_tween = create_tween().set_parallel(true)
	damage_tween.tween_property(damage_label, "position:y", -105.0, 0.45)
	damage_tween.tween_property(damage_label, "modulate:a", 0.0, 0.45)
