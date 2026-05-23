class_name RunController
extends RefCounted

const GameState: Script = preload("res://scripts/game/game_state.gd")

const GAME_MODE_CLASSIC: String = "CLASSIC"
const GAME_MODE_MIRROR_CHALLENGE: String = "MIRROR_CHALLENGE"

var state: int = GameState.MAIN_MENU
var current_round: int = 1
var max_round: int = 30
var game_mode: String = GAME_MODE_CLASSIC


func enter_main_menu() -> void:
	state = GameState.MAIN_MENU
	current_round = 1
	game_mode = GAME_MODE_CLASSIC


func start_run(selected_game_mode: String = GAME_MODE_CLASSIC) -> void:
	current_round = 1
	state = GameState.PREPARE
	game_mode = selected_game_mode


func enter_hero_selection() -> void:
	state = GameState.HERO_SELECTION


func enter_prepare() -> void:
	state = GameState.PREPARE


func enter_battle() -> void:
	state = GameState.BATTLE


func enter_reward() -> void:
	state = GameState.REWARD


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
