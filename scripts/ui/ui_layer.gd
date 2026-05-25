class_name UILayer
extends RefCounted


# Keep broad UI categories far apart so local adjustments do not accidentally
# cover unrelated surfaces.
const WORLD_BACKGROUND: int = -100
const WORLD_EFFECT: int = -10

const HUD_BASE: int = 0
const HUD_FLOATING: int = 100
const WORKSPACE_PANEL: int = 200
const DETAIL_PANEL: int = 300
const FLOW_OVERLAY: int = 400
const APP_OVERLAY: int = 500
const SYSTEM_MODAL: int = 600
const FLOATING_POPUP: int = 900

const RESULT_LABEL: int = HUD_BASE + 0
const ROUND_LABEL: int = HUD_BASE + 0
const GOLD_PANEL: int = HUD_BASE + 0
const HERO_EXP_PANEL: int = HUD_BASE + 0
const RELIC_BAR: int = HUD_BASE + 0
const ENCOUNTER_INFO: int = HUD_BASE + 10
const SELL_ZONE: int = HUD_BASE + 20

const HUD_ACTION_BUTTON: int = HUD_FLOATING + 0
const MENU_BUTTON: int = HUD_FLOATING + 10
const BATTLE_SPEED_BUTTON: int = HUD_FLOATING + 10
const MIRROR_INFO_BUTTON: int = HUD_FLOATING + 10
const BOND_PANEL: int = HUD_FLOATING + 20

const SHOP_PANEL: int = WORKSPACE_PANEL + 0
const BENCH_PANEL: int = WORKSPACE_PANEL + 10
const STATS_PANEL: int = WORKSPACE_PANEL + 20

const UNIT_DETAIL: int = DETAIL_PANEL + 0
const RELIC_DETAIL: int = DETAIL_PANEL + 10
const BOND_DETAIL: int = DETAIL_PANEL + 20
const MIRROR_INFO_PANEL: int = DETAIL_PANEL + 30

const HERO_SELECTION: int = FLOW_OVERLAY + 0
const REWARD_PANEL: int = FLOW_OVERLAY + 10
const HERO_SELECTION_POPUP: int = FLOW_OVERLAY + 80

const MAIN_MENU: int = APP_OVERLAY + 0
const ENCYCLOPEDIA: int = APP_OVERLAY + 20

const GAMEPLAY_MENU: int = SYSTEM_MODAL + 0
const GAME_END_DIALOG: int = SYSTEM_MODAL + 10

const HOVER_DETAIL: int = FLOATING_POPUP + 0
