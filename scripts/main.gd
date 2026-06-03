extends Node2D

const DEBUG_LOG_SCRIPT: Script = preload("res://scripts/debug_log.gd")
const GameState: Script = preload("res://scripts/game/game_state.gd")
const STATS_MANAGER_SCRIPT: Script = preload("res://scripts/stats_manager.gd")
const ROSTER_MANAGER_SCRIPT: Script = preload("res://scripts/roster_manager.gd")
const BATTLE_MANAGER_SCRIPT: Script = preload("res://scripts/battle_manager.gd")
const ENCOUNTER_MANAGER_SCRIPT: Script = preload("res://scripts/encounter_manager.gd")
const SHOP_MANAGER_SCRIPT: Script = preload("res://scripts/shop_manager.gd")
const ECONOMY_MANAGER_SCRIPT: Script = preload("res://scripts/game/economy_manager.gd")
const RUN_CONTROLLER_SCRIPT: Script = preload("res://scripts/game/run_controller.gd")
const UNIT_TEXT_FORMATTER_SCRIPT: Script = preload("res://scripts/unit_text_formatter.gd")
const RARITY_FORMATTER_SCRIPT: Script = preload("res://scripts/formatters/rarity_formatter.gd")
const UNIT_DETAIL_PANEL_CONTROLLER_SCRIPT: Script = preload("res://scripts/ui/unit_detail_panel_controller.gd")
const RELIC_PANEL_CONTROLLER_SCRIPT: Script = preload("res://scripts/ui/relic_panel_controller.gd")
const REWARD_PANEL_CONTROLLER_SCRIPT: Script = preload("res://scripts/ui/reward_panel_controller.gd")
const SHOP_PANEL_CONTROLLER_SCRIPT: Script = preload("res://scripts/ui/shop_panel_controller.gd")
const MENU_PANEL_CONTROLLER_SCRIPT: Script = preload("res://scripts/ui/menu_panel_controller.gd")
const ENCYCLOPEDIA_PANEL_CONTROLLER_SCRIPT: Script = preload("res://scripts/ui/encyclopedia_panel_controller.gd")
const LINEUP_SNAPSHOT_MANAGER_SCRIPT: Script = preload("res://scripts/lineup_snapshot_manager.gd")
const MIRROR_CHALLENGE_MANAGER_SCRIPT: Script = preload("res://scripts/game/mirror_challenge_manager.gd")
const HERO_MANAGER_SCRIPT: Script = preload("res://scripts/hero_manager.gd")
const HERO_SELECTION_PANEL_CONTROLLER_SCRIPT: Script = preload("res://scripts/ui/hero_selection_panel_controller.gd")
const BATTLE_TIME_MANAGER_SCRIPT: Script = preload("res://scripts/battle_time_manager.gd")
const BOND_MANAGER_SCRIPT: Script = preload("res://scripts/bond_manager.gd")
const PATH_SELECTION_MANAGER_SCRIPT: Script = preload("res://scripts/path_selection_manager.gd")
const PATH_SELECTION_PANEL_CONTROLLER_SCRIPT: Script = preload("res://scripts/ui/path_selection_panel_controller.gd")
const MERCHANT_MANAGER_SCRIPT: Script = preload("res://scripts/merchant_manager.gd")
const MERCHANT_PANEL_CONTROLLER_SCRIPT: Script = preload("res://scripts/ui/merchant_panel_controller.gd")
const TRAINING_MANAGER_SCRIPT: Script = preload("res://scripts/training_manager.gd")
const EVENT_MANAGER_SCRIPT: Script = preload("res://scripts/event_manager.gd")
const EVENT_PANEL_CONTROLLER_SCRIPT: Script = preload("res://scripts/ui/event_panel_controller.gd")
const TRANSITION_PANEL_CONTROLLER_SCRIPT: Script = preload("res://scripts/ui/transition_panel_controller.gd")
const PIXEL_UI_THEME: Script = preload("res://scripts/ui/pixel_ui_theme.gd")
const UI_LAYER: Script = preload("res://scripts/ui/ui_layer.gd")
const BACKGROUND_CATALOG: Script = preload("res://scripts/ui/background_catalog.gd")
const INITIAL_MAX_ACTIVE_UNITS: int = 10
const MAX_TOTAL_UNITS: int = 25
const MAX_RELIC_BAR_ITEMS: int = 8
const MAX_RELIC_BAR_NAME_LENGTH: int = 14
const GAME_MODE_CLASSIC: String = "CLASSIC"
const GAME_MODE_MIRROR_CHALLENGE: String = "MIRROR_CHALLENGE"

@export var unit_scene: PackedScene
@export var warrior_data: Resource
@export var archer_data: Resource
@export var assassin_data: Resource
@export var tank_data: Resource
@export var mage_data: Resource
@export var priest_data: Resource
@export var bard_data: Resource
@export var forest_druid_data: Resource
@export var plague_caster_data: Resource
@export var guardian_captain_data: Resource
@export var wind_chanter_data: Resource
@export var greatsword_knight_data: Resource
@export var bomb_thrower_data: Resource
@export var cleric_data: Resource
@export var alchemist_data: Resource
@export var necromancer_data: Resource
@export var puppet_warlock_data: Resource
@export var use_random_encounters: bool = true

var last_result_text: String = ""
var last_player_won: bool = false
var relic_manager: RelicManager = RelicManager.new()
var reward_manager: RewardManager = RewardManager.new()
var stats_manager: Variant = STATS_MANAGER_SCRIPT.new()
var roster_manager: Variant = ROSTER_MANAGER_SCRIPT.new()
var battle_manager: Variant = BATTLE_MANAGER_SCRIPT.new()
var encounter_manager: Variant = ENCOUNTER_MANAGER_SCRIPT.new()
var shop_manager: Variant = SHOP_MANAGER_SCRIPT.new()
var economy_manager: Variant = ECONOMY_MANAGER_SCRIPT.new()
var run_controller: Variant = RUN_CONTROLLER_SCRIPT.new()
var unit_text_formatter: Variant = UNIT_TEXT_FORMATTER_SCRIPT.new()
var rarity_formatter: Variant = RARITY_FORMATTER_SCRIPT.new()
var unit_detail_panel_controller: Variant = UNIT_DETAIL_PANEL_CONTROLLER_SCRIPT.new()
var relic_panel_controller: Variant = RELIC_PANEL_CONTROLLER_SCRIPT.new()
var reward_panel_controller: Variant = REWARD_PANEL_CONTROLLER_SCRIPT.new()
var shop_panel_controller: Variant = SHOP_PANEL_CONTROLLER_SCRIPT.new()
var menu_panel_controller: Variant = MENU_PANEL_CONTROLLER_SCRIPT.new()
var encyclopedia_panel_controller: Variant = ENCYCLOPEDIA_PANEL_CONTROLLER_SCRIPT.new()
var lineup_snapshot_manager: Variant = LINEUP_SNAPSHOT_MANAGER_SCRIPT.new()
var mirror_challenge_manager: Variant = MIRROR_CHALLENGE_MANAGER_SCRIPT.new()
var hero_manager: Variant = HERO_MANAGER_SCRIPT.new()
var hero_selection_panel_controller: Variant = HERO_SELECTION_PANEL_CONTROLLER_SCRIPT.new()
var battle_time_manager: Variant = BATTLE_TIME_MANAGER_SCRIPT.new()
var bond_manager: Variant = BOND_MANAGER_SCRIPT.new()
var path_selection_manager: Variant = PATH_SELECTION_MANAGER_SCRIPT.new()
var path_selection_panel_controller: Variant = PATH_SELECTION_PANEL_CONTROLLER_SCRIPT.new()
var merchant_manager: Variant = MERCHANT_MANAGER_SCRIPT.new()
var merchant_panel_controller: Variant = MERCHANT_PANEL_CONTROLLER_SCRIPT.new()
var training_manager: Variant = TRAINING_MANAGER_SCRIPT.new()
var event_manager: Variant = EVENT_MANAGER_SCRIPT.new()
var event_panel_controller: Variant = EVENT_PANEL_CONTROLLER_SCRIPT.new()
var transition_panel_controller: Variant = TRANSITION_PANEL_CONTROLLER_SCRIPT.new()
var mirror_enemy_relic_manager: RelicManager = null
var gold_relic_logs: Array[String] = []
var mirror_info_button: Button = null
var mirror_info_panel: Panel = null
var mirror_info_text: RichTextLabel = null
var battle_speed_button: Button = null
var grid_toggle_button: Button = null
var background_switch_button: OptionButton = null
var bond_panel: Panel = null
var bond_panel_label: Label = null
var bond_buttons_vbox: VBoxContainer = null
var bond_detail_panel: Panel = null
var bond_detail_text: RichTextLabel = null
var stats_popup_panel: Panel = null
var stats_popup_title_label: Label = null
var stats_popup_summary_label: Label = null
var stats_popup_scroll: ScrollContainer = null
var stats_popup_content: VBoxContainer = null
var stats_popup_close_button: Button = null
var selected_bond_id: String = ""
var pending_post_hero_upgrade_result_text: String = ""
var pending_post_hero_upgrade_player_won: bool = false
var is_sell_zone_highlighted: bool = false
var sell_zone_feedback_tween: Tween = null
var _pending_treasure_relic: Variant = null
var is_popup_active: bool = false
var _popup_callback: Callable = Callable()
var dynamic_stat_refresh_pending: bool = false
var selected_background_index: int = 0

@onready var battle_board: Variant = $"BoardBackground Node2D"
@onready var result_label: Label = $"UI CanvasLayer/ResultLabel Label"
@onready var round_label: Label = $"UI CanvasLayer/RoundLabel Label"
@onready var hero_exp_panel: Panel = $"UI CanvasLayer/HeroExpPanel Panel"
@onready var hero_exp_name_label: Label = $"UI CanvasLayer/HeroExpPanel Panel/HeroExpName Label"
@onready var hero_exp_bar: ProgressBar = $"UI CanvasLayer/HeroExpPanel Panel/HeroExpBar ProgressBar"
@onready var hero_exp_value_label: Label = $"UI CanvasLayer/HeroExpPanel Panel/HeroExpValue Label"
@onready var gold_frame: Panel = $"UI CanvasLayer/GoldFrame TextureRect"
@onready var gold_label: Label = $"UI CanvasLayer/GoldLabel Label"
@onready var start_button: Button = $"UI CanvasLayer/StartButton Button"
@onready var menu_button: Button = $"UI CanvasLayer/MenuButton Button"
@onready var shop_button: Button = $"UI CanvasLayer/ShopButton Button"
@onready var bench_button: Button = $"UI CanvasLayer/BenchButton Button"
@onready var stats_label: RichTextLabel = $"UI CanvasLayer/StatsPanel RichTextLabel"
@onready var encounter_info_panel: Panel = $"UI CanvasLayer/EncounterInfoPanel Panel"
@onready var encounter_info_label: RichTextLabel = $"UI CanvasLayer/EncounterInfoPanel Panel/EncounterInfo RichTextLabel"
@onready var shop_panel: Panel = $"UI CanvasLayer/ShopPanel Panel"
@onready var shop_title_label: Label = $"UI CanvasLayer/ShopPanel Panel/ShopTitle Label"
@onready var shop_item_label_1: Label = $"UI CanvasLayer/ShopPanel Panel/ShopItem1 Label"
@onready var shop_item_label_2: Label = $"UI CanvasLayer/ShopPanel Panel/ShopItem2 Label"
@onready var shop_item_label_3: Label = $"UI CanvasLayer/ShopPanel Panel/ShopItem3 Label"
@onready var shop_item_label_4: Label = $"UI CanvasLayer/ShopPanel Panel/ShopItem4 Label"
@onready var shop_item_label_5: Label = $"UI CanvasLayer/ShopPanel Panel/ShopItem5 Label"
@onready var shop_item_label_6: Label = $"UI CanvasLayer/ShopPanel Panel/ShopItem6 Label"
@onready var shop_item_label_7: Label = $"UI CanvasLayer/ShopPanel Panel/ShopItem7 Label"
@onready var shop_item_label_8: Label = $"UI CanvasLayer/ShopPanel Panel/ShopItem8 Label"
@onready var shop_item_label_9: Label = $"UI CanvasLayer/ShopPanel Panel/ShopItem9 Label"
@onready var shop_item_label_10: Label = $"UI CanvasLayer/ShopPanel Panel/ShopItem10 Label"
@onready var shop_buy_button_1: Button = $"UI CanvasLayer/ShopPanel Panel/ShopBuyButton1 Button"
@onready var shop_buy_button_2: Button = $"UI CanvasLayer/ShopPanel Panel/ShopBuyButton2 Button"
@onready var shop_buy_button_3: Button = $"UI CanvasLayer/ShopPanel Panel/ShopBuyButton3 Button"
@onready var shop_buy_button_4: Button = $"UI CanvasLayer/ShopPanel Panel/ShopBuyButton4 Button"
@onready var shop_buy_button_5: Button = $"UI CanvasLayer/ShopPanel Panel/ShopBuyButton5 Button"
@onready var shop_buy_button_6: Button = $"UI CanvasLayer/ShopPanel Panel/ShopBuyButton6 Button"
@onready var shop_buy_button_7: Button = $"UI CanvasLayer/ShopPanel Panel/ShopBuyButton7 Button"
@onready var shop_buy_button_8: Button = $"UI CanvasLayer/ShopPanel Panel/ShopBuyButton8 Button"
@onready var shop_buy_button_9: Button = $"UI CanvasLayer/ShopPanel Panel/ShopBuyButton9 Button"
@onready var shop_buy_button_10: Button = $"UI CanvasLayer/ShopPanel Panel/ShopBuyButton10 Button"
@onready var shop_gold_label: Label = $"UI CanvasLayer/ShopPanel Panel/ShopGold Label"
@onready var refresh_shop_button: Button = $"UI CanvasLayer/ShopPanel Panel/RefreshShopButton Button"
@onready var shop_close_button: Button = $"UI CanvasLayer/ShopPanel Panel/ShopCloseButton Button"
@onready var sell_zone_panel: Control = $"UI CanvasLayer/SellZonePanel ColorRect"
@onready var bench_panel: Panel = $"UI CanvasLayer/BenchPanel Panel"
@onready var active_count_label: Label = $"UI CanvasLayer/BenchPanel Panel/ActiveCount Label"
@onready var total_units_label: Label = $"UI CanvasLayer/BenchPanel Panel/TotalUnits Label"
@onready var active_units_vbox: VBoxContainer = $"UI CanvasLayer/BenchPanel Panel/ActiveUnitsScroll ScrollContainer/ActiveUnitsVBox VBoxContainer"
@onready var bench_units_vbox: VBoxContainer = $"UI CanvasLayer/BenchPanel Panel/BenchUnitsScroll ScrollContainer/BenchUnitsVBox VBoxContainer"
@onready var bench_close_button: Button = $"UI CanvasLayer/BenchPanel Panel/BenchCloseButton Button"
@onready var reward_panel: Panel = $"UI CanvasLayer/RewardPanel Panel"
@onready var path_selection_panel: Panel = $"UI CanvasLayer/PathSelectionPanel Panel"
@onready var path_selection_title: Label = $"UI CanvasLayer/PathSelectionPanel Panel/Title Label"
@onready var path_button_1: Button = $"UI CanvasLayer/PathSelectionPanel Panel/PathButton1 Button"
@onready var path_button_2: Button = $"UI CanvasLayer/PathSelectionPanel Panel/PathButton2 Button"
@onready var path_button_3: Button = $"UI CanvasLayer/PathSelectionPanel Panel/PathButton3 Button"
@onready var merchant_panel: Panel = $"UI CanvasLayer/MerchantPanel Panel"
@onready var merchant_title_label: Label = $"UI CanvasLayer/MerchantPanel Panel/Title Label"
@onready var merchant_gold_label: Label = $"UI CanvasLayer/MerchantPanel Panel/GoldLabel Label"
@onready var merchant_refresh_button: Button = $"UI CanvasLayer/MerchantPanel Panel/RefreshButton Button"
@onready var merchant_leave_button: Button = $"UI CanvasLayer/MerchantPanel Panel/LeaveButton Button"
@onready var merchant_relic_button_1: Button = $"UI CanvasLayer/MerchantPanel Panel/RelicItem1 Button"
@onready var merchant_relic_button_2: Button = $"UI CanvasLayer/MerchantPanel Panel/RelicItem2 Button"
@onready var merchant_relic_button_3: Button = $"UI CanvasLayer/MerchantPanel Panel/RelicItem3 Button"
@onready var merchant_relic_button_4: Button = $"UI CanvasLayer/MerchantPanel Panel/RelicItem4 Button"
@onready var merchant_special_button_1: Button = $"UI CanvasLayer/MerchantPanel Panel/SpecialItem1 Button"
@onready var merchant_special_button_2: Button = $"UI CanvasLayer/MerchantPanel Panel/SpecialItem2 Button"
@onready var merchant_special_button_3: Button = $"UI CanvasLayer/MerchantPanel Panel/SpecialItem3 Button"
@onready var merchant_special_button_4: Button = $"UI CanvasLayer/MerchantPanel Panel/SpecialItem4 Button"
@onready var reward_button_1: Button = $"UI CanvasLayer/RewardPanel Panel/RewardButton1 Button"
@onready var reward_button_2: Button = $"UI CanvasLayer/RewardPanel Panel/RewardButton2 Button"
@onready var reward_button_3: Button = $"UI CanvasLayer/RewardPanel Panel/RewardButton3 Button"
@onready var hero_selection_panel: Panel = $"UI CanvasLayer/HeroSelectionPanel Panel"
@onready var unit_detail_panel: Panel = $"UI CanvasLayer/UnitDetailPanel Panel"
@onready var unit_detail_title: Label = $"UI CanvasLayer/UnitDetailPanel Panel/UnitDetailTitle Label"
@onready var unit_detail_close_button: Button = $"UI CanvasLayer/UnitDetailPanel Panel/UnitDetailCloseButton Button"
@onready var unit_detail_text: RichTextLabel = $"UI CanvasLayer/UnitDetailPanel Panel/UnitDetailText RichTextLabel"
@onready var relic_bar_panel: Panel = $"UI CanvasLayer/RelicBarPanel Panel"
@onready var relic_bar_hbox: HBoxContainer = $"UI CanvasLayer/RelicBarPanel Panel/RelicBarHBox HBoxContainer"
@onready var relic_detail_panel: Panel = $"UI CanvasLayer/RelicDetailPanel Panel"
@onready var relic_detail_close_button: Button = $"UI CanvasLayer/RelicDetailPanel Panel/RelicDetailCloseButton Button"
@onready var relic_list_vbox: VBoxContainer = $"UI CanvasLayer/RelicDetailPanel Panel/RelicListScroll ScrollContainer/RelicListVBox VBoxContainer"
@onready var relic_info_text: RichTextLabel = $"UI CanvasLayer/RelicDetailPanel Panel/RelicInfo RichTextLabel"
@onready var event_panel: Panel = $"UI CanvasLayer/EventPanel Panel"
@onready var event_title_label: Label = $"UI CanvasLayer/EventPanel Panel/Title Label"
@onready var event_text_label: RichTextLabel = $"UI CanvasLayer/EventPanel Panel/EventText RichTextLabel"
@onready var event_choice_button_1: Button = $"UI CanvasLayer/EventPanel Panel/ChoiceButton1 Button"
@onready var event_choice_button_2: Button = $"UI CanvasLayer/EventPanel Panel/ChoiceButton2 Button"
@onready var event_result_label: Label = $"UI CanvasLayer/EventPanel Panel/ResultText Label"
@onready var event_continue_button: Button = $"UI CanvasLayer/EventPanel Panel/ContinueButton Button"
@onready var transition_panel: Panel = $"UI CanvasLayer/TransitionPanel Panel"
@onready var transition_background: ColorRect = $"UI CanvasLayer/TransitionPanel Panel/Background ColorRect"
@onready var transition_round_label: Label = $"UI CanvasLayer/TransitionPanel Panel/ContentVBox VBoxContainer/RoundLabel Label"
@onready var transition_node_type_label: Label = $"UI CanvasLayer/TransitionPanel Panel/ContentVBox VBoxContainer/NodeTypeLabel Label"
@onready var transition_description_label: Label = $"UI CanvasLayer/TransitionPanel Panel/ContentVBox VBoxContainer/DescriptionLabel Label"


