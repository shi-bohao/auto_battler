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

	attack_feedback_tween = unit.create_tween()
	attack_feedback_tween.tween_property(unit, "scale", Vector2(1.12, 0.92), _get_scaled_duration(unit, 0.06))
	attack_feedback_tween.tween_property(unit, "scale", Vector2.ONE, _get_scaled_duration(unit, 0.08))


func play_damage_feedback(unit: Node2D, body: ColorRect, amount: int, is_critical: bool = false) -> void:
	if unit == null or not is_instance_valid(unit):
		return

	_show_damage_number(unit, amount, is_critical)

	if body == null:
		return

	if damage_flash_tween != null:
		damage_flash_tween.kill()

	body.modulate = Color(1.0, 0.35, 0.35)
	damage_flash_tween = unit.create_tween()
	damage_flash_tween.tween_property(body, "modulate", Color.WHITE, _get_scaled_duration(unit, 0.12))


func play_heal_feedback(unit: Node2D, amount: int) -> void:
	if unit == null or not is_instance_valid(unit):
		return

	_show_heal_number(unit, amount)


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


func _show_damage_number(unit: Node2D, amount: int, is_critical: bool) -> void:
	var damage_label: Label = Label.new()
	if is_critical:
		damage_label.text = "暴击 " + str(amount)
	else:
		damage_label.text = "-" + str(amount)
	damage_label.position = Vector2(8.0, -34.0)
	damage_label.modulate = Color(1.0, 0.35, 0.15) if is_critical else Color(1.0, 0.85, 0.15)
	damage_label.add_theme_font_size_override("font_size", 18 if is_critical else 16)
	unit.add_child(damage_label)

	var label_tween: Tween = unit.create_tween()
	label_tween.set_parallel(true)
	label_tween.tween_property(damage_label, "position", damage_label.position + Vector2(0.0, -24.0), _get_scaled_duration(unit, 0.45))
	label_tween.tween_property(damage_label, "modulate:a", 0.0, _get_scaled_duration(unit, 0.45))
	label_tween.set_parallel(false)
	label_tween.tween_callback(Callable(damage_label, "queue_free"))


func _show_heal_number(unit: Node2D, amount: int) -> void:
	var heal_label: Label = Label.new()
	heal_label.text = "+" + str(amount)
	heal_label.position = Vector2(8.0, -44.0)
	heal_label.modulate = Color(0.35, 1.0, 0.45)
	heal_label.add_theme_font_size_override("font_size", 16)
	unit.add_child(heal_label)

	var label_tween: Tween = unit.create_tween()
	label_tween.set_parallel(true)
	label_tween.tween_property(heal_label, "position", heal_label.position + Vector2(0.0, -24.0), _get_scaled_duration(unit, 0.45))
	label_tween.tween_property(heal_label, "modulate:a", 0.0, _get_scaled_duration(unit, 0.45))
	label_tween.set_parallel(false)
	label_tween.tween_callback(Callable(heal_label, "queue_free"))


func _get_scaled_duration(unit: Node2D, duration: float) -> float:
	var battle_unit: Unit = unit as Unit
	if battle_unit == null:
		return duration

	return maxf(duration / maxf(battle_unit.battle_time_scale, 0.01), 0.01)
