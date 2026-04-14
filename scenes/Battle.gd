extends Control

const BATTLE_END_DELAY := 2.5

# ── UI refs ──────────────────────────────────────────────────
var _status_label: Label
var _party_container: VBoxContainer
var _enemy_container: VBoxContainer
var _log: RichTextLabel
var _speed_label: Label

# ── State ────────────────────────────────────────────────────
var _current_party: Array = []
var _current_enemies: Array = []
var _unit_labels: Dictionary = {}   # instance_id → Label
var _battle_done: bool = false


func _ready() -> void:
	_build_ui()
	call_deferred("_start_battle")


func _exit_tree() -> void:
	_disconnect_signals()


# ── Build UI ──────────────────────────────────────────────────
func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var outer := VBoxContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("separation", 4)
	add_child(outer)

	# Status bar
	_status_label = Label.new()
	_status_label.text = "Entering battle…"
	_status_label.add_theme_font_size_override("font_size", 16)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.custom_minimum_size.y = 32
	outer.add_child(_status_label)

	# Combatants row
	var combatants := HBoxContainer.new()
	combatants.size_flags_vertical = Control.SIZE_EXPAND_FILL
	combatants.add_theme_constant_override("separation", 6)
	outer.add_child(combatants)

	# Party panel
	var lp := PanelContainer.new()
	lp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	combatants.add_child(lp)
	var lv := VBoxContainer.new()
	lp.add_child(lv)
	var ph := Label.new()
	ph.text = "YOUR PARTY"
	ph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ph.add_theme_font_size_override("font_size", 14)
	lv.add_child(ph)
	_party_container = VBoxContainer.new()
	_party_container.add_theme_constant_override("separation", 3)
	lv.add_child(_party_container)

	# VS label
	var vs := Label.new()
	vs.text = "VS"
	vs.add_theme_font_size_override("font_size", 20)
	vs.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vs.custom_minimum_size.x = 36
	vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combatants.add_child(vs)

	# Enemy panel
	var rp := PanelContainer.new()
	rp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	combatants.add_child(rp)
	var rv := VBoxContainer.new()
	rp.add_child(rv)
	var eh := Label.new()
	eh.text = "ENEMIES"
	eh.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eh.add_theme_font_size_override("font_size", 14)
	rv.add_child(eh)
	_enemy_container = VBoxContainer.new()
	_enemy_container.add_theme_constant_override("separation", 3)
	rv.add_child(_enemy_container)

	# Speed controls
	var speed_bar := HBoxContainer.new()
	speed_bar.custom_minimum_size.y = 36
	outer.add_child(speed_bar)
	_speed_label = Label.new()
	_speed_label.text = "Speed: Normal  "
	speed_bar.add_child(_speed_label)
	for entry in [["1×", 0.8], ["2×", 0.3], ["4×", 0.1], ["⚡", 0.0]]:
		var btn := Button.new()
		btn.text = entry[0]
		var d: float = entry[1]
		btn.pressed.connect(func(): _set_speed(d))
		speed_bar.add_child(btn)

	# Combat log
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.custom_minimum_size = Vector2(0, 220)
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(_log)


# ── Battle ────────────────────────────────────────────────────
func _start_battle() -> void:
	var fdata  := RunState.get_current_floor_data()
	var ftype: String = fdata.get("type", "battle")
	var tier: int     = fdata.get("enemy_tier", 1)

	_current_enemies = EnemyFactory.make_enemy_party(RunState.current_floor, ftype)
	_current_party   = RunState.get_living_party()

	_log_add("[b]Floor %d — %s[/b]" % [RunState.current_floor, ftype.to_upper()])
	var mod: String = fdata.get("modifier", "")
	if mod != "":
		_log_add("[color=orange]⚠ Modifier: %s[/color]" % mod)

	_connect_signals()
	BattleManager.start_battle(_current_party, _current_enemies)


func _set_speed(delay: float) -> void:
	BattleManager.turn_delay = delay
	if delay == 0.0:
		_speed_label.text = "Speed: Instant  "
	elif delay <= 0.1:
		_speed_label.text = "Speed: 4×  "
	elif delay <= 0.3:
		_speed_label.text = "Speed: 2×  "
	else:
		_speed_label.text = "Speed: Normal  "


# ── Signal connections ────────────────────────────────────────
func _connect_signals() -> void:
	BattleManager.battle_started.connect(_on_battle_started)
	BattleManager.turn_started.connect(_on_turn_started)
	BattleManager.unit_attacked.connect(_on_unit_attacked)
	BattleManager.unit_healed.connect(_on_unit_healed)
	BattleManager.unit_died.connect(_on_unit_died)
	BattleManager.skill_used.connect(_on_skill_used)
	BattleManager.battle_ended.connect(_on_battle_ended)
	BattleManager.morale_changed.connect(_on_morale_changed)