func _ready() -> void:
	randomize()
	roster_manager.setup(warrior_data, archer_data, assassin_data, tank_data, mage_data, priest_data, bard_data, forest_druid_data, plague_caster_data, guardian_captain_data, wind_chanter_data, greatsword_knight_data, bomb_thrower_data, cleric_data, alchemist_data, necromancer_data, puppet_warlock_data)
	roster_manager.max_active_units = INITIAL_MAX_ACTIVE_UNITS
	roster_manager.max_total_units = MAX_TOTAL_UNITS
	encounter_manager.setup(warrior_data, archer_data, assassin_data, tank_data, mage_data, priest_data, bard_data)
	encounter_manager.use_random_encounters = use_random_encounters
	shop_manager.setup(warrior_data, archer_data, assassin_data, tank_data, mage_data, priest_data, bard_data, forest_druid_data, plague_caster_data, guardian_captain_data, wind_chanter_data, greatsword_knight_data, bomb_thrower_data, cleric_data, alchemist_data, necromancer_data, puppet_warlock_data, relic_manager, roster_manager)
	reward_manager.setup(relic_manager, roster_manager)
	relic_manager.set_gold_callback(Callable(self, "_on_relic_gold_added"))
	relic_manager.set_gold_query_callback(Callable(economy_manager, "get_gold"))
	if not economy_manager.gold_changed.is_connected(_on_gold_changed):
		economy_manager.gold_changed.connect(_on_gold_changed)
	battle_manager.setup(self, unit_scene, stats_manager, relic_manager, battle_board, Callable(self, "_on_prepare_unit_drop_requested"), hero_manager, bond_manager)
	battle_manager.set_roster_manager(roster_manager)
	battle_manager.battle_ended.connect(_on_battle_ended)
	battle_manager.overtime_started.connect(_on_overtime_started)
	if battle_board != null and battle_board.has_signal("layout_changed"):
		battle_board.layout_changed.connect(_on_battle_board_layout_changed)
	_apply_static_ui_layers()
	start_button.pressed.connect(_on_start_button_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)
	shop_button.pressed.connect(_on_shop_button_pressed)
	bench_button.pressed.connect(_on_bench_button_pressed)
	shop_close_button.pressed.connect(_on_shop_close_button_pressed)
	bench_close_button.pressed.connect(_on_bench_close_button_pressed)
	unit_detail_close_button.pressed.connect(_on_unit_detail_close_button_pressed)
	relic_detail_close_button.pressed.connect(_on_relic_detail_close_button_pressed)
	_setup_shop_panel_controller()
	_setup_reward_panel_controller()
	_setup_path_selection_panel_controller()
	_setup_merchant_panel_controller()
	_setup_training_manager()
	_setup_event_manager()
	_setup_transition_panel()
	_apply_main_action_button_styles()
	_apply_battle_panel_styles()
	_localize_static_ui()
	unit_detail_panel_controller.setup(unit_detail_panel, unit_detail_title, unit_detail_text, unit_text_formatter, rarity_formatter, battle_board)
	unit_detail_panel_controller.set_bond_manager(bond_manager)
	relic_panel_controller.setup(relic_bar_panel, relic_bar_hbox, relic_detail_panel, relic_list_vbox, relic_info_text, relic_manager, rarity_formatter, MAX_RELIC_BAR_ITEMS, MAX_RELIC_BAR_NAME_LENGTH)
	_setup_menu_panel_controller()
	_setup_encyclopedia_panel_controller()
	_setup_hero_selection_panel_controller()
	_setup_background_catalog()
	_create_battle_speed_button()
	_create_grid_toggle_button()
	_create_background_switch_button()
	_create_bond_panel()
	bond_manager.setup(roster_manager.unit_catalog, hero_manager)
	_create_mirror_info_ui()
	_position_encounter_info_panel()
	_enter_main_menu()


func _process(delta: float) -> void:
	var is_battle_running: bool = (run_controller.state == GameState.BATTLE and battle_manager.is_battle_active) or (run_controller.state == GameState.TRAINING and training_manager.is_training_active)
	var battle_delta: float = battle_time_manager.update(delta, is_battle_running)
	if run_controller.state == GameState.TRAINING and training_manager.is_training_active:
		battle_manager.update(battle_delta)
		if training_manager.tick(battle_delta):
			_on_training_timer_expired()
			return
	elif run_controller.state != GameState.MAIN_MENU:
		battle_manager.update(battle_delta)
		_update_sell_zone_highlight()
	_refresh_unit_detail_panel_if_open()


func _apply_static_ui_layers() -> void:
	result_label.z_index = UI_LAYER.RESULT_LABEL
	round_label.z_index = UI_LAYER.ROUND_LABEL
	hero_exp_panel.z_index = UI_LAYER.HERO_EXP_PANEL
	gold_frame.z_index = UI_LAYER.GOLD_PANEL
	gold_label.z_index = UI_LAYER.GOLD_PANEL
	relic_bar_panel.z_index = UI_LAYER.RELIC_BAR
	encounter_info_panel.z_index = UI_LAYER.ENCOUNTER_INFO
	sell_zone_panel.z_index = UI_LAYER.SELL_ZONE

	start_button.z_index = UI_LAYER.HUD_ACTION_BUTTON
	shop_button.z_index = UI_LAYER.HUD_ACTION_BUTTON
	bench_button.z_index = UI_LAYER.HUD_ACTION_BUTTON
	menu_button.z_index = UI_LAYER.MENU_BUTTON

	shop_panel.z_index = UI_LAYER.SHOP_PANEL
	bench_panel.z_index = UI_LAYER.BENCH_PANEL
	stats_label.z_index = UI_LAYER.STATS_PANEL
	unit_detail_panel.z_index = UI_LAYER.UNIT_DETAIL
	relic_detail_panel.z_index = UI_LAYER.RELIC_DETAIL
	hero_selection_panel.z_index = UI_LAYER.HERO_SELECTION
	reward_panel.z_index = UI_LAYER.REWARD_PANEL


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return

	var mouse_button: InputEventMouseButton = event as InputEventMouseButton
	if not mouse_button.pressed:
		return

	if mouse_button.button_index != MOUSE_BUTTON_LEFT and mouse_button.button_index != MOUSE_BUTTON_RIGHT:
		return

	if unit_detail_panel == null or not unit_detail_panel.visible:
		return

	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	if _is_position_inside_control(unit_detail_panel, mouse_position):
		return

	if _is_position_over_any_unit(mouse_position):
		return

	_hide_unit_detail_panel()


func _on_battle_board_layout_changed(old_board_origin: Vector2, old_cell_size: float) -> void:
	if run_controller.state == GameState.MAIN_MENU:
		return

	_remap_existing_units_to_board_layout(old_board_origin, old_cell_size)
	_position_encounter_info_panel()
	if run_controller.state == GameState.PREPARE:
		_save_player_start_positions()
	_refresh_unit_detail_panel_if_open()


func _remap_existing_units_to_board_layout(old_board_origin: Vector2, old_cell_size: float) -> void:
	if battle_board == null or not is_instance_valid(battle_board):
		return

	if not battle_board.has_method("remap_world_position_from_layout"):
		return

	for unit: Unit in battle_manager.get_left_units():
		_remap_unit_to_board_layout(unit, old_board_origin, old_cell_size)
	for unit: Unit in battle_manager.get_right_units():
		_remap_unit_to_board_layout(unit, old_board_origin, old_cell_size)
	for unit: Unit in battle_manager.get_bench_units():
		_remap_unit_to_board_layout(unit, old_board_origin, old_cell_size)


func _remap_unit_to_board_layout(unit: Unit, old_board_origin: Vector2, old_cell_size: float) -> void:
	if unit == null or not is_instance_valid(unit):
		return

	unit.position = battle_board.remap_world_position_from_layout(unit.position, old_board_origin, old_cell_size)
	unit.last_ai_position = battle_board.remap_world_position_from_layout(unit.last_ai_position, old_board_origin, old_cell_size)
	if unit.drag_controller != null and unit.drag_controller.is_dragging:
		unit.drag_controller.drag_start_position = battle_board.remap_world_position_from_layout(
			unit.drag_controller.drag_start_position,
			old_board_origin,
			old_cell_size
		)


func _enter_main_menu() -> void:
	run_controller.enter_main_menu()
	battle_time_manager.reset_for_run()
	_apply_current_battle_speed()
	mirror_challenge_manager.clear_challenge()
	encounter_manager.clear_mirror_boss_encounters()
	mirror_enemy_relic_manager = null
	economy_manager.reset()
	event_manager.reset()
	_battle_stats_text = ""
	_battle_stats_units.clear()
	_battle_stats_duration = 0.0
	_battle_stats_relic_damage = 0
	last_result_text = ""
	last_player_won = false
	pending_post_hero_upgrade_result_text = ""
	pending_post_hero_upgrade_player_won = false
	battle_manager.clear_battlefield()
	stats_manager.clear()
	relic_manager.clear_relics()
	hero_manager.reset_hero()
	_hide_shop_panel()
	_hide_bench_panel()
	_hide_reward_panel()
	_hide_path_selection_panel()
	_hide_merchant_panel()
	_hide_stats_button()
	_hide_event_panel()
	_hide_hero_selection_panel()
	_hide_gameplay_menu()
	_hide_unit_detail_panel()
	_hide_relic_detail_panel()
	_hide_mirror_info_panel()
	_hide_encyclopedia_panel()
	_update_battle_speed_button_visibility()
	_update_mirror_info_button_visibility()
	if bond_panel != null:
		bond_panel.visible = false
	_hide_bond_detail_panel()
	_hide_encounter_info_panel()
	_hide_prepare_action_buttons()
	_set_board_visible(false)
	_set_gameplay_ui_visible(false)
	stats_label.text = ""

	menu_panel_controller.hide_game_end_dialog()
	menu_panel_controller.show_main_menu()


func _on_main_menu_start_pressed() -> void:
	_restart_run(GAME_MODE_CLASSIC)


func _on_mirror_challenge_requested() -> void:
	_restart_run(GAME_MODE_MIRROR_CHALLENGE)


func _on_encyclopedia_requested() -> void:
	_show_encyclopedia_panel()


func _on_hero_selected(hero_id: String) -> void:
	if not hero_manager.select_hero(hero_id):
		result_label.text = "英雄选择失败"
		return

	_hide_hero_selection_panel()
	result_label.text = ""
	_update_hero_exp_ui()
	run_controller.pending_node_type = ""
	_show_transition(Callable(self, "_enter_prepare_state"))


func _on_hero_selection_cancelled() -> void:
	_enter_main_menu()


func _on_game_end_confirm_pressed() -> void:
	_enter_main_menu()


func _on_menu_button_pressed() -> void:
	if run_controller.state == GameState.MAIN_MENU or run_controller.state == GameState.GAME_OVER:
		return

	_show_gameplay_menu()


func _on_gameplay_menu_main_menu_pressed() -> void:
	_hide_gameplay_menu()
	_enter_main_menu()


func _on_gameplay_menu_restart_pressed() -> void:
	_hide_gameplay_menu()
	_restart_run()


func _show_gameplay_menu() -> void:
	menu_panel_controller.show_gameplay_menu()


func _hide_gameplay_menu() -> void:
	menu_panel_controller.hide_gameplay_menu()


func _show_game_end_dialog(game_over_text: String) -> void:
	menu_panel_controller.show_game_end_dialog(game_over_text, run_controller.current_round)


func _hide_game_end_dialog() -> void:
	menu_panel_controller.hide_game_end_dialog()


func _show_encyclopedia_panel() -> void:
	encyclopedia_panel_controller.show()


func _hide_encyclopedia_panel() -> void:
	encyclopedia_panel_controller.hide()


func _localize_static_ui() -> void:
	result_label.text = "就绪"
	round_label.text = ""
	if hero_exp_panel != null:
		hero_exp_panel.visible = false
	gold_label.text = "金币：" + str(economy_manager.gold)
	start_button.text = "开始战斗"
	start_button.visible = false
	menu_button.text = "菜单"
	menu_button.visible = false
	_update_battle_speed_button()
	_update_battle_speed_button_visibility()
	shop_button.text = "商店"
	bench_button.text = "阵容"
	bench_button.visible = false
	bench_panel.visible = false
	if sell_zone_panel != null:
		var sell_zone_title_label: Label = sell_zone_panel.get_node_or_null("SellZoneTitle Label") as Label
		var sell_zone_hint_label: Label = sell_zone_panel.get_node_or_null("SellZoneHint Label") as Label
		if sell_zone_title_label != null:
			sell_zone_title_label.text = "出售"
			sell_zone_title_label.visible = true
		if sell_zone_hint_label != null:
			sell_zone_hint_label.text = "拖拽单位到这里出售"
			sell_zone_hint_label.visible = true
	shop_title_label.text = "商店"
	shop_close_button.text = "关闭"
	refresh_shop_button.text = "刷新"
	shop_gold_label.text = "金币：" + str(economy_manager.gold)
	bench_close_button.text = "关闭"
	var reward_title_label: Label = reward_panel.get_node("RewardTitle Label") as Label
	if reward_title_label != null:
		reward_title_label.text = "选择奖励"
	unit_detail_title.text = "单位详情"
	unit_detail_close_button.text = "关闭"
	var relic_detail_title_label: Label = relic_detail_panel.get_node("RelicDetailTitle Label") as Label
	if relic_detail_title_label != null:
		relic_detail_title_label.text = "遗物详情"
	relic_detail_close_button.text = "关闭"


func _setup_reward_panel_controller() -> void:
	var buttons: Array[Button] = []
	buttons.append(reward_button_1)
	buttons.append(reward_button_2)
	buttons.append(reward_button_3)
	reward_panel_controller.setup(reward_panel, buttons, reward_manager, roster_manager, relic_manager, rarity_formatter)
	reward_panel_controller.reward_applied.connect(_on_reward_applied)
	reward_panel_controller.hero_upgrade_selected.connect(_on_hero_upgrade_selected)


func _setup_path_selection_panel_controller() -> void:
	var buttons: Array[Button] = []
	buttons.append(path_button_1)
	buttons.append(path_button_2)
	buttons.append(path_button_3)
	path_selection_panel_controller.setup(path_selection_panel, path_selection_title, buttons)
	path_selection_panel_controller.path_selected.connect(_on_path_selected)


func _setup_merchant_panel_controller() -> void:
	merchant_manager.setup(relic_manager, roster_manager)
	var relic_btns: Array[Button] = []
	relic_btns.append(merchant_relic_button_1)
	relic_btns.append(merchant_relic_button_2)
	relic_btns.append(merchant_relic_button_3)
	relic_btns.append(merchant_relic_button_4)
	var special_btns: Array[Button] = []
	special_btns.append(merchant_special_button_1)
	special_btns.append(merchant_special_button_2)
	special_btns.append(merchant_special_button_3)
	special_btns.append(merchant_special_button_4)
	merchant_panel_controller.setup(
		merchant_panel,
		merchant_title_label,
		merchant_gold_label,
		merchant_refresh_button,
		merchant_leave_button,
		relic_btns,
		special_btns,
		merchant_manager,
		economy_manager
	)
	merchant_panel_controller.item_purchased.connect(_on_merchant_item_purchased)
	merchant_panel_controller.leave_requested.connect(_on_merchant_leave)


func _setup_shop_panel_controller() -> void:
	shop_panel_controller.setup(
		shop_panel,
		shop_title_label,
		shop_gold_label,
		refresh_shop_button,
		shop_close_button,
		_get_shop_item_labels(),
		_get_shop_buy_buttons(),
		shop_manager,
		roster_manager,
		relic_manager,
		rarity_formatter
	)
	shop_panel_controller.buy_requested.connect(_on_shop_buy_button_pressed)
	shop_panel_controller.refresh_requested.connect(_on_refresh_shop_button_pressed)
	shop_panel_controller.relic_detail_requested.connect(_show_shop_relic_detail_panel)


func _setup_menu_panel_controller() -> void:
	var ui_canvas_layer: CanvasLayer = $"UI CanvasLayer"
	menu_panel_controller.setup(ui_canvas_layer, rarity_formatter)
	menu_panel_controller.start_requested.connect(_on_main_menu_start_pressed)
	menu_panel_controller.mirror_challenge_requested.connect(_on_mirror_challenge_requested)
	menu_panel_controller.encyclopedia_requested.connect(_on_encyclopedia_requested)
	menu_panel_controller.game_end_confirmed.connect(_on_game_end_confirm_pressed)
	menu_panel_controller.main_menu_requested.connect(_on_gameplay_menu_main_menu_pressed)
	menu_panel_controller.restart_requested.connect(_on_gameplay_menu_restart_pressed)
	if menu_panel_controller.has_signal("background_selected"):
		menu_panel_controller.background_selected.connect(_on_main_menu_background_selected)


