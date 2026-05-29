# 控制效果测试单位设计与实现文档

更新时间：2026-05-29

本文档为后续控制效果系统设计 5 个用于实战测试的玩家单位，每个单位聚焦一种控制效果：减速、禁锢、眩晕、冻结、嘲讽。当前文档只提供设计与实现方案，不直接新增资源或脚本。

相关前置文档：

- `docs/control_effect_system_design.md`：控制效果系统设计。
- `docs/unit_design.md`：玩家单位设计参考。
- `docs/content_reference.md`：当前单位、敌人、召唤物和遗物数据总览。

## 设计目标

1. 每个控制效果至少有一个玩家单位可以稳定触发，便于在真实战斗中验证。
2. 单位机制尽量单纯，避免混入过多伤害、召唤、羁绊或经济机制导致测试结果不清晰。
3. 控制效果覆盖普攻触发、主动技能触发、单体、范围、强制目标等典型入口。
4. 第一版全部作为正式玩家单位设计，但数值偏保守，避免控制系统上线后破坏战斗节奏。
5. 所有控制通过 `StatusEffectFactory.apply_control_effect()` 进入系统，不在技能逻辑里直接修改移动、攻击、施法或索敌字段。

## 新单位总览

| 控制 | 单位 | ID | 稀有度 | 定位 | 羁绊建议 | 测试重点 |
| --- | --- | --- | --- | --- | --- | --- |
| 减速 | 霜箭哨手 / Frost Sentry | `frost_sentry` | FINE | 后排输出/软控 | 猎手、奥术 | 多个减速取最强；减速不影响攻击和施法 |
| 禁锢 | 藤缚卫士 / Vine Binder | `vine_binder` | RARE | 辅助/控制 | 圣疗、召唤 | 不能移动但可攻击/施法；目标不在范围时原地等待 |
| 眩晕 | 震锤先锋 / Thundermaul Vanguard | `thundermaul_vanguard` | RARE | 前排/硬控 | 铁壁 | 硬控禁止移动、普攻、施法；满魔不被清空 |
| 冻结 | 冰棱术士 / Frost Prism Mage | `frost_prism_mage` | EPIC | 法术/硬控 | 奥术 | 冻结版眩晕；后续验证技能伤害易伤 |
| 嘲讽 | 挑衅旗手 / Taunt Banneret | `taunt_banneret` | RARE | 前排/目标控制 | 铁壁、圣疗 | forced target、禁止重选目标、嘲讽来源失效 |

## 1. 霜箭哨手 / Frost Sentry

### 定位

后排远程软控单位，用普攻稳定施加减速，主动技能施加更强减速。用于验证减速聚合规则和远程弹道命中后施加控制。

### 数据建议

```gdscript
unit_type = "frost_sentry"
unit_name_cn = "霜箭哨手"
description_cn = "后排软控射手，普攻和主动技能都能降低敌人移动速度。"
role = "damage"
rarity = "FINE"
price = 4
bond_tags = ["hunter", "arcane"]

max_hp = 95
attack_damage = 18
defense = 0
attack_interval = 1.20
attack_range = 150.0
move_speed = 95.0
max_mana = 80
mana_regen_per_second = 12.0
target_mode = "NEAREST"
basic_attack_type = "projectile"
projectile_speed = 580.0
projectile_visual_type = "arrow"
passive_id = "frost_arrow"
active_skill_id = "pinning_frost"
```

### 被动：霜箭 / `frost_arrow`

效果：

- 普攻命中后，对目标施加 2 秒减速。
- 减速倍率：`move_speed_multiplier = 0.70`。
- 2 星：减速倍率提升到 `0.65`。
- 3 星：减速持续时间提升到 3 秒。

控制数据：

```gdscript
{
    "effect_id": "frost_arrow_slow",
    "control_type": "SLOW",
    "duration": 2.0,
    "move_speed_multiplier": 0.70,
    "stack_key": "slow",
    "source_mode": "PER_SOURCE",
    "stack_policy": "REFRESH_LONGER_DURATION"
}
```

### 主动：钉霜箭 / `pinning_frost`

效果：

