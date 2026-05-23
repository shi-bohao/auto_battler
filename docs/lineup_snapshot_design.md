# Lineup Snapshot Design

玩家在 Boss 遭遇胜利后会保存一份阵容快照，用于后续新的对战模式读取和还原玩家阵容。

## 保存位置

默认保存到：

- `user://lineup_snapshots.json`

选择 JSON 的原因：

- Godot 原生支持 `JSON.stringify()` 和 `JSON.parse_string()`。
- 方便后续模式批量读取、筛选和迁移。
- 不直接序列化 `Resource`，而是保存 `unit_id` / `relic_id` 和 `resource_path`，可解析、可还原。

## 保存时机

入口位于：

- `scripts/main.gd`
- `_on_battle_ended()`

当 `player_won == true` 且当前遭遇 `encounter_type == "BOSS"` 时保存。第 10 / 20 波 Boss 和第 30 波最终 Boss 胜利都会记录。

## 快照结构

顶层字段：

- `schema_version`
- `snapshot_id`
- `created_unix_time`
- `created_datetime`
- `source`
- `run`
- `global_effects`
- `units`
- `relics`

`units.active` 和 `units.bench` 会保存：

- `unit_id`
- `resource_path`
- `display_name`
- `star`
- `base_price`
- `roster_id`
- `saved_cell`
- `saved_position`

`relics` 会保存：

- `relic_id`
- `resource_path`
- `name`
- `rarity`
- `trigger_type`
- `value`

`global_effects` 当前保存：

- `player_hp_multiplier`
- `player_attack_multiplier`
- `max_active_units`
- `max_total_units`
- `unlocked_unit_ids`

## 还原入口

主要入口：

- `LineupSnapshotManager.load_all_snapshots()`
- `LineupSnapshotManager.load_latest_snapshot()`
- `LineupSnapshotManager.parse_snapshot(snapshot, roster_manager, relic_manager)`
- `LineupSnapshotManager.restore_snapshot_to_managers(snapshot, roster_manager, relic_manager)`

`RosterManager.restore_lineup_snapshot()` 用于还原单位、星级、站位和全局倍率。

`RelicManager.restore_relic_ids()` 用于按 `relic_id` 还原遗物。
