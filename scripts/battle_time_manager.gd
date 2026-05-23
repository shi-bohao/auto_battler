class_name BattleTimeManager
extends RefCounted


const SPEED_OPTIONS: Array[float] = [1.0, 2.0, 3.0]

var speed_index: int = 0
var battle_speed: float = 1.0
var raw_delta: float = 0.0
var battle_delta: float = 0.0
var battle_elapsed: float = 0.0
var real_elapsed: float = 0.0


func reset_for_run() -> void:
	speed_index = 0
	_sync_speed()
	reset_battle_clock()


func reset_battle_clock() -> void:
	raw_delta = 0.0
	battle_delta = 0.0
	battle_elapsed = 0.0
	real_elapsed = 0.0


func update(delta: float, is_battle_running: bool) -> float:
	raw_delta = maxf(delta, 0.0)
	if not is_battle_running:
		battle_delta = 0.0
		return battle_delta

	real_elapsed += raw_delta
	battle_delta = raw_delta * battle_speed
	battle_elapsed += battle_delta
	return battle_delta


func cycle_speed() -> float:
	speed_index = (speed_index + 1) % SPEED_OPTIONS.size()
	_sync_speed()
	return battle_speed


func set_speed_index(index: int) -> void:
	speed_index = clampi(index, 0, SPEED_OPTIONS.size() - 1)
	_sync_speed()


func get_speed_value() -> float:
	return battle_speed


func get_speed_label() -> String:
	return "x" + str(int(round(battle_speed)))


func _sync_speed() -> void:
	battle_speed = float(SPEED_OPTIONS[clampi(speed_index, 0, SPEED_OPTIONS.size() - 1)])
