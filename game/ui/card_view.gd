class_name CardView
extends Control

signal reveal_requested(card_view: CardView)
signal presentation_cue(cue: StringName)
signal reveal_finished(card_view: CardView)

enum State { HIDDEN, ANTICIPATING, FLIPPING, REVEALED }

const INK := Color("242432")
const CREAM := Color("f8edce")
const COMMON := Color("c3c7b3")
const UNCOMMON := Color("8ce5bd")
const RARE := Color("ffd17c")

@onready var card_back: Control = $CardBack
@onready var card_front: Control = $CardFront
@onready var creature_visual: Label = $CardFront/CreatureVisual
@onready var name_label: Label = $CardFront/NameLabel
@onready var rarity_label: Label = $CardFront/RarityLabel
@onready var star_display: Label = $CardFront/StarDisplay
@onready var result_badge: Label = $CardFront/ResultBadge
@onready var copies_label: Label = $CardFront/CopiesLabel
@onready var icon: TextureRect = $CardFront/Icon

var state := State.HIDDEN
var card: CardData
var is_new := false
var glow_strength := 0.0:
	set(value):
		glow_strength = value
		queue_redraw()
var burst_strength := 0.0:
	set(value):
		burst_strength = value
		queue_redraw()
var hover_strength := 0.0:
	set(value):
		hover_strength = value
		queue_redraw()
var _active_tween: Tween
var _entry_tween: Tween
var _hover_tween: Tween
var _landed := true
var _rest_position := Vector2.ZERO
var _hover_x := 0.5


func _ready() -> void:
	pivot_offset = size * 0.5
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_show_face(false)


func configure(value: CardData, new_card: bool, copies_before: int, copies_after: int, stars: int, during_run: bool = false) -> void:
	card = value
	is_new = new_card
	state = State.HIDDEN
	name_label.text = value.display_name.to_upper()
	rarity_label.text = value.rarity_name().to_upper()
	star_display.text = "★".repeat(maxi(stars, 1))
	result_badge.text = "NEW!" if new_card else "+1 COPY"
	copies_label.text = ("AVAILABLE NEXT RUN" if during_run else "NEW CREATURE!") if new_card else "COPIES %d → %d" % [copies_before, copies_after]
	creature_visual.text = value.display_name.substr(0, 1).to_upper()
	icon.texture = value.icon
	icon.visible = value.icon != null
	creature_visual.visible = value.icon == null
	_show_face(false)
	queue_redraw()


