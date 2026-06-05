# Unit Design Document

> 维护提示：当前单位数值与技能描述以自动生成的 `docs/content_reference.md` 为权威来源。本文档保留设计原则、伤害/升星规则、技能设计意图和新单位设计模板。新增玩家单位资源应放入 `data/units`，召唤物放入 `data/summons`，敌人放入 `data/enemies`。

When adding a new unit, add its design here first. Implementation should create the matching `.tres` resource and update the relevant registration points:

- `scripts/unit_data.gd` only when the shared UnitData schema needs a new exported field
- `data/units/*.tres` / `data/summons/*.tres` / `data/enemies/*.tres`
- `scripts/combat/passive_resolver.gd`, `scripts/combat/active_skill_caster.gd`, or related combat resolver files when adding new skill logic
- `scripts/catalog/unit_catalog.gd`, `scripts/roster_manager.gd`, or encounter catalogs when the unit needs to enter a runtime pool
- `scripts/unit_text_formatter.gd` and `scripts/tools/generate_content_reference.gd` when skill or content reference text needs to be shown
- shop, encounter, or reward pools if the unit should appear there

## 设计原则

### 职业/羁绊定位

| 职业 | 定位关键词 | 代表单位 |
| --- | --- | --- |
| 坦克 (Tank) | 前排承伤、高生命/防御、减伤、护盾 | Warrior, Tank, Guardian Captain |
| 输出 (Damage) | 后排远程/近战爆发、暴击、技能伤害 | Archer, Assassin, Mage |
| 辅助 (Support) | 治疗、护盾、增益、召唤 | Priest, Bard, Soul Binder |

### 羁绊设计方向

- **铁壁**：前排承伤与护盾联动，适合持久战
- **猎手**：暴击与收割，低血量目标增伤
- **奥术**：技能爆发与魔力循环
- **圣疗**：治疗溢出、护盾转化与死亡预防
- **剧毒**：毒层叠加与引爆
- **召唤**：数量压制与阵亡转化

## Runtime Attribute Model

`UnitData` 支持的核心字段（完整枚举以 `scripts/unit_data.gd` 和 `content_reference.md` 为准）：

Runtime combat bonuses are layered through `UnitStatController` in the order `BASE_OVERRIDE -> PERMANENT_FLAT -> PERMANENT_PERCENT -> RUNTIME_FLAT -> RUNTIME_PERCENT -> FINAL_FLAT -> FINAL_PERCENT -> FINAL_MULTIPLY`.

核心字段（详细默认值见 `UnitData` 资源定义）：

| 分类 | 字段 | 说明 |
| --- | --- | --- |
| 标识 | `unit_type`, `unit_name`, `unit_name_cn`, `description_cn` | 单位 ID 与显示名 |
| 定位 | `role` (tank/damage/support), `bond_tags`, `rarity`, `star` | 职业、羁绊、稀有度、星级 |
| 战斗 | `max_hp`, `attack_damage`, `defense`, `crit_chance`, `crit_damage_multiplier` | 基础战斗属性 |
| 技能 | `skill_power`, `healing_power`, `shield_power`, `max_mana`, `mana_regen_per_second` | 技能与魔力 |
| 生存 | `life_steal`, `damage_reduction`, `dodge_chance`, `status_resistance` | 生存属性 |
| 节奏 | `attack_interval`, `attack_range`, `search_range`, `move_speed` | 攻速、射程、移速 |
| 索敌 | `target_mode` (NEAREST/LOWEST_HP), `retarget_interval`, `lowest_hp_switch_threshold` | 目标选择 |
| 技能ID | `passive_id`, `active_skill_id` | 技能绑定 |
| 表现 | `basic_attack_type`, `projectile_speed`, `projectile_visual_type`, `board_sprite`, `portrait_texture`, `icon_texture` | 视觉表现 |

## Damage Rules

1. 从基础伤害开始
2. 判定暴击（`crit_chance`），暴击时乘以 `crit_damage_multiplier`
3. 应用防御减伤：`damage_after_defense = damage_after_crit * 100 / (100 + defense)`
4. 取整后先进护盾，剩余进 HP
5. 被动减伤在护盾后、HP 损失前应用（如 armor、fortress）
6. 有效伤害计入战斗统计
7. 遗物伤害默认不暴击，但走同一护盾/HP 伤害路径