- 对当前目标造成 `160%` 攻击力技能伤害。
- 对目标施加 3 秒强减速。
- 强减速倍率：`move_speed_multiplier = 0.45`。
- 3 星：额外对目标周围 80 范围内敌人施加 2 秒普通减速，倍率 `0.70`。

控制测试点：

- 普攻 0.70 减速和主动 0.45 减速同时存在时，最终移动倍率应为 0.45。
- 主动强减速过期后，如果普攻减速仍在，应恢复到 0.70。
- 减速期间敌人仍能攻击和施法。

### 实现入口

- `data/units/frost_sentry.tres`
- `scripts/combat/passive_resolver.gd`
  - 新增 `frost_arrow` 的 `attack_landed` 处理。
- `scripts/combat/active_skill_caster.gd`
  - 新增 `pinning_frost`。
- `scripts/unit_text_formatter.gd`
  - 新增被动和主动技能文本。

## 2. 藤缚卫士 / Vine Binder

### 定位

中后排控制辅助，通过主动技能禁锢敌人。用于验证“不能移动但可以攻击/施法”的控制语义。

### 数据建议

```gdscript
unit_type = "vine_binder"
unit_name_cn = "藤缚卫士"
description_cn = "控制型辅助，能用藤蔓禁锢敌人，限制其接近后排。"
role = "support"
rarity = "RARE"
price = 6
bond_tags = ["divine", "summon"]

max_hp = 125
attack_damage = 13
defense = 5
attack_interval = 1.30
attack_range = 125.0
move_speed = 90.0
max_mana = 90
mana_regen_per_second = 13.0
target_mode = "NEAREST"
basic_attack_type = "projectile"
projectile_speed = 430.0
projectile_visual_type = "magic"
passive_id = "tangled_growth"
active_skill_id = "vine_snare"
```

### 被动：缠生 / `tangled_growth`

效果：

- 每当自身主动技能成功禁锢敌人时，为最低生命比例友军提供 `18 + 60% 攻击力` 护盾。
- 2 星：护盾提高到 `24 + 70% 攻击力`。
- 3 星：如果被护盾目标生命低于 40%，额外治疗 20。

设计目的：

- 被动本身不施加控制，避免测试禁锢时触发频率过高。
- 同时让该单位在实战中有辅助价值。

### 主动：藤蔓禁锢 / `vine_snare`

效果：

- 对当前目标造成 `120%` 攻击力技能伤害。
- 禁锢目标 2.5 秒。
- 2 星：持续时间 3 秒。
- 3 星：额外禁锢目标周围 70 范围内 1 个最近敌人 1.5 秒。

控制数据：

```gdscript
{
    "effect_id": "vine_snare_root",
    "control_type": "ROOT",
    "duration": 2.5,
    "disable_movement": true,
    "stack_key": "root",
    "source_mode": "PER_SOURCE",
    "stack_policy": "REFRESH_LONGER_DURATION"
}
```

控制测试点：

- 被禁锢敌人如果当前目标在攻击范围内，应继续攻击。
- 被禁锢敌人如果目标不在攻击范围内，应原地等待。
- 被禁锢敌人满魔后仍可释放主动技能。
- 禁锢和减速同时存在时，禁锢期间不能移动；禁锢结束后减速若未过期继续生效。

### 实现入口

- `data/units/vine_binder.tres`
- `scripts/combat/active_skill_caster.gd`
  - 新增 `vine_snare`。
- `scripts/combat/passive_resolver.gd`
  - 可新增主动技能成功后回调，或在 `active_skill_caster` 内直接处理该单位被动。
- `scripts/unit_text_formatter.gd`
  - 新增技能文本。

## 3. 震锤先锋 / Thundermaul Vanguard

### 定位

前排硬控坦克，用低频眩晕验证硬控对移动、普攻、主动技能的完整禁止。数值应偏坦，不做高输出。

### 数据建议

```gdscript
unit_type = "thundermaul_vanguard"
unit_name_cn = "震锤先锋"
description_cn = "前排硬控坦克，能用重锤打断敌人的行动。"
role = "tank"
rarity = "RARE"
price = 6
bond_tags = ["iron_wall"]

max_hp = 260
attack_damage = 15
defense = 24
attack_interval = 1.25
attack_range = 55.0
move_speed = 65.0
max_mana = 100
mana_regen_per_second = 10.0
target_mode = "NEAREST"
basic_attack_type = "melee"
passive_id = "concussive_armor"
active_skill_id = "hammer_stun"
```

