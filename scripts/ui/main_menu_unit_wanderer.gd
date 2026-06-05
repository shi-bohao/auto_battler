class_name MainMenuUnitWanderer
extends Node2D

var wander_velocity: Vector2 = Vector2.ZERO
var visual_motion_time: float = 0.0
var move_speed: float = 40.0
var bounds_rect: Rect2 = Rect2()
var sprite: Sprite2D = null

var behavior_timer: float = 0.0
var next_behavior_time: float = 2.0
var is_idle: bool = false
var idle_timer: float = 0.0
var idle_duration: float = 1.0


func setup(texture: Texture2D, start_position: Vector2, move_bounds: Rect2) -> void:
	position = start_position
	bounds_rect = move_bounds
	sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var texture_size: Vector2 = texture.get_size()
	var fit_scale: float = 96.0 / maxf(texture_size.x, texture_size.y)
	sprite.scale = Vector2(fit_scale, fit_scale)
	add_child(sprite)
	_pick_random_direction()


func update(delta: float) -> void:
	if not is_idle:
		position += wander_velocity * delta
		_clamp_to_bounds()
	else:
		_idle_tick(delta)
	_update_bob_animation(delta)
	_behavior_tick(delta)


func _pick_random_direction() -> void:
	var angle: float = randf() * TAU
	wander_velocity = Vector2(cos(angle), sin(angle)) * move_speed


func _start_idle() -> void:
	is_idle = true
	wander_velocity = Vector2.ZERO
	idle_duration = randf_range(1.0, 3.0)
	idle_timer = 0.0


func _end_idle() -> void:
	is_idle = false
	_pick_random_direction()


func _idle_tick(delta: float) -> void:
	idle_timer += delta
	if idle_timer >= idle_duration:
		_end_idle()


func _clamp_to_bounds() -> void:
	var margin: float = 24.0
	var clamped: bool = false
	if position.x < bounds_rect.position.x + margin:
		position.x = bounds_rect.position.x + margin
		wander_velocity.x = abs(wander_velocity.x)
		clamped = true
	elif position.x > bounds_rect.end.x - margin:
		position.x = bounds_rect.end.x - margin
		wander_velocity.x = -abs(wander_velocity.x)
		clamped = true
	if position.y < bounds_rect.position.y + margin:
		position.y = bounds_rect.position.y + margin
		wander_velocity.y = abs(wander_velocity.y)
		clamped = true
	elif position.y > bounds_rect.end.y - margin:
		position.y = bounds_rect.end.y - margin
		wander_velocity.y = -abs(wander_velocity.y)
		clamped = true
	if clamped:
		behavior_timer = next_behavior_time


func _update_bob_animation(delta: float) -> void:
	visual_motion_time += delta
	if sprite != null:
		sprite.position = Vector2(0.0, sin(visual_motion_time * 14.0) * 1.5)


func _behavior_tick(delta: float) -> void:
	behavior_timer += delta
	if behavior_timer >= next_behavior_time:
		behavior_timer = 0.0
		next_behavior_time = randf_range(1.5, 4.0)
		if randf() < 0.3:
			_start_idle()
		else:
			if is_idle:
				_end_idle()
			else:
				_pick_random_direction()
