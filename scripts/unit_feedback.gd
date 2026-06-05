class_name UnitFeedback
extends RefCounted

var attack_feedback_tween: Tween = null
var damage_flash_tween: Tween = null
var death_tween: Tween = null


func play_attack_feedback(unit: Node2D) -> void:
	if unit == null or not is_instance_valid(unit):
		return

	if attack_feedback_tween != null:
		attack_feedback_tween.kill()

	var feedback_target: Node2D = _get_feedback_target(unit)
	feedback_target.scale = Vector2.ONE
	attack_feedback_tween = unit.create_tween()
	attack_feedback_tween.tween_property(feedback_target, "scale", Vector2(1.12, 0.92), _get_scaled_duration(unit, 0.06))
	attack_feedback_tween.tween_property(feedback_target, "scale", Vector2.ONE, _get_scaled_duration(unit, 0.08))


func play_damage_feedback(unit: Node2D, body: ColorRect, amount: int, is_critical: bool = false, floating_style: String = "damage") -> void:
	if unit == null or not is_instance_valid(unit):
		return

	var style: String = "critical" if is_critical else floating_style
	var text: String = _get_damage_text(amount, is_critical, floating_style)
	play_floating_number(unit, text, style)

	var flash_target: CanvasItem = _get_flash_target(unit, body)
	if flash_target == null:
		return

	if damage_flash_tween != null:
		damage_flash_tween.kill()

	flash_target.modulate = Color(1.0, 0.35, 0.35)
	damage_flash_tween = unit.create_tween()
	damage_flash_tween.tween_property(flash_target, "modulate", Color.WHITE, _get_scaled_duration(unit, 0.12))


func play_heal_feedback(unit: Node2D, amount: int) -> void:
	if unit == null or not is_instance_valid(unit):
		return

	play_floating_number(unit, "+" + str(amount), "heal")


func play_floating_number(unit: Node2D, text: String, style: String = "damage") -> void:
	if unit == null or not is_instance_valid(unit):
		return

	var config: Dictionary = _get_floating_config(style)
	var label: Label = Label.new()
	label.text = text
	label.z_index = 20
	label.add_theme_font_size_override("font_size", config.font_size)
	label.add_theme_color_override("font_color", config.color)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	label.add_theme_constant_override("outline_size", config.outline_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var random_offset: float = randf_range(-10.0, 10.0)
	label.position = Vector2(random_offset, -42.0)

	unit.add_child(label)

	var duration: float = _get_scaled_duration(unit, config.duration)
	var label_tween: Tween = unit.create_tween()
	label_tween.set_parallel(true)
	label_tween.tween_property(label, "position", label.position + Vector2(0.0, -36.0), duration)
	label_tween.tween_property(label, "modulate:a", 0.0, duration)
	label_tween.set_parallel(false)
	label_tween.tween_callback(Callable(label, "queue_free"))


func play_death_feedback(unit: Node2D) -> void:
	if unit == null or not is_instance_valid(unit):
		return

	if attack_feedback_tween != null:
		attack_feedback_tween.kill()

	if damage_flash_tween != null:
		damage_flash_tween.kill()

	if death_tween != null:
		death_tween.kill()

	death_tween = unit.create_tween()
	death_tween.set_parallel(true)
	death_tween.tween_property(unit, "modulate:a", 0.0, _get_scaled_duration(unit, 0.35))
	death_tween.tween_property(unit, "scale", Vector2(0.8, 0.8), _get_scaled_duration(unit, 0.35))
	death_tween.set_parallel(false)
	death_tween.tween_callback(Callable(unit, "queue_free"))


func play_skill_feedback(unit: Node2D, skill_name: String) -> void:
	if unit == null or not is_instance_valid(unit):
		return

	var skill_label: Label = Label.new()
	skill_label.text = skill_name
	skill_label.position = Vector2(-28.0, -58.0)
	skill_label.modulate = Color(0.45, 0.9, 1.0)
	skill_label.add_theme_font_size_override("font_size", 13)
	unit.add_child(skill_label)

	var label_tween: Tween = unit.create_tween()
	label_tween.set_parallel(true)
	label_tween.tween_property(skill_label, "position", skill_label.position + Vector2(0.0, -22.0), _get_scaled_duration(unit, 0.45))
	label_tween.tween_property(skill_label, "modulate:a", 0.0, _get_scaled_duration(unit, 0.45))
	label_tween.set_parallel(false)
	label_tween.tween_callback(Callable(skill_label, "queue_free"))


func play_control_feedback(unit: Node2D, control_name: String, color: Color) -> void:
	if unit == null or not is_instance_valid(unit):
		return

	var control_label: Label = Label.new()
	control_label.text = control_name
	control_label.position = Vector2(-16.0, -72.0)
	control_label.modulate = color
	control_label.add_theme_font_size_override("font_size", 14)
	control_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	control_label.add_theme_constant_override("outline_size", 3)
	unit.add_child(control_label)

	var label_tween: Tween = unit.create_tween()
	label_tween.set_parallel(true)
	label_tween.tween_property(control_label, "position", control_label.position + Vector2(0.0, -18.0), _get_scaled_duration(unit, 0.35))
	label_tween.tween_property(control_label, "modulate:a", 0.0, _get_scaled_duration(unit, 0.35))
	label_tween.set_parallel(false)
	label_tween.tween_callback(Callable(control_label, "queue_free"))


func _show_damage_number(unit: Node2D, amount: int, is_critical: bool) -> void:
	var style: String = "critical" if is_critical else "damage"
	var text: String = _get_damage_text(amount, is_critical, "damage")
	play_floating_number(unit, text, style)


func _show_heal_number(unit: Node2D, amount: int) -> void:
	play_floating_number(unit, "+" + str(amount), "heal")


func _get_floating_config(style: String) -> Dictionary:
	match style:
		"critical":
			return {"color": Color(1.0, 0.15, 0.05), "font_size": 24, "outline_size": 5, "duration": 0.65}
		"burning":
			return {"color": Color(1.0, 0.35, 0.08), "font_size": 19, "outline_size": 4, "duration": 0.6}
		"venom":
			return {"color": Color(0.45, 1.0, 0.15), "font_size": 19, "outline_size": 4, "duration": 0.6}
		"heal":
			return {"color": Color(0.35, 1.0, 0.45), "font_size": 20, "outline_size": 4, "duration": 0.6}
		_:
			return {"color": Color(1.0, 0.85, 0.15), "font_size": 20, "outline_size": 4, "duration": 0.6}


func _get_damage_text(amount: int, is_critical: bool, floating_style: String) -> String:
	if is_critical:
		return "暴击 " + str(amount)
	match floating_style:
		"burning":
			return "燃 -" + str(amount)
		"venom":
			return "毒 -" + str(amount)
		_:
			return "-" + str(amount)


func _get_scaled_duration(unit: Node2D, duration: float) -> float:
	var battle_unit: Unit = unit as Unit
	if battle_unit == null:
		return duration

	return maxf(duration / maxf(battle_unit.battle_time_scale, 0.01), 0.01)


func _get_feedback_target(unit: Node2D) -> Node2D:
	if unit != null and unit.has_method("get_feedback_target"):
		var target: Variant = unit.get_feedback_target()
		if target is Node2D and is_instance_valid(target):
			return target

	return unit


func _get_flash_target(unit: Node2D, fallback_body: ColorRect) -> CanvasItem:
	if unit != null and unit.has_method("get_flash_target"):
		var target: Variant = unit.get_flash_target()
		if target is CanvasItem and is_instance_valid(target):
			return target

	return fallback_body
