class_name SummonData
extends Resource

@export var summon_id: String = ""
@export var unit_data: Resource
@export var count: int = 1
@export var duration: float = -1.0
@export var source_type: String = "unit"
@export var source_key: String = ""
@export var summon_cap: int = 3
@export var affects_battle_result: bool = true
@export var position_mode: String = "near_source"
@export var spawn_radius: float = 42.0
