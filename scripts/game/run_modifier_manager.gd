class_name RunModifierManager
extends RefCounted


var luck: float = 0.0


func reset() -> void:
	luck = 0.0


func add_luck(amount: float) -> void:
	luck += amount


func set_luck(value: float) -> void:
	luck = value


func get_luck() -> float:
	return luck


func get_state_snapshot() -> Dictionary:
	return {"luck": luck}


func restore_state_snapshot(snapshot: Dictionary) -> void:
	luck = float(snapshot.get("luck", 0.0))
