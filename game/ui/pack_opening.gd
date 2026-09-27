class_name PackOpening
extends Control

signal open_requested
signal presentation_cue(cue: StringName)

const CARD_SCENE: PackedScene = preload("res://game/ui/card_view.tscn")

@onready var title_label: Label = $Panel/Title
@onready var count_label: Label = $Panel/Count
@onready var open_button: Button = $Panel/Open
@onready var continue_button: Button = $Panel/Continue
@onready var reveal_all_button: Button = $Panel/RevealAll
@onready var hint_label: Label = $Panel/Hint
@onready var cards_row: Control = $Panel/Cards
@onready var focus_dim: ColorRect = $Panel/FocusDim
@onready var debug_hint: Label = $Panel/DebugHint

var _cards: Array[CardView] = []
var _preview_cards: Array[CardData] = []
var _revealing := false
var _focus_tweens: Array[Tween] = []


func _ready() -> void:
	open_button.pressed.connect(func() -> void: open_requested.emit())
	continue_button.pressed.connect(_continue)
	reveal_all_button.pressed.connect(_reveal_all)
	debug_hint.visible = OS.is_debug_build()
	_reset_view()


func configure_debug_cards(cards: Array[CardData]) -> void:
	_preview_cards = cards.duplicate()


func show_inventory(pack_name: String, count: int) -> void:
	title_label.text = pack_name
	_clear_cards()
	_revealing = false
	_reset_view()
	set_pack_count(count)
	visible = true


func set_pack_count(count: int) -> void:
	count_label.text = "PACKS x%d" % count
	open_button.disabled = count <= 0


func show_results(pack_name: String, cards: Array[CardData], new_flags: Array[bool], copies_before: Array[int], copies_after: Array[int], stars: Array[int], during_run: bool = false) -> void:
	title_label.text = pack_name
	_clear_cards()
	open_button.visible = false
	continue_button.visible = false
	reveal_all_button.visible = true
	hint_label.text = "PICK A CARD TO REVEAL"
	for index: int in range(cards.size()):
		var view: CardView = CARD_SCENE.instantiate()
		cards_row.add_child(view)
		view.position = Vector2(7.0 + index * 126.0, 0.0)
		view.configure(cards[index], new_flags[index], copies_before[index], copies_after[index], stars[index], during_run)
		view.reveal_requested.connect(_reveal_card)
		view.reveal_finished.connect(_on_reveal_finished)
		view.presentation_cue.connect(func(cue: StringName) -> void: presentation_cue.emit(cue))
		_cards.append(view)
		view.enter(index * 0.08)
	presentation_cue.emit(&"pack_open")


func _reveal_card(view: CardView) -> void:
	if _revealing:
		return
	_revealing = true
	_stop_focus_tweens()
	focus_dim.visible = false
	for other: CardView in _cards:
		other.modulate.a = 1.0
	if view.card.rarity == CardData.Rarity.RARE:
		focus_dim.visible = true
		focus_dim.modulate.a = 0.0
		var tween := create_tween()
		_focus_tweens.append(tween)
		tween.tween_property(focus_dim, "modulate:a", 0.42, 0.22)
		cards_row.move_child(view, cards_row.get_child_count() - 1)
		for other: CardView in _cards:
			if other != view and other.state == CardView.State.HIDDEN:
				var dim_tween := create_tween()
				_focus_tweens.append(dim_tween)
				dim_tween.tween_property(other, "modulate:a", 0.45, 0.22)
	view.reveal()


func _on_reveal_finished(_view: CardView) -> void:
	_revealing = false
	_stop_focus_tweens()
	for other: CardView in _cards:
		if other != _view and other.state == CardView.State.HIDDEN:
			var restore_tween := create_tween()
			_focus_tweens.append(restore_tween)
			restore_tween.tween_property(other, "modulate:a", 1.0, 0.14)
	if focus_dim.visible:
		var tween := create_tween()
		_focus_tweens.append(tween)
		tween.tween_property(focus_dim, "modulate:a", 0.0, 0.14)
		tween.finished.connect(func() -> void: focus_dim.visible = false)
	for view: CardView in _cards:
		if view.state != CardView.State.REVEALED:
			return
	hint_label.text = "PACK COMPLETE"
	continue_button.text = "CONTINUE"
	continue_button.visible = true
	reveal_all_button.visible = false


func _reveal_all() -> void:
	_revealing = false
	_stop_focus_tweens()
	focus_dim.visible = false
	for view: CardView in _cards:
		view.modulate.a = 1.0
		view.reveal_immediately()


func _continue() -> void:
	_clear_cards()
	_reset_view()
	visible = false


func _reset_view() -> void:
	open_button.visible = true
	continue_button.visible = true
	continue_button.text = "CLOSE"
	reveal_all_button.visible = false
	focus_dim.visible = false
	hint_label.text = "A LITTLE TROUBLE INSIDE"


func _clear_cards() -> void:
	_revealing = false
	_stop_focus_tweens()
	for view: CardView in _cards:
		cards_row.remove_child(view)
		view.queue_free()
	_cards.clear()
	focus_dim.visible = false


func _stop_focus_tweens() -> void:
	for tween: Tween in _focus_tweens:
		if tween.is_running():
			tween.kill()
	_focus_tweens.clear()


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not OS.is_debug_build() or not event is InputEventKey or not event.pressed or event.echo:
		return
	var rarity := -1
	var new_card := false
	match event.keycode:
		KEY_1:
			rarity = CardData.Rarity.COMMON
		KEY_2:
			rarity = CardData.Rarity.UNCOMMON
		KEY_3:
			rarity = CardData.Rarity.RARE
		KEY_4:
			rarity = CardData.Rarity.RARE
			new_card = true
	if rarity < 0:
		return
	for candidate: CardData in _preview_cards:
		if candidate.rarity == rarity:
			var preview: Array[CardData] = [candidate, candidate, candidate]
			var flags: Array[bool] = [false, new_card, false]
			var before: Array[int] = [1, 0 if new_card else 2, 3]
			var after: Array[int] = [2, 0 if new_card else 3, 4]
			var stars: Array[int] = [1, 1, 1]
			show_results("PREVIEW · " + candidate.rarity_name().to_upper(), preview, flags, before, after, stars)
			get_viewport().set_input_as_handled()
			return
