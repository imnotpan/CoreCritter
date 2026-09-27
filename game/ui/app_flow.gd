class_name AppFlow
extends Control

signal play_requested
signal collection_requested
signal settings_requested
signal continue_requested
signal exit_requested

enum State { MAIN_MENU, PRE_RUN, ACTIVE_RUN, RUN_RESULTS }

var state := State.MAIN_MENU
var panel: PanelContainer
var content: VBoxContainer
var pause_panel: PanelContainer
var confirm_panel: PanelContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel = _make_panel()
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 9)
	panel.add_child(content)
	pause_panel = _make_panel()
	confirm_panel = _make_panel()
	show_menu()


func _make_panel() -> PanelContainer:
	var result := PanelContainer.new()
	result.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(result)
	result.visible = false
	return result


func _clear_content() -> void:
	for child: Node in content.get_children():
		content.remove_child(child)
		child.queue_free()


func _label(value: String) -> void:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	content.add_child(label)


func _button(value: String, action: Callable) -> void:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(200, 42)
	button.pressed.connect(action)
	content.add_child(button)


func show_menu() -> void:
	state = State.MAIN_MENU
	_clear_content()
	_label("CORECRITTERS")
	_button("PLAY", func() -> void: play_requested.emit())
	_button("COLLECTION", func() -> void: collection_requested.emit())
	_button("SETTINGS", func() -> void: settings_requested.emit())
	if OS.is_debug_build():
		_button("QUIT", func() -> void: get_tree().quit())
	panel.visible = true
	pause_panel.visible = false
	confirm_panel.visible = false


func show_pre_run() -> void:
	state = State.PRE_RUN
	panel.visible = false
	pause_panel.visible = false
	confirm_panel.visible = false


func show_active_run() -> void:
	state = State.ACTIVE_RUN
	panel.visible = false
	pause_panel.visible = false
	confirm_panel.visible = false


func show_results(run: RunSession) -> void:
	state = State.RUN_RESULTS
	_clear_content()
	_label("RUN COMPLETE" if run.completed else "RUN ENDED")
	_label(run.world.display_name.to_upper())
	_label("Cores destroyed: %d" % run.cores_destroyed)
	_label("Coins earned: %d" % run.coins_earned)
	_label("Packs earned: %d" % run.packs_earned)
	var names: Array[String] = []
	for card: CardData in run.new_cards:
		names.append(card.display_name)
	_label("New creatures: %s" % (", ".join(names) if not names.is_empty() else "None"))
	_button("CONTINUE", func() -> void: continue_requested.emit())
	panel.visible = true
	pause_panel.visible = false
	confirm_panel.visible = false


func show_pause() -> void:
	if state != State.ACTIVE_RUN:
		return
	_fill_dialog(pause_panel, "RUN OPTIONS", "RETURN", func() -> void: pause_panel.visible = false, "EXIT RUN", _confirm_exit)
	pause_panel.visible = true


func _confirm_exit() -> void:
	confirm_panel.visible = true
	_fill_dialog(confirm_panel, "Exit this run? Earned rewards stay.", "CANCEL", func() -> void: confirm_panel.visible = false, "EXIT RUN", func() -> void: exit_requested.emit())


func _fill_dialog(target: PanelContainer, message: String, first: String, first_action: Callable, second: String, second_action: Callable) -> void:
	for child: Node in target.get_children():
		target.remove_child(child)
		child.queue_free()
	var box := VBoxContainer.new()
	target.add_child(box)
	var label := Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(label)
	for pair: Array in [[first, first_action], [second, second_action]]:
		var button := Button.new()
		button.text = pair[0]
		button.pressed.connect(pair[1])
		box.add_child(button)


func show_settings() -> void:
	_clear_content()
	_label("SETTINGS")
	_label("No settings available yet")
	_button("BACK", show_menu)
	panel.visible = true
