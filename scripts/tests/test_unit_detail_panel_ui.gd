extends SceneTree

const UNIT_DETAIL_PANEL_SCENE: PackedScene = preload("res://scenes/ui/unit_detail_panel.tscn")
const UNIT_SCENE: PackedScene = preload("res://scenes/unit.tscn")
const WARRIOR_DATA: Resource = preload("res://data/units/warrior.tres")
const UNIT_TEXT_FORMATTER_SCRIPT: Script = preload("res://scripts/unit_text_formatter.gd")
const RARITY_FORMATTER_SCRIPT: Script = preload("res://scripts/formatters/rarity_formatter.gd")
const UNIT_DETAIL_PANEL_CONTROLLER_SCRIPT: Script = preload("res://scripts/ui/unit_detail_panel_controller.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var panel: Panel = UNIT_DETAIL_PANEL_SCENE.instantiate() as Panel
	get_root().add_child(panel)

	var unit: Unit = UNIT_SCENE.instantiate() as Unit
	unit.unit_data = WARRIOR_DATA.duplicate(true)
	unit.display_name = "测试战士"
	unit.team_id = 1
	unit.skill_power = 0.25
	unit.healing_power = 0.10
	unit.shield_power = 0.15
	unit.defense_penetration = 8
	unit.life_steal = 0.12
	unit.damage_reduction = 0.09
	unit.initial_mana = 20.0
	unit.mana_on_attack = 5.0
	unit.mana_on_hit_taken = 4.0
	unit.status_resistance = 0.18
	unit.dodge_chance = 0.07
	get_root().add_child(unit)
	await process_frame

	var controller: Variant = UNIT_DETAIL_PANEL_CONTROLLER_SCRIPT.new()
	var title_label: Label = panel.get_node("UnitDetailTitle Label") as Label
	var detail_text: RichTextLabel = panel.get_node("UnitDetailText RichTextLabel") as RichTextLabel
	controller.setup(panel, title_label, detail_text, UNIT_TEXT_FORMATTER_SCRIPT.new(), RARITY_FORMATTER_SCRIPT.new(), null)
	controller.show(unit)
	await process_frame

	_expect_bool(panel.visible, true, "Unit detail panel should become visible.")
	_expect_bool(panel.size.x >= 520.0, true, "Unit detail panel should be wide enough for larger text.")
	_expect_string(str((panel.get_node("UnitName Label") as Label).text), "测试战士", "Unit detail panel should show unit name.")
	var base_stats_grid: GridContainer = panel.get_node("BaseStatsGrid GridContainer") as GridContainer
	var skill_section_title: Label = panel.get_node("SkillSectionTitle Label") as Label
	_expect_bool(base_stats_grid.get_child_count() > 0, true, "Unit detail panel should render base stat labels.")
	_expect_int(base_stats_grid.columns, 3, "Base stat grid should use three stat columns.")
	_expect_bool(_control_bottom(base_stats_grid) <= skill_section_title.position.y, true, "Base stat grid should not overlap the skill section.")
	_expect_bool(_grid_has_text(base_stats_grid, "技能强度"), true, "Unit detail panel should show skill power.")
	_expect_bool(_grid_has_text(base_stats_grid, "状态抗性"), true, "Unit detail panel should show status resistance.")
	_expect_bool(_grid_has_text(base_stats_grid, "闪避"), true, "Unit detail panel should show dodge chance.")

	var passive_button: Button = panel.get_node("PassiveSkillButton Button") as Button
	var active_button: Button = panel.get_node("ActiveSkillButton Button") as Button
	_expect_bool(passive_button.text.strip_edges() != "" and passive_button.text != unit.passive_id, true, "Passive skill button should show a skill name.")
	_expect_bool(active_button.text.strip_edges() != "" and active_button.text != unit.active_skill_id, true, "Active skill button should show a skill name.")

	passive_button.emit_signal("pressed")
	_expect_bool(detail_text.text.find(passive_button.text) >= 0, true, "Clicking passive skill should show passive detail.")
	active_button.emit_signal("pressed")
	_expect_bool(detail_text.text.find(active_button.text) >= 0, true, "Clicking active skill should show active detail.")

	unit.set_meta("is_hero", true)
	unit.set_meta("hero_upgrade_ids", ["iron_guard_synergy"])
	unit.set_meta("hero_base_stat_upgrade_counts", {"hero_base_stat_defense": 2})
	controller.show(unit)
	await process_frame
	var hero_upgrade_title: Label = panel.get_node("HeroUpgradeTitle Label") as Label
	var hero_upgrade_text: RichTextLabel = panel.get_node("HeroUpgradeText RichTextLabel") as RichTextLabel
	_expect_string(str(hero_upgrade_title.text), "英雄强化", "Hero upgrade title should use readable text.")
	_expect_bool(hero_upgrade_text.visible, true, "Hero detail panel should show the hero upgrade section.")
	_expect_bool(hero_upgrade_text.text.strip_edges() != "" and hero_upgrade_text.text.strip_edges() != "-", true, "Hero upgrade section should list selected hero upgrades.")
	_expect_bool(hero_upgrade_text.text.find("x2") >= 0, true, "Hero upgrade section should include repeatable base stat counts.")

	panel.queue_free()
	unit.queue_free()
	_finish()


func _finish() -> void:
	if failures.is_empty():
		print("Unit detail panel UI tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _expect_bool(actual: bool, expected: bool, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")


func _expect_string(actual: String, expected: String, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + expected + ", got " + actual + ".")


func _expect_int(actual: int, expected: int, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")


func _control_bottom(control: Control) -> float:
	return control.position.y + control.size.y


func _grid_has_text(grid: GridContainer, text_value: String) -> bool:
	for child in grid.get_children():
		var label: Label = child as Label
		if label != null and label.text.find(text_value) >= 0:
			return true

	return false
