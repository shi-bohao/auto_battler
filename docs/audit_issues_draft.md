# 文档审计剩余问题草稿

> 本文件只保留尚未处理或本轮明确暂缓的问题。已修复的 combat/progression/ui 文档问题，以及精英路径强制遭遇代码问题，已从草稿中剔除。

## 暂缓：镜像挑战与阵容快照

这些问题与镜像挑战还原规则有关，本轮按要求暂时搁置，后续需要先确认设计目标：镜像挑战是否要完整还原玩家通关阵容的永久成长和全局强化，还是只还原单位、星级、基础 HP/攻击倍率和遗物列表。

| # | 文档 | 问题 | 当前实现核对 |
|---|---|---|---|
| M14 | `docs/systems/snapshot_and_mirror.md` | `global_effects` 字段列表只列出 `player_hp_multiplier`、`player_attack_multiplier`、`max_active_units`、`max_total_units`、`unlocked_unit_ids`，遗漏 `global_stat_bonuses` 与 `has_death_prevention`。 | `LineupSnapshotManager._build_global_effects_snapshot()` 实际保存 7 个字段。 |
| L9 | `docs/systems/snapshot_and_mirror.md` | 文档写明镜像单位会还原 `permanent_stat_bonuses`，但镜像敌人构建时没有把该字段带入缩放流程。 | `MirrorChallengeManager._build_mirror_enemy_units()` 当前只传 `unit_id/resource_path/star/cell/hp_multiplier/attack_multiplier` 等。 |
| L10 | `docs/systems/snapshot_and_mirror.md` | 同一 Boss 波次存在多个快照时的随机选择行为未在文档中明确。 | `MirrorChallengeManager._pick_snapshot_for_round()` 会在候选中随机选择。 |
| L11 | `docs/systems/snapshot_and_mirror.md` | 快照结构中 `run` 字段未展开列出。 | `LineupSnapshotManager._build_run_snapshot()` 保存 `current_round`、`max_round`、`encounter_type`、`encounter_name`、`gold`。 |
| L12 | `docs/systems/snapshot_and_mirror.md` | “第 10/20/30 波 Boss”容易被理解为保存条件会检查具体波次。 | 当前保存入口实际以 `encounter_type == "BOSS"` 为主。 |

