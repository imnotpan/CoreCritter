class_name CoreInteraction
extends Node2D

signal finished

const NAMES := ["", "PAPER JAM", "COFFEE SPILL", "FIREWALL NODES", "GRAB"]

var kind: CoreData.Interaction
var army: Army
var core: CoreTarget
var victim: Unit
var markers: Array[Button] = []
var warning := 1.5
var remaining := 15.0
var tick_clock := 0.0
var resolved := false
var ended := false
var clicks_left := 3
var zone_center := Vector2.ZERO
var affected: Array[Unit] = []


func configure(type: CoreData.Interaction, player_army: Army, target: CoreTarget) -> bool:
	kind = type
	army = player_army
	core = target
	var candidates := army.get_active_units().filter(func(unit: Unit) -> bool: return not unit.exploding and not unit.ko)
	if candidates.is_empty():
		return false
	victim = candidates.pick_random()
	zone_center = victim.global_position
	if kind == CoreData.Interaction.COFFEE_SPILL:
		zone_center = zone_center.clamp(Vector2(65, 110), Vector2(335, 180))
	if kind == CoreData.Interaction.FIREWALL_NODES:
		for index: int in 3:
			_add_marker(core.global_position + Vector2.RIGHT.rotated(-PI / 2.0 + TAU * index / 3.0) * 88.0)
	else:
		_add_marker(zone_center)
	return true


func _marker_position(at: Vector2) -> Vector2:
	return (at - global_position - Vector2(42, 0)).clamp(Vector2(8, 75), Vector2(308, 176))


func _add_marker(at: Vector2) -> void:
	var button := Button.new()
	button.position = _marker_position(at - Vector2(0, 16))
	button.custom_minimum_size = Vector2(84, 32)
	button.add_theme_font_size_override("font_size", 9)
	button.text = NAMES[kind] + "\nINCOMING"
	button.modulate = Color(1, 0.8, 0.5, 0.8)
	button.disabled = true
	button.pressed.connect(interact.bind(button))
	add_child(button)
	markers.append(button)


func _process(delta: float) -> void:
	advance(delta)


func advance(delta: float) -> void:
	if ended:
		return
	if core.current_hp <= 0.0 or not army.running:
		finish()
		return
	if not resolved:
		if (kind == CoreData.Interaction.PAPER_JAM or kind == CoreData.Interaction.GRAB) and is_instance_valid(victim):
			markers[0].position = _marker_position(victim.global_position - Vector2(0, 36))
		warning -= delta
		queue_redraw()
		if warning > 0.0:
			return
		resolve()
		return
	remaining -= delta
	if remaining <= 0.0:
		if kind == CoreData.Interaction.GRAB and is_instance_valid(victim):
			victim.knock_out()
		finish()
		return
	if kind == CoreData.Interaction.PAPER_JAM or kind == CoreData.Interaction.GRAB:
		if not is_instance_valid(victim) or victim.ko or victim.is_queued_for_deletion():
			finish()
			return
		markers[0].position = _marker_position(victim.global_position - Vector2(0, 36))
	if kind == CoreData.Interaction.COFFEE_SPILL:
		tick_clock += delta
		if tick_clock >= 1.0:
			tick_clock = 0.0
			for unit: Unit in army.get_active_units():
				if unit.global_position.distance_to(zone_center) <= 55.0:
					unit.apply_speed_effect(&"coffee", 0.75, 1.2)
					if not affected.has(unit):
						affected.append(unit)
					unit.take_damage(4)
	queue_redraw()


func resolve() -> void:
	resolved = true
	for marker: Button in markers:
		marker.disabled = false
		marker.text = NAMES[kind] + "\nCLICK / EXPIRES"
		marker.modulate = Color(1, 0.85, 0.65, 0.9)
	match kind:
		CoreData.Interaction.PAPER_JAM:
			if is_instance_valid(victim) and not victim.ko:
				_launch_paper()
				victim.take_damage(5)
				victim.apply_speed_effect(&"paper", 0.65, remaining)
		CoreData.Interaction.FIREWALL_NODES:
			core.firewall_nodes = markers.size()
		CoreData.Interaction.GRAB:
			remaining = 8.0
			if is_instance_valid(victim) and not victim.ko:
				victim.disabled = true
				victim.global_position = core.global_position + Vector2(0, -30)


func interact(marker: Button = null) -> void:
	if ended or not resolved:
		return
	if kind == CoreData.Interaction.FIREWALL_NODES:
		if marker == null or not markers.has(marker):
			return
		markers.erase(marker)
		marker.queue_free()
		core.firewall_nodes = markers.size()
		if markers.is_empty():
			finish()
	else:
		clicks_left -= 1
		if clicks_left <= 0 or kind == CoreData.Interaction.PAPER_JAM:
			finish()
		elif not markers.is_empty():
			markers[0].text = NAMES[kind] + "\n%d CLICKS" % clicks_left


func finish() -> void:
	if ended:
		return
	ended = true
	if is_instance_valid(victim):
		victim.speed_effects.erase(&"paper")
		if kind == CoreData.Interaction.GRAB:
			victim.disabled = false
	for unit: Unit in affected:
		if is_instance_valid(unit):
			unit.speed_effects.erase(&"coffee")
	if is_instance_valid(core) and kind == CoreData.Interaction.FIREWALL_NODES:
		core.firewall_nodes = 0
	finished.emit()
	queue_free()


func _draw() -> void:
	if ended:
		return
	var tint := Color(1.0, 0.65, 0.25, 0.25) if not resolved else Color(0.55, 0.27, 0.1, 0.35)
	if kind == CoreData.Interaction.COFFEE_SPILL:
		draw_circle(zone_center - global_position, 55.0, tint)
		draw_arc(zone_center - global_position, 55.0, 0, TAU, 32, Color(1, 0.65, 0.2, 0.7), 2.0)
	else:
		for marker: Button in markers:
			draw_circle(marker.position + Vector2(42, 16), 24.0 + (sin(warning * 8) * 4.0 if not resolved else 0.0), tint)


func _launch_paper() -> void:
	var paper := Polygon2D.new()
	paper.polygon = PackedVector2Array([Vector2(-5, -4), Vector2(5, -4), Vector2(5, 4), Vector2(-5, 4)])
	paper.color = Color(1, 0.95, 0.8)
	add_child(paper)
	paper.global_position = core.global_position
	var tween := paper.create_tween()
	tween.tween_property(paper, "global_position", victim.global_position, 0.3)
	tween.tween_callback(paper.queue_free)
