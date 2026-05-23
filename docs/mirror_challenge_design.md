# Mirror Challenge Design

镜像挑战是一个与主模式总波次相同的新模式。普通波、精英波保持原有生成规则；原 Boss 波会被替换为玩家历史 Boss 胜利时保存的通关阵容。

## 模式入口

主菜单提供两个入口：

- `开始游戏`：经典模式。
- `镜像挑战`：进入镜像挑战。

运行状态记录在 `RunController.game_mode`：

- `CLASSIC`
- `MIRROR_CHALLENGE`

## 镜像选择规则

入口：

- `scripts/game/mirror_challenge_manager.gd`

进入镜像挑战时，会读取：

- `user://lineup_snapshots.json`

并在开局时为所有 Boss 波锁定镜像阵容。当前总波次为 30，因此会锁定第 10 / 20 / 30 波。

选择规则：

1. 优先选择历史快照中 `run.current_round` 等于当前 Boss 波的快照。
2. 如果没有对应波次快照，则从所有 `BOSS_VICTORY` 快照中随机选择。
3. 如果完全没有历史快照，则该 Boss 波回退为原始 Boss 遭遇。

选定结果保存在本局 `MirrorChallengeManager.selected_snapshots_by_round` 中，不会在后续波次重新随机。

## Boss 替换规则

镜像 Boss 波仍保持 `encounter_type = "BOSS"`，因此胜利、奖励、最终通关判断沿用主模式。

镜像敌方阵容使用快照中的 `units.active`：

- `unit_id` 和 `resource_path` 用于加载玩家单位资源。
- `star` 用于还原星级。
- `saved_cell` 会左右镜像到敌方半场。
- `global_effects.player_hp_multiplier` 和 `player_attack_multiplier` 会应用到镜像单位。

快照中的遗物会还原为敌方 `RelicManager`，并在该 Boss 战中以敌方队伍为拥有者触发。

## 查看方式

镜像挑战准备阶段会显示 `镜像阵容` 按钮。点击后可以查看本局已锁定的所有 Boss 镜像阵容。

当前波次如果是镜像 Boss，遭遇信息面板也会显示该波镜像阵容、全局倍率和遗物摘要。

## 关键文件

- `scripts/game/mirror_challenge_manager.gd`
- `scripts/game/run_controller.gd`
- `scripts/encounter_manager.gd`
- `scripts/battle_manager.gd`
- `scripts/ui/menu_panel_controller.gd`
- `scripts/main.gd`
- `scenes/ui/main_menu_panel.tscn`
