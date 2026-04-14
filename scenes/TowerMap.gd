extends Control

# ── UI refs ──────────────────────────────────────────────────
var _floor_label: Label
var _gold_label: Label
var _floor_info: Label
var _modifier_label: Label
var _party_container: VBoxContainer
var _action_btn: Button
var _gacha_btn: Button


func _ready() -> void:
	_build_ui()
	_refresh()
	RunState.gold_changed.connect(_on_gold_changed)
	RunState.run_ended.connect(_on_run_ended)


func _exit_tree() -> void:
	if RunState.gold_changed.is_connected(_on_gold_changed):
		RunState.gold_changed.disconnect(_on_gold_changed)
	if RunState.run_ended.is_connected(_on_run_ended):
		RunState.run_ended.disconnect(_on_run_ended)


# ── Build UI ──────────────────────────────────────────────────
func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.09, 0.11)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 32)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# ── Header row ──────────────────────────────────────────
	var hdr := HBoxContainer.new()
	vbox.add_child(hdr)

	_floor_label = Label.new()
	_floor_label.add_theme_font_size_override("font_size", 26)
	_floor_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(_floor_label)

	_gold_label = Label.new()
	_gold_label.add_theme_font_size_override("font_size", 18)
	hdr.add_child(_gold_label)

	# ── Floor info ──────────────────────────────────────────
	_floor_info = Label.new()
	_floor_info.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_floor_info)

	_modifier_label = Label.new()
	_modifier_label.modulate = Color(1.0, 0.8, 0.3)
	vbox.add_child(_modifier_label)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	# ── Party ───────────────────────────────────────────────
	var party_title := Label.new()
	party_title.text = "── Your Party ──"
	party_title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(party_title)

	_party_container = VBoxContainer.new()
	_party_container.add_theme_constant_override("separation", 4)
	vbox.add_child(_party_container)

	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(gap)

	# ── Buttons ─────────────────────────────────────────────
	_action_btn = Button.new()
	_action_btn.custom_minimum_size = Vector2(0, 56)
	_action_btn.pressed.connect(_on_advance_pressed)
	vbox.add_child(_action_btn)

	_gacha_btn = Button.new()
	_gacha_btn.custom_minimum_size = Vector2(0, 48)
	_gacha_btn.pressed.connect(_on_gacha_pressed)
	vbox.add_child(_gacha_btn)

	var save_btn := Button.new()
	save_btn.text = "💾  Save"
	save_btn.custom_minimum_size = Vector2(0, 40)
	save_btn.pressed.connect(RunState.save)
	vbox.add_child(save_btn)


# ── Refresh ───────────────────────────────────────────────────
func _refresh() -> void:
	var next_floor := RunState.current_floor + 1
	var floor_data: Dictionary = {}
	if next_floor < RunState.floor_map.size():
		floor_data = RunState.floor_map[next_floor]

	# Header
	if RunState.current_floor == 0:
		_floor_label.text = "Tower Entrance"
	else:
		_floor_label.text = "Floor  %d / %d" % [RunState.current_floor, RunState.max_floor]
	_gold_label.text = "💰 %d   🎫 %d" % [RunState.gold, RunState.gacha_tickets]

	# Next-floor info
	if floor_data.is_empty():
		_floor_info.text = "You've climbed to the top!"
		_modifier_label.text = ""
	else:
		var ftype: String = floor_data.get("type", "battle")
		_floor_info.text = "Next  →  Floor %d  [%s]" % [next_floor, ftype.to_upper()]
		var mod: String = floor_data.get("modifier", "")
		_modifier_label.text = ("⚠ Modifier: %s" % mod) if mod != "" else ""

	# Party list
	for c in _party_container.get_children():
		c.queue_free()
	for hero in RunState.roster:
		var row := Label.new()
		if hero.is_dead:
			row.text = "  💀  %s  (fell on floor %d)" % [hero.data.hero_name, hero.death_floor]
			row.modulate = Color(0.5, 0.5, 0.5)
		else:
			var hp_pct := float(hero.current_hp) / float(hero.max_hp)
			row.text = "  %s  Lv.%d  %s  HP %d/%d  ♥ %d" % [
				hero.data.hero_name, hero.level,
				_hp_bar(hp_pct, 8),
				hero.current_hp, hero.max_hp,
				hero.morale,
			]
		_party_container.add_child(row)

	# Action button
	if not RunState.run_active:
		_action_btn.text = "Run Over"
		_action_btn.disabled = true
	elif floor_data.is_empty():
		_action_btn.text = "🏆  Claim Victory!"
		_action_btn.disabled = false
	else:
		var ftype: String = floor_data.get("type", "battle")
		_action_btn.text = _floor_btn_label(ftype)
		_action_btn.disabled = RunState.get_living_party().is_empty()

	# Gacha button
	var full := RunState.roster.size() >= RunState.max_party_size
	_gacha_btn.text = "🎲  Pull Hero  (%d 🎫)" % RunState.gacha_tickets
	_gacha_btn.disabled = RunState.gacha_tickets < 1 or full or not RunState.run_active


func _hp_bar(pct: float, len: int) -> String:
	var filled := int(pct * len)
	var bar := "["
	for i in range(len):
		bar += "█" if i < filled else "░"
	bar += "]"
	return bar


func _floor_btn_label(ftype: String) -> String:
	match ftype:
		"battle": return "⚔  Enter Battle"
		"elite":  return "⚔  Fight Elite"
		"boss":   return "💀  Challenge Boss"
		"rest":   return "🏕  Rest"
		"shop":   return "🛒  Visit Shop"
		"event":  return "❓  Explore Event"
	return "▶  Advance"


# ── Handlers ──────────────────────────────────────────────────
func _on_advance_pressed() -> void:
	var next_floor := RunState.current_floor + 1
	if next_floor > RunState.max_floor:
		RunState.end_run(true)
		SceneManager.go_to(SceneManager.GAME_OVER)
		return

	RunState.advance_floor()
	var fdata  := RunState.get_current_floor_data()
	var ftype: String = fdata.get("type", "battle")
	match ftype:
		"rest", "shop", "event":
			SceneManager.go_to(SceneManager.REST)
		_:
			SceneManager.go_to(SceneManager.BATTLE)


func _on_gacha_pressed() -> void:
	var pulled := GachaManager.single_pull()
	if pulled and RunState.roster.size() < RunState.max_party_size:
		RunState.add_hero(pulled)
	_refresh()


func _on_gold_changed(_new_total: int) -> void:
	_refresh()


func _on_run_ended(_victory: bool) -> void:
	_refresh()
