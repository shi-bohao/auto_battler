class_name RelicData
extends Resource

@export var relic_id: String = ""
@export var relic_name: String = "遗物"
@export var relic_name_cn: String = ""
@export var description: String = ""
@export var description_cn: String = ""
@export_enum("COMMON", "FINE", "RARE", "EPIC", "LEGENDARY", "MYTHIC") var rarity: String = "COMMON"
@export var icon_texture: Texture2D = null
@export var trigger_type: String = ""
@export var value: float = 0.0
