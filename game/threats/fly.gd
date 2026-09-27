class_name Fly
extends Area2D

signal clicked

const ATTACK_SPEED_MULTIPLIER := 0.75
const HOVER_OFFSET := Vector2(0, -19)

@onready var lifetime: Timer = $Lifetime
@onready var body: Polygon2D = $Body
@onready var splat_label: Label = $SplatLabel

var attached_unit: Unit
var units_parent: Node2D
var hover_clock := 0.0
var removed := false


func _ready() -> void:
	lifetime.timeout.connect(_expire)
	input_event.connect(_on_input_event)
	lifetime.start()


func attach(unit: Unit, parent: Node2D) -> void:
	units_parent = parent
	attached_unit = unit
	attached_unit.set_attack_speed_multiplier(ATTACK_SPEED_MULTIPLIER)
	global_position = unit.global_position + HOVER_OFFSET


func _process(delta: float) -> void:
	if removed:
		return
	if not is_instance_valid(attached_unit) or attached_unit.is_queued_for_deletion():
		_retarget()
		if not is_instance_valid(attached_unit) or attached_unit.is_queued_for_deletion():
			return
	hover_clock += delta * 8.0
	global_position = attached_unit.global_position + HOVER_OFFSET + Vector2(0, sin(hover_clock) * 3.0)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_click()


func _click() -> void:
	if removed:
		return
	removed = true
	_release_unit()
	lifetime.stop()
	input_pickable = false
	body.visible = false
	splat_label.visible = true
	clicked.emit()
	get_tree().create_timer(0.5).timeout.connect(queue_free)


func _expire() -> void:
	if removed:
		return
	removed = true
	_release_unit()
	queue_free()


func _release_unit() -> void:
	if is_instance_valid(attached_unit) and not attached_unit.is_queued_for_deletion():
		attached_unit.set_attack_speed_multiplier(1.0)
	attached_unit = null


func _retarget() -> void:
	_release_unit()
	for child: Node in units_parent.get_children():
		if child is Unit and not child.is_queued_for_deletion():
			attach(child as Unit, units_parent)
			return
