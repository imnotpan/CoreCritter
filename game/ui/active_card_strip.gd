class_name ActiveCardStrip
extends HBoxContainer

const INK := Color("152125")
const CREAM := Color("f7efd5")
const MUTED := Color("aebbbb")

signal command_requested(card: CardData)

var commands: CardCommands
var loadout: RunLoadout
var army: Army
var slots: Array[Dictionary] = []
var state_timer: Timer


func _ready() -> void:
	add_theme_constant_override("separation", 4)
	for index: int in DeckLoadout.SLOT_COUNT:
		_add_slot(index)
	state_timer = Timer.new()
	state_timer.wait_time = 0.25
	state_timer.timeout.connect(_refresh_states)
	add_child(state_timer)
	state_timer.start()


func configure(run_loadout: RunLoadout, player_army: Army, card_commands: CardCommands = null) -> void:
	commands = card_commands
	loadout = run_loadout
	army = player_army
	if not army.spawn_state_changed.is_connected(_refresh_states):
		army.spawn_state_changed.connect(_refresh_states)
	_refresh_cards()


func _add_slot(index: int) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 55)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.105, 0.12, 0.86)
	style.border_color = Color(0.42, 0.64, 0.55, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	panel.add_child(column)
	var identity := HBoxContainer.new()
	identity.add_theme_constant_override("separation", 4)
	column.add_child(identity)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(23, 23)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	identity.add_child(icon)
	var placeholder := Label.new()
	placeholder.custom_minimum_size = Vector2(23, 23)
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	placeholder.add_theme_font_size_override("font_size", 15)
	identity.add_child(placeholder)
	var name := Label.new()
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.clip_text = true
	name.add_theme_font_size_override("font_size", 11)
	name.add_theme_color_override("font_color", CREAM)
	identity.add_child(name)
	var stars := Label.new()
	stars.add_theme_font_size_override("font_size", 11)
	stars.add_theme_color_override("font_color", Color("ffda80"))
	column.add_child(stars)
	var command := Button.new()
	command.add_theme_font_size_override("font_size", 9)
	command.custom_minimum_size.y = 20
	command.pressed.connect(func() -> void: command_requested.emit(loadout.get_card(index)))
	column.add_child(command)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 3)
	column.add_child(bottom)
	var state := Label.new()
	state.custom_minimum_size.x = 59
	state.add_theme_font_size_override("font_size", 8)
	state.add_theme_color_override("font_color", MUTED)
	bottom.add_child(state)
	var progress := ProgressBar.new()
	progress.custom_minimum_size = Vector2(28, 3)
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress.show_percentage = false
	progress.max_value = 1.0
	bottom.add_child(progress)
	slots.append({"command": command, "panel": panel, "style": style, "icon": icon, "placeholder": placeholder, "name": name, "stars": stars, "state": state, "progress": progress})


func _refresh_cards() -> void:
	var cards := loadout.get_cards()
	for index: int in slots.size():
		var slot: Dictionary = slots[index]
		var card: CardData = cards[index] if index < cards.size() else null
		var name: Label = slot.name
		var stars: Label = slot.stars
		var icon: TextureRect = slot.icon
		var placeholder: Label = slot.placeholder
		name.text = card.display_name.to_upper() if card != null else "EMPTY"
		var level := loadout.get_star_level(card)
		stars.text = "★".repeat(level) + "☆".repeat(5 - level)
		icon.texture = card.icon if card != null else null
		icon.visible = icon.texture != null
		placeholder.visible = not icon.visible
		placeholder.text = card.display_name.substr(0, 1).to_upper() if card != null else "?"
		placeholder.add_theme_color_override("font_color", card.unit_data.color if card != null and card.unit_data != null else MUTED)
		var style: StyleBoxFlat = slot.style
		style.border_color = _rarity_color(card) if card != null else MUTED
	_refresh_states()


func _refresh_states() -> void:
	if loadout == null or army == null:
		return
	var cards := loadout.get_cards()
	for index: int in slots.size():
		var slot: Dictionary = slots[index]
		var card: CardData = cards[index] if index < cards.size() else null
		var spawn: Dictionary = commands.get_state(card) if commands != null else army.get_spawn_state(card)
		var command: Button = slot.command
		command.text = spawn.get("name", "")
		command.disabled = commands == null or spawn.status != "READY" or not army.running
		var state: Label = slot.state
		var progress: ProgressBar = slot.progress
		state.text = spawn.status
		progress.value = spawn.progress
		progress.visible = spawn.status != "READY" and spawn.status != "UNAVAILABLE"
		var panel: PanelContainer = slot.panel
		panel.modulate.a = 0.58 if spawn.status == "UNAVAILABLE" else 1.0


func _rarity_color(card: CardData) -> Color:
	match card.rarity:
		CardData.Rarity.UNCOMMON:
			return Color("83d8b0")
		CardData.Rarity.RARE:
			return Color("ffd17c")
	return Color("b8c7bd")