func _setup_background_catalog() -> void:
	var textures: Array[Texture2D] = BACKGROUND_CATALOG.load_background_textures()
	var names: Array[String] = BACKGROUND_CATALOG.get_background_names()
	if battle_board != null and is_instance_valid(battle_board):
		if battle_board.has_method("set_background_catalog"):
			battle_board.set_background_catalog(textures, names, selected_background_index)
		else:
			battle_board.background_options = textures
			battle_board.background_names = names
			if battle_board.has_method("set_background_index"):
				battle_board.set_background_index(selected_background_index)
	if menu_panel_controller.has_method("set_background_index"):
		menu_panel_controller.set_background_index(selected_background_index)


func _setup_encyclopedia_panel_controller() -> void:
	var ui_canvas_layer: CanvasLayer = $"UI CanvasLayer"
	encyclopedia_panel_controller.setup(ui_canvas_layer, unit_text_formatter, rarity_formatter)
	encyclopedia_panel_controller.set_bond_manager(bond_manager)


func _setup_hero_selection_panel_controller() -> void:
	hero_selection_panel_controller.setup(hero_selection_panel, hero_manager, rarity_formatter)
	hero_selection_panel_controller.set_bond_manager(bond_manager)
	hero_selection_panel_controller.hero_selected.connect(_on_hero_selected)
	hero_selection_panel_controller.selection_cancelled.connect(_on_hero_selection_cancelled)


func _create_battle_speed_button() -> void:
	var ui_canvas_layer: CanvasLayer = $"UI CanvasLayer"
	if ui_canvas_layer == null:
		return

	battle_speed_button = Button.new()
	battle_speed_button.anchor_left = 1.0
	battle_speed_button.anchor_right = 1.0
	battle_speed_button.offset_left = -174.0
	battle_speed_button.offset_top = 96.0
	battle_speed_button.offset_right = -24.0
	battle_speed_button.offset_bottom = 132.0
	battle_speed_button.visible = false
	battle_speed_button.focus_mode = Control.FOCUS_NONE
	battle_speed_button.z_index = UI_LAYER.BATTLE_SPEED_BUTTON
	battle_speed_button.tooltip_text = "点击切换战斗速度"
	battle_speed_button.pressed.connect(_on_battle_speed_button_pressed)
	battle_speed_button.add_theme_font_size_override("font_size", 16)
	_apply_menu_button_style(battle_speed_button, Color(0.18, 0.32, 0.50, 1.0), Color(0.72, 0.86, 1.0, 1.0))
	ui_canvas_layer.add_child(battle_speed_button)
	_update_battle_speed_button()


func _create_grid_toggle_button() -> void:
	var ui_canvas_layer: CanvasLayer = $"UI CanvasLayer"
	if ui_canvas_layer == null:
		return

	grid_toggle_button = Button.new()
	grid_toggle_button.anchor_left = 1.0
	grid_toggle_button.anchor_right = 1.0
	grid_toggle_button.offset_left = -174.0
	grid_toggle_button.offset_top = 138.0
	grid_toggle_button.offset_right = -24.0
	grid_toggle_button.offset_bottom = 174.0
	grid_toggle_button.visible = false
	grid_toggle_button.focus_mode = Control.FOCUS_NONE
	grid_toggle_button.z_index = UI_LAYER.BATTLE_SPEED_BUTTON
	grid_toggle_button.tooltip_text = "切换棋盘网格显示"
	grid_toggle_button.pressed.connect(_on_grid_toggle_button_pressed)
	grid_toggle_button.add_theme_font_size_override("font_size", 16)
	_apply_menu_button_style(grid_toggle_button, Color(0.18, 0.34, 0.22, 1.0), Color(0.70, 0.92, 0.58, 1.0))
	ui_canvas_layer.add_child(grid_toggle_button)
	_update_grid_toggle_button()


func _create_background_switch_button() -> void:
	var ui_canvas_layer: CanvasLayer = $"UI CanvasLayer"
	if ui_canvas_layer == null:
		return

	background_switch_button = OptionButton.new()
	background_switch_button.anchor_left = 1.0
	background_switch_button.anchor_right = 1.0
	background_switch_button.offset_left = -244.0
	background_switch_button.offset_top = 180.0
	background_switch_button.offset_right = -24.0
	background_switch_button.offset_bottom = 216.0
	background_switch_button.visible = false
	background_switch_button.focus_mode = Control.FOCUS_NONE
	background_switch_button.z_index = UI_LAYER.BATTLE_SPEED_BUTTON
	background_switch_button.tooltip_text = "切换对战背景"
	background_switch_button.item_selected.connect(_on_background_option_selected)
	background_switch_button.add_theme_font_size_override("font_size", 16)
	_apply_menu_button_style(background_switch_button, Color(0.22, 0.18, 0.34, 1.0), Color(0.86, 0.70, 1.0, 1.0))
	ui_canvas_layer.add_child(background_switch_button)
	_populate_background_selector()
	_update_background_switch_button()


func _create_bond_panel() -> void:
	var ui_canvas_layer: CanvasLayer = $"UI CanvasLayer"
	if ui_canvas_layer == null:
		return

	bond_panel = Panel.new()
	bond_panel.visible = false
	bond_panel.z_index = UI_LAYER.BOND_PANEL
	bond_panel.add_theme_stylebox_override("panel", _create_panel_style(Color(0.045, 0.060, 0.090, 0.90), Color(0.50, 0.67, 0.88, 0.88), 0, 2))
	ui_canvas_layer.add_child(bond_panel)

	bond_panel_label = Label.new()
	bond_panel_label.text = "羁绊"
	bond_panel_label.position = Vector2(12.0, 8.0)
	bond_panel_label.custom_minimum_size = Vector2(166.0, 24.0)
	bond_panel_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bond_panel_label.add_theme_font_size_override("font_size", 15)
	bond_panel_label.add_theme_color_override("font_color", Color(0.98, 0.86, 0.58, 1.0))
	bond_panel_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.04, 0.08, 0.9))
	bond_panel_label.add_theme_constant_override("shadow_offset_x", 1)
	bond_panel_label.add_theme_constant_override("shadow_offset_y", 1)
	bond_panel.add_child(bond_panel_label)

	bond_buttons_vbox = VBoxContainer.new()
	bond_buttons_vbox.position = Vector2(10.0, 38.0)
	bond_buttons_vbox.add_theme_constant_override("separation", 4)
	bond_panel.add_child(bond_buttons_vbox)

	bond_detail_panel = Panel.new()
	bond_detail_panel.visible = false
	bond_detail_panel.z_index = UI_LAYER.BOND_DETAIL
	bond_detail_panel.custom_minimum_size = Vector2(520.0, 420.0)
	bond_detail_panel.add_theme_stylebox_override("panel", _create_panel_style(Color(0.040, 0.052, 0.078, 0.98), Color(0.78, 0.62, 0.36, 0.96), 0, 2))
	ui_canvas_layer.add_child(bond_detail_panel)

	var detail_title: Label = Label.new()
	detail_title.text = "羁绊详情"
	detail_title.position = Vector2(18.0, 14.0)
	detail_title.custom_minimum_size = Vector2(240.0, 28.0)
	detail_title.add_theme_font_size_override("font_size", 20)
	detail_title.add_theme_color_override("font_color", Color(0.98, 0.86, 0.58, 1.0))
	bond_detail_panel.add_child(detail_title)

	var detail_close_button: Button = Button.new()
	detail_close_button.text = "关闭"
	detail_close_button.position = Vector2(424.0, 12.0)
	detail_close_button.custom_minimum_size = Vector2(76.0, 30.0)
	detail_close_button.focus_mode = Control.FOCUS_NONE
	detail_close_button.pressed.connect(_hide_bond_detail_panel)
	_apply_menu_button_style(detail_close_button, Color(0.22, 0.25, 0.30, 1.0), Color(0.68, 0.72, 0.78, 1.0))
	bond_detail_panel.add_child(detail_close_button)

	bond_detail_text = RichTextLabel.new()
	bond_detail_text.position = Vector2(18.0, 54.0)
	bond_detail_text.size = Vector2(504.0, 406.0)
	bond_detail_text.fit_content = false
	bond_detail_text.scroll_active = true
	bond_detail_text.bbcode_enabled = false
	bond_detail_text.add_theme_font_size_override("normal_font_size", 15)
	bond_detail_text.add_theme_color_override("default_color", Color(0.90, 0.93, 0.98, 1.0))
	bond_detail_panel.add_child(bond_detail_text)

	_update_bond_panel_layout()
	_refresh_bond_panel()


func _refresh_bond_panel() -> void:
	if bond_panel == null or bond_buttons_vbox == null:
		return

	if run_controller.state == GameState.PREPARE:
		bond_manager.calculate_from_roster(roster_manager.get_active_roster(), hero_manager)
	elif run_controller.state == GameState.BATTLE:
		bond_manager.calculate_from_units(battle_manager.get_left_units())

	var should_show: bool = (run_controller.state == GameState.PREPARE or run_controller.state == GameState.BATTLE) and not shop_panel.visible
	_refresh_bond_buttons()
	call_deferred("_update_bond_panel_layout")
	bond_panel.visible = should_show
	if bond_detail_text != null:
		if selected_bond_id != "":
			bond_detail_text.text = bond_manager.get_bond_detail_text_for_bond(selected_bond_id)
		else:
			bond_detail_text.text = ""
	if not should_show:
		_hide_bond_detail_panel()


func _refresh_bond_buttons() -> void:
	if bond_buttons_vbox == null:
		return

	for child: Node in bond_buttons_vbox.get_children():
		bond_buttons_vbox.remove_child(child)
		child.queue_free()

	var bond_items: Array[Dictionary] = bond_manager.get_active_bond_button_data()
	if bond_items.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "羁绊：无"
		empty_label.custom_minimum_size = Vector2(170.0, 28.0)
		empty_label.add_theme_font_size_override("font_size", 15)
		empty_label.add_theme_color_override("font_color", Color(0.80, 0.86, 0.94, 1.0))
		bond_buttons_vbox.add_child(empty_label)
		selected_bond_id = ""
		_hide_bond_detail_panel()
		return

	var has_selected_bond: bool = false
	for item: Dictionary in bond_items:
		var bond_id: String = str(item.get("bond_id", ""))
		if bond_id == selected_bond_id:
			has_selected_bond = true
		var button: Button = Button.new()
		button.text = str(item.get("label", ""))
		button.custom_minimum_size = Vector2(170.0, 28.0)
		button.focus_mode = Control.FOCUS_NONE
		button.tooltip_text = "点击查看" + str(item.get("name", "")) + "羁绊详情"
		button.pressed.connect(_on_bond_name_pressed.bind(bond_id))
		button.add_theme_font_size_override("font_size", 14)
		_apply_bond_name_button_style(button, bond_id == selected_bond_id)
		bond_buttons_vbox.add_child(button)

	if selected_bond_id != "" and not has_selected_bond:
		selected_bond_id = ""
		_hide_bond_detail_panel()


func _update_bond_panel_layout() -> void:
	if bond_panel == null or shop_button == null:
		return

	var panel_position: Vector2 = shop_button.position + Vector2(0.0, shop_button.size.y + 10.0)
	bond_panel.position = panel_position

	var content_height: float = bond_buttons_vbox.position.y + bond_buttons_vbox.size.y + 12.0
	bond_panel.size = Vector2(190.0, maxf(content_height, 72.0))

	if bond_detail_panel != null:
		bond_detail_panel.position = panel_position + Vector2(202.0, 0.0)
		bond_detail_panel.size = Vector2(540.0, 480.0)


func _on_bond_name_pressed(bond_id: String) -> void:
	if bond_id == "":
		return
	if selected_bond_id == bond_id and bond_detail_panel != null and bond_detail_panel.visible:
		_hide_bond_detail_panel()
		selected_bond_id = ""
	else:
		selected_bond_id = bond_id
		_show_bond_detail_panel(bond_id)
	_refresh_bond_buttons()


func _show_bond_detail_panel(bond_id: String) -> void:
	if bond_detail_panel == null or bond_detail_text == null:
		return
	_update_bond_panel_layout()
	bond_detail_text.text = bond_manager.get_bond_detail_text_for_bond(bond_id)
	bond_detail_panel.visible = true


func _hide_bond_detail_panel() -> void:
	if bond_detail_panel != null:
		bond_detail_panel.visible = false


func _apply_bond_name_button_style(button: Button, is_selected: bool) -> void:
	var base_color: Color = Color(0.075, 0.13, 0.20, 0.96)
	var border_color: Color = Color(0.38, 0.55, 0.76, 0.88)
	if is_selected:
		base_color = Color(0.18, 0.30, 0.43, 0.98)
		border_color = Color(0.96, 0.72, 0.40, 0.96)
	PIXEL_UI_THEME.apply_button_style(button, base_color, border_color, 1, 14)


func _on_battle_speed_button_pressed() -> void:
	battle_time_manager.cycle_speed()
	_apply_current_battle_speed()
	_update_battle_speed_button()


func _on_grid_toggle_button_pressed() -> void:
	if battle_board == null or not is_instance_valid(battle_board):
		return
	if battle_board.has_method("toggle_grid_visible"):
		battle_board.toggle_grid_visible()
	_update_grid_toggle_button()


func _on_background_option_selected(index: int) -> void:
	_select_background(index)


func _on_main_menu_background_selected(index: int) -> void:
	_select_background(index)


func _select_background(index: int) -> void:
	selected_background_index = index
	if battle_board != null and is_instance_valid(battle_board) and battle_board.has_method("set_background_index"):
		battle_board.set_background_index(selected_background_index)
	if menu_panel_controller.has_method("set_background_index"):
		menu_panel_controller.set_background_index(selected_background_index)
	_update_background_switch_button()


func _apply_current_battle_speed() -> void:
	if battle_manager == null:
		return

	if battle_manager.has_method("set_battle_speed_multiplier"):
		battle_manager.set_battle_speed_multiplier(battle_time_manager.get_speed_value())


func _update_battle_speed_button() -> void:
	if battle_speed_button == null:
		return

	battle_speed_button.text = "速度 " + battle_time_manager.get_speed_label()
	battle_speed_button.tooltip_text = "点击切换战斗速度：" + battle_time_manager.get_speed_label()


func _update_battle_speed_button_visibility() -> void:
	if battle_speed_button == null:
		return

	battle_speed_button.visible = run_controller.state == GameState.PREPARE or run_controller.state == GameState.BATTLE or run_controller.state == GameState.TRAINING
	battle_speed_button.disabled = false
	_update_grid_toggle_button_visibility()


func _update_grid_toggle_button() -> void:
	if grid_toggle_button == null:
		return

	var is_grid_visible: bool = true
	if battle_board != null and is_instance_valid(battle_board) and battle_board.has_method("is_grid_visible"):
		is_grid_visible = bool(battle_board.is_grid_visible())
	grid_toggle_button.text = "网格 " + ("开" if is_grid_visible else "关")
	grid_toggle_button.tooltip_text = "切换棋盘网格显示：" + ("当前开启" if is_grid_visible else "当前关闭")


func _update_grid_toggle_button_visibility() -> void:
	if grid_toggle_button == null:
		return

	grid_toggle_button.visible = run_controller.state == GameState.PREPARE or run_controller.state == GameState.BATTLE or run_controller.state == GameState.TRAINING
	grid_toggle_button.disabled = false
	_update_background_switch_button_visibility()


func _update_background_switch_button() -> void:
	if background_switch_button == null:
		return

	var total_count: int = 1
	var current_index: int = 0
	var current_name: String = "背景 1"
	if battle_board != null and is_instance_valid(battle_board):
		if battle_board.has_method("get_background_count"):
			total_count = int(battle_board.get_background_count())
		if battle_board.has_method("get_current_background_index"):
			current_index = int(battle_board.get_current_background_index())
		if battle_board.has_method("get_current_background_name"):
			current_name = str(battle_board.get_current_background_name())

	if background_switch_button.item_count != total_count:
		_populate_background_selector()
	if background_switch_button.item_count > 0:
		background_switch_button.select(clampi(current_index, 0, background_switch_button.item_count - 1))
	background_switch_button.tooltip_text = "选择对战背景：" + current_name


func _populate_background_selector() -> void:
	if background_switch_button == null:
		return

	background_switch_button.clear()
	var total_count: int = 1
	if battle_board != null and is_instance_valid(battle_board) and battle_board.has_method("get_background_count"):
		total_count = int(battle_board.get_background_count())

	for index: int in range(total_count):
		var item_name: String = "背景 " + str(index + 1)
		if battle_board != null and is_instance_valid(battle_board) and battle_board.has_method("get_background_name"):
			item_name = str(battle_board.get_background_name(index))
		background_switch_button.add_item(item_name, index)


func _update_background_switch_button_visibility() -> void:
	if background_switch_button == null:
		return

	background_switch_button.visible = run_controller.state == GameState.PREPARE or run_controller.state == GameState.BATTLE or run_controller.state == GameState.TRAINING
	background_switch_button.disabled = false


