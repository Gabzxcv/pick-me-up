extends Control

var _seed_input: LineEdit


func _ready() -> void:
	_setup_gacha_pool()
	_build_ui()


func _setup_gacha_pool() -> void:
	for rarity in GachaManager.pool:
		GachaManager.pool[rarity].clear()

	var paths := [
		"res://Resources/heroes/hero_Brom.tres",
		"res://Resources/heroes/hero_Lyra.tres",
		"res://Resources/heroes/hero_Kael.tres",
	]
	for path in paths:
		if ResourceLoader.exists(path):
			GachaManager.register_hero(load(path))


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.06, 0.12)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "PICK ME UP"
	title.add_theme_font_size_override("font_size", 52)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "A Roguelite Tower Climber"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)

	var gap := Control.new()
	gap.custom_minimum_size.y = 24
	vbox.add_child(gap)

	var lbl := Label.new()
	lbl.text = "Run Seed  (leave blank for random)"
	vbox.add_child(lbl)

	_seed_input = LineEdit.new()
	_seed_input.placeholder_text = "e.g.  dragon_tower  (blank = random)"
	_seed_input.text = ""
	_seed_input.custom_minimum_size.x = 320
	vbox.add_child(_seed_input)

	var gap2 := Control.new()
	gap2.custom_minimum_size.y = 10
	vbox.add_child(gap2)

	var start_btn := Button.new()
	start_btn.text = "▶  New Run"
	start_btn.custom_minimum_size = Vector2(320, 54)
	start_btn.pressed.connect(_on_start_pressed)
	vbox.add_child(start_btn)

	if FileAccess.file_exists("user://run_save.json"):
		var cont_btn := Button.new()
		cont_btn.text = "↩  Continue"
		cont_btn.custom_minimum_size = Vector2(320, 54)
		cont_btn.pressed.connect(_on_continue_pressed)
		vbox.add_child(cont_btn)


func _on_start_pressed() -> void:
	var seed_text := _seed_input.text.strip_edges()
	if seed_text.is_empty():
		seed_text = "run_%d" % Time.get_unix_time_from_system()

	RunState.start_new_run(seed_text)

	# Always start with Tirus
	var tirus: HeroData = load("res://Resources/heroes/hero_Tirus.tres")
	if tirus:
		RunState.add_hero(tirus)

	# Pull 2 starter heroes from gacha
	for _i in range(2):
		if RunState.gacha_tickets > 0:
			var pulled := GachaManager.single_pull()
			if pulled:
				RunState.add_hero(pulled)

	SceneManager.go_to(SceneManager.TOWER_MAP)


func _on_continue_pressed() -> void:
	var hero_db := {}
	var paths := [
		"res://Resources/heroes/hero_Tirus.tres",
		"res://Resources/heroes/hero_Brom.tres",
		"res://Resources/heroes/hero_Lyra.tres",
		"res://Resources/heroes/hero_Kael.tres",
	]
	for path in paths:
		if ResourceLoader.exists(path):
			var hd: HeroData = load(path)
			if hd:
				hero_db[hd.hero_id] = hd

	if RunState.load_save(hero_db):
		SceneManager.go_to(SceneManager.TOWER_MAP)
	else:
		push_warning("Failed to load save — starting fresh.")
		_on_start_pressed()
