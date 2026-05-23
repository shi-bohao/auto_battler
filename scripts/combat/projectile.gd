extends Node2D

## A basic attack projectile that homes toward its target and resolves damage on arrival.
## Owns no combat logic — delegates to CombatResolver.resolve_basic_attack_hit().

const HIT_DISTANCE_THRESHOLD: float = 12.0
const COMBAT_RESOLVER_SCRIPT: Script = preload("res://scripts/combat/combat_resolver.gd")

var payload: Variant = null
var target: Variant = null
var speed: float = 500.0
var lifetime: float = 0.0
var max_lifetime: float = 2.0
var is_destroyed: bool = false
var combat_resolver: Variant = COMBAT_RESOLVER_SCRIPT.new()
var projectile_manager: Variant = null
var is_enhanced: bool = false
var enhanced_color: Color = Color.WHITE

@onready var body: ColorRect = $"Body" as ColorRect


func setup(configured_payload: Variant, configured_target: Variant, configured_speed: float, configured_manager: Variant) -> void:
	payload = configured_payload
	target = configured_target
	speed = maxf(1.0, configured_speed)
	max_lifetime = maxf(0.5, float(configured_payload.max_lifetime))
	projectile_manager = configured_manager

	if configured_payload.is_enhanced:
		is_enhanced = true
		enhanced_color = configured_payload.enhanced_visual_color
		if enhanced_color == Color.WHITE:
			enhanced_color = Color(1.0, 0.55, 0.12, 1.0)


func _ready() -> void:
	if is_enhanced and body != null:
		body.color = enhanced_color
		body.offset_left = -6.0
		body.offset_top = -6.0
		body.offset_right = 6.0
		body.offset_bottom = 6.0


func _process(delta: float) -> void:
	if is_destroyed:
		return

	lifetime += delta
	if lifetime > max_lifetime:
		_destroy()
		return

	if not _is_valid_target(target):
		_destroy()
		return

	# Move toward target (homing)
	var direction: Vector2 = target.global_position - global_position
	var distance: float = direction.length()

	if distance <= HIT_DISTANCE_THRESHOLD:
		_on_hit()
		return

	direction = direction.normalized()
	position += direction * speed * delta


func _on_hit() -> void:
	if is_destroyed:
		return

	# Re-validate target before resolving
	if not _is_valid_target(target):
		_destroy()
		return

	if not target.is_alive:
		_destroy()
		return

	# Validate teams are still opposed
	if int(target.team_id) == int(payload.source_team_id):
		_destroy()
		return

	# Resolve hit through unified entry point
	var attacker: Variant = payload.source_unit_ref
	if attacker == null or not is_instance_valid(attacker):
		_destroy()
		return

	combat_resolver.resolve_basic_attack_hit(attacker, target, payload)
	_destroy()


func _is_valid_target(check_target: Variant) -> bool:
	return check_target != null and is_instance_valid(check_target) and is_instance_valid(check_target.get_parent())


func _destroy() -> void:
	if is_destroyed:
		return

	is_destroyed = true
	if projectile_manager != null and is_instance_valid(projectile_manager) and projectile_manager.has_method("_on_projectile_destroyed"):
		projectile_manager._on_projectile_destroyed(self)

	if is_inside_tree():
		queue_free()