func _create_mirror_info_ui() -> void:
	var ui_canvas_layer: CanvasLayer = $"UI CanvasLayer"
	if ui_canvas_layer == null:
		return

	mirror_info_button = Button.new()
	mirror_info_button.text = "镜像阵容"
	mirror_info_button.position = Vector2(24.0, 140.0)
	mirror_info_button.custom_minimum_size = Vector2(136.0, 36.0)
	mirror_info_button.visible = false
	mirror_info_button.z_index = UI_LAYER.MIRROR_INFO_BUTTON
	mirror_info_button.pressed.connect(_on_mirror_info_button_pressed)
	_apply_menu_button_style(mirror_info_button, Color(0.34, 0.30, 0.58, 1.0), Color(0.86, 0.80, 1.0, 1.0))
	ui_canvas_layer.add_child(mirror_info_button)

	mirror_info_panel = Panel.new()
	mirror_info_panel.visible = false
	mirror_info_panel.z_index = UI_LAYER.MIRROR_INFO_PANEL
	mirror_info_panel.anchor_left = 0.5
	mirror_info_panel.anchor_top = 0.5
	mirror_info_panel.anchor_right = 0.5
	mirror_info_panel.anchor_bottom = 0.5
	mirror_info_panel.offset_left = -380.0
	mirror_info_panel.offset_top = -260.0
	mirror_info_panel.offset_right = 380.0
	mirror_info_panel.offset_bottom = 260.0
	mirror_info_panel.add_theme_stylebox_override("panel", _create_panel_style(Color(0.07, 0.08, 0.10, 0.98), Color(0.62, 0.68, 0.88, 1.0), 8, 2))
	ui_canvas_layer.add_child(mirror_info_panel)

	var title_label: Label = Label.new()
	title_label.text = "镜像挑战阵容"
	title_label.position = Vector2(24.0, 18.0)
	title_label.size = Vector2(520.0, 32.0)
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(0.94, 0.92, 1.0, 1.0))
	mirror_info_panel.add_child(title_label)

	var close_button: Button = Button.new()
	close_button.text = "关闭"
	close_button.position = Vector2(650.0, 18.0)
	close_button.custom_minimum_size = Vector2(84.0, 32.0)
	close_button.pressed.connect(_hide_mirror_info_panel)
	_apply_menu_button_style(close_button, Color(0.24, 0.28, 0.32, 1.0), Color(0.72, 0.76, 0.82, 1.0))
	mirror_info_panel.add_child(close_button)

	mirror_info_text = RichTextLabel.new()
	mirror_info_text.position = Vector2(24.0, 66.0)
	mirror_info_text.size = Vector2(712.0, 430.0)
	mirror_info_text.fit_content = false
	mirror_info_text.scroll_active = true
	mirror_info_text.add_theme_font_size_override("normal_font_size", 16)
	mirror_info_text.add_theme_color_override("default_color", Color(0.88, 0.92, 0.96, 1.0))
	mirror_info_panel.add_child(mirror_info_text)


func _create_panel_style(bg_color: Color, border_color: Color, corner_radius: int, border_width: int) -> StyleBoxFlat:
	return PIXEL_UI_THEME.create_panel_style(bg_color, border_color, border_width, 8.0)


func _on_mirror_info_button_pressed() -> void:
	_show_mirror_info_panel()


func _show_mirror_info_panel() -> void:
	if mirror_info_panel == null or mirror_info_text == null:
		return

	mirror_info_text.text = mirror_challenge_manager.build_locked_preview_text(run_controller.max_round)
	mirror_info_panel.visible = true


func _hide_mirror_info_panel() -> void:
	if mirror_info_panel != null:
		mirror_info_panel.visible = false


func _update_mirror_info_button_visibility() -> void:
	if mirror_info_button == null:
		return

	mirror_info_button.visible = run_controller.is_mirror_challenge() \
		and run_controller.state == GameState.PREPARE \
		and mirror_challenge_manager != null


func _get_battle_result_display_text(result_text: String, player_won: bool) -> String:
	if result_text == "Draw":
		return "平局"
	if player_won:
		return "战斗胜利"

	return "战斗失败"


func _enter_hero_selection_state() -> void:
	run_controller.enter_hero_selection()
	result_label.text = "选择英雄"
	round_label.text = ""
	_update_battle_speed_button_visibility()
	_update_hero_exp_ui()
	menu_button.visible = true
	_set_board_bench_visible(false)
	_hide_prepare_action_buttons()
	_hide_encounter_info_panel()
	_hide_shop_panel()
	_hide_bench_panel()
	_hide_reward_panel()
	_hide_unit_detail_panel()
	_hide_relic_detail_panel()
	_hide_mirror_info_panel()
	_refresh_relic_bar()
	_set_start_button_state("请选择英雄", false)
	_show_hero_selection_panel()


func _enter_prepare_state() -> void:
	if unit_scene == null:
		result_label.text = "单位场景缺失"
		push_warning("Unit scene is not assigned on Main.")
		return

	if not _has_required_unit_data():
		result_label.text = "单位数据缺失"
		push_warning("All unit data resources must be assigned on Main.")
		return

	if not hero_manager.has_selected_hero():
		_enter_hero_selection_state()
		return

	run_controller.enter_prepare()
	last_result_text = ""
	last_player_won = false
	relic_manager.reset_battle_stats()
	result_label.text = "准备阶段"
	menu_button.visible = true
	shop_manager.roll_shop_items()
	_update_round_label()
	_update_battle_speed_button()
	_update_battle_speed_button_visibility()
	_refresh_bond_panel()
	_update_gold_label()
	_update_hero_exp_ui()
	_set_board_bench_visible(true)
	_set_board_visible(true)
	_show_encounter_info_panel()
	_show_prepare_action_buttons()
	_hide_shop_panel()
	_hide_bench_panel()
	stats_label.text = ""
	_hide_reward_panel()
	_hide_unit_detail_panel()
	_hide_mirror_info_panel()
	_refresh_relic_bar()
	_set_start_button_state("开始战斗", true)
	DEBUG_LOG_SCRIPT.info(encounter_manager.get_encounter_debug_text(run_controller.current_round))
	relic_manager.print_player_relics()

	var player_unit_configs: Array[Dictionary] = roster_manager.get_player_battle_unit_configs(battle_board, _get_reserved_hero_cells_for_roster())
	var enemy_unit_configs: Array[Dictionary] = encounter_manager.get_enemy_unit_configs(run_controller.current_round)
	var bench_unit_configs: Array[Dictionary] = roster_manager.get_bench_unit_configs(battle_board)
	battle_manager.setup(self, unit_scene, stats_manager, relic_manager, battle_board, Callable(self, "_on_prepare_unit_drop_requested"), hero_manager, bond_manager)
	battle_manager.set_roster_manager(roster_manager)
	battle_manager.set_enemy_relic_manager(_create_mirror_enemy_relic_manager_for_current_round())
	battle_manager.spawn_battle(player_unit_configs, enemy_unit_configs, bench_unit_configs)
	_refresh_bond_panel()


func start_battle() -> void:
	if run_controller.state != GameState.PREPARE:
		return

	var current_encounter: Dictionary = encounter_manager.get_encounter(run_controller.current_round)
	var is_training: bool = str(current_encounter.get("encounter_type", "")) == "TRAINING"

	_save_player_start_positions()
	if is_training:
		_enter_training_state()
	else:
		run_controller.enter_battle()
	result_label.text = "训练场 - 战斗中" if is_training else "战斗开始"
	battle_time_manager.reset_battle_clock()
	_apply_current_battle_speed()
	_update_round_label()
	_update_battle_speed_button_visibility()
	_refresh_bond_panel()
	_update_gold_label()
	_update_hero_exp_ui()
	_set_board_bench_visible(false)
	_hide_prepare_action_buttons()
	_hide_encounter_info_panel()
	_hide_shop_panel()
	_hide_bench_panel()
	_hide_reward_panel()
	_hide_unit_detail_panel()
	_hide_mirror_info_panel()
	_refresh_relic_bar()
	_set_start_button_state("训练中" if is_training else "战斗中", false)
	battle_manager.start_battle()
	_refresh_bond_panel()


func _has_required_unit_data() -> bool:
	return warrior_data != null \
		and archer_data != null \
		and assassin_data != null \
		and tank_data != null \
		and mage_data != null \
		and priest_data != null \
		and bard_data != null \
		and forest_druid_data != null \
		and plague_caster_data != null \
		and guardian_captain_data != null \
		and wind_chanter_data != null \
		and greatsword_knight_data != null \
		and bomb_thrower_data != null \
		and cleric_data != null \
		and alchemist_data != null \
		and necromancer_data != null \
		and puppet_warlock_data != null


func _on_start_button_pressed() -> void:
	if run_controller.state == GameState.PREPARE:
		start_battle()


func _on_battle_ended(result_text: String, player_won: bool) -> void:
	if run_controller.state == GameState.TRAINING:
		_on_training_timer_expired()
		return
	var encounter_type: String = _get_current_encounter_type()
	gold_relic_logs.clear()
	if player_won:
		var pre_reward_gold: int = economy_manager.gold
		var base_reward: int = _get_victory_gold_reward(encounter_type)
		var is_final_boss: bool = encounter_type == "BOSS" and run_controller.is_final_boss_victory(encounter_type)
		var round_reward_result: Dictionary = {}
		if not is_final_boss:
			round_reward_result = relic_manager.trigger_round_reward_relics(encounter_type, run_controller.current_round, run_controller.max_round, pre_reward_gold, base_reward)
		var extra_gold: int = int(round_reward_result.get("extra_gold", 0))
		var logs: PackedStringArray = round_reward_result.get("logs", PackedStringArray()) as PackedStringArray
		for log_line: String in logs:
			gold_relic_logs.append(log_line)
		var total_gold: int = base_reward + extra_gold
		if total_gold > 0:
			_add_gold(total_gold)
			var log_text: String = _get_victory_gold_reward_debug_text(encounter_type, base_reward)
			if extra_gold > 0:
				log_text += "，遗物额外金币：" + ", ".join(logs)
			log_text += "，金币 +" + str(total_gold) + "，当前金币：" + str(economy_manager.gold)
			DEBUG_LOG_SCRIPT.info(log_text)

	_show_battle_statistics(result_text)
	if player_won and encounter_type == "BOSS":
		_save_boss_victory_lineup_snapshot()

	if player_won and run_controller.is_final_boss_victory(encounter_type):
		_enter_game_over_state("Victory - Run Cleared")
		return

	if not player_won:
		_enter_game_over_state(_get_failure_game_over_text(result_text))
		return

	if _try_enter_hero_upgrade_state(result_text, player_won, encounter_type):
		return

	_enter_reward_state(result_text, player_won)


func _on_overtime_started() -> void:
	if run_controller.state != GameState.BATTLE:
		return

	result_label.text = "进入加时赛！"
	stats_label.text = "60 秒已到，进入加时赛\n全体攻击力 x2，攻击速度 x2\n所有存活单位每秒承受递增伤害"
	DEBUG_LOG_SCRIPT.info("Overtime: started after 60 seconds. Attack damage x2, attack speed x2, escalating damage started.")


var _battle_stats_text: String = ""
var _battle_stats_units: Array = []
var _battle_stats_duration: float = 0.0
var _battle_stats_relic_damage: int = 0
var _stats_button: Button = null


func _show_battle_statistics(result_text: String) -> void:
	_battle_stats_text = stats_manager.build_statistics_by_team(relic_manager.relic_damage_dealt)
	_battle_stats_units = stats_manager.get_all_unit_stats().duplicate(true)
	_battle_stats_duration = float(stats_manager.battle_duration)
	_battle_stats_relic_damage = int(relic_manager.relic_damage_dealt)
	stats_label.text = ""


func _save_boss_victory_lineup_snapshot() -> void:
	var encounter: Dictionary = encounter_manager.get_encounter(run_controller.current_round) as Dictionary
	var snapshot: Dictionary = lineup_snapshot_manager.save_boss_victory_snapshot(
		roster_manager,
		relic_manager,
		economy_manager,
		run_controller,
		encounter
	)
	if snapshot.is_empty():
		push_warning("Boss victory lineup snapshot was not saved.")
		return

	DEBUG_LOG_SCRIPT.info("Saved boss victory lineup snapshot: " + str(snapshot.get("snapshot_id", "")))


func _enter_result_state(result_text: String, player_won: bool) -> void:
	if player_won:
		_enter_reward_state(result_text, player_won)
	else:
		_enter_game_over_state(_get_failure_game_over_text(result_text))


func _try_enter_hero_upgrade_state(result_text: String, player_won: bool, encounter_type: String) -> bool:
	if not player_won:
		return false

	var did_level_up: bool = hero_manager.process_victory_encounter(run_controller.current_round, encounter_type)
	_update_hero_exp_ui()
	if not did_level_up:
		return false

	var upgrade_options: Array[Dictionary] = hero_manager.get_pending_upgrade_options()
	if upgrade_options.is_empty():
		return false

	pending_post_hero_upgrade_result_text = result_text
	pending_post_hero_upgrade_player_won = player_won
	run_controller.enter_reward()
	result_label.text = "英雄升级 Lv." + str(hero_manager.hero_level) + " - 选择强化"
	_hide_encounter_info_panel()
	_set_board_bench_visible(false)
	_hide_prepare_action_buttons()
	_hide_shop_panel()
	_hide_bench_panel()
	_hide_unit_detail_panel()
	_hide_mirror_info_panel()
	_refresh_relic_bar()
	_update_gold_label()
	_update_hero_exp_ui()
	_set_start_button_state("请选择英雄强化", false)
	reward_panel_controller.show_hero_upgrade_panel(upgrade_options)
	_update_battle_speed_button_visibility()
	return true


func _on_hero_upgrade_selected(upgrade: Dictionary) -> void:
	if run_controller.state != GameState.REWARD:
		return

	if not hero_manager.apply_hero_upgrade(upgrade):
		result_label.text = "英雄强化选择失败"
		return

	_hide_reward_panel()
	var result_text: String = pending_post_hero_upgrade_result_text
	var player_won: bool = pending_post_hero_upgrade_player_won
	pending_post_hero_upgrade_result_text = ""
	pending_post_hero_upgrade_player_won = false
	_enter_reward_state(result_text, player_won)


func _enter_reward_state(result_text: String = "", player_won: bool = true) -> void:
	if not player_won:
		return

	last_result_text = result_text
	last_player_won = true
	run_controller.enter_reward()
	result_label.text = _get_battle_result_display_text(result_text, true) + " - 选择奖励"
	_update_battle_speed_button_visibility()
	_hide_encounter_info_panel()
	_set_board_bench_visible(false)
	_hide_prepare_action_buttons()
	_hide_shop_panel()
	_hide_bench_panel()
	_hide_unit_detail_panel()
	_hide_mirror_info_panel()
	_refresh_relic_bar()
	_update_gold_label()
	_update_hero_exp_ui()
	_set_start_button_state("请选择", false)
	_show_reward_panel()
	_show_stats_button()


func _try_enter_path_select_or_next_prepare() -> void:
	var next_round: int = run_controller.current_round + 1
	if next_round % 10 == 0:
		_enter_forced_path_select_state("BOSS")
		return
	if next_round % 5 == 0:
		_enter_forced_path_select_state("ELITE")
		return
	_enter_path_select_state()


func _enter_forced_path_select_state(forced_type: String) -> void:
	run_controller.enter_path_select()
	result_label.text = "前方强敌"
	stats_label.text = ""
	_update_round_label()
	_update_battle_speed_button_visibility()
	_set_start_button_state("选择路径", false)
	_set_board_visible(false)
	battle_manager.clear_battlefield()
	_hide_prepare_action_buttons()
	_hide_shop_panel()
	_hide_bench_panel()
	_hide_encounter_info_panel()
	_hide_reward_panel()
	_hide_unit_detail_panel()
	_hide_mirror_info_panel()
	var candidate: Dictionary = {
		"node_type": forced_type,
		"display_name": path_selection_manager.DISPLAY_NAMES.get(forced_type, forced_type),
		"description": path_selection_manager.DESCRIPTIONS.get(forced_type, ""),
		"rarity_hint": "EPIC" if forced_type == "BOSS" else "RARE",
	}
	_show_path_selection_panel([candidate])


func _enter_path_select_state() -> void:
	run_controller.enter_path_select()
	result_label.text = "选择下一站"
	stats_label.text = ""
	_update_round_label()
	_update_battle_speed_button_visibility()
	_set_start_button_state("选择路径", false)
	_set_board_visible(false)
	battle_manager.clear_battlefield()
	_hide_prepare_action_buttons()
	_hide_shop_panel()
	_hide_bench_panel()
	_hide_encounter_info_panel()
	_hide_reward_panel()
	_hide_unit_detail_panel()
	_hide_mirror_info_panel()
	var candidates: Array[Dictionary] = path_selection_manager.generate_candidates(
		run_controller.current_round, run_controller.path_history
	)
	_show_path_selection_panel(candidates)


func _on_path_selected(candidate: Dictionary) -> void:
	if run_controller.state != GameState.PATH_SELECT:
		return
	var node_type: String = candidate.get("node_type", "NORMAL")
	run_controller.record_path_choice(node_type)
	_hide_path_selection_panel()

	run_controller.advance_round()
	if run_controller.has_cleared_round_limit():
		_enter_game_over_state("Victory - Run Cleared")
		return

	match node_type:
		"NORMAL":
			encounter_manager.forced_encounter_type = "NORMAL"
			_show_transition(Callable(self, "_enter_prepare_state"))
		"ELITE":
			encounter_manager.forced_encounter_type = "ELITE"
			_show_transition(Callable(self, "_enter_prepare_state"))
		"BOSS":
			encounter_manager.forced_encounter_type = "BOSS"
			_show_transition(Callable(self, "_enter_prepare_state"))
		"MERCHANT":
			_show_transition(Callable(self, "_enter_merchant_state"))
		"TRAINING":
			var enc: Dictionary = training_manager.create_training_encounter(run_controller.current_round)
			encounter_manager.set_override_encounter(run_controller.current_round, enc)
			_show_transition(Callable(self, "_enter_prepare_state"))
		"EVENT":
			_show_transition(Callable(self, "_enter_event_state"))
		"TREASURE":
			_show_transition(Callable(self, "_enter_treasure_state"))
		_:
			_show_transition(Callable(self, "_enter_prepare_state"))


func _show_path_selection_panel(candidates: Array[Dictionary]) -> void:
	path_selection_panel_controller.show_panel(candidates)


func _hide_path_selection_panel() -> void:
	path_selection_panel_controller.hide_panel()


func _enter_merchant_state() -> void:
	run_controller.enter_merchant()
	result_label.text = ""
	stats_label.text = ""
	_update_round_label()
	_update_battle_speed_button_visibility()
	_set_start_button_state("商人", false)
	_set_board_visible(false)
	_hide_prepare_action_buttons()
	_hide_shop_panel()
	_hide_bench_panel()
	_hide_encounter_info_panel()
	_hide_reward_panel()
	_hide_unit_detail_panel()
	_hide_mirror_info_panel()
	_show_merchant_panel()


func _show_merchant_panel() -> void:
	merchant_panel_controller.show_panel()


func _hide_merchant_panel() -> void:
	merchant_panel_controller.hide_panel()


