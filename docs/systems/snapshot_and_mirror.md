# 阵容快照与镜像挑战

更新时间：2026-06-02

---

## 一、阵容快照 / Lineup Snapshot

玩家在 Boss 遭遇胜利后会保存一份阵容快照，用于镜像挑战模式读取和还原玩家阵容。

### 保存位置

`user://lineup_snapshots.json`

选择 JSON：Godot 原生支持，方便批量读取和迁移。不直接序列化 `Resource`，而是保存 `unit_id`/`relic_id` + `resource_path`。

### 保存时机

入口：`scripts/main.gd` → `_on_battle_ended()`

当 `player_won == true` 且 `encounter_type == "BOSS"` 时保存（第 10/20/30 波 Boss）。

### 快照结构

- `schema_version`、`snapshot_id`、`created_unix_time`、`created_datetime`、`source`、`run`
- `global_effects`：`player_hp_multiplier`、`player_attack_multiplier`、`max_active_units`、`max_total_units`、`unlocked_unit_ids`
- `units.active` / `units.bench`：`unit_id`、`resource_path`、`display_name`、`star`、`base_price`、`roster_id`、`saved_cell`、`saved_position`、`permanent_stat_bonuses`
- `relics`：`relic_id`、`resource_path`、`name`、`rarity`、`trigger_type`、`value`

`permanent_stat_bonuses` 保存本局永久属性成长（如 Blood Oath Chalice 写入的 max_hp）。

### 还原入口

- `LineupSnapshotManager.load_all_snapshots()`
- `LineupSnapshotManager.load_latest_snapshot()`
- `RosterManager.restore_lineup_snapshot()`
- `RelicManager.restore_relic_ids()`

---

## 二、镜像挑战 / Mirror Challenge

镜像挑战是一个与主模式总波次相同的新模式。普通波/精英波保持原有规则；Boss 波替换为玩家历史 Boss 胜利时保存的通关阵容。

### 模式入口

主菜单提供"经典模式"和"镜像挑战"两个入口。运行状态记录在 `RunController.game_mode`（`CLASSIC` / `MIRROR_CHALLENGE`）。

### 镜像选择规则

入口：`scripts/game/mirror_challenge_manager.gd`

1. 优先选择历史快照中 `run.current_round` 等于当前 Boss 波的快照
2. 无对应波次快照时，从所有 `BOSS_VICTORY` 快照中随机选择
3. 无任何历史快照时，回退为原始 Boss 遭遇

结果锁定在 `MirrorChallengeManager.selected_snapshots_by_round`。

### Boss 替换规则

- 镜像 Boss 波保持 `encounter_type = "BOSS"`，胜利/奖励/通关判断沿用主模式
- 使用快照 `units.active` 加载玩家单位资源，`star` 还原星级，`saved_cell` 左右镜像到敌方半场
- `permanent_stat_bonuses` 还原本局永久属性成长
- `global_effects` 倍率应用到镜像单位
- 快照遗物还原为敌方 `RelicManager`

### 查看方式

准备阶段显示"镜像阵容"按钮，可查看本局所有已锁定 Boss 镜像阵容。遭遇信息面板显示当前镜像阵容、全局倍率和遗物摘要。

### 关键文件

- `scripts/game/mirror_challenge_manager.gd`
- `scripts/game/run_controller.gd`
- `scripts/encounter_manager.gd`
- `scripts/battle_manager.gd`
- `scripts/ui/menu_panel_controller.gd`
- `scripts/main.gd`
- `scenes/ui/main_menu_panel.tscn`
