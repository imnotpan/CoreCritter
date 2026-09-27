class_name ActiveCardStrip
extends HBoxContainer

const TEXT := Color("e4e9e9")
const MUTED := Color("9da9ad")

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


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _add_slot(index: int) -> void:
	# The entire compact card is the command target; its contents pass clicks through.
	var command := Button.new()
	command.custom_minimum_size = Vector2(0, 42)
	command.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("1a2025") if state in ["normal", "disabled"] else Color("2b363e")
		style.set_corner_radius_all(2)
		if state == "focus":
			style.bg_color = Color.TRANSPARENT
			style.border_color = MUTED
			style.set_border_width_all(1)
		command.add_theme_stylebox_override(state, style)
	command.pressed.connect(func() -> void: command_requested.emit(loadout.get_card(index)))
	add_child(command)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 5)
	for side: String in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 4)
	command.add_child(margin)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 1)
	margin.add_child(column)
	var identity := HBoxContainer.new()
	identity.mouse_filter = Control.MOUSE_FILTER_IGNORE
	identity.add_theme_constant_override("separation", 3)
	column.add_child(identity)
	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(16, 16)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	identity.add_child(icon)
	var placeholder := _label(12, MUTED)
	placeholder.custom_minimum_size = Vector2(12, 16)
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	identity.add_child(placeholder)
	var name := _label(10, TEXT)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	identity.add_child(name)
	var stars := _label(9, Color("c8bd94"))
	identity.add_child(stars)
	var detail := HBoxContainer.new()
	detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail.add_theme_constant_override("separation", 3)
	column.add_child(detail)
	var command_name := _label(9, MUTED)
	command_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	command_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	detail.add_child(command_name)
	var state := _label(9, MUTED)
	detail.add_child(state)
	slots.append({"command": command, "icon": icon, "placeholder": placeholder,
		"name": name, "stars": stars, "command_name": command_name, "state": state})


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
		stars.text = "★" if level == 1 else "★%d" % level
		stars.tooltip_text = "%d stars" % level
		icon.texture = card.icon if card != null else null
		icon.visible = icon.texture != null
		placeholder.visible = not icon.visible
		placeholder.text = card.display_name.substr(0, 1).to_upper() if card != null else "?"
		placeholder.add_theme_color_override("font_color", card.unit_data.color if card != null and card.unit_data != null else MUTED)
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
		var command_name: Label = slot.command_name
		command_name.text = spawn.get("name", "")
		command.disabled = commands == null or spawn.status != "READY" or not army.running
		command.tooltip_text = "%s · %s · %s" % [card.display_name if card != null else "EMPTY", command_name.text, spawn.status]
		var state: Label = slot.state
		state.text = spawn.status
		state.add_theme_color_override("font_color", Color("b8d4c4") if spawn.status == "READY" else MUTED)
		command.modulate.a = 0.58 if spawn.status == "UNAVAILABLE" else 1.0
