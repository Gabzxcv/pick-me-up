# AppearanceData.gd
# Stores the rolled appearance for one hero instance.
# Saved inside HeroInstance so it persists across scenes.

class_name AppearanceData
extends Resource

# Texture paths — filled in by AppearanceGenerator
@export var hair_texture: String = ""
@export var shirt_texture: String = ""
@export var pants_texture: String = ""
@export var feet_texture: String = ""
@export var hat_texture: String = ""   # empty string = no hat

# Color modulates applied to each layer
@export var skin_color: Color = Color.WHITE
@export var hair_color: Color = Color.WHITE
@export var outfit_color: Color = Color.WHITE
