extends Node

# ── Signals ───────────────────────────────────────────────────
signal battle_started(party: Array, enemies: Array)
signal turn_started(unit: HeroInstance, turn_number: int)
signal unit_attacked(attacker: HeroInstance, target: HeroInstance, damage: int, is_crit: bool)
signal unit_healed(caster: HeroInstance, target: HeroInstance, amount: int)
signal unit_status_applied(target: HeroInstance, status_id: String)
signal unit_died(unit: HeroInstance, is_party_member: bool)
signal skill_used(caster: HeroInstance, skill: SkillData, targets: Array)
signal battle_ended(victory: bool, surviving_party: Array)
signal morale_changed(hero: HeroInstance, delta: int, new_value: int)

# ── Internal state ────────────────────────────────────────────
var _party: Array = []
var _enemies: Array = []
var _turn_order: Array = []
var _turn_number: int = 0
var _battle_active: bool = false
var turn_delay: float = 0.8


# ── Entry ─────────────────────────────────────────────────────
func start_battle(party: Array, enemies: Array) -> void:
	_party   = party.filter(func(h): return h.is_alive())
	_enemies = enemies.duplicate()
	_turn_number = 0
	_battle_active = true
	_reset_cooldowns(_party)
	_reset_cooldowns(_enemies)
	_build_turn_order()
	battle_started.emit(_party, _enemies)
	_next_turn()


# ── Turn loop ─────────────────────────────────────────────────
func _next_turn() -> void:
	if not _battle_active:
		return
	_turn_number += 1
	if _turn_order.is_empty():
		_build_turn_order()
	if _turn_order.is_empty():
		_end_battle()
		return

	var unit: HeroInstance = _turn_order.pop_front()
	if not unit.is_alive():
		_next_turn()
		return

	_tick_status_effects(unit)
	_tick_cooldowns(unit)
	turn_started.emit(unit, _turn_number)

	if _is_party_member(unit):
		_take_action(unit, _enemies)
	else:
		_take_action(unit, _party)

	_check_battle_end()

	if _battle_active:
		if turn_delay > 0.0:
			await get_tree().create_timer(turn_delay).timeout
		_next_turn()


# ── Action ────────────────────────────────────────────────────
func _take_action(unit: HeroInstance, enemies: Array) -> void:
	var living = enemies.filter(func(e): return e.is_alive())
	if living.is_empty():
		return
	var skill = _pick_skill(unit)
	if skill == null:
		_resolve_basic_attack(unit, _pick_target(living))
	else:
		_resolve_skill(unit, skill, living)


func _resolve_basic_attack(attacker: HeroInstance, target: HeroInstance) -> void:
	var damage = _calc_damage(attacker, target, 1.0)
	var is_crit = _roll_crit(attacker)
	if is_crit:
		damage = int(damage * attacker.data.base_crit_mult)
	var dealt = target.take_damage(damage)
	unit_attacked.emit(attacker, target, dealt, is_crit)
	if not target.is_alive():
		_on_unit_died(target)
		attacker.kill_count += 1


func _resolve_skill(caster: HeroInstance, skill: SkillData, living_enemies: Array) -> void:
	var living_allies = (_party if _is_party_member(caster) else _enemies).filter(
		func(h): return h.is_alive()
	)
	var targets = _get_skill_targets(skill, caster, living_enemies, living_allies)
	skill_used.emit(caster, skill, targets)
	caster.skill_cooldowns[skill.skill_id] = skill.cooldown_turns

	for target in targets:
		match skill.effect_type:
			SkillData.EffectType.DAMAGE:
				var dmg = _calc_damage(caster, target, skill.atk_multiplier) + skill.flat_value
				var is_crit = _roll_crit(caster)
				if is_crit:
					dmg = int(dmg * caster.data.base_crit_mult)
				var dealt = target.take_damage(dmg)
				unit_attacked.emit(caster, target, dealt, is_crit)
				if not target.is_alive():
					_on_unit_died(target)
					caster.kill_count += 1
			SkillData.EffectType.HEAL:
				var amount = int(caster.atk * skill.atk_multiplier) + skill.flat_value
				var healed = target.heal(amount)
				unit_healed.emit(caster, target, healed)

		if skill.applies_status != "" and randf() < skill.status_chance:
			_apply_status(target, skill.applies_status, skill.status_duration)


