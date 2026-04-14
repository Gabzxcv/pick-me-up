extends Node

const ENEMY_NAMES := [
	"Goblin Scout", "Orc Grunt", "Skeleton", "Dark Cultist",
	"Stone Troll", "Vampire Bat", "Shadow Imp", "Stone Golem",
]

const BOSS_NAMES := [
	"Floor Warden", "Dungeon Beast", "Lich Overlord",
	"Corrupted Champion", "Void Colossus", "Infernal Drake",
	"Ancient Revenant", "Chaos Titan", "Abyss Sovereign",
	"The Final Guardian",
]


func make_enemy_party(floor_num: int, floor_type: String) -> Array:
	var enemies: Array = []
	var count := _get_count(floor_type, floor_num)
	for i in range(count):
		enemies.append(_make_enemy(floor_num, i, floor_type == "boss", floor_type == "elite"))
	return enemies


func _get_count(floor_type: String, floor_num: int) -> int:
	match floor_type:
		"boss":  return 1
		"elite": return 2
		_:       return clampi(2 + floor_num / 20, 2, 4)


func _make_enemy(floor: int, index: int, is_boss: bool, is_elite: bool) -> HeroInstance:
	var data := HeroData.new()
	var tier  := floor / 10 + 1

	if is_boss:
		var bi := max(0, floor / 10 - 1) % BOSS_NAMES.size()
		data.hero_name       = BOSS_NAMES[bi]
		data.hero_id         = "enemy_boss_f%d" % floor
		data.base_hp         = 200 + floor * 12
		data.base_atk        = 18 + floor * 2
		data.base_def        = 10 + tier * 2
		data.base_spd        = 8 + tier
		data.hp_growth       = 35.0
		data.atk_growth      = 5.0
		data.def_growth      = 2.5
		data.base_crit_chance = 0.12
		data.base_crit_mult  = 2.0
	elif is_elite:
		data.hero_name       = "Elite " + ENEMY_NAMES[(floor + index) % ENEMY_NAMES.size()]
		data.hero_id         = "enemy_elite_f%d_%d" % [floor, index]
		data.base_hp         = 120 + floor * 8
		data.base_atk        = 14 + floor
		data.base_def        = 6 + tier
		data.base_spd        = 10 + tier
		data.hp_growth       = 20.0
		data.atk_growth      = 3.5
		data.def_growth      = 1.5
		data.base_crit_chance = 0.10
		data.base_crit_mult  = 1.8
	else:
		data.hero_name       = ENEMY_NAMES[(floor + index) % ENEMY_NAMES.size()]
		data.hero_id         = "enemy_f%d_%d" % [floor, index]
		data.base_hp         = 60 + floor * 6
		data.base_atk        = 8 + floor
		data.base_def        = 3 + tier
		data.base_spd        = 6 + tier * 2
		data.hp_growth       = 12.0
		data.atk_growth      = 2.0
		data.def_growth      = 1.0
		data.base_crit_chance = 0.05
		data.base_crit_mult  = 1.5

	data.base_morale = 100
	data.rarity      = HeroData.Rarity.COMMON

	# Basic strike
	var strike := SkillData.new()
	strike.skill_name     = "Strike"
	strike.skill_id       = "enemy_strike_%d_%d" % [floor, index]
	strike.effect_type    = SkillData.EffectType.DAMAGE
	strike.target_type    = SkillData.TargetType.SINGLE_ENEMY
	strike.atk_multiplier = 1.0
	strike.cooldown_turns = 0
	data.skills.append(strike)

	# Bosses also have a heavy blow
	if is_boss:
		var heavy := SkillData.new()
		heavy.skill_name     = "Crushing Blow"
		heavy.skill_id       = "enemy_heavy_%d" % floor
		heavy.effect_type    = SkillData.EffectType.DAMAGE
		heavy.target_type    = SkillData.TargetType.SINGLE_ENEMY
		heavy.atk_multiplier = 2.5
		heavy.cooldown_turns = 3
		heavy.priority       = 10
		data.skills.append(heavy)

	var inst := HeroInstance.create(data, "enemy_run")
	inst.level = max(1, floor - 1 + randi_range(0, 2))
	inst.recalculate_stats()
	return inst
