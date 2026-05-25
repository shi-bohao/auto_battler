class_name StatModifier
extends RefCounted


const STAGE_BASE_OVERRIDE: String = "BASE_OVERRIDE"
const STAGE_PERMANENT_FLAT: String = "PERMANENT_FLAT"
const STAGE_PERMANENT_PERCENT: String = "PERMANENT_PERCENT"
const STAGE_RUNTIME_FLAT: String = "RUNTIME_FLAT"
const STAGE_RUNTIME_PERCENT: String = "RUNTIME_PERCENT"
const STAGE_FINAL_FLAT: String = "FINAL_FLAT"
const STAGE_FINAL_PERCENT: String = "FINAL_PERCENT"
const STAGE_FINAL_MULTIPLY: String = "FINAL_MULTIPLY"

var modifier_id: String = ""
var source_key: String = ""
var stat_name: String = ""
var stage: String = STAGE_RUNTIME_FLAT
var value: float = 0.0
var priority: int = 0
var dynamic_key: String = ""
var params: Dictionary = {}


static func from_data(data: Dictionary) -> StatModifier:
	var modifier: StatModifier = StatModifier.new()
	modifier.modifier_id = str(data.get("modifier_id", ""))
	modifier.source_key = str(data.get("source_key", ""))
	modifier.stat_name = str(data.get("stat_name", ""))
	modifier.stage = str(data.get("stage", STAGE_RUNTIME_FLAT))
	modifier.value = float(data.get("value", 0.0))
	modifier.priority = int(data.get("priority", 0))
	modifier.dynamic_key = str(data.get("dynamic_key", ""))
	var configured_params: Variant = data.get("params", {})
	if configured_params is Dictionary:
		modifier.params = (configured_params as Dictionary).duplicate(true)
	return modifier


func get_key() -> String:
	if modifier_id.strip_edges() != "":
		return modifier_id

	return source_key + "|" + stat_name + "|" + stage + "|" + dynamic_key
