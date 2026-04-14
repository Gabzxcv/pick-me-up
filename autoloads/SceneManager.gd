extends Node

const MAIN_MENU := "res://scenes/MainMenu.tscn"
const TOWER_MAP := "res://scenes/TowerMap.tscn"
const BATTLE    := "res://scenes/Battle.tscn"
const REST      := "res://scenes/RestEvent.tscn"
const GAME_OVER := "res://scenes/GameOver.tscn"


func go_to(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
