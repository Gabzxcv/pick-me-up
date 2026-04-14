extends Node2D

@export var test_hero: HeroData

func _ready() -> void:
	if not test_hero:
		print("ERROR: assign hero_Tirus.tres in the Inspector")
		return

	print("=== HERO LOADED ===")
	print("Name:     ", test_hero.hero_name)
	print("Rarity:   ", test_hero.get_rarity_label())
	print("HP lv1:   ", test_hero.get_stat_at_level("hp", 1))
	print("HP lv10:  ", test_hero.get_stat_at_level("hp", 10))
	print("Skills:   ", test_hero.skills.size())
	for s in test_hero.skills:
		print("  → ", s.skill_name, " | cd:", s.cooldown_turns, " | x", s.atk_multiplier)

	var inst = HeroInstance.create(test_hero, "test_run_01")
	print("\n=== INSTANCE ===")
	print("Max HP:  ", inst.max_hp)
	print("ATK:     ", inst.atk)
	print("Morale:  ", inst.morale)

	var dmg = inst.take_damage(50)
	print("Took %d dmg → %d/%d HP" % [dmg, inst.current_hp, inst.max_hp])

	inst.add_xp(150)
	print("After XP → Level:", inst.level, " HP:", inst.max_hp)
