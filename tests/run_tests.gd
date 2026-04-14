extends SceneTree

const HeroDataScript = preload("res://Resources/HeroData.gd")
const HeroInstanceScript = preload("res://Resources/HeroInstance.gd")
const SkillDataScript = preload("res://Resources/SkillData.gd")
const RunStateScript = preload("res://autoloads/RunState.gd")
const EnemyFactoryScript = preload("res://autoloads/EnemyFactory.gd")
const BattleManagerScript = preload("res://autoloads/BattleManager.gd")

var _assertions := 0
var _failures: Array[String] = []


func _init() -> void:
	_test_hero_data()
	_test_hero_instance()
	_test_run_state()
	_test_gacha_manager()
	_test_enemy_factory()
	_test_battle_manager()

	if _failures.is_empty():
		print("PASS: %d assertions" % _assertions)
		quit(0)
		return

	push_error("FAIL: %d failures out of %d assertions" % [_failures.size(), _assertions])
	for failure in _failures:
		push_error(" - " + failure)
	quit(1)


func _expect(condition: bool, message: String) -> void:
	_assertions += 1
	if not condition:
		_failures.append(message)


func _hero_data(name: String = "Hero", hero_id: String = "hero_test",
		rarity: int = HeroData.Rarity.COMMON) -> HeroData:
	var h: HeroData = HeroDataScript.new()
	h.hero_name = name
	h.hero_id = hero_id
	h.rarity = rarity
	h.base_hp = 100
	h.base_atk = 10
	h.base_def = 5
	h.base_spd = 10
	h.hp_growth = 20.0
	h.atk_growth = 3.0
	h.def_growth = 1.5
	h.spd_growth = 0.5
	h.base_crit_chance = 0.0
	h.base_crit_mult = 2.0
	h.base_morale = 80
	return h


func _skill(skill_id: String, priority: int, cooldown: int,
		target_type: int = SkillData.TargetType.SINGLE_ENEMY,
		effect_type: int = SkillData.EffectType.DAMAGE) -> SkillData:
	var s: SkillData = SkillDataScript.new()
	s.skill_name = skill_id
	s.skill_id = skill_id
	s.priority = priority
	s.cooldown_turns = cooldown
	s.target_type = target_type
	s.effect_type = effect_type
	s.atk_multiplier = 1.0
	return s


func _hero_instance(name: String, hero_id: String, level: int = 1, morale: int = 100) -> HeroInstance:
	var h = _hero_data(name, hero_id)
	var inst = HeroInstance.create(h, "run")
	inst.level = level
	inst.recalculate_stats()
	inst.current_hp = inst.max_hp
	inst.morale = morale
	return inst


func _test_hero_data() -> void:
	var h = _hero_data("Lyra", "hero_lyra", HeroData.Rarity.EPIC)
	_expect(is_equal_approx(h.get_stat_at_level("hp", 1), 100.0), "HeroData hp level 1 should equal base")
	_expect(is_equal_approx(h.get_stat_at_level("atk", 3), 16.0), "HeroData atk level growth should apply")
	_expect(is_equal_approx(h.get_stat_at_level("unknown", 5), 0.0), "HeroData unknown stat should return 0")
	_expect(h.get_rarity_label() == "EPIC", "HeroData rarity label should match enum")


func _test_hero_instance() -> void:
	var h = _hero_data("Kael", "hero_kael")
	var inst = HeroInstance.create(h, "run123")
	_expect(inst.instance_id == "hero_kael_run123", "HeroInstance.create should set instance_id")
	_expect(inst.max_hp == 100 and inst.atk == 10 and inst.def_stat == 5 and inst.spd == 10,
		"HeroInstance.create should initialize stats from HeroData")

	inst.current_hp = 30
	var healed = inst.heal(50)
	_expect(healed == 50 and inst.current_hp == 80, "HeroInstance.heal should restore requested amount when possible")
	healed = inst.heal(50)
	_expect(healed == 20 and inst.current_hp == 100, "HeroInstance.heal should clamp to max hp")

	var mitigated = inst.take_damage(3)
	_expect(mitigated == 1 and inst.current_hp == 99, "HeroInstance.take_damage should mitigate with minimum 1")
	inst.take_damage(9999)
	_expect(inst.is_dead and not inst.is_alive(), "HeroInstance should die at zero hp")

	var dead_xp = inst.current_xp
	_expect(not inst.add_xp(200) and inst.current_xp == dead_xp, "Dead HeroInstance should not gain XP")

	var leveller = HeroInstance.create(h, "run124")
	leveller.current_xp = 90
	var levelled = leveller.add_xp(20)
	_expect(levelled and leveller.level == 2, "HeroInstance.add_xp should trigger level up")
	_expect(leveller.current_xp == 10 and leveller.xp_to_next == 125, "HeroInstance level up should update XP values")
	_expect(leveller.max_hp == 120 and leveller.atk == 13, "HeroInstance level up should recalculate stats")

	leveller.morale = 95
	leveller.adjust_morale(20)
	_expect(leveller.morale == 100, "HeroInstance.adjust_morale should clamp upper bound")
	leveller.adjust_morale(-200)
	_expect(leveller.morale == 0, "HeroInstance.adjust_morale should clamp lower bound")

	leveller.current_hp = 42
	leveller.stress = 7
	leveller.kill_count = 3
	var saved = leveller.to_dict()
	var loaded = HeroInstance.from_dict(saved, h)
	_expect(loaded.instance_id == leveller.instance_id, "HeroInstance.from_dict should restore instance id")
	_expect(loaded.level == leveller.level and loaded.current_xp == leveller.current_xp,
		"HeroInstance.from_dict should restore progression fields")
	_expect(loaded.current_hp == 42 and loaded.stress == 7 and loaded.kill_count == 3,
		"HeroInstance.from_dict should restore combat fields")


