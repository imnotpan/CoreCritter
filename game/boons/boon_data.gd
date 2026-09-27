class_name BoonData
extends Resource

enum Effect { RICOCHET, CAPACITY, SPAWN_SPEED, HEALTH, ATTACK_SPEED }

@export var id: StringName
@export var display_name: String
@export var description: String
@export var effect: Effect
@export var value: float
@export var creature_id: StringName


func apply(army: Army) -> void:
	match effect:
		Effect.RICOCHET:
			army.ricochet_bonus += value
		Effect.CAPACITY:
			army.extra_capacity[creature_id] = int(army.extra_capacity.get(creature_id, 0)) + roundi(value)
		Effect.SPAWN_SPEED:
			army.spawn_multiplier *= 1.0 - value
		Effect.HEALTH:
			army.hp_multiplier *= 1.0 + value
		Effect.ATTACK_SPEED:
			army.attack_speed_bonus += value
	army.refresh_run_effects()
