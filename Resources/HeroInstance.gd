class_name HeroInstance
extends Resource

var data: HeroData
var instance_id: String = ""

# Level & XP
var level: int = 1
var current_xp: int = 0
var xp_to_next: int = 100

# Current stats
var max_hp: int = 0
var current_hp: int = 0
var atk: int = 0
var def_stat: int = 0
var spd: int = 0

# Psychology
var morale: int = 100
var stress: int = 0

# Permadeath
var is_dead: bool = false
var death_floor: int = -1
var kill_count: int = 0

# Battle state
var status_effects: Array = []
var skill_cooldowns: Dictionary = {}


# ── Factory ───────────────────────────────────────────────────
static func create(hero_data: HeroData, run_id: String) -> HeroInstance:
	var inst = HeroInstance.new()
	inst.data = hero_data
	inst.instance_id = hero_data.hero_id + "_" + run_id
	inst.morale = hero_data.base_morale
	inst.recalculate_stats()
	return inst


# ── Stats ─────────────────────────────────────────────────────
func recalculate_stats() -> void:
	max_hp   = int(data.get_stat_at_level("hp",  level))
	current_hp = max_hp
	atk      = int(data.get_stat_at_level("atk", level))
	def_stat = int(data.get_stat_at_level("def", level))
	spd      = int(data.get_stat_at_level("spd", level))


# ── XP & Level ────────────────────────────────────────────────
func add_xp(amount: int) -> bool:
	if is_dead:
		return false
	current_xp += amount
	if current_xp >= xp_to_next:
		_level_up()
		return true
	return false


func _level_up() -> void:
	level += 1
	current_xp -= xp_to_next
	xp_to_next = int(xp_to_next * 1.25)
	recalculate_stats()
	current_hp = max_hp
	print("%s levelled up to %d!" % [data.hero_name, level])


# ── Combat ────────────────────────────────────────────────────
func take_damage(amount: int) -> int:
	var mitigated = max(1, amount - def_stat)
	current_hp = max(0, current_hp - mitigated)
	if current_hp == 0:
		_on_death()
	return mitigated


func heal(amount: int) -> int:
	var healed = min(amount, max_hp - current_hp)
	current_hp += healed
	return healed


func is_alive() -> bool:
	return current_hp > 0 and not is_dead


func adjust_morale(delta: int) -> void:
	morale = clamp(morale + delta, 0, 100)


func _on_death() -> void:
	is_dead = true
	print("%s has fallen!" % data.hero_name)


# ── Serialization ─────────────────────────────────────────────
func to_dict() -> Dictionary:
	return {
		"hero_id":     data.hero_id,
		"instance_id": instance_id,
		"level":       level,
		"current_xp":  current_xp,
		"xp_to_next":  xp_to_next,
		"current_hp":  current_hp,
		"morale":      morale,
		"stress":      stress,
		"is_dead":     is_dead,
		"death_floor": death_floor,
		"kill_count":  kill_count,
	}


static func from_dict(d: Dictionary, hero_data: HeroData) -> HeroInstance:
	var inst = HeroInstance.create(hero_data, "loaded")
	inst.instance_id = d.get("instance_id", inst.instance_id)
	inst.level       = d.get("level", 1)
	inst.current_xp  = d.get("current_xp", 0)
	inst.xp_to_next  = d.get("xp_to_next", 100)
	inst.morale      = d.get("morale", hero_data.base_morale)
	inst.stress      = d.get("stress", 0)
	inst.is_dead     = d.get("is_dead", false)
	inst.death_floor = d.get("death_floor", -1)
	inst.kill_count  = d.get("kill_count", 0)
	inst.recalculate_stats()
	inst.current_hp  = d.get("current_hp", inst.max_hp)
	return inst