func _on_merchant_item_purchased(item: Dictionary) -> void:
	var item_type: String = item.get("type", "")
	var popup_text: String = ""
	if item_type == "relic":
		var relic_data: Variant = item.get("relic_data", null)
		if relic_data != null:
			relic_manager.add_relic(relic_data)
			_refresh_relic_bar()
			var relic_name: String = _get_relic_name_cn(relic_data)
			popup_text = "[center]购买成功[/center]\n\n获得遗物：" + relic_name
	elif item_type == "buff":
		var buff_data: Dictionary = item.get("buff_data", {})
		_apply_merchant_buff(buff_data)
		var buff_name: String = buff_data.get("name_cn", "全局强化")
		var buff_desc: String = buff_data.get("description_cn", "")
		popup_text = "[center]购买成功[/center]\n\n获得全局强化：" + buff_name + "\n" + buff_desc
	elif item_type == "unit":
		var unit_name: String = _add_merchant_high_rarity_unit()
		if unit_name != "":
			popup_text = "[center]购买成功[/center]\n\n获得单位：" + unit_name
	elif item_type == "population":
		pass
	_update_gold_label()
	_refresh_bench_panel()
	if popup_text != "":
		_show_popup(popup_text)


func _on_merchant_leave() -> void:
	_hide_merchant_panel()
	_try_enter_path_select_or_next_prepare()


func _apply_merchant_buff(buff_data: Dictionary) -> void:
	var stat: String = buff_data.get("stat", "")
	var ratio: float = float(buff_data.get("ratio", 0.0))
	var mode: String = buff_data.get("mode", "percent")
	if stat == "death_prevention":
		roster_manager.has_death_prevention = true
		return
	if stat == "":
		return
	if mode == "percent":
		roster_manager.apply_permanent_percent_bonus(stat, ratio)
	elif mode == "flat":
		roster_manager.apply_permanent_flat_bonus(stat, ratio)


func _add_merchant_high_rarity_unit() -> String:
	var pool: Array[Resource] = roster_manager.get_high_rarity_unit_pool("RARE")
	if pool.is_empty():
		pool = roster_manager.get_all_unit_pool()
	if pool.is_empty():
		return ""
	var selected: Resource = pool[randi() % pool.size()]
	if not roster_manager.is_unit_unlocked(selected):
		roster_manager.unlock_unit_data(selected)
	roster_manager.add_unit(selected)
	var name_cn: Variant = selected.get("unit_name_cn")
	if name_cn != null and str(name_cn) != "" and str(name_cn) != "<null>":
		return str(name_cn)
	return str(selected.get("unit_name"))


func _setup_training_manager() -> void:
	training_manager.setup(relic_manager, roster_manager, economy_manager)
	battle_manager.enemy_unit_died.connect(_on_training_enemy_died)


func _enter_training_state() -> void:
	run_controller.enter_training()
	training_manager.start_training()
	result_label.text = "训练场 - 战斗中"
	_update_battle_speed_button_visibility()
	_set_start_button_state("训练中", false)


func _on_training_enemy_died(_unit: Unit) -> void:
	if run_controller.state != GameState.TRAINING:
		return
	var drop: Dictionary = training_manager.on_dummy_killed()
	var display: String = drop.get("display", "")
	if display != "":
		DEBUG_LOG_SCRIPT.info("[训练场掉落] " + display)
	_update_gold_label()
	_refresh_relic_bar()


func _on_training_timer_expired() -> void:
	if not training_manager.is_training_active and run_controller.state != GameState.TRAINING:
		return
	training_manager.end_training()
	battle_manager.force_end_battle()
	var drops: Array[Dictionary] = training_manager.get_drops_collected()
	var summary_lines: Array[String] = ["[center]训练结束！[/center]", ""]
	for drop: Dictionary in drops:
		summary_lines.append("· " + drop.get("display", ""))
	summary_lines.append("")
	summary_lines.append("共获得 " + str(drops.size()) + " 个奖励")
	DEBUG_LOG_SCRIPT.info("[训练场] " + "训练结束，获得 " + str(drops.size()) + " 个奖励")
	_set_board_bench_visible(true)
	_update_gold_label()
	_refresh_relic_bar()
	_show_popup("\n".join(summary_lines), Callable(self, "_on_training_summary_confirmed"))


func _enter_treasure_state() -> void:
	run_controller.enter_treasure()
	result_label.text = ""
	stats_label.text = ""
	_update_round_label()
	_update_battle_speed_button_visibility()
	_set_board_visible(false)
	_hide_prepare_action_buttons()
	_hide_shop_panel()
	_hide_bench_panel()
	_hide_encounter_info_panel()
	_hide_reward_panel()
	_hide_unit_detail_panel()
	_hide_mirror_info_panel()
	_pending_treasure_relic = _roll_treasure_relic()
	if _pending_treasure_relic != null:
		var relic_name: String = _get_relic_name_cn(_pending_treasure_relic)
		var relic_desc: String = _get_relic_description_cn(_pending_treasure_relic)
		var relic_rarity: String = _get_relic_rarity_str(_pending_treasure_relic)
		var text: String = "[center]宝箱[/center]\n\n获得遗物：[b]" + relic_name + "[/b]  [" + relic_rarity + "]\n" + relic_desc
		_show_popup(text, Callable(self, "_on_treasure_confirmed"))
	else:
		_show_popup("[center]宝箱[/center]\n\n宝箱为空，获得 10 金币", Callable(self, "_on_treasure_confirmed"))


func _on_treasure_confirmed() -> void:
	if _pending_treasure_relic != null:
		relic_manager.add_relic(_pending_treasure_relic)
		var relic_name: String = _get_relic_name_cn(_pending_treasure_relic)
		DEBUG_LOG_SCRIPT.info("[宝箱] 获得遗物: " + relic_name)
		_refresh_relic_bar()
	else:
		economy_manager.add_gold(10)
		DEBUG_LOG_SCRIPT.info("[宝箱] 无可用遗物，获得 10 金币")
	_pending_treasure_relic = null
	_update_gold_label()
	_try_enter_path_select_or_next_prepare()


func _on_training_summary_confirmed() -> void:
	_try_enter_path_select_or_next_prepare()


func _show_popup(text: String, callback: Callable = Callable()) -> void:
	var popup_style: StyleBoxFlat = StyleBoxFlat.new()
	popup_style.bg_color = Color(0.06, 0.08, 0.12, 0.98)
	popup_style.set_border_width_all(2)
	popup_style.border_color = Color(0.50, 0.67, 0.88, 0.88)
	popup_style.set_corner_radius_all(8)
	event_panel.add_theme_stylebox_override("panel", popup_style)
	event_panel.z_index = UI_LAYER.FLOATING_POPUP + 10
	event_panel.offset_left = -440.0
	event_panel.offset_right = 440.0
	event_panel.offset_top = -310.0
	event_panel.offset_bottom = 310.0
	event_panel.visible = true
	event_title_label.text = ""
	event_text_label.visible = false
	event_choice_button_1.visible = false
	event_choice_button_2.visible = false
	event_result_label.offset_left = 20.0
	event_result_label.offset_right = 860.0
	event_result_label.offset_top = 40.0
	event_result_label.offset_bottom = 480.0
	event_result_label.text = text
	event_result_label.visible = true
	event_continue_button.offset_top = 460.0
	event_continue_button.offset_bottom = 500.0
	event_continue_button.visible = true
	PIXEL_UI_THEME.apply_button_style(event_continue_button, Color(0.15, 0.25, 0.15), Color(0.35, 0.60, 0.35), 2)
	is_popup_active = true
	_popup_callback = callback


func _on_popup_confirmed() -> void:
	is_popup_active = false
	event_panel.visible = false
	event_panel.z_index = 0
	event_panel.offset_left = -380.0
	event_panel.offset_right = 380.0
	event_panel.offset_top = -260.0
	event_panel.offset_bottom = 260.0
	event_result_label.offset_left = 36.0
	event_result_label.offset_right = 724.0
	event_result_label.offset_top = 220.0
	event_result_label.offset_bottom = 340.0
	event_result_label.text = ""
	event_result_label.visible = false
	event_continue_button.offset_top = 400.0
	event_continue_button.offset_bottom = 440.0
	event_continue_button.visible = false
	var callback: Callable = _popup_callback
	_popup_callback = Callable()
	if not callback.is_null():
		callback.call()


func _get_relic_name_cn(relic_data: Variant) -> String:
	if relic_data == null:
		return "未知遗物"
	var name_cn: Variant = relic_data.get("relic_name_cn")
	if name_cn != null and str(name_cn) != "" and str(name_cn) != "<null>":
		return str(name_cn)
	var name_en: Variant = relic_data.get("relic_name")
	if name_en != null:
		return str(name_en)
	return "遗物"


func _get_relic_description_cn(relic_data: Variant) -> String:
	if relic_data == null:
		return ""
	var desc_cn: Variant = relic_data.get("description_cn")
	if desc_cn != null and str(desc_cn) != "" and str(desc_cn) != "<null>":
		return str(desc_cn)
	var desc: Variant = relic_data.get("description")
	if desc != null:
		return str(desc)
	return ""


func _get_relic_rarity_str(relic_data: Variant) -> String:
	if relic_data == null:
		return ""
	var rarity: Variant = relic_data.get("rarity")
	if rarity == null:
		return ""
	match str(rarity):
		"COMMON":
			return "普通"
		"FINE":
			return "精良"
		"RARE":
			return "稀有"
		"EPIC":
			return "史诗"
		"LEGENDARY":
			return "传说"
		"MYTHIC":
			return "神话"
		_:
			return str(rarity)


func _roll_treasure_relic() -> Variant:
	var all_options: Array = relic_manager.get_available_relic_reward_options()
	if all_options.is_empty():
		return null
	var rare_pool: Array[Dictionary] = []
	var epic_pool: Array[Dictionary] = []
	var legendary_pool: Array[Dictionary] = []
	for option: Dictionary in all_options:
		var rarity: String = str(option.get("rarity", ""))
		match rarity:
			"RARE":
				rare_pool.append(option)
			"EPIC":
				epic_pool.append(option)
			"LEGENDARY":
				legendary_pool.append(option)
	var roll: int = randi() % 100
	var selected_pool: Array[Dictionary] = []
	if roll < 50 and not rare_pool.is_empty():
		selected_pool = rare_pool
	elif roll < 85 and not epic_pool.is_empty():
		selected_pool = epic_pool
	elif not legendary_pool.is_empty():
		selected_pool = legendary_pool
	else:
		selected_pool = rare_pool if not rare_pool.is_empty() else epic_pool if not epic_pool.is_empty() else legendary_pool
	if selected_pool.is_empty():
		if not all_options.is_empty():
			return all_options[randi() % all_options.size()].get("relic_data", null)
		return null
	return selected_pool[randi() % selected_pool.size()].get("relic_data", null)


func _setup_event_manager() -> void:
	event_manager.setup(relic_manager, roster_manager, economy_manager)
	var choice_buttons: Array[Button] = []
	choice_buttons.append(event_choice_button_1)
	choice_buttons.append(event_choice_button_2)
	event_panel_controller.setup(
		event_panel, event_title_label, event_text_label,
		choice_buttons, event_result_label, event_continue_button,
		event_manager
	)
	event_panel_controller.choice_resolved.connect(_on_event_choice_resolved)
	event_panel_controller.continue_pressed.connect(_on_event_continue_pressed)


func _setup_transition_panel() -> void:
	transition_panel_controller.setup(
		transition_panel, transition_background,
		transition_round_label, transition_node_type_label, transition_description_label
	)


func _show_transition(on_complete: Callable = Callable()) -> void:
	var current_round: int = run_controller.current_round
	var pending: String = run_controller.pending_node_type
	var node_display: String
	var node_desc: String

	# For combat nodes, always check the actual encounter — pending can be stale (e.g. forced Boss)
	if pending == "NORMAL" or pending == "ELITE" or pending == "BOSS" or pending == "":
		var encounter: Dictionary = encounter_manager.get_encounter(current_round)
		var enc_type: String = str(encounter.get("encounter_type", ""))
		match enc_type:
			"BOSS":
				node_display = "Boss 战"
				node_desc = "击败强大的 Boss，推进进度。"
			"ELITE":
				node_display = "精英战斗"
				node_desc = "挑战精英敌人，获得丰厚奖励。"
			"TRAINING":
				node_display = "训练场"
				node_desc = "限时击杀木桩，获取掉落的奖励。"
			_:
				node_display = "普通战斗"
				node_desc = "与敌人战斗，获得金币和奖励。"
	else:
		match pending:
			"MERCHANT":
				node_display = "商人"
				node_desc = "购买遗物、强化和人口。"
			"EVENT":
				node_display = "随机事件"
				node_desc = "遭遇随机事件，做出选择。"
			"TREASURE":
				node_display = "宝箱"
				node_desc = "打开宝箱，获得一件遗物。"
			"TRAINING":
				node_display = "训练场"
				node_desc = "限时击杀木桩，获取掉落的奖励。"
			_:
				node_display = "普通战斗"
				node_desc = "与敌人战斗，获得金币和奖励。"

	transition_panel_controller.show_transition(current_round, pending, node_display, node_desc, on_complete)


func _enter_event_state() -> void:
	run_controller.enter_event()
	result_label.text = ""
	stats_label.text = ""
	_update_round_label()
	_update_battle_speed_button_visibility()
	_set_start_button_state("事件", false)
	_set_board_visible(false)
	_hide_prepare_action_buttons()
	_hide_shop_panel()
	_hide_bench_panel()
	_hide_encounter_info_panel()
	_hide_reward_panel()
	_hide_unit_detail_panel()
	_hide_mirror_info_panel()
	var event: Dictionary = event_manager.get_random_event(run_controller.current_round)
	event_panel_controller.show_panel(event)


func _on_event_choice_resolved(result: Dictionary) -> void:
	var pending_relic: bool = result.get("pending_relic_choice", false)
	if pending_relic:
		_show_event_relic_choice()
	_update_gold_label()
	_refresh_relic_bar()
	_refresh_bench_panel()


func _show_event_relic_choice() -> void:
	event_panel.visible = false
	var rarity_pool: Array[String] = ["EPIC"]
	var current_event: Dictionary = event_manager.get_current_event()
	var choices: Array = current_event.get("choices", [])
	for choice: Dictionary in choices:
		var effects: Array = choice.get("effects", [])
		for effect: Dictionary in effects:
			if effect.get("effect_id", "") == "relic_choice_3":
				var params: Dictionary = effect.get("params", {})
				var pool: Array = params.get("rarity_pool", ["EPIC"])
				rarity_pool.clear()
				for r: Variant in pool:
					rarity_pool.append(str(r))
	var all_options: Array = relic_manager.get_available_relic_reward_options()
	var filtered: Array[Dictionary] = []
	for option: Dictionary in all_options:
		if str(option.get("rarity", "")) in rarity_pool:
			filtered.append(option)
	if filtered.size() < 3:
		filtered.clear()
		for option: Dictionary in all_options:
			filtered.append(option)
	var reward_options: Array[Dictionary] = []
	var used_indices: Array[int] = []
	for i: int in range(mini(3, filtered.size())):
		var idx: int = randi() % filtered.size()
		while idx in used_indices and used_indices.size() < filtered.size():
			idx = randi() % filtered.size()
		used_indices.append(idx)
		var option: Dictionary = filtered[idx]
		reward_options.append({
			"type": "RELIC",
			"name": option.get("name", "遗物"),
			"description": option.get("description", ""),
			"rarity": option.get("rarity", "RARE"),
			"relic_data": option.get("relic_data", null),
		})
	if reward_options.is_empty():
		economy_manager.add_gold(8)
		_update_gold_label()
		return
	reward_panel_controller.show_custom_options(reward_options)


func _on_event_continue_pressed() -> void:
	if is_popup_active:
		_on_popup_confirmed()
		return
	_hide_event_panel()
	_try_enter_path_select_or_next_prepare()


func _hide_event_panel() -> void:
	event_panel_controller.hide_panel()



func _enter_game_over_state(game_over_text: String) -> void:
	run_controller.enter_game_over()
	result_label.text = menu_panel_controller.get_game_end_title(game_over_text)
	_update_battle_speed_button_visibility()
	_update_round_label()
	_update_gold_label()
	_set_board_bench_visible(false)
	_hide_prepare_action_buttons()
	_hide_encounter_info_panel()
	_hide_shop_panel()
	_hide_bench_panel()
	_hide_reward_panel()
	_hide_path_selection_panel()
	_hide_event_panel()
	_hide_unit_detail_panel()
	_hide_mirror_info_panel()
	_refresh_relic_bar()
	_update_hero_exp_ui()
	_set_start_button_state("挑战结束", false)
	menu_button.visible = false
	_show_game_end_dialog(game_over_text)


func _get_failure_game_over_text(result_text: String = "") -> String:
	var safe_result_text: String = result_text if result_text.strip_edges() != "" else last_result_text
	if safe_result_text == "Draw":
		return "Draw - Game Over"

	return "Defeat"


func _restart_run(selected_game_mode: String = "") -> void:
	menu_panel_controller.hide_main_menu()
	_hide_game_end_dialog()
	_hide_gameplay_menu()
	_hide_encyclopedia_panel()
	_set_board_visible(true)
	_set_gameplay_ui_visible(true)
	battle_time_manager.reset_for_run()
	_apply_current_battle_speed()
	var next_game_mode: String = selected_game_mode
	if next_game_mode == "":
		next_game_mode = run_controller.game_mode
	run_controller.start_run(next_game_mode)
	dynamic_stat_refresh_pending = false
	economy_manager.reset()
	last_result_text = ""
	last_player_won = false
	pending_post_hero_upgrade_result_text = ""
	pending_post_hero_upgrade_player_won = false
	battle_manager.clear_battlefield()
	stats_manager.clear()
	roster_manager.setup(warrior_data, archer_data, assassin_data, tank_data, mage_data, priest_data, bard_data, forest_druid_data, plague_caster_data, guardian_captain_data, wind_chanter_data, greatsword_knight_data, bomb_thrower_data, cleric_data, alchemist_data, necromancer_data, puppet_warlock_data)
	roster_manager.max_active_units = INITIAL_MAX_ACTIVE_UNITS
	roster_manager.max_total_units = MAX_TOTAL_UNITS
	roster_manager.reset_roster()
	encounter_manager.setup(warrior_data, archer_data, assassin_data, tank_data, mage_data, priest_data, bard_data)
	encounter_manager.use_random_encounters = use_random_encounters
	shop_manager.setup(warrior_data, archer_data, assassin_data, tank_data, mage_data, priest_data, bard_data, forest_druid_data, plague_caster_data, guardian_captain_data, wind_chanter_data, greatsword_knight_data, bomb_thrower_data, cleric_data, alchemist_data, necromancer_data, puppet_warlock_data, relic_manager, roster_manager)
	reward_manager.setup(relic_manager, roster_manager)
	relic_manager.clear_relics()
	hero_manager.reset_hero()
	bond_manager.clear()
	_prepare_mirror_challenge_for_run()
	_hide_relic_detail_panel()
	_hide_hero_selection_panel()
	_hide_mirror_info_panel()
	_refresh_relic_bar()
	_enter_hero_selection_state()


