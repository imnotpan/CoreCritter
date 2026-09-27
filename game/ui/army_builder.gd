class_name ArmyBuilder
extends Control

signal world_requested
signal start_requested
signal back_requested
signal equip_requested(index: int, card: CardData)
signal upgrade_requested(card: CardData)
signal debug_copies_requested(card: CardData)
signal debug_coins_requested

@onready var card_grid: GridContainer = $Panel/CardGrid
@onready var slot_buttons: Array[Button] = [
	$Panel/Slots/Slot1, $Panel/Slots/Slot2, $Panel/Slots/Slot3
]
@onready var hint_label: Label = $Panel/Hint

var collection: CardCollection
var loadout: DeckLoadout
var wallet: Wallet
var progression: WorldProgression
var selected_world: WorldData
var collection_only := false
var selected_card: CardData
var detail_label: Label
var upgrade_button: Button
var back_button: Button
var debug_copies_button: Button
var debug_coins_button: Button
var detail_slot_buttons: Array[Button] = []


func configure(card_collection: CardCollection, deck: DeckLoadout, player_wallet: Wallet, worlds: WorldProgression) -> void:
	collection = card_collection
	loadout = deck
	wallet = player_wallet
	progression = worlds
	_build_detail()
	collection.cards_changed.connect(_refresh)
	loadout.changed.connect(_refresh)
	wallet.coins_changed.connect(func(_coins: int) -> void: _refresh())
	for index: int in range(slot_buttons.size()):
		slot_buttons[index].pressed.connect(_on_slot_pressed.bind(index))
	$Panel/WorldButton.pressed.connect(func() -> void: world_requested.emit())
	$Panel/StartButton.pressed.connect(func() -> void: start_requested.emit())
	$Panel/BackButton.pressed.connect(func() -> void: back_requested.emit())
	_refresh()


func open(as_collection: bool = false) -> void:
	collection_only = as_collection
	selected_card = null
	hint_label.text = "View cards and upgrades." if collection_only else "COLLECTION — pick a card, then a deck slot."
	_refresh()
	visible = true


func set_world(world: WorldData) -> void:
	selected_world = world
	_refresh()


func _refresh() -> void:
	if collection == null or loadout == null:
		return
	var showing_detail := selected_card != null
	$Panel/Title.text = "COLLECTION" if collection_only else "PRE-RUN / YOUR DECK"
	$Panel/WorldButton.visible = not collection_only and not showing_detail
	$Panel/StartButton.visible = not collection_only and not showing_detail
	$Panel/WorldButton.text = "WORLD: %s" % (selected_world.display_name.to_upper() if selected_world != null else "SELECT")
	$Panel/StartButton.disabled = collection_only or not loadout.is_valid() or selected_world == null or not progression.worlds.has(selected_world) or not progression.is_unlocked(selected_world) or selected_world.cores.is_empty()
	card_grid.visible = not showing_detail
	$Panel/ArmyLabel.visible = not showing_detail and not collection_only
	$Panel/Slots.visible = not showing_detail and not collection_only
	detail_label.visible = showing_detail
	upgrade_button.visible = showing_detail and collection_only
	back_button.visible = showing_detail
	debug_copies_button.visible = showing_detail and OS.is_debug_build()
	debug_coins_button.visible = showing_detail and OS.is_debug_build()
	for button: Button in detail_slot_buttons:
		button.visible = showing_detail and not collection_only
	if showing_detail:
		_refresh_detail()
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
		button.disabled = not collection.is_unlocked(card) and not collection_only
		button.modulate = Color(1, 0.93, 0.6) if card == selected_card else Color.WHITE
		button.pressed.connect(_on_card_pressed.bind(card))
		card_grid.add_child(button)
	for index: int in range(slot_buttons.size()):
		var card: CardData = equipped[index] if index < equipped.size() else null
		slot_buttons[index].text = "%d: %s" % [index + 1, card.display_name if card != null else "Empty"]


func _card_text(card: CardData, equipped: Array[CardData]) -> String:
	var selected := "SLOT %d" % (equipped.find(card) + 1) if equipped.has(card) else "AVAILABLE"
	if collection_only:
		selected = "OWNED"
	if not collection.is_unlocked(card):
		selected = "LOCKED"
	else:
		selected = "Copies: %d · %s" % [collection.get_owned_copies(card), selected]
	var unit := card.unit_data
	return "%s  %s  %s\n%s" % [card.display_name, _stars(collection.get_star_level(card)), card.rarity_name().to_upper(), selected]


func _stars(level: int) -> String:
	return "★".repeat(level) + "☆".repeat(5 - level)


