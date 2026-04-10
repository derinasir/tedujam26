class_name HitInfo
extends RefCounted

var attacker: Node #Node2D or Node3D
var victim: Node #Node2D or Node3D
var damage: float
var type: Constants.DamageType
var alignment: float # -1.0...1.0
var knockback_dir: Variant # Vector2 or Vector3
var knockback_force: float


static func from_damage_data(p_attacker: Node, damage_data: DamageData) -> HitInfo:
	return HitInfo.new(
		p_attacker,
		damage_data.damage,
		damage_data.type,
		damage_data.knockback_force,
	)


func _init(
		p_attacker: Node,
		p_damage: float,
		p_type: Constants.DamageType,
		p_knockback_force: float,
) -> void:
	attacker = p_attacker
	damage = p_damage
	type = p_type
	knockback_force = p_knockback_force


func clone() -> HitInfo:
	var copy = HitInfo.new(attacker, damage, type, knockback_force)
	copy.alignment = alignment
	copy.knockback_dir = knockback_dir
	return copy
