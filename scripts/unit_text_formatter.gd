class_name UnitTextFormatter
extends RefCounted


func get_unit_description(unit_data: Resource) -> String:
	if unit_data == null:
		return ""

	var configured_cn_description: Variant = unit_data.get("description_cn")
	if configured_cn_description != null and str(configured_cn_description).strip_edges() != "":
		return str(configured_cn_description)

	return ""


func get_unit_description_with_skills(unit_data: Resource) -> String:
	if unit_data == null:
		return ""

	var parts: Array[String] = []
	var base_description: String = get_unit_description(unit_data)
	if base_description.strip_edges() != "":
		parts.append(base_description)

	var star: int = _get_int_property(unit_data, "star", 1)
	var passive_text: String = get_passive_skill_text(_get_string_property(unit_data, "passive_id"), star)
	if passive_text != "":
		parts.append("被动：" + passive_text)

	var active_text: String = get_active_skill_text(_get_string_property(unit_data, "active_skill_id"), star)
	if active_text != "":
		parts.append("主动：" + active_text)

	return _join_text(parts, "\n")


func get_passive_skill_text(passive_id: String, star: int = 1) -> String:
	var safe_star: int = maxi(1, star)
	match passive_id:
		"armor":
			return "护甲：受到护盾后的生命伤害降低 " + ("25%" if safe_star >= 3 else "15%") + "。"
		"long_shot":
			return "长射：攻击远距离目标时，普攻伤害提高 " + ("25%" if safe_star >= 3 else "15%") + "。"
		"execute":
			return "处决：攻击低生命目标时，普攻伤害提高；" + ("3 星阈值 50%，伤害 +60%。" if safe_star >= 3 else "阈值 40%，伤害 +35%。")
		"fortress":
			return "堡垒：受到生命伤害降低 " + ("30%" if safe_star >= 3 else "20%") + "；生命低于 40% 时额外防御 +" + ("40" if safe_star >= 3 else "20") + "。"
		"arcane_focus":
			return "奥术专注：主动技能伤害提高 " + ("30%" if safe_star >= 3 else "15%") + "。"
		"benevolence":
			return "仁慈：治疗效果提高 " + ("40%" if safe_star >= 3 else "20%") + "。"
		"battle_song":
			return "战歌：战斗开始时全队攻击提高 " + ("12%，并获得 +10% 魔力回复。" if safe_star >= 3 else "8%。")
		"nature_touch":
			return "自然触碰：每 3 次普攻为低生命友军施加 3 秒持续治疗，每秒 " + ("20" if safe_star >= 3 else "12") + "。"
		"poison_blade":
			return "毒刃：普攻使目标中毒 4 秒，每秒受到 " + ("14" if safe_star >= 3 else "8") + " 伤害。"
		"defensive_command":
			return "防御指令：战斗开始时前排友军获得 +" + ("30" if safe_star >= 3 else "16") + " 防御。"
		"wind_rhythm":
			return "风律：战斗开始时全队魔力回复提高 " + ("22%" if safe_star >= 3 else "12%") + "。"
		"cleaving_edge":
			return "裂刃：普攻命中时，对前方 120° 扇形（半径=攻击范围）内其他敌人造成 " + ("50%" if safe_star >= 3 else "35%") + " 攻击力的范围伤害，可暴击。"
		"unstable_bomb":
			return "不稳定炸弹：每 " + ("2" if safe_star >= 3 else "3") + " 次普攻爆炸，对主目标周围半径 " + ("85" if safe_star >= 3 else "75") + " 内其他敌人造成 " + ("55%" if safe_star >= 3 else "40%") + " 攻击力范围伤害，可暴击。"
		"healing_aura":
			return "疗愈光环：每 " + ("3" if safe_star >= 3 else "4") + " 秒治疗自身周围半径 " + ("120" if safe_star >= 3 else "100") + " 内所有友军，治疗量 " + ("12 + 40% 攻击力。" if safe_star >= 3 else "8 + 30% 攻击力。")
		"corrosive_flask":
			return "腐蚀药剂：普攻使目标腐蚀 " + ("4" if safe_star >= 3 else "3") + " 秒，每秒受到 " + ("7" if safe_star >= 3 else "4") + " 伤害，重复施加刷新持续时间。"
		"grave_command":
			return "坟场号令：召唤物存活整场战斗；自身召唤上限 +" + ("5。" if safe_star >= 3 else "3。" if safe_star >= 2 else "1。")
		"puppet_contract":
			return "傀儡契约：主动技能标记敌人，标记目标死亡后在其位置召唤傀儡，受自身召唤上限限制。"
		"summoned_bone_edge":
			return "骨刃：普攻命中生命低于 50% 的敌人时，伤害提高 " + ("35%。" if safe_star >= 3 else "20%。")
		"summoned_puppet_body":
			return "傀儡身躯：受到生命伤害降低 " + ("18%。" if safe_star >= 3 else "10%。")
		"summoned_golem_body":
			return "巨人之躯：受到生命伤害降低 15%。"
		"summoned_dragon_breath":
			return "龙息溅射：普攻命中时，对目标周围 80 内其他敌人造成 30% 攻击力的溅射伤害。"
		"soul_thread":
			return "魂线牵引：友方召唤物死亡时恢复 " + ("18" if safe_star >= 3 else "12") + " 魔力；友方非召唤单位死亡时恢复 " + ("35" if safe_star >= 3 else "25") + " 魔力，并为生命比例最低的" + ("两个" if safe_star >= 3 else "一个") + "友方单位添加 " + ("45" if safe_star >= 3 else "30") + " 护盾。"
		"starforged_body":
			return "星铸护体：每有 1 个玩家场上 2 星单位获得 +" + ("10" if safe_star >= 3 else "6") + " 防御；每有 1 个 3 星单位额外获得 +" + ("20" if safe_star >= 3 else "12") + " 防御和 " + ("40" if safe_star >= 3 else "25") + " 护盾。"
		"overload_core":
			return "过载核心：获得来自其他单位或效果的魔力时，有 " + ("50%" if safe_star >= 3 else "25%") + " 概率额外获得 " + ("12" if safe_star >= 3 else "8") + " 魔力，该额外魔力不会再次触发。"
		"venom_brood":
			return "毒群共生：玩家单位每对敌人造成 " + ("2" if safe_star >= 3 else "4") + " 次伤害，附加一层持续剧毒。"
		"dawnbell_echo":
			return "晨钟回响：玩家单位治疗溢出时，将 " + ("150%" if safe_star >= 3 else "70%") + " 溢出治疗转化为护盾；每场战斗可阻止 " + ("3" if safe_star >= 3 else "1") + " 次友方死亡。"
		"nightblade_order":
			return "夜刃军令：战斗开始时，所有玩家刺客和弓手获得 +" + ("25%" if safe_star >= 3 else "15%") + " 暴击率；攻击低于 50% 生命的目标时额外造成 " + ("60%" if safe_star >= 3 else "25%") + " 伤害。"
		"bloodbound_rage":
			return "血契狂怒：" + ("生命低于 70% 时攻击力 +40%、吸血 +20%；低于 30% 时攻击力 +70%、吸血 +35%。" if safe_star >= 3 else "生命低于 50% 时攻击力 +20%、吸血 +10%；低于 25% 时攻击力 +35%、吸血 +20%。")
		"prism_refraction":
			return "棱镜折射：玩家单位造成主动技能伤害时，有 " + ("70%" if safe_star >= 3 else "40%") + " 概率使该次技能伤害提高 " + ("50%" if safe_star >= 3 else "25%") + "。"
		"enemy_grave_command":
			return "唤墓：自身召唤上限 +1；召唤物默认存活到本场战斗结束。"
		"enemy_death_summons_skeletons":
			return "骨骸爆裂：死亡时在原地召唤 2 个骷髅。"
		"enemy_kill_summons_skeletons":
			return "收尸役令：击杀敌人时在目标位置召唤 1 个骷髅。"
		"enemy_shield_wall":
			return "盾墙：受到护盾后的生命伤害降低 10%。"
		"enemy_stone_skin":
			return "石肤：防御 +10；生命低于 50% 时额外防御 +15。"
		"enemy_iron_body":
			return "铁躯：受到护盾后的生命伤害降低 18%。"
		"enemy_colossus_core":
			return "巨像核心：受到护盾后的生命伤害降低 25%，并在承受重击后获得护盾。"
		"enemy_steady_aim":
			return "稳固瞄准：攻击远距离目标时，普攻伤害提高 10%。"
		"enemy_flame_focus":
			return "烈焰专注：主动技能伤害提高 10%。"
		"enemy_reaper_execute":
			return "收割处决：攻击生命低于 45% 的目标时，普攻伤害提高 35%。"
		"enemy_void_charge":
			return "虚空充能：普攻命中时额外恢复 8 魔力。"
		"enemy_dark_blessing":
			return "暗影祝福：治疗效果提高 15%。"
		"enemy_war_rhythm":
			return "战鼓节奏：战斗开始时敌方全队攻击提高 6%。"
		"enemy_blood_ritual":
			return "血祭：精英血谕者存活时，敌方单位击杀玩家单位会使击杀者恢复 25 生命。"
		"maggot_death_burst":
			return "腐爆：死亡时以自身位置为中心造成范围伤害，并对命中目标施加 1 层剧毒和腐痕。"
		"amalgam_split_birth":
			return "分裂繁殖：死亡时在附近召唤 4 只巨型蛆虫，召唤物参与胜负判定。"
		"enemy_abyss_chant":
			return "深渊吟诵：战斗开始时敌方全队获得 30 护盾，并提高 10% 魔力回复。"
		"hero_iron_oath_commander":
			return "铁誓军势：战斗开始时，前排友军获得 15 + 10% 英雄防御的防御；承伤类前排额外获得 20 + 英雄防御 + 10% 自身最大生命的护盾。\n不倒战线：任意前排友军首次低于 40% 生命时，获得等同已损失生命的护盾，每单位每场战斗 1 次。"
		"hero_arcane_mentor":
			return "奥术回流：玩家单位释放主动技能时，奥术导师恢复 8 魔力；技能输出单位释放时额外恢复 4 魔力。\n法术共鸣：玩家单位造成主动技能伤害提高 10%。"
		"hero_bloodshadow_hunter":
			return "猎杀标记：战斗开始时标记 1 个敌方后排单位，玩家单位攻击标记目标时伤害提高 15%。\n血影收割：玩家单位击杀敌人时，击杀者恢复 20 生命和 15 魔力；刺客或弓手击杀后额外获得 +10% 暴击率，持续 5 秒。"
		"hero_boneweaver":
			return "骨潮：战斗开始时，所有玩家召唤单位获得 15% 攻击力和 15% 最大生命加成；场上每有 1 个玩家召唤单位，召唤单位伤害提高 5%，最多 25%。\n不灭仆从：玩家召唤单位首次受到致命伤害时保留 1 点生命并获得 2 秒无敌，每单位每场战斗限 1 次。"
		_ :
			return _format_unknown_skill(passive_id)


