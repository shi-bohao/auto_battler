# 遗物系统

更新时间：2026-06-02

本文档记录遗物系统的触发类型、效果路径、动态光环和实现入口。精确数值以 `docs/content_reference.md` 为准。

## 核心规则

### 遗物触发类型

当前已实现 6 种触发类型：

| 触发类型 | 触发时机 | 说明 |
| --- | --- | --- |
| `AURA` | 单位生成后 | 常驻光环，实时随条件变化（如金币动态光环） |
| `BATTLE_START` | 战斗开始时 | 一次性临时增益、护盾或初始魔力 |
| `ON_ATTACK` | 普通攻击命中后 | 攻击触发效果 |
| `ON_KILL` | 玩家单位击杀目标后 | 击杀触发，支持本局永久属性成长 |
| `ON_DEATH` | 玩家单位死亡时 | 死亡触发，支持召唤效果 |
| `ON_ROUND_REWARD` | 战斗胜利金币结算时 | 参考 `pre_reward_gold` 计算额外金币 |

### 动态金币光环

金甲契约、黄金护符、贪婪王冠等遗物将实时金币转化为属性加成：
- 通过 `EconomyManager.gold_changed` 信号触发刷新
- `RelicManager.has_dynamic_gold_relics()` 判断是否需要刷新
- 同一帧内多次变化使用 deferred 合并刷新
- 动态 modifier 读取实时金币，按 `floor(gold/step) * per_step` 计算

### 遗物持有规则

- 遗物**不重复获得**同名遗物
- 商店/奖励中的遗物去重逻辑由 `RelicManager` 处理
- 当前共 **43 件遗物**

## 效果触发路径

```
战斗开始 → RelicManager.trigger_battle_start_relics(player_units)
普攻命中 → RelicManager.trigger_attack_relics(attacker, target)
击杀 → RelicManager.trigger_kill_relics(attacker, target, ...)
死亡 → RelicManager.trigger_death_relics(dead_unit, enemy_units, ...)
胜利结算 → RelicManager.trigger_round_reward_relics(...)
单位生成 → RelicManager.apply_always_on_relics_to_runtime_unit(unit)
金币变化 → RelicManager.refresh_dynamic_relic_auras_for_unit(s)
```

## 实现入口

| 内容 | 文件 |
| --- | --- |
| 遗物持有与触发 | `scripts/relic_manager.gd` |
| 效果解析 | `scripts/relic/relic_effect_resolver.gd` |
| 触发分发 | `scripts/relic/relic_trigger_dispatcher.gd` |
| 遗物数据 | `data/relics/*.tres` |
| 遗物奖励池 | `scripts/relic/relic_reward_pool.gd` |
| 动态金币光环 | `scripts/relic/relic_effect_resolver.gd` + `EconomyManager` |
