# 召唤系统

更新时间：2026-06-02

本文档记录召唤系统的核心规则、召唤物管理和实现入口。精确数值以 `docs/content_reference.md` 为准。

## 核心规则

### 召唤物分类

当前项目有 8 种正式召唤物（位于 `data/summons/`），外加 2 种由敌方单位分裂产生的类召唤物：

**正式召唤物（8 种）**：

| 召唤物 | ID | 定位 | 攻击类型 | 来源 |
| --- | --- | --- | --- | --- |
| 骷髅 / Skeleton | `summoned_skeleton` | 近战 | 近战 | 亡灵法师主动、唤墓者主动、运骨者死亡、击杀触发 |
| 骷髅弓箭手 / Skeleton Archer | `summoned_skeleton_archer` | 远程物理 | 弹道(arrow) | 天灾领主主动 |
| 骷髅法师 / Skeleton Mage | `summoned_skeleton_mage` | 远程法术 | 弹道(dark) | 天灾领主主动 |
| 骷髅战士 / Skeleton Warrior | `summoned_skeleton_warrior` | 近战坦克 | 近战 | 天灾领主主动 |
| 傀儡 / Puppet | `summoned_puppet` | 近战坦克 | 近战 | 傀儡术士标记、傀儡缚师标记 |
| 魂偶 / Soul Puppet | `summoned_soul_puppet` | 近战坦克 | 近战 | 缚魂祭司主动 |
| 骨巨人 / Bone Golem | `summoned_bone_golem` | 近战坦克 | 近战 | 织骨者英雄主动 |
| 骨龙 / Bone Dragon | `summoned_bone_dragon` | 远程范围 | 近战(溅射) | 织骨者英雄主动（Lv.4+） |

**敌人分裂产生的类召唤物**（位于 `data/enemies/`，也走召唤系统）：

| 单位 | ID | 来源 |
| --- | --- | --- |
| 巨型蛆虫 / Giant Maggot | `enemy_giant_maggot` | 蛆虫聚合体死亡分裂 |
| 巨型史莱姆 / Giant Slime | `enemy_giant_slime` | 巨型史莱姆死亡分裂 |

### 召唤上限

- **默认单位召唤上限**：3（`DEFAULT_UNIT_SUMMON_CAP`）
- **按来源管理**：上限按 `source_key` 独立计算，同一来源共享一个上限池
- **特殊上限**：
  - 骨巨人 / 骨龙：各独立上限 1（织骨者英雄技能控制）
  - 蛆虫聚合体分裂：上限 4
  - 巨型史莱姆分裂：上限 2（受 `slime_split_count` 限制）
  - 天灾领主（Boss）主动亡灵小队：`boss_undead_warband`，上限 6（`active_skill_caster.gd`）
  - 天灾领主（Boss）被动亡者复苏：`boss_raise_the_fallen`，上限 6（`passive_resolver.gd`）
- **遗物召唤**：由遗物效果本身决定数量，不占用单位召唤上限

### 胜负判定

- 召唤物**默认参与**胜负判定（`META_SUMMON_AFFECTS_RESULT`，默认 `true`）
- 可通过 `context["affects_battle_result"]` 覆写
- 限时召唤物在存续期间内参与判定

### 召唤生命周期

1. `SummonManager.summon_units()` — 创建召唤单位并注册到 `active_unit_summons_by_source`
2. 召唤物死亡 → `handle_unit_death()` 注销、处理死亡触发召唤（分裂/史莱姆亡语等）
3. 召唤物击杀目标 → `handle_unit_killed_target()` 处理击杀触发召唤
4. 战斗结束 → `BattleManager` 清理所有召唤物

## 实现入口

| 内容 | 文件 |
| --- | --- |
| 召唤管理 | `scripts/summon_manager.gd` |
| 正式召唤物数据 | `data/summons/*.tres`（8 个） |
| 分裂用敌人数据 | `data/enemies/giant_maggot.tres`、`data/enemies/giant_slime.tres` |
| 单位召唤技能 | `scripts/combat/active_skill_caster.gd` |
| 单位被动/分裂类死亡召唤 | `scripts/summon_manager.gd` |
| 遗物「骸骨坠饰」死亡召唤 | `scripts/relic/relic_trigger_dispatcher.gd` → `scripts/relic/relic_effect_resolver.gd`（`apply_gravebone_charm_relic`） |
| 分裂/亡语召唤 | `scripts/summon_manager.gd` |
