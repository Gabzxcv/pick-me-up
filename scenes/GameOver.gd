extends Control


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var victory := RunState.current_floor > RunState.max_floor or \
		(not RunState.run_active and RunState.current_floor >= RunState.max_floor)
	# If run is not active and we have living heroes, treat as victory
	if RunState.run_active:
		victory = false
	var living := RunState.get_living_party()
	if not RunState.run_active and living.size() > 0:
		victory = true

	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.06) if not victory else Color(0.04, 0.07, 0.04)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.custom_minimum_size.x = 480
	center.add_child(vbox)

	# Title
	var title := Label.new()
	if victory:
		title.text = "🏆  VICTORY!"
		title.modulate = Color(1.0, 0.85, 0.2)
	else:
		title.text = "💀  DEFEAT"
		title.modulate = Color(0.9, 0.3, 0.3)
	title.add_theme_font_size_override("font_size", 46)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Floor reached
	var floor_lbl := Label.new()
	floor_lbl.text = "Floor reached:  %d / %d" % [RunState.current_floor, RunState.max_floor]
	floor_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	floor_lbl.add_theme_font_size_override("font_size", 20)
	vbox.add_child(floor_lbl)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Hero report
	var hero_title := Label.new()
	hero_title.text = "── Heroes ──"
	hero_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hero_title)

	for hero in RunState.roster:
		var row := Label.new()
		if hero.is_dead:
			row.text = "  💀  %s  (Lv.%d)  —  fell on floor %d  —  %d kills" % [
				hero.data.hero_name, hero.level, hero.death_floor, hero.kill_count,
			]
			row.modulate = Color(0.55, 0.55, 0.55)
		else:
			row.text = "  ✅  %s  (Lv.%d)  —  survived  —  %d kills" % [
				hero.data.hero_name, hero.level, hero.kill_count,
			]
		vbox.add_child(row)

	var sep2 := HSeparator.new()
	vbox.add_child(sep2)

	# Gold summary
	var gold_lbl := Label.new()
	gold_lbl.text = "Gold remaining:  💰 %d" % RunState.gold
	gold_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(gold_lbl)

	var gap := Control.new()
	gap.custom_minimum_size.y = 10
	vbox.add_child(gap)

	# Restart
	var restart_btn := Button.new()
	restart_btn.text = "↩  Return to Main Menu"
	restart_btn.custom_minimum_size = Vector2(0, 54)
	restart_btn.pressed.connect(func(): SceneManager.go_to(SceneManager.MAIN_MENU))
	vbox.add_child(restart_btn)
