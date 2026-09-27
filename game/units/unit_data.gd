class_name UnitData
extends Resource

enum AttackMode { REPEAT, SELF_DESTRUCT }
enum AttackProfile { MELEE, MID, RANGED }

@export var display_name: String = "UNIT"
@export var move_speed: float = 55.0
@export var max_hp: int = 30
@export var spawn_interval: float = 5.0
@export_range(1, 100) var max_active_instances: int = 1
@export var attack_range: float = 54.0
@export var attack_profile: AttackProfile = AttackProfile.MELEE
@export var attack_interval: float = 1.0
@export var damage: int = 10
@export var color: Color = Color(0.4, 0.8, 0.4)
@export var body_polygon: PackedVector2Array = PackedVector2Array([
	Vector2(-12, -12), Vector2(12, -12), Vector2(12, 12), Vector2(-12, 12)
])
@export var projectile_scene: PackedScene
@export var attack_mode: AttackMode = AttackMode.REPEAT
@export var behavior: UnitBehavior
