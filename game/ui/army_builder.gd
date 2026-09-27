class_name ArmyBuilder
extends Control

@onready var card_grid: GridContainer = $Panel/CardGrid
@onready var slot_buttons: Array[Button] = [
	$Panel/Slots/Slot1, $Panel/Slots/Slot2, $Panel/Slots/Slot3
]
@onready var hint_label: Label = $Panel/Hint

var collection: CardCollection
var loadout: ArmyLoadout
var selected_card: CardData


func configure(card_collection: CardCollection, army_loadout: ArmyLoadout) -> void:
	collection = card_collection
	loadout = army_loadout
	collection.cards_changed.connect(_refresh)
	loadout.changed.connect(_refresh)
	for index: int in range(slot_buttons.size()):
		slot_buttons[index].pressed.connect(_on_slot_pressed.bind(index))
	_refresh()


func open() -> void:
	selected_card = null
	hint_label.text = "Pick a card, then an army slot."
	_refresh()
	visible = true


func _refresh() -> void:
	if collection == null or loadout == null:
		return
	for child: Node in card_grid.get_children():
		card_grid.remove_child(child)
		child.queue_free()
	var equipped := loadout.get_cards()
	for card: CardData in collection.cards:
		var button := Button.new()
		button.custom_minimum_size = Vector2(190, 56)
		button.add_theme_font_size_override("font_size", 10)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = _card_text(card, equipped)
		button.icon = card.icon if card.icon != null else _placeholder_icon(card.unit_data.color)
		button.disabled = not collection.is_unlocked(card)
		button.modulate = Color(1, 0.93, 0.6) if card == selected_card else Color.WHITE
		button.pressed.connect(_on_card_pressed.bind(card))
		card_grid.add_child(button)
	for index: int in range(slot_buttons.size()):
		var card: CardData = equipped[index]
		slot_buttons[index].text = "%d: %s" % [index + 1, card.display_name if card != null else "Empty"]


func _card_text(card: CardData, equipped: Array[CardData]) -> String:
	var selected := "SLOT %d" % (equipped.find(card) + 1) if equipped.has(card) else "AVAILABLE"
	if not collection.is_unlocked(card):
		selected = "LOCKED"
	else:
		selected = "x%d · %s" % [collection.get_owned_copies(card), selected]
	var unit := card.unit_data
	var profile: String = UnitData.AttackProfile.keys()[unit.attack_profile]
	return "%s · %s · %s\nDMG %d  ATK %.1fs\nSPAWN %.1fs  MAX %d  %s" % [
		card.display_name, card.rarity_name(), selected,
		unit.damage, unit.attack_interval, unit.spawn_interval,
		unit.max_active_instances, profile
	]


func _placeholder_icon(color: Color) -> Texture2D:
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for y: int in range(2, 14):
		for x: int in range(2, 14):
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


func _on_card_pressed(card: CardData) -> void:
	selected_card = card
	hint_label.text = "Choose a slot for %s." % card.display_name
	_refresh()


func _on_slot_pressed(index: int) -> void:
	if selected_card == null:
		hint_label.text = "Pick a card first."
		return
	if loadout.equip(index, selected_card):
		hint_label.text = "%s equipped in slot %d." % [selected_card.display_name, index + 1]
		selected_card = null
		_refresh()
	else:
		hint_label.text = "That card cannot be equipped."
