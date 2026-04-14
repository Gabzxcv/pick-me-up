extends Node

# ── Signals ───────────────────────────────────────────────────
signal run_started
signal run_ended(victory: bool)
signal hero_died(hero: HeroInstance)
signal floor_changed(new_floor: int)
signal gold_changed(new_total: int)

# ── Run state ─────────────────────────────────────────────────
var run_id: String = ""
var player_seed: int = 0
var current_floor: int = 0
var max_floor: int = 100
var run_active: bool = false

# ── Roster ────────────────────────────────────────────────────
var roster: Array = []
var max_party_size: int = 5

# ── Resources ─────────────────────────────────────────────────
var gold: int = 0
var gacha_tickets: int = 0
var pity_counter: int = 0

# ── Tower map ─────────────────────────────────────────────────
var floor_map: Array = []


# ── Start / End ───────────────────────────────────────────────
func start_new_run(seed_string: String) -> void:
	run_id       = seed_string
	player_seed  = seed_string.hash()
	current_floor = 0
	gold          = 50
	gacha_tickets = 3
	pity_counter  = 0
	roster.clear()
	floor_map.clear()
	run_active = true
	_generate_tower()
	run_started.emit()
	print("Run started — seed: %d" % player_seed)


func end_run(victory: bool) -> void:
	run_active = false
	run_ended.emit(victory)
	print("Run ended — victory: %s" % str(victory))


# ── Roster ────────────────────────────────────────────────────
func add_hero(hero_data: HeroData) -> HeroInstance:
	var inst = HeroInstance.create(hero_data, run_id + "_" + str(roster.size()))
	roster.append(inst)
	return inst


func get_living_party() -> Array:
	return roster.filter(func(h): return h.is_alive())


func get_dead_heroes() -> Array:
	return roster.filter(func(h): return h.is_dead)


func on_hero_died(hero: HeroInstance) -> void:
	hero.death_floor = current_floor
	hero_died.emit(hero)
	if get_living_party().is_empty():
		end_run(false)


# ── Floor ─────────────────────────────────────────────────────
func advance_floor() -> void:
	current_floor += 1
	if current_floor > max_floor:
		end_run(true)
		return
	floor_changed.emit(current_floor)


func get_current_floor_data() -> Dictionary:
	if current_floor < floor_map.size():
		return floor_map[current_floor]
	return {}


# ── Gold ──────────────────────────────────────────────────────
func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)


func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true


# ── Tower generation ──────────────────────────────────────────
func _generate_tower() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = player_seed
	floor_map.clear()
	for i in range(max_floor + 1):
		floor_map.append({
			"floor":      i,
			"type":       _pick_floor_type(rng, i),
			"enemy_tier": i / 10 + 1,
			"modifier":   _pick_modifier(rng, i),
		})


func _pick_floor_type(rng: RandomNumberGenerator, floor: int) -> String:
	if floor % 10 == 0 and floor > 0:
		return "boss"
	if floor % 5 == 0:
		return "elite"
	var roll = rng.randi_range(0, 9)
	match roll:
		0, 1: return "rest"
		2:    return "shop"
		3:    return "event"
		_:    return "battle"


func _pick_modifier(rng: RandomNumberGenerator, floor: int) -> String:
	if floor < 5:
		return ""
	var mods = ["", "", "", "thorns", "haste", "fog_of_war", "double_hp"]
	return mods[rng.randi_range(0, mods.size() - 1)]


# ── Save / Load ───────────────────────────────────────────────
func save() -> void:
	var data: Dictionary = {
		"run_id":        run_id,
		"player_seed":   player_seed,
		"current_floor": current_floor,
		"gold":          gold,
		"gacha_tickets": gacha_tickets,
		"pity_counter":  pity_counter,
		"roster":        roster.map(func(h): return h.to_dict()),
		"floor_map":     floor_map,
	}
	var file = FileAccess.open("user://run_save.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("Game saved.")


func load_save(hero_db: Dictionary) -> bool:
	if not FileAccess.file_exists("user://run_save.json"):
		return false
	var file = FileAccess.open("user://run_save.json", FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null:
		return false
	run_id        = parsed.get("run_id", "")
	player_seed   = parsed.get("player_seed", 0)
	current_floor = parsed.get("current_floor", 0)
	gold          = parsed.get("gold", 0)
	gacha_tickets = parsed.get("gacha_tickets", 0)
	pity_counter  = parsed.get("pity_counter", 0)
	floor_map     = parsed.get("floor_map", [])
	roster.clear()
	for hero_dict in parsed.get("roster", []):
		var hd = hero_db.get(hero_dict.get("hero_id"))
		if hd:
			roster.append(HeroInstance.from_dict(hero_dict, hd))
	run_active = true
	return true
