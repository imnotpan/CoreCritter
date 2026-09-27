class_name StarStats
extends RefCounted


static func damage(base_damage: int, stars: int) -> int:
	var result := base_damage
	if stars >= 2:
		result += ceili(base_damage * 0.15)
	if stars >= 4:
		result += ceili(base_damage * 0.20)
	return maxi(1, result)
