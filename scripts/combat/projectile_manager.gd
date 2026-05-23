extends RefCounted

## Manages active basic attack projectiles.
## Owned by BattleManager — provides spawn, tracking, and battle-end cleanup.

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/combat/projectile.tscn")

var battle_root: Node = null
var active_projectiles: Array = []


func setup(configured_battle_root: Node) -> void:
	battle_root = configured_battle_root


func spawn_basic_attack_projectile(attacker: Variant, target: Variant, payload: Variant, projectile_speed: float) -> void:
	if battle_root == null or not is_instance_valid(battle_root):
		return

	var projectile: Variant = PROJECTILE_SCENE.instantiate()
	projectile.global_position = attacker.global_position
	projectile.setup(payload, target, projectile_speed, self)
	battle_root.add_child(projectile)
	active_projectiles.append(projectile)


func clear_all() -> void:
	for projectile: Variant in active_projectiles:
		if is_instance_valid(projectile) and not projectile.is_destroyed:
			projectile.is_destroyed = true
			if is_instance_valid(projectile.get_parent()):
				projectile.queue_free()

	active_projectiles.clear()


func _on_projectile_destroyed(projectile: Variant) -> void:
	active_projectiles.erase(projectile)