func _disconnect_signals() -> void:
	var pairs := [
		[BattleManager.battle_started,  Callable(self, "_on_battle_started")],
		[BattleManager.turn_started,    Callable(self, "_on_turn_started")],
		[BattleManager.unit_attacked,   Callable(self, "_on_unit_attacked")],
		[BattleManager.unit_healed,     Callable(self, "_on_unit_healed")],
		[BattleManager.unit_died,       Callable(self, "_on_unit_died")],
		[BattleManager.skill_used,      Callable(self, "_on_skill_used")],
		[BattleManager.battle_ended,    Callable(self, "_on_battle_ended")],
		[BattleManager.morale_changed,  Callable(self, "_on_morale_changed")],
	]
	for pair in pairs:
		var sig: Signal     = pair[0]
		var cal: Callable   = pair[1]
		if sig.is_connected(cal):
			sig.disconnect(cal)


# ── Signal handlers ───────────────────────────────────────────
func _on_battle_started(party: Array, enemies: Array) -> void:
	_unit_labels.clear()

	for c in _party_container.get_children():
		c.queue_free()
	for hero in party:
		var lbl := Label.new()
		_party_container.add_child(lbl)
		_unit_labels[hero.instance_id] = lbl

	for c in _enemy_container.get_children():
		c.queue_free()
	for enemy in enemies:
		var lbl := Label.new()
		_enemy_container.add_child(lbl)
		_unit_labels[enemy.instance_id] = lbl

	_refresh_units(party + enemies)
	_log_add("[b]⚔  Battle begins![/b]")


func _on_turn_started(unit: HeroInstance, turn_num: int) -> void:
	_status_label.text = "Turn %d  —  %s acts" % [turn_num, unit.data.hero_name]
	_refresh_units(_current_party + _current_enemies)


func _on_skill_used(caster: HeroInstance, skill: SkillData, targets: Array) -> void:
	var names := targets.map(func(t: HeroInstance) -> String: return t.data.hero_name)
	_log_add("%s uses [b]%s[/b] → %s" % [caster.data.hero_name, skill.skill_name, ", ".join(names)])


func _on_unit_attacked(attacker: HeroInstance, target: HeroInstance, damage: int, is_crit: bool) -> void:
	var crit_str := " [color=yellow][CRIT][/color]" if is_crit else ""
	_log_add("  %s → %s  %d dmg%s" % [attacker.data.hero_name, target.data.hero_name, damage, crit_str])
	_refresh_units(_current_party + _current_enemies)


func _on_unit_healed(caster: HeroInstance, target: HeroInstance, amount: int) -> void:
	_log_add("  [color=green]%s heals %s for %d[/color]" % [caster.data.hero_name, target.data.hero_name, amount])
	_refresh_units(_current_party + _current_enemies)


func _on_unit_died(unit: HeroInstance, is_party_member: bool) -> void:
	var side := "party" if is_party_member else "enemy"
	_log_add("[color=red]💀 %s (%s) has fallen![/color]" % [unit.data.hero_name, side])
	_refresh_units(_current_party + _current_enemies)


func _on_morale_changed(hero: HeroInstance, delta: int, _new_val: int) -> void:
	var dir := "+" if delta >= 0 else ""
	_log_add("[color=orange]%s morale %s%d[/color]" % [hero.data.hero_name, dir, delta])


func _on_battle_ended(victory: bool, _survivors: Array) -> void:
	if _battle_done:
		return
	_battle_done = true
	_disconnect_signals()

	if victory:
		_log_add("[color=green][b]Victory![/b][/color]")
		_status_label.text = "Victory!  Returning to tower…"
		await get_tree().create_timer(BATTLE_END_DELAY).timeout
		SceneManager.go_to(SceneManager.TOWER_MAP)
	else:
		_log_add("[color=red][b]Defeat!  The party has fallen.[/b][/color]")
		_status_label.text = "Defeated…"
		await get_tree().create_timer(BATTLE_END_DELAY).timeout
		SceneManager.go_to(SceneManager.GAME_OVER)


# ── Helpers ───────────────────────────────────────────────────
func _refresh_units(units: Array) -> void:
	for unit: HeroInstance in units:
		if not (unit.instance_id in _unit_labels):
			continue
		var lbl: Label = _unit_labels[unit.instance_id]
		if unit.is_alive():
			var pct := float(unit.current_hp) / float(unit.max_hp)
			lbl.text = "%s  L%d  %s  %d/%d" % [
				unit.data.hero_name, unit.level,
				_hp_bar(pct, 10),
				unit.current_hp, unit.max_hp,
			]
			lbl.modulate = Color.WHITE
		else:
			lbl.text = "💀 %s" % unit.data.hero_name
			lbl.modulate = Color(0.4, 0.4, 0.4)


func _hp_bar(pct: float, length: int) -> String:
	var filled := int(pct * length)
	var bar := "["
	for i in range(length):
		bar += "█" if i < filled else "░"
	bar += "]"
	return bar


func _log_add(text: String) -> void:
	_log.append_text(text + "\n")
