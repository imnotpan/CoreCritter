class_name StarProgressionConfig
extends Resource

@export var copies_required: PackedInt32Array = PackedInt32Array([2, 3, 5, 8])
@export var coins_required: PackedInt32Array = PackedInt32Array([50, 100, 200, 400])


func cost_for(star_level: int) -> Vector2i:
	if star_level < 1 or star_level > 4:
		return Vector2i.ZERO
	return Vector2i(copies_required[star_level - 1], coins_required[star_level - 1])