### 被动：震荡护甲 / `concussive_armor`

效果：

- 自身受到护盾后的生命伤害降低 10%。
- 如果当前目标处于眩晕，自身对其造成的普攻伤害提高 20%。
- 3 星：生命伤害降低提高到 15%。

设计目的：

- 被动可以帮助观察眩晕状态是否被正确识别。
- 伤害加成只对眩晕目标生效，避免平时输出过强。

### 主动：震锤重击 / `hammer_stun`

效果：

- 对当前目标造成 `150%` 攻击力技能伤害。
- 眩晕目标 1.25 秒。
- 2 星：眩晕持续 1.5 秒。
- 3 星：对目标周围 60 范围内最近 1 个敌人造成 80% 攻击力伤害，并眩晕 0.75 秒。

控制数据：

```gdscript
{
    "effect_id": "hammer_stun",
    "control_type": "STUN",
    "duration": 1.25,
    "disable_movement": true,
    "disable_attack": true,
    "disable_cast": true,
    "stack_key": "stun",
    "source_mode": "PER_SOURCE",
    "stack_policy": "REFRESH_LONGER_DURATION"
}
```

控制测试点：

- 眩晕期间目标不能移动、普攻或施法。
- 眩晕期间目标魔力继续恢复。
- 眩晕期间满魔不能释放；眩晕结束后如果魔力仍满，应能释放。
- 攻击冷却继续计时，眩晕结束后可立即攻击。
- 攻击者眩晕前发出的 projectile 不被取消。

### 实现入口

- `data/units/thundermaul_vanguard.tres`
- `scripts/combat/active_skill_caster.gd`
  - 新增 `hammer_stun`。
- `scripts/combat/passive_resolver.gd`
  - 新增 `concussive_armor`。
- `scripts/unit_text_formatter.gd`
  - 新增技能文本。

## 4. 冰棱术士 / Frost Prism Mage

### 定位

奥术控制法师，用主动技能冻结敌人。第一版可先把冻结实现为带显示标签的眩晕；第二阶段用于验证“受到技能伤害提高”。

### 数据建议

```gdscript
unit_type = "frost_prism_mage"
unit_name_cn = "冰棱术士"
description_cn = "法术控制单位，能冻结敌人并放大后续技能伤害。"
role = "damage"
rarity = "EPIC"
price = 8
bond_tags = ["arcane"]

max_hp = 95
attack_damage = 28
defense = 0
attack_interval = 1.45
attack_range = 145.0
move_speed = 80.0
max_mana = 110
mana_regen_per_second = 12.0
target_mode = "LOWEST_HP"
basic_attack_type = "projectile"
projectile_speed = 460.0
projectile_visual_type = "magic"
passive_id = "shatter_focus"
active_skill_id = "frost_prison"
```

### 被动：碎冰聚焦 / `shatter_focus`

效果：

- 自身对被冻结目标造成的主动技能伤害提高 20%。
- 如果控制系统阶段 B 已实现冻结技能易伤，则该加成与目标的冻结易伤相乘。
- 3 星：如果主动技能击杀被冻结目标，恢复 30 魔力。

设计目的：

- 帮助验证冻结标签、技能伤害上下文、击杀后回魔是否正常。
- 如果第一版冻结还未接入技能易伤，该被动仍可作为自身侧验证。

### 主动：冰棱囚牢 / `frost_prison`

效果：

- 以当前目标为中心，对 90 范围内最多 3 个敌人造成 `170%` 攻击力技能伤害。
- 冻结主目标 1.5 秒。
- 周围目标冻结 0.8 秒。
- 2 星：主目标冻结 1.8 秒。
- 3 星：范围提高到 110，最多命中 4 个敌人。

控制数据：

