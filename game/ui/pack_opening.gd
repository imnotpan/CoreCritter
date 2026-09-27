class_name PackOpening
extends Control

signal open_requested

@onready var title_label: Label = $Panel/Title
@onready var count_label: Label = $Panel/Count
@onready var open_button: Button = $Panel/Open
@onready var continue_button: Button = $Panel/Continue
@onready var results_list: VBoxContainer = $Panel/Results


func _ready() -> void:
	open_button.pressed.connect(func() -> void: open_requested.emit())
	continue_button.pressed.connect(hide)


func show_inventory(pack_name: String, count: int) -> void:
	title_label.text = pack_name
	_clear_results()
	set_pack_count(count)
	visible = true


func set_pack_count(count: int) -> void:
	count_label.text = "PACKS x%d" % count
	open_button.disabled = count <= 0


func show_results(pack_name: String, cards: Array[CardData], new_flags: Array[bool]) -> void:
	title_label.text = pack_name
	_clear_results()
	for index: int in range(cards.size()):
		var label := Label.new()
		label.text = "%s  ·  %s  ·  %s" % [
			cards[index].display_name,
			cards[index].rarity_name().to_upper(),
			"NEW!" if new_flags[index] else "+1"
		]
		label.add_theme_font_size_override("font_size", 16)
		results_list.add_child(label)


func _clear_results() -> void:
	for child: Node in results_list.get_children():
		results_list.remove_child(child)
		child.queue_free()
