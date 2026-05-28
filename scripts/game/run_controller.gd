class_name RunController
extends RefCounted

const GameState: Script = preload("res://scripts/game/game_state.gd")

const GAME_MODE_CLASSIC: String = "CLASSIC"
const GAME_MODE_MIRROR_CHALLENGE: String = "MIRROR_CHALLENGE"

const BOSS_ROUNDS: Array[int] = [10, 20, 30]

var state: int = GameState.MAIN_MENU
var current_round: int = 1
var max_round: int = 30
var game_mode: String = GAME_MODE_CLASSIC
var pending_node_type: String = ""
var path_history: Array[String] = []


func enter_main_menu() -> void:
	state = GameState.MAIN_MENU
	current_round = 1
	game_mode = GAME_MODE_CLASSIC
	pending_node_type = ""
	path_history.clear()


func start_run(selected_game_mode: String = GAME_MODE_CLASSIC) -> void:
	current_round = 1
	state = GameState.PREPARE
	game_mode = selected_game_mode
	pending_node_type = ""
	path_history.clear()


func enter_hero_selection() -> void:
	state = GameState.HERO_SELECTION


func enter_prepare() -> void:
	state = GameState.PREPARE


func enter_battle() -> void:
	state = GameState.BATTLE


func enter_reward() -> void:
	state = GameState.REWARD


func enter_path_select() -> void:
	state = GameState.PATH_SELECT


func enter_merchant() -> void:
	state = GameState.MERCHANT


func enter_event() -> void:
	state = GameState.EVENT


func enter_training() -> void:
	state = GameState.TRAINING


func enter_treasure() -> void:
	state = GameState.TREASURE


func enter_next_prepare() -> void:
	state = GameState.NEXT_PREPARE


func enter_game_over() -> void:
	state = GameState.GAME_OVER


func advance_round() -> void:
	current_round += 1


func has_cleared_round_limit() -> bool:
	return current_round > max_round


func is_final_boss_victory(encounter_type: String) -> bool:
	return encounter_type == "BOSS" and current_round >= max_round


func is_mirror_challenge() -> bool:
	return game_mode == GAME_MODE_MIRROR_CHALLENGE


func is_next_round_boss() -> bool:
	return (current_round + 1) in BOSS_ROUNDS


func record_path_choice(node_type: String) -> void:
	pending_node_type = node_type
	path_history.append(node_type)
