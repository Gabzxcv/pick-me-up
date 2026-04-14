# HeroSetup.gd
# Attach this to a Node in a temporary scene, run it once to print
# .tres file content for all skills and heroes, then delete the scene.
# OR just read the printed output and create the .tres files manually.
#
# Run with F6, copy the output, done.

extends Node

func _ready() -> void:
	print("=== SKILL: basic_attack.tres — fix missing fields ===")
	print("""
skill_name = \"Basic Attack\"
skill_id = \"skill_bas_atk\"
description = \"A straightforward strike.\"
cooldown_turns = 0
priority = 0
effect_type = 0
atk_multiplier = 1.0
flat_value = 0
""")

	print("=== KAEL unique skill: arcane_burst.tres ===")
	print("""
skill_name = \"Arcane Burst\"
skill_id = \"skill_arcane_burst\"
description = \"Unleashes a blast of raw arcane energy hitting all enemies.\"
target_type = 1
cooldown_turns = 4
priority = 15
effect_type = 0
atk_multiplier = 1.8
flat_value = 0
""")

	print("=== LYRA unique skill: quick_shot.tres ===")
	print("""
skill_name = \"Quick Shot\"
skill_id = \"skill_quick_shot\"
description = \"A rapid arrow that almost always lands a critical hit.\"
target_type = 0
cooldown_turns = 2
priority = 8
effect_type = 0
atk_multiplier = 1.2
flat_value = 0
applies_status = \"\"
""")

	print("=== BROM unique skill: shield_slam.tres ===")
	print("""
skill_name = \"Shield Slam\"
skill_id = \"skill_shield_slam\"
description = \"A powerful shield bash that stuns the enemy.\"
target_type = 0
cooldown_turns = 3
priority = 12
effect_type = 0
atk_multiplier = 1.5
flat_value = 10
applies_status = \"stun\"
status_chance = 0.4
status_duration = 1
""")

	print("=== TIRUS unique skill: rallying_cry.tres ===")
	print("""
skill_name = \"Rallying Cry\"
skill_id = \"skill_rallying_cry\"
description = \"Inspires the party, healing all allies.\"
target_type = 3
cooldown_turns = 5
priority = 20
effect_type = 1
atk_multiplier = 0.8
flat_value = 20
""")

	print("=== VAEL unique skill: shadow_step.tres ===")
	print("""
skill_name = \"Shadow Step\"
skill_id = \"skill_shadow_step\"
description = \"Blinks behind the target for a devastating backstab.\"
target_type = 0
cooldown_turns = 3
priority = 18
effect_type = 0
atk_multiplier = 3.0
flat_value = 0
applies_status = \"poison\"
status_chance = 0.5
status_duration = 3
""")

	print("=== SERA unique skill: holy_light.tres ===")
	print("""
skill_name = \"Holy Light\"
skill_id = \"skill_holy_light\"
description = \"Calls down sacred light to heal the most wounded ally.\"
target_type = 2
cooldown_turns = 3
priority = 20
effect_type = 1
atk_multiplier = 1.5
flat_value = 30
""")