func _prepare_mirror_challenge_for_run() -> void:
	mirror_challenge_manager.clear_challenge()
	encounter_manager.clear_mirror_boss_encounters()
	mirror_enemy_relic_manager = null
	if not run_controller.is_mirror_challenge():
		return

	mirror_challenge_manager.prepare_challenge(run_controller.max_round)
	encounter_manager.set_mirror_boss_encounters(mirror_challenge_manager.get_mirror_encounters())


func _create_mirror_enemy_relic_manager_for_current_round() -> RelicManager:
	mirror_enemy_relic_manager = null
	if not run_controller.is_mirror_challenge():
		return null

	var relic_ids: Array[String] = mirror_challenge_manager.get_relic_ids_for_round(run_controller.current_round)
	if relic_ids.is_empty():
		return null

	mirror_enemy_relic_manager = RelicManager.new()
	mirror_enemy_relic_manager.set_owner_team_id(2)
	mirror_enemy_relic_manager.set_battle_gold_context(mirror_challenge_manager.get_snapshot_gold_for_round(run_controller.current_round))
	mirror_enemy_relic_manager.restore_relic_ids(relic_ids)
	return mirror_enemy_relic_manager


func _update_round_label() -> void:
	if run_controller.current_round > run_controller.max_round:
		round_label.text = "已通关"
		return
	round_label.text = "第 " + str(run_controller.current_round) + " / " + str(run_controller.max_round) + " 轮"
	if run_controller.is_mirror_challenge():
		round_label.text += " - 镜像挑战"
	# Only append encounter info for combat states — avoids generating encounters for non-combat rounds
	if run_controller.state == GameState.PREPARE or run_controller.state == GameState.BATTLE or run_controller.state == GameState.TRAINING:
		var encounter: Dictionary = encounter_manager.get_encounter(run_controller.current_round) as Dictionary
		if not encounter.is_empty():
			round_label.text += " - " + _format_encounter_type(str(encounter["encounter_type"]))
			round_label.text += ": " + _get_encounter_display_name(str(encounter["encounter_name"]))
			round_label.text += "  敌人倍率 x" + _format_multiplier(float(encounter["enemy_hp_multiplier"]))


func _update_hero_exp_ui() -> void:
	if hero_exp_panel == null:
		return

	var should_show: bool = hero_manager.has_selected_hero() and run_controller.state != GameState.MAIN_MENU and run_controller.state != GameState.HERO_SELECTION
	hero_exp_panel.visible = should_show
	if not should_show:
		return

	var experience_to_next: int = hero_manager.get_experience_to_next_level()
	var current_experience: int = hero_manager.hero_experience
	hero_exp_name_label.text = hero_manager.get_selected_hero_name() + " Lv." + str(hero_manager.hero_level)
	hero_exp_value_label.text = str(current_experience) + " / " + str(experience_to_next)
	hero_exp_bar.max_value = float(maxi(1, experience_to_next))
	hero_exp_bar.value = float(clampi(current_experience, 0, experience_to_next))
	hero_exp_panel.tooltip_text = "英雄经验：普通关 +10，精英关 +20，BOSS 关 +30。满 50 经验升级并选择一次英雄强化。"


func _add_gold(amount: int) -> void:
	if amount <= 0:
		return

	economy_manager.add_gold(amount)
	_update_gold_label()
	DEBUG_LOG_SCRIPT.info("金币 +" + str(amount) + "，当前金币：" + str(economy_manager.gold))


func _on_relic_gold_added(amount: int) -> void:
	economy_manager.add_gold(amount)
	_update_gold_label()


func _on_gold_changed(_new_gold: int, _delta: int) -> void:
	if relic_manager == null or not relic_manager.has_method("has_dynamic_gold_relics"):
		return

	if not bool(relic_manager.has_dynamic_gold_relics()):
		return

	if dynamic_stat_refresh_pending:
		return

	dynamic_stat_refresh_pending = true
	call_deferred("_flush_dynamic_stat_modifier_refresh")


func _flush_dynamic_stat_modifier_refresh() -> void:
	dynamic_stat_refresh_pending = false
	_refresh_dynamic_stat_modifiers()


func _refresh_dynamic_stat_modifiers() -> void:
	if relic_manager != null and relic_manager.has_method("has_dynamic_gold_relics"):
		if not bool(relic_manager.has_dynamic_gold_relics()):
			return

	if battle_manager != null and battle_manager.has_method("refresh_dynamic_relic_auras"):
		battle_manager.refresh_dynamic_relic_auras()


func _get_victory_gold_reward(encounter_type: String) -> int:
	return economy_manager.get_victory_gold_reward(encounter_type, run_controller.current_round, run_controller.max_round)


func _get_victory_gold_reward_debug_text(encounter_type: String, reward: int) -> String:
	return economy_manager.get_victory_gold_reward_debug_text(encounter_type, reward)


func _update_gold_label() -> void:
	gold_label.text = "金币：" + str(economy_manager.gold)
	shop_gold_label.text = "金币：" + str(economy_manager.gold)


func _show_encounter_info_panel() -> void:
	_position_encounter_info_panel()
	encounter_info_label.text = _build_encounter_info_text()
	encounter_info_panel.visible = true


func _hide_encounter_info_panel() -> void:
	encounter_info_panel.visible = false


func _position_encounter_info_panel() -> void:
	if encounter_info_panel == null or encounter_info_label == null:
		return
	if battle_board == null or not is_instance_valid(battle_board):
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = Vector2(1920.0, 1080.0)

	var board_origin: Vector2 = battle_board.board_origin
	var cell_size: float = battle_board.cell_size
	var enemy_board_right: float = board_origin.x + float(battle_board.COLUMN_COUNT) * cell_size
	var enemy_board_top: float = board_origin.y
	var enemy_board_height: float = float(battle_board.ROW_COUNT) * cell_size
	var margin: float = 16.0
	var panel_left: float = enemy_board_right + margin
	var available_width: float = viewport_size.x - panel_left - margin
	var panel_width: float = clampf(available_width, 160.0, 260.0)
	var panel_size: Vector2 = Vector2(panel_width, minf(340.0, maxf(220.0, enemy_board_height - margin * 2.0)))
	var panel_top: float = clampf(enemy_board_top + 8.0, margin, maxf(margin, viewport_size.y - panel_size.y - margin))

	encounter_info_panel.position = Vector2(panel_left, panel_top)
	encounter_info_panel.size = panel_size
	encounter_info_label.position = Vector2(24.0, 28.0)
	encounter_info_label.size = panel_size - Vector2(48.0, 56.0)


func _set_board_bench_visible(is_visible: bool) -> void:
	if battle_board == null:
		return

	if battle_board.has_method("set_bench_visible"):
		battle_board.set_bench_visible(is_visible)


func _set_board_visible(is_visible: bool) -> void:
	if battle_board == null:
		return

	battle_board.visible = is_visible


func create_damage_field(
	source_unit: Variant,
	center_position: Vector2,
	radius: float,
	duration: float,
	tick_interval: float,
	damage_per_tick: int
) -> int:
	if battle_manager == null:
		return -1
	if not battle_manager.has_method("create_damage_field"):
		return -1

	return int(battle_manager.create_damage_field(source_unit, center_position, radius, duration, tick_interval, damage_per_tick))



func create_aoe_shape_visual(shape_data: Dictionary, color: Color, duration: float = 0.25) -> void:
	if battle_manager == null or not battle_manager.has_method("create_aoe_shape_visual"):
		return
	battle_manager.create_aoe_shape_visual(shape_data, color, duration)


func create_visual_field(center_position: Vector2, radius: float, duration: float, color: Color) -> int:
	if battle_manager == null:
		return -1
	if not battle_manager.has_method("create_visual_field"):
		return -1

	return int(battle_manager.create_visual_field(center_position, radius, duration, color))


func create_follow_visual_field(follow_unit: Variant, center_position: Vector2, radius: float, duration: float, color: Color) -> int:
	if battle_manager == null:
		return -1
	if not battle_manager.has_method("create_follow_visual_field"):
		return -1

	return int(battle_manager.create_follow_visual_field(follow_unit, center_position, radius, duration, color))


func create_heal_field(
	source_unit: Variant,
	follow_unit: Variant,
	center_position: Vector2,
	radius: float,
	duration: float,
	tick_interval: float,
	heal_tick_values: Array[int],
	color: Color
) -> int:
	if battle_manager == null:
		return -1
	if not battle_manager.has_method("create_heal_field"):
		return -1

	return int(battle_manager.create_heal_field(source_unit, follow_unit, center_position, radius, duration, tick_interval, heal_tick_values, color))


func create_status_field(
	source_unit: Variant,
	center_position: Vector2,
	radius: float,
	duration: float,
	tick_interval: float,
	status_data: Dictionary,
	color: Color
) -> int:
	if battle_manager == null:
		return -1
	if not battle_manager.has_method("create_status_field"):
		return -1

	return int(battle_manager.create_status_field(source_unit, center_position, radius, duration, tick_interval, status_data, color))


func create_shape_status_field(
	source_unit: Variant,
	shape_data: Dictionary,
	duration: float,
	tick_interval: float,
	status_data: Dictionary,
	color: Color
) -> int:
	if battle_manager == null:
		return -1
	if not battle_manager.has_method("create_shape_status_field"):
		return -1

	return int(battle_manager.create_shape_status_field(source_unit, shape_data, duration, tick_interval, status_data, color))



func summon_units(source_unit: Unit, summon_unit_data: Resource, count: int, context: Dictionary = {}) -> Array[Unit]:
	if battle_manager == null or not battle_manager.has_method("summon_units"):
		var empty_units: Array[Unit] = []
		return empty_units

	return battle_manager.summon_units(source_unit, summon_unit_data, count, context)


func mark_puppet_summon_target(source_unit: Unit, target: Unit) -> bool:
	if battle_manager == null:
		return false

	var current_summon_manager: Variant = battle_manager.summon_manager
	if current_summon_manager == null or not current_summon_manager.has_method("mark_puppet_target"):
		return false

	return bool(current_summon_manager.mark_puppet_target(source_unit, target))

func spawn_basic_attack_projectile(attacker: Unit, target: Unit, payload: Variant, projectile_speed: float) -> void:
	if battle_manager == null:
		return
	var pm: Variant = battle_manager.projectile_manager
	if pm == null or not pm.has_method("spawn_basic_attack_projectile"):
		return
	pm.spawn_basic_attack_projectile(attacker, target, payload, projectile_speed)



func _set_gameplay_ui_visible(is_visible: bool) -> void:
	result_label.visible = is_visible
	round_label.visible = is_visible
	if hero_exp_panel != null:
		hero_exp_panel.visible = false
	if gold_frame != null:
		gold_frame.visible = is_visible
	gold_label.visible = is_visible
	start_button.visible = is_visible and run_controller.state == GameState.PREPARE
	menu_button.visible = is_visible
	stats_label.visible = is_visible
	relic_bar_panel.visible = is_visible

	if not is_visible:
		if battle_speed_button != null:
			battle_speed_button.visible = false
		if grid_toggle_button != null:
			grid_toggle_button.visible = false
		if background_switch_button != null:
			background_switch_button.visible = false
		_hide_gameplay_menu()
		_hide_shop_panel()
		_hide_bench_panel()
		_hide_reward_panel()
		_hide_hero_selection_panel()
		_hide_unit_detail_panel()
		_hide_relic_detail_panel()
		_hide_mirror_info_panel()
		_hide_encounter_info_panel()
		_hide_prepare_action_buttons()
	else:
		_update_hero_exp_ui()
		_update_battle_speed_button()
		_update_battle_speed_button_visibility()
		_update_mirror_info_button_visibility()


func _show_shop_panel() -> void:
	if run_controller.state != GameState.PREPARE:
		return

	_hide_bench_panel()
	_hide_bond_detail_panel()
	if bond_panel != null:
		bond_panel.visible = false
	_refresh_shop_panel()
	shop_panel.visible = true
	shop_button.text = "关闭商店"


func _hide_shop_panel() -> void:
	shop_panel.visible = false
	shop_button.text = "商店"
	if relic_panel_controller.is_showing_shop_relic_detail():
		_hide_relic_detail_panel()
	_refresh_bond_panel()


func _show_prepare_action_buttons() -> void:
	start_button.visible = true
	start_button.disabled = false
	shop_button.visible = true
	bench_button.visible = false
	_update_battle_speed_button_visibility()
	_update_mirror_info_button_visibility()
	shop_button.disabled = run_controller.state != GameState.PREPARE
	bench_button.disabled = run_controller.state != GameState.PREPARE
	_set_sell_zone_visible(true)


func _hide_prepare_action_buttons() -> void:
	start_button.visible = false
	shop_button.visible = false
	bench_button.visible = false
	if mirror_info_button != null:
		mirror_info_button.visible = false
	if bond_panel != null:
		bond_panel.visible = false
	_hide_bond_detail_panel()
	_set_sell_zone_visible(false)


func _on_shop_button_pressed() -> void:
	if run_controller.state != GameState.PREPARE:
		return

	if shop_panel.visible:
		_hide_shop_panel()
	else:
		_show_shop_panel()


func _on_bench_button_pressed() -> void:
	if run_controller.state != GameState.PREPARE:
		return

	_show_bench_panel()


func _on_shop_close_button_pressed() -> void:
	_hide_shop_panel()


func _on_bench_close_button_pressed() -> void:
	_hide_bench_panel()


func _refresh_shop_panel() -> void:
	shop_panel_controller.refresh_shop_panel(run_controller.state == GameState.PREPARE)


func _on_shop_buy_button_pressed(shop_index: int) -> void:
	if run_controller.state != GameState.PREPARE:
		return

	var shop_item: Dictionary = shop_manager.get_shop_item(shop_index)
	if shop_item.is_empty():
		return

	if bool(shop_item.get("is_sold", false)):
		return

	var price: int = int(shop_item["price"])
	var item_name: String = str(shop_item["name"])
	if not economy_manager.can_spend(price):
		result_label.text = "金币不足"
		DEBUG_LOG_SCRIPT.info("Cannot buy " + item_name + ": need " + str(price) + " gold, current gold: " + str(economy_manager.gold))
		return

	var item_type: String = str(shop_item.get("type", "UNIT"))
	if item_type == "EMPTY":
		return

	if item_type == "RELIC":
		_buy_shop_relic(shop_index, shop_item, price, item_name)
		return

	_buy_shop_unit(shop_index, shop_item, price, item_name)


func _buy_shop_unit(shop_index: int, shop_item: Dictionary, price: int, unit_name: String) -> void:
	if not roster_manager.can_add_unit():
		result_label.text = "单位数量已满"
		DEBUG_LOG_SCRIPT.info("Cannot buy unit: roster is full.")
		_refresh_shop_panel()
		_refresh_bench_panel()
		return

	var unit_data: Resource = shop_item["unit_data"] as Resource
	if unit_data == null:
		return

	_save_player_start_positions()
	if not economy_manager.spend_gold(price):
		result_label.text = "金币不足"
		_update_gold_label()
		_refresh_shop_panel()
		return

	var added_unit: bool = roster_manager.add_unit(unit_data, price)
	if not added_unit:
		economy_manager.refund_gold(price)
		result_label.text = "单位数量已满"
		DEBUG_LOG_SCRIPT.info("Cannot buy " + unit_name + ": roster is full.")
		_update_gold_label()
		_refresh_shop_panel()
		_refresh_bench_panel()
		return

	_refresh_player_preview_from_roster()
	shop_manager.mark_item_sold(shop_index)
	_update_gold_label()
	_refresh_shop_panel()
	_refresh_bench_panel()
	result_label.text = "已解锁并购买 " + unit_name if bool(shop_item.get("is_unlock_offer", false)) else "已购买 " + unit_name
	DEBUG_LOG_SCRIPT.info("Bought " + unit_name + " for " + str(price) + " gold. Current gold: " + str(economy_manager.gold))


func _buy_shop_relic(shop_index: int, shop_item: Dictionary, price: int, relic_name: String) -> void:
	var relic_data: Resource = shop_item.get("relic_data", null) as Resource
	if relic_data == null:
		return

	if relic_manager.has_relic(relic_data):
		result_label.text = "已拥有该遗物"
		_refresh_shop_panel()
		return

	if not economy_manager.spend_gold(price):
		result_label.text = "金币不足"
		_update_gold_label()
		_refresh_shop_panel()
		return

	relic_manager.add_relic(relic_data)
	shop_manager.mark_item_sold(shop_index)
	_refresh_dynamic_stat_modifiers()
	_update_gold_label()
	_refresh_shop_panel()
	_refresh_relic_bar()
	result_label.text = "已购买 " + relic_name
	DEBUG_LOG_SCRIPT.info("Bought " + relic_name + " for " + str(price) + " gold. Current gold: " + str(economy_manager.gold))


func _on_refresh_shop_button_pressed() -> void:
	if run_controller.state != GameState.PREPARE:
		return

	var refresh_cost: int = shop_manager.get_refresh_cost()
	if not economy_manager.can_spend(refresh_cost):
		result_label.text = "金币不足"
		DEBUG_LOG_SCRIPT.info("Cannot refresh shop: need " + str(refresh_cost) + " gold, current gold: " + str(economy_manager.gold))
		return

	economy_manager.spend_gold(refresh_cost)
	shop_manager.roll_shop_items()
	if relic_panel_controller.is_showing_shop_relic_detail():
		_hide_relic_detail_panel()
	_update_gold_label()
	_refresh_shop_panel()
	result_label.text = "商店已刷新"
	DEBUG_LOG_SCRIPT.info("Shop refreshed for " + str(refresh_cost) + " gold. Current gold: " + str(economy_manager.gold))


func _refresh_player_preview_from_roster() -> void:
	if run_controller.state != GameState.PREPARE:
		return

	_save_player_start_positions()
	var player_unit_configs: Array[Dictionary] = roster_manager.get_player_battle_unit_configs(battle_board, _get_reserved_hero_cells_for_roster())
	var bench_unit_configs: Array[Dictionary] = roster_manager.get_bench_unit_configs(battle_board)
	battle_manager.refresh_player_and_bench_units(player_unit_configs, bench_unit_configs)
	_refresh_bond_panel()