func get_active_skill_text(active_skill_id: String, star: int = 1) -> String:
	var safe_star: int = maxi(1, star)
	match active_skill_id:
		"guard_barrier":
			return "守护屏障：为自身获得 " + ("50 + 35% 最大生命" if safe_star >= 3 else "30 + 25% 最大生命") + " 护盾，并为最低生命友军提供 40% 护盾量。"
		"piercing_arrow":
			return "穿刺箭：对当前目标造成 " + ("230%" if safe_star >= 3 else "180%") + " 攻击力的技能伤害。"
		"shadow_strike":
			return "影袭：对当前目标造成 " + ("340%" if safe_star >= 3 else "260%") + " 攻击力的技能伤害，击杀后恢复 " + ("60" if safe_star >= 3 else "35") + " 生命。"
		"stone_guard":
			return "石卫：自身获得 " + ("70 + 40% 最大生命" if safe_star >= 3 else "40 + 30% 最大生命") + " 护盾。"
		"fireball":
			return "火球术：对当前目标造成 " + ("400%" if safe_star >= 3 else "300%") + " 攻击力的技能伤害。"
		"holy_light":
			return "圣光：治疗低生命友军 " + ("60 + 200% 攻击力" if safe_star >= 3 else "35 + 150% 攻击力") + "；3 星治疗他人时自身恢复部分生命。"
		"inspiring_song":
			return "激励之歌：全队获得 " + ("25 + 120% 攻击力" if safe_star >= 3 else "15 + 80% 攻击力") + " 护盾。"
		"regrowth":
			return "再生：为低生命友军施加 5 秒持续治疗，每秒 " + ("28 + 90% 攻击力，影响 2 个目标。" if safe_star >= 3 else "18 + 65% 攻击力。")
		"toxic_cloud":
			return "毒云：使目标中毒 " + ("6" if safe_star >= 3 else "5") + " 秒，每秒受到 " + ("24 + 60% 攻击力" if safe_star >= 3 else "15 + 45% 攻击力") + " 伤害。"
		"iron_order":
			return "钢铁号令：全队获得 +" + ("50" if safe_star >= 3 else "30") + " 防御，持续 " + ("6" if safe_star >= 3 else "5") + " 秒；3 星额外提供护盾。"
		"haste_song":
			return "急速曲：全队攻击间隔降低 " + ("26%" if safe_star >= 3 else "16%") + "，魔力回复提高 " + ("32%" if safe_star >= 3 else "20%") + "，持续 " + ("6" if safe_star >= 3 else "5") + " 秒。"
		"sweeping_slash":
			return "横扫斩：对前方矩形区域（长=2×攻击范围，宽=攻击范围）内所有敌人造成 " + ("200%" if safe_star >= 3 else "160%") + " 攻击力的技能伤害；3 星额外获得 20 护盾。"
		"explosive_barrage":
			return "爆破齐射：以当前目标为中心，对半径 " + ("120" if safe_star >= 3 else "100") + " 内所有敌人造成 " + ("210%" if safe_star >= 3 else "170%") + " 攻击力的技能伤害；3 星命中至少 3 个敌人时恢复 20 魔力。"
		"sanctuary":
			return "圣域：以生命比例最低友军为中心，治疗半径 " + ("140" if safe_star >= 3 else "120") + " 内所有友军，3 秒内每秒治疗一次，总治疗量 " + ("55 + 150% 攻击力，并提供 15 护盾。" if safe_star >= 3 else "35 + 120% 攻击力。")
		"acid_field":
			return "酸液领域：在当前目标位置生成固定酸液区域，持续 " + ("6" if safe_star >= 3 else "5") + " 秒，半径 " + ("120" if safe_star >= 3 else "100") + "，每秒对区域内所有敌人造成 " + ("16 + 45% 攻击力" if safe_star >= 3 else "10 + 35% 攻击力") + " 伤害。"
		"raise_skeletons":
			return "亡灵召唤：在自身身边召唤 " + ("4" if safe_star >= 3 else "2") + " 个骷髅，受自身召唤上限限制。"
		"puppet_mark":
			return "傀儡标记：优先标记未被标记的当前敌人，否则选择低生命未标记敌人；目标死亡时召唤 1 个傀儡，并使其受到伤害提高 " + ("25%，持续 10 秒。" if safe_star >= 3 else "15%，持续 8 秒。")
		"summoned_bone_slash":
			return "骨斩：对当前目标造成 " + ("210%" if safe_star >= 3 else "160%") + " 攻击力的技能伤害。"
		"summoned_puppet_guard":
			return "傀儡护架：自身获得 " + ("40 + 25% 最大生命" if safe_star >= 3 else "25 + 18% 最大生命") + " 的护盾。"
		"summoned_golem_smash":
			return "巨人重击：对当前目标造成 " + ("260%" if safe_star >= 3 else "200%") + " 攻击力的技能伤害。"
		"summoned_dragon_barrage":
			return "龙息弹幕：对当前目标周围 " + ("130" if safe_star >= 3 else "100") + " 内所有敌人造成 " + ("200%" if safe_star >= 3 else "150%") + " 攻击力的技能伤害。"
		"binding_rite":
			return "缚魂仪式：标记当前目标 " + ("15" if safe_star >= 3 else "10") + " 秒；目标死亡时在其位置召唤 1 个魂偶，魂偶额外获得目标 " + ("100%" if safe_star >= 3 else "50%") + " 的生命与攻击" + ("，并获得 50 护盾。" if safe_star >= 3 else "。")
		"astral_bulwark":
			return "星界壁垒：自身获得 " + ("120 + 30% 最大生命" if safe_star >= 3 else "80 + 20% 最大生命") + " 护盾；" + ("所有友方单位获得 35% 护盾，3 星友方额外获得 15% 伤害减免，持续 5 秒。" if safe_star >= 3 else "若玩家场上存在 3 星单位，所有友方单位额外获得 20% 护盾。")
		"arcane_barrage":
			return "奥术炮击：以当前目标为中心，对半径 " + ("145" if safe_star >= 3 else "120") + " 内所有敌人造成 " + ("360%" if safe_star >= 3 else "240%") + " 攻击力的技能伤害；" + ("命中至少 3 个敌人时，所有玩家单位恢复 15 魔力。" if safe_star >= 3 else "每命中 1 名敌人，所有玩家单位恢复 2 魔力。")
		"feast_of_venom":
			return "万毒盛宴：对所有敌方单位施加 " + ("3" if safe_star >= 3 else "1") + " 层剧毒；" + ("将当前目标剧毒层数翻倍后" if safe_star >= 3 else "然后") + "引爆当前目标剧毒，造成层数 x 攻击力 x " + ("50%" if safe_star >= 3 else "30%") + " 的毒性伤害，不清除层数。"
		"bell_of_sanctuary":
			return "圣钟庇佑：治疗所有玩家单位 " + ("100 + 25% 最大生命" if safe_star >= 3 else "40 + 15% 最大生命") + "，并添加 " + ("60" if safe_star >= 3 else "30") + " 护盾" + ("，同时恢复 30 魔力。" if safe_star >= 3 else "。")
		"reaping_command":
			return "收割号令：对生命比例最低的敌人造成 " + ("500%" if safe_star >= 3 else "360%") + " 攻击力的技能伤害；若击杀目标，所有玩家刺客和弓手恢复 " + ("35" if safe_star >= 3 else "20") + " 魔力并提高 " + ("100% 暴击伤害和 15% 暴击率。" if safe_star >= 3 else "50% 暴击伤害。")
		"blood_debt_slash":
			return "血债斩：消耗自身当前生命的 " + ("8%" if safe_star >= 3 else "10%") + "，对当前目标造成 " + ("320%" if safe_star >= 3 else "250%") + " 攻击力的技能伤害，随后恢复实际伤害的 " + ("70%" if safe_star >= 3 else "35%") + " 生命；该技能不会使自身死亡。"
		"focus_beam":
			return "聚焦光束：为技能强度最高的友方单位添加聚焦，持续 " + ("7" if safe_star >= 3 else "5") + " 秒；聚焦期间技能强度 +" + ("80%" if safe_star >= 3 else "50%") + "，暴击率 +" + ("20%" if safe_star >= 3 else "10%") + ("，并恢复 25 魔力。" if safe_star >= 3 else "。")
		"enemy_raise_skeletons":
			return "唤骨术：在自身身边召唤 2 个骷髅。"
		"enemy_puppet_mark":
			return "傀儡咒印：优先标记未被标记的敌人，标记目标死亡时召唤 1 个傀儡，并使其受到伤害提高 " + ("25%，持续 10 秒。" if safe_star >= 3 else "15%，持续 8 秒。")
		"septic_spit":
			return "腐蚀喷吐：对当前目标造成 120% 攻击力的技能伤害，并施加 2 层剧毒和腐痕。"
		"putrid_tide":
			return "腐潮：向当前目标方向释放扇形腐潮，对命中目标造成 140% 攻击力的技能伤害；若目标已有腐痕，本次伤害提高 25%，随后施加 2 层剧毒并刷新腐痕。"
		"enemy_guard_stance":
			return "防守姿态：自身获得 25 + 15% 最大生命护盾。"
		"enemy_harden":
			return "硬化：自身获得 40 护盾。"
		"enemy_fortify_allies":
			return "加固阵线：自身获得 60 护盾，友军获得 20 护盾。"
		"enemy_earthbreaker_barrier":
			return "裂地屏障：自身获得 100 + 12% 最大生命护盾，并造成 180% 攻击力伤害。"
		"enemy_power_shot":
			return "强力射击：对当前目标造成 180% 攻击力的技能伤害。"
		"enemy_firebolt":
			return "火焰箭：对当前目标造成 250% 攻击力的技能伤害。"
		"enemy_shadow_cleave":
			return "暗影顺劈：造成 260% 攻击力伤害，击杀后恢复 30 生命。"
		"enemy_void_beam":
			return "虚空光束：造成 320% 攻击力伤害，对半血以下目标伤害提高。"
		"enemy_dark_heal":
			return "暗影治疗：治疗低生命友军 30 + 130% 攻击力。"
		"enemy_drum_shield":
			return "战鼓护盾：敌方全队获得 15 护盾。"
		"enemy_oracle_blessing":
			return "神谕祝福：治疗低生命友军 50 + 150% 攻击力，并提供 20 护盾。"
		"enemy_mass_benediction":
			return "群体赐福：敌方全队恢复 25 + 120% 攻击力生命，并获得 50 护盾。"
		"hero_commanding_order":
			return "统帅号令：满魔自动释放。全体玩家单位获得 25 + 英雄防御 + 10% 英雄最大生命的护盾；前排友军额外获得 20 + 10% 英雄防御的防御，持续 5 秒。英雄 Lv.4 起，护盾提升为 40 + 150% 英雄防御 + 20% 英雄最大生命，防御提升为 35 + 20% 英雄防御，持续 6 秒。"
		"hero_arcane_storm":
			return "奥术风暴：满魔自动释放。以当前目标为中心，对半径 120 内敌人造成 220% 攻击力的技能伤害。英雄 Lv.4 起，范围提升至 150，伤害提升至 280% 攻击力；命中 3 个以上敌人时，所有玩家单位恢复 15 魔力。"
		"hero_bloodshadow_assault":
			return "血影突袭：满魔自动释放。攻击生命比例最低的敌人，造成 260% 攻击力的技能伤害；若目标低于 50% 生命，伤害提高 30%；若击杀目标，英雄恢复 50 魔力。英雄 Lv.4 起，基础伤害提升至 320% 攻击力。"
		"hero_bone_golem":
			return "骨巨人召唤：满魔自动释放。在最近敌人附近召唤一个骨巨人（近战肉盾），攻击 18+80%英雄攻击，生命 200+150%英雄攻击，防御 20，持续 15 秒。英雄 Lv.4 起额外召唤一只骨龙（远程范围输出），攻击 30+150%英雄攻击，生命 100+80%英雄攻击，攻击可造成溅射伤害。"
		_:
			return _format_unknown_skill(active_skill_id)