```gdscript
{
    "effect_id": "frost_prison_freeze",
    "control_type": "FREEZE",
    "duration": 1.5,
    "disable_movement": true,
    "disable_attack": true,
    "disable_cast": true,
    "skill_damage_taken_multiplier": 1.10,
    "stack_key": "freeze",
    "source_mode": "PER_SOURCE",
    "stack_policy": "REFRESH_LONGER_DURATION"
}
```

控制测试点：

- 阶段 A：冻结表现应与眩晕相同，但 UI 显示为 FREEZE。
- 阶段 B：冻结目标只受到技能伤害提高，不提高普攻、DoT、遗物伤害。
- 多个冻结同时存在时，行动限制不叠加；技能承伤倍率取最大。
- Boss 冻结时长应受到硬控缩减影响。

### 实现入口

- `data/units/frost_prism_mage.tres`
- `scripts/combat/active_skill_caster.gd`
  - 新增 `frost_prison`。
- `scripts/combat/passive_resolver.gd`
  - 新增 `shatter_focus`。
- `scripts/combat/combat_resolver.gd`
  - 阶段 B 需要 `resolve_skill_damage()`。
- `scripts/unit_text_formatter.gd`
  - 新增技能文本。

## 5. 挑衅旗手 / Taunt Banneret

### 定位

前排目标控制坦克，主动技能嘲讽敌人，让敌人强制攻击自身。用于验证 `forced_target`、禁止重选目标和嘲讽来源失效。

### 数据建议

```gdscript
unit_type = "taunt_banneret"
unit_name_cn = "挑衅旗手"
description_cn = "前排目标控制单位，能迫使敌人转火自身。"
role = "tank"
rarity = "RARE"
price = 6
bond_tags = ["iron_wall", "divine"]

max_hp = 285
attack_damage = 11
defense = 28
attack_interval = 1.20
attack_range = 55.0
move_speed = 60.0
max_mana = 90
mana_regen_per_second = 10.0
target_mode = "NEAREST"
basic_attack_type = "melee"
passive_id = "banner_guard"
active_skill_id = "challenge_banner"
```

### 被动：护旗姿态 / `banner_guard`

效果：

- 自身被至少 1 个敌人嘲讽锁定时，获得 12% 伤害减免。
- 每多 1 个被自身嘲讽的敌人，额外获得 4 护盾强度，最多计算 4 个敌人。
- 3 星：被嘲讽敌人攻击自身时，自身恢复 3 魔力。

设计目的：

- 通过被动可以验证“哪些敌人当前被该单位嘲讽”。
- 让嘲讽单位在实战中能承受转火。

### 主动：挑战旗帜 / `challenge_banner`

效果：

- 嘲讽当前目标和自身周围 120 范围内最多 2 个敌人，持续 3 秒。
- 自身获得 `40 + 15% 最大生命` 护盾。
- 2 星：嘲讽数量提高到最多 3 个。
- 3 星：嘲讽持续时间提高到 3.5 秒，并额外获得 20 防御，持续 3.5 秒。

控制数据：

```gdscript
{
    "effect_id": "challenge_banner_taunt",
    "control_type": "TAUNT",
    "duration": 3.0,
    "disable_retarget": true,
    "forced_target": unit,
    "forced_target_unit_id": unit.unit_id,
    "stack_key": "taunt",
    "source_mode": "GLOBAL",
    "stack_policy": "REPLACE_BY_LAST"
}
```

控制测试点：

- 被嘲讽敌人当前目标应切换为旗手。
- 如果攻击范围不足，应向旗手移动。
- 如果被禁锢且打不到旗手，应原地等待。
- 被眩晕时嘲讽仍计时，眩晕结束后继续攻击旗手。
- 旗手死亡、不可选中或被清理时，嘲讽应失效并恢复正常索敌。
- 低血优先敌人被嘲讽后，不应因 `retarget_interval` 切回低血目标。
- 敌方目标型主动技能应优先以旗手为目标；治疗和友方增益不受嘲讽影响。

### 实现入口

- `data/units/taunt_banneret.tres`
- `scripts/combat/active_skill_caster.gd`
  - 新增 `challenge_banner`。
  - 增加敌方目标技能统一取目标入口。
- `scripts/combat/passive_resolver.gd`
  - 新增 `banner_guard`。
- `scripts/unit_targeting.gd`
  - forced target、禁止重选、卡住检测例外。