## Star Growth Rules

Star growth is applied only when creating runtime battle `UnitData` from the player roster. Original `.tres` resources are not modified.

Growth fields: `max_hp_multiplier`, `attack_damage_multiplier`, `defense_bonus`, `attack_interval_multiplier`, `move_speed_multiplier`, `crit_chance_bonus`, `crit_damage_multiplier_bonus`.

Sell price based on unit price and star:

| Star | Sell Price |
| --- | --- |
| 1 | `price * 1` |
| 2 | `price * 3` |
| 3 | `price * 9` |

具体每个单位的升星成长数值以 `content_reference.md` 和 `.tres` 资源为准。

## Passive Abilities

### `armor` — Warrior

Design intent: 前排稳定减伤，无复杂条件。

- Normal: 受到护盾后的生命伤害 ×0.85
- 3-star: ×0.75

### `long_shot` — Archer

Design intent: 鼓励后排站位，拉开距离后获得伤害奖励。

- Trigger: 目标距离 ≥ `attack_range * 0.6`
- Normal: 普攻伤害 ×1.15
- 3-star: 普攻伤害 ×1.25

### `execute` — Assassin

Design intent: 收割定位，对低血量目标造成额外伤害。

- Normal: 目标 HP 比 ≤0.4，普攻伤害 ×1.35
- 3-star: 目标 HP 比 ≤0.5，普攻伤害 ×1.6

### `fortress` — Tank

Design intent: Tank 是核心承伤单位。相比 Warrior，伤害和机动更低但生存更强。

- Normal: 受到护盾后的生命伤害 ×0.80；HP 比 ≤0.40 时 +20 防御
- 3-star: ×0.70；HP 比 ≤0.40 时 +40 防御

### `arcane_focus` — Mage

Design intent: Mage 依赖主动技能爆发而非普攻 DPS。

- Normal: 主动技能伤害 +15%
- 3-star: 主动技能伤害 +30%

### `benevolence` — Priest

Design intent: 治疗辅助，价值在于持续抬血。

- Normal: 治疗效果 +20%
- 3-star: 治疗效果 +40%

### `battle_song` — Bard

Design intent: 团队增幅辅助，自身伤害低但提高全队输出和技能节奏。

- Normal: 全队攻击力 +8%
- 3-star: 全队攻击力 +12%，魔力回复 +10%

## Active Skills

Active skills cast automatically when mana reaches `max_mana`. Mana resets to `0` on successful cast.

### `guard_barrier` — Warrior

- Normal: 自身护盾 `30 + max_hp * 0.25`，最低 HP 友军护盾 `self_shield * 0.4`
- 3-star: 自身护盾 `50 + max_hp * 0.35`，最低 HP 友军护盾 `self_shield * 0.4`

### `piercing_arrow` — Archer

- Normal: `attack_damage * 1.8` 技能伤害
- 3-star: `attack_damage * 2.3` 技能伤害。当前不穿透多个目标。

### `shadow_strike` — Assassin

- Normal: `attack_damage * 2.6` 技能伤害，击杀恢复 35 HP
- 3-star: `attack_damage * 3.4` 技能伤害，击杀恢复 60 HP

### `stone_guard` — Tank

- Normal: 护盾 `40 + max_hp * 0.30`，临时防御 +25 持续 5s
- 3-star: 护盾 `70 + max_hp * 0.40`，临时防御 +45 持续 5s
- 注：临时防御部分尚未接入 `StatusEffect` 系统，当前仅施加护盾

### `fireball` — Mage

- Normal: `attack_damage * 3.0` 技能伤害，可暴击
- 3-star: `attack_damage * 4.0` 技能伤害。当前不造成范围伤害。

### `holy_light` — Priest

- Normal: 治疗最低 HP 比友军 `35 + attack_damage * 1.5`，无受伤友军时自疗
- 3-star: 治疗 `60 + attack_damage * 2.0`，额外自疗 50% 最终治疗量

### `inspiring_song` — Bard

