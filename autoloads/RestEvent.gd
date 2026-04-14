extends Control

var _floor_type: String = "rest"
var _modifier: String   = ""


func _ready() -> void:
	var fdata  := RunState.get_current_floor_data()
	_floor_type = fdata.get("type", "rest")
	_modifier   = fdata.get("modifier", "")
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.10, 0.09)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.custom_minimum_size.x = 460
	center.add_child(vbox)

	var floor_lbl := Label.new()
	floor_lbl.text = "Floor %d" % RunState.current_floor
	floor_lbl.add_theme_font_size_override("font_size", 22)
	floor_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(floor_lbl)

	if _modifier != "":
		var mod_lbl := Label.new()
		mod_lbl.text = "⚠ Modifier: %s" % _modifier
		mod_lbl.modulate = Color(1.0, 0.8, 0.3)
		mod_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(mod_lbl)

	# Morale report
	var living := RunState.get_living_party()
	if living.size() > 0:
		var morale_lbl := Label.new()
		morale_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		morale_lbl.modulate = Color(0.8, 0.9, 1.0)
		var low_morale = living.filter(func(h): return h.morale < 40)
		if low_morale.size() > 0:
			var names = low_morale.map(func(h): return h.data.hero_name)
			morale_lbl.text = "⚠ %s look demoralized..." % ", ".join(names)
		else:
			morale_lbl.text = "♥ Party morale is holding strong."
		vbox.add_child(morale_lbl)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	match _floor_type:
		"rest":  _add_rest_options(vbox)
		"shop":  _add_shop_options(vbox)
		"event": _add_event_options(vbox)
		_:       _add_rest_options(vbox)