func enter(delay: float) -> void:
	_landed = false
	_rest_position = position
	modulate.a = 0.0
	position.y += 24.0
	scale = Vector2(0.88, 0.88)
	_entry_tween = create_tween()
	_entry_tween.tween_interval(delay)
	_entry_tween.tween_property(self, "modulate:a", 1.0, 0.14)
	_entry_tween.parallel().tween_property(self, "position:y", position.y - 24.0, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_entry_tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_entry_tween.finished.connect(func() -> void:
		_landed = true
		presentation_cue.emit(&"card_land")
	)


func reveal() -> void:
	if state != State.HIDDEN or card == null or not _landed:
		return
	state = State.ANTICIPATING
	var rarity := card.rarity
	var pause := 0.08 if rarity == CardData.Rarity.COMMON else (0.19 if rarity == CardData.Rarity.UNCOMMON else 0.42)
	var glow := 0.3 if rarity == CardData.Rarity.COMMON else (0.6 if rarity == CardData.Rarity.UNCOMMON else 1.0)
	_active_tween = create_tween()
	_active_tween.tween_property(self, "scale", Vector2(1.07, 1.07) if rarity == CardData.Rarity.RARE else Vector2(1.035, 1.035), pause)
	_active_tween.parallel().tween_property(self, "glow_strength", glow, pause)
	await _active_tween.finished
	if state != State.ANTICIPATING:
		return
	state = State.FLIPPING
	_active_tween = create_tween()
	_active_tween.tween_property(self, "scale:x", 0.04, 0.12).set_trans(Tween.TRANS_QUAD)
	await _active_tween.finished
	if state != State.FLIPPING:
		return
	_show_face(true)
	presentation_cue.emit(_rarity_cue())
	_active_tween = create_tween()
	_active_tween.tween_property(self, "scale", Vector2(1.13, 1.13) if is_new else Vector2(1.08, 1.08), 0.19 if rarity == CardData.Rarity.RARE else 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var burst := 0.2 if rarity == CardData.Rarity.COMMON else (0.6 if rarity == CardData.Rarity.UNCOMMON else 1.0)
	_active_tween.parallel().tween_property(self, "burst_strength", burst, 0.08)
	await _active_tween.finished
	if state != State.FLIPPING:
		return
	if is_new:
		presentation_cue.emit(&"new_card")
	_active_tween = create_tween()
	_active_tween.tween_property(self, "scale", Vector2.ONE, 0.16 if is_new else 0.11).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_active_tween.parallel().tween_property(self, "burst_strength", 0.0, 0.26)
	_active_tween.parallel().tween_property(self, "glow_strength", 0.0, 0.26)
	if is_new:
		_active_tween.tween_interval(0.10)
	await _active_tween.finished
	if state == State.FLIPPING:
		state = State.REVEALED
		reveal_finished.emit(self)


func reveal_immediately() -> void:
	if state == State.REVEALED or card == null:
		return
	if _active_tween and _active_tween.is_running():
		_active_tween.kill()
	if _entry_tween and _entry_tween.is_running():
		_entry_tween.kill()
	modulate.a = 1.0
	position = _rest_position
	_landed = true
	state = State.REVEALED
	_show_face(true)
	scale = Vector2.ONE
	glow_strength = 0.0
	burst_strength = 0.0
	hover_strength = 0.0
	queue_redraw()
	presentation_cue.emit(_rarity_cue())
	if is_new:
		presentation_cue.emit(&"new_card")
	reveal_finished.emit(self)


func _rarity_cue() -> StringName:
	match card.rarity:
		CardData.Rarity.UNCOMMON:
			return &"uncommon_reveal"
		CardData.Rarity.RARE:
			return &"rare_reveal"
	return &"common_reveal"


func _show_face(front: bool) -> void:
	card_back.visible = not front
	card_front.visible = front
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if state == State.HIDDEN and _landed and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		reveal_requested.emit(self)
		accept_event()
	elif state == State.REVEALED and event is InputEventMouseMotion:
		_hover_x = clampf(event.position.x / size.x, 0.0, 1.0)
		rotation = clampf((_hover_x - 0.5) * 0.09, -0.045, 0.045)
		queue_redraw()


func _on_mouse_entered() -> void:
	if state == State.REVEALED:
		if _hover_tween:
			_hover_tween.kill()
		_hover_tween = create_tween()
		_hover_tween.tween_property(self, "scale", Vector2(1.04, 1.04), 0.12)
		_hover_tween.parallel().tween_property(self, "hover_strength", 1.0, 0.12)


func _on_mouse_exited() -> void:
	if state == State.REVEALED:
		if _hover_tween:
			_hover_tween.kill()
		_hover_tween = create_tween()
		_hover_tween.tween_property(self, "scale", Vector2.ONE, 0.15)
		_hover_tween.parallel().tween_property(self, "rotation", 0.0, 0.15)
		_hover_tween.parallel().tween_property(self, "hover_strength", 0.0, 0.15)


func _draw() -> void:
	if card == null:
		return
	var color := COMMON if card.rarity == CardData.Rarity.COMMON else (UNCOMMON if card.rarity == CardData.Rarity.UNCOMMON else RARE)
	if glow_strength > 0.01:
		draw_rect(Rect2(-3, -3, size.x + 6, size.y + 6), Color(color, glow_strength * 0.55), false, 3.0)
	if burst_strength > 0.01:
		var rays := 12 if card.rarity == CardData.Rarity.RARE else 8
		for index: int in rays:
			var angle := TAU * float(index) / float(rays)
			var direction := Vector2.RIGHT.rotated(angle)
			var center := size * 0.5
			draw_line(center + direction * 64.0, center + direction * (64.0 + 13.0 * burst_strength), Color(color, burst_strength), 2.0)
	if card_front.visible:
		draw_rect(Rect2(Vector2.ZERO, size), INK)
		draw_rect(Rect2(3, 3, size.x - 6, size.y - 6), RARE if is_new else color, false, 3.0 if not is_new else 5.0)
		draw_rect(Rect2(7, 7, size.x - 14, size.y - 14), CREAM)
		draw_rect(Rect2(10, 25, size.x - 20, 69), Color(color, 0.48))
		if hover_strength > 0.01:
			var shine_x := lerpf(14.0, size.x - 25.0, _hover_x)
			draw_colored_polygon(PackedVector2Array([
				Vector2(shine_x, 27), Vector2(shine_x + 12, 27),
				Vector2(shine_x - 12, 92), Vector2(shine_x - 24, 92)
			]), Color(1.0, 1.0, 1.0, hover_strength * 0.16))
	else:
		draw_rect(Rect2(Vector2.ZERO, size), INK)
		draw_rect(Rect2(4, 4, size.x - 8, size.y - 8), Color("58517a"), false, 3.0)
		for index: int in 5:
			draw_line(Vector2(13 + index * 20, 20), Vector2(13 + index * 20, size.y - 20), Color("716890"), 1.0)
		draw_circle(size * 0.5, 26.0, Color("f2d585"))
		draw_circle(size * 0.5, 20.0, INK)
