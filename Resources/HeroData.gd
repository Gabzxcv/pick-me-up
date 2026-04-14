class_name HeroData
extends Resource

@export var hero_name: String = "Unknown"
@export var hero_id: String = "hero_000"
@export_multiline var backstory: String = ""
@export var portrait: Texture2D
@export var battle_sprite: Texture2D

enum Rarity { COMMON, RARE, EPIC, LEGENDARY }
@export var rarity: Rarity = Rarity.COMMON

enum Role { TANK, WARRIOR, MAGE, SUPPORT, ASSASSIN, RANGER }
@export var role: Role = Role.WARRIOR

@export_group("Base Stats")
@export var base_hp: int = 100
@export var base_atk: int = 10
@export var base_def: int = 5
@export var base_spd: int = 10
@export var base_crit_chance: float = 0.05
@export var base_crit_mult: float = 1.5

@export_group("Stat Growth")
@export var hp_growth: float = 20.0
@export var atk_growth: float = 3.0
@export var def_growth: float = 1.5
@export var spd_growth: float = 0.5

@export_group("Skills")
@export var skills: Array[SkillData] = []

@export_group("Psychology")
enum Personality { BRAVE, COWARDLY, LOYAL, VENGEFUL, RECKLESS, CALM }
@export var personality: Personality = Personality.CALM
@export var base_morale: int = 100
@export var loyalty_threshold: int = 30


func get_stat_at_level(stat: String, level: int) -> float:
	match stat:
		"hp":  return base_hp  + hp_growth  * (level - 1)
		"atk": return base_atk + atk_growth * (level - 1)
		"def": return base_def + def_growth * (level - 1)
		"spd": return base_spd + spd_growth * (level - 1)
	return 0.0


func get_rarity_label() -> String:
	return Rarity.keys()[rarity]