- Normal: 全队护盾 `15 + attack_damage * 0.8`，全队 +10% 攻击力 5s
- 3-star: 全队护盾 `25 + attack_damage * 1.2`，全队 +15% 攻击力 +15% 魔力回复 5s
- 注：定时攻击/魔力回复增益在守护队长和风语者等新单位中已实现，但尚未接入此技能

## Existing Units

当前玩家单位（完整属性与技能数值以 `content_reference.md` 为准）：

| `unit_type` | 中文名 | 稀有度 | 定位 | 羁绊 | 设计要点 |
| --- | --- | --- | --- | --- | --- |
| `warrior` | 战士 | COMMON | tank | 铁壁 | 前排减伤+护盾，入门坦克 |
| `archer` | 弓手 | COMMON | damage | 猎手 | 后排远程持续输出 |
| `assassin` | 刺客 | COMMON→FINE | damage | 猎手 | 高速收割，低血目标优先 |
| `tank` | 重装坦克 | COMMON | tank | 铁壁 | 核心承伤，高生命高防御 |
| `mage` | 法师 | COMMON | damage | 奥术 | 技能爆发，火球打击低血目标 |
| `priest` | 牧师 | COMMON | support | 圣疗 | 治疗辅助，持续抬血 |
| `bard` | 吟游诗人 | COMMON | support | 圣疗 | 团队增幅，护盾+攻击增益 |
| `forest_druid` | 森林德鲁伊 | FINE | support | 圣疗 | 持续治疗（HoT）辅助 |
| `plague_caster` | 瘟疫术士 | FINE | damage | 剧毒 | 普攻施毒+剧毒扩散 |
| `guardian_captain` | 守护队长 | FINE | tank | 铁壁 | 防御指挥，限时防御增益 |
| `wind_chanter` | 风语者 | FINE | support | 奥术 | 节奏辅助，攻速+魔力回复 |
| `greatsword_knight` | 巨剑骑士 | RARE | tank | 铁壁+猎手 | 半肉范围劈砍 |
| `alchemist` | 炼金术士 | RARE | damage | 奥术+剧毒 | 范围施毒+剧毒场地 |
| `bomb_thrower` | 爆弹投手 | RARE | damage | 猎手+奥术 | 周期性爆炸普攻+范围齐射 |
| `cleric` | 神官 | RARE | support | 圣疗 | 光环治疗+圣域范围治疗 |
| `necromancer` | 亡灵法师 | RARE | support | 召唤 | 召唤构筑核心，唤骷髅 |
| `puppet_warlock` | 傀儡术士 | RARE | damage | 召唤 | 标记击杀召唤傀儡 |
| `taunt_banneret` | 挑衅旗手 | RARE | tank | 铁壁+圣疗 | 嘲讽控制前排 |
| `vine_binder` | 藤缚卫士 | RARE | support | 圣疗+召唤 | 禁锢控制+护盾辅助 |
| `frost_sentry` | 霜箭哨手 | FINE | damage | 猎手+奥术 | 软控射手，迟缓敌人 |
| `thundermaul_vanguard` | 震锤先锋 | RARE | tank | 铁壁 | 硬控坦克，眩晕敌人 |
| `frost_prism_mage` | 冰棱术士 | EPIC | damage | 奥术 | 冻结+对冻结目标增伤 |
| `bloodbound_berserker` | 血契狂战 | RARE | damage | 猎手 | 低血爆发+吸血 |
| `soul_binder` | 缚魂祭司 | EPIC | support | 召唤 | 阵亡回魔/护盾+标记制造魂偶 |
| `starforged_vanguard` | 星铸禁卫 | EPIC | tank | 铁壁 | 升星流前排，高星越多越硬 |
| `arcane_artillerist` | 奥术炮师 | EPIC | damage | 奥术 | 技能爆发+魔力循环 AoE |
| `venom_matriarch` | 剧毒女王 | EPIC | damage | 剧毒 | 毒层叠加流核心，引爆毒层 |
| `dawnbell_saint` | 晨钟圣徒 | LEGENDARY | support | 圣疗 | 溢出治疗转护盾+死亡预防 |
| `nightblade_captain` | 夜刃统领 | EPIC | damage | 猎手 | 暴击收割流核心，强化刺客/弓手 |
| `prism_weaver` | 棱镜术师 | RARE | support | 奥术 | 技能流辅助，增伤+聚焦增益 |