func get_hero_passive_skill_text(passive_id: String, upgrade_ids: Array[String]) -> String:
	var lines: Array[String] = [get_passive_skill_text(passive_id, 1)]
	match passive_id:
		"hero_iron_oath_commander":
			if upgrade_ids.has("iron_guard_synergy"):
				lines.append("护卫协同：每有 1 个承伤单位，全队防御 +10。")
			if upgrade_ids.has("iron_heavy_formation"):
				lines.append("重甲阵列：所有前排单位最大生命 +20%。")
			if upgrade_ids.has("iron_shield_training"):
				lines.append("护盾训练：玩家单位获得的护盾值提高 15%。")
			if upgrade_ids.has("iron_line_echo"):
				lines.append("战线回响：玩家单位获得护盾时恢复 10 魔力，每单位每 2 秒最多触发 1 次。")
			if upgrade_ids.has("iron_final_defense"):
				lines.append("最终防线：英雄死亡时，所有存活玩家单位获得 100 + 英雄防御的护盾。")
		"hero_arcane_mentor":
			if upgrade_ids.has("arcane_mana_surge"):
				lines.append("魔力涌动：所有玩家单位魔力回复速度 +10%。")
			if upgrade_ids.has("arcane_spell_piercing"):
				lines.append("法术穿透：玩家主动技能伤害额外提高 10%。")
			if upgrade_ids.has("arcane_mana_shield"):
				lines.append("魔力护盾：玩家单位释放主动技能后获得 10 护盾。")
			if upgrade_ids.has("arcane_elemental_overload"):
				lines.append("元素过载：法师、炼金术士、爆弹投手攻击力 +12%。")
			if upgrade_ids.has("arcane_chain_casting"):
				lines.append("连锁施法：奥术导师释放主动技能后，随机友方单位恢复 30 魔力。")
			if upgrade_ids.has("arcane_alchemical_resonance"):
				lines.append("炼金共振：场地持续伤害类技能伤害 +20%。")
		"hero_bloodshadow_hunter":
			if upgrade_ids.has("blood_lethal_instinct"):
				lines.append("致命预感：全队暴击率 +8%。")
			if upgrade_ids.has("blood_hunter_instinct"):
				lines.append("猎手本能：刺客和弓手暴击伤害 +30%。")
			if upgrade_ids.has("blood_weakness_exposed"):
				lines.append("弱点暴露：被标记目标防御 -20。")
			if upgrade_ids.has("blood_hunt_pace"):
				lines.append("追猎节奏：被标记目标受到攻击时，攻击者恢复 5 魔力。")
			if upgrade_ids.has("blood_continuous_harvest"):
				lines.append("连续收割：玩家单位击杀后攻击间隔降低 15%，持续 5 秒；收割回血和回蓝提高。")
			if upgrade_ids.has("blood_mark_retarget"):
				lines.append("猎手追踪：标记目标死亡后，重新标记 1 个敌人。")
			if upgrade_ids.has("blood_wounded_hunter"):
				lines.append("残血猎杀：玩家单位攻击生命比例低于 35% 的敌人时，伤害 +12%。")
			if upgrade_ids.has("blood_shadow_shelter"):
				lines.append("暗影庇护：刺客和弓手击杀后获得 25 护盾。")
		"hero_boneweaver":
			if upgrade_ids.has("skeleton_vigor"):
				lines.append("骸骨活力：所有召唤单位最大生命 +25%。")
			if upgrade_ids.has("bone_spike_armor"):
				lines.append("骨刺护甲：召唤单位获得 10% 伤害反弹。")
			if upgrade_ids.has("death_echo"):
				lines.append("亡者回响：召唤单位死亡时对周围 80 内敌人造成 60% 攻击力的伤害。")
			if upgrade_ids.has("grave_caller"):
				lines.append("墓穴召唤：玩家召唤单位上限 +1。")
			if upgrade_ids.has("bone_golem_fury"):
				lines.append("骨巨人狂怒：骨巨人攻击力 +30%，攻击速度 +20%。")
			if upgrade_ids.has("skeletal_fortitude"):
				lines.append("骸骨坚韧：召唤单位受到的范围伤害 -20%。")
			if upgrade_ids.has("bone_dragon"):
				lines.append("骨龙降临：额外召唤一只骨龙（远程范围输出），与骨巨人上限分开计算。")
			if upgrade_ids.has("eternal_thralls"):
				lines.append("永恒仆从：不灭仆从无敌时间从 2 秒延长至 4 秒。")

	return _join_text(lines, "\n")