func _get_reserved_hero_cells_for_roster() -> Array[Vector2i]:
	var reserved_cells: Array[Vector2i] = []
	if hero_manager == null or battle_board == null:
		return reserved_cells

	if not hero_manager.has_method("get_reserved_hero_cell"):
		return reserved_cells

	var hero_cell: Vector2i = hero_manager.get_reserved_hero_cell(battle_board)
	if hero_cell == Vector2i(-1, -1):
		hero_cell = _save_current_preview_hero_cell()

	if hero_cell != Vector2i(-1, -1):
		reserved_cells.append(hero_cell)

	return reserved_cells


func _save_current_preview_hero_cell() -> Vector2i:
	if battle_board == null or battle_manager == null or hero_manager == null:
		return Vector2i(-1, -1)

	if not hero_manager.has_method("save_hero_cell"):
		return Vector2i(-1, -1)

	for unit: Unit in battle_manager.get_left_units():
		if unit == null or not is_instance_valid(unit) or not _is_hero_unit(unit):
			continue

		var hero_cell: Vector2i = battle_board.world_to_grid(unit.position)
		if battle_board.has_method("is_valid_player_cell") and battle_board.is_valid_player_cell(hero_cell):
			var snapped_position: Vector2 = battle_board.grid_to_world(hero_cell)
			hero_manager.save_hero_cell(hero_cell, snapped_position)
			return hero_cell

	return Vector2i(-1, -1)


func _save_player_start_positions() -> void:
	if run_controller.state != GameState.PREPARE:
		return

	var positions_by_roster_id: Dictionary = {}
	var cells_by_roster_id: Dictionary = {}
	var player_units: Array[Unit] = battle_manager.get_left_units()
	for unit: Unit in player_units:
		if not is_instance_valid(unit):
			continue

		if _is_hero_unit(unit):
			if battle_board != null and battle_board.has_method("world_to_grid") and hero_manager != null and hero_manager.has_method("save_hero_cell"):
				var hero_cell: Vector2i = battle_board.world_to_grid(unit.position)
				if battle_board.has_method("is_valid_player_cell") and battle_board.is_valid_player_cell(hero_cell):
					hero_manager.save_hero_cell(hero_cell, battle_board.grid_to_world(hero_cell))
			continue

		if unit.roster_id <= 0:
			continue

		positions_by_roster_id[unit.roster_id] = unit.position
		if battle_board != null and battle_board.has_method("world_to_grid"):
			cells_by_roster_id[unit.roster_id] = battle_board.world_to_grid(unit.position)

	if battle_board != null and cells_by_roster_id.size() > 0:
		roster_manager.save_active_unit_cells(cells_by_roster_id, positions_by_roster_id)
	else:
		roster_manager.save_active_unit_positions(positions_by_roster_id)


func _on_prepare_unit_drop_requested(unit: Unit, fallback_position: Vector2) -> void:
	if run_controller.state != GameState.PREPARE:
		unit.position = fallback_position
		return

	if unit == null or not is_instance_valid(unit):
		return

	if _try_sell_unit_from_drop(unit, fallback_position):
		return

	if battle_board == null:
		unit.position = fallback_position
		return

	var drop_cell: Vector2i = battle_board.world_to_grid(unit.position)
	var drop_bench_slot: int = battle_board.world_to_bench_slot(unit.position)
	if _is_hero_unit(unit):
		_handle_hero_unit_drop(unit, fallback_position, drop_cell)
	elif unit.roster_area == "bench":
		_handle_bench_unit_drop(unit, fallback_position, drop_cell, drop_bench_slot)
	else:
		_handle_active_unit_drop(unit, fallback_position, drop_cell, drop_bench_slot)


func _handle_hero_unit_drop(unit: Unit, fallback_position: Vector2, drop_cell: Vector2i) -> void:
	if battle_board.is_valid_player_cell(drop_cell) and not battle_board.is_cell_occupied(drop_cell, battle_manager.get_left_units(), unit):
		var snapped_position: Vector2 = battle_board.grid_to_world(drop_cell)
		unit.position = snapped_position
		if hero_manager != null and hero_manager.has_method("save_hero_cell"):
			hero_manager.save_hero_cell(drop_cell, snapped_position)
		_refresh_dynamic_stat_modifiers()
		result_label.text = "已调整英雄站位"
		return

	unit.position = fallback_position
	result_label.text = "英雄只能部署在玩家棋盘内"


func _handle_active_unit_drop(unit: Unit, fallback_position: Vector2, drop_cell: Vector2i, drop_bench_slot: int) -> void:
	if battle_board.is_valid_player_cell(drop_cell) and not battle_board.is_cell_occupied(drop_cell, battle_manager.get_left_units(), unit):
		var snapped_position: Vector2 = battle_board.grid_to_world(drop_cell)
		unit.position = snapped_position
		roster_manager.save_active_unit_cell(unit.roster_id, drop_cell, snapped_position)
		_refresh_dynamic_stat_modifiers()
		return

	if battle_board.is_valid_bench_slot(drop_bench_slot) \
		and not battle_board.is_bench_slot_occupied(drop_bench_slot, battle_manager.get_bench_units()) \
		and _move_active_unit_to_bench_from_drop(unit, fallback_position):
		_refresh_roster_preview_without_saving()
		_refresh_shop_panel()
		result_label.text = "已移入备战席"
		return

	unit.position = fallback_position


func _move_active_unit_to_bench_from_drop(unit: Unit, fallback_position: Vector2) -> bool:
	var fallback_cell: Vector2i = battle_board.world_to_grid(fallback_position)
	if battle_board.is_valid_player_cell(fallback_cell):
		roster_manager.save_active_unit_cell(unit.roster_id, fallback_cell, battle_board.grid_to_world(fallback_cell))

	return roster_manager.move_active_to_bench_by_id(unit.roster_id)


func _handle_bench_unit_drop(unit: Unit, fallback_position: Vector2, drop_cell: Vector2i, drop_bench_slot: int) -> void:
	if battle_board.is_valid_player_cell(drop_cell):
		if roster_manager.get_active_count() >= roster_manager.max_active_units:
			result_label.text = "上场单位已满"
			unit.position = fallback_position
			return

		if battle_board.is_cell_occupied(drop_cell, battle_manager.get_left_units()):
			unit.position = fallback_position
			return

		var snapped_position: Vector2 = battle_board.grid_to_world(drop_cell)
		if roster_manager.move_bench_to_active_by_id(unit.roster_id):
			roster_manager.save_active_unit_cell(unit.roster_id, drop_cell, snapped_position)
			_refresh_roster_preview_without_saving()
			_refresh_dynamic_stat_modifiers()
			_refresh_shop_panel()
			result_label.text = "已部署单位"
			return

	if battle_board.is_valid_bench_slot(drop_bench_slot):
		unit.position = fallback_position
		return

	unit.position = fallback_position


func _try_sell_unit_from_drop(unit: Unit, fallback_position: Vector2) -> bool:
	if not _is_unit_in_sell_zone(unit):
		return false

	if _is_hero_unit(unit):
		unit.position = fallback_position
		result_label.text = "英雄无法出售"
		return true

	if unit.roster_id <= 0:
		unit.position = fallback_position
		result_label.text = "无法出售单位"
		return true

	var sell_price: int = 0
	if unit.roster_area == "bench":
		sell_price = roster_manager.sell_bench_unit_by_id(unit.roster_id)
	else:
		_save_player_start_positions()
		sell_price = roster_manager.sell_active_unit_by_id(unit.roster_id)

	if sell_price <= 0:
		unit.position = fallback_position
		result_label.text = "无法出售单位"
		return true

	economy_manager.add_gold(sell_price)
	_hide_unit_detail_panel()
	_update_gold_label()
	_refresh_player_preview_from_roster()
	_refresh_shop_panel()
	_refresh_bench_panel()
	result_label.text = "已出售单位，金币 +" + str(sell_price)
	DEBUG_LOG_SCRIPT.info("Sold dropped unit for " + str(sell_price) + " gold. Current gold: " + str(economy_manager.gold))
	return true


func _is_unit_in_sell_zone(unit: Unit) -> bool:
	if sell_zone_panel == null or not sell_zone_panel.visible:
		return false

	if unit == null or not is_instance_valid(unit):
		return false

	var drop_position: Vector2 = unit.global_position + Vector2(20.0, 20.0)
	return sell_zone_panel.get_global_rect().has_point(drop_position)


func _set_sell_zone_visible(is_visible: bool) -> void:
	if sell_zone_panel != null:
		sell_zone_panel.visible = is_visible
		if not is_visible:
			_set_sell_zone_highlighted(false)


func _update_sell_zone_highlight() -> void:
	if run_controller.state != GameState.PREPARE:
		_set_sell_zone_highlighted(false)
		return

	if sell_zone_panel == null or not sell_zone_panel.visible:
		_set_sell_zone_highlighted(false)
		return

	_set_sell_zone_highlighted(_is_dragged_unit_in_sell_zone())


func _is_dragged_unit_in_sell_zone() -> bool:
	var checked_units: Array = []
	checked_units.append_array(battle_manager.get_left_units())
	checked_units.append_array(battle_manager.get_bench_units())
	for unit_value: Variant in checked_units:
		var unit: Unit = unit_value as Unit
		if unit == null or not is_instance_valid(unit):
			continue
		if unit.drag_controller == null or not unit.drag_controller.is_dragging:
			continue
		if _is_unit_in_sell_zone(unit):
			return true

	return false


func _set_sell_zone_highlighted(is_highlighted: bool) -> void:
	if sell_zone_panel == null:
		return

	if is_sell_zone_highlighted == is_highlighted:
		return

	is_sell_zone_highlighted = is_highlighted
	sell_zone_panel.pivot_offset = sell_zone_panel.size * 0.5
	if sell_zone_feedback_tween != null:
		sell_zone_feedback_tween.kill()

	var target_scale: Vector2 = Vector2(1.055, 1.055) if is_highlighted else Vector2.ONE
	var target_modulate: Color = Color(1.22, 1.10, 1.05, 1.0) if is_highlighted else Color.WHITE
	sell_zone_feedback_tween = create_tween()
	sell_zone_feedback_tween.set_parallel(true)
	sell_zone_feedback_tween.set_trans(Tween.TRANS_QUAD)
	sell_zone_feedback_tween.set_ease(Tween.EASE_OUT)
	sell_zone_feedback_tween.tween_property(sell_zone_panel, "scale", target_scale, 0.10)
	sell_zone_feedback_tween.tween_property(sell_zone_panel, "modulate", target_modulate, 0.10)


func _refresh_roster_preview_without_saving() -> void:
	if run_controller.state != GameState.PREPARE:
		return

	var player_unit_configs: Array[Dictionary] = roster_manager.get_player_battle_unit_configs(battle_board, _get_reserved_hero_cells_for_roster())
	var bench_unit_configs: Array[Dictionary] = roster_manager.get_bench_unit_configs(battle_board)
	battle_manager.refresh_player_and_bench_units(player_unit_configs, bench_unit_configs)
	_refresh_bond_panel()


func _show_bench_panel() -> void:
	_hide_bench_panel()


func _hide_bench_panel() -> void:
	bench_panel.visible = false


func _refresh_bench_panel() -> void:
	active_count_label.text = "上场：" + str(roster_manager.get_active_count()) + " / " + str(roster_manager.max_active_units)
	total_units_label.text = "拥有：" + str(roster_manager.get_total_unit_count()) + " / " + str(MAX_TOTAL_UNITS)

	_rebuild_roster_rows(active_units_vbox, roster_manager.get_active_roster(), "移入备战", true)
	_rebuild_roster_rows(bench_units_vbox, roster_manager.get_bench_roster(), "上场", false)


func _rebuild_roster_rows(container: VBoxContainer, roster: Array[Dictionary], button_text: String, is_active_list: bool) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()

	if roster.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "-"
		PIXEL_UI_THEME.apply_label_style(empty_label, Color(0.74, 0.80, 0.88, 1.0), 15)
		container.add_child(empty_label)
		return

	for index: int in range(roster.size()):
		var row: HBoxContainer = HBoxContainer.new()
		var name_label: Label = Label.new()
		var action_button: Button = Button.new()
		var roster_item: Dictionary = roster[index]

		name_label.text = roster_manager.get_unit_display_name_with_star(roster_item)
		name_label.custom_minimum_size = Vector2(210.0, 24.0)
		PIXEL_UI_THEME.apply_label_style(name_label, Color(0.90, 0.94, 1.0, 1.0), 15)
		action_button.text = button_text
		action_button.custom_minimum_size = Vector2(84.0, 24.0)
		PIXEL_UI_THEME.apply_button_style(action_button, Color(0.10, 0.18, 0.28, 1.0), Color(0.58, 0.72, 0.90, 1.0), 1, 13)

		if is_active_list:
			action_button.pressed.connect(_on_active_unit_bench_button_pressed.bind(index))
		else:
			action_button.pressed.connect(_on_bench_unit_deploy_button_pressed.bind(index))

		row.add_child(name_label)
		row.add_child(action_button)
		container.add_child(row)


func _on_active_unit_bench_button_pressed(active_index: int) -> void:
	if run_controller.state != GameState.PREPARE:
		return

	_save_player_start_positions()
	if roster_manager.move_active_to_bench(active_index):
		_refresh_player_preview_from_roster()
		_refresh_shop_panel()
		_refresh_bench_panel()
		result_label.text = "已移入备战席"


func _on_bench_unit_deploy_button_pressed(bench_index: int) -> void:
	if run_controller.state != GameState.PREPARE:
		return

	if roster_manager.get_active_count() >= roster_manager.max_active_units:
		result_label.text = "上场单位已满"
		DEBUG_LOG_SCRIPT.info("Cannot deploy unit: active team is full.")
		return

	if roster_manager.move_bench_to_active(bench_index):
		_refresh_player_preview_from_roster()
		_refresh_shop_panel()
		_refresh_bench_panel()
		result_label.text = "已部署单位"


func _get_shop_item_labels() -> Array[Label]:
	var labels: Array[Label] = []
	labels.append(shop_item_label_1)
	labels.append(shop_item_label_2)
	labels.append(shop_item_label_3)
	labels.append(shop_item_label_4)
	labels.append(shop_item_label_5)
	labels.append(shop_item_label_6)
	labels.append(shop_item_label_7)
	labels.append(shop_item_label_8)
	labels.append(shop_item_label_9)
	labels.append(shop_item_label_10)
	return labels


func _get_shop_buy_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	buttons.append(shop_buy_button_1)
	buttons.append(shop_buy_button_2)
	buttons.append(shop_buy_button_3)
	buttons.append(shop_buy_button_4)
	buttons.append(shop_buy_button_5)
	buttons.append(shop_buy_button_6)
	buttons.append(shop_buy_button_7)
	buttons.append(shop_buy_button_8)
	buttons.append(shop_buy_button_9)
	buttons.append(shop_buy_button_10)
	return buttons


func _build_encounter_info_text() -> String:
	var encounter: Dictionary = encounter_manager.get_encounter(run_controller.current_round) as Dictionary
	if encounter.is_empty():
		return "遭遇数据缺失"

	var enemy_summary: String = _build_enemy_summary_text(encounter)
	var enemy_units: Array = encounter["enemy_units"] as Array
	var text: String = "[b]第 " + str(run_controller.current_round) + " / " + str(run_controller.max_round) + " 轮[/b]\n" \
		+ _get_encounter_display_name(str(encounter["encounter_name"])) + "  " + _format_encounter_type(str(encounter["encounter_type"])) + "\n" \
		+ "敌人数量：" + str(enemy_units.size()) + "\n" \
		+ enemy_summary
	var mirror_preview: String = ""
	if run_controller.is_mirror_challenge():
		mirror_preview = mirror_challenge_manager.build_current_round_preview_text(run_controller.current_round)
		if mirror_preview != "":
			text += "\n\n" + mirror_preview

	return text


func _build_enemy_summary_text(encounter: Dictionary) -> String:
	var counts: Dictionary = {}
	var enemy_units: Array = encounter["enemy_units"] as Array
	var ordered_names: Array[String] = []

	for enemy_unit_value: Variant in enemy_units:
		var enemy_unit: Dictionary = enemy_unit_value as Dictionary
		var unit_id: String = str(enemy_unit.get("unit_id", ""))
		var display_name: String = str(enemy_unit.get("display_name", _get_unit_type_display_name(unit_id)))
		if not counts.has(display_name):
			counts[display_name] = 0
			ordered_names.append(display_name)
		counts[display_name] = int(counts[display_name]) + 1

	var summary_parts: Array[String] = []
	for display_name: String in ordered_names:
		var count: int = int(counts.get(display_name, 0))
		if count > 0:
			summary_parts.append(display_name + " x" + str(count))

	return _join_text(summary_parts, " / ")


func _get_unit_type_display_name(unit_id: String) -> String:
	match unit_id:
		"warrior":
			return "战士"
		"archer":
			return "弓手"
		"assassin":
			return "刺客"
		"tank":
			return "重装坦克"
		"mage":
			return "法师"
		"priest":
			return "牧师"
		"bard":
			return "吟游诗人"
		"forest_druid":
			return "森林德鲁伊"
		"plague_caster":
			return "瘟疫术士"
		"guardian_captain":
			return "守护队长"
		"wind_chanter":
			return "风语者"
		"greatsword_knight":
			return "巨剑骑士"
		"bomb_thrower":
			return "爆弹投手"
		"cleric":
			return "神官"
		"alchemist":
			return "炼金术士"
		"enemy_shield_guard":
			return "盾卫"
		"enemy_stoneback_beast":
			return "石背巨兽"
		"enemy_elite_iron_warden":
			return "精英铁壁守卫"
		"enemy_boss_earthbreaker_colossus":
			return "Boss：裂地巨像"
		"enemy_crossbow_raider":
			return "弩手掠袭者"
		"enemy_flame_imp":
			return "烈焰小鬼"
		"enemy_elite_shadow_reaper":
			return "精英影刃收割者"
		"enemy_boss_crystal_cannon":
			return "Boss：冰晶炮台"
		"enemy_dark_acolyte":
			return "黑暗侍僧"
		"enemy_war_drummer":
			return "战鼓手"
		"enemy_elite_blood_oracle":
			return "精英血谕者"
		"enemy_boss_goblin_high_priest":
			return "Boss：哥布林大祭司"
		_:
			return unit_id.capitalize()


