# AppearanceGenerator.gd
# Call generate(hero_id, run_id) once when a hero is pulled.
# Returns an AppearanceData to store on the HeroInstance.

class_name AppearanceGenerator
extends RefCounted

# ── Available assets from your farmer pack ───────────────────
const HAIR_OPTIONS = [
	"res://art/heroes/farmer/fbas_13hair_bob1_00a.png",
	"res://art/heroes/farmer/fbas_13hair_dapper_00a.png",
]
const SHIRT_OPTIONS = [
	"res://art/heroes/farmer/fbas_05shrt_shortshirt_00a.png",
	"res://art/heroes/farmer/fbas_05shrt_shortshirtboobs_00a.png",
]
const PANTS_OPTIONS = [
	"res://art/heroes/farmer/fbas_04lwr1_longpants_00a.png",
]
const FEET_OPTIONS = [
	"res://art/heroes/farmer/fbas_03fot1_shoes_00a.png",
]
const HAT_OPTIONS = [
	"",   # no hat (weighted higher)
	"",   # extra weight for no hat
	"res://art/heroes/farmer/fbas_14head_cowboyhat_00d.png",
]

# ── Skin tones (from the Mana Seed skin ramp) ─────────────────
const SKIN_COLORS = [
	Color(1.00, 0.87, 0.74),   # light
	Color(0.95, 0.76, 0.57),   # medium light
	Color(0.82, 0.60, 0.38),   # medium
	Color(0.62, 0.40, 0.22),   # medium dark
	Color(0.38, 0.24, 0.13),   # dark
]

# ── Hair colors ───────────────────────────────────────────────
const HAIR_COLORS = [
	Color(0.20, 0.13, 0.08),   # black
	Color(0.55, 0.32, 0.10),   # brown
	Color(0.85, 0.65, 0.20),   # blonde
	Color(0.75, 0.22, 0.12),   # red
	Color(0.70, 0.70, 0.72),   # grey
	Color(0.40, 0.60, 0.90),   # blue (fantasy)
	Color(0.85, 0.35, 0.70),   # pink (fantasy)
]


static func generate(hero_id: String, run_id: String) -> AppearanceData:
	var rng = RandomNumberGenerator.new()
	rng.seed = (hero_id + run_id).hash()

	var appearance = AppearanceData.new()
	appearance.hair_texture    = HAIR_OPTIONS [rng.randi() % HAIR_OPTIONS.size()]
	appearance.shirt_texture   = SHIRT_OPTIONS[rng.randi() % SHIRT_OPTIONS.size()]
	appearance.pants_texture   = PANTS_OPTIONS[rng.randi() % PANTS_OPTIONS.size()]
	appearance.feet_texture    = FEET_OPTIONS [rng.randi() % FEET_OPTIONS.size()]
	appearance.hat_texture     = HAT_OPTIONS  [rng.randi() % HAT_OPTIONS.size()]
	appearance.skin_color      = SKIN_COLORS  [rng.randi() % SKIN_COLORS.size()]
	appearance.hair_color      = HAIR_COLORS  [rng.randi() % HAIR_COLORS.size()]
	appearance.outfit_color    = _random_outfit_color(rng)

	return appearance


static func _random_outfit_color(rng: RandomNumberGenerator) -> Color:
	# Generates a random muted color — avoids eye-searing saturation
	var h = rng.randf()               # any hue
	var s = rng.randf_range(0.3, 0.7) # medium saturation
	var v = rng.randf_range(0.5, 0.9) # medium-bright
	return Color.from_hsv(h, s, v)