func get_hero_active_skill_text(active_skill_id: String, hero_level: int, upgrade_ids: Array[String]) -> String:
	var lines: Array[String] = [get_active_skill_text(active_skill_id, 1)]
	match active_skill_id:
		"hero_commanding_order":
			if hero_level >= 4:
				lines.append("当前等级：已启用 Lv.4 强化版护盾、防御和持续时间。")
			if upgrade_ids.has("iron_wall_spread"):
				lines.append("铁壁扩散：统帅号令的防御加成也影响中排单位。")
			if upgrade_ids.has("iron_hold_horn"):
				lines.append("坚守号角：统帅号令额外治疗前排和受影响中排单位 10% 已损生命。")
		"hero_arcane_storm":
			if hero_level >= 4:
				lines.append("当前等级：范围 150，伤害 280% 攻击力，命中 3 个以上敌人时全队回 15 魔力。")
			if upgrade_ids.has("arcane_shattering_storm"):
				lines.append("爆裂奥术：每额外命中 1 个敌人，伤害提高 5%，最多提高 25%。")
			if upgrade_ids.has("arcane_quick_chanting"):
				lines.append("快速吟唱：奥术导师最大魔力 -15，但技能伤害降低 8%。")
		"hero_bloodshadow_assault":
			if hero_level >= 4:
				lines.append("当前等级：基础伤害 320% 攻击力。")
			if upgrade_ids.has("blood_shadow_chain"):
				lines.append("血影连斩：主动技能击杀后，对最近敌人追加一次 60% 威力的突袭。")
		"hero_bone_golem":
			if hero_level >= 4:
				lines.append("当前等级：额外召唤一只骨龙（远程范围输出），与骨巨人召唤上限分开计算。")
			if upgrade_ids.has("bone_golem_fury"):
				lines.append("骨巨人狂怒：骨巨人攻击力 +30%，攻击速度 +20%。")
			if upgrade_ids.has("bone_dragon"):
				lines.append("骨龙降临：额外召唤一只骨龙，远程范围攻击，召唤上限与骨巨人分开计算。")

	return _join_text(lines, "\n")


