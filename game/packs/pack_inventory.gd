class_name PackInventory
extends RefCounted

signal count_changed(count: int)

var pack_count := 0


func add_pack(amount: int = 1) -> void:
	if amount <= 0:
		return
	pack_count += amount
	count_changed.emit(pack_count)


func consume_pack() -> bool:
	if pack_count <= 0:
		return false
	pack_count -= 1
	count_changed.emit(pack_count)
	return true


func get_pack_count() -> int:
	return pack_count