func _build_detail() -> void:
	var panel: Panel = $Panel
	detail_label = Label.new()
	detail_label.position = Vector2(10, 50)
	detail_label.size = Vector2(380, 193)
	detail_label.add_theme_font_size_override("font_size", 13)
	panel.add_child(detail_label)
	for index: int in range(DeckLoadout.SLOT_COUNT):
		var slot_button := Button.new()
		slot_button.position = Vector2(10 + index * 129, 210)
		slot_button.size = Vector2(122, 32)
		slot_button.text = "EQUIP SLOT %d" % (index + 1)
		slot_button.pressed.connect(_on_slot_pressed.bind(index))
		panel.add_child(slot_button)
		detail_slot_buttons.append(slot_button)
	upgrade_button = Button.new()
	upgrade_button.position = Vector2(10, 247)
	upgrade_button.size = Vector2(260, 33)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	panel.add_child(upgrade_button)
	back_button = Button.new()
	back_button.position = Vector2(280, 247)
	back_button.size = Vector2(110, 33)
	back_button.text = "BACK"
	back_button.pressed.connect(func() -> void:
		selected_card = null
		_refresh()
	)
	panel.add_child(back_button)
	debug_copies_button = Button.new()
	debug_copies_button.position = Vector2(10, 284)
	debug_copies_button.size = Vector2(180, 27)
	debug_copies_button.text = "DEBUG +10 COPIES"
	debug_copies_button.pressed.connect(func() -> void: debug_copies_requested.emit(selected_card))
	panel.add_child(debug_copies_button)
	debug_coins_button = Button.new()
	debug_coins_button.position = Vector2(200, 284)
	debug_coins_button.size = Vector2(190, 27)
	debug_coins_button.text = "DEBUG +1000 COINS"
	debug_coins_button.pressed.connect(func() -> void: debug_coins_requested.emit())
	panel.add_child(debug_coins_button)


func _refresh_detail() -> void:
	var card := selected_card
	var level := collection.get_star_level(card)
	var unit := card.unit_data
	var profile: String = UnitData.AttackProfile.keys()[unit.attack_profile]
	var signature := unit.behavior.signature_name if unit.behavior != null else ""
	var mastery := unit.behavior.mastery_name if unit.behavior != null else ""
	var ability := "Base creature"
	if level >= 5:
		ability = "%s + %s" % [signature, mastery]
	elif level >= 3:
		ability = signature
	var next := "MAX STAR"
	if level == 0:
		next = "Unlock from a pack"
	elif level == 1 or level == 3:
		next = "%d★ +%d%% damage" % [level + 1, 15 if level == 1 else 20]
	elif level == 2:
		next = "3★ %s" % signature
	elif level == 4:
		next = "5★ %s" % mastery
	var cost := collection.get_upgrade_cost(card.id)
	var cost_text := "LOCKED" if level == 0 else ("MAX STAR" if level >= 5 else "%d copies + %d coins" % [cost.x, cost.y])
	detail_label.text = "%s  %s  %s\nCopies: %d    Coins: %d\nDamage: %d    Attack: %.1fs\nSpawn: %.1fs    Max active: %d\nProfile: %s\nAbility: %s\nNext: %s\nCost: %s" % [
		card.display_name, _stars(level), card.rarity_name().to_upper(),
		collection.get_owned_copies(card), wallet.coins,
		StarStats.damage(unit.damage, level), unit.attack_interval,
		unit.spawn_interval, unit.max_active_instances, profile,
		ability, next, cost_text]
	upgrade_button.disabled = not collection_only or not collection.can_upgrade(card.id)
	upgrade_button.text = "UPGRADE" if not upgrade_button.disabled else _upgrade_reason(card, cost)


func _upgrade_reason(card: CardData, cost: Vector2i) -> String:
	if not collection.is_unlocked(card):
		return "LOCKED"
	if collection.get_star_level(card) >= 5:
		return "MAX STAR"
	var missing_copies := maxi(0, cost.x - collection.get_owned_copies(card))
	var missing_coins := maxi(0, cost.y - wallet.coins)
	if missing_copies > 0:
		return "Need %d more copies" % missing_copies
	if missing_coins > 0:
		return "Need %d more coins" % missing_coins
	return "UPGRADE UNAVAILABLE"


func _on_upgrade_pressed() -> void:
	if selected_card == null or not collection_only:
		return
	upgrade_requested.emit(selected_card)
	_refresh()


func show_upgrade(card: CardData) -> void:
	selected_card = card
	var level := collection.get_star_level(selected_card)
	var behavior := selected_card.unit_data.behavior
	if level == 3 or level == 5:
		hint_label.text = "%s → %s  %s UNLOCKED!" % [selected_card.display_name, _stars(level), behavior.signature_name if level == 3 else behavior.mastery_name]
	else:
		hint_label.text = "%s → %s  DAMAGE +%d%%" % [selected_card.display_name, _stars(level), 15 if level == 2 else 20]
	_refresh()


func _placeholder_icon(color: Color) -> Texture2D:
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for y: int in range(2, 14):
		for x: int in range(2, 14):
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


func _on_card_pressed(card: CardData) -> void:
	selected_card = card
	hint_label.text = "View %s progression." % card.display_name if collection_only else "Choose a deck slot for %s." % card.display_name
	_refresh()


func _on_slot_pressed(index: int) -> void:
	if collection_only:
		return
	if selected_card == null:
		hint_label.text = "Pick a card first."
		return
	equip_requested.emit(index, selected_card)
	selected_card = null
	_refresh()