func _add_rest_options(vbox: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "🏕  Rest Campfire"
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = "Your weary party sets up camp for the night.\nChoose how to spend the rest."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	# Check for morale events
	_add_morale_dialogue(vbox)

	var heal_btn := Button.new()
	heal_btn.text = "💚  Heal Party  (+30% Max HP each)"
	heal_btn.custom_minimum_size = Vector2(0, 50)
	heal_btn.pressed.connect(_on_heal_pressed)
	vbox.add_child(heal_btn)

	var morale_btn := Button.new()
	morale_btn.text = "🔥  Boost Morale  (+20 morale all)"
	morale_btn.custom_minimum_size = Vector2(0, 50)
	morale_btn.pressed.connect(_on_morale_pressed)
	vbox.add_child(morale_btn)

	var train_btn := Button.new()
	train_btn.text = "⚔  Train  (+15 XP all)"
	train_btn.custom_minimum_size = Vector2(0, 50)
	train_btn.pressed.connect(_on_train_pressed)
	vbox.add_child(train_btn)

	var skip_btn := Button.new()
	skip_btn.text = "➜  Move On"
	skip_btn.custom_minimum_size = Vector2(0, 44)
	skip_btn.pressed.connect(_leave)
	vbox.add_child(skip_btn)


func _add_morale_dialogue(vbox: VBoxContainer) -> void:
	# Show dialogue from a low-morale hero if one exists
	var living := RunState.get_living_party()
	var low = living.filter(func(h): return h.morale < 40)
	if low.is_empty():
		return

	var hero: HeroInstance = low[0]
	var lines := {
		0: "\"%s: I don't know how much longer I can do this...\"" % hero.data.hero_name,   # BRAVE
		1: "\"%s: I want to go home. I really do.\"" % hero.data.hero_name,                # COWARDLY
		2: "\"%s: I'm doing this for the party. That's all.\"" % hero.data.hero_name,       # LOYAL
		3: "\"%s: They'll pay for everything they've done.\"" % hero.data.hero_name,        # VENGEFUL
		4: "\"%s: I'm fine. Let's just keep moving.\"" % hero.data.hero_name,              # RECKLESS
		5: "\"%s: ...I need a moment.\"" % hero.data.hero_name,                            # CALM
	}
	var personality_idx = int(hero.data.personality)
	var line = lines.get(personality_idx, "\"...\"")

	var dialogue := Label.new()
	dialogue.text = line
	dialogue.modulate = Color(0.9, 0.75, 0.5)
	dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(dialogue)


func _add_shop_options(vbox: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "🛒  Travelling Merchant"
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var gold_lbl := Label.new()
	gold_lbl.text = "Your gold: 💰 %d" % RunState.gold
	gold_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(gold_lbl)

	_add_shop_button(vbox, gold_lbl,
		"🎫  Buy Gacha Ticket  (40 💰)", 40,
		func():
			RunState.gacha_tickets += 1
	)
	_add_shop_button(vbox, gold_lbl,
		"💊  Heal Party  (25 💰)", 25,
		func(): _heal_party(0.5)
	)
	_add_shop_button(vbox, gold_lbl,
		"🔥  Morale Tonic  (20 💰)", 20,
		func(): _boost_morale(25)
	)
	_add_shop_button(vbox, gold_lbl,
		"📖  Skill Scroll  (+20 XP all)  (30 💰)", 30,
		func(): _grant_xp_all(20)
	)

	var leave_btn := Button.new()
	leave_btn.text = "➜  Leave Shop"
	leave_btn.custom_minimum_size = Vector2(0, 44)
	leave_btn.pressed.connect(_leave)
	vbox.add_child(leave_btn)


func _add_shop_button(vbox: VBoxContainer, gold_lbl: Label,
		label: String, cost: int, action: Callable) -> void:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(0, 50)
	btn.disabled = RunState.gold < cost
	btn.pressed.connect(func():
		if RunState.spend_gold(cost):
			action.call()
			gold_lbl.text = "Your gold: 💰 %d" % RunState.gold
			btn.text = "✅  Purchased!  (gold: %d)" % RunState.gold
			btn.disabled = true
	)
	vbox.add_child(btn)


func _add_event_options(vbox: VBoxContainer) -> void:
	var events := [
		{
			"title": "⚗  Mysterious Potion",
			"desc":  "A stranger offers you a glowing vial. It smells faintly of danger.",
			"opts":  [
				["Drink it  (+50 HP first hero)", func(): _first_hero_heal(50)],
				["Sell it  (+15 💰)",              func(): RunState.add_gold(15)],
				["Leave it alone",                 func(): pass],
			]
		},
		{
			"title": "📜  Ancient Tome",
			"desc":  "You find a weathered book of battle lore, crackling with old magic.",
			"opts":  [
				["Study it  (+30 XP all)",          func(): _grant_xp_all(30)],
				["Sell it  (+25 💰)",               func(): RunState.add_gold(25)],
				["Leave it",                        func(): pass],
			]
		},
		{
			"title": "💎  Treasure Chest",
			"desc":  "A locked chest sits in the middle of the path. Trapped? Maybe.",
			"opts":  [
				["Force it open  (+40 💰)",          func(): RunState.add_gold(40)],
				["Pick the lock  (+20 💰, safer)",   func(): RunState.add_gold(20)],
				["Leave it",                         func(): pass],
			]
		},
		{
			"title": "👻  Wandering Spirit",
			"desc":  "A faint specter drifts toward you, eyes hollow with sorrow.",
			"opts":  [
				["Listen to its tale  (+20 morale)", func(): _boost_morale(20)],
				["Banish it  (+10 💰)",              func(): RunState.add_gold(10)],
				["Walk past",                        func(): pass],
			]
		},
		{
			"title": "⚔  Abandoned Armory",
			"desc":  "Old weapons and armor line the walls. Most are rusted beyond use.",
			"opts":  [
				["Salvage parts  (+30 💰)",           func(): RunState.add_gold(30)],
				["Train with the dummies  (+25 XP all)", func(): _grant_xp_all(25)],
				["Keep moving",                       func(): pass],
			]
		},
		{
			"title": "🌿  Hidden Spring",
			"desc":  "You discover a glowing spring tucked behind a crumbling wall.",
			"opts":  [
				["Drink deeply  (+40% HP all)",       func(): _heal_party(0.4)],
				["Bottle some  (+1 🎫)",              func(): _add_ticket()],
				["Ignore it",                         func(): pass],
			]
		},
		{
			"title": "🗣  Deserter Soldier",
			"desc":  "A frightened soldier begs to join you. He seems... unreliable.",
			"opts":  [
				["Encourage him  (+15 morale all)",   func(): _boost_morale(15)],
				["Take his coin  (+20 💰)",           func(): RunState.add_gold(20)],
				["Send him away",                     func(): pass],
			]
		},
		{
			"title": "🕯  Shrine of the Fallen",
			"desc":  "A small shrine honors those who perished in the tower.",
			"opts":  [
				["Pay respects  (+25 morale all)",    func(): _boost_morale(25)],
				["Search for offerings  (+15 💰)",    func(): RunState.add_gold(15)],
				["Walk on",                           func(): pass],
			]
		},
	]

	# Pick event based on floor — deterministic so same seed = same events
	var rng = RandomNumberGenerator.new()
	rng.seed = RunState.player_seed + RunState.current_floor * 7
	var ev: Dictionary = events[rng.randi() % events.size()]

	var title := Label.new()
	title.text = ev["title"]
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = ev["desc"]
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	for opt in ev["opts"]:
		var btn := Button.new()
		btn.text = opt[0]
		btn.custom_minimum_size = Vector2(0, 48)
		var action: Callable = opt[1]
		btn.pressed.connect(func():
			action.call()
			_leave()
		)
		vbox.add_child(btn)


# ── Actions ───────────────────────────────────────────────────
func _on_heal_pressed() -> void:
	_heal_party(0.3)
	_leave()

func _on_morale_pressed() -> void:
	_boost_morale(20)
	_leave()

func _on_train_pressed() -> void:
	_grant_xp_all(15)
	_leave()

func _heal_party(pct: float) -> void:
	for hero in RunState.get_living_party():
		hero.heal(int(hero.max_hp * pct))

func _boost_morale(amount: int) -> void:
	for hero in RunState.get_living_party():
		hero.adjust_morale(amount)

func _grant_xp_all(amount: int) -> void:
	for hero in RunState.get_living_party():
		hero.add_xp(amount)

func _first_hero_heal(amount: int) -> void:
	var living := RunState.get_living_party()
	if living.size() > 0:
		living[0].heal(amount)

func _add_ticket() -> void:
	RunState.gacha_tickets += 1

func _leave() -> void:
	SceneManager.go_to(SceneManager.TOWER_MAP)