## 高稀有度单位设计意图

以下为稀有度 EPIC+ 单位的构筑方向摘要。完整属性与技能数值以 `content_reference.md` 为准。

| 单位 | 构筑方向 | 核心机制 |
| --- | --- | --- |
| 缚魂祭司 / Soul Binder | 召唤流辅助核心 | 友方死亡→回魔+护盾，仪式标记→召唤魂偶（继承属性） |
| 星铸禁卫 / Starforged Vanguard | 升星流前排承伤 | 场上高星单位越多越硬，3 星单位额外护盾 |
| 奥术炮师 / Arcane Artillerist | 技能爆发输出 | 魔力循环+AoE 炮击，命中回全队魔力 |
| 剧毒女王 / Venom Matriarch | 毒层叠加核心 | 全队施毒+引爆毒层爆发 |
| 晨钟圣徒 / Dawnbell Saint | 治疗护盾传奇辅助 | 溢出治疗→护盾，战斗中阻止友方死亡 |
| 夜刃统领 / Nightblade Captain | 暴击收割核心 | 强化刺客/弓手暴击，击杀窗口回蓝+暴伤 |
| 血契狂战 / Bloodbound Berserker | 低血爆发 | 生命越低输出越高+强力吸血 |
| 棱镜术师 / Prism Weaver | 技能流辅助 | 概率增伤+聚焦关键输出单位 |

### 召唤物：魂偶 / Soul Puppet

由缚魂祭司/缚魂仪式生成的近战坦克召唤物。继承被标记目标 50% 生命与攻击，强度波动大。与傀儡共用 `summoned_puppet_body` / `summoned_puppet_guard` 被动和主动技能。

## New Unit Design Template

Use this template when designing a new unit. Fields correspond to `UnitData` exported properties. Current values for existing units are auto-generated in `docs/content_reference.md`.

### Unit Name

Role:

Resource path: `data/units/<unit_type>.tres`

### Identity

| Attribute | Value |
| --- | --- |
| `unit_name` | |
| `unit_name_cn` | |
| `description_cn` | |
| `unit_type` | |
| `catalog_id` | |
| `role` | `tank` / `damage` / `support` |
| `rarity` | `COMMON` / `FINE` / `RARE` / `EPIC` / `LEGENDARY` |
| `bond_tags` | |
| `star` | `1` |
| `price` | |

### Combat

| Attribute | Value |
| --- | --- |
| `max_hp` | |
| `attack_damage` | |
| `crit_chance` | |
| `crit_damage_multiplier` | |
| `defense` | |
| `attack_interval` | |
| `attack_range` | |
| `search_range` | `999.0` |
| `move_speed` | |

### Skills & Mana

| Attribute | Value |
| --- | --- |
| `passive_id` | |
| `active_skill_id` | |
| `max_mana` | |
| `mana_regen_per_second` | |

### Targeting

| Attribute | Value |
| --- | --- |
| `target_mode` | `NEAREST` / `LOWEST_HP` |
| `retarget_interval` | `0.4` |
| `lowest_hp_switch_threshold` | `0.1` |

### Visuals

| Attribute | Value |
| --- | --- |
| `basic_attack_type` | `melee` / `projectile` |
| `projectile_speed` | |
| `projectile_visual_type` | `arrow` / `magic` / `holy` / `flask` / `bomb` / `dark` / `curse` |
| `board_sprite` | |
| `portrait_texture` | |
| `icon_texture` | |
| `art_scale` | `1.0` |
| `art_offset` | `Vector2.ZERO` |

### Passive

- id:
- normal effect:
- 3-star effect:

### Active Skill

- id:
- mana:
- normal effect:
- 3-star effect:

### Star Growth

| Star | HP Mult | Attack Mult | Defense Bonus | Attack Interval Mult | Move Speed Mult | Crit Chance Bonus | Crit Damage Bonus |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `1.0` | `1.0` | `0` | `1.0` | `1.0` | `0.0` | `0.0` |
| 2 | | | | | | | |
| 3 | | | | | | | |