func _on_unit_detail_requested(unit: Unit) -> void:
	if unit == null or not is_instance_valid(unit):
		_hide_unit_detail_panel()
		return

	_show_unit_detail_panel(unit)


func modify_status_effect_data_for_bonds(effect_data: Dictionary) -> Dictionary:
	if battle_manager != null and battle_manager.has_method("modify_status_effect_data_for_bonds"):
		return battle_manager.modify_status_effect_data_for_bonds(effect_data)

	return effect_data


func _on_unit_detail_close_button_pressed() -> void:
	_hide_unit_detail_panel()


func _show_unit_detail_panel(unit: Unit) -> void:
	unit_detail_panel_controller.show(unit)


func _hide_unit_detail_panel() -> void:
	unit_detail_panel_controller.hide()


func _refresh_unit_detail_panel_if_open() -> void:
	unit_detail_panel_controller.refresh_if_open()


func _is_position_inside_control(control: Control, position: Vector2) -> bool:
	if control == null or not is_instance_valid(control) or not control.visible:
		return false

	return control.get_global_rect().has_point(position)


func _is_hero_unit(unit: Unit) -> bool:
	if unit == null or not is_instance_valid(unit):
		return false

	return bool(unit.get_meta("is_hero", false)) or unit.roster_area == "hero" or unit.unit_type.begins_with("hero_")


func _is_position_over_any_unit(position: Vector2) -> bool:
	if battle_manager == null or not battle_manager.has_method("get_all_units"):
		return false

	var units: Array[Unit] = battle_manager.get_all_units()
	for unit: Unit in units:
		if unit == null or not is_instance_valid(unit) or not unit.is_alive:
			continue

		if unit.has_method("_is_mouse_over_body") and bool(unit._is_mouse_over_body(position)):
			return true

	return false


func _refresh_relic_bar() -> void:
	relic_panel_controller.refresh_relic_bar()


func _on_relic_detail_close_button_pressed() -> void:
	_hide_relic_detail_panel()


func _show_relic_detail_panel(selected_index: int = 0) -> void:
	relic_panel_controller.show_relic_detail(selected_index)


func _hide_relic_detail_panel() -> void:
	relic_panel_controller.hide_relic_detail()


func _show_shop_relic_detail_panel(shop_item: Dictionary) -> void:
	relic_panel_controller.show_shop_relic_detail(shop_item)


func _join_text(parts: Array[String], separator: String) -> String:
	var joined_text: String = ""

	for index: int in range(parts.size()):
		if index > 0:
			joined_text += separator
		joined_text += parts[index]

	return joined_text


func _format_multiplier(multiplier: float) -> String:
	return "%0.2f" % multiplier


func _format_encounter_type(encounter_type: String) -> String:
	match encounter_type:
		"NORMAL":
			return "普通"
		"ELITE":
			return "精英"
		"BOSS":
			return "Boss"
		_:
			return encounter_type


func _get_encounter_display_name(encounter_name: String) -> String:
	match encounter_name:
		"Enemy Patrol", "Random Patrol":
			return "敌方巡逻队"
		"Guarded Imp":
			return "小鬼护卫"
		"Stoneback Escort":
			return "石背护卫队"
		"Drummed Patrol":
			return "战鼓巡逻队"
		"Iron Warden":
			return "铁壁守卫"
		"Reinforced Enemy Wall":
			return "强化敌方防线"
		"Flame Escort":
			return "烈焰护卫队"
		"Enemy Line", "Enemy Squad":
			return "敌方阵线"
		"Enemy Vanguard":
			return "敌方先锋"
		"Wandering Formation":
			return "游荡阵型"
		"Elite Assault Team":
			return "精英突击队"
		"Arcane Elite":
			return "奥术精英"
		"Iron Wall Elite":
			return "铁壁精英"
		"Boss: Earthbreaker Colossus":
			return "Boss：裂地巨像"
		_:
			return encounter_name


func _set_start_button_state(button_text: String, is_enabled: bool) -> void:
	if run_controller.state == GameState.PREPARE:
		start_button.text = "开始战斗"
	else:
		start_button.text = button_text
	start_button.disabled = not is_enabled
	start_button.visible = is_enabled


func _apply_menu_button_style(button: Button, base_color: Color, border_color: Color) -> void:
	PIXEL_UI_THEME.apply_button_style(button, base_color, border_color, 2)


func _apply_main_action_button_styles() -> void:
	PIXEL_UI_THEME.apply_button_style(start_button, Color(0.13, 0.30, 0.48, 1.0), Color(0.92, 0.70, 0.40, 1.0), 3, 24)
	PIXEL_UI_THEME.apply_button_style(menu_button, Color(0.12, 0.20, 0.32, 1.0), Color(0.68, 0.82, 1.0, 1.0), 2, 18)
	PIXEL_UI_THEME.apply_button_style(shop_button, Color(0.14, 0.28, 0.36, 1.0), Color(0.90, 0.74, 0.42, 1.0), 2, 18)
	PIXEL_UI_THEME.apply_button_style(bench_button, Color(0.12, 0.22, 0.34, 1.0), Color(0.66, 0.82, 0.96, 1.0), 2, 16)


func _apply_texture_overlay_button_style(button: Button) -> void:
	PIXEL_UI_THEME.apply_button_style(button)


func _apply_battle_panel_styles() -> void:
	if encounter_info_panel != null:
		PIXEL_UI_THEME.apply_panel_style(encounter_info_panel, Color(0.045, 0.060, 0.090, 0.94), Color(0.58, 0.68, 0.82, 1.0), 2, 8.0)
	if bench_panel != null:
		PIXEL_UI_THEME.apply_panel_style(bench_panel, Color(0.045, 0.060, 0.090, 0.95), Color(0.58, 0.68, 0.82, 1.0), 2, 8.0)
		for label_path: String in ["BenchTitle Label", "ActiveCount Label", "TotalUnits Label", "ActiveTitle Label", "BenchTitle2 Label"]:
			var bench_label: Label = bench_panel.get_node_or_null(label_path) as Label
			PIXEL_UI_THEME.apply_label_style(bench_label, Color(0.90, 0.94, 1.0, 1.0), 16)
	if bench_close_button != null:
		PIXEL_UI_THEME.apply_button_style(bench_close_button, Color(0.12, 0.20, 0.32, 1.0), Color(0.68, 0.82, 1.0, 1.0), 2, 14)
	if relic_bar_panel != null:
		PIXEL_UI_THEME.apply_panel_style(relic_bar_panel, Color(0.045, 0.060, 0.090, 0.90), Color(0.70, 0.52, 0.30, 1.0), 2, 8.0)
	if gold_frame != null:
		PIXEL_UI_THEME.apply_panel_style(gold_frame, Color(0.050, 0.064, 0.090, 0.94), Color(0.92, 0.70, 0.38, 1.0), 2, 8.0)
	if hero_exp_panel != null:
		PIXEL_UI_THEME.apply_panel_style(hero_exp_panel, Color(0.045, 0.058, 0.084, 0.92), Color(0.64, 0.76, 0.94, 1.0), 2, 6.0)
	if sell_zone_panel != null:
		PIXEL_UI_THEME.apply_panel_style(sell_zone_panel, Color(0.18, 0.070, 0.055, 0.90), Color(0.94, 0.52, 0.38, 1.0), 2, 8.0)
		var sell_zone_title_label: Label = sell_zone_panel.get_node_or_null("SellZoneTitle Label") as Label
		var sell_zone_hint_label: Label = sell_zone_panel.get_node_or_null("SellZoneHint Label") as Label
		PIXEL_UI_THEME.apply_label_style(sell_zone_title_label, Color(1.0, 0.92, 0.84, 1.0), 20, 2)
		PIXEL_UI_THEME.apply_label_style(sell_zone_hint_label, Color(1.0, 0.86, 0.78, 1.0), 14, 2)


func _create_reward_button_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	return PIXEL_UI_THEME.create_button_style(bg_color, border_color, border_width, 10.0)


func _get_reward_rarity_display_name(rarity: String) -> String:
	return rarity_formatter.get_display_name(rarity)


func _get_reward_rarity_color(rarity: String) -> Color:
	return rarity_formatter.get_color(rarity)


func _normalize_reward_rarity(rarity: String) -> String:
	return rarity_formatter.normalize(rarity)


func _get_reward_text_color(bg_color: Color) -> Color:
	return rarity_formatter.get_text_color(bg_color)


func _lighten_color(color: Color, amount: float) -> Color:
	return rarity_formatter.lighten_color(color, amount)


func _darken_color(color: Color, amount: float) -> Color:
	return rarity_formatter.darken_color(color, amount)


func _create_stats_button() -> void:
	if _stats_button != null:
		return
	_stats_button = Button.new()
	_stats_button.text = "战斗统计"
	_stats_button.custom_minimum_size = Vector2(110.0, 36.0)
	_stats_button.focus_mode = Control.FOCUS_NONE
	_stats_button.visible = false
	_stats_button.z_index = 200
	PIXEL_UI_THEME.apply_button_style(_stats_button, Color(0.12, 0.18, 0.28), Color(0.40, 0.55, 0.85), 2)
	_stats_button.pressed.connect(_on_stats_button_pressed)
	$"UI CanvasLayer".add_child(_stats_button)


func _show_stats_button() -> void:
	if _stats_button == null:
		_create_stats_button()
	if _battle_stats_text == "":
		return
	_stats_button.visible = true
	_stats_button.position = Vector2(360.0, 490.0)


func _hide_stats_button() -> void:
	if _stats_button != null:
		_stats_button.visible = false
	_hide_stats_popup()


func _on_stats_button_pressed() -> void:
	if _battle_stats_text == "":
		return
	_show_stats_popup()


func _create_stats_popup() -> void:
	if stats_popup_panel != null:
		return

	var ui_canvas_layer: CanvasLayer = $"UI CanvasLayer"
	if ui_canvas_layer == null:
		return

	stats_popup_panel = Panel.new()
	stats_popup_panel.visible = false
	stats_popup_panel.z_index = UI_LAYER.FLOATING_POPUP + 20
	stats_popup_panel.add_theme_stylebox_override("panel", _create_panel_style(Color(0.04, 0.05, 0.08, 0.98), Color(0.52, 0.68, 0.90, 0.95), 8, 2))
	ui_canvas_layer.add_child(stats_popup_panel)

	stats_popup_title_label = Label.new()
	stats_popup_title_label.text = "战斗统计"
	stats_popup_title_label.position = Vector2(24.0, 18.0)
	stats_popup_title_label.add_theme_font_size_override("font_size", 24)
	stats_popup_title_label.add_theme_color_override("font_color", Color(0.98, 0.86, 0.58, 1.0))
	stats_popup_panel.add_child(stats_popup_title_label)

	stats_popup_summary_label = Label.new()
	stats_popup_summary_label.position = Vector2(24.0, 54.0)
	stats_popup_summary_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	stats_popup_summary_label.clip_text = true
	stats_popup_summary_label.add_theme_font_size_override("font_size", 15)
	stats_popup_summary_label.add_theme_color_override("font_color", Color(0.90, 0.94, 1.0, 1.0))
	stats_popup_panel.add_child(stats_popup_summary_label)

	stats_popup_close_button = Button.new()
	stats_popup_close_button.text = "关闭"
	stats_popup_close_button.focus_mode = Control.FOCUS_NONE
	stats_popup_close_button.pressed.connect(_hide_stats_popup)
	_apply_menu_button_style(stats_popup_close_button, Color(0.22, 0.25, 0.30, 1.0), Color(0.68, 0.72, 0.78, 1.0))
	stats_popup_panel.add_child(stats_popup_close_button)

	stats_popup_scroll = ScrollContainer.new()
	stats_popup_scroll.clip_contents = true
	stats_popup_panel.add_child(stats_popup_scroll)

	stats_popup_content = VBoxContainer.new()
	stats_popup_content.add_theme_constant_override("separation", 6)
	stats_popup_content.custom_minimum_size = Vector2(_get_stats_table_width(), 0.0)
	stats_popup_scroll.add_child(stats_popup_content)


func _show_stats_popup() -> void:
	if _battle_stats_units.is_empty():
		return
	_create_stats_popup()
	if stats_popup_panel == null:
		return

	_layout_stats_popup()
	_populate_stats_popup_content()
	stats_popup_panel.visible = true


func _hide_stats_popup() -> void:
	if stats_popup_panel != null:
		stats_popup_panel.visible = false


func _layout_stats_popup() -> void:
	if stats_popup_panel == null:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var panel_size: Vector2 = Vector2(
		minf(1620.0, maxf(760.0, viewport_size.x - 120.0)),
		minf(860.0, maxf(520.0, viewport_size.y - 120.0))
	)
	stats_popup_panel.position = (viewport_size - panel_size) * 0.5
	stats_popup_panel.size = panel_size

	if stats_popup_title_label != null:
		stats_popup_title_label.size = Vector2(panel_size.x - 160.0, 30.0)
	if stats_popup_summary_label != null:
		stats_popup_summary_label.size = Vector2(panel_size.x - 48.0, 24.0)
	if stats_popup_close_button != null:
		stats_popup_close_button.position = Vector2(panel_size.x - 104.0, 16.0)
		stats_popup_close_button.custom_minimum_size = Vector2(80.0, 32.0)
	if stats_popup_scroll != null:
		stats_popup_scroll.position = Vector2(24.0, 88.0)
		stats_popup_scroll.size = Vector2(panel_size.x - 48.0, panel_size.y - 112.0)


func _populate_stats_popup_content() -> void:
	if stats_popup_content == null:
		return

	for child: Node in stats_popup_content.get_children():
		stats_popup_content.remove_child(child)
		child.queue_free()

	var player_units: Array = []
	var enemy_units: Array = []
	for stat: Dictionary in _battle_stats_units:
		if int(stat.get("team_id", 0)) == 1:
			player_units.append(stat)
		else:
			enemy_units.append(stat)

	if stats_popup_summary_label != null:
		stats_popup_summary_label.text = _build_stats_summary_text(player_units.size(), enemy_units.size())

	_add_stats_section("我方单位", player_units)
	_add_stats_section("敌方单位", enemy_units)


func _build_stats_summary_text(player_count: int, enemy_count: int) -> String:
	var text: String = "战斗时间：" + ("%0.1f" % _battle_stats_duration) + " 秒"
	text += "    我方：" + str(player_count) + "    敌方：" + str(enemy_count)
	if _battle_stats_relic_damage > 0:
		text += "    遗物伤害：" + str(_battle_stats_relic_damage)
	return text


func _add_stats_section(section_title: String, units: Array) -> void:
	var title_label: Label = Label.new()
	title_label.text = section_title + "（" + str(units.size()) + "）"
	title_label.custom_minimum_size = Vector2(_get_stats_table_width(), 28.0)
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color(0.98, 0.86, 0.58, 1.0))
	stats_popup_content.add_child(title_label)

	_add_stats_row(["单位", "伤害", "承伤", "治疗", "护盾", "回蓝", "击杀", "攻击", "存活", "状态"], true)
	if units.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "无"
		empty_label.custom_minimum_size = Vector2(_get_stats_table_width(), 26.0)
		empty_label.add_theme_font_size_override("font_size", 14)
		empty_label.add_theme_color_override("font_color", Color(0.76, 0.80, 0.88, 1.0))
		stats_popup_content.add_child(empty_label)
		return

	for stat: Dictionary in units:
		_add_stats_row(_build_stats_row_values(stat), false)


func _build_stats_row_values(stat: Dictionary) -> Array[String]:
	var survival_time: float = float(stat.get("survival_time", 0.0))
	var alive: bool = bool(stat.get("is_alive_at_end", false))
	return [
		str(stat.get("display_name", "未知单位")),
		str(int(stat.get("damage_dealt", 0))),
		str(int(stat.get("damage_taken", 0))),
		str(int(stat.get("healing_done", 0))),
		str(int(stat.get("shield_given", 0))),
		"%0.1f" % float(stat.get("mana_restored", 0.0)),
		str(int(stat.get("kill_count", 0))),
		str(int(stat.get("attack_count", 0))),
		("%0.1f" % survival_time) + "秒",
		"存活" if alive else "阵亡",
	]


func _add_stats_row(values: Array[String], is_header: bool) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.custom_minimum_size = Vector2(_get_stats_table_width(), 28.0)
	row.add_theme_constant_override("separation", 6)
	stats_popup_content.add_child(row)

	var widths: Array[float] = _get_stats_column_widths()
	for index: int in range(values.size()):
		var label: Label = Label.new()
		label.text = values[index]
		label.custom_minimum_size = Vector2(widths[index], 26.0)
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.clip_text = true
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 14 if not is_header else 15)
		if is_header:
			label.add_theme_color_override("font_color", Color(0.78, 0.88, 1.0, 1.0))
		else:
			label.add_theme_color_override("font_color", Color(0.90, 0.93, 0.98, 1.0))
		row.add_child(label)


func _get_stats_column_widths() -> Array[float]:
	return [220.0, 118.0, 118.0, 118.0, 118.0, 110.0, 82.0, 82.0, 118.0, 76.0]


func _get_stats_table_width() -> float:
	var width: float = 0.0
	var widths: Array[float] = _get_stats_column_widths()
	for column_width: float in widths:
		width += column_width
	width += float(maxi(0, widths.size() - 1)) * 6.0
	return width


func _show_reward_panel() -> void:
	reward_panel_controller.show_reward_panel(_get_current_encounter_type())


func _hide_reward_panel() -> void:
	reward_panel_controller.hide_reward_panel()


func _show_hero_selection_panel() -> void:
	hero_selection_panel_controller.show_selection()


func _hide_hero_selection_panel() -> void:
	hero_selection_panel_controller.hide()


func _on_reward_applied(_reward: Dictionary) -> void:
	if run_controller.state == GameState.EVENT:
		_refresh_relic_bar()
		_hide_reward_panel()
		event_panel.visible = true
		event_result_label.text = "已获得遗物"
		event_result_label.visible = true
		event_continue_button.visible = true
		PIXEL_UI_THEME.apply_button_style(event_continue_button, Color(0.15, 0.25, 0.15), Color(0.35, 0.60, 0.35), 2)
		return
	if run_controller.state != GameState.REWARD:
		return

	_hide_stats_button()
	_refresh_relic_bar()
	_hide_reward_panel()
	_try_enter_path_select_or_next_prepare()


func _get_current_encounter_type() -> String:
	var encounter: Dictionary = encounter_manager.get_encounter(run_controller.current_round) as Dictionary
	if encounter.is_empty():
		return ""

	return str(encounter["encounter_type"])
