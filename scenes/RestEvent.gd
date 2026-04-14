extends Control

# ── State ────────────────────────────────────────────────────
var _floor_type: String = "rest"
var _modifier: String   = ""


func _ready() -> void:
	var fdata    := RunState.get_current_floor_data()
	_floor_type   = fdata.get("type", "rest")
	_modifier     = fdata.get("modifier", "")
	_build_ui()


# ── Build UI ──────────────────────────────────────────────────
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
	vbox.custom_minimum_size.x = 420
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
	desc.text = "Your weary party sets up camp.\nChoose how to spend the rest."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	var heal_btn := Button.new()
	heal_btn.text = "💚  Heal Party  (+30 % Max HP)"
	heal_btn.custom_minimum_size = Vector2(0, 50)
	heal_btn.pressed.connect(_on_heal_pressed)
	vbox.add_child(heal_btn)

	var morale_btn := Button.new()
	morale_btn.text = "🔥  Boost Morale  (+20 morale all)"
	morale_btn.custom_minimum_size = Vector2(0, 50)
	morale_btn.pressed.connect(_on_morale_pressed)
	vbox.add_child(morale_btn)

	var skip_btn := Button.new()
	skip_btn.text = "➜  Move On"
	skip_btn.custom_minimum_size = Vector2(0, 44)
	skip_btn.pressed.connect(_leave)
	vbox.add_child(skip_btn)


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

	# Buy ticket
	var ticket_cost := 40
	var ticket_btn := Button.new()
	ticket_btn.text = "🎫  Buy Gacha Ticket  (%d 💰)" % ticket_cost
	ticket_btn.custom_minimum_size = Vector2(0, 50)
	ticket_btn.disabled = RunState.gold < ticket_cost
	ticket_btn.pressed.connect(func():
		if RunState.spend_gold(ticket_cost):
			RunState.gacha_tickets += 1
			gold_lbl.text = "Your gold: 💰 %d" % RunState.gold
			ticket_btn.text = "🎫  Bought!  (gold: %d)" % RunState.gold
			ticket_btn.disabled = true
	)
	vbox.add_child(ticket_btn)

	# Heal for gold
	var heal_cost := 25
	var heal_btn := Button.new()
	heal_btn.text = "💊  Heal Party  (%d 💰)" % heal_cost
	heal_btn.custom_minimum_size = Vector2(0, 50)
	heal_btn.disabled = RunState.gold < heal_cost
	heal_btn.pressed.connect(func():
		if RunState.spend_gold(heal_cost):
			_heal_party(0.5)
			heal_btn.text = "💊  Healed!  (gold: %d)" % RunState.gold
			heal_btn.disabled = true
	)
	vbox.add_child(heal_btn)

	var leave_btn := Button.new()
	leave_btn.text = "➜  Leave Shop"
	leave_btn.custom_minimum_size = Vector2(0, 44)
	leave_btn.pressed.connect(_leave)
	vbox.add_child(leave_btn)


func _add_event_options(vbox: VBoxContainer) -> void:
	# Pick a deterministic event based on floor
	var events := [
		{
			"title": "⚗  Mysterious Potion",
			"desc":  "A stranger offers you a glowing vial.",
			"opts":  [
				["Drink it  (+50 HP first hero)", func(): _first_hero_heal(50)],
				["Sell it  (+15 💰)",             func(): RunState.add_gold(15)],
				["Leave it alone",                func(): _leave()],
			]
		},
		{
			"title": "📜  Ancient Tome",
			"desc":  "You find a weathered book of battle lore.",
			"opts":  [
				["Study it  (+20 morale all)",     func(): _boost_morale(20)],
				["Sell it  (+25 💰)",              func(): RunState.add_gold(25)],
				["Leave it",                       func(): _leave()],
			]
		},
		{
			"title": "💎  Treasure Chest",
			"desc":  "A locked chest sits in the middle of the path.",
			"opts":  [
				["Force it open  (+40 💰)",        func(): RunState.add_gold(40)],
				["Leave it",                       func(): _leave()],
			]
		},
	]

	var event_idx := RunState.current_floor % events.size()
	var ev: Dictionary = events[event_idx]

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
		btn.pressed.connect(func(): action.call(); _leave())
		vbox.add_child(btn)


# ── Actions ───────────────────────────────────────────────────
func _on_heal_pressed() -> void:
	_heal_party(0.3)
	_leave()


func _on_morale_pressed() -> void:
	_boost_morale(20)
	_leave()


func _heal_party(pct: float) -> void:
	for hero in RunState.get_living_party():
		hero.heal(int(hero.max_hp * pct))


func _boost_morale(amount: int) -> void:
	for hero in RunState.get_living_party():
		hero.adjust_morale(amount)


func _first_hero_heal(amount: int) -> void:
	var living := RunState.get_living_party()
	if living.size() > 0:
		living[0].heal(amount)


func _leave() -> void:
	SceneManager.go_to(SceneManager.TOWER_MAP)