- `scripts/unit_text_formatter.gd`
  - 新增技能文本。

## 实现顺序建议

建议不要一次性把 5 个单位全部实现。更稳的顺序：

1. 实现控制系统基础：`CONTROL` 状态、`UnitControlState`、移动/普攻/施法读取。
2. 实现霜箭哨手，验证 Slow。
3. 实现藤缚卫士，验证 Root。
4. 实现震锤先锋，验证 Stun。
5. 实现挑衅旗手，验证 Taunt。嘲讽牵涉索敌和主动技能目标，风险比前 3 个高。
6. 实现冰棱术士阶段 A，验证 Freeze 作为硬控。
7. 补充 `resolve_skill_damage()` 后，实现冰棱术士阶段 B 的技能易伤。

## 资源与代码接入清单

新增资源：

```text
data/units/frost_sentry.tres
data/units/vine_binder.tres
data/units/thundermaul_vanguard.tres
data/units/frost_prism_mage.tres
data/units/taunt_banneret.tres
```

需要修改：

```text
scripts/combat/status_effect_factory.gd
scripts/status_effect.gd
scripts/unit_effect_controller.gd
scripts/combat/unit_control_state.gd
scripts/unit.gd
scripts/unit_targeting.gd
scripts/unit_skill.gd
scripts/combat/active_skill_caster.gd
scripts/combat/passive_resolver.gd
scripts/combat/combat_resolver.gd
scripts/unit_text_formatter.gd
scripts/catalog/unit_catalog.gd
scripts/tools/generate_content_reference.gd
docs/content_reference.md
```

可选修改：

```text
scripts/ui/unit_detail_panel_controller.gd
scripts/ui/encyclopedia_panel_controller.gd
scripts/tests/test_control_effect_system.gd
```

## 测试阵容建议

### Slow 测试

玩家：

- 霜箭哨手 x1
- 任意前排 x1

敌方：

- 近战敌人 x2

验证：

- 敌人移动速度下降。
- 敌人仍能普攻和释放技能。
- 强减速覆盖弱减速，强减速过期后弱减速继续生效。

### Root 测试

玩家：

- 藤缚卫士 x1
- 任意前排 x1

敌方：

- 近战敌人 x1
- 远程敌人 x1

验证：

- 近战被禁锢且目标不在范围时原地等待。
- 远程被禁锢但目标在范围内时继续攻击。
- 被禁锢单位满魔后仍能施法。

### Stun 测试

玩家：

- 震锤先锋 x1
- 任意输出 x1

敌方：

- 高攻速近战敌人 x1
- 远程 projectile 敌人 x1

验证：

- 眩晕期间不能移动、攻击、施法。
- 眩晕期间攻击冷却继续走。
- 已发射 projectile 不取消。

### Freeze 测试

玩家：

- 冰棱术士 x1
- 法师或奥术炮师 x1

敌方：

- 普通敌人 x3

验证：

- 阶段 A：冻结行动限制与眩晕一致。
- 阶段 B：只增强主动技能伤害。
- 普攻和 DoT 不被冻结易伤放大。

### Taunt 测试

玩家：

- 挑衅旗手 x1
- 低血后排输出 x1

敌方：

- LOWEST_HP 模式敌人 x2
- 远程敌人 x1

验证：

- 敌人从低血后排转向旗手。
- 嘲讽期间不因低血重选目标。
- 旗手死亡后敌人恢复正常索敌。
- 敌方治疗技能不被嘲讽错误改向旗手。

## 验收标准

1. 每个控制效果至少有一个单位可以在真实战斗中稳定触发。
2. 五个单位能进入商店、图鉴和内容总览。
3. 控制效果均通过 `StatusEffectFactory.apply_control_effect()` 施加。
4. 控制持续时间受 `status_resistance` 与控制抗性影响。
5. 控制状态在单位死亡、战斗结束、Restart 后清空。
6. 嘲讽不产生 previously freed 相关错误。
7. 冻结阶段 A 不阻塞控制系统上线；阶段 B 有明确技能伤害入口后再启用易伤。
8. 新单位不会破坏现有遗物、羁绊、召唤、弹道、AoE 和奖励系统。