func _test_run_state() -> void:
	var rs = RunStateScript.new()
	rs.max_floor = 10
	rs.start_new_run("seed_abc")
	_expect(rs.run_active, "RunState.start_new_run should set run_active")
	_expect(rs.gold == 50 and rs.gacha_tickets == 3 and rs.pity_counter == 0, "RunState.start_new_run should reset economy")
	_expect(rs.current_floor == 0 and rs.floor_map.size() == 11, "RunState.start_new_run should initialize floor map")

	var hero = _hero_data("Brom", "hero_brom")
	var inst = rs.add_hero(hero)
	_expect(rs.roster.size() == 1 and inst.instance_id == "hero_brom_seed_abc_0", "RunState.add_hero should append roster")
	inst.take_damage(9999)
	_expect(rs.get_living_party().is_empty() and rs.get_dead_heroes().size() == 1, "RunState living/dead filters should work")

	_expect(not rs.spend_gold(999), "RunState.spend_gold should fail if insufficient")
	_expect(rs.spend_gold(10) and rs.gold == 40, "RunState.spend_gold should deduct and succeed when affordable")
	rs.add_gold(15)
	_expect(rs.gold == 55, "RunState.add_gold should increase gold")

	var rng = RandomNumberGenerator.new()
	rng.seed = 123
	_expect(rs._pick_floor_type(rng, 10) == "boss", "RunState floor type should be boss every 10 floors")
	_expect(rs._pick_floor_type(rng, 5) == "elite", "RunState floor type should be elite every 5 floors")
	_expect(rs._pick_modifier(rng, 2) == "", "RunState modifier should be empty before floor 5")

	rs.current_floor = 10
	rs.advance_floor()
	_expect(not rs.run_active, "RunState.advance_floor beyond max should end run with victory")

	var rs_save = RunStateScript.new()
	rs_save.max_floor = 10
	rs_save.start_new_run("save_seed")
	var save_hero = _hero_data("Sera", "hero_sera")
	var save_inst = rs_save.add_hero(save_hero)
	save_inst.add_xp(100)
	rs_save.current_floor = 3
	rs_save.gold = 77
	rs_save.gacha_tickets = 5
	rs_save.save()

	var rs_load = RunStateScript.new()
	var loaded_ok = rs_load.load_save({"hero_sera": save_hero})
	_expect(loaded_ok, "RunState.load_save should load existing save file")
	_expect(rs_load.current_floor == 3 and rs_load.gold == 77 and rs_load.gacha_tickets == 5,
		"RunState.load_save should restore economy and floor state")
	_expect(rs_load.roster.size() == 1 and rs_load.roster[0].data.hero_id == "hero_sera",
		"RunState.load_save should restore roster entries")


func _test_gacha_manager() -> void:
	for rarity in GachaManager.pool.keys():
		GachaManager.pool[rarity].clear()

	var common = _hero_data("Common", "hero_common", HeroData.Rarity.COMMON)
	var rare = _hero_data("Rare", "hero_rare", HeroData.Rarity.RARE)
	var legendary = _hero_data("Legendary", "hero_legend", HeroData.Rarity.LEGENDARY)
	GachaManager.register_hero(common)
	GachaManager.register_hero(rare)
	GachaManager.register_hero(legendary)

	RunState.gacha_tickets = 0
	_expect(GachaManager.single_pull() == null, "GachaManager.single_pull should fail without tickets")

	RunState.gacha_tickets = 1
	var pulled = GachaManager.single_pull()
	_expect(pulled != null and RunState.gacha_tickets == 0, "GachaManager.single_pull should consume one ticket")

	RunState.gacha_tickets = 9
	var ten_fail = GachaManager.ten_pull()
	_expect(ten_fail.is_empty(), "GachaManager.ten_pull should fail with fewer than 10 tickets")

	RunState.pity_counter = GachaManager.PITY_THRESHOLD
	_expect(GachaManager._roll_rarity() == HeroData.Rarity.LEGENDARY, "GachaManager pity threshold should guarantee legendary")

	RunState.pity_counter = GachaManager.PITY_THRESHOLD
	var pity_pull = GachaManager._do_pull()
	_expect(pity_pull != null and RunState.pity_counter == 0, "GachaManager legendary pull should reset pity")


