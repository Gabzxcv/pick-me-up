class_name SkillData
extends Resource

@export var skill_name: String = "Basic Attack"
@export var skill_id: String = "skill_000"
@export_multiline var description: String = ""
@export var icon: Texture2D

enum TargetType { SINGLE_ENEMY, ALL_ENEMIES, SINGLE_ALLY, ALL_ALLIES, SELF }
@export var target_type: TargetType = TargetType.SINGLE_ENEMY

@export var cooldown_turns: int = 0
@export var priority: int = 0

enum EffectType { DAMAGE, HEAL, BUFF, DEBUFF, SUMMON }
@export var effect_type: EffectType = EffectType.DAMAGE

@export var atk_multiplier: float = 1.0
@export var flat_value: int = 0

@export_group("Status Effect")
@export var applies_status: String = ""
@export var status_chance: float = 0.0
@export var status_duration: int = 0
