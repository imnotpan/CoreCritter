extends RefCounted

const WINDOW_SIZE := Vector2i(400, 320)
const EDGE_MARGIN := Vector2i(16, 16)


static func configure(window: Window) -> void:
	window.size = WINDOW_SIZE
	window.mode = Window.MODE_WINDOWED
	window.borderless = true
	window.always_on_top = true
	window.transparent = true
	window.transparent_bg = true
	window.unresizable = true
	var usable_rect: Rect2i = DisplayServer.screen_get_usable_rect(window.current_screen)
	window.position = usable_rect.end - window.size - EDGE_MARGIN
