# TestBattle.gd — paste this into your first scene to verify everything works
extends Node2D

func _ready() -> void:
	print("=== BATTLE TEST ===")

	# 1. Verify RunState autoload works
	RunState.start_new_run("player_test_seed")
	print("Floor: ", RunState.current_floor)
	print("Gold: ", RunState.gold)
	print("Tower floor 3: ", RunState.floor_map[3])

	# 2. Connect to BattleManager signals
	BattleManager.battle_ended.connect(_on_battle_ended)
	BattleManager.unit_attacked.connect(_on_unit_attacked)

	print("Autoloads connected. Ready.")

func _on_battle_ended(victory: bool, survivors: Array) -> void:
	print("Battle ended! Victory: ", victory)
	print("Survivors: ", survivors.size())

func _on_unit_attacked(attacker, target, damage: int, is_crit: bool) -> void:
	var crit_text = " [CRIT!]" if is_crit else ""
	print("%s hit %s for %d%s" % [attacker.data.hero_name, target.data.hero_name, damage, crit_text])
