class_name HeroData
extends Resource


@export var hero_id: String = ""
@export var hero_name: String = ""
@export var hero_name_cn: String = ""
@export var hero_unit_data: Resource = null
@export_multiline var description: String = ""
@export var role_tags: PackedStringArray = []
@export var base_passive_ids: PackedStringArray = []
@export var base_active_skill_id: String = ""
@export var upgrade_pool: Array[Resource] = []
@export var recommended_cells: Array[Vector2i] = []


func get_display_name() -> String:
	if hero_name_cn.strip_edges() != "":
		return hero_name_cn

	return hero_name


func get_tagline() -> String:
	var parts: Array[String] = []
	for tag_value: String in role_tags:
		var tag: String = tag_value.strip_edges()
		if tag != "":
			parts.append(tag)

	var tagline: String = ""
	for index: int in range(parts.size()):
		if index > 0:
			tagline += " / "
		tagline += parts[index]

	return tagline