func _test_enemy_factory() -> void:
	var ef = EnemyFactoryScript.new()
	_expect(ef._get_count("boss", 20) == 1, "EnemyFactory boss floor should spawn one enemy")
	_expect(ef._get_count("elite", 20) == 2, "EnemyFactory elite floor should spawn two enemies")
	_expect(ef._get_count("battle", 200) == 4, "EnemyFactory normal floor count should clamp at four")

	var normal_party = ef.make_enemy_party(1, "battle")
	_expect(normal_party.size() == 2, "EnemyFactory normal party size should scale from floor")

	var elite_party = ef.make_enemy_party(12, "elite")
	_expect(elite_party.size() == 2 and elite_party[0].data.hero_name.begins_with("Elite "),
		"EnemyFactory elite enemies should be tagged and sized correctly")

	var boss_party = ef.make_enemy_party(10, "boss")
	_expect(boss_party.size() == 1, "EnemyFactory boss party should contain one unit")
	var boss = boss_party[0]
	_expect(boss.data.skills.size() >= 2, "EnemyFactory boss should have multiple skills")
	_expect(boss.data.skills.any(func(s): return s.skill_id.begins_with("enemy_heavy_")),
		"EnemyFactory boss should include heavy skill")


func _test_battle_manager() -> void:
	var bm = BattleManagerScript.new()
	var attacker = _hero_instance("Attacker", "hero_attacker")
	var target = _hero_instance("Target", "hero_target")
	target.def_stat = 999

	attacker.morale = 100
	_expect(bm._calc_damage(attacker, target, 1.0) == attacker.atk, "BattleManager damage should scale with morale at 100")
	attacker.morale = 0
	_expect(bm._calc_damage(attacker, target, 1.0) == int(attacker.atk * 0.7), "BattleManager damage should reduce with low morale")

	var weak = _hero_instance("Weak", "hero_weak")
	weak.current_hp = 5
	var strong = _hero_instance("Strong", "hero_strong")
	strong.current_hp = 20
	_expect(bm._pick_target([strong, weak]) == weak, "BattleManager should target lowest HP enemy")

	var caster = _hero_instance("Caster", "hero_caster")
	var ally1 = _hero_instance("Ally1", "hero_ally1")
	var ally2 = _hero_instance("Ally2", "hero_ally2")
	ally1.current_hp = ally1.max_hp - 10
	var heal_skill = _skill("heal", 1, 2, SkillData.TargetType.SINGLE_ALLY, SkillData.EffectType.HEAL)
	var single_ally_targets = bm._get_skill_targets(heal_skill, caster, [target], [caster, ally1, ally2])
	_expect(single_ally_targets.size() == 1 and single_ally_targets[0] == ally1,
		"BattleManager SINGLE_ALLY targeting should prefer wounded ally")

	ally1.current_hp = ally1.max_hp
	ally2.current_hp = ally2.max_hp
	var fallback_targets = bm._get_skill_targets(heal_skill, caster, [target], [caster, ally1, ally2])
	_expect(fallback_targets[0] == caster, "BattleManager SINGLE_ALLY should fallback to caster when no ally is wounded")

	var low_priority = _skill("low", 1, 3)
	var high_priority = _skill("high", 10, 4)
	caster.data.skills = [low_priority, high_priority]
	caster.skill_cooldowns["low"] = 1
	caster.skill_cooldowns["high"] = 0
	_expect(bm._pick_skill(caster) == high_priority, "BattleManager should pick highest priority available cooldown skill")

	caster.skill_cooldowns["high"] = 2
	_expect(bm._pick_skill(caster) == null, "BattleManager should return null when no cooldown-based skills are ready")

	caster.skill_cooldowns = {"a": 2, "b": 0}
	bm._tick_cooldowns(caster)
	_expect(caster.skill_cooldowns["a"] == 1 and caster.skill_cooldowns["b"] == 0,
		"BattleManager cooldown tick should decrement and clamp at zero")

	var poisoned = _hero_instance("Poisoned", "hero_poisoned")
	poisoned.status_effects = [{"id": "poison", "duration": 1}]
	var hp_before = poisoned.current_hp
	bm._tick_status_effects(poisoned)
	_expect(poisoned.current_hp < hp_before and poisoned.status_effects.is_empty(),
		"BattleManager poison should deal damage and expire at zero duration")

	var party_dead = _hero_instance("DeadParty", "hero_dead")
	party_dead.take_damage(9999)
	var enemy_alive = _hero_instance("EnemyAlive", "hero_enemy")
	bm._party = [party_dead]
	bm._enemies = [enemy_alive]
	bm._battle_active = true
	bm._check_battle_end()
	_expect(not bm._battle_active, "BattleManager should end battle when party is wiped")

	RunState.start_new_run("battle_test")
	var dead_member = _hero_instance("Fallen", "hero_fallen")
	dead_member.take_damage(9999)
	var living_ally = _hero_instance("Living", "hero_living")
	living_ally.morale = 60
	bm._party = [dead_member, living_ally]
	bm._on_unit_died(dead_member)
	_expect(living_ally.morale == 45, "BattleManager ally death should reduce living allies' morale")
