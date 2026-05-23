class_name HeroUpgradeData
extends Resource


@export var upgrade_id: String = ""
@export var upgrade_name: String = ""
@export_multiline var description: String = ""
@export var hero_id: String = ""
@export var effect_type: String = ""
@export var effect_key: String = ""
@export var value: float = 0.0
@export var required_level: int = 2


func to_reward_option() -> Dictionary:
	return {
		"type": "HERO_UPGRADE",
		"upgrade_id": upgrade_id,
		"name": upgrade_name,
		"description": description,
		"hero_id": hero_id,
		"effect_type": effect_type,
		"effect_key": effect_key,
		"value": value,
		"required_level": required_level,
		"rarity": "MYTHIC",
		"upgrade_data": self,
	}