# ── Damage ────────────────────────────────────────────────────
func _calc_damage(attacker: HeroInstance, target: HeroInstance, mult: float) -> int:
	var base = attacker.atk * mult
	var morale_mod = 0.7 + (attacker.morale / 100.0) * 0.3
	return max(1, int(base * morale_mod))


func _roll_crit(unit: HeroInstance) -> bool:
	return randf() < unit.data.base_crit_chance


# ── Targeting ─────────────────────────────────────────────────
func _pick_target(enemies: Array) -> HeroInstance:
	var sorted = enemies.duplicate()
	sorted.sort_custom(func(a, b): return a.current_hp < b.current_hp)
	return sorted[0]


func _get_skill_targets(skill: SkillData, caster: HeroInstance,
		enemies: Array, allies: Array) -> Array:
	match skill.target_type:
		SkillData.TargetType.SINGLE_ENEMY:  return [_pick_target(enemies)]
		SkillData.TargetType.ALL_ENEMIES:   return enemies
		SkillData.TargetType.SINGLE_ALLY:
			var wounded = allies.filter(func(h): return h.current_hp < h.max_hp)
			return [wounded[0] if not wounded.is_empty() else caster]
		SkillData.TargetType.ALL_ALLIES:    return allies
		SkillData.TargetType.SELF:          return [caster]
	return [_pick_target(enemies)]


# ── Skill selection ───────────────────────────────────────────
func _pick_skill(unit: HeroInstance) -> SkillData:
	var available = unit.data.skills.filter(func(s):
		return s.cooldown_turns > 0 and unit.skill_cooldowns.get(s.skill_id, 0) <= 0
	)
	if available.is_empty():
		return null
	available.sort_custom(func(a, b): return a.priority > b.priority)
	return available[0]


# ── Status effects ────────────────────────────────────────────
func _apply_status(target: HeroInstance, status_id: String, duration: int) -> void:
	target.status_effects.append({"id": status_id, "duration": duration})
	unit_status_applied.emit(target, status_id)


func _tick_status_effects(unit: HeroInstance) -> void:
	var expired = []
	for effect in unit.status_effects:
		match effect.id:
			"poison":
				var dmg = max(1, int(unit.max_hp * 0.05))
				unit.current_hp = max(0, unit.current_hp - dmg)
				unit_attacked.emit(unit, unit, dmg, false)
		effect.duration -= 1
		if effect.duration <= 0:
			expired.append(effect)
	for e in expired:
		unit.status_effects.erase(e)


# ── Cooldowns ─────────────────────────────────────────────────
func _tick_cooldowns(unit: HeroInstance) -> void:
	for key in unit.skill_cooldowns.keys():
		unit.skill_cooldowns[key] = max(0, unit.skill_cooldowns[key] - 1)


func _reset_cooldowns(units: Array) -> void:
	for unit in units:
		unit.skill_cooldowns.clear()


# ── Turn order ────────────────────────────────────────────────
func _build_turn_order() -> void:
	var all = (_party + _enemies).filter(func(u): return u.is_alive())
	all.sort_custom(func(a, b): return a.spd > b.spd)
	_turn_order = all


# ── Win / loss ────────────────────────────────────────────────
func _check_battle_end() -> void:
	var enemies_alive = _enemies.any(func(e): return e.is_alive())
	var party_alive   = _party.any(func(h): return h.is_alive())
	if not enemies_alive or not party_alive:
		_end_battle()


func _end_battle() -> void:
	_battle_active = false
	var victory = _enemies.all(func(e): return not e.is_alive())
	var survivors = _party.filter(func(h): return h.is_alive())
	if victory:
		_grant_rewards(survivors)
	battle_ended.emit(victory, survivors)


func _grant_rewards(survivors: Array) -> void:
	var xp = 30 + RunState.current_floor * 5
	var gold = 10 + RunState.current_floor * 3
	for hero in survivors:
		hero.add_xp(xp)
	RunState.add_gold(gold)


# ── Death ─────────────────────────────────────────────────────
func _on_unit_died(unit: HeroInstance) -> void:
	var is_party = _is_party_member(unit)
	unit_died.emit(unit, is_party)
	if is_party:
		RunState.on_hero_died(unit)
		for ally in _party:
			if ally.is_alive():
				ally.adjust_morale(-15)
				morale_changed.emit(ally, -15, ally.morale)


func _is_party_member(unit: HeroInstance) -> bool:
	return _party.has(unit)
