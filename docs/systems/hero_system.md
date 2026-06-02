# 英雄系统

更新时间：2026-06-02

本文档记录英雄系统的核心规则、经验成长、强化机制和实现入口。精确数值以 `docs/content_reference.md` 为准。

## 核心规则

### 英雄基础规则

- 开局选择 1 名英雄，英雄作为**特殊单位**加入玩家队伍
- 英雄**不占用**普通单位最大上场数量
- 英雄**不可购买、出售、升星或下阵**
- 英雄死亡只影响当前战斗，下一场会重新生成
- 英雄可在准备阶段拖动调整站位，只能放置在玩家棋盘内

### 英雄列表

当前已实现 4 名英雄：

| 英雄 | ID | 定位 | 羁绊 | 主动技能 |
| --- | --- | --- | --- | --- |
| 铁誓统帅 / Iron Oath Commander | `iron_oath_commander` | 前排/护盾 | 铁壁 | `hero_commanding_order` |
| 奥术导师 / Arcane Mentor | `arcane_mentor` | 后排/法术 | 奥术 | `hero_arcane_storm` |
| 血影猎手 / Bloodshadow Hunter | `bloodshadow_hunter` | 刺客/收割 | 猎手 | `hero_bloodshadow_assault` |
| 织骨者 / Boneweaver | `boneweaver` | 后排/召唤 | 召唤 | `hero_bone_golem` |

### 经验与升级

- **升级阈值**：50 经验/级
- **经验获取**：
  - 普通战斗胜利：+10
  - 精英战斗胜利：+20
  - Boss 战斗胜利：+30
- 升级时弹出**强化三选一**，不足 3 个专属强化时用基础属性强化补齐

### 英雄强化池

当前英雄强化池由 `HeroManager` 直接构建。铁誓统帅、奥术导师、织骨者各 8 个专属强化；血影猎手当前 9 个专属强化。合计 **33 个专属强化** + 4 个可重复基础属性强化：

| 类型 | 数量 | 说明 |
| --- | --- | --- |
| 专属强化 | 当前 33 个 | 改变技能效果或新增机制；多数英雄 8 个，血影猎手 9 个 |
| 基础属性 | 4 | `max_hp`、`attack_damage`、`defense`、`mana_regen`，可重复选择叠加 |

### 等级成长

英雄等级按成长曲线提高基础属性（生命、攻击、防御、魔力回复）。已选强化在后续战斗重新生成英雄时重新应用。

## 实现入口

| 内容 | 文件 |
| --- | --- |
| 英雄管理 | `scripts/hero_manager.gd` |
| 英雄数据 | `data/heroes/*.tres` |
| 英雄单位配置 | `scripts/hero_data.gd`、`scripts/hero_upgrade_data.gd` |
| 战斗生成 | `scripts/hero_manager.gd` → `create_hero_battle_unit_data()` |
| 经验结算 | `scripts/hero_manager.gd` → `process_victory_encounter()` |
| 强化选择 | `scripts/hero_manager.gd` → `generate_hero_upgrade_options()` |
