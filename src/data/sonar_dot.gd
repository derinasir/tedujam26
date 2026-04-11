class_name SonarDot
extends RefCounted

var global_position: Vector2 = Vector2.ZERO
var color: Color
var group: String
var lifetime: float = 1.0
var max_lifetime: float = 1.0


func _init(p_global_pos: Vector2, p_group: String, p_lifetime: float = 1.0) -> void:
	global_position = p_global_pos
	group = p_group
	lifetime = p_lifetime
	max_lifetime = p_lifetime
