extends Node

const WINDOW_SIZE := Vector2i(400, 320)
const SCREEN_MARGIN := Vector2i(16, 16)


func _ready() -> void:
	var window: Window = get_window()
	window.size = WINDOW_SIZE
	window.borderless = true
	window.always_on_top = true
	window.transparent = true
	window.transparent_bg = true
	window.unresizable = true

	var usable_rect: Rect2i = DisplayServer.screen_get_usable_rect(window.current_screen)
	window.position = usable_rect.end - window.size - SCREEN_MARGIN