func get_hero_upgrade_text(upgrade_id: String) -> String:
	match upgrade_id:
		"iron_unshakable":
			return "坚不可摧：英雄自身防御 +50。"
		"iron_guard_synergy":
			return "护卫协同：每有 1 个承伤单位，全队防御 +10。"
		"iron_heavy_formation":
			return "重甲阵列：所有前排单位最大生命 +20%。"
		"iron_shield_training":
			return "护盾训练：玩家单位获得的护盾值提高 15%。"
		"iron_wall_spread":
			return "铁壁扩散：统帅号令的防御加成也影响中排单位。"
		"iron_line_echo":
			return "战线回响：玩家单位获得护盾时恢复 10 魔力。"
		"iron_hold_horn":
			return "坚守号角：统帅号令额外治疗前排单位。"
		"iron_final_defense":
			return "最终防线：英雄死亡时为全队提供护盾。"
		"arcane_mana_surge":
			return "魔力涌动：所有玩家单位魔力回复速度 +10%。"
		"arcane_spell_piercing":
			return "法术穿透：玩家主动技能伤害额外提高 10%。"
		"arcane_mana_shield":
			return "魔力护盾：玩家单位释放主动技能后获得 10 护盾。"
		"arcane_elemental_overload":
			return "元素过载：法师、炼金术士、爆弹投手攻击力 +12%。"
		"arcane_chain_casting":
			return "连锁施法：奥术导师释放主动技能后，随机友方单位恢复 30 魔力。"
		"arcane_alchemical_resonance":
			return "炼金共振：场地持续伤害类技能伤害 +20%。"
		"arcane_shattering_storm":
			return "爆裂奥术：奥术风暴每额外命中 1 个敌人，伤害提高。"
		"arcane_quick_chanting":
			return "快速吟唱：最大魔力 -15，技能伤害 -8%。"
		"blood_lethal_instinct":
			return "致命预感：全队暴击率 +8%。"
		"blood_hunter_instinct":
			return "猎手本能：刺客和弓手暴击伤害 +30%。"
		"blood_weakness_exposed":
			return "弱点暴露：被标记目标防御 -20。"
		"blood_hunt_pace":
			return "追猎节奏：攻击标记目标时恢复 5 魔力。"
		"blood_continuous_harvest":
			return "连续收割：击杀后获得攻击节奏，并提高收割回复。"
		"blood_mark_retarget":
			return "猎手追踪：标记目标死亡后重新标记。"
		"blood_wounded_hunter":
			return "残血猎杀：攻击低生命敌人时伤害 +12%。"
		"blood_shadow_shelter":
			return "暗影庇护：刺客和弓手击杀后获得 25 护盾。"
		"blood_shadow_chain":
			return "血影连斩：主动技能击杀后追加弱化突袭。"
		"hero_base_stat_max_hp":
			return "英雄体魄：英雄最大生命 +12%。"
		"hero_base_stat_attack_damage":
			return "英雄武训：英雄攻击力 +10%。"
		"hero_base_stat_defense":
			return "英雄护甲：英雄防御 +8。"
		"hero_base_stat_mana_regen":
			return "英雄聚能：英雄魔力回复速度 +12%。"
		_:
			return upgrade_id


func _format_unknown_skill(skill_id: String) -> String:
	if skill_id.strip_edges() == "":
		return ""

	return skill_id


func _get_string_property(resource: Resource, property_name: String) -> String:
	if resource == null:
		return ""

	var configured_value: Variant = resource.get(property_name)
	if configured_value == null:
		return ""

	return str(configured_value)


func _get_int_property(resource: Resource, property_name: String, default_value: int) -> int:
	if resource == null:
		return default_value

	var configured_value: Variant = resource.get(property_name)
	if configured_value == null:
		return default_value

	return int(configured_value)


func _join_text(parts: Array[String], separator: String) -> String:
	var joined_text: String = ""
	for index: int in range(parts.size()):
		if index > 0:
			joined_text += separator
		joined_text += parts[index]

	return joined_text
